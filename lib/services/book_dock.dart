/// Where a BookOrbit Book Dock file can be filed: one folder of one library.
class BookDockDestination {
  final String libraryId;
  final String libraryName;
  final String folderId;
  final String folderName;

  const BookDockDestination({
    required this.libraryId,
    required this.libraryName,
    required this.folderId,
    required this.folderName,
  });
}

/// What filing a dock file into a library did.
class BookDockFileResult {
  final bool success;

  /// The library already holds a file with this name, so nothing was added.
  final bool duplicate;

  /// The server's own explanation when it did not file the book.
  final String? message;

  const BookDockFileResult({required this.success, this.duplicate = false, this.message});
}

/// One field filing would change: [from] is what the file says, null when
/// it says nothing.
class BookDockChange {
  final String field;
  final String? from;
  final String to;

  const BookDockChange({required this.field, this.from, required this.to});
}

/// One file of a multi-file dock entry.
class BookDockUnitFile {
  final String fileName;
  final int? fileSize;
  final String? role;

  const BookDockUnitFile({required this.fileName, this.fileSize, this.role});
}

/// The dock-only part of a dock item (`item['bookDock']`), null for books.
/// Mirrors what BookOrbit's web Book Dock shows for a file.
class BookDockInfo {
  final String status;
  final String fileName;
  final String? format;
  final int? fileSize;
  final String? errorMessage;
  final bool hasFoundDetails;

  /// 'edited' (details saved), 'fetched' (found online, not applied),
  /// 'embedded' (only what the file says) or 'none'.
  final String detailsState;

  /// How well the details found online match the file, 0-100.
  final int? confidence;
  final String? targetLibraryId;
  final String? targetFolderId;
  final int? addedAt;
  final List<BookDockUnitFile> unitFiles;
  final List<BookDockChange> changes;

  const BookDockInfo({
    required this.status,
    required this.fileName,
    this.format,
    this.fileSize,
    this.errorMessage,
    this.hasFoundDetails = false,
    this.detailsState = 'none',
    this.confidence,
    this.targetLibraryId,
    this.targetFolderId,
    this.addedAt,
    this.unitFiles = const [],
    this.changes = const [],
  });

  /// BookOrbit's web asks for a review below this match.
  static const reviewBelow = 70;

  /// Still extracting or looking up details on the server.
  bool get isWorking => status == 'pending' || status == 'extracting' || status == 'fetching';

  bool get hasDestination => targetLibraryId != null && targetFolderId != null;

  bool get hasMatch => confidence != null && confidence! > 0;

  /// The web's "Needs review": ready, but no destination or a weak match.
  bool get needsReview =>
      status == 'ready' && (!hasDestination || (confidence != null && confidence! < reviewBelow));

  static BookDockInfo? of(Map<String, dynamic>? item) {
    final d = item?['bookDock'];
    if (d is! Map) return null;
    return BookDockInfo(
      status: '${d['status'] ?? ''}',
      fileName: '${d['fileName'] ?? ''}',
      format: d['format'] as String?,
      fileSize: (d['fileSize'] as num?)?.toInt(),
      errorMessage: d['errorMessage'] as String?,
      hasFoundDetails: d['hasFoundDetails'] == true,
      detailsState: '${d['detailsState'] ?? 'none'}',
      confidence: (d['confidence'] as num?)?.toInt(),
      targetLibraryId: d['targetLibraryId'] as String?,
      targetFolderId: d['targetFolderId'] as String?,
      addedAt: (d['addedAt'] as num?)?.toInt(),
      unitFiles: [
        for (final u in (d['unitFiles'] as List? ?? const []).whereType<Map>())
          BookDockUnitFile(
            fileName: '${u['fileName'] ?? ''}',
            fileSize: (u['fileSize'] as num?)?.toInt(),
            role: u['role'] as String?,
          ),
      ],
      changes: [
        for (final c in (d['changes'] as List? ?? const []).whereType<Map>())
          BookDockChange(field: '${c['field']}', from: c['from'] as String?, to: '${c['to'] ?? ''}'),
      ],
    );
  }
}
