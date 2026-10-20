import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'scoped_prefs.dart';

/// Why a spot was kept.
enum EbookSpotReason { closed, beforeJump, beforeSync }

/// A page the reader was on.
class EbookSpot {
  const EbookSpot({
    required this.cfi,
    required this.reason,
    required this.at,
    this.progress,
    this.chapter,
  });

  final String cfi;
  final EbookSpotReason reason;
  final DateTime at;
  final double? progress;
  final String? chapter;

  Map<String, dynamic> toJson() => {
        'cfi': cfi,
        'r': reason.name,
        'at': at.millisecondsSinceEpoch,
        if (progress != null) 'p': progress,
        if (chapter != null) 'c': chapter,
      };

  static EbookSpot? fromJson(Map<String, dynamic> j) {
    final cfi = j['cfi'], at = j['at'];
    if (cfi is! String || at is! num) return null;
    return EbookSpot(
      cfi: cfi,
      reason: EbookSpotReason.values.firstWhere((r) => r.name == j['r'], orElse: () => EbookSpotReason.closed),
      at: DateTime.fromMillisecondsSinceEpoch(at.toInt()),
      progress: (j['p'] as num?)?.toDouble(),
      chapter: j['c'] as String?,
    );
  }
}

/// Pages the reader was on, kept on this phone for each book: where it was
/// closed, and where it was before every jump (a chapter, a search hit, a
/// sync to the audio). A way back when the place gets lost.
class EbookHistory {
  EbookHistory._();
  static final EbookHistory instance = EbookHistory._();

  static const _max = 100;

  static String _key(String itemId) => 'ebook_history_$itemId';

  Future<void> record(
    String itemId, {
    required String cfi,
    required EbookSpotReason reason,
    double? progress,
    String? chapter,
  }) async {
    if (!cfi.startsWith('epubcfi(')) return;
    try {
      final list = await ScopedPrefs.getStringList(_key(itemId));
      if (list.isNotEmpty) {
        final last = EbookSpot.fromJson(jsonDecode(list.last) as Map<String, dynamic>);
        if (last?.cfi == cfi) return;
      }
      final title = chapter?.trim();
      list.add(jsonEncode(EbookSpot(
        cfi: cfi,
        reason: reason,
        at: DateTime.now(),
        progress: progress,
        chapter: title == null || title.isEmpty ? null : title,
      ).toJson()));
      if (list.length > _max) list.removeRange(0, list.length - _max);
      await ScopedPrefs.setStringList(_key(itemId), list);
      debugPrint('[EbookHistory] $itemId: kept ${reason.name} at '
          '${progress == null ? '?' : '${(progress * 100).toStringAsFixed(1)}%'}${title == null ? '' : ' ($title)'}');
    } catch (e) {
      debugPrint('[EbookHistory] keeping a spot for $itemId failed: $e');
    }
  }

  /// The kept spots, newest first.
  Future<List<EbookSpot>> spots(String itemId) async {
    final out = <EbookSpot>[];
    for (final raw in (await ScopedPrefs.getStringList(_key(itemId))).reversed) {
      try {
        final s = EbookSpot.fromJson(jsonDecode(raw) as Map<String, dynamic>);
        if (s != null) out.add(s);
      } catch (_) {}
    }
    return out;
  }
}
