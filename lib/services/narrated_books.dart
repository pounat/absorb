import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Audiobookshelf books whose EPUB reads itself aloud, as found on this
/// phone (the server only sees an ebook), and the EPUBs looked into that
/// don't. Held in memory so the quick "is this ebook only" checks can count
/// them as audiobooks, and the detail sheet knows straight away which
/// buttons a book gets. Item ids are unique across servers, so one list
/// serves every account.
/// Whether [item] has an EPUB that reads itself aloud: BookOrbit says so in
/// its book lists, an Audiobookshelf book once its EPUB has been looked at.
bool hasReadAlongEbook(Map<String, dynamic>? item) {
  if (item == null) return false;
  final bookOrbit = item['bookOrbit'];
  if (bookOrbit is Map && bookOrbit['readAlong'] == true) return true;
  if ((item['media'] as Map?)?['narration'] != null) return true;
  final id = item['id'];
  return id is String && NarratedBooks.contains(id);
}

class NarratedBooks {
  NarratedBooks._();

  static const _key = 'narrated_books';
  static const _plainKey = 'plain_epubs';
  static final Map<String, double> _durations = {};
  static final Set<String> _plain = {};
  static Future<void>? _loading;

  static Future<void> load() => _loading ??= _load();

  static Future<void> _load() async {
    try {
      final raw = (await SharedPreferences.getInstance()).getString(_key);
      if (raw == null) return;
      (jsonDecode(raw) as Map<String, dynamic>).forEach((id, d) {
        if (d is num && d > 0) _durations[id] = d.toDouble();
      });
    } catch (e) {
      debugPrint('[Narration] reading the narrated books failed: $e');
    }
    try {
      _plain.addAll((await SharedPreferences.getInstance()).getStringList(_plainKey) ?? const []);
    } catch (e) {
      debugPrint('[Narration] reading the narrated books failed: $e');
    }
  }

  static bool contains(Object? itemId) => itemId is String && _durations.containsKey(itemId);

  /// Whether this phone has looked into [itemId]'s EPUB, either way.
  static bool checked(Object? itemId) => itemId is String && (_durations.containsKey(itemId) || _plain.contains(itemId));

  static double? duration(String itemId) => _durations[itemId];

  /// Notes [itemId] as narrated with [duration] seconds, or as not narrated.
  static Future<void> set(String itemId, double? duration) async {
    await load();
    if (duration != null && duration > 0) {
      if (_durations[itemId] == duration) return;
      _durations[itemId] = duration;
      _plain.remove(itemId);
    } else {
      final dropped = _durations.remove(itemId) != null;
      if (!_plain.add(itemId) && !dropped) return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode(_durations));
      await prefs.setStringList(_plainKey, _plain.toList());
    } catch (e) {
      debugPrint('[Narration] saving the narrated books failed: $e');
    }
  }

  @visibleForTesting
  static void debugSet(Map<String, double> durations) {
    _loading = Future.value();
    _plain.clear();
    _durations
      ..clear()
      ..addAll(durations);
  }
}
