import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/library_provider.dart';
import '../widgets/absorbing_shared.dart';
import 'tv_book_screen.dart';
import 'tv_cover_tile.dart';
import 'tv_focusable.dart';
import 'tv_now_playing_bar.dart';

const _gridDelegate = SliverGridDelegateWithMaxCrossAxisExtent(
  maxCrossAxisExtent: 190,
  mainAxisSpacing: 28,
  crossAxisSpacing: 28,
  childAspectRatio: 0.74,
);

/// A grid laid out and scrolled the way the TV's other grids are.
Widget tvGrid({required int count, required IndexedWidgetBuilder builder, double top = 20}) => TvScrollFocusGroup(
      child: GridView.builder(
        padding: EdgeInsets.fromLTRB(56, top, 56, 140),
        clipBehavior: Clip.hardEdge,
        cacheExtent: 900,
        gridDelegate: _gridDelegate,
        itemCount: count,
        itemBuilder: builder,
      ),
    );

/// A tile in the browse grids: a picture, a name and a line under it.
class TvBrowseTile extends StatelessWidget {
  final Widget picture;
  final String name;
  final String detail;
  final VoidCallback onSelect;
  final bool round;

  const TvBrowseTile({
    super.key,
    required this.picture,
    required this.name,
    required this.detail,
    required this.onSelect,
    this.round = false,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return RepaintBoundary(
      child: Column(
        crossAxisAlignment: round ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: TvFocusable(
              onSelect: onSelect,
              radius: round ? 999 : 12,
              focusScale: 1.08,
              child: round
                  ? ClipOval(child: picture)
                  : ClipRRect(borderRadius: BorderRadius.circular(12), child: picture),
            ),
          ),
          const SizedBox(height: 8),
          Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: tt.titleSmall),
          Text(detail, maxLines: 1, overflow: TextOverflow.ellipsis, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }
}

/// The books of one group, in order: a series, an author, a collection or
/// a playlist. OK on one opens its page.
class TvBooksPage extends StatefulWidget {
  final String title;
  final Future<List<Map<String, dynamic>>> Function(BuildContext context) load;

  const TvBooksPage({super.key, required this.title, required this.load});

  static void open(
    BuildContext context,
    String title,
    Future<List<Map<String, dynamic>>> Function(BuildContext context) load,
  ) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => TvBooksPage(title: title, load: load)));
  }

  @override
  State<TvBooksPage> createState() => _TvBooksPageState();
}

class _TvBooksPageState extends State<TvBooksPage> {
  List<Map<String, dynamic>>? _books;

  @override
  void initState() {
    super.initState();
    widget.load(context).then((b) {
      if (mounted) setState(() => _books = b);
    }).catchError((_) {
      if (mounted) setState(() => _books = const []);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final books = _books;
    return Scaffold(
      backgroundColor: cs.surface,
      body: Stack(children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(56, 40, 56, 0),
            child: Row(children: [
              Flexible(
                child: Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: tt.headlineMedium?.copyWith(fontWeight: FontWeight.w600)),
              ),
              if (books != null) ...[
                const SizedBox(width: 16),
                Text(l.tvBookCount(books.length), style: tt.titleSmall?.copyWith(color: cs.onSurfaceVariant)),
              ],
            ]),
          ),
          Expanded(
            child: books == null
                ? const Center(child: CircularProgressIndicator())
                : books.isEmpty
                    ? Center(child: Text(l.tvNothingHere, style: tt.titleMedium))
                    : tvGrid(
                        count: books.length,
                        builder: (context, i) => TvCoverTile(
                          item: books[i],
                          autofocus: i == 0,
                          onSelect: () => openTvBook(context, books[i]),
                        ),
                      ),
          ),
        ]),
        Positioned(right: 28, bottom: 24, child: TvNowPlayingBar(hint: l.tvNowPlayingHint)),
      ]),
    );
  }
}

/// A series's books in order, for the series grid and "More in series".
Future<List<Map<String, dynamic>>> tvSeriesBooks(BuildContext context, String seriesId, {String? libraryId}) {
  final lib = context.read<LibraryProvider>();
  final id = libraryId ?? lib.selectedLibraryId;
  if (id == null) return Future.value(const []);
  return lib.fetchBooksBySeries(id, seriesId);
}

/// The library's series as covers; OK opens one in order.
class TvSeriesSection extends StatefulWidget {
  const TvSeriesSection({super.key});

  @override
  State<TvSeriesSection> createState() => _TvSeriesSectionState();
}

class _TvSeriesSectionState extends State<TvSeriesSection> {
  final _series = <Map<String, dynamic>>[];
  String? _libraryId;
  int _page = 0;
  int _total = -1;
  bool _loading = false;
  int _gen = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final id = context.watch<LibraryProvider>().selectedLibraryId;
    if (id != _libraryId) {
      _libraryId = id;
      _gen++;
      _series.clear();
      _page = 0;
      _total = -1;
      _loading = false;
      _more();
    }
  }

  Future<void> _more() async {
    final id = _libraryId;
    final api = context.read<AuthProvider>().apiService;
    if (id == null || api == null || _loading || (_total >= 0 && _series.length >= _total)) return;
    final gen = _gen;
    setState(() => _loading = true);
    final data = await api.getLibrarySeries(id, page: _page, limit: 60, sort: 'name', desc: 0);
    if (!mounted || gen != _gen) return;
    setState(() {
      _loading = false;
      if (data == null) return;
      _series.addAll((data['results'] as List? ?? const []).whereType<Map<String, dynamic>>());
      _total = (data['total'] as num?)?.toInt() ?? _series.length;
      _page++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final tt = Theme.of(context).textTheme;
    if (_series.isEmpty) {
      return Center(child: _loading ? const CircularProgressIndicator() : Text(l.tvNothingHere, style: tt.titleMedium));
    }
    return tvGrid(
      count: _series.length,
      builder: (context, i) {
        if (i >= _series.length - 18) WidgetsBinding.instance.addPostFrameCallback((_) => _more());
        final s = _series[i];
        final books = (s['books'] as List? ?? const []).whereType<Map<String, dynamic>>().toList();
        final name = s['name'] as String? ?? '';
        final first = books.isEmpty ? null : books.first;
        return TvBrowseTile(
          picture: TvCover(itemId: first?['id'] as String?, title: name, author: '', width: 300),
          name: name,
          detail: l.tvBookCount(books.length),
          onSelect: () => TvBooksPage.open(context, name, (c) => tvSeriesBooks(c, s['id'] as String? ?? '', libraryId: _libraryId)),
        );
      },
    );
  }
}

/// The library's authors, with their photos; OK shows their books.
class TvAuthorsSection extends StatefulWidget {
  const TvAuthorsSection({super.key});

  @override
  State<TvAuthorsSection> createState() => _TvAuthorsSectionState();
}

class _TvAuthorsSectionState extends State<TvAuthorsSection> {
  List<Map<String, dynamic>>? _authors;
  String? _libraryId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final id = context.watch<LibraryProvider>().selectedLibraryId;
    if (id != _libraryId) {
      _libraryId = id;
      _authors = null;
      _load();
    }
  }

  Future<void> _load() async {
    final id = _libraryId;
    final api = context.read<AuthProvider>().apiService;
    if (id == null || api == null) return;
    final authors = await api.getLibraryAuthors(id);
    if (!mounted || id != _libraryId) return;
    authors.sort((a, b) => (a['name'] as String? ?? '').toLowerCase().compareTo((b['name'] as String? ?? '').toLowerCase()));
    setState(() => _authors = authors);
  }

  Future<List<Map<String, dynamic>>> _books(BuildContext context, String authorId) async {
    final api = context.read<AuthProvider>().apiService;
    final author = await api?.getAuthorById(authorId, libraryId: _libraryId);
    return (author?['libraryItems'] as List? ?? const []).whereType<Map<String, dynamic>>().toList();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final authors = _authors;
    if (authors == null) return const Center(child: CircularProgressIndicator());
    if (authors.isEmpty) return Center(child: Text(l.tvNothingHere, style: tt.titleMedium));
    final api = context.read<AuthProvider>().apiService;
    final headers = context.read<LibraryProvider>().mediaHeaders;
    return tvGrid(
      count: authors.length,
      builder: (context, i) {
        final a = authors[i];
        final id = a['id'] as String? ?? '';
        final name = a['name'] as String? ?? '';
        final count = (a['numBooks'] as num?)?.toInt() ?? 0;
        final placeholder = ColoredBox(
          color: cs.primaryContainer,
          child: Center(
            child: Text(
              name.isEmpty ? '?' : name.trim()[0].toUpperCase(),
              style: tt.displaySmall?.copyWith(color: cs.onPrimaryContainer),
            ),
          ),
        );
        return TvBrowseTile(
          round: true,
          picture: a['imagePath'] == null || api == null
              ? placeholder
              : CachedNetworkImage(
                  imageUrl: api.getAuthorImageUrl(id, width: 300),
                  httpHeaders: headers,
                  fit: BoxFit.cover,
                  memCacheWidth: 300,
                  fadeInDuration: Duration.zero,
                  placeholder: (_, _) => placeholder,
                  errorWidget: (_, _, _) => placeholder,
                ),
          name: name,
          detail: l.tvBookCount(count),
          onSelect: () => TvBooksPage.open(context, name, (c) => _books(c, id)),
        );
      },
    );
  }
}

/// Collections and playlists, as covers; OK shows the books in one.
class TvListsSection extends StatefulWidget {
  const TvListsSection({super.key});

  @override
  State<TvListsSection> createState() => _TvListsSectionState();
}

class _TvListsSectionState extends State<TvListsSection> {
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    final lib = context.read<LibraryProvider>();
    Future.wait([lib.loadCollections(), lib.loadPlaylists()]).whenComplete(() {
      if (mounted) setState(() => _loaded = true);
    });
  }

  static List<Map<String, dynamic>> _booksOf(Map<String, dynamic> list) {
    final collectionBooks = list['books'] as List?;
    if (collectionBooks != null) return collectionBooks.whereType<Map<String, dynamic>>().toList();
    return [
      for (final it in (list['items'] as List? ?? const []).whereType<Map>())
        if (it['libraryItem'] is Map)
          {
            ...(it['libraryItem'] as Map).cast<String, dynamic>(),
            if (it['episode'] is Map) 'recentEpisode': it['episode'],
          },
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final tt = Theme.of(context).textTheme;
    final lib = context.watch<LibraryProvider>();
    final lists = <Map<String, dynamic>>[
      ...lib.collections.whereType<Map<String, dynamic>>(),
      ...lib.playlists.whereType<Map<String, dynamic>>(),
    ];
    if (lists.isEmpty) {
      return Center(child: _loaded ? Text(l.tvNothingHere, style: tt.titleMedium) : const CircularProgressIndicator());
    }
    return tvGrid(
      count: lists.length,
      builder: (context, i) {
        final list = lists[i];
        final name = list['name'] as String? ?? '';
        final books = _booksOf(list);
        final first = books.isEmpty ? null : books.first;
        return TvBrowseTile(
          picture: first == null
              ? CoverPlaceholder(title: name, author: '')
              : TvCover(itemId: first['id'] as String?, title: name, author: '', width: 300),
          name: name,
          detail: l.tvBookCount(books.length),
          onSelect: () => TvBooksPage.open(context, name, (_) async => books),
        );
      },
    );
  }
}
