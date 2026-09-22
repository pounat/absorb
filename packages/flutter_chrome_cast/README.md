# Flutter Google Cast

[![Codecov](https://codecov.io/gh/felnanuke2/flutter_google_cast/branch/master/graph/badge.svg)](https://codecov.io/gh/felnanuke2/flutter_google_cast)
[![CI](https://github.com/felnanuke2/flutter_google_cast/workflows/Flutter%20CI%20with%20Test%20Enforcement/badge.svg)](https://github.com/felnanuke2/flutter_google_cast/actions)

**FlutterGoogleCast** is a comprehensive Flutter plugin that provides seamless integration with the Google Cast SDK for both iOS and Android platforms. This plugin enables your Flutter application to discover, connect to, and control Chromecast devices and other Google Cast-enabled receivers.

> **📱 Alternative for Non-Cast Devices**: If you need to integrate with devices that don't have Google Cast built-in or are not Chromecast devices, you may be interested in https://github.com/felnanuke2/media_cast_dlna - take a look!

## Support the Project

<a href='https://ko-fi.com/Y8Y61HCG2P' target='_blank'><img height='36' style='border:0px;height:36px;' src='https://storage.ko-fi.com/cdn/kofi5.png?v=6' border='0' alt='Buy Me a Coffee at ko-fi.com' /></a>

## Demo Video

<video src="https://raw.githubusercontent.com/felnanuke2/flutter_google_cast/refs/heads/master/Screen_Recording_20250618_125333.mp4" controls width="600" poster="https://raw.githubusercontent.com/felnanuke2/flutter_google_cast/refs/heads/master/Screenshot_20250618_130514.jpg">
  Your browser does not support the video tag.
</video>

## Features

- 🔍 **Device Discovery**: Automatically discover Google Cast devices on your network
- 📱 **Cross-Platform**: Full support for both iOS and Android
- 🎥 **Media Streaming**: Stream videos, audio, and other media content
- 📋 **Queue Management**: Load and manage media queues with multiple items
- 🎛️ **Media Controls**: Play, pause, seek, volume control, and more
- 📺 **Session Management**: Connect and disconnect from cast devices
- 🔄 **Real-time Updates**: Stream-based APIs for real-time status updates
- 📱 **Mini Controller**: Built-in mini controller widget for easy integration
- 🛠️ **Robust Build System**: Optimized Android builds with automated troubleshooting tools

## Getting Started

### Installation

Add `flutter_chrome_cast` to your `pubspec.yaml` file:

```yaml
dependencies:
  flutter_chrome_cast: ^latest_version
```

Then run:
```bash
flutter pub get
```

## Import Strategy

This package provides flexible import options to optimize your app's performance:

### 🎯 Modular Imports (Recommended)

Instead of importing everything, you can now import only what you need:

| Import | What it includes | When to use |
|--------|------------------|-------------|
| `flutter_chrome_cast.dart` | Everything | Getting started, prototyping |
| `cast_context.dart` | Google Cast initialization | Always needed |
| `discovery.dart` | Device discovery | When you need to find devices |
| `session.dart` | Session management | When managing cast sessions |
| `media.dart` | Media control | When controlling media playback |
| `widgets.dart` | UI components | When using built-in cast widgets |
| `entities.dart` | Data models | When working with cast data |
| `enums.dart` | Constants & enums | When you need specific constants |

### 📊 Benefits

- **Smaller bundle size**: Only include what you use
- **Faster compilation**: Less code to analyze and compile  
- **Cleaner namespace**: Avoid importing unused classes
- **Better IDE support**: More precise auto-completion

### 🔄 Migration Guide

**Before (v1.0.4 and earlier):**
```dart
import 'package:flutter_chrome_cast/lib.dart';
```

**After (v1.1.0+):**
```dart
// Option 1: Everything (same functionality)
import 'package:flutter_chrome_cast/flutter_chrome_cast.dart';

// Option 2: Only what you need (recommended)
import 'package:flutter_chrome_cast/cast_context.dart';
import 'package:flutter_chrome_cast/media.dart';
import 'package:flutter_chrome_cast/widgets.dart';
```

## Platform Setup

### iOS Configuration

This plugin supports both **CocoaPods** (default) and **Swift Package Manager (SPM)** for iOS dependency management.

#### Info.plist Configuration

Add the following configuration to your `ios/Runner/Info.plist` file:

```xml
<key>NSLocalNetworkUsageDescription</key>
<string>${PRODUCT_NAME} uses the local network to discover Cast-enabled devices on your WiFi network.</string>
<key>NSBonjourServices</key>
<array>
    <string>_CC1AD845._googlecast._tcp</string>
    <string>_googlecast._tcp</string>
</array>
```

> **Note**: Replace `_CC1AD845._googlecast._tcp` with your actual Google Cast application ID.

#### Using Swift Package Manager (SPM)

If you prefer to use SPM instead of CocoaPods, or if you're experiencing CocoaPods read-only issues, this plugin provides full SPM support.

The plugin uses the [SRGSSR/google-cast-sdk](https://github.com/SRGSSR/google-cast-sdk) community wrapper since Google does not officially provide an SPM-compatible distribution of the Cast SDK.

To use SPM:

1. Open your iOS project in Xcode
2. Navigate to File → Add Package Dependencies
3. Add the flutter_chrome_cast plugin's iOS package

Or add it to your project's `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/felnanuke2/flutter_google_cast.git", from: "1.2.6")
]
```

<details>
<summary>Complete iOS Info.plist example</summary>

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>NSLocalNetworkUsageDescription</key>
    <string>${PRODUCT_NAME} uses the local network to discover Cast-enabled devices on your WiFi network.</string>
    <key>NSBonjourServices</key>
    <array>
        <string>_CC1AD845._googlecast._tcp</string>
        <string>_googlecast._tcp</string>
    </array>
    <key>CFBundleDevelopmentRegion</key>
    <string>$(DEVELOPMENT_LANGUAGE)</string>
    <key>CFBundleDisplayName</key>
    <string>Google Cast</string>
    <key>CFBundleExecutable</key>
    <string>$(EXECUTABLE_NAME)</string>
    <key>CFBundleIdentifier</key>
    <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>google_cast_example</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>$(FLUTTER_BUILD_NAME)</string>
    <key>CFBundleSignature</key>
    <string>????</string>
    <key>CFBundleVersion</key>
    <string>$(FLUTTER_BUILD_NUMBER)</string>
    <key>LSRequiresIPhoneOS</key>
    <true/>
    <key>UILaunchStoryboardName</key>
    <string>LaunchScreen</string>
    <key>UIMainStoryboardFile</key>
    <string>Main</string>
    <key>UISupportedInterfaceOrientations</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
        <string>UIInterfaceOrientationLandscapeLeft</string>
        <string>UIInterfaceOrientationLandscapeRight</string>
    </array>
    <key>UISupportedInterfaceOrientations~ipad</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
        <string>UIInterfaceOrientationPortraitUpsideDown</string>
        <string>UIInterfaceOrientationLandscapeLeft</string>
        <string>UIInterfaceOrientationLandscapeRight</string>
    </array>
    <key>UIViewControllerBasedStatusBarAppearance</key>
    <false/>
    <key>CADisableMinimumFrameDurationOnPhone</key>
    <true/>
</dict>
</plist>
```
</details>

### Android Configuration

Add the following to your `android/app/src/main/AndroidManifest.xml` file inside the `<application>` tag:

```xml
<!-- Required permission for media playback in foreground service -->
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK" />

<!-- Google Cast framework configuration -->
<meta-data
    android:name="com.google.android.gms.cast.framework.OPTIONS_PROVIDER_CLASS_NAME"
    android:value="com.felnanuke.google_cast.GoogleCastOptionsProvider" />

<!-- Media notification service for cast controls -->
<service
    android:name="com.google.android.gms.cast.framework.media.MediaNotificationService"
    android:exported="false"
    android:foregroundServiceType="mediaPlayback" />
```

<details>
<summary>Complete Android AndroidManifest.xml example</summary>

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.felnanuke.google_cast_example">
    
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK" />
    
    <application
        android:label="google_cast_example"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">
        
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">
            
            <meta-data
                android:name="io.flutter.embedding.android.NormalTheme"
                android:resource="@style/NormalTheme" />
                
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
        
        <meta-data
            android:name="flutterEmbedding"
            android:value="2" />
            
        <meta-data
            android:name="com.google.android.gms.cast.framework.OPTIONS_PROVIDER_CLASS_NAME"
            android:value="com.felnanuke.google_cast.GoogleCastOptionsProvider" />

        <service
            android:name="com.google.android.gms.cast.framework.media.MediaNotificationService"
            android:exported="false"
            android:foregroundServiceType="mediaPlayback" />

    </application>
</manifest>
```
</details>

## Usage

### 1. Import the Library

You have several options for importing the Flutter Chrome Cast library:

#### Option A: Complete Import (Recommended for getting started)
```dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_chrome_cast/flutter_chrome_cast.dart';
```

#### Option B: Selective Imports (Recommended for production)
For better performance and cleaner code, import only what you need:

```dart
import 'dart:io';
import 'package:flutter/material.dart';

// Core functionality
import 'package:flutter_chrome_cast/cast_context.dart';  // Google Cast initialization
import 'package:flutter_chrome_cast/discovery.dart';    // Device discovery
import 'package:flutter_chrome_cast/session.dart';      // Session management
import 'package:flutter_chrome_cast/media.dart';        // Media control

// UI widgets (if needed)
import 'package:flutter_chrome_cast/widgets.dart';      // Cast UI widgets

// Data models (if needed)
import 'package:flutter_chrome_cast/entities.dart';     // Cast entities
import 'package:flutter_chrome_cast/enums.dart';        // Enums and constants
```

#### Option C: Legacy Import (Deprecated)
```dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_chrome_cast/lib.dart';  // ⚠️ Deprecated - use option A or B
```

> **💡 Pro Tip**: Use selective imports (Option B) in production apps to reduce bundle size and improve compile times. You only import the functionality you actually use.

### 2. Initialize the Google Cast Context

Initialize the Google Cast context in your app's `initState()` or main function:

```dart
Future<void> initPlatformState() async {
  // Use the default Cast application ID or your custom one
  const appId = GoogleCastDiscoveryCriteria.kDefaultApplicationId;
  GoogleCastOptions? options;
  
  if (Platform.isIOS) {
    options = IOSGoogleCastOptions(
      GoogleCastDiscoveryCriteriaInitialize.initWithApplicationID(appId),
      // Optional: Stop casting when app is killed (default: false)
      stopCastingOnAppTerminated: true,
    );
  } else if (Platform.isAndroid) {
    options = GoogleCastOptionsAndroid(
      appId: appId,
      // Optional: Stop casting when app is killed (default: false)
      stopCastingOnAppTerminated: true,
    );
  }
  
  // Initialize the Google Cast context
  GoogleCastContext.instance.setSharedInstanceWithOptions(options!);
}
```

### Configuration Options

The `GoogleCastOptions` class and its platform-specific subclasses support the following configuration options:

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `stopCastingOnAppTerminated` | `bool` | `false` | When `true`, automatically stops casting and ends the session when the app is killed/terminated. Useful when you want casting to stop when users close the app. |
| `physicalVolumeButtonsWillControlDeviceVolume` | `bool` | `true` | Whether hardware volume buttons control the Cast device volume. |
| `suspendSessionsWhenBackgrounded` | `bool` | `true` | Whether to suspend sessions when the app goes to background. |
| `stopReceiverApplicationWhenEndingSession` | `bool` | `false` | Whether to stop the receiver application when ending a session. |

#### Stop Casting on App Terminated

By default, when you close/kill your app, casting continues on the Chromecast device. If you want the casting to stop when the app is killed, set `stopCastingOnAppTerminated: true`:

```dart
// iOS
options = IOSGoogleCastOptions(
  GoogleCastDiscoveryCriteriaInitialize.initWithApplicationID(appId),
  stopCastingOnAppTerminated: true,  // Stop casting when app is killed
);

// Android
options = GoogleCastOptionsAndroid(
  appId: appId,
  stopCastingOnAppTerminated: true,  // Stop casting when app is killed
);
```

> **Note:** This works for normal app closures and most system-initiated kills. Force-kills (swiping away from recent apps) may not always trigger this behavior depending on the platform and circumstances.

### 3. Device Discovery

The plugin automatically discovers Cast devices when initialized. You can also manually start/stop discovery:

```dart
// Start discovery (usually automatic when app is in foreground)
GoogleCastDiscoveryManager.instance.startDiscovery();

// Stop discovery to save battery
GoogleCastDiscoveryManager.instance.stopDiscovery();
```

### 4. Display Available Devices

Create a UI to show discovered Cast devices:

```dart
StreamBuilder<List<GoogleCastDevice>>(
  stream: GoogleCastDiscoveryManager.instance.devicesStream,
  builder: (context, snapshot) {
    final devices = snapshot.data ?? [];
    
    if (devices.isEmpty) {
      return const Center(
        child: Text('No Cast devices found'),
      );
    }
    
    return ListView.builder(
      itemCount: devices.length,
      itemBuilder: (context, index) {
        final device = devices[index];
        return ListTile(
          leading: const Icon(Icons.cast),
          title: Text(device.friendlyName),
          subtitle: Text(device.modelName ?? 'Unknown model'),
          onTap: () => _connectToDevice(device),
        );
      },
    );
  },
)
```

### 5. Connect to a Cast Device

```dart
Future<void> _connectToDevice(GoogleCastDevice device) async {
  try {
    await GoogleCastSessionManager.instance.startSessionWithDevice(device);
    print('Connected to ${device.friendlyName}');
  } catch (e) {
    print('Failed to connect: $e');
  }
}
```

### 6. Monitor Connection Status

Listen to connection state changes:

```dart
StreamBuilder<GoogleCastSession?>(
  stream: GoogleCastSessionManager.instance.currentSessionStream,
  builder: (context, snapshot) {
    final isConnected = GoogleCastSessionManager.instance.connectionState == 
        GoogleCastConnectState.ConnectionStateConnected;
    
    return IconButton(
      onPressed: isConnected 
          ? GoogleCastSessionManager.instance.endSessionAndStopCasting
          : null,
      icon: Icon(
        isConnected ? Icons.cast_connected : Icons.cast,
        color: isConnected ? Colors.blue : Colors.grey,
      ),
    );
  },
)
```

### 7. Load and Play Media

#### Single Media Item

```dart
Future<void> _loadSingleMedia(GoogleCastDevice device) async {
  await GoogleCastSessionManager.instance.startSessionWithDevice(device);

  await GoogleCastRemoteMediaClient.instance.loadMedia(
    GoogleCastMediaInformationIOS(
      contentId: 'elephants_dream',
      streamType: CastMediaStreamType.BUFFERED,
      contentUrl: Uri.parse(
        'http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4'
      ),
      contentType: 'video/mp4',
      metadata: GoogleCastTvShowMediaMetadata(
        episode: 1,
        season: 1,
        seriesTitle: 'Elephants Dream',
        originalAirDate: DateTime.now(),
        images: [
          GoogleCastImage(
            url: Uri.parse(
              'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/images/ElephantsDream.jpg'
            ),
            height: 480,
            width: 854,
          ),
        ],
      ),
      tracks: [
        GoogleCastMediaTrack(
          trackId: 0,
          type: TrackType.TEXT,
          trackContentId: Uri.parse(
            'https://raw.githubusercontent.com/felnanuke2/flutter_cast/master/example/assets/VEED-subtitles_Blender_Foundation_-_Elephants_Dream_1024.vtt'
          ).toString(),
          trackContentType: 'text/vtt',
          name: 'English Subtitles',
          language: RFC5646_LANGUAGE.ENGLISH_UNITED_STATES,
          subtype: TextTrackType.SUBTITLES,
        ),
      ],
    ),
    autoPlay: true,
    playPosition: const Duration(seconds: 0),
    playbackRate: 1.0,
    activeTrackIds: [0],
  );
}
```

#### Media Queue (Playlist)

```dart
Future<void> _loadMediaQueue(GoogleCastDevice device) async {
  await GoogleCastSessionManager.instance.startSessionWithDevice(device);
  
  await GoogleCastRemoteMediaClient.instance.queueLoadItems(
    [
      GoogleCastQueueItem(
        activeTrackIds: [0],
        mediaInformation: GoogleCastMediaInformationIOS(
          contentId: 'elephants_dream',
          streamType: CastMediaStreamType.BUFFERED,
          contentUrl: Uri.parse(
            'http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4'
          ),
          contentType: 'video/mp4',
          metadata: GoogleCastMovieMediaMetadata(
            title: 'Elephants Dream',
            studio: 'Blender Foundation',
            releaseDate: DateTime(2006),
            images: [
              GoogleCastImage(
                url: Uri.parse(
                  'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/images/ElephantsDream.jpg'
                ),
                height: 480,
                width: 854,
              ),
            ],
          ),
          tracks: [
            GoogleCastMediaTrack(
              trackId: 0,
              type: TrackType.TEXT,
              trackContentId: Uri.parse(
                'https://raw.githubusercontent.com/felnanuke2/flutter_cast/master/example/assets/VEED-subtitles_Blender_Foundation_-_Elephants_Dream_1024.vtt'
              ).toString(),
              trackContentType: 'text/vtt',
              name: 'English',
              language: RFC5646_LANGUAGE.ENGLISH_UNITED_STATES,
              subtype: TextTrackType.SUBTITLES,
            ),
          ],
        ),
      ),
      GoogleCastQueueItem(
        preLoadTime: const Duration(seconds: 15),
        mediaInformation: GoogleCastMediaInformationIOS(
          contentId: 'big_buck_bunny',
          streamType: CastMediaStreamType.BUFFERED,
          contentUrl: Uri.parse(
            'http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4'
          ),
          contentType: 'video/mp4',
          metadata: GoogleCastMovieMediaMetadata(
            title: 'Big Buck Bunny',
            studio: 'Blender Foundation',
            releaseDate: DateTime(2008),
            images: [
              GoogleCastImage(
                url: Uri.parse(
                  'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/images/BigBuckBunny.jpg'
                ),
                height: 480,
                width: 854,
              ),
            ],
          ),
        ),
      ),
    ],
    options: GoogleCastQueueLoadOptions(
      startIndex: 0,
      playPosition: const Duration(seconds: 0),
    ),
  );
}
```

### 8. Media Playback Controls

#### Basic Controls

```dart
// Play/Pause toggle
void _togglePlayPause() {
  final isPlaying = GoogleCastRemoteMediaClient.instance.mediaStatus?.playerState == 
      CastMediaPlayerState.playing;
  
  if (isPlaying) {
    GoogleCastRemoteMediaClient.instance.pause();
  } else {
    GoogleCastRemoteMediaClient.instance.play();
  }
}

// Stop playback
void _stop() {
  GoogleCastRemoteMediaClient.instance.stop();
}

// Seek to specific position
void _seekTo(Duration position) {
  GoogleCastRemoteMediaClient.instance.seek(
    GoogleCastMediaSeekOption(position: position)
  );
}
```

#### Queue Controls

```dart
// Skip to next item in queue
void _skipToNext() {
  GoogleCastRemoteMediaClient.instance.queueNextItem();
}

// Skip to previous item in queue
void _skipToPrevious() {
  GoogleCastRemoteMediaClient.instance.queuePrevItem();
}

// Insert item into queue
void _insertQueueItem() {
  GoogleCastRemoteMediaClient.instance.queueInsertItems(
    [
      GoogleCastQueueItem(
        mediaInformation: GoogleCastMediaInformationIOS(
          contentId: 'new_video',
          streamType: CastMediaStreamType.BUFFERED,
          contentUrl: Uri.parse('your_video_url_here'),
          contentType: 'video/mp4',
          metadata: GoogleCastMovieMediaMetadata(
            title: 'New Video',
            studio: 'Your Studio',
            releaseDate: DateTime.now(),
          ),
        ),
      )
    ],
    beforeItemWithId: 2, // Insert before item with ID 2
  );
}
```

### 9. Monitor Media Status

```dart
StreamBuilder<GoggleCastMediaStatus?>(
  stream: GoogleCastRemoteMediaClient.instance.mediaStatusStream,
  builder: (context, snapshot) {
    final mediaStatus = snapshot.data;
    
    if (mediaStatus == null) {
      return const Text('No media loaded');
    }
    
    final isPlaying = mediaStatus.playerState == CastMediaPlayerState.playing;
    final duration = mediaStatus.mediaInformation?.duration ?? Duration.zero;
    final position = GoogleCastRemoteMediaClient.instance.playerPosition;
    
    return Column(
      children: [
        Text('Status: ${isPlaying ? "Playing" : "Paused"}'),
        Text('Title: ${mediaStatus.mediaInformation?.metadata?.title ?? "Unknown"}'),
        LinearProgressIndicator(
          value: duration.inSeconds > 0 ? position.inSeconds / duration.inSeconds : 0,
        ),
        Text('${_formatDuration(position)} / ${_formatDuration(duration)}'),
      ],
    );
  },
)
```

### 10. Add Mini Controller

The plugin provides a convenient mini controller widget:

```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    body: Stack(
      children: [
        // Your main app content
        YourMainContent(),
        
        // Mini controller (appears when casting)
        const GoogleCastMiniController(),
      ],
    ),
  );
}
```

## Customization: Themes & Texts

You can customize the look and feel of the player and localize its texts using the `GoogleCastPlayerTheme` and `GoogleCastPlayerTexts` classes.

### Customizing the Player Theme

```dart
final darkTheme = GoogleCastPlayerTheme(
  backgroundColor: Colors.black,
  titleTextStyle: const TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  ),
  deviceTextStyle: TextStyle(
    fontSize: 14,
    color: Colors.grey[400],
    fontWeight: FontWeight.w400,
  ),
  iconColor: Colors.white,
  iconSize: 32,
  imageBorderRadius: BorderRadius.circular(8),
  imageShadow: [
    BoxShadow(
      color: Colors.white.withOpacity(0.2),
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
  ],
);

// Use with the player widget:
ExpandedGoogleCastPlayerController(
  theme: darkTheme,
)
```

### Customizing Player Texts (Localization)

```dart
const spanishTexts = GoogleCastPlayerTexts(
  unknownTitle: 'Título desconocido',
  castingToDevice: (deviceName) => 'Transmitiendo a $deviceName',
  noCaptionsAvailable: 'Sin subtítulos disponibles',
  captionsOff: 'Desactivar',
  trackFallback: (trackId) => 'Pista $trackId',
);

// Use with the player widget:
ExpandedGoogleCastPlayerController(
  texts: spanishTexts,
)
```

You can combine both theme and texts for full customization:

```dart
ExpandedGoogleCastPlayerController(
  theme: darkTheme,
  texts: spanishTexts,
)
```

For more advanced examples, see the example app in [`example/lib/main.dart`](example/lib/main.dart).

## Complete Example

A full working example is available in [`example/lib/main.dart`](example/lib/main.dart) in this repository.

The usage snippets above cover the most common integration patterns. For advanced usage, custom UI, and more, see the example app source code.

## API Reference

### Core Classes

#### GoogleCastContext
Main entry point for Google Cast functionality.
- `setSharedInstanceWithOptions(GoogleCastOptions options)`: Initialize Cast context

#### GoogleCastDiscoveryManager
Manages device discovery.
- `startDiscovery()`: Start discovering Cast devices
- `stopDiscovery()`: Stop device discovery
- `devicesStream`: Stream of discovered devices

#### GoogleCastSessionManager
Manages Cast sessions.
- `startSessionWithDevice(GoogleCastDevice device)`: Connect to a device
- `endSessionAndStopCasting()`: Disconnect from current device
- `currentSessionStream`: Stream of session changes
- `connectionState`: Current connection state

#### GoogleCastRemoteMediaClient
Controls media playback.
- `loadMedia()`: Load a single media item
- `queueLoadItems()`: Load a media queue
- `play()`: Start playback
- `pause()`: Pause playback
- `stop()`: Stop playback
- `seek()`: Seek to position
- `queueNextItem()`: Skip to next item
- `queuePrevItem()`: Skip to previous item
- `mediaStatusStream`: Stream of media status updates

### Widgets

#### GoogleCastMiniController
A pre-built widget that provides basic media controls when casting.

## Troubleshooting

### Common Issues

1. **No devices found**: Ensure your mobile device and Cast receiver are on the same WiFi network.

2. **iOS: Local network permission**: Make sure you've added the `NSLocalNetworkUsageDescription` to your Info.plist.

3. **Android: Service not found**: Verify that the required meta-data and service entries are in your AndroidManifest.xml.

4. **Media not loading**: Check that your media URLs are accessible and in supported formats (MP4, WebM, etc.).

### Supported Media Formats

- **Video**: MP4, WebM, MOV
- **Audio**: MP3, AAC, FLAC, WAV
- **Streaming**: HLS (m3u8), DASH

## 📚 Documentation

### User Guides
- **[Import Guide](IMPORT_GUIDE.md)** - Optimize your Flutter imports for better performance
- **[Main README](README.md)** - This file - complete plugin usage and setup

### Developer Documentation
- **[Native Development Guide](NATIVE_GUIDE.md)** - Overview of native implementation architecture
- **[iOS Native Guide](NATIVE_IOS_GUIDE.md)** - Swift implementation details, debugging, and contribution guide
- **[Android Native Guide](NATIVE_ANDROID_GUIDE.md)** - Kotlin implementation details, debugging, and contribution guide

### Quick Links
- 🎯 **New to the plugin?** Start with this README and the [Import Guide](IMPORT_GUIDE.md)
- 🔧 **Want to contribute to native code?** Check out the [Native Development Guide](NATIVE_GUIDE.md)
- 🍎 **iOS development?** See the [iOS Native Guide](NATIVE_IOS_GUIDE.md)
- 🤖 **Android development?** See the [Android Native Guide](NATIVE_ANDROID_GUIDE.md)
- 💡 **Optimizing imports?** Use the [Import Guide](IMPORT_GUIDE.md)

## Development & Testing

### Running Tests

This project maintains high test coverage to ensure reliability. Tests are automatically run on every PR to master.

```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage

# Quick coverage report (opens in browser on macOS/Linux)
./scripts/quick_coverage.sh
```

### Coverage Reports

Coverage is automatically generated and reported on every PR. Reports are uploaded to Codecov and the workflow produces HTML artifacts for each run.

Coverage badges at the top of this README show the current coverage status. Detailed coverage reports are available:
- As artifacts in GitHub Actions workflow runs
- On [Codecov](https://codecov.io/gh/felnanuke2/flutter_google_cast)

### Coverage Scripts

The project includes several coverage scripts:

- `scripts/run_coverage.sh` - Comprehensive coverage analysis with detailed reporting
- `scripts/quick_coverage.sh` - Quick coverage check for development
- `scripts/test_enforcement.sh` - Enforces test requirements

## Troubleshooting

### Android Build Issues

If you encounter Android build issues, the plugin includes several solutions:

#### Quick Fix Script

Run the automated fix script:

```bash
./scripts/fix_android_build.sh
```

#### Common Issues

1. **Java heap space errors during build**:
   - The plugin now includes optimized Gradle settings
   - Heap size is automatically increased to 3GB

2. **Android x86 target deprecation warnings**:
   - x86 targets are excluded by default
   - Use: `flutter build apk --target-platform android-arm64,android-arm`

3. **AndroidX migration conflicts**:
   - Jetifier is optimized with blacklisted problematic dependencies
   - AndroidX is enabled by default

4. **Dependency resolution issues**:
   ```bash
   flutter clean
   flutter pub get
   cd android && ./gradlew clean
   flutter build apk --target-platform android-arm64,android-arm
   ```

For detailed troubleshooting, see [ANDROID_BUILD_TROUBLESHOOTING.md](ANDROID_BUILD_TROUBLESHOOTING.md).

### Dependency Updates

Check for outdated dependencies:

```bash
flutter pub outdated
```

The CI automatically checks and reports outdated dependencies, but they won't fail the build if they're incompatible with current constraints.

## Contributing

Contributions are welcome! Please submit pull requests to our GitHub repository.

## License

This plugin is released under the BSD-3-Clause License. See the LICENSE file for details.
