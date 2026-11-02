import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/api_service.dart';
import '../services/bookorbit_match.dart';
import 'overlay_toast.dart';

typedef MatchUpdate = ({Map<String, dynamic> metadata, String? coverUrl});

/// The editor's Match tab on BookOrbit, after its web editor: every source
/// is searched at once and ranked against the book, then a result opens a
/// side by side comparison where each field is kept or taken from that
/// result or another one. Nothing changes until Apply.
class BookOrbitMatchView extends StatefulWidget {
  final ApiService api;
  final String itemId;
  final MatchCurrent current;
  final String? currentCoverUrl;
  final Map<String, String> coverHeaders;
  final bool isAudiobook;

  /// Saves the picked values; true when it worked.
  final Future<bool> Function(MatchUpdate update) onApply;

  const BookOrbitMatchView({
    super.key,
    required this.api,
    required this.itemId,
    required this.current,
    required this.onApply,
    this.currentCoverUrl,
    this.coverHeaders = const {},
    this.isAudiobook = true,
  });

  @override
  State<BookOrbitMatchView> createState() => _BookOrbitMatchViewState();
}

class _BookOrbitMatchViewState extends State<BookOrbitMatchView> with AutomaticKeepAliveClientMixin {
  late final _titleCtrl = TextEditingController(text: widget.current.title);
  late final _authorCtrl = TextEditingController(text: widget.current.authors.join(', '));
  late final _isbnCtrl = TextEditingController(text: widget.current.isbn);

  List<Map<String, String>> _providers = const [];
  final List<MatchCandidate> _results = [];
  final Map<String, String> _stopped = {};
  StreamSubscription<MatchSearchEvent>? _search;
  bool _streaming = false;
  bool _searched = false;
  String? _searchError;
  bool _showOther = false;

  MatchCandidate? _active;
  final Map<MatchField, MatchCandidate> _picks = {};
  MatchCandidate? _coverPick;
  bool _mergeGenres = true;
  bool _onlyDifferences = true;
  final Set<MatchField> _othersOpen = {};
  bool _applying = false;

  @override
  void initState() {
    super.initState();
    widget.api.bookMatchProviders().then((list) {
      if (mounted && list != null) setState(() => _providers = list);
    });
    _runSearch();
  }

  @override
  void dispose() {
    _search?.cancel();
    _titleCtrl.dispose();
    _authorCtrl.dispose();
    _isbnCtrl.dispose();
    super.dispose();
  }

  void _runSearch() {
    FocusManager.instance.primaryFocus?.unfocus();
    _search?.cancel();
    setState(() {
      _results.clear();
      _stopped.clear();
      _streaming = true;
      _searched = true;
      _searchError = null;
      _active = null;
    });
    _search = widget.api
        .searchMatches(
          widget.itemId,
          title: _titleCtrl.text,
          author: _authorCtrl.text,
          isbn: _isbnCtrl.text,
          isAudiobook: widget.isAudiobook,
        )
        .listen(
          (event) {
            if (!mounted) return;
            setState(() {
              final c = event.candidate;
              if (c != null) {
                if (!_results.any((r) => r.key == c.key)) _results.add(c);
              } else if (event.provider != null) {
                _stopped[event.provider!] = event.outcome ?? 'failed';
              }
            });
          },
          onError: (Object e) {
            debugPrint('[BookOrbit] match search failed: $e');
            if (mounted) setState(() {
              _streaming = false;
              _searchError = '$e';
            });
          },
          onDone: () {
            if (mounted) setState(() => _streaming = false);
          },
          cancelOnError: true,
        );
  }

  String _providerLabel(String key) {
    for (final p in _providers) {
      if (p['key'] == key) return p['label'] ?? key;
    }
    if (key == 'audnexus') return 'Audnexus';
    return key.isEmpty ? key : '${key[0].toUpperCase()}${key.substring(1)}';
  }

  List<String> get _providerOrder => [for (final p in _providers) p['key'] ?? ''];

  String _fieldLabel(AppLocalizations l, MatchField field) => switch (field) {
        MatchField.title => l.titleLabel,
        MatchField.subtitle => l.subtitleLabel,
        MatchField.authors => l.authorLabel,
        MatchField.narrators => l.narratorLabel,
        MatchField.series => l.seriesLabel,
        MatchField.description => l.descriptionLabel,
        MatchField.publisher => l.publisherLabel,
        MatchField.published => l.yearLabel,
        MatchField.language => l.languageLabel,
        MatchField.isbn => l.isbnLabel,
        MatchField.genres => l.genresLabel,
      };

  int get _pickCount => _picks.length + (_coverPick != null ? 1 : 0);

  Future<void> _apply() async {
    final l = AppLocalizations.of(context)!;
    setState(() => _applying = true);
    final ok = await widget.onApply(buildMatchUpdate(
      widget.current,
      _picks,
      cover: _coverPick,
      mergeGenres: _mergeGenres,
    ));
    if (!mounted) return;
    setState(() {
      _applying = false;
      if (ok) {
        _picks.clear();
        _coverPick = null;
        _active = null;
      }
    });
    showOverlayToast(context, ok ? l.editMetadataUpdatedFromMatch : l.failedToUpdateMetadata,
        icon: ok ? Icons.check_circle_outline_rounded : Icons.error_outline_rounded);
  }

  // Peeking at another tab keeps the results and picks.
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final active = _active;
    return active == null ? _buildResults(context) : _buildCompare(context, active);
  }

  // Results

  Widget _buildResults(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final ranked = rankMatches(_results, widget.current, providerOrder: _providerOrder);
    final strong = ranked.where((r) => r.assessment.tier == MatchTier.strong).toList();
    final possible = ranked.where((r) => r.assessment.tier == MatchTier.possible).toList();
    final other = ranked.where((r) => r.assessment.tier == MatchTier.weak).toList();
    final counts = <String, int>{};
    for (final r in _results) {
      counts[r.provider] = (counts[r.provider] ?? 0) + 1;
    }
    final sources = [
      ..._providerOrder.where((k) => k.isNotEmpty),
      ...counts.keys.where((k) => !_providerOrder.contains(k)),
    ];

    InputDecoration field(String label) => InputDecoration(
          labelText: label,
          isDense: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        );

    return ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 32), children: [
      TextField(controller: _titleCtrl, decoration: field(l.titleLabel), onSubmitted: (_) => _runSearch()),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(flex: 3, child: TextField(controller: _authorCtrl, decoration: field(l.authorLabel), onSubmitted: (_) => _runSearch())),
        const SizedBox(width: 8),
        Expanded(flex: 2, child: TextField(controller: _isbnCtrl, decoration: field(l.isbnLabel), onSubmitted: (_) => _runSearch())),
      ]),
      const SizedBox(height: 10),
      SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: _runSearch,
          icon: _streaming
              ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: cs.onPrimary))
              : const Icon(Icons.travel_explore_rounded, size: 18),
          label: Text(_streaming ? l.bomatchSearching : l.bomatchSearchAll),
        ),
      ),
      if (sources.isNotEmpty) ...[
        const SizedBox(height: 10),
        Wrap(spacing: 6, runSpacing: 6, children: [
          for (final key in sources) _sourceChip(context, key, counts[key] ?? 0),
        ]),
      ],
      const SizedBox(height: 12),
      if (_searchError != null)
        Text(l.bomatchSearchFailed, style: tt.bodySmall?.copyWith(color: cs.error))
      else if (_searched && !_streaming && _results.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Center(child: Text(l.bomatchNoResults, style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant))),
        ),
      if (strong.isNotEmpty) ...[
        _sectionTitle(context, l.bomatchStrong),
        for (final r in strong) _resultRow(context, r.candidate, r.assessment),
      ],
      if (possible.isNotEmpty) ...[
        _sectionTitle(context, l.bomatchPossible),
        for (final r in possible) _resultRow(context, r.candidate, r.assessment),
      ],
      if (other.isNotEmpty) ...[
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => setState(() => _showOther = !_showOther),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(children: [
              Text(l.bomatchOther(other.length),
                  style: tt.labelLarge?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w600)),
              const SizedBox(width: 4),
              Icon(_showOther ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                  size: 18, color: cs.onSurfaceVariant),
            ]),
          ),
        ),
        if (_showOther)
          for (final r in other) _resultRow(context, r.candidate, r.assessment),
      ],
    ]);
  }

  Widget _sourceChip(BuildContext context, String key, int count) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final stopped = _stopped[key];
    final text = stopped != null
        ? '${_providerLabel(key)} · ${switch (stopped) {
            'timeout' => l.bomatchSourceTimeout,
            'throttled' => l.bomatchSourceBusy,
            _ => l.bomatchSourceFailed,
          }}'
        : '${_providerLabel(key)} · $count';
    final color = stopped != null ? cs.error : count > 0 ? cs.primary : cs.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (_streaming && stopped == null && count == 0)
          Padding(
            padding: const EdgeInsets.only(right: 5),
            child: SizedBox(width: 10, height: 10, child: CircularProgressIndicator(strokeWidth: 1.5, color: color)),
          ),
        Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
      ]),
    );
  }

  Widget _sectionTitle(BuildContext context, String text) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 6),
      child: Text(text, style: tt.labelLarge?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w600)),
    );
  }

  Widget _cover(String url, {double width = 48, Map<String, String>? headers}) {
    final cs = Theme.of(context).colorScheme;
    final box = Container(
      width: width,
      height: width * 1.4,
      color: cs.surfaceContainerHigh,
      child: Icon(Icons.image_not_supported_outlined, size: width * 0.4, color: cs.onSurfaceVariant),
    );
    if (url.isEmpty) return ClipRRect(borderRadius: BorderRadius.circular(6), child: box);
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: CachedNetworkImage(
        imageUrl: url,
        // Results point at the sources' own servers, which must not get the
        // account's token.
        httpHeaders: headers,
        width: width,
        height: width * 1.4,
        fit: BoxFit.cover,
        placeholder: (_, __) => box,
        errorWidget: (_, __, ___) => box,
      ),
    );
  }

  Widget _resultRow(BuildContext context, MatchCandidate c, MatchAssessment a) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final summary = summarizeDifferences(widget.current, c);
    final line = [
      if (c.authors.isNotEmpty) c.authors.join(', '),
      if (c.year.isNotEmpty) c.year,
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => setState(() {
            _active = c;
            _othersOpen.clear();
          }),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _cover(c.coverUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(c.title.isEmpty ? '-' : c.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                  if (line.isNotEmpty)
                    Text(line, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                  const SizedBox(height: 6),
                  Wrap(spacing: 4, runSpacing: 4, children: [
                    _tag(_providerLabel(c.provider), cs.primary),
                    if (a.linked) _tag(l.bomatchLinked, Colors.green),
                    if (a.isbnMatch) _tag(l.bomatchSameIsbn, Colors.green),
                    if (a.sparse) _tag(l.bomatchFewDetails, cs.onSurfaceVariant),
                    if (summary.changes > 0) _tag(l.bomatchChanged(summary.changes), Colors.orange),
                    if (summary.fills > 0) _tag(l.bomatchNew(summary.fills), Colors.green),
                  ]),
                ]),
              ),
              Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _tag(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
        child: Text(text, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: color)),
      );

  // Compare

  /// Likely matches only: other books' values would be noise beside this one's.
  List<MatchCandidate> get _alternatives => [
        for (final r in rankMatches(_results, widget.current, providerOrder: _providerOrder))
          if (r.assessment.tier != MatchTier.weak) r.candidate,
      ];

  Widget _buildCompare(BuildContext context, MatchCandidate active) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final alternatives = _alternatives;
    final fields = [
      for (final f in MatchField.values)
        if (_showField(f, active, alternatives)) f,
    ];
    final actionable = [
      for (final f in MatchField.values)
        if (isActionable(classifyField(widget.current, active, f))) f,
    ];
    return Column(children: [
      Expanded(
        child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 16), children: [
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => setState(() => _active = null),
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: Text(l.bomatchBack),
            ),
          ),
          Text(active.title, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          Text([_providerLabel(active.provider), if (active.year.isNotEmpty) active.year].join(' · '),
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: 12),
          _coverRow(context, active, alternatives),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
            OutlinedButton(
              onPressed: () => setState(() {
                for (final f in actionable) {
                  // A value already picked from another result stays.
                  if (classifyField(widget.current, active, f) == DiffKind.fill) _picks.putIfAbsent(f, () => active);
                }
              }),
              child: Text(l.bomatchFillEmpty),
            ),
            OutlinedButton(
              onPressed: () => setState(() {
                for (final f in actionable) {
                  _picks[f] = active;
                }
                if (active.coverUrl.isNotEmpty) _coverPick = active;
              }),
              child: Text(l.bomatchTakeAll),
            ),
            FilterChip(
              label: Text(l.bomatchOnlyDifferences),
              selected: _onlyDifferences,
              onSelected: (v) => setState(() => _onlyDifferences = v),
            ),
          ]),
          const SizedBox(height: 8),
          for (final f in fields) _fieldCard(context, active, f, alternatives),
        ]),
      ),
      SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _pickCount == 0 || _applying ? null : _apply,
              child: _applying
                  ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: cs.onPrimary))
                  : Text(l.bomatchApply(_pickCount)),
            ),
          ),
        ),
      ),
    ]);
  }

  bool _showField(MatchField f, MatchCandidate active, List<MatchCandidate> alternatives) {
    final kind = classifyField(widget.current, active, f);
    if (_picks.containsKey(f)) return true;
    if (_onlyDifferences) return isActionable(kind);
    return kind != DiffKind.missing ||
        currentValue(widget.current, f).isNotEmpty ||
        otherValues(f, active, alternatives).isNotEmpty;
  }

  Widget _coverRow(BuildContext context, MatchCandidate active, List<MatchCandidate> alternatives) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final picked = _coverPick;
    final others = [
      for (final c in alternatives)
        if (c.key != active.key && c.coverUrl.isNotEmpty && c.coverUrl != active.coverUrl) c,
    ];
    Widget labelled(Widget child, String label, {bool chosen = false}) => Column(children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: chosen ? cs.primary : Colors.transparent, width: 2),
            ),
            child: child,
          ),
          const SizedBox(height: 4),
          Text(label, style: tt.labelSmall?.copyWith(color: chosen ? cs.primary : cs.onSurfaceVariant)),
        ]);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: cs.surfaceContainerHigh, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(l.metadataLookupCover, style: tt.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            GestureDetector(
              onTap: () => setState(() => _coverPick = null),
              child: labelled(_cover(widget.currentCoverUrl ?? '', width: 72, headers: widget.coverHeaders),
                  l.bomatchNow, chosen: picked == null),
            ),
            if (active.coverUrl.isNotEmpty) ...[
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => setState(() => _coverPick = active),
                child: labelled(_cover(active.coverUrl, width: 72), _providerLabel(active.provider),
                    chosen: picked?.key == active.key),
              ),
            ],
            for (final c in others) ...[
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => setState(() => _coverPick = c),
                child: labelled(_cover(c.coverUrl, width: 72), _providerLabel(c.provider),
                    chosen: picked?.key == c.key),
              ),
            ],
          ]),
        ),
      ]),
    );
  }

  Widget _fieldCard(BuildContext context, MatchCandidate active, MatchField f, List<MatchCandidate> alternatives) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final kind = classifyField(widget.current, active, f);
    final picked = _picks[f];
    final fromOther = picked != null && picked.key != active.key;
    final now = currentValue(widget.current, f);
    final incoming = candidateValue(picked ?? active, f);
    final others = otherValues(f, active, alternatives);
    final (kindLabel, kindColor) = switch (kind) {
      DiffKind.fill => (l.bomatchKindNew, Colors.green),
      DiffKind.change => (l.bomatchKindChange, Colors.orange),
      DiffKind.minor => (l.bomatchKindSmall, cs.onSurfaceVariant),
      DiffKind.same => (l.bomatchKindSame, cs.onSurfaceVariant),
      DiffKind.missing => (l.bomatchKindNone, cs.onSurfaceVariant),
    };
    final maxLines = f == MatchField.description ? 6 : 3;
    final decision = picked == null
        ? 'keep'
        : f == MatchField.genres
            ? (_mergeGenres ? 'merge' : 'replace')
            : 'use';
    final canUse = kind != DiffKind.missing || fromOther;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: picked != null ? cs.primary.withValues(alpha: 0.5) : Colors.transparent),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(_fieldLabel(l, f), style: tt.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(width: 6),
          _tag(kindLabel, kindColor),
          if (fromOther) ...[
            const SizedBox(width: 4),
            _tag(l.bomatchFrom(_providerLabel(picked.provider)), cs.primary),
          ],
        ]),
        const SizedBox(height: 6),
        Text(l.bomatchNow, style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
        Text(now.isEmpty ? l.bomatchEmpty : now, maxLines: maxLines, overflow: TextOverflow.ellipsis,
            style: tt.bodySmall?.copyWith(
              color: now.isEmpty ? cs.onSurfaceVariant : cs.onSurface,
              fontStyle: now.isEmpty ? FontStyle.italic : null,
              decoration: picked != null && f != MatchField.genres ? TextDecoration.lineThrough : null,
            )),
        const SizedBox(height: 6),
        Text(_providerLabel((picked ?? active).provider), style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
        Text(incoming.isEmpty ? l.bomatchEmpty : incoming, maxLines: maxLines, overflow: TextOverflow.ellipsis,
            style: tt.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
        if (canUse) ...[
          const SizedBox(height: 8),
          SegmentedButton<String>(
            showSelectedIcon: false,
            style: const ButtonStyle(visualDensity: VisualDensity.compact),
            segments: [
              ButtonSegment(value: 'keep', label: Text(l.bomatchKeep)),
              if (f == MatchField.genres) ...[
                ButtonSegment(value: 'merge', label: Text(l.bomatchMerge)),
                ButtonSegment(value: 'replace', label: Text(l.bomatchReplace)),
              ] else
                ButtonSegment(value: 'use', label: Text(l.bomatchUse)),
            ],
            selected: {decision},
            onSelectionChanged: (s) => setState(() {
              final next = s.first;
              if (next == 'keep') {
                _picks.remove(f);
              } else {
                _picks[f] = picked ?? active;
                if (f == MatchField.genres) _mergeGenres = next == 'merge';
              }
            }),
          ),
        ],
        if (others.isNotEmpty) ...[
          const SizedBox(height: 4),
          TextButton(
            style: TextButton.styleFrom(padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
            onPressed: () => setState(() {
              if (!_othersOpen.add(f)) _othersOpen.remove(f);
            }),
            child: Text(l.bomatchOtherSources(others.length)),
          ),
          if (_othersOpen.contains(f))
            for (final o in others)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(o.from.map((c) => _providerLabel(c.provider)).toSet().join(', '),
                          style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
                      Text(o.value, maxLines: maxLines, overflow: TextOverflow.ellipsis, style: tt.bodySmall),
                    ]),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _picks[f] = o.from.first),
                    child: Text(o.from.any((c) => c.key == picked?.key) ? l.bomatchChosen : l.bomatchUseThis),
                  ),
                ]),
              ),
        ],
      ]),
    );
  }
}
