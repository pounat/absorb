import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/player_settings.dart';

/// What the user picked in [showDeleteConfirmDialog]. [hardDelete] true means
/// the server wipes the files on disk too (`?hard=1`), false means it only
/// drops the entry from its database.
class DeleteChoice {
  final bool hardDelete;
  const DeleteChoice(this.hardDelete);
}

/// Confirm a delete that happens on the Audiobookshelf server, offering the
/// same file-system choice the web UI does. Returns null when cancelled.
///
/// The checkbox starts ticked and remembers the last choice, matching the web
/// UI. [message] should say what is being deleted; the file-system wording is
/// added below it.
Future<DeleteChoice?> showDeleteConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String? confirmLabel,
}) async {
  final initial = await PlayerSettings.getDeleteFromFileSystem();
  if (!context.mounted) return null;
  final l = AppLocalizations.of(context)!;
  final choice = await showDialog<DeleteChoice>(
    context: context,
    builder: (ctx) {
      final cs = Theme.of(ctx).colorScheme;
      final tt = Theme.of(ctx).textTheme;
      bool hard = initial;
      return StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          scrollable: true,
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message),
              const SizedBox(height: 8),
              InkWell(
                onTap: () => setLocal(() => hard = !hard),
                borderRadius: BorderRadius.circular(10),
                child: Row(children: [
                  Checkbox(
                    value: hard,
                    onChanged: (v) => setLocal(() => hard = v ?? false),
                  ),
                  Expanded(child: Text(l.deleteFilesCheckbox, style: tt.bodyMedium)),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 4, top: 2),
                child: Text(
                  hard ? l.deleteFilesCheckedHint : l.deleteFilesUncheckedHint,
                  style: tt.bodySmall?.copyWith(
                    color: hard ? cs.error : cs.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, DeleteChoice(hard)),
              style: FilledButton.styleFrom(
                backgroundColor: cs.error,
                foregroundColor: cs.onError,
              ),
              child: Text(confirmLabel ?? l.delete),
            ),
          ],
        ),
      );
    },
  );
  if (choice != null) {
    await PlayerSettings.setDeleteFromFileSystem(choice.hardDelete);
  }
  return choice;
}
