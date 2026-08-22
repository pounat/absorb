import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../flutter_epub_viewer.dart';
import 'utils.dart';

/// Callback for text selection events with WebView-relative coordinates.
///
/// Provides precise positioning information for implementing custom selection UI.
/// All rectangles are relative to the WebView's coordinate system (not screen coordinates).
///
/// Parameters:
/// * [selectedText] - The text that was selected
/// * [cfiRange] - The EPUB CFI (Canonical Fragment Identifier) range for the selection
/// * [selectionRect] - The bounding rectangle of the selected text (WebView-relative)
/// * [viewRect] - The bounding rectangle of the entire WebView
typedef EpubSelectionCallback =
    void Function(
      String selectedText,
      String cfiRange,
      Rect selectionRect,
      Rect viewRect,
    );

class EpubViewer extends StatefulWidget {
  const EpubViewer({
    super.key,
    required this.epubController,
    required this.epubSource,
    this.initialCfi,
    this.initialXPath,
    this.onChaptersLoaded,
    this.onEpubLoaded,
    this.onLocationLoaded,
    this.onRelocated,
    this.onTextSelected,
    this.displaySettings,
    this.selectionContextMenu,
    this.onAnnotationClicked,
    this.onSelection,
    this.onSelectionChanging,
    this.onDeselection,
    this.onInitialPositionLoading,
    this.onInitialPositionLoaded,
    this.onTouchDown,
    this.onTouchUp,
    this.suppressNativeContextMenu = false,
    this.clearSelectionOnPageChange = true,
    this.selectAnnotationRange = false,
  });

  //Epub controller to manage epub
  final EpubController epubController;

  ///Epub source, accepts url, file or assets
  ///opf format is not tested, use with caution
  final EpubSource epubSource;

  ///Initial cfi string to  specify which part of epub to load initially
  ///if null, the first chapter will be loaded
  final String? initialCfi;

  ///Initial xpath/XPointer string to specify which part of epub to load initially
  ///if null and initialCfi is also null, the first chapter will be loaded
  final String? initialXPath;

  ///Call back when epub is loaded and displayed
  final VoidCallback? onEpubLoaded;

  /// Callback when the location are generated for epub, progress will be only available after this
  final VoidCallback? onLocationLoaded;

  ///Call back when chapters are loaded
  final ValueChanged<List<EpubChapter>>? onChaptersLoaded;

  ///Call back when epub page changes
  final ValueChanged<EpubLocation>? onRelocated;

  ///Callback when initial position loading starts (for showing progress indicator)
  ///Receives the type: 'xpath' or 'cfi'
  final ValueChanged<String>? onInitialPositionLoading;

  ///Callback when initial position loading completes
  final VoidCallback? onInitialPositionLoaded;

  ///Call back when text selection changes
  final ValueChanged<EpubTextSelection>? onTextSelected;

  ///initial display settings
  final EpubDisplaySettings? displaySettings;

  ///Callback for handling annotation click (Highlight and Underline)
  ///Provides the CFI range and the selection rect (same format as onSelection)
  final void Function(String cfiRange, Map<String, dynamic>? rect)?
  onAnnotationClicked;

  /// Context menu for text selection.
  /// If null, the default context menu will be used.
  final ContextMenu? selectionContextMenu;

  /// Whether to suppress the native context menu entirely.
  /// When true, no native context menu will be shown on text selection.
  /// Use with [onSelection] to implement custom selection UI.
  final bool suppressNativeContextMenu;

  /// Callback when text is selected with WebView-relative coordinates.
  ///
  /// Fires when:
  /// * User completes initial text selection
  /// * User finishes dragging selection handles (after a 300ms debounce)
  ///
  /// Use this callback to display custom UI at the selection position.
  /// Coordinates are relative to the WebView, not the screen.
  ///
  /// See also:
  /// * [onSelectionChanging] - Called while user is actively dragging handles
  /// * [onDeselection] - Called when selection is cleared
  final EpubSelectionCallback? onSelection;

  /// Callback fired continuously while the user is dragging selection handles.
  ///
  /// This callback helps prevent UI flicker and performance issues by allowing you to
  /// hide custom selection UI while the user is actively adjusting the selection.
  /// Once dragging stops, [onSelection] will be called with the final selection.
  ///
  /// Typical usage:
  /// ```dart
  /// onSelectionChanging: () {
  ///   // Hide custom selection UI while user drags handles
  ///   setState(() => showSelectionMenu = false);
  /// }
  /// ```
  ///
  /// See also:
  /// * [onSelection] - Called when selection is finalized
  final VoidCallback? onSelectionChanging;

  /// Callback when text selection is cleared.
  ///
  /// Fired when the user taps elsewhere or explicitly clears the selection.
  /// Use this to hide any custom selection UI.
  final VoidCallback? onDeselection;

  /// Whether to automatically clear text selection when navigating to a new page.
  ///
  /// When true (default), text selection will be cleared when the user navigates
  /// to a different page using next(), previous(), or toCfi(). This is the standard
  /// behavior in most e-reader applications.
  ///
  /// Set to false if you want to preserve selection across page changes, though
  /// note that the selection may not be visible on the new page.
  final bool clearSelectionOnPageChange;

  /// Whether to programmatically select annotation ranges when clicked.
  ///
  /// When true, clicking on an annotation (highlight/underline) will automatically
  /// select the text range, triggering the selection event with the correct rect.
  /// This is useful for displaying custom selection UI for annotations.
  ///
  /// When false (default), annotation clicks will only trigger [onAnnotationClicked]
  /// without programmatically selecting the text.
  final bool selectAnnotationRange;

  /// Callback fired when the user touches down on the EPUB viewer.
  ///
  /// Provides normalized coordinates (0.0-1.0) relative to the WebView dimensions.
  /// Coordinates use the same calculation logic as selection coordinates.
  ///
  /// Fires regardless of whether there's an active text selection, allowing you to:
  /// * Determine which zone of the EPUB viewer was tapped
  /// * Compare tap location with selection location to trigger selection-specific pop-ups
  /// * Control navigation and menus based on tap position
  ///
  /// Parameters:
  /// * [x] - Normalized X coordinate (0.0 = left edge, 1.0 = right edge)
  /// * [y] - Normalized Y coordinate (0.0 = top edge, 1.0 = bottom edge)
  final void Function(double x, double y)? onTouchDown;

  /// Callback fired when the user releases a touch on the EPUB viewer.
  ///
  /// Provides normalized coordinates (0.0-1.0) relative to the WebView dimensions.
  /// Coordinates use the same calculation logic as selection coordinates.
  ///
  /// Fires regardless of whether there's an active text selection, allowing you to:
  /// * Determine which zone of the EPUB viewer was tapped
  /// * Compare tap location with selection location to trigger selection-specific pop-ups
  /// * Control navigation and menus based on tap position
  ///
  /// Parameters:
  /// * [x] - Normalized X coordinate (0.0 = left edge, 1.0 = right edge)
  /// * [y] - Normalized Y coordinate (0.0 = top edge, 1.0 = bottom edge)
  final void Function(double x, double y)? onTouchUp;

  @override
  State<EpubViewer> createState() => _EpubViewerState();
}

class _EpubViewerState extends State<EpubViewer> {
  final GlobalKey webViewKey = GlobalKey();

  Timer?
  _selectionCheckTimer; // Timer to periodically verify selection still exists

  InAppWebViewController? webViewController;

  InAppWebViewSettings settings = InAppWebViewSettings(
    isInspectable: kDebugMode,
    javaScriptEnabled: true,
    mediaPlaybackRequiresUserGesture: false,
    transparentBackground: true,
    supportZoom: false,
    allowsInlineMediaPlayback: true,
    disableLongPressContextMenuOnLinks: false,
    iframeAllowFullscreen: true,
    allowsLinkPreview: false,
    verticalScrollBarEnabled: false,
    selectionGranularity: SelectionGranularity.CHARACTER,
  );

  @override
  void initState() {
    super.initState();
  }

  /// Block or unblock gestures using CSS touch-action when selection is active
  void _blockGesturesWhenSelected(bool block) {
    if (!mounted || webViewController == null) return;

    // Use CSS touch-action to block horizontal panning/swiping when selection exists
    // This works at the browser level, before JavaScript event handlers
    // We apply it to the parent document and iframe elements (not sandboxed contents)
    webViewController?.evaluateJavascript(
      source: 'blockGesturesWhenSelected(${block ? 'true' : 'false'})',
    );
  }

  void _handleSelection({
    required Map<String, dynamic>? rect,
    required String selectedText,
    required String cfi,
  }) {
    if (!mounted) return;

    try {
      final renderBox = context.findRenderObject() as RenderBox;
      final webViewSize = renderBox.size;

      if (rect == null) {
        // Still call onTextSelected for basic selection functionality
        widget.onTextSelected?.call(
          EpubTextSelection(selectedText: selectedText, selectionCfi: cfi),
        );
        return;
      }

      // Convert relative coordinates (0-1) to actual WebView coordinates
      final left = (rect['left'] as num).toDouble();
      final top = (rect['top'] as num).toDouble();
      final width = (rect['width'] as num).toDouble();
      final height = (rect['height'] as num).toDouble();

      final scaledRect = Rect.fromLTWH(
        left * webViewSize.width,
        top * webViewSize.height,
        width * webViewSize.width,
        height * webViewSize.height,
      );

      // Create viewRect in WebView-relative coordinates
      final viewRect = Rect.fromLTWH(
        0,
        0,
        webViewSize.width,
        webViewSize.height,
      );

      // Provide WebView-relative coordinates (not screen coordinates)
      widget.onSelection?.call(
        selectedText,
        cfi,
        scaledRect, // WebView-relative coordinates
        viewRect,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint("Error in _handleSelection: $e");
      }
    }
  }

  void addJavaScriptHandlers() {
    webViewController?.addJavaScriptHandler(
      handlerName: "displayed",
      callback: (data) {
        widget.onEpubLoaded?.call();
      },
    );

    webViewController?.addJavaScriptHandler(
      handlerName: "chapters",
      callback: (data) async {
        final chapters = await widget.epubController.parseChapters();
        widget.onChaptersLoaded?.call(chapters);
      },
    );

    webViewController?.addJavaScriptHandler(
      handlerName: "selection",
      callback: (data) {
        final cfiString = data[0] as String;
        final selectedText = data[1] as String;
        Map<String, dynamic>? rect;
        String? selectionXpath;

        try {
          if (data.length > 2 && data[2] != null) {
            rect = Map<String, dynamic>.from(data[2] as Map);
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('Error parsing selection rect: $e');
          }
          rect = null;
        }

        try {
          if (data.length > 3 && data[3] != null) {
            selectionXpath = data[3] as String?;
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('Error parsing selection xpath: $e');
          }
          selectionXpath = null;
        }

        // Block gestures when selection is active
        _blockGesturesWhenSelected(true);
        _startSelectionMonitoring();

        // Always call basic text selection callback
        widget.onTextSelected?.call(
          EpubTextSelection(
            selectedText: selectedText,
            selectionCfi: cfiString,
            selectionXpath: selectionXpath,
          ),
        );

        // If we have coordinates and a selection callback, provide full selection info
        if (rect != null && widget.onSelection != null) {
          _handleSelection(
            rect: rect,
            selectedText: selectedText,
            cfi: cfiString,
          );
        }
      },
    );

    // Add deselection handler
    webViewController?.addJavaScriptHandler(
      handlerName: 'selectionCleared',
      callback: (args) {
        _stopSelectionMonitoring();
        _blockGesturesWhenSelected(false);
        widget.onDeselection?.call();
      },
    );

    // Add selection changing handler (dragging handles)
    webViewController?.addJavaScriptHandler(
      handlerName: 'selectionChanging',
      callback: (args) {
        widget.onSelectionChanging?.call();
      },
    );

    // Add touch down handler
    webViewController?.addJavaScriptHandler(
      handlerName: 'onTouchDown',
      callback: (data) {
        try {
          if (data.length >= 2) {
            final x = (data[0] as num).toDouble();
            final y = (data[1] as num).toDouble();
            widget.onTouchDown?.call(x, y);
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('Error parsing onTouchDown coordinates: $e');
          }
        }
      },
    );

    // Add touch up handler
    webViewController?.addJavaScriptHandler(
      handlerName: 'onTouchUp',
      callback: (data) {
        try {
          if (data.length >= 2) {
            final x = (data[0] as num).toDouble();
            final y = (data[1] as num).toDouble();
            widget.onTouchUp?.call(x, y);
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('Error parsing onTouchUp coordinates: $e');
          }
        }
      },
    );

    webViewController?.addJavaScriptHandler(
      handlerName: "search",
      callback: (data) async {
        var searchResult = data[0];
        widget.epubController.searchResultCompleter.complete(
          List<EpubSearchResult>.from(
            searchResult.map((e) => EpubSearchResult.fromJson(e)),
          ),
        );
      },
    );

    webViewController?.addJavaScriptHandler(
      handlerName: "relocated",
      callback: (data) {
        var location = data[0];
        widget.onRelocated?.call(EpubLocation.fromJson(location));
      },
    );

    webViewController?.addJavaScriptHandler(
      handlerName: 'locationLoaded',
      callback: (arguments) {
        widget.onLocationLoaded?.call();
      },
    );

    webViewController?.addJavaScriptHandler(
      handlerName: 'initialPositionLoading',
      callback: (data) {
        String type = 'cfi';
        if (data.isNotEmpty) {
          try {
            if (data[0] is Map) {
              type = (data[0] as Map)['type'] ?? 'cfi';
            } else if (data[0] is String) {
              type = data[0] as String;
            }
          } catch (e) {
            if (kDebugMode) {
              debugPrint('Error parsing initialPositionLoading type: $e');
            }
          }
        }
        widget.onInitialPositionLoading?.call(type);
      },
    );

    webViewController?.addJavaScriptHandler(
      handlerName: 'initialPositionLoaded',
      callback: (arguments) {
        widget.onInitialPositionLoaded?.call();
      },
    );

    webViewController?.addJavaScriptHandler(
      handlerName: "readyToLoad",
      callback: (data) {
        loadBook();
      },
    );

    webViewController?.addJavaScriptHandler(
      handlerName: "markClicked",
      callback: (data) {
        String cfi = data[0];
        Map<String, dynamic>? rect;
        try {
          if (data.length > 1 && data[1] != null) {
            rect = Map<String, dynamic>.from(data[1] as Map);
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('Error parsing annotation rect: $e');
          }
          rect = null;
        }
        widget.onAnnotationClicked?.call(cfi, rect);
      },
    );

    webViewController?.addJavaScriptHandler(
      handlerName: "epubText",
      callback: (data) {
        var text = data[0].trim();
        var cfi = data[1];
        String? xpathRange;
        try {
          if (data.length > 2 && data[2] != null) {
            xpathRange = data[2] as String?;
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('Error parsing xpathRange: $e');
          }
          xpathRange = null;
        }
        widget.epubController.completePageText(
          EpubTextExtractRes(text: text, cfiRange: cfi, xpathRange: xpathRange),
        );
      },
    );

    webViewController?.addJavaScriptHandler(
      handlerName: "cfiRect",
      callback: (data) {
        try {
          if (data.isNotEmpty && data[0] != null) {
            final rectData = data[0] as Map<String, dynamic>;
            final rect = Rect.fromLTRB(
              (rectData['left'] as num).toDouble(),
              (rectData['top'] as num).toDouble(),
              (rectData['right'] as num).toDouble(),
              (rectData['bottom'] as num).toDouble(),
            );
            widget.epubController.cfiRectCompleter.complete(rect);
          } else {
            widget.epubController.cfiRectCompleter.complete(null);
          }
        } catch (e) {
          widget.epubController.cfiRectCompleter.completeError(e);
        }
      },
    );

    webViewController?.addJavaScriptHandler(
      handlerName: "currentLocation",
      callback: (data) {
        try {
          if (data.isNotEmpty && data[0] != null) {
            final locationData = data[0] as Map<String, dynamic>;
            final location = EpubLocation(
              startCfi: locationData['startCfi'],
              endCfi: locationData['endCfi'],
              startXpath: locationData['startXpath'],
              endXpath: locationData['endXpath'],
              progress: (locationData['progress'] as num).toDouble(),
            );
            widget.epubController.currentLocationCompleter.complete(location);
          } else {
            widget.epubController.currentLocationCompleter.completeError(
              Exception('Invalid location data'),
            );
          }
        } catch (e) {
          widget.epubController.currentLocationCompleter.completeError(e);
        }
      },
    );
  }

  Future<void> loadBook() async {
    var data = await widget.epubSource.epubData;
    final displaySettings = widget.displaySettings ?? EpubDisplaySettings();
    String manager = displaySettings.manager.name;
    String flow = displaySettings.flow.name;
    String spread = displaySettings.spread.name;
    bool snap = displaySettings.snap;
    bool allowScripted = displaySettings.allowScriptedContent;
    String cfi = widget.initialCfi ?? "";
    String? initialXPath = widget.initialXPath;
    String direction =
        widget.displaySettings?.defaultDirection.name ??
        EpubDefaultDirection.ltr.name;
    int fontSize = displaySettings.fontSize;

    bool useCustomSwipe =
        Platform.isAndroid && !displaySettings.useSnapAnimationAndroid;

    String? foregroundColor = widget.displaySettings?.theme?.foregroundColor
        ?.toHex();
    String customCss = widget.displaySettings?.theme?.customCss != null
        ? Utils.encodeMap(widget.displaySettings!.theme!.customCss!)
        : "null";

    bool clearSelectionOnPageChange = widget.clearSelectionOnPageChange;

    String xpathParam = initialXPath != null ? '"$initialXPath"' : 'null';

    // Stream the file into the page in base64 chunks and assemble it there.
    // Serializing the whole book into the script source (the upstream
    // data.join(',') approach) builds a string several times the file size on
    // both sides of the bridge; a 322MB epub took the entire app down with an
    // out-of-memory crash before it ever reached the WebView.
    const chunkBytes = 2 * 1024 * 1024;
    await webViewController?.evaluateJavascript(source: 'beginBookData()');
    for (var i = 0; i < data.length; i += chunkBytes) {
      final end = (i + chunkBytes < data.length) ? i + chunkBytes : data.length;
      final b64 = base64Encode(Uint8List.sublistView(data, i, end));
      await webViewController?.evaluateJavascript(
        source: 'appendBookData("$b64")',
      );
    }
    webViewController?.evaluateJavascript(
      source:
          'loadBook(null, "$cfi", $xpathParam, "$manager", "$flow", "$spread", $snap, $allowScripted, "$direction", $useCustomSwipe, "${null}", "$foregroundColor", "$fontSize", $clearSelectionOnPageChange, ${widget.selectAnnotationRange}, $customCss)',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: widget.displaySettings?.theme?.backgroundDecoration,
      child: InAppWebView(
        contextMenu: widget.suppressNativeContextMenu
            ? ContextMenu(
                menuItems: [],
                settings: ContextMenuSettings(
                  hideDefaultSystemContextMenuItems: true,
                ),
              )
            : widget.selectionContextMenu,
        key: webViewKey,
        initialFile:
            'packages/flutter_epub_viewer/lib/assets/webpage/html/swipe.html',
        initialSettings: settings
          ..disableVerticalScroll = widget.displaySettings?.snap ?? false,
        onWebViewCreated: (controller) async {
          webViewController = controller;
          widget.epubController.setWebViewController(controller);
          addJavaScriptHandlers();
        },
        onLoadStart: (controller, url) {},
        onPermissionRequest: (controller, request) async {
          return PermissionResponse(
            resources: request.resources,
            action: PermissionResponseAction.GRANT,
          );
        },
        shouldOverrideUrlLoading: (controller, navigationAction) async {
          return NavigationActionPolicy.ALLOW;
        },
        onLoadStop: (controller, url) async {},
        onReceivedError: (controller, request, error) {},
        onProgressChanged: (controller, progress) {},
        onUpdateVisitedHistory: (controller, url, androidIsReload) {},
        onConsoleMessage: (controller, consoleMessage) {
          if (kDebugMode) {
            debugPrint("JS_LOG: ${consoleMessage.message}");
          }
        },
        onLongPressHitTestResult: (controller, hitTestResult) {
          // On iPad, long press creates selection but events don't fire
          // Trigger JavaScript to check for selection after a delay
          // Also set up periodic checking for selection changes (when handles are dragged)
          Future.delayed(const Duration(milliseconds: 300), () {
            controller.evaluateJavascript(
              source: 'checkSelectionAfterLongPress()',
            );

            // Set up periodic checking for selection changes (when handles are dragged)
            // Check every 150ms for up to 10 seconds after long press
            var checkCount = 0;
            var maxChecks = 67; // 67 * 150ms = ~10 seconds
            Timer.periodic(const Duration(milliseconds: 150), (timer) {
              checkCount++;
              if (checkCount > maxChecks) {
                timer.cancel();
                return;
              }

              controller.evaluateJavascript(
                source: 'checkSelectionPeriodically()',
              );
            });
          });
        },
        gestureRecognizers: {
          Factory<VerticalDragGestureRecognizer>(
            () => VerticalDragGestureRecognizer(),
          ),
          Factory<LongPressGestureRecognizer>(
            () => LongPressGestureRecognizer(
              duration: const Duration(milliseconds: 30),
            ),
          ),
        },
      ),
    );
  }

  /// Start monitoring selection state to ensure blocking persists
  void _startSelectionMonitoring() {
    _stopSelectionMonitoring(); // Stop any existing timer

    _selectionCheckTimer = Timer.periodic(const Duration(milliseconds: 200), (
      timer,
    ) {
      if (!mounted || webViewController == null) {
        timer.cancel();
        return;
      }

      // Check if selection still exists and re-apply blocking if needed
      webViewController
          ?.evaluateJavascript(source: 'checkSelectionAndReapplyBlocking()')
          .then((result) {
            // If selection no longer exists, stop monitoring
            if (result == 'no-selection') {
              _stopSelectionMonitoring();
              _blockGesturesWhenSelected(false);
            }
          });
    });
  }

  /// Stop monitoring selection state
  void _stopSelectionMonitoring() {
    _selectionCheckTimer?.cancel();
    _selectionCheckTimer = null;
  }

  @override
  void dispose() {
    _stopSelectionMonitoring();
    super.dispose();
  }
}
