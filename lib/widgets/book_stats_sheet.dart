import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../services/book_stats_service.dart';

/// Listening stats for one book: always the reader's own, plus a server-wide
/// picture for admins (who listened, who finished, how long altogether).
///
/// The numbers come from [BookStatsService], which the book detail sheet
/// starts loading as soon as it opens - so this sheet usually opens on data
/// that is ready, or joins a load already under way instead of starting one.
Future<void> showBookStatsSheet(
  BuildContext context, {
  required String itemId,
  required String title,
  String? episodeId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (ctx, scrollController) => _BookStatsSheet(
        itemId: itemId,
        title: title,
        episodeId: episodeId,
        scrollController: scrollController,
      ),
    ),
  );
}

class _BookStatsSheet extends StatefulWidget {
  final String itemId;
  final String title;
  final String? episodeId;
  final ScrollController scrollController;
  const _BookStatsSheet({
    required this.itemId,
    required this.title,
    required this.episodeId,
    required this.scrollController,
  });

  @override
  State<_BookStatsSheet> createState() => _BookStatsSheetState();
}

class _BookStatsSheetState extends State<_BookStatsSheet> {
  late final BookStats _stats =
      BookStatsService.instance.stats(widget.itemId, episodeId: widget.episodeId);
  bool _noApi = false;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    final api = auth.apiService;
    if (api == null) {
      _noApi = true;
      return;
    }
    BookStatsService.instance.ensureLoaded(
      widget.itemId,
      api,
      episodeId: widget.episodeId,
      isAdmin: auth.isAdmin,
    );
  }

  String _dur(double seconds, AppLocalizations l) {
    final h = (seconds / 3600).floor();
    final m = ((seconds % 3600) / 60).floor();
    if (h > 0) return l.statsScreenDurationHm(h, m);
    if (m > 0) return l.statsScreenDurationM(m);
    if (seconds > 0) return l.statsScreenDurationLessThanMin;
    return l.statsScreenDurationZero;
  }

  String _date(int ms) {
    final d = DateTime.fromMillisecondsSinceEpoch(ms);
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return ListenableBuilder(
      listenable: _stats,
      builder: (context, _) {
        final s = _stats;
        final failed = s.failed || (_noApi && s.checkedAt == null);
        return ListView(
          controller: widget.scrollController,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            Text(widget.title,
                style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            if (s.loading && !failed)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (failed)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(l.statsCouldNotLoad,
                    style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
              )
            else ...[
              Text(l.bookStatsYou.toUpperCase(),
                  style: tt.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant, letterSpacing: 1)),
              const SizedBox(height: 8),
              _row(l.bookStatsListened, _dur(s.mySeconds, l), cs, tt),
              _row(l.bookStatsSessions, '${s.mySessions}', cs, tt),
              if (s.myFirst != null)
                _row(l.bookStatsFirst, _date(s.myFirst!), cs, tt),
              if (s.myLast != null) _row(l.bookStatsLast, _date(s.myLast!), cs, tt),
              if (s.isAdmin) ...[
                const SizedBox(height: 22),
                Row(children: [
                  Text(l.bookStatsEveryone.toUpperCase(),
                      style: tt.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant, letterSpacing: 1)),
                  const Spacer(),
                  // Cached numbers stay on screen while the rescan runs, so
                  // say when they were last brought up to date.
                  if (s.serverLoading && s.users.isNotEmpty)
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: cs.onSurfaceVariant),
                    )
                  else if (s.checkedAt != null)
                    Text(l.bookStatsLastChecked(_date(s.checkedAt!)),
                        style:
                            tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
                ]),
                const SizedBox(height: 8),
                if (s.serverLoading && s.users.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Column(children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 14),
                      Text(
                        s.scanTotal > 0
                            ? l.bookStatsScanningCount(s.scanDone, s.scanTotal)
                            : l.bookStatsScanning,
                        textAlign: TextAlign.center,
                        style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ]),
                  )
                else if (s.users.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(l.bookStatsNobody,
                        style:
                            tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                  )
                else ...[
                  _row(l.bookStatsListeners, '${s.users.length}', cs, tt),
                  _row(l.bookStatsFinishedCount,
                      '${s.users.where((u) => u.finished).length}', cs, tt),
                  _row(
                      l.bookStatsTotalTime,
                      _dur(s.users.fold(0.0, (a, u) => a + u.seconds), l),
                      cs,
                      tt),
                  const SizedBox(height: 12),
                  for (final u in s.users)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(children: [
                        Icon(
                          u.finished
                              ? Icons.check_circle_rounded
                              : Icons.headphones_rounded,
                          size: 18,
                          color: u.finished ? cs.primary : cs.onSurfaceVariant,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(u.username,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: tt.bodyMedium),
                        ),
                        Text(
                          '${(u.progress * 100).clamp(0, 100).round()}%  ${_dur(u.seconds, l)}',
                          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                        ),
                      ]),
                    ),
                ],
              ],
            ],
          ],
        );
      },
    );
  }

  Widget _row(String label, String value, ColorScheme cs, TextTheme tt) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: tt.bodyMedium),
            Text(value,
                style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
      );
}
