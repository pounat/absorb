import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_epub_viewer/src/epub_data_loader.dart';


/// Epub file source
class EpubSource {
  final EpubDataLoader _loader;

  /// Set for file sources. The viewer serves such a file to the page over
  /// loopback instead of pushing its bytes across the bridge, so the bytes
  /// are only read on demand, never eagerly at construction.
  final File? file;

  EpubSource._(this._loader, {this.file});

  Future<Uint8List> get epubData => _loader.loadData();

  ///Loading from a file
  factory EpubSource.fromFile(File file) =>
      EpubSource._(FileEpubLoader(file), file: file);

  ///load from a url with optional headers
  factory EpubSource.fromUrl(String url, {Map<String, String>? headers}) =>
      EpubSource._(UrlEpubLoader(url, headers: headers));

  ///load from assets
  factory EpubSource.fromAsset(String assetPath) =>
      EpubSource._(AssetEpubLoader(assetPath));
}
