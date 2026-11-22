# just_audio_media_kit

[`media_kit`](https://github.com/media-kit/media-kit) bindings for [`just_audio`](https://github.com/ryanheise/just_audio)

## Breaking changes in 2.x

The installation process has changed, please re-read the install instructions.

## Installation

### In your `pubspec.yaml`:

```yaml
dependencies:
  just_audio_media_kit: ^2.1.0

  # Select the native media_kit libs based on your usage:
  # NOTE: if including video libs already, these audio libs aren't necessary.
  media_kit_libs_linux: any
  media_kit_libs_windows_audio: any
```

**Note**: you can also use `just_audio_media_kit` for Android, iOS and macOS by including the required libs (see below) and enable them in `ensureInitialized()`. However, this is not required as they're natively supported by `just_audio`.

### Use mimalloc (from [media-kit's README](https://github.com/media-kit/media-kit?tab=readme-ov-file#utilize-mimalloc))

You should consider replacing the default memory allocator with [mimalloc](https://github.com/microsoft/mimalloc) for [avoiding memory leaks](https://github.com/media-kit/media-kit/issues/68).

This is as simple as [adding one line to `linux/CMakeLists.txt`](https://github.com/media-kit/media-kit/blob/d02a97ce70b316207db024401fb99e3f4509a250/media_kit_test/linux/CMakeLists.txt#L92-L94):

```cmake
target_link_libraries(${BINARY_NAME} PRIVATE ${MIMALLOC_LIB})
```

### Before using the `AudioPlayer`, call

```dart
// by default, windows and linux are enabled
JustAudioMediaKit.ensureInitialized();

// or, if you want to manually configure enabled platforms instead:
// make sure to include the required dependency in pubspec.yaml for
// each enabled platform!
JustAudioMediaKit.ensureInitialized(
    linux: true,            // default: true  - dependency: media_kit_libs_linux
    windows: true,          // default: true  - dependency: media_kit_libs_windows_audio
    android: true,          // default: false - dependency: media_kit_libs_android_audio
    iOS: true,              // default: false - dependency: media_kit_libs_ios_audio
    macOS: true,            // default: false - dependency: media_kit_libs_macos_audio
);
```

Now you can use just_audio's `AudioPlayer` as normal!

## Plugin-specific configuration (settings for `media_kit`'s `Player()` instance)

**NOTE**: these must be set <u>before</u> the player initializes or they won't work (you can set these right after or before calling `ensureInitialized`)!

Set MPV's log level. Default: `MPVLogLevel.error`

```dart
JustAudioMediaKit.mpvLogLevel = MPVLogLevel.debug;
```

Sets the demuxer's cache size (in bytes). Default: `32 * 1024 * 1204` (32 MB)

```dart
JustAudioMediaKit.bufferSize = 8 * 1024 * 1024; // 8 MB
```

Sets the name of the underlying window and process for native backend. This is visible, for example, inside the Windows' volume mixer or also in `pavucontrol` on Linux. Default: `'JustAudioMediaKit'`

```dart
JustAudioMediaKit.title = 'My Audio Player App';
```

Sets the list of allowed protocols for native backend. Default: `['udp', 'rtp', 'tcp', 'tls', 'data', 'file', 'http', 'https', 'crypto']`

**IF YOU EDIT THIS OPTION**: Remember that `file` is needed for playing local files (assets included!), `https` and `http` are needed to play from URLs and `http` to play from a `StreamAudioSource` (and sources that implement it, like `LockCachingAudioSource`).

```dart
JustAudioMediaKit.protocolWhitelist = const ['http', 'https'];
```

Enables or disables pitch shift control for native backend (with this set to false, `setPitch` won't work). Default: `true`

```dart
JustAudioMediaKit.pitch = true;
```

Enables gapless playback via the [`--prefetch-playlist`](https://mpv.io/manual/stable/#options-prefetch-playlist) in libmpv. Default: `false`

This is highly experimental. Use at your own risk.

Check [mpv's docs](https://mpv.io/manual/stable/#options-prefetch-playlist) and
[the related issue](https://github.com/Pato05/just_audio_media_kit/issues/11) for more information

```dart
JustAudioMediaKit.prefetchPlaylist = true;
```

## Manually specify `libmpv` path (ADVANCED)

To manually specify the `libmpv` path, you can use the `libmpv` parameter in the `ensureInitialized` method:

```dart
JustAudioMediaKit.ensureInitialized(
    libmpv: '/usr/lib/libmpv.so.2',
);
```

This is **NOT NEEDED** in most cases, as `package:media_kit` will choose the right library for you (and can even bundle `libmpv` via the `media_kit_libs_*_*` packages). If you choose to use this option, you will have to perform checks about what platform you're on and where `libmpv` is located in that specific platform.

## Features

| Feature                        |                |
| ------------------------------ | :------------: |
| read from URL                  |       ✅       |
| read from file                 |       ✅       |
| read from asset                |       ✅       |
| read from byte stream          |      ✅\*      |
| request headers                | ✅ (untested)  |
| DASH                           | ✅ (untested)  |
| HLS                            | ✅ (untested)  |
| ICY metadata                   |                |
| buffer status/position         |       ✅       |
| play/pause/seek                |       ✅       |
| set volume/speed               |       ✅       |
| clip audio                     |       ✅       |
| playlists                      |       ✅       |
| looping/shuffling              |       ✅       |
| compose audio                  |                |
| gapless playback               |       ✅\*\*   |
| report player errors           |       ✅       |
| handle phonecall interruptions |                |
| buffering/loading options      |                |
| set pitch                      |       ✅       |
| skip silence                   |                |
| equalizer                      |                |
| volume boost                   |                |

\* reads from byte stream via a local HTTP server provided by `just_audio`
<br>\*\* needs to be enabled

## Caveats

- `just_audio`'s shuffleOrder is currently ignored, because there doesn't seem to be a straightforward way to implement it: because of this, I recommend implementing shuffle by manually shuffling the queue, create a new `ConcatenatingAudioSource` and use `setAudioSource` on your player object.
  - See: [#3](https://github.com/Pato05/just_audio_media_kit/issues/3) and [#13](https://github.com/Pato05/just_audio_media_kit/issues/13)
  - Correct shuffle order implementation is currently implemented in [feat/queue-shuffle](https://github.com/Pato05/just_audio_media_kit/tree/feat/queue-shuffle)
- `SilenceAudioSource` is currently not supported (issue: [media-kit#28](https://github.com/media-kit/media-kit/issues/28)).
- The plugin hasn't been tested with multiple player instances, though it should work without any issues.

## Licensing

This package is licensed under the `Unlicense` license, though
please note that `package:media_kit` (which is a direct dependency of this package) is licensed under the `MIT` license.
So please refer to [`package:media_kit`](https://github.com/media-kit/media-kit) for potential licensing issues.
