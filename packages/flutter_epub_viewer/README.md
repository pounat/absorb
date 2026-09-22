# Flutter Epub Viewer

[![Pub Version](https://img.shields.io/pub/v/flutter_epub_viewer?color=blue)](https://pub.dev/packages/flutter_epub_viewer)
[![License](https://img.shields.io/github/license/fayis672/epub_viewer)](https://github.com/fayis672/epub_viewer/blob/main/LICENSE)

A powerful Flutter package for viewing EPUB documents, built by combining the capabilities of [Epub.js](https://github.com/futurepress/epub.js) and [flutter_inappwebview](https://pub.dev/packages/flutter_inappwebview). This package provides a highly customizable and feature-rich EPUB reader for your Flutter applications.

<img width='50%' src="https://github.com/fayis672/epub_viewer/blob/main/example/epub_viewr_exp.gif?raw=true" alt="Demo GIF">

## ✨ Features

*   **Text Highlighting**: Highlight important text within the EPUB.
*   **Search Functionality**: Search for specific terms or phrases within the book.
*   **Chapter Listing**: Easy navigation through chapters.
*   **Text Selection**: Select text for copying or other actions.
*   **Customizable UI**: Tailor the look and feel to match your app's design.
*   **Reading Progress**: Resume reading from where you left off using CFI (Canonical Fragment Identifier).
*   **Custom Context Menus**: Define custom actions for text selection.
*   **Versatile Loading**: Load EPUBs from Files, URLs, or Assets.
*   **Touch Interactions**: Receive touch event callbacks with normalized coordinates (`onTouchDown`, `onTouchUp`).

## 🚀 Getting Started

### Installation

Add the dependency to your `pubspec.yaml` file:

```shell
flutter pub add flutter_epub_viewer
```

### Platform Setup

#### Android

**Important**: You must enable cleartext traffic for the viewer to function correctly on Android 8.0+.

Add `android:usesCleartextTraffic="true"` to your `AndroidManifest.xml` file in the `<application>` tag.

For more details, refer to this [StackOverflow answer](https://stackoverflow.com/questions/45940861/android-8-cleartext-http-traffic-not-permitted/50834600#50834600).

Also, ensure you complete the platform-wise setup for `flutter_inappwebview` as described [here](https://inappwebview.dev/docs/intro).

## 📖 Usage

### Basic Example

Here is a simple example of how to use `EpubViewer` in your application:

```dart
import 'package:flutter_epub_viewer/flutter_epub_viewer.dart';
import 'package:flutter/material.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final epubController = EpubController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: EpubViewer(
          epubSource: EpubSource.fromUrl(
              'https://github.com/IDPF/epub3-samples/releases/download/20230704/accessible_epub_3.epub'),
          epubController: epubController,
          displaySettings:
              EpubDisplaySettings(flow: EpubFlow.paginated, snap: true),
          onChaptersLoaded: (chapters) {
            // Handle chapters loaded
          },
          onEpubLoaded: () async {
            // Handle epub loaded
          },
          onRelocated: (value) {
            // Handle page change
          },
          onTextSelected: (epubTextSelection) {
            // Handle text selection
          },
        ),
      ),
    );
  }
}
```

### Parameters

| Parameter | Type | Description |
| :--- | :--- | :--- |
| `epubController` | `EpubController` | Controller to manage EPUB actions and state. |
| `epubSource` | `EpubSource` | Source of the EPUB (URL, File, or Asset). **Note**: OPF format is not fully tested. |
| `headers` | `Map<String, String>` | HTTP headers for loading EPUBs from the network. |
| `initialCfi` | `String?` | Initial CFI string to specify the starting position. Defaults to the first chapter if null. |
| `displaySettings` | `EpubDisplaySettings?` | Initial display settings (flow, snap, etc.). |
| `selectionContextMenu` | `ContextMenu?` | Custom context menu for text selection. If null, the default menu is used. |
| `selectAnnotationRange` | `bool` | If `true`, clicking an annotation automatically selects the text range. Defaults to `false`. |

### Callbacks

| Callback | Description |
| :--- | :--- |
| `onEpubLoaded` | Called when the EPUB is successfully loaded and displayed. |
| `onChaptersLoaded` | Called when the chapters are loaded. Returns a list of `EpubChapter`. |
| `onRelocated` | Called when the EPUB page changes. Returns `EpubLocation`. |
| `onTextSelected` | Called when text is selected. Returns `EpubTextSelection`. |
| `onAnnotationClicked` | Called when an annotation (highlight/underline) is clicked. Provides CFI range and rect. |
| `onTouchDown` | Called on touch down event. Provides normalized (x, y) coordinates. |
| `onTouchUp` | Called on touch up event. Provides normalized (x, y) coordinates. |

### EpubController Methods

Use the `EpubController` to interact with the viewer programmatically:

```dart
// Navigation
epubController.display(cfi: cfiString); // Move to specific CFI or chapter href
epubController.next(); // Go to next page
epubController.prev(); // Go to previous page
epubController.toProgressPercentage(0.5); // Go to 50% progress
epubController.moveToFistPage(); // Go to first page
epubController.moveToLastPage(); // Go to last page

// Information
epubController.getCurrentLocation(); // Get current location info
epubController.getChapters(); // Get list of chapters
epubController.getMetadata(); // Get book metadata

// Search
epubController.search(query: "search term"); // Search in EPUB

// Annotations
epubController.addHighlight(cfi: cfiString, color: Colors.yellow); // Add highlight
epubController.removeHighlight(cfi: cfiString); // Remove highlight
epubController.addUnderline(cfi: cfiString); // Add underline
epubController.removeUnderline(cfi: cfiString); // Remove underline

// Custom Theme
EpubTheme.custom(
  customCss: {
    'p': {
      'font-family': 'Roboto, sans-serif',
      'font-size': '18px',
      'line-height': '1.5',
      'color': '#333333',
    },
    'h1': {
       'color': 'blue'
    },
    "a": {
      "color": "inherit !important",
      "-webkit-text-fill-color": "red !important"
    },
    "a:link": {
      "color": "inherit !important",
      "-webkit-text-fill-color": "red !important"
    },
  },
);

// Selection
epubController.clearSelection(); // Clear active selection
epubController.extractText(startCfi: start, endCfi: end); // Extract text from range
epubController.extractCurrentPageText(); // Extract text from current page

// Settings
epubController.setSpread(spread: EpubSpread.auto); // Set spread mode
epubController.setFlow(flow: EpubFlow.paginated); // Set flow mode
epubController.setManager(manager: EpubManager.defaultManager); // Set manager
epubController.setFontSize(fontSize: 16); // Adjust font size
```

## ⚠️ Limitations & Known Issues

*   **OPF Support**: The OPF format is not fully supported yet.
*   **Android Animation**: `onRelocated` callback may be broken when `useSnapAnimationAndroid` is set to `true` in `EpubDisplaySettings` on Android.
*   **Scrolled Flow**: Chapter navigation might break initially when using `scrolled` flow.

## 🔮 Upcoming Features

*   Advanced annotation customization.
*   Additional callbacks (e.g., rendered, error events).

## 🤝 Contributing

Contributions are welcome! We appreciate your help in making this package better.

1.  **Fork** the repository on GitHub.
2.  **Clone** your fork locally.
3.  **Create a new branch** for your feature or bug fix.
4.  **Commit** your changes with descriptive commit messages.
5.  **Push** your branch to your fork.
6.  **Submit a Pull Request** to the main repository.

Please ensure your code follows the existing style and includes relevant tests.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## ❤️ Acknowledgments

*   [Epub.js](https://github.com/futurepress/epub.js) for the core EPUB rendering engine.
*   [flutter_inappwebview](https://pub.dev/packages/flutter_inappwebview) for the powerful WebView integration.

## 👥 Contributors

Big thanks to all the contributors who have helped build this project!

<a href="https://github.com/fayis672/epub_viewer/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=fayis672/epub_viewer" />
</a>
