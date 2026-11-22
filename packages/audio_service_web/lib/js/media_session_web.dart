@JS()
library;

import 'dart:js_interop';

abstract final class MediaSessionPlaybackState {
  static const none = 'none';
  static const paused = 'paused';
  static const playing = 'playing';
}

abstract final class MediaSessionActions {
  static const play = 'play';
  static const pause = 'pause';
  static const seekbackward = 'seekbackward';
  static const seekforward = 'seekforward';
  static const previoustrack = 'previoustrack';
  static const nexttrack = 'nexttrack';
  static const stop = 'stop';
  static const seekto = 'seekto';
}

@JS()
@anonymous
extension type MediaSessionActionDetails._(JSObject _) implements JSObject {
  external String get action;
  external bool? get fastSeek;
  external double? get seekOffset;
  external double? get seekTime;
}
