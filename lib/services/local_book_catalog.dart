import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import 'api_service.dart';

/// One atomic snapshot per account, server and library. A failed sync never
/// replaces the last complete snapshot with a partial page of results.
class LocalBookCatalog {
  static final _syncs = <String, Future<List<Map<String, dynamic>>>>{};
  bool needsUpgrade = false;
  final String identity;
  LocalBookCatalog(String scope, String server, String library)
      : identity = sha256.convert(utf8.encode(jsonEncode([scope, server, library]))).toString();

  Future<File> _file() async {
    final root = await getApplicationSupportDirectory();
    final dir = Directory('${root.path}/book-catalog-v1');
    await dir.create(recursive: true);
    return File('${dir.path}/$identity.json');
  }

  Future<List<Map<String, dynamic>>?> read() async {
    try {
      final data = jsonDecode(await (await _file()).readAsString()) as Map;
      if (data['version'] != 1 && data['version'] != 2) return null;
      needsUpgrade = data['version'] == 1;
      return (data['items'] as List).cast<Map<String, dynamic>>();
    } on FileSystemException { return null; }
      on FormatException { return null; }
      on TypeError { return null; }
  }

  static Future<List<Map<String, dynamic>>> fetchAll(
    Future<Map<String, dynamic>?> Function(int page) fetch,
    void Function(int loaded, int total) progress,
  ) async {
    final items = <String, Map<String, dynamic>>{};
    int? expected;
    var count = 0;
    for (var page = 0; ; page++) {
      final result = await fetch(page);
      if (result == null || result['results'] is! List || result['total'] is! num) {
        throw StateError('Library sync failed; saved library was kept.');
      }
      final total = (result['total'] as num).toInt();
      expected ??= total;
      if (total != expected) throw StateError('Library changed during sync. Please retry.');
      final batch = (result['results'] as List).cast<Map<String, dynamic>>();
      for (final item in batch) {
        final id = item['id'];
        if (id is! String || items.containsKey(id)) {
          throw StateError('Library changed during sync. Please retry.');
        }
        items[id] = item;
      }
      count += batch.length;
      progress(count, total);
      if (count == total) return items.values.toList();
      if (batch.isEmpty || count > total) throw StateError('Incomplete library sync.');
    }
  }

  static Future<List<Map<String, dynamic>>> fetchDetails(
    List<Map<String, dynamic>> listing,
    Future<List<Map<String, dynamic>>> Function(List<String>) fetch,
    void Function(int, int) progress,
  ) async {
    final result = <Map<String, dynamic>>[];
    for (var offset = 0; offset < listing.length; offset += 50) {
      final batch = listing.skip(offset).take(50).toList();
      final ids = batch.map((item) => item['id'] as String).toList();
      final details = await fetch(ids);
      final byId = <String, Map<String, dynamic>>{};
      for (final item in details) {
        final id = item['id'];
        if (id is! String || !ids.contains(id) || byId.containsKey(id)) {
          throw StateError('Invalid detail batch. Saved library was kept.');
        }
        byId[id] = item;
      }
      if (byId.length != ids.length) {
        throw StateError('Incomplete metadata sync. Saved library was kept.');
      }
      for (final item in batch) {
        final full = byId[item['id']]!;
        final metadata = (full['media'] as Map?)?['metadata'] as Map?;
        if (metadata == null || metadata['series'] is! List || metadata['authors'] is! List) {
          throw StateError('Expanded book metadata unavailable. Saved library was kept.');
        }
        result.add({...item, ...full});
      }
      progress(result.length, listing.length);
    }
    return result;
  }

  Future<List<Map<String, dynamic>>> sync(ApiService api, String library,
      void Function(int, int) progress) async {
    final pending = _syncs.putIfAbsent(identity, () => _sync(api, library, progress));
    try { return await pending; }
    finally { if (identical(_syncs[identity], pending)) _syncs.remove(identity); }
  }

  Future<List<Map<String, dynamic>>> _sync(ApiService api, String library,
      void Function(int, int) progress) async {
    final listing = await fetchAll((page) => api.getLibraryItems(library,
        page: page, limit: 200, sort: 'addedAt', desc: 0, expanded: true), progress);
    // The listing API may always be minified, regardless of minified=0.
    // Batch detail provides the series IDs, authors, tracks and chapters.
    final items = await fetchDetails(listing, api.getLibraryItemsBatch, progress);
    // Expanded metadata has arrays; tiles also expect the minified name fields.
    for (final item in items) {
      final metadata = (item['media'] as Map?)?['metadata'] as Map?;
      if (metadata == null) continue;
      metadata['authorName'] ??= (metadata['authors'] as List? ?? [])
          .map((a) => (a as Map)['name'] ?? '').join(', ');
      metadata['authorNameLF'] ??= metadata['authorName'];
    }
    final file = await _file();
    final pending = File('${file.path}.pending');
    await pending.writeAsString(jsonEncode({'version': 2, 'items': items}), flush: true);
    await pending.rename(file.path);
    return items;
  }
}
