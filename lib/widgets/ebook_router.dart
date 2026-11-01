import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/ebook_cache.dart';
import '../services/image_epub.dart';
import '../services/narration_service.dart';
import '../services/server_backend.dart';
import 'comic_reader_view.dart';
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

bool canReadEbook(Map<String, dynamic>? ebookFile) {
  if (ebookFile == null) return false;
  final ext = ebookExt(ebookFile);
  // BookOrbit unpacks CBR and CB7 on the server and sends the pages.
  if (comicEbookFormats.contains(ext) && ServerBackend.active.isBookOrbit) return true;
  return readableEbookFormats.contains(ext);
}

/// Opens a book's ebook at a highlight. A downloaded ebook opens from the
/// reader cache, so this works offline. [title] is looked up when not given.
Future<void> openHighlightInReader(
  BuildContext context, {
  required String itemId,
  required String cfi,
  String? title,
}) async {
  final l = AppLocalizations.of(context)!;
  final api = context.read<AuthProvider>().apiService;
  var ebookFile = await cachedEbookFileFor(itemId);
  if ((ebookFile == null || title == null) && api != null) {
    final item = await api.getLibraryItem(itemId);
    ebookFile ??= resolveEbookFile(item);
    if (title == null) {
      final media = item?['media'] as Map<String, dynamic>? ?? {};
      final metadata = media['metadata'] as Map<String, dynamic>? ?? {};
      title = metadata['title'] as String?;
    }
  }
  if (!context.mounted) return;
  if (ebookFile == null) {
    showOverlayToast(
      context,
      api == null ? l.bookmarksNotConnected : l.noEbookFileFound,
      icon: Icons.menu_book_outlined,
    );
    return;
  }
  await openEbookReader(
    context,
    itemId: itemId,
    title: title ?? '',
    ebookFile: ebookFile,
    openAtCfi: cfi,
  );
}

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
  double? openAtAudioSeconds,
  bool startReadAlong = false,
}) async {
  final ext = ebookExt(ebookFile);
  final Widget viewer;
  if (ext == 'epub') {
    viewer = _EpubGate(
      itemId: itemId,
      title: title,
      ebookFile: ebookFile,
      epubReader: (file) => EbookReaderView(
          itemId: itemId, title: title, ebookFile: file, openAtCfi: openAtCfi,
          findText: findText, findChapterHint: findChapterHint,
          findPositionSeconds: findPositionSeconds, openAtAudioSeconds: openAtAudioSeconds,
          startReadAlong: startReadAlong),
    );
  } else if (comicEbookFormats.contains(ext)) {
    viewer = ComicReaderView(itemId: itemId, title: title, ebookFile: ebookFile);
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

/// Gets an EPUB onto the phone, then opens it in the EPUB reader, or in the
/// comic reader when its pages are all pictures (a scanned or comic-style
/// book has no text to lay out, so the EPUB reader can only shrink it).
class _EpubGate extends StatefulWidget {
  final String itemId;
  final String title;
  final Map<String, dynamic> ebookFile;
  final Widget Function(Map<String, dynamic> ebookFile) epubReader;

  const _EpubGate({
    required this.itemId,
    required this.title,
    required this.ebookFile,
    required this.epubReader,
  });

  @override
  State<_EpubGate> createState() => _EpubGateState();
}

class _EpubGateState extends State<_EpubGate> {
  bool _decided = false;
  File? _imageEpub;
  late Map<String, dynamic> _ebookFile = widget.ebookFile;

  @override
  void initState() {
    super.initState();
    _decide();
  }

  // Any failure here falls through to the EPUB reader, which fetches the
  // file again and shows its own error.
  Future<void> _decide() async {
    File? imageEpub;
    try {
      final api = context.read<AuthProvider>().apiService;
      if (api is BookOrbitApiService) {
        final readAlong = await api.readAlongReaderFile(widget.itemId);
        if (readAlong != null && readAlong['ino'] != widget.ebookFile['ino']) {
          debugPrint('[EbookRouter] ${widget.itemId}: opening the read along EPUB ${readAlong['ino']} '
              'instead of ${widget.ebookFile['ino']}');
          _ebookFile = readAlong;
        }
      }
      if (api != null) {
        final file = await NarrationService.instance
            .readerFile(api, widget.itemId, _ebookFile, widget.title);
        final pages = await imageEpubPageCount(file);
        if (pages > 0) {
          debugPrint('[EbookRouter] ${widget.itemId} is $pages page pictures - opening as a comic');
          imageEpub = file;
        }
      }
    } catch (e) {
      debugPrint('[EbookRouter] image check skipped for ${widget.itemId}: $e');
    }
    if (mounted) setState(() { _imageEpub = imageEpub; _decided = true; });
  }

  @override
  Widget build(BuildContext context) {
    if (!_decided) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis)),
        body: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    final imageEpub = _imageEpub;
    if (imageEpub != null) {
      return ComicReaderView(
        itemId: widget.itemId,
        title: widget.title,
        ebookFile: _ebookFile,
        imageEpub: imageEpub,
      );
    }
    return widget.epubReader(_ebookFile);
  }
}
