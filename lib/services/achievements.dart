/// BookOrbit achievements: the catalogue with what the user has earned, tier
/// sets grouped the way BookOrbit's web app groups them, and the "how to get
/// it" hints. Follows packages/types/src/achievement.ts and
/// client/src/features/achievements.
library;

const achievementCategories = ['reading', 'library', 'exploration', 'dedication', 'devices'];

enum AchievementRarity { common, rare, epic, legendary }

enum AchievementBucket { earned, inProgress, locked }

/// What each tier set counts. The server sends tiers, not a unit.
const achievementSetUnits = <String, String>{
  'books_finished': 'books',
  'pages_read': 'pages',
  'hours_read': 'hours',
  'long_book': 'pages',
  'library_builder': 'books',
  'annotator': 'annotations',
  'critic': 'ratings',
  'genre_explorer': 'genres',
  'polyglot': 'languages',
  'streak': 'days',
};

class Achievement {
  final String key;
  final String? groupKey;
  final int? tier;
  final String category;
  final String name;
  final String description;
  final String iconName;
  final AchievementRarity rarity;
  final double? threshold;
  final bool hidden;
  final int sortOrder;
  final bool earned;
  final DateTime? awardedAt;
  final int? contextBookId;
  final String? contextBookTitle;
  final double? currentProgress;

  const Achievement({
    required this.key,
    this.groupKey,
    this.tier,
    required this.category,
    required this.name,
    required this.description,
    required this.iconName,
    this.rarity = AchievementRarity.common,
    this.threshold,
    this.hidden = false,
    this.sortOrder = 0,
    this.earned = false,
    this.awardedAt,
    this.contextBookId,
    this.contextBookTitle,
    this.currentProgress,
  });

  /// Not earned and not shown yet. The server hides its name too.
  bool get lockedSecret => hidden && !earned;

  /// 0 to 1 toward unlocking, or null when nothing is counting.
  double? get progress {
    final t = threshold, c = currentProgress;
    if (earned || t == null || t <= 0 || c == null) return null;
    return (c / t).clamp(0.0, 1.0);
  }

  static Achievement? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final key = raw['key'];
    if (key is! String || key.isEmpty) return null;
    final title = raw['contextBookTitle'];
    return Achievement(
      key: key,
      groupKey: raw['groupKey'] as String?,
      tier: (raw['tier'] as num?)?.toInt(),
      category: '${raw['category'] ?? ''}',
      name: '${raw['name'] ?? ''}',
      description: '${raw['description'] ?? ''}',
      iconName: '${raw['iconName'] ?? ''}',
      rarity: AchievementRarity.values.asNameMap()[raw['rarity']] ?? AchievementRarity.common,
      threshold: (raw['threshold'] as num?)?.toDouble(),
      hidden: raw['hidden'] == true,
      sortOrder: (raw['sortOrder'] as num?)?.toInt() ?? 0,
      earned: raw['earned'] == true,
      awardedAt: DateTime.tryParse('${raw['awardedAt'] ?? ''}')?.toLocal(),
      contextBookId: (raw['contextBookId'] as num?)?.toInt(),
      contextBookTitle: title is String && title.trim().isNotEmpty ? title : null,
      currentProgress: (raw['currentProgress'] as num?)?.toDouble(),
    );
  }
}

/// One medal: a tier set shown as its best earned tier, or a single
/// achievement on its own.
class AchievementEntry {
  final String id;
  final String category;

  /// Lowest tier first. A single achievement is its only tier.
  final List<Achievement> tiers;
  final bool isSet;

  const AchievementEntry({required this.id, required this.category, required this.tiers, required this.isSet});

  int get earnedCount => tiers.where((t) => t.earned).length;
  bool get complete => earnedCount == tiers.length;

  Achievement? get highestEarned {
    for (final t in tiers.reversed) {
      if (t.earned) return t;
    }
    return null;
  }

  Achievement? get nextUnearned {
    for (final t in tiers) {
      if (!t.earned) return t;
    }
    return null;
  }

  /// The tier whose name, icon and rarity the medal shows.
  Achievement get face => highestEarned ?? tiers.first;

  String? get unit => isSet ? achievementSetUnits[id] : null;

  int get sortOrder => tiers.first.sortOrder;

  /// The newest unlock among its tiers, for sorting recent ones first.
  DateTime? get lastAwardedAt {
    DateTime? latest;
    for (final t in tiers) {
      final at = t.awardedAt;
      if (at != null && (latest == null || at.isAfter(latest))) latest = at;
    }
    return latest;
  }

  AchievementBucket get bucket {
    if (complete) return AchievementBucket.earned;
    if (isSet) {
      if (earnedCount > 0 || (nextUnearned?.currentProgress ?? 0) > 0) return AchievementBucket.inProgress;
      return AchievementBucket.locked;
    }
    final only = tiers.first;
    if (!only.lockedSecret && (only.currentProgress ?? 0) > 0) return AchievementBucket.inProgress;
    return AchievementBucket.locked;
  }
}

class AchievementCatalogue {
  final List<Achievement> achievements;
  final int totalEarned;
  final int totalAvailable;

  const AchievementCatalogue({required this.achievements, required this.totalEarned, required this.totalAvailable});

  static AchievementCatalogue fromJson(Map<String, dynamic> json) {
    final all = <Achievement>[];
    for (final c in (json['categories'] as List? ?? const [])) {
      if (c is! Map) continue;
      for (final a in (c['achievements'] as List? ?? const [])) {
        final item = Achievement.fromJson(a);
        if (item != null) all.add(item);
      }
    }
    return AchievementCatalogue(
      achievements: all,
      totalEarned: (json['totalEarned'] as num?)?.toInt() ?? all.where((a) => a.earned).length,
      totalAvailable: (json['totalAvailable'] as num?)?.toInt() ?? all.length,
    );
  }

  /// Tier sets folded into one entry each, in BookOrbit's order.
  List<AchievementEntry> get entries {
    final sets = <String, List<Achievement>>{};
    final result = <AchievementEntry>[];
    for (final a in achievements) {
      if (a.groupKey != null && a.tier != null) {
        sets.putIfAbsent(a.groupKey!, () => []).add(a);
      } else {
        result.add(AchievementEntry(id: a.key, category: a.category, tiers: [a], isSet: false));
      }
    }
    for (final MapEntry(key: groupKey, value: tiers) in sets.entries) {
      tiers.sort((a, b) => (a.tier ?? 0).compareTo(b.tier ?? 0));
      result.add(AchievementEntry(id: groupKey, category: tiers.first.category, tiers: tiers, isSet: true));
    }
    result.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return result;
  }
}

/// A book a hint points at.
class AchievementHintBook {
  final int id;
  final String? title;
  const AchievementHintBook(this.id, this.title);
}

/// How to get the next unlock, for the achievement [key]. Which [kind]s
/// exist grows over time; a kind Absorb doesn't know shows nothing.
class AchievementHint {
  final String key;
  final String kind;
  final int? count;
  final List<AchievementHintBook> books;
  final Map<String, dynamic> values;

  const AchievementHint({
    required this.key,
    required this.kind,
    this.count,
    this.books = const [],
    this.values = const {},
  });

  num? number(String name) {
    final v = values[name];
    return v is num && v.isFinite ? v : null;
  }

  String? text(String name) {
    final v = values[name];
    return v is String && v.trim().isNotEmpty ? v : null;
  }

  /// The book a "continue" action would open.
  int? get resumeBookId {
    final r = values['resume'];
    return r is Map ? (r['bookId'] as num?)?.toInt() : null;
  }

  static AchievementHint? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final key = raw['key'], kind = raw['kind'];
    if (key is! String || kind is! String) return null;
    final ids = raw['bookIds'] is List ? raw['bookIds'] as List : const [];
    final titles = raw['bookTitles'] is List ? raw['bookTitles'] as List : const [];
    final books = <AchievementHintBook>[];
    for (var i = 0; i < ids.length && books.length < 3; i++) {
      final id = (ids[i] as num?)?.toInt();
      if (id == null || id <= 0) continue;
      final title = i < titles.length ? titles[i] : null;
      books.add(AchievementHintBook(id, title is String && title.trim().isNotEmpty ? title : null));
    }
    return AchievementHint(
      key: key,
      kind: kind,
      count: (raw['count'] as num?)?.toInt(),
      books: books,
      values: raw['values'] is Map ? Map<String, dynamic>.from(raw['values'] as Map) : const {},
    );
  }
}
