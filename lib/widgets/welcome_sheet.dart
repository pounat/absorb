import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';

/// Shows a one-time welcome dialog explaining the Absorb terminology and a
/// couple of essential gestures. Kept short on purpose - the previous version
/// was a long modal sheet that users tended to dismiss without reading.
class WelcomeSheet {
  static const prefKey = 'has_seen_welcome';

  static Future<void> showIfNeeded(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(prefKey) == true) return;
    await prefs.setBool(prefKey, true);
    if (!context.mounted) return;
    // Small delay so the app finishes its initial layout first
    await Future.delayed(const Duration(milliseconds: 800));
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (_) => const _WelcomeDialog(),
    );
  }
}

class _WelcomeDialog extends StatelessWidget {
  const _WelcomeDialog();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;

    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
      title: Row(children: [
        Icon(Icons.waves_rounded, color: cs.primary, size: 26),
        const SizedBox(width: 10),
        Expanded(
          child: Text(l.welcomeToAbsorb,
              style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        ),
      ]),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.welcomeTagline,
                style: tt.bodySmall
                    ?.copyWith(color: cs.onSurface.withValues(alpha: 0.6))),
            const SizedBox(height: 18),
            _section(
              cs, tt,
              icon: Icons.menu_book_rounded,
              title: l.welcomeAbsorbingTitle,
              body: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.welcomeAbsorbingIntro,
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.7),
                        height: 1.45,
                      )),
                  const SizedBox(height: 6),
                  _bullet(cs, tt, l.welcomeAbsorbingTabBullet),
                  _bullet(cs, tt, l.welcomeAbsorbButtonBullet),
                  _bullet(cs, tt, l.welcomeFullyAbsorbBullet),
                ],
              ),
            ),
            _section(
              cs, tt,
              icon: Icons.touch_app_rounded,
              title: l.welcomeGettingAroundTitle,
              body: Text(l.welcomeGettingAroundBody,
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.7),
                    height: 1.45,
                  )),
            ),
            _section(
              cs, tt,
              icon: Icons.settings_rounded,
              title: l.welcomeMakeItYoursTitle,
              body: Text(l.welcomeMakeItYoursBody,
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.7),
                    height: 1.45,
                  )),
            ),
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.getStarted),
        ),
      ],
    );
  }

  Widget _section(ColorScheme cs, TextTheme tt, {
    required IconData icon,
    required String title,
    required Widget body,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 16, color: cs.primary),
            const SizedBox(width: 8),
            Text(title,
                style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 24),
            child: body,
          ),
        ],
      ),
    );
  }

  Widget _bullet(ColorScheme cs, TextTheme tt, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6, right: 8),
            child: Container(
              width: 4, height: 4,
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Expanded(
            child: Text(text,
                style: tt.bodySmall?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.7),
                  height: 1.4,
                )),
          ),
        ],
      ),
    );
  }
}
