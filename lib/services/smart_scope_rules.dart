// The rule tree behind a BookOrbit Smart Scope, kept to what the server
// accepts (packages/types/src/query.ts and its group rule validator):
// a group joins rules and groups with AND or OR, groups nest at most four
// levels below the top, every group needs at least one rule, and list
// values hold 1 to 20 items.

/// How a rule's value is entered.
enum ScopeInput {
  /// The operator needs no value (is empty, is finished, ...).
  none,
  text,
  /// One name, with suggestions from the server.
  suggest,
  /// Several names, with suggestions from the server.
  suggestList,
  /// Several values from a fixed set (formats, statuses, library names).
  options,
  number,
  /// A file size typed in MB and sent in bytes.
  sizeMb,
  /// A calendar date, sent as YYYY-MM-DD.
  date,
  /// A number of days, typed with a days / weeks / months unit.
  days,
  /// A series number, sent as text ("3", "1.5-2").
  seriesIndex,
}

const scopeValuelessOperators = {
  'isEmpty', 'isNotEmpty', 'isMissing', 'isPresent', 'isUnread', 'isInProgress',
  'isFinished', 'isLocked', 'isUnlocked', 'isUpNext', 'isTrue', 'isFalse',
};

const _textOps = ['contains', 'notContains', 'startsWith', 'endsWith', 'eq', 'notEq', 'isEmpty', 'isNotEmpty'];

/// Operators per built-in field, in the order the web lists them.
const scopeFieldOperators = <String, List<String>>{
  'title': _textOps,
  'author': ['includesAny', 'includesAll', 'excludesAll', 'isEmpty', 'isNotEmpty'],
  'series': ['contains', 'notContains', 'eq', 'notEq', 'includesAny', 'excludesAll', 'isEmpty', 'isNotEmpty'],
  'seriesIndex': ['eq', 'notEq', 'gt', 'gte', 'lt', 'lte', 'between', 'isEmpty', 'isNotEmpty'],
  'genre': ['includesAny', 'includesAll', 'excludesAll', 'isEmpty', 'isNotEmpty'],
  'tag': ['includesAny', 'includesAll', 'excludesAll', 'isEmpty', 'isNotEmpty'],
  'readStatus': ['includesAny', 'excludesAll', 'isEmpty', 'isNotEmpty'],
  'readProgress': ['isUnread', 'isInProgress', 'isFinished'],
  'rating': ['eq', 'gt', 'gte', 'lt', 'lte', 'isEmpty', 'isNotEmpty'],
  'format': ['includesAny', 'excludesAll'],
  'library': ['includesAny', 'excludesAll'],
  'collection': ['includesAny', 'excludesAll', 'isEmpty', 'isNotEmpty'],
  'publisher': ['contains', 'notContains', 'eq', 'notEq', 'includesAny', 'excludesAll', 'isEmpty', 'isNotEmpty'],
  'language': ['eq', 'notEq', 'includesAny', 'excludesAll', 'isEmpty', 'isNotEmpty'],
  'publishedDate': ['before', 'after', 'between', 'withinLast', 'isEmpty', 'isNotEmpty'],
  'publishedYear': ['eq', 'notEq', 'gt', 'gte', 'lt', 'lte', 'between', 'isEmpty', 'isNotEmpty'],
  'addedAt': ['before', 'after', 'between', 'withinLast'],
  'startedAt': ['before', 'after', 'between', 'withinLast', 'isEmpty', 'isNotEmpty'],
  'finishedAt': ['before', 'after', 'between', 'withinLast', 'isEmpty', 'isNotEmpty'],
  'pageCount': ['gt', 'gte', 'lt', 'lte', 'between', 'isEmpty', 'isNotEmpty'],
  'fileSize': ['eq', 'notEq', 'gt', 'gte', 'lt', 'lte', 'between', 'isEmpty', 'isNotEmpty'],
  'communityRating': ['eq', 'notEq', 'gt', 'gte', 'lt', 'lte', 'between', 'isEmpty', 'isNotEmpty'],
  'communityRatingCount': ['eq', 'notEq', 'gt', 'gte', 'lt', 'lte', 'between', 'isEmpty', 'isNotEmpty'],
  'metadataScore': ['gt', 'gte', 'lt', 'lte', 'between', 'isEmpty', 'isNotEmpty'],
  'isbn': ['isEmpty', 'isNotEmpty', 'eq'],
  'description': ['isEmpty', 'isNotEmpty'],
  'cover': ['isMissing', 'isPresent'],
  'audioCover': ['isMissing', 'isPresent'],
  'fileAvailability': ['isMissing', 'isPresent'],
  'lockStatus': ['isLocked', 'isUnlocked'],
  'seriesStatus': ['isUpNext'],
};

/// Operators for a custom metadata field of [type] (text, url, number,
/// date, boolean).
List<String> scopeCustomOperators(String type) => switch (type) {
      'number' => const ['eq', 'notEq', 'gt', 'gte', 'lt', 'lte', 'between', 'isEmpty', 'isNotEmpty'],
      'date' => const ['before', 'after', 'between', 'withinLast', 'isEmpty', 'isNotEmpty'],
      'boolean' => const ['isTrue', 'isFalse', 'isEmpty', 'isNotEmpty'],
      _ => _textOps,
    };

/// Where a field's name suggestions come from: GET /metadata/<source>.
const scopeSuggestSource = <String, String>{
  'author': 'authors',
  'genre': 'genres',
  'tag': 'tags',
  'series': 'series',
  'publisher': 'publishers',
  'language': 'languages',
  'collection': 'collections',
};

const scopeBookFormats = [
  'epub', 'kepub', 'pdf', 'cbz', 'cbr', 'cb7', 'mobi', 'azw3', 'azw', 'fb2',
  'm4b', 'mp3', 'm4a', 'opus', 'ogg', 'flac',
];

const scopeRatingProviders = [
  'any', 'hardcover', 'goodreads', 'google', 'openLibrary', 'itunes', 'ranobedb', 'amazon', 'audible',
];

/// Sort fields a scope can order by, as the web offers them.
const scopeSortFields = [
  'author', 'title', 'series', 'seriesIndex', 'addedAt', 'updatedAt', 'publishedDate',
  'publishedYear', 'pageCount', 'rating', 'publisher', 'fileSize', 'readProgress',
  'readStatus', 'format', 'lastReadAt', 'startedAt', 'finishedAt', 'random', 'language',
  'metadataScore',
];

/// Groups can sit this many levels below the top group.
const scopeMaxNesting = 4;

/// The value types of the user's custom metadata fields, by rule field key
/// (`custom:<id>`).
typedef ScopeCustomTypes = Map<String, String>;

bool scopeIsCustom(String field) => field.startsWith('custom:');

List<String> scopeOperatorsFor(String field, ScopeCustomTypes custom) {
  if (scopeIsCustom(field)) {
    final type = custom[field];
    return type == null ? const [] : scopeCustomOperators(type);
  }
  return scopeFieldOperators[field] ?? const [];
}

ScopeInput scopeInputFor(String field, String op, ScopeCustomTypes custom) {
  if (scopeValuelessOperators.contains(op)) return ScopeInput.none;
  if (scopeIsCustom(field)) {
    return switch (custom[field]) {
      'number' => ScopeInput.number,
      'date' => op == 'withinLast' ? ScopeInput.days : ScopeInput.date,
      'boolean' => ScopeInput.none,
      _ => ScopeInput.text,
    };
  }
  final list = op == 'includesAny' || op == 'includesAll' || op == 'excludesAll';
  switch (field) {
    case 'title':
    case 'isbn':
      return ScopeInput.text;
    case 'publisher':
    case 'language':
    case 'series':
      return list ? ScopeInput.suggestList : ScopeInput.suggest;
    case 'author':
    case 'genre':
    case 'tag':
    case 'collection':
      return ScopeInput.suggestList;
    case 'library':
    case 'format':
    case 'readStatus':
      return ScopeInput.options;
    case 'seriesIndex':
      return ScopeInput.seriesIndex;
    case 'fileSize':
      return ScopeInput.sizeMb;
    case 'publishedDate':
    case 'addedAt':
    case 'startedAt':
    case 'finishedAt':
      return op == 'withinLast' ? ScopeInput.days : ScopeInput.date;
    default:
      return ScopeInput.number;
  }
}

bool scopeHasProvider(String field) => field == 'communityRating' || field == 'communityRatingCount';

sealed class ScopeNode {
  Map<String, dynamic>? toJson(ScopeCustomTypes custom);
}

class ScopeRule extends ScopeNode {
  String field;
  String op;
  Object? value;
  Object? valueTo;
  String? provider;

  /// A rule this version can't edit (an unknown field or operator). It is
  /// sent back exactly as it came.
  final Map<String, dynamic>? raw;

  ScopeRule({required this.field, required this.op, this.value, this.valueTo, this.provider})
      : raw = null;

  ScopeRule._raw(Map<String, dynamic> json)
      : raw = json,
        field = '${json['field']}',
        op = '${json['operator']}';

  bool get isUnsupported => raw != null;

  /// A blank rule on [field], with its first operator.
  factory ScopeRule.blank(String field, ScopeCustomTypes custom) {
    final ops = scopeOperatorsFor(field, custom);
    return ScopeRule(
      field: field,
      op: ops.isEmpty ? 'eq' : ops.first,
      provider: scopeHasProvider(field) ? 'any' : null,
    );
  }

  bool get needsValueTo => op == 'between';

  bool isComplete(ScopeCustomTypes custom) {
    if (raw != null) return true;
    if (!scopeOperatorsFor(field, custom).contains(op)) return false;
    final input = scopeInputFor(field, op, custom);
    if (input == ScopeInput.none) return true;
    if (!_filled(value)) return false;
    return !needsValueTo || _filled(valueTo);
  }

  static bool _filled(Object? v) {
    if (v == null) return false;
    if (v is String) return v.trim().isNotEmpty;
    if (v is num) return v.isFinite;
    if (v is List) return v.isNotEmpty && v.length <= 20;
    return false;
  }

  @override
  Map<String, dynamic>? toJson(ScopeCustomTypes custom) {
    final r = raw;
    if (r != null) return r;
    if (!isComplete(custom)) return null;
    final input = scopeInputFor(field, op, custom);
    Object? clean(Object? v) => v is String ? v.trim() : v;
    return {
      'type': 'rule',
      'field': field,
      'operator': op,
      if (input != ScopeInput.none) 'value': clean(value),
      if (input != ScopeInput.none && needsValueTo) 'valueTo': clean(valueTo),
      if (scopeHasProvider(field)) 'provider': provider ?? 'any',
    };
  }
}

class ScopeGroup extends ScopeNode {
  String join;
  final List<ScopeNode> children;

  ScopeGroup({this.join = 'AND', List<ScopeNode>? children}) : children = children ?? [];

  /// Null when nothing in the group is complete: the server refuses empty
  /// groups, so they and half-filled rules are left out.
  @override
  Map<String, dynamic>? toJson(ScopeCustomTypes custom) {
    final rules = [
      for (final c in children) c.toJson(custom),
    ].whereType<Map<String, dynamic>>().toList();
    if (rules.isEmpty) return null;
    return {'type': 'group', 'join': join == 'OR' ? 'OR' : 'AND', 'rules': rules};
  }

  /// How many groups deep the deepest group under this one sits.
  int get depth {
    var deepest = 0;
    for (final c in children) {
      if (c is ScopeGroup) {
        final d = c.depth + 1;
        if (d > deepest) deepest = d;
      }
    }
    return deepest;
  }

  static ScopeGroup fromJson(Object? json, ScopeCustomTypes custom) {
    if (json is! Map) return ScopeGroup();
    final group = ScopeGroup(join: json['join'] == 'OR' ? 'OR' : 'AND');
    for (final r in (json['rules'] as List<dynamic>? ?? const [])) {
      if (r is! Map) continue;
      final m = Map<String, dynamic>.from(r);
      if (m['type'] == 'group') {
        group.children.add(fromJson(m, custom));
        continue;
      }
      final field = '${m['field']}';
      final op = '${m['operator']}';
      if (!scopeOperatorsFor(field, custom).contains(op)) {
        group.children.add(ScopeRule._raw(m));
        continue;
      }
      group.children.add(ScopeRule(
        field: field,
        op: op,
        value: _copy(m['value']),
        valueTo: _copy(m['valueTo']),
        provider: m['provider'] as String? ?? (scopeHasProvider(field) ? 'any' : null),
      ));
    }
    return group;
  }

  static Object? _copy(Object? v) => v is List ? List<Object?>.from(v) : v;
}

/// Starting points the web offers for an empty scope.
ScopeGroup scopeTemplate(String id) => switch (id) {
      'hasSeries' => ScopeGroup(children: [ScopeRule(field: 'series', op: 'isNotEmpty')]),
      'recent' => ScopeGroup(children: [ScopeRule(field: 'addedAt', op: 'withinLast', value: 30)]),
      'pdf' => ScopeGroup(children: [ScopeRule(field: 'format', op: 'includesAny', value: ['pdf'])]),
      'noGenres' => ScopeGroup(children: [ScopeRule(field: 'genre', op: 'isEmpty')]),
      'epub' => ScopeGroup(children: [ScopeRule(field: 'format', op: 'includesAny', value: ['epub'])]),
      _ => ScopeGroup(children: [ScopeRule(field: 'title', op: 'contains')]),
    };

const scopeTemplateIds = ['hasSeries', 'recent', 'pdf', 'noGenres', 'epub'];

/// A file size in MB as the bytes the server compares against.
int scopeMbToBytes(num mb) => (mb * 1024 * 1024).round();

double scopeBytesToMb(num bytes) => bytes / (1024 * 1024);
