import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'adaptive_modal.dart';
import 'listening_session_card.dart';

typedef DaySessionLoader =
    Future<List<Map<String, dynamic>>> Function(DateTime day);
typedef DaySessionOpener = Future<bool> Function(Map<String, dynamic> session);

bool listeningSessionMatchesDate(Map<String, dynamic> session, DateTime day) {
  final dateTime = listeningSessionDateOf(session);
  if (dateTime == null) return false;
  return dateTime.year == day.year &&
      dateTime.month == day.month &&
      dateTime.day == day.day;
}

DateTime? listeningSessionDateOf(Map<String, dynamic> session) {
  final date = session['date'];
  if (date is String && date.length >= 10) {
    return DateTime.tryParse(date.substring(0, 10));
  }

  final updatedAt = session['updatedAt'];
  if (updatedAt is! num) return null;
  return DateTime.fromMillisecondsSinceEpoch(updatedAt.toInt());
}

bool listeningSessionMatchesSearch(Map<String, dynamic> session, String query) {
  final normalized = query.trim().toLowerCase();
  if (normalized.isEmpty) return true;

  final metadata =
      session['mediaMetadata'] as Map<String, dynamic>? ?? const {};
  final device = session['deviceInfo'] as Map<String, dynamic>? ?? const {};
  final searchable = [
    session['displayTitle'],
    session['displayAuthor'],
    metadata['title'],
    metadata['subtitle'],
    metadata['authorName'],
    metadata['narratorName'],
    metadata['seriesName'],
    device['clientName'],
    device['deviceName'],
    device['model'],
    device['manufacturer'],
    device['osName'],
  ].whereType<String>().join(' ').toLowerCase();
  return searchable.contains(normalized);
}

class DaySessionsSheet extends StatefulWidget {
  const DaySessionsSheet({
    super.key,
    required this.initialDate,
    required this.loadSessions,
    required this.onSessionTap,
  });

  final DateTime initialDate;
  final DaySessionLoader loadSessions;
  final DaySessionOpener onSessionTap;

  @override
  State<DaySessionsSheet> createState() => _DaySessionsSheetState();
}

class _DaySessionsSheetState extends State<DaySessionsSheet> {
  late DateTime _date;
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _sessions = const [];
  bool _loading = true;
  bool _loadFailed = false;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _date = DateTime(
      widget.initialDate.year,
      widget.initialDate.month,
      widget.initialDate.day,
    );
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    try {
      final sessions = await widget.loadSessions(_date);
      if (!mounted) return;
      setState(() {
        _sessions = sessions;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _sessions = const [];
        _loading = false;
        _loadFailed = true;
      });
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date.isAfter(now) ? now : _date,
      firstDate: DateTime(2000),
      lastDate: now,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _date = DateTime(picked.year, picked.month, picked.day);
      _searchController.clear();
    });
    await _load();
  }

  Future<void> _openSession(Map<String, dynamic> session) async {
    final changed = await widget.onSessionTap(session);
    if (!mounted || !changed) return;
    _changed = true;
    await _load();
  }

  String _formatDuration(double seconds, AppLocalizations l) {
    final hours = (seconds / 3600).floor();
    final minutes = ((seconds % 3600) / 60).floor();
    if (hours > 0) return l.statsScreenDurationHm(hours, minutes);
    if (minutes > 0) return l.statsScreenDurationM(minutes);
    if (seconds > 0) return l.statsScreenDurationLessThanMin;
    return l.statsScreenDurationZero;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;
    final desktopMode = ModalSurface.isDesktopOf(context);
    final dateLabel = MaterialLocalizations.of(context).formatFullDate(_date);
    final filtered = _sessions
        .where(
          (session) =>
              listeningSessionMatchesSearch(session, _searchController.text),
        )
        .toList();
    final totalSeconds = filtered.fold<double>(
      0,
      (total, session) =>
          total + ((session['timeListening'] as num?)?.toDouble() ?? 0),
    );
    final countLabel = filtered.length == 1
        ? l.statsScreenSessionCountOne(filtered.length)
        : l.statsScreenSessionCountOther(filtered.length);

    return AdaptiveDraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.5,
      maxChildSize: 0.96,
      expand: false,
      builder: (_, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: desktopMode
                ? BorderRadius.zero
                : const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l.statsSessionsForDate(dateLabel),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: tt.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      key: const Key('day-sessions-date-picker'),
                      tooltip: l.sessionDayLabel,
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_month_rounded),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context, _changed),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: TextField(
                  key: const Key('day-sessions-search'),
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: l.statsSearchSessions,
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                            icon: const Icon(Icons.clear_rounded),
                          ),
                    filled: true,
                    fillColor: cs.surfaceContainerHighest.withValues(
                      alpha: 0.45,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              if (!_loading && !_loadFailed && _sessions.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
                  child: Row(
                    children: [
                      Text(
                        countLabel,
                        style: tt.labelMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _formatDuration(totalSeconds, l),
                        style: tt.labelMedium?.copyWith(
                          color: cs.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _loadFailed
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.cloud_off_rounded,
                              size: 42,
                              color: cs.onSurfaceVariant,
                            ),
                            const SizedBox(height: 10),
                            Text(l.statsSessionsLoadFailed),
                            const SizedBox(height: 8),
                            TextButton(onPressed: _load, child: Text(l.retry)),
                          ],
                        ),
                      )
                    : filtered.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            _sessions.isEmpty
                                ? l.statsNoSessionsForDate
                                : l.statsNoSessionSearchResults,
                            textAlign: TextAlign.center,
                            style: tt.bodyMedium?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                        itemCount: filtered.length,
                        itemBuilder: (_, index) {
                          final session = filtered[index];
                          return ListeningSessionCard(
                            session: session,
                            onTap: () => _openSession(session),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
