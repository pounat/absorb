import 'package:flutter_chrome_cast/lib.dart';

/// Extensions for [GoogleCastMediaMetadata] to provide additional functionality.
extension GoogleCastMediaMetadataExtensions on GoogleCastMediaMetadata {
  /// Extracts the title from the metadata based on the metadata type.
  String? get extractedTitle {
    final type = metadataType;
    String? title;
    final metadata = this;

    switch (type) {
      case GoogleCastMediaMetadataType.tvShowMediaMetadata:
        metadata as GoogleCastTvShowMediaMetadata;
        title = metadata.seriesTitle;
        break;
      case GoogleCastMediaMetadataType.genericMediaMetadata:
        metadata as GoogleCastGenericMediaMetadata;
        title = metadata.title;
        break;
      case GoogleCastMediaMetadataType.movieMediaMetadata:
        metadata as GoogleCastMovieMediaMetadata;
        title = metadata.title;
        break;
      case GoogleCastMediaMetadataType.musicTrackMediaMetadata:
        metadata as GoogleCastMusicMediaMetadata;
        title = metadata.title;
        break;
      case GoogleCastMediaMetadataType.photoMediaMetadata:
        metadata as GoogleCastPhotoMediaMetadata;
        title = metadata.title;
        break;
      default:
    }
    return title;
  }

  /// Extracts the subtitle from the metadata based on the metadata type.
  String? get extractedSubtitle {
    final type = metadataType;
    String? subtitle;
    final metadata = this;

    switch (type) {
      case GoogleCastMediaMetadataType.tvShowMediaMetadata:
        metadata as GoogleCastTvShowMediaMetadata;
        // For TV shows, create subtitle from season and episode info
        if (metadata.season != null && metadata.episode != null) {
          subtitle = 'S${metadata.season}E${metadata.episode}';
        } else if (metadata.season != null) {
          subtitle = 'Season ${metadata.season}';
        } else if (metadata.episode != null) {
          subtitle = 'Episode ${metadata.episode}';
        }
        break;
      case GoogleCastMediaMetadataType.genericMediaMetadata:
        metadata as GoogleCastGenericMediaMetadata;
        subtitle = metadata.subtitle;
        break;
      case GoogleCastMediaMetadataType.movieMediaMetadata:
        metadata as GoogleCastMovieMediaMetadata;
        subtitle = metadata.subtitle;
        break;
      case GoogleCastMediaMetadataType.musicTrackMediaMetadata:
        metadata as GoogleCastMusicMediaMetadata;
        // For music, use album name or artist as subtitle
        subtitle = metadata.albumName ?? metadata.artist;
        break;
      case GoogleCastMediaMetadataType.photoMediaMetadata:
        metadata as GoogleCastPhotoMediaMetadata;
        subtitle = metadata.artist;
        break;
      default:
    }
    //replace line breaks with spaces
    if (subtitle != null) {
      subtitle = subtitle.replaceAll('\n', ' ').replaceAll('\r', ' ');
    }
    return subtitle;
  }
}

/// Extensions for [Duration] to provide formatting functionality.
extension DurationExtension on Duration {
  /// Formats the duration as a readable string.
  String get formatted {
    int seconds = inSeconds;
    final days = seconds ~/ Duration.secondsPerDay;
    seconds -= days * Duration.secondsPerDay;
    final hours = seconds ~/ Duration.secondsPerHour;
    seconds -= hours * Duration.secondsPerHour;
    final minutes = seconds ~/ Duration.secondsPerMinute;
    seconds -= minutes * Duration.secondsPerMinute;

    final List<String> tokens = [];
    if (days != 0) {
      tokens.add('${days}d');
    }
    if (tokens.isNotEmpty || hours != 0) {
      tokens.add('$hours');
    }

    tokens.add('$minutes'.padLeft(2, '0'));

    tokens.add('$seconds'.padLeft(2, '0'));

    return tokens.join(':');
  }
}
