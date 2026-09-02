import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/app_localizations.dart';

/// Lightweight HTML-to-RichText widget with clickable links.
///
/// Handles common podcast/book description HTML:
/// - `<a href>` → tappable links
/// - `<b>`, `<strong>` → bold
/// - `<i>`, `<em>` → italic
/// - `<br>` → line break, `<p>` → paragraph break (blank line between)
/// - Bare URLs → tappable links
/// - HTML entities → decoded
///
/// With [maxLines] set it truncates and offers a "Show more / Show less"
/// toggle; null shows the whole thing with no toggle.
class HtmlDescription extends StatefulWidget {
  final String html;
  final int? maxLines;
  final TextStyle? style;
  final Color? linkColor;

  const HtmlDescription({
    super.key,
    required this.html,
    this.maxLines = 4,
    this.style,
    this.linkColor,
  });

  @override
  State<HtmlDescription> createState() => _HtmlDescriptionState();
}

class _HtmlDescriptionState extends State<HtmlDescription> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    final baseStyle = widget.style ?? Theme.of(context).textTheme.bodySmall?.copyWith(
      color: cs.onSurface.withValues(alpha: 0.7), height: 1.5);
    final linkColor = widget.linkColor ?? cs.primary;

    final spans = _parseHtml(widget.html, baseStyle ?? const TextStyle(), linkColor);
    final textSpan = TextSpan(children: spans);
    final maxLines = widget.maxLines;
    if (maxLines == null) return Text.rich(textSpan);

    return LayoutBuilder(builder: (context, constraints) {
      // Measure whether the text actually overflows at maxLines
      final tp = TextPainter(
        text: textSpan,
        maxLines: maxLines,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: constraints.maxWidth);
      final isTruncated = tp.didExceedMaxLines;
      tp.dispose();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            textSpan,
            maxLines: _expanded ? null : maxLines,
            overflow: _expanded ? TextOverflow.clip : TextOverflow.ellipsis,
          ),
          if (isTruncated)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: GestureDetector(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Text(
                  _expanded ? l.showLess : l.showMore,
                  style: TextStyle(fontSize: 12, color: linkColor, fontWeight: FontWeight.w500),
                ),
              ),
            ),
        ],
      );
    });
  }
}

// ─── HTML Parsing ──────────────────────────────────────────

/// Regex for bare URLs not already inside an <a> tag.
final _bareUrlRegex = RegExp(
  r'https?://[^\s<>\])"]+',
  caseSensitive: false,
);

/// Parse HTML string into a list of styled TextSpans.
List<InlineSpan> _parseHtml(String html, TextStyle baseStyle, Color linkColor) {
  // Pre-process: convert block elements to newlines. A closing paragraph
  // becomes a blank line, the way a browser spaces <p> blocks - one newline
  // ran every paragraph straight into the next. CR/LF from descriptions
  // typed on Windows is normalised first so it counts as a plain newline.
  var text = html
      .replaceAll('\r\n', '\n')
      .replaceAll('\r', '\n')
      .replaceAll(RegExp(r'<br\s*/?>'), '\n')
      .replaceAll(RegExp(r'</p>'), '\n\n')
      .replaceAll(RegExp(r'<p[^>]*>'), '')
      .replaceAll(RegExp(r'</div>'), '\n')
      .replaceAll(RegExp(r'<div[^>]*>'), '')
      .replaceAll(RegExp(r'</?ul[^>]*>'), '\n')
      .replaceAll(RegExp(r'</?ol[^>]*>'), '\n')
      .replaceAll(RegExp(r'<li[^>]*>'), '  \u2022 ')
      .replaceAll(RegExp(r'</li>'), '\n')
      .replaceAll(RegExp(r'\n{3,}'), '\n\n'); // collapse excess newlines

  final spans = <InlineSpan>[];
  final tagPattern = RegExp(
    r'<(/?)(a|b|strong|i|em)(\s[^>]*)?>',
    caseSensitive: false,
  );

  var bold = false;
  var italic = false;
  String? linkUrl;
  var pos = 0;

  for (final match in tagPattern.allMatches(text)) {
    // Add text before this tag
    if (match.start > pos) {
      final segment = text.substring(pos, match.start);
      spans.addAll(_textWithLinks(
        _decodeEntities(segment),
        _buildStyle(baseStyle, bold, italic, linkUrl != null, linkColor),
        linkColor,
        linkUrl,
      ));
    }
    pos = match.end;

    final isClosing = match.group(1) == '/';
    final tag = match.group(2)!.toLowerCase();

    switch (tag) {
      case 'a':
        if (isClosing) {
          linkUrl = null;
        } else {
          final attrs = match.group(3) ?? '';
          final hrefMatch = RegExp(r'href\s*=\s*"([^"]*)"').firstMatch(attrs) ??
              RegExp(r"href\s*=\s*'([^']*)'").firstMatch(attrs);
          linkUrl = hrefMatch?.group(1);
        }
        break;
      case 'b':
      case 'strong':
        bold = !isClosing;
        break;
      case 'i':
      case 'em':
        italic = !isClosing;
        break;
    }
  }

  // Add remaining text after last tag
  if (pos < text.length) {
    final segment = text.substring(pos);
    // Strip any remaining unknown tags
    final cleaned = segment.replaceAll(RegExp(r'<[^>]+>'), '');
    spans.addAll(_textWithLinks(
      _decodeEntities(cleaned),
      _buildStyle(baseStyle, bold, italic, linkUrl != null, linkColor),
      linkColor,
      linkUrl,
    ));
  }

  // Trim leading newlines (an empty opening paragraph would otherwise start
  // the text with a blank line)
  while (spans.isNotEmpty) {
    final first = spans.first;
    if (first is TextSpan && first.text != null) {
      final trimmed = first.text!.replaceAll(RegExp(r'^\n+'), '');
      if (trimmed.isEmpty) {
        spans.removeAt(0);
      } else {
        spans[0] = TextSpan(
          text: trimmed,
          style: first.style,
          recognizer: first.recognizer,
        );
        break;
      }
    } else {
      break;
    }
  }

  // Trim trailing newlines
  while (spans.isNotEmpty) {
    final last = spans.last;
    if (last is TextSpan && last.text != null) {
      final trimmed = last.text!.replaceAll(RegExp(r'\n+$'), '');
      if (trimmed.isEmpty) {
        spans.removeLast();
      } else {
        spans[spans.length - 1] = TextSpan(
          text: trimmed,
          style: last.style,
          recognizer: last.recognizer,
        );
        break;
      }
    } else {
      break;
    }
  }

  return spans;
}

TextStyle _buildStyle(TextStyle base, bool bold, bool italic, bool isLink, Color linkColor) {
  var style = base;
  if (bold) style = style.copyWith(fontWeight: FontWeight.w600);
  if (italic) style = style.copyWith(fontStyle: FontStyle.italic);
  if (isLink) style = style.copyWith(color: linkColor, decoration: TextDecoration.underline, decorationColor: linkColor.withValues(alpha: 0.4));
  return style;
}

/// Split text into plain segments and bare-URL segments, making URLs tappable.
List<InlineSpan> _textWithLinks(String text, TextStyle style, Color linkColor, String? explicitUrl) {
  if (explicitUrl != null) {
    // Entire segment is inside an <a> tag
    return [_tappableSpan(text, style, explicitUrl)];
  }

  // Detect bare URLs
  final spans = <InlineSpan>[];
  var pos = 0;
  for (final match in _bareUrlRegex.allMatches(text)) {
    if (match.start > pos) {
      spans.add(TextSpan(text: text.substring(pos, match.start), style: style));
    }
    final url = match.group(0)!;
    final linkStyle = style.copyWith(
      color: linkColor,
      decoration: TextDecoration.underline,
      decorationColor: linkColor.withValues(alpha: 0.4),
    );
    spans.add(_tappableSpan(url, linkStyle, url));
    pos = match.end;
  }
  if (pos < text.length) {
    spans.add(TextSpan(text: text.substring(pos), style: style));
  }
  return spans;
}

TextSpan _tappableSpan(String text, TextStyle style, String url) {
  return TextSpan(
    text: text,
    style: style,
    recognizer: TapGestureRecognizer()
      ..onTap = () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
  );
}

String _decodeEntities(String text) {
  return text
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&apos;', "'")
      .replaceAll('&#x27;', "'")
      .replaceAll('&mdash;', '\u2014')
      .replaceAll('&ndash;', '\u2013')
      .replaceAll('&hellip;', '\u2026')
      .replaceAll('&laquo;', '\u00AB')
      .replaceAll('&raquo;', '\u00BB');
}

