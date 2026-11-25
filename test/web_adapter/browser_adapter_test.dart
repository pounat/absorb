import 'package:flutter_test/flutter_test.dart';
import 'package:absorb/services/browser_adapter.dart';

void main() {
  final origin = Uri.parse('https://absorb.example/absorb/#/login');
  test('web API origin excludes app path and fragment', () {
    expect(BrowserAdapter.currentOrigin(origin), 'https://absorb.example');
    expect(() => BrowserAdapter.currentOrigin(Uri.parse('file:///app')), throwsArgumentError);
  });
  test('browser requests never carry account credentials or custom headers', () {
    expect(BrowserAdapter.requestHeaders({'Authorization':'Bearer secret', 'x-refresh-token':'secret', 'X-Key':'secret'}), {'Content-Type':'application/json'});
  });
  test('request destinations reject foreign origins and query credentials', () {
    expect(BrowserAdapter.requestUri(origin, Uri.parse('https://absorb.example/api/me')).path, '/api/me');
    for (final uri in ['https://evil.example/api/me', 'https://absorb.example/api/me?token=secret', 'https://user:secret@absorb.example/api/me']) {
      expect(() => BrowserAdapter.requestUri(origin, Uri.parse(uri)), throwsArgumentError);
    }
  });
  test('MIME negotiation advertises only codec-qualified browser answers', () {
    final seen = <String>[];
    final options = BrowserAdapter.playbackOptions((mime) {
      seen.add(mime);
      return mime == 'audio/mp4; codecs="mp4a.40.2"' ? 'probably' : '';
    });
    expect(options['supportedMimeTypes'], ['audio/mp4']);
    expect(options['mediaPlayer'], 'html5');
    expect(options['forceDirectPlay'], false);
    expect(options['forceTranscode'], false);
    expect(options.containsKey('startOffset'), false);
    expect(seen, isNotEmpty);
  });
  test('media is same origin and contains no credentials; HLS fails visibly', () {
    expect(BrowserAdapter.mediaUrl(origin, '/api/items/book/file/123?token=secret'), 'https://absorb.example/api/items/book/file/123');
    for (final url in ['https://elsewhere.example/audio', '//evil.example/audio', '/hls/s/output.m3u8', '/api/items/a/file/1?accessToken=secret']) {
      expect(() => BrowserAdapter.mediaUrl(origin, url), throwsArgumentError);
    }
  });
  test('session generation rejects values outside positive JS-safe integers', () {
    for (final generation in <Object?>[
      'generation-a', '1', '', null, true, false, 0, -1, 1.5,
      double.nan, double.infinity, 9007199254740992,
    ]) {
      final sessions = BrowserSessionWrites();
      expect(() => sessions.register({'id': 'synthetic', 'webGeneration': generation}),
          throwsStateError, reason: 'Invalid generation: $generation');
      expect(() => sessions.next('synthetic'), throwsStateError);
    }
  });
  test('positive JS-safe integer generation boundaries round trip unchanged', () {
    for (final generation in [1, 9007199254740991]) {
      final sessions = BrowserSessionWrites();
      sessions.register({'id': 'synthetic', 'webGeneration': generation});
      expect(sessions.next('synthetic'), {'webGeneration': generation, 'webSequence': 1});
    }
  });
  test('session sequence is monotonic and stale generations fail closed', () {
    final sessions = BrowserSessionWrites();
    sessions.register({'id':'s', 'webGeneration':1});
    expect(sessions.next('s'), {'webGeneration':1, 'webSequence':1});
    expect(sessions.next('s')['webSequence'], 2);
    sessions.register({'id':'new', 'webGeneration':2});
    expect(() => sessions.next('s'), throwsStateError);
    expect(sessions.next('new')['webSequence'], 1);
    sessions.invalidate('new');
    expect(() => sessions.next('new'), throwsStateError);
    expect(() => sessions.register({'id':'missing'}), throwsStateError);
  });
}
