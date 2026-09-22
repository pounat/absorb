import 'package:flutter_chrome_cast/enums/media_metadata_type.dart';
import 'cast_media_metadata.dart';

///Describes a generic media artifact.
class GoogleCastGenericMediaMetadata extends GoogleCastMediaMetadata {
  ///optional Descriptive title of the content.
  /// Player can independently retrieve title
  /// using content_id or it can be given by
  ///  the sender in the Load message
  final String? title;

  /// 	optional Descriptive subtitle of the content.
  /// Player can independently retrieve title using
  /// content_id or it can be given by the sender
  /// in the Load message
  final String? subtitle;

  ///optional Array of URL(s) to an image associated with the content.
  ///The initial value of the field can be provided by the sender in the
  ///Load message. Should provide recommended sizes

  ///optional ISO 8601 date and time
  /// this content was released. Player can
  ///  independently retrieve title using
  ///  content_id or it can be given
  ///  by the sender in the Load message
  final DateTime? releaseDate;

  /// Creates a generic media metadata instance.
  GoogleCastGenericMediaMetadata({
    this.title,
    this.subtitle,
    super.images,
    this.releaseDate,
  }) : super(metadataType: GoogleCastMediaMetadataType.genericMediaMetadata);
  @override
  Map<String, dynamic> toMap() {
    return {
      'metadataType': metadataType.value,
      'title': title,
      'subtitle': subtitle,
      'images': images?.map((x) => x.toMap()).toList(),
      'releaseDate': releaseDate?.millisecondsSinceEpoch,
    }..removeWhere((key, value) => value == null);
  }
}
