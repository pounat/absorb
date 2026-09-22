import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_carplay/flutter_carplay.dart';
import 'android_auto_service.dart';
import 'api_service.dart';
import 'audio_player_service.dart';
import 'carplay_image_url.dart';

/// Manages Apple CarPlay browse tree and playback integration.
/// Mirrors the Android Auto layout: 3 tabs (Continue, Library, Downloads)
/// with hierarchical drilling into books/series/authors and podcasts.
class CarPlayService {
  static final CarPlayService _instance = CarPlayService._();
  factory CarPlayService() => _instance;
  CarPlayService._();

  final _autoService = AndroidAutoService();
  final _flutterCarplay = FlutterCarplay();

  /// Bridges CarPlay Now Playing button taps to/from native. The buttons live
  /// only on CPNowPlayingTemplate, so the iOS lock screen is never affected.
  static const _nowPlayingChannel = MethodChannel('com.absorb.carplay');

  double _lastPushedSpeed = -1;
  bool _bannerShowing = false;
  Timer? _bannerDismissTimer;

  bool _initialized = false;
  bool _connected = false;
  DateTime? _lastRootBuilt;
  CPTabBarTemplate? _rootTemplate;
  Future<void>? _inFlightBuild;

  void init() {
    if (!Platform.isIOS || _initialized) return;
    _initialized = true;
    _flutterCarplay.addListenerOnConnectionChange(_onConnectionChange);
    _nowPlayingChannel.setMethodCallHandler(_handleNativeCall);
    // Keep the CarPlay speed button label in sync with rate changes from
    // anywhere (the phone speed sheet, a per-book default, etc.).
    AudioPlayerService().addListener(_onPlayerChanged);
    debugPrint('[CarPlay] Initialized');
    // Re-render the root template when the background server refresh
    // completes. AutoBrowse.refresh() returns immediately after downloads
    // are populated and continues the server fetch in the background;
    // this hook is how we know to swap the downloads-only tree for the
    // full one (or the other way for offline → online recovery).
    AndroidAutoService.onServerDataChanged = () {
      if (!_initialized || !_connected || _rootTemplate == null) return;
      // _connectAndRender awaits its own refresh() which fires this callback
      // mid-flight; without this guard both paths call setRootTemplate within
      // ~0ms and CarPlay renders the tabs blank until the user backgrounds
      // and reopens the app.
      if (_inFlightBuild != null) {
        debugPrint('[CarPlay] onServerDataChanged - skipped (build in flight)');
        return;
      }
      if (_lastRootBuilt != null &&
          DateTime.now().difference(_lastRootBuilt!) < const Duration(milliseconds: 500)) {
        debugPrint('[CarPlay] onServerDataChanged - skipped (built ${DateTime.now().difference(_lastRootBuilt!).inMilliseconds}ms ago)');
        return;
      }
      debugPrint('[CarPlay] onServerDataChanged - rebuilding root template');
      refreshTemplates();
    };
    unawaited(_restoreConnectionState());
  }

  Future<void> _restoreConnectionState() async {
    try {
      if (await FlutterCarplay.isConnected && _initialized && !_connected) {
        _onConnectionChange(ConnectionStatusTypes.connected);
      }
    } catch (e) {
      debugPrint('[CarPlay] Connection state check failed: $e');
    }
  }

  void dispose() {
    _connected = false;
    _flutterCarplay.removeListenerOnConnectionChange();
    AudioPlayerService().removeListener(_onPlayerChanged);
    _bannerDismissTimer?.cancel();
  }

  void _onConnectionChange(ConnectionStatusTypes status) {
    debugPrint('[CarPlay] Connection status: $status');
    if (status == ConnectionStatusTypes.disconnected) {
      _connected = false;
      _rootTemplate = null;
      _lastRootBuilt = null;
      _bannerDismissTimer?.cancel();
      _bannerShowing = false;
      return;
    }
    if (status != ConnectionStatusTypes.connected) return;
    if (_connected) return;
    _connected = true;
    unawaited(_maybeAutoplayOnConnect());
    _connectAndRender();
  }

  /// GH #371 (CarPlay side): opt-in autoplay when the car connects with
  /// nothing loaded. Unlike Android Auto there's an explicit connection
  /// event, so no browse-stamp heuristics - the _connected edge above is the
  /// once-per-connection gate. A loaded book means the session is alive and
  /// a resume belongs to the user (or the head unit's own play command), and
  /// it keeps a deliberate pause from being undone by a reconnect.
  Future<void> _maybeAutoplayOnConnect() async {
    try {
      final player = AudioPlayerService();
      if (player.hasBook) return;
      if (!await PlayerSettings.getAutoplayOnCarConnect()) return;
      // The connect event can arrive during a cold launch in the car - let
      // init settle before starting audio.
      await Future.delayed(const Duration(milliseconds: 1500));
      if (!_connected) return;
      if (player.hasBook || player.isPlaying) return;
      final restore = AudioPlayerService.onColdStartPlayRequested;
      if (restore == null) return;
      debugPrint('[AutoPlay] CarPlay connected - resuming last played');
      await restore();
    } catch (e) {
      debugPrint('[AutoPlay] CarPlay autoplay failed: $e');
    }
  }

  Future<void> _connectAndRender() async {
    if (!_connected) return;
    // Make sure data is loaded before rendering so the first template the
    // user sees has real content.
    //
    // We avoid calling setRootTemplate twice (once empty, once full) because
    // the flutter_carplay native side appears to leave the first template
    // visible and the second call doesn't re-render. Same for
    // updateTabBarTemplates - it updates the cached template but doesn't
    // refresh the displayed UI and (worse) breaks tap routing on the new
    // items. So we wait, then setRootTemplate once with full data.
    try {
      await _autoService.refresh();
    } catch (e) {
      debugPrint('[CarPlay] Pre-render refresh failed: $e');
    }
    if (!_connected) return;
    await _setRootTemplate(label: 'on-connect');
  }

  /// Clear cache and rebuild templates (e.g. on account switch).
  Future<void> clearAndRefresh() async {
    if (!_initialized || !_connected) return;
    await _autoService.refresh(force: true);
    if (!_connected) return;
    await _setRootTemplate(label: 'clear-and-refresh');
  }

  /// Refresh CarPlay templates (e.g. after download completes).
  Future<void> refreshTemplates() async {
    if (!_initialized || !_connected) return;
    await _setRootTemplate(label: 'refresh-templates');
  }

  // ─── Root template ──────────────────────────────────────────────────

  Future<List<CPListTemplate>> _buildTabs() async {
    final downloadsTab = await _buildDownloadsTab();
    // When the server is unreachable, Continue / New / Library are empty
    // anyway (we skip the server fetch). Drop them so CarPlay opens
    // straight into the user's downloads instead of showing three empty
    // tabs they have to swipe past.
    if (AudioPlayerService().knownOffline) {
      return [downloadsTab];
    }
    // Cold start race: knownOffline defaults to false and only flips after
    // the auth ping fails (~15s). If CarPlay connects before then with no
    // server data loaded yet, Continue/New/Library would render as empty
    // tabs and the user lands on a blank Continue tab. Skip any tab that
    // has nothing to show; onServerDataChanged will rebuild once data
    // arrives.
    final tabs = <CPListTemplate>[];
    if (_autoService.continueListening.isNotEmpty) {
      tabs.add(await _buildContinueTab());
    }
    if (_autoService.recentlyAdded.isNotEmpty) {
      tabs.add(await _buildRecentlyAddedTab());
    }
    if (_autoService.libraries.isNotEmpty) {
      tabs.add(await _buildLibraryTab());
    }
    tabs.add(downloadsTab);
    return tabs;
  }

  Future<void> _setRootTemplate({String label = ''}) async {
    if (!_connected) return;
    // Coalesce concurrent calls. If a build is already in flight, await it
    // instead of starting a second one - two setRootTemplate invocations
    // racing within the same microtask leave CarPlay rendering blank tabs.
    if (_inFlightBuild != null) {
      debugPrint('[CarPlay] _setRootTemplate ($label) - awaiting in-flight build');
      return _inFlightBuild;
    }
    final fut = _doSetRootTemplate(label: label);
    _inFlightBuild = fut;
    try {
      await fut;
    } finally {
      _inFlightBuild = null;
    }
  }

  Future<void> _doSetRootTemplate({required String label}) async {
    final tabs = await _buildTabs();
    if (!_connected) return;
    final root = CPTabBarTemplate(templates: tabs);
    _rootTemplate = root;
    await FlutterCarplay.setRootTemplate(rootTemplate: root, animated: false);
    if (!_connected) return;
    // Without this the native side may not register onPress callbacks on
    // the new list items, leaving taps stuck on an infinite spinner.
    await _flutterCarplay.forceUpdateRootTemplate();
    _lastRootBuilt = DateTime.now();
    debugPrint('[CarPlay] Root template set ($label)'
        ' continue=${_autoService.continueListening.length}'
        ' downloads=${_autoService.downloaded.length}'
        ' libraries=${_autoService.libraries.length}');
    // Configure the Now Playing buttons after the root template is built.
    await _configureNowPlayingButtons();
  }

  // ─── Now Playing custom buttons ─────────────────────────────────────

  /// Ask the native side to (re)attach the custom buttons to
  /// CPNowPlayingTemplate.shared.
  Future<void> _configureNowPlayingButtons() async {
    if (!_connected) return;
    try {
      final speed = AudioPlayerService().speed;
      _lastPushedSpeed = speed;
      await _nowPlayingChannel
          .invokeMethod('setupNowPlayingButtons', {'speed': speed});
    } catch (e) {
      debugPrint('[CarPlay] setupNowPlayingButtons failed: $e');
    }
  }

  /// Refresh the CarPlay speed button when the rate changes anywhere.
  void _onPlayerChanged() {
    if (!_connected) return;
    final speed = AudioPlayerService().speed;
    if ((speed - _lastPushedSpeed).abs() < 0.001) return;
    _configureNowPlayingButtons();
  }

  /// Briefly confirm a saved bookmark. CarPlay has no toast, so we present an
  /// auto-dismissing modal alert (the closest thing to a banner it offers). The
  /// OK action lets the driver dismiss early; otherwise it clears itself.
  Future<void> _showBookmarkBanner() async {
    if (!_connected) return;
    try {
      _bannerDismissTimer?.cancel();
      if (_bannerShowing) {
        await FlutterCarplay.popModal();
        _bannerShowing = false;
      }
      if (!_connected) return;
      await FlutterCarplay.showAlert(
        template: CPAlertTemplate(
          titleVariants: const ['Bookmark added'],
          actions: [
            CPAlertAction(
              title: 'OK',
              onPress: () {
                _bannerDismissTimer?.cancel();
                _bannerShowing = false;
                if (_connected) FlutterCarplay.popModal();
              },
            ),
          ],
        ),
      );
      _bannerShowing = true;
      _bannerDismissTimer = Timer(const Duration(milliseconds: 1800), () {
        if (!_connected || !_bannerShowing) return;
        _bannerShowing = false;
        FlutterCarplay.popModal();
      });
    } catch (e) {
      debugPrint('[CarPlay] bookmark banner failed: $e');
    }
  }

  /// Route a Now Playing button tap from native into the audio handler's
  /// customAction, which owns the chapter/speed/bookmark logic.
  Future<dynamic> _handleNativeCall(MethodCall call) async {
    if (!_connected || call.method != 'carPlayButton') return null;
    final action = (call.arguments as Map?)?['action'] as String?;
    if (action == null) return null;
    debugPrint('[CarPlay] Now Playing button: $action');
    final result = await AudioPlayerService.handler?.customAction(action);
    if (action == 'bookmark' && result == true) {
      await _showBookmarkBanner();
    }
    return null;
  }

  // ─── Continue Listening tab ─────────────────────────────────────────

  Future<CPListTemplate> _buildContinueTab() async {
    final api = await _autoService.getApi();
    final entries = _autoService.continueListening;
    final items = entries.map((e) => _playableListItem(e, api)).toList();
    return CPListTemplate(
      sections: [CPListSection(items: items)],
      title: 'Continue',
      systemIcon: 'play.circle.fill',
    );
  }

  // ─── Recently Added tab ────────────────────────────────────────────

  Future<CPListTemplate> _buildRecentlyAddedTab() async {
    final api = await _autoService.getApi();
    final entries = _autoService.recentlyAdded;
    final items = entries.map((e) => _playableListItem(e, api)).toList();
    return CPListTemplate(
      sections: [CPListSection(items: items)],
      title: 'New',
      systemIcon: 'sparkles',
    );
  }

  // ─── Library tab ────────────────────────────────────────────────────

  Future<CPListTemplate> _buildLibraryTab() async {
    final libs = _autoService.libraries;

    // Single library: skip picker, show sub-categories or shows directly
    if (libs.length == 1) {
      final lib = libs.first;
      if (lib.isPodcast) {
        return _buildPodcastShowsList(lib.id, lib.name);
      }
      return _buildBookSubCategories(lib.id, 'Library');
    }

    // Multiple libraries: show library picker
    final items = libs.map((lib) {
      return CPListItem(
        text: lib.name,
        accessoryType: CPListItemAccessoryTypes.disclosureIndicator,
        onPress: (complete, self) async {
          if (lib.isPodcast) {
            final template = await _buildPodcastShowsList(lib.id, lib.name);
            _pushTemplate(template);
          } else {
            final template = await _buildBookSubCategories(lib.id, lib.name);
            _pushTemplate(template);
          }
          complete();
        },
      );
    }).toList();

    return CPListTemplate(
      sections: [CPListSection(items: items)],
      title: 'Library',
      systemIcon: 'books.vertical.fill',
    );
  }

  // ─── Downloads tab ──────────────────────────────────────────────────

  Future<CPListTemplate> _buildDownloadsTab() async {
    final api = await _autoService.getApi();
    final entries = _autoService.downloaded;
    final items = entries.map((e) => _playableListItem(e, api)).toList();
    return CPListTemplate(
      sections: [CPListSection(items: items)],
      title: 'Downloads',
      systemIcon: 'arrow.down.circle.fill',
    );
  }

  // ─── Book library sub-categories ───────────────────────────────────

  Future<CPListTemplate> _buildBookSubCategories(String libraryId, String title) async {
    final items = [
      CPListItem(
        text: 'Books',
        accessoryType: CPListItemAccessoryTypes.disclosureIndicator,
        onPress: (complete, self) async {
          final template = await _buildBooksList(libraryId);
          _pushTemplate(template);
          complete();
        },
      ),
      CPListItem(
        text: 'Series',
        accessoryType: CPListItemAccessoryTypes.disclosureIndicator,
        onPress: (complete, self) async {
          final template = await _buildSeriesList(libraryId);
          _pushTemplate(template);
          complete();
        },
      ),
      CPListItem(
        text: 'Authors',
        accessoryType: CPListItemAccessoryTypes.disclosureIndicator,
        onPress: (complete, self) async {
          final template = await _buildAuthorsList(libraryId);
          _pushTemplate(template);
          complete();
        },
      ),
    ];

    return CPListTemplate(
      sections: [CPListSection(items: items)],
      title: title,
      systemIcon: 'books.vertical',
    );
  }

  // ─── Books list ────────────────────────────────────────────────────

  /// CarPlay books browse. Unlike Android Auto, CarPlay caps the navigation
  /// stack (~5 pushed templates), so a recursive letter drilldown (T -> Th ->
  /// The -> ...) pushes too deep and iOS kills the app. Instead we show ONE
  /// flat level of letter/prefix buckets (each <= bucketThreshold) and then
  /// the book list - a fixed depth of two pushes.
  Future<CPListTemplate> _buildBooksList(String libraryId) async {
    final api = await _autoService.getApi();
    final all = await _autoService.fetchAllBooks(libraryId);

    // Small library: skip the bucket level, list the books directly.
    if (all.length <= AndroidAutoService.bucketThreshold) {
      final items = all.map((e) => _playableListItem(e, api)).toList();
      return CPListTemplate(
        sections: [CPListSection(items: items)],
        title: 'Books',
        systemIcon: 'book.fill',
      );
    }

    final buckets = _autoService.flattenedBookBuckets(all);
    final items = buckets.map((b) {
      return CPListItem(
        text: b.prefix.isEmpty ? '#' : b.prefix,
        detailText: '${b.count}',
        accessoryType: CPListItemAccessoryTypes.disclosureIndicator,
        onPress: (complete, self) async {
          final template = await _buildBooksLeaf(libraryId, b.prefix);
          _pushTemplate(template);
          complete();
        },
      );
    }).toList();
    return CPListTemplate(
      sections: [CPListSection(items: items)],
      title: 'Books',
      systemIcon: 'book.fill',
    );
  }

  /// Leaf book list for one flat bucket [prefix].
  Future<CPListTemplate> _buildBooksLeaf(String libraryId, String prefix) async {
    final api = await _autoService.getApi();
    final all = await _autoService.fetchAllBooks(libraryId);
    final books = _autoService.booksForPrefix(all, prefix);
    final items = books.map((e) => _playableListItem(e, api)).toList();
    return CPListTemplate(
      sections: [CPListSection(items: items)],
      title: prefix.isEmpty ? 'Books' : prefix,
      systemIcon: 'book.fill',
    );
  }

  // ─── Series list ───────────────────────────────────────────────────

  Future<CPListTemplate> _buildSeriesList(String libraryId) async {
    final seriesData = await _autoService.fetchLibrarySeriesData(libraryId);
    final items = seriesData.map((s) {
      return CPListItem(
        text: s.name,
        accessoryType: CPListItemAccessoryTypes.disclosureIndicator,
        onPress: (complete, self) async {
          final template = await _buildSeriesBooks(s.id, libraryId, s.name);
          _pushTemplate(template);
          complete();
        },
      );
    }).toList();

    return CPListTemplate(
      sections: [CPListSection(items: items)],
      title: 'Series',
      systemIcon: 'rectangle.stack.fill',
    );
  }

  Future<CPListTemplate> _buildSeriesBooks(String seriesId, String libraryId, String title) async {
    final api = await _autoService.getApi();
    final entries = await _autoService.fetchSeriesBooksData(seriesId, libraryId);
    final items = entries.map((e) => _playableListItem(e, api)).toList();
    return CPListTemplate(
      sections: [CPListSection(items: items)],
      title: title,
      systemIcon: 'rectangle.stack.fill',
    );
  }

  // ─── Authors list ──────────────────────────────────────────────────

  Future<CPListTemplate> _buildAuthorsList(String libraryId) async {
    final authorsData = await _autoService.fetchLibraryAuthorsData(libraryId);
    final items = authorsData.map((a) {
      return CPListItem(
        text: a.name,
        accessoryType: CPListItemAccessoryTypes.disclosureIndicator,
        onPress: (complete, self) async {
          final template = await _buildAuthorBooks(a.id, libraryId, a.name);
          _pushTemplate(template);
          complete();
        },
      );
    }).toList();

    return CPListTemplate(
      sections: [CPListSection(items: items)],
      title: 'Authors',
      systemIcon: 'person.2.fill',
    );
  }

  Future<CPListTemplate> _buildAuthorBooks(String authorId, String libraryId, String title) async {
    final api = await _autoService.getApi();
    final entries = await _autoService.fetchAuthorBooksData(authorId, libraryId);
    final items = entries.map((e) => _playableListItem(e, api)).toList();
    return CPListTemplate(
      sections: [CPListSection(items: items)],
      title: title,
      systemIcon: 'person.fill',
    );
  }

  // ─── Podcast shows ─────────────────────────────────────────────────

  Future<CPListTemplate> _buildPodcastShowsList(String libraryId, String title) async {
    final showsData = await _autoService.fetchPodcastShowsData(libraryId);
    final items = showsData.map((s) {
      return CPListItem(
        text: s.title,
        image: safeCarPlayImageUrl(s.coverUrl),
        accessoryType: CPListItemAccessoryTypes.disclosureIndicator,
        onPress: (complete, self) async {
          final template = await _buildShowEpisodes(s.id, libraryId, s.title);
          _pushTemplate(template);
          complete();
        },
      );
    }).toList();

    return CPListTemplate(
      sections: [CPListSection(items: items)],
      title: title,
      systemIcon: 'mic.fill',
    );
  }

  Future<CPListTemplate> _buildShowEpisodes(String showId, String libraryId, String title) async {
    final api = await _autoService.getApi();
    final entries = await _autoService.fetchShowEpisodesData(showId, libraryId);
    final items = entries.map((e) => _playableListItem(e, api)).toList();
    return CPListTemplate(
      sections: [CPListSection(items: items)],
      title: title,
      systemIcon: 'mic.fill',
    );
  }

  // ─── Helpers ───────────────────────────────────────────────────────

  /// Build a playable CPListItem from an AutoBookEntry. Recently-added
  /// podcast shows aren't directly playable, so build a browseable item that
  /// drills into the show's episodes.
  CPListItem _playableListItem(AutoBookEntry entry, ApiService? api) {
    final coverItemId = entry.showId ?? entry.id;
    // Downloaded books: file:// URL (already mtime-busted in _refreshDownloaded).
    // Streaming: ?ts= the server updatedAt so iOS refetches after a cover change.
    final entryUrl = entry.coverUrl;
    final ts = AndroidAutoService.coverTsFor(coverItemId);
    final rawCoverUrl = (entryUrl != null && entryUrl.startsWith('file://'))
        ? entryUrl
        : api?.getCoverUrl(coverItemId, updatedAt: ts);
    final coverUrl = safeCarPlayImageUrl(rawCoverUrl);

    final isPodcastShow = entry.mediaType == 'podcast' &&
        entry.episodeId == null &&
        entry.libraryId != null &&
        entry.libraryId!.isNotEmpty;

    if (isPodcastShow) {
      return CPListItem(
        text: entry.title,
        detailText: entry.author.isNotEmpty ? entry.author : null,
        image: coverUrl,
        accessoryType: CPListItemAccessoryTypes.disclosureIndicator,
        onPress: (complete, self) async {
          final template = await _buildShowEpisodes(
              entry.id, entry.libraryId!, entry.title);
          _pushTemplate(template);
          complete();
        },
      );
    }

    final mediaId = (entry.episodeId != null && entry.showId != null)
        ? AutoMediaIds.itemId('${entry.showId}-${entry.episodeId}')
        : AutoMediaIds.itemId(entry.id);

    return CPListItem(
      text: entry.title,
      detailText: entry.author.isNotEmpty ? entry.author : null,
      image: coverUrl,
      playbackProgress: _playbackProgress(entry),
      onPress: (complete, self) {
        _playItem(mediaId);
        complete();
      },
    );
  }

  double _playbackProgress(AutoBookEntry entry) {
    if (entry.currentTime == null || entry.duration <= 0) return 0;
    return (entry.currentTime! / entry.duration).clamp(0.0, 1.0);
  }

  void _pushTemplate(CPListTemplate template) {
    if (!_connected) return;
    FlutterCarplay.push(template: template);
  }

  void _playItem(String mediaId) {
    debugPrint('[CarPlay] Playing: $mediaId');
    // Call the handler directly. The static AudioService.playFromMediaId is a
    // deprecated compat shim wired only in the old AudioService.start() flow;
    // with the modern AudioService.init() it routes to a no-op BaseAudioHandler.
    AudioPlayerService.handler?.playFromMediaId(mediaId);
    // Jump straight to Now Playing on tap, like the native apps, instead of
    // making the user find the Now Playing button. pushIfNotExist on the native
    // side means it's a no-op if Now Playing is already on screen.
    if (_connected) FlutterCarplay.showSharedNowPlaying();
  }
}
