import 'dart:async';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/book_requests.dart';
import '../services/bookorbit_match.dart';
import '../widgets/absorb_page_header.dart';
import '../widgets/book_detail_sheet.dart';
import '../widgets/overlay_toast.dart';
import 'book_request_release_screen.dart';

/// BookOrbit book requests: ask for a book the library doesn't have, follow
/// your requests, and (for managers) approve or reject everyone's. Picking a
/// release by hand stays on BookOrbit's web.
class BookRequestsScreen extends StatefulWidget {
  final String initialQuery;

  /// Open on My requests instead of the search.
  final bool openList;

  const BookRequestsScreen({super.key, this.initialQuery = '', this.openList = false});

  static Future<void> open(BuildContext context, {String query = '', bool openList = false}) =>
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => BookRequestsScreen(initialQuery: query, openList: openList)),
      );

  @override
  State<BookRequestsScreen> createState() => _BookRequestsScreenState();
}

typedef BookRequestLibrary = ({int id, String name});

/// What a request sheet needs: who may ask, the libraries a request can land
/// in, and the server's default library for each kind.
typedef BookRequestSetup = ({
  BookRequestAccess access,
  List<BookRequestLibrary> libraries,
  Map<String, int> defaults,
});

Future<BookRequestSetup> loadBookRequestSetup(ApiService api) async {
  final results = await Future.wait([
    api.bookRequestAccess(),
    api.getLibraries(),
    api.bookRequestDefaultLibraries(),
  ]);
  return (
    access: results[0] as BookRequestAccess,
    libraries: [
      for (final lib in (results[1] as List<dynamic>).whereType<Map>())
        if (int.tryParse('${lib['id']}') != null)
          (id: int.parse('${lib['id']}'), name: '${lib['name'] ?? ''}'),
    ],
    defaults: results[2] as Map<String, int>,
  );
}

class _BookRequestsScreenState extends State<BookRequestsScreen> with TickerProviderStateMixin {
  BookRequestAccess? _access;
  TabController? _tabs;
  List<BookRequestLibrary> _libraries = const [];
  Map<String, int> _defaults = const {};
  final _mine = GlobalKey<_RequestListState>();
  final _all = GlobalKey<_RequestListState>();

  ApiService? get _api => context.read<AuthProvider>().apiService;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final api = _api;
    if (api == null) {
      setState(() => _access = BookRequestAccess.none);
      return;
    }
    final setup = await loadBookRequestSetup(api);
    if (!mounted) return;
    final access = setup.access;
    setState(() {
      _access = access;
      _libraries = setup.libraries;
      _defaults = setup.defaults;
      if (access.canRequest) {
        _tabs = TabController(
          length: access.canManage ? 3 : 2,
          vsync: this,
          initialIndex: widget.openList ? 1 : 0,
        );
      }
    });
  }

  @override
  void dispose() {
    _tabs?.dispose();
    super.dispose();
  }

  void _changed() {
    _mine.currentState?.reload(quiet: true);
    _all.currentState?.reload(quiet: true);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;
    final access = _access;
    final tabs = _tabs;
    final api = _api;

    Widget body;
    if (access == null) {
      body = const Center(child: CircularProgressIndicator(strokeWidth: 2));
    } else if (!access.canRequest || tabs == null || api == null) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(l.breqNoAccess,
              textAlign: TextAlign.center, style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
        ),
      );
    } else {
      final shared = (libraries: _libraries, defaults: _defaults);
      body = Column(children: [
        TabBar(
          controller: tabs,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: cs.primary,
          unselectedLabelColor: cs.onSurfaceVariant,
          indicatorColor: cs.primary,
          tabs: [
            Tab(text: l.breqTabRequest),
            Tab(text: l.breqTabMine),
            if (access.canManage) Tab(text: l.breqTabAll),
          ],
        ),
        Expanded(
          child: TabBarView(controller: tabs, children: [
            _RequestSearch(
              api: api,
              access: access,
              libraries: shared.libraries,
              defaults: shared.defaults,
              initialQuery: widget.initialQuery,
              onRequested: _changed,
            ),
            _RequestList(
              key: _mine,
              api: api,
              access: access,
              all: false,
              libraries: shared.libraries,
              defaults: shared.defaults,
              onChanged: () => _all.currentState?.reload(quiet: true),
            ),
            if (access.canManage)
              _RequestList(
                key: _all,
                api: api,
                access: access,
                all: true,
                libraries: shared.libraries,
                defaults: shared.defaults,
                onChanged: () => _mine.currentState?.reload(quiet: true),
              ),
          ]),
        ),
      ]);
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 8, 0),
            child: Row(children: [
              Expanded(child: AbsorbPageHeader(title: l.breqTitle, padding: EdgeInsets.zero)),
              IconButton(
                icon: Icon(Icons.close_rounded, color: cs.onSurfaceVariant),
                onPressed: () => Navigator.pop(context),
              ),
            ]),
          ),
          const SizedBox(height: 4),
          Expanded(child: body),
        ]),
      ),
    );
  }
}

Widget _cover(BuildContext context, String? url, {double width = 48}) {
  final cs = Theme.of(context).colorScheme;
  final box = Container(
    width: width,
    height: width * 1.45,
    color: cs.surfaceContainerHighest,
    child: Icon(Icons.menu_book_rounded, size: width * 0.4, color: cs.onSurfaceVariant),
  );
  return ClipRRect(
    borderRadius: BorderRadius.circular(6),
    child: url == null || url.isEmpty
        ? box
        // Covers come from the sources' own servers, so no account headers.
        : CachedNetworkImage(
            imageUrl: url,
            width: width,
            height: width * 1.45,
            fit: BoxFit.cover,
            placeholder: (_, __) => box,
            errorWidget: (_, __, ___) => box,
          ),
  );
}

Widget _tag(String text, Color color) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.13), borderRadius: BorderRadius.circular(6)),
      child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );

String _kindLabel(AppLocalizations l, String kind) => switch (kind) {
      'ebook' => l.breqKindEbook,
      'comic' => l.breqKindComic,
      'both' => l.breqKindBoth,
      _ => l.breqKindAudiobook,
    };

/// Library choices for a request of [kind]: null stands for "whatever the
/// server picks", offered only when it has a default or someone else decides.
Widget _libraryPicker({
  required BuildContext context,
  String? label,
  required List<BookRequestLibrary> libraries,
  required int? defaultId,
  required int? value,
  required bool allowNone,
  required ValueChanged<int?> onChanged,
}) {
  final l = AppLocalizations.of(context)!;
  String? defaultName;
  for (final lib in libraries) {
    if (lib.id == defaultId) defaultName = lib.name;
  }
  return DropdownButtonFormField<int?>(
    initialValue: value,
    isExpanded: true,
    decoration: InputDecoration(
      labelText: label ?? l.breqLibrary,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      isDense: true,
    ),
    hint: Text(l.breqLibraryChoose),
    items: [
      if (allowNone || defaultName != null)
        DropdownMenuItem<int?>(
          value: null,
          child: Text(defaultName != null ? l.breqLibraryDefault(defaultName) : l.breqLibraryApprover),
        ),
      for (final lib in libraries) DropdownMenuItem<int?>(value: lib.id, child: Text(lib.name)),
    ],
    onChanged: onChanged,
  );
}

/// Confirms a request for one or more [kinds]: the library each lands in when
/// that's up to the user, and a note for whoever approves it. Null when
/// dismissed.
Future<({Map<String, int?> libraries, String note})?> showBookRequestSheet(
  BuildContext context, {
  required String title,
  List<String> authors = const [],
  String? coverUrl,
  required List<String> kinds,
  required BookRequestSetup setup,
}) {
  final l = AppLocalizations.of(context)!;
  final access = setup.access;
  // An approved request needs a library, so with nobody to approve and no
  // default the user picks one.
  bool mustPick(String kind, int? picked) => access.autoApprove && setup.defaults[kind] == null && picked == null;
  final showLibrary = access.autoApprove || setup.libraries.length > 1;
  final noteCtrl = TextEditingController();
  final libraries = <String, int?>{for (final k in kinds) k: null};
  final pair = kinds.length > 1;
  return showModalBottomSheet<({Map<String, int?> libraries, String note})>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheet) {
        final cs = Theme.of(ctx).colorScheme;
        final tt = Theme.of(ctx).textTheme;
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + MediaQuery.of(ctx).viewInsets.bottom),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _cover(ctx, coverUrl, width: 56),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  if (authors.isNotEmpty)
                    Text(authors.join(', '), style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                  const SizedBox(height: 6),
                  _tag(_kindLabel(l, pair ? 'both' : kinds.single), cs.primary),
                ]),
              ),
            ]),
            const SizedBox(height: 18),
            if (showLibrary)
              for (final k in kinds) ...[
                _libraryPicker(
                  context: ctx,
                  label: !pair
                      ? null
                      : k == 'ebook'
                          ? l.breqEbookLibrary
                          : l.breqAudiobookLibrary,
                  libraries: setup.libraries,
                  defaultId: setup.defaults[k],
                  value: libraries[k],
                  allowNone: !access.autoApprove,
                  onChanged: (v) => setSheet(() => libraries[k] = v),
                ),
                const SizedBox(height: 12),
              ],
            if (access.autoApprove)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(l.breqAutoApproved, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
              )
            else ...[
              TextField(
                controller: noteCtrl,
                maxLength: 2000,
                minLines: 1,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: l.breqNote,
                  hintText: l.breqNoteHint,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 4),
            ],
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: kinds.any((k) => mustPick(k, libraries[k]))
                    ? null
                    : () => Navigator.pop(ctx, (libraries: Map.of(libraries), note: noteCtrl.text)),
                child: Text(pair ? l.breqRequestBoth : l.breqRequest),
              ),
            ),
          ]),
        );
      },
    ),
  ).whenComplete(() => WidgetsBinding.instance.addPostFrameCallback((_) => noteCtrl.dispose()));
}

class _RequestSearch extends StatefulWidget {
  final ApiService api;
  final BookRequestAccess access;
  final List<BookRequestLibrary> libraries;
  final Map<String, int> defaults;
  final String initialQuery;
  final VoidCallback onRequested;

  const _RequestSearch({
    required this.api,
    required this.access,
    required this.libraries,
    required this.defaults,
    required this.initialQuery,
    required this.onRequested,
  });

  @override
  State<_RequestSearch> createState() => _RequestSearchState();
}

class _RequestSearchState extends State<_RequestSearch> with AutomaticKeepAliveClientMixin {
  late final _titleCtrl = TextEditingController(text: widget.initialQuery);
  final _authorCtrl = TextEditingController();
  String _kind = 'audiobook';
  List<Map<String, String>> _providers = const [];

  final List<MatchCandidate> _results = [];
  final Map<String, BookRequestAvailability?> _availability = {};
  final Set<String> _asked = {};
  StreamSubscription<MatchSearchEvent>? _search;
  Timer? _annotate;
  int _generation = 0;
  bool _streaming = false;
  bool _searched = false;
  bool _failed = false;
  final Set<String> _busy = {};

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    widget.api.bookMatchProviders().then((list) {
      if (mounted && list != null) setState(() => _providers = list);
    });
    if (widget.initialQuery.trim().isNotEmpty) _runSearch();
  }

  @override
  void dispose() {
    _search?.cancel();
    _annotate?.cancel();
    _titleCtrl.dispose();
    _authorCtrl.dispose();
    super.dispose();
  }

  String _providerLabel(String key) {
    for (final p in _providers) {
      if (p['key'] == key) return p['label'] ?? key;
    }
    return key.isEmpty ? key : '${key[0].toUpperCase()}${key.substring(1)}';
  }

  void _runSearch() {
    FocusManager.instance.primaryFocus?.unfocus();
    final title = _titleCtrl.text.trim();
    final author = _authorCtrl.text.trim();
    if (title.isEmpty && author.isEmpty) return;
    _search?.cancel();
    _annotate?.cancel();
    final generation = ++_generation;
    setState(() {
      _results.clear();
      _availability.clear();
      _asked.clear();
      _streaming = true;
      _searched = true;
      _failed = false;
    });
    _search = widget.api
        .searchMatches(
          '',
          title: title,
          author: author,
          mediaKind: _kind == 'both' ? null : _kind,
          mediaKinds: _kind == 'both' ? _halves : null,
        )
        .listen(
          (event) {
            final c = event.candidate;
            if (!mounted || generation != _generation || c == null) return;
            if (_results.any((r) => r.key == c.key)) return;
            setState(() => _results.add(c));
            _annotate?.cancel();
            _annotate = Timer(const Duration(milliseconds: 400), () => _annotateNow(generation));
          },
          onError: (Object e) {
            debugPrint('[BookOrbit] request search failed: $e');
            if (mounted && generation == _generation) {
              setState(() {
                _streaming = false;
                _failed = true;
              });
            }
          },
          onDone: () {
            if (!mounted || generation != _generation) return;
            setState(() => _streaming = false);
            _annotate?.cancel();
            _annotateNow(generation);
          },
          cancelOnError: true,
        );
  }

  /// Asks the server which results are already owned or requested.
  Future<void> _annotateNow(int generation) async {
    final pending = [
      for (final r in _results)
        if (r.title.isNotEmpty && _asked.add(r.key)) r,
    ];
    if (pending.isEmpty) return;
    final kinds = _halves;
    // One answer per format: a book can be owned as an e-book and still be
    // missing as an audiobook.
    final answers = await Future.wait([
      for (final k in kinds) widget.api.bookRequestAvailability(pending, k),
    ]);
    if (!mounted || generation != _generation) return;
    setState(() {
      for (var k = 0; k < kinds.length; k++) {
        for (var i = 0; i < pending.length; i++) {
          _availability['${kinds[k]}|${pending[i].key}'] = i < answers[k].length ? answers[k][i] : null;
        }
      }
    });
  }

  /// The formats a search covers: two when asking for both.
  List<String> get _halves => _kind == 'both' ? const ['ebook', 'audiobook'] : [_kind];

  BookRequestAvailability? _availabilityOf(BookRequestWork work, String kind) =>
      BookRequestAvailability.merge(work.records.map((r) => _availability['$kind|${r.key}']));

  void _markRequested(BookRequestWork work, String kind, BookRequest? request) {
    if (request == null) return;
    final mark = BookRequestAvailability(
      ownedBookId: request.status == 'available' ? request.matchedBookId : null,
      existingRequestId: request.id,
      existingRequestStatus: request.status,
      alreadySubscribed: true,
    );
    for (final r in work.records) {
      _availability['$kind|${r.key}'] = mark;
    }
  }

  /// Asks for one format. [targetBookId] files it into a book that already
  /// has the other format.
  Future<void> _request(BookRequestWork work, String kind, {required bool join, int? targetBookId}) async {
    int? libraryId;
    String? note;
    if (!join) {
      final choice = await _confirm(work, [kind]);
      if (choice == null || !mounted) return;
      libraryId = choice.libraries[kind];
      note = choice.note;
    }
    final l = AppLocalizations.of(context)!;
    final generation = _generation;
    setState(() => _busy.add(work.key));
    final result = await widget.api.submitBookRequest(bookRequestPayload(
      work,
      kind,
      providerLabel: _providerLabel,
      note: note,
      libraryId: libraryId,
      targetBookId: targetBookId,
    ));
    if (!mounted) return;
    setState(() {
      _busy.remove(work.key);
      if (generation == _generation) _markRequested(work, kind, result.request);
    });
    if (result.ok) {
      widget.onRequested();
      showOverlayToast(
        context,
        result.subscribed
            ? l.breqJoined
            : targetBookId != null
                ? l.breqJoinsOwned
                : l.breqSubmitted,
        icon: Icons.check_circle_outline_rounded,
      );
    } else {
      showOverlayToast(context, result.error != null ? l.breqFailedReason(result.error!) : l.breqFailed,
          icon: Icons.error_outline_rounded);
    }
  }

  /// [join] adds the user to existing requests for both, which have their
  /// libraries already, so there is nothing to choose.
  Future<void> _requestPair(BookRequestWork work, {bool join = false}) async {
    final choice = join
        ? (libraries: const <String, int?>{}, note: '')
        : await _confirm(work, const ['ebook', 'audiobook']);
    if (choice == null || !mounted) return;
    final l = AppLocalizations.of(context)!;
    final generation = _generation;
    setState(() => _busy.add(work.key));
    final result = await widget.api.submitBookRequestPair(bookRequestPairPayload(
      work,
      providerLabel: _providerLabel,
      note: choice.note,
      ebookLibraryId: choice.libraries['ebook'],
      audiobookLibraryId: choice.libraries['audiobook'],
    ));
    if (!mounted) return;
    setState(() {
      _busy.remove(work.key);
      if (generation == _generation) {
        _markRequested(work, 'ebook', result.ebook.request);
        _markRequested(work, 'audiobook', result.audiobook.request);
      }
    });
    if (result.ok) {
      widget.onRequested();
      final joined = [result.ebook.subscribed, result.audiobook.subscribed].where((s) => s).length;
      showOverlayToast(
        context,
        joined == 2
            ? l.breqJoinedBoth
            : joined == 1
                ? l.breqPairOneJoined
                : l.breqPairSubmitted,
        icon: Icons.check_circle_outline_rounded,
      );
    } else {
      showOverlayToast(context, result.error != null ? l.breqFailedReason(result.error!) : l.breqFailed,
          icon: Icons.error_outline_rounded);
    }
  }

  Future<({Map<String, int?> libraries, String note})?> _confirm(BookRequestWork work, List<String> kinds) =>
      showBookRequestSheet(
        context,
        title: work.title,
        authors: work.authors,
        coverUrl: work.coverUrl,
        kinds: kinds,
        setup: (access: widget.access, libraries: widget.libraries, defaults: widget.defaults),
      );

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final works = groupRequestResults(_results, _kind);

    InputDecoration field(String label) => InputDecoration(
          labelText: label,
          isDense: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        );

    return ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 32), children: [
      TextField(
        controller: _titleCtrl,
        decoration: field(l.breqTitleHint),
        textInputAction: TextInputAction.search,
        onSubmitted: (_) => _runSearch(),
      ),
      const SizedBox(height: 8),
      TextField(
        controller: _authorCtrl,
        decoration: field(l.breqAuthorHint),
        textInputAction: TextInputAction.search,
        onSubmitted: (_) => _runSearch(),
      ),
      const SizedBox(height: 10),
      SegmentedButton<String>(
        showSelectedIcon: false,
        segments: [
          for (final k in widget.access.mediaKinds) ButtonSegment(value: k, label: Text(_kindLabel(l, k))),
        ],
        selected: {_kind},
        onSelectionChanged: (s) {
          setState(() => _kind = s.first);
          // Ownership and earlier requests are per kind.
          if (_searched) _runSearch();
        },
      ),
      const SizedBox(height: 10),
      SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: _runSearch,
          icon: _streaming
              ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: cs.onPrimary))
              : const Icon(Icons.search_rounded, size: 18),
          label: Text(_streaming ? l.breqSearching : l.breqSearch),
        ),
      ),
      const SizedBox(height: 16),
      if (_failed)
        Text(l.breqSearchFailed, style: tt.bodySmall?.copyWith(color: cs.error))
      else if (!_searched)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Text(l.breqSearchPrompt,
              textAlign: TextAlign.center, style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
        )
      else if (!_streaming && works.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Text(l.breqNoResults,
              textAlign: TextAlign.center, style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
        ),
      for (final work in works) _workRow(context, work),
    ]);
  }

  /// A format's state as a tag, or null while nothing is known about it.
  Widget? _availabilityTag(AppLocalizations l, ColorScheme cs, BookRequestAvailability? a, {String? kind}) {
    if (a == null) return null;
    String label(String text) => kind == null ? text : '${_kindLabel(l, kind)} · $text';
    if (a.ownedBookId != null) return _tag(label(l.breqInLibrary), Colors.green);
    if (a.alreadySubscribed) return _tag(label(l.breqYouAsked), cs.primary);
    if (a.existingRequestId != null) return _tag(label(kind == null ? l.breqSomeoneAsked : l.breqRequested), Colors.orange);
    return null;
  }

  Widget _singleAction(AppLocalizations l, BookRequestWork work, BookRequestAvailability? a) {
    if (a?.ownedBookId != null) {
      return TextButton(
        onPressed: () => showBookDetailSheet(context, '${a!.ownedBookId}'),
        child: Text(l.breqView),
      );
    }
    if (a?.alreadySubscribed == true) return FilledButton.tonal(onPressed: null, child: Text(l.breqRequested));
    if (a?.existingRequestId != null) {
      return FilledButton.tonal(
        onPressed: () => _request(work, _kind, join: true),
        child: Text(l.breqAddMeToo),
      );
    }
    return FilledButton(
      onPressed: () => _request(work, _kind, join: false),
      child: Text(l.breqRequest),
    );
  }

  /// Both formats at once when both are open; just the missing one when the
  /// other is owned (it joins that book) or already asked for by this user.
  Widget _pairAction(AppLocalizations l, BookRequestWork work, BookRequestAvailability? e, BookRequestAvailability? a) {
    bool open(BookRequestAvailability? x) => x?.ownedBookId == null && x?.alreadySubscribed != true;
    final eOpen = open(e);
    final aOpen = open(a);
    if (!eOpen && !aOpen) {
      final owned = a?.ownedBookId ?? e?.ownedBookId;
      if (e?.ownedBookId != null && a?.ownedBookId != null && owned != null) {
        return TextButton(onPressed: () => showBookDetailSheet(context, '$owned'), child: Text(l.breqView));
      }
      return FilledButton.tonal(onPressed: null, child: Text(l.breqRequested));
    }
    if (eOpen && aOpen) {
      final joinBoth = e?.existingRequestId != null && a?.existingRequestId != null;
      return FilledButton(
        onPressed: () => _requestPair(work, join: joinBoth),
        child: Text(joinBoth ? l.breqAddMeToBoth : l.breqRequestBoth),
      );
    }
    final kind = eOpen ? 'ebook' : 'audiobook';
    final half = eOpen ? e : a;
    final other = eOpen ? a : e;
    final join = half?.existingRequestId != null;
    final label = join
        ? (kind == 'ebook' ? l.breqAddMeEbook : l.breqAddMeAudiobook)
        : (kind == 'ebook' ? l.breqRequestEbook : l.breqRequestAudiobook);
    return FilledButton(
      onPressed: () => _request(work, kind, join: join, targetBookId: other?.ownedBookId),
      child: Text(label),
    );
  }

  Widget _workRow(BuildContext context, BookRequestWork work) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final busy = _busy.contains(work.key);
    final pair = _kind == 'both';
    final line = [
      if (work.authors.isNotEmpty) work.authors.join(', '),
      if (work.year != null) '${work.year}',
    ].join(' · ');

    final List<Widget> tags;
    final Widget action;
    if (pair) {
      final e = _availabilityOf(work, 'ebook');
      final a = _availabilityOf(work, 'audiobook');
      tags = [
        ?_availabilityTag(l, cs, e, kind: 'ebook'),
        ?_availabilityTag(l, cs, a, kind: 'audiobook'),
      ];
      action = _pairAction(l, work, e, a);
    } else {
      final a = _availabilityOf(work, _kind);
      tags = [?_availabilityTag(l, cs, a)];
      action = _singleAction(l, work, a);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: cs.surfaceContainerHigh, borderRadius: BorderRadius.circular(12)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _cover(context, work.coverUrl),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(work.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                if (line.isNotEmpty)
                  Text(line, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                Text(work.providers.map(_providerLabel).join(', '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant.withValues(alpha: 0.8))),
                if (tags.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(spacing: 4, runSpacing: 4, children: tags),
                ],
              ]),
            ),
          ]),
          const SizedBox(height: 6),
          busy
              ? const Padding(
                  padding: EdgeInsets.all(8),
                  child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)),
                )
              : action,
        ]),
      ),
    );
  }
}

class _RequestList extends StatefulWidget {
  final ApiService api;
  final BookRequestAccess access;
  final bool all;
  final List<BookRequestLibrary> libraries;
  final Map<String, int> defaults;
  final VoidCallback onChanged;

  const _RequestList({
    super.key,
    required this.api,
    required this.access,
    required this.all,
    required this.libraries,
    required this.defaults,
    required this.onChanged,
  });

  @override
  State<_RequestList> createState() => _RequestListState();
}

class _RequestListState extends State<_RequestList> with AutomaticKeepAliveClientMixin {
  static const _pageSize = 25;

  List<BookRequest> _items = [];
  int _total = 0;
  int _pages = 1;
  bool _loading = true;
  bool _failed = false;
  bool _loadingMore = false;
  bool _showHidden = false;
  Timer? _poll;
  int _generation = 0;
  final Set<int> _busy = {};

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    reload();
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  String? get _myId => context.read<AuthProvider>().userId;

  /// Fetches again. [quiet] keeps what's on screen until the answer is in.
  Future<void> reload({bool quiet = false}) async {
    final generation = ++_generation;
    if (!quiet) {
      setState(() {
        _loading = true;
        _failed = false;
      });
    }
    // A quiet refresh covers everything already loaded, in one go.
    final limit = quiet ? math.min(100, math.max(_pageSize, _items.length)) : _pageSize;
    final page = await widget.api.bookRequests(
      all: widget.all,
      limit: limit,
      includeDismissed: _showHidden,
    );
    if (!mounted || generation != _generation) return;
    setState(() {
      _loading = false;
      if (page == null) {
        if (!quiet) _failed = true;
      } else {
        _items = page.items;
        _total = page.total;
        _pages = (page.items.length / _pageSize).ceil().clamp(1, 1 << 20);
      }
    });
    _schedulePoll();
  }

  Future<void> _loadMore() async {
    setState(() => _loadingMore = true);
    final generation = _generation;
    final page = await widget.api.bookRequests(
      all: widget.all,
      page: _pages + 1,
      limit: _pageSize,
      includeDismissed: _showHidden,
    );
    if (!mounted || generation != _generation) return;
    setState(() {
      _loadingMore = false;
      if (page != null) {
        final seen = {for (final r in _items) r.id};
        _items = [..._items, ...page.items.where((r) => !seen.contains(r.id))];
        _total = page.total;
        _pages++;
      }
    });
  }

  /// BookOrbit moves downloads along by itself, so while one is moving the
  /// list checks back now and then.
  void _schedulePoll() {
    _poll?.cancel();
    if (!_items.any((r) => isBookRequestWorking(r.status))) return;
    _poll = Timer(const Duration(seconds: 8), () {
      if (mounted) reload(quiet: true);
    });
  }

  void _replace(BookRequest updated) {
    final i = _items.indexWhere((r) => r.id == updated.id);
    if (i >= 0) _items[i] = updated;
  }

  /// Runs [action] after any confirming it needs, and returns the request as
  /// it stands afterwards, or null when nothing changed.
  Future<BookRequest?> _act(BookRequest r, BookRequestAction action) async {
    final l = AppLocalizations.of(context)!;
    String? note;
    int? libraryId;
    switch (action) {
      case BookRequestAction.cancel:
        if (!await _confirm(l.breqCancel, l.breqCancelConfirm, l.breqCancel)) return null;
      case BookRequestAction.delete:
        if (!await _confirm(l.breqDelete, l.breqDeleteConfirm, l.delete)) return null;
      case BookRequestAction.discardImport:
        if (!await _confirm(l.breqDiscardImport, l.breqDiscardConfirm, l.breqDiscardImport)) return null;
      case BookRequestAction.stopDownload:
        if (!await _confirm(l.breqStopDownload, l.breqStopDownloadConfirm, l.breqStopDownload)) return null;
      case BookRequestAction.reject:
        final reason = await _rejectReason();
        if (reason == null) return null;
        note = reason;
      case BookRequestAction.approve:
        if (r.targetLibraryId == null && !widget.defaults.containsKey(r.mediaKind)) {
          final picked = await _pickLibrary(r);
          if (picked == null) return null;
          libraryId = picked;
        }
      default:
        break;
    }
    if (!mounted) return null;
    setState(() => _busy.add(r.id));
    final res = await widget.api.bookRequestAction(
      r.id,
      action,
      note: note,
      libraryId: libraryId,
      downloadId: r.download?.id,
    );
    if (!mounted) return null;
    setState(() {
      _busy.remove(r.id);
      if (!res.ok) return;
      final updated = res.request;
      final gone = action == BookRequestAction.delete ||
          action == BookRequestAction.leave ||
          (action == BookRequestAction.dismiss && !_showHidden);
      if (gone) {
        _items.removeWhere((x) => x.id == r.id);
        if (_total > 0) _total--;
      } else if (updated != null) {
        _replace(updated);
      }
    });
    if (res.ok) {
      widget.onChanged();
      _schedulePoll();
    }
    final done = switch (action) {
      BookRequestAction.cancel => l.breqCancelledToast,
      BookRequestAction.dismiss => l.breqHiddenToast,
      BookRequestAction.restore => l.breqRestoredToast,
      BookRequestAction.leave => l.breqLeftToast,
      BookRequestAction.approve => l.breqApprovedToast,
      BookRequestAction.reject => l.breqRejectedToast,
      BookRequestAction.delete => l.breqDeletedToast,
      BookRequestAction.forceFile => l.breqFiledToast,
      BookRequestAction.discardImport => l.breqDiscardedToast,
      BookRequestAction.stopDownload => l.breqStoppedToast,
    };
    showOverlayToast(
      context,
      res.ok ? done : (res.error != null ? l.breqActionFailedReason(res.error!) : l.breqActionFailed),
      icon: res.ok ? Icons.check_circle_outline_rounded : Icons.error_outline_rounded,
    );
    return res.ok ? (res.request ?? r) : null;
  }

  /// A manager works any request; someone allowed to download directly
  /// works the ones that are theirs to fulfil.
  bool _canFulfil(BookRequest r) =>
      widget.access.canManage ||
      (widget.access.selfFulfill && _myId != null && '${r.fulfillerUserId}' == _myId);

  Future<void> _findRelease(BookRequest r) async {
    final updated = await BookRequestReleaseScreen.open(context, widget.api, r);
    if (!mounted || updated == null) return;
    setState(() => _replace(updated));
    widget.onChanged();
    _schedulePoll();
  }

  Future<void> _approveAndFind(BookRequest r) async {
    final approved = await _act(r, BookRequestAction.approve);
    if (approved != null && mounted && canGrabBookRequest(approved.status)) await _findRelease(approved);
  }

  Future<void> _review(BookRequest r) async {
    final action = await showBookRequestReview(context, widget.api, r);
    if (action != null && mounted) await _act(r, action);
  }

  Future<bool> _confirm(String title, String body, String action) async {
    final l = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(action)),
        ],
      ),
    );
    return ok == true;
  }

  Future<String?> _rejectReason() async {
    final l = AppLocalizations.of(context)!;
    final ctrl = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.breqRejectTitle),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLength: 2000,
          minLines: 1,
          maxLines: 4,
          decoration: InputDecoration(labelText: l.breqRejectReason),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, ctrl.text), child: Text(l.breqReject)),
        ],
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => ctrl.dispose());
    return reason;
  }

  Future<int?> _pickLibrary(BookRequest r) async {
    final l = AppLocalizations.of(context)!;
    int? picked;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: Text(l.breqApproveTitle),
          content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l.breqApproveLibraryNeeded),
            const SizedBox(height: 14),
            _libraryPicker(
              context: ctx,
              libraries: widget.libraries,
              defaultId: null,
              value: picked,
              allowNone: false,
              onChanged: (v) => setDialog(() => picked = v),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
            TextButton(
              onPressed: picked == null ? null : () => Navigator.pop(ctx, true),
              child: Text(l.breqApprove),
            ),
          ],
        ),
      ),
    );
    return ok == true ? picked : null;
  }

  String _statusLabel(AppLocalizations l, String status) => switch (status) {
        'pending' => l.breqStatusPending,
        'approved' => l.breqStatusApproved,
        'rejected' => l.breqStatusRejected,
        'cancelled' => l.breqStatusCancelled,
        'searching' => l.breqStatusSearching,
        'grabbed' => l.breqStatusGrabbed,
        'downloading' => l.breqStatusDownloading,
        'importing' => l.breqStatusImporting,
        'needs_review' => l.breqStatusNeedsReview,
        'available' => l.breqStatusAvailable,
        'failed' => l.breqStatusFailed,
        _ => status,
      };

  Color _statusColor(ColorScheme cs, String status) => switch (status) {
        'pending' || 'needs_review' => Colors.orange,
        'available' => Colors.green,
        'rejected' || 'failed' => cs.error,
        'cancelled' => cs.onSurfaceVariant,
        _ => cs.primary,
      };

  String _outcome(AppLocalizations l, BookRequest r) => switch (r.status) {
        'pending' => l.breqWaitingApproval,
        'approved' => r.selfServe ? l.breqWaitingRelease : l.breqStatusApproved,
        'searching' => l.breqLookingForRelease,
        'grabbed' => l.breqStartingDownload,
        'downloading' => l.breqDownloadingPercent((r.download?.progressPercent ?? 0).round()),
        'importing' => l.breqAddingToLibrary,
        'needs_review' => l.breqWaitingCheck,
        'available' => r.targetLibraryName != null ? l.breqAddedTo(r.targetLibraryName!) : l.breqReady,
        'rejected' => r.decisionNote != null ? l.breqRejectedWithNote(r.decisionNote!) : l.breqStatusRejected,
        'cancelled' => l.breqStatusCancelled,
        'failed' => l.breqFailedWithReason(r.statusReason ?? r.download?.errorMessage ?? l.breqSomethingWrong),
        _ => r.status,
      };

  String _age(AppLocalizations l, DateTime? at) {
    if (at == null) return '';
    final d = DateTime.now().difference(at);
    if (d.inMinutes < 1) return l.justNow;
    if (d.inHours < 1) return l.minutesAgo(d.inMinutes);
    if (d.inDays < 1) return l.hoursAgo(d.inHours);
    if (d.inDays < 30) return l.daysAgo(d.inDays);
    return DateFormat.yMMMd().format(at);
  }

  bool _isMine(BookRequest r) => _myId != null && '${r.userId}' == _myId;
  bool _following(BookRequest r) => _myId != null && r.subscribers.any((s) => '${s.userId}' == _myId);

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    if (_loading) return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    if (_failed) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(l.breqLoadFailed, style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: 8),
          TextButton(onPressed: reload, child: Text(l.retry)),
        ]),
      );
    }

    return RefreshIndicator(
      onRefresh: () => reload(quiet: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Row(children: [
            Expanded(
              child: Text(l.breqCount(_total),
                  style: tt.labelLarge?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w600)),
            ),
            if (!widget.all)
              FilterChip(
                label: Text(l.breqShowHidden),
                selected: _showHidden,
                onSelected: (v) {
                  setState(() => _showHidden = v);
                  reload();
                },
              ),
          ]),
          const SizedBox(height: 8),
          if (_items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Text(widget.all ? l.breqAllEmpty : l.breqMineEmpty,
                  textAlign: TextAlign.center, style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
            ),
          for (final r in _items) _row(context, r),
          if (_items.length < _total)
            Center(
              child: _loadingMore
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  : TextButton(onPressed: _loadMore, child: Text(l.breqLoadMore)),
            ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, BookRequest r) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final busy = _busy.contains(r.id);
    final downloading = r.status == 'downloading' && r.download != null;
    final pendingForManager = widget.all && widget.access.canManage && r.status == 'pending';
    final grabbable = _canFulfil(r) && canGrabBookRequest(r.status);
    final reviewable = _canFulfil(r) && r.status == 'needs_review';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _openDetail(r),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _cover(context, r.coverUrl, width: 44),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(r.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                    if (r.authors.isNotEmpty)
                      Text(r.authors.join(', '), maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                    const SizedBox(height: 6),
                    Wrap(spacing: 6, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
                      _tag(_statusLabel(l, r.status), _statusColor(cs, r.status)),
                      _tag(_kindLabel(l, r.mediaKind), cs.onSurfaceVariant),
                      if (r.dismissed) _tag(l.breqHidden, cs.onSurfaceVariant),
                      Text(_age(l, r.createdAt), style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
                    ]),
                    const SizedBox(height: 4),
                    if (downloading)
                      Padding(
                        padding: const EdgeInsets.only(top: 2, bottom: 2),
                        child: LinearProgressIndicator(
                          value: r.download!.progressPercent / 100,
                          minHeight: 4,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    Text(_outcome(l, r), maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: tt.bodySmall?.copyWith(
                            color: r.status == 'failed' ? cs.error : cs.onSurfaceVariant)),
                    if (widget.all && r.requester.isNotEmpty)
                      Text(l.breqRequestedBy(r.requester),
                          style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
                  ]),
                ),
                if (busy)
                  const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
              ]),
              if (!busy && (pendingForManager || grabbable || reviewable))
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                    if (pendingForManager) ...[
                      TextButton(
                        onPressed: () => _act(r, BookRequestAction.reject),
                        child: Text(l.breqReject),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () => _act(r, BookRequestAction.approve),
                        child: Text(l.breqApprove),
                      ),
                    ] else if (reviewable)
                      FilledButton.tonal(
                        onPressed: () => _review(r),
                        child: Text(l.breqReviewButton),
                      )
                    else
                      FilledButton.tonal(
                        onPressed: () => _findRelease(r),
                        child: Text(r.status == 'failed' ? l.breqTryAnotherRelease : l.breqFindRelease),
                      ),
                  ]),
                ),
            ]),
          ),
        ),
      ),
    );
  }

  void _openDetail(BookRequest r) {
    final l = AppLocalizations.of(context)!;
    final mine = _isMine(r);
    final manage = widget.access.canManage;
    final actions = <({String label, IconData icon, VoidCallback run, bool danger})>[
      if (r.status == 'available' && r.matchedBookId != null)
        (
          label: l.breqOpenBook,
          icon: Icons.menu_book_rounded,
          run: () => showBookDetailSheet(context, '${r.matchedBookId}'),
          danger: false,
        ),
      if (manage && r.status == 'pending') ...[
        (label: l.breqApprove, icon: Icons.check_rounded, run: () => _act(r, BookRequestAction.approve), danger: false),
        (
          label: l.breqApproveAndFind,
          icon: Icons.manage_search_rounded,
          run: () => _approveAndFind(r),
          danger: false,
        ),
        (label: l.breqReject, icon: Icons.block_rounded, run: () => _act(r, BookRequestAction.reject), danger: true),
      ],
      if (_canFulfil(r) && canGrabBookRequest(r.status))
        (
          label: r.status == 'failed' ? l.breqTryAnotherRelease : l.breqFindRelease,
          icon: Icons.manage_search_rounded,
          run: () => _findRelease(r),
          danger: false,
        ),
      if (_canFulfil(r) && r.status == 'needs_review')
        (label: l.breqReviewButton, icon: Icons.fact_check_outlined, run: () => _review(r), danger: false),
      if ((mine || _canFulfil(r)) &&
          (r.status == 'grabbed' || r.status == 'downloading') &&
          r.download?.id != null)
        (
          label: l.breqStopDownload,
          icon: Icons.stop_circle_outlined,
          run: () => _act(r, BookRequestAction.stopDownload),
          danger: true,
        ),
      if (canCancelBookRequest(r.status) && (mine || manage))
        (label: l.breqCancel, icon: Icons.cancel_outlined, run: () => _act(r, BookRequestAction.cancel), danger: true),
      if (!widget.all && isSettledBookRequest(r.status))
        r.dismissed
            ? (label: l.breqUnhide, icon: Icons.visibility_rounded, run: () => _act(r, BookRequestAction.restore), danger: false)
            : (label: l.breqHide, icon: Icons.visibility_off_rounded, run: () => _act(r, BookRequestAction.dismiss), danger: false),
      if (!mine && _following(r))
        (label: l.breqLeave, icon: Icons.logout_rounded, run: () => _act(r, BookRequestAction.leave), danger: false),
      if (manage && isSettledBookRequest(r.status))
        (label: l.breqDelete, icon: Icons.delete_outline_rounded, run: () => _act(r, BookRequestAction.delete), danger: true),
    ];

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        final tt = Theme.of(ctx).textTheme;
        final others = [
          for (final s in r.subscribers)
            if (s.userId != r.userId && s.name.isNotEmpty) s.name,
        ];
        Widget fact(String label, String? value) => value == null || value.isEmpty
            ? const SizedBox.shrink()
            : Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(label, style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
                  const SizedBox(height: 2),
                  Text(value, style: tt.bodyMedium),
                ]),
              );
        final series = r.seriesName == null
            ? null
            : r.seriesIndex == null
                ? r.seriesName
                : '${r.seriesName} #${r.seriesIndex}';
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          maxChildSize: 0.95,
          builder: (ctx, scroll) => ListView(controller: scroll, padding: const EdgeInsets.fromLTRB(20, 20, 20, 24), children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _cover(ctx, r.coverUrl, width: 72),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(r.title, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  if (r.subtitle != null)
                    Text(r.subtitle!, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                  if (r.authors.isNotEmpty)
                    Text(r.authors.join(', '), style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                  const SizedBox(height: 8),
                  Wrap(spacing: 6, runSpacing: 4, children: [
                    _tag(_statusLabel(l, r.status), _statusColor(cs, r.status)),
                    _tag(_kindLabel(l, r.mediaKind), cs.onSurfaceVariant),
                  ]),
                ]),
              ),
            ]),
            const SizedBox(height: 14),
            if (r.status == 'downloading' && r.download != null) ...[
              LinearProgressIndicator(
                value: r.download!.progressPercent / 100,
                minHeight: 5,
                borderRadius: BorderRadius.circular(3),
              ),
              const SizedBox(height: 6),
            ],
            Text(_outcome(l, r),
                style: tt.bodyMedium?.copyWith(color: r.status == 'failed' ? cs.error : cs.onSurface)),
            const SizedBox(height: 16),
            fact(l.breqFactRequestedBy, r.requester),
            fact(l.breqFactRequestedOn,
                r.createdAt == null ? null : DateFormat.yMMMd().add_jm().format(r.createdAt!)),
            fact(l.breqFactLibrary, r.targetLibraryName),
            fact(l.seriesLabel, series),
            fact(l.isbnLabel, r.isbn),
            fact(l.breqFactDecidedBy, r.decidedBy),
            fact(l.breqFactNote, r.note),
            fact(l.breqFactDecisionNote, r.decisionNote),
            fact(l.breqFactAlsoWanted, others.isEmpty ? null : others.join(', ')),
            if (actions.isNotEmpty) ...[
              const Divider(height: 24),
              for (final a in actions)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(a.icon, color: a.danger ? cs.error : cs.primary),
                  title: Text(a.label, style: TextStyle(color: a.danger ? cs.error : null)),
                  onTap: () {
                    Navigator.pop(ctx);
                    a.run();
                  },
                ),
            ],
          ]),
        );
      },
    );
  }
}
