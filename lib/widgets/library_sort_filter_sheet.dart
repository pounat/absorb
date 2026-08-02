import 'dart:async';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../screens/library_screen.dart';
import '../utils/app_platform.dart';

/// Which library tab the sort/filter sheet is being shown for.
enum LibraryTab { library, series, authors, narrators, lists }

// ═══════════════════════════════════════════════════════════════
// Sort & Filter bottom sheet with tabs
// ═══════════════════════════════════════════════════════════════
class SortFilterSheet extends StatefulWidget {
  final LibrarySort currentSort;
  final bool sortAsc;
  final LibraryFilter currentFilter;
  final String? genreFilter;
  final String? tagFilter;
  final String? filterValue;
  final MissingMetadataField? missingMetadataFilter;
  final List<String> availableGenres;
  final List<String> availableTags;
  final List<Map<String, String>> availableSeries;
  final List<Map<String, String>> availableAuthors;
  final List<String> availableNarrators;
  final List<String> availableLanguages;
  final List<String> availablePublishers;
  final List<String> availablePublishedDecades;
  final int initialTab;
  final ColorScheme cs;
  final TextTheme tt;
  final void Function(LibrarySort) onSortChanged;
  final VoidCallback onSortDirectionToggled;
  final void Function(
    LibraryFilter, {
    String? genre,
    String? tag,
    String? filterValue,
    String? filterValueLabel,
    MissingMetadataField? missingMetadata,
  }) onFilterChanged;
  final VoidCallback onClearFilter;
  final bool collapseSeries;
  final ValueChanged<bool> onCollapseSeriesChanged;
  final bool isPodcastLibrary;
  final bool canAccessExplicitContent;
  final LibraryTab libraryTab;
  final VoidCallback? onUpcomingReleases;
  /// Series-tab progress filter (computed client-side). Optional so other
  /// callers don't have to pass it; null = no filter active.
  final SeriesFilter currentSeriesFilter;
  final void Function(SeriesFilter)? onSeriesFilterChanged;

  const SortFilterSheet({
    super.key,
    required this.currentSort, required this.sortAsc,
    required this.currentFilter, this.genreFilter, this.tagFilter,
    this.filterValue,
    this.missingMetadataFilter,
    required this.availableGenres, this.availableTags = const [],
    this.availableSeries = const [],
    this.availableAuthors = const [],
    this.availableNarrators = const [],
    this.availableLanguages = const [],
    this.availablePublishers = const [],
    this.availablePublishedDecades = const [],
    required this.initialTab,
    required this.cs, required this.tt,
    required this.onSortChanged, required this.onSortDirectionToggled,
    required this.onFilterChanged, required this.onClearFilter,
    this.collapseSeries = false, required this.onCollapseSeriesChanged,
    required this.isPodcastLibrary,
    this.canAccessExplicitContent = false,
    this.libraryTab = LibraryTab.library,
    this.onUpcomingReleases,
    this.currentSeriesFilter = SeriesFilter.none,
    this.onSeriesFilterChanged,
  });

  @override
  State<SortFilterSheet> createState() => _SortFilterSheetState();
}

class _SortFilterSheetState extends State<SortFilterSheet> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  bool _genreExpanded = false;
  bool _tagExpanded = false;
  bool _missingMetadataExpanded = false;
  bool _seriesExpanded = false;
  bool _authorExpanded = false;
  bool _narratorExpanded = false;
  bool _languageExpanded = false;
  bool _publisherExpanded = false;
  bool _publishedDecadeExpanded = false;
  late bool _collapseSeries;

  bool get _showFilterTab =>
      widget.libraryTab == LibraryTab.library ||
      (widget.libraryTab == LibraryTab.series &&
          widget.onSeriesFilterChanged != null);

  bool get _anyFilterActive =>
      widget.currentFilter != LibraryFilter.none ||
      widget.currentSeriesFilter != SeriesFilter.none;

  @override
  void initState() {
    super.initState();
    _collapseSeries = widget.collapseSeries;
    final tabCount = 1 + (_showFilterTab ? 1 : 0);
    _tabCtrl = TabController(
      length: tabCount, vsync: this,
      initialIndex: widget.initialTab.clamp(0, tabCount - 1),
    );
    // Rebuild on tab swipe so the sheet height (which depends on the active
    // tab for the series tab's filter view) stays correct.
    _tabCtrl.addListener(() {
      if (mounted) setState(() {});
    });
    if (widget.currentFilter == LibraryFilter.genre) _genreExpanded = true;
    if (widget.currentFilter == LibraryFilter.tag) _tagExpanded = true;
    if (widget.currentFilter == LibraryFilter.missingMetadata) {
      _missingMetadataExpanded = true;
    }
    if (widget.currentFilter == LibraryFilter.series) _seriesExpanded = true;
    if (widget.currentFilter == LibraryFilter.author) _authorExpanded = true;
    if (widget.currentFilter == LibraryFilter.narrator) {
      _narratorExpanded = true;
    }
    if (widget.currentFilter == LibraryFilter.language) {
      _languageExpanded = true;
    }
    if (widget.currentFilter == LibraryFilter.publisher) {
      _publisherExpanded = true;
    }
    if (widget.currentFilter == LibraryFilter.publishedDecade) {
      _publishedDecadeExpanded = true;
    }
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
          if (_tabCtrl.length > 1)
            TabBar(
              controller: _tabCtrl,
              labelColor: cs.primary, unselectedLabelColor: cs.onSurfaceVariant,
              indicatorColor: cs.primary, indicatorSize: TabBarIndicatorSize.label,
              dividerColor: Colors.transparent,
              tabs: _buildTabs(l),
            )
          else
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(l.sort, style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, color: cs.primary)),
            ),
          SizedBox(
            height: _calcHeight(),
            child: _tabCtrl.length > 1
                ? TabBarView(controller: _tabCtrl, children: _buildViews(cs, l))
                : _buildSortTab(cs, l),
          ),
          SizedBox(height: MediaQuery.of(context).viewPadding.bottom + 8),
        ],
      ),
    );
  }

  List<Widget> _buildTabs(AppLocalizations l) => [
    Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.sort_rounded, size: 18), const SizedBox(width: 6), Text(l.sort)])),
    if (_showFilterTab)
      Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.filter_list_rounded, size: 18), const SizedBox(width: 6),
        Text(_anyFilterActive ? l.filterActive : l.filter)])),
  ];

  List<Widget> _buildViews(ColorScheme cs, AppLocalizations l) => [
    _buildSortTab(cs, l),
    if (_showFilterTab) _buildFilterTab(cs, l),
  ];

  double _calcHeight() {
    if (widget.libraryTab == LibraryTab.series) {
      // Need extra room when the filter tab is showing on series.
      if (_showFilterTab && _tabCtrl.index == 1) return 280;
      return widget.onUpcomingReleases != null ? 330 : 230;
    }
    if (widget.libraryTab == LibraryTab.authors) return 180;
    if (widget.libraryTab == LibraryTab.narrators) return 130;
    if (widget.libraryTab == LibraryTab.lists) return 230;
    if (_genreExpanded ||
        _tagExpanded ||
        _missingMetadataExpanded ||
        _seriesExpanded ||
        _authorExpanded ||
        _narratorExpanded ||
        _languageExpanded ||
        _publisherExpanded ||
        _publishedDecadeExpanded) {
      return 420;
    }
    return 440;
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
      case LibraryTab.lists:
        return [
          (LibrarySort.alphabetical, l.name, Icons.sort_by_alpha_rounded),
          (LibrarySort.recentlyAdded, l.dateAdded, Icons.schedule_rounded),
          (LibrarySort.totalDuration, l.numberOfBooks, Icons.format_list_numbered_rounded),
        ];
      case LibraryTab.library:
        if (widget.isPodcastLibrary) {
          return [
            (LibrarySort.recentlyAdded, l.dateAdded, Icons.schedule_rounded),
            (LibrarySort.alphabetical, l.title, Icons.sort_by_alpha_rounded),
            (LibrarySort.authorName, l.author, Icons.person_rounded),
            (LibrarySort.episodeCount, l.episodeCount, Icons.podcasts_rounded),
            (LibrarySort.fileSize, l.fileSize, Icons.storage_rounded),
            (LibrarySort.fileCreated, l.fileCreated, Icons.event_rounded),
            (LibrarySort.lastModified, l.lastModified, Icons.update_rounded),
            (LibrarySort.random, l.random, Icons.shuffle_rounded),
          ];
        }
        final options = <(LibrarySort, String, IconData)>[
          (LibrarySort.recentlyAdded, l.dateAdded, Icons.schedule_rounded),
          (LibrarySort.alphabetical, l.title, Icons.sort_by_alpha_rounded),
          (LibrarySort.authorFirstLast, l.authorFirstLast, Icons.person_rounded),
          (LibrarySort.authorName, l.authorLastFirst, Icons.person_outline_rounded),
          (LibrarySort.publishedYear, l.publishedYear, Icons.calendar_today_rounded),
          (LibrarySort.duration, l.duration, Icons.timelapse_rounded),
          (LibrarySort.fileSize, l.fileSize, Icons.storage_rounded),
          (LibrarySort.lastUpdated, l.lastUpdated, Icons.sync_rounded),
          (LibrarySort.fileCreated, l.fileCreated, Icons.event_rounded),
          (LibrarySort.lastModified, l.lastModified, Icons.update_rounded),
          (LibrarySort.progress, l.progressSort, Icons.percent_rounded),
          (LibrarySort.dateStarted, l.dateStarted, Icons.play_arrow_rounded),
          (LibrarySort.dateFinished, l.dateFinished, Icons.done_all_rounded),
          (LibrarySort.random, l.random, Icons.shuffle_rounded),
        ];
        if (widget.currentFilter == LibraryFilter.series &&
            widget.filterValue != null &&
            widget.filterValue != 'no-series') {
          options.insert(
            options.length - 1,
            (LibrarySort.sequence, l.sequence, Icons.format_list_numbered_rounded),
          );
        }
        return options;
    }
  }

  Widget _buildFilterTab(ColorScheme cs, AppLocalizations l) {
    if (widget.libraryTab == LibraryTab.series) {
      return _buildSeriesFilterTab(cs, l);
    }
    if (widget.isPodcastLibrary) {
      return _buildPodcastFilterTab(cs, l);
    }
    final filters = <(LibraryFilter, String, IconData)>[
      (LibraryFilter.notFinished, l.notFinished, Icons.pending_outlined),
      (LibraryFilter.inProgress, l.inProgress, Icons.play_circle_outline_rounded),
      (LibraryFilter.finished, l.filterFinished, Icons.check_circle_outline_rounded),
      (LibraryFilter.notStarted, l.notStarted, Icons.circle_outlined),
      if (!AppPlatform.isWeb)
        (LibraryFilter.downloaded, l.downloaded, Icons.download_done_rounded),
      (LibraryFilter.hasEbook, l.hasEbook, Icons.menu_book_rounded),
      (LibraryFilter.noEbook, l.noEbook, Icons.menu_book_outlined),
      (
        LibraryFilter.hasSupplementaryEbook,
        l.hasSupplementaryEbook,
        Icons.library_add_check_rounded,
      ),
      (
        LibraryFilter.noSupplementaryEbook,
        l.noSupplementaryEbook,
        Icons.library_add_outlined,
      ),
      (LibraryFilter.noTracks, l.noTracks, Icons.music_off_rounded),
      (LibraryFilter.singleTrack, l.singleTrack, Icons.audiotrack_rounded),
      (LibraryFilter.multipleTracks, l.multipleTracks, Icons.queue_music_rounded),
      (LibraryFilter.abridged, l.abridged, Icons.content_cut_rounded),
      (LibraryFilter.issues, l.issues, Icons.warning_amber_rounded),
      (LibraryFilter.feedOpen, l.rssFeedOpen, Icons.rss_feed_rounded),
    ];
    if (widget.canAccessExplicitContent) {
      filters.add(
        (LibraryFilter.explicit, l.explicitContent, Icons.explicit_rounded),
      );
    }
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
        ..._buildSeriesFilterSection(cs, l),
        ..._buildNamedFilterSection(
          cs: cs,
          label: l.libraryTabAuthors,
          icon: Icons.person_rounded,
          filter: LibraryFilter.author,
          values: widget.availableAuthors,
          expanded: _authorExpanded,
          onToggle: () => setState(() => _authorExpanded = !_authorExpanded),
        ),
        ..._buildStringFilterSection(
          cs: cs,
          label: l.libraryTabNarrators,
          icon: Icons.record_voice_over_rounded,
          filter: LibraryFilter.narrator,
          values: widget.availableNarrators,
          expanded: _narratorExpanded,
          onToggle: () => setState(
            () => _narratorExpanded = !_narratorExpanded,
          ),
        ),
        ..._buildStringFilterSection(
          cs: cs,
          label: l.languageLabel,
          icon: Icons.language_rounded,
          filter: LibraryFilter.language,
          values: widget.availableLanguages,
          expanded: _languageExpanded,
          onToggle: () => setState(
            () => _languageExpanded = !_languageExpanded,
          ),
        ),
        ..._buildStringFilterSection(
          cs: cs,
          label: l.publisherLabel,
          icon: Icons.business_rounded,
          filter: LibraryFilter.publisher,
          values: widget.availablePublishers,
          expanded: _publisherExpanded,
          onToggle: () => setState(
            () => _publisherExpanded = !_publisherExpanded,
          ),
        ),
        ..._buildStringFilterSection(
          cs: cs,
          label: l.publishedDecade,
          icon: Icons.date_range_rounded,
          filter: LibraryFilter.publishedDecade,
          values: widget.availablePublishedDecades,
          expanded: _publishedDecadeExpanded,
          onToggle: () => setState(
            () => _publishedDecadeExpanded = !_publishedDecadeExpanded,
          ),
          valueLabel: (value) => '${value}s',
        ),
        SheetOption(
          icon: Icons.manage_search_rounded,
          label: l.missingMetadata,
          selected: widget.currentFilter == LibraryFilter.missingMetadata,
          selectedColor: cs.tertiary,
          trailing: Icon(
            _missingMetadataExpanded
                ? Icons.expand_less_rounded
                : Icons.expand_more_rounded,
            size: 20,
            color: cs.onSurfaceVariant,
          ),
          onTap: () => setState(
            () => _missingMetadataExpanded = !_missingMetadataExpanded,
          ),
        ),
        if (_missingMetadataExpanded)
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Column(
              children: MissingMetadataField.values.map((field) {
                final selected =
                    widget.currentFilter == LibraryFilter.missingMetadata &&
                    widget.missingMetadataFilter == field;
                return SheetOption(
                  icon: Icons.error_outline_rounded,
                  label: missingMetadataFieldLabel(l, field),
                  selected: selected,
                  selectedColor: cs.tertiary,
                  compact: true,
                  onTap: () => widget.onFilterChanged(
                    LibraryFilter.missingMetadata,
                    missingMetadata: field,
                  ),
                );
              }).toList(),
            ),
          ),
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
        SheetOption(
          icon: Icons.local_offer_rounded,
          label: l.tag,
          selected: widget.currentFilter == LibraryFilter.tag,
          selectedColor: cs.tertiary,
          trailing: Icon(_tagExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded, size: 20, color: cs.onSurfaceVariant),
          onTap: () => setState(() => _tagExpanded = !_tagExpanded),
        ),
        if (_tagExpanded)
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: widget.availableTags.isEmpty
                ? Padding(padding: const EdgeInsets.all(12),
                    child: Text(l.noTagsFound, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)))
                : Column(children: widget.availableTags.map((tag) {
                    final selected = widget.currentFilter == LibraryFilter.tag && widget.tagFilter == tag;
                    return SheetOption(
                      icon: Icons.local_offer_outlined, label: tag,
                      selected: selected, selectedColor: cs.tertiary,
                      compact: true, marquee: true,
                      onTap: () => widget.onFilterChanged(LibraryFilter.tag, tag: tag),
                    );
                  }).toList()),
          ),
      ],
    );
  }

  Widget _buildPodcastFilterTab(ColorScheme cs, AppLocalizations l) {
    final filters = <(LibraryFilter, String, IconData)>[
      (
        LibraryFilter.subscribed,
        l.episodeListSubscribedChip,
        Icons.notifications_active_outlined,
      ),
      (LibraryFilter.issues, l.issues, Icons.warning_amber_rounded),
      (LibraryFilter.feedOpen, l.rssFeedOpen, Icons.rss_feed_rounded),
    ];
    if (widget.canAccessExplicitContent) {
      filters.add(
        (LibraryFilter.explicit, l.explicitContent, Icons.explicit_rounded),
      );
    }
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        if (widget.currentFilter != LibraryFilter.none)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: widget.onClearFilter,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: cs.errorContainer.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(children: [
                  Icon(Icons.clear_rounded, size: 18, color: cs.error),
                  const SizedBox(width: 10),
                  Text(
                    l.clearFilter,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: cs.error,
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ...filters.map((f) {
          final (filter, label, icon) = f;
          return SheetOption(
            icon: icon,
            label: label,
            selected: filter == widget.currentFilter,
            selectedColor: cs.tertiary,
            onTap: () => widget.onFilterChanged(filter),
          );
        }),
        ..._buildStringFilterSection(
          cs: cs,
          label: l.genre,
          icon: Icons.category_rounded,
          optionIcon: Icons.label_outline_rounded,
          filter: LibraryFilter.genre,
          values: widget.availableGenres,
          expanded: _genreExpanded,
          onToggle: () => setState(() => _genreExpanded = !_genreExpanded),
          onSelected: (value, _) => widget.onFilterChanged(
            LibraryFilter.genre,
            genre: value,
          ),
        ),
        ..._buildStringFilterSection(
          cs: cs,
          label: l.tag,
          icon: Icons.local_offer_rounded,
          optionIcon: Icons.local_offer_outlined,
          filter: LibraryFilter.tag,
          values: widget.availableTags,
          expanded: _tagExpanded,
          onToggle: () => setState(() => _tagExpanded = !_tagExpanded),
          onSelected: (value, _) => widget.onFilterChanged(
            LibraryFilter.tag,
            tag: value,
          ),
        ),
        ..._buildStringFilterSection(
          cs: cs,
          label: l.languageLabel,
          icon: Icons.language_rounded,
          filter: LibraryFilter.language,
          values: widget.availableLanguages,
          expanded: _languageExpanded,
          onToggle: () => setState(
            () => _languageExpanded = !_languageExpanded,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildSeriesFilterSection(
    ColorScheme cs,
    AppLocalizations l,
  ) {
    final values = <Map<String, String>>[
      {'id': 'no-series', 'name': l.noSeries},
      ...widget.availableSeries,
    ];
    return [
      SheetOption(
        icon: Icons.auto_stories_rounded,
        label: l.libraryTabSeries,
        selected: widget.currentFilter == LibraryFilter.series,
        selectedColor: cs.tertiary,
        trailing: Icon(
          _seriesExpanded
              ? Icons.expand_less_rounded
              : Icons.expand_more_rounded,
          size: 20,
          color: cs.onSurfaceVariant,
        ),
        onTap: () => setState(() => _seriesExpanded = !_seriesExpanded),
      ),
      if (_seriesExpanded)
        Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Column(
            children: values.map((series) {
              final id = series['id']!;
              final name = series['name']!;
              final selected =
                  widget.currentFilter == LibraryFilter.series &&
                  widget.filterValue == id;
              return SheetOption(
                icon: Icons.book_outlined,
                label: name,
                selected: selected,
                selectedColor: cs.tertiary,
                compact: true,
                marquee: true,
                onTap: () => widget.onFilterChanged(
                  LibraryFilter.series,
                  filterValue: id,
                  filterValueLabel: name,
                ),
              );
            }).toList(),
          ),
        ),
    ];
  }

  List<Widget> _buildStringFilterSection({
    required ColorScheme cs,
    required String label,
    required IconData icon,
    required LibraryFilter filter,
    required List<String> values,
    required bool expanded,
    required VoidCallback onToggle,
    IconData optionIcon = Icons.label_outline_rounded,
    String Function(String)? valueLabel,
    void Function(String value, String label)? onSelected,
  }) {
    if (values.isEmpty) return const [];
    final displayLabel = valueLabel ?? (value) => value;
    return [
      SheetOption(
        icon: icon,
        label: label,
        selected: widget.currentFilter == filter,
        selectedColor: cs.tertiary,
        trailing: Icon(
          expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
          size: 20,
          color: cs.onSurfaceVariant,
        ),
        onTap: onToggle,
      ),
      if (expanded)
        Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Column(
            children: values.map((value) {
              final shown = displayLabel(value);
              final selected =
                  widget.currentFilter == filter &&
                  (filter == LibraryFilter.genre
                      ? widget.genreFilter == value
                      : filter == LibraryFilter.tag
                      ? widget.tagFilter == value
                      : widget.filterValue == value);
              return SheetOption(
                icon: optionIcon,
                label: shown,
                selected: selected,
                selectedColor: cs.tertiary,
                compact: true,
                marquee: true,
                onTap: () {
                  if (onSelected != null) {
                    onSelected(value, shown);
                  } else {
                    widget.onFilterChanged(
                      filter,
                      filterValue: value,
                      filterValueLabel: shown,
                    );
                  }
                },
              );
            }).toList(),
          ),
        ),
    ];
  }

  List<Widget> _buildNamedFilterSection({
    required ColorScheme cs,
    required String label,
    required IconData icon,
    required LibraryFilter filter,
    required List<Map<String, String>> values,
    required bool expanded,
    required VoidCallback onToggle,
  }) {
    if (values.isEmpty) return const [];
    return [
      SheetOption(
        icon: icon,
        label: label,
        selected: widget.currentFilter == filter,
        selectedColor: cs.tertiary,
        trailing: Icon(
          expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
          size: 20,
          color: cs.onSurfaceVariant,
        ),
        onTap: onToggle,
      ),
      if (expanded)
        Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Column(
            children: values.map((value) {
              final id = value['id']!;
              final name = value['name']!;
              final selected =
                  widget.currentFilter == filter &&
                  widget.filterValue == id;
              return SheetOption(
                icon: Icons.label_outline_rounded,
                label: name,
                selected: selected,
                selectedColor: cs.tertiary,
                compact: true,
                marquee: true,
                onTap: () => widget.onFilterChanged(
                  filter,
                  filterValue: id,
                  filterValueLabel: name,
                ),
              );
            }).toList(),
          ),
        ),
    ];
  }

  /// Series-tab filter UI. ABS doesn't expose progress filters on series
  /// server-side, so absorb computes these client-side from per-book
  /// progress (handled in library_screen.dart).
  Widget _buildSeriesFilterTab(ColorScheme cs, AppLocalizations l) {
    final filters = <(SeriesFilter, String, IconData)>[
      (SeriesFilter.notFinished, l.notFinished, Icons.pending_outlined),
      (SeriesFilter.inProgress, l.inProgress, Icons.play_circle_outline_rounded),
      (SeriesFilter.finished, l.filterFinished, Icons.check_circle_outline_rounded),
      (SeriesFilter.notStarted, l.notStarted, Icons.circle_outlined),
    ];
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        if (widget.currentSeriesFilter != SeriesFilter.none)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: () =>
                  widget.onSeriesFilterChanged?.call(SeriesFilter.none),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                    color: cs.errorContainer.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(14)),
                child: Row(children: [
                  Icon(Icons.clear_rounded, size: 18, color: cs.error),
                  const SizedBox(width: 10),
                  Text(l.clearFilter,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: cs.error)),
                ]),
              ),
            ),
          ),
        ...filters.map((f) {
          final (filter, label, icon) = f;
          return SheetOption(
            icon: icon,
            label: label,
            selected: filter == widget.currentSeriesFilter,
            selectedColor: cs.tertiary,
            onTap: () => widget.onSeriesFilterChanged?.call(filter),
          );
        }),
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
