import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/audio_player_service.dart';
import '../services/sleep_timer_service.dart';

// ─── SHARED SLEEP TIMER SHEET ─────────────────────────────────
void showSleepTimerSheet(BuildContext context, Color accent) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => SleepTimerSheet(accent: accent),
  );
}

class SleepTimerSheet extends StatefulWidget {
  final Color accent;
  const SleepTimerSheet({super.key, required this.accent});
  @override
  State<SleepTimerSheet> createState() => _SleepTimerSheetState();
}

class _SleepTimerSheetState extends State<SleepTimerSheet> {
  int _tabIndex = 0; // 0 = Timer, 1 = End of Chapter
  double _customMinutes = 30;
  int _customChapters = 1;
  String _shakeMode = 'addTime'; // 'off', 'addTime', 'resetTimer'
  int _shakeAddMinutes = 5;
  int _sleepRewindSeconds = 0;
  int _selectedChapterIndex = 0;
  bool _useChapterEnd = true;

  static const _maxRewindMinutes = 120;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final results = await Future.wait([
      PlayerSettings.getShakeMode(),
      PlayerSettings.getShakeAddMinutes(),
      PlayerSettings.getSleepTimerMinutes(),
      PlayerSettings.getSleepTimerChapters(),
      PlayerSettings.getSleepRewindSeconds(),
      PlayerSettings.getSleepTimerTab(),
    ]);
    if (mounted)
      setState(() {
        _shakeMode = results[0] as String;
        _shakeAddMinutes = results[1] as int;
        _customMinutes = (results[2] as int).toDouble();
        _customChapters = results[3] as int;
        _sleepRewindSeconds = results[4] as int;
        _tabIndex = results[5] as int;
        final currentIdx = _getCurrentChapterIndexFromPlayer();
        if (currentIdx >= 0) _selectedChapterIndex = currentIdx;
      });
  }

  int _getCurrentChapterIndexFromPlayer() {
    final player = AudioPlayerService();
    final chapters = player.chapters;
    final pos = player.position.inMilliseconds / 1000.0;
    for (int i = 0; i < chapters.length; i++) {
      final ch = chapters[i] as Map<String, dynamic>;
      final start = (ch['start'] as num?)?.toDouble() ?? 0;
      final end = (ch['end'] as num?)?.toDouble() ?? 0;
      if (pos >= start && pos < end) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final accent = widget.accent;
    final l = AppLocalizations.of(context)!;

    return ListenableBuilder(
      listenable: SleepTimerService(),
      builder: (_, __) {
        final sleep = SleepTimerService();
        final isActive = sleep.isActive;

        final navBarPad = MediaQuery.of(context).viewPadding.bottom;

        return Container(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 24 + navBarPad),
          decoration: BoxDecoration(
            color: Theme.of(context).bottomSheetTheme.backgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
                top:
                    BorderSide(color: accent.withValues(alpha: 0.2), width: 1)),
          ),
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: cs.onSurface.withValues(alpha: 0.24),
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              Text(l.sleepTimer,
                  style: tt.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600, color: cs.onSurface)),
              const SizedBox(height: 16),
              if (isActive)
                _buildActiveState(sleep, accent, tt, l)
              else ...[
                // Tab bar
                Container(
                  decoration: BoxDecoration(
                    color: cs.onSurface.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(3),
                  child: Row(children: [
                    _tab(l.timer, Icons.timer_outlined, 0, accent),
                    const SizedBox(width: 4),
                    _tab(
                        l.endOfChapter, Icons.auto_stories_outlined, 1, accent),
                    const SizedBox(width: 4),
                    _tab(l.sleepTimerSheetTabSpecificChapter, Icons.bookmark_outlined, 2, accent),
                  ]),
                ),
                const SizedBox(height: 20),

                // Tab content
                if (_tabIndex == 0)
                  _buildTimerTab(accent, tt, l)
                else if (_tabIndex == 1)
                  _buildChapterTab(accent, tt, l)
                else
                  _buildSpecificChapterTab(accent, tt, l),
                const SizedBox(height: 16),
                Container(
                    height: 0.5, color: cs.onSurface.withValues(alpha: 0.08)),
                const SizedBox(height: 12),

                // Rewind on sleep
                _buildRewindSection(accent, tt, l),

                const SizedBox(height: 12),
                Container(
                    height: 0.5, color: cs.onSurface.withValues(alpha: 0.08)),
                const SizedBox(height: 12),

                // Shake toggle
                _buildShakeToggle(accent, tt, l),
              ],
            ]),
          ),
        );
      },
    );
  }

  Widget _buildActiveState(
      SleepTimerService sleep, Color accent, TextTheme tt, AppLocalizations l) {
    final cs = Theme.of(context).colorScheme;
    final isTime = sleep.mode == SleepTimerMode.time;

    String countdownLabel;
    if (isTime) {
      final r = sleep.timeRemaining;
      final m = r.inMinutes;
      final s = r.inSeconds % 60;
      countdownLabel =
          '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    } else {
      countdownLabel = l.sleepTimerSheetChaptersLeft(sleep.chaptersRemaining);
    }

    return Column(children: [
      // Countdown display
      if (isTime) ...[
        Text(countdownLabel,
            style: TextStyle(
                color: accent,
                fontSize: 40,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()])),
        const SizedBox(height: 8),
        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: sleep.timeProgress,
            minHeight: 4,
            backgroundColor: cs.onSurface.withValues(alpha: 0.08),
            valueColor: AlwaysStoppedAnimation(accent.withValues(alpha: 0.6)),
          ),
        ),
      ] else ...[
        Icon(Icons.auto_stories_outlined,
            size: 28, color: accent.withValues(alpha: 0.6)),
        const SizedBox(height: 8),
        Text(countdownLabel,
            style: TextStyle(
                color: accent, fontSize: 24, fontWeight: FontWeight.w700)),
      ],
      const SizedBox(height: 20),

      // Quick add buttons
      Text(l.addMoreTime,
          style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
      const SizedBox(height: 10),
      if (isTime)
        Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              for (final mins in [5, 10, 15, 30])
                _presetChip(
                    accent, l.sleepTimerSheetAddMinutesChip(mins), false, () {
                  sleep.addTime(Duration(minutes: mins));
                }),
            ])
      else
        Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              for (final ch in [1, 2, 3])
                _presetChip(accent, l.sleepTimerSheetAddChaptersChip(ch), false,
                    () {
                  for (int i = 0; i < ch; i++) sleep.addChapter();
                }),
            ]),
      const SizedBox(height: 20),

      // Cancel button
      SizedBox(
          width: double.infinity,
          height: 44,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.close_rounded, size: 18),
            label: Text(l.cancelTimer),
            style: OutlinedButton.styleFrom(
              foregroundColor: cs.onSurfaceVariant,
              side: BorderSide(color: cs.onSurface.withValues(alpha: 0.12)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              sleep.cancelByUser();
              Navigator.pop(context);
            },
          )),

      const SizedBox(height: 12),
      Container(height: 0.5, color: cs.onSurface.withValues(alpha: 0.08)),
      const SizedBox(height: 12),
      _buildRewindSection(accent, tt, l),
      const SizedBox(height: 12),
      Container(height: 0.5, color: cs.onSurface.withValues(alpha: 0.08)),
      const SizedBox(height: 12),
      _buildShakeToggle(accent, tt, l),
    ]);
  }

  Widget _buildSpecificChapterTab(
      Color accent, TextTheme tt, AppLocalizations l) {
    final cs = Theme.of(context).colorScheme;
    final player = AudioPlayerService();
    final chapters = player.chapters;

    if (chapters.isEmpty) {
      return Center(
        child: Text(l.sleepTimerSheetSpecificNoChapters,
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
      );
    }

    final selectedChapter =
        chapters[_selectedChapterIndex] as Map<String, dynamic>;
    final refTimeSec = _useChapterEnd
        ? (selectedChapter['end'] as num?)?.toDouble() ?? 0
        : (selectedChapter['start'] as num?)?.toDouble() ?? 0;

    final currentPosSec = player.position.inMilliseconds / 1000.0;
    final secondsUntilTarget = refTimeSec - currentPosSec;
    final realSecondsUntil = secondsUntilTarget / player.speed;
    final endTime = DateTime.now()
        .add(Duration(milliseconds: (realSecondsUntil * 1000).round()));

    final isPast = secondsUntilTarget <= 0;

    return Column(children: [
      // Chapter dropdown
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: cs.onSurface.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.onSurface.withValues(alpha: 0.1)),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<int>(
            value: _selectedChapterIndex,
            isExpanded: true,
            style: TextStyle(color: cs.onSurface, fontSize: 13),
            dropdownColor: Theme.of(context).bottomSheetTheme.backgroundColor,
            items: chapters.asMap().entries.map((e) {
              final ch = e.value as Map<String, dynamic>;
              final title = ch['title'] as String? ?? l.sleepTimerSheetSpecificChapterFallback(e.key + 1);
              final endSec = (ch['end'] as num?)?.toDouble() ?? 0;
              final currentPosSec = player.position.inMilliseconds / 1000.0;
              final secondsUntil = (endSec - currentPosSec) / player.speed;

              final endTime = DateTime.now().add(
                Duration(milliseconds: (secondsUntil * 1000).round()),
              );

              final timeLabel =
                  secondsUntil > 0 ? _formatWallClock(endTime) : l.sleepTimerSheetSpecificPassedShort;

              return DropdownMenuItem(
                value: e.key,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      timeLabel,
                      style: TextStyle(
                        color:
                            secondsUntil > 0 ? cs.onSurfaceVariant : cs.error,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (v) => setState(() => _selectedChapterIndex = v!),
          ),
        ),
      ),

      const SizedBox(height: 12),

      // Start / End toggle
      SizedBox(
        width: double.infinity,
        child: SegmentedButton<bool>(
          showSelectedIcon: false,
          segments: [
            ButtonSegment(value: false, label: FittedBox(fit: BoxFit.scaleDown, child: Text(l.sleepTimerSheetSpecificStart, maxLines: 1))),
            ButtonSegment(value: true, label: FittedBox(fit: BoxFit.scaleDown, child: Text(l.sleepTimerSheetSpecificEnd, maxLines: 1))),
          ],
          selected: {_useChapterEnd},
          style: const ButtonStyle(
            visualDensity: VisualDensity.compact,
            textStyle: WidgetStatePropertyAll(TextStyle(fontSize: 12)),
          ),
          onSelectionChanged: (v) => setState(() => _useChapterEnd = v.first),
        ),
      ),

      const SizedBox(height: 20),

      // Estimated end time
      if (!isPast) ...[
        Text(l.sleepTimerSheetSpecificEndsAt,
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
        const SizedBox(height: 4),
        Text(_formatWallClock(endTime),
            style: TextStyle(
                color: accent,
                fontSize: 36,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()])),
        const SizedBox(height: 4),
        Text(
            l.sleepTimerSheetSpecificCountdown(_formatCountdown(Duration(seconds: realSecondsUntil.round()))),
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
      ] else
        Text(l.sleepTimerSheetSpecificAlreadyPassed,
            style: TextStyle(color: cs.error, fontSize: 13)),

      const SizedBox(height: 16),

      // Start button
      SizedBox(
          width: double.infinity,
          height: 44,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor:
                  isPast ? cs.onSurface.withValues(alpha: 0.12) : accent,
              foregroundColor:
                  isPast ? cs.onSurface.withValues(alpha: 0.38) : cs.surface,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: isPast
                ? null
                : () {
                    SleepTimerService().setTimeSleep(Duration(
                        milliseconds: (realSecondsUntil * 1000).round()));
                    Navigator.pop(context);
                  },
            child: Text(
              isPast ? l.sleepTimerSheetSpecificStartButtonPassed : l.sleepTimerSheetSpecificStartButton,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          )),
    ]);
  }

  String _formatWallClock(DateTime dt) {
    final l = AppLocalizations.of(context)!;
    final h = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final m = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? l.timePm : l.timeAm;
    return '$h:$m $period';
  }

  String _formatCountdown(Duration d) {
    if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes % 60}m';
    if (d.inMinutes > 0) return '${d.inMinutes}m';
    return '${d.inSeconds}s';
  }

  Widget _tab(String label, IconData icon, int index, Color accent) {
    final cs = Theme.of(context).colorScheme;
    final selected = _tabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _tabIndex = index);
          PlayerSettings.setSleepTimerTab(index);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color:
                selected ? accent.withValues(alpha: 0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon,
                size: 15, color: selected ? accent : cs.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                  color: selected ? accent : cs.onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                )),
          ]),
        ),
      ),
    );
  }

  Widget _buildTimerTab(Color accent, TextTheme tt, AppLocalizations l) {
    final cs = Theme.of(context).colorScheme;
    return Column(children: [
      // Custom slider
      Text(l.minutesValue(_customMinutes.round()),
          style: TextStyle(
              color: accent,
              fontSize: 28,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()])),
      const SizedBox(height: 8),
      SliderTheme(
        data: SliderThemeData(
          activeTrackColor: accent,
          inactiveTrackColor: cs.onSurface.withValues(alpha: 0.1),
          thumbColor: accent,
          overlayColor: accent.withValues(alpha: 0.1),
          trackHeight: 4,
        ),
        child: Slider(
          value: _customMinutes,
          min: 1,
          max: 120,
          divisions: 119,
          onChanged: (v) => setState(() => _customMinutes = v),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(l.sleepTimerSheetMinShort(1),
              style: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.3), fontSize: 11)),
          Text(l.sleepTimerSheetMinShort(120),
              style: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.3), fontSize: 11)),
        ]),
      ),
      const SizedBox(height: 12),
      // Presets
      Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            for (final mins in [5, 10, 15, 30, 45, 60])
              _presetChip(accent, l.sleepTimerSheetMinShort(mins),
                  _customMinutes.round() == mins, () {
                setState(() => _customMinutes = mins.toDouble());
              }),
          ]),
      const SizedBox(height: 16),
      // Start button
      SizedBox(
          width: double.infinity,
          height: 44,
          child: FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: cs.surface,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            onPressed: () {
              PlayerSettings.setSleepTimerMinutes(_customMinutes.round());
              SleepTimerService()
                  .setTimeSleep(Duration(minutes: _customMinutes.round()));
              Navigator.pop(context);
            },
            child: Text(l.startMinTimer(_customMinutes.round()),
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          )),
    ]);
  }

  Widget _buildChapterTab(Color accent, TextTheme tt, AppLocalizations l) {
    final cs = Theme.of(context).colorScheme;
    return Column(children: [
      Text(l.sleepTimerSheetChaptersValue(_customChapters),
          style: TextStyle(
              color: accent, fontSize: 28, fontWeight: FontWeight.w700)),
      const SizedBox(height: 16),
      // Chapter count selector
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        _circleButton(
            Icons.remove_rounded,
            accent,
            _customChapters > 1
                ? () {
                    setState(() => _customChapters--);
                  }
                : null),
        const SizedBox(width: 32),
        _circleButton(
            Icons.add_rounded,
            accent,
            _customChapters < 20
                ? () {
                    setState(() => _customChapters++);
                  }
                : null),
      ]),
      const SizedBox(height: 12),
      // Quick presets
      Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            for (final ch in [1, 2, 3, 5])
              _presetChip(accent, l.sleepTimerSheetChaptersChip(ch),
                  _customChapters == ch, () {
                setState(() => _customChapters = ch);
              }),
          ]),
      const SizedBox(height: 16),
      // Start button
      SizedBox(
          width: double.infinity,
          height: 44,
          child: FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: cs.surface,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            onPressed: () {
              PlayerSettings.setSleepTimerChapters(_customChapters);
              SleepTimerService().setChapterSleep(_customChapters);
              Navigator.pop(context);
            },
            child: Text(l.sleepTimerSheetStartChapterSleep(_customChapters),
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          )),
    ]);
  }

  /// Format seconds as a human-readable label (e.g. "30s", "5m", "1m 30s").
  String _rewindLabel(int seconds, AppLocalizations l) {
    if (seconds == 0) return l.off;
    if (seconds < 60) return l.sleepTimerSheetSecondsShort(seconds);
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return s > 0
        ? l.sleepTimerSheetMinSecShort(m, s)
        : l.sleepTimerSheetMinShort(m);
  }

  Widget _buildRewindSection(Color accent, TextTheme tt, AppLocalizations l) {
    final cs = Theme.of(context).colorScheme;
    final isEnabled = _sleepRewindSeconds > 0;
    final rewindMinutes =
        (_sleepRewindSeconds / 60).clamp(0.0, _maxRewindMinutes.toDouble());

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(Icons.replay_rounded,
            size: 18,
            color: isEnabled ? accent : cs.onSurface.withValues(alpha: 0.24)),
        const SizedBox(width: 10),
        Expanded(
            child: Text(l.sleepTimerSheetRewindOnSleep,
                style: TextStyle(
                    color: isEnabled
                        ? cs.onSurface.withValues(alpha: 0.7)
                        : cs.onSurfaceVariant,
                    fontSize: 13,
                    fontWeight: FontWeight.w500))),
        Text(isEnabled ? _rewindLabel(_sleepRewindSeconds, l) : l.off,
            style: TextStyle(
                color: isEnabled ? accent : cs.onSurface.withValues(alpha: 0.3),
                fontSize: 13,
                fontWeight: FontWeight.w600)),
      ]),
      const SizedBox(height: 4),
      SliderTheme(
        data: SliderThemeData(
          activeTrackColor: accent,
          inactiveTrackColor: cs.onSurface.withValues(alpha: 0.1),
          thumbColor: accent,
          overlayColor: accent.withValues(alpha: 0.1),
          trackHeight: 4,
        ),
        child: Slider(
          value: rewindMinutes,
          min: 0,
          max: _maxRewindMinutes.toDouble(),
          divisions: _maxRewindMinutes,
          onChanged: (v) {
            final seconds = (v * 60).round();
            setState(() => _sleepRewindSeconds = seconds);
            PlayerSettings.setSleepRewindSeconds(seconds);
          },
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(l.off,
              style: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.3), fontSize: 11)),
          Text(l.sleepTimerSheetMinShort(120),
              style: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.3), fontSize: 11)),
        ]),
      ),
    ]);
  }

  Widget _buildShakeToggle(Color accent, TextTheme tt, AppLocalizations l) {
    final cs = Theme.of(context).colorScheme;
    final isEnabled = _shakeMode != 'off';
    String subtitle;
    if (_shakeMode == 'addTime') {
      subtitle = _tabIndex == 0
          ? l.sleepTimerSheetAddsMinutes(_shakeAddMinutes)
          : l.sleepTimerSheetAddsOneChapter;
    } else if (_shakeMode == 'resetTimer') {
      subtitle = l.sleepTimerSheetResetsToFull;
    } else {
      subtitle = l.disabled;
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(Icons.vibration_rounded,
            size: 18,
            color: isEnabled ? accent : cs.onSurface.withValues(alpha: 0.24)),
        const SizedBox(width: 10),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l.sleepTimerSheetShake,
              style: TextStyle(
                  color: isEnabled
                      ? cs.onSurface.withValues(alpha: 0.7)
                      : cs.onSurfaceVariant,
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
          Text(subtitle,
              style: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.3), fontSize: 11)),
        ])),
      ]),
      const SizedBox(height: 10),
      SizedBox(
        width: double.infinity,
        child: SegmentedButton<String>(
          showSelectedIcon: false,
          segments: [
            ButtonSegment(value: 'off', label: FittedBox(fit: BoxFit.scaleDown, child: Text(l.off, maxLines: 1))),
            ButtonSegment(value: 'addTime', label: FittedBox(fit: BoxFit.scaleDown, child: Text(l.shakeAddTime, maxLines: 1))),
            ButtonSegment(value: 'resetTimer', label: FittedBox(fit: BoxFit.scaleDown, child: Text(l.shakeReset, maxLines: 1))),
          ],
          selected: {_shakeMode},
          style: ButtonStyle(
            visualDensity: VisualDensity.compact,
            textStyle: WidgetStatePropertyAll(TextStyle(fontSize: 12)),
          ),
          onSelectionChanged: (v) {
            setState(() => _shakeMode = v.first);
            PlayerSettings.setShakeMode(v.first);
          },
        ),
      ),
      AnimatedOpacity(
        opacity: _shakeMode == 'addTime' ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: IgnorePointer(
          ignoring: _shakeMode != 'addTime',
          child: Column(children: [
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l.shakeAdds,
                    style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
                Text(l.minutesValue(_shakeAddMinutes),
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: accent,
                        fontSize: 12)),
              ],
            ),
            SliderTheme(
              data: SliderThemeData(
                activeTrackColor: accent,
                inactiveTrackColor: cs.onSurface.withValues(alpha: 0.1),
                thumbColor: accent,
                overlayColor: accent.withValues(alpha: 0.1),
                trackHeight: 4,
              ),
              child: Slider(
                value: _shakeAddMinutes.toDouble(),
                min: 1,
                max: 30,
                divisions: 29,
                onChanged: (v) {
                  setState(() => _shakeAddMinutes = v.round());
                  PlayerSettings.setShakeAddMinutes(v.round());
                },
              ),
            ),
          ]),
        ),
      ),
    ]);
  }

  Widget _circleButton(IconData icon, Color accent, VoidCallback? onTap) {
    final cs = Theme.of(context).colorScheme;
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: enabled
              ? accent.withValues(alpha: 0.15)
              : cs.onSurface.withValues(alpha: 0.04),
          shape: BoxShape.circle,
          border: Border.all(
              color: enabled
                  ? accent.withValues(alpha: 0.3)
                  : cs.onSurface.withValues(alpha: 0.06)),
        ),
        child: Icon(icon,
            color: enabled ? accent : cs.onSurface.withValues(alpha: 0.24),
            size: 24),
      ),
    );
  }

  Widget _presetChip(
      Color accent, String label, bool active, VoidCallback onTap) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: active
                ? accent.withValues(alpha: 0.2)
                : cs.onSurface.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: active
                    ? accent.withValues(alpha: 0.4)
                    : cs.onSurface.withValues(alpha: 0.1)),
          ),
          child: Text(label,
              style: TextStyle(
                  color: active ? accent : cs.onSurfaceVariant,
                  fontSize: 13,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w400)),
        ));
  }
}
