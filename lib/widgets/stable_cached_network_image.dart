import 'package:cached_network_image/cached_network_image.dart';

String stableCoverCacheKey(String imageUrl, {int? updatedAt}) {
  final uri = Uri.tryParse(imageUrl);
  if (uri == null ||
      !uri.path.contains('/api/items/') ||
      !uri.path.endsWith('/cover')) {
    return imageUrl;
  }

  final query = Map<String, String>.from(uri.queryParameters);
  final revision = updatedAt?.toString() ?? query['ts'];
  query.remove('token');
  query.remove('ts');
  if (revision != null) query['ts'] = revision;

  return uri.replace(queryParameters: query.isEmpty ? null : query).toString();
}

class StableCachedNetworkImage extends CachedNetworkImage {
  StableCachedNetworkImage({
    super.key,
    required super.imageUrl,
    required super.cacheKey,
    super.fit,
    super.httpHeaders,
    super.imageBuilder,
    super.placeholder,
    super.errorWidget,
  }) : super(useOldImageOnUrlChange: true);
}
