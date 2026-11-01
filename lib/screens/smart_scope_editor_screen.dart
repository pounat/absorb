import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/library_provider.dart';
import '../services/api_service.dart';
import '../services/smart_scope_rules.dart';
import '../utils/read_status.dart';
import '../widgets/overlay_toast.dart';

/// Lucide icon names BookOrbit's web draws, with the closest Material icon
/// for showing them here.
const scopeIcons = <String, IconData>{
  'Funnel': Icons.filter_alt_rounded,
  'BookOpen': Icons.menu_book_rounded,
  'Library': Icons.local_library_rounded,
  'Bookmark': Icons.bookmark_rounded,
  'Star': Icons.star_rounded,
  'Heart': Icons.favorite_rounded,
  'Clock': Icons.schedule_rounded,
  'Calendar': Icons.calendar_month_rounded,
  'Sparkles': Icons.auto_awesome_rounded,
  'Flame': Icons.local_fire_department_rounded,
  'Headphones': Icons.headphones_rounded,
  'Tag': Icons.sell_rounded,
  'CircleCheck': Icons.check_circle_rounded,
  'Moon': Icons.nightlight_round,
  'Sun': Icons.wb_sunny_rounded,
  'Rocket': Icons.rocket_launch_rounded,
  'Trophy': Icons.emoji_events_rounded,
  'Brain': Icons.psychology_rounded,
  'Baby': Icons.child_care_rounded,
  'Leaf': Icons.eco_rounded,
};

IconData scopeIconData(String? name) => scopeIcons[name] ?? Icons.filter_alt_rounded;

String scopeOpLabel(AppLocalizations l, String op) => switch (op) {
      'contains' => l.scopeOpContains,
      'notContains' => l.scopeOpNotContains,
      'startsWith' => l.scopeOpStartsWith,
      'endsWith' => l.scopeOpEndsWith,
      'eq' => l.scopeOpEq,
      'notEq' => l.scopeOpNotEq,
      'isEmpty' => l.scopeOpIsEmpty,
      'isNotEmpty' => l.scopeOpIsNotEmpty,
      'gt' => l.scopeOpGt,
      'gte' => l.scopeOpGte,
      'lt' => l.scopeOpLt,
      'lte' => l.scopeOpLte,
      'between' => l.scopeOpBetween,
      'includesAny' => l.scopeOpIncludesAny,
      'includesAll' => l.scopeOpIncludesAll,
      'excludesAll' => l.scopeOpExcludesAll,
      'before' => l.scopeOpBefore,
      'after' => l.scopeOpAfter,
      'withinLast' => l.scopeOpWithinLast,
      'isMissing' => l.scopeOpIsMissing,
      'isPresent' => l.scopeOpIsPresent,
      'isUnread' => l.scopeOpIsUnread,
      'isInProgress' => l.scopeOpIsInProgress,
      'isFinished' => l.scopeOpIsFinished,
      'isLocked' => l.scopeOpIsLocked,
      'isUnlocked' => l.scopeOpIsUnlocked,
      'isUpNext' => l.scopeOpIsUpNext,
      'isTrue' => l.scopeOpIsTrue,
      'isFalse' => l.scopeOpIsFalse,
      _ => op,
    };

String scopeFieldLabel(AppLocalizations l, String field, Map<String, String> customLabels) {
  if (scopeIsCustom(field)) return customLabels[field] ?? field;
  return switch (field) {
    'title' => l.scopeFieldTitle,
    'author' => l.scopeFieldAuthor,
    'series' => l.scopeFieldSeries,
    'seriesIndex' => l.scopeFieldSeriesIndex,
    'genre' => l.scopeFieldGenre,
    'tag' => l.scopeFieldTag,
    'readStatus' => l.scopeFieldReadStatus,
    'readProgress' => l.scopeFieldReadProgress,
    'rating' => l.scopeFieldRating,
    'format' => l.scopeFieldFormat,
    'library' => l.scopeFieldLibrary,
    'collection' => l.scopeFieldCollection,
    'publisher' => l.scopeFieldPublisher,
    'language' => l.scopeFieldLanguage,
    'publishedDate' => l.scopeFieldPublishedDate,
    'publishedYear' => l.scopeFieldPublishedYear,
    'addedAt' => l.scopeFieldAddedAt,
    'startedAt' => l.scopeFieldStartedAt,
    'finishedAt' => l.scopeFieldFinishedAt,
    'pageCount' => l.scopeFieldPageCount,
    'fileSize' => l.scopeFieldFileSize,
    'communityRating' => l.scopeFieldCommunityRating,
    'communityRatingCount' => l.scopeFieldCommunityRatingCount,
    'metadataScore' => l.scopeFieldMetadataScore,
    'isbn' => l.scopeFieldIsbn,
    'description' => l.scopeFieldDescription,
    'cover' => l.scopeFieldCover,
    'audioCover' => l.scopeFieldAudioCover,
    'fileAvailability' => l.scopeFieldFileAvailability,
    'lockStatus' => l.scopeFieldLockStatus,
    'seriesStatus' => l.scopeFieldSeriesStatus,
    'updatedAt' => l.scopeSortUpdatedAt,
    'lastReadAt' => l.scopeSortLastReadAt,
    'random' => l.scopeSortRandom,
    _ => field,
  };
}

String _providerLabel(AppLocalizations l, String p) => switch (p) {
      'any' => l.smartScopeAnyProvider,
      'hardcover' => 'Hardcover',
      'goodreads' => 'Goodreads',
      'google' => 'Google Books',
      'openLibrary' => 'Open Library',
      'itunes' => 'iTunes',
      'ranobedb' => 'RanobeDB',
      'amazon' => 'Amazon',
      'audible' => 'Audible',
      _ => p,
    };

/// Creates or edits a BookOrbit Smart Scope: a name and icon, a tree of
/// rules like the web's builder, and a default sort.
class SmartScopeEditorScreen extends StatefulWidget {
  /// The scope's BookOrbit id; null makes a new one.
  final String? scopeId;

  const SmartScopeEditorScreen({super.key, this.scopeId});

  /// What happened: [SmartScopeEdit.saved], [SmartScopeEdit.deleted], or
  /// null when the editor was closed without either.
  static Future<SmartScopeEdit?> open(BuildContext context, {String? scopeId}) {
    return Navigator.of(context, rootNavigator: true).push<SmartScopeEdit>(
      MaterialPageRoute(builder: (_) => SmartScopeEditorScreen(scopeId: scopeId)),
    );
  }

  @override
  State<SmartScopeEditorScreen> createState() => _SmartScopeEditorScreenState();
}

enum SmartScopeEdit { saved, deleted }

class _SmartScopeEditorScreenState extends State<SmartScopeEditorScreen> {
  BookOrbitApiService? _api;
  bool _loading = true;
  String? _loadError;
  bool _saving = false;

  final _name = TextEditingController();
  String _icon = 'Funnel';
  bool _public = false;
  bool _kobo = false;
  ScopeGroup? _root;
  final List<({String field, String dir})> _sort = [];

  final ScopeCustomTypes _customTypes = {};
  final Map<String, String> _customLabels = {};
  List<String> _libraryNames = const [];

  // Per-rule "within the last" unit (1, 7 or 30 days), shown only.
  final Map<ScopeRule, int> _dayUnits = {};

  int? _count;
  bool _counting = false;
  Timer? _countTimer;
  int _countGen = 0;

  bool get _isNew => widget.scopeId == null;

  @override
  void initState() {
    super.initState();
    final api = context.read<AuthProvider>().apiService;
    _api = api is BookOrbitApiService ? api : null;
    _name.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _countTimer?.cancel();
    _name.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final api = _api;
    if (api == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final results = await Future.wait([
        api.customMetadataFields(),
        api.libraryNames(),
        if (!_isNew) api.smartScope(widget.scopeId!),
      ]);
      for (final f in results[0] as List<Map<String, String>>) {
        _customTypes[f['key']!] = f['type']!;
        _customLabels[f['key']!] = f['label']!;
      }
      _libraryNames = results[1] as List<String>;
      if (!_isNew) {
        final s = results[2] as Map<String, dynamic>;
        _name.text = '${s['name'] ?? ''}';
        _icon = '${s['icon'] ?? 'Funnel'}';
        _public = s['isPublic'] == true;
        _kobo = s['syncToKobo'] == true;
        final filter = s['filter'];
        _root = filter is Map ? ScopeGroup.fromJson(filter, _customTypes) : null;
        for (final spec in (s['defaultSort'] as List<dynamic>? ?? const [])) {
          if (spec is Map && spec['field'] is String) {
            _sort.add((field: spec['field'] as String, dir: spec['dir'] == 'desc' ? 'desc' : 'asc'));
          }
        }
      }
    } catch (e) {
      debugPrint('[SmartScope] load failed: $e');
      _loadError = '$e';
    }
    if (!mounted) return;
    setState(() => _loading = false);
    _scheduleCount();
  }

  void _changed() {
    setState(() {});
    _scheduleCount();
  }

  List<Map<String, dynamic>> get _sortJson => [
        for (final s in _sort) {'field': s.field, 'dir': s.dir},
      ];

  void _scheduleCount() {
    _countTimer?.cancel();
    _countTimer = Timer(const Duration(milliseconds: 450), () async {
      final api = _api;
      if (api == null || !mounted) return;
      final gen = ++_countGen;
      setState(() => _counting = true);
      final count = await api.smartScopeMatchCount(_root?.toJson(_customTypes), _sortJson);
      if (!mounted || gen != _countGen) return;
      setState(() {
        _count = count;
        _counting = false;
      });
    });
  }

  Future<void> _save() async {
    final api = _api;
    final name = _name.text.trim();
    if (api == null || name.isEmpty || _saving) return;
    final l = AppLocalizations.of(context)!;
    setState(() => _saving = true);
    // A scope with no finished rule clears its filter: null, not a missing
    // key, which the server would read as "keep the old one".
    final body = <String, dynamic>{
      'name': name,
      'icon': _icon,
      'filter': _root?.toJson(_customTypes),
      'defaultSort': _sortJson,
      'isPublic': _public,
      'syncToKobo': _kobo,
    };
    try {
      if (_isNew) {
        await api.createSmartScope(body);
      } else {
        await api.updateSmartScope(widget.scopeId!, body);
      }
      if (!mounted) return;
      unawaited(context.read<LibraryProvider>().loadCollections(force: true));
      Navigator.of(context).pop(SmartScopeEdit.saved);
    } catch (e) {
      debugPrint('[SmartScope] save failed: $e');
      if (!mounted) return;
      setState(() => _saving = false);
      showOverlayToast(context, l.smartScopeSaveFailed, icon: Icons.error_outline_rounded);
    }
  }

  Future<void> _delete() async {
    final api = _api;
    if (api == null || _isNew) return;
    final l = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.smartScopeDelete),
        content: Text(l.smartScopeDeleteConfirm(_name.text.trim())),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.delete)),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _saving = true);
    try {
      await api.deleteSmartScope(widget.scopeId!);
      if (!mounted) return;
      unawaited(context.read<LibraryProvider>().loadCollections(force: true));
      Navigator.of(context).pop(SmartScopeEdit.deleted);
    } catch (e) {
      debugPrint('[SmartScope] delete failed: $e');
      if (!mounted) return;
      setState(() => _saving = false);
      showOverlayToast(context, l.smartScopeDeleteFailed, icon: Icons.error_outline_rounded);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final canSave = !_loading && _loadError == null && _name.text.trim().isNotEmpty && !_saving;
    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? l.smartScopeNew : l.smartScopeEditTitle),
        actions: [
          if (!_isNew && !_loading && _loadError == null)
            IconButton(
              tooltip: l.smartScopeDelete,
              icon: Icon(Icons.delete_outline_rounded, color: cs.error),
              onPressed: _saving ? null : _delete,
            ),
          TextButton(onPressed: canSave ? _save : null, child: Text(l.save)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : _loadError != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(l.smartScopeLoadFailed, textAlign: TextAlign.center),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 48),
                  children: [
                    TextField(
                      controller: _name,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(labelText: l.name, border: const OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    _section(l.smartScopeIcon),
                    _iconPicker(cs),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l.smartScopePublic),
                      value: _public,
                      onChanged: (v) => setState(() => _public = v),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l.smartScopeKobo),
                      value: _kobo,
                      onChanged: (v) => setState(() => _kobo = v),
                    ),
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(child: _section(l.smartScopeRules)),
                      _countChip(l, cs),
                    ]),
                    const SizedBox(height: 4),
                    if (_root == null) _templates(l) else _group(_root!, 0, l, cs),
                    const SizedBox(height: 20),
                    _section(l.smartScopeSort),
                    _sortEditor(l, cs),
                  ],
                ),
    );
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
      );

  Widget _countChip(AppLocalizations l, ColorScheme cs) {
    final text = _counting || _count == null ? l.smartScopeCounting : l.smartScopeMatchCount(_count!);
    return Chip(
      visualDensity: VisualDensity.compact,
      avatar: Icon(Icons.filter_alt_rounded, size: 16, color: cs.primary),
      label: Text(text),
    );
  }

  Widget _iconPicker(ColorScheme cs) {
    final names = scopeIcons.keys.toList();
    // A scope made on the web may use any icon; keep it selectable as is.
    if (!scopeIcons.containsKey(_icon)) names.insert(0, _icon);
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final name in names)
          ChoiceChip(
            label: Icon(scopeIconData(name), size: 20),
            selected: _icon == name,
            showCheckmark: false,
            tooltip: name,
            onSelected: (_) => setState(() => _icon = name),
          ),
      ],
    );
  }

  Widget _templates(AppLocalizations l) {
    String label(String id) => switch (id) {
          'hasSeries' => l.smartScopeTplHasSeries,
          'recent' => l.smartScopeTplRecent,
          'pdf' => l.smartScopeTplPdf,
          'noGenres' => l.smartScopeTplNoGenres,
          'epub' => l.smartScopeTplEpub,
          _ => id,
        };
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(l.smartScopeStartFrom, style: Theme.of(context).textTheme.bodySmall),
      const SizedBox(height: 6),
      Wrap(spacing: 6, runSpacing: 6, children: [
        for (final id in scopeTemplateIds)
          ActionChip(
            label: Text(label(id)),
            onPressed: () {
              _root = scopeTemplate(id);
              _changed();
            },
          ),
      ]),
      const SizedBox(height: 8),
      OutlinedButton.icon(
        icon: const Icon(Icons.add_rounded),
        label: Text(l.smartScopeFromScratch),
        onPressed: () {
          _root = scopeTemplate('scratch');
          _changed();
        },
      ),
    ]);
  }

  Widget _group(ScopeGroup g, int depth, AppLocalizations l, ColorScheme cs, {ScopeGroup? parent}) {
    final showJoin = depth > 0 || g.children.length > 1;
    final content = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (showJoin || parent != null)
        Row(children: [
          if (showJoin)
            SegmentedButton<String>(
              segments: [
                ButtonSegment(value: 'AND', label: Text(l.smartScopeMatchAll)),
                ButtonSegment(value: 'OR', label: Text(l.smartScopeMatchAny)),
              ],
              selected: {g.join},
              showSelectedIcon: false,
              style: const ButtonStyle(visualDensity: VisualDensity.compact),
              onSelectionChanged: (s) {
                g.join = s.first;
                _changed();
              },
            ),
          const Spacer(),
          if (parent != null)
            IconButton(
              tooltip: l.remove,
              icon: const Icon(Icons.close_rounded),
              onPressed: () {
                parent.children.remove(g);
                _changed();
              },
            ),
        ]),
      for (final child in g.children)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: child is ScopeGroup
              ? _group(child, depth + 1, l, cs, parent: g)
              : _rule(child as ScopeRule, g, l, cs),
        ),
      const SizedBox(height: 8),
      Wrap(spacing: 8, children: [
        TextButton.icon(
          icon: const Icon(Icons.add_rounded),
          label: Text(l.smartScopeAddRule),
          onPressed: () {
            g.children.add(ScopeRule.blank('title', _customTypes));
            _changed();
          },
        ),
        if (depth < scopeMaxNesting)
          TextButton.icon(
            icon: const Icon(Icons.account_tree_outlined),
            label: Text(l.smartScopeAddGroup),
            onPressed: () {
              g.children.add(ScopeGroup(children: [ScopeRule.blank('title', _customTypes)]));
              _changed();
            },
          ),
      ]),
    ]);
    if (depth == 0) return content;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 6, 6, 4),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: cs.primary.withValues(alpha: 0.5), width: 3)),
        color: cs.primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
      ),
      child: content,
    );
  }

  List<String> get _fieldChoices => [
        ...scopeFieldOperators.keys,
        ..._customTypes.keys,
      ];

  Widget _rule(ScopeRule r, ScopeGroup parent, AppLocalizations l, ColorScheme cs) {
    final remove = IconButton(
      tooltip: l.remove,
      icon: const Icon(Icons.close_rounded),
      onPressed: () {
        parent.children.remove(r);
        _dayUnits.remove(r);
        _changed();
      },
    );
    if (r.isUnsupported) {
      return Card(
        margin: EdgeInsets.zero,
        child: ListTile(
          leading: Icon(Icons.lock_outline_rounded, color: cs.onSurfaceVariant),
          title: Text('${r.field} ${r.op}'),
          subtitle: Text(l.smartScopeUnsupportedRule),
          trailing: remove,
        ),
      );
    }
    final ops = scopeOperatorsFor(r.field, _customTypes);
    final fieldItems = <DropdownMenuItem<String>>[
      for (final f in scopeFieldOperators.keys)
        DropdownMenuItem(value: f, child: Text(scopeFieldLabel(l, f, _customLabels))),
      for (final f in _customTypes.keys)
        DropdownMenuItem(value: f, child: Text('${scopeFieldLabel(l, f, _customLabels)} (${l.smartScopeCustomFields})')),
    ];
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 4, 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Expanded(
              child: DropdownButton<String>(
                value: _fieldChoices.contains(r.field) ? r.field : null,
                isExpanded: true,
                underline: const SizedBox.shrink(),
                items: fieldItems,
                onChanged: (f) {
                  if (f == null || f == r.field) return;
                  // A new field starts over, like the web: its first operator, no value.
                  final blank = ScopeRule.blank(f, _customTypes);
                  r
                    ..field = blank.field
                    ..op = blank.op
                    ..value = null
                    ..valueTo = null
                    ..provider = blank.provider;
                  _dayUnits.remove(r);
                  _changed();
                },
              ),
            ),
            remove,
          ]),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: DropdownButton<String>(
              value: ops.contains(r.op) ? r.op : null,
              isExpanded: true,
              items: [for (final o in ops) DropdownMenuItem(value: o, child: Text(scopeOpLabel(l, o)))],
              onChanged: (o) {
                if (o == null || o == r.op) return;
                final before = scopeInputFor(r.field, r.op, _customTypes);
                r.op = o;
                // Keep what was typed when the kind of value stays the same.
                if (scopeInputFor(r.field, o, _customTypes) != before) {
                  r.value = null;
                  r.valueTo = null;
                }
                if (o != 'between') r.valueTo = null;
                _changed();
              },
            ),
          ),
          if (scopeHasProvider(r.field))
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: DropdownButton<String>(
                value: r.provider ?? 'any',
                isExpanded: true,
                items: [
                  for (final p in scopeRatingProviders)
                    DropdownMenuItem(value: p, child: Text(_providerLabel(l, p))),
                ],
                onChanged: (p) {
                  r.provider = p;
                  _changed();
                },
              ),
            ),
          if (r.field == 'metadataScore') _scorePresets(r, l),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _valueInput(r, l, cs),
          ),
        ]),
      ),
    );
  }

  Widget _scorePresets(ScopeRule r, AppLocalizations l) {
    ActionChip chip(String label, String op, int v) => ActionChip(
          label: Text(label),
          onPressed: () {
            r
              ..op = op
              ..value = v
              ..valueTo = null;
            _changed();
          },
        );
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Wrap(spacing: 6, children: [
        chip(l.smartScopeScoreOutstanding, 'gte', 90),
        chip(l.smartScopeScoreGood, 'gte', 70),
        chip(l.smartScopeScoreFair, 'gte', 50),
        chip(l.smartScopeScorePoor, 'lt', 50),
      ]),
    );
  }

  Widget _valueInput(ScopeRule r, AppLocalizations l, ColorScheme cs) {
    final input = scopeInputFor(r.field, r.op, _customTypes);
    if (input == ScopeInput.none) return const SizedBox.shrink();
    Widget one(bool to) => _singleInput(r, input, to, l, cs);
    if (r.op == 'between' && input != ScopeInput.suggestList && input != ScopeInput.options) {
      return Row(children: [
        Expanded(child: one(false)),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Text(l.smartScopeAnd)),
        Expanded(child: one(true)),
      ]);
    }
    return one(false);
  }

  Key _key(ScopeRule r, String part) => ValueKey('${identityHashCode(r)}-${r.field}-${r.op}-$part');

  Widget _singleInput(ScopeRule r, ScopeInput input, bool to, AppLocalizations l, ColorScheme cs) {
    Object? get() => to ? r.valueTo : r.value;
    void set(Object? v) {
      if (to) {
        r.valueTo = v;
      } else {
        r.value = v;
      }
      _changed();
    }

    switch (input) {
      case ScopeInput.none:
        return const SizedBox.shrink();
      case ScopeInput.text:
      case ScopeInput.seriesIndex:
        return TextFormField(
          key: _key(r, to ? 'to' : 'v'),
          initialValue: get() == null ? '' : '${get()}',
          decoration: InputDecoration(hintText: l.smartScopeValue, isDense: true),
          onChanged: (v) => set(v),
        );
      case ScopeInput.number:
        final integer = const {'publishedYear', 'pageCount', 'rating', 'communityRatingCount'}.contains(r.field);
        return TextFormField(
          key: _key(r, to ? 'to' : 'v'),
          initialValue: get() == null ? '' : '${get()}',
          keyboardType: TextInputType.numberWithOptions(decimal: !integer, signed: false),
          decoration: InputDecoration(hintText: l.smartScopeValue, isDense: true),
          onChanged: (v) {
            final n = num.tryParse(v.trim());
            set(n == null ? null : (integer ? n.round() : n));
          },
        );
      case ScopeInput.sizeMb:
        final bytes = get();
        return TextFormField(
          key: _key(r, to ? 'to' : 'v'),
          initialValue: bytes is num ? _trimNum(scopeBytesToMb(bytes)) : '',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(hintText: l.smartScopeValue, suffixText: l.smartScopeMb, isDense: true),
          onChanged: (v) {
            final mb = num.tryParse(v.trim());
            set(mb == null || mb < 0 ? null : scopeMbToBytes(mb));
          },
        );
      case ScopeInput.date:
        final v = get();
        return Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.event_rounded, size: 18),
            label: Text(v is String && v.isNotEmpty ? v.split('T').first : l.smartScopePickDate),
            onPressed: () async {
              final initial = DateTime.tryParse(v is String ? v : '') ?? DateTime.now();
              final picked = await showDatePicker(
                context: context,
                initialDate: initial,
                firstDate: DateTime(1000),
                lastDate: DateTime(DateTime.now().year + 50),
              );
              if (picked == null) return;
              set('${picked.year.toString().padLeft(4, '0')}-'
                  '${picked.month.toString().padLeft(2, '0')}-'
                  '${picked.day.toString().padLeft(2, '0')}');
            },
          ),
        );
      case ScopeInput.days:
        final unit = _dayUnits[r] ?? 1;
        final days = get();
        final shown = days is num ? _trimNum(days / unit) : '';
        return Row(children: [
          Expanded(
            child: TextFormField(
              key: _key(r, 'days$unit'),
              initialValue: shown,
              keyboardType: const TextInputType.numberWithOptions(decimal: false),
              decoration: InputDecoration(hintText: l.smartScopeValue, isDense: true),
              onChanged: (v) {
                final n = int.tryParse(v.trim());
                set(n == null || n < 0 ? null : n * unit);
              },
            ),
          ),
          const SizedBox(width: 8),
          DropdownButton<int>(
            value: unit,
            items: [
              DropdownMenuItem(value: 1, child: Text(l.smartScopeDays)),
              DropdownMenuItem(value: 7, child: Text(l.smartScopeWeeks)),
              DropdownMenuItem(value: 30, child: Text(l.smartScopeMonths)),
            ],
            onChanged: (u) {
              if (u == null) return;
              final current = r.value is num ? (r.value as num) / unit : null;
              _dayUnits[r] = u;
              r.value = current == null ? null : (current * u).round();
              _changed();
            },
          ),
        ]);
      case ScopeInput.suggest:
        return _SuggestField(
          key: _key(r, 'suggest'),
          initial: get() is String ? get() as String : '',
          hint: l.smartScopeValue,
          suggest: (q) => _api?.metadataSuggestions(scopeSuggestSource[r.field]!, q) ?? Future.value(const []),
          onChanged: (v) => set(v),
        );
      case ScopeInput.suggestList:
        final values = (r.value is List ? (r.value as List).map((e) => '$e').toList() : <String>[]);
        return _ChipList(
          key: _key(r, 'chips'),
          values: values,
          hint: values.length >= 20 ? l.smartScopeMaxValues : l.smartScopeAddValue,
          canAdd: values.length < 20,
          suggest: (q) => _api?.metadataSuggestions(scopeSuggestSource[r.field] ?? '', q) ?? Future.value(const []),
          onChanged: (list) => set(list.isEmpty ? null : list),
        );
      case ScopeInput.options:
        final options = switch (r.field) {
          'format' => scopeBookFormats,
          'readStatus' => bookOrbitReadStatuses,
          _ => _libraryNames,
        };
        String label(String o) => switch (r.field) {
              'format' => o.toUpperCase(),
              'readStatus' => readStatusLabel(l, o),
              _ => o,
            };
        final selected = (r.value is List ? (r.value as List).map((e) => '$e').toSet() : <String>{});
        return Wrap(spacing: 6, runSpacing: 4, children: [
          for (final o in options)
            FilterChip(
              label: Text(label(o)),
              selected: selected.contains(o),
              onSelected: (on) {
                final next = {...selected};
                if (on) {
                  next.add(o);
                } else {
                  next.remove(o);
                }
                set(next.isEmpty ? null : [for (final x in options) if (next.contains(x)) x]);
              },
            ),
        ]);
    }
  }

  static String _trimNum(num v) {
    final s = v.toStringAsFixed(2);
    return s.contains('.') ? s.replaceFirst(RegExp(r'\.?0+$'), '') : s;
  }

  Widget _sortEditor(AppLocalizations l, ColorScheme cs) {
    final all = [...scopeSortFields, ..._customTypes.keys];
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (_sort.isEmpty)
        Text(l.smartScopeSortNone, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
      for (var i = 0; i < _sort.length; i++)
        Row(children: [
          Expanded(
            child: DropdownButton<String>(
              value: all.contains(_sort[i].field) ? _sort[i].field : null,
              isExpanded: true,
              items: [
                for (final f in all)
                  if (f == _sort[i].field || !_sort.any((s) => s.field == f))
                    DropdownMenuItem(value: f, child: Text(scopeFieldLabel(l, f, _customLabels))),
              ],
              onChanged: (f) {
                if (f == null) return;
                _sort[i] = (field: f, dir: _sort[i].dir);
                _changed();
              },
            ),
          ),
          IconButton(
            tooltip: _sort[i].dir == 'asc' ? l.smartScopeAscending : l.smartScopeDescending,
            icon: Icon(_sort[i].dir == 'asc' ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded),
            onPressed: () {
              _sort[i] = (field: _sort[i].field, dir: _sort[i].dir == 'asc' ? 'desc' : 'asc');
              _changed();
            },
          ),
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_up_rounded),
            onPressed: i == 0
                ? null
                : () {
                    final s = _sort.removeAt(i);
                    _sort.insert(i - 1, s);
                    _changed();
                  },
          ),
          IconButton(
            tooltip: l.remove,
            icon: const Icon(Icons.close_rounded),
            onPressed: () {
              _sort.removeAt(i);
              _changed();
            },
          ),
        ]),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          icon: const Icon(Icons.add_rounded),
          label: Text(l.smartScopeAddSort),
          onPressed: _sort.length >= all.length
              ? null
              : () {
                  final next = all.firstWhere((f) => !_sort.any((s) => s.field == f));
                  _sort.add((field: next, dir: 'asc'));
                  _changed();
                },
        ),
      ),
    ]);
  }
}

/// One name, typed or picked from the server's suggestions.
class _SuggestField extends StatelessWidget {
  final String initial;
  final String hint;
  final Future<List<String>> Function(String q) suggest;
  final ValueChanged<String> onChanged;

  const _SuggestField({
    super.key,
    required this.initial,
    required this.hint,
    required this.suggest,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      initialValue: TextEditingValue(text: initial),
      optionsBuilder: (v) => suggest(v.text),
      onSelected: onChanged,
      fieldViewBuilder: (context, controller, focus, onSubmit) => TextField(
        controller: controller,
        focusNode: focus,
        decoration: InputDecoration(hintText: hint, isDense: true),
        onChanged: onChanged,
      ),
    );
  }
}

/// Several names: chips for what's chosen and a field that suggests more.
/// Anything typed can be added too, as on the web.
class _ChipList extends StatefulWidget {
  final List<String> values;
  final String hint;
  final bool canAdd;
  final Future<List<String>> Function(String q) suggest;
  final ValueChanged<List<String>> onChanged;

  const _ChipList({
    super.key,
    required this.values,
    required this.hint,
    required this.canAdd,
    required this.suggest,
    required this.onChanged,
  });

  @override
  State<_ChipList> createState() => _ChipListState();
}

class _ChipListState extends State<_ChipList> {
  TextEditingController? _field;

  void _add(String v) {
    final t = v.trim();
    if (t.isEmpty || !widget.canAdd) return;
    if (!widget.values.contains(t)) widget.onChanged([...widget.values, t]);
    _field?.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (widget.values.isNotEmpty)
        Wrap(spacing: 6, runSpacing: 4, children: [
          for (final v in widget.values)
            InputChip(
              label: Text(v),
              onDeleted: () => widget.onChanged([...widget.values]..remove(v)),
            ),
        ]),
      Autocomplete<String>(
        optionsBuilder: (v) => widget.canAdd ? widget.suggest(v.text) : Future.value(const <String>[]),
        onSelected: _add,
        fieldViewBuilder: (context, controller, focus, onSubmit) {
          _field = controller;
          return TextField(
            controller: controller,
            focusNode: focus,
            enabled: widget.canAdd,
            decoration: InputDecoration(hintText: widget.hint, isDense: true),
            onSubmitted: _add,
          );
        },
      ),
    ]);
  }
}
