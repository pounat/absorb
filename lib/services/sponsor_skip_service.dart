import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'player_settings.dart';

enum SponsorSegmentKind { sponsor, introOutro, custom }

class SponsorSegment {
  final double start;
  final double end;
  final String label;
  final SponsorSegmentKind kind;

  const SponsorSegment({
    required this.start,
    required this.end,
    required this.label,
    required this.kind,
  });

  double get duration => (end - start).clamp(0.0, double.infinity);

  String get key => '${start.toStringAsFixed(1)}-${end.toStringAsFixed(1)}';

  @override
  String toString() =>
      'SponsorSegment($start..$end, "$label", kind=${kind.name})';
}

/// Detects sponsor, ad, and optional intro/outro segments in podcast episodes
/// from embedded chapters and timestamped show-notes descriptions.
class SponsorSkipService {
  static final List<RegExp> _sponsorPatterns = [
    RegExp(r'\bsponsor(?:s|ed|ship|ing)?\b', caseSensitive: false),
    RegExp(
      r'\bad(?:s|vertisement|vertisements|vert|orial)?\b',
      caseSensitive: false,
    ),
    RegExp(
      r'\bad\s*[-–—]?\s*(?:break|read|spot|segment|block)\b',
      caseSensitive: false,
    ),
    RegExp(r'\bcommercials?\b', caseSensitive: false),
    RegExp(r'\b(?:pre|mid|post)\s*[-–—]?\s*roll\b', caseSensitive: false),
    RegExp(
      r'\bpaid\s+(?:partnership|promotion|promo|sponsor(?:ship)?)\b',
      caseSensitive: false,
    ),
    RegExp(
      r'\bpromo(?:\s+code|\s+break|\s+segment|tion)?\b',
      caseSensitive: false,
    ),
    RegExp(r'\bbrought\s+to\s+you\s+by\b', caseSensitive: false),
    RegExp(r'\bthanks\s+to\s+our\s+sponsor\b', caseSensitive: false),
    RegExp(r'\bword\s+from\s+our\s+sponsor\b', caseSensitive: false),
  ];

  static final RegExp _introOutroPattern = RegExp(
    r'\b(?:intro|introduction|opening|outro|closing|end\s+credits|credits)\b',
    caseSensitive: false,
  );

  static final RegExp _rangeLineRegex = RegExp(
    r'^\s*(?:[-*•]\s*)?[\[(]?((?:\d{1,2}:)?\d{1,2}:\d{2})[\])]?\s*(?:-|–|—|\bto\b)\s*[\[(]?((?:\d{1,2}:)?\d{1,2}:\d{2})[\])]?\s*[:\-–—|]?\s*(.+?)\s*$',
    caseSensitive: false,
  );

  static final RegExp _singleTimestampLineRegex = RegExp(
    r'^\s*(?:[-*•]\s*)?[\[(]?((?:\d{1,2}:)?\d{1,2}:\d{2})[\])]?\s*[:\-–—|]?\s*(.+?)\s*$',
  );

  static List<String> parseCustomKeywords(String raw) {
    if (raw.trim().isEmpty) return const [];
    return raw
        .split(RegExp(r'[,\n]+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  static Future<bool> isEnabledForShow(String? showId) async {
    if (showId != null && showId.isNotEmpty) {
      final override =
          await PlayerSettings.getPodcastSponsorSkipOverride(showId);
      if (override != null) return override;
    }
    return PlayerSettings.getPodcastSponsorSkipEnabled();
  }

  static SponsorSegmentKind? classifyTitle(
    String title, {
    bool includeIntroOutro = false,
    List<String> customKeywords = const [],
  }) {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return null;

    for (final pattern in _sponsorPatterns) {
      if (pattern.hasMatch(trimmed)) {
        return SponsorSegmentKind.sponsor;
      }
    }

    for (final kw in customKeywords) {
      final k = kw.trim();
      if (k.isEmpty) continue;
      final isWordLike = RegExp(r'^[\w\s]+$').hasMatch(k);
      if (isWordLike) {
        final re = RegExp(
          '\\b${RegExp.escape(k)}\\b',
          caseSensitive: false,
        );
        if (re.hasMatch(trimmed)) return SponsorSegmentKind.custom;
      } else if (trimmed.toLowerCase().contains(k.toLowerCase())) {
        return SponsorSegmentKind.custom;
      }
    }

    if (includeIntroOutro && _introOutroPattern.hasMatch(trimmed)) {
      return SponsorSegmentKind.introOutro;
    }

    return null;
  }

  static double? parseTimestampSeconds(String ts) {
    final parts = ts.trim().split(':');
    if (parts.length < 2 || parts.length > 3) return null;
    final nums = <int>[];
    for (final p in parts) {
      final n = int.tryParse(p);
      if (n == null || n < 0) return null;
      nums.add(n);
    }
    if (nums.length == 2) {
      if (nums[1] >= 60) return null;
      return (nums[0] * 60 + nums[1]).toDouble();
    }
    if (nums[1] >= 60 || nums[2] >= 60) return null;
    return (nums[0] * 3600 + nums[1] * 60 + nums[2]).toDouble();
  }

  static String _htmlToPlainLines(String html) {
    var text = html
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(
          RegExp(r'</(?:p|div|li|h[1-6]|tr)>', caseSensitive: false),
          '\n',
        )
        .replaceAll(RegExp(r'<[^>]+>'), ' ');
    text = text
        .replaceAll('&amp;', '&')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&apos;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&ndash;', '–')
        .replaceAll('&mdash;', '—');
    return text;
  }

  static List<SponsorSegment> extractFromChapters(
    List<dynamic> chapters, {
    double totalDuration = 0,
    bool includeIntroOutro = false,
    List<String> customKeywords = const [],
  }) {
    if (chapters.isEmpty) return const [];
    final out = <SponsorSegment>[];
    for (final raw in chapters) {
      if (raw is! Map) continue;
      final title = (raw['title'] as String?)?.trim() ?? '';
      final start = (raw['start'] as num?)?.toDouble() ?? 0.0;
      var end = (raw['end'] as num?)?.toDouble() ?? totalDuration;
      if (end <= 0 && totalDuration > 0) end = totalDuration;
      if (end <= start + 1.0) continue;

      final kind = classifyTitle(
        title,
        includeIntroOutro: includeIntroOutro,
        customKeywords: customKeywords,
      );
      if (kind != null) {
        out.add(
          SponsorSegment(start: start, end: end, label: title, kind: kind),
        );
      }
    }
    return out;
  }

  static List<SponsorSegment> extractFromDescription(
    String description, {
    double totalDuration = 0,
    bool includeIntroOutro = false,
    List<String> customKeywords = const [],
  }) {
    if (description.trim().isEmpty) return const [];
    final plain = _htmlToPlainLines(description);
    final lines = plain.split('\n');

    final explicitRanges = <SponsorSegment>[];
    final singleMarkers = <({double start, String label})>[];

    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;

      final rangeMatch = _rangeLineRegex.firstMatch(line);
      if (rangeMatch != null) {
        final start = parseTimestampSeconds(rangeMatch.group(1)!);
        final end = parseTimestampSeconds(rangeMatch.group(2)!);
        final label = rangeMatch.group(3)!.trim();
        if (start != null && end != null && end > start + 1.0) {
          final kind = classifyTitle(
            label,
            includeIntroOutro: includeIntroOutro,
            customKeywords: customKeywords,
          );
          if (kind != null) {
            explicitRanges.add(
              SponsorSegment(
                start: start,
                end: end,
                label: label,
                kind: kind,
              ),
            );
          }
          continue;
        }
      }

      final singleMatch = _singleTimestampLineRegex.firstMatch(line);
      if (singleMatch != null) {
        final start = parseTimestampSeconds(singleMatch.group(1)!);
        final label = singleMatch.group(2)!.trim();
        if (start != null && label.isNotEmpty) {
          singleMarkers.add((start: start, label: label));
        }
      }
    }

    final inferred = <SponsorSegment>[];
    if (singleMarkers.length >= 2) {
      singleMarkers.sort((a, b) => a.start.compareTo(b.start));
      for (int i = 0; i < singleMarkers.length; i++) {
        final cur = singleMarkers[i];
        double? end;
        if (i + 1 < singleMarkers.length) {
          final nextStart = singleMarkers[i + 1].start;
          if (nextStart > cur.start + 1.0) {
            end = nextStart;
          }
        } else if (totalDuration > cur.start + 1.0 &&
            totalDuration - cur.start <= 300) {
          end = totalDuration;
        }
        if (end == null) continue;

        final kind = classifyTitle(
          cur.label,
          includeIntroOutro: includeIntroOutro,
          customKeywords: customKeywords,
        );
        if (kind != null) {
          inferred.add(
            SponsorSegment(
              start: cur.start,
              end: end,
              label: cur.label,
              kind: kind,
            ),
          );
        }
      }
    }

    return [...explicitRanges, ...inferred];
  }

  static List<SponsorSegment> mergeSegments(List<SponsorSegment> segments) {
    if (segments.length <= 1) return List<SponsorSegment>.from(segments);
    final sorted = List<SponsorSegment>.from(segments)
      ..sort((a, b) => a.start.compareTo(b.start));
    final merged = <SponsorSegment>[sorted.first];
    for (int i = 1; i < sorted.length; i++) {
      final cur = sorted[i];
      final prev = merged.last;
      if (cur.start <= prev.end + 1.0) {
        final combinedEnd = cur.end > prev.end ? cur.end : prev.end;
        final combinedLabel =
            prev.label.toLowerCase() == cur.label.toLowerCase()
                ? prev.label
                : '${prev.label} / ${cur.label}';
        merged[merged.length - 1] = SponsorSegment(
          start: prev.start,
          end: combinedEnd,
          label: combinedLabel,
          kind: prev.kind,
        );
      } else {
        merged.add(cur);
      }
    }
    return merged;
  }

  static List<SponsorSegment> detectSegments({
    required List<dynamic> chapters,
    String? description,
    double totalDuration = 0,
    bool includeIntroOutro = false,
    List<String> customKeywords = const [],
  }) {
    final fromChapters = extractFromChapters(
      chapters,
      totalDuration: totalDuration,
      includeIntroOutro: includeIntroOutro,
      customKeywords: customKeywords,
    );
    if (fromChapters.isNotEmpty) {
      return mergeSegments(fromChapters);
    }
    if (description != null && description.trim().isNotEmpty) {
      final fromDesc = extractFromDescription(
        description,
        totalDuration: totalDuration,
        includeIntroOutro: includeIntroOutro,
        customKeywords: customKeywords,
      );
      return mergeSegments(fromDesc);
    }
    return const [];
  }

  static SponsorSegment? findSegmentAt(
    List<SponsorSegment> segments,
    double positionSeconds,
  ) {
    for (final seg in segments) {
      if (positionSeconds >= seg.start && positionSeconds < seg.end - 0.5) {
        return seg;
      }
    }
    return null;
  }

  // ── YouTube / SponsorBlock API support ──

  static const List<String> selectableSponsorBlockCategories = [
    'sponsor',
    'selfpromo',
    'interaction',
    'preview',
    'filler',
    'music_offtopic',
  ];

  static final RegExp _ytUrlRegex = RegExp(
    r'(?:youtube(?:-nocookie)?\.com/(?:watch\?(?:[^#\s]*&)?v=|live/|shorts/|embed/|v/)|youtu\.be/)([A-Za-z0-9_-]{11})(?![A-Za-z0-9_-])',
    caseSensitive: false,
  );

  static final RegExp _ytGuidRegex = RegExp(
    r'\byt:video:([A-Za-z0-9_-]{11})(?![A-Za-z0-9_-])',
    caseSensitive: false,
  );

  static final RegExp _ytBracketIdRegex = RegExp(
    r'\[([A-Za-z0-9_-]{11})\](?:\.[a-zA-Z0-9]{2,5})?(?:[/\s._-]|$)',
  );

  static final RegExp _ytBareIdRegex = RegExp(r'^[A-Za-z0-9_-]{11}$');

  static final Map<String, List<SponsorSegment>> _sponsorBlockCache = {};
  static final Map<String, String> _ytSearchCache = {};

  /// Clears the in-memory SponsorBlock and YouTube search caches (useful for tests).
  static void clearSponsorBlockCache() {
    _sponsorBlockCache.clear();
    _ytSearchCache.clear();
  }

  /// Extracts an 11-character YouTube video ID from a URL, `yt:video:` guid,
  /// or `yt-dlp`-style `[videoId]` filename, or returns `null` if none found.
  static String? extractYouTubeVideoId(
    String? text, {
    bool allowBracketId = false,
    bool allowBareId = false,
  }) {
    if (text == null) return null;
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;

    if (allowBareId && _ytBareIdRegex.hasMatch(trimmed)) {
      return trimmed;
    }

    final normalized = trimmed.replaceAll('&amp;', '&');
    final urlMatch = _ytUrlRegex.firstMatch(normalized);
    if (urlMatch != null) return urlMatch.group(1);

    final guidMatch = _ytGuidRegex.firstMatch(normalized);
    if (guidMatch != null) return guidMatch.group(1);

    if (allowBracketId) {
      final bracketMatch = _ytBracketIdRegex.firstMatch(normalized);
      if (bracketMatch != null) return bracketMatch.group(1);
    }
    return null;
  }

  /// Extracts a YouTube video ID from an Audiobookshelf podcast episode map.
  static String? extractYouTubeVideoIdFromEpisode(Map<dynamic, dynamic> episode) {
    final enclosure = episode['enclosure'];
    if (enclosure is Map) {
      final id = extractYouTubeVideoId(enclosure['url']?.toString());
      if (id != null) return id;
    }

    for (final key in const ['link', 'url', 'guid']) {
      final id = extractYouTubeVideoId(episode[key]?.toString());
      if (id != null) return id;
    }

    final audioFile = episode['audioFile'];
    if (audioFile is Map) {
      final metadata = audioFile['metadata'];
      if (metadata is Map) {
        for (final key in const ['filename', 'path']) {
          final id = extractYouTubeVideoId(
            metadata[key]?.toString(),
            allowBracketId: true,
          );
          if (id != null) return id;
        }
      }
      final metaTags = audioFile['metaTags'];
      if (metaTags is Map) {
        for (final val in metaTags.values) {
          final id = extractYouTubeVideoId(val?.toString());
          if (id != null) return id;
        }
      }
    }

    for (final key in const ['description', 'descriptionHtml', 'subtitle']) {
      final id = extractYouTubeVideoId(episode[key]?.toString());
      if (id != null) return id;
    }
    return null;
  }

  static String _sponsorBlockCategoryLabel(String category) {
    switch (category) {
      case 'sponsor':
        return 'Sponsor';
      case 'selfpromo':
        return 'Self-promotion';
      case 'interaction':
        return 'Interaction reminder';
      case 'intro':
        return 'Intro';
      case 'outro':
        return 'Outro';
      case 'preview':
        return 'Preview / Recap';
      case 'filler':
        return 'Filler';
      case 'music_offtopic':
        return 'Off-topic music';
      default:
        return 'Sponsor';
    }
  }

  static SponsorSegmentKind _sponsorBlockCategoryKind(String category) {
    switch (category) {
      case 'intro':
      case 'outro':
      case 'preview':
        return SponsorSegmentKind.introOutro;
      case 'filler':
      case 'music_offtopic':
        return SponsorSegmentKind.custom;
      case 'sponsor':
      case 'selfpromo':
      case 'interaction':
      default:
        return SponsorSegmentKind.sponsor;
    }
  }

  /// Parses the JSON response from SponsorBlock's `/api/skipSegments/<prefix>`
  /// (or `/api/skipSegments?videoID=...`) endpoint for [videoId].
  static List<SponsorSegment> parseSponsorBlockResponse(
    String body,
    String videoId,
  ) {
    if (body.trim().isEmpty) return const [];
    final decoded = jsonDecode(body);
    if (decoded is! List) return const [];

    final rawSegments = <dynamic>[];
    for (final item in decoded) {
      if (item is! Map) continue;
      if (item.containsKey('videoID') && item.containsKey('segments')) {
        if (item['videoID'] == videoId && item['segments'] is List) {
          rawSegments.addAll(item['segments'] as List);
        }
      } else if (item.containsKey('segment')) {
        rawSegments.add(item);
      }
    }

    final out = <SponsorSegment>[];
    for (final raw in rawSegments) {
      if (raw is! Map) continue;
      final actionType = raw['actionType']?.toString();
      if (actionType != null && actionType != 'skip') continue;

      final bounds = raw['segment'];
      if (bounds is! List || bounds.length < 2) continue;
      final start = (bounds[0] as num?)?.toDouble();
      final end = (bounds[1] as num?)?.toDouble();
      if (start == null || end == null || end <= start + 0.5) continue;

      final category = raw['category']?.toString() ?? 'sponsor';
      out.add(
        SponsorSegment(
          start: start,
          end: end,
          label: _sponsorBlockCategoryLabel(category),
          kind: _sponsorBlockCategoryKind(category),
        ),
      );
    }
    return mergeSegments(out);
  }

  /// Queries SponsorBlock's privacy-preserving hash-prefix API for [videoId].
  /// Returns an empty list on 404, network error, or timeout.
  static Future<List<SponsorSegment>> fetchSponsorBlockSegments(
    String videoId, {
    List<String> categories = PlayerSettings.defaultSponsorBlockCategories,
    bool includeIntroOutro = false,
    http.Client? client,
  }) async {
    final effectiveCats = <String>{
      ...categories.map((c) => c.trim()).where((c) => c.isNotEmpty),
      if (includeIntroOutro) ...const ['intro', 'outro'],
    }.toList()
      ..sort();

    if (effectiveCats.isEmpty) return const [];

    final cacheKey = '$videoId|${effectiveCats.join(',')}';
    if (client == null && _sponsorBlockCache.containsKey(cacheKey)) {
      return _sponsorBlockCache[cacheKey]!;
    }

    final hashPrefix =
        sha256.convert(utf8.encode(videoId)).toString().substring(0, 4);
    final uri = Uri.https(
      'sponsor.ajay.app',
      '/api/skipSegments/$hashPrefix',
      {'category': effectiveCats},
    );

    final httpClient = client ?? http.Client();
    try {
      final resp = await httpClient
          .get(
            uri,
            headers: const {'User-Agent': 'Absorb/1.0 (Podcast SponsorBlock)'},
          )
          .timeout(const Duration(seconds: 6));

      if (resp.statusCode == 404) {
        if (client == null) _cacheSponsorBlockResult(cacheKey, const []);
        return const [];
      }
      if (resp.statusCode != 200) {
        debugPrint(
          '[SponsorBlock] HTTP ${resp.statusCode} for $videoId ($hashPrefix)',
        );
        return const [];
      }

      final segments = parseSponsorBlockResponse(resp.body, videoId);
      if (client == null) _cacheSponsorBlockResult(cacheKey, segments);
      return segments;
    } catch (e) {
      debugPrint('[SponsorBlock] Failed to fetch segments for $videoId: $e');
      return const [];
    } finally {
      if (client == null) {
        httpClient.close();
      }
    }
  }

  static void _cacheSponsorBlockResult(
    String key,
    List<SponsorSegment> segments,
  ) {
    if (_sponsorBlockCache.length >= 200) {
      _sponsorBlockCache.remove(_sponsorBlockCache.keys.first);
    }
    _sponsorBlockCache[key] = segments;
  }

  /// Searches YouTube for a podcast episode when the episode metadata does not
  /// contain a YouTube URL/ID, matching by title and duration.
  static Future<String?> searchYouTubeVideoId({
    String? showTitle,
    required String episodeTitle,
    double expectedDurationSeconds = 0,
    http.Client? client,
  }) async {
    final cleanEpisode = episodeTitle.trim();
    if (cleanEpisode.isEmpty) return null;
    final cleanShow = showTitle?.trim() ?? '';
    final cacheKey = '$cleanShow|$cleanEpisode';
    if (client == null && _ytSearchCache.containsKey(cacheKey)) {
      final cached = _ytSearchCache[cacheKey]!;
      return cached.isEmpty ? null : cached;
    }

    final query = cleanShow.isNotEmpty ? '$cleanShow $cleanEpisode' : cleanEpisode;
    final uri = Uri.https('www.youtube.com', '/results', {
      'search_query': query,
      'hl': 'en',
    });

    final httpClient = client ?? http.Client();
    try {
      final resp = await httpClient
          .get(
            uri,
            headers: const {
              'User-Agent':
                  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
              'Accept-Language': 'en-US,en;q=0.9',
              'Cookie': 'CONSENT=YES+cb',
            },
          )
          .timeout(const Duration(seconds: 6));
      if (resp.statusCode != 200) {
        debugPrint('[SponsorBlock] YouTube search HTTP ${resp.statusCode}');
        return null;
      }
      final videoId = parseYouTubeSearchResponse(
        resp.body,
        episodeTitle: cleanEpisode,
        expectedDurationSeconds: expectedDurationSeconds,
      );
      if (client == null) {
        if (_ytSearchCache.length >= 200) {
          _ytSearchCache.remove(_ytSearchCache.keys.first);
        }
        _ytSearchCache[cacheKey] = videoId ?? '';
      }
      return videoId;
    } catch (e) {
      debugPrint('[SponsorBlock] YouTube search failed: $e');
      return null;
    } finally {
      if (client == null) {
        httpClient.close();
      }
    }
  }

  /// Parses YouTube search HTML (`ytInitialData`) and picks the best matching
  /// video ID for [episodeTitle] and optional [expectedDurationSeconds].
  static String? parseYouTubeSearchResponse(
    String html, {
    required String episodeTitle,
    double expectedDurationSeconds = 0,
  }) {
    final jsonStr = _extractYtInitialDataJson(html);
    if (jsonStr == null) return null;

    dynamic decoded;
    try {
      decoded = jsonDecode(jsonStr);
    } catch (_) {
      return null;
    }

    final renderers = <Map<String, dynamic>>[];
    _collectVideoRenderers(decoded, renderers);
    if (renderers.isEmpty) return null;

    final targetNorm = _normalizeForMatch(episodeTitle);
    final targetTokens = _significantTokens(episodeTitle);
    if (targetNorm.isEmpty || targetTokens.isEmpty) return null;

    String? bestId;
    double bestScore = 0.0;

    for (final r in renderers) {
      final videoId = r['videoId']?.toString();
      if (videoId == null || !_ytBareIdRegex.hasMatch(videoId)) continue;

      final titleText = _extractYtRunsText(r['title']);
      if (titleText == null || titleText.isEmpty) continue;

      final candNorm = _normalizeForMatch(titleText);
      final candTokens = _significantTokens(titleText).toSet();

      int overlap = 0;
      for (final t in targetTokens) {
        if (candTokens.contains(t)) overlap++;
      }
      final tokenRecall = overlap / targetTokens.length;
      final substringMatch =
          candNorm.contains(targetNorm) || targetNorm.contains(candNorm);
      if (!substringMatch &&
          (targetTokens.length >= 2 ? tokenRecall < 0.6 : tokenRecall < 1.0)) {
        continue;
      }

      double durationScore = 0.0;
      final lengthText = (r['lengthText'] is Map)
          ? (r['lengthText'] as Map)['simpleText']?.toString()
          : null;
      final candDur = _parseColonDuration(lengthText);
      if (expectedDurationSeconds > 60 && candDur != null && candDur > 0) {
        final diff = (candDur - expectedDurationSeconds).abs();
        if (diff > 300 && diff > expectedDurationSeconds * 0.25) {
          // Likely a short clip/highlight rather than the full episode.
          continue;
        }
        if (diff <= 120) {
          durationScore = 0.35;
        } else {
          durationScore = 0.15;
        }
      }

      final score =
          (substringMatch ? 1.0 : tokenRecall) + durationScore;
      if (score > bestScore) {
        bestScore = score;
        bestId = videoId;
      }
    }

    return bestId;
  }

  static String? _extractYtInitialDataJson(String html) {
    const markers = ['var ytInitialData = ', 'window["ytInitialData"] = '];
    int startIdx = -1;
    for (final m in markers) {
      final idx = html.indexOf(m);
      if (idx != -1) {
        startIdx = idx + m.length;
        break;
      }
    }
    if (startIdx == -1) return null;
    while (startIdx < html.length && html[startIdx] != '{') {
      if (html[startIdx].trim().isNotEmpty) return null;
      startIdx++;
    }
    if (startIdx >= html.length) return null;

    int depth = 0;
    bool inString = false;
    bool escaped = false;
    for (int i = startIdx; i < html.length; i++) {
      final ch = html.codeUnitAt(i);
      if (escaped) {
        escaped = false;
        continue;
      }
      if (ch == 92 /* \ */ && inString) {
        escaped = true;
        continue;
      }
      if (ch == 34 /* " */) {
        inString = !inString;
        continue;
      }
      if (!inString) {
        if (ch == 123 /* { */) {
          depth++;
        } else if (ch == 125 /* } */) {
          depth--;
          if (depth == 0) {
            return html.substring(startIdx, i + 1);
          }
        }
      }
    }
    return null;
  }

  static void _collectVideoRenderers(
    dynamic node,
    List<Map<String, dynamic>> out,
  ) {
    if (out.length >= 15) return;
    if (node is Map) {
      final vr = node['videoRenderer'];
      if (vr is Map<String, dynamic>) {
        out.add(vr);
      } else {
        for (final val in node.values) {
          _collectVideoRenderers(val, out);
          if (out.length >= 15) return;
        }
      }
    } else if (node is List) {
      for (final item in node) {
        _collectVideoRenderers(item, out);
        if (out.length >= 15) return;
      }
    }
  }

  static String? _extractYtRunsText(dynamic titleNode) {
    if (titleNode is Map) {
      final simple = titleNode['simpleText']?.toString();
      if (simple != null && simple.isNotEmpty) return simple;
      final runs = titleNode['runs'];
      if (runs is List) {
        return runs
            .whereType<Map>()
            .map((r) => r['text']?.toString() ?? '')
            .join();
      }
    }
    return null;
  }

  static double? _parseColonDuration(String? text) {
    if (text == null || text.trim().isEmpty) return null;
    final parts = text.trim().split(':');
    if (parts.length < 2 || parts.length > 3) return null;
    final nums = parts.map((p) => int.tryParse(p.trim())).toList();
    if (nums.any((n) => n == null)) return null;
    if (nums.length == 2) {
      return nums[0]! * 60.0 + nums[1]!;
    }
    return nums[0]! * 3600.0 + nums[1]! * 60.0 + nums[2]!;
  }

  static String _normalizeForMatch(String input) => input
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  static const Set<String> _stopWords = {
    'the',
    'and',
    'for',
    'with',
    'from',
    'this',
    'that',
    'episode',
    'ep',
    'podcast',
  };

  static List<String> _significantTokens(String input) {
    final norm = _normalizeForMatch(input);
    final all = norm.split(' ').where((w) => w.length >= 2).toList();
    final filtered = all.where((w) => !_stopWords.contains(w)).toList();
    return filtered.isNotEmpty ? filtered : all;
  }
}
