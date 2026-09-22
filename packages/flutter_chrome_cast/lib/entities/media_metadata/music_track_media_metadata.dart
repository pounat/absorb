import 'package:flutter_chrome_cast/enums/media_metadata_type.dart';

import 'cast_media_metadata.dart';

///Describes a music track media artifact.
class GoogleCastMusicMediaMetadata extends GoogleCastMediaMetadata {
  /// Creates a music track media metadata instance.
  GoogleCastMusicMediaMetadata({
    this.albumName,
    this.title,
    this.albumArtist,
    this.artist,
    this.composer,
    this.trackNumber,
    this.discNumber,
    super.images,
    this.releaseDate,
  }) : super(metadataType: GoogleCastMediaMetadataType.musicTrackMediaMetadata);

  /// 	optional Album or collection from which this track
  ///  is drawn. Player can independently retrieve albumName
  ///  using content_id or it can be given by the sender
  ///  in the Load message
  final String? albumName;

  /// 	optional Name of the track
  /// (for example, song title). Player can
  ///  independently retrieve title using
  ///  content_id or it can be given by
  ///  the sender in the Load message
  final String? title;

  ///optional Name of the artist associated with
  /// the album featuring this track. Player can
  ///  independently retrieve albumArtist using
  ///  content_id or it can be given by the
  ///  sender in the Load message
  final String? albumArtist;

  ///optional Name of the artist associated
  /// with the media track. Player can
  /// independently retrieve artist using
  ///  content_id or it can be given
  ///  by the sender in the Load message
  final String? artist;

  ///optional Name of the composer associated with the
  /// media track. Player can independently retrieve
  ///  composer using content_id or it can be
  /// given by the sender in the Load message
  final String? composer;

  ///optional Number of the track on the album
  final int? trackNumber;

  ///optional Number of the volume (for example, a disc) of the album
  final int? discNumber;

  ///optional Array of URL(s) to an image associated
  ///with the content. The initial value of the
  ///field can be provided by the sender in
  ///the Load message. Should provide recommended sizes

  ///optional ISO 8601 date and time
  /// this content was released. Player
  ///  can independently retrieve releaseDate
  ///  using content_id or it can be given
  ///  by the sender in the Load message
  final DateTime? releaseDate;
  @override
  Map<String, dynamic> toMap() {
    return {
      'metadataType': metadataType.value,
      'albumName': albumName,
      'title': title,
      'albumArtist': albumArtist,
      'artist': artist,
      'composer': composer,
      'trackNumber': trackNumber,
      'discNumber': discNumber,
      'images': images?.map((x) => x.toMap()).toList(),
      'releaseDate': releaseDate?.millisecondsSinceEpoch,
    };
  }
}
