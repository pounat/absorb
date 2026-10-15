import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';

/// Small, dismissible in-context tip. Used for progressive feature discovery
/// (e.g. "Tap a card to resume, hold for details"). Each instance is gated on
/// its own [prefKey] so different hints can live and retire independently.
///
/// Returns an empty widget once the user has dismissed the hint, so it's safe
/// to inline inside a layout without branching.
class FeatureHint extends StatefulWidget {
  final String prefKey;
  final IconData icon;
  final String message;
  final EdgeInsetsGeometry padding;

  const FeatureHint({
    super.key,
    required this.prefKey,
    required this.message,
    this.icon = Icons.lightbulb_outline_rounded,
    this.padding = const EdgeInsets.fromLTRB(20, 8, 20, 4),
  });

  /// Bumped whenever [resetAll] runs, so live hint widgets re-read their
  /// dismissed state instead of staying hidden until the next cold start.
  static final ValueNotifier<int> resetTick = ValueNotifier<int>(0);

  /// Wipe all dismissal flags (and the welcome-dialog flag) and notify any
  /// currently-mounted hints to reappear without an app restart.
  static Future<void> resetAll() async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in prefs.getKeys()) {
      if (key.startsWith('hint_')) {
        await prefs.remove(key);
      }
    }
    await prefs.remove('has_seen_welcome');
    resetTick.value = resetTick.value + 1;
  }

  @override
  State<FeatureHint> createState() => _FeatureHintState();
}

class _FeatureHintState extends State<FeatureHint> {
  bool? _dismissed;

  @override
  void initState() {
    super.initState();
    _readState();
    FeatureHint.resetTick.addListener(_readState);
  }

  @override
  void dispose() {
    FeatureHint.resetTick.removeListener(_readState);
    super.dispose();
  }

  Future<void> _readState() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _dismissed = prefs.getBool(widget.prefKey) ?? false);
  }

  Future<void> _dismiss() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(widget.prefKey, true);
    if (mounted) setState(() => _dismissed = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_dismissed != false) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: widget.padding,
      child: Container(
        decoration: BoxDecoration(
          color: cs.primaryContainer.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: cs.primary.withValues(alpha: 0.25),
            width: 0.5,
          ),
        ),
        padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
        child: Row(
          children: [
            Icon(widget.icon, size: 16, color: cs.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(widget.message,
                  style: tt.bodySmall?.copyWith(
                    color: cs.onPrimaryContainer,
                    height: 1.25,
                  )),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 16),
              color: cs.onPrimaryContainer.withValues(alpha: 0.7),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              visualDensity: VisualDensity.compact,
              tooltip: AppLocalizations.of(context)!.dismiss,
              onPressed: _dismiss,
            ),
          ],
        ),
      ),
    );
  }
}
