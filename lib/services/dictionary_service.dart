import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

/// The platform's own dictionary UI: UIReferenceLibraryViewController on iOS
/// (offline, the user's own dictionaries, any language), the system DEFINE
/// action / text-processing chooser on Android. Returns false when the
/// platform had nothing to show, so the caller can fall back to the in-app
/// lookup sheet.
class NativeDictionary {
  static const _channel = MethodChannel('com.absorb.equalizer');

  static Future<bool> define(String word) async {
    try {
      final ok = await _channel.invokeMethod<bool>('defineWord', {'word': word});
      return ok ?? false;
    } catch (e) {
      debugPrint('[Dictionary] native define failed: $e');
      return false;
    }
  }
}

enum DictionaryStatus { found, notFound, error }

class DictionaryDefinition {
  final String definition;
  final String? example;
  const DictionaryDefinition(this.definition, this.example);
}

class DictionaryMeaning {
  final String partOfSpeech;
  final List<DictionaryDefinition> definitions;
  final List<String> synonyms;
  const DictionaryMeaning(this.partOfSpeech, this.definitions, this.synonyms);
}

class DictionaryResult {
  final DictionaryStatus status;
  final String word;
  final String? phonetic;
  final List<DictionaryMeaning> meanings;
  const DictionaryResult(this.status, this.word,
      {this.phonetic, this.meanings = const []});
}

/// Word lookups against the free dictionaryapi.dev endpoint (English), so a
/// definition opens in an in-app sheet instead of bouncing to a browser.
class DictionaryService {
  static Future<DictionaryResult> lookup(String word) async {
    final clean = word.trim().toLowerCase();
    try {
      final resp = await http
          .get(Uri.parse(
              'https://api.dictionaryapi.dev/api/v2/entries/en/${Uri.encodeComponent(clean)}'))
          .timeout(const Duration(seconds: 8));
      if (resp.statusCode == 404) {
        return DictionaryResult(DictionaryStatus.notFound, clean);
      }
      if (resp.statusCode != 200) {
        return DictionaryResult(DictionaryStatus.error, clean);
      }
      final data = jsonDecode(resp.body);
      if (data is! List || data.isEmpty) {
        return DictionaryResult(DictionaryStatus.notFound, clean);
      }

      String? phonetic;
      final meanings = <DictionaryMeaning>[];
      for (final entry in data.whereType<Map<String, dynamic>>()) {
        phonetic ??= (entry['phonetic'] as String?)?.trim();
        if (phonetic == null || phonetic.isEmpty) {
          final phonetics =
              (entry['phonetics'] as List<dynamic>? ?? const [])
                  .whereType<Map<String, dynamic>>();
          for (final p in phonetics) {
            final t = (p['text'] as String?)?.trim();
            if (t != null && t.isNotEmpty) {
              phonetic = t;
              break;
            }
          }
        }
        for (final m in (entry['meanings'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()) {
          final defs = <DictionaryDefinition>[];
          for (final d in (m['definitions'] as List<dynamic>? ?? const [])
              .whereType<Map<String, dynamic>>()) {
            final text = (d['definition'] as String?)?.trim();
            if (text == null || text.isEmpty) continue;
            defs.add(DictionaryDefinition(
                text, (d['example'] as String?)?.trim()));
          }
          if (defs.isEmpty) continue;
          final synonyms = (m['synonyms'] as List<dynamic>? ?? const [])
              .whereType<String>()
              .where((s) => s.trim().isNotEmpty)
              .take(8)
              .toList();
          meanings.add(DictionaryMeaning(
              (m['partOfSpeech'] as String?) ?? '', defs, synonyms));
        }
      }
      if (meanings.isEmpty) {
        return DictionaryResult(DictionaryStatus.notFound, clean);
      }
      return DictionaryResult(DictionaryStatus.found, clean,
          phonetic: phonetic, meanings: meanings);
    } catch (e) {
      debugPrint('[Dictionary] lookup failed for "$clean": $e');
      return DictionaryResult(DictionaryStatus.error, clean);
    }
  }
}
