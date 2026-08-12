import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/library_provider.dart';
import '../services/audio_player_service.dart';
import 'delete_confirm_dialog.dart';
import 'overlay_toast.dart';

class DesktopQuickMatchOptions {
  final String provider;
  final bool overrideCover;
  final bool overrideDetails;

  const DesktopQuickMatchOptions({
    required this.provider,
    required this.overrideCover,
    required this.overrideDetails,
  });
}

Future<DesktopQuickMatchOptions?> showDesktopQuickMatchDialog(
  BuildContext context, {
  required List<String> providers,
  required String initialProvider,
}) {
  final availableProviders = providers.isEmpty
      ? <String>[initialProvider]
      : providers.toSet().toList();
  var provider = availableProviders.contains(initialProvider)
      ? initialProvider
      : availableProviders.first;
  var overrideCover = true;
  var overrideDetails = true;
  final l = AppLocalizations.of(context)!;

  return showDialog<DesktopQuickMatchOptions>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setLocalState) => AlertDialog(
        title: Text(l.quickMatch),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                initialValue: provider,
                decoration: InputDecoration(labelText: l.libProvider),
                items: [
                  for (final value in availableProviders)
                    DropdownMenuItem(value: value, child: Text(value)),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setLocalState(() => provider = value);
                  }
                },
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Replace covers'),
                value: overrideCover,
                onChanged: (value) =>
                    setLocalState(() => overrideCover = value ?? false),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Replace details'),
                value: overrideDetails,
                onChanged: (value) =>
                    setLocalState(() => overrideDetails = value ?? false),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              dialogContext,
              DesktopQuickMatchOptions(
                provider: provider,
                overrideCover: overrideCover,
                overrideDetails: overrideDetails,
              ),
            ),
            child: Text(l.quickMatch),
          ),
        ],
      ),
    ),
  );
}

class DesktopBatchActions {
  const DesktopBatchActions._();

  static Future<bool?> quickMatch(
    BuildContext context,
    List<String> itemIds,
  ) async {
    if (itemIds.isEmpty) return null;
    final auth = context.read<AuthProvider>();
    final lib = context.read<LibraryProvider>();
    final api = auth.apiService;
    if (api == null) return false;

    final libraryProvider =
        lib.selectedLibrary?['provider']?.toString().trim() ?? '';
    final providers = await api.getMetadataProviders();
    if (!context.mounted) return null;
    final initialProvider = libraryProvider.isNotEmpty
        ? libraryProvider
        : (providers.isNotEmpty ? providers.first : 'audible');
    final options = await showDesktopQuickMatchDialog(
      context,
      providers: providers,
      initialProvider: initialProvider,
    );
    if (options == null || !context.mounted) return null;

    final success = await api.quickMatchLibraryItems(
      itemIds,
      provider: options.provider,
      overrideCover: options.overrideCover,
      overrideDetails: options.overrideDetails,
    );
    if (!context.mounted) return success;
    final l = AppLocalizations.of(context)!;
    showOverlayToast(
      context,
      success
          ? l.adminMatchingStarted(l.selectedCount(itemIds.length))
          : l.failedToUpdateMetadata,
      icon: success
          ? Icons.check_circle_outline_rounded
          : Icons.error_outline_rounded,
    );
    return success;
  }

  static Future<bool> setFinished(
    BuildContext context,
    List<String> itemIds, {
    required bool isFinished,
  }) async {
    if (itemIds.isEmpty) return false;
    final auth = context.read<AuthProvider>();
    final lib = context.read<LibraryProvider>();
    final api = auth.apiService;
    if (api == null) return false;
    final success = await api.updateLibraryItemsFinished(
      itemIds,
      isFinished: isFinished,
    );
    if (!context.mounted) return success;
    final l = AppLocalizations.of(context)!;
    if (success) await lib.refresh();
    if (!context.mounted) return success;
    showOverlayToast(
      context,
      success
          ? (isFinished
                ? l.playlistDetailItemsMarkedFinished(itemIds.length)
                : l.playlistDetailItemsMarkedUnfinished(itemIds.length))
          : l.failedToUpdateCheckConnection,
      icon: success
          ? (isFinished
                ? Icons.check_circle_outline_rounded
                : Icons.radio_button_unchecked_rounded)
          : Icons.error_outline_rounded,
    );
    return success;
  }

  static Future<bool?> delete(
    BuildContext context,
    List<String> itemIds,
  ) async {
    if (itemIds.isEmpty) return null;
    final l = AppLocalizations.of(context)!;
    final choice = await showDeleteConfirmDialog(
      context,
      title: l.deleteFromServerTitle,
      message: l.selectedCount(itemIds.length),
    );
    if (choice == null || !context.mounted) return null;

    final auth = context.read<AuthProvider>();
    final lib = context.read<LibraryProvider>();
    final api = auth.apiService;
    if (api == null) return false;
    final status = await api.deleteLibraryItems(
      itemIds,
      hard: choice.hardDelete,
    );
    if (!context.mounted) return status == 200;
    if (status == 200) {
      final player = AudioPlayerService();
      if (itemIds.contains(player.currentItemId)) {
        await player.stopWithoutSaving();
      }
      for (final itemId in itemIds) {
        await lib.removeFromAbsorbing(itemId);
      }
      await lib.refresh();
      if (!context.mounted) return true;
      showOverlayToast(
        context,
        l.deletedFromServer(l.selectedCount(itemIds.length)),
        icon: Icons.delete_outline_rounded,
      );
      return true;
    }
    showOverlayToast(
      context,
      status == 403 ? l.deletePermissionRequired : l.deleteFromServerFailed,
      icon: status == 403
          ? Icons.lock_outline_rounded
          : Icons.error_outline_rounded,
    );
    return false;
  }
}

class DesktopBatchActionBar extends StatelessWidget {
  final int selectedCount;
  final int selectableCount;
  final bool busy;
  final String? busyLabel;
  final bool canQuickMatch;
  final bool canMarkProgress;
  final bool canDelete;
  final VoidCallback onSelectAll;
  final VoidCallback onClear;
  final VoidCallback onQuickMatch;
  final VoidCallback onMarkFinished;
  final VoidCallback onMarkUnfinished;
  final VoidCallback onDelete;

  const DesktopBatchActionBar({
    super.key,
    required this.selectedCount,
    required this.selectableCount,
    required this.busy,
    this.busyLabel,
    required this.canQuickMatch,
    this.canMarkProgress = true,
    required this.canDelete,
    required this.onSelectAll,
    required this.onClear,
    required this.onQuickMatch,
    required this.onMarkFinished,
    required this.onMarkUnfinished,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    final hasSelection = selectedCount > 0;
    final allSelected = selectableCount > 0 && selectedCount >= selectableCount;

    return Material(
      elevation: 10,
      color: cs.surfaceContainerHigh,
      shadowColor: Colors.black.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(28),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 52),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (busy) ...[
                const Padding(
                  padding: EdgeInsets.all(10),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                if (busyLabel != null && busyLabel!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Text(
                      busyLabel!,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
              ] else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    l.selectedCount(selectedCount),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              Tooltip(
                message: allSelected ? l.deselectAll : l.selectAll,
                child: IconButton(
                  onPressed: busy || selectableCount == 0 ? null : onSelectAll,
                  icon: Icon(
                    allSelected
                        ? Icons.deselect_rounded
                        : Icons.select_all_rounded,
                  ),
                ),
              ),
              if (canQuickMatch)
                Tooltip(
                  message: l.quickMatch,
                  child: IconButton(
                    onPressed: busy || !hasSelection ? null : onQuickMatch,
                    icon: const Icon(Icons.auto_fix_high_rounded),
                  ),
                ),
              if (canMarkProgress) ...[
                Tooltip(
                  message: l.markFinished,
                  child: IconButton(
                    onPressed: busy || !hasSelection ? null : onMarkFinished,
                    icon: const Icon(Icons.check_circle_outline_rounded),
                  ),
                ),
                Tooltip(
                  message: l.markUnfinished,
                  child: IconButton(
                    onPressed: busy || !hasSelection ? null : onMarkUnfinished,
                    icon: const Icon(Icons.radio_button_unchecked_rounded),
                  ),
                ),
              ],
              if (canDelete)
                Tooltip(
                  message: l.deleteFromServerAction,
                  child: IconButton(
                    onPressed: busy || !hasSelection ? null : onDelete,
                    color: cs.error,
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
                ),
              Tooltip(
                message: l.downloadsCancelSelection,
                child: IconButton(
                  onPressed: busy ? null : onClear,
                  icon: const Icon(Icons.close_rounded),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
