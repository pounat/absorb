import 'dart:async';
import 'package:flutter/foundation.dart';

import 'api_service.dart';

// GMS-free stub of ChromecastService for the F-Droid flavor. Chromecast needs
// Google Play Services, which F-Droid disallows, so this no-op twin replaces
// the real service (and `flutter_chrome_cast` is stripped from pubspec) at
// build time via the fdroiddata recipe. The public surface mirrors the real
// service so every caller compiles unchanged; everything reports
// "not connected" so the cast UI stays dormant.
//
// The two plugin-typed members of the real service (`devicesStream`,
// `connectToDevice`) are intentionally absent — they're only referenced by the
// real chromecast_button.dart, which is swapped for its stub alongside this.

enum CastConnectionState { disconnected, connecting, connected }

enum CastPlaybackState { idle, loading, playing, paused, buffering }

class ChromecastService extends ChangeNotifier {
  static final ChromecastService _instance = ChromecastService._();
  factory ChromecastService() => _instance;
  ChromecastService._();

  /// GMS-free build: Chromecast is unavailable, so the UI hides every cast
  /// entry point (the cast button is filtered out of the card action menu).
  static const bool castSupported = false;

  CastConnectionState get connectionState => CastConnectionState.disconnected;
  CastPlaybackState get playbackState => CastPlaybackState.idle;
  bool get isConnected => false;
  bool get isCasting => false;
  bool get isReceiverActive => false;
  bool get isPlaying => false;

  String? get castingItemId => null;
  String? get castingEpisodeId => null;
  String? get castingTitle => null;
  String? get castingAuthor => null;
  String? get castingCoverUrl => null;
  double get castingDuration => 0;
  List<dynamic> get castingChapters => const [];
  Duration get castPosition => Duration.zero;
  String? get connectedDeviceName => null;

  Stream<Duration>? get castPositionStream => null;

  String? get currentChapterTitle => null;
  Map<String, dynamic>? get currentChapter => null;

  double get volume => 1.0;
  double get castSpeed => 1.0;

  static void setOnBookFinishedCallback(void Function(String itemId)? cb) {}
  static void setOnPlaybackStateChangedCallback(
    void Function(bool isPlaying)? cb,
  ) {}

  Future<void> init() async {}

  Future<void> disconnect() async {}

  Future<bool> castItem({
    required ApiService api,
    required String itemId,
    required String title,
    required String author,
    required String? coverUrl,
    required double totalDuration,
    required List<dynamic> chapters,
    double startTime = 0,
    String? episodeId,
  }) async => false;

  Future<void> setVolume(double value) async {}

  Future<void> play() async {}
  Future<void> pause() async {}
  Future<void> togglePlayPause() async {}

  Future<void> seekTo(Duration position) async {}
  Future<void> skipForward([int s = 30]) async {}
  Future<void> skipBackward([int s = 10]) async {}

  Future<void> setSpeed(double speed) async {}

  Future<void> stopCasting() async {}

  Future<void> skipToNextChapter() async {}
  Future<void> skipToPreviousChapter() async {}
}
