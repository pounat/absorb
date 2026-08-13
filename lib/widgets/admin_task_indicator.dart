import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/server_task_tracker.dart';
import 'adaptive_modal.dart';

class AdminTaskIndicator extends StatelessWidget {
  static const indicatorKey = Key('admin-task-indicator');

  final List<ServerTask> tasks;
  final VoidCallback onPressed;

  const AdminTaskIndicator({
    super.key,
    required this.tasks,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) return const SizedBox.shrink();
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final runningCount = tasks.where((task) => task.isRunning).length;
    final hasFailure = tasks.any((task) => task.isFailed);
    final tooltip = runningCount > 0
        ? l.adminTasksRunning(runningCount)
        : l.adminTasksRecent;

    return IconButton(
      key: indicatorKey,
      onPressed: onPressed,
      tooltip: tooltip,
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          if (runningCount > 0)
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: cs.primary,
              ),
            )
          else
            Icon(
              hasFailure
                  ? Icons.error_outline_rounded
                  : Icons.notifications_rounded,
              color: hasFailure ? cs.error : cs.primary,
            ),
          if (runningCount > 1)
            Positioned(
              right: -8,
              top: -7,
              child: Container(
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: cs.primary,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: cs.surface, width: 1.5),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$runningCount',
                  style: TextStyle(
                    color: cs.onPrimary,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

Future<void> showAdminTasksSheet(
  BuildContext context,
  ServerTaskTracker tracker,
) {
  return showAdaptiveActionMenu<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    desktopWidth: 560,
    desktopScrollWrap: false,
    builder: (sheetContext) => ListenableBuilder(
      listenable: tracker,
      builder: (_, __) => AdminTasksSheet(tasks: tracker.visibleTasks),
    ),
  );
}

class AdminTasksSheet extends StatelessWidget {
  final List<ServerTask> tasks;

  const AdminTasksSheet({super.key, required this.tasks});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final runningCount = tasks.where((task) => task.isRunning).length;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.78,
      ),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 10),
            decoration: BoxDecoration(
              color: cs.onSurface.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 8, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.adminTasksTitle,
                        style: tt.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        runningCount > 0
                            ? l.adminTasksRunning(runningCount)
                            : l.adminTasksRecent,
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.5)),
          if (tasks.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 36, 24, 48),
              child: Column(
                children: [
                  Icon(
                    Icons.check_circle_outline_rounded,
                    size: 36,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.55),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l.adminTasksEmpty,
                    textAlign: TextAlign.center,
                    style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                itemCount: tasks.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, index) => _ServerTaskCard(task: tasks[index]),
              ),
            ),
        ],
      ),
    );
  }
}

class _ServerTaskCard extends StatelessWidget {
  final ServerTask task;

  const _ServerTaskCard({required this.task});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final title = task.title.isNotEmpty
        ? task.title
        : task.action.replaceAll('-', ' ');
    final scanSummary = _scanSummary(l);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: _statusIcon(cs),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                if (task.description.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    task.description,
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
                if (scanSummary != null) ...[
                  const SizedBox(height: 5),
                  Text(
                    scanSummary,
                    style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
                if (task.isFailed && task.error.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    task.error,
                    style: tt.bodySmall?.copyWith(color: cs.error),
                  ),
                ],
                if (task.isRunning && task.progress != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: task.progress! / 100,
                            minHeight: 5,
                            backgroundColor: cs.onSurface.withValues(
                              alpha: 0.08,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        l.percentComplete(task.progress!.round().toString()),
                        style: tt.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusIcon(ColorScheme cs) {
    if (task.isRunning) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2, color: cs.primary),
      );
    }
    return Icon(
      task.isFailed ? Icons.error_rounded : Icons.check_circle_rounded,
      size: 22,
      color: task.isFailed ? cs.error : Colors.green,
    );
  }

  String? _scanSummary(AppLocalizations l) {
    final results = task.scanResults;
    if (results == null) return null;
    final added = (results['added'] as num?)?.toInt() ?? 0;
    final updated = (results['updated'] as num?)?.toInt() ?? 0;
    final missing = (results['missing'] as num?)?.toInt() ?? 0;
    return l.adminTaskScanSummary(added, updated, missing);
  }
}
