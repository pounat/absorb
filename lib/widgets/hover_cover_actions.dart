import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../screens/book_edit_screen.dart';
import '../utils/desktop_workspace.dart';

/// Desktop hover overlay for book/episode covers: a 3-dot menu opening the
/// item's quick actions and, when permitted, an edit shortcut into the book
/// editor. Returns the child untouched off the desktop workspace, so mobile
/// tiles are unaffected.
class HoverCoverActions extends StatefulWidget {
  final Widget child;
  final VoidCallback? onMenu;
  final bool selectionMode;
  final bool selected;
  final VoidCallback? onSelectionToggle;

  /// Item id to open in the book editor; null hides the edit shortcut.
  /// Callers gate this on `auth.canUpdateMetadata && !lib.isOffline`.
  final String? editItemId;

  const HoverCoverActions({
    super.key,
    required this.child,
    this.onMenu,
    this.editItemId,
    this.selectionMode = false,
    this.selected = false,
    this.onSelectionToggle,
  });

  @override
  State<HoverCoverActions> createState() => _HoverCoverActionsState();
}

class _HoverCoverActionsState extends State<HoverCoverActions> {
  bool _hovering = false;
  bool _loadingEditor = false;

  Future<void> _openEditor() async {
    final itemId = widget.editItemId;
    if (itemId == null || _loadingEditor) return;
    final auth = context.read<AuthProvider>();
    final api = auth.apiService;
    if (api == null) return;
    setState(() => _loadingEditor = true);
    final item = await api.getLibraryItem(itemId);
    if (!mounted) return;
    setState(() => _loadingEditor = false);
    if (item == null) return;
    final media = item['media'] as Map<String, dynamic>? ?? {};
    final meta = media['metadata'] as Map<String, dynamic>? ?? {};
    final tags = ((media['tags'] as List<dynamic>?) ?? const []).cast<String>();
    final audioFiles = (media['audioFiles'] as List<dynamic>?) ?? const [];
    final libraryFiles = (item['libraryFiles'] as List<dynamic>?) ?? const [];
    contentNavigator(context).push(
      MaterialPageRoute(
        builder: (_) => BookEditScreen(
          itemId: itemId,
          bookTitle: meta['title'] as String? ?? '',
          metadata: meta,
          tags: tags,
          audioFiles: audioFiles,
          libraryFiles: libraryFiles,
          relPath: item['relPath'] as String? ?? '',
          isEbookOnly: audioFiles.isEmpty && media['ebookFile'] != null,
          isAdmin: auth.isAdmin,
          libraryId: item['libraryId'] as String?,
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    bool busy = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.black.withValues(alpha: 0.6),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: busy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(icon, size: 16, color: Colors.white),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!isDesktopWorkspace(context)) return widget.child;
    if (widget.onMenu == null &&
        widget.editItemId == null &&
        widget.onSelectionToggle == null) {
      return widget.child;
    }
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final showSelection = widget.selectionMode || widget.selected;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          widget.child,
          if (widget.selected)
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: cs.primary, width: 3),
                    color: cs.primary.withValues(alpha: 0.08),
                  ),
                ),
              ),
            ),
          if (widget.onSelectionToggle != null)
            Positioned(
              top: 4,
              left: 4,
              child: AnimatedOpacity(
                opacity: _hovering || showSelection ? 1 : 0,
                duration: const Duration(milliseconds: 120),
                child: IgnorePointer(
                  ignoring: !_hovering && !showSelection,
                  child: _actionButton(
                    icon: widget.selected
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    tooltip: widget.selected ? 'Deselect' : 'Select',
                    onTap: widget.onSelectionToggle!,
                  ),
                ),
              ),
            ),
          Positioned(
            top: 4,
            right: 4,
            child: AnimatedOpacity(
              opacity: _hovering && !widget.selectionMode ? 1 : 0,
              duration: const Duration(milliseconds: 120),
              child: IgnorePointer(
                ignoring: !_hovering || widget.selectionMode,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.editItemId != null) ...[
                      _actionButton(
                        icon: Icons.edit_rounded,
                        tooltip: l.edit,
                        onTap: _openEditor,
                        busy: _loadingEditor,
                      ),
                      const SizedBox(width: 4),
                    ],
                    if (widget.onMenu != null)
                      _actionButton(
                        icon: Icons.more_horiz_rounded,
                        tooltip: l.moreActions,
                        onTap: widget.onMenu!,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
