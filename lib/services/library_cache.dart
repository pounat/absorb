import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'scoped_prefs.dart';

class LibraryCache {
  static const _key = 'cached_libraries';

  static Future<void> save(List<dynamic> libraries) async {
    try {
      await ScopedPrefs.setString(_key, jsonEncode(_sanitize(libraries)));
    } catch (e) {
      debugPrint('[LibraryCache] Failed to save libraries: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> load() async {
    try {
      return decode(await ScopedPrefs.getString(_key));
    } catch (e) {
      debugPrint('[LibraryCache] Failed to load libraries: $e');
      return [];
    }
  }

  @visibleForTesting
  static List<Map<String, dynamic>> decode(String? value) {
    if (value == null || value.isEmpty) return [];
    try {
      final decoded = jsonDecode(value);
      if (decoded is! List<dynamic>) return [];
      return _sanitize(decoded);
    } catch (_) {
      return [];
    }
  }

  static List<Map<String, dynamic>> _sanitize(Iterable<dynamic> libraries) {
    final sanitized = <Map<String, dynamic>>[];
    for (final library in libraries) {
      if (library is! Map) continue;
      final id = library['id'];
      if (id is! String || id.isEmpty) continue;
      final name = library['name'];
      final mediaType = library['mediaType'];
      sanitized.add({
        'id': id,
        'name': name is String && name.isNotEmpty ? name : 'Library',
        'mediaType': mediaType is String && mediaType.isNotEmpty
            ? mediaType
            : 'book',
      });
    }
    return sanitized;
  }
}
