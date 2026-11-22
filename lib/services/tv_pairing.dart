import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// What the phone hands a TV so it can sign in on its own: an API key made
/// for it, or a username and password. Either way the TV ends up with a
/// session of its own and never shares the phone's.
class TvSignIn {
  final String serverUrl;
  final String backend;
  final String? apiKey;
  final String? username;
  final String? password;
  final Map<String, String> customHeaders;

  /// The server's address at home, when the phone switches to one there.
  final String? localServerUrl;

  /// Other ways the phone knows to reach the server, tried in order when
  /// the TV can't reach [serverUrl]: a name only the phone can look up
  /// (through its VPN or its own hosts) still works by its number.
  final List<String> alternates;

  /// The library the phone is on, and whether it merges them, so the TV
  /// shows the same cards.
  final String? libraryId;
  final bool mergeLibraries;

  const TvSignIn({
    required this.serverUrl,
    required this.backend,
    this.apiKey,
    this.username,
    this.password,
    this.customHeaders = const {},
    this.localServerUrl,
    this.alternates = const [],
    this.libraryId,
    this.mergeLibraries = false,
  });

  Map<String, dynamic> toJson() => {
        'v': 1,
        'serverUrl': serverUrl,
        'backend': backend,
        if (apiKey != null) 'apiKey': apiKey,
        if (username != null) 'username': username,
        if (password != null) 'password': password,
        if (customHeaders.isNotEmpty) 'customHeaders': customHeaders,
        if (localServerUrl != null) 'localServerUrl': localServerUrl,
        if (alternates.isNotEmpty) 'alternates': alternates,
        if (libraryId != null) 'libraryId': libraryId,
        if (mergeLibraries) 'mergeLibraries': true,
      };

  static TvSignIn? fromJson(Object? json) {
    if (json is! Map) return null;
    final url = json['serverUrl'];
    final backend = json['backend'];
    if (url is! String || url.isEmpty || backend is! String) return null;
    final apiKey = json['apiKey'];
    final username = json['username'];
    final password = json['password'];
    if (apiKey is! String && (username is! String || password is! String)) return null;
    final headers = json['customHeaders'];
    final local = json['localServerUrl'];
    final libraryId = json['libraryId'];
    return TvSignIn(
      serverUrl: url,
      backend: backend,
      apiKey: apiKey is String ? apiKey : null,
      username: username is String ? username : null,
      password: password is String ? password : null,
      customHeaders: headers is Map
          ? {for (final e in headers.entries) '${e.key}': '${e.value}'}
          : const {},
      localServerUrl: local is String && local.isNotEmpty ? local : null,
      alternates: [for (final a in (json['alternates'] as List? ?? const [])) if (a is String && a.isNotEmpty) a],
      libraryId: libraryId is String && libraryId.isNotEmpty ? libraryId : null,
      mergeLibraries: json['mergeLibraries'] == true,
    );
  }
}

/// The link the TV's QR code leads to, once its page passes it on:
/// absorb://tv?h=<address:port>&k=<key>.
class TvPairLink {
  static const host = 'tv';

  final String address;
  final Uint8List key;

  const TvPairLink(this.address, this.key);

  static bool isTvLink(Uri uri) =>
      uri.scheme.toLowerCase() == 'absorb' && uri.host.toLowerCase() == host;

  static TvPairLink? parse(Uri uri) {
    if (!isTvLink(uri)) return null;
    final address = uri.queryParameters['h'];
    final key = uri.queryParameters['k'];
    if (address == null || key == null) return null;
    // Only a plain address on the home network; anything else isn't a TV.
    if (!RegExp(r'^[0-9.]+:[0-9]{1,5}$').hasMatch(address)) return null;
    try {
      final bytes = base64Url.decode(base64Url.normalize(key));
      if (bytes.length != 32) return null;
      return TvPairLink(address, bytes);
    } catch (_) {
      return null;
    }
  }
}

/// Seals the sign-in under the key that only the QR code carries, so
/// nobody else on the network can read or change it on its way to the TV.
/// HMAC-SHA256 in counter mode for the bytes, then HMAC-SHA256 over the
/// result to prove it came from whoever saw the code.
@visibleForTesting
abstract final class TvPairSeal {
  static List<int> _sub(List<int> key, String label) =>
      Hmac(sha256, key).convert(utf8.encode(label)).bytes;

  static Uint8List _stream(List<int> encKey, List<int> nonce, int length) {
    final out = BytesBuilder(copy: false);
    final hmac = Hmac(sha256, encKey);
    for (var i = 0; out.length < length; i++) {
      final counter = ByteData(4)..setUint32(0, i);
      out.add(hmac.convert([...nonce, ...counter.buffer.asUint8List()]).bytes);
    }
    return Uint8List.sublistView(out.takeBytes(), 0, length);
  }

  static Uint8List seal(List<int> key, List<int> plain, {List<int>? nonce}) {
    final n = nonce ?? List<int>.generate(16, (_) => Random.secure().nextInt(256));
    final ks = _stream(_sub(key, 'absorb-tv-enc'), n, plain.length);
    final body = Uint8List(plain.length);
    for (var i = 0; i < plain.length; i++) {
      body[i] = plain[i] ^ ks[i];
    }
    final tag = Hmac(sha256, _sub(key, 'absorb-tv-mac')).convert([...n, ...body]).bytes;
    return Uint8List.fromList([...n, ...body, ...tag]);
  }

  static Uint8List? open(List<int> key, List<int> sealed) {
    if (sealed.length < 16 + 32) return null;
    final n = sealed.sublist(0, 16);
    final body = sealed.sublist(16, sealed.length - 32);
    final tag = sealed.sublist(sealed.length - 32);
    final want = Hmac(sha256, _sub(key, 'absorb-tv-mac')).convert([...n, ...body]).bytes;
    var diff = 0;
    for (var i = 0; i < 32; i++) {
      diff |= want[i] ^ tag[i];
    }
    if (diff != 0) return null;
    final ks = _stream(_sub(key, 'absorb-tv-enc'), n, body.length);
    return Uint8List.fromList([for (var i = 0; i < body.length; i++) body[i] ^ ks[i]]);
  }
}

/// The TV's end: a small web server on the home network that waits for a
/// phone to hand over a sign-in. The QR code points the phone's camera at
/// its page, which opens Absorb on the phone with the address and key.
class TvPairServer {
  static const _maxBody = 32 * 1024;
  static const _maxBadTries = 5;

  final HttpServer _server;
  final String _ip;
  final Future<String?> Function(TvSignIn) _onSignIn;
  Uint8List _key;
  int _badTries = 0;
  bool _busy = false;
  bool _closing = false;
  bool _closed = false;

  /// The address the QR code shows. Changes when too many wrong tries make
  /// the TV start over with a new key.
  final ValueNotifier<String> qrUrl;

  TvPairServer._(this._server, this._ip, this._key, this._onSignIn)
      : qrUrl = ValueNotifier(_urlFor(_ip, _server.port, _key));

  String get address => '$_ip:${_server.port}';

  static String _urlFor(String ip, int port, Uint8List key) =>
      'http://$ip:$port/#k=${base64Url.encode(key).replaceAll('=', '')}';

  static Uint8List _newKey() =>
      Uint8List.fromList(List<int>.generate(32, (_) => Random.secure().nextInt(256)));

  /// Starts listening. [onSignIn] signs the TV in and answers null, or the
  /// reason it couldn't. Null when the TV has no address on a network.
  static Future<TvPairServer?> start({required Future<String?> Function(TvSignIn) onSignIn}) async {
    final ip = await homeNetworkAddress();
    if (ip == null) return null;
    final server = await HttpServer.bind(InternetAddress.anyIPv4, 0);
    final pair = TvPairServer._(server, ip, _newKey(), onSignIn);
    server.listen(pair._handle, onError: (Object e) => debugPrint('[TvPair] server error: $e'));
    debugPrint('[TvPair] waiting on ${pair.address}');
    return pair;
  }

  /// This device's address on the home network, preferring the usual
  /// private ranges over anything else it has.
  static Future<String?> homeNetworkAddress() async {
    try {
      final interfaces = await NetworkInterface.list(type: InternetAddressType.IPv4);
      final all = [for (final i in interfaces) ...i.addresses.map((a) => a.address)];
      bool private(String a) =>
          a.startsWith('192.168.') ||
          a.startsWith('10.') ||
          RegExp(r'^172\.(1[6-9]|2[0-9]|3[01])\.').hasMatch(a);
      return all.where(private).firstOrNull ?? all.where((a) => !a.startsWith('127.')).firstOrNull;
    } catch (e) {
      debugPrint('[TvPair] no network address: $e');
      return null;
    }
  }

  /// Stops listening. A sign-in still being answered finishes first: the
  /// TV leaves this screen the moment it signs in, and the phone still needs
  /// to hear that it worked.
  Future<void> close() async {
    _closing = true;
    if (!_busy) await _shutdown();
  }

  Future<void> _shutdown() async {
    if (_closed) return;
    _closed = true;
    qrUrl.dispose();
    await _server.close(force: true);
  }

  Future<void> _handle(HttpRequest req) async {
    final res = req.response;
    try {
      if (req.method == 'GET' && req.uri.path == '/') {
        res.headers.contentType = ContentType.html;
        res.headers.set('Cache-Control', 'no-store');
        res.write(_page);
      } else if (req.method == 'POST' && req.uri.path == '/pair') {
        await _pair(req);
      } else {
        res.statusCode = HttpStatus.notFound;
      }
    } catch (e) {
      debugPrint('[TvPair] request failed: $e');
      res.statusCode = HttpStatus.internalServerError;
    }
    await res.close();
    if (_closing && !_busy) await _shutdown();
  }

  Future<void> _pair(HttpRequest req) async {
    final res = req.response;
    final bytes = BytesBuilder(copy: false);
    await for (final chunk in req) {
      bytes.add(chunk);
      if (bytes.length > _maxBody) {
        res.statusCode = HttpStatus.requestEntityTooLarge;
        return;
      }
    }
    Uint8List? plain;
    try {
      plain = TvPairSeal.open(_key, base64Url.decode(base64Url.normalize(utf8.decode(bytes.takeBytes()).trim())));
    } catch (_) {}
    final signIn = plain == null ? null : TvSignIn.fromJson(_tryJson(plain));
    if (signIn == null) {
      if (++_badTries >= _maxBadTries) {
        debugPrint('[TvPair] too many wrong tries, starting over with a new code');
        _badTries = 0;
        _key = _newKey();
        qrUrl.value = _urlFor(_ip, _server.port, _key);
      }
      res.statusCode = HttpStatus.forbidden;
      return;
    }
    if (_busy) {
      res.statusCode = HttpStatus.conflict;
      return;
    }
    _busy = true;
    String? error;
    try {
      error = await _onSignIn(signIn);
    } catch (e) {
      error = '$e';
    }
    res.headers.contentType = ContentType.json;
    res.write(jsonEncode({'ok': error == null, if (error != null) 'error': error}));
    // Cleared once the answer is written, so a close that came in meanwhile
    // waits for the response to go out in _handle.
    _busy = false;
  }

  static Object? _tryJson(List<int> bytes) {
    try {
      return jsonDecode(utf8.decode(bytes));
    } catch (_) {
      return null;
    }
  }

  static const _page = '''<!doctype html>
<html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Absorb</title>
<style>
body{font-family:system-ui,sans-serif;background:#0e0e0e;color:#eee;margin:0;padding:48px 24px;text-align:center}
h1{font-size:22px;font-weight:600;margin:0 0 12px}
p{color:#aaa;line-height:1.5;margin:0 0 28px}
a{display:inline-block;background:#7c6fbf;color:#fff;text-decoration:none;padding:14px 28px;border-radius:999px;font-weight:600}
</style></head>
<body><h1>Sign in your TV</h1>
<p>Open this in Absorb on your phone. You need to be signed in there first.</p>
<a id="go" href="#">Open in Absorb</a>
<script>
var m=location.hash.match(/k=([A-Za-z0-9_-]+)/);
if(m){var u='absorb://tv?h='+encodeURIComponent(location.host)+'&k='+m[1];
document.getElementById('go').href=u;location.href=u;}
</script></body></html>''';
}

enum TvSendError { refused, busy, noAnswer, unreachable, failed }

/// The phone's end: seals [signIn] for the TV behind [link] and sends it.
/// No error once the TV says it signed in; otherwise why not, with the TV's
/// own words when it gave any.
Future<({TvSendError? error, String? detail})> sendSignInToTv(
  TvPairLink link,
  TvSignIn signIn, {
  http.Client? client,
}) async {
  final sealed = TvPairSeal.seal(link.key, utf8.encode(jsonEncode(signIn.toJson())));
  final c = client ?? http.Client();
  try {
    final r = await c
        .post(Uri.parse('http://${link.address}/pair'), body: base64Url.encode(sealed))
        .timeout(const Duration(seconds: 45));
    if (r.statusCode == HttpStatus.forbidden) return (error: TvSendError.refused, detail: null);
    if (r.statusCode == HttpStatus.conflict) return (error: TvSendError.busy, detail: null);
    if (r.statusCode != 200) return (error: TvSendError.failed, detail: 'HTTP ${r.statusCode}');
    final body = jsonDecode(r.body);
    if (body is Map && body['ok'] == true) return (error: null, detail: null);
    return (error: TvSendError.failed, detail: body is Map ? body['error'] as String? : null);
  } on TimeoutException {
    return (error: TvSendError.noAnswer, detail: null);
  } on SocketException {
    return (error: TvSendError.unreachable, detail: null);
  } on http.ClientException {
    return (error: TvSendError.unreachable, detail: null);
  } catch (e) {
    return (error: TvSendError.failed, detail: '$e');
  } finally {
    if (client == null) c.close();
  }
}
