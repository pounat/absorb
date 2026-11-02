// ignore_for_file: experimental_member_use

import 'package:audio_session/audio_session.dart';

/// Outputs whose removal means the audio lost its way out. No bluetoothSco:
/// that's the call/intercom link, books never play over it, and a helmet
/// drops and re-adds it on a timer while its media link keeps playing (#369).
const Set<AudioDeviceType> externalAudioOutputTypes = {
  AudioDeviceType.bluetoothA2dp,
  AudioDeviceType.bluetoothLe,
  AudioDeviceType.wiredHeadset,
  AudioDeviceType.wiredHeadphones,
  AudioDeviceType.usbAudio,
  AudioDeviceType.hearingAid,
  AudioDeviceType.carAudio,
};
