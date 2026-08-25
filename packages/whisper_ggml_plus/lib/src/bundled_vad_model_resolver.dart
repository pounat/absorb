import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:universal_io/io.dart';

import 'models/requests/transcribe_request.dart';
import 'models/requests/whisper_vad_mode.dart';

const String _bundledVadFileName = 'ggml-silero-v6.2.0.bin';
const List<String> _bundledVadAssetKeys = <String>[
  'packages/whisper_ggml_plus/assets/models/ggml-silero-v6.2.0.bin',
  'assets/models/ggml-silero-v6.2.0.bin',
];

Future<TranscribeRequest> resolveVadModelPath(
  TranscribeRequest request,
) async {
  final String? providedPath = request.vadModelPath?.trim();
  if (request.splitOnWord || request.vadMode == WhisperVadMode.disabled) {
    return request.copyWith(vadModelPath: providedPath);
  }

  if (providedPath != null && providedPath.isNotEmpty) {
    return request.copyWith(vadModelPath: providedPath);
  }

  try {
    final String bundledPath =
        await _BundledVadModelCache.instance.ensurePath();
    return request.copyWith(vadModelPath: bundledPath);
  } catch (error) {
    if (request.vadMode == WhisperVadMode.enabled) {
      throw StateError(
        'VAD is enabled but the bundled model could not be prepared: $error',
      );
    }

    debugPrint(
      '⚠️  [WHISPER ENGINE] Falling back without VAD because the bundled '
      'model could not be prepared: $error',
    );
    return request.copyWith(vadModelPath: null);
  }
}

class _BundledVadModelCache {
  _BundledVadModelCache._();

  static final _BundledVadModelCache instance = _BundledVadModelCache._();

  Future<String>? _pathFuture;

  Future<String> ensurePath() {
    return _pathFuture ??= _extractBundledVadModel().catchError((Object error) {
      _pathFuture = null;
      throw error;
    });
  }

  Future<String> _extractBundledVadModel() async {
    final Directory baseDirectory = Platform.isIOS || Platform.isMacOS
        ? await getLibraryDirectory()
        : await getApplicationSupportDirectory();
    final Directory outputDirectory = Directory(
        '${baseDirectory.path}${Platform.pathSeparator}whisper_ggml_plus');

    if (!outputDirectory.existsSync()) {
      await outputDirectory.create(recursive: true);
    }

    final File outputFile = File(
      '${outputDirectory.path}${Platform.pathSeparator}$_bundledVadFileName',
    );
    if (outputFile.existsSync() && outputFile.lengthSync() > 0) {
      return outputFile.path;
    }

    final ByteData assetData = await _loadBundledVadAsset();
    final Uint8List bytes = assetData.buffer.asUint8List(
      assetData.offsetInBytes,
      assetData.lengthInBytes,
    );
    await outputFile.writeAsBytes(bytes, flush: true);
    return outputFile.path;
  }

  Future<ByteData> _loadBundledVadAsset() async {
    Object? lastError;
    for (final String assetKey in _bundledVadAssetKeys) {
      try {
        return await rootBundle.load(assetKey);
      } catch (error) {
        lastError = error;
      }
    }

    throw StateError(
      'Bundled VAD asset not found. Tried: ${_bundledVadAssetKeys.join(', ')}. '
      'Last error: $lastError',
    );
  }
}
