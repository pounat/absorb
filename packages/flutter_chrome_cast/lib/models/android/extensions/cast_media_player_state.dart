import 'package:flutter_chrome_cast/enums/player_state.dart';

/// Android-specific extension for cast media player state.
extension CastMediaPlayerStateAndroid on CastMediaPlayerState {
  /// Creates a player state from a map value.
  static CastMediaPlayerState fromMap(String value) {
    return CastMediaPlayerState.values.firstWhere(
      (element) => element.name.toUpperCase() == value.toUpperCase(),
      orElse: () => CastMediaPlayerState.idle,
    );
  }
}
