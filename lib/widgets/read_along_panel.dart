import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/read_along_jobs.dart';
import '../utils/duration_format.dart';
import '../utils/file_size.dart';
import 'adaptive_modal.dart';

/// BookOrbit's read along maker for one book, where BookOrbit's web has it
/// on the Files tab: the Create button, then the latest job and how far it
/// got. Shows nothing for an account or server that can't make read alongs.
class ReadAlongPanel extends StatefulWidget {
  final String bookId;
  final String? bookLanguage;

  /// A read along was added to the book.
  final VoidCallback onAdded;

  const ReadAlongPanel({super.key, required this.bookId, this.bookLanguage, required this.onAdded});

  @override
  State<ReadAlongPanel> createState() => _ReadAlongPanelState();
}

class _ReadAlongPanelState extends State<ReadAlongPanel> {
  // Jobs run for minutes to hours; this is often enough for the bar to move
  // while the sheet is open, and nothing is asked once it closes.
  static const _runningPoll = Duration(seconds: 5);
  static const _reviewPoll = Duration(seconds: 30);

  BookOrbitApiService? _api;
  String? _myId;
  ReadAlongCapability? _cap;
  ReadAlongJob? _job;
  bool _loadFailed = false;
  bool _checking = false;
  String? _busy;
  String? _jobError;
  Timer? _poll;

  /// A job whose status the server refused or forgot; asking again can't work.
  String? _pollStoppedFor;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider?>();
    final api = auth?.apiService;
    _api = api is BookOrbitApiService ? api : null;
    _myId = auth?.userId;
    _load();
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final api = _api;
    if (api == null) return;
    setState(() => _checking = true);
    try {
      final cap = await api.readAlongCapability(widget.bookId);
      if (!mounted) return;
      setState(() {
        _cap = cap;
        _loadFailed = false;
        _checking = false;
      });
      _apply(cap?.latestJob, watched: false);
    } catch (e) {
      debugPrint('[ReadAlong] ${widget.bookId}: availability not checked: $e');
      if (!mounted) return;
      setState(() {
        _loadFailed = _cap == null;
        _checking = false;
      });
    }
  }

  /// [watched] is false for the job the book loaded with: a job that was
  /// already done then wasn't just added.
  void _apply(ReadAlongJob? next, {bool watched = true}) {
    final previous = _job;
    if (next != null && previous != null && next.id == previous.id) {
      final a = next.updatedAt;
      final b = previous.updatedAt;
      if (a != null && b != null && a.isBefore(b)) return;
    }
    setState(() {
      if (next?.id != previous?.id) _jobError = null;
      _job = next;
    });
    if (watched && previous != null && previous.id == next?.id && previous.active && !next!.active) {
      if (next.completed) {
        debugPrint('[ReadAlong] ${widget.bookId}: job ${next.id} added file ${next.outputFileId}');
        widget.onAdded();
      }
      // The book's read alongs and what's free to start changed with it.
      unawaited(_load());
    }
    _schedulePoll();
  }

  void _schedulePoll() {
    _poll?.cancel();
    _poll = null;
    final job = _job;
    if (!mounted || job == null || !job.active || _pollStoppedFor == job.id) return;
    _poll = Timer(job.awaitingReview ? _reviewPoll : _runningPoll, _pollTick);
  }

  Future<void> _pollTick() async {
    final api = _api;
    final job = _job;
    if (!mounted || api == null || job == null) return;
    // In the background nobody's watching; look again once the app's back.
    final state = WidgetsBinding.instance.lifecycleState;
    if (state == AppLifecycleState.hidden || state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      _schedulePoll();
      return;
    }
    final res = await api.readAlongJob(job.id);
    if (!mounted) return;
    if (res.job != null) {
      _apply(res.job);
      return;
    }
    if (res.failure == ReadAlongFailure.forbidden || res.failure == ReadAlongFailure.gone) {
      _pollStoppedFor = job.id;
      if (res.failure == ReadAlongFailure.gone) unawaited(_load());
      return;
    }
    _schedulePoll();
  }

  Future<void> _create({ReadAlongJob? startOver}) async {
    final api = _api;
    final cap = _cap;
    if (api == null || cap == null) return;
    final started = await showAdaptiveSheetDialog<ReadAlongJob>(
      context: context,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      builder: (ctx, scroll) => _CreateReadAlongSheet(
        api: api,
        bookId: widget.bookId,
        cap: cap,
        bookLanguage: widget.bookLanguage,
        startOver: startOver,
        scroll: scroll,
      ),
    );
    if (!mounted) return;
    if (started != null) {
      _apply(started);
    } else {
      // A start that failed may have been because things moved on.
      unawaited(_load());
    }
  }

  Future<bool> _confirm(String prompt, String yes, String no) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(prompt),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(no)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(yes, style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _act(String name, Future<({ReadAlongJob? job, ReadAlongFailure? failure})> Function(String id) call) async {
    final api = _api;
    final job = _job;
    if (!mounted || api == null || job == null || _busy != null) return;
    setState(() {
      _busy = name;
      _jobError = null;
    });
    final res = await call(job.id);
    if (!mounted) return;
    setState(() => _busy = null);
    if (res.job != null) {
      _apply(res.job);
      return;
    }
    final l = AppLocalizations.of(context)!;
    setState(() => _jobError = switch (res.failure) {
          ReadAlongFailure.forbidden => l.readAlongNotAllowed,
          ReadAlongFailure.gone => l.readAlongGone,
          ReadAlongFailure.conflict => l.readAlongMovedOn,
          _ => l.readAlongActionFailed,
        });
    final fresh = await api.readAlongJob(job.id);
    if (mounted && fresh.job != null) _apply(fresh.job);
    if (res.failure == ReadAlongFailure.gone && mounted) unawaited(_load());
  }

  String? _blockedNote(AppLocalizations l, ReadAlongCapability cap, bool cardShown) {
    final job = _job;
    if (job != null && job.active) return cardShown ? null : l.readAlongWhyRunning;
    return switch (cap.reason) {
      'worker_unavailable' => l.readAlongWhyWorkerOffline,
      'worker_incompatible' => l.readAlongWhyWorkerOutdated,
      'book_missing' => l.readAlongWhyFilesMissing,
      'no_epub' => cap.existing.isNotEmpty ? l.readAlongWhyNoEpubHasOne : l.readAlongWhyNoEpub,
      'too_many_audio_files' => l.readAlongWhyTooManyTracks,
      'epub_not_allowed' => l.readAlongWhyEpubNotAllowed,
      'library_not_mounted' => l.readAlongWhyNotMounted,
      'job_active' => cardShown ? null : l.readAlongWhyRunning,
      _ => l.readAlongWhyUnknown,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_api == null) return const SizedBox.shrink();
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final cap = _cap;

    if (cap == null) {
      if (!_loadFailed) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Row(children: [
          Expanded(child: Text(l.readAlongLoadFailed, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant))),
          TextButton(onPressed: _checking ? null : _load, child: Text(l.readAlongCheckAgain)),
        ]),
      );
    }

    final job = _job;
    final card = job != null && job.dismissedAt == null && !(job.completed && job.outputFileId == null) ? job : null;
    final entry = cap.entry(job);
    if (entry == ReadAlongEntry.hidden && card == null) return const SizedBox.shrink();
    final note = entry == ReadAlongEntry.blocked ? _blockedNote(l, cap, card != null) : null;
    final myId = _myId;

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (entry != ReadAlongEntry.hidden) ...[
        const SizedBox(height: 16),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: FilledButton.tonalIcon(
            onPressed: entry == ReadAlongEntry.available ? () => _create() : null,
            icon: const Icon(Icons.record_voice_over_rounded, size: 18),
            label: Text(l.readAlongCreate),
          ),
        ),
        if (note != null) ...[
          const SizedBox(height: 6),
          Text(note, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
        ],
      ],
      if (card != null) ...[
        const SizedBox(height: 12),
        _JobCard(
          job: card,
          busy: _busy,
          error: _jobError,
          othersJob: !card.canManage || (myId != null && card.requestedById != null && '${card.requestedById}' != myId),
          canStartOver: entry == ReadAlongEntry.available,
          onCancel: () async {
            if (await _confirm(l.readAlongCancelPrompt, l.readAlongCancel, l.readAlongKeepRunning)) {
              await _act('cancel', _api!.cancelReadAlong);
            }
          },
          onDiscard: () async {
            if (await _confirm(l.readAlongDiscardPrompt, l.readAlongDiscard, l.readAlongKeepIt)) {
              await _act('discard', _api!.cancelReadAlong);
            }
          },
          onPublish: () => _act('publish', _api!.publishReadAlong),
          onRetry: () => _act('retry', _api!.retryReadAlong),
          onDismiss: () => _act('dismiss', _api!.dismissReadAlong),
          onStartOver: () => _create(startOver: card),
        ),
      ],
    ]);
  }
}

class _JobCard extends StatelessWidget {
  final ReadAlongJob job;
  final String? busy;
  final String? error;
  final bool othersJob;
  final bool canStartOver;
  final VoidCallback onCancel;
  final VoidCallback onDiscard;
  final VoidCallback onPublish;
  final VoidCallback onRetry;
  final VoidCallback onDismiss;
  final VoidCallback onStartOver;

  const _JobCard({
    required this.job,
    required this.busy,
    required this.error,
    required this.othersJob,
    required this.canStartOver,
    required this.onCancel,
    required this.onDiscard,
    required this.onPublish,
    required this.onRetry,
    required this.onDismiss,
    required this.onStartOver,
  });

  String _title(AppLocalizations l) {
    if (job.stopping) return l.readAlongStopping;
    if (job.queued) return l.readAlongWaiting;
    if (job.processing) return _stageLabel(l, job.stage);
    if (job.awaitingReview) return l.readAlongReviewTitle;
    if (job.completed) return job.status == 'completed_with_warnings' ? l.readAlongReadyWarnings : l.readAlongReady;
    if (job.discarded) return l.readAlongDiscarded;
    if (job.failed) return l.readAlongFailed;
    return l.readAlongCancelled;
  }

  static String _stageLabel(AppLocalizations l, String stage) => switch (stage) {
        'queued' => l.readAlongWaiting,
        'preparing_audio' => l.readAlongStagePreparingAudio,
        'downloading_model' => l.readAlongStageDownloadingModel,
        'generating_emissions' => l.readAlongStageListening,
        'marking_up_ebook' => l.readAlongStageMarkingUp,
        'aligning' => l.readAlongStageAligning,
        'validating' => l.readAlongStageChecking,
        'awaiting_review' => l.readAlongReviewTitle,
        'publishing' => l.readAlongStagePublishing,
        _ => l.readAlongStageWorking,
      };

  static String errorText(AppLocalizations l, String? code) => switch (code) {
        'worker_unavailable' => l.readAlongErrorWorkerOffline,
        'worker_incompatible' => l.readAlongWhyWorkerOutdated,
        'worker_crashed' => l.readAlongErrorWorkerCrashed,
        'library_not_mounted' => l.readAlongWhyNotMounted,
        'source_missing' => l.readAlongErrorSourceMissing,
        'source_changed' => l.readAlongErrorSourceChanged,
        'invalid_source' => l.readAlongErrorInvalidSource,
        'unsupported_language' => l.readAlongErrorLanguage,
        'insufficient_storage' => l.readAlongErrorStorage,
        'audio_processing_failed' => l.readAlongErrorAudio,
        'model_download_failed' => l.readAlongErrorModel,
        'inference_failed' => l.readAlongErrorListening,
        'markup_failed' => l.readAlongErrorMarkup,
        'alignment_failed' => l.readAlongErrorAlignment,
        'invalid_output' => l.readAlongErrorOutput,
        'publication_failed' => l.readAlongErrorPublish,
        'review_expired' => l.readAlongExpired,
        'discarded' => l.readAlongErrorDiscarded,
        'cancelled' => l.readAlongErrorCancelled,
        _ => l.readAlongErrorUnknown,
      };

  List<String> _description(AppLocalizations l, String locale) {
    if (job.stopping) return [l.readAlongStoppingHint];
    if (job.queued) {
      final ahead = job.queuePosition;
      if (ahead == null) return const [];
      return [ahead == 0 ? l.readAlongNextInLine : l.readAlongJobsAhead(ahead)];
    }
    if (job.processing) {
      final total = job.stageTotal ?? 0;
      // The worker counts finished items, so the one under way is the next.
      final current = ((job.stageCurrent ?? 0) + 1).clamp(1, total < 1 ? 1 : total);
      final started = job.startedAt;
      final seconds = started == null ? null : DateTime.now().difference(started).inSeconds;
      return [
        if (total > 0)
          switch (job.stageUnit) {
            'file' => l.readAlongFileOf(current, total),
            'track' => l.readAlongTrackOf(current, total),
            'chapter' => l.readAlongChapterOf(current, total),
            _ => l.readAlongStepOf(current, total),
          },
        if (job.stage == 'downloading_model') l.readAlongFirstRun,
        if (seconds != null) seconds < 60 ? l.readAlongJustStarted : l.readAlongRunningFor(formatHm(seconds.toDouble())),
      ];
    }
    if (job.awaitingReview) {
      final matched = job.matchedSentences;
      final total = job.totalSentences;
      if (matched == null || total == null || total <= 0) return [l.readAlongReviewPlain];
      return [l.readAlongReviewMatched(NumberFormat.percentPattern(locale).format(matched / total))];
    }
    if (job.completed) return [job.replaceFileId != null ? l.readAlongReplaced : l.readAlongAdded];
    if (job.expired) return [l.readAlongExpired];
    if (job.failed) return [errorText(l, job.errorCode)];
    return [l.readAlongNothingAdded];
  }

  List<String> _coverage(AppLocalizations l, String locale) {
    final matched = job.matchedSentences;
    final total = job.totalSentences;
    if (!job.completed || matched == null || total == null) return const [];
    final numbers = NumberFormat.decimalPattern(locale);
    return [
      l.readAlongMatchedSentences(numbers.format(matched), numbers.format(total)),
      if (job.audioUsed != null) l.readAlongAudioUsed(NumberFormat.percentPattern(locale).format(job.audioUsed)),
    ];
  }

  String? _outside(AppLocalizations l) {
    if (!(job.completed || job.awaitingReview) || job.outsideTitles.isEmpty) return null;
    final names = [...job.outsideTitles, if (job.outsideMore > 0) l.readAlongOutsideMore(job.outsideMore)];
    return l.readAlongOutside(names.join(', '));
  }

  String _warning(AppLocalizations l, String code) => switch (code) {
        'unaligned_tracks' => l.readAlongWarnUnaligned,
        'unmatched_text' => l.readAlongWarnUnmatched,
        'interpolated_text' => l.readAlongWarnInterpolated,
        'dropped_text' => l.readAlongWarnDropped,
        _ => '',
      };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context).toString();
    final date = DateFormat.MMMd(locale);
    final now = DateTime.now();
    final description = _description(l, locale);
    final coverage = _coverage(l, locale);
    final outside = _outside(l);
    final warnings = job.completed ? [for (final w in job.warnings) _warning(l, w)].where((w) => w.isNotEmpty).toList() : const <String>[];
    final expires = job.expiresAt;
    final reviewExpiry = job.awaitingReview && expires != null && expires.difference(now) < const Duration(days: 7)
        ? l.readAlongReviewExpires(date.format(expires))
        : null;
    final retryable = job.canRetry(now) && job.canManage;
    final retryHint = retryable ? l.readAlongRetryUntil(date.format(job.retryableUntil!)) : null;
    final subtle = tt.bodySmall?.copyWith(color: cs.onSurfaceVariant);

    final (IconData icon, Color iconColor) = job.running
        ? (Icons.sync_rounded, cs.primary)
        : job.awaitingReview
            ? (Icons.fact_check_rounded, cs.tertiary)
            : job.completed
                ? (Icons.check_circle_rounded, cs.primary)
                : job.failed && !job.expired
                    ? (Icons.error_rounded, cs.error)
                    : (Icons.block_rounded, cs.onSurfaceVariant);

    Widget spinner() => const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2));

    final step = readAlongStepOf(job.stage);
    final stepLabels = [
      l.readAlongStepAudio,
      l.readAlongStepSpeech,
      l.readAlongStepText,
      l.readAlongStepAlign,
      l.readAlongStepCheck,
      l.readAlongStepAdd,
    ];

    final buttons = <Widget>[
      if (job.canCancel)
        OutlinedButton(
          onPressed: busy != null ? null : onCancel,
          child: busy == 'cancel' ? spinner() : Text(l.readAlongCancel),
        ),
      if (job.awaitingReview && job.canManage) ...[
        FilledButton(
          onPressed: busy != null ? null : onPublish,
          child: busy == 'publish' ? spinner() : Text(l.readAlongAddAnyway),
        ),
        OutlinedButton(
          onPressed: busy != null ? null : onDiscard,
          child: busy == 'discard' ? spinner() : Text(l.readAlongDiscard),
        ),
      ],
      if (retryable)
        FilledButton.tonalIcon(
          onPressed: busy != null ? null : onRetry,
          icon: busy == 'retry' ? spinner() : const Icon(Icons.replay_rounded, size: 18),
          label: Text(l.retry),
        ),
      if ((job.failed || job.cancelled) && job.canManage && canStartOver)
        OutlinedButton(onPressed: busy != null ? null : onStartOver, child: Text(l.readAlongStartOver)),
    ];

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.fromLTRB(14, 10, 6, 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text(l.readAlong.toUpperCase(),
                style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
          ),
          if (othersJob)
            Flexible(
              child: Text(
                job.requestedByName != null ? l.readAlongStartedBy(job.requestedByName!) : l.readAlongStartedByOther,
                style: subtle,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          if (job.finished && job.canManage)
            IconButton(
              tooltip: l.dismiss,
              visualDensity: VisualDensity.compact,
              onPressed: busy != null ? null : onDismiss,
              icon: busy == 'dismiss' ? spinner() : const Icon(Icons.close_rounded, size: 18),
            )
          else
            const SizedBox(height: 40),
        ]),
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: job.running
                    ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: iconColor))
                    : Icon(icon, size: 18, color: iconColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_title(l), style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(description.join(' · '), style: subtle),
                  ],
                  if (coverage.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(coverage.join(' · '), style: subtle),
                  ],
                  if (outside != null) ...[
                    const SizedBox(height: 2),
                    Text(outside, style: subtle),
                  ],
                  if (reviewExpiry != null) ...[
                    const SizedBox(height: 2),
                    Text(reviewExpiry, style: subtle),
                  ],
                  if (retryHint != null) ...[
                    const SizedBox(height: 2),
                    Text(retryHint, style: subtle),
                  ],
                ]),
              ),
              if (job.processing && !job.stopping) ...[
                const SizedBox(width: 8),
                Text(NumberFormat.percentPattern(locale).format(job.progress / 100),
                    style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              ],
            ]),
            if (job.processing) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(value: job.progress / 100, minHeight: 6),
              ),
              if (!job.stopping) ...[
                const SizedBox(height: 10),
                Wrap(spacing: 12, runSpacing: 6, children: [
                  for (var i = 0; i < stepLabels.length; i++)
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      if (step >= 0 && i < step)
                        Icon(Icons.check_circle_rounded, size: 14, color: cs.primary)
                      else if (i == step)
                        SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.6, color: cs.primary))
                      else
                        Icon(Icons.circle_outlined, size: 14, color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
                      const SizedBox(width: 4),
                      Text(stepLabels[i],
                          style: tt.labelSmall?.copyWith(
                              color: i <= step ? cs.onSurface : cs.onSurfaceVariant.withValues(alpha: 0.7))),
                    ]),
                ]),
              ],
            ],
            if (job.awaitingReview) ...[
              const SizedBox(height: 8),
              Text(l.readAlongReviewWeb, style: subtle),
            ],
            for (final w in warnings) ...[
              const SizedBox(height: 6),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.warning_amber_rounded, size: 16, color: cs.tertiary),
                const SizedBox(width: 6),
                Expanded(child: Text(w, style: tt.bodySmall)),
              ]),
            ],
            if (error != null) ...[
              const SizedBox(height: 8),
              Text(error!, style: tt.bodySmall?.copyWith(color: cs.error)),
            ],
            if (buttons.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: buttons),
            ],
          ]),
        ),
      ]),
    );
  }
}

class _CreateReadAlongSheet extends StatefulWidget {
  final BookOrbitApiService api;
  final String bookId;
  final ReadAlongCapability cap;
  final String? bookLanguage;

  /// The job Start over came from, whose picks fill the form.
  final ReadAlongJob? startOver;
  final ScrollController scroll;

  const _CreateReadAlongSheet({
    required this.api,
    required this.bookId,
    required this.cap,
    required this.bookLanguage,
    required this.startOver,
    required this.scroll,
  });

  @override
  State<_CreateReadAlongSheet> createState() => _CreateReadAlongSheetState();
}

class _CreateReadAlongSheetState extends State<_CreateReadAlongSheet> {
  int? _epub;
  String _language = '';
  String _granularity = 'sentence';

  // Radio value for keeping the old read alongs beside the new one.
  static const _keep = -1;

  /// The read along to overwrite, or [_keep].
  int _replace = _keep;
  String? _savedDefault;
  bool _defaultLoaded = false;
  bool _defaultSaved = false;
  bool _defaultFailed = false;
  bool _savingDefault = false;
  bool _starting = false;
  String? _error;

  ReadAlongCapability get _cap => widget.cap;
  bool get _canReplace => widget.api.canReplaceReadAlongs;
  String? get _bookCode => readAlongLanguageOf(widget.bookLanguage, _cap.languages);

  @override
  void initState() {
    super.initState();
    final from = widget.startOver;
    final epubIds = _cap.epubs.map((f) => f.id).toList();
    _epub = from?.epubFileId != null && epubIds.contains(from!.epubFileId) ? from.epubFileId : epubIds.firstOrNull;
    _granularity = from?.granularity ?? 'sentence';
    _language = _preferredLanguage() ?? '';
    final existingIds = _cap.existing.map((f) => f.fileId).toSet();
    if (_canReplace) {
      final previous = from?.replaceFileId;
      if (previous != null && existingIds.contains(previous)) {
        _replace = previous;
      } else {
        // BookOrbit's own output is safe to overwrite; an imported one may
        // be the only copy of someone's work.
        _replace = _cap.existing.where((f) => f.madeByBookOrbit).firstOrNull?.fileId ?? _keep;
      }
    }
    _loadDefault();
  }

  /// The last job's language, then the book's, then the saved default.
  String? _preferredLanguage() {
    final from = widget.startOver?.language;
    final candidates = [
      if (from != null) readAlongLanguageOf(from, _cap.languages) else _bookCode,
      _savedDefault,
    ];
    return candidates.whereType<String>().where(_cap.languages.contains).firstOrNull;
  }

  Future<void> _loadDefault() async {
    final saved = await widget.api.readAlongDefaultLanguage();
    if (!mounted) return;
    setState(() {
      _savedDefault = saved;
      _defaultLoaded = true;
      if (_language.isEmpty) _language = _preferredLanguage() ?? '';
    });
  }

  Future<void> _saveDefault() async {
    final code = _language;
    if (code.isEmpty || _savingDefault) return;
    setState(() {
      _savingDefault = true;
      _defaultFailed = false;
    });
    final ok = await widget.api.setReadAlongDefaultLanguage(code);
    if (!mounted) return;
    setState(() {
      _savingDefault = false;
      if (ok) _savedDefault = code;
      if (_language == code) {
        _defaultSaved = ok;
        _defaultFailed = !ok;
      }
    });
  }

  String? _languageHint(AppLocalizations l) {
    final isDefault = _language.isNotEmpty && _language == _savedDefault;
    if (isDefault && _defaultSaved) return l.readAlongLanguageSaved;
    final raw = widget.bookLanguage?.trim();
    // Matching narration in one language against a model for another fails.
    if (raw != null && raw.isNotEmpty && _bookCode == null) return l.readAlongLanguageUnsupported(raw);
    if (isDefault) return l.readAlongLanguageIsDefault;
    if (_language.isNotEmpty && _language == _bookCode) return l.readAlongLanguageFromBook;
    return null;
  }

  String? _lowDisk(AppLocalizations l) {
    final free = _cap.workerFreeBytes;
    if (free == null) return null;
    final audioBytes = _cap.audio.fold<int>(0, (sum, f) => sum + (f.size ?? 0));
    final allTimed = _cap.audio.every((f) => f.duration != null);
    final needed = ReadAlongCapability.workBytes(
      audioBytes: audioBytes,
      epubBytes: _cap.epubs.where((f) => f.id == _epub).firstOrNull?.size ?? 0,
      audioSeconds: allTimed ? _cap.audio.fold<double>(0, (sum, f) => sum + f.duration!) : null,
    );
    if (needed <= free) return null;
    return l.readAlongLowDisk(formatFileSize(needed), formatFileSize(free));
  }

  Future<void> _start() async {
    final epub = _epub;
    if (epub == null || _language.isEmpty || _starting) return;
    final l = AppLocalizations.of(context)!;
    setState(() {
      _starting = true;
      _error = null;
    });
    final res = await widget.api.startReadAlong(
      widget.bookId,
      epubFileId: epub,
      language: _language,
      granularity: _granularity,
      replaceFileId: _canReplace && _replace != _keep ? _replace : null,
    );
    if (!mounted) return;
    if (res.job != null) {
      Navigator.of(context).pop(res.job);
      return;
    }
    setState(() {
      _starting = false;
      _error = switch (res.failure) {
        ReadAlongFailure.invalid => l.readAlongStartInvalid,
        ReadAlongFailure.forbidden => l.readAlongNotAllowed,
        ReadAlongFailure.conflict => l.readAlongWhyRunning,
        ReadAlongFailure.unavailable => l.readAlongStartOffline,
        _ => l.readAlongStartFailed,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final subtle = tt.bodySmall?.copyWith(color: cs.onSurfaceVariant);
    final heading = tt.titleSmall?.copyWith(fontWeight: FontWeight.w700);
    final audioSeconds = _cap.audio.fold<double>(0, (sum, f) => sum + (f.duration ?? 0));
    final hint = _languageHint(l);
    final lowDisk = _lowDisk(l);
    final languages = [..._cap.languages]
      ..sort((a, b) => (readAlongLanguageNames[a] ?? a).compareTo(readAlongLanguageNames[b] ?? b));
    final canStart = _epub != null && _cap.audio.isNotEmpty && _language.isNotEmpty && !_starting;
    final existing = _cap.existing;

    String existingLine(ReadAlongExisting f) => [
          f.madeByBookOrbit ? l.readAlongMadeByBookOrbit : l.readAlongImported,
          if (f.size != null) formatFileSize(f.size!),
        ].join(' · ');

    return Column(children: [
      Expanded(
        child: ListView(
          controller: widget.scroll,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: cs.onSurface.withValues(alpha: 0.24),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(l.readAlongSheetTitle, style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(l.readAlongSheetIntro, style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(height: 20),
            Text(l.readAlongEbook, style: heading),
            const SizedBox(height: 4),
            if (_cap.epubs.length > 1) ...[
              Text(l.readAlongEbookHint, style: subtle),
              RadioGroup<int>(
                groupValue: _epub,
                onChanged: (v) => setState(() => _epub = v ?? _epub),
                child: Column(children: [
                  for (final f in _cap.epubs)
                    RadioListTile<int>(
                      contentPadding: EdgeInsets.zero,
                      value: f.id,
                      title: Text(f.filename, maxLines: 2, overflow: TextOverflow.ellipsis),
                      subtitle: f.size != null ? Text(formatFileSize(f.size!)) : null,
                    ),
                ]),
              ),
            ] else if (_cap.epubs.isNotEmpty)
              Text(
                [_cap.epubs.first.filename, if (_cap.epubs.first.size != null) formatFileSize(_cap.epubs.first.size!)]
                    .join(' · '),
                style: tt.bodyMedium,
              ),
            const SizedBox(height: 16),
            Text(l.readAlongAudio, style: heading),
            const SizedBox(height: 4),
            Text(
              [l.readAlongTracks(_cap.audio.length), if (audioSeconds > 0) formatHm(audioSeconds)].join(' · '),
              style: tt.bodyMedium,
            ),
            if (existing.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(l.readAlongExistingTitle(existing.length), style: heading),
              if (_canReplace) ...[
                RadioGroup<int>(
                  groupValue: _replace,
                  onChanged: (v) => setState(() => _replace = v ?? _keep),
                  child: Column(children: [
                    for (final f in existing)
                      RadioListTile<int>(
                        contentPadding: EdgeInsets.zero,
                        value: f.fileId,
                        title: Text(l.readAlongReplace(f.filename), maxLines: 3, overflow: TextOverflow.ellipsis),
                        subtitle: Text(existingLine(f)),
                      ),
                    RadioListTile<int>(
                      contentPadding: EdgeInsets.zero,
                      value: _keep,
                      title: Text(l.readAlongKeepBoth(existing.length)),
                      subtitle: Text(l.readAlongKeepHint),
                    ),
                  ]),
                ),
                if (_replace != _keep) Text(l.readAlongReplaceHint, style: subtle),
              ] else ...[
                const SizedBox(height: 6),
                for (final f in existing)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(f.filename, style: tt.bodyMedium),
                      Text(existingLine(f), style: subtle),
                    ]),
                  ),
                Text(l.readAlongReplaceNotAllowed, style: subtle),
              ],
            ],
            const SizedBox(height: 20),
            Text(l.readAlongLanguage, style: heading),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              key: ValueKey('language-$_language'),
              initialValue: _language.isEmpty ? null : _language,
              isExpanded: true,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                isDense: true,
              ),
              hint: Text(l.readAlongPickLanguage),
              items: [
                for (final code in languages)
                  DropdownMenuItem(value: code, child: Text(readAlongLanguageNames[code] ?? code)),
              ],
              onChanged: (v) => setState(() {
                _language = v ?? '';
                _defaultSaved = false;
                _defaultFailed = false;
              }),
            ),
            if (hint != null) ...[
              const SizedBox(height: 6),
              Text(hint, style: subtle),
            ],
            if (_defaultFailed) ...[
              const SizedBox(height: 6),
              Text(l.readAlongDefaultFailed, style: tt.bodySmall?.copyWith(color: cs.error)),
            ],
            if (_defaultLoaded && _language.isNotEmpty && _language != _savedDefault)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton(
                  onPressed: _savingDefault ? null : _saveDefault,
                  child: Text(l.readAlongSetDefault),
                ),
              ),
            const SizedBox(height: 16),
            Text(l.readAlongHighlighting, style: heading),
            RadioGroup<String>(
              groupValue: _granularity,
              onChanged: (v) => setState(() => _granularity = v ?? _granularity),
              child: Column(children: [
                RadioListTile<String>(
                  contentPadding: EdgeInsets.zero,
                  value: 'sentence',
                  title: Text(l.readAlongSentence),
                  subtitle: Text(l.readAlongSentenceHint),
                ),
                RadioListTile<String>(
                  contentPadding: EdgeInsets.zero,
                  value: 'word',
                  title: Text(l.readAlongWord),
                  subtitle: Text(l.readAlongWordHint),
                ),
              ]),
            ),
            const SizedBox(height: 12),
            if (_cap.estimatedSize != null) ...[
              Text(l.readAlongEstimatedSize(formatFileSize(_cap.estimatedSize!)), style: subtle),
              const SizedBox(height: 4),
            ],
            Text(l.readAlongBackgroundNote, style: subtle),
            if (lowDisk != null) ...[
              const SizedBox(height: 8),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.warning_amber_rounded, size: 16, color: cs.tertiary),
                const SizedBox(width: 6),
                Expanded(child: Text(lowDisk, style: tt.bodySmall)),
              ]),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: tt.bodyMedium?.copyWith(color: cs.error)),
            ],
          ],
        ),
      ),
      SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _starting ? null : () => Navigator.of(context).pop(),
                child: Text(l.cancel),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: canStart ? _start : null,
                child: _starting
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(l.readAlongStart),
              ),
            ),
          ]),
        ),
      ),
    ]);
  }
}
