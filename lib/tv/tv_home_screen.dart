import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../main.dart' show colorSourceNotifier, coverSeedNotifier;
import '../providers/library_provider.dart';
import '../services/audio_player_service.dart';
import '../services/chromecast_service.dart';
import '../utils/absorbing_list.dart';
import '../utils/cover_accent.dart';
import 'tv_cover_tile.dart';
import 'tv_player_panel.dart';
import 'tv_playback.dart';

/// Bumped to put the remote on the cover row, as Back from another tab does.
final tvHomeFocusRow = ValueNotifier<int>(0);

/// Bumped to put the remote on the tab bar, as up from the cover row does.
final tvFocusTabs = ValueNotifier<int>(0);

/// Whether the player is open over the home row. The shell hides its tabs
/// meanwhile and sends Back here.
final tvPlayerOpen = ValueNotifier<bool>(false);

/// Bumped to close the player, by Back in the shell.
final tvPlayerClose = ValueNotifier<int>(0);

/// A book to open in the player from elsewhere: Play on its page.
final tvPlayerRequest = ValueNotifier<TvPlayRequest?>(null);

class TvPlayRequest {
  final Map<String, dynamic> item;
  final Map<String, dynamic>? episode;
  final bool fromStart;

  /// Start it playing. Off when it's only to show the book already playing.
  final bool play;

  const TvPlayRequest(this.item, {this.episode, this.fromStart = false, this.play = true});
}

/// The TV's home: the Absorbing books as a row of covers, moved with the
/// remote's left and right. OK opens the player in place: the cover glides
/// left and grows while the row fades, and the controls slide in beside it.
/// Only the cover moves, drawn once, so even a slow TV keeps up. The
/// remote's play button starts the book as it opens.
class TvHomeScreen extends StatefulWidget {
  /// The tab showing. Coming back to it lands on the playing book.
  final bool active;

  /// Room left at the top for the tab bar, which floats over this screen.
  /// The open player takes the whole screen.
  final double topInset;

  const TvHomeScreen({super.key, this.active = true, this.topInset = 0});

  @override
  State<TvHomeScreen> createState() => _TvHomeScreenState();
}

class _TvHomeScreenState extends State<TvHomeScreen> with SingleTickerProviderStateMixin {
  final _player = AudioPlayerService();
  final _cast = ChromecastService();
  final _homeFocus = FocusNode(debugLabel: 'tv home');
  final _coverKeys = <String, GlobalKey>{};
  late final AnimationController _openAnim =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
  PageController? _pages;
  double _fraction = 0;
  int _page = 0;
  bool _mergeLibraries = false;
  List<Map<String, dynamic>> _books = const [];
  String? _themedFrom;
  bool _orderedOnce = false;

  /// The book open in the player, and where its cover sat in the row.
  Map<String, dynamic>? _openItem;
  Rect? _from;

  @override
  void initState() {
    super.initState();
    _player.addListener(_onPlayer);
    tvHomeFocusRow.addListener(_focusRow);
    tvPlayerClose.addListener(_closePlayer);
    tvPlayerRequest.addListener(_onRequest);
    PlayerSettings.getMergeAbsorbingLibraries().then((v) {
      if (mounted && v != _mergeLibraries) setState(() => _mergeLibraries = v);
    });
  }

  @override
  void dispose() {
    _player.removeListener(_onPlayer);
    tvHomeFocusRow.removeListener(_focusRow);
    tvPlayerClose.removeListener(_closePlayer);
    tvPlayerRequest.removeListener(_onRequest);
    tvPlayerOpen.value = false;
    _openAnim.dispose();
    _homeFocus.dispose();
    _pages?.dispose();
    super.dispose();
  }

  void _onPlayer() {
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(TvHomeScreen old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active && _openItem == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showPlaying());
    }
  }

  void _focusRow() {
    // After the tab is showing again, or focus can't land in it.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _openItem == null) _homeFocus.requestFocus();
    });
    // A still screen has no next frame coming on its own.
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  /// Colors the app from [item]'s cover, the way the phone colors it from
  /// the book playing. Left alone when a color is picked in Settings.
  void _themeFrom(Map<String, dynamic> item) {
    final id = item['id'] as String?;
    if (id == null || id == _themedFrom || colorSourceNotifier.value == 'manual') return;
    final lib = context.read<LibraryProvider>();
    final url = lib.getCoverUrl(id, width: 400);
    if (url == null || url.isEmpty) return;
    _themedFrom = id;
    CoverAccents.seed(url, CachedNetworkImageProvider(url, headers: lib.mediaHeaders)).then((seed) {
      if (seed == null || !mounted || _themedFrom != id) return;
      coverSeedNotifier.value = seed;
      PlayerSettings.setCoverSeedColor(seed.toARGB32());
    }).catchError((_) {
      if (_themedFrom == id) _themedFrom = null;
    });
  }

  /// Moves the playing book to the front of the row and turns to it, and
  /// saves that order, as the phone does when a book starts.
  void _showPlaying() {
    final id = _player.currentItemId;
    final pages = _pages;
    if (!mounted || id == null || pages == null || !pages.hasClients) return;
    final ep = _player.currentEpisodeId;
    final key = ep == null ? id : '$id-$ep';
    final i = _books.indexWhere((b) => absorbingKeyOf(b) == key);
    if (i < 0) return;
    if (i > 0) context.read<LibraryProvider>().moveAbsorbingToFront(key);
    if (_page != 0) pages.jumpToPage(0);
    setState(() => _page = 0);
  }

  PageController _controllerFor(double fraction) {
    final existing = _pages;
    if (existing != null && (fraction - _fraction).abs() < 0.001) return existing;
    _fraction = fraction;
    final next = PageController(initialPage: _page, viewportFraction: fraction);
    if (existing != null) WidgetsBinding.instance.addPostFrameCallback((_) => existing.dispose());
    _pages = next;
    return next;
  }

  GlobalKey _keyFor(String key) => _coverKeys.putIfAbsent(key, GlobalKey.new);

  /// Where the cover for [key] sits in the row, in this screen's terms.
  Rect? _coverRect(String key) {
    final global = tvRectOf(_keyFor(key));
    final box = context.findRenderObject() as RenderBox?;
    if (global == null || box == null || !box.hasSize) return null;
    return box.globalToLocal(global.topLeft) & global.size;
  }

  void _openPlayer(
    Map<String, dynamic> item, {
    bool play = false,
    Map<String, dynamic>? episode,
    bool fromStart = false,
  }) {
    final shown = tvCardItem(item, episode ?? tvEpisodeOf(item));
    final key = absorbingKeyOf(shown);
    // Already open on this book: just start it.
    if (_openItem != null && absorbingKeyOf(_openItem!) == key) {
      if (play) startTvPlayback(context, item, episode: episode ?? tvEpisodeOf(item), fromStart: fromStart);
      return;
    }
    setState(() {
      _openItem = shown;
      _from = _coverRect(key);
    });
    tvPlayerOpen.value = true;
    _openAnim.forward(from: 0).whenComplete(() {
      // The heavy part of starting a book waits until the motion is done.
      if (play && mounted) {
        startTvPlayback(context, item, episode: episode ?? tvEpisodeOf(item), fromStart: fromStart);
      }
    });
  }

  void _closePlayer() {
    final open = _openItem;
    if (open == null || _openAnim.status == AnimationStatus.reverse) return;
    _from = _coverRect(absorbingKeyOf(open)) ?? _from;
    _openAnim.reverse().whenComplete(() {
      if (!mounted) return;
      setState(() => _openItem = null);
      tvPlayerOpen.value = false;
      _homeFocus.requestFocus();
      _showPlaying();
    });
  }

  /// Play on a book's page: back here, the row turned to that book if it's
  /// in it, and the player opened on it.
  void _onRequest() {
    final request = tvPlayerRequest.value;
    if (request == null) return;
    tvPlayerRequest.value = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final key = absorbingKeyOf(tvCardItem(request.item, request.episode));
      final i = _books.indexWhere((b) => absorbingKeyOf(b) == key);
      if (i >= 0 && i != _page && _pages != null && _pages!.hasClients) {
        _pages!.jumpToPage(i);
        setState(() => _page = i);
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _openPlayer(request.item, play: request.play, episode: request.episode, fromStart: request.fromStart);
      });
    });
  }

  KeyEventResult _onKey(KeyEvent event, List<Map<String, dynamic>> books) {
    // The player handles its own keys while it's open.
    if (_openItem != null || event is KeyUpEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    final pages = _pages;
    if (key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.arrowRight) {
      if (pages != null && pages.hasClients && books.isNotEmpty) {
        final target = (_page + (key == LogicalKeyboardKey.arrowRight ? 1 : -1)).clamp(0, books.length - 1);
        if (target != _page) {
          pages.animateToPage(target, duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic);
        }
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      tvFocusTabs.value++;
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowDown) return KeyEventResult.handled;
    final open = key == LogicalKeyboardKey.select ||
        key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter ||
        key == LogicalKeyboardKey.gameButtonA;
    final play = key == LogicalKeyboardKey.mediaPlayPause || key == LogicalKeyboardKey.mediaPlay;
    if (open || play) {
      if (event is KeyDownEvent && books.isNotEmpty) {
        _openPlayer(books[_page.clamp(0, books.length - 1)], play: play);
      }
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Widget _rowCover(Map<String, dynamic> item, double side) {
    final n = tvItemNames(item);
    return SizedBox.square(
      dimension: side,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 30, offset: Offset(0, 12))],
        ),
        child: ClipRRect(
          key: _keyFor(absorbingKeyOf(item)),
          borderRadius: BorderRadius.circular(20),
          child: TvCover(itemId: item['id'] as String?, title: n.title, author: n.author, width: 700),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final lib = context.watch<LibraryProvider>();
    // Order holds still while browsing: a book that starts playing stays where
    // the remote left it until the row is shown again.
    final books = buildAbsorbingList(
      lib,
      player: _player,
      cast: _cast,
      mergeLibraries: _mergeLibraries,
      suppressReorder: true,
    );
    _books = books;
    // On opening too, the book playing goes to the front of the row.
    if (!_orderedOnce && books.isNotEmpty && _player.hasBook) {
      _orderedOnce = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _showPlaying());
    }
    if (_openItem != null) {
      _themeFrom(_openItem!);
    } else if (books.isNotEmpty) {
      _themeFrom(books.first);
    }
    if (_page >= books.length && books.isNotEmpty) _page = books.length - 1;
    final focused = books.isEmpty ? null : books[_page];
    final backdrop = _openItem ?? focused;

    Widget body;
    if (focused == null) {
      body = Center(
        child: lib.isLoading
            ? const CircularProgressIndicator()
            : ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Text(l.tvHomeEmpty, textAlign: TextAlign.center, style: tt.titleLarge),
              ),
      );
    } else {
      final names = tvItemNames(focused);
      final episode = tvEpisodeOf(focused);
      final key = absorbingKeyOf(focused);
      final progress = lib.getProgressData(key);
      final pct = (progress?['progress'] as num?)?.toDouble() ?? 0;
      final playing = _player.currentItemId == focused['id'] &&
          _player.currentEpisodeId == episode?['id'] &&
          _player.isPlaying;

      body = LayoutBuilder(builder: (context, box) {
        final side = (box.maxHeight * 0.62).clamp(160.0, 520.0);
        final controller = _controllerFor((side + 40) / box.maxWidth);
        return Column(children: [
          SizedBox(
            height: side * 1.08,
            child: PageView.builder(
              controller: controller,
              clipBehavior: Clip.none,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (i) => setState(() => _page = i),
              itemCount: books.length,
              itemBuilder: (context, i) => AnimatedBuilder(
                animation: controller,
                builder: (context, child) {
                  final page = controller.hasClients && controller.position.haveDimensions
                      ? (controller.page ?? _page.toDouble())
                      : _page.toDouble();
                  final dist = (page - i).abs().clamp(0.0, 1.0);
                  return Opacity(
                    opacity: 1 - 0.55 * dist,
                    child: Transform.scale(scale: 1 - 0.22 * dist, child: child),
                  );
                },
                child: Center(child: _rowCover(books[i], side)),
              ),
            ),
          ),
          const SizedBox(height: 20),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Column(children: [
              Text(
                episode?['title'] as String? ?? names.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                episode != null ? names.title : names.author,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: tt.titleMedium?.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 14),
              Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(playing ? Icons.graphic_eq_rounded : Icons.play_arrow_rounded, size: 20, color: cs.primary),
                const SizedBox(width: 10),
                SizedBox(
                  width: 260,
                  child: LinearProgressIndicator(value: pct, minHeight: 5, borderRadius: BorderRadius.circular(3)),
                ),
                const SizedBox(width: 10),
                Text('${(pct * 100).round()}%', style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
              ]),
            ]),
          ),
        ]);
      });
    }

    final open = _openItem;
    return Focus(
      focusNode: _homeFocus,
      autofocus: true,
      onKeyEvent: (_, event) => _onKey(event, books),
      child: LayoutBuilder(builder: (context, box) {
        final size = box.biggest;
        // The cover's place in the open player: big, on the left.
        final side = (size.height * 0.74).clamp(160.0, 620.0);
        final target = Rect.fromLTWH(64, (size.height - side) / 2, side, side);
        return Stack(fit: StackFit.expand, children: [
          // The book's cover color washed in behind everything. A plain
          // color, not a blurred cover: TVs can't blur and stay smooth.
          if (backdrop != null)
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.2),
                  radius: 1.1,
                  colors: [
                    tvCoverColor(context, backdrop['id'] as String?, onFound: _onPlayer).withValues(alpha: 0.85),
                    cs.surface,
                  ],
                ),
              ),
            ),
          AnimatedBuilder(
            animation: _openAnim,
            child: Padding(padding: EdgeInsets.fromLTRB(0, widget.topInset + 12, 0, 24), child: Center(child: body)),
            // Kept in the tree while the player is open (fully faded, it isn't
            // drawn), so the row keeps its place instead of coming back at the
            // start while the remote thinks it's still on the same book.
            builder: (context, child) {
              final fade = 1 - const Interval(0, 0.5).transform(_openAnim.value);
              return ExcludeFocus(
                excluding: open != null,
                child: Opacity(opacity: fade, child: child),
              );
            },
          ),
          if (open != null) ...[
            // The cover, drawn once at its open size and only moved and
            // scaled on the way there and back.
            AnimatedBuilder(
              animation: _openAnim,
              child: RepaintBoundary(child: _openCover(open, side)),
              builder: (context, child) {
                final t = Curves.easeInOutCubic.transform(_openAnim.value);
                final from = _from ?? Rect.fromCenter(center: target.center, width: side * 0.85, height: side * 0.85);
                final now = Rect.lerp(from, target, t)!;
                final scale = now.width / target.width;
                return Positioned.fromRect(
                  rect: target,
                  child: Opacity(
                    opacity: _from == null ? const Interval(0, 0.4).transform(_openAnim.value) : 1,
                    child: Transform(
                      transform: Matrix4.translationValues(now.left - target.left, now.top - target.top, 0)
                        ..scale(scale, scale, 1.0),
                      child: child,
                    ),
                  ),
                );
              },
            ),
            Positioned(
              left: target.right + 56,
              right: 56,
              top: 0,
              bottom: 0,
              child: AnimatedBuilder(
                animation: _openAnim,
                // Scrolls if a long title pushes the buttons past the bottom;
                // moving down through it brings them into view.
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: RepaintBoundary(child: TvPlayerPanel(key: ValueKey(absorbingKeyOf(open)), item: open)),
                  ),
                ),
                // Built from the first frame (cheap), so nothing new appears
                // mid-motion; it's just not drawn until it starts to show.
                builder: (context, child) {
                  final p = const Interval(0.35, 1, curve: Curves.easeOutCubic).transform(_openAnim.value);
                  return Opacity(
                    opacity: p,
                    child: Transform.translate(offset: Offset((1 - p) * 80, 0), child: child),
                  );
                },
              ),
            ),
          ],
        ]);
      }),
    );
  }

  Widget _openCover(Map<String, dynamic> item, double side) {
    final n = tvItemNames(item);
    return SizedBox.square(
      dimension: side,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 40, offset: Offset(0, 16))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: TvCover(itemId: item['id'] as String?, title: n.title, author: n.author, width: 700),
        ),
      ),
    );
  }
}
