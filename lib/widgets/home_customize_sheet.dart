import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/library_provider.dart';
import 'section_labels.dart';

class HomeCustomizeSheet extends StatefulWidget {
  final ScrollController? scrollController;

  const HomeCustomizeSheet({super.key, this.scrollController});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return GestureDetector(
          onTap: () => Navigator.pop(context),
          behavior: HitTestBehavior.opaque,
          child: DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.3,
            maxChildSize: 0.85,
            builder: (context, scrollController) {
              return GestureDetector(
                onTap: () {}, // absorb taps on the sheet itself
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).bottomSheetTheme.backgroundColor ??
                        Theme.of(context).colorScheme.surface,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: HomeCustomizeSheet(scrollController: scrollController),
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  State<HomeCustomizeSheet> createState() => _HomeCustomizeSheetState();
}

class _HomeCustomizeSheetState extends State<HomeCustomizeSheet> {
  late List<Map<String, String>> _sections;
  late Set<String> _hiddenIds;
  bool _initialized = false;

  static const _sectionIcons = {
    'continue-listening': Icons.play_circle_outline_rounded,
    'continue-series': Icons.auto_stories_rounded,
    'recently-added': Icons.new_releases_outlined,
    'listen-again': Icons.replay_rounded,
    'discover': Icons.explore_outlined,
    'episodes-recently-added': Icons.podcasts_rounded,
    'downloaded-books': Icons.download_done_rounded,
  };

  void _initSections(LibraryProvider lib) {
    if (_initialized) return;
    _initialized = true;

    final allMeta = lib.getAllSectionMeta();
    final order = lib.sectionOrder;
    _hiddenIds = Set<String>.from(lib.hiddenSectionIds);

    if (order.isNotEmpty) {
      final ordered = <Map<String, String>>[];
      for (final id in order) {
        final meta = allMeta.where((m) => m['id'] == id).firstOrNull;
        if (meta != null) ordered.add(meta);
      }
      for (final meta in allMeta) {
        if (!order.contains(meta['id'])) ordered.add(meta);
      }
      _sections = ordered;
    } else {
      _sections = allMeta;
    }
  }

  void _reset(LibraryProvider lib) {
    setState(() {
      _sections = lib.getAllSectionMeta();
      _hiddenIds = {};
    });
  }

  Future<void> _showAddGenre(BuildContext context, LibraryProvider lib, ColorScheme cs, TextTheme tt) async {
    final api = context.read<AuthProvider>().apiService;
    final libraryId = lib.selectedLibraryId;
    if (api == null || libraryId == null) return;

    final filterData = await api.getLibraryFilterData(libraryId);
    if (filterData == null || !context.mounted) return;

    final genres = (filterData['genres'] as List<dynamic>? ?? [])
        .map((g) => g is Map ? (g['name'] as String? ?? '') : g.toString())
        .where((g) => g.isNotEmpty)
        .toList()
      ..sort();

    final alreadyAdded = lib.addedGenres;

    if (!context.mounted) return;
    final l = AppLocalizations.of(context)!;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        expand: false,
        builder: (ctx, sc) => Column(children: [
          const SizedBox(height: 8),
          Center(child: Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: cs.onSurface.withValues(alpha: 0.24),
              borderRadius: BorderRadius.circular(2),
            ),
          )),
          const SizedBox(height: 16),
          Text(l.homeCustomizeAddGenreTitle, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(l.homeCustomizeAddGenreSubtitle,
            style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: 12),
          Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.3), indent: 20, endIndent: 20),
          Expanded(
            child: genres.isEmpty
                ? ListView(controller: sc, children: [
                    const SizedBox(height: 60),
                    Center(child: Text(l.noGenresFound, style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant))),
                  ])
                : ListView.builder(
                    controller: sc,
                    padding: EdgeInsets.only(top: 8, bottom: MediaQuery.of(ctx).padding.bottom + 8),
                    itemCount: genres.length,
                    itemBuilder: (ctx, i) {
                      final genre = genres[i];
                      final added = alreadyAdded.contains(genre);
                      return ListTile(
                        dense: true,
                        leading: Icon(Icons.label_outline_rounded, size: 18, color: cs.onSurfaceVariant),
                        title: Text(genre, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                        trailing: added
                            ? Icon(Icons.check_rounded, size: 18, color: cs.primary)
                            : null,
                        onTap: added ? null : () async {
                          await lib.addGenreSection(genre);
                          _initialized = false; // force re-init to pick up the new section
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (mounted) setState(() {});
                        },
                      );
                    },
                  ),
          ),
        ]),
      ),
    );
  }

  Future<void> _removeGenre(String genre, LibraryProvider lib) async {
    await lib.removeGenreSection(genre);
    setState(() {
      final sectionId = 'genre:$genre';
      _sections.removeWhere((s) => s['id'] == sectionId);
      _hiddenIds.remove(sectionId);
    });
  }

  Future<void> _save(LibraryProvider lib) async {
    await lib.saveSectionOrder(_sections.map((s) => s['id']!).toList());
    // Sync hidden state: apply our local set to the provider
    final currentHidden = lib.hiddenSectionIds;
    // Unhide anything we removed
    for (final id in currentHidden) {
      if (!_hiddenIds.contains(id)) {
        await lib.toggleSectionVisibility(id);
      }
    }
    // Hide anything we added
    for (final id in _hiddenIds) {
      if (!lib.hiddenSectionIds.contains(id)) {
        await lib.toggleSectionVisibility(id);
      }
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final lib = context.read<LibraryProvider>();
    final l = AppLocalizations.of(context)!;

    _initSections(lib);

    return Column(children: [
      // Grab handle + header
      const SizedBox(height: 8),
      Center(child: Container(
        width: 40, height: 4,
        decoration: BoxDecoration(
          color: cs.onSurface.withValues(alpha: 0.24),
          borderRadius: BorderRadius.circular(2),
        ),
      )),
      const SizedBox(height: 16),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(children: [
          GestureDetector(
            onTap: () => _reset(lib),
            child: Text(l.reset, style: tt.labelMedium?.copyWith(
              color: cs.primary, fontWeight: FontWeight.w500,
            )),
          ),
          const Spacer(),
          Text(l.customizeHome, style: tt.titleMedium?.copyWith(
            fontWeight: FontWeight.w600, color: cs.onSurface,
          )),
          const Spacer(),
          GestureDetector(
            onTap: () => _showAddGenre(context, lib, cs, tt),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Icon(Icons.add_rounded, size: 24, color: cs.primary),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => _save(lib),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: Text(l.done, style: tt.labelLarge?.copyWith(
                color: cs.primary, fontWeight: FontWeight.w600,
              )),
            ),
          ),
        ]),
      ),
      const SizedBox(height: 4),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Text(
          l.dragToReorderTapEye,
          style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
      ),
      const SizedBox(height: 12),
      Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.3),
        indent: 20, endIndent: 20),
      // Reorderable list
      Expanded(
        child: ReorderableListView.builder(
          scrollController: widget.scrollController,
          padding: EdgeInsets.only(top: 8, bottom: MediaQuery.of(context).padding.bottom + 8),
          itemCount: _sections.length,
          onReorderStart: (_) => HapticFeedback.mediumImpact(),
          onReorder: (oldIndex, newIndex) {
            setState(() {
              if (newIndex > oldIndex) newIndex--;
              final item = _sections.removeAt(oldIndex);
              _sections.insert(newIndex, item);
            });
          },
          itemBuilder: (context, index) {
            final section = _sections[index];
            final id = section['id']!;
            final label = sectionLabel(id, section['label'], l);
            final isHidden = _hiddenIds.contains(id);
            final isPlaylist = id.startsWith('playlist:');
            final isCollection = id.startsWith('collection:');
            final isGenre = id.startsWith('genre:');
            final icon = isPlaylist
                ? Icons.playlist_play_rounded
                : isCollection
                    ? Icons.collections_bookmark_rounded
                    : isGenre
                        ? Icons.label_outline_rounded
                        : (_sectionIcons[id] ?? Icons.album_outlined);

            return Container(
              key: ValueKey(id),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: isHidden ? 0.02 : 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.onSurface.withValues(alpha: 0.08)),
              ),
              child: ListTile(
                dense: true,
                leading: Icon(icon, size: 18,
                  color: isHidden
                      ? cs.onSurfaceVariant.withValues(alpha: 0.3)
                      : cs.onSurfaceVariant),
                title: Text(label, style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w500,
                  color: isHidden
                      ? cs.onSurface.withValues(alpha: 0.35)
                      : cs.onSurface,
                )),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  if (isGenre)
                    GestureDetector(
                      onTap: () => _removeGenre(id.substring(6), lib),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Icon(Icons.remove_circle_outline_rounded, size: 18,
                          color: Colors.red.withValues(alpha: 0.6)),
                      ),
                    ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        if (_hiddenIds.contains(id)) {
                          _hiddenIds.remove(id);
                        } else {
                          _hiddenIds.add(id);
                        }
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        isHidden ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                        size: 18,
                        color: isHidden
                            ? cs.onSurfaceVariant.withValues(alpha: 0.3)
                            : cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                  ReorderableDragStartListener(
                    index: index,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(Icons.drag_handle_rounded, size: 18,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
                    ),
                  ),
                ]),
              ),
            );
          },
        ),
      ),
    ]);
  }
}

