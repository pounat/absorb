## [1.3.3](https://github.com/DDULDDUCK/whisper_ggml_plus/compare/v1.3.2...v1.3.3) (2026-02-24)


### Bug Fixes

* clarify release-please changelog and notes generation ([56d8b23](https://github.com/DDULDDUCK/whisper_ggml_plus/commit/56d8b2345c1832409b40a82b5db1e3ac39d86287))

## [1.5.2](https://github.com/DDULDDUCK/whisper_ggml_plus/compare/v1.5.1...v1.5.2) (2026-04-01)


### Bug Fixes

* exclude local artifacts from published package ([d2e1ace](https://github.com/DDULDDUCK/whisper_ggml_plus/commit/d2e1ace8539ff912b0aee97203f35b4e736a9b84))

## [1.5.1](https://github.com/DDULDDUCK/whisper_ggml_plus/compare/v1.5.0...v1.5.1) (2026-04-01)


### Bug Fixes

* enforce 16 KB page alignment for Android builds ([5ea1416](https://github.com/DDULDDUCK/whisper_ggml_plus/commit/5ea1416bb856ae91a53c140681a233721208e0fd))

## [1.5.0](https://github.com/DDULDDUCK/whisper_ggml_plus/compare/v1.4.2...v1.5.0) (2026-03-23)


### Features

* windows build ([7927493](https://github.com/DDULDDUCK/whisper_ggml_plus/commit/7927493cd76b7b211cd96d9163b6b453cb7ff65e))

## [1.4.2](https://github.com/DDULDDUCK/whisper_ggml_plus/compare/v1.4.1...v1.4.2) (2026-03-17)


### Bug Fixes

* restore Android and iOS native build wiring ([8b0ac82](https://github.com/DDULDDUCK/whisper_ggml_plus/commit/8b0ac82b6e43638ee370633d144220670e396b58))

## [1.4.1](https://github.com/DDULDDUCK/whisper_ggml_plus/compare/v1.4.0...v1.4.1) (2026-03-11)


### Bug Fixes

* clean up Dart bridge request handling ([4787819](https://github.com/DDULDDUCK/whisper_ggml_plus/commit/47878190d027e9b12d2669e7f949c52a73af4847))
* export native response cleanup hooks on Apple and Android ([545b420](https://github.com/DDULDDUCK/whisper_ggml_plus/commit/545b420b74d9f1754abdc7260052594f4bc34abd))
* harden Windows native bridge ownership and WAV paths ([f04bfdc](https://github.com/DDULDDUCK/whisper_ggml_plus/commit/f04bfdc8242f0bdd0df24313cc4f1f9306551f75))
* repair Windows backend path conversion ([461d6c9](https://github.com/DDULDDUCK/whisper_ggml_plus/commit/461d6c98bd527c19e89cb7d75cc9e4f93aa8b180))
* restore bundled VAD defaults across platforms ([3bb2166](https://github.com/DDULDDUCK/whisper_ggml_plus/commit/3bb21662f3ff5d44441d42b48a53a86d095c9552))

## [1.4.0](https://github.com/DDULDDUCK/whisper_ggml_plus/compare/v1.3.5...v1.4.0) (2026-03-09)


### Features

* expose configurable VAD mode in Dart requests ([4bd3b2c](https://github.com/DDULDDUCK/whisper_ggml_plus/commit/4bd3b2cfad2fd50296c66fe2a9b55dc8459a180a))


### Bug Fixes

* add Windows FFI wrapper and loader support ([3987e27](https://github.com/DDULDDUCK/whisper_ggml_plus/commit/3987e27f04dbfed3bc77e65daedd128c860a1b3f))
* apply explicit VAD policy across transcription backends ([08651d1](https://github.com/DDULDDUCK/whisper_ggml_plus/commit/08651d13cc5374abd745ee83bf2207118096b887))

## [1.3.5](https://github.com/DDULDDUCK/whisper_ggml_plus/compare/v1.3.4...v1.3.5) (2026-02-25)


### Bug Fixes

* add missing includes for Android build (GGML_VERSION, WHISPER_VERSION, android/log.h) ([4d07ce2](https://github.com/DDULDDUCK/whisper_ggml_plus/commit/4d07ce21de64e5c3e7a638beda2a5ffd2c9f4c64))
* add missing includes for Android build. ([c5a3155](https://github.com/DDULDDUCK/whisper_ggml_plus/commit/c5a3155d95107b4afd9b89ae72e793a39d160868))

## [1.3.4](https://github.com/DDULDDUCK/whisper_ggml_plus/compare/v1.3.3...v1.3.4) (2026-02-24)


### Bug Fixes

* align pub trusted publisher workflow with tag push ([9738337](https://github.com/DDULDDUCK/whisper_ggml_plus/commit/9738337b8d20c5d624c87109490e70f0ebec2146))

## 1.3.2

* **Android Build Fix**: Fixed `android/src/whisper/CMakeLists.txt` source and include paths to match the current whisper.cpp directory layout.
* **CMake Stability**: Updated ABI condition checks to avoid configuration failures when `ANDROID_ABI` is not set.
* **Memory Lifecycle API**: Added explicit native context disposal route (`dispose`) across Android, iOS, and macOS bridges.
* **Dart API Update**: Added `Whisper.dispose()` and `WhisperController.dispose()` for explicit context release from Flutter.
* **Documentation**: Clarified that live streaming transcription while recording is not yet supported in the current API.
* **Release Automation**: Added Release Please, pub.dev publish workflow, PR labeler, and stale issue/PR maintenance workflows.

## 1.3.1

* **Cleanup**: Removed unused imports and legacy conversion logic in `WhisperController`.
* **Stability**: Refined internal audio conversion routing for better error handling.
* **Documentation**: Fully restored and updated CoreML acceleration guides in README.

## 1.3.0

* **FFmpeg Decoupling**: Removed `ffmpeg_kit_flutter_new_min` from core dependencies to prevent version conflicts with other FFmpeg-related packages.
* **Extensible Audio Conversion**: Introduced `WhisperAudioConverter` interface and `WhisperController.registerAudioConverter()` for flexible audio preprocessing.
* **New Companion Package**: Released `whisper_ggml_plus_ffmpeg` for users who need automatic FFmpeg-based conversion.
* **Optimization**: Core package is now significantly smaller and more compatible with various app configurations.

## 1.2.19

* **Build Compatibility**: Fixed `std::filesystem` compilation error on iOS/Apple platforms.
* **Compatibility**: Disabled dynamic backend loading on Apple platforms to resolve `u8path` unavailability in older iOS SDKs.
* **CoreML Troubleshooting**: Added guidance for `.mlmodelc` directory structure requirements.

## 1.2.18

* **Native Logging Overhaul**:
    * Moved transcription time measurement to the C++ native layer for more accurate and immediate logging.
    * Added `fflush(stderr)` to ensure debug logs appear instantly in the Flutter console even when the main thread is busy.
    * Added precise AI inference time tracking using `std::chrono`.
* **Flutter Controller Refinement**:
    * Cleaned up redundant logging in Dart and synchronized output with native events.

## 1.2.17

* **Native Build Fix (Final)**: Resolved remaining compilation errors in debug logs by switching from `wparams.speed_up` to `params.speed_up`.
* **Platform Coverage**: Applied the fix across iOS, Android, and macOS native implementations.

## 1.2.16

* **Native Build Fix**: Resolved `No member named 'speed_up'` error by aligning with the latest `whisper.cpp` v1.8.3 engine parameters.
* **Performance**: Replaced deprecated `speed_up` flag with `audio_ctx` optimization for improved inference speed when `speedUp` is enabled in Dart.
* **Stability**: Ensured cross-platform consistency for all native engine configurations (iOS, Android, macOS).

## 1.2.15

* **Dependency Updates**: Updated all package dependencies to their latest compatible versions.
    * `ffi` to `^2.1.5`
    * `ffmpeg_kit_flutter_new_min` to `^3.1.0`
    * `freezed_annotation` to `^3.1.0`
    * `json_annotation` to `^4.10.0`
    * `universal_io` to `^2.3.1`
    * `flutter_riverpod` updated to support up to `^3.2.0` (via range constraint `'>=2.6.1 <4.0.0'`).
* **Dev Dependencies**: Updated `ffigen`, `json_serializable`, and `very_good_analysis` to their latest versions.

## 1.2.14

* **Multi-Platform Parameter Sync**: Fixed `speedUp` and `threads` parameters not being correctly passed to native engines on Android and macOS.
* **Enhanced Native Logging**: Added detailed parameter status (threads, speed_up) to native debug logs across all platforms.
* **Bug Fix**: Ensured all performance optimization options are consistently applied at the C++ engine level.

## 1.2.13

* **Performance Optimization Options**:
    * Added `threads` parameter to customize CPU core usage (default: 6).
    * Added `speedUp` parameter for 2-3x faster inference by skipping audio features (at slight accuracy cost).
    * Added `isTranslate` parameter for automatic translation to English.
* **DevOps Automation**:
    * Added GitHub Actions workflow for automated releases based on `CHANGELOG.md` notes when version tags are pushed.
* **Debug Logging**: Improved transcription status and performance metrics visibility in console.

## 1.2.12

* **Large-v3-Turbo & CoreML Enhancements**:
    * Added explicit `WhisperModel.largeV3Turbo` enum for better model path management.
    * Improved documentation for CoreML naming conventions (requires 5-character quantization suffix like `-q5_0.bin` for auto-detection).
* **New Transcription Options**:
    * Added `withTimestamps` parameter to `WhisperController.transcribe` (defaults to `true`).
    * Added `convert` parameter to `WhisperController.transcribe` (defaults to `true`) to allow skipping FFmpeg conversion for already optimized WAV files.
* **Optimization**: Refactored `Whisper.transcribe` to remove redundant conversion logic and centralized it in the controller.

## 1.2.11

* **Documentation Enhancement**: Comprehensive CoreML setup guide to prevent common deployment mistakes.
* **Critical Information Added**: 
  - `.mlmodelc` is a directory (not a single file) containing multiple files (model.mil, coremldata.bin, metadata.json)
  - Cannot be bundled via Flutter assets - directory structure breaks during asset compilation
  - Must be deployed via runtime download or native bundle (Xcode folder references)
  - Must be placed in same directory as GGML .bin model with matching base name
* **README Updates**:
  - Added detailed CoreML deployment section with two methods (runtime download vs Xcode bundle)
  - Added troubleshooting section with log examples for CoreML loading failures
  - Added performance comparison table (CoreML NPU vs Metal GPU vs CPU)
  - Added automatic detection mechanism explanation
* **Example Code Documentation**:
  - Added 44-line header comment in `example/lib/main.dart` explaining CoreML setup (visible on pub.dev)
  - Added inline comments warning against Flutter assets usage for `.mlmodelc`
  - Added CoreML auto-detection explanation in transcription code
* **New Example README**: Complete setup guide with model download, CoreML generation, deployment options, and troubleshooting scenarios.
* **Impact**: Users will now understand `.mlmodelc` directory structure and avoid the critical mistake of trying to bundle it via Flutter assets.

## 1.2.10

* **UTF-8 Error Handler Fix**: Changed JSON error handling strategy from `strict` to `replace` to handle malformed UTF-8 sequences from Whisper.cpp output.
* **Root Cause**: Whisper.cpp can produce truncated multibyte UTF-8 sequences (e.g., `0xEC` without following bytes) due to buffer limits or audio cutoffs. The `strict` error handler would abort during validation before `ensure_ascii` could escape the characters.
* **Solution**: 
  - Changed `nlohmann::json::error_handler_t::strict` → `error_handler_t::replace` in all platforms
  - Malformed UTF-8 bytes are now replaced with Unicode replacement character (U+FFFD `�`) instead of crashing
  - Added try-catch safety wrapper with fallback error JSON
* **Impact**: Transcriptions with Korean/CJK text will no longer crash with `[json.exception.type_error.316]` errors, even when Whisper outputs incomplete multibyte sequences.
* Applied to iOS, macOS, and Android platforms.

## 1.2.9

* **UTF-8 Encoding Fix**: Fixed JSON parsing error with non-ASCII characters (Korean, Chinese, Japanese, etc.) in transcription results.
* **Root Cause**: `nlohmann::json::dump()` was outputting raw UTF-8 bytes, which caused issues when passing through FFI boundary to Dart. Error: `[json.exception.type_error.316] invalid UTF-8 byte at index N`.
* **Solution**: Added `ensure_ascii` flag to JSON serialization - non-ASCII characters are now escaped as `\uXXXX` Unicode escape sequences.
* **Impact**: Transcriptions with Korean/CJK characters now parse correctly without UTF-8 decoding errors.
* Applied fix to iOS, macOS, and Android platforms.

## 1.2.8

* **Enhanced CoreML Debugging**: Added comprehensive debug logging to diagnose CoreML loading failures.
* **Pre-validation Checks**: Added file existence and directory validation before attempting CoreML model initialization.
* **Detailed Error Reporting**: 
  - Logs exact file path being attempted
  - Reports whether file exists and if it's a directory (CoreML models must be directories)
  - Lists parent directory contents when model not found
  - Captures and logs full NSError details (domain, code, description)
* **Purpose**: Help users identify why CoreML models fail to load (missing file, wrong path, format issues, etc.)
* Use these logs to troubleshoot CoreML deployment issues - check for `[CoreML Debug]` and `[CoreML Error]` tags in device console.

## 1.2.7

* **CoreML Activation Fix**: Fixed CoreML (NPU) not being detected despite setup due to incorrect compiler flag.
* **Root Cause**: Podspec defined `-DWHISPER_COREML` but whisper.cpp source code checks for `#ifdef WHISPER_USE_COREML` (different flag name), causing CoreML detection code to be excluded at compile time.
* **Solution**: Changed iOS/macOS podspecs to use correct `-DWHISPER_USE_COREML` flag matching whisper.cpp expectations.
* **Impact**: CoreML encoder will now be properly detected and loaded when `.mlmodelc` file is present alongside GGML model, providing 3x+ faster transcription on Apple Silicon devices (M1+, A14+) with better battery efficiency.
* Changed from `WHISPER_COREML_ALLOW_LOW_LATENCY` to `WHISPER_COREML_ALLOW_FALLBACK` flag for graceful Metal fallback when CoreML model is unavailable.
* Added CoreML framework to macOS podspec (was missing).

## 1.2.6

* **Segmentation Fix for Large-v3-Turbo (Beam Search Solution)**: Fixed issue where Large-v3-Turbo produces single segment instead of multiple timestamps.
* **Root Cause**: Large-v3-Turbo (4 decoder layers, distilled) doesn't generate timestamp tokens naturally in greedy sampling mode due to weak timestamp prediction, causing all text to be treated as one segment.
* **Solution**: Automatically enable beam search sampling (`beam_size=3`) for Large-v3-Turbo models instead of greedy sampling. Beam search explores multiple token candidates simultaneously, increasing probability of selecting timestamp tokens for natural segmentation.
* **Why Beam Search Works**: Proven by whisper-cli (beam_size=5) producing perfect multi-segment results on macOS. Our beam_size=3 balances speed vs quality trade-off.
* **Performance Impact**: ~2-3x slower than greedy sampling, but produces proper segmentation matching other Whisper models (base, large-v3).
* Added Turbo model auto-detection (`n_text_layer=4`, `n_vocab=51866`) with automatic beam search strategy selection.
* Removed `max_len=50` forced segmentation approach (v1.2.5) which was ineffective for dense languages like Korean.
* Added comprehensive debug logging for sampling strategy and beam search parameters.

## 1.2.5

* **Segmentation Fix for Large-v3-Turbo (Deprecated)**: Attempted fix using forced segmentation (`max_len=50`).
* **Issue**: This approach was ineffective for dense languages (Korean, Japanese) where entire segments fit within 50 characters.
* **Superseded by**: v1.2.6 beam search solution.

## 1.2.3

* **Performance Enhancement**: Added VAD (Voice Activity Detection) support with Silero VAD model.
* VAD automatically detects and processes only speech segments, skipping silence for 2-3x faster transcription.
* Bundled ggml-silero-v6.2.0.bin model (864KB) for out-of-the-box VAD support on iOS/macOS.
* VAD reduces battery consumption by skipping silence processing.
* Android VAD support planned for future release.
* Fixed `whisper_vad_init_from_file_with_params: failed to open VAD model '(null)'` crash.

## 1.2.2

* **Critical Fix**: Added missing `GGML_USE_CPU` compiler flag for iOS/macOS.
* Fixed `GGML_ASSERT(device) failed` crash when CPU backend was not registered.
* CPU backend is now properly initialized alongside Metal backend on iOS/macOS.
* Resolves issue where `ggml_backend_dev_by_type(GGML_BACKEND_DEVICE_TYPE_CPU)` returned NULL.

## 1.2.1

* **Critical Fix**: Added Metal shader compilation for iOS/macOS.
* Implemented automatic Metal library compilation via CocoaPods script phases.
* Fixed `GGML_ASSERT(device) failed` crash on iOS devices due to missing Metal shaders.
* Pre-compiles `ggml-metal.metal` to `default.metallib` for faster startup and better performance.
* Reduces app bundle size (~100KB vs ~416KB source file).
* Requires Xcode Metal Toolchain (one-time install via `xcodebuild -downloadComponent MetalToolchain`).

## 1.2.0

* Refactored codebase to version 1.2.0 for improved structure and compatibility.

## 1.1.3

* Completed missing sub-directory hierarchy for `ggml-cpu` and `coreml`.
* Fixed `unary-ops.h` and other implicit header dependency errors.
* Optimized include paths in Podspec and CMake for better v1.8.3 compatibility.

## 1.1.2

* Restored `ggml-cpu` directory hierarchy to match official v1.8.3 structure.
* Fixed missing header dependencies: `ggml-threading.h`, `quants.h`.
* Updated build configurations (Podspec, CMake) for subdirectory support.

## 1.1.1

* Fixed missing header dependencies for whisper.cpp v1.8.3 (traits.h, whisper-compat.h, gguf.h).
* Improved Android directory structure for better compatibility.

## 1.1.0

* Major upgrade: Synchronized engine with official whisper.cpp v1.8.3.
* Implemented new dynamic backend architecture (ggml-backend).
* Added full support for Large-v3-Turbo with improved stability.
* Refactored native bridge for better performance and API compatibility.
* Standardized directory structure across all platforms.

## 1.0.6

* Fixed critical integer overflow during Large-v3-Turbo tensor loading.
* Corrected memory size calculation for 1.6GB+ models to prevent pointer corruption.

## 1.0.5

* Fixed critical `EXC_BAD_ACCESS` (Segment Fault) error during model loading.
* Improved memory safety by using heap allocation for model file streams.
* Fixed dangling pointer issue in `whisper_init_from_file_no_state`.

## 1.0.4

* Fixed `Exception: map::at: key not found` error when using K-quantized models (Q2_K, Q3_K, Q4_K, Q5_K, Q6_K).
* Added missing quantization types to memory requirement maps.

## 1.0.3

* Refactored native bridge for better thread safety and persistent context management.
* Optimized model switching logic to prevent memory leaks and race conditions.
* Standardized version reporting across all platforms.

## 1.0.2

* Enabled CoreML and Metal hardware acceleration for iOS and MacOS.
* Added dynamic CoreML bridge (whisper-encoder.mm) without Xcode auto-generation dependencies.
* Fully optimized Large-v3-Turbo (128-mel) models using Apple Neural Engine.
* Improved stability and performance for heavy models on mobile devices.

## 1.0.1

* Added support for Large-v3-Turbo models (128 mel bands).
* Fixed silent hangs by adding robust NULL checks during model initialization.
* Improved error messaging for memory allocation failures (OOM).
* Renamed package to `whisper_ggml_plus` and updated all internal imports.

## 1.0.0

* Initial fork of `whisper_ggml`.
* Added support for Large-v3-Turbo models (128 mel bands).
* Renamed package to `whisper_ggml_plus`.
