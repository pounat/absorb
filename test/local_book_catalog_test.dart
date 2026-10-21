import 'package:absorb/services/local_book_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('abbreviated listings are enriched with real series membership', () async {
    final listing = <Map<String, dynamic>>[
      {'id': 'a', 'media': {'metadata': {'seriesName': 'Example'}}},
      {'id': 'b', 'media': {'metadata': {'seriesName': 'Example'}}},
    ];
    final enriched = await LocalBookCatalog.fetchDetails(listing, (ids) async =>
        ids.reversed.map((id) => <String, dynamic>{
          'id': id,
          'media': {'metadata': {
            'authors': <dynamic>[],
            'series': [{'id': 'series-1', 'name': 'Example', 'sequence': '1'}],
          }},
        }).toList(), (_, __) {});
    expect(enriched.map((i) => i['id']), ['a', 'b']);
    for (final item in enriched) {
      final series = ((item['media'] as Map)['metadata'] as Map)['series'] as List;
      expect((series.single as Map)['id'], 'series-1');
    }
  });

  test('incomplete detail responses never replace the saved catalog', () async {
    await expectLater(LocalBookCatalog.fetchDetails(
        [{'id': 'a'}], (_) async => [], (_, __) {}), throwsStateError);
    await expectLater(LocalBookCatalog.fetchDetails(
        [{'id': 'a'}], (_) async => [{'id': 'a', 'media': {'metadata': {'seriesName': 'Example'}}}],
        (_, __) {}), throwsStateError);
  });

  test('catalog identities isolate accounts, servers and libraries', () {
    final base = LocalBookCatalog('user1', 'https://a', 'books').identity;
    expect(LocalBookCatalog('user1', 'https://a', 'books').identity, base);
    expect(LocalBookCatalog('user2', 'https://a', 'books').identity, isNot(base));
    expect(LocalBookCatalog('user1', 'https://b', 'books').identity, isNot(base));
    expect(LocalBookCatalog('user1', 'https://a', 'other').identity, isNot(base));
  });

  test('catalog fetches every page before publishing a snapshot', () async {
    final seen = <int>[];
    final loaded = <int>[];
    final result = await LocalBookCatalog.fetchAll((page) async {
      seen.add(page);
      return {'total': 3, 'results': page == 0
          ? [{'id': 'a'}, {'id': 'b'}] : [{'id': 'c'}]};
    }, (count, total) => loaded.add(count));
    expect(seen, [0, 1]);
    expect(loaded, [2, 3]);
    expect(result.map((item) => item['id']), ['a', 'b', 'c']);
  });

  test('a failed later page cannot publish a partial catalog', () async {
    await expectLater(LocalBookCatalog.fetchAll((page) async => page == 0
        ? {'total': 3, 'results': [{'id': 'a'}]} : null,
        (_, __) {}), throwsStateError);
  });

  test('changed totals and duplicate items require a retry', () async {
    await expectLater(LocalBookCatalog.fetchAll((page) async => {
      'total': page == 0 ? 3 : 4, 'results': [{'id': '$page'}],
    }, (_, __) {}), throwsStateError);
    await expectLater(LocalBookCatalog.fetchAll((page) async => {
      'total': 3, 'results': [{'id': 'same'}],
    }, (_, __) {}), throwsStateError);
  });

  test('empty library is a complete snapshot', () async {
    expect(await LocalBookCatalog.fetchAll((_) async => {
      'total': 0, 'results': <Map<String, dynamic>>[],
    }, (_, __) {}), isEmpty);
  });
}
