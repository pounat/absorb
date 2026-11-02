import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../services/api_service.dart';
import '../services/book_requests.dart';
import '../widgets/absorb_page_header.dart';
import '../widgets/overlay_toast.dart';

/// Picks a release by hand for a book request: BookOrbit asks its indexers,
/// the releases come back ranked by its release profile, and the one picked
/// goes to the download client. Pops with the updated request once grabbed.
class BookRequestReleaseScreen extends StatefulWidget {
  final ApiService api;
  final BookRequest request;

  const BookRequestReleaseScreen({super.key, required this.api, required this.request});

  static Future<BookRequest?> open(BuildContext context, ApiService api, BookRequest request) =>
      Navigator.push<BookRequest>(
        context,
        MaterialPageRoute(builder: (_) => BookRequestReleaseScreen(api: api, request: request)),
      );

  @override
  State<BookRequestReleaseScreen> createState() => _BookRequestReleaseScreenState();
}

class _BookRequestReleaseScreenState extends State<BookRequestReleaseScreen> {
  BookRequestReleases? _result;
  bool _loading = true;
  String? _error;
  bool _failed = false;
  int _generation = 0;
  BookRequestReleaseSort _sort = BookRequestReleaseSort.best;
  String? _grabbing;
  bool _termsOpen = false;
  late final _titleCtrl = TextEditingController(text: widget.request.title);
  late final _authorCtrl = TextEditingController(text: widget.request.authors.isEmpty ? '' : widget.request.authors.first);
  late final _isbnCtrl = TextEditingController(text: widget.request.isbn ?? '');

  @override
  void initState() {
    super.initState();
    _search();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _authorCtrl.dispose();
    _isbnCtrl.dispose();
    super.dispose();
  }

  Future<void> _search({bool refresh = false, bool custom = false}) async {
    FocusManager.instance.primaryFocus?.unfocus();
    final generation = ++_generation;
    setState(() {
      _loading = true;
      _failed = false;
      _error = null;
    });
    final res = await widget.api.bookRequestReleases(
      widget.request.id,
      refresh: refresh,
      terms: custom
          ? (
              title: _titleCtrl.text,
              author: _authorCtrl.text,
              isbn: _isbnCtrl.text.trim().isEmpty ? null : _isbnCtrl.text.trim(),
            )
          : null,
    );
    if (!mounted || generation != _generation) return;
    setState(() {
      _loading = false;
      _result = res.releases ?? _result;
      _failed = res.releases == null;
      _error = res.error;
      final r = res.releases;
      if (r != null && !custom) {
        if (r.title.isNotEmpty) _titleCtrl.text = r.title;
        if (r.authors.isNotEmpty) _authorCtrl.text = r.authors.first;
        _isbnCtrl.text = r.isbn ?? '';
      }
    });
  }

  Future<void> _grab(BookRequestRelease release) async {
    final l = AppLocalizations.of(context)!;
    if (_grabbing != null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.breqGrabTitle),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(release.title, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text([
            release.indexerName,
            if (release.sizeBytes != null) formatReleaseSize(release.sizeBytes),
            if (release.formats.isNotEmpty) release.formats.join(', ').toUpperCase(),
          ].join(' · ')),
          if (release.vipOnly) ...[
            const SizedBox(height: 8),
            Text(l.breqReleaseVipWarning, style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
          ],
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.breqGrab)),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _grabbing = release.guid);

    // BookOrbit's picker looks inside the release first and won't send one
    // with nothing in it that can be filed.
    final inspection = await widget.api.inspectBookRequestRelease(widget.request.id, release.indexerId, release.guid);
    if (!mounted) return;
    if (inspection.status == null || inspection.status == 'no_supported_file') {
      setState(() => _grabbing = null);
      showOverlayToast(
        context,
        inspection.status == 'no_supported_file'
            ? l.breqReleaseNoBookFile
            : inspection.error != null
                ? l.breqReleaseCheckFailedReason(inspection.error!)
                : l.breqReleaseCheckFailed,
        icon: Icons.error_outline_rounded,
      );
      return;
    }

    final res = await widget.api.grabBookRequestRelease(widget.request.id, release.indexerId, release.guid);
    if (!mounted) return;
    setState(() => _grabbing = null);
    if (res.request == null) {
      showOverlayToast(context, res.error != null ? l.breqGrabFailedReason(res.error!) : l.breqGrabFailed,
          icon: Icons.error_outline_rounded);
      return;
    }
    showOverlayToast(context, l.breqGrabbed, icon: Icons.download_rounded);
    Navigator.pop(context, res.request);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;
    final result = _result;
    final releases = result == null ? const <BookRequestRelease>[] : sortBookRequestReleases(result.releases, _sort);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 8, 0),
            child: Row(children: [
              Expanded(child: AbsorbPageHeader(title: l.breqFindRelease, padding: EdgeInsets.zero)),
              IconButton(
                tooltip: l.breqSearchAgain,
                icon: Icon(Icons.refresh_rounded, color: cs.onSurfaceVariant),
                onPressed: _loading ? null : () => _search(refresh: true),
              ),
              IconButton(
                icon: Icon(Icons.close_rounded, color: cs.onSurfaceVariant),
                onPressed: () => Navigator.pop(context),
              ),
            ]),
          ),
          Expanded(
            child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 32), children: [
              _header(context),
              const SizedBox(height: 10),
              _terms(context),
              const SizedBox(height: 10),
              if (_loading)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Column(children: [
                    const SizedBox(width: 26, height: 26, child: CircularProgressIndicator(strokeWidth: 2.5)),
                    const SizedBox(height: 14),
                    Text(l.breqSearchingIndexers,
                        textAlign: TextAlign.center, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                  ]),
                )
              else if (_failed)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(children: [
                    Text(_error != null ? l.breqReleasesFailedReason(_error!) : l.breqReleasesFailed,
                        textAlign: TextAlign.center, style: tt.bodyMedium?.copyWith(color: cs.error)),
                    TextButton(onPressed: _search, child: Text(l.retry)),
                  ]),
                ),
              if (!_loading && result != null) ...[
                _sources(context, result),
                const SizedBox(height: 8),
                if (releases.isNotEmpty) _sortRow(context),
                if (releases.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(_emptyText(l, result),
                        textAlign: TextAlign.center, style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                  ),
                for (final r in releases) _releaseRow(context, r),
              ],
            ]),
          ),
        ]),
      ),
    );
  }

  String _emptyText(AppLocalizations l, BookRequestReleases r) {
    if (r.configuredIndexers == 0) return l.breqNoSourcesSetUp;
    if (r.enabledIndexers == 0) return l.breqNoSourcesOn;
    if (r.indexers.isEmpty && r.uncoveredIndexers > 0) return l.breqNoSourceCarries;
    return l.breqNoReleases;
  }

  Widget _header(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final r = widget.request;
    final box = Container(
      width: 44,
      height: 64,
      color: cs.surfaceContainerHighest,
      child: Icon(Icons.menu_book_rounded, size: 18, color: cs.onSurfaceVariant),
    );
    return Row(children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: r.coverUrl == null
            ? box
            : CachedNetworkImage(
                imageUrl: r.coverUrl!,
                width: 44,
                height: 64,
                fit: BoxFit.cover,
                placeholder: (_, __) => box,
                errorWidget: (_, __, ___) => box,
              ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(r.title, style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          if (r.authors.isNotEmpty)
            Text(r.authors.join(', '), style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
        ]),
      ),
    ]);
  }

  Widget _terms(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;
    InputDecoration field(String label, {String? hint}) => InputDecoration(
          labelText: label,
          hintText: hint,
          isDense: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        );
    return Container(
      decoration: BoxDecoration(color: cs.surfaceContainerHigh, borderRadius: BorderRadius.circular(12)),
      child: Column(children: [
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() => _termsOpen = !_termsOpen),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
            child: Row(children: [
              Icon(Icons.tune_rounded, size: 18, color: cs.onSurfaceVariant),
              const SizedBox(width: 8),
              Expanded(child: Text(l.breqSearchTerms, style: tt.labelLarge?.copyWith(fontWeight: FontWeight.w600))),
              Icon(_termsOpen ? Icons.expand_less_rounded : Icons.expand_more_rounded, color: cs.onSurfaceVariant),
            ]),
          ),
        ),
        if (_termsOpen)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Column(children: [
              TextField(controller: _titleCtrl, decoration: field(l.breqTitleHint)),
              const SizedBox(height: 8),
              TextField(controller: _authorCtrl, decoration: field(l.breqAuthorHint)),
              const SizedBox(height: 8),
              TextField(
                controller: _isbnCtrl,
                keyboardType: TextInputType.number,
                decoration: field(l.isbnLabel, hint: l.breqIsbnHint),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _loading ? null : () => _search(custom: true),
                  icon: const Icon(Icons.search_rounded, size: 18),
                  label: Text(l.breqSearch),
                ),
              ),
            ]),
          ),
      ]),
    );
  }

  Widget _sources(BuildContext context, BookRequestReleases r) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;
    String failure(String? code) => switch (code) {
          'unauthorized' => l.breqIndexerUnauthorized,
          'throttled' => l.breqIndexerThrottled,
          'timeout' => l.breqIndexerTimeout,
          'unreachable' => l.breqIndexerUnreachable,
          'unsupportedMedium' => l.breqIndexerNoMedium,
          _ => l.breqIndexerError,
        };
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
        r.cached ? '${l.breqReleaseCount(r.releases.length)} · ${l.breqFromCache}' : l.breqReleaseCount(r.releases.length),
        style: tt.labelLarge?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w600),
      ),
      if (r.indexers.isNotEmpty) ...[
        const SizedBox(height: 6),
        Wrap(spacing: 6, runSpacing: 6, children: [
          for (final i in r.indexers)
            _chip(
              i.ok ? '${i.name} · ${i.count}' : '${i.name} · ${failure(i.failure)}',
              i.ok ? (i.count > 0 ? cs.primary : cs.onSurfaceVariant) : cs.error,
            ),
        ]),
      ],
    ]);
  }

  Widget _sortRow(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          for (final s in BookRequestReleaseSort.values)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ChoiceChip(
                label: Text(switch (s) {
                  BookRequestReleaseSort.best => l.breqSortBest,
                  BookRequestReleaseSort.seeders => l.breqSortSeeders,
                  BookRequestReleaseSort.size => l.breqSortSize,
                  BookRequestReleaseSort.newest => l.breqSortNewest,
                }),
                selected: _sort == s,
                onSelected: (_) => setState(() => _sort = s),
              ),
            ),
        ]),
      ),
    );
  }

  Widget _chip(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.13), borderRadius: BorderRadius.circular(6)),
        child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
      );

  String _reasonLabel(AppLocalizations l, BookRequestReleaseReason r) {
    final d = r.detail ?? '';
    return switch (r.code) {
      'isbnMatch' => l.breqReasonIsbn,
      'titleMatch' => l.breqReasonTitle,
      'authorMatch' => l.breqReasonAuthor,
      'preferredFormat' => l.breqReasonPreferredFormat(d.toUpperCase()),
      'knownFormat' => l.breqReasonFormat(d.toUpperCase()),
      'unknownFormat' => l.breqReasonUnknownFormat,
      'expectedSize' => l.breqReasonExpectedSize,
      'suspiciousSize' => l.breqReasonSuspiciousSize,
      'seeders' => l.breqReasonSeeders(d),
      'freeleech' => l.breqReasonFreeleech,
      'likelySeveralBooks' => l.breqReasonSeveralBooks,
      _ => r.code,
    };
  }

  Widget _releaseRow(BuildContext context, BookRequestRelease r) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;
    final busy = _grabbing == r.guid;
    final facts = [
      r.indexerName,
      if (r.sizeBytes != null) formatReleaseSize(r.sizeBytes),
      if (r.seeders != null) l.breqSeeders(r.seeders!, r.leechers ?? 0),
      if (r.bitrateKbps != null) '${r.bitrateKbps} kbps',
      if (r.fileCount != null) l.breqFileCount(r.fileCount!),
      if (r.publishedAt != null) DateFormat.yMMMd().format(r.publishedAt!),
    ];
    final reasons = r.reasons.where((x) => x.points != 0).toList()
      ..sort((a, b) => b.points.abs().compareTo(a.points.abs()));

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: cs.surfaceContainerHigh, borderRadius: BorderRadius.circular(12)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(r.title, style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(facts.join(' · '), style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: 6),
          Wrap(spacing: 4, runSpacing: 4, children: [
            if (r.tierName != null) _chip(r.tierName!, Colors.green) else _chip(l.breqScore(r.score.round()), cs.primary),
            for (final f in r.formats) _chip(f.toUpperCase(), cs.onSurfaceVariant),
            if (r.language != null) _chip(r.language!.toUpperCase(), cs.onSurfaceVariant),
            if (r.freeleech) _chip(l.breqFreeleech, Colors.green),
            if (r.vipOnly) _chip(l.breqVipOnly, cs.error),
            if (r.alreadyGrabbed) _chip(l.breqAlreadyGrabbed, Colors.orange),
          ]),
          if (reasons.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              reasons
                  .take(4)
                  .map((x) => '${_reasonLabel(l, x)} ${x.points > 0 ? '+' : ''}${x.points}')
                  .join(' · '),
              style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: busy
                ? Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                      const SizedBox(width: 10),
                      Text(l.breqCheckingRelease, style: tt.bodySmall),
                    ]),
                  )
                : FilledButton.tonal(
                    onPressed: _grabbing != null ? null : () => _grab(r),
                    child: Text(l.breqGrab),
                  ),
          ),
        ]),
      ),
    );
  }
}

/// The import BookOrbit held back, and the choice to file it anyway or
/// throw it away. Pops with the action picked, or null.
Future<BookRequestAction?> showBookRequestReview(BuildContext context, ApiService api, BookRequest request) {
  return showModalBottomSheet<BookRequestAction>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => _ReviewSheet(api: api, request: request),
  );
}

class _ReviewSheet extends StatefulWidget {
  final ApiService api;
  final BookRequest request;
  const _ReviewSheet({required this.api, required this.request});

  @override
  State<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<_ReviewSheet> {
  BookRequestReview? _review;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    widget.api.bookRequestReview(widget.request.id).then((res) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _review = res.review;
        _error = res.error;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;
    final review = _review;

    String fieldLabel(String field) => switch (field) {
          'title' => l.titleLabel,
          'authors' => l.authorLabel,
          'isbn13' => l.isbnLabel,
          _ => field,
        };
    Color verdictColor(String verdict) => switch (verdict) {
          'match' => Colors.green,
          'mismatch' => cs.error,
          _ => cs.onSurfaceVariant,
        };

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      builder: (ctx, scroll) => ListView(controller: scroll, padding: const EdgeInsets.fromLTRB(20, 20, 20, 24), children: [
        Text(l.breqReviewTitle, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(widget.request.title, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
        const SizedBox(height: 16),
        if (_loading)
          const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator(strokeWidth: 2)))
        else if (review == null)
          Text(_error != null ? l.breqReviewFailedReason(_error!) : l.breqReviewFailed,
              style: tt.bodyMedium?.copyWith(color: cs.error))
        else ...[
          if (review.score != null && review.threshold != null)
            Text(l.breqReviewScore(review.score!, review.threshold!), style: tt.bodyMedium),
          if (review.rows.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (final row in review.rows)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text(fieldLabel(row.field), style: tt.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    Icon(
                      row.verdict == 'match'
                          ? Icons.check_circle_rounded
                          : row.verdict == 'mismatch'
                              ? Icons.cancel_rounded
                              : Icons.help_outline_rounded,
                      size: 16,
                      color: verdictColor(row.verdict),
                    ),
                  ]),
                  Text(l.breqReviewRequested(row.requested ?? '-'), style: tt.bodySmall),
                  Text(l.breqReviewImported(row.imported ?? '-'), style: tt.bodySmall),
                ]),
              ),
          ],
          if (review.dockEntryGone)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 8),
              child: Text(l.breqReviewDockGone, style: tt.bodySmall?.copyWith(color: cs.error)),
            ),
          if (review.files.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              review.totalSizeBytes != null
                  ? '${l.breqReviewFiles(review.files.length)} · ${formatReleaseSize(review.totalSizeBytes)}'
                  : l.breqReviewFiles(review.files.length),
              style: tt.labelLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            for (final f in review.files.take(30))
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  [f.fileName, if (f.size != null) formatReleaseSize(f.size)].join(' · '),
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ),
          ],
          if (!review.canFile)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(l.breqReviewNoLibrary, style: tt.bodySmall?.copyWith(color: cs.error)),
            ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context, BookRequestAction.discardImport),
                child: Text(l.breqDiscardImport),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                onPressed: review.canFile && !review.dockEntryGone
                    ? () => Navigator.pop(context, BookRequestAction.forceFile)
                    : null,
                child: Text(l.breqFileAnyway),
              ),
            ),
          ]),
        ],
      ]),
    );
  }
}
