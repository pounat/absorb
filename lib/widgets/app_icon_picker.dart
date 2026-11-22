import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/app_icon_service.dart';
import '../utils/app_icon_palette.dart';
import '../utils/app_platform.dart';
import 'overlay_toast.dart';

const _isDevBuild = bool.fromEnvironment('DEV_BUILD');

String appIconName(AppLocalizations l, String id) => switch (id) {
      'light' => l.appIconLight,
      'teal' => l.appIconTeal,
      'blue' => l.appIconBlue,
      'sky' => l.appIconSky,
      'purple' => l.appIconPurple,
      'pink' => l.appIconPink,
      'red' => l.appIconRed,
      'orange' => l.appIconOrange,
      'yellow' => l.appIconYellow,
      'green' => l.appIconGreen,
      _ => _isDevBuild ? l.appIconAurora : l.appIconClassic,
    };

/// An app icon color drawn from the same numbers as the real icon files.
class AppIconPreview extends StatelessWidget {
  final AppIconOption option;
  final double size;

  const AppIconPreview({super.key, required this.option, this.size = 56});

  @override
  Widget build(BuildContext context) => SizedBox.square(
        dimension: size,
        child: CustomPaint(painter: _AppIconPainter(option)),
      );
}

class _AppIconPainter extends CustomPainter {
  final AppIconOption option;
  _AppIconPainter(this.option);

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 1024;
    final shape = RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(size.width * 0.225));
    canvas.drawRRect(shape, Paint()..color = Color(option.background));
    for (var i = 0; i < appIconBars.length; i++) {
      final b = appIconBars[i];
      final bar = RRect.fromLTRBR(
        (b.centerX - appIconBarWidth / 2) * k,
        b.top * k,
        (b.centerX + appIconBarWidth / 2) * k,
        b.bottom * k,
        Radius.circular(appIconBarWidth / 2 * k),
      );
      canvas.drawRRect(bar, Paint()..color = Color(option.barColor(i)));
    }
  }

  @override
  bool shouldRepaint(_AppIconPainter old) => old.option != option;
}

/// The options as this build offers them: the dev build's Classic is Aurora.
List<AppIconOption> get pickableAppIcons =>
    _isDevBuild ? [appIconAurora, ...appIconOptions.skip(1)] : appIconOptions;

AppIconOption appIconOption(String id) =>
    pickableAppIcons.firstWhere((o) => o.id == id, orElse: () => pickableAppIcons.first);

Future<void> showAppIconPicker(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      final l = AppLocalizations.of(sheetContext)!;
      final cs = Theme.of(sheetContext).colorScheme;
      final tt = Theme.of(sheetContext).textTheme;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: ValueListenableBuilder<String>(
            valueListenable: AppIconService.current,
            builder: (context, current, _) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.appIconLabel, style: tt.titleMedium),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 16,
                  children: [
                    for (final o in pickableAppIcons)
                      SizedBox(
                        width: 64,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: current == o.id
                              ? null
                              : () async {
                                  final ok = await AppIconService.set(o.id);
                                  if (!ok && sheetContext.mounted) {
                                    showOverlayToast(sheetContext, l.appIconFailed,
                                        icon: Icons.error_outline_rounded);
                                  }
                                },
                          child: Column(children: [
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: current == o.id ? cs.primary : Colors.transparent,
                                  width: 2.5,
                                ),
                              ),
                              child: AppIconPreview(option: o, size: 52),
                            ),
                            const SizedBox(height: 4),
                            Text(appIconName(l, o.id),
                                style: tt.labelSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                          ]),
                        ),
                      ),
                  ],
                ),
                if (AppPlatform.isAndroid) ...[
                  const SizedBox(height: 16),
                  Text(l.appIconAndroidNote, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                ],
              ],
            ),
          ),
        ),
      );
    },
  );
}
