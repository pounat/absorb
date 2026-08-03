import 'package:flutter/material.dart';
import 'package:flutter_chrome_cast/flutter_chrome_cast.dart';
import '../l10n/app_localizations.dart';
import '../services/chromecast_service.dart';
import '../services/api_service.dart';
import 'adaptive_modal.dart';

/// Shows a device picker. If castAfter params are provided, automatically
/// casts the book after connecting to the selected device.
void showCastDevicePicker(
  BuildContext context, {
  ApiService? api,
  String? itemId,
  String? title,
  String? author,
  String? coverUrl,
  double? totalDuration,
  List<dynamic>? chapters,
  String? episodeId,
}) {
  final cast = ChromecastService();
  showAdaptiveActionMenu(
    context: context,
    backgroundColor: Theme.of(context).bottomSheetTheme.backgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      final cs = Theme.of(ctx).colorScheme;
      final l = AppLocalizations.of(ctx)!;
      return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 36, height: 4, decoration: BoxDecoration(color: cs.onSurface.withValues(alpha: 0.24), borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Text(l.castToDevice, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: cs.onSurface)),
            const SizedBox(height: 16),
            Flexible(
              child: StreamBuilder<List<GoogleCastDevice>>(
                stream: cast.devicesStream,
                builder: (_, snap) {
                  final devices = snap.data ?? [];
                  if (devices.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: cs.onSurfaceVariant)),
                          const SizedBox(height: 12),
                          Text(l.searchingForCastDevices, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: devices.length,
                    itemBuilder: (_, i) {
                      final device = devices[i];
                      return ListTile(
                        leading: Icon(Icons.cast_rounded, color: cs.onSurfaceVariant),
                        title: Text(device.friendlyName, style: TextStyle(color: cs.onSurface)),
                        subtitle: Text(device.modelName ?? '', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
                        onTap: () {
                          Navigator.pop(ctx);
                          cast.connectToDevice(device);
                          if (api != null && itemId != null) {
                            _waitAndCast(cast, api: api, itemId: itemId,
                              title: title ?? '', author: author ?? '',
                              coverUrl: coverUrl, totalDuration: totalDuration ?? 0,
                              chapters: chapters ?? [], episodeId: episodeId);
                          }
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      );
    },
  );
}

/// Wait for connection to establish, then cast the item.
Future<void> _waitAndCast(
  ChromecastService cast, {
  required ApiService api,
  required String itemId,
  required String title,
  required String author,
  required String? coverUrl,
  required double totalDuration,
  required List<dynamic> chapters,
  String? episodeId,
}) async {
  // Poll for connection (up to 15s)
  if (!cast.isConnected) {
    for (int i = 0; i < 30; i++) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (cast.isConnected) break;
    }
    if (!cast.isConnected) {
      debugPrint('[Cast] Connection timeout — giving up auto-cast');
      return;
    }
  }

  // Small delay to let session fully initialise
  await Future.delayed(const Duration(milliseconds: 500));
  cast.castItem(api: api, itemId: itemId, title: title, author: author,
    coverUrl: coverUrl, totalDuration: totalDuration, chapters: chapters,
    episodeId: episodeId);
}

/// Bottom sheet with cast volume, stop, and disconnect controls.
class CastControlSheet extends StatelessWidget {
  const CastControlSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ChromecastService(),
      builder: (context, _) {
        final cast = ChromecastService();
        final accent = Theme.of(context).colorScheme.primary;
        final l = AppLocalizations.of(context)!;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 20),

                Row(children: [
                  Icon(Icons.cast_connected_rounded, size: 20, color: accent),
                  const SizedBox(width: 10),
                  Expanded(child: Text(cast.connectedDeviceName ?? l.castDevice,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: accent), overflow: TextOverflow.ellipsis)),
                ]),

                const SizedBox(height: 16),
                _CastVolumeControl(cast: cast, accent: accent),

                const SizedBox(height: 20),
                Row(children: [
                  if (cast.isCasting) ...[
                    Expanded(child: OutlinedButton.icon(
                      onPressed: () { cast.stopCasting(); Navigator.of(context).pop(); },
                      icon: const Icon(Icons.stop_rounded, size: 18), label: Text(l.stopCasting),
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.white60, side: const BorderSide(color: Colors.white12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
                    const SizedBox(width: 12),
                  ],
                  Expanded(child: OutlinedButton.icon(
                    onPressed: () { cast.disconnect(); Navigator.of(context).pop(); },
                    icon: const Icon(Icons.close_rounded, size: 18), label: Text(l.disconnect),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent.withValues(alpha: 0.8),
                      side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.3)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
                ]),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Cast Volume Control ────────────────────────────────────

class _CastVolumeControl extends StatefulWidget {
  final ChromecastService cast;
  final Color accent;
  const _CastVolumeControl({required this.cast, required this.accent});

  @override
  State<_CastVolumeControl> createState() => _CastVolumeControlState();
}

class _CastVolumeControlState extends State<_CastVolumeControl> {
  late double _localVolume;
  bool _dragging = false;

  @override
  void initState() {
    super.initState();
    _localVolume = widget.cast.volume;
  }

  @override
  Widget build(BuildContext context) {
    final vol = _dragging ? _localVolume : widget.cast.volume;
    return Row(
      children: [
        Icon(
          vol <= 0.01 ? Icons.volume_off_rounded
            : vol < 0.5 ? Icons.volume_down_rounded
            : Icons.volume_up_rounded,
          size: 18, color: Colors.white54,
        ),
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              activeTrackColor: widget.accent,
              inactiveTrackColor: Colors.white12,
              thumbColor: widget.accent,
              overlayColor: widget.accent.withValues(alpha: 0.15),
            ),
            child: Slider(
              value: vol.clamp(0.0, 1.0),
              min: 0.0,
              max: 1.0,
              onChangeStart: (_) => _dragging = true,
              onChanged: (v) => setState(() => _localVolume = v),
              onChangeEnd: (v) {
                _dragging = false;
                widget.cast.setVolume(v);
              },
            ),
          ),
        ),
      ],
    );
  }
}
