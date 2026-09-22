import 'package:flutter/material.dart';
import 'package:flutter_chrome_cast/lib.dart' hide GoogleCastPlayerTheme;
import 'package:marquee/marquee.dart';

import '../themes.dart';

/// A floating mini controller widget for Google Cast media playback.
///
/// This widget provides a beautiful, floating mini controller that displays:
/// - Media artwork with rounded corners and shadows
/// - Media title and casting device information
/// - Play/pause controls with theme-aware styling
/// - A sleek progress indicator
///
/// The widget consumes and respects the `ExpandedGoogleCastPlayerTheme` for consistent styling.
///
/// Example usage:
/// ```dart
/// GoogleCastMiniController(
///   theme: ExpandedGoogleCastPlayerTheme(
///     backgroundColor: Colors.white,
///     titleTextStyle: TextStyle(
///       fontSize: 16,
///       fontWeight: FontWeight.w600,
///       color: Colors.black,
///     ),
///     deviceTextStyle: TextStyle(
///       fontSize: 12,
///       color: Colors.grey[600],
///     ),
///     iconColor: Colors.blue,
///     iconSize: 28,
///     imageBorderRadius: BorderRadius.circular(12),
///     imageShadow: [
///       BoxShadow(
///         color: Colors.black26,
///         blurRadius: 8,
///         offset: Offset(0, 2),
///       ),
///     ],
///   ),
///   margin: EdgeInsets.all(16),
///   borderRadius: BorderRadius.circular(16),
///   showDeviceName: true,
/// )
/// ```
class GoogleCastMiniController extends StatefulWidget {
  /// Theme configuration for customizing the visual appearance
  final GoogleCastPlayerTheme? theme;

  /// Custom margin for the mini controller
  final EdgeInsets? margin;

  /// Custom border radius for the mini controller
  final BorderRadius? borderRadius;

  /// Whether to show the device name
  final bool showDeviceName;

  /// Creates a new [GoogleCastMiniController].
  const GoogleCastMiniController({
    super.key,
    this.theme,
    this.margin,
    this.borderRadius,
    this.showDeviceName = true,
  });

  @override
  State<GoogleCastMiniController> createState() =>
      _GoogleCastMiniControllerState();
}

class _GoogleCastMiniControllerState extends State<GoogleCastMiniController> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<GoogleCastSession?>(
        stream: GoogleCastSessionManager.instance.currentSessionStream,
        builder: (context, snapshot) {
          return StreamBuilder<GoggleCastMediaStatus?>(
            stream: GoogleCastRemoteMediaClient.instance.mediaStatusStream,
            builder: ((context, snapshot) {
              final mediaStatus = snapshot.data;
              final hasConnectedSession =
                  GoogleCastSessionManager.instance.hasConnectedSession;

              if (!hasConnectedSession) return const SizedBox.shrink();

              if (mediaStatus == null) return const SizedBox.shrink();

              if (isExpanded) {
                return ExpandedGoogleCastPlayerController(
                  toggleExpand: _toggleExpand,
                  theme: widget.theme ??
                      GoogleCastPlayerTheme(
                          titleTextStyle: TextStyle(color: Colors.white)),
                );
              }
              return Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  margin: widget.margin ?? const EdgeInsets.all(16),
                  child: _miniPlayerController(mediaStatus),
                ),
              );
            }),
          );
        });
  }

  Widget _miniPlayerController(GoggleCastMediaStatus mediaStatus) {
    final theme = widget.theme;
    final borderRadius = widget.borderRadius ?? BorderRadius.circular(16);

    return Container(
      constraints: const BoxConstraints(
        minHeight: 84,
        maxHeight: 96,
      ),
      decoration: BoxDecoration(
        color: theme?.backgroundColor ?? Colors.white,
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: borderRadius,
        child: InkWell(
          onTap: _toggleExpand,
          borderRadius: borderRadius,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _image(mediaStatus),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            minHeight: 40,
                            maxHeight: 80,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(child: _buildTitle(mediaStatus)),
                              const SizedBox(height: 2),
                              Flexible(child: _buildSubtitle(mediaStatus)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: (theme?.iconColor ?? Colors.grey[800])
                              ?.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: IconButton(
                          onPressed: () =>
                              _togglePlayAndPause.call(mediaStatus.playerState),
                          icon:
                              _getIconFromPlayerState(mediaStatus.playerState),
                          iconSize: theme?.iconSize ?? 28,
                          color: theme?.iconColor ?? Colors.grey[800],
                          padding: const EdgeInsets.all(8),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                _buildProgressIndicator(mediaStatus),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _image(GoggleCastMediaStatus mediaStatus) {
    final metadata = mediaStatus.mediaInformation?.metadata;
    final images = metadata?.images;
    final theme = widget.theme;

    if (images != null && images.isNotEmpty) {
      // Try to find the best image for the mini controller
      final sortedImages = List<GoogleCastImage>.from(images);
      sortedImages.sort((a, b) {
        final aSize = (a.width ?? 0) * (a.height ?? 0);
        final bSize = (b.width ?? 0) * (b.height ?? 0);
        return bSize.compareTo(aSize); // Descending order
      });

      return Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: theme?.imageBorderRadius ?? BorderRadius.circular(12),
          boxShadow: theme?.imageShadow ??
              [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
        ),
        child: Hero(
          tag: 'com.felnanuke.google_cast.controller.image',
          child: ClipRRect(
            borderRadius: theme?.imageBorderRadius ?? BorderRadius.circular(12),
            child: Image.network(
              sortedImages.first.url.toString(),
              fit: theme?.imageFit ?? BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius:
                        theme?.imageBorderRadius ?? BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) => Container(
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius:
                      theme?.imageBorderRadius ?? BorderRadius.circular(12),
                ),
                child: Icon(
                  _getMediaIcon(metadata?.metadataType),
                  size: 24,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Fallback when no image is available
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: theme?.imageBorderRadius ?? BorderRadius.circular(12),
        boxShadow: theme?.imageShadow ??
            [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
      ),
      child: Icon(
        _getMediaIcon(metadata?.metadataType),
        size: 24,
        color: Colors.grey[600],
      ),
    );
  }

  IconData _getMediaIcon(GoogleCastMediaMetadataType? metadataType) {
    switch (metadataType) {
      case GoogleCastMediaMetadataType.movieMediaMetadata:
        return Icons.movie;
      case GoogleCastMediaMetadataType.musicTrackMediaMetadata:
        return Icons.music_note;
      case GoogleCastMediaMetadataType.tvShowMediaMetadata:
        return Icons.tv;
      case GoogleCastMediaMetadataType.photoMediaMetadata:
        return Icons.photo;
      case GoogleCastMediaMetadataType.genericMediaMetadata:
      default:
        return Icons.play_circle_filled;
    }
  }

  /// Helper method to create scrolling text using marquee package
  Widget _buildScrollingText({
    required String text,
    required TextStyle style,
  }) {
    if (text.isEmpty) {
      return const SizedBox.shrink();
    }

    return Marquee(
      text: text,
      style: style,
      scrollAxis: Axis.horizontal,
      crossAxisAlignment: CrossAxisAlignment.start,
      blankSpace: 20.0,
      velocity: 30.0,
      pauseAfterRound: const Duration(seconds: 2),
      startPadding: 0.0,
      accelerationDuration: const Duration(seconds: 1),
      accelerationCurve: Curves.linear,
      decelerationDuration: const Duration(milliseconds: 500),
      decelerationCurve: Curves.easeOut,
    );
  }

  Widget _buildTitle(GoggleCastMediaStatus mediaStatus) {
    final title = mediaStatus.mediaInformation?.metadata?.extractedTitle ?? '';
    final theme = widget.theme;

    return Hero(
      tag: 'com.felnanuke.google_cast.controller.title',
      child: _buildScrollingText(
        text: title,
        style: theme?.titleTextStyle ??
            TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[900],
            ),
      ),
    );
  }

  Widget _buildSubtitle(GoggleCastMediaStatus mediaStatus) {
    final subtitle =
        mediaStatus.mediaInformation?.metadata?.extractedSubtitle ?? '';
    final theme = widget.theme;

    // Only show subtitle if it exists and is not empty
    if (subtitle.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildScrollingText(
      text: subtitle,
      style: (theme?.deviceTextStyle ??
              TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w400,
              ))
          .copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w300, // Slightly lighter weight for subtitle
      ),
    );
  }

  void _togglePlayAndPause(CastMediaPlayerState playerState) {
    switch (playerState) {
      case CastMediaPlayerState.playing:
      case CastMediaPlayerState.buffering:
      case CastMediaPlayerState.loading:
        // When playing or buffering - pause the media
        GoogleCastRemoteMediaClient.instance.pause();
        break;
      case CastMediaPlayerState.paused:
      case CastMediaPlayerState.idle:
      case CastMediaPlayerState.unknown:
        // When paused, idle, loading, or unknown - play the media
        GoogleCastRemoteMediaClient.instance.play();
        break;
    }
  }

  Widget _getIconFromPlayerState(CastMediaPlayerState playerState) {
    final theme = widget.theme;
    IconData iconData;
    switch (playerState) {
      case CastMediaPlayerState.playing:
      case CastMediaPlayerState.buffering:
        iconData = Icons.pause_rounded;
        break;
      case CastMediaPlayerState.paused:
      case CastMediaPlayerState.idle:
      case CastMediaPlayerState.unknown:
        iconData = Icons.play_arrow_rounded;
        break;
      case CastMediaPlayerState.loading:
        return SizedBox(
          width: theme?.iconSize ?? 28,
          height: theme?.iconSize ?? 28,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              theme?.iconColor ?? Colors.grey[800]!,
            ),
          ),
        );
    }
    return Icon(
      iconData,
      color: theme?.iconColor ?? Colors.grey[800],
      size: theme?.iconSize ?? 28,
    );
  }

  Widget _buildProgressIndicator(GoggleCastMediaStatus mediaStatus) {
    final theme = widget.theme;

    return StreamBuilder<Duration?>(
      stream: GoogleCastRemoteMediaClient.instance.playerPositionStream,
      builder: (_, snapshot) => Container(
        height: 3,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(1.5),
          color: Colors.grey[300],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(1.5),
          child: LinearProgressIndicator(
            value: getPlayerPercentage(mediaStatus, snapshot.data),
            backgroundColor: Colors.transparent,
            valueColor: AlwaysStoppedAnimation<Color>(
              theme?.iconColor ?? Colors.blue,
            ),
            minHeight: 3,
          ),
        ),
      ),
    );
  }

  void _toggleExpand() {
    setState(() {
      isExpanded = !isExpanded;
    });
  }

  Size get size => MediaQuery.of(context).size;
}
