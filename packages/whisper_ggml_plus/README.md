<div align="center">

# Whisper GGML Plus

_On-device Whisper.cpp transcription for Flutter on Android, iOS, Linux, macOS, and Windows._

<p align="center">
  <a href="https://pub.dev/packages/whisper_ggml_plus">
     <img src="https://img.shields.io/pub/v/whisper_ggml_plus?logo=dart" alt="pub">
  </a>
</p>
</div>

`whisper_ggml_plus` is for Flutter apps that want local Whisper inference without sending audio to a remote service. It is built around file-based transcription, so the package works best when your app can provide a finished audio file path and let Whisper process it in batch.

## Why use `whisper_ggml_plus`

The goal of this package is to give Flutter developers a practical Whisper.cpp integration that feels native to a Flutter app, while still exposing the important controls that affect quality, speed, and platform behavior.

- Cross-platform Flutter FFI plugin for on-device transcription
- Whisper.cpp v1.8.3 engine with Large-v3-Turbo support
- File-based batch transcription from local audio files
- Optional audio conversion via the `whisper_ggml_plus_ffmpeg` companion package
- Configurable VAD through `WhisperVadMode`
- Optional Metal and CoreML acceleration on iOS and macOS
- Windows support is available in the current package release

## Supported platforms

The package currently declares support for all of the platforms below. Apple platforms can optionally use extra acceleration paths, while the other platforms use the standard FFI flow.

| Platform | Support | Notes |
| --- | --- | --- |
| Android | ✅ | File-based transcription |
| iOS | ✅ | Metal, optional CoreML |
| Linux | ✅ | FFI plugin |
| macOS | ✅ | Metal, optional CoreML |
| Windows | ✅ | FFI plugin, example support |

## Android note

The plugin now requests 16 KB-compatible native linking for 64-bit Android builds via its native linker configuration. Final APK/AAB packaging may still depend on the consuming app, including whether it uses a modern AGP version or legacy native library packaging settings.

## What this package does

At a high level, the package takes an audio file path, prepares the matching GGML model path, and runs Whisper.cpp locally through FFI. If your app already works with saved audio files, this package is designed for that workflow.

- Transcribes completed audio files from `audioPath`
- Works with predefined `WhisperModel` enums
- Can download official GGML models with `WhisperController.downloadModel()`
- Supports timestamps, `splitOnWord`, VAD, `abort()`, and `dispose()`

## What this package does not do yet

It is useful to be explicit about the current scope so users know where the package boundary is.

- Stream partial transcription tokens while recording
- Provide a built-in microphone capture UI
- Bundle CoreML `.mlmodelc` directories through Flutter assets

## Quick start

The simplest way to think about setup is this:

1. add the core package
2. make sure you have a GGML model file available
3. pass a local audio file path into `transcribe(...)`

If your app already produces 16 kHz mono WAV files, the core package is often enough on its own.

### Install the core package

```bash
flutter pub add whisper_ggml_plus
```

### If your audio is already 16 kHz mono WAV

Use the core package directly and call `transcribe(...)` with the WAV file path.

```dart
import 'package:whisper_ggml_plus/whisper_ggml_plus.dart';

final controller = WhisperController();

final result = await controller.transcribe(
  model: WhisperModel.base,
  audioPath: wavPath,
  lang: 'auto',
);
```

### If your audio is MP3, M4A, MP4, or another format

The core package no longer bundles FFmpeg. That keeps the base package smaller and avoids forcing one conversion strategy on every app.

If your app needs automatic conversion, register a converter from the companion package once at app startup.

```bash
flutter pub add whisper_ggml_plus_ffmpeg
```

```dart
import 'package:whisper_ggml_plus/whisper_ggml_plus.dart';
import 'package:whisper_ggml_plus_ffmpeg/whisper_ggml_plus_ffmpeg.dart';

void main() {
  WhisperFFmpegConverter.register();
  runApp(const MyApp());
}
```

After that, you can keep calling `transcribe(...)` with common audio formats and let the registered converter handle preprocessing before Whisper runs.

## Model setup

The package expects a GGML `.bin` model file in app-writable storage. In practice, most apps do one of two things:

- copy a bundled `.bin` asset into an app-writable directory on first run
- download the model on demand with `WhisperController.downloadModel()`

The package supports both approaches.

```dart
final controller = WhisperController();

await controller.downloadModel(WhisperModel.base);
final modelPath = await controller.getPath(WhisperModel.base);
print(modelPath);
```

Notes:
- `downloadModel()` uses the official `ggerganov/whisper.cpp` GGML model URLs defined by `WhisperModel`.
- `getPath()` is useful when you want to copy a bundled `.bin` asset into the app's model directory before transcribing.
- CoreML `.mlmodelc` is optional and separate from the `.bin` model file.

## Basic usage

Once the model file exists, the basic transcription flow is intentionally small. Most apps can start from this and then add VAD, timestamps, or conversion only when needed.

```dart
import 'package:whisper_ggml_plus/whisper_ggml_plus.dart';

final controller = WhisperController();

final result = await controller.transcribe(
  model: WhisperModel.largeV3Turbo,
  audioPath: audioPath,
  lang: 'auto',
  withTimestamps: true,
  threads: 6,
  vadMode: WhisperVadMode.auto,
);

if (result != null) {
  print(result.transcription.text);
}
```

## Voice activity detection (VAD)

`whisper_ggml_plus` exposes VAD policy through `WhisperVadMode`.

This is useful when you want a more explicit tradeoff between silence trimming and timestamp behavior, instead of relying on one fixed package default.

```dart
final result = await controller.transcribe(
  model: WhisperModel.base,
  audioPath: audioPath,
  vadMode: WhisperVadMode.auto,
);
```

- `WhisperVadMode.auto`: automatically uses the bundled Silero VAD model when available.
- `WhisperVadMode.disabled`: always turns VAD off.
- `WhisperVadMode.enabled`: forces VAD on and uses the bundled model by default unless you override it with `vadModelPath`.

For lower-level control, pass `vadMode` and `vadModelPath` directly through `TranscribeRequest`.

```dart
final controller = WhisperController();
await controller.downloadModel(WhisperModel.base);

final response = await Whisper(model: WhisperModel.base).transcribe(
  transcribeRequest: TranscribeRequest(
    audio: audioPath,
    vadMode: WhisperVadMode.enabled,
    vadModelPath: '/absolute/path/to/ggml-silero-v6.2.0.bin',
  ),
  modelPath: await controller.getPath(WhisperModel.base),
);
```

## Word-level timestamps and `splitOnWord`

`splitOnWord` is a timestamp-sensitive mode. This package disables VAD automatically when `splitOnWord` is enabled so that word-level timestamps stay more stable and predictable.

That behavior is worth calling out because users often expect VAD and word-level timestamps to compose cleanly, but in practice VAD can make token-level timing harder to reason about.

```dart
final controller = WhisperController();
await controller.downloadModel(WhisperModel.base);

final response = await Whisper(model: WhisperModel.base).transcribe(
  transcribeRequest: TranscribeRequest(
    audio: audioPath,
    splitOnWord: true,
    vadMode: WhisperVadMode.auto,
  ),
  modelPath: await controller.getPath(WhisperModel.base),
);
```

Notes:
- `splitOnWord: true` uses token-level timestamps.
- VAD is forced off for this mode even if `vadMode` is `auto` or `enabled`.
- If you want stronger silence trimming, keep `splitOnWord` off and use segment-level timestamps instead.

## Batch transcription, abort, and dispose

`whisper_ggml_plus` currently supports file-based batch transcription from `audioPath`.

That means the package fits very well when your app already saves audio to disk first, but it is not yet a streaming speech-to-text API.

- `transcribe(...)` processes completed audio files.
- Partial streaming transcription while recording is not exposed in the current API.
- `abort()` can stop an in-flight batch transcription.
- `dispose()` releases native resources for the active model context.

```dart
final whisper = Whisper(model: WhisperModel.base);

await whisper.abort();
await whisper.dispose();
```

## Example app

The example app in `/example` shows one complete Flutter flow on top of the package. It is intentionally more detailed than the main README and is the best place to look if you want to see how recording, model setup, and sample-file transcription fit together in one app.

- record WAV audio in the app with `record`
- transcribe the bundled `jfk.wav` sample file
- copy a GGML model asset or fall back to `downloadModel()`
- run on Android, iOS, macOS, and Windows

See [`example/README.md`](example/README.md) for the demo app instructions.

## Performance tips

Performance depends heavily on model size, quantization, platform, and whether you are testing in debug or release mode. The tips below are the most important defaults for practical Flutter usage.

- Test performance in `--release` mode.
- Prefer quantized models such as `q5_0` or `q3_k` to reduce memory use.
- Use `WhisperModel.base` or `WhisperModel.small` for more practical mobile defaults.
- Use `WhisperModel.largeV3Turbo` when you want the best accuracy and can afford the memory and runtime cost.

## Optional CoreML acceleration on iOS and macOS

This section is only for Apple-platform acceleration. It is not required for Android, Linux, Windows, or standard CPU/GPU usage on Apple platforms.

If you are just trying to get the package running for the first time, you can skip this section and come back later. CoreML is an optimization path, not a requirement for basic package usage.

### What is `.mlmodelc`?

`.mlmodelc` is a compiled CoreML model directory, not a single file. A typical directory contains:

- `model.mil`
- `coremldata.bin`
- `metadata.json`

Important:
- `.mlmodelc` must remain a directory.
- Flutter assets cannot bundle it correctly.
- It must live next to the GGML `.bin` model file with a matching base name.

### 1. Generate a CoreML encoder

```bash
git clone https://github.com/ggerganov/whisper.cpp
cd whisper.cpp

python3.11 -m venv venv
source venv/bin/activate

pip install torch==2.5.0 "numpy<2.0" coremltools==8.1 openai-whisper ane_transformers

./models/generate-coreml-model.sh large-v3-turbo
```

Example output:

```text
models/ggml-large-v3-turbo-encoder.mlmodelc/
```

### 2. Deploy the CoreML model

#### Option A: download at runtime

```dart
import 'dart:io';

import 'package:path_provider/path_provider.dart';

Future<String> prepareModelDir() async {
  final appSupport = await getApplicationSupportDirectory();
  final modelDir = Directory('${appSupport.path}/models');
  await modelDir.create(recursive: true);

  final coremlDir =
      Directory('${modelDir.path}/ggml-large-v3-turbo-encoder.mlmodelc');

  if (!await coremlDir.exists()) {
    await coremlDir.create(recursive: true);
    // Download each file in the .mlmodelc directory from your own storage.
  }

  return modelDir.path;
}
```

#### Option B: add it as an Xcode folder reference

1. Open `ios/Runner.xcworkspace` or the macOS runner in Xcode.
2. Drag the `.mlmodelc` folder into the project.
3. Choose **Create folder references**, not **Create groups**.
4. Add it to the correct target.

### 3. Keep the naming and placement consistent

```text
/app/support/models/
├── ggml-large-v3-turbo-q3_k.bin
└── ggml-large-v3-turbo-encoder.mlmodelc/
    ├── model.mil
    ├── coremldata.bin
    └── metadata.json
```

Naming convention:
- GGML model: `ggml-{model-name}-{quantization}.bin`
- CoreML model: `ggml-{model-name}-encoder.mlmodelc/`

Examples:
- `ggml-large-v3-turbo-q3_k.bin` + `ggml-large-v3-turbo-encoder.mlmodelc/`
- `ggml-base-q5_0.bin` + `ggml-base-encoder.mlmodelc/`

### 4. Use the normal transcription API

```dart
final result = await WhisperController().transcribe(
  model: WhisperModel.largeV3Turbo,
  audioPath: audioPath,
);
```

Whisper.cpp automatically looks for the matching `-encoder.mlmodelc` directory next to the `.bin` model and uses it when available.

### Troubleshooting CoreML

Common causes of CoreML not loading:

1. The `.mlmodelc` path is wrong.
2. The `.mlmodelc` item is a file instead of a directory.
3. The directory is not next to the `.bin` model.
4. The base names do not match.
5. The model was bundled through Flutter assets instead of runtime storage or Xcode folder references.

## License

MIT License - Based on the original work by sk3llo/whisper_ggml.
