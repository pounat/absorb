import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

/// iOS only: present the system dictionary (UIReferenceLibraryViewController -
/// offline, the user's own downloaded dictionaries, any language). Android has
/// no equivalent (the DEFINE intent just bounces into the Google app), so it
/// returns false there and the caller shows the in-app Wiktionary sheet.
class NativeDictionary {
  static const _channel = MethodChannel('com.absorb.equalizer');

  static Future<bool> define(String word) async {
    if (!Platform.isIOS) return false;
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
  /// Display name of the word's language section ("German", "French"), so a
  /// foreign word's entry can be labeled. Null/"English" renders unlabeled.
  final String? language;
  const DictionaryMeaning(this.partOfSpeech, this.definitions, this.synonyms,
      {this.language});
}

class DictionaryResult {
  final DictionaryStatus status;
  final String word;
  final String? phonetic;
  final List<DictionaryMeaning> meanings;
  const DictionaryResult(this.status, this.word,
      {this.phonetic, this.meanings = const []});
}

/// Word lookups against Wiktionary's definition API, so a definition opens in
/// an in-app sheet instead of bouncing to a browser or the Google app. Covers
/// words in most languages (definitions written in English); the exact
/// capitalization is tried first (German nouns), lowercase second.
class DictionaryService {
  static Future<DictionaryResult> lookup(String word) async {
    final clean = word.trim();
    final result = await _fetch(clean);
    if (result.status == DictionaryStatus.notFound &&
        clean != clean.toLowerCase()) {
      final lower = await _fetch(clean.toLowerCase());
      if (lower.status == DictionaryStatus.found) return lower;
    }
    return result;
  }

  static Future<DictionaryResult> _fetch(String word) async {
    try {
      final resp = await http.get(
        Uri.parse(
            'https://en.wiktionary.org/api/rest_v1/page/definition/${Uri.encodeComponent(word)}'),
        headers: const {'User-Agent': 'Absorb audiobook app'},
      ).timeout(const Duration(seconds: 8));
      if (resp.statusCode == 404) {
        return DictionaryResult(DictionaryStatus.notFound, word);
      }
      if (resp.statusCode != 200) {
        return DictionaryResult(DictionaryStatus.error, word);
      }
      final data = jsonDecode(resp.body);
      if (data is! Map<String, dynamic> || data.isEmpty) {
        return DictionaryResult(DictionaryStatus.notFound, word);
      }

      // English section first, other languages after in response order.
      final keys = [
        if (data.containsKey('en')) 'en',
        ...data.keys.where((k) => k != 'en'),
      ];
      final meanings = <DictionaryMeaning>[];
      for (final key in keys) {
        final section = data[key];
        if (section is! List) continue;
        for (final entry in section.whereType<Map<String, dynamic>>()) {
          final language = (entry['language'] as String?)?.trim();
          final defs = <DictionaryDefinition>[];
          for (final d in (entry['definitions'] as List<dynamic>? ?? const [])
              .whereType<Map<String, dynamic>>()) {
            final text = _stripHtml((d['definition'] as String?) ?? '');
            if (text.isEmpty) continue;
            String? example;
            final parsed = (d['parsedExamples'] as List<dynamic>? ?? const [])
                .whereType<Map<String, dynamic>>();
            for (final p in parsed) {
              final e = _stripHtml((p['example'] as String?) ?? '');
              if (e.isNotEmpty) {
                example = e;
                break;
              }
            }
            example ??= (d['examples'] as List<dynamic>? ?? const [])
                .whereType<String>()
                .map(_stripHtml)
                .where((e) => e.isNotEmpty)
                .firstOrNull;
            defs.add(DictionaryDefinition(text, example));
          }
          if (defs.isEmpty) continue;
          meanings.add(DictionaryMeaning(
              (entry['partOfSpeech'] as String?) ?? '', defs, const [],
              language: language));
        }
      }
      if (meanings.isEmpty) {
        return DictionaryResult(DictionaryStatus.notFound, word);
      }
      return DictionaryResult(DictionaryStatus.found, word,
          meanings: meanings);
    } catch (e) {
      debugPrint('[Dictionary] lookup failed for "$word": $e');
      return DictionaryResult(DictionaryStatus.error, word);
    }
  }

  static String _stripHtml(String s) => s
      .replaceAll(RegExp(r'<[^>]*>'), '')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&#39;', "'")
      .replaceAll('&quot;', '"')
      .replaceAll('&nbsp;', ' ')
      .trim();
}
