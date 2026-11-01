import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../services/achievements.dart';
import '../widgets/absorb_page_header.dart';
import '../widgets/book_detail_sheet.dart' show showBookDetailSheet;

/// The account's BookOrbit achievements: what is earned, what is close, and
/// how to get the rest, grouped the way BookOrbit's web app groups them.
class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  static Future<void> open(BuildContext context) => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AchievementsScreen()),
      );

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  AchievementCatalogue? _catalogue;
  Map<String, AchievementHint> _hints = {};
  bool _loading = true;
  AchievementBucket? _filter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  Future<void> _reload({bool fresh = false}) async {
    final api = context.read<AuthProvider>().apiService;
    if (api == null) return;
    setState(() => _loading = true);
    final results = await Future.wait([api.achievements(fresh: fresh), api.achievementHints()]);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _catalogue = results[0] as AchievementCatalogue? ?? _catalogue;
      _hints = {for (final h in results[1] as List<AchievementHint>) h.key: h};
    });
  }

  AchievementHint? _hintFor(AchievementEntry e) {
    final key = e.isSet ? e.nextUnearned?.key : (e.tiers.first.earned ? null : e.tiers.first.key);
    return key == null ? null : _hints[key];
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;
    final catalogue = _catalogue;
    final entries = catalogue?.entries ?? const <AchievementEntry>[];
    final counts = {
      for (final b in AchievementBucket.values) b: entries.where((e) => e.bucket == b).length,
    };
    final shown = entries.where((e) => _filter == null || e.bucket == _filter).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 8, 0),
            child: Row(children: [
              Expanded(child: AbsorbPageHeader(title: l.achievementsTitle, padding: EdgeInsets.zero)),
              IconButton(
                icon: Icon(Icons.close_rounded, color: cs.onSurfaceVariant),
                onPressed: () => Navigator.pop(context),
              ),
            ]),
          ),
          const SizedBox(height: 8),
          if (_loading) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _reload(fresh: true),
              child: catalogue == null
                  ? ListView(children: [
                      const SizedBox(height: 120),
                      if (!_loading) ...[
                        Icon(Icons.cloud_off_rounded, size: 40, color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
                        const SizedBox(height: 12),
                        Center(
                          child: Text(l.achievementsLoadFailed,
                              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant.withValues(alpha: 0.6))),
                        ),
                      ],
                    ])
                  : CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverToBoxAdapter(child: _summary(cs, tt, l, catalogue)),
                        SliverToBoxAdapter(child: _filters(l, entries.length, counts)),
                        if (shown.isEmpty)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.all(48),
                              child: Center(
                                child: Text(l.achievementsNoneMatch,
                                    style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant.withValues(alpha: 0.6))),
                              ),
                            ),
                          ),
                        for (final category in [
                          ...achievementCategories,
                          ...{for (final e in shown) e.category}.where((c) => !achievementCategories.contains(c)),
                        ])
                          ..._section(cs, tt, l, category, entries, shown.where((e) => e.category == category).toList()),
                        const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
                      ],
                    ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _summary(ColorScheme cs, TextTheme tt, AppLocalizations l, AchievementCatalogue c) {
    final share = c.totalAvailable == 0 ? 0.0 : c.totalEarned / c.totalAvailable;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [cs.primary.withValues(alpha: 0.14), cs.primary.withValues(alpha: 0.04)],
          ),
          border: Border.all(color: cs.primary.withValues(alpha: 0.15)),
        ),
        child: Row(children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: cs.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(14)),
            child: Icon(Icons.emoji_events_rounded, color: cs.primary, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l.achievementsEarnedSummary(c.totalEarned, c.totalAvailable),
                  style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: share,
                  minHeight: 6,
                  backgroundColor: cs.primary.withValues(alpha: 0.12),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _filters(AppLocalizations l, int all, Map<AchievementBucket, int> counts) {
    Widget chip(AchievementBucket? bucket, String label, int count) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text('$label  $count'),
            selected: _filter == bucket,
            onSelected: (_) => setState(() => _filter = bucket),
          ),
        );
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 4),
      child: Row(children: [
        chip(null, l.achievementsFilterAll, all),
        chip(AchievementBucket.earned, l.achievementsFilterEarned, counts[AchievementBucket.earned]!),
        chip(AchievementBucket.inProgress, l.achievementsFilterInProgress, counts[AchievementBucket.inProgress]!),
        chip(AchievementBucket.locked, l.achievementsFilterLocked, counts[AchievementBucket.locked]!),
      ]),
    );
  }

  List<Widget> _section(ColorScheme cs, TextTheme tt, AppLocalizations l, String category,
      List<AchievementEntry> all, List<AchievementEntry> shown) {
    if (shown.isEmpty) return const [];
    final inCategory = all.where((e) => e.category == category);
    final earned = inCategory.fold<int>(0, (n, e) => n + e.earnedCount);
    final total = inCategory.fold<int>(0, (n, e) => n + e.tiers.length);
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          child: Row(children: [
            Expanded(
              child: Text(achievementCategoryLabel(l, category).toUpperCase(),
                  style: tt.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant.withValues(alpha: 0.7), fontWeight: FontWeight.w700, letterSpacing: 0.6)),
            ),
            Text('$earned / $total', style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant.withValues(alpha: 0.6))),
          ]),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 130,
            mainAxisExtent: 156,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, i) => _MedalTile(
              entry: shown[i],
              onTap: () => AchievementDetailSheet.show(context, shown[i], _hintFor(shown[i])),
            ),
            childCount: shown.length,
          ),
        ),
      ),
    ];
  }
}

String achievementCategoryLabel(AppLocalizations l, String category) => switch (category) {
      'reading' => l.achievementsCategoryReading,
      'library' => l.achievementsCategoryLibrary,
      'exploration' => l.achievementsCategoryExploration,
      'dedication' => l.achievementsCategoryDedication,
      'devices' => l.achievementsCategoryDevices,
      _ => category,
    };

String achievementRarityLabel(AppLocalizations l, AchievementRarity r) => switch (r) {
      AchievementRarity.common => l.achievementsRarityCommon,
      AchievementRarity.rare => l.achievementsRarityRare,
      AchievementRarity.epic => l.achievementsRarityEpic,
      AchievementRarity.legendary => l.achievementsRarityLegendary,
    };

Color achievementRarityColor(AchievementRarity r) => switch (r) {
      AchievementRarity.common => const Color(0xFF7C8B99),
      AchievementRarity.rare => const Color(0xFF3B82F6),
      AchievementRarity.epic => const Color(0xFFA855F7),
      AchievementRarity.legendary => const Color(0xFFF59E0B),
    };

/// BookOrbit names its icons after Lucide's; these are the closest Material
/// ones.
IconData achievementIcon(String name) => switch (name) {
      'lock' => Icons.lock_rounded,
      'highlighter' => Icons.border_color_rounded,
      'star' => Icons.star_rounded,
      'star-half' => Icons.star_half_rounded,
      'library' => Icons.local_library_rounded,
      'globe' => Icons.public_rounded,
      'flame' => Icons.local_fire_department_rounded,
      'file-text' => Icons.description_rounded,
      'files' => Icons.file_copy_rounded,
      'compass' => Icons.explore_rounded,
      'clock' => Icons.schedule_rounded,
      'timer' => Icons.timer_rounded,
      'hourglass' => Icons.hourglass_bottom_rounded,
      'book-open' => Icons.menu_book_rounded,
      'book-marked' => Icons.bookmark_rounded,
      'bookmark-check' => Icons.bookmark_added_rounded,
      'book-heart' => Icons.favorite_rounded,
      'book-x' => Icons.book_rounded,
      'scroll' || 'scroll-text' || 'feather' => Icons.history_edu_rounded,
      'calendar' => Icons.calendar_today_rounded,
      'calendar-range' => Icons.date_range_rounded,
      'calendar-check' => Icons.event_available_rounded,
      'zap' => Icons.bolt_rounded,
      'trophy' => Icons.emoji_events_rounded,
      'medal' => Icons.military_tech_rounded,
      'award' => Icons.workspace_premium_rounded,
      'thumbs-down' => Icons.thumb_down_rounded,
      'swords' => Icons.shield_rounded,
      'sunrise' => Icons.wb_twilight_rounded,
      'sun' => Icons.wb_sunny_rounded,
      'moon' => Icons.dark_mode_rounded,
      'sprout' => Icons.eco_rounded,
      'sparkles' => Icons.auto_awesome_rounded,
      'party-popper' => Icons.celebration_rounded,
      'smartphone' => Icons.smartphone_rounded,
      'repeat' => Icons.repeat_rounded,
      'rabbit' => Icons.cruelty_free_rounded,
      'play' => Icons.play_arrow_rounded,
      'fast-forward' => Icons.fast_forward_rounded,
      'pen-tool' => Icons.draw_rounded,
      'pen-line' => Icons.edit_rounded,
      'palette' => Icons.palette_rounded,
      'orbit' => Icons.track_changes_rounded,
      'mountain' => Icons.landscape_rounded,
      'minimize-2' => Icons.close_fullscreen_rounded,
      'list-ordered' => Icons.format_list_numbered_rounded,
      'heart' => Icons.favorite_rounded,
      'gavel' => Icons.gavel_rounded,
      'gauge' => Icons.speed_rounded,
      'folder-open' => Icons.folder_open_rounded,
      'corner-up-right' => Icons.turn_right_rounded,
      'coffee' => Icons.coffee_rounded,
      'arrow-up-down' => Icons.swap_vert_rounded,
      'arrow-left-right' => Icons.swap_horiz_rounded,
      'activity' => Icons.show_chart_rounded,
      _ => Icons.emoji_events_rounded,
    };

String _number(num value, String locale) => NumberFormat.decimalPattern(locale).format(value);

/// "120 / 500 pages", counted down to what has been reached.
String achievementProgressText(AppLocalizations l, Achievement a, String? unit, String locale) {
  final current = _number((a.currentProgress ?? 0).floor(), locale);
  final threshold = _number(a.threshold ?? 0, locale);
  return switch (unit) {
    'books' => l.achievementsProgressBooks(current, threshold),
    'pages' => l.achievementsProgressPages(current, threshold),
    'hours' => l.achievementsProgressHours(current, threshold),
    'annotations' => l.achievementsProgressAnnotations(current, threshold),
    'ratings' => l.achievementsProgressRatings(current, threshold),
    'genres' => l.achievementsProgressGenres(current, threshold),
    'languages' => l.achievementsProgressLanguages(current, threshold),
    'days' => l.achievementsProgressDays(current, threshold),
    _ => l.achievementsProgress(current, threshold),
  };
}

/// What a hint says, in this app's words. Null for a kind Absorb doesn't
/// know or one missing a value it needs.
({String text, String? note, bool blocked})? achievementHintText(
    AppLocalizations l, AchievementHint h, String locale) {
  final count = h.count;
  String pct(num p) => NumberFormat.percentPattern(locale).format(p / 100);
  String month(int year, int m) => DateFormat.MMMM(locale).format(DateTime(year, m));
  ({String text, String? note, bool blocked}) say(String text, [String? note]) =>
      (text: text, note: note, blocked: false);

  switch (h.kind) {
    case 'reading_pace':
      final hours = h.number('hours'), days = h.number('days'), eta = h.number('etaDays');
      if (hours == null || days == null) return null;
      String? note;
      if (eta != null) {
        note = eta < 14
            ? l.achievementsHintEtaDays(math.max(1, eta.round()))
            : eta < 60
                ? l.achievementsHintEtaWeeks((eta / 7).round())
                : l.achievementsHintEtaMonths((eta / 30).round());
      }
      return say(l.achievementsHintReadingPace(hours.floor(), days.round()), note);
    case 'period_unread':
      final period = h.number('period');
      if (period == null || count == null) return null;
      return say(h.values['years'] == 100
          ? l.achievementsHintCenturyUnread(count, '${period.round()}')
          : l.achievementsHintDecadeUnread(count, '${period.round()}'));
    case 'stalled_book':
      final started = DateTime.tryParse(h.text('startedAt') ?? '')?.toLocal();
      if (started == null) return null;
      final title = h.text('title') ?? l.achievementsHintUntitledBook;
      final date = DateFormat.yMMMd(locale).format(started);
      final percent = h.number('percent');
      return say(percent == null
          ? l.achievementsHintStalledNoProgress(title, date)
          : l.achievementsHintStalled(title, pct(percent), date));
    case 'nearly_finished':
      final min = h.number('minPercent');
      if (min == null || count == null) return null;
      return say(l.achievementsHintNearlyFinished(count, pct(min)));
    case 'unrated_finished':
      if (count == null) return null;
      return say(l.achievementsHintUnrated(count));
    case 'short_books':
      final pages = h.number('maxPages'), started = h.number('inProgress');
      if (pages == null || count == null) return null;
      return say(l.achievementsHintShortBooks(count, _number(pages, locale)),
          started != null && started > 0 ? l.achievementsHintAlreadyStarted(started.round()) : null);
    case 'long_books':
      final pages = h.number('minPages');
      if (pages == null || count == null) return null;
      return say(l.achievementsHintLongBooks(count, _number(pages, locale)));
    case 'old_books':
      final year = h.number('year');
      if (year == null || count == null) return null;
      return say(l.achievementsHintOldBooks(count, '${year.round()}'));
    case 'author_unread':
      final author = h.text('author'), finished = h.number('finished');
      if (author == null || finished == null || count == null) return null;
      return say(l.achievementsHintAuthorUnread(author, finished.round(), count));
    case 'language_unread':
      final language = h.text('language');
      if (language == null || count == null) return null;
      return say(l.achievementsHintLanguageUnread(count, language));
    case 'months_left':
      final year = h.number('year')?.round(), read = h.number('monthsRead');
      final months = [
        for (final m in (h.values['months'] is List ? h.values['months'] as List : const []))
          if (m is int && m >= 1 && m <= 12) m,
      ];
      if (year == null || read == null || months.isEmpty) return null;
      return say(l.achievementsHintMonthsRead(read.round(), '$year'),
          l.achievementsHintMonthsLeft(months.length, months.map((m) => month(year, m)).join(', ')));
    case 'unavailable':
      final text = switch (h.values['reason']) {
        'no_long_book' when h.number('pages') != null =>
          l.achievementsHintNoLongBook(_number(h.number('pages')!, locale)),
        'nothing_before_year' when h.number('year') != null =>
          l.achievementsHintNothingBefore('${h.number('year')!.round()}'),
        'too_few_periods' when h.number('reachable') != null => h.values['years'] == 100
            ? l.achievementsHintTooFewCenturies(h.number('reachable')!.round())
            : l.achievementsHintTooFewDecades(h.number('reachable')!.round()),
        'missed_month' when h.number('year') != null && h.number('month') != null =>
          l.achievementsHintMissedMonth(
              month(h.number('year')!.round(), h.number('month')!.round().clamp(1, 12)), '${h.number('year')!.round()}'),
        _ => null,
      };
      return text == null ? null : (text: text, note: null, blocked: true);
  }
  return null;
}

class _Medal extends StatelessWidget {
  final Achievement face;
  final bool earned;
  final double? progress;
  final double size;

  const _Medal({required this.face, required this.earned, this.progress, this.size = 64});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = achievementRarityColor(face.rarity);
    final ring = size + 8;
    return SizedBox(
      width: ring,
      height: ring,
      child: Stack(alignment: Alignment.center, children: [
        if (progress != null)
          SizedBox(
            width: ring,
            height: ring,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 3,
              color: cs.primary,
              backgroundColor: cs.onSurface.withValues(alpha: 0.08),
            ),
          ),
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: earned
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [color.withValues(alpha: 0.95), Color.lerp(color, Colors.black, 0.3)!],
                  )
                : null,
            color: earned ? null : cs.surfaceContainerHighest,
            border: Border.all(
                color: earned ? color.withValues(alpha: 0.5) : cs.onSurface.withValues(alpha: 0.08), width: 2),
          ),
          child: Icon(
            face.lockedSecret ? Icons.lock_rounded : achievementIcon(face.iconName),
            size: size * 0.45,
            color: earned ? Colors.white : cs.onSurfaceVariant.withValues(alpha: 0.5),
          ),
        ),
      ]),
    );
  }
}

class _MedalTile extends StatelessWidget {
  final AchievementEntry entry;
  final VoidCallback onTap;

  const _MedalTile({required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final face = entry.face;
    final next = entry.nextUnearned;
    final name = face.lockedSecret ? l.achievementsSecretName : face.name;
    final String subtitle;
    if (entry.isSet) {
      subtitle = l.achievementsTierOf(entry.earnedCount, entry.tiers.length);
    } else if (face.earned && face.awardedAt != null) {
      subtitle = DateFormat.yMMMd(locale).format(face.awardedAt!);
    } else if (next?.progress != null && (next!.currentProgress ?? 0) > 0) {
      subtitle = achievementProgressText(l, next, entry.unit, locale);
    } else {
      subtitle = '';
    }

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
        child: Column(children: [
          _Medal(
            face: face,
            earned: entry.highestEarned != null,
            progress: entry.complete ? null : next?.progress,
          ),
          const SizedBox(height: 8),
          Text(name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: tt.labelMedium?.copyWith(fontWeight: FontWeight.w600, height: 1.15)),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant.withValues(alpha: 0.7), fontSize: 10.5)),
          ],
        ]),
      ),
    );
  }
}

class AchievementDetailSheet extends StatelessWidget {
  final AchievementEntry entry;
  final AchievementHint? hint;

  const AchievementDetailSheet({super.key, required this.entry, this.hint});

  static Future<void> show(BuildContext context, AchievementEntry entry, AchievementHint? hint) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (_) => AchievementDetailSheet(entry: entry, hint: hint),
      );

  void _openBook(BuildContext context, int id) {
    Navigator.pop(context);
    showBookDetailSheet(context, '$id');
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final face = entry.face;
    final secret = face.lockedSecret;
    final next = entry.nextUnearned;
    final hintView = hint == null ? null : achievementHintText(l, hint!, locale);
    final rarity = achievementRarityColor(face.rarity);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: entry.isSet || hintView != null ? 0.7 : 0.5,
      maxChildSize: 0.95,
      builder: (context, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: cs.onSurface.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: _Medal(
              face: face,
              earned: entry.highestEarned != null,
              progress: entry.complete ? null : next?.progress,
              size: 88,
            ),
          ),
          const SizedBox(height: 14),
          Text(secret ? l.achievementsSecretName : face.name,
              textAlign: TextAlign.center, style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(alignment: WrapAlignment.center, spacing: 8, runSpacing: 6, children: [
            if (!secret)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: rarity.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                child: Text(achievementRarityLabel(l, face.rarity),
                    style: tt.labelSmall?.copyWith(color: rarity, fontWeight: FontWeight.w700)),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: cs.onSurface.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(6)),
              child: Text(achievementCategoryLabel(l, entry.category),
                  style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w600)),
            ),
            if (entry.isSet)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: cs.onSurface.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(6)),
                child: Text(l.achievementsTierOf(entry.earnedCount, entry.tiers.length),
                    style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w600)),
              ),
          ]),
          const SizedBox(height: 12),
          Text(secret ? l.achievementsSecretHint : face.description,
              textAlign: TextAlign.center, style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
          if (face.earned && face.awardedAt != null) ...[
            const SizedBox(height: 10),
            Text(l.achievementsEarnedOn(DateFormat.yMMMd(locale).format(face.awardedAt!)),
                textAlign: TextAlign.center, style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant)),
          ],
          if (face.earned && face.contextBookTitle != null)
            Center(
              child: TextButton.icon(
                onPressed: face.contextBookId == null ? null : () => _openBook(context, face.contextBookId!),
                icon: const Icon(Icons.menu_book_rounded, size: 16),
                label: Text(l.achievementsWhileReading(face.contextBookTitle!), textAlign: TextAlign.center),
              ),
            ),
          if (entry.complete && entry.isSet) ...[
            const SizedBox(height: 16),
            Center(
              child: Text(l.achievementsAllTiers,
                  style: tt.labelLarge?.copyWith(color: cs.primary, fontWeight: FontWeight.w700)),
            ),
          ] else if (!secret && next?.progress != null) ...[
            const SizedBox(height: 18),
            Row(children: [
              Expanded(
                child: Text(entry.isSet ? next!.name : '',
                    style: tt.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
              ),
              Text(achievementProgressText(l, next!, entry.unit, locale),
                  style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant)),
            ]),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: next.progress,
                minHeight: 6,
                backgroundColor: cs.onSurface.withValues(alpha: 0.08),
              ),
            ),
          ],
          if (hintView != null) ...[
            const SizedBox(height: 22),
            Text(l.achievementsHowToGetIt.toUpperCase(),
                style: tt.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant.withValues(alpha: 0.7), fontWeight: FontWeight.w700, letterSpacing: 0.6)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(14)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(hintView.blocked ? Icons.info_outline_rounded : Icons.lightbulb_outline_rounded,
                      size: 18, color: hintView.blocked ? cs.onSurfaceVariant : cs.primary),
                  const SizedBox(width: 10),
                  Expanded(child: Text(hintView.text, style: tt.bodyMedium)),
                ]),
                if (hintView.note != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 28, top: 4),
                    child: Text(hintView.note!, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                  ),
                if (hint!.books.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 24, top: 8),
                    child: Wrap(spacing: 8, runSpacing: 6, children: [
                      for (final b in hint!.books)
                        ActionChip(
                          avatar: const Icon(Icons.menu_book_rounded, size: 16),
                          label: Text(b.title ?? l.achievementsHintUntitledBook,
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          onPressed: () => _openBook(context, b.id),
                        ),
                    ]),
                  ),
              ]),
            ),
          ],
          if (entry.isSet) ...[
            const SizedBox(height: 22),
            Text(l.achievementsTiers.toUpperCase(),
                style: tt.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant.withValues(alpha: 0.7), fontWeight: FontWeight.w700, letterSpacing: 0.6)),
            const SizedBox(height: 4),
            for (final t in entry.tiers)
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: Icon(
                  t.earned ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                  color: t.earned ? achievementRarityColor(t.rarity) : cs.onSurfaceVariant.withValues(alpha: 0.4),
                ),
                title: Text(t.name, style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                subtitle: Text(t.description, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                trailing: Text(
                  t.earned && t.awardedAt != null
                      ? DateFormat.yMMMd(locale).format(t.awardedAt!)
                      : achievementRarityLabel(l, t.rarity),
                  style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant.withValues(alpha: 0.7)),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
