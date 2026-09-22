import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import '../services/offline_source.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/audio_player_service.dart';
import '../widgets/adaptive_modal.dart';
import '../services/chapter_start_finder.dart';
import '../services/download_service.dart';
import '../services/remote_audio_slice.dart';
import '../services/transcription_service.dart';
import '../widgets/overlay_toast.dart';

/// Mutable working copy of one chapter. [uid] is a stable identity that
/// survives reindexing/add/remove (used for controllers + locks); [id] is the
/// positional index recomputed on every change and sent to the server.
class _Ch {
  final int uid;
  int id;
  double start;
  double end;
  String title;
  String? error;
  _Ch({
    required this.uid,
    required this.id,
    required this.start,
    required this.end,
    required this.title,
  });
}

/// Standalone full-screen wrapper around [ChapterEditBody]. Kept for direct
/// navigation; the unified editor embeds [ChapterEditBody] as a tab instead.
class ChapterEditorScreen extends StatelessWidget {
  final String itemId;
  final String bookTitle;
  const ChapterEditorScreen({super.key, required this.itemId, required this.bookTitle});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l.chapterEditorTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            Text(bookTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          ],
        ),
      ),
      body: ChapterEditBody(itemId: itemId, bookTitle: bookTitle),
    );
  }
}

/// The editor body, embeddable as a tab. Mirrors the ABS web editor: edit
/// start/title, add/insert/remove, lock, shift times, set-from-tracks, Audnexus
/// lookup, play-preview with scrubbing, and save / reset / remove-all.
class ChapterEditBody extends StatefulWidget {
  final String itemId;
  final String bookTitle;
  const ChapterEditBody({super.key, required this.itemId, required this.bookTitle});

  @override
  State<ChapterEditBody> createState() => _ChapterEditBodyState();
}

class _ChapterEditBodyState extends State<ChapterEditBody>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  bool _loading = true;
  bool _saving = false;
  String? _loadError;

  double _duration = 0;
  List<Map<String, dynamic>> _audioFiles = [];
  List<Map<String, dynamic>> _originalChapters = []; // raw server chapters
  final List<_Ch> _chapters = [];
  final Map<int, TextEditingController> _titleCtl = {}; // keyed by uid
  final Set<int> _locked = {}; // keyed by uid
  int _uid = 0;

  bool _showSeconds = false;
  bool _showShift = false;
  final TextEditingController _shiftCtl = TextEditingController(text: '0');
  final TextEditingController _bulkCtl = TextEditingController();
  final ScrollController _listScroll = ScrollController();
  bool _hasChanges = false;
  String? _asin;
  List<Map<String, dynamic>> _tracks = [];

  // Preview player - a separate just_audio instance (works on iOS + Android,
  // independent of the main native/ExoPlayer engine). Main playback is paused
  // while previewing and restored when leaving the screen.
  AudioPlayer? _preview;
  StreamSubscription<Duration>? _previewPosSub;
  StreamSubscription<PlayerState>? _previewStateSub;
  int? _previewUid; // chapter uid currently previewing
  bool _previewLoading = false;
  bool _previewPlaying = false;
  double _previewTrackOffset = 0;
  double _previewTrackDur = 0;
  double _previewPosSec = 0;
  bool _scrubbing = false;
  bool? _mainWasPlaying;

  // The scrubber shows a window of the track, not the whole file: on a long
  // book a whole-file slider moves minutes per pixel. Track-local seconds.
  static const List<int> _windowChoices = [2, 5, 10];
  int _windowMinutes = 5;
  double _windowStart = 0;
  // The spot being cut. Loop the cut plays a second before it to two after
  // it on repeat, so a nudge is heard straight away.
  double _cutPos = 0;
  bool _loopCut = false;
  static const double _loopBefore = 1.0;
  static const double _loopAfter = 2.0;
  // Find the start only shows when transcription can actually run here.
  bool _canFind = false;

  Future<void> _checkFindAvailable() async {
    final ok = await TranscriptionService.instance.canTranscribeNow();
    if (mounted && ok != _canFind) setState(() => _canFind = ok);
  }

  double get _windowSeconds => _windowMinutes * 60.0;
  double get _windowEnd => _windowStart + _windowSeconds;

  /// Put the window around [center], keeping it inside the track.
  void _centerWindow(double center) {
    final maxStart = _previewTrackDur > _windowSeconds ? _previewTrackDur - _windowSeconds : 0.0;
    _windowStart = (center - _windowSeconds / 2).clamp(0.0, maxStart);
  }

  void _cycleWindow() {
    final i = _windowChoices.indexOf(_windowMinutes);
    setState(() {
      _windowMinutes = _windowChoices[(i + 1) % _windowChoices.length];
      _centerWindow(_cutPos);
    });
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in _titleCtl.values) {
      c.dispose();
    }
    _shiftCtl.dispose();
    _bulkCtl.dispose();
    _listScroll.dispose();
    _previewPosSub?.cancel();
    _previewStateSub?.cancel();
    _preview?.dispose();
    if (_mainWasPlaying == true) {
      AudioPlayerService().play();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final l = AppLocalizations.of(context)!;
    final api = context.read<AuthProvider>().apiService;
    if (api == null) {
      setState(() {
        _loading = false;
        _loadError = l.chapterNotConnected;
      });
      return;
    }
    try {
      final item = await api.getLibraryItem(widget.itemId);
      final media = item?['media'] as Map<String, dynamic>? ?? {};
      final meta = media['metadata'] as Map<String, dynamic>? ?? {};
      final dur = (media['duration'] as num?)?.toDouble() ?? 0;
      final chs = (media['chapters'] as List<dynamic>? ?? []);
      final afs = (media['audioFiles'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .where((af) => af['exclude'] != true)
          .toList();
      final rawTracks =
          (media['tracks'] as List<dynamic>? ?? []).whereType<Map<String, dynamic>>().toList();
      final tracks = rawTracks.isNotEmpty ? rawTracks : _tracksFromAudioFiles(afs);
      if (!mounted) return;
      setState(() {
        _duration = dur;
        _audioFiles = afs;
        _tracks = tracks;
        _asin = (meta['asin'] as String?)?.trim();
        _originalChapters = chs.whereType<Map<String, dynamic>>().toList();
        _initChapters(_originalChapters);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = '$e';
      });
    }
  }

  void _initChapters(List<dynamic> chs) {
    _chapters.clear();
    if (chs.isEmpty) {
      _chapters.add(_Ch(uid: _uid++, id: 0, start: 0, end: _duration, title: ''));
    } else {
      int i = 0;
      for (final c in chs.whereType<Map<String, dynamic>>()) {
        _chapters.add(_Ch(
          uid: _uid++,
          id: i++,
          start: (c['start'] as num?)?.toDouble() ?? 0,
          end: (c['end'] as num?)?.toDouble() ?? _duration,
          title: c['title'] as String? ?? '',
        ));
      }
    }
    _locked.clear();
    _syncTitleControllers();
    _check();
  }

  void _syncTitleControllers() {
    final uids = _chapters.map((c) => c.uid).toSet();
    for (final k in _titleCtl.keys.where((k) => !uids.contains(k)).toList()) {
      _titleCtl.remove(k)!.dispose();
    }
    for (final c in _chapters) {
      final ctl = _titleCtl[c.uid];
      if (ctl == null) {
        _titleCtl[c.uid] = TextEditingController(text: c.title);
      } else if (ctl.text != c.title) {
        ctl.text = c.title;
      }
    }
  }

  /// Reindex ids, recompute per-row validation errors, and recompute whether
  /// anything differs from the saved chapters.
  void _check() {
    final l = AppLocalizations.of(context)!;
    double prev = 0;
    bool changed = _chapters.length != _originalChapters.length;
    for (int i = 0; i < _chapters.length; i++) {
      final c = _chapters[i];
      c.id = i;
      final t = c.title.trim();
      if (i == 0 && c.start != 0) {
        c.error = l.chapterErrorFirstNotZero;
      } else if (i > 0 && c.start <= prev) {
        c.error = l.chapterErrorStartAfterPrevious;
      } else if (_duration > 0 && c.start >= _duration) {
        c.error = l.chapterErrorStartBeforeEnd;
      } else if (t.isEmpty) {
        c.error = l.chapterErrorTitleRequired;
      } else {
        c.error = null;
      }
      prev = c.start;

      if (!changed) {
        final o = i < _originalChapters.length ? _originalChapters[i] : null;
        final oStart = (o?['start'] as num?)?.toDouble() ?? -1;
        final oTitle = (o?['title'] as String? ?? '').trim();
        if (o == null || c.start != oStart || t != oTitle) changed = true;
      }
    }
    _hasChanges = changed;
  }

  // ─── Time helpers ───────────────────────────────────────────

  String _clock(double seconds) {
    final s = seconds.round();
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    final sec = s % 60;
    final mm = m.toString().padLeft(2, '0');
    final ss = sec.toString().padLeft(2, '0');
    return h > 0 ? '$h:$mm:$ss' : '$mm:$ss';
  }

  String _fmtStart(double seconds) {
    if (_showSeconds) {
      return seconds == seconds.roundToDouble()
          ? seconds.toStringAsFixed(0)
          : seconds.toStringAsFixed(2);
    }
    return _clock(seconds);
  }

  /// Parse "SS", "MM:SS", "HH:MM:SS" or a decimal seconds value.
  double? _parseTime(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return null;
    if (s.contains(':')) {
      double total = 0;
      for (final p in s.split(':')) {
        final v = double.tryParse(p.trim());
        if (v == null) return null;
        total = total * 60 + v;
      }
      return total;
    }
    return double.tryParse(s);
  }

  double _clampStart(double v) {
    if (v < 0) return 0;
    if (_duration > 0 && v > _duration) return _duration;
    return v;
  }

  /// Build a track list (startOffset / duration / contentUrl) from audio files
  /// when the expanded item doesn't include media.tracks.
  List<Map<String, dynamic>> _tracksFromAudioFiles(List<Map<String, dynamic>> afs) {
    final tracks = <Map<String, dynamic>>[];
    double off = 0;
    for (final af in afs) {
      final dur = (af['duration'] as num?)?.toDouble() ?? 0;
      final ino = af['ino'] as String?;
      tracks.add({
        'startOffset': off,
        'duration': dur,
        'contentUrl': ino != null ? '/api/items/${widget.itemId}/file/$ino' : null,
      });
      off += dur;
    }
    return tracks;
  }

  String _basename(String p) {
    var name = p.replaceAll('\\', '/');
    final slash = name.lastIndexOf('/');
    if (slash >= 0) name = name.substring(slash + 1);
    final dot = name.lastIndexOf('.');
    if (dot > 0) name = name.substring(0, dot);
    return name;
  }

  // ─── Edits ──────────────────────────────────────────────────

  /// Hours, minutes and seconds drums instead of typing: no keyboard, and no
  /// way to enter a time the book doesn't have.
  Future<void> _editStart(_Ch c) async {
    final l = AppLocalizations.of(context)!;
    var picked = c.start;
    final maxHours = _duration > 0 ? (_duration / 3600).floor() : 99;
    final result = await showDialog<double>(
      context: context,
      builder: (dctx) => AlertDialog(
        title: Text(l.chapterEditStartTitle),
        contentPadding: const EdgeInsets.fromLTRB(8, 20, 8, 0),
        content: _TimeDrums(
          seconds: c.start,
          maxHours: maxHours,
          onChanged: (v) => picked = v,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dctx),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dctx, _clampStart(picked)),
            child: Text(l.done),
          ),
        ],
      ),
    );
    if (result == null) return;
    setState(() {
      c.start = result;
      _check();
    });
  }

  void _toggleLock(_Ch c) {
    setState(() {
      if (_locked.contains(c.uid)) {
        _locked.remove(c.uid);
      } else {
        _locked.add(c.uid);
      }
    });
  }

  void _insertBelow(_Ch c) {
    final idx = _chapters.indexOf(c);
    final nextStart = idx + 1 < _chapters.length ? _chapters[idx + 1].start : _duration;
    var start = (c.start + nextStart) / 2;
    if (start <= c.start) start = _clampStart(c.start + 1);
    setState(() {
      _chapters.insert(idx + 1, _Ch(uid: _uid++, id: idx + 1, start: start, end: nextStart, title: ''));
      _syncTitleControllers();
      _check();
    });
  }

  void _remove(_Ch c) {
    if (_locked.contains(c.uid)) {
      showOverlayToast(context, AppLocalizations.of(context)!.chapterLocked, icon: Icons.lock_rounded);
      return;
    }
    if (_chapters.length <= 1) return;
    setState(() {
      _chapters.remove(c);
      _syncTitleControllers();
      _check();
    });
  }

  void _shift() {
    final amount = _parseTime(_shiftCtl.text);
    if (amount == null || amount == 0 || _chapters.length <= 1) return;
    final anyUnlocked = _chapters.any((c) => !_locked.contains(c.uid));
    if (!anyUnlocked) {
      showOverlayToast(context, AppLocalizations.of(context)!.chapterAllLocked, icon: Icons.lock_rounded);
      return;
    }
    setState(() {
      for (int i = 0; i < _chapters.length; i++) {
        final c = _chapters[i];
        if (_locked.contains(c.uid)) continue;
        c.end = (c.end + amount).clamp(0, _duration);
        if (i > 0) c.start = _clampStart(c.start + amount);
      }
      _check();
    });
    HapticFeedback.mediumImpact();
  }

  void _setFromTracks() {
    if (_audioFiles.isEmpty) return;
    final l = AppLocalizations.of(context)!;
    final chs = <_Ch>[];
    double t = 0;
    int i = 0;
    for (final af in _audioFiles) {
      final dur = (af['duration'] as num?)?.toDouble() ?? 0;
      final meta = af['metadata'] as Map<String, dynamic>? ?? {};
      final fname = meta['filename'] as String? ?? l.chapterTrackTitle(i + 1);
      chs.add(_Ch(uid: _uid++, id: i++, start: t, end: t + dur, title: _basename(fname)));
      t += dur;
    }
    setState(() {
      _chapters
        ..clear()
        ..addAll(chs);
      _locked.clear();
      _syncTitleControllers();
      _check();
    });
  }

  // ─── Preview (separate player; pauses main while active) ────

  Map<String, dynamic>? _trackForTime(double t) {
    for (final tr in _tracks) {
      final off = (tr['startOffset'] as num?)?.toDouble() ?? 0;
      final dur = (tr['duration'] as num?)?.toDouble() ?? 0;
      if (t >= off && t < off + dur) return tr;
    }
    return _tracks.isNotEmpty ? _tracks.last : null;
  }

  void _captureAndPauseMain() {
    final main = AudioPlayerService();
    _mainWasPlaying ??= main.isPlaying;
    if (main.isPlaying) main.pause();
  }

  Future<void> _playChapter(_Ch c, {bool autoplay = true}) async {
    final l = AppLocalizations.of(context)!;
    await _stopPreview();

    final track = _trackForTime(c.start);
    final contentUrl = track?['contentUrl'] as String?;
    final api = context.read<AuthProvider>().apiService;
    if (track == null || contentUrl == null || api == null) {
      showOverlayToast(context, l.chapterNoAudioForPosition, icon: Icons.error_outline_rounded);
      return;
    }
    final startOffset = (track['startOffset'] as num?)?.toDouble() ?? 0;
    final seekSec = (c.start - startOffset) < 0 ? 0.0 : (c.start - startOffset);

    _captureAndPauseMain();

    setState(() {
      _previewUid = c.uid;
      _previewLoading = true;
      _previewPlaying = false;
      _scrubbing = false;
      _previewTrackOffset = startOffset;
      _previewTrackDur = (track['duration'] as num?)?.toDouble() ?? 0;
      _previewPosSec = seekSec;
      _cutPos = seekSec;
      _centerWindow(seekSec);
    });
    unawaited(_checkFindAvailable());

    try {
      final player = AudioPlayer();
      _preview = player;
      _previewPosSub = player.positionStream.listen((pos) {
        if (!mounted || _scrubbing) return;
        final sec = pos.inMilliseconds / 1000.0;
        if (_loopCut && sec > _cutPos + _loopAfter) {
          _preview?.seek(Duration(milliseconds: ((_cutPos - _loopBefore).clamp(0.0, sec) * 1000).round()));
          return;
        }
        // The window stays on the start; playback running past it just
        // fills the track to the edge.
        setState(() => _previewPosSec = sec);
      });
      _previewStateSub = player.playerStateStream.listen((st) {
        if (!mounted) return;
        final loading = st.processingState == ProcessingState.loading ||
            st.processingState == ProcessingState.buffering;
        final done = st.processingState == ProcessingState.completed;
        setState(() {
          _previewLoading = loading;
          _previewPlaying = st.playing && !done;
        });
        if (done) _stopPreview();
      });
      await player.setAudioSource(AudioSource.uri(
          Uri.parse(api.buildTrackUrl(contentUrl)),
          options: mp3ExtractorOptions()));
      await player.seek(Duration(milliseconds: (seekSec * 1000).round()));
      if (autoplay) await player.play();
    } catch (e) {
      debugPrint('[ChapterEditor] preview error: $e');
      await _stopPreview();
      if (mounted) showOverlayToast(context, l.chapterCouldNotPlayPreview, icon: Icons.error_outline_rounded);
    }
  }

  Future<void> _stopPreview() async {
    await _previewPosSub?.cancel();
    _previewPosSub = null;
    await _previewStateSub?.cancel();
    _previewStateSub = null;
    final p = _preview;
    _preview = null;
    if (p != null) {
      try {
        await p.stop();
        await p.dispose();
      } catch (_) {}
    }
    if (mounted) {
      setState(() {
        _previewUid = null;
        _previewLoading = false;
        _previewPlaying = false;
      });
    }
  }

  Future<void> _togglePreviewPlay() async {
    final p = _preview;
    if (p == null || _previewLoading) return;
    if (_previewPlaying) {
      await p.pause();
    } else {
      // Play always starts from the chapter start, not wherever the pause
      // left the audio: the point of listening is to check the cut.
      _seekPreviewTo(_cutPos);
    }
  }

  /// Nudges move the cut, not the playhead: with the loop on the base is the
  /// cut itself, otherwise wherever the audio is.
  void _seekPreviewBy(double deltaSec, {bool play = true}) =>
      _seekPreviewTo(_cutPos + deltaSec, play: play);

  /// Move the chapter's start to [posSec] (seconds into the track) and play
  /// from there, so every nudge and every slider release is heard from the
  /// new start. With the loop on, playback opens a second early and keeps
  /// coming back around it. The panel edits the start itself: there is no
  /// separate "set start" step.
  void _seekPreviewTo(double posSec, {bool play = true}) {
    final p = _preview;
    if (p == null) return;
    var target = posSec;
    if (target < 0) target = 0;
    if (_previewTrackDur > 0 && target > _previewTrackDur) target = _previewTrackDur;
    _cutPos = target;
    _Ch? active;
    for (final ch in _chapters) {
      if (ch.uid == _previewUid) {
        active = ch;
        break;
      }
    }
    // A held nudge only moves the start; the audio follows when the finger
    // lifts, so the sound doesn't stutter five times a second.
    if (play) {
      final playFrom = _loopCut ? (target - _loopBefore).clamp(0.0, target) : target;
      p.seek(Duration(milliseconds: (playFrom * 1000).round()));
      if (!_previewPlaying && !_previewLoading) p.play();
      _previewPosSec = playFrom;
    }
    if (mounted) {
      setState(() {
        if (target < _windowStart || target > _windowEnd) _centerWindow(target);
        if (active != null) {
          active.start = _clampStart(_previewTrackOffset + target);
          _check();
        }
      });
    }
  }

  void _toggleLoopCut() {
    setState(() => _loopCut = !_loopCut);
    if (_loopCut) _seekPreviewTo(_cutPos);
  }

  // ─── Bulk add ───────────────────────────────────────────────

  void _handleBulkAdd() {
    final input = _bulkCtl.text.trim();
    if (input.isEmpty) return;
    final m = RegExp(r'(\d+)').firstMatch(input);
    if (m == null) {
      _addSingle(input);
    } else {
      _promptBulkCount(input, m);
    }
  }

  void _addSingle(String title) {
    final start = _chapters.isNotEmpty ? _chapters.last.end : 0.0;
    final end = _duration > 0 ? (start + 300).clamp(0.0, _duration) : start + 300;
    setState(() {
      _chapters.add(_Ch(uid: _uid++, id: _chapters.length, start: _clampStart(start), end: end, title: title));
      _bulkCtl.clear();
      _syncTitleControllers();
      _check();
    });
  }

  String _padNum(int n, int width, bool leadingZeros) {
    final s = n.toString();
    return (leadingZeros && width > 1) ? s.padLeft(width, '0') : s;
  }

  Future<void> _promptBulkCount(String input, RegExpMatch m) async {
    final l = AppLocalizations.of(context)!;
    final numStr = m.group(1)!;
    final startNum = int.parse(numStr);
    final width = numStr.length;
    final zeros = numStr.length > 1 && numStr.startsWith('0');
    final before = input.substring(0, m.start);
    final after = input.substring(m.start + numStr.length);

    final countCtl = TextEditingController(text: '5');
    final count = await showDialog<int>(
      context: context,
      builder: (dctx) {
        final cs = Theme.of(dctx).colorScheme;
        return AlertDialog(
          title: Text(l.chapterAddNumberedTitle),
          content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
                l.chapterNextPreview(
                  '$before${_padNum(startNum + 1, width, zeros)}$after',
                  '$before${_padNum(startNum + 2, width, zeros)}$after',
                ),
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
            const SizedBox(height: 12),
            TextField(
              controller: countCtl,
              autofocus: true,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: l.chapterHowMany),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dctx), child: Text(l.cancel)),
            TextButton(
              onPressed: () => Navigator.pop(dctx, int.tryParse(countCtl.text.trim())),
              child: Text(l.add),
            ),
          ],
        );
      },
    );
    countCtl.dispose();
    if (count == null) return;
    if (count < 1 || count > 150) {
      showOverlayToast(context, l.chapterCountRange, icon: Icons.error_outline_rounded);
      return;
    }
    final base = _chapters.isNotEmpty ? _chapters.last.start + 1 : 0.0;
    setState(() {
      for (int i = 0; i < count; i++) {
        _chapters.add(_Ch(
          uid: _uid++,
          id: _chapters.length,
          start: _clampStart(base + i),
          end: _duration,
          title: '$before${_padNum(startNum + i, width, zeros)}$after',
        ));
      }
      _bulkCtl.clear();
      _syncTitleControllers();
      _check();
    });
  }

  // ─── Audnexus lookup ────────────────────────────────────────

  Future<void> _openLookup() async {
    final api = context.read<AuthProvider>().apiService;
    if (api == null) return;
    final result = await showAdaptiveActionMenu<_LookupResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      desktopScrollWrap: false,
      builder: (_) => _ChapterLookupSheet(api: api, initialAsin: _asin, mediaDuration: _duration),
    );
    if (result == null || !mounted) return;
    var data = result.data;
    if (result.removeBranding) data = _removeBranding(data);
    final audible = (data['chapters'] as List<dynamic>? ?? []).whereType<Map<String, dynamic>>().toList();
    if (audible.isEmpty) return;
    if (result.titlesOnly) {
      _applyTitlesOnly(audible);
    } else {
      _applyChapters(audible);
    }
  }

  void _applyTitlesOnly(List<Map<String, dynamic>> audible) {
    setState(() {
      for (int i = 0; i < _chapters.length && i < audible.length; i++) {
        if (_locked.contains(_chapters[i].uid)) continue;
        _chapters[i].title = audible[i]['title'] as String? ?? _chapters[i].title;
      }
      _syncTitleControllers();
      _check();
    });
    showOverlayToast(context, AppLocalizations.of(context)!.chapterTitlesUpdated, icon: Icons.check_rounded);
  }

  void _applyChapters(List<Map<String, dynamic>> audible) {
    final converted = <_Ch>[];
    for (final ch in audible) {
      final startMs = (ch['startOffsetMs'] as num?)?.toDouble() ??
          ((ch['startOffsetSec'] as num?)?.toDouble() ?? 0) * 1000;
      final start = startMs / 1000;
      if (_duration > 0 && start >= _duration) continue;
      final lenMs = (ch['lengthMs'] as num?)?.toDouble() ?? 0;
      final end = _duration > 0 ? ((startMs + lenMs) / 1000).clamp(0.0, _duration) : (startMs + lenMs) / 1000;
      converted.add(_Ch(uid: 0, id: 0, start: start, end: end, title: ch['title'] as String? ?? ''));
    }
    // Merge, keeping locked chapters where they are (by current position).
    final merged = <_Ch>[];
    int aIdx = 0;
    final maxLen = _chapters.length > converted.length ? _chapters.length : converted.length;
    for (int i = 0; i < maxLen; i++) {
      if (i < _chapters.length && _locked.contains(_chapters[i].uid)) {
        merged.add(_chapters[i]);
      } else if (aIdx < converted.length) {
        final c = converted[aIdx++];
        merged.add(_Ch(uid: _uid++, id: merged.length, start: c.start, end: c.end, title: c.title));
      } else if (i < _chapters.length) {
        merged.add(_chapters[i]);
      }
    }
    setState(() {
      _chapters
        ..clear()
        ..addAll(merged);
      _syncTitleControllers();
      _check();
    });
    showOverlayToast(context, AppLocalizations.of(context)!.chaptersApplied, icon: Icons.check_rounded);
  }

  /// Mirror the web client's "remove Audible branding": shift every chapter
  /// earlier by the intro duration and drop a trailing outro-only chapter.
  Map<String, dynamic> _removeBranding(Map<String, dynamic> data) {
    try {
      final intro = (data['brandIntroDurationMs'] as num?)?.toDouble() ?? 0;
      final outro = (data['brandOutroDurationMs'] as num?)?.toDouble() ?? 0;
      final chapters = (data['chapters'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map((c) => Map<String, dynamic>.from(c))
          .toList();
      for (int i = 0; i < chapters.length; i++) {
        final off = (chapters[i]['startOffsetMs'] as num?)?.toDouble() ?? 0;
        if (off < intro) {
          chapters[i]['startOffsetMs'] = i * 1000;
          chapters[i]['startOffsetSec'] = i;
        } else {
          chapters[i]['startOffsetMs'] = off - intro;
          chapters[i]['startOffsetSec'] = ((off - intro) / 1000).floor();
        }
      }
      if (chapters.isNotEmpty) {
        final lastLen = (chapters.last['lengthMs'] as num?)?.toDouble() ?? 0;
        if (lastLen <= outro) chapters.removeLast();
      }
      return {...data, 'chapters': chapters};
    } catch (_) {
      return data;
    }
  }

  Future<void> _reset() async {
    final l = AppLocalizations.of(context)!;
    final ok = await _confirm(l.chapterDiscardTitle, l.chapterDiscardMessage);
    if (ok != true) return;
    setState(() => _initChapters(_originalChapters));
  }

  Future<void> _removeAll() async {
    final l = AppLocalizations.of(context)!;
    final ok = await _confirm(l.chapterRemoveAllTitle, l.chapterRemoveAllMessage);
    if (ok != true) return;
    final api = context.read<AuthProvider>().apiService;
    if (api == null) return;
    setState(() => _saving = true);
    final success = await api.updateChapters(widget.itemId, const []);
    if (!mounted) return;
    setState(() {
      _saving = false;
      if (success) {
        _originalChapters = [];
        _initChapters(const []);
      }
    });
    showOverlayToast(context, success ? l.chapterAllRemoved : l.couldNotUpdate,
        icon: success ? Icons.check_rounded : Icons.error_outline_rounded);
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context)!;
    _check();
    for (final c in _chapters) {
      if (c.error != null) {
        showOverlayToast(context, l.chapterFixHighlighted, icon: Icons.error_outline_rounded);
        setState(() {});
        return;
      }
    }
    final api = context.read<AuthProvider>().apiService;
    if (api == null) return;

    final payload = <Map<String, dynamic>>[];
    for (int i = 0; i < _chapters.length; i++) {
      final c = _chapters[i];
      final end = i < _chapters.length - 1 ? _chapters[i + 1].start : _duration;
      payload.add({'id': i, 'start': c.start, 'end': end, 'title': c.title.trim()});
    }

    setState(() => _saving = true);
    final success = await api.updateChapters(widget.itemId, payload);
    if (!mounted) return;
    setState(() {
      _saving = false;
      if (success) {
        _originalChapters = payload
            .map((p) => {'start': p['start'], 'end': p['end'], 'title': p['title']})
            .toList();
        _check();
      }
    });
    HapticFeedback.mediumImpact();
    showOverlayToast(context, success ? l.chaptersUpdated : l.couldNotUpdate,
        icon: success ? Icons.check_rounded : Icons.error_outline_rounded);
  }

  Future<bool?> _confirm(String title, String message) {
    final l = AppLocalizations.of(context)!;
    return showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dctx, false), child: Text(l.cancel)),
          TextButton(onPressed: () => Navigator.pop(dctx, true), child: Text(l.ok)),
        ],
      ),
    );
  }

  // ─── UI ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final cs = Theme.of(context).colorScheme;
    if (_loading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (_loadError != null) {
      return Center(child: Text(_loadError!, style: TextStyle(color: cs.error)));
    }
    return Stack(children: [
      _buildBody(cs),
      if (_saving)
        const Positioned.fill(
          child: ColoredBox(
            color: Color(0x55000000),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
        ),
    ]);
  }

  Widget _saveBar(ColorScheme cs) {
    if (!_hasChanges) return const SizedBox.shrink();
    final l = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      child: Row(children: [
        OutlinedButton(onPressed: _saving ? null : _reset, child: Text(l.reset)),
        const Spacer(),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(l.chapterSaveButton),
        ),
      ]),
    );
  }

  Widget _buildBody(ColorScheme cs) {
    // Only the save bar and the add field stay put. The toolbar scrolls away
    // with the list, so a small or zoomed screen with the keyboard up still
    // has room to see and reach the chapters instead of a two-row slit.
    return Column(
      children: [
        _saveBar(cs),
        Expanded(
          child: CustomScrollView(
            controller: _listScroll,
            slivers: [
              SliverToBoxAdapter(child: _toolbar(cs)),
              // Shifting is lock a few, shift the rest, repeat, so the shift
              // row stays put while the list scrolls under it.
              if (_showShift) PinnedHeaderSliver(child: _shiftPanel(cs)),
              const SliverToBoxAdapter(child: Divider(height: 1)),
              SliverList.builder(
                itemCount: _chapters.length,
                itemBuilder: (_, i) => _row(cs, _chapters[i], i),
              ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 16)),
            ],
          ),
        ),
        _bulkBar(cs),
      ],
    );
  }

  Widget _bulkBar(ColorScheme cs) {
    final l = AppLocalizations.of(context)!;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
          border: Border(top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3))),
        ),
        child: Row(children: [
          Expanded(
            child: TextField(
              controller: _bulkCtl,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                isDense: true,
                hintText: l.chapterAddHint,
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (_) => _handleBulkAdd(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: l.chapterAddTooltip,
            onPressed: _handleBulkAdd,
          ),
        ]),
      ),
    );
  }

  Widget _toolbar(ColorScheme cs) {
    final l = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (_chapters.isNotEmpty)
                OutlinedButton.icon(
                  onPressed: _removeAll,
                  icon: const Icon(Icons.delete_sweep_rounded, size: 18),
                  label: Text(l.chapterRemoveAll),
                ),
              if (_chapters.length > 1)
                OutlinedButton.icon(
                  onPressed: () => setState(() => _showShift = !_showShift),
                  icon: const Icon(Icons.schedule_rounded, size: 18),
                  label: Text(l.chapterShiftTimes),
                ),
              if (_audioFiles.isNotEmpty)
                OutlinedButton.icon(
                  onPressed: _setFromTracks,
                  icon: const Icon(Icons.library_music_rounded, size: 18),
                  label: Text(l.chapterFromTracks),
                ),
              OutlinedButton.icon(
                onPressed: _openLookup,
                icon: const Icon(Icons.travel_explore_rounded, size: 18),
                label: Text(l.chapterLookup),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Switch(
                value: _showSeconds,
                onChanged: (v) => setState(() => _showSeconds = v),
              ),
              Text(l.chapterShowSeconds),
            ],
          ),
        ],
      ),
    );
  }

  Widget _shiftPanel(ColorScheme cs) {
    final l = AppLocalizations.of(context)!;
    return Container(
      color: Color.alphaBlend(
          cs.surfaceContainerHighest.withValues(alpha: 0.4), cs.surface),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(l.chapterShiftBySeconds),
              const SizedBox(width: 12),
              SizedBox(
                width: 90,
                child: TextField(
                  controller: _shiftCtl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                  decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(onPressed: _shift, child: Text(l.apply)),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              l.chapterShiftHint,
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(ColorScheme cs, _Ch c, int index) {
    final l = AppLocalizations.of(context)!;
    final hasError = c.error != null;
    final active = _previewUid == c.uid;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      padding: const EdgeInsets.fromLTRB(6, 8, 2, 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasError
              ? cs.error.withValues(alpha: 0.6)
              : active
                  ? cs.primary.withValues(alpha: 0.5)
                  : cs.outlineVariant.withValues(alpha: 0.3),
          width: active ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 26,
                child: Text('${index + 1}',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: cs.onSurfaceVariant)),
              ),
              Expanded(
                child: InkWell(
                  onTap: () => _editStart(c),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _fmtStart(c.start),
                      style: TextStyle(
                        fontFeatures: const [FontFeature.tabularFigures()],
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: cs.primary,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 2),
              ..._rowActions(cs, c),
              _expandButton(cs, c),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 8, right: 8, top: 2),
            child: TextField(
              controller: _titleCtl[c.uid],
              onChanged: (v) {
                c.title = v;
                setState(_check);
              },
              style: const TextStyle(fontSize: 16),
              decoration: InputDecoration(
                hintText: l.chapterTitleHint,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: const UnderlineInputBorder(),
              ),
            ),
          ),
          if (hasError)
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 6),
              child: Text(c.error!, style: TextStyle(fontSize: 12.5, color: cs.error)),
            ),
          if (active) _previewPanel(cs, c),
        ],
      ),
    );
  }

  /// Opens the row into its preview panel, where the play button and the
  /// chapter's menu live; opening loads the audio paused.
  Widget _expandButton(ColorScheme cs, _Ch c) {
    final active = _previewUid == c.uid;
    final l = AppLocalizations.of(context)!;
    return IconButton(
      onPressed: () => active ? _stopPreview() : _playChapter(c, autoplay: false),
      icon: Icon(active ? Icons.expand_less_rounded : Icons.expand_more_rounded),
      iconSize: 28,
      color: active ? cs.primary : cs.onSurfaceVariant,
      tooltip: active ? l.chapterStopPreview : l.chapterPreviewFromHere,
    );
  }

  Widget _previewPanel(ColorScheme cs, _Ch c) {
    final l = AppLocalizations.of(context)!;
    final global = c.start;
    final trackEnd = _previewTrackDur > 0 ? _previewTrackDur : (_cutPos > 1 ? _cutPos : 1.0);
    final winEnd = _windowEnd < trackEnd ? _windowEnd : trackEnd;
    final winStart = _windowStart < winEnd ? _windowStart : (winEnd - 1).clamp(0.0, winEnd);
    // The thumb is the chapter start. Playback shows as the lighter fill
    // running ahead of it, so the start never drifts off under the audio.
    final val = _cutPos.clamp(winStart, winEnd);
    final playhead = _previewPosSec.clamp(winStart, winEnd);
    return Container(
      margin: const EdgeInsets.only(left: 4, right: 4, top: 10),
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 12),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          IconButton(
            onPressed: _previewLoading ? null : _togglePreviewPlay,
            icon: _previewLoading
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                : Icon(_previewPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
            iconSize: 30,
            color: cs.primary,
          ),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l.chapterScrubHint,
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
              Text(l.chapterStartAt(_clock(global)),
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: cs.primary,
                      fontFeatures: const [FontFeature.tabularFigures()])),
            ]),
          ),
          IconButton(
            onPressed: _toggleLoopCut,
            tooltip: l.chapterLoopCut,
            isSelected: _loopCut,
            icon: const Icon(Icons.repeat_rounded),
            selectedIcon: Icon(Icons.repeat_on_rounded, color: cs.primary),
          ),
          if (_canFind)
            IconButton(
              onPressed: () => _showFindStart(c),
              tooltip: l.chapterFindStart,
              icon: const Icon(Icons.hearing_rounded),
              color: cs.primary,
            ),
        ]),
        Row(children: [
          Expanded(
            child: Slider(
              value: val,
              secondaryTrackValue: playhead > val ? playhead : null,
              min: winStart,
              max: winEnd,
              onChangeStart: (_) => _scrubbing = true,
              onChanged: (v) => _seekPreviewTo(v, play: false),
              onChangeEnd: (v) {
                _scrubbing = false;
                // Let go at an edge and the window slides on by half.
                final edge = _windowSeconds * 0.02;
                if (v <= winStart + edge && winStart > 0) {
                  _centerWindow(winStart);
                } else if (v >= winEnd - edge && winEnd < trackEnd) {
                  _centerWindow(winEnd);
                }
                _seekPreviewTo(v);
              },
            ),
          ),
          // Tap to cycle the window width: two, five or ten minutes.
          ActionChip(
            visualDensity: VisualDensity.compact,
            label: Text(l.chapterWindowMinutes(_windowMinutes)),
            onPressed: _cycleWindow,
          ),
          const SizedBox(width: 4),
        ]),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(children: [
            Text(_clock(_previewTrackOffset + winStart),
                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
            const Spacer(),
            Text(_clock(_previewTrackOffset + winEnd),
                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
          ]),
        ),
        const SizedBox(height: 6),
        Row(children: [
          _skipBtn('-5s', -5),
          const SizedBox(width: 8),
          _skipBtn('-1s', -1),
          const Spacer(),
          _skipBtn('+1s', 1),
          const SizedBox(width: 8),
          _skipBtn('+5s', 5),
        ]),
      ]),
    );
  }

  /// A nudge button that keeps nudging while held: the start moves with
  /// each tick, the audio catches up once on release.
  Widget _skipBtn(String label, double delta) {
    Timer? repeat;
    void onTap() => _seekPreviewBy(delta);
    return GestureDetector(
      onLongPressStart: (_) {
        _seekPreviewBy(delta, play: false);
        repeat = Timer.periodic(
            const Duration(milliseconds: 180), (_) => _seekPreviewBy(delta, play: false));
      },
      onLongPressEnd: (_) {
        repeat?.cancel();
        _seekPreviewTo(_cutPos);
      },
      onLongPressCancel: () => repeat?.cancel(),
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(58, 44),
          padding: const EdgeInsets.symmetric(horizontal: 10),
        ),
        child: Text(label),
      ),
    );
  }

  /// Listen around the marker for where this chapter really starts and let
  /// the user pick from what was heard.
  Future<void> _showFindStart(_Ch c) async {
    final l = AppLocalizations.of(context)!;
    if (!await TranscriptionService.instance.canTranscribeNow()) {
      if (mounted) {
        showOverlayToast(context, l.chapterFindStartNeedsModel,
            icon: Icons.record_voice_over_rounded);
      }
      return;
    }
    final localPaths = DownloadService().getLocalPaths(widget.itemId);
    final downloaded = localPaths != null && localPaths.isNotEmpty;
    if (!mounted) return;
    final marker = c.start;
    final track = _trackForTime(marker);
    final api = context.read<AuthProvider>().apiService;
    if (track == null || api == null) return;
    final trackIndex = _tracks.indexOf(track);
    final offset = (track['startOffset'] as num?)?.toDouble() ?? 0;
    final trackDur = (track['duration'] as num?)?.toDouble() ?? 0;
    // Android's decoder opens a stream URL itself. Apple's only reads local
    // files, so on iOS a streamed book gets the window's bytes pulled down
    // and rewrapped first.
    final String source;
    RemoteTrack? remote;
    if (downloaded && trackIndex >= 0 && trackIndex < localPaths.length) {
      source = localPaths[trackIndex];
    } else {
      final contentUrl = track['contentUrl'] as String?;
      if (contentUrl == null) return;
      source = api.buildTrackUrl(contentUrl);
      if (Platform.isIOS) {
        remote = RemoteTrack(
          url: source,
          headers: api.mediaHeaders,
          durationSeconds: trackDur,
          mimeType: track['mimeType'] as String?,
        );
      }
    }
    final index = _chapters.indexOf(c);
    final title = _titleCtl[c.uid]?.text ?? c.title;
    // First pass is the scrubber's own window around the marker.
    final half = _windowSeconds / 2;
    final local = marker - offset;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _FindStartSheet(
        source: source,
        remote: remote,
        sourceOffset: offset,
        trackDuration: trackDur,
        centerLocal: local,
        firstHalfWidth: half,
        chapterNumber: index + 1,
        title: title,
        clock: _clock,
        onPlay: (t) {
          if (_previewUid != c.uid) return;
          _seekPreviewTo(t - _previewTrackOffset);
        },
        onPick: (t, suggested) {
          // A heard title replaces an empty or number-only one; a heard
          // name ("Chapter 2: The Storm") is worth taking over anything.
          final current = (_titleCtl[c.uid]?.text ?? c.title).trim();
          final generic = current.isEmpty ||
              RegExp(r'^(chapter|part)?\s*\d+\.?$', caseSensitive: false).hasMatch(current);
          final takeTitle = suggested != null && (suggested.contains(':') || generic);
          setState(() {
            c.start = _clampStart(t);
            if (takeTitle) {
              c.title = suggested;
              _titleCtl[c.uid]?.text = suggested;
            }
            _check();
          });
          if (_previewUid == c.uid) _seekPreviewTo(t - _previewTrackOffset);
        },
      ),
    );
  }

  /// Lock, insert and delete sit beside the time now that the row has the
  /// room, instead of behind a menu in the preview panel.
  List<Widget> _rowActions(ColorScheme cs, _Ch c) {
    final l = AppLocalizations.of(context)!;
    final locked = _locked.contains(c.uid);
    return [
      IconButton(
        onPressed: () => _toggleLock(c),
        icon: Icon(locked ? Icons.lock_rounded : Icons.lock_open_rounded),
        iconSize: 22,
        visualDensity: VisualDensity.compact,
        color: locked ? Colors.orange : cs.onSurfaceVariant,
        tooltip: locked ? l.chapterUnlock : l.chapterLock,
      ),
      IconButton(
        onPressed: () => _insertBelow(c),
        icon: const Icon(Icons.add_box_outlined),
        iconSize: 22,
        visualDensity: VisualDensity.compact,
        color: cs.onSurfaceVariant,
        tooltip: l.chapterInsertBelow,
      ),
      if (_chapters.length > 1)
        IconButton(
          onPressed: () => _remove(c),
          icon: const Icon(Icons.delete_outline_rounded),
          iconSize: 22,
          visualDensity: VisualDensity.compact,
          color: cs.error.withValues(alpha: 0.8),
          tooltip: l.delete,
        ),
    ];
  }
}

class _LookupResult {
  final Map<String, dynamic> data;
  final bool titlesOnly;
  final bool removeBranding;
  _LookupResult({required this.data, required this.titlesOnly, required this.removeBranding});
}

/// ASIN -> Audnexus chapter lookup. Collects ASIN/region/branding, searches via
/// the server, previews the result, and returns how to apply it.
class _ChapterLookupSheet extends StatefulWidget {
  final ApiService api;
  final String? initialAsin;
  final double mediaDuration;
  const _ChapterLookupSheet({required this.api, required this.initialAsin, required this.mediaDuration});

  @override
  State<_ChapterLookupSheet> createState() => _ChapterLookupSheetState();
}

class _ChapterLookupSheetState extends State<_ChapterLookupSheet> {
  late final TextEditingController _asinCtl;
  String _region = 'US';
  bool _removeBranding = false;
  bool _finding = false;
  String? _error;
  Map<String, dynamic>? _data;

  static const _regions = ['US', 'CA', 'UK', 'AU', 'FR', 'DE', 'JP', 'IT', 'IN', 'ES'];

  @override
  void initState() {
    super.initState();
    _asinCtl = TextEditingController(text: widget.initialAsin ?? '');
  }

  @override
  void dispose() {
    _asinCtl.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final l = AppLocalizations.of(context)!;
    final asin = _asinCtl.text.trim();
    if (asin.isEmpty) {
      setState(() => _error = l.chapterEnterAsin);
      return;
    }
    setState(() {
      _finding = true;
      _error = null;
    });
    final data = await widget.api.searchChapters(asin, _region);
    if (!mounted) return;
    setState(() {
      _finding = false;
      if (data == null) {
        _error = l.chapterLookupFailed;
      } else if (data['error'] != null) {
        _error = l.chapterNoChaptersFound;
      } else {
        _data = data;
      }
    });
  }

  String _clock(num seconds) {
    final s = seconds.round();
    final h = s ~/ 3600, m = (s % 3600) ~/ 60, sec = s % 60;
    final mm = m.toString().padLeft(2, '0'), ss = sec.toString().padLeft(2, '0');
    return h > 0 ? '$h:$mm:$ss' : '$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        child: _data == null ? _inputView(cs) : _resultsView(cs, _data!),
      ),
    );
  }

  Widget _handle(ColorScheme cs) => Center(
        child: Container(
          width: 40,
          height: 4,
          margin: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
              color: cs.onSurface.withValues(alpha: 0.24), borderRadius: BorderRadius.circular(2)),
        ),
      );

  Widget _inputView(ColorScheme cs) {
    final l = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        _handle(cs),
        Text(l.chapterFindTitle, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: cs.onSurface)),
        const SizedBox(height: 4),
        Text(l.chapterFindSubtitle,
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(
            child: TextField(
              controller: _asinCtl,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(labelText: 'ASIN', isDense: true, border: OutlineInputBorder()),
            ),
          ),
          const SizedBox(width: 10),
          DropdownButton<String>(
            value: _region,
            onChanged: (v) => setState(() => _region = v ?? 'US'),
            items: [for (final r in _regions) DropdownMenuItem(value: r, child: Text(r))],
          ),
        ]),
        Row(children: [
          Checkbox(value: _removeBranding, onChanged: (v) => setState(() => _removeBranding = v ?? false)),
          Flexible(child: Text(l.chapterRemoveBranding)),
        ]),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(_error!, style: TextStyle(color: cs.error, fontSize: 12)),
          ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _finding ? null : _search,
            child: _finding
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(l.search),
          ),
        ),
      ]),
    );
  }

  Widget _resultsView(ColorScheme cs, Map<String, dynamic> data) {
    final l = AppLocalizations.of(context)!;
    final chapters = (data['chapters'] as List<dynamic>? ?? []).whereType<Map<String, dynamic>>().toList();
    final runtime = (data['runtimeLengthSec'] as num?)?.toDouble() ?? 0;
    final bookDur = widget.mediaDuration;
    final mismatch = runtime > 0 && bookDur > 0 && (runtime - bookDur).abs() > 60;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      _handle(cs),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(children: [
          IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => setState(() => _data = null)),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l.chapterFoundCount(chapters.length),
                  style: TextStyle(fontWeight: FontWeight.w600, color: cs.onSurface)),
              Text(l.chapterAudibleVsBook(_clock(runtime), _clock(bookDur)),
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
            ]),
          ),
        ]),
      ),
      if (mismatch)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
          child: Text(
            runtime > bookDur
                ? l.chapterAudibleLonger
                : l.chapterAudibleShorter,
            style: const TextStyle(fontSize: 12, color: Colors.orange),
          ),
        ),
      const Divider(height: 12),
      Flexible(
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: chapters.length,
          itemBuilder: (_, i) {
            final ch = chapters[i];
            final off = (ch['startOffsetSec'] as num?)?.toDouble() ??
                ((ch['startOffsetMs'] as num?)?.toDouble() ?? 0) / 1000;
            final pastEnd = bookDur > 0 && off >= bookDur;
            return Container(
              color: pastEnd ? cs.error.withValues(alpha: 0.12) : null,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(children: [
                SizedBox(
                  width: 72,
                  child: Text(_clock(off),
                      style: TextStyle(
                          fontFeatures: const [FontFeature.tabularFigures()],
                          fontSize: 12,
                          color: cs.onSurfaceVariant)),
                ),
                Expanded(
                  child: Text(ch['title'] as String? ?? '',
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                ),
              ]),
            );
          },
        ),
      ),
      SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(
                    context, _LookupResult(data: data, titlesOnly: true, removeBranding: _removeBranding)),
                child: Text(l.chapterTitlesOnly),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                onPressed: () => Navigator.pop(
                    context, _LookupResult(data: data, titlesOnly: false, removeBranding: _removeBranding)),
                child: Text(l.chapterApplyChapters),
              ),
            ),
          ]),
        ),
      ),
    ]);
  }
}

/// Hours, minutes and seconds drums for a chapter start.
class _TimeDrums extends StatefulWidget {
  final double seconds;
  final int maxHours;
  final ValueChanged<double> onChanged;
  const _TimeDrums({required this.seconds, required this.maxHours, required this.onChanged});

  @override
  State<_TimeDrums> createState() => _TimeDrumsState();
}

class _TimeDrumsState extends State<_TimeDrums> {
  late final FixedExtentScrollController _h;
  late final FixedExtentScrollController _m;
  late final FixedExtentScrollController _s;

  @override
  void initState() {
    super.initState();
    final total = widget.seconds.round().clamp(0, 1 << 31);
    _h = FixedExtentScrollController(initialItem: (total ~/ 3600).clamp(0, widget.maxHours));
    _m = FixedExtentScrollController(initialItem: (total % 3600) ~/ 60);
    _s = FixedExtentScrollController(initialItem: total % 60);
  }

  @override
  void dispose() {
    _h.dispose();
    _m.dispose();
    _s.dispose();
    super.dispose();
  }

  void _emit() {
    widget.onChanged(_h.selectedItem * 3600.0 + _m.selectedItem * 60.0 + _s.selectedItem);
  }

  Widget _drum(FixedExtentScrollController c, int count, String unit, ColorScheme cs) {
    return Expanded(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(
          height: 150,
          child: ListWheelScrollView.useDelegate(
            controller: c,
            itemExtent: 38,
            physics: const FixedExtentScrollPhysics(),
            diameterRatio: 1.6,
            onSelectedItemChanged: (_) => _emit(),
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: count,
              builder: (_, i) => Center(
                child: Text(
                  i.toString().padLeft(2, '0'),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: cs.onSurface,
                  ),
                ),
              ),
            ),
          ),
        ),
        Text(unit, style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(children: [
      _drum(_h, widget.maxHours + 1, 'h', cs),
      _drum(_m, 60, 'm', cs),
      _drum(_s, 60, 's', cs),
    ]);
  }
}

/// Where a chapter could start, heard from the audio around the marker.
/// Starts on the scrubber's window and can search wider twice, to about
/// half an hour in all, before giving up.
class _FindStartSheet extends StatefulWidget {
  final String source;
  final RemoteTrack? remote;
  final double sourceOffset;
  final double trackDuration;
  final double centerLocal;
  final double firstHalfWidth;
  final int chapterNumber;
  final String title;
  final String Function(double) clock;
  final ValueChanged<double> onPlay;
  final void Function(double time, String? suggestedTitle) onPick;
  const _FindStartSheet({
    required this.source,
    this.remote,
    required this.sourceOffset,
    required this.trackDuration,
    required this.centerLocal,
    required this.firstHalfWidth,
    required this.chapterNumber,
    required this.title,
    required this.clock,
    required this.onPlay,
    required this.onPick,
  });

  @override
  State<_FindStartSheet> createState() => _FindStartSheetState();
}

class _FindStartSheetState extends State<_FindStartSheet> {
  // Each level adds this much on both sides: 5 min, then 15, then 30 in all.
  static const List<double> _growBy = [300, 450];

  final List<ChapterCandidate> _found = [];
  bool _running = true;
  bool _cancelled = false;
  int _level = 0;
  String? _error;
  late double _from = (widget.centerLocal - widget.firstHalfWidth).clamp(0.0, _trackEnd);
  late double _to = (widget.centerLocal + widget.firstHalfWidth).clamp(0.0, _trackEnd);

  double get _trackEnd => widget.trackDuration > 0 ? widget.trackDuration : double.infinity;
  bool get _atCeiling => _level >= _growBy.length;

  @override
  void initState() {
    super.initState();
    _run([(from: _from, to: _to)]);
  }

  @override
  void dispose() {
    _cancelled = true;
    super.dispose();
  }

  Future<void> _run(List<({double from, double to})> ranges) async {
    setState(() {
      _running = true;
      _error = null;
    });
    for (final r in ranges) {
      if (_cancelled) return;
      if (r.to - r.from < 2) continue;
      try {
        await ChapterStartFinder.run(
          source: widget.source,
          remote: widget.remote,
          sourceOffset: widget.sourceOffset,
          startLocal: r.from,
          windowSeconds: r.to - r.from,
          chapterNumber: widget.chapterNumber,
          title: widget.title,
          cancelled: () => _cancelled,
          onCandidate: (c) {
            if (!mounted || _cancelled) return;
            setState(() {
              _found.add(c);
              _found.sort((a, b) => a.time.compareTo(b.time));
            });
          },
        );
      } on TranscriptionException catch (e) {
        if (!mounted) return;
        final l = AppLocalizations.of(context)!;
        setState(() {
          _error = switch (e.kind) {
            TranscriptionError.disabled => l.transcriptionDisabledHint,
            TranscriptionError.modelMissing => l.transcriptionNoModelDownloaded,
            TranscriptionError.busy => l.transcriptionBusyMsg,
            _ => l.transcriptionFailedMsg,
          };
        });
        break;
      } catch (e) {
        debugPrint('[ChapterFind] failed: $e');
        if (!mounted) return;
        setState(() => _error = AppLocalizations.of(context)!.transcriptionFailedMsg);
        break;
      }
    }
    if (mounted) setState(() => _running = false);
  }

  void _wider() {
    if (_running || _atCeiling) return;
    final grow = _growBy[_level];
    final left = (from: (_from - grow).clamp(0.0, _from), to: _from);
    final right = (from: _to, to: (_to + grow).clamp(_to, _trackEnd));
    setState(() {
      _level++;
      _from = left.from;
      _to = right.to;
    });
    _run([left, right]);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final maxH = MediaQuery.of(context).size.height * 0.75;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxH),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 12, 4),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(l.chapterFindStart, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  _running
                      ? l.chapterFindStartListening
                      : l.chapterFindStartRange(
                          widget.clock(widget.sourceOffset + _from),
                          widget.clock(widget.sourceOffset + (_to.isFinite ? _to : 0))),
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ]),
            ),
            if (_running)
              const Padding(
                padding: EdgeInsets.all(8),
                child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
              ),
          ]),
        ),
        Flexible(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 4),
            children: [
              for (final c in _found) _candidate(c, l, cs, tt, _isBest(c)),
              if (!_running && _found.isEmpty && _error == null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                  child: Text(l.chapterFindStartNone, style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                  child: Text(_error!, style: tt.bodyMedium?.copyWith(color: cs.error)),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: _atCeiling && !_running
              ? Text(l.chapterFindStartCeiling,
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant))
              : SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _running || _error != null ? null : _wider,
                    icon: const Icon(Icons.unfold_more_rounded, size: 18),
                    label: Text(l.chapterFindStartWider),
                  ),
                ),
        ),
      ]),
    );
  }

  /// The candidate the finder would pick: the top score, once something was
  /// actually heard that sounds like a chapter.
  bool _isBest(ChapterCandidate c) {
    if (c.score < 2) return false;
    return !_found.any((o) => o.score > c.score);
  }

  Widget _candidate(ChapterCandidate c, AppLocalizations l, ColorScheme cs, TextTheme tt, bool best) {
    final strong = c.score >= 2;
    final maybe = c.score == 1;
    final heard = c.heard.trim();
    final shortHeard = heard.length > 90 ? '${heard.substring(0, 90)}...' : heard;
    final gap = l.chapterFindStartGap(c.silenceSeconds.toStringAsFixed(1));
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ListTile(
      shape: best
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: cs.primary, width: 1.5))
          : null,
      tileColor: best ? cs.primary.withValues(alpha: 0.06) : null,
      leading: IconButton(
        icon: Icon(Icons.play_circle_outline_rounded, color: cs.primary),
        tooltip: l.preview,
        onPressed: () => widget.onPlay(c.time),
      ),
      title: Row(children: [
        Text(widget.clock(c.time),
            style: tt.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()])),
        const SizedBox(width: 8),
        if (strong || maybe)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: (strong ? cs.primary : cs.onSurface).withValues(alpha: strong ? 0.15 : 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(strong ? l.chapterFindStartStrong : l.chapterFindStartMaybe,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                    color: strong ? cs.primary : cs.onSurfaceVariant)),
          ),
      ]),
      subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          heard.isEmpty ? gap : '$gap  -  $shortHeard',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
        ),
        if (c.suggestedTitle != null)
          Text(
            l.chapterFindStartTitle(c.suggestedTitle!),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: tt.bodySmall?.copyWith(color: cs.primary, fontWeight: FontWeight.w600),
          ),
      ]),
      isThreeLine: c.suggestedTitle != null,
      trailing: TextButton(
        onPressed: () {
          widget.onPick(c.time, c.suggestedTitle);
          Navigator.pop(context);
        },
        child: Text(l.chapterFindStartUseThis),
      ),
      onTap: () {
        widget.onPick(c.time, c.suggestedTitle);
        Navigator.pop(context);
      },
      ),
    );
  }
}
