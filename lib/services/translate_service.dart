import 'dart:async';
import 'dart:io';
import 'dart:ui' show Locale, PlatformDispatcher;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'player_settings.dart';

enum TranslatorKind { app, apple, web }

class Translator {
  final String id;
  final String label;
  final TranslatorKind kind;
  const Translator(this.id, this.label, this.kind);
}

/// Sends a reader selection to a translator: an installed translation app on
/// Android (Google Translate shows its card over the book), Apple's
/// translation sheet on iOS 17.4+, or Google Translate / DeepL on the web.
class TranslateService {
  static const google = 'google';
  static const deepl = 'deepl';
  static const apple = 'apple';
  static const _appPrefix = 'app:';
  static const _maxWebChars = 2000;

  static const _channel = MethodChannel('com.absorb.equalizer');
  @visibleForTesting
  static ProcessTextService processText = DefaultProcessTextService();
  @visibleForTesting
  static bool? appleOverride;

  static final _translatorApp = RegExp(r'translat|deepl|papago|reverso', caseSensitive: false);

  static bool get _apple => appleOverride ?? Platform.isIOS;

  static Future<List<Translator>> available() async {
    final apps = <Translator>[];
    for (final a in await processText.queryTextActions()) {
      if (!_translatorApp.hasMatch('${a.id} ${a.label}')) continue;
      apps.add(Translator('$_appPrefix${a.id}', a.label, TranslatorKind.app));
    }
    apps.sort((a, b) {
      final ga = a.id.contains('com.google.android.apps.translate') ? 0 : 1;
      final gb = b.id.contains('com.google.android.apps.translate') ? 0 : 1;
      return ga != gb ? ga - gb : a.label.toLowerCase().compareTo(b.label.toLowerCase());
    });
    return [
      ...apps,
      if (_apple) const Translator(apple, 'Apple Translate', TranslatorKind.apple),
      const Translator(google, 'Google Translate', TranslatorKind.web),
      const Translator(deepl, 'DeepL', TranslatorKind.web),
    ];
  }

  /// The saved choice if this device still has it, otherwise the first one.
  static Translator pick(List<Translator> options, String saved) =>
      options.firstWhere((t) => t.id == saved, orElse: () => options.first);

  static Future<void> translate(String text) async {
    text = text.trim();
    if (text.isEmpty) return;
    final choice = pick(await available(), await PlayerSettings.getEreaderTranslateWith());
    switch (choice.kind) {
      case TranslatorKind.app:
        // Completes when the translator closes; there is nothing to wait for.
        unawaited(processText
            .processTextAction(choice.id.substring(_appPrefix.length), text, true)
            .then((_) {}, onError: (Object e) {
          debugPrint('[Translate] ${choice.id} failed: $e');
          _openWeb(google, text);
        }));
      case TranslatorKind.apple:
        bool shown = false;
        try {
          shown = await _channel.invokeMethod<bool>('translateText', {'text': text}) ?? false;
        } catch (e) {
          debugPrint('[Translate] Apple translation failed: $e');
        }
        if (!shown) await _openWeb(google, text);
      case TranslatorKind.web:
        await _openWeb(choice.id, text);
    }
  }

  static Future<void> _openWeb(String service, String text) =>
      launchUrl(webUrl(service, text, PlatformDispatcher.instance.locale), mode: LaunchMode.externalApplication);

  @visibleForTesting
  static Uri webUrl(String service, String text, Locale into) {
    if (text.length > _maxWebChars) text = text.substring(0, _maxWebChars);
    final lang = into.languageCode.toLowerCase();
    if (service == deepl) {
      // DeepL reads source/target/text from the fragment and treats a bare
      // slash as a separator, so slashes in the text are escaped its own way.
      final to = lang == 'no' ? 'nb' : lang;
      return Uri.parse('https://www.deepl.com/translator#auto/$to/${Uri.encodeComponent(text.replaceAll('/', r'\/'))}');
    }
    final traditional = into.scriptCode == 'Hant' || const {'TW', 'HK', 'MO'}.contains(into.countryCode);
    final to = lang == 'zh' ? (traditional ? 'zh-TW' : 'zh-CN') : lang;
    return Uri.https('translate.google.com', '/', {'sl': 'auto', 'tl': to, 'text': text, 'op': 'translate'});
  }
}
