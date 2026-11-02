import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'audio_player_service.dart';
import 'sleep_timer_service.dart';

/// Pushes the active playback snapshot to the paired Wear OS companion
/// (AbsorbWear) via the Wearable Data Layer.
///
/// Like [WearAuthService] this is best-effort and a no-op off Android.
/// We piggyback on the existing HomeWidgetService update cadence (~2s),
/// so the bandwidth profile is identical to what the home widget
/// already costs.
class WearPlayerService {
  WearPlayerService._();
  static final WearPlayerService instance = WearPlayerService._();

  static const MethodChannel _channel =
      MethodChannel('com.barnabas.absorb/wear_player');

  bool get _supported => !kIsWeb && Platform.isAndroid;

  bool _listening = false;
  String? _chaptersPublishedFor;

  /// Start taking the watch's extra actions (chapter skips, bookmark, sleep
  /// timer, seek). Safe to call more than once.
  void listen() {
    if (!_supported || _listening) return;
    _listening = true;
    _channel.setMethodCallHandler((call) async {
      if (call.method != 'command') return null;
      final args = Map<String, dynamic>.from(call.arguments as Map);
      await WearCommands.handle(args['name'] as String? ?? '', args);
      return true;
    });
  }

  /// The playing book's chapter list, sent once per book so the watch can
  /// show and jump between chapters while the phone plays.
  Future<void> publishChapters(String? itemId, List<dynamic> chapters) async {
    if (!_supported) return;
    if (itemId == null) {
      _chaptersPublishedFor = null;
      return;
    }
    if (_chaptersPublishedFor == itemId) return;
    _chaptersPublishedFor = itemId;
    final list = <Map<String, dynamic>>[];
    for (final c in chapters) {
      if (c is! Map) continue;
      list.add({
        'title': c['title']?.toString() ?? '',
        'start': (c['start'] as num?)?.toDouble() ?? 0.0,
        'end': (c['end'] as num?)?.toDouble() ?? 0.0,
      });
    }
    try {
      await _channel.invokeMethod<void>('publishChapters', {
        'itemId': itemId,
        'chapters': jsonEncode(list),
      });
    } catch (e) {
      debugPrint('[WearPlayer] publishChapters failed: $e');
    }
  }

  Future<void> publish({
    required bool hasBook,
    String? itemId,
    String? title,
    String? author,
    String? chapter,
    required bool isPlaying,
    required int positionMs,
    required int durationMs,
    required double speed,
    required int skipBackSec,
    required int skipForwardSec,
    int chapterStartMs = 0,
    int chapterEndMs = 0,
    bool autoRewindEnabled = true,
    double autoRewindMinSec = 1.0,
    double autoRewindMaxSec = 30.0,
    double autoRewindDelaySec = 0.0,
    bool autoRewindChapterBarrier = false,
    bool autoRewindSessionStart = false,
    bool skipChapterBarrier = true,
    bool speedAdjustedTime = true,
    int chapterIndex = -1,
    int chapterCount = 0,
    String? sleepMode,
    int sleepEndsAtMs = 0,
    int sleepChaptersLeft = 0,
    int sleepAddMinutes = 5,
    List<double> speedPresets = const [],
    int themeColor = 0,
  }) async {
    if (!_supported) return;
    try {
      await _channel.invokeMethod<void>('publish', {
        'hasBook': hasBook,
        'itemId': itemId,
        'title': title,
        'author': author,
        'chapter': chapter,
        'isPlaying': isPlaying,
        'positionMs': positionMs,
        'durationMs': durationMs,
        'speed': speed,
        'skipBackSec': skipBackSec,
        'skipForwardSec': skipForwardSec,
        'chapterStartMs': chapterStartMs,
        'chapterEndMs': chapterEndMs,
        'autoRewindEnabled': autoRewindEnabled,
        'autoRewindMinSec': autoRewindMinSec,
        'autoRewindMaxSec': autoRewindMaxSec,
        'autoRewindDelaySec': autoRewindDelaySec,
        'autoRewindChapterBarrier': autoRewindChapterBarrier,
        'autoRewindSessionStart': autoRewindSessionStart,
        'skipChapterBarrier': skipChapterBarrier,
        'speedAdjustedTime': speedAdjustedTime,
        'chapterIndex': chapterIndex,
        'chapterCount': chapterCount,
        'sleepMode': sleepMode,
        'sleepEndsAtMs': sleepEndsAtMs,
        'sleepChaptersLeft': sleepChaptersLeft,
        'sleepAddMinutes': sleepAddMinutes,
        'speedPresets': speedPresets,
        'themeColor': themeColor,
      });
    } catch (e) {
      debugPrint('[WearPlayer] publish failed: $e');
    }
  }
}

/// The watch's extra player actions, the same whether they arrive over the
/// wear_player channel (app up) or as a widget-style launch URI (app woken
/// for them).
class WearCommands {
  WearCommands._();

  static Future<void> handle(String name, Map<String, dynamic> args) async {
    debugPrint('[WearPlayer] command $name $args');
    final player = AudioPlayerService();
    switch (name) {
      case 'next_chapter':
        if (player.hasBook) await player.skipToNextChapter();
        break;
      case 'prev_chapter':
        if (player.hasBook) await player.skipToPreviousChapter();
        break;
      case 'bookmark':
        if (player.hasBook) await AudioPlayerService.handler?.customAction('bookmark');
        break;
      case 'stop':
        if (player.hasBook) await player.stop();
        break;
      case 'speed':
        final speed = _double(args['speed']);
        if (player.hasBook && speed != null && speed > 0) await player.setSpeed(speed);
        break;
      case 'seek':
        final ms = _int(args['positionMs']);
        if (player.hasBook && ms != null) {
          await player.seekTo(Duration(milliseconds: ms), logDetail: 'watch');
        }
        break;
      case 'sleep':
        final sleep = SleepTimerService();
        final minutes = _int(args['minutes']);
        final chapters = _int(args['chapters']);
        final add = _int(args['add']);
        if (args['cancel'] == true || args['cancel'] == 'true') {
          sleep.cancel();
        } else if (minutes != null && minutes > 0) {
          sleep.setTimeSleep(Duration(minutes: minutes));
        } else if (chapters != null && chapters > 0) {
          sleep.setChapterSleep(chapters);
        } else if (add != null && add > 0) {
          sleep.addTime(Duration(minutes: add));
        }
        break;
    }
  }

  static int? _int(Object? v) {
    if (v == null) return null;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  static double? _double(Object? v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }
}
