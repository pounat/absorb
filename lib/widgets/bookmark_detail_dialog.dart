import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/library_provider.dart';
import '../services/api_service.dart';
import '../services/audio_player_service.dart';
import '../services/bookmark_service.dart';
import '../services/bookmark_preview_player.dart';
import '../services/download_service.dart';
import '../services/transcription_service.dart';
import 'clip_editor_sheet.dart';
import 'overlay_toast.dart';

/// Result of [BookmarkDetailSheet]. [action] is 'jump' (caller should seek
/// there) or 'saved' (stay put, refresh). [position] is the possibly-nudged
/// bookmark time in seconds. The sheet returns null when closed without saving.
typedef BookmarkDetailResult = ({String action, double position});

/// Bookmark editor shown as a bottom sheet, shared by the standalone Bookmarks
/// screen and the in-player bookmark sheet: roomy title/note, a -5/-1/+1/+5 fine
/// time nudge (synced to the server), inline preview that auditions the spot
/// without moving the user's real position, and an Export clip action that opens
/// the [ClipEditorSheet]. Persists on Save/Jump, then pops a [BookmarkDetailResult].
class BookmarkDetailSheet extends StatefulWidget {
  final String itemId;
  final Bookmark bookmark;
  final ApiService? api;
  const BookmarkDetailSheet({
    super.key,
    required this.itemId,
    required this.bookmark,
    this.api,
  });

  @override
  State<BookmarkDetailSheet> createState() => _BookmarkDetailSheetState();
}

class _BookmarkDetailSheetState extends State<BookmarkDetailSheet> {
  late final TextEditingController _titleC;
  late final TextEditingController _noteC;
  late double _seconds;
  late final BookmarkPreviewPlayer _preview;
  bool _saving = false;
  bool _transcriptionOn = false;
  // Display-only speed division (speed-adjusted-time setting). _seconds stays
  // raw book time throughout - preview, clip export, jump and save all use it.
  double _displaySpeed = 1.0;

  @override
  void initState() {
    super.initState();
    _titleC = TextEditingController(text: widget.bookmark.title);
    _noteC = TextEditingController(text: widget.bookmark.note ?? '');
    // Clamp a stray negative position to 0 so it shows 0:00 (not "59:59") and
    // self-heals to 0 if the user saves.
    _seconds = widget.bookmark.positionSeconds < 0 ? 0.0 : widget.bookmark.positionSeconds;
    _preview = BookmarkPreviewPlayer(
        itemId: widget.itemId, api: widget.api, label: 'bookmark')
      ..clipLength = const Duration(seconds: 60)
      ..addListener(_onPreview);
    _loadDisplaySpeed();
    PlayerSettings.getTranscriptionEnabled().then((on) {
      if (mounted && on) setState(() => _transcriptionOn = true);
    });
  }

  Future<void> _loadDisplaySpeed() async {
    if (!await PlayerSettings.getSpeedAdjustedTime()) return;
    final player = AudioPlayerService();
    final speed = player.currentItemId == widget.itemId
        ? player.speed
        : (await PlayerSettings.getBookSpeed(widget.itemId) ??
            await PlayerSettings.getDefaultSpeed());
    if (mounted && speed > 0 && speed != _displaySpeed) {
      setState(() => _displaySpeed = speed);
    }
  }

  void _onPreview() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _preview.removeListener(_onPreview);
    _preview.dispose();
    _titleC.dispose();
    _noteC.dispose();
    super.dispose();
  }

  String _fmt(double s) {
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    final sec = s.toInt() % 60;
    if (h > 0) {
      return '$h:${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
    }
    return '$m:${sec.toString().padLeft(2, '0')}';
  }

  void _nudge(double delta) {
    setState(() => _seconds = (_seconds + delta).clamp(0.0, double.infinity));
    _preview.stop(); // next Listen uses the new time
  }

  Future<void> _togglePreview() async {
    try {
      await _preview.toggleAt(_seconds);
    } catch (e) {
      debugPrint('[Preview] bookmark ${widget.itemId}: toggle failed: $e');
      // stop() resumes the main book we paused and resets for a retry.
      await _preview.stop();
      if (!mounted) return;
      final l = AppLocalizations.of(context)!;
      showOverlayToast(context, l.bookmarkPreviewFailed,
          icon: Icons.error_outline_rounded);
    }
  }

  Future<void> _openClipEditor() async {
    await _preview.stop();
    if (!mounted) return;
    // iOS can't export from a streaming book, so prompt to download up front
    // rather than letting the user trim a clip and only fail at Save. Android
    // exports streamed clips fine, so it always opens the editor.
    if (Platform.isIOS && !DownloadService().isDownloaded(widget.itemId)) {
      await _promptDownload();
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).bottomSheetTheme.backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => ClipEditorSheet(
        itemId: widget.itemId,
        bookmarkSeconds: _seconds,
        bookmarkTitle:
            _titleC.text.trim().isEmpty ? widget.bookmark.title : _titleC.text.trim(),
        api: widget.api,
      ),
    );
  }

  Future<void> _promptDownload() async {
    final l = AppLocalizations.of(context)!;
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(l.clipDownloadToExport),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.download),
          ),
        ],
      ),
    );
    if (go == true) await _startDownload();
  }

  Future<void> _startDownload() async {
    final api = widget.api;
    if (api == null) return;
    final libraryId = context.read<LibraryProvider>().selectedLibraryId;
    var title =
        _titleC.text.trim().isEmpty ? widget.bookmark.title : _titleC.text.trim();
    var author = '';
    try {
      final item = await api.getLibraryItem(widget.itemId);
      final meta = (item?['media'] as Map<String, dynamic>?)?['metadata']
          as Map<String, dynamic>?;
      title = meta?['title'] as String? ?? title;
      author = meta?['authorName'] as String? ?? '';
    } catch (_) {}
    await DownloadService().downloadItem(
      api: api,
      itemId: widget.itemId,
      title: title,
      author: author,
      coverUrl: api.getCoverUrl(widget.itemId, width: 400),
      libraryId: libraryId,
    );
  }

  String _mapTranscriptionError(AppLocalizations l, TranscriptionError kind) {
    switch (kind) {
      case TranscriptionError.disabled:
        return l.transcriptionDisabledHint;
      case TranscriptionError.modelMissing:
        return l.transcriptionNoModelDownloaded;
      case TranscriptionError.notDownloaded:
        return l.transcriptionNotDownloadedBook;
      case TranscriptionError.noMetadata:
        return l.transcriptionNoMetadataMsg;
      case TranscriptionError.busy:
        return l.transcriptionBusyMsg;
      case TranscriptionError.empty:
        return l.transcriptionEmptyMsg;
      case TranscriptionError.extractFailed:
      case TranscriptionError.transcribeFailed:
        return l.transcriptionFailedMsg;
    }
  }

  /// Transcribe the audio around the (possibly nudged) bookmark time, let the
  /// user review the text alongside the clip, then append it to the note and
  /// persist. Downloaded books only - the service guards enforce the rest.
  Future<void> _transcribe() async {
    final l = AppLocalizations.of(context)!;
    await _preview.stop();
    if (!mounted) return;
    if (!TranscriptionService.instance.canTranscribeBook(widget.itemId)) {
      showOverlayToast(context, l.transcriptionNotDownloadedBook,
          icon: Icons.download_rounded);
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Row(children: [
          const SizedBox(
              width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5)),
          const SizedBox(width: 16),
          Expanded(child: Text(l.transcribing)),
        ]),
      ),
    );

    ({String text, String audioPath})? result;
    String? error;
    try {
      result = await TranscriptionService.instance
          .transcribeAt(itemId: widget.itemId, positionSeconds: _seconds);
    } on TranscriptionException catch (e) {
      error = _mapTranscriptionError(l, e.kind);
    } catch (_) {
      error = l.transcriptionFailedMsg;
    }

    if (!mounted) return;
    Navigator.pop(context); // dismiss the progress dialog

    if (error != null) {
      showOverlayToast(context, error, icon: Icons.error_outline_rounded);
      return;
    }

    final edited = await showDialog<String>(
      context: context,
      builder: (ctx) => _TranscriptReviewDialog(
          initialText: result!.text, audioPath: result.audioPath),
    );

    // The dialog owned the clip while open; clean it up now.
    try {
      final f = File(result!.audioPath);
      if (f.existsSync()) await f.delete();
    } catch (_) {}

    if (edited == null || !mounted) return; // closed without saving
    final trimmed = edited.trim();
    if (trimmed.isEmpty) return;
    setState(() {
      _noteC.text =
          _noteC.text.trim().isEmpty ? trimmed : '${_noteC.text.trim()}\n\n$trimmed';
    });
    await _persist();
    if (mounted) {
      setState(() => _saving = false);
      showOverlayToast(context, l.transcriptionSavedToNote,
          icon: Icons.note_add_rounded);
    }
  }

  Future<void> _persist() async {
    setState(() => _saving = true);
    await _preview.stop();
    final newTitle =
        _titleC.text.trim().isEmpty ? widget.bookmark.title : _titleC.text.trim();
    // Pass the trimmed text as-is (even empty) so clearing the note actually
    // clears it - updateBookmark treats empty as "clear", null as "leave".
    final newNote = _noteC.text.trim();
    final svc = BookmarkService();
    await svc.updateBookmark(
      itemId: widget.itemId,
      bookmarkId: widget.bookmark.id,
      title: newTitle,
      note: newNote,
      api: widget.api,
    );
    if ((_seconds - widget.bookmark.positionSeconds).abs() >= 0.05) {
      await svc.moveBookmark(
        itemId: widget.itemId,
        bookmarkId: widget.bookmark.id,
        newPositionSeconds: _seconds,
        api: widget.api,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final mq = MediaQuery.of(context);
    // Clear the keyboard when it's open, otherwise the system navigation bar
    // (3-button mode) so the buttons aren't hidden behind it.
    final bottomInset = mq.viewInsets.bottom > mq.viewPadding.bottom
        ? mq.viewInsets.bottom
        : mq.viewPadding.bottom;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 4,
        bottom: 20 + bottomInset,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(l.editBookmark, style: tt.titleLarge),
                const Spacer(),
                Text(
                  _fmt(_seconds / _displaySpeed),
                  style: tt.titleMedium?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w600,
                    fontFeatures: [const FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleC,
              decoration: InputDecoration(
                  labelText: l.titleLabel, border: const OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteC,
              minLines: 3,
              maxLines: 8,
              keyboardType: TextInputType.multiline,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: l.noteOptionalLabel,
                border: const OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),
            Row(children: [
              // Nudges move the DISPLAYED time by the button amount, so the
              // raw delta is scaled up by the display speed.
              _nudgeBtn('-5', _saving ? null : () => _nudge(-5 * _displaySpeed)),
              _nudgeBtn('-1', _saving ? null : () => _nudge(-1 * _displaySpeed)),
              Expanded(
                child: Center(
                  child: Text(
                    _fmt(_seconds / _displaySpeed),
                    style: tt.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontFeatures: [const FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ),
              _nudgeBtn('+1', _saving ? null : () => _nudge(1 * _displaySpeed)),
              _nudgeBtn('+5', _saving ? null : () => _nudge(5 * _displaySpeed)),
            ]),
            const SizedBox(height: 4),
            Center(
              child: TextButton.icon(
                icon: _preview.isLoading
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : Icon(_preview.isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded),
                label: Text(_preview.isPlaying ? l.bookmarkPause : l.bookmarkListen),
                onPressed: _preview.isLoading ? null : _togglePreview,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.content_cut_rounded, size: 18),
                label: Text(l.clipExport),
                onPressed: _saving ? null : _openClipEditor,
              ),
            ),
            if (_transcriptionOn) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.record_voice_over_rounded, size: 18),
                  label: Text(l.transcribe),
                  onPressed: _saving ? null : _transcribe,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _saving
                      ? null
                      : () async {
                          await _preview.stop();
                          if (mounted) Navigator.pop(context);
                        },
                  child: Text(l.bookmarksScreenClose),
                ),
                const SizedBox(width: 8),
                // Jump is the secondary action; Save is the prominent primary
                // (rightmost, filled) so it's not easy to hit Jump by mistake.
                OutlinedButton(
                  onPressed: _saving
                      ? null
                      : () async {
                          await _persist();
                          if (mounted) {
                            Navigator.pop(context, (action: 'jump', position: _seconds));
                          }
                        },
                  child: Text(l.bookmarksJump),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _saving
                      ? null
                      : () async {
                          await _persist();
                          if (mounted) {
                            Navigator.pop(context, (action: 'saved', position: _seconds));
                          }
                        },
                  child: Text(l.save),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _nudgeBtn(String label, VoidCallback? onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          minimumSize: const Size(44, 38),
        ),
        child: Text(label),
      ),
    );
  }
}

/// Editable transcript plus inline playback of the extracted clip, so the user
/// can listen to the bookmarked spot while fixing up the text - WITHOUT moving
/// their real playback position. Uses a separate just_audio player (mirroring
/// the chapter editor's preview) and pauses the main player while the clip
/// plays. Returns the edited text on save, or null if closed.
class _TranscriptReviewDialog extends StatefulWidget {
  final String initialText;
  final String audioPath;
  const _TranscriptReviewDialog({required this.initialText, required this.audioPath});

  @override
  State<_TranscriptReviewDialog> createState() => _TranscriptReviewDialogState();
}

class _TranscriptReviewDialogState extends State<_TranscriptReviewDialog> {
  late final TextEditingController _controller;
  AudioPlayer? _preview;
  StreamSubscription<PlayerState>? _stateSub;
  bool _loading = false;
  bool _playing = false;
  bool? _mainWasPlaying;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    _preview?.dispose();
    _controller.dispose();
    // Resume the main player if we paused it to audition the clip.
    if (_mainWasPlaying == true) AudioPlayerService().play();
    super.dispose();
  }

  Future<void> _toggle() async {
    final main = AudioPlayerService();

    // First tap: spin up a separate preview player and load the clip.
    if (_preview == null) {
      setState(() => _loading = true);
      _mainWasPlaying ??= main.isPlaying;
      if (main.isPlaying) main.pause();
      final p = AudioPlayer();
      _preview = p;
      _stateSub = p.playerStateStream.listen((s) {
        if (!mounted) return;
        if (s.processingState == ProcessingState.completed) {
          p.pause();
          p.seek(Duration.zero);
          setState(() => _playing = false);
        } else {
          setState(() => _playing = s.playing);
        }
      });
      try {
        await p.setAudioSource(AudioSource.file(widget.audioPath));
      } catch (_) {
        if (mounted) setState(() => _loading = false);
        return;
      }
      if (!mounted) return;
      setState(() => _loading = false);
      await p.play();
      return;
    }

    final p = _preview!;
    if (p.playing) {
      await p.pause();
    } else {
      _mainWasPlaying ??= main.isPlaying;
      if (main.isPlaying) main.pause();
      if (p.processingState == ProcessingState.completed) {
        await p.seek(Duration.zero);
      }
      await p.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return AlertDialog(
      scrollable: true,
      icon: const Icon(Icons.record_voice_over_rounded),
      title: Text(l.transcriptionResultTitle),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _controller,
              minLines: 5,
              maxLines: 12,
              keyboardType: TextInputType.multiline,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              icon: _loading
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Icon(_playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
              label: Text(_playing
                  ? l.transcriptionPauseSnippet
                  : l.transcriptionPlaySnippet),
              onPressed: _loading ? null : _toggle,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.bookmarksScreenClose),
        ),
        FilledButton.icon(
          icon: const Icon(Icons.note_add_rounded, size: 18),
          label: Text(l.transcriptionSaveToNote),
          onPressed: () => Navigator.pop(context, _controller.text),
        ),
      ],
    );
  }
}
