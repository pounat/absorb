import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../build_info.dart';
import '../l10n/app_localizations.dart';
import 'welcome_sheet.dart';

/// After an update, offers the GitHub release notes for the new build.
class WhatsNewPrompt {
  static const _lastBuildKey = 'whats_new_last_build';
  static const _enabledKey = 'whats_new_enabled';
  static const _isDevBuild = bool.fromEnvironment('DEV_BUILD');

  /// Some people read the release notes on GitHub anyway, so the prompt can
  /// be turned off, from the prompt itself or in Settings.
  static Future<bool> isEnabled() async =>
      (await SharedPreferences.getInstance()).getBool(_enabledKey) ?? true;

  static Future<void> setEnabled(bool on) async =>
      (await SharedPreferences.getInstance()).setBool(_enabledKey, on);

  /// Call before [WelcomeSheet.showIfNeeded]: a fresh install hasn't seen the
  /// welcome yet, and that's how it's told apart from an update.
  static Future<void> showIfUpdated(BuildContext context) async {
    if (kIsWeb || _isDevBuild) return;
    final prefs = await SharedPreferences.getInstance();
    final freshInstall = prefs.getBool(WelcomeSheet.prefKey) != true;
    final info = await PackageInfo.fromPlatform();
    final build = int.tryParse(info.buildNumber);
    if (build == null) return;
    final lastBuild = prefs.getInt(_lastBuildKey);
    await prefs.setInt(_lastBuildKey, build);
    if (freshInstall || (lastBuild != null && build <= lastBuild)) return;
    if (prefs.getBool(_enabledKey) == false) return;

    final beta = betaNumberFor(info.version);
    final tag = beta == null ? 'v${info.version}' : 'v${info.version}-$build';
    final url = Uri.parse('https://github.com/pounat/absorb/releases/tag/$tag');

    // Let launch settle so this doesn't land on top of the first frames.
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!context.mounted) return;
    final l = AppLocalizations.of(context)!;
    final version =
        beta == null ? info.version : '${info.version} (${l.betaLabel(beta)})';
    var keepShowing = true;
    final open = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.whatsNewTitle),
        content: StatefulBuilder(
          builder: (ctx, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.whatsNewContent(version)),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l.whatsNewKeepShowing),
                subtitle: Text(l.whatsNewKeepShowingHint),
                value: keepShowing,
                onChanged: (v) {
                  setDialogState(() => keepShowing = v);
                  setEnabled(v);
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.later),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.whatsNewButton),
          ),
        ],
      ),
    );
    if (open == true) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}
