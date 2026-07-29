// ignore_for_file: experimental_member_use

import 'package:audio_session/audio_session.dart';

const Set<AudioDeviceType> externalAudioOutputTypes = {
  AudioDeviceType.bluetoothA2dp,
  AudioDeviceType.bluetoothSco,
  AudioDeviceType.bluetoothLe,
  AudioDeviceType.wiredHeadset,
  AudioDeviceType.wiredHeadphones,
  AudioDeviceType.usbAudio,
  AudioDeviceType.hearingAid,
  AudioDeviceType.carAudio,
};
