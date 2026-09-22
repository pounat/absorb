import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';
import 'package:flutter_chrome_cast/lib.dart' hide GoogleCastPlayerTexts;
import 'package:flutter_chrome_cast/themes.dart';

/// A full-screen cast player controller widget that displays media information,
/// playback controls, and cast session details.
///
/// This widget provides a rich media player interface with customizable theming
/// and text content. It supports drag-to-dismiss gestures and displays:
/// - Media artwork and title
/// - Playback progress and controls
/// - Caption/subtitle selection
/// - Volume control
/// - Cast device information
///
/// Example usage:
/// ```dart
/// ExpandedGoogleCastPlayerController(
///   toggleExpand: () => Navigator.pop(context),
///   theme: ExpandedGoogleCastPlayerTheme(
///     backgroundColor: Colors.black,
///     titleTextStyle: TextStyle(fontSize: 24, color: Colors.white),
///   ),
///   texts: ExpandedGoogleCastPlayerTexts(
///     nowPlaying: 'Now Playing',
///     unknownTitle: 'Unknown Media',
///     castingToDevice: (device) => 'Playing on $device',
///   ),
/// )
/// ```
class ExpandedGoogleCastPlayerController extends StatefulWidget {
  /// Callback function called when the user wants to collapse the expanded player
  final void Function()? toggleExpand;

  /// Theme configuration for customizing the visual appearance
  final GoogleCastPlayerTheme? theme;

  /// Text configuration for customizing all displayed text content
  final GoogleCastPlayerTexts? texts;

  /// Creates an expanded Google Cast player controller.
  const ExpandedGoogleCastPlayerController(
      {super.key, this.toggleExpand, this.theme, this.texts});

  @override
  State<ExpandedGoogleCastPlayerController> createState() =>
      _ExpandedGoogleCastPlayerControllerState();
}

class _ExpandedGoogleCastPlayerControllerState
    extends State<ExpandedGoogleCastPlayerController>
    with TickerProviderStateMixin {
  bool _isSliding = false;
  double _sliderPercentage = 0;
  late AnimationController _playPauseController;
  late AnimationController _dragController;
  double _dragOffset = 0;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _playPauseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: 1.0,
    );
    _dragController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
  }

  @override
  void dispose() {
    _playPauseController.dispose();
    _dragController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final texts = widget.texts ?? const GoogleCastPlayerTexts();
    return StreamBuilder<GoggleCastMediaStatus?>(
        stream: GoogleCastRemoteMediaClient.instance.mediaStatusStream,
        builder: (context, snapshot) {
          // Use snapshot.data to get the latest value from the stream
          final mediaStatus =
              snapshot.data ?? GoogleCastRemoteMediaClient.instance.mediaStatus;
          final deviceName = GoogleCastSessionManager
              .instance.currentSession?.device?.friendlyName;
          if (mediaStatus == null) return const SizedBox.shrink();
          return GestureDetector(
            onVerticalDragStart: (details) {
              _dragController.stop();
              setState(() {
                _isDragging = true;
              });
            },
            onVerticalDragUpdate: (details) {
              setState(() {
                _dragOffset += details.delta.dy;
                // Apply resistance when dragging upward
                if (_dragOffset < 0) {
                  _dragOffset *= 0.2; // More resistance upward
                }
                // Add some velocity-based smoothing
                final velocity = details.delta.dy.abs();
                if (velocity > 5) {
                  _dragOffset *= 0.95; // Slight smoothing for fast drags
                }
                _dragOffset = _dragOffset.clamp(-50.0, 300.0);
              });
            },
            onVerticalDragEnd: (details) {
              final velocity = details.velocity.pixelsPerSecond.dy;
              final shouldDismiss = _dragOffset > 60 ||
                  velocity > 600; // More responsive thresholds

              if (shouldDismiss) {
                widget.toggleExpand?.call();
              } else {
                // Smooth animation back to original position
                final startOffset = _dragOffset;
                _dragController.reset();

                // Create a temporary listener for this animation
                void animationListener() {
                  setState(() {
                    _dragOffset = startOffset * (1 - _dragController.value);
                  });
                }

                _dragController.addListener(animationListener);

                _dragController
                    .animateTo(
                  1.0,
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.elasticOut,
                )
                    .then((_) {
                  _dragController.removeListener(animationListener);
                  setState(() {
                    _dragOffset = 0;
                    _isDragging = false;
                  });
                });
              }
            },
            child: Transform.translate(
              offset: Offset(0, _dragOffset),
              child: Opacity(
                opacity: _isDragging
                    ? (1 - (_dragOffset / 300))
                        .clamp(0.4, 1.0) // Slower opacity fade for better UX
                    : 1.0,
                child: Scaffold(
                  extendBodyBehindAppBar: true,
                  appBar: AppBar(
                    elevation: 0,
                    backgroundColor: Colors.transparent,
                    leading: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      margin: const EdgeInsets.all(8),
                      child: IconButton(
                        onPressed: widget.toggleExpand,
                        icon: const Icon(
                          CupertinoIcons.chevron_down,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    title: Hero(
                      tag: 'com.felnanuke.google_cast.controller.title',
                      child: Text(
                        texts.nowPlaying,
                        style: theme?.titleTextStyle ??
                            Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    actions: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        margin: const EdgeInsets.all(8),
                        child: IconButton(
                          onPressed: _onCastPressed,
                          icon: const Icon(
                            Icons.cast,
                            color: Colors.white,
                          ),
                        ),
                      )
                    ],
                  ),
                  body: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (theme?.backgroundWidget != null)
                        theme!.backgroundWidget!
                      else
                        Hero(
                          tag:
                              'com.felnanuke.google_cast.controller.background',
                          child: _buildBackgroundImage(mediaStatus),
                        ),
                      // Blurred overlay for better contrast
                      BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.3),
                        ),
                      ),
                      // Drag handle indicator
                      Positioned(
                        top: 8,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: _isDragging ? 70 : 40,
                            height: _isDragging ? 5 : 4,
                            decoration: BoxDecoration(
                              color: _isDragging
                                  ? Colors.white.withValues(alpha: 0.9)
                                  : Colors.white.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(3),
                              boxShadow: _isDragging
                                  ? [
                                      BoxShadow(
                                        color:
                                            Colors.white.withValues(alpha: 0.4),
                                        blurRadius: 12,
                                        spreadRadius: 2,
                                      ),
                                    ]
                                  : [
                                      BoxShadow(
                                        color:
                                            Colors.black.withValues(alpha: 0.3),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                            ),
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(32),
                          gradient: theme?.backgroundGradient ??
                              LinearGradient(
                                  tileMode: TileMode.clamp,
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    const Color(0xFF232526),
                                    const Color(0xFF414345),
                                    Colors.black.withValues(alpha: 0.7),
                                  ]),
                        ),
                      ),
                      // Media Image Display
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Media Image
                              Container(
                                constraints: BoxConstraints(
                                  maxWidth: theme?.imageMaxWidth ?? 300,
                                  maxHeight: theme?.imageMaxHeight ?? 300,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: theme?.imageBorderRadius ??
                                      BorderRadius.circular(16),
                                  boxShadow: theme?.imageShadow ??
                                      [
                                        BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.4),
                                          blurRadius: 20,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                ),
                                child: ClipRRect(
                                  borderRadius: theme?.imageBorderRadius ??
                                      BorderRadius.circular(16),
                                  child: Hero(
                                    tag:
                                        'com.felnanuke.google_cast.controller.image',
                                    child: AspectRatio(
                                      aspectRatio: 1.0,
                                      child: _buildMediaImage(mediaStatus),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              // Media Title and Subtitle with marquee scrolling
                              Container(
                                width: double.infinity,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: _buildTitleAndSubtitle(
                                    mediaStatus, texts, theme, context),
                              ),
                              const SizedBox(
                                  height:
                                      160), // Increased space for controls and device name positioning
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom:
                            220, // Moved even higher to avoid slider overlap
                        left: 16,
                        right: 16,
                        child: Center(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 32),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              texts.castingToDevice(
                                  deviceName ?? 'Unknown Device'),
                              style: theme?.deviceTextStyle ??
                                  Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(
                                        color: Colors.white,
                                      ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 24,
                        left: 0,
                        right: 0,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 24),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  StreamBuilder<Duration?>(
                                    stream: GoogleCastRemoteMediaClient
                                        .instance.playerPositionStream,
                                    builder: (context, snapshot) {
                                      return SizedBox(
                                        width: 48,
                                        child: Text(
                                          (mediaStatus.mediaInformation
                                                          ?.streamType ==
                                                      CastMediaStreamType
                                                          .live &&
                                                  (mediaStatus.mediaInformation
                                                              ?.duration ==
                                                          null ||
                                                      mediaStatus
                                                              .mediaInformation!
                                                              .duration!
                                                              .inSeconds ==
                                                          0))
                                              ? ''
                                              : _isSliding
                                                  ? _getDurationToSeek(
                                                          _sliderPercentage,
                                                          mediaStatus)
                                                      .formatted
                                                  : GoogleCastRemoteMediaClient
                                                      .instance
                                                      .playerPosition
                                                      .formatted,
                                          style: theme?.timeTextStyle ??
                                              Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    color: Colors.white,
                                                  ),
                                        ),
                                      );
                                    },
                                  ),
                                  _buildSlider(mediaStatus, theme),
                                  SizedBox(
                                    width: 48,
                                    child: Text(
                                      (mediaStatus.mediaInformation
                                                      ?.streamType ==
                                                  CastMediaStreamType.live &&
                                              (mediaStatus.mediaInformation
                                                          ?.duration ==
                                                      null ||
                                                  mediaStatus
                                                          .mediaInformation!
                                                          .duration!
                                                          .inSeconds ==
                                                      0))
                                          ? 'LIVE'
                                          : mediaStatus.mediaInformation
                                                  ?.duration?.formatted ??
                                              '-',
                                      style: theme?.timeTextStyle ??
                                          Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: Colors.white,
                                              ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(32),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Main playback controls row
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      IconButton(
                                        onPressed: _previous,
                                        icon: const Icon(Icons.skip_previous),
                                        iconSize: theme?.iconSize ?? 40,
                                        color: theme?.iconColor ?? Colors.white,
                                      ),
                                      IconButton(
                                        onPressed: _seekBackward30,
                                        icon: const Icon(Icons.replay_30),
                                        iconSize: theme?.iconSize ?? 40,
                                        color: theme?.iconColor ?? Colors.white,
                                      ),
                                      GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onTap: () {
                                          debugPrint(
                                              '[Flutter] Play/Pause GestureDetector tapped! playerState: ${mediaStatus.playerState} (index: ${mediaStatus.playerState.index})');
                                          _togglePlayAndPause(
                                              mediaStatus.playerState);
                                          // Treat buffering as playing for animation (not loading - loading means resuming)
                                          final isPlaying = mediaStatus
                                                      .playerState ==
                                                  CastMediaPlayerState
                                                      .playing ||
                                              mediaStatus.playerState ==
                                                  CastMediaPlayerState
                                                      .buffering ||
                                              mediaStatus.playerState ==
                                                  CastMediaPlayerState.loading;
                                          if (isPlaying) {
                                            _playPauseController.reverse();
                                          } else {
                                            _playPauseController.forward();
                                          }
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          child: AnimatedIcon(
                                            icon: AnimatedIcons.play_pause,
                                            progress: _playPauseController,
                                            color: theme?.iconColor ??
                                                Colors.white,
                                            size: theme?.iconSize != null
                                                ? theme!.iconSize! + 16
                                                : 56,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: _seekForward30,
                                        icon: const Icon(Icons.forward_30),
                                        iconSize: theme?.iconSize ?? 40,
                                        color: theme?.iconColor ?? Colors.white,
                                      ),
                                      IconButton(
                                        color: theme?.iconColor ?? Colors.white,
                                        onPressed: GoogleCastRemoteMediaClient
                                                .instance.queueHasNextItem
                                            ? _next
                                            : null,
                                        disabledColor:
                                            theme?.disabledIconColor ??
                                                Colors.grey,
                                        icon: const Icon(Icons.skip_next),
                                        iconSize: theme?.iconSize ?? 40,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  // Additional controls row
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      PopupMenuButton<int>(
                                        itemBuilder: (context) =>
                                            _buildCaptionMenuItems(
                                                mediaStatus, texts, theme),
                                        onSelected: (trackId) =>
                                            _toggleTextTrack(
                                                trackId, mediaStatus),
                                        icon: Icon(
                                          Icons.closed_caption,
                                          color:
                                              theme?.iconColor ?? Colors.white,
                                        ),
                                        iconSize: theme?.iconSize ?? 40,
                                        color: theme?.popupBackgroundColor ??
                                            const Color(0xFF333333),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                      GoogleCastVolume(
                                        iconColor:
                                            theme?.iconColor ?? Colors.white,
                                        iconSize: theme?.iconSize ?? 40,
                                        popupBackgroundColor:
                                            theme?.popupBackgroundColor ??
                                                const Color(0xFF333333),
                                        sliderActiveColor:
                                            theme?.volumeSliderActiveColor,
                                        sliderInactiveColor:
                                            theme?.volumeSliderInactiveColor,
                                        sliderThumbColor:
                                            theme?.volumeSliderThumbColor,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        });
  }

  Expanded _buildSlider(
      GoggleCastMediaStatus? mediaStatus, GoogleCastPlayerTheme? theme) {
    return Expanded(
      child: StreamBuilder<Duration>(
          stream: GoogleCastRemoteMediaClient.instance.playerPositionStream,
          builder: (context, snapshot) {
            return SliderTheme(
              data: SliderTheme.of(context).copyWith(
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
                trackHeight: 4,
                activeTrackColor:
                    theme?.iconColor ?? Theme.of(context).colorScheme.primary,
                inactiveTrackColor:
                    theme?.iconColor?.withValues(alpha: 0.3) ?? Colors.white30,
                thumbColor: theme?.iconColor ?? Colors.white,
                overlayColor:
                    (theme?.iconColor ?? Colors.white).withValues(alpha: 0.2),
              ),
              child: Slider(
                value: (mediaStatus?.mediaInformation?.streamType ==
                            CastMediaStreamType.live &&
                        (mediaStatus?.mediaInformation?.duration == null ||
                            mediaStatus
                                    ?.mediaInformation?.duration?.inSeconds ==
                                0))
                    ? 1.0
                    : _isSliding
                        ? _sliderPercentage
                        : _getProgressPercentage(
                            mediaStatus,
                            GoogleCastRemoteMediaClient.instance.playerPosition,
                          ),
                onChanged: (mediaStatus?.mediaInformation?.streamType ==
                            CastMediaStreamType.live &&
                        (mediaStatus?.mediaInformation?.duration == null ||
                            mediaStatus
                                    ?.mediaInformation?.duration?.inSeconds ==
                                0))
                    ? null
                    : _onSliderChanged,
                onChangeStart: (mediaStatus?.mediaInformation?.streamType ==
                            CastMediaStreamType.live &&
                        (mediaStatus?.mediaInformation?.duration == null ||
                            mediaStatus
                                    ?.mediaInformation?.duration?.inSeconds ==
                                0))
                    ? null
                    : _onSliderStarts,
                onChangeEnd: (mediaStatus?.mediaInformation?.streamType ==
                            CastMediaStreamType.live &&
                        (mediaStatus?.mediaInformation?.duration == null ||
                            mediaStatus
                                    ?.mediaInformation?.duration?.inSeconds ==
                                0))
                    ? null
                    : (value) => _onSliderEnd.call(value, mediaStatus!),
              ),
            );
          }),
    );
  }

  void _onCastPressed() async {
    try {
      await GoogleCastSessionManager.instance.endSession();
    } catch (e) {
      // Handle potential errors silently
      // In a production app, you might want to show a snackbar or log the error
      debugPrint('Failed to end cast session: $e');
    }
  }

  void _previous() => GoogleCastRemoteMediaClient.instance.queuePrevItem();

  void _togglePlayAndPause(CastMediaPlayerState playerState) {
    debugPrint(
        '[Flutter] _togglePlayAndPause called with state: $playerState (index: ${playerState.index})');
    switch (playerState) {
      case CastMediaPlayerState.playing:
      case CastMediaPlayerState.buffering:
      case CastMediaPlayerState.loading:
        // When playing or buffering - pause the media
        debugPrint('[Flutter] Calling pause()');
        GoogleCastRemoteMediaClient.instance.pause();
        break;
      case CastMediaPlayerState.paused:
      case CastMediaPlayerState.idle:
      case CastMediaPlayerState.unknown:
        // When paused, idle, loading, or unknown - play the media
        debugPrint('[Flutter] Calling play()');
        GoogleCastRemoteMediaClient.instance.play();
        break;
    }
  }

  void _next() => GoogleCastRemoteMediaClient.instance.queueNextItem();

  void _seekBackward30() {
    debugPrint('[Flutter] _seekBackward30 called');
    GoogleCastRemoteMediaClient.instance.seek(
      GoogleCastMediaSeekOption(
        position: const Duration(seconds: -30),
        relative: true,
        resumeState: GoogleCastMediaResumeState.play,
      ),
    );
  }

  void _seekForward30() {
    GoogleCastRemoteMediaClient.instance.seek(
      GoogleCastMediaSeekOption(
        position: const Duration(seconds: 30),
        relative: true,
        resumeState: GoogleCastMediaResumeState.play,
      ),
    );
  }

  double _getProgressPercentage(
      GoggleCastMediaStatus? mediaStatus, Duration playerPosition) {
    final mediaDuration =
        mediaStatus?.mediaInformation?.duration ?? Duration.zero;

    if (mediaDuration.inSeconds == 0) return 0;

    if (playerPosition.inSeconds == 0) return 0;

    return playerPosition.inSeconds / mediaDuration.inSeconds;
  }

  void _onSliderStarts(double value) {
    setState(() {
      _isSliding = true;
      _sliderPercentage = value;
    });
  }

  void _onSliderChanged(double value) {
    setState(() {
      _sliderPercentage = value;
    });
  }

  void _onSliderEnd(double value, GoggleCastMediaStatus mediaStatus) {
    setState(() {
      _isSliding = false;
    });
    final durationToSeek = _getDurationToSeek(value, mediaStatus);
    debugPrint('[Flutter] Slider seek to: ${durationToSeek.inSeconds} seconds');
    GoogleCastRemoteMediaClient.instance.seek(
      GoogleCastMediaSeekOption(
        position: durationToSeek,
        resumeState: GoogleCastMediaResumeState.play,
      ),
    );
  }

  Duration _getDurationToSeek(double value, GoggleCastMediaStatus mediaStatus) {
    final duration = mediaStatus.mediaInformation?.duration ?? Duration.zero;
    final secondsToSeek = duration.inSeconds * value;
    final durationToSeek = Duration(seconds: secondsToSeek.round());
    return durationToSeek;
  }

  Widget _buildMediaImage(GoggleCastMediaStatus? mediaStatus) {
    final theme = widget.theme;
    final images = mediaStatus?.mediaInformation?.metadata?.images;

    // Try to find the best image (largest one or first available)
    String? imageUrl;
    if (images != null && images.isNotEmpty) {
      // Sort by size and pick the largest, or just use the first one
      final sortedImages = List<GoogleCastImage>.from(images);
      sortedImages.sort((a, b) {
        final aSize = (a.width ?? 0) * (a.height ?? 0);
        final bSize = (b.width ?? 0) * (b.height ?? 0);
        return bSize.compareTo(aSize); // Descending order
      });
      imageUrl = sortedImages.first.url.toString();
    }

    if (imageUrl != null && imageUrl.isNotEmpty) {
      return Image.network(
        imageUrl,
        fit: theme?.imageFit ?? BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: Colors.grey[800],
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
                color: Colors.white54,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) =>
            theme?.noImageFallback ??
            Container(
              color: Colors.grey[800],
              child: const Icon(
                Icons.music_note,
                size: 80,
                color: Colors.white54,
              ),
            ),
      );
    }

    // Use custom fallback or default
    return theme?.noImageFallback ??
        Container(
          color: Colors.grey[800],
          child: Icon(
            _getMediaIcon(
                mediaStatus?.mediaInformation?.metadata?.metadataType),
            size: 80,
            color: Colors.white54,
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

  Widget _buildBackgroundImage(GoggleCastMediaStatus? mediaStatus) {
    final images = mediaStatus?.mediaInformation?.metadata?.images;

    // Try to find the best image for background
    String? imageUrl;
    if (images != null && images.isNotEmpty) {
      final sortedImages = List<GoogleCastImage>.from(images);
      sortedImages.sort((a, b) {
        final aSize = (a.width ?? 0) * (a.height ?? 0);
        final bSize = (b.width ?? 0) * (b.height ?? 0);
        return bSize.compareTo(aSize); // Descending order
      });
      imageUrl = sortedImages.first.url.toString();
    }

    if (imageUrl != null && imageUrl.isNotEmpty) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: Colors.grey[900],
          child: const Icon(
            Icons.music_note,
            size: 100,
            color: Colors.white54,
          ),
        ),
      );
    }

    return Container(
      color: Colors.grey[900],
      child: Icon(
        _getMediaIcon(mediaStatus?.mediaInformation?.metadata?.metadataType),
        size: 100,
        color: Colors.white54,
      ),
    );
  }

  /// Build menu items for available text tracks
  List<PopupMenuEntry<int>> _buildCaptionMenuItems(
      GoggleCastMediaStatus? mediaStatus,
      GoogleCastPlayerTexts texts,
      GoogleCastPlayerTheme? theme) {
    final tracks = mediaStatus?.mediaInformation?.tracks;
    final activeTrackIds = mediaStatus?.activeTrackIds ?? [];

    if (tracks == null || tracks.isEmpty) {
      return [
        PopupMenuItem<int>(
          enabled: false,
          child: Text(
            texts.noCaptionsAvailable,
            style: theme?.popupTextStyle ??
                TextStyle(
                  color: theme?.popupTextColor ?? Colors.white,
                ),
          ),
        ),
      ];
    }

    final textTracks = tracks
        .where((track) =>
            track.type == TrackType.text ||
            track.subtype == TextTrackType.subtitles ||
            track.subtype == TextTrackType.captions)
        .toList();

    if (textTracks.isEmpty) {
      return [];
    }

    final menuItems = <PopupMenuEntry<int>>[];

    // Add "Off" option
    menuItems.add(
      PopupMenuItem<int>(
        value: -1,
        child: Row(
          children: [
            Icon(
              activeTrackIds.isEmpty ? Icons.check : null,
              color: theme?.popupTextColor ?? Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              texts.captionsOff,
              style: theme?.popupTextStyle ??
                  TextStyle(
                    color: theme?.popupTextColor ?? Colors.white,
                  ),
            ),
          ],
        ),
      ),
    );

    // Add available text tracks
    for (final track in textTracks) {
      final isActive = activeTrackIds.contains(track.trackId);
      menuItems.add(
        PopupMenuItem<int>(
          value: track.trackId,
          child: Row(
            children: [
              Icon(
                isActive ? Icons.check : null,
                color: theme?.popupTextColor ?? Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  track.name ??
                      track.language?.toString() ??
                      texts.trackFallback(track.trackId),
                  overflow: TextOverflow.ellipsis,
                  style: theme?.popupTextStyle ??
                      TextStyle(
                        color: theme?.popupTextColor ?? Colors.white,
                      ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return menuItems;
  }

  /// Toggle text track on/off
  void _toggleTextTrack(int trackId, GoggleCastMediaStatus? mediaStatus) {
    final activeTrackIds = List<int>.from(mediaStatus?.activeTrackIds ?? []);

    if (trackId == -1) {
      // Turn off all text tracks
      final tracks = mediaStatus?.mediaInformation?.tracks;
      if (tracks != null) {
        final textTrackIds = tracks
            .where((track) =>
                track.type == TrackType.text ||
                track.subtype == TextTrackType.subtitles ||
                track.subtype == TextTrackType.captions)
            .map((track) => track.trackId)
            .toList();

        activeTrackIds.removeWhere((id) => textTrackIds.contains(id));
      }
    } else {
      // Toggle specific track
      if (activeTrackIds.contains(trackId)) {
        activeTrackIds.remove(trackId);
      } else {
        // Remove other text tracks first (only one text track at a time)
        final tracks = mediaStatus?.mediaInformation?.tracks;
        if (tracks != null) {
          final textTrackIds = tracks
              .where((track) =>
                  track.type == TrackType.text ||
                  track.subtype == TextTrackType.subtitles ||
                  track.subtype == TextTrackType.captions)
              .map((track) => track.trackId)
              .toList();

          activeTrackIds.removeWhere((id) => textTrackIds.contains(id));
        }
        activeTrackIds.add(trackId);
      }
    }

    // Update active tracks
    GoogleCastRemoteMediaClient.instance.setActiveTrackIDs(activeTrackIds);
  }

  /// Build title and subtitle with marquee scrolling, displayed vertically
  Widget _buildTitleAndSubtitle(
      GoggleCastMediaStatus mediaStatus,
      GoogleCastPlayerTexts texts,
      GoogleCastPlayerTheme? theme,
      BuildContext context) {
    final title = mediaStatus.mediaInformation?.metadata?.extractedTitle ??
        texts.unknownTitle;
    final subtitle = mediaStatus.mediaInformation?.metadata?.extractedSubtitle;

    final titleStyle = theme?.titleTextStyle ??
        Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            );

    final subtitleStyle = theme?.titleTextStyle?.copyWith(
          fontSize: (theme.titleTextStyle?.fontSize ?? 20) * 0.8,
          fontWeight: FontWeight.normal,
          color: Colors.white70,
        ) ??
        Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white70,
              fontWeight: FontWeight.normal,
            );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Title with marquee
        SizedBox(
          height: 40,
          child: _buildMarqueeText(title, titleStyle),
        ),
        if (subtitle != null && subtitle.isNotEmpty) ...[
          const SizedBox(height: 8),
          // Subtitle with marquee - constrained height to prevent overlap
          ConstrainedBox(
            constraints: const BoxConstraints(
              maxHeight: 30,
              minHeight: 30,
            ),
            child: _buildMarqueeText(subtitle, subtitleStyle),
          ),
        ],
      ],
    );
  }

  /// Build a marquee text widget
  Widget _buildMarqueeText(String text, TextStyle? style) {
    return Marquee(
      text: text,
      style: style,
      scrollAxis: Axis.horizontal,
      crossAxisAlignment: CrossAxisAlignment.center,
      blankSpace: 50.0,
      velocity: 50.0,
      pauseAfterRound: const Duration(seconds: 2),
      startPadding: 10.0,
      accelerationDuration: const Duration(milliseconds: 500),
      accelerationCurve: Curves.linear,
      decelerationDuration: const Duration(milliseconds: 500),
      decelerationCurve: Curves.easeOut,
      startAfter: const Duration(milliseconds: 1000),
    );
  }
}
