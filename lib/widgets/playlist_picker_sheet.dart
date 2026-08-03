import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/library_provider.dart';
import 'adaptive_modal.dart';
import 'overlay_toast.dart';

class PlaylistPickerSheet extends StatefulWidget {
  final String libraryItemId;
  final String? episodeId;

  const PlaylistPickerSheet({
    super.key,
    required this.libraryItemId,
    this.episodeId,
  });

  static void show(BuildContext context, String libraryItemId, {String? episodeId}) {
    showAdaptiveActionMenu(
      context: context,
      backgroundColor: Theme.of(context).bottomSheetTheme.backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (_) => PlaylistPickerSheet(
        libraryItemId: libraryItemId,
        episodeId: episodeId,
      ),
    );
  }

  @override
  State<PlaylistPickerSheet> createState() => _PlaylistPickerSheetState();
}

class _PlaylistPickerSheetState extends State<PlaylistPickerSheet> {
  bool _creatingNew = false;
  final _nameController = TextEditingController();
  bool _adding = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _createAndAdd(LibraryProvider lib) async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    setState(() => _adding = true);
    final playlist = await lib.createPlaylist(name);
    if (playlist != null) {
      final playlistId = playlist['id'] as String;
      await lib.addToPlaylist(
        playlistId, widget.libraryItemId, episodeId: widget.episodeId,
      );
      if (mounted) {
        final l = AppLocalizations.of(context)!;
        showOverlayToast(context, l.addedToName(name), icon: Icons.playlist_add_check_rounded);
        Navigator.pop(context);
      }
    } else {
      setState(() => _adding = false);
    }
  }

  Future<void> _addToExisting(LibraryProvider lib, Map<String, dynamic> playlist) async {
    setState(() => _adding = true);
    final playlistId = playlist['id'] as String;
    final l = AppLocalizations.of(context)!;
    final name = playlist['name'] as String? ?? l.playlistPickerPlaylistFallback;
    final ok = await lib.addToPlaylist(
      playlistId, widget.libraryItemId, episodeId: widget.episodeId,
    );
    if (mounted) {
      showOverlayToast(
        context,
        ok ? l.addedToName(name) : l.failedToAdd,
        icon: ok ? Icons.playlist_add_check_rounded : Icons.error_outline_rounded,
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final lib = context.watch<LibraryProvider>();
    final playlists = lib.playlists;
    final l = AppLocalizations.of(context)!;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16, 8, 16, 16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Grab handle
          Center(child: Container(
            width: 40, height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: cs.onSurface.withValues(alpha: 0.24),
              borderRadius: BorderRadius.circular(2),
            ),
          )),
          // Title
          Text(l.addToPlaylist, style: TextStyle(
            color: cs.onSurface, fontSize: 16, fontWeight: FontWeight.w600,
          )),
          const SizedBox(height: 12),
          // New playlist
          if (_creatingNew)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                Expanded(child: TextField(
                  controller: _nameController,
                  autofocus: true,
                  style: TextStyle(color: cs.onSurface, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: l.playlistNameHint,
                    hintStyle: TextStyle(color: cs.onSurface.withValues(alpha: 0.4)),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: cs.onSurface.withValues(alpha: 0.2)),
                    ),
                  ),
                  onSubmitted: (_) => _createAndAdd(lib),
                )),
                const SizedBox(width: 8),
                _adding
                    ? const SizedBox(width: 36, height: 36,
                        child: Padding(
                          padding: EdgeInsets.all(8),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ))
                    : IconButton(
                        icon: Icon(Icons.check_rounded, color: cs.primary),
                        onPressed: () => _createAndAdd(lib),
                      ),
              ]),
            )
          else
            _sheetItem(cs, Icons.add_rounded, l.newPlaylist,
              onTap: () => setState(() => _creatingNew = true)),
          // Existing playlists
          if (playlists.isNotEmpty) ...[
            const SizedBox(height: 4),
            ...playlists.map((p) {
              final pm = p as Map<String, dynamic>;
              final name = pm['name'] as String? ?? l.playlistPickerPlaylistFallback;
              final items = (pm['items'] as List<dynamic>?) ?? [];
              // Check if item is already in this playlist
              final alreadyIn = items.any((item) {
                final im = item as Map<String, dynamic>;
                final lid = im['libraryItemId'] as String?;
                final eid = im['episodeId'] as String?;
                return lid == widget.libraryItemId &&
                    (widget.episodeId == null ? eid == null : eid == widget.episodeId);
              });
              return _sheetItem(
                cs,
                alreadyIn ? Icons.check_rounded : Icons.playlist_play_rounded,
                l.playlistPickerNameWithCount(name, items.length),
                enabled: !alreadyIn && !_adding,
                onTap: () => _addToExisting(lib, pm),
              );
            }),
          ],
        ]),
      ),
    );
  }

  Widget _sheetItem(ColorScheme cs, IconData icon, String label,
      {required VoidCallback onTap, bool enabled = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            color: cs.onSurface.withValues(alpha: enabled ? 0.06 : 0.03),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cs.onSurface.withValues(alpha: 0.1)),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 16,
                color: enabled ? cs.onSurfaceVariant : cs.onSurfaceVariant.withValues(alpha: 0.4)),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(
              color: enabled ? cs.onSurfaceVariant : cs.onSurfaceVariant.withValues(alpha: 0.4),
              fontSize: 13, fontWeight: FontWeight.w500,
            )),
          ]),
        ),
      ),
    );
  }
}
