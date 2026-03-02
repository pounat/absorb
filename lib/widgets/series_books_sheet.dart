import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/library_provider.dart';
import '../services/download_service.dart';
import 'book_detail_sheet.dart';
import 'episode_list_sheet.dart';

/// Show a bottom sheet with all books in a series, sorted by sequence.
/// Can be called from any screen.
void showSeriesBooksSheet(BuildContext context, {
  required String seriesName,
  String? seriesId,
  List<dynamic> books = const [],
  String? serverUrl,
  String? token,
}) {
  FocusManager.instance.primaryFocus?.unfocus();
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.05,
      maxChildSize: 0.9,
      expand: false,
      builder: (ctx, scrollController) => SeriesBooksSheet(
        seriesName: seriesName,
        seriesId: seriesId,
        books: books,
        serverUrl: serverUrl,
        token: token,
        scrollController: scrollController,
      ),
    ),
  );
}

class SeriesBooksSheet extends StatefulWidget {
  final String seriesName;
  final String? seriesId;
  final List<dynamic> books;
  final String? serverUrl;
  final String? token;
  final ScrollController scrollController;

  const SeriesBooksSheet({
    super.key,
    required this.seriesName,
    this.seriesId,
    required this.books,
    required this.serverUrl,
    required this.token,
    required this.scrollController,
  });

  @override
  State<SeriesBooksSheet> createState() => _SeriesBooksSheetState();
}

class _SeriesBooksSheetState extends State<SeriesBooksSheet> {
  List<Map<String, dynamic>> _books = [];
  bool _isLoading = true;
  bool _isDownloadingAll = false;

  @override
  void initState() {
    super.initState();
    // Use passed books as initial data
    _books = _unwrapBooks(widget.books);
    _sortBooks();
    if (_books.isNotEmpty) _isLoading = false;
    // Fetch full data from API for proper sequence info
    _fetchFromApi();
  }

  /// Unwrap ABS format: { libraryItem: {...}, sequence: "1" }
  /// Move sequence to top level of the item for consistent access.
  List<Map<String, dynamic>> _unwrapBooks(List<dynamic> raw) {
    final result = <Map<String, dynamic>>[];
    for (final b in raw) {
      if (b is! Map<String, dynamic>) continue;
      if (b.containsKey('libraryItem') && b['libraryItem'] is Map<String, dynamic>) {
        final item = Map<String, dynamic>.from(b['libraryItem'] as Map<String, dynamic>);
        if (b['sequence'] != null) item['sequence'] = b['sequence'];
        result.add(item);
      } else {
        result.add(Map<String, dynamic>.from(b));
      }
    }
    return result;
  }

  void _sortBooks() {
    _books.sort((a, b) {
      final seqA = _getSequence(a);
      final seqB = _getSequence(b);
      if (seqA == null && seqB == null) return 0;
      if (seqA == null) return 1;
      if (seqB == null) return -1;
      return seqA.compareTo(seqB);
    });
  }

  double? _getSequence(Map<String, dynamic> book) {
    // Top-level sequence (from unwrapping)
    final seq = book['sequence'];
    if (seq != null) {
      final v = double.tryParse(seq.toString());
      if (v != null) return v;
    }
    // Nested in metadata.series
    final media = book['media'] as Map<String, dynamic>? ?? {};
    final metadata = media['metadata'] as Map<String, dynamic>? ?? {};
    final seriesRaw = metadata['series'];
    if (seriesRaw is List) {
      for (final s in seriesRaw) {
        if (s is Map<String, dynamic>) {
          final v = s['sequence'];
          if (v != null) {
            final d = double.tryParse(v.toString());
            if (d != null) return d;
          }
        }
      }
    } else if (seriesRaw is Map<String, dynamic>) {
      final v = seriesRaw['sequence'];
      if (v != null) {
        final d = double.tryParse(v.toString());
        if (d != null) return d;
      }
    }
    final fallback = metadata['seriesSequence'];
    if (fallback != null) return double.tryParse(fallback.toString());
    return null;
  }

  String? _getSequenceString(Map<String, dynamic> book) {
    final v = _getSequence(book);
    if (v == null) return null;
    // Show as int if whole number, otherwise decimal
    return v == v.roundToDouble() ? v.toInt().toString() : v.toString();
  }

  Future<void> _fetchFromApi() async {
    final seriesId = widget.seriesId;
    if (seriesId == null || seriesId.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    final auth = context.read<AuthProvider>();
    final api = auth.apiService;
    if (api == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    final lib = context.read<LibraryProvider>();
    final data = await api.getSeries(seriesId, libraryId: lib.selectedLibraryId);
    if (data != null && mounted) {
      final rawBooks = data['books'] ?? data['libraryItems'] ?? [];
      if (rawBooks is List && rawBooks.isNotEmpty) {
        final fetched = _unwrapBooks(rawBooks);
        setState(() {
          _books = fetched;
          _sortBooks();
          _isLoading = false;
        });
        return;
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _downloadAll() async {
    final auth = context.read<AuthProvider>();
    final api = auth.apiService;
    if (api == null) return;

    setState(() => _isDownloadingAll = true);

    for (final book in _books) {
      if (!mounted) break;
      final bookId = book['id'] as String? ?? '';
      if (DownloadService().isDownloaded(bookId) || DownloadService().isDownloading(bookId)) continue;

      final media = book['media'] as Map<String, dynamic>? ?? {};
      final metadata = media['metadata'] as Map<String, dynamic>? ?? {};
      final title = metadata['title'] as String? ?? 'Unknown';
      final author = metadata['authorName'] as String? ?? '';

      await DownloadService().downloadItem(
        api: api,
        itemId: bookId,
        title: title,
        author: author,
        coverUrl: api.getCoverUrl(bookId),
        waitForCompletion: false,
      );
    }

    if (mounted) setState(() => _isDownloadingAll = false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final lib = context.watch<LibraryProvider>();

    // Calculate time-weighted series progress across all books
    double totalDuration = 0;
    double listenedDuration = 0;
    for (final book in _books) {
      final bookId = book['id'] as String? ?? '';
      final media = book['media'] as Map<String, dynamic>? ?? {};
      final dur = (media['duration'] is num) ? (media['duration'] as num).toDouble() : 0.0;
      final prog = lib.getProgress(bookId);
      totalDuration += dur;
      listenedDuration += dur * prog;
    }
    final seriesProgress = totalDuration > 0 ? (listenedDuration / totalDuration).clamp(0.0, 1.0) : 0.0;
    final seriesPercent = (seriesProgress * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 4),
          child: Row(
            children: [
              Icon(Icons.auto_stories_rounded, size: 20, color: cs.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(widget.seriesName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: tt.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(24, 0, 24, seriesProgress > 0 ? 4 : 12),
          child: Text(
            '${_books.length} book${_books.length != 1 ? 's' : ''} in this series',
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ),
        if (seriesProgress > 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
            child: Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: seriesProgress,
                      minHeight: 4,
                      backgroundColor: cs.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation(cs.primary),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '$seriesPercent% complete',
                  style: tt.labelSmall?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        // Download All button (reactive)
        if (_books.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
            child: ListenableBuilder(
              listenable: DownloadService(),
              builder: (_, __) {
                final dl = DownloadService();
                int downloaded = 0;
                int downloading = 0;
                double totalProgress = 0;
                for (final book in _books) {
                  final bookId = book['id'] as String? ?? '';
                  if (dl.isDownloaded(bookId)) {
                    downloaded++;
                  } else if (dl.isDownloading(bookId)) {
                    downloading++;
                    totalProgress += dl.downloadProgress(bookId);
                  }
                }
                final allDone = downloaded == _books.length;
                final anyActive = _isDownloadingAll || downloading > 0;
                final overallProgress = _books.isNotEmpty
                    ? (downloaded + totalProgress) / _books.length
                    : 0.0;
                final green = Theme.of(context).brightness == Brightness.dark
                    ? Colors.greenAccent : Colors.green.shade700;

                if (allDone) {
                  return Container(height: 44,
                    decoration: BoxDecoration(
                      color: green.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: green.withValues(alpha: 0.15)),
                    ),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.download_done_rounded, size: 16, color: green.withValues(alpha: 0.7)),
                      const SizedBox(width: 6),
                      Text('All Books Downloaded',
                        style: TextStyle(color: green.withValues(alpha: 0.7), fontSize: 12, fontWeight: FontWeight.w500)),
                    ]),
                  );
                }

                return GestureDetector(
                  onTap: anyActive ? null : _downloadAll,
                  child: Container(height: 44,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: cs.onSurface.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: cs.onSurface.withValues(alpha: 0.1)),
                    ),
                    child: Stack(children: [
                      if (anyActive)
                        FractionallySizedBox(
                          widthFactor: overallProgress.clamp(0.0, 1.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: cs.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(13),
                            ),
                          ),
                        ),
                      Center(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        if (anyActive)
                          SizedBox(width: 14, height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: cs.primary))
                        else
                          Icon(Icons.download_rounded, size: 16, color: cs.onSurfaceVariant),
                        const SizedBox(width: 6),
                        Text(
                          anyActive
                              ? 'Downloading ${downloaded + downloading}/${_books.length} · ${(overallProgress * 100).toStringAsFixed(0)}%'
                              : downloaded > 0
                                  ? 'Download Remaining (${_books.length - downloaded})'
                                  : 'Download All Books',
                          style: TextStyle(
                            color: anyActive ? cs.primary : cs.onSurfaceVariant,
                            fontSize: 12, fontWeight: FontWeight.w500)),
                      ])),
                    ]),
                  ),
                );
              },
            ),
          ),
        ],
        if (_isLoading && _books.isEmpty)
          const Expanded(
              child: Center(child: CircularProgressIndicator()))
        else if (_books.isEmpty)
          Expanded(
            child: Center(
              child: Text('No books found',
                  style: tt.bodyLarge
                      ?.copyWith(color: cs.onSurfaceVariant)),
            ),
          )
        else
          Expanded(
            child: ListenableBuilder(
              listenable: DownloadService(),
              builder: (context, _) => ListView.builder(
              controller: widget.scrollController,
              padding: EdgeInsets.fromLTRB(16, 0, 16, 24 + MediaQuery.of(context).viewPadding.bottom),
              itemCount: _books.length,
              itemBuilder: (context, index) {
                final book = _books[index];
                final bookId = book['id'] as String? ?? '';
                final media = book['media'] as Map<String, dynamic>? ?? {};
                final metadata =
                    media['metadata'] as Map<String, dynamic>? ?? {};
                final bookTitle = metadata['title'] as String? ?? 'Unknown';
                final authorName = metadata['authorName'] as String? ?? '';
                final sequence = _getSequenceString(book);
                final duration = (media['duration'] is num)
                    ? (media['duration'] as num).toDouble()
                    : 0.0;

                final progress = lib.getProgress(bookId);
                final isFinished = lib.getProgressData(bookId)?['isFinished'] == true;
                final isDownloaded = DownloadService().isDownloaded(bookId);
                final isDownloading = DownloadService().isDownloading(bookId);
                final downloadPct = (DownloadService().downloadProgress(bookId) * 100)
                    .clamp(0, 100)
                    .round();

                String? coverUrl;
                if (bookId.isNotEmpty &&
                    widget.serverUrl != null &&
                    widget.token != null) {
                  final cleanUrl = widget.serverUrl!.endsWith('/')
                      ? widget.serverUrl!
                          .substring(0, widget.serverUrl!.length - 1)
                      : widget.serverUrl!;
                  coverUrl =
                      '$cleanUrl/api/items/$bookId/cover?width=400&token=${widget.token}';
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Card(
                    elevation: 0,
                    color: cs.surfaceContainerHigh,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () {
                        if (bookId.isNotEmpty) {
                          if (lib.isPodcastLibrary) {
                            EpisodeListSheet.show(context, book);
                          } else {
                            showBookDetailSheet(context, bookId);
                          }
                        }
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Row(
                        children: [
                          // Square cover with sequence badge + status badges
                          SizedBox(
                            width: 80,
                            height: 80,
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: coverUrl != null
                                      ? CachedNetworkImage(
                                          imageUrl: coverUrl,
                                          fit: BoxFit.cover,
                                          httpHeaders: context.read<LibraryProvider>().mediaHeaders,
                                          placeholder: (_, __) =>
                                              _placeholder(cs),
                                          errorWidget: (_, __, ___) =>
                                              _placeholder(cs),
                                        )
                                      : _placeholder(cs),
                                ),
                                if (sequence != null && sequence.isNotEmpty)
                                  Positioned(
                                    top: 4,
                                    left: 4,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: cs.primary,
                                        borderRadius:
                                            BorderRadius.circular(8),
                                        boxShadow: [
                                          BoxShadow(
                                              color: Colors.black
                                                  .withValues(alpha: 0.3),
                                              blurRadius: 4)
                                        ],
                                      ),
                                      child: Text('#$sequence',
                                          style: TextStyle(
                                              color: cs.onPrimary,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w800)),
                                    ),
                                  ),
                                if (!isDownloaded && isDownloading)
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.black54,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '$downloadPct%',
                                        style: TextStyle(
                                          color: cs.primary,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                // Progress bar at bottom
                                if (progress > 0 && !isFinished)
                                  Positioned(
                                    left: 0,
                                    right: 0,
                                    bottom: 0,
                                    child: LinearProgressIndicator(
                                      value: progress.clamp(0.0, 1.0),
                                      minHeight: 3,
                                      backgroundColor: Colors.black38,
                                      valueColor: AlwaysStoppedAnimation(cs.primary),
                                    ),
                                  ),
                                // Done / Downloaded banners
                                if (isFinished || isDownloaded)
                                  Positioned(
                                    left: 0,
                                    right: 0,
                                    bottom: 0,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 3),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.bottomCenter,
                                          end: Alignment.topCenter,
                                          colors: [
                                            Colors.black.withValues(alpha: 0.85),
                                            Colors.black.withValues(alpha: 0.0),
                                          ],
                                        ),
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (isFinished)
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.check_circle_rounded,
                                                    size: 10, color: Theme.of(context).brightness == Brightness.dark ? Colors.greenAccent[400] : Colors.green.shade700),
                                                const SizedBox(width: 3),
                                                Text('Done',
                                                    style: TextStyle(
                                                        fontSize: 9,
                                                        fontWeight: FontWeight.w600,
                                                        color: Theme.of(context).brightness == Brightness.dark ? Colors.greenAccent[400] : Colors.green.shade700)),
                                              ],
                                            ),
                                          if (isDownloaded)
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.download_done_rounded,
                                                    size: 10, color: cs.primary),
                                                const SizedBox(width: 3),
                                                Text('Saved',
                                                    style: TextStyle(
                                                        fontSize: 9,
                                                        fontWeight: FontWeight.w600,
                                                        color: cs.primary)),
                                              ],
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          // Info
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  if (sequence != null &&
                                      sequence.isNotEmpty)
                                    Text('Book $sequence',
                                        style: tt.labelSmall?.copyWith(
                                            color: cs.primary,
                                            fontWeight: FontWeight.w600)),
                                  Text(bookTitle,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: tt.titleSmall?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: cs.onSurface)),
                                  if (authorName.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(authorName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: tt.bodySmall?.copyWith(
                                            color: cs.onSurfaceVariant)),
                                  ],
                                  if (duration > 0) ...[
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Text(_formatDuration(duration),
                                            style: tt.labelSmall?.copyWith(
                                                color: cs.onSurfaceVariant)),
                                        if (progress > 0 && !isFinished) ...[
                                          const SizedBox(width: 8),
                                          Text('${(progress * 100).round()}%',
                                              style: tt.labelSmall?.copyWith(
                                                  color: cs.primary,
                                                  fontWeight: FontWeight.w600)),
                                        ],
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: Icon(Icons.chevron_right_rounded,
                                color: cs.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          ),
      ],
    );
  }

  Widget _placeholder(ColorScheme cs) {
    return Container(
      color: cs.surfaceContainerHighest,
      child: Center(
        child: Icon(Icons.headphones_rounded,
            size: 24, color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
      ),
    );
  }

  String _formatDuration(double seconds) {
    final h = (seconds / 3600).floor();
    final m = ((seconds % 3600) / 60).floor();
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }
}
