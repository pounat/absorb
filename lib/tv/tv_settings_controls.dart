import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/audio_player_service.dart';
import '../services/sleep_timer_service.dart';
import 'tv_focusable.dart';
import 'tv_night_mode.dart';

/// A pill that steps through [values] on OK, saving each pick.
class _StepPill<T> extends StatelessWidget {
  final IconData icon;
  final String label;
  final List<T> values;
  final T value;
  final ValueChanged<T> onPick;

  const _StepPill({
    required this.icon,
    required this.label,
    required this.values,
    required this.value,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final i = values.indexOf(value);
    return TvPillButton(
      icon: icon,
      label: label,
      onSelect: () => onPick(values[(i + 1) % values.length]),
    );
  }
}

/// Speed for books never played before, and the rewind when resuming
/// after a pause.
class TvPlaybackExtras extends StatefulWidget {
  const TvPlaybackExtras({super.key});

  @override
  State<TvPlaybackExtras> createState() => _TvPlaybackExtrasState();
}

class _TvPlaybackExtrasState extends State<TvPlaybackExtras> {
  static const _speeds = [0.8, 0.9, 1.0, 1.1, 1.2, 1.25, 1.3, 1.5, 1.75, 2.0];
  static const _rewinds = [0, 5, 10, 15, 30];
  double? _speed;
  AutoRewindSettings? _rewind;

  @override
  void initState() {
    super.initState();
    PlayerSettings.getDefaultSpeed().then((v) {
      if (mounted) setState(() => _speed = _speeds.contains(v) ? v : 1.0);
    });
    AutoRewindSettings.load().then((v) {
      if (mounted) setState(() => _rewind = v);
    });
  }

  int get _rewindStep {
    final r = _rewind;
    if (r == null || !r.enabled) return 0;
    return _rewinds.lastWhere((s) => s <= r.maxRewind.round(), orElse: () => 5);
  }

  void _setRewind(int seconds) {
    final r = _rewind ?? const AutoRewindSettings();
    final next = AutoRewindSettings(
      enabled: seconds > 0,
      minRewind: seconds > 0 ? (r.minRewind > seconds ? seconds.toDouble() : r.minRewind) : r.minRewind,
      maxRewind: seconds > 0 ? seconds.toDouble() : r.maxRewind,
      activationDelay: r.activationDelay,
      chapterBarrier: r.chapterBarrier,
      sessionStartRewind: r.sessionStartRewind,
    );
    setState(() => _rewind = next);
    next.save();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final speed = _speed;
    if (speed == null || _rewind == null) return const SizedBox(height: 48);
    final rewind = _rewindStep;
    return Wrap(spacing: 14, runSpacing: 14, children: [
      _StepPill<double>(
        icon: Icons.speed_rounded,
        label: l.tvDefaultSpeed(speed.toStringAsFixed(2).replaceAll(RegExp(r'0$'), '')),
        values: _speeds,
        value: speed,
        onPick: (v) {
          setState(() => _speed = v);
          PlayerSettings.setDefaultSpeed(v);
        },
      ),
      _StepPill<int>(
        icon: Icons.history_rounded,
        label: rewind == 0 ? l.tvRewindOff : l.tvRewindOnResume(rewind),
        values: _rewinds,
        value: rewind,
        onPick: _setRewind,
      ),
    ]);
  }
}

/// The sleep timer's usual length, the window it starts itself in, and
/// night mode coming on by itself while one runs.
class TvSleepSettings extends StatefulWidget {
  const TvSleepSettings({super.key});

  @override
  State<TvSleepSettings> createState() => _TvSleepSettingsState();
}

class _TvSleepSettingsState extends State<TvSleepSettings> {
  static const _lengths = [10, 15, 20, 30, 45, 60, 90];
  static const _starts = [20, 21, 22, 23, 0, 1];
  static const _ends = [5, 6, 7, 8, 9];
  static const _nights = [0, 1, 2, 5, 10];
  int? _length;
  AutoSleepSettings? _auto;

  @override
  void initState() {
    super.initState();
    PlayerSettings.getSleepTimerMinutes().then((v) {
      if (mounted) setState(() => _length = _lengths.contains(v) ? v : 30);
    });
    AutoSleepSettings.load().then((v) {
      if (mounted) setState(() => _auto = v);
    });
  }

  void _saveAuto(AutoSleepSettings s) {
    setState(() => _auto = s);
    s.save();
    SleepTimerService().updateAutoSleepSettings(s);
  }

  static String _hour(int h) => AutoSleepSettings(startHour: h).startLabel;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final length = _length;
    final auto = _auto;
    if (length == null || auto == null) return const SizedBox(height: 48);
    return ValueListenableBuilder<int>(
      valueListenable: TvAutoNight.minutes,
      builder: (context, night, _) => Wrap(spacing: 14, runSpacing: 14, children: [
        _StepPill<int>(
          icon: Icons.nightlight_round_outlined,
          label: l.tvSleepDefault(length),
          values: _lengths,
          value: length,
          onPick: (v) {
            setState(() => _length = v);
            PlayerSettings.setSleepTimerMinutes(v);
          },
        ),
        TvPillButton(
          icon: Icons.schedule_rounded,
          label: auto.enabled ? l.tvAutoSleepOn : l.tvAutoSleepOff,
          selected: auto.enabled,
          onSelect: () => _saveAuto(auto.copyWith(enabled: !auto.enabled)),
        ),
        if (auto.enabled) ...[
          _StepPill<int>(
            icon: Icons.bedtime_outlined,
            label: l.tvAutoSleepFrom(_hour(auto.startHour)),
            values: _starts,
            value: _starts.contains(auto.startHour) ? auto.startHour : 22,
            onPick: (h) => _saveAuto(auto.copyWith(startHour: h, startMinute: 0)),
          ),
          _StepPill<int>(
            icon: Icons.wb_twilight_rounded,
            label: l.tvAutoSleepUntil(_hour(auto.endHour)),
            values: _ends,
            value: _ends.contains(auto.endHour) ? auto.endHour : 6,
            onPick: (h) => _saveAuto(auto.copyWith(endHour: h, endMinute: 0)),
          ),
        ],
        _StepPill<int>(
          icon: Icons.bedtime_rounded,
          label: night == 0 ? l.tvAutoNightOff : l.tvAutoNightAfter(night),
          values: _nights,
          value: _nights.contains(night) ? night : 2,
          onPick: TvAutoNight.setMinutes,
        ),
      ]),
    );
  }
}
