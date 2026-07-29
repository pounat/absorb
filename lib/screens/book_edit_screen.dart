import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../widgets/edit_metadata_sheet.dart';

/// Full-screen unified per-book editor. Thin wrapper that hosts
/// [MetadataEditView], which owns the swipeable Details / Cover / Chapters /
/// Match / Encode tabs (Audiobookshelf web order).
class BookEditScreen extends StatelessWidget {
  final String itemId;
  final String bookTitle;
  final Map<String, dynamic> metadata;
  final List<String> tags;
  final List<dynamic> audioFiles;
  final List<dynamic> libraryFiles;
  final String relPath;
  final bool isEbookOnly;
  final bool isAdmin;
  final String? libraryId;

  const BookEditScreen({
    super.key,
    required this.itemId,
    required this.bookTitle,
    required this.metadata,
    required this.tags,
    required this.audioFiles,
    this.libraryFiles = const [],
    required this.relPath,
    required this.isEbookOnly,
    required this.isAdmin,
    this.libraryId,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l.edit, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            Text(bookTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          ],
        ),
      ),
      body: MetadataEditView(
        itemId: itemId,
        bookTitle: bookTitle,
        metadata: metadata,
        tags: tags,
        audioFiles: audioFiles,
        libraryFiles: libraryFiles,
        relPath: relPath,
        isEbookOnly: isEbookOnly,
        isAdmin: isAdmin,
        libraryId: libraryId,
      ),
    );
  }
}
