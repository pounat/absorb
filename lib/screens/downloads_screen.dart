import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/library_provider.dart';
import '../services/audio_player_service.dart';
import '../services/download_service.dart';
import '../widgets/absorb_page_header.dart';
import '../widgets/overlay_toast.dart';
import '../l10n/app_localizations.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});
  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  bool _loading = true;
  List<DownloadInfo> _items = [];
  Map<String, int> _fileSizes = {};
  bool _selecting = false;
  final Set<String> _selected = {};
  bool _mergeLibraries = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = DownloadService().downloadedItems;
    final sizes = <String, int>{};
    for (final item in items) {
      sizes[item.itemId] = DownloadService().getItemFileSize(item.itemId);
    }
    final merge = await PlayerSettings.getMergeAbsorbingLibraries();
    if (mounted) {
      setState(() {
        _items = items;
        _fileSizes = sizes;
        _mergeLibraries = merge;
        _loading = false;
      });
    }
  }

  void _toggleSelect(String itemId) {
    setState(() {
      if (_selected.contains(itemId)) {
        _selected.remove(itemId);
        if (_selected.isEmpty) _selecting = false;
      } else {
        _selected.add(itemId);
      }
    });
  }

  void _enterSelection(String itemId) {
    setState(() {
      _selecting = true;
      _selected.add(itemId);
    });
  }

  void _exitSelection() {
    setState(() {
      _selecting = false;
      _selected.clear();
    });
  }

  /// The completed downloads currently visible, honoring the same library
  /// filter as the list - select-all must never grab hidden items or a bulk
  /// delete would remove downloads the user can't see.
  List<DownloadInfo> _visibleCompleted() {
    final lib = context.read<LibraryProvider>();
    final activeLibId = lib.selectedLibraryId;
    final shouldFilter = !lib.isOffline && !_mergeLibraries && activeLibId != null;
    final completed = DownloadService().downloadedItems;
    if (!shouldFilter) return completed;
    return completed
        .where((d) => d.libraryId == null || d.libraryId == activeLibId)
        .toList();
  }

  void _toggleSelectAll() {
    final visible = _visibleCompleted().map((d) => d.itemId).toList();
    setState(() {
      final allSelected =
          visible.isNotEmpty && visible.every(_selected.contains);
      _selected.clear();
      if (!allSelected) _selected.addAll(visible);
    });
  }

  Future<void> _deleteSelected() async {
    if (_selected.isEmpty) return;

    final l = AppLocalizations.of(context)!;
    final count = _selected.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.delete_outline_rounded),
        title: Text(l.downloadsDeleteCount(count)),
        content: Text(l.downloadsDeleteContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.delete),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    for (final itemId in _selected.toList()) {
      await DownloadService().deleteDownload(itemId);
    }

    _exitSelection();
    await _load();

    if (mounted) {
      showOverlayToast(context, l.downloadsDeletedCount(count),
          icon: Icons.delete_outline_rounded);
    }
  }

  Future<void> _deleteSingle(DownloadInfo info) async {
    final l = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.delete_outline_rounded),
        title: Text(l.downloadsRemoveTitle),
        content: Text(l.downloadsRemoveContent(info.title ?? '')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await DownloadService().deleteDownload(info.itemId);
    await _load();
    if (mounted) {
      showOverlayToast(context, l.downloadsRemovedTitle(info.title ?? ''),
          icon: Icons.delete_outline_rounded);
    }
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 8, 0),
                    child: Row(children: [
                      Expanded(
                        child: AbsorbPageHeader(
                          title: l.downloadsTitle,
                          padding: EdgeInsets.zero,
                        ),
                      ),
                      if (_selecting) ...[
                        IconButton(
                          icon: Icon(Icons.select_all_rounded,
                              color: cs.onSurfaceVariant),
                          tooltip: l.selectAll,
                          onPressed: _toggleSelectAll,
                        ),
                        IconButton(
                          icon: Icon(Icons.close_rounded,
                              color: cs.onSurfaceVariant),
                          tooltip: l.downloadsCancelSelection,
                          onPressed: _exitSelection,
                        ),
                      ] else ...[
                        if (_items.isNotEmpty)
                          IconButton(
                            icon: Icon(Icons.checklist_rounded,
                                color: cs.onSurfaceVariant),
                            tooltip: l.downloadsSelect,
                            onPressed: () =>
                                setState(() => _selecting = true),
                          ),
                        IconButton(
                          icon: Icon(Icons.close_rounded,
                              color: cs.onSurfaceVariant),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ]),
                  ),
                  const SizedBox(height: 12),

                  // Content
                  Expanded(
                    child: ListenableBuilder(
                      listenable: DownloadService(),
                      builder: (ctx, _) {
                        final ds = DownloadService();
                        final lib = context.watch<LibraryProvider>();
                        final activeLibId = lib.selectedLibraryId;
                        final shouldFilter = !lib.isOffline && !_mergeLibraries && activeLibId != null;

                        List<DownloadInfo> filterByLibrary(List<DownloadInfo> items) {
                          if (!shouldFilter) return items;
                          return items.where((d) => d.libraryId == null || d.libraryId == activeLibId).toList();
                        }

                        final active = filterByLibrary(ds.activeDownloads);
                        final queued = filterByLibrary(ds.queuedDownloads);
                        final completed = filterByLibrary(ds.downloadedItems);
                        final hasAny = active.isNotEmpty || queued.isNotEmpty || completed.isNotEmpty;

                        if (!hasAny) {
                          return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.download_done_rounded,
                                    size: 48,
                                    color: cs.onSurfaceVariant
                                        .withValues(alpha: 0.4)),
                                const SizedBox(height: 12),
                                Text(l.downloadsNoDownloads,
                                    style: tt.bodyLarge?.copyWith(
                                        color: cs.onSurfaceVariant)),
                              ],
                            ),
                          );
                        }

                        return ListView(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          children: [
                            // Active downloads
                            if (active.isNotEmpty) ...[
                              Padding(
                                padding: const EdgeInsets.only(left: 4, bottom: 8),
                                child: Text(l.downloadsDownloading,
                                    style: tt.labelMedium?.copyWith(
                                        color: cs.primary,
                                        fontWeight: FontWeight.w600)),
                              ),
                              for (final info in active)
                                _ActiveDownloadCard(
                                  info: info,
                                  cs: cs,
                                  tt: tt,
                                  onCancel: () => ds.cancelDownload(info.itemId),
                                  mediaHeaders: context.read<LibraryProvider>().mediaHeaders,
                                ),
                            ],
                            // Queued downloads
                            if (queued.isNotEmpty) ...[
                              Padding(
                                padding: const EdgeInsets.only(left: 4, top: 4, bottom: 8),
                                child: Text(l.downloadsQueued,
                                    style: tt.labelMedium?.copyWith(
                                        color: cs.onSurfaceVariant,
                                        fontWeight: FontWeight.w600)),
                              ),
                              for (final info in queued)
                                _ActiveDownloadCard(
                                  info: info,
                                  cs: cs,
                                  tt: tt,
                                  isQueued: true,
                                  onCancel: () => ds.cancelDownload(info.itemId),
                                  mediaHeaders: context.read<LibraryProvider>().mediaHeaders,
                                ),
                            ],
                            // Completed downloads
                            if (completed.isNotEmpty) ...[
                              if (active.isNotEmpty || queued.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(left: 4, top: 4, bottom: 8),
                                  child: Text(l.downloadsCompleted,
                                      style: tt.labelMedium?.copyWith(
                                          color: cs.onSurfaceVariant,
                                          fontWeight: FontWeight.w600)),
                                ),
                              for (final info in completed)
                                _DownloadCard(
                                  info: info,
                                  fileSize: _fileSizes[info.itemId] ?? 0,
                                  cs: cs,
                                  tt: tt,
                                  selecting: _selecting,
                                  isSelected: _selected.contains(info.itemId),
                                  onToggle: () => _toggleSelect(info.itemId),
                                  onLongPress: () => _enterSelection(info.itemId),
                                  onDelete: () => _deleteSingle(info),
                                  formatBytes: _formatBytes,
                                  mediaHeaders: context.read<LibraryProvider>().mediaHeaders,
                                ),
                            ],
                          ],
                        );
                      },
                    ),
                  ),

                  // Bottom delete bar
                  if (_selecting && _selected.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHigh,
                        border: Border(
                          top: BorderSide(
                            color: cs.outlineVariant
                                .withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                      child: SafeArea(
                        top: false,
                        child: Row(children: [
                          Text(
                            l.downloadsSelectedCount(_selected.length),
                            style: tt.bodyMedium
                                ?.copyWith(color: cs.onSurface),
                          ),
                          const Spacer(),
                          FilledButton.tonalIcon(
                            icon: const Icon(
                                Icons.delete_outline_rounded,
                                size: 18),
                            label: Text(l.delete),
                            style: FilledButton.styleFrom(
                              backgroundColor: cs.errorContainer,
                              foregroundColor: cs.onErrorContainer,
                            ),
                            onPressed: _deleteSelected,
                          ),
                        ]),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

class _DownloadCard extends StatelessWidget {
  final DownloadInfo info;
  final int fileSize;
  final ColorScheme cs;
  final TextTheme tt;
  final bool selecting;
  final bool isSelected;
  final VoidCallback onToggle;
  final VoidCallback onLongPress;
  final VoidCallback onDelete;
  final String Function(int) formatBytes;
  final Map<String, String> mediaHeaders;

  const _DownloadCard({
    required this.info,
    required this.fileSize,
    required this.cs,
    required this.tt,
    required this.selecting,
    required this.isSelected,
    required this.onToggle,
    required this.onLongPress,
    required this.onDelete,
    required this.formatBytes,
    required this.mediaHeaders,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: selecting ? onToggle : null,
        onLongPress: !selecting ? onLongPress : null,
        child: Card(
          elevation: 0,
          color: cs.surfaceContainerHigh,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                if (selecting)
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Icon(
                      isSelected
                          ? Icons.check_circle_rounded
                          : Icons.circle_outlined,
                      size: 22,
                      color: isSelected
                          ? cs.primary
                          : cs.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                  ),
                // Cover art
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: _buildCover(),
                  ),
                ),
                const SizedBox(width: 12),
                // Title, author, size
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        info.title ?? l.unknown,
                        style: tt.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (info.author != null && info.author!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            info.author!,
                            style: tt.bodySmall
                                ?.copyWith(color: cs.onSurfaceVariant),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      if (fileSize > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            formatBytes(fileSize),
                            style: tt.labelSmall?.copyWith(
                              color:
                                  cs.onSurfaceVariant.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (!selecting)
                  IconButton(
                    icon: Icon(Icons.delete_outline_rounded,
                        color: cs.error, size: 22),
                    tooltip: l.delete,
                    onPressed: onDelete,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCover() {
    // Try local cover first (offline-safe)
    if (info.localCoverPath != null && info.localCoverPath!.isNotEmpty) {
      final file = File(info.localCoverPath!);
      if (file.existsSync()) {
        return Image.file(file,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _coverPlaceholder());
      }
    }

    // Try coverUrl via CachedNetworkImage
    if (info.coverUrl != null && info.coverUrl!.isNotEmpty) {
      if (info.coverUrl!.startsWith('/')) {
        final file = File(info.coverUrl!);
        if (file.existsSync()) {
          return Image.file(file,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _coverPlaceholder());
        }
        return _coverPlaceholder();
      }
      return CachedNetworkImage(
        imageUrl: info.coverUrl!,
        fit: BoxFit.cover,
        httpHeaders: mediaHeaders,
        placeholder: (_, __) => _coverPlaceholder(),
        errorWidget: (_, __, ___) => _coverPlaceholder(),
      );
    }

    return _coverPlaceholder();
  }

  Widget _coverPlaceholder() {
    return Container(
      color: cs.surfaceContainerHighest,
      child: Center(
        child: Icon(Icons.headphones_rounded,
            size: 24, color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
      ),
    );
  }
}

class _ActiveDownloadCard extends StatelessWidget {
  final DownloadInfo info;
  final ColorScheme cs;
  final TextTheme tt;
  final bool isQueued;
  final VoidCallback onCancel;
  final Map<String, String> mediaHeaders;

  const _ActiveDownloadCard({
    required this.info,
    required this.cs,
    required this.tt,
    this.isQueued = false,
    required this.onCancel,
    required this.mediaHeaders,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final progress = info.progress;
    final pct = (progress * 100).round();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        elevation: 0,
        color: cs.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Cover art
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: _buildCover(),
                ),
              ),
              const SizedBox(width: 12),
              // Title, status, progress
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      info.title ?? l.unknown,
                      style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (isQueued)
                      Text(l.downloadsWaiting,
                          style: tt.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant))
                    else ...[
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 6,
                                backgroundColor: cs.surfaceContainerHighest,
                                valueColor: AlwaysStoppedAnimation(cs.primary),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('$pct%',
                              style: tt.labelSmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: Icon(Icons.close_rounded,
                    color: cs.onSurfaceVariant, size: 20),
                tooltip: l.cancel,
                onPressed: onCancel,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCover() {
    if (info.coverUrl != null && info.coverUrl!.isNotEmpty) {
      if (info.coverUrl!.startsWith('/')) {
        final file = File(info.coverUrl!);
        if (file.existsSync()) {
          return Image.file(file,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _coverPlaceholder());
        }
        return _coverPlaceholder();
      }
      return CachedNetworkImage(
        imageUrl: info.coverUrl!,
        fit: BoxFit.cover,
        httpHeaders: mediaHeaders,
        placeholder: (_, __) => _coverPlaceholder(),
        errorWidget: (_, __, ___) => _coverPlaceholder(),
      );
    }
    return _coverPlaceholder();
  }

  Widget _coverPlaceholder() {
    return Container(
      color: cs.surfaceContainerHighest,
      child: Center(
        child: Icon(Icons.headphones_rounded,
            size: 24, color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
      ),
    );
  }
}
