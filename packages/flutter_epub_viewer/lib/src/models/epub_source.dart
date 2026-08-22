import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_epub_viewer/src/epub_data_loader.dart';


/// Epub file source
class EpubSource {
  // final Uint8List epubData;
  final Future<Uint8List> epubData;

  EpubSource._({required this.epubData});

  ///Loading from a file
  factory EpubSource.fromFile(File file) {
    final loader = FileEpubLoader(file);
    return EpubSource._(epubData: loader.loadData());
  }

  ///load from a url with optional headers
  factory EpubSource.fromUrl(String url, {Map<String, String>? headers}) {
    final loader = UrlEpubLoader(url, headers: headers);
    return EpubSource._(epubData: loader.loadData());
  }

  ///load from assets
  factory EpubSource.fromAsset(String assetPath) {
    final loader = AssetEpubLoader(assetPath);
    return EpubSource._(epubData: loader.loadData());
  }
}
