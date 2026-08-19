import 'dart:io';
import 'dart:math' show min;
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/app_localizations.dart';
import '../providers/library_provider.dart';
import 'adaptive_modal.dart';
import 'overlay_toast.dart';

/// Card shapes offered for a shared quote, as width/height.
enum _QuoteShape {
  portrait(4 / 5),
  square(1),
  story(9 / 16);

  final double ratio;
  const _QuoteShape(this.ratio);
}

/// What sits between the cover and the text.
enum _QuoteBackdrop { blur, dim, none }

/// Which way the text (and the veil under it) leans, so the quote stays
/// readable on both pale and dark covers.
enum _QuoteTone { light, dark }

/// Opens the share sheet for a quote: the text laid over the book's cover,
/// exported as a PNG through the system share sheet.
Future<void> showQuoteShareSheet(
  BuildContext context, {
  required String itemId,
  required String quote,
  String? bookTitle,
  String? author,
  String? chapter,
}) {
  final text = quote.trim();
  if (text.isEmpty) return Future.value();
  final lib = context.read<LibraryProvider>();
  final coverUrl = lib.getCoverUrl(itemId, width: 800);
  final headers = lib.mediaHeaders;
  return showAdaptiveActionMenu<void>(
    context: context,
    isScrollControlled: true,
    // The sheet scrolls itself, so the desktop surface must not wrap it in a
    // second scroll view - the preview would land in unbounded height.
    desktopScrollWrap: false,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).bottomSheetTheme.backgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => _QuoteShareSheet(
      quote: text,
      coverUrl: coverUrl,
      mediaHeaders: headers,
      bookTitle: bookTitle,
      author: author,
      chapter: chapter,
    ),
  );
}

class _QuoteShareSheet extends StatefulWidget {
  final String quote;
  final String? coverUrl;
  final Map<String, String> mediaHeaders;
  final String? bookTitle;
  final String? author;
  final String? chapter;

  const _QuoteShareSheet({
    required this.quote,
    required this.coverUrl,
    required this.mediaHeaders,
    this.bookTitle,
    this.author,
    this.chapter,
  });

  @override
  State<_QuoteShareSheet> createState() => _QuoteShareSheetState();
}

class _QuoteShareSheetState extends State<_QuoteShareSheet> {
  final _cardKey = GlobalKey();
  late final TextEditingController _titleController;
  late final TextEditingController _detailController;
  _QuoteShape _shape = _QuoteShape.portrait;
  _QuoteBackdrop _backdrop = _QuoteBackdrop.blur;
  _QuoteTone _tone = _QuoteTone.light;
  bool _busy = false;
  ImageProvider? _cover;
  // The export captures whatever the preview is showing, so hold the share
  // action until the cover has actually decoded.
  bool _coverSettled = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.bookTitle ?? '');
    // Seeded with what we know, then it's the user's line: a chapter, a page,
    // whoever said it.
    _detailController = TextEditingController(
      text: [
        if ((widget.author ?? '').isNotEmpty) widget.author!,
        if ((widget.chapter ?? '').isNotEmpty) widget.chapter!,
      ].join(', '),
    );
    _prepareCover();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _detailController.dispose();
    super.dispose();
  }

  Future<void> _prepareCover() async {
    final url = widget.coverUrl;
    if (url == null || url.isEmpty) {
      setState(() => _coverSettled = true);
      return;
    }
    ImageProvider? provider;
    if (url.startsWith('/')) {
      final file = File(url);
      if (file.existsSync()) provider = FileImage(file);
    } else {
      provider = CachedNetworkImageProvider(url, headers: widget.mediaHeaders);
    }
    if (provider == null) {
      setState(() => _coverSettled = true);
      return;
    }
    setState(() => _cover = provider);
    try {
      // Keep the provider even if this fails: the Image below falls back to the
      // plain background on its own, and dropping the cover here would lose it
      // over one bad request. The timeout is so a cover that never answers
      // can't leave Share disabled forever.
      await precacheImage(provider, context)
          .timeout(const Duration(seconds: 8));
    } catch (e) {
      debugPrint('[QuoteShare] Cover not ready: $e');
    }
    if (mounted) setState(() => _coverSettled = true);
  }

  Future<void> _share() async {
    final l = AppLocalizations.of(context)!;
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      final boundary =
          _cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) throw StateError('no card to capture');
      // Export at a fixed width so the picture looks the same off any phone.
      final pixelRatio = (1080 / boundary.size.width).clamp(1.0, 4.0);
      final image = await boundary.toImage(pixelRatio: pixelRatio);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (data == null) throw StateError('no png bytes');

      final dir = await getTemporaryDirectory();
      final safe = (widget.bookTitle ?? 'quote')
          .replaceAll(RegExp('[<>:"/|?*]'), '_')
          .replaceAll(r'\', '_')
          .trim();
      final file =
          File('${dir.path}/${safe.isEmpty ? 'quote' : safe}_quote.png');
      await file.writeAsBytes(data.buffer.asUint8List(), flush: true);

      if (!mounted) return;
      final box = context.findRenderObject() as RenderBox?;
      final origin =
          box != null ? box.localToGlobal(Offset.zero) & box.size : null;
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png')],
        sharePositionOrigin: origin,
      );
    } catch (e) {
      debugPrint('[QuoteShare] Failed: $e');
      if (mounted) {
        showOverlayToast(context, l.quoteShareFailed,
            icon: Icons.error_outline_rounded);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _copy() async {
    final l = AppLocalizations.of(context)!;
    await Clipboard.setData(ClipboardData(text: widget.quote));
    if (mounted) {
      showOverlayToast(context, l.readerCopied, icon: Icons.copy_rounded);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;
    final media = MediaQuery.of(context);

    final maxWidth = min(media.size.width, 520.0) - 40;
    // The whole sheet - preview, chips, both fields, buttons - has to fit above
    // a keyboard or a button-nav bar without scrolling on a normal phone.
    final maxHeight =
        media.size.height * (media.viewInsets.bottom > 0 ? 0.26 : 0.36);
    var cardWidth = maxWidth;
    var cardHeight = cardWidth / _shape.ratio;
    if (cardHeight > maxHeight) {
      cardHeight = maxHeight;
      cardWidth = cardHeight * _shape.ratio;
    }

    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(l.quoteShareTitle,
                style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 12),
          Center(
            child: SizedBox(
              width: cardWidth,
              height: cardHeight,
              child: RepaintBoundary(
                key: _cardKey,
                // The system font scale must not reach the exported picture,
                // or the same quote comes out cropped on one phone and roomy
                // on another.
                child: MediaQuery(
                  data: media.copyWith(textScaler: TextScaler.noScaling),
                  child: _QuoteCard(
                    quote: widget.quote,
                    cover: _cover,
                    backdrop: _backdrop,
                    tone: _tone,
                    title: _titleController.text.trim(),
                    detail: _detailController.text.trim(),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: [
              _chip(cs, l.quoteShapePortrait, _shape == _QuoteShape.portrait,
                  () => setState(() => _shape = _QuoteShape.portrait)),
              _chip(cs, l.quoteShapeSquare, _shape == _QuoteShape.square,
                  () => setState(() => _shape = _QuoteShape.square)),
              _chip(cs, l.quoteShapeStory, _shape == _QuoteShape.story,
                  () => setState(() => _shape = _QuoteShape.story)),
              _chip(cs, l.quoteStyleBlur, _backdrop == _QuoteBackdrop.blur,
                  () => setState(() => _backdrop = _QuoteBackdrop.blur)),
              _chip(cs, l.quoteStyleDim, _backdrop == _QuoteBackdrop.dim,
                  () => setState(() => _backdrop = _QuoteBackdrop.dim)),
              _chip(cs, l.quoteStyleNone, _backdrop == _QuoteBackdrop.none,
                  () => setState(() => _backdrop = _QuoteBackdrop.none)),
              _chip(cs, l.quoteTextLight, _tone == _QuoteTone.light,
                  () => setState(() => _tone = _QuoteTone.light)),
              _chip(cs, l.quoteTextDark, _tone == _QuoteTone.dark,
                  () => setState(() => _tone = _QuoteTone.dark)),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _titleController,
            textCapitalization: TextCapitalization.sentences,
            keyboardType: TextInputType.multiline,
            minLines: 1,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: l.quoteFieldTitle,
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _detailController,
            textCapitalization: TextCapitalization.sentences,
            keyboardType: TextInputType.multiline,
            minLines: 1,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: l.quoteFieldDetail,
              hintText: l.quoteFieldDetailHint,
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.copy_rounded, size: 18),
                label: Text(l.readerTooltipCopy),
                onPressed: _busy ? null : _copy,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                icon: _busy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.ios_share_rounded, size: 18),
                label: Text(l.quoteShareAction),
                onPressed: _busy || !_coverSettled ? null : _share,
              ),
            ),
          ]),
          ]),
        ),
      ),
    );
  }

  Widget _chip(ColorScheme cs, String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? cs.primary.withValues(alpha: 0.16)
              : cs.onSurface.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? cs.primary.withValues(alpha: 0.6)
                : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: selected ? cs.primary : cs.onSurfaceVariant,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
        ),
      ),
    );
  }
}

class _QuoteCard extends StatelessWidget {
  final String quote;
  final ImageProvider? cover;
  final _QuoteBackdrop backdrop;
  final _QuoteTone tone;
  final String title;
  final String detail;

  const _QuoteCard({
    required this.quote,
    required this.cover,
    required this.backdrop,
    required this.tone,
    required this.title,
    required this.detail,
  });

  bool get _light => tone == _QuoteTone.light;

  Color get _ink => _light ? Colors.white : const Color(0xFF17130F);

  /// Long passages step down through a few sizes so a whole page worth of text
  /// still lands inside the card instead of cutting off after a few lines.
  double _quoteSize(double cardWidth) {
    final base = cardWidth / 14;
    final len = quote.length;
    if (len <= 90) return base * 1.1;
    if (len <= 180) return base * 0.92;
    if (len <= 320) return base * 0.76;
    if (len <= 520) return base * 0.62;
    return base * 0.5;
  }

  /// Veil under the text, leaning away from the ink so a pale cover can carry
  /// dark text and a dark one can carry light text. Blur already softens the
  /// art, so it needs far less than a sharp cover does.
  double _veilOpacity() {
    switch (backdrop) {
      case _QuoteBackdrop.blur:
        return 0.2;
      case _QuoteBackdrop.dim:
        return 0.45;
      case _QuoteBackdrop.none:
        return 0;
    }
  }

  Widget _plainBackground() {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _light
              ? [const Color(0xFF2A2438), const Color(0xFF120F18)]
              : [const Color(0xFFF3ECE2), const Color(0xFFD9CFC2)],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      final pad = w * 0.085;
      final shadow = [
        Shadow(
          color: (_light ? Colors.black : Colors.white).withValues(alpha: 0.55),
          blurRadius: w * 0.035,
        ),
      ];
      final veil = _veilOpacity();

      return ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(fit: StackFit.expand, children: [
          if (cover != null)
            backdrop == _QuoteBackdrop.blur
                // Scaled up a touch so the blur's soft edge stays outside the
                // card, and clamped so it doesn't bleed to transparent.
                ? Transform.scale(
                    scale: 1.1,
                    child: ImageFiltered(
                      imageFilter: ui.ImageFilter.blur(
                        sigmaX: w * 0.022,
                        sigmaY: w * 0.022,
                        tileMode: TileMode.clamp,
                      ),
                      child: Image(
                        image: cover!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _plainBackground(),
                      ),
                    ),
                  )
                : Image(
                    image: cover!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _plainBackground(),
                  )
          else
            _plainBackground(),
          if (veil > 0)
            ColoredBox(
              color: (_light ? Colors.black : Colors.white)
                  .withValues(alpha: veil),
            ),
          Padding(
            padding: EdgeInsets.all(pad),
            child: Center(
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '"$quote"',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'serif',
                        fontStyle: FontStyle.italic,
                        color: _ink,
                        fontSize: _quoteSize(w),
                        height: 1.34,
                        shadows: shadow,
                      ),
                    ),
                    if (title.isNotEmpty || detail.isNotEmpty)
                      SizedBox(height: w * 0.06),
                    if (title.isNotEmpty)
                      Text(
                        '- $title',
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _ink,
                          fontSize: w * 0.05,
                          fontWeight: FontWeight.w600,
                          shadows: shadow,
                        ),
                      ),
                    if (detail.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: w * 0.012),
                        child: Text(
                          detail,
                          textAlign: TextAlign.center,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _ink.withValues(alpha: 0.82),
                            fontSize: w * 0.042,
                            shadows: shadow,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ]),
      );
    });
  }
}
