import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

/// Abstract interface for loading epub data
abstract class EpubDataLoader {
  Future<Uint8List> loadData();
}

/// File system epub loader implementation
class FileEpubLoader implements EpubDataLoader {
  final File file;
  
  FileEpubLoader(this.file);
  
  @override
  Future<Uint8List> loadData() {
    return file.readAsBytes();
  }
}

/// Network/URL epub loader implementation
class UrlEpubLoader implements EpubDataLoader {
  final String url;
  final Map<String, String>? headers;
  
  UrlEpubLoader(this.url, {this.headers});
  
  @override
  Future<Uint8List> loadData() async {
    try {
      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        throw Exception('Failed to download file from URL');
      }
    } catch (e) {
      throw Exception('Failed to download file from URL, $e');
    }
  }
}

/// Asset epub loader implementation
class AssetEpubLoader implements EpubDataLoader {
  final String assetPath;
  
  AssetEpubLoader(this.assetPath);
  
  @override
  Future<Uint8List> loadData() async {
    final byteData = await rootBundle.load(assetPath);
    return byteData.buffer.asUint8List();
  }
}
