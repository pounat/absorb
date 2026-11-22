import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/library_provider.dart';
import 'tv_book_screen.dart';
import 'tv_browse.dart';
import 'tv_cover_tile.dart';
import 'tv_focusable.dart';

enum _TvSort { added, title, author }

/// The Library tab's parts, as on the phone: every book, series, authors,
/// and lists (collections and playlists).
enum _TvSection { books, series, authors, lists }

/// Every book in the library as a grid of covers, a page at a time as the
/// remote nears the end.
class TvLibraryScreen extends StatefulWidget {
  const TvLibraryScreen({super.key});

  @override
  State<TvLibraryScreen> createState() => _TvLibraryScreenState();
}

/// Focuses the pill for the section showing (or the sort pill in a podcast
/// library): where down from the Library tab lands.
void Function()? tvFocusLibraryTop;

class _TvLibraryScreenState extends State<TvLibraryScreen> {
  final _sectionFocus = {for (final s in _TvSection.values) s: FocusNode(debugLabel: 'tv section ${s.name}')};
  final _sortFocus = FocusNode(debugLabel: 'tv library sort');

  @override
  void initState() {
    super.initState();
    tvFocusLibraryTop = _focusTop;
  }

  @override
  void dispose() {
    if (tvFocusLibraryTop == _focusTop) tvFocusLibraryTop = null;
    for (final n in _sectionFocus.values) {
      n.dispose();
    }
    _sortFocus.dispose();
    super.dispose();
  }

  void _focusTop() {
    final podcasts = context.read<LibraryProvider>().isPodcastLibrary;
    (podcasts ? _sortFocus : _sectionFocus[_section]!).requestFocus();
  }
  static const _pageSize = 60;

  final _items = <Map<String, dynamic>>[];
  String? _libraryId;
  _TvSort _sort = _TvSort.added;
  _TvSection _section = _TvSection.books;
  // Each part builds the first time it's shown and then stays, so going
  // back to one keeps its place.
  final _shown = <_TvSection>{_TvSection.books};

  void _showSection(_TvSection s) {
    if (s == _section) return;
    setState(() {
      _section = s;
      _shown.add(s);
    });
  }
  int _total = -1;
  int _page = 0;
  bool _loading = false;
  int _gen = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final id = context.watch<LibraryProvider>().selectedLibraryId;
    if (id != _libraryId) {
      _libraryId = id;
      _reset();
    }
  }

  void _reset() {
    _gen++;
    _items.clear();
    _total = -1;
    _page = 0;
    _loading = false;
    _loadMore();
  }

  Future<void> _loadMore() async {
    final id = _libraryId;
    final api = context.read<AuthProvider>().apiService;
    if (id == null || api == null || _loading) return;
    if (_total >= 0 && _items.length >= _total) return;
    final gen = _gen;
    setState(() => _loading = true);
    final (sort, desc) = switch (_sort) {
      _TvSort.added => ('addedAt', 1),
      _TvSort.title => ('media.metadata.title', 0),
      _TvSort.author => ('media.metadata.authorName', 0),
    };
    final data = await api.getLibraryItems(id, page: _page, limit: _pageSize, sort: sort, desc: desc);
    if (!mounted || gen != _gen) return;
    setState(() {
      _loading = false;
      if (data == null) return;
      final results = (data['results'] as List? ?? const []).whereType<Map<String, dynamic>>();
      _items.addAll(results);
      _total = (data['total'] as num?)?.toInt() ?? _items.length;
      _page++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final tt = Theme.of(context).textTheme;
    final sortLabel = switch (_sort) {
      _TvSort.added => l.tvSortAdded,
      _TvSort.title => l.tvSortTitle,
      _TvSort.author => l.tvSortAuthor,
    };

    final podcasts = context.watch<LibraryProvider>().isPodcastLibrary;

    Widget section(_TvSection s, String label, IconData icon) => Padding(
          padding: const EdgeInsets.only(right: 10),
          child: TvPillButton(
            focusNode: _sectionFocus[s],
            label: label,
            icon: icon,
            selected: _section == s,
            // Switches as the remote moves along, like the tabs above.
            onFocusChange: (v) {
              if (v) _showSection(s);
            },
            onSelect: () => _showSection(s),
          ),
        );

    final Widget books = _items.isEmpty
              ? Center(
                  child: _loading ? const CircularProgressIndicator() : Text(l.tvNothingHere, style: tt.titleMedium),
                )
              : TvScrollFocusGroup(
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(56, 20, 56, 140),
                    // Clipped, or covers scroll up over the tab bar.
                    clipBehavior: Clip.hardEdge,
                    cacheExtent: 900,
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 190,
                      mainAxisSpacing: 28,
                      crossAxisSpacing: 28,
                      childAspectRatio: 0.74,
                    ),
                    itemCount: _items.length,
                    itemBuilder: (context, i) {
                      if (i >= _items.length - 18) WidgetsBinding.instance.addPostFrameCallback((_) => _loadMore());
                      final item = _items[i];
                      return TvCoverTile(item: item, onSelect: () => openTvBook(context, item));
                    },
                  ),
                );

    Widget part(_TvSection s) => switch (s) {
          _TvSection.books => books,
          _TvSection.series => const TvSeriesSection(),
          _TvSection.authors => const TvAuthorsSection(),
          _TvSection.lists => const TvListsSection(),
        };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(56, 4, 56, 16),
          child: Row(
            children: [
              // A podcast library is just its podcasts.
              if (!podcasts) ...[
                section(_TvSection.books, l.tvBooks, Icons.menu_book_rounded),
                section(_TvSection.series, l.libraryTabSeries, Icons.collections_bookmark_rounded),
                section(_TvSection.authors, l.libraryTabAuthors, Icons.person_rounded),
                section(_TvSection.lists, l.tvLists, Icons.list_alt_rounded),
              ],
              if (_section == _TvSection.books || podcasts) ...[
                if (!podcasts) const SizedBox(width: 24),
                TvPillButton(
                  focusNode: _sortFocus,
                  icon: Icons.sort_rounded,
                  label: sortLabel,
                  onSelect: () {
                    setState(() => _sort = _TvSort.values[(_sort.index + 1) % _TvSort.values.length]);
                    _reset();
                  },
                ),
                const SizedBox(width: 16),
                if (_total >= 0) Text(podcasts ? l.tvPodcastCount(_total) : l.tvBookCount(_total), style: tt.titleSmall),
              ],
            ],
          ),
        ),
        Expanded(
          child: Stack(children: [
            for (final s in _TvSection.values)
              if (_shown.contains(s) && (!podcasts || s == _TvSection.books))
                Offstage(
                  offstage: s != (podcasts ? _TvSection.books : _section),
                  child: ExcludeFocus(excluding: s != _section, child: part(s)),
                ),
          ]),
        ),
      ],
    );
  }
}
