import 'package:shared_preferences/shared_preferences.dart';

/// Which kind of server an account talks to. Everything above ApiService
/// speaks Audiobookshelf shapes; a BookOrbit account gets an ApiService that
/// translates on the way in and out.
enum ServerBackend {
  audiobookshelf('abs'),
  bookorbit('bookorbit');

  const ServerBackend(this.key);

  /// Stored in prefs and saved accounts.
  final String key;

  static const prefsKey = 'server_backend';

  /// The backend of the signed-in session in this isolate. ApiService falls
  /// back to it when a caller doesn't say, so code that builds an ApiService
  /// from the stored session gets the right flavor without knowing about it.
  static ServerBackend active = ServerBackend.audiobookshelf;

  static ServerBackend fromKey(String? key) {
    for (final b in values) {
      if (b.key == key) return b;
    }
    return ServerBackend.audiobookshelf;
  }

  /// Read the stored session's backend and make it [active]. Background
  /// isolates (widgets, workers) call this before building an ApiService.
  static ServerBackend loadActive(SharedPreferences prefs) {
    active = fromKey(prefs.getString(prefsKey));
    return active;
  }

  static Future<void> saveActive(ServerBackend backend) async {
    active = backend;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefsKey, backend.key);
  }

  bool get isBookOrbit => this == ServerBackend.bookorbit;

  String get displayName => switch (this) {
        ServerBackend.audiobookshelf => 'Audiobookshelf',
        ServerBackend.bookorbit => 'BookOrbit',
      };
}
