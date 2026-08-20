import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/ebook_cache.dart';
import 'ebook_reader_view.dart';
import 'pdf_reader_view.dart';
import 'foliate_reader_view.dart';
import 'overlay_toast.dart';

/// Lower-cased ebook format (no dot) for an ABS ebookFile. Shares the cache's
/// format-first derivation so the router, cache and readers can never disagree
/// on what a file is.
String ebookExt(Map<String, dynamic>? ebookFile) {
  if (ebookFile == null) return '';
  final ext = ebookExtFromFile(ebookFile);
  return ext.startsWith('.') ? ext.substring(1) : ext;
}

bool canReadEbook(Map<String, dynamic>? ebookFile) =>
    ebookFile != null && readableEbookFormats.contains(ebookExt(ebookFile));

/// Routes an ebook to the right reader for its format, or toasts when the
/// format isn't supported in-app. [openAtCfi] jumps an EPUB straight to a
/// saved location (a highlight) instead of resuming where reading left off.
/// [findText] hands an EPUB a transcript to fuzzy-locate once it has loaded
/// (Find in ebook), with [findChapterHint] naming the audio chapter it came from.
Future<void> openEbookReader(
  BuildContext context, {
  required String itemId,
  required String title,
  required Map<String, dynamic> ebookFile,
  String? openAtCfi,
  String? findText,
  String? findChapterHint,
  double? findPositionSeconds,
}) async {
  final ext = ebookExt(ebookFile);
  final Widget viewer;
  if (ext == 'epub') {
    viewer = EbookReaderView(
        itemId: itemId, title: title, ebookFile: ebookFile, openAtCfi: openAtCfi,
        findText: findText, findChapterHint: findChapterHint,
        findPositionSeconds: findPositionSeconds);
  } else if (ext == 'pdf') {
    viewer = PdfReaderView(itemId: itemId, title: title, ebookFile: ebookFile);
  } else if (foliateEbookFormats.contains(ext)) {
    viewer = FoliateReaderView(itemId: itemId, title: title, ebookFile: ebookFile);
  } else {
    showOverlayToast(context, AppLocalizations.of(context)!.readerFormatUnsupported,
        icon: Icons.menu_book_outlined);
    return;
  }
  await Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute(builder: (_) => viewer),
  );
}
