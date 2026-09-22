import 'package:flutter/material.dart';
import 'package:flutter_chrome_cast/_session_manager/cast_session_manager.dart';
import 'package:get/get_rx/get_rx.dart';

/// A widget that provides volume control for Google Cast devices.
///
/// This widget displays a volume icon that, when tapped, shows a popup
/// with a slider to control the volume of the currently connected Cast device.
class GoogleCastVolume extends StatefulWidget {
  /// Color of the volume icon.
  final Color? iconColor;

  /// Size of the volume icon.
  final double? iconSize;

  /// Background color of the volume control popup.
  final Color? popupBackgroundColor;

  /// Color of the active portion of the volume slider.
  final Color? sliderActiveColor;

  /// Color of the inactive portion of the volume slider.
  final Color? sliderInactiveColor;

  /// Color of the volume slider thumb/handle.
  final Color? sliderThumbColor;

  /// Creates a Google Cast volume control widget.
  ///
  /// All styling parameters are optional and will use default Material Design
  /// colors if not specified.
  const GoogleCastVolume({
    super.key,
    this.iconColor,
    this.iconSize,
    this.popupBackgroundColor,
    this.sliderActiveColor,
    this.sliderInactiveColor,
    this.sliderThumbColor,
  });

  @override
  State<GoogleCastVolume> createState() => _GoogleCastVolumeState();
}

class _GoogleCastVolumeState extends State<GoogleCastVolume> {
  @override
  void initState() {
    GoogleCastSessionManager.instance.currentSessionStream.listen((event) {
      volumeLevel.value = event?.currentDeviceVolume ?? 0;
      volumeMuted.value = event?.currentDeviceMuted ?? false;
    });
    super.initState();
  }

  final volumeLevel = 0.5.obs;
  final volumeMuted = false.obs;
  bool isSliderTapDown = false;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      color: widget.popupBackgroundColor,
      icon: StreamBuilder(
          stream: volumeMuted.stream,
          builder: (context, snapshot) {
            return Icon(
              volumeMuted.value || volumeLevel.value == 0
                  ? Icons.volume_off
                  : Icons.volume_up,
              color: widget.iconColor ?? Colors.white,
              size: widget.iconSize ?? 44,
            );
          }),
      itemBuilder: (context) {
        return [
          PopupMenuItem(
            enabled: false,
            child: StreamBuilder(
              stream: volumeLevel.stream,
              builder: (context, snapshot) {
                return Slider(
                  value: volumeLevel.value,
                  onChanged: _onVolumeChanged,
                  onChangeStart: _onVolumeChangedStart,
                  onChangeEnd: _onVolumeChangedEnd,
                  activeColor: widget.sliderActiveColor,
                  inactiveColor: widget.sliderInactiveColor,
                  thumbColor: widget.sliderThumbColor,
                );
              },
            ),
          ),
        ];
      },
    );
  }

  void _onVolumeChangedEnd(double value) {
    isSliderTapDown = false;
    GoogleCastSessionManager.instance.setDeviceVolume(value);
  }

  void _onVolumeChangedStart(double value) {
    isSliderTapDown = true;
  }

  void _onVolumeChanged(double value) {
    volumeLevel.value = value;
  }
}
