import 'dart:ui' as ui;
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:absorb/widgets/stable_cached_network_image.dart';
import 'package:absorb/widgets/library_cached_cover.dart';
import 'package:flutter_test/flutter_test.dart';
import 'local_book_catalog_test.dart' as catalog_tests;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late PersistentLibraryImageCache testCache;
  setUpAll(() {
    testCache = PersistentLibraryImageCache(Config(
      'library-cover-unit-tests',
      repo: JsonCacheInfoRepository(databaseName: 'library-cover-unit-tests'),
      fileSystem: LibraryCoverFileSystem(),
    ));
    LibraryCoverCache.testInstance = testCache;
  });
  tearDownAll(() async {
    await testCache.dispose();
    LibraryCoverCache.testInstance = null;
  });
  catalog_tests.main();

  const url = 'https://books.example/api/items/book-a/cover'
      '?token=old&width=400&ts=123';

  test('saved original produces reusable thumbnails without HTTP refresh', () async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.drawColor(const ui.Color(0xff123456), ui.BlendMode.src);
    final picture = recorder.endRecording();
    final original = await picture.toImage(8, 8);
    final bytes = await original.toByteData(format: ui.ImageByteFormat.png);
    original.dispose();
    picture.dispose();
    const source = 'https://offline.invalid/api/items/test-cover/cover?raw=1&ts=42';
    final key = stableCoverCacheKey(source);
    final manager = LibraryCoverCache.instance;
    await manager.putFile(source, bytes!.buffer.asUint8List(), key: key,
        fileExtension: 'png', maxAge: const Duration(days: -1));
    final first = await manager.getImageFile(source, key: key, maxWidth: 4)
        .where((r) => r is FileInfo).cast<FileInfo>().first;
    final second = await manager.getImageFile(source, key: key, maxWidth: 4)
        .where((r) => r is FileInfo).cast<FileInfo>().first;
    expect(second.file.path, first.file.path);
    final codec = await ui.instantiateImageCodec(await second.file.readAsBytes());
    final frame = await codec.getNextFrame();
    expect(frame.image.width, 4);
    frame.image.dispose();
    codec.dispose();
    await manager.removeFile(key);
    await manager.removeFile('local-thumbnail-v1-4-$key');
  });

  test('token refresh reuses the cover without changing the request', () {
    final original = LibraryCachedCover(imageUrl: url);
    final refreshedUrl = url.replaceFirst('token=old', 'token=new');
    final refreshed = LibraryCachedCover(imageUrl: refreshedUrl);
    expect(refreshed.cacheKey, original.cacheKey);
    expect(refreshed.imageUrl, originalLibraryCoverUrl(refreshedUrl));
  });

  test('different artwork and servers do not collide', () {
    final original = LibraryCachedCover(imageUrl: url);
    for (final other in [
      url.replaceFirst('book-a', 'book-b'),
      url.replaceFirst('books.example', 'other.example'),
      url.replaceFirst('ts=123', 'ts=124'),
    ]) {
      expect(LibraryCachedCover(imageUrl: other).cacheKey,
          isNot(original.cacheKey));
    }
  });

  test('display sizes share an authenticated original', () {
    final small = LibraryCachedCover(imageUrl: url);
    final large = LibraryCachedCover(
        imageUrl: url.replaceFirst('width=400', 'width=800'));
    expect(small.cacheKey, large.cacheKey);
    final request = Uri.parse(small.imageUrl);
    expect(request.queryParameters['raw'], '1');
    expect(request.queryParameters['width'], isNull);
    expect(request.queryParameters['token'], 'old');
    expect(request.queryParameters['ts'], '123');
  });

  test('external artwork keeps query parameters that may identify the image', () {
    const external = 'https://images.example/art?token=image-id';
    expect(LibraryCachedCover(imageUrl: external).cacheKey, external);
  });

  test('foreground and background share disk cache but keep decode sizes', () {
    final foreground = LibraryCachedCover(imageUrl: url, memCacheWidth: 400);
    final background = LibraryCachedCover(imageUrl: url, memCacheWidth: 32);
    expect(foreground.cacheKey, background.cacheKey);
    expect(identical(foreground.cacheManager, background.cacheManager), isTrue);
    expect(foreground.memCacheWidth, 400);
    expect(background.memCacheWidth, 32);
    expect(foreground.fadeInDuration, const Duration(milliseconds: 250));
    expect(foreground.fadeOutDuration, Duration.zero);
  });
}
