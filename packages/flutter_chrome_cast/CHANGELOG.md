## 1.4.1 - Stop Casting on App Terminated
### ✨ New Features
- **Stop Casting on App Kill**: Added `stopCastingOnAppTerminated` option to automatically stop casting and end the session when the app is killed/terminated
  - Available on both iOS and Android platforms
  - Configurable via `IOSGoogleCastOptions` and `GoogleCastOptionsAndroid`
  - When enabled, the Chromecast device stops playing when the user closes the app
  - Default is `false` (casting continues after app is closed, maintaining previous behavior)

### 🔧 Platform Improvements  
- **iOS**: Added lifecycle observer to detect app termination and end cast session with `endSessionAndStopCasting(true)`
- **Android**: Implemented `ActivityLifecycleCallbacks` to monitor activity destruction and properly end cast sessions

### 📚 Documentation
- Updated README with configuration options table
- Added code examples for both iOS and Android showing how to enable `stopCastingOnAppTerminated`
## 1.3.1 - Swift Package Manager Fixes
### 🐛 Bug Fixes
- **SPM Build Fixes**: Fixed Swift compiler errors when building with Swift Package Manager
  - Added missing `import Flutter` statements to all method channel Swift files
  - Added `@objc(GoogleCastPlugin)` attribute to expose Swift plugin class with correct name for Flutter's plugin registrant
  - Fixes "Cannot find type 'FlutterPlugin' in scope" and related compiler errors
  - Fixes "Unknown receiver 'GoogleCastPlugin'" error in GeneratedPluginRegistrant.m

### 🔧 Notes
- SPM support now fully functional for iOS builds
- No breaking API changes

## 1.3.0 - Swift Package Manager Support
### ✨ New Features
- **Swift Package Manager (SPM) Support**: Added full SPM support for iOS
  - Added `Package.swift` manifest with [SRGSSR/google-cast-sdk](https://github.com/SRGSSR/google-cast-sdk) dependency
  - Plugin now supports both CocoaPods and SPM for iOS dependency management
  - Resolves pub.dev scoring requirement for SPM support

### 🔧 Platform Changes
- **iOS Deployment Target**: Updated minimum iOS version from 14.0 to 15.0 (required by GoogleCast SPM package)

### 📚 Documentation
- Updated README with SPM usage instructions
- Added SPM documentation to podspec

## 1.2.9 - iOS Cast contentURL fix
### 🐛 Fixes
- Use `GCKMediaInformationBuilder(contentURL:)` instead of deprecated `contentID` to align with current Google Cast SDK and fix media load failures (including HLS) on iOS.

## 1.2.8 - iOS HLS & Media Safety
### 🐛 Fixes
- Hardened iOS media parsing to avoid crashes from missing/invalid metadata; `fromMap` now bails out safely and treats infinite/NaN durations as zero.
- Improved HLS playback support by mapping segment formats, honoring `startAbsoluteTime`, and correctly propagating `playPosition`, `startTime`, and `preloadTime` values.
- Queue load options now respect fractional play positions, keeping live and buffered streams in sync.

### 🧭 UX
- Tweaked expanded player and mini controller behavior for live streams (slider, play/pause), improving control feedback during HLS playback.

**Full Changelog**: https://github.com/felnanuke2/flutter_google_cast/compare/v1.2.7...v1.2.8

## 1.2.7
## What's Changed
* Unknown track languages in m3u8 playlists cause player state events to be lost by @RabbitKabong in https://github.com/felnanuke2/flutter_google_cast/pull/46
* Bump version to 1.2.7 in pubspec.yaml by @felnanuke2 in https://github.com/felnanuke2/flutter_google_cast/pull/48

## New Contributors
* @RabbitKabong made their first contribution in https://github.com/felnanuke2/flutter_google_cast/pull/46

**Full Changelog**: https://github.com/felnanuke2/flutter_google_cast/compare/v1.2.6...v1.2.7

## 1.2.6 - iOS Simulator Build Compatibility Fix
### 🐛 Bug Fixes
- **iOS Simulator Module Resolution**: Fixed "Module 'flutter_chrome_cast' not found" parse error that occurred during iOS simulator builds
  - Issue affected only simulator builds; device builds and IPA generation worked correctly
  - Added `DEFINES_MODULE=YES` to podspec for proper Swift module header generation
  - Added `ENABLE_TESTING_SEARCH_PATHS=YES` to improve module resolution during simulator compilation
  - Updated Google Cast SDK to ~> 4.8
  - Maintains full compatibility with static framework linking for transitive Google Cast SDK dependencies

### 🔧 Notes
- No public API changes. This release focuses on build system compatibility for iOS simulator builds
- Resolves issue #XX where users encountered "Module not found" errors on some machines while others were unaffected

## 1.2.5 - iOS Apple Silicon Support & Enhanced Media Controls
### ✨ New Features
- **Missing Audio Control**: Added missing `stop` method for audio control in remote casting client
  - Implements the stop functionality that was previously missing from the Android remote media client
  - Fix contributed via PR #40 by @abdulmajedkhan

### 🔧 Platform Improvements
- **Apple Silicon Support**: Added full support for Apple Silicon (M1/M2/M3) Mac simulators
  - Updated Google Cast SDK dependency from `google-cast-sdk-no-bluetooth` to standard `google-cast-sdk` ~> 4.7
  - Removed arm64 simulator architecture exclusions that prevented builds on Apple Silicon
  - Fixes contributed via PR #39 by @SVyatoslavG and @nsikaktradearies
- **iOS Deployment Target**: Bumped minimum iOS deployment target to 13.0 to align with modern platform requirements
- **Enhanced Logging**: Improved debug logging capabilities with conditional debug print statements

### 🚀 Performance & Developer Experience
- **Faster Plugin Initialization**: Returns Flutter plugin result earlier during initialization for faster feedback
- **Conditional Logging**: Gated console logging behind debug flags to reduce noise in production builds
- **Better Discovery**: Enhanced device discovery initialization and lifecycle management

### 🔧 Technical Updates
- **CocoaPods Integration**: Updated CocoaPods and Xcode project metadata to reflect dependency changes
- **Build System**: Improved build phases and linker configuration for better compatibility

### 🔧 Notes
- No breaking API changes. This release focuses on platform compatibility and missing functionality
- Existing projects may need to update their iOS deployment target to 13.0 for optimal compatibility

## 1.2.4 - Misc fixes and Android method channel improvements
### 🐛 Bug Fixes
- **Android remote media client**: Fixes in `android_remote_media_client_method_channel.dart` to address method channel behavior when loading single media items.
- **Example fixes**: Minor example app updates to `example/lib/main.dart` and `example/android/app/build.gradle` to keep the sample project in sync with the plugin changes.
- **Pubspec tidy**: Updated `pubspec.yaml` to reflect dependency/metadata housekeeping.

### 🔧 Notes
- No public API breaking changes. This release contains internal fixes and example updates.

## 1.2.3 - iOS Teardown Crash Fix
### 🐛 Bug Fixes
- **iOS Teardown Safety**: Safely teardown Google Cast listeners on iOS to avoid a crash when the app terminates.
  - Fix merged via pull request #32: https://github.com/felnanuke2/flutter_google_cast/pull/32

### 🔧 Notes
- No public API changes. This is a small internal lifecycle fix for iOS listener teardown.

## 1.2.2 - Repeat Mode Bug Fix
### 🐛 Bug Fixes
### 🐛 Bug Fixes
- **Cross-Platform Repeat Mode Fix**: Fixed repeat mode handling across Android and iOS platforms
  - **Android**: Updated repeat mode parsing to use string-based values instead of integer mapping
  - **iOS**: Fixed GCKMediaQueueLoadOptions repeat mode enum parsing to handle string values
  - **Dart**: Enhanced GoogleCastMediaRepeatMode enum with proper string value mapping
  - **Consistency**: Ensured consistent repeat mode behavior across all platforms

### 🔧 Code Improvements
- **Removed Platform-Specific Code**: Eliminated Android-specific repeat mode extensions for cleaner architecture
- **Type Safety**: Improved type safety in repeat mode handling with proper string-to-enum conversion
- **Code Formatting**: Applied consistent code formatting and styling improvements


## 1.2.1 - Documentation & Testing Improvements
### 📚 Documentation Enhancements
- **Expanded API Documentation**: Added comprehensive documentation for public members across all Dart classes
- **Improved Public API Coverage**: Enhanced doc comments for better IDE support and developer experience
- **Coverage Badge**: Added test coverage badge to track and display code coverage metrics

### 🧪 Testing Infrastructure
- **Test Suite Initialization**: Started implementing comprehensive test coverage for the application
- **Testing Foundation**: Established testing framework and initial test cases for core functionality
- **Quality Assurance**: Improved code reliability through systematic testing approach

### 🔧 Code Quality
- **Documentation Standards**: Ensured all public class members have proper documentation
- **Code Coverage Tracking**: Implemented coverage monitoring for better code quality insights
- **Developer Experience**: Enhanced IDE support with better API documentation

## 1.2.0 - API Documentation & Quality Release
### 📚 Documentation & API Improvements
- **Extensive API Documentation**: Added or improved doc comments for nearly all public classes, methods, enums, and fields across the codebase.
- **Public API Coverage**: Significantly increased public API documentation coverage for better IDE support and pub.dev health.
- **README & Example Updates**: Improved usage examples, customization guides, and documentation for easier integration.
- **Linter Rule**: Enabled `public_member_api_docs` lint to enforce documentation for all public members.
- **No Breaking Changes**: This is a safe update with no breaking API changes.

### 🛠️ Internal & Quality
- Improved code comments and structure for maintainability.
- All previous features and fixes from 1.1.1 included.

## 1.1.1 - Perfect Package Score Achievement
### 🏆 Quality Improvements
- **Perfect Pana Score**: Achieved 160/160 points in package analysis
  - ✅ **File Conventions (30/30)**: Valid `pubspec.yaml`, `README.md`, `CHANGELOG.md`, and OSI-approved BSD-3-Clause license
  - ✅ **Documentation (20/20)**: 31.5% of public API documented (above 20% requirement) with comprehensive example
  - ✅ **Platform Support (20/20)**: Full iOS and Android support
  - ✅ **Static Analysis (50/50)**: Zero errors, warnings, lints, or formatting issues
  - ✅ **Dependencies (40/40)**: All dependencies up-to-date and compatible with constraint lower bounds

### 🔧 Technical Improvements
- **Code Formatting**: Applied `dart format` to ensure consistent code style across all files
- **Static Analysis**: Resolved all linting and formatting issues for perfect static analysis score
- **Dependency Compatibility**: Verified compatibility with latest stable Dart and Flutter SDKs
- **Package Health**: Optimized for pub.dev publication with excellent package health metrics

### 📊 Package Metrics
- **API Documentation Coverage**: 234 out of 744 API elements documented (31.5%)
- **Platform Coverage**: iOS ✅ Android ✅
- **License**: BSD-3-Clause (OSI-approved)
- **Dependencies**: All current and compatible
- **Static Analysis**: Perfect score with zero issues

## 1.1.0 - Modular Import System
### ✨ New Features
- **Modular Import System**: Introduced a new flexible import structure for better performance and cleaner code
  - Added `flutter_chrome_cast.dart` as the main entry point (imports everything)
  - Added selective imports: `cast_context.dart`, `discovery.dart`, `session.dart`, `media.dart`, `widgets.dart`, etc.
  - Each module exports only related functionality for optimized bundle size

### 📦 Import Options
- **Complete Import**: `import 'package:flutter_chrome_cast/flutter_chrome_cast.dart';` (recommended for getting started)
- **Selective Imports**: Import only what you need for production apps
  ```dart
  import 'package:flutter_chrome_cast/cast_context.dart';  // Core functionality
  import 'package:flutter_chrome_cast/media.dart';         // Media control
  import 'package:flutter_chrome_cast/widgets.dart';       // UI widgets
  ```

### 📈 Benefits
- **Smaller Bundle Size**: Only include the functionality you actually use
- **Faster Compilation**: Less code to analyze and compile
- **Cleaner Namespace**: Avoid importing unused classes
- **Better IDE Support**: More precise auto-completion and error detection

### 🔄 Migration Guide
- **Old**: `import 'package:flutter_chrome_cast/lib.dart';` (still works but deprecated)
- **New**: Choose between complete import or selective imports based on your needs

### 📚 Documentation
- Updated README with comprehensive import strategy guide
- Added import comparison table showing what each module includes
- Added migration examples and best practices

### ⚠️ Deprecations
- `lib.dart` is now deprecated in favor of the new import system (still functional for backward compatibility)

## 1.0.4
### Bug Fixes
- **Code Quality**: Fixed Dart formatting issues across the entire codebase
- **Static Analysis**: Resolved formatting warnings to improve pub.dev package score
- **Formatted Files**: Applied Dart formatter to 115 files ensuring compliance with Dart style guidelines
  - Fixed formatting in `android_discovery_manager.dart`
  - Fixed formatting in `ios_cast_session_manager.dart`
  - Applied consistent formatting across all library files

## 1.0.3
### Breaking Changes
- **Enum Naming Convention Update**: All enums have been updated from UPPER_SNAKE_CASE to lowerCamelCase for better Dart conventions
  - `GoogleCastConnectState.ConnectionStateConnected` → `GoogleCastConnectState.connected`
  - `CastMediaStreamType.BUFFERED` → `CastMediaStreamType.buffered`
  - `TrackType.TEXT` → `TrackType.text`
  - `TextTrackType.SUBTITLES` → `TextTrackType.subtitles`
  - `RFC5646_LANGUAGE` → `Rfc5646Language`
  - And many more enum updates across the codebase

### Android Build System Modernization
- **Gradle Update**: Updated from 7.x to 8.4 for better compatibility
- **Android Gradle Plugin**: Updated from 7.x to 8.3.0
- **Kotlin**: Updated from 1.6.10 to 1.9.10
- **Java Compatibility**: Updated to Java 11
- **Android SDK**: Updated compile SDK to 35, target SDK to 34
- **Dependencies**: Updated Google Cast Framework (21.0.1 → 21.5.0), AndroidX libraries, and other Android dependencies

### Enhanced UI/UX
- **Completely Redesigned Mini Controller**: 
  - Modern Material Design with floating card style
  - Marquee text scrolling for long titles and subtitles
  - Better visual hierarchy and improved touch targets
  - Theme-aware styling with customizable colors and typography
- **Enhanced Expanded Player**:
  - Drag-to-dismiss gesture support with smooth animations
  - Better media image handling with fallbacks
  - Improved controls layout with backdrop blur effects
  - Caption/subtitle track selection
  - Seek forward/backward 30 seconds functionality
  - Volume control integration
- **Theme Support**: Added comprehensive theming with `ExpandedGoogleCastPlayerTheme`
- **Internationalization**: Added `ExpandedGoogleCastPlayerTexts` for customizable text content

### Bug Fixes
- **Device Discovery**: Fixed duplicate device detection in Android discovery manager
- **Error Handling**: Improved error handling and removed debug print statements
- **Import Issues**: Fixed missing imports and dependency issues
- **Memory Leaks**: Better disposal of animation controllers and stream subscriptions
- **UI Stability**: Fixed various layout and rendering issues

### New Features
- **Marquee Text Support**: Added `marquee` package dependency for scrolling text
- **Customizable Texts**: Complete internationalization support with example
- **Advanced Theming**: Comprehensive theme customization options
- **Better Examples**: Added `customizable_texts_example.dart` and documentation
- **Enhanced Documentation**: Added `CUSTOMIZABLE_TEXTS.md` with usage examples

### Developer Experience
- **Improved Code Quality**: Better type safety, null safety compliance
- **Documentation**: Enhanced inline documentation and examples
- **File Organization**: Better separation of concerns and cleaner imports

### Migration Guide
If you're upgrading from previous versions, you'll need to update enum usage:
```dart
// Before
GoogleCastConnectState.ConnectionStateConnected
CastMediaStreamType.BUFFERED
TrackType.TEXT

// After  
GoogleCastConnectState.connected
CastMediaStreamType.buffered
TrackType.text
```

## 1.0.2
- Improved README.md with better documentation and examples
- Enhanced setup instructions and usage guidelines
- Updated documentation formatting and clarity

## 0.0.1

* TODO: Describe initial release.


## 0.0.3
allow change subtitle tracks and audio tracks

## 0.0.4
add license to pubspec.yaml

## 0.0.5
add repository to pubspec.yaml

## 0.0.6
generate dart doc with dartdoc

## 0.0.7
update package name in podpec

## 0.0.8
fix GoogleCastPlugin.m file

## 0.0.9
fix /android/app/src/main/AndroidManifest.xml and add
```xml
<meta-data
           android:name=
               "com.google.android.gms.cast.framework.OPTIONS_PROVIDER_CLASS_NAME"
           android:value="com.felnanuke.google_cast.GoogleCastOptionsProvider" />
```

## 0.0.10
- Now supports Flutter 3.22.0, thanks to contributions from fmsidoe.

## 0.0.11
- fix issue on that crash app when session is disconnected
- add to doc and example new properties required to work on android api 34+

## 1.0.0
- Update plugin to support Flutter v3.24.3.
- Bump version and update dependency versions in pubspec.yaml.
- Update SDK constraints in both main and example pubspec files for compatibility with latest Flutter.
- Add conditional namespace configuration in android/build.gradle for compatibility with the latest Gradle and Android Studio.

## 1.0.1
- Update README example to use fully qualified provider class name for Android manifest integration
- Clarify the android:value meta-data entry with complete package path to prevent ambiguity when registering the options provider
