import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../services/book_stats_service.dart';

/// "5h 3m", "25m", "<1m", the way BookOrbit's reading cards write a length.
String activityDuration(AppLocalizations l, double seconds) {
  if (seconds <= 0) return l.statsScreenDurationZero;
  if (seconds < 60) return l.statsScreenDurationLessThanMin;
  final minutes = (seconds / 60).round();
  final h = minutes ~/ 60;
  final m = minutes % 60;
  return h > 0 ? l.statsScreenDurationHm(h, m) : l.statsScreenDurationM(m);
}

String activityPercent(double p) {
  if (p > 0 && p < 1) return '<1%';
  if (p > 99 && p < 100) return '>99%';
  return '${p.clamp(0, 100).round()}%';
}

/// "5m ago" up to a month, then the date.
String activityAgo(BuildContext context, AppLocalizations l, int ms) {
  final d = DateTime.fromMillisecondsSinceEpoch(ms);
  final diff = DateTime.now().difference(d);
  if (diff.inHours < 1) return l.minutesAgo(math.max(1, diff.inMinutes));
  if (diff.inDays < 1) return l.hoursAgo(diff.inHours);
  if (diff.inDays < 30) return l.daysAgo(diff.inDays);
  final locale = Localizations.localeOf(context).toString();
  return d.year == DateTime.now().year ? DateFormat.MMMd(locale).format(d) : DateFormat.yMMMd(locale).format(d);
}

/// A book's activity at a glance, laid out like BookOrbit's "Your reading"
/// card: totals, a strip of the days it was read on, and the latest
/// sessions. Fed by [BookStatsService], which the detail sheet warms.
class BookActivityCard extends StatelessWidget {
  final String itemId;
  final bool bookOrbit;
  final Color accent;
  final VoidCallback onOpen;

  /// Every session, for a server without a reading log of its own.
  final VoidCallback? onAllSessions;

  /// The everyone view, for admins.
  final VoidCallback? onOthers;
  final String? me;
  final String? meId;

  const BookActivityCard({
    super.key,
    required this.itemId,
    required this.bookOrbit,
    required this.accent,
    required this.onOpen,
    this.onAllSessions,
    this.onOthers,
    this.me,
    this.meId,
  });

  static const int _shown = 3;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final stats = BookStatsService.instance.stats(itemId);
    return ListenableBuilder(
      listenable: stats,
      builder: (context, _) {
        final s = stats;
        final a = s.activity;
        final has = a != null && a.sessions > 0;
        final small = tt.labelSmall?.copyWith(
            fontSize: 10, letterSpacing: 1, fontWeight: FontWeight.w600, color: cs.onSurfaceVariant);
        String? when;
        if (a != null && !has) {
          when = l.activityNotStarted;
        } else if (has && a.lastAt != null) {
          final ago = activityAgo(context, l, a.lastAt!);
          when = bookOrbit ? l.activityLastRead(ago) : l.activityLastListened(ago);
        }
        final others = onOthers != null && s.isAdmin && (s.checkedAt != null || s.users.isNotEmpty);
        final scanning = onOthers != null && s.isAdmin && s.serverLoading && s.users.isEmpty && s.checkedAt == null;
        final more = onAllSessions != null && s.sessions.length > _shown;
        return Container(
          decoration: BoxDecoration(
            color: cs.onSurface.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cs.onSurface.withValues(alpha: 0.08)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            InkWell(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              onTap: onOpen,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 8, 8),
                child: Row(children: [
                  Text((bookOrbit ? l.activityYourReading : l.activityYourListening).toUpperCase(), style: small),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(when ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                        style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
                  ),
                  Icon(Icons.chevron_right_rounded, size: 20, color: cs.onSurface.withValues(alpha: 0.4)),
                ]),
              ),
            ),
            if (a == null && s.loading && !s.failed)
              const Padding(
                padding: EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: LinearProgressIndicator(minHeight: 2),
              )
            else if (a == null && s.failed)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: Text(l.statsCouldNotLoad, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
              )
            else if (!has)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: Text(bookOrbit ? l.activityNoReading : l.detailSessionsNone,
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
              )
            else ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _stat(l.bookStatsSessions, '${a.sessions}', cs, tt),
                  _stat(l.activityTime, activityDuration(l, a.seconds), cs, tt),
                  _stat(l.activityAverage, activityDuration(l, a.avgSeconds), cs, tt),
                  _stat(l.activityProgress, a.progress == null ? '-' : activityPercent(a.progress!), cs, tt),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
                child: ActivityDayStrip(minutesByDay: a.minutesByDay, color: accent),
              ),
              const SizedBox(height: 6),
              for (var i = 0; i < math.min(_shown, a.recent.length); i++) ...[
                Divider(height: 1, indent: 14, endIndent: 14, color: cs.onSurface.withValues(alpha: 0.08)),
                _row(context, l, cs, tt, a.recent[i]),
              ],
              if (more || others || scanning)
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 2, 4, 4),
                  child: Row(children: [
                    if (scanning)
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 1.5, color: cs.onSurfaceVariant)),
                      )
                    else if (others)
                      TextButton.icon(
                        onPressed: onOthers,
                        icon: Icon(Icons.group_outlined, size: 16, color: cs.onSurfaceVariant),
                        label: Text(l.detailOtherListeners(s.othersCount(id: meId, username: me)),
                            style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant)),
                      ),
                    const Spacer(),
                    if (more)
                      TextButton(
                        onPressed: onAllSessions,
                        child: Text(l.detailSessionsAll(s.sessions.length),
                            style: tt.labelMedium?.copyWith(color: accent, fontWeight: FontWeight.w600)),
                      ),
                  ]),
                )
              else
                const SizedBox(height: 6),
            ],
          ]),
        );
      },
    );
  }

  Widget _stat(String label, String value, ColorScheme cs, TextTheme tt) => Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: tt.labelSmall?.copyWith(
                  fontSize: 9, letterSpacing: 0.8, fontWeight: FontWeight.w600, color: cs.onSurfaceVariant)),
          const SizedBox(height: 2),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: cs.onSurface)),
        ]),
      );

  Widget _row(BuildContext context, AppLocalizations l, ColorScheme cs, TextTheme tt, BookActivityRow r) {
    final muted = tt.labelSmall?.copyWith(color: cs.onSurfaceVariant);
    final reached = r.reading && !bookOrbit
        ? l.sessionReading
        : l.activityReached(r.reached == null ? '-' : activityPercent(r.reached!));
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 7, 14, 7),
      child: Row(children: [
        SizedBox(
          width: 88,
          child: Text(r.at == null ? '-' : activityAgo(context, l, r.at!),
              maxLines: 1, overflow: TextOverflow.ellipsis, style: muted),
        ),
        SizedBox(
          width: 56,
          child: Text(activityDuration(l, r.seconds),
              maxLines: 1, style: tt.labelSmall?.copyWith(fontWeight: FontWeight.w700, color: cs.onSurface)),
        ),
        Expanded(child: Text(reached, maxLines: 1, overflow: TextOverflow.ellipsis, style: muted)),
        if (r.format != null) FormatChip(format: r.format!),
      ]),
    );
  }
}

/// A file format as a small outlined tag ("M4B", "EPUB").
class FormatChip extends StatelessWidget {
  final String format;
  const FormatChip({super.key, required this.format});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = cs.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: color.withValues(alpha: 0.4)),
        color: color.withValues(alpha: 0.08),
      ),
      child: Text(format.toUpperCase(),
          style: TextStyle(fontSize: 9, height: 1, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: color)),
    );
  }
}

/// One bar per day across the stretch the book was read over, a week at the
/// least and four at the most, ending on the last day with any time.
class ActivityDayStrip extends StatelessWidget {
  final Map<String, double> minutesByDay;
  final Color color;
  final double height;
  const ActivityDayStrip({super.key, required this.minutesByDay, required this.color, this.height = 28});

  static List<double> days(Map<String, double> minutesByDay) {
    final keys = minutesByDay.entries.where((e) => e.value > 0).map((e) => e.key).toList()..sort();
    if (keys.isEmpty) return const [];
    final first = DateTime.tryParse(keys.first);
    final last = DateTime.tryParse(keys.last);
    if (first == null || last == null) return const [];
    final span = DateTime.utc(last.year, last.month, last.day)
            .difference(DateTime.utc(first.year, first.month, first.day))
            .inDays +
        1;
    final count = (span + 2).clamp(7, 28);
    return [
      for (var offset = count - 1; offset >= 0; offset--)
        minutesByDay[BookActivity.dayKey(DateTime.utc(last.year, last.month, last.day - offset))] ?? 0,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final list = days(minutesByDay);
    if (list.isEmpty) return const SizedBox.shrink();
    final peak = list.fold<double>(1, math.max);
    return SizedBox(
      height: height,
      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        for (var i = 0; i < list.length; i++) ...[
          if (i > 0) const SizedBox(width: 3),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(2),
              ),
              alignment: Alignment.bottomCenter,
              child: list[i] <= 0
                  ? null
                  : FractionallySizedBox(
                      heightFactor: math.max(0.16, list[i] / peak),
                      widthFactor: 1,
                      child: Container(
                        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
            ),
          ),
        ],
      ]),
    );
  }
}
