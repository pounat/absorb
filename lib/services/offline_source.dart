import 'package:just_audio/just_audio.dart';

import 'player_settings.dart';

/// True when a stored download location is an Android Storage Access Framework
/// content URI rather than a filesystem path. SAF custom folders store
/// content:// URIs in DownloadInfo.localPaths; everything else (iOS app-group,
/// Android internal and legacy downloads) stays a filesystem path.
bool isContentUri(String pathOrUri) => pathOrUri.startsWith('content://');

/// Extractor options applied to every book/podcast audio source. Index
/// seeking fixes seek drift in VBR mp3s; opt-in because ExoPlayer builds the
/// index by reading the file, so a seek near the end of a large mp3 has to
/// read (and for streams, download) everything up to that point first.
/// Android-only - iOS ignores androidExtractorOptions.
ProgressiveAudioSourceOptions? mp3ExtractorOptions() =>
    PlayerSettings.mp3IndexSeeking
        ? const ProgressiveAudioSourceOptions(
            androidExtractorOptions: AndroidExtractorOptions(
                mp3Flags: AndroidExtractorOptions.flagMp3EnableIndexSeeking))
        : null;

/// Build the right AudioSource for a downloaded track. Content URIs play via
/// AudioSource.uri (media3's ContentDataSource opens them through the persisted
/// SAF permission); filesystem paths play via AudioSource.file.
AudioSource localAudioSource(String pathOrUri) => isContentUri(pathOrUri)
    ? AudioSource.uri(Uri.parse(pathOrUri), options: mp3ExtractorOptions())
    : AudioSource.file(pathOrUri, options: mp3ExtractorOptions());
