import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../services/socket_service.dart';
import '../widgets/absorb_page_header.dart';
import '../widgets/delete_confirm_dialog.dart';
import '../widgets/overlay_toast.dart';

/// Admin cleanup screen: lists the items a library has flagged as "issues" -
/// missing (files removed from disk) or invalid (present but unparseable) - and
/// lets an admin delete the stale entries. Delete is the plain soft delete
/// (DELETE /api/items/:id, no hard flag), so it removes the Audiobookshelf entry
/// only and never touches files on disk. That's what makes it safe for the
/// staging-library workflow where the audio has already been moved elsewhere.
class AdminMissingItemsScreen extends StatefulWidget {
  final Map<String, dynamic> library;
  const AdminMissingItemsScreen({super.key, required this.library});

  @override
  State<AdminMissingItemsScreen> createState() => _AdminMissingItemsScreenState();
}

class _AdminMissingItemsScreenState extends State<AdminMissingItemsScreen> {
  bool _loading = true;
  List<dynamic> _items = [];
  final Set<String> _deleting = {};
  final Set<String> _selected = {};

  String get _libraryId => widget.library['id'] as String? ?? '';
  String get _libraryName => widget.library['name'] as String? ?? '';
  bool get _selecting => _selected.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _load();
    SocketService().addItemsChangedListener(_onItemsChanged);
  }

  @override
  void dispose() {
    SocketService().removeItemsChangedListener(_onItemsChanged);
    _liveRefreshDebounce?.cancel();
    super.dispose();
  }

  // A running scan can flag or clear items while this list is open.
  Timer? _liveRefreshDebounce;
  void _onItemsChanged() {
    if (!mounted) return;
    _liveRefreshDebounce?.cancel();
    _liveRefreshDebounce = Timer(const Duration(seconds: 2), () {
      if (mounted && _deleting.isEmpty) _load();
    });
  }

  Future<void> _load() async {
    final api = context.read<AuthProvider>().apiService;
    if (api == null) return;
    // Full-screen spinner only before the first result; live refreshes and
    // pull-to-refresh swap the list in place.
    if (_items.isEmpty) setState(() => _loading = true);
    final items = await api.getIssueItems(_libraryId);
    if (!mounted) return;
    setState(() {
      _items = items;
      _selected.removeWhere((id) => !items.any((it) => (it as Map)['id'] == id));
      _loading = false;
    });
  }

  void _msg(String s, {IconData? icon}) =>
      showOverlayToast(context, s, icon: icon);

  String _titleOf(Map<String, dynamic> item) =>
      ((item['media'] as Map?)?['metadata'] as Map?)?['title'] as String? ??
      AppLocalizations.of(context)!.unknown;

  String _authorOf(Map<String, dynamic> item) =>
      ((item['media'] as Map?)?['metadata'] as Map?)?['authorName'] as String? ?? '';

  void _toggle(String id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        _selected.add(id);
      }
    });
  }

  void _selectAll() {
    setState(() {
      _selected
        ..clear()
        ..addAll(_items.map((it) => (it as Map)['id'] as String? ?? '').where((id) => id.isNotEmpty));
    });
  }

  Future<void> _deleteOne(Map<String, dynamic> item) async {
    final l = AppLocalizations.of(context)!;
    final title = _titleOf(item);
    final choice = await _confirm(l.adminMissingDeleteTitle, l.adminMissingDeleteOneContent(title));
    if (choice == null || !mounted) return;
    final id = item['id'] as String? ?? '';
    if (id.isEmpty) return;
    final api = context.read<AuthProvider>().apiService;
    if (api == null) return;
    setState(() => _deleting.add(id));
    final status = await api.deleteLibraryItem(id, hard: choice.hardDelete);
    if (!mounted) return;
    setState(() => _deleting.remove(id));
    if (status == 200) {
      setState(() {
        _items.removeWhere((it) => (it as Map)['id'] == id);
        _selected.remove(id);
      });
      _msg(l.adminMissingRemovedOne(title), icon: Icons.delete_outline_rounded);
    } else if (status == 403) {
      _msg(l.deletePermissionRequired, icon: Icons.lock_outline_rounded);
    } else {
      _msg(l.adminMissingDeleteFailed, icon: Icons.error_outline_rounded);
    }
  }

  Future<void> _deleteSelected() async {
    if (_selected.isEmpty) return;
    final l = AppLocalizations.of(context)!;
    final count = _selected.length;
    final choice = await _confirm(l.adminMissingDeleteTitle, l.adminMissingDeleteManyContent(count));
    if (choice == null || !mounted) return;
    final api = context.read<AuthProvider>().apiService;
    if (api == null) return;
    final ids = Set<String>.from(_selected);
    setState(() {
      _deleting.addAll(ids);
      _selected.clear();
    });
    int deleted = 0;
    bool forbidden = false;
    for (final id in ids) {
      final status = await api.deleteLibraryItem(id, hard: choice.hardDelete);
      if (status == 200) {
        deleted++;
        _items.removeWhere((it) => (it as Map)['id'] == id);
      } else if (status == 403) {
        forbidden = true;
        break;
      }
    }
    if (!mounted) return;
    setState(() => _deleting.removeAll(ids));
    if (forbidden && deleted == 0) {
      _msg(l.deletePermissionRequired, icon: Icons.lock_outline_rounded);
    } else {
      _msg(l.adminMissingRemovedMany(deleted),
          icon: Icons.delete_outline_rounded);
    }
  }

  Future<DeleteChoice?> _confirm(String title, String content) =>
      showDeleteConfirmDialog(context, title: title, message: content);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 8, 0),
            child: Row(children: [
              IconButton(
                icon: Icon(Icons.arrow_back_rounded, color: cs.onSurfaceVariant),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(child: AbsorbPageHeader(title: l.adminMissingTitle, padding: EdgeInsets.zero)),
              if (_items.isNotEmpty)
                IconButton(
                  icon: Icon(Icons.checklist_rounded, color: _selecting ? cs.primary : cs.onSurface.withValues(alpha: 0.3), size: 22),
                  tooltip: l.adminPodcastsSelectMultipleTooltip,
                  onPressed: () => _selecting ? setState(_selected.clear) : _selectAll(),
                ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(l.adminMissingSubtitle(_libraryName), style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
            ),
          ),
          Expanded(child: _body(cs, tt, l)),
        ]),
      ),
    );
  }

  Widget _body(ColorScheme cs, TextTheme tt, AppLocalizations l) {
    if (_loading) return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    if (_items.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.check_circle_outline_rounded, size: 44, color: cs.onSurface.withValues(alpha: 0.12)),
          const SizedBox(height: 10),
          Text(l.adminMissingNone, style: tt.bodyMedium?.copyWith(color: cs.onSurface.withValues(alpha: 0.4))),
        ]),
      );
    }

    return Stack(children: [
      RefreshIndicator(
        onRefresh: _load,
        child: ListView.builder(
          padding: EdgeInsets.fromLTRB(16, 4, 16, _selecting ? 88 : 16),
          itemCount: _items.length,
          itemBuilder: (_, i) => _itemRow(_items[i] as Map<String, dynamic>, cs, tt, l),
        ),
      ),
      if (_selecting)
        Positioned(
          left: 16,
          right: 16,
          bottom: 16,
          child: Row(children: [
            GestureDetector(
              onTap: () => setState(_selected.clear),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: Icon(Icons.close_rounded, size: 20, color: cs.onSurface.withValues(alpha: 0.6)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: _deleteSelected,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.red.shade400,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: Colors.red.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(l.adminMissingDeleteCount(_selected.length),
                        style: tt.bodySmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
                  ]),
                ),
              ),
            ),
          ]),
        ),
    ]);
  }

  Widget _itemRow(Map<String, dynamic> item, ColorScheme cs, TextTheme tt, AppLocalizations l) {
    final api = context.read<AuthProvider>().apiService;
    final id = item['id'] as String? ?? '';
    final title = _titleOf(item);
    final author = _authorOf(item);
    final isMissing = item['isMissing'] == true;
    final selected = _selected.contains(id);
    final busy = _deleting.contains(id);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: GestureDetector(
        onTap: _selecting ? () => _toggle(id) : null,
        onLongPress: () => _toggle(id),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? Colors.red.withValues(alpha: 0.08) : cs.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(12),
            border: selected ? Border.all(color: Colors.red.withValues(alpha: 0.2)) : null,
          ),
          child: Row(children: [
            if (_selecting) ...[
              Icon(selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                  size: 20, color: selected ? Colors.red.shade300 : cs.onSurface.withValues(alpha: 0.2)),
              const SizedBox(width: 10),
            ],
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                width: 40,
                height: 40,
                child: api == null
                    ? _coverPlaceholder(cs)
                    : CachedNetworkImage(
                        imageUrl: api.getCoverUrl(id, width: 120),
                        httpHeaders: api.mediaHeaders,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => _coverPlaceholder(cs),
                        errorWidget: (_, __, ___) => _coverPlaceholder(cs),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: tt.bodySmall?.copyWith(fontWeight: FontWeight.w600, color: cs.onSurface),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Row(children: [
                  _badge(cs, tt, isMissing ? l.adminMissingBadge : l.adminInvalidBadge, isMissing ? Colors.red : Colors.orange),
                  if (author.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(author,
                          style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant.withValues(alpha: 0.6), fontSize: 11),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ]),
              ]),
            ),
            if (!_selecting) ...[
              const SizedBox(width: 8),
              busy
                  ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: cs.onSurfaceVariant.withValues(alpha: 0.4)))
                  : IconButton(
                      icon: Icon(Icons.delete_outline_rounded, size: 20, color: Colors.red.shade300),
                      tooltip: l.delete,
                      onPressed: () => _deleteOne(item),
                    ),
            ],
          ]),
        ),
      ),
    );
  }

  Widget _badge(ColorScheme cs, TextTheme tt, String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(6)),
        child: Text(label, style: tt.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w700, fontSize: 10)),
      );

  Widget _coverPlaceholder(ColorScheme cs) => Container(
        color: cs.surfaceContainerHighest,
        child: Icon(Icons.book_rounded, size: 18, color: cs.onSurfaceVariant.withValues(alpha: 0.3)),
      );
}
