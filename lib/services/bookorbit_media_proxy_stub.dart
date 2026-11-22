/// Web stand-in for the BookOrbit media proxy, which needs dart:io. URLs
/// pass straight to the server, so media on web only loads where the
/// browser already holds a BookOrbit session.
abstract class BookOrbitTokenSource {
  String get upstreamBaseUrl;
  Map<String, String> get upstreamCustomHeaders;
  Future<String?> currentAccessToken();
  Future<String?> tokenAfterRejection();
}

class BookOrbitMediaProxy {
  BookOrbitMediaProxy._();
  static final BookOrbitMediaProxy instance = BookOrbitMediaProxy._();

  BookOrbitTokenSource? _source;

  bool get isReady => _source != null;

  void attach(BookOrbitTokenSource source) => _source = source;

  String urlFor(String serverPathAndQuery) =>
      '${_source?.upstreamBaseUrl ?? ''}$serverPathAndQuery';

  bool owns(String url) => false;

  String? upstreamUrlFor(String proxyUrl) => proxyUrl;

  Future<void> ensureRunning() async {}

  Future<void> stop() async {}
}
