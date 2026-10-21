import 'dart:ui' as ui;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:file/file.dart' as storage;
import 'package:file/local.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';

import 'stable_cached_network_image.dart';

/// One original per item, regardless of the grid's display size.
String originalLibraryCoverUrl(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null || !uri.path.contains('/api/items/') ||
      !uri.path.endsWith('/cover')) return url;
  final query = Map<String, String>.from(uri.queryParameters)
    ..remove('width')
    ..remove('height')
    ..remove('format')
    ..['raw'] = '1';
  return uri.replace(queryParameters: query).toString();
}

/// App support storage survives OS temporary-cache cleanup.
class LibraryCoverFileSystem implements FileSystem {
  @override
  Future<storage.File> createFile(String name) async {
    final root = await getApplicationSupportDirectory();
    final directory = const LocalFileSystem()
        .directory('${root.path}/library-cover-originals-v2');
    await directory.create(recursive: true);
    return directory.childFile(name);
  }
}

/// Artwork revisions are part of the key. An unchanged revision is read from
/// disk without a network freshness check during scrolling.
class PersistentLibraryImageCache extends CacheManager with ImageCacheManager {
  PersistentLibraryImageCache(super.config);
  final _preparing = <String, Future<FileInfo>>{};

  @override
  Stream<FileResponse> getFileStream(String url, {String? key,
      Map<String, String>? headers, bool withProgress = false}) async* {
    final cached = await getFileFromCache(key ?? url);
    if (cached != null && await cached.file.exists()) {
      yield FileInfo(cached.file, FileSource.Cache,
          DateTime.now().add(const Duration(days: 3650)), cached.originalUrl);
      return;
    }
    yield* super.getFileStream(url, key: key, headers: headers, withProgress: withProgress);
  }

  @override
  Stream<FileResponse> getImageFile(String url, {String? key,
      Map<String, String>? headers, bool withProgress = false,
      int? maxHeight, int? maxWidth}) async* {
    if (maxWidth == null) {
      yield* getFileStream(url, key: key, headers: headers, withProgress: withProgress);
      return;
    }
    final originalKey = key ?? url;
    final thumbnailKey = 'local-thumbnail-v1-$maxWidth-$originalKey';
    final cached = await getFileFromCache(thumbnailKey);
    if (cached != null && await cached.file.exists()) {
      yield cached;
      return;
    }
    final pending = _preparing.putIfAbsent(thumbnailKey, () async {
      final original = await getFileStream(url, key: originalKey, headers: headers)
          .where((f) => f is FileInfo).cast<FileInfo>().first;
      final codec = await ui.instantiateImageCodec(await original.file.readAsBytes(),
          targetWidth: maxWidth, allowUpscaling: false);
      try {
        final frame = await codec.getNextFrame();
        try {
          final data = await frame.image.toByteData(format: ui.ImageByteFormat.png);
          if (data == null) throw StateError('Could not prepare cover');
          final file = await putFile(url, data.buffer.asUint8List(),
              key: thumbnailKey, fileExtension: 'png',
              maxAge: const Duration(days: 3650));
          return FileInfo(file, FileSource.Cache,
              DateTime.now().add(const Duration(days: 3650)), url);
        } finally { frame.image.dispose(); }
      } finally { codec.dispose(); }
    });
    try { yield await pending; }
    finally { if (identical(_preparing[thumbnailKey], pending)) _preparing.remove(thumbnailKey); }
  }
}

class LibraryCoverCache {
  // Room for 750 books, extra artwork, and replaced cover revisions.
  // The byte-bounded decoded cache never promises to hold 750 full bitmaps.
  // Tests inject a platform-independent repository.
  static PersistentLibraryImageCache? testInstance;
  static PersistentLibraryImageCache get instance => testInstance ?? _instance;
  static final _instance = PersistentLibraryImageCache(Config(
    'absorbLibraryOriginalsV2',
    stalePeriod: const Duration(days: 3650),
    maxNrOfCacheObjects: 12000,
    fileSystem: LibraryCoverFileSystem(),
  ));

  static int thumbnailWidth(int? width) {
    final requested = width ?? 512;
    if (requested <= 32) return 32;
    if (requested <= 512) return 512;
    if (requested <= 1024) return 1024;
    return requested;
  }

  static Future<void> prepare(String imageUrl, Map<String, String> headers) async {
    final url = originalLibraryCoverUrl(imageUrl);
    final key = stableCoverCacheKey(url);
    for (final width in [512, 32, 1024]) {
      await instance.getImageFile(url, key: key, headers: headers, maxWidth: width).drain<void>();
    }
  }

  static bool _memoryConfigured = false;
  static CacheManager forBrowsing() {
    if (!_memoryConfigured) {
      final cache = PaintingBinding.instance.imageCache;
      if (cache.maximumSize < 2000) cache.maximumSize = 2000;
      if (cache.maximumSizeBytes < 2 * 1024 * 1024 * 1024) {
        cache.maximumSizeBytes = 2 * 1024 * 1024 * 1024;
      }
      _memoryConfigured = true;
    }
    return instance;
  }
}

/// Store originals on disk; decode only the pixels needed by each tile.
class LibraryCachedCover extends CachedNetworkImage {
  LibraryCachedCover({
    super.key,
    required String imageUrl,
    super.fit,
    super.httpHeaders,
    int? memCacheWidth,
    super.placeholder,
    super.errorWidget,
  }) : super(
          imageUrl: originalLibraryCoverUrl(imageUrl),
          cacheKey: stableCoverCacheKey(originalLibraryCoverUrl(imageUrl)),
          cacheManager: LibraryCoverCache.forBrowsing(),
          memCacheWidth: memCacheWidth,
          maxWidthDiskCache: memCacheWidth == null ? null : LibraryCoverCache.thumbnailWidth(memCacheWidth),
          useOldImageOnUrlChange: true,
          fadeInDuration: const Duration(milliseconds: 250),
          fadeOutDuration: Duration.zero,
          placeholderFadeInDuration: Duration.zero,
        );
}
