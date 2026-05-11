import 'dart:async';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../screens/library_screen.dart';

/// Which library tab the sort/filter sheet is being shown for.
enum LibraryTab { library, series, authors, narrators }

// ═══════════════════════════════════════════════════════════════
// Sort & Filter bottom sheet with tabs
// ═══════════════════════════════════════════════════════════════
class SortFilterSheet extends StatefulWidget {
  final LibrarySort currentSort;
  final bool sortAsc;
  final LibraryFilter currentFilter;
  final String? genreFilter;
  final List<String> availableGenres;
  final int initialTab;
  final ColorScheme cs;
  final TextTheme tt;
  final void Function(LibrarySort) onSortChanged;
  final VoidCallback onSortDirectionToggled;
  final void Function(LibraryFilter, {String? genre}) onFilterChanged;
  final VoidCallback onClearFilter;
  final bool collapseSeries;
  final ValueChanged<bool> onCollapseSeriesChanged;
  final bool isPodcastLibrary;
  final LibraryTab libraryTab;
  final VoidCallback? onUpcomingReleases;

  const SortFilterSheet({
    super.key,
    required this.currentSort, required this.sortAsc,
    required this.currentFilter, this.genreFilter,
    required this.availableGenres, required this.initialTab,
    required this.cs, required this.tt,
    required this.onSortChanged, required this.onSortDirectionToggled,
    required this.onFilterChanged, required this.onClearFilter,
    this.collapseSeries = false, required this.onCollapseSeriesChanged,
    required this.isPodcastLibrary,
    this.libraryTab = LibraryTab.library,
    this.onUpcomingReleases,
  });

  @override
  State<SortFilterSheet> createState() => _SortFilterSheetState();
}

class _SortFilterSheetState extends State<SortFilterSheet> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  bool _genreExpanded = false;
  late bool _collapseSeries;

  bool get _showFilterTab => widget.libraryTab == LibraryTab.library && !widget.isPodcastLibrary;

  @override
  void initState() {
    super.initState();
    _collapseSeries = widget.collapseSeries;
    final tabCount = _showFilterTab ? 2 : 1;
    _tabCtrl = TabController(
      length: tabCount, vsync: this,
      initialIndex: _showFilterTab ? widget.initialTab.clamp(0, 1) : 0,
    );
    if (widget.currentFilter == LibraryFilter.genre) _genreExpanded = true;
  }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final cs = widget.cs;
    final l = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Center(child: Container(width: 40, height: 4,
            decoration: BoxDecoration(color: cs.onSurfaceVariant.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          if (_showFilterTab)
            TabBar(
              controller: _tabCtrl,
              labelColor: cs.primary, unselectedLabelColor: cs.onSurfaceVariant,
              indicatorColor: cs.primary, indicatorSize: TabBarIndicatorSize.label,
              dividerColor: Colors.transparent,
              tabs: [
                Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.sort_rounded, size: 18), const SizedBox(width: 6), Text(l.sort)])),
                Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.filter_list_rounded, size: 18), const SizedBox(width: 6),
                  Text(widget.currentFilter != LibraryFilter.none ? l.filterActive : l.filter)])),
              ],
            )
          else
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(l.sort, style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, color: cs.primary)),
            ),
          SizedBox(
            height: _calcHeight(),
            child: _showFilterTab
                ? TabBarView(controller: _tabCtrl, children: [
                    _buildSortTab(cs, l), _buildFilterTab(cs, l)])
                : _buildSortTab(cs, l),
          ),
          SizedBox(height: MediaQuery.of(context).viewPadding.bottom + 8),
        ],
      ),
    );
  }

  double _calcHeight() {
    if (widget.libraryTab == LibraryTab.series) return widget.onUpcomingReleases != null ? 330 : 230;
    if (widget.libraryTab == LibraryTab.authors) return 180;
    if (widget.libraryTab == LibraryTab.narrators) return 130;
    return _genreExpanded ? 420 : (widget.isPodcastLibrary ? 200 : 400);
  }

  Widget _buildSortTab(ColorScheme cs, AppLocalizations l) {
    final sorts = _getSortOptions(l);
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        ...sorts.map((s) {
          final (sort, label, icon) = s;
          final selected = sort == widget.currentSort;
          return SheetOption(
            icon: icon, label: label, selected: selected, selectedColor: cs.primary,
            trailing: selected && sort != LibrarySort.random
                ? GestureDetector(
                    onTap: widget.onSortDirectionToggled,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: cs.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(widget.sortAsc ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, size: 14, color: cs.primary),
                        const SizedBox(width: 4),
                        Text(widget.sortAsc ? l.asc : l.desc, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cs.primary)),
                      ]),
                    ),
                  ) : null,
            onTap: () => widget.onSortChanged(sort),
          );
        }),
        if (widget.libraryTab == LibraryTab.library && !widget.isPodcastLibrary)
          GestureDetector(
            onTap: () {
              setState(() => _collapseSeries = !_collapseSeries);
              widget.onCollapseSeriesChanged(_collapseSeries);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                color: _collapseSeries ? cs.secondary.withValues(alpha: 0.12) : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(children: [
                Icon(Icons.auto_stories_rounded, size: 20,
                  color: _collapseSeries ? cs.secondary : cs.onSurfaceVariant),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(l.collapseSeries, style: TextStyle(
                    fontSize: 14,
                    fontWeight: _collapseSeries ? FontWeight.w600 : FontWeight.w400,
                    color: _collapseSeries ? cs.secondary : cs.onSurface)),
                ),
                Switch(
                  value: _collapseSeries,
                  onChanged: (v) {
                    setState(() => _collapseSeries = v);
                    widget.onCollapseSeriesChanged(v);
                  },
                  activeThumbColor: cs.secondary,
                ),
              ]),
            ),
          ),
        if (widget.libraryTab == LibraryTab.series && widget.onUpcomingReleases != null) ...[
          const Divider(height: 24),
          GestureDetector(
            onTap: widget.onUpcomingReleases,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: cs.primary.withValues(alpha: 0.15)),
              ),
              child: Row(children: [
                Icon(Icons.calendar_month_rounded, size: 20, color: cs.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.librarySortFilterUpcomingReleases, style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600, color: cs.primary)),
                      Text(l.librarySortFilterUpcomingReleasesSubtitle, style: TextStyle(
                        fontSize: 11, color: cs.onSurfaceVariant)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, size: 20, color: cs.primary),
              ]),
            ),
          ),
        ],
      ],
    );
  }

  List<(LibrarySort, String, IconData)> _getSortOptions(AppLocalizations l) {
    switch (widget.libraryTab) {
      case LibraryTab.series:
        return [
          (LibrarySort.alphabetical, l.name, Icons.sort_by_alpha_rounded),
          (LibrarySort.recentlyAdded, l.dateAdded, Icons.schedule_rounded),
          (LibrarySort.totalDuration, l.numberOfBooks, Icons.auto_stories_rounded),
        ];
      case LibraryTab.authors:
        return [
          (LibrarySort.alphabetical, l.name, Icons.sort_by_alpha_rounded),
          (LibrarySort.totalDuration, l.numberOfBooks, Icons.auto_stories_rounded),
        ];
      case LibraryTab.narrators:
        return [
          (LibrarySort.alphabetical, l.name, Icons.sort_by_alpha_rounded),
        ];
      case LibraryTab.library:
        if (widget.isPodcastLibrary) {
          return [
            (LibrarySort.recentlyAdded, l.dateAdded, Icons.schedule_rounded),
            (LibrarySort.alphabetical, l.title, Icons.sort_by_alpha_rounded),
            (LibrarySort.random, l.random, Icons.shuffle_rounded),
          ];
        }
        return [
          (LibrarySort.recentlyAdded, l.dateAdded, Icons.schedule_rounded),
          (LibrarySort.alphabetical, l.title, Icons.sort_by_alpha_rounded),
          (LibrarySort.authorName, l.author, Icons.person_rounded),
          (LibrarySort.publishedYear, l.publishedYear, Icons.calendar_today_rounded),
          (LibrarySort.duration, l.duration, Icons.timelapse_rounded),
          (LibrarySort.random, l.random, Icons.shuffle_rounded),
        ];
    }
  }

  Widget _buildFilterTab(ColorScheme cs, AppLocalizations l) {
    final filters = <(LibraryFilter, String, IconData)>[
      (LibraryFilter.inProgress, l.inProgress, Icons.play_circle_outline_rounded),
      (LibraryFilter.finished, l.filterFinished, Icons.check_circle_outline_rounded),
      (LibraryFilter.notStarted, l.notStarted, Icons.circle_outlined),
      (LibraryFilter.downloaded, l.downloaded, Icons.download_done_rounded),
      (LibraryFilter.hasEbook, l.hasEbook, Icons.menu_book_rounded),
    ];
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        if (widget.currentFilter != LibraryFilter.none)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: widget.onClearFilter,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(color: cs.errorContainer.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(14)),
                child: Row(children: [
                  Icon(Icons.clear_rounded, size: 18, color: cs.error),
                  const SizedBox(width: 10),
                  Text(l.clearFilter, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.error)),
                ]),
              ),
            ),
          ),
        ...filters.map((f) {
          final (filter, label, icon) = f;
          return SheetOption(
            icon: icon, label: label,
            selected: filter == widget.currentFilter, selectedColor: cs.tertiary,
            onTap: () => widget.onFilterChanged(filter),
          );
        }),
        SheetOption(
          icon: Icons.category_rounded,
          label: l.genre,
          selected: widget.currentFilter == LibraryFilter.genre,
          selectedColor: cs.tertiary,
          trailing: Icon(_genreExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded, size: 20, color: cs.onSurfaceVariant),
          onTap: () => setState(() => _genreExpanded = !_genreExpanded),
        ),
        if (_genreExpanded)
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: widget.availableGenres.isEmpty
                ? Padding(padding: const EdgeInsets.all(12),
                    child: Text(l.noGenresFound, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)))
                : Column(children: widget.availableGenres.map((genre) {
                    final selected = widget.currentFilter == LibraryFilter.genre && widget.genreFilter == genre;
                    return SheetOption(
                      icon: Icons.label_outline_rounded, label: genre,
                      selected: selected, selectedColor: cs.tertiary,
                      compact: true, marquee: true,
                      onTap: () => widget.onFilterChanged(LibraryFilter.genre, genre: genre),
                    );
                  }).toList()),
          ),
      ],
    );
  }
}

class SheetOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final Color selectedColor;
  final Widget? trailing;
  final VoidCallback onTap;
  final bool compact;
  final bool marquee;

  const SheetOption({
    super.key,
    required this.icon, required this.label, required this.selected,
    required this.selectedColor, this.trailing, required this.onTap,
    this.compact = false, this.marquee = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final vPad = compact ? 8.0 : 10.0;
    final fontSize = compact ? 13.0 : 14.0;
    final iconSize = compact ? 18.0 : 20.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: vPad),
        margin: EdgeInsets.only(bottom: compact ? 2 : 4),
        decoration: BoxDecoration(
          color: selected ? selectedColor.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(children: [
          Icon(icon, size: iconSize, color: selected ? selectedColor : cs.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: marquee
                ? MarqueeText(text: label, style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    color: selected ? selectedColor : cs.onSurface))
                : Text(label, style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    color: selected ? selectedColor : cs.onSurface)),
          ),
          if (trailing != null) trailing!,
          if (selected && trailing == null)
            Icon(Icons.check_rounded, size: 18, color: selectedColor),
        ]),
      ),
    );
  }
}

class MarqueeText extends StatefulWidget {
  final String text;
  final TextStyle style;
  const MarqueeText({super.key, required this.text, required this.style});
  @override
  State<MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<MarqueeText> {
  late final ScrollController _sc;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _sc = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAndScroll());
  }

  void _checkAndScroll() {
    if (!_sc.hasClients || _sc.position.maxScrollExtent <= 0) return;
    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 1), () {
      if (!mounted || !_sc.hasClients) return;
      final max = _sc.position.maxScrollExtent;
      _sc.animateTo(max, duration: Duration(milliseconds: (max * 30).round().clamp(1000, 5000)), curve: Curves.linear).then((_) {
        if (!mounted) return;
        Future.delayed(const Duration(seconds: 1), () {
          if (!mounted || !_sc.hasClients) return;
          _sc.animateTo(0, duration: const Duration(milliseconds: 500), curve: Curves.easeOut).then((_) {
            if (mounted) _checkAndScroll();
          });
        });
      });
    });
  }

  @override
  void dispose() { _timer?.cancel(); _sc.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _sc, scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      child: Text(widget.text, style: widget.style, maxLines: 1),
    );
  }
}
