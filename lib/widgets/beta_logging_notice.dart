import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../build_info.dart';
import '../l10n/app_localizations.dart';
import '../services/player_settings.dart';

/// Beta builds start with logging on, so testers have logs ready to send when
/// something goes wrong, and say so once after the update.
class BetaLoggingNotice {
  static const _appliedKey = 'beta_logging_default_applied';
  static const _pendingKey = 'beta_logging_notice_pending';

  /// Call before the log service starts. It only ever runs once, and never
  /// over a switch someone already flipped, so turning logging off sticks
  /// through later betas.
  static Future<void> applyDefault(String version) async {
    if (kIsWeb || betaNumberFor(version) == null) return;
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_appliedKey) == true) return;
    await prefs.setBool(_appliedKey, true);
    if (await PlayerSettings.loggingChosen()) return;
    await PlayerSettings.setLoggingEnabled(true);
    await prefs.setBool(_pendingKey, true);
  }

  static Future<void> showIfPending(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_pendingKey) != true) return;
    if (!await PlayerSettings.getLoggingEnabled()) {
      await prefs.remove(_pendingKey);
      return;
    }
    await Future.delayed(const Duration(milliseconds: 600));
    if (!context.mounted) return;
    await prefs.remove(_pendingKey);
    if (!context.mounted) return;
    final l = AppLocalizations.of(context)!;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.article_outlined),
        title: Text(l.betaLoggingTitle),
        content: Text(l.betaLoggingContent),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.gotIt),
          ),
        ],
      ),
    );
  }
}
