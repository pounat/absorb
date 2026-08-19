import 'dart:convert';
import 'dart:io';
import 'dart:math' show min;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_epub_viewer/flutter_epub_viewer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/library_provider.dart';
import '../services/audio_player_service.dart';
import '../services/ebook_annotation_service.dart';
import '../services/ebook_cache.dart';
import '../services/progress_sync_service.dart';
import '../services/reader_font_service.dart';
import '../services/scoped_prefs.dart';
import '../services/volume_key_service.dart';
import 'overlay_toast.dart';
import 'quote_share_sheet.dart';
import 'card_buttons.dart' show CardSpeedSheet;

/// Reader background/text presets (e-reader themes). Colors are hex so they
/// feed both the WebView CSS and the Flutter overlays.
class _ReaderPalette {
  final String id;
  final String label;
  final String bg; // '#rrggbb'
  final String fg;
  const _ReaderPalette(this.id, this.label, this.bg, this.fg);
  Color get bgColor => Color(int.parse('FF${bg.substring(1)}', radix: 16));
  Color get fgColor => Color(int.parse('FF${fg.substring(1)}', radix: 16));
}

const _kReaderPalettes = [
  _ReaderPalette('light', 'Light', '#ffffff', '#121212'),
  _ReaderPalette('sepia', 'Sepia', '#f4ecd8', '#5b4636'),
  _ReaderPalette('gray', 'Gray', '#333537', '#e6e6e6'),
  _ReaderPalette('dark', 'Dark', '#000000', '#ffffff'),
];


class EbookReaderView extends StatefulWidget {
  final String itemId;
  final String title;
  final Map<String, dynamic> ebookFile;
  /// Opens here instead of the saved reading position, for jumping straight
  /// to a highlight from outside the reader.
  final String? openAtCfi;

  const EbookReaderView({
    super.key,
    required this.itemId,
    required this.title,
    required this.ebookFile,
    this.openAtCfi,
  });

  @override
  State<EbookReaderView> createState() => EbookReaderViewState();
}

class EbookReaderViewState extends State<EbookReaderView> with WidgetsBindingObserver {
  EpubController? _epubController;
  bool _loading = true;
  String? _error;
  File? _cachedFile;
  // Swiping to the recents/app-switcher un-hides the system bars. The frozen
  // safe-area padding (see _buildViewerArea) keeps that from resizing the
  // WebView, but if a resize still gets through (some OEMs resize the window
  // itself), epub.js re-paginates and re-anchors a page back, firing a stray
  // relocate that would save that wrong page. Remember the real page while
  // backgrounded, ignore relocations that arrive while away, and restore the
  // page on return if one actually drifted us.
  bool _readerActive = true;
  String? _bgCfi;
  bool _bgDrifted = false;
  String? _initialCfi;
  bool _showControls = false;
  List<EpubChapter> _chapters = [];
  double _progress = 0;
  // epub.js reports a usable page percentage only after its CFI location index
  // is built/loaded. Until then we don't trust or sync value.progress.
  bool _locationsReady = false;
  int _chapterPage = 0;
  int _chapterPageTotal = 0;
  String? _currentChapterTitle;

  // Annotations
  final _annotationService = EbookAnnotationService();
  List<EbookAnnotation> _annotations = [];
  bool _hasBookmarkAtCurrent = false;
  String? _currentCfi;

  // Search state - persisted across screen opens so the user keeps their results
  String _searchQuery = '';
  List<EpubSearchResult> _searchResults = [];
  List<String?> _resultChapters = []; // parallel to _searchResults
  String _lastSearchedQuery = '';
  // cfi -> which occurrence of the query within its section (for exact re-anchor)
  final Map<String, int> _resultOccByCfi = {};

  // Selection state for highlight menu
  String? _selectionText;
  String? _selectionCfi;
  Rect? _selectionRect;
  // Track touch start position to distinguish taps from swipes
  double? _touchDownX;
  double? _touchDownY;
  double? _ptrDownX;
  double? _ptrDownY;

  // Key to force-rebuild EpubViewer when layout mode changes
  int _viewerKey = 0;
  // onEpubLoaded is wired to epub.js's "displayed" event, which re-fires on
  // every display() - so the load-time rescue re-display must run at most once
  // per mount, or it re-triggers itself into an endless display->displayed loop
  // that freezes page-turn taps. Reset whenever the viewer remounts.
  bool _didLoadRescue = false;
  // Where an outside jump (a highlight from the list) asked to land, re-applied
  // once after the first paint - epub.js repaginates right after load and can
  // round the target away.
  String? _settleJumpCfi;
  // Same event, same reason: the handler/highlight/font wiring must run once
  // per mount, not on every chapter crossing - unguarded it stacked a new JS
  // relocated-listener, re-registered every highlight and re-shipped the
  // ~100KB font payload each time a chapter boundary was crossed.
  bool _didInitViewer = false;

  // Reader settings
  int _fontSize = 16;
  double _lineHeight = 1.4;
  int _marginH = 16; // left + right
  String _volumeNavMode = 'off';
  bool _volumeNavWhilePlaying = false;
  int _marginV = 16; // top + bottom
  // Page layout: auto shows two pages on wide screens (tablets), single forces
  // one page, two forces a spread. Stored as index 0=auto/1=single/2=two.
  EpubSpread _spread = EpubSpread.auto;
  static const _spreadModes = [EpubSpread.auto, EpubSpread.none, EpubSpread.always];
  // E-reader background theme (empty = follow the app's light/dark) and font.
  String _themeId = '';
  String _fontId = 'original';

  static const _kFontSize = 'ereader_fontSize';
  static const _kLineHeight = 'ereader_lineHeight';
  static const _kMargin = 'ereader_margin'; // legacy single margin (migrated)
  static const _kMarginH = 'ereader_margin_h';
  static const _kMarginV = 'ereader_margin_v';
  static const _kSpread = 'ereader_spread';
  static const _kTheme = 'ereader_theme';
  static const _kFont = 'ereader_font';

  // Gates the WebView mount until the entering route animation completes, so
  // the heavy platform view doesn't stutter the open transition.
  bool _entered = false;
  Animation<double>? _routeAnim;

  // In-reader media controls (immersion reading) drive the shared player.
  int _forwardSkip = 30;
  int _backSkip = 10;
  // This item's audiobook metadata, so the controls can show (and start
  // playback) even before a session is running.
  bool _hasAudio = false;
  double _audioDuration = 0;
  List<dynamic> _audioChapters = const [];
  String _audioAuthor = '';
  String? _audioCoverUrl;
  bool _startingAudio = false;
  // Held from initState so dispose can lift the quiet without a context read.
  late final LibraryProvider _quietLib;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _epubController = EpubController();
    _quietLib = context.read<LibraryProvider>();
    _quietLib.setReaderQuiet(true);
    _loadInitialLocation();
    // A settings read failure must not stop the book from opening - fall back
    // to the field defaults and open anyway.
    _loadSettings()
        .catchError((e) => debugPrint('[EbookReader] settings load failed: $e'))
        .whenComplete(_downloadAndOpen);
    // Fullscreen is toggled once the open transition completes (see _onRouteAnim
    // / didChangeDependencies), not here: hiding the system bars mid-transition
    // forces a full relayout while the busy home screen is still compositing
    // behind the sliding-in reader, which makes opening from a home card janky.
    PlayerSettings.settingsChanged.addListener(_loadSkipSettings);
    _loadSkipSettings();
    _loadAudioMeta();
    _volumeNav.attach();
  }

  late final EreaderVolumeNav _volumeNav = EreaderVolumeNav(
    onPrev: () => _epubController?.prev(),
    onNext: () => _epubController?.next(),
  );

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _readerActive = true;
      // Restore the page we were on before the recents/background resize drifted
      // it - only if a stray relocation actually fired while away, so the common
      // no-resize round trip doesn't get a redundant re-display. Delay so the
      // window has settled back to full size and epub.js has re-paginated,
      // otherwise the re-display would round against the wrong (still-resizing)
      // layout.
      final cfi = _bgCfi;
      final drifted = _bgDrifted;
      _bgCfi = null;
      _bgDrifted = false;
      if (drifted && cfi != null && cfi.isNotEmpty) {
        Future.delayed(const Duration(milliseconds: 350), () {
          if (mounted && _readerActive) _epubController?.display(cfi: cfi);
        });
      }
    } else {
      // Leaving the foreground: snapshot the real page and stop trusting
      // relocations until we're back (they'll be resize artifacts).
      if (_readerActive) _bgCfi = _currentCfi;
      _readerActive = false;
    }
  }

  Future<void> _loadAudioMeta() async {
    final lib = context.read<LibraryProvider>();
    _audioCoverUrl = lib.getCoverUrl(widget.itemId);
    final api = context.read<AuthProvider>().apiService;
    if (api == null) return;
    try {
      final item = await api.getLibraryItem(widget.itemId);
      if (item == null || !mounted) return;
      final media = item['media'] as Map<String, dynamic>? ?? {};
      final metadata = media['metadata'] as Map<String, dynamic>? ?? {};
      final dur = (media['duration'] as num?)?.toDouble() ?? 0;
      setState(() {
        _audioAuthor = metadata['authorName'] as String? ?? '';
        _audioDuration = dur;
        _audioChapters = media['chapters'] as List<dynamic>? ?? const [];
        _hasAudio = dur > 0;
      });
    } catch (_) {}
  }

  Future<void> _startThisBook() async {
    if (_startingAudio || !_hasAudio) return;
    final api = context.read<AuthProvider>().apiService;
    if (api == null) return;
    setState(() => _startingAudio = true);
    final lib = context.read<LibraryProvider>();
    lib.addToAbsorbing(widget.itemId);
    await AudioPlayerService().playItem(
      api: api,
      itemId: widget.itemId,
      title: widget.title,
      author: _audioAuthor,
      coverUrl: _audioCoverUrl,
      totalDuration: _audioDuration,
      chapters: _audioChapters,
      libraryId: lib.selectedLibraryId,
      fromUi: true,
    );
    if (mounted) setState(() => _startingAudio = false);
  }

  void _loadSkipSettings() {
    PlayerSettings.getForwardSkip().then((v) {
      if (mounted && v != _forwardSkip) setState(() => _forwardSkip = v);
    });
    PlayerSettings.getBackSkip().then((v) {
      if (mounted && v != _backSkip) setState(() => _backSkip = v);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_entered) return;
    _routeAnim = ModalRoute.of(context)?.animation;
    if (_routeAnim == null || _routeAnim!.isCompleted) {
      _entered = true;
      _setFullscreen(true); // no transition to wait for
    } else {
      _routeAnim!.addStatusListener(_onRouteAnim);
    }
  }

  void _onRouteAnim(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted) {
      _routeAnim?.removeStatusListener(_onRouteAnim);
      // Defer the immersive relayout until the reader fully covers the screen, so
      // it doesn't jank the open animation over the busy home screen.
      _setFullscreen(true);
      setState(() => _entered = true);
    }
  }

  Future<void> _loadSettings() async {
    _fontSize = await ScopedPrefs.getInt(_kFontSize) ?? 16;
    _lineHeight = await ScopedPrefs.getDouble(_kLineHeight) ?? 1.4;
    final legacyMargin = await ScopedPrefs.getInt(_kMargin) ?? 16;
    _marginH = await ScopedPrefs.getInt(_kMarginH) ?? legacyMargin;
    _marginV = await ScopedPrefs.getInt(_kMarginV) ?? legacyMargin;
    final si = (await ScopedPrefs.getInt(_kSpread) ?? 0).clamp(0, 2);
    _spread = _spreadModes[si];
    _themeId = await ScopedPrefs.getString(_kTheme) ?? '';
    _fontId = await ScopedPrefs.getString(_kFont) ?? 'original';
    _volumeNavMode = await PlayerSettings.getEreaderVolumeNav();
    _volumeNavWhilePlaying = await PlayerSettings.getEreaderVolumeNavWhilePlaying();
    if (mounted) setState(() {});
  }

  // Resolve the active palette; empty selection follows the app's brightness.
  _ReaderPalette _resolvePalette(BuildContext context) {
    for (final p in _kReaderPalettes) {
      if (p.id == _themeId) return p;
    }
    final dark = Theme.of(context).brightness == Brightness.dark;
    return dark ? _kReaderPalettes[3] : _kReaderPalettes[0];
  }

  ReaderFont get _font => readerFontById(_fontId) ?? kBuiltinReaderFonts.first;

  Future<void> _updateReaderTheme(String id) async {
    if (id == _themeId) return;
    setState(() => _themeId = id);
    _applySettings();
    await ScopedPrefs.setString(_kTheme, id);
  }

  Future<void> _updateReaderFont(String id) async {
    if (id == _fontId) return;
    setState(() => _fontId = id);
    _applySettings();
    await _applyFontFace();
    await ScopedPrefs.setString(_kFont, id);
  }

  /// Define the @font-face injector once: a content hook that stamps the
  /// current downloaded font's @font-face into every rendered section's iframe.
  void _setupFontInjector() {
    _epubController?.webViewController?.evaluateJavascript(source: '''
      (function(){
        if (window.__absorbFontInit) return;
        window.__absorbFontInit = true;
        window.__absorbFontFace = '';
        function applyTo(doc){
          if(!doc || !doc.head) return;
          var old = doc.getElementById('absorb-fontface');
          if(old && old.parentNode) old.parentNode.removeChild(old);
          if(!window.__absorbFontFace) return;
          var s = doc.createElement('style');
          s.id = 'absorb-fontface';
          s.textContent = window.__absorbFontFace;
          doc.head.appendChild(s);
        }
        window.__absorbApplyFont = function(css){
          window.__absorbFontFace = css || '';
          try { rendition.getContents().forEach(function(c){ applyTo(c.document); }); } catch(e){}
        };
        try { rendition.hooks.content.register(function(contents){ applyTo(contents.document); }); } catch(e){}
      })();
    ''');
  }

  /// Inject (or clear) the @font-face for the selected font as a base64 data
  /// URI, so a downloaded woff2 renders inside the WebView on iOS and Android.
  Future<void> _applyFontFace() async {
    final font = _font;
    String css = '';
    if (font.downloadable) {
      final b64 = await ReaderFontService().base64Woff2(font.id);
      if (b64 != null) {
        css = '@font-face{font-family:"${font.family}";'
            'src:url(data:font/woff2;base64,$b64) format("woff2");font-display:swap;}';
      }
    }
    await _epubController?.webViewController?.evaluateJavascript(
        source: "if(window.__absorbApplyFont){window.__absorbApplyFont('$css');}");
  }

  Future<void> _updateSpread(int index) async {
    final mode = _spreadModes[index];
    if (mode == _spread) return;
    setState(() {
      // Re-open at the current page after the layout rebuild.
      _initialCfi = _currentCfi ?? _initialCfi;
      _spread = mode;
      _locationsReady = false;
      _viewerKey++; // force the viewer to remount with the new spread
      _didLoadRescue = false; // let the remounted viewer rescue its first paint
      _didInitViewer = false; // fresh JS context needs its wiring again
    });
    await ScopedPrefs.setInt(_kSpread, index);
  }

  EpubTheme _buildTheme(_ReaderPalette p) {
    // No foregroundColor on purpose: all colors live in customCss. The
    // plugin's loadBook ends with updateTheme(background, foreground) WITHOUT
    // the customCss arg - if a foreground color is set, that call re-registers
    // the theme with just a body color and wipes every customCss rule (text
    // color inherit, line height, margins, scroll smoothness). With no colors
    // passed, that wipe call builds zero rules and becomes a no-op, so the
    // full theme from load survives and no post-load re-apply is needed.
    final font = _font;
    final body = <String, String>{
      // !important so a book's own stylesheet can't override the reader theme
      // (some books set their own body colors, which left the page white with
      // black text regardless of the chosen theme).
      'color': '${p.fg} !important',
      'background': '${p.bg} !important',
      'line-height': '$_lineHeight',
      'padding': '${_marginV}px 0 !important',
      'margin': '0px !important',
      'box-sizing': 'border-box !important',
      'max-width': '100vw !important',
      'overflow-x': 'hidden !important',
      '-webkit-overflow-scrolling': 'touch',
      'will-change': 'scroll-position',
    };
    final textRule = <String, String>{'color': 'inherit !important'};
    if (font.family.isNotEmpty) {
      final fam = font.downloadable ? '"${font.family}"' : font.family;
      body['font-family'] = '$fam !important';
      textRule['font-family'] = '$fam !important';
    }
    return EpubTheme.custom(
      backgroundDecoration: BoxDecoration(color: p.bgColor),
      customCss: {
        // Theme the root too: some books put a background on html (or leave body
        // narrower than the page), which would otherwise show through white.
        'html': {'background': '${p.bg} !important'},
        'body': body,
        'p, div, span, h1, h2, h3, h4, h5, h6, li, td, th, a, em, strong, blockquote': textRule,
      },
    );
  }

  void _applySettings() {
    _epubController?.setFontSize(fontSize: _fontSize.toDouble());
    _epubController?.updateTheme(theme: _buildTheme(_resolvePalette(context)));
  }

  Future<void> _updateFontSize(int size) async {
    setState(() => _fontSize = size);
    _epubController?.setFontSize(fontSize: size.toDouble());
    await ScopedPrefs.setInt(_kFontSize, size);
  }

  Future<void> _updateLineHeight(double height) async {
    setState(() => _lineHeight = height);
    _applySettings();
    await ScopedPrefs.setDouble(_kLineHeight, height);
  }

  Future<void> _updateMarginH(int margin) async {
    // Side margins resize the WebView (handled in _buildViewerArea), so just
    // rebuild - no CSS re-apply needed.
    setState(() => _marginH = margin);
    await ScopedPrefs.setInt(_kMarginH, margin);
  }

  Future<void> _updateMarginV(int margin) async {
    setState(() => _marginV = margin);
    _applySettings();
    await ScopedPrefs.setInt(_kMarginV, margin);
  }

  @override
  void dispose() {
    _quietLib.setReaderQuiet(false);
    WidgetsBinding.instance.removeObserver(this);
    _volumeNav.detach();
    _routeAnim?.removeStatusListener(_onRouteAnim);
    PlayerSettings.settingsChanged.removeListener(_loadSkipSettings);
    // Restore system UI when leaving
    _setFullscreen(false);
    super.dispose();
  }

  void _setFullscreen(bool fullscreen) {
    if (fullscreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      // Explicitly show top + bottom bars. edgeToEdge alone doesn't reliably
      // undo immersiveSticky on every Android version.
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: SystemUiOverlay.values,
      );
    }
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
  }

  DateTime _lastReaderTap = DateTime.fromMillisecondsSinceEpoch(0);

  /// Shared tap handler: left quarter = previous page, right quarter = next,
  /// center = toggle controls. [frac] is the tap's x position 0..1 across the
  /// page. Debounced so the touch and injected-click paths can't double-fire.
  void _readerTapAt(double frac, String source) {
    final now = DateTime.now();
    final sinceMs = now.difference(_lastReaderTap).inMilliseconds;
    if (sinceMs < 350) {
      debugPrint('[ReaderTap] DEBOUNCED frac=${frac.toStringAsFixed(2)} src=$source since=${sinceMs}ms');
      return;
    }
    _lastReaderTap = now;
    final action = frac < 0.25 ? 'prev' : (frac > 0.75 ? 'next' : 'menu');
    debugPrint('[ReaderTap] frac=${frac.toStringAsFixed(2)} src=$source -> $action ctrl=${_epubController != null}');
    if (frac < 0.25) {
      _epubController?.prev();
    } else if (frac > 0.75) {
      _epubController?.next();
    } else {
      _toggleControls();
    }
  }

  /// epub.js touch callbacks don't fire on iOS, so inject our own click
  /// listener into each rendered section and route it to a handler we register
  /// (the same callHandler bridge the selection menu uses). Skips taps while
  /// text is selected so highlighting still works.
  void _setupTapHandler() {
    _epubController?.webViewController?.addJavaScriptHandler(
      handlerName: 'absorbReaderTap',
      callback: (args) {
        final frac = args.isNotEmpty ? (args[0] as num?)?.toDouble() : null;
        final src = args.length > 1 ? '${args[1]}' : 'js';
        if (frac != null) _readerTapAt(frac.clamp(0.0, 1.0), 'js:$src');
      },
    );
    _epubController?.webViewController?.evaluateJavascript(source: '''
      (function(){
        if (window.__absorbTapInit) return;
        window.__absorbTapInit = true;
        function send(frac, kind){
          try { if(window.flutter_inappwebview){ window.flutter_inappwebview.callHandler('absorbReaderTap', frac, kind); return; } } catch(e){}
          try { if(window.parent && window.parent.flutter_inappwebview){ window.parent.flutter_inappwebview.callHandler('absorbReaderTap', frac, kind); } } catch(e){}
        }
        function onTap(e, kind){
          try {
            var win = e.view || window;
            var sel = win.getSelection ? win.getSelection() : null;
            if (sel && String(sel).length > 0) return; // selecting text, not a tap
            var w = win.innerWidth || window.innerWidth;
            if (!w) return;
            var cx = (e.clientX != null) ? e.clientX
              : (e.changedTouches && e.changedTouches[0] ? e.changedTouches[0].clientX : null);
            if (cx == null) return;
            send(cx / w, kind);
          } catch(err){}
        }
        function attach(doc){
          try {
            // Track the touch start and whether the gesture became a drag, so a
            // swipe doesn't fall through to a center-tap (menu toggle) on release.
            var _tsx=null,_tsy=null,_dragged=false;
            doc.addEventListener('touchstart',function(e){
              if(e.touches.length===1){_tsx=e.touches[0].clientX;_tsy=e.touches[0].clientY;_dragged=false;}
              else{_tsx=null;}
            },{passive:true});
            doc.addEventListener('touchmove',function(e){
              if(_tsx==null)return;
              var dx=Math.abs(e.touches[0].clientX-_tsx),dy=Math.abs(e.touches[0].clientY-_tsy);
              if(dx>10||dy>10)_dragged=true;
              // Swallow horizontal drags so epub.js can't partially scroll the column.
              if(dx>dy)e.preventDefault();
            },{passive:false});
            function onTapGuarded(e,kind){
              if(_dragged){ if(kind==='touchend')_dragged=false; return; }
              onTap(e,kind);
            }
            doc.addEventListener('click', function(e){ onTapGuarded(e,'click'); }, true);
            doc.addEventListener('pointerup', function(e){ onTapGuarded(e,'pointerup'); }, true);
            doc.addEventListener('touchend', function(e){ onTapGuarded(e,'touchend'); }, true);
          } catch(e){}
        }
        try { rendition.getContents().forEach(function(c){ attach(c.document); }); } catch(e){}
        try { rendition.hooks.content.register(function(contents){ attach(contents.document); }); } catch(e){}
      })();
    ''');
  }

  void _loadInitialLocation() {
    final lib = context.read<LibraryProvider>();
    // A highlight jump wins over the saved reading position; the percent below
    // still comes from saved progress so the bar isn't at 0 until epub.js has
    // indexed locations.
    final target = widget.openAtCfi;
    if (target != null && target.isNotEmpty) {
      _initialCfi = pointCfi(target);
      _settleJumpCfi = _initialCfi;
    }
    final progressData = lib.getProgressData(widget.itemId);
    final loc = progressData?['ebookLocation'] as String?;
    if (_initialCfi == null && loc != null && loc.isNotEmpty) {
      _initialCfi = loc;
    }
    // Seed the displayed percent from saved progress so the bar shows the
    // resume position until epub.js's location index is ready, and so the
    // pre-index save keeps this value instead of regressing to 0.
    final savedProgress = (progressData?['ebookProgress'] as num?)?.toDouble();
    if (savedProgress != null) _progress = savedProgress.clamp(0.0, 1.0);
  }

  Future<void> _downloadAndOpen() async {
    try {
      final auth = context.read<AuthProvider>();
      final api = auth.apiService;
      if (api == null) {
        setState(() { _error = 'Not connected to server'; _loading = false; });
        return;
      }
      // Shared persistent cache - reuses a downloaded/previously-opened copy so
      // the book reads offline.
      final playing = AudioPlayerService().isPlaying;
      debugPrint('[EbookReader] open item=${widget.itemId} ext=${ebookExtFromFile(widget.ebookFile)} '
          'cached=${await isEbookCached(widget.itemId, widget.ebookFile)} playing=$playing');
      final file = await fetchEbookToCache(api, widget.itemId, widget.ebookFile, widget.title);
      final len = file.existsSync() ? await file.length() : 0;
      debugPrint('[EbookReader] file ready item=${widget.itemId} bytes=$len path=${file.path}');
      if (mounted) {
        setState(() { _cachedFile = file; _loading = false; });
      }
    } catch (e) {
      debugPrint('[EbookReader] Error: $e');
      if (mounted) {
        setState(() { _error = 'Error loading ebook: $e'; _loading = false; });
      }
    }
  }

  void _syncProgress(String cfi, double progress) {
    final auth = context.read<AuthProvider>();
    final api = auth.apiService;
    if (api == null) return;
    ProgressSyncService().pushEbookProgress(
      api,
      widget.itemId,
      location: cfi,
      progress: progress,
    );
    context.read<LibraryProvider>().applyLocalEbookProgress(
      widget.itemId, location: cfi, progress: progress);
  }

  Future<void> _loadAnnotations() async {
    _annotations = await _annotationService.getAnnotations(widget.itemId);
    if (mounted) setState(() {});
  }

  void _restoreHighlights() {
    for (final a in _annotations) {
      if (a.type == AnnotationType.highlight && a.color != null) {
        _epubController?.addHighlight(
          cfi: a.cfi,
          color: Color(int.parse('FF${a.color!.hex.substring(1)}', radix: 16)),
          opacity: 0.35,
        );
      }
    }
  }

  void _setupPageInfoHandler() {
    _epubController?.webViewController?.addJavaScriptHandler(
      handlerName: 'pageInfo',
      callback: (args) {
        if (!mounted || args.isEmpty) return;
        final data = args[0] as Map<String, dynamic>?;
        if (data == null) return;
        final page = data['page'] as int? ?? 0;
        final total = data['total'] as int? ?? 0;
        final href = data['href'] as String? ?? '';
        // Resolve the current section to its chapter title; keep the last one
        // if this section isn't in the TOC.
        final chapter = href.isNotEmpty
            ? (_chapterForHref(href) ?? _currentChapterTitle)
            : _currentChapterTitle;
        // Brief total=0 reports happen at chapter handoffs; keep the last
        // valid count visible rather than blanking the indicator.
        if (total == 0 && _chapterPageTotal > 0) return;
        if (page != _chapterPage ||
            total != _chapterPageTotal ||
            chapter != _currentChapterTitle) {
          setState(() {
            _chapterPage = page;
            _chapterPageTotal = total;
            _currentChapterTitle = chapter;
          });
        }
      },
    );
    _epubController?.webViewController?.evaluateJavascript(
      source: '''
        (function() {
          rendition.on('relocated', function(location) {
            if (location && location.start && location.start.displayed) {
              window.flutter_inappwebview.callHandler('pageInfo', {
                page: location.start.displayed.page,
                total: location.start.displayed.total,
                href: location.start.href || ''
              });
            }
          });
        })();
      ''',
    );
  }

  Future<void> _addHighlight(HighlightColor color) async {
    if (_selectionCfi == null || _selectionText == null) return;
    final annotation = await _annotationService.addHighlight(
      itemId: widget.itemId,
      cfi: _selectionCfi!,
      selectedText: _selectionText!,
      color: color,
      chapter: _currentChapterTitle,
    );
    _epubController?.addHighlight(
      cfi: annotation.cfi,
      color: Color(int.parse('FF${color.hex.substring(1)}', radix: 16)),
      opacity: 0.35,
    );
    _annotations.insert(0, annotation);
    if (mounted) _dismissSelection();
  }

  /// [onThisPage] is for a highlight tapped in the book: the reader is sitting
  /// in its chapter, so an older highlight with no recorded chapter can borrow
  /// the current one. From the list it would be a guess, so it stays blank.
  Future<void> _shareHighlight(EbookAnnotation annotation,
      {bool onThisPage = false}) async {
    final text = annotation.selectedText ?? '';
    if (text.isEmpty) return;
    await showQuoteShareSheet(
      context,
      itemId: widget.itemId,
      quote: text,
      bookTitle: widget.title,
      author: _audioAuthor.isEmpty ? null : _audioAuthor,
      chapter: annotation.chapter ?? (onThisPage ? _currentChapterTitle : null),
    );
  }

  Future<void> _removeHighlight(EbookAnnotation annotation) async {
    _epubController?.removeHighlight(cfi: annotation.cfi);
    await _annotationService.delete(
      itemId: widget.itemId,
      annotationId: annotation.id,
    );
    _annotations.removeWhere((a) => a.id == annotation.id);
    if (mounted) setState(() {});
  }

  Future<void> _toggleBookmark() async {
    final cfi = _currentCfi;
    if (cfi == null) return;

    if (_hasBookmarkAtCurrent) {
      // Remove existing bookmark at this location
      final existing = _annotations.where(
        (a) => a.type == AnnotationType.bookmark && a.cfi == cfi,
      ).toList();
      for (final bm in existing) {
        await _annotationService.delete(
          itemId: widget.itemId,
          annotationId: bm.id,
        );
        _annotations.removeWhere((a) => a.id == bm.id);
      }
    } else {
      final annotation = await _annotationService.addBookmark(
        itemId: widget.itemId,
        cfi: cfi,
        chapter: _currentChapterTitle,
      );
      _annotations.insert(0, annotation);
    }
    _updateBookmarkState();
    if (mounted) setState(() {});
  }

  void _updateBookmarkState() {
    final cfi = _currentCfi;
    _hasBookmarkAtCurrent = cfi != null &&
        _annotations.any((a) => a.type == AnnotationType.bookmark && a.cfi == cfi);
  }

  void _clearSelection() {
    _selectionText = null;
    _selectionCfi = null;
    _selectionRect = null;
  }

  /// Clears both our toolbar state and the WebView's native selection. The
  /// plugin's JS blocks page-turn taps while a selection is active, so leaving
  /// the native selection behind locks the user on the page.
  void _dismissSelection() {
    _epubController?.clearSelection();
    setState(() => _clearSelection());
  }

  Widget _divider(ColorScheme cs) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 2),
    child: Container(width: 1, height: 24, color: cs.onSurface.withValues(alpha: 0.15)),
  );

  void _copySelection() {
    if (_selectionText == null) return;
    Clipboard.setData(ClipboardData(text: _selectionText!));
    _dismissSelection();
    showOverlayToast(context, AppLocalizations.of(context)!.readerCopied,
        icon: Icons.content_copy_rounded);
  }

  void _searchSelection() {
    if (_selectionText == null) return;
    final query = Uri.encodeComponent(_selectionText!.trim());
    launchUrl(Uri.parse('https://www.google.com/search?q=$query'), mode: LaunchMode.externalApplication);
    _dismissSelection();
  }

  void _defineSelection() {
    if (_selectionText == null) return;
    final word = _selectionText!.trim().split(RegExp(r'\s+')).first;
    final query = Uri.encodeComponent('define $word');
    launchUrl(Uri.parse('https://www.google.com/search?q=$query'), mode: LaunchMode.externalApplication);
    _dismissSelection();
  }

  void _onSelection(String text, String cfi, Rect selRect, Rect vRect) {
    if (text.trim().isEmpty) return;
    setState(() {
      _selectionText = text;
      _selectionCfi = cfi;
      _selectionRect = selRect;
    });
  }

  Future<void> _addNoteToAnnotation(EbookAnnotation annotation) async {
    final controller = TextEditingController(text: annotation.note ?? '');
    final l = AppLocalizations.of(context)!;
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(children: [
          Expanded(child: Text(l.readerNoteTitle)),
          if ((annotation.selectedText ?? '').isNotEmpty)
            IconButton(
              icon: const Icon(Icons.ios_share_rounded),
              tooltip: l.quoteShareTitle,
              onPressed: () {
                Navigator.pop(ctx);
                _shareHighlight(annotation, onThisPage: true);
              },
            ),
        ]),
        content: TextField(
          controller: controller,
          maxLines: 5,
          autofocus: true,
          decoration: InputDecoration(
            hintText: l.readerNoteHint,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: Text(l.save),
          ),
        ],
      ),
    );
    if (result != null) {
      await _annotationService.updateNote(
        itemId: widget.itemId,
        annotationId: annotation.id,
        note: result.isEmpty ? null : result,
      );
      annotation.note = result.isEmpty ? null : result;
      if (mounted) setState(() {});
    }
  }

  void _navigateToChapter(String href) {
    final escaped = href.replaceAll("'", "\\'");
    _epubController?.webViewController?.evaluateJavascript(
      source: '''
        (function() {
          rendition.display('$escaped').then(function(section) {
            rendition.resize();
            // RTL books land on the wrong page after a chapter jump: epub.js resets
            // the scroll to 0 and only repositions right-to-left content when the
            // target carries an in-chapter anchor, which a bare chapter href does
            // not. Re-run epub.js's own RTL placement (scroll the target section's
            // view to offset+width, which resolves to its first/rightmost page)
            // against the section we actually navigated to. find(section) is used
            // rather than the last view because the continuous manager appends the
            // next chapter during display. Gated to RTL so left-to-right books are
            // untouched; epub.js's post-display location report picks up the
            // corrected scroll, so we don't fire our own.
            try {
              var mgr = rendition.manager;
              if (section && mgr && rendition.settings
                  && rendition.settings.direction === 'rtl'
                  && mgr.layout && mgr.layout.name !== 'pre-paginated') {
                var view = mgr.views.find(section);
                if (view) {
                  var off = view.offset();
                  mgr.scrollTo(off.left + view.width(), off.top, true);
                }
              }
            } catch (e) {}
          });
        })();
      ''',
    );
  }

  List<EpubChapter> _flattenChapters(List<EpubChapter> chapters) {
    final flat = <EpubChapter>[];
    for (final ch in chapters) {
      flat.add(ch);
      if (ch.subitems.isNotEmpty) {
        flat.addAll(_flattenChapters(ch.subitems));
      }
    }
    return flat;
  }

  void _showChapterList() {
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(AppLocalizations.of(ctx)!.readerChapters, style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: cs.onSurface)),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _chapters.length,
                itemBuilder: (ctx, i) {
                  final ch = _chapters[i];
                  return ListTile(
                    title: Text(ch.title.trim(), maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: cs.onSurface)),
                    dense: true,
                    onTap: () {
                      Navigator.pop(ctx);
                      _navigateToChapter(ch.href);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSettingsSheet() {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    // Live preview for the side-margin slider so the WebView only re-paginates
    // when the drag ends, not on every step.
    int hPreview = _marginH;
    showModalBottomSheet(
      context: context,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final l = AppLocalizations.of(ctx)!;
          return SafeArea(
          child: SingleChildScrollView(
            child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 32, height: 4,
                    decoration: BoxDecoration(
                      color: cs.onSurface.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(l.readerSettings, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 20),

                // Font size
                Row(children: [
                  Icon(Icons.text_fields_rounded, size: 20, color: cs.onSurfaceVariant),
                  const SizedBox(width: 12),
                  Text(l.readerFontSize, style: tt.bodyMedium),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.remove_rounded, size: 20, color: cs.onSurfaceVariant),
                    onPressed: _fontSize > 10 ? () {
                      setSheetState(() {});
                      _updateFontSize(_fontSize - 1);
                    } : null,
                  ),
                  Text('$_fontSize', style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                  IconButton(
                    icon: Icon(Icons.add_rounded, size: 20, color: cs.onSurfaceVariant),
                    onPressed: _fontSize < 32 ? () {
                      setSheetState(() {});
                      _updateFontSize(_fontSize + 1);
                    } : null,
                  ),
                ]),
                const SizedBox(height: 8),

                // Line height
                Row(children: [
                  Icon(Icons.format_line_spacing_rounded, size: 20, color: cs.onSurfaceVariant),
                  const SizedBox(width: 12),
                  Text(l.readerLineSpacing, style: tt.bodyMedium),
                  const Spacer(),
                  Text(_lineHeight.toStringAsFixed(1), style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                ]),
                Slider(
                  value: _lineHeight,
                  min: 1.0,
                  max: 2.5,
                  divisions: 15,
                  onChanged: (v) {
                    setSheetState(() {});
                    _updateLineHeight(double.parse(v.toStringAsFixed(1)));
                  },
                ),
                const SizedBox(height: 8),

                // Side margins (left + right)
                Row(children: [
                  Icon(Icons.padding_rounded, size: 20, color: cs.onSurfaceVariant),
                  const SizedBox(width: 12),
                  Text(l.readerSideMargins, style: tt.bodyMedium),
                  const Spacer(),
                  Text('${hPreview}px', style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                ]),
                Slider(
                  value: hPreview.toDouble(),
                  min: 0,
                  max: 64,
                  divisions: 16,
                  onChanged: (v) => setSheetState(() => hPreview = v.round()),
                  onChangeEnd: (v) => _updateMarginH(v.round()),
                ),
                const SizedBox(height: 4),

                // Top & bottom margins
                Row(children: [
                  Icon(Icons.vertical_align_center_rounded, size: 20, color: cs.onSurfaceVariant),
                  const SizedBox(width: 12),
                  Text(l.readerTopBottom, style: tt.bodyMedium),
                  const Spacer(),
                  Text('${_marginV}px', style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                ]),
                Slider(
                  value: _marginV.toDouble(),
                  min: 0,
                  max: 64,
                  divisions: 16,
                  onChanged: (v) {
                    setSheetState(() {});
                    _updateMarginV(v.round());
                  },
                ),
                const SizedBox(height: 12),

                // Page layout — Auto shows two pages on wide screens (tablets).
                Row(children: [
                  Icon(Icons.auto_stories_rounded, size: 20, color: cs.onSurfaceVariant),
                  const SizedBox(width: 12),
                  Text(l.readerPageLayout, style: tt.bodyMedium),
                ]),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<int>(
                    segments: [
                      ButtonSegment(value: 0, label: Text(l.readerLayoutAuto)),
                      ButtonSegment(value: 1, label: Text(l.readerLayoutSingle)),
                      ButtonSegment(value: 2, label: Text(l.readerLayoutTwoPage)),
                    ],
                    selected: {_spreadModes.indexOf(_spread)},
                    showSelectedIcon: false,
                    onSelectionChanged: (s) {
                      setSheetState(() {});
                      _updateSpread(s.first);
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Theme (background + text colors)
                Row(children: [
                  Icon(Icons.palette_outlined, size: 20, color: cs.onSurfaceVariant),
                  const SizedBox(width: 12),
                  Text(l.readerTheme, style: tt.bodyMedium),
                ]),
                const SizedBox(height: 10),
                Row(
                  children: [
                    for (final p in _kReaderPalettes) ...[
                      _themeSwatch(
                        p,
                        (_themeId.isEmpty ? _resolvePalette(context).id : _themeId) == p.id,
                        () { setSheetState(() {}); _updateReaderTheme(p.id); },
                        cs,
                      ),
                      const SizedBox(width: 12),
                    ],
                  ],
                ),
                const SizedBox(height: 16),

                // Font — opens a picker with built-in + downloadable fonts.
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () async {
                    await _showFontSheet();
                    setSheetState(() {});
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(children: [
                      Icon(Icons.font_download_outlined, size: 20, color: cs.onSurfaceVariant),
                      const SizedBox(width: 12),
                      Text(l.readerFont, style: tt.bodyMedium),
                      const Spacer(),
                      Text(_font.label,
                          style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(width: 4),
                      Icon(Icons.chevron_right_rounded, size: 20, color: cs.onSurfaceVariant),
                    ]),
                  ),
                ),
                const SizedBox(height: 16),

                // Volume keys turn pages (normal: up = previous, down = next)
                Row(children: [
                  Icon(Icons.swap_vert_rounded, size: 20, color: cs.onSurfaceVariant),
                  const SizedBox(width: 12),
                  Expanded(child: Text(l.readerVolumeNav, style: tt.bodyMedium)),
                ]),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<String>(
                    showSelectedIcon: false,
                    segments: [
                      ButtonSegment(value: 'off', label: Text(l.readerVolumeNavOff)),
                      ButtonSegment(value: 'normal', label: Text(l.readerVolumeNavNormal)),
                      ButtonSegment(value: 'mirrored', label: Text(l.readerVolumeNavMirrored)),
                    ],
                    selected: {_volumeNavMode},
                    onSelectionChanged: (sel) {
                      final v = sel.first;
                      setSheetState(() {});
                      setState(() => _volumeNavMode = v);
                      PlayerSettings.setEreaderVolumeNav(v);
                    },
                    style: const ButtonStyle(visualDensity: VisualDensity.compact),
                  ),
                ),
                if (_volumeNavMode != 'off')
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l.readerVolumeNavWhilePlaying, style: tt.bodyMedium),
                    value: _volumeNavWhilePlaying,
                    onChanged: (v) {
                      setSheetState(() {});
                      setState(() => _volumeNavWhilePlaying = v);
                      PlayerSettings.setEreaderVolumeNavWhilePlaying(v);
                    },
                  ),
              ],
            ),
          ),
          ),
        );
        },
      ),
    );
  }

  Widget _themeSwatch(_ReaderPalette p, bool selected, VoidCallback onTap, ColorScheme cs) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: p.bgColor,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? cs.primary : cs.onSurface.withValues(alpha: 0.25),
            width: selected ? 3 : 1,
          ),
        ),
        child: Center(
          child: Text('Aa',
              style: TextStyle(color: p.fgColor, fontSize: 13, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  /// Font picker: built-in fonts plus downloadable ones (downloaded once, then
  /// rendered via injected @font-face). Live download state via the service.
  Future<void> _showFontSheet() async {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final svc = ReaderFontService();
    await svc.load();
    await showModalBottomSheet(
      context: context,
      backgroundColor: cs.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: ListenableBuilder(
          listenable: svc,
          builder: (ctx, _) {
            Widget tile(ReaderFont f) {
              final selected = f.id == _fontId;
              final installed = !f.downloadable || svc.isInstalled(f.id);
              final downloading = svc.isDownloading(f.id);
              return ListTile(
                dense: true,
                leading: Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: selected ? cs.primary : cs.onSurfaceVariant,
                ),
                title: Text(f.label,
                    style: TextStyle(
                        color: cs.onSurface,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w400)),
                trailing: downloading
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : (f.downloadable
                        ? (installed
                            ? IconButton(
                                icon: Icon(Icons.delete_outline_rounded,
                                    color: cs.onSurfaceVariant),
                                tooltip: AppLocalizations.of(context)!.readerFontRemove,
                                onPressed: () => svc.remove(f.id),
                              )
                            : Icon(Icons.download_rounded, color: cs.primary))
                        : null),
                onTap: () async {
                  if (installed) {
                    _updateReaderFont(f.id);
                    if (mounted) Navigator.of(ctx).pop();
                    return;
                  }
                  final ok = await svc.download(f);
                  if (ok) {
                    _updateReaderFont(f.id);
                    if (mounted) Navigator.of(ctx).pop();
                  } else if (mounted) {
                    showOverlayToast(context, AppLocalizations.of(context)!.readerFontDownloadFailed(f.label),
                        icon: Icons.error_outline_rounded);
                  }
                },
              );
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: cs.onSurface.withValues(alpha: 0.24),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(AppLocalizations.of(ctx)!.readerFont,
                        style: tt.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600, color: cs.onSurface)),
                  ),
                ),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final f in kBuiltinReaderFonts) tile(f),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                        child: Text(AppLocalizations.of(ctx)!.readerMoreFonts,
                            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                      ),
                      for (final f in kDownloadableReaderFonts) tile(f),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Maps a spine item href to its TOC chapter title. The spine href and the
  /// TOC href often differ by directory prefix or URL-encoding (e.g.
  /// `OEBPS/Text/ch1.xhtml` vs `Text/ch1.xhtml` vs `ch1%20.xhtml`), so match on
  /// the decoded basename first and fall back to a suffix check. Chapters
  /// pointing at sub-fragments of the same spine item all map to the same
  /// label, which is fine for a search result subtitle.
  String? _chapterForHref(String href) {
    if (href.isEmpty || _chapters.isEmpty) return null;
    String basename(String s) {
      var p = s.split('#').first;
      try { p = Uri.decodeFull(p); } catch (_) {}
      return p.split('/').last.toLowerCase();
    }
    // TOC labels often carry the nav markup's indentation/newlines, so trim.
    String? label(String t) => t.trim().isEmpty ? null : t.trim();
    final base = basename(href);
    if (base.isNotEmpty) {
      for (final ch in _chapters) {
        if (basename(ch.href) == base) return label(ch.title);
      }
    }
    // Fallback: suffix match on the full path.
    final path = href.split('#').first;
    for (final ch in _chapters) {
      final tocPath = ch.href.split('#').first;
      if (tocPath.isEmpty) continue;
      if (path.endsWith(tocPath) || tocPath.endsWith(path)) return label(ch.title);
    }
    return null;
  }

  /// Searches the whole book. Bypasses the plugin's search(): that one runs
  /// Promise.all over the spine with no error handling, so a single chapter
  /// that fails to load means the result handler never fires and the await
  /// hangs forever. This version searches chapter by chapter, skips broken
  /// ones, and tags each hit with the spine href so we can label it with a
  /// chapter title.
  Future<_SearchPayload> _searchBook(String q) async {
    final wc = _epubController?.webViewController;
    if (wc == null) return _SearchPayload(query: q, results: const [], chapters: const []);
    final res = await wc.callAsyncJavaScript(
      functionBody: '''
        // Search a SEPARATE epub.js Book that shares the live book's packaging
        // and loader but owns its own spine sections. The old version loaded and
        // unloaded every section of the LIVE book, tearing state out from under
        // the rendition and wedging its shared next/prev/display queue — which
        // froze page turns after a search-jump. Result CFIs are identical because
        // cfiBase is derived from the same packaging. Cached per webview (one
        // book per reader), so re-searches reuse it.
        var sb = window.__absorbSearchBook;
        if (!sb) {
          sb = ePub();
          sb.spine.unpack(book.packaging, book.resolve.bind(book), book.canonical.bind(book));
          window.__absorbSearchBook = sb;
        }
        var out = [];
        var items = (sb.spine && sb.spine.spineItems) ? sb.spine.spineItems : [];
        for (var i = 0; i < items.length; i++) {
          var item = items[i];
          try {
            await item.load(book.load.bind(book));
            var found = (typeof item.search === 'function') ? item.search(query) : item.find(query);
            found = found || [];
            for (var j = 0; j < found.length; j++) {
              // occ = which occurrence of the query this is WITHIN its section
              // (0-based, document order). Used at jump time to re-find the exact
              // same hit in the live rendered DOM.
              out.push({ cfi: found[j].cfi, excerpt: found[j].excerpt || '', href: item.href || '', occ: j });
            }
          } catch (e) {
          } finally {
            try { item.unload(); } catch (e2) {}
          }
        }
        return JSON.stringify(out);
      ''',
      arguments: {'query': q},
    ).timeout(const Duration(seconds: 60), onTimeout: () => null);
    final raw = res?.value;
    if (raw is! String || raw.isEmpty) {
      return _SearchPayload(query: q, results: const [], chapters: const []);
    }
    List<dynamic> list;
    try {
      list = jsonDecode(raw) as List<dynamic>;
    } catch (_) {
      return _SearchPayload(query: q, results: const [], chapters: const []);
    }
    final results = <EpubSearchResult>[];
    final chapters = <String?>[];
    _resultOccByCfi.clear();
    for (final entry in list) {
      final m = entry as Map<String, dynamic>;
      final cfi = m['cfi'] as String? ?? '';
      if (cfi.isEmpty) continue;
      results.add(EpubSearchResult(cfi: cfi, excerpt: (m['excerpt'] as String? ?? '').trim()));
      chapters.add(_chapterForHref(m['href'] as String? ?? ''));
      _resultOccByCfi[cfi] = (m['occ'] as num?)?.toInt() ?? 0;
    }
    return _SearchPayload(query: q, results: results, chapters: chapters);
  }

  void _jumpToSearchResult(EpubSearchResult result) {
    final wc = _epubController?.webViewController;
    final query = _lastSearchedQuery;
    final occ = _resultOccByCfi[result.cfi] ?? 0;
    debugPrint('[Search] jump query="$query" occ=$occ cfi=${result.cfi}');
    if (wc == null || query.isEmpty) {
      _jumpToRawCfi(result.cfi);
      return;
    }
    // The search-result CFI was generated against the section parsed as XML
    // (book.load), but the reader renders the chapter as HTML in an iframe. The
    // two DOM trees differ structurally, so that CFI can resolve to the wrong
    // spot. Navigate to the section with the rough CFI, then re-find the exact
    // hit in the LIVE rendered document and rebuild the CFI there. Uses the
    // section's whole concatenated text (so a match split across formatting
    // spans still resolves) and the occurrence index (so a repeated word lands
    // on the one the user tapped, not the first).
    wc.callAsyncJavaScript(
      functionBody: '''
        var dbg = { matched: false };
        try {
          await rendition.display(cfi);
          var target = null;
          try { target = book.spine.get(cfi); } catch (e) {}
          var si = target ? target.index : -1;
          dbg.si = si;
          var contents = (typeof rendition.getContents === 'function') ? rendition.getContents() : [];
          dbg.nContents = contents.length;
          dbg.secIdx = contents.map(function(x){ return x.sectionIndex; });
          var c = null;
          for (var i = 0; i < contents.length; i++) {
            if (si < 0 || contents[i].sectionIndex === si) { c = contents[i]; break; }
          }
          if (!c) c = contents[0];
          var doc = c && c.document;
          if (doc) {
            var tw = doc.createTreeWalker(doc.body || doc, NodeFilter.SHOW_TEXT, null, false);
            var nodes = [], text = '', node;
            while (node = tw.nextNode()) {
              nodes.push({ node: node, start: text.length, len: node.textContent.length });
              text += node.textContent;
            }
            dbg.textLen = text.length;
            var hay = text.toLowerCase();
            var needle = (query || '').toLowerCase();
            dbg.total = 0;
            { var t = hay.indexOf(needle); while (needle && t !== -1) { dbg.total++; t = hay.indexOf(needle, t + 1); } }
            if (needle && nodes.length) {
              var pos = hay.indexOf(needle);
              for (var n = 0; n < (occ || 0) && pos !== -1; n++) {
                var np = hay.indexOf(needle, pos + 1);
                if (np === -1) break;
                pos = np;
              }
              dbg.pos = pos;
              if (pos !== -1) {
                var locate = function (off) {
                  for (var k = 0; k < nodes.length; k++) {
                    var e = nodes[k];
                    if (off < e.start + e.len) return { node: e.node, offset: off - e.start };
                  }
                  var last = nodes[nodes.length - 1];
                  return { node: last.node, offset: last.len };
                };
                var s = locate(pos), en = locate(pos + needle.length);
                var r = doc.createRange();
                r.setStart(s.node, s.offset);
                r.setEnd(en.node, en.offset);
                var liveCfi = c.cfiFromRange(r);
                if (liveCfi) { dbg.matched = true; dbg.liveCfi = liveCfi; await rendition.display(liveCfi); }
              }
            }
          }
        } catch (e) { dbg.err = String(e); }
        return JSON.stringify(dbg);
      ''',
      arguments: {'cfi': result.cfi, 'query': query, 'occ': occ},
    ).then((res) {
      if (!mounted) return;
      final raw = res?.value;
      debugPrint('[Search] anchor $raw');
      var liveCfi = result.cfi;
      if (raw is String) {
        try {
          final d = jsonDecode(raw) as Map<String, dynamic>;
          if (d['matched'] == true && d['liveCfi'] is String) {
            liveCfi = d['liveCfi'] as String;
          }
        } catch (_) {}
      }
      _highlightSearchHit(liveCfi);
    });
  }

  void _jumpToRawCfi(String cfi) {
    _epubController?.display(cfi: cfi);
    _highlightSearchHit(cfi);
  }

  void _highlightSearchHit(String cfi) {
    // Brief highlight so the user can spot the match on the page. Strong opacity
    // and a vivid amber so it stays visible across light, sepia, and dark themes
    // (the highlight blends with the page, so a faint tint washes out on some).
    _epubController?.addHighlight(
      cfi: cfi,
      color: const Color(0xFFFFC400),
      opacity: 0.9,
    );
    Future.delayed(const Duration(seconds: 4), () {
      if (!mounted) return;
      _epubController?.removeHighlight(cfi: cfi);
    });
  }

  Future<void> _openSearchScreen() async {
    // Fullscreen route — opaque so the WebView is fully covered. Bottom-sheet
    // approach had soft-keyboard taps leaking through to the reader's JS
    // swipe-to-turn handlers underneath.
    final selected = await Navigator.of(context, rootNavigator: true).push<EpubSearchResult>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _EbookSearchScreen(
          initialQuery: _searchQuery,
          initialResults: _searchResults,
          initialChapters: _resultChapters,
          initialLastQuery: _lastSearchedQuery,
          runSearch: (q) async {
            final payload = await _searchBook(q);
            // Persist back on the parent state so reopening the search screen
            // restores the same list.
            if (mounted) {
              setState(() {
                _searchQuery = q;
                _searchResults = payload.results;
                _resultChapters = payload.chapters;
                _lastSearchedQuery = q;
              });
            }
            return payload;
          },
        ),
      ),
    );
    if (selected != null && mounted) {
      _jumpToSearchResult(selected);
    }
  }

  void _showAnnotationsSheet() {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final highlights = _annotations.where((a) => a.type == AnnotationType.highlight).toList();
    final bookmarks = _annotations.where((a) => a.type == AnnotationType.bookmark).toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: cs.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        builder: (ctx, scrollController) => DefaultTabController(
          length: 2,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    Text(AppLocalizations.of(ctx)!.readerAnnotations, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Text(
                      '${_annotations.length}',
                      style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              TabBar(
                tabs: [
                  Tab(text: AppLocalizations.of(ctx)!.readerHighlights(highlights.length)),
                  Tab(text: AppLocalizations.of(ctx)!.readerBookmarks(bookmarks.length)),
                ],
                labelColor: cs.primary,
                unselectedLabelColor: cs.onSurfaceVariant,
                indicatorColor: cs.primary,
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    // Highlights tab
                    highlights.isEmpty
                        ? Center(child: Text(AppLocalizations.of(ctx)!.readerNoHighlights, style: TextStyle(color: cs.onSurfaceVariant)))
                        : ListView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: highlights.length,
                            itemBuilder: (ctx, i) {
                              final h = highlights[i];
                              return Dismissible(
                                key: ValueKey(h.id),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 16),
                                  color: cs.error,
                                  child: Icon(Icons.delete_rounded, color: cs.onError),
                                ),
                                onDismissed: (_) => _removeHighlight(h),
                                child: ListTile(
                                  leading: Container(
                                    width: 4,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Color(int.parse('FF${h.color!.hex.substring(1)}', radix: 16)),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  title: Text(
                                    h.selectedText ?? '',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: tt.bodyMedium,
                                  ),
                                  subtitle: h.note != null && h.note!.isNotEmpty
                                      ? Text(h.note!, maxLines: 1, overflow: TextOverflow.ellipsis,
                                          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant))
                                      : null,
                                  trailing: IconButton(
                                    icon: const Icon(Icons.ios_share_rounded, size: 18),
                                    tooltip: AppLocalizations.of(ctx)!.quoteShareTitle,
                                    color: cs.onSurfaceVariant,
                                    onPressed: () {
                                      Navigator.pop(ctx);
                                      _shareHighlight(h);
                                    },
                                  ),
                                  dense: true,
                                  onTap: () {
                                    Navigator.pop(ctx);
                                    _epubController?.display(cfi: pointCfi(h.cfi));
                                  },
                                  onLongPress: () => _addNoteToAnnotation(h),
                                ),
                              );
                            },
                          ),

                    // Bookmarks tab
                    bookmarks.isEmpty
                        ? Center(child: Text(AppLocalizations.of(ctx)!.readerNoBookmarks, style: TextStyle(color: cs.onSurfaceVariant)))
                        : ListView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: bookmarks.length,
                            itemBuilder: (ctx, i) {
                              final bm = bookmarks[i];
                              final date = '${bm.createdAt.month}/${bm.createdAt.day}/${bm.createdAt.year}';
                              return Dismissible(
                                key: ValueKey(bm.id),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 16),
                                  color: cs.error,
                                  child: Icon(Icons.delete_rounded, color: cs.onError),
                                ),
                                onDismissed: (_) async {
                                  await _annotationService.delete(
                                    itemId: widget.itemId,
                                    annotationId: bm.id,
                                  );
                                  _annotations.removeWhere((a) => a.id == bm.id);
                                  _updateBookmarkState();
                                  if (mounted) setState(() {});
                                },
                                child: ListTile(
                                  leading: Icon(Icons.bookmark_rounded, color: cs.primary),
                                  title: Text(
                                    bm.note ?? AppLocalizations.of(ctx)!.readerBookmarkDefault,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: tt.bodyMedium,
                                  ),
                                  subtitle: Text(date, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                                  dense: true,
                                  onTap: () {
                                    Navigator.pop(ctx);
                                    _epubController?.display(cfi: pointCfi(bm.cfi));
                                  },
                                  onLongPress: () => _addNoteToAnnotation(bm),
                                ),
                              );
                            },
                          ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Wraps a body in a Scaffold.
  Widget _wrap(Widget body, Color bg, {PreferredSizeWidget? appBar}) {
    // Don't resize for the keyboard — epub.js reflows when the WebView
    // resizes, which would shift the visible page when the search keyboard
    // pops up. The bottom sheet positions itself above the keyboard via
    // MediaQuery.viewInsets, so it stays visible regardless.
    return Scaffold(
      backgroundColor: bg,
      appBar: appBar,
      body: body,
      resizeToAvoidBottomInset: false,
    );
  }

  // The viewer's safe-area padding, frozen at the smallest value seen for the
  // current window size. Swiping to recents un-hides the system bars, which
  // grows MediaQuery padding for a moment - a live SafeArea would shrink the
  // WebView and epub.js would visibly rescale the page mid-gesture. Once
  // immersive mode settles, the only real padding left is the camera cutout,
  // which only changes when the window size does (rotation, split-screen), so
  // padding growth at a constant size is transient chrome and is ignored.
  EdgeInsets? _viewerPadding;
  Size? _viewerPaddingSize;

  /// Padded with the frozen safe-area padding above so the page never slides
  /// under the camera cutout but also never resizes when the system bars flash
  /// back in. Side margins are applied here (horizontal padding shrinks the
  /// WebView so epub.js paginates into the narrower box) - epub.js's column
  /// layout ignores horizontal body padding, so CSS only handles the vertical
  /// margins.
  Widget _buildViewerArea(Widget viewer) {
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final prev = _viewerPadding;
    if (prev == null || _viewerPaddingSize != size) {
      _viewerPadding = pad;
      _viewerPaddingSize = size;
    } else {
      _viewerPadding = EdgeInsets.only(
        left: min(prev.left, pad.left),
        top: min(prev.top, pad.top),
        right: min(prev.right, pad.right),
        bottom: min(prev.bottom, pad.bottom),
      );
    }
    return Padding(
      padding: _viewerPadding!,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: _marginH.toDouble()),
        child: LayoutBuilder(
          builder: (ctx, cons) => Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: (e) {
              _ptrDownX = e.localPosition.dx;
              _ptrDownY = e.localPosition.dy;
            },
            onPointerUp: (e) {
              final w = cons.maxWidth;
              final dx = _ptrDownX != null ? (e.localPosition.dx - _ptrDownX!).abs() : 0.0;
              final dy = _ptrDownY != null ? (e.localPosition.dy - _ptrDownY!).abs() : 0.0;
              _ptrDownX = null;
              _ptrDownY = null;
              if (dx > 16 || dy > 16 || w <= 0) return;
              _readerTapAt(e.localPosition.dx / w, 'flutterPtr');
            },
            child: SizedBox.expand(child: viewer),
          ),
        ),
      ),
    );
  }

  void _handleClose() {
    Navigator.pop(context);
  }

  String _speedLabel(double s) {
    var t = s.toStringAsFixed(2);
    if (t.contains('.')) t = t.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
    return '${t}x';
  }

  /// Playback controls for immersion reading (listen while you read). Drives the
  /// shared player; only shown while a book is loaded.
  Widget _buildMediaBar(Color fg, Color accent) {
    final player = AudioPlayerService();
    return ListenableBuilder(
      listenable: player,
      builder: (context, _) {
        // This book is the live session?
        final isActive = player.hasBook && player.currentItemId == widget.itemId;
        // Show whenever this book has audio, or it's already the active session.
        if (!isActive && !_hasAudio) return const SizedBox.shrink();
        final fwdIcon = _forwardSkip == 5
            ? Icons.forward_5_rounded
            : _forwardSkip == 10 ? Icons.forward_10_rounded : Icons.forward_30_rounded;
        final backIcon = _backSkip == 5
            ? Icons.replay_5_rounded
            : _backSkip == 10 ? Icons.replay_10_rounded : Icons.replay_30_rounded;
        final dim = fg.withValues(alpha: 0.3);
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              SizedBox(
                width: 64,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(0, 36),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () => showModalBottomSheet(
                      context: context,
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      builder: (_) => CardSpeedSheet(
                        player: player, accent: accent, itemId: widget.itemId),
                    ),
                    child: Text(_speedLabel(player.speed),
                        style: TextStyle(color: fg, fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Skips only act on the live session.
                    IconButton(
                      icon: Icon(backIcon, color: isActive ? fg : dim),
                      iconSize: 30,
                      onPressed: isActive ? () => player.skipBackward(_backSkip) : null,
                    ),
                    IconButton(
                      icon: Icon(
                        (isActive && player.isPlaying)
                            ? Icons.pause_circle_filled_rounded
                            : Icons.play_circle_filled_rounded,
                        color: accent,
                      ),
                      iconSize: 48,
                      // Active: toggle. Otherwise start this book's audiobook.
                      onPressed: _startingAudio
                          ? null
                          : (isActive
                                ? () => player.togglePlayPause(fromUi: true)
                                : _startThisBook),
                    ),
                    IconButton(
                      icon: Icon(fwdIcon, color: isActive ? fg : dim),
                      iconSize: 30,
                      onPressed: isActive ? () => player.skipForward(_forwardSkip) : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 64), // balance the speed button
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final palette = _resolvePalette(context);
    final bg = palette.bgColor;
    final fg = palette.fgColor;
    final fgDim = fg.withValues(alpha: 0.6);
    final accent = cs.primary;

    // Hold the heavy WebView until the open animation finishes — mounting it
    // mid-transition (e.g. for an already-cached book) stutters the slide-in.
    if (_loading || !_entered) {
      return _wrap(
        const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        bg,
        appBar: AppBar(
          title: Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis),
          backgroundColor: Colors.transparent,
        ),
      );
    }

    if (_error != null || _cachedFile == null) {
      return _wrap(
        Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(_error ?? 'Unknown error', textAlign: TextAlign.center,
                style: TextStyle(color: cs.onSurfaceVariant)),
          ),
        ),
        bg,
        appBar: AppBar(title: Text(widget.title)),
      );
    }

    // EpubViewer + overlays, each wrapped in a SafeArea for camera cutouts.
    final viewerBody = Stack(
      children: [
          // Epub viewer with safe area padding for camera cutouts
          _buildViewerArea(EpubViewer(
              key: ValueKey(_viewerKey),
              epubSource: EpubSource.fromFile(_cachedFile!),
              epubController: _epubController!,
              initialCfi: _initialCfi,
              displaySettings: EpubDisplaySettings(
                flow: EpubFlow.paginated,
                spread: _spread,
                // Swipe-to-turn via epub.js's snap manager is janky inside the
                // WebView and never fires on iOS, so it's off. Page turns come
                // from edge taps; horizontal drags are swallowed below.
                snap: false,
                useSnapAnimationAndroid: false,
                // Font size at load time, not applied after: a post-load
                // setFontSize reflows the text after initialCfi has displayed,
                // which would drift the resume position.
                fontSize: _fontSize,
                theme: _buildTheme(palette),
              ),
              onChaptersLoaded: (chapters) {
                debugPrint('[EbookReader] onChaptersLoaded item=${widget.itemId} count=${chapters.length}');
                if (mounted) setState(() => _chapters = _flattenChapters(chapters));
              },
              // Fires once the plugin finishes generating its location index;
              // value.progress is only meaningful (and stable) after this.
              onLocationLoaded: () {
                debugPrint('[EbookReader] onLocationLoaded item=${widget.itemId}');
                if (mounted) setState(() => _locationsReady = true);
              },
              suppressNativeContextMenu: true,
              onSelection: _onSelection,
              onDeselection: () {
                if (mounted) setState(() => _clearSelection());
              },
              onAnnotationClicked: (cfi, rect) {
                final match = _annotations.where(
                  (a) => a.type == AnnotationType.highlight && a.cfi == cfi,
                ).firstOrNull;
                if (match != null) _addNoteToAnnotation(match);
              },
              onEpubLoaded: () {
                // Re-display once to rescue an occasionally-blank first paint.
                // Guarded so it runs at most once per mount: onEpubLoaded fires
                // on every epub.js "displayed" event, so an unguarded re-display
                // would re-trigger itself forever (freezing taps and snapping
                // back to the start). Position-safe: font size and theme are
                // already in displaySettings, so nothing reflows after this.
                if (!_didLoadRescue) {
                  _didLoadRescue = true;
                  final once = _initialCfi;
                  if (once != null && once.isNotEmpty) {
                    _initialCfi = null;
                    _epubController?.display(cfi: once);
                    // Safe to re-display: _didLoadRescue is already set, so the
                    // "displayed" event this fires can't loop back in here.
                    final settle = _settleJumpCfi;
                    if (settle != null) {
                      _settleJumpCfi = null;
                      Future.delayed(const Duration(milliseconds: 700), () {
                        if (mounted) _epubController?.display(cfi: settle);
                      });
                    }
                  } else {
                    // First open (no saved position) - the same blank-first-paint
                    // can happen here, but display(cfi:) needs a target, so force
                    // epub.js to re-display the start directly.
                    _epubController?.webViewController?.evaluateJavascript(
                        source: 'try{rendition.display();}catch(e){}');
                  }
                  debugPrint('[EbookReader] onEpubLoaded item=${widget.itemId} '
                      'rescue=${once != null && once.isNotEmpty ? "cfi" : "start"}');
                }
                if (!_didInitViewer) {
                  _didInitViewer = true;
                  _loadAnnotations().then((_) => _restoreHighlights());
                  _setupPageInfoHandler();
                  _setupTapHandler();
                  _setupFontInjector();
                  _applyFontFace();
                }
              },
              onRelocated: (value) {
                if (!mounted) return;
                // Ignore relocations while backgrounded: the recents/resize
                // re-paginate fires a stray one that would save the wrong page.
                // Note it so the resume path knows the page needs restoring.
                if (!_readerActive) {
                  _bgDrifted = true;
                  return;
                }
                _currentCfi = value.startCfi;
                _updateBookmarkState();
                if (_locationsReady) {
                  // Trust the percentage only once epub.js has built its
                  // location index. Before that it reports a bogus spine
                  // estimate that jumps around (e.g. 75% then 25%) — pushing
                  // it would corrupt the server's percent and could even mark
                  // the book finished (isFinished = progress >= 1.0).
                  setState(() => _progress = value.progress);
                  _syncProgress(value.startCfi, value.progress);
                } else {
                  // Still save the fresh position, but keep the last-known-good
                  // percentage so the stored progress never regresses.
                  _syncProgress(value.startCfi, _progress);
                }
              },
              onTouchDown: (x, y) {
                _touchDownX = x;
                _touchDownY = y;
              },
              onTouchUp: (x, y) {
                // onTouchDown doesn't fire reliably on iOS; if we never got a
                // down point, treat this as a tap (0 movement) instead of
                // rejecting it, otherwise no taps register at all.
                final dx = _touchDownX != null ? (x - _touchDownX!).abs() : 0.0;
                final dy = _touchDownY != null ? (y - _touchDownY!).abs() : 0.0;
                _touchDownX = null;
                _touchDownY = null;
                if (dx > 0.05 || dy > 0.05) return;
                _readerTapAt(x, 'touch');
              },
          )),

          // Top bar overlay
          AnimatedOpacity(
            opacity: _showControls ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: IgnorePointer(
              ignoring: !_showControls,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [bg.withValues(alpha: 1.0), bg.withValues(alpha: 0.6)],
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.arrow_back_rounded,
                            color: fg,
                          ),
                          onPressed: _handleClose,
                        ),
                        Expanded(
                          child: Text(
                            widget.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: fg,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            _hasBookmarkAtCurrent
                                ? Icons.bookmark_rounded
                                : Icons.bookmark_border_rounded,
                            color: _hasBookmarkAtCurrent ? accent : fg,
                          ),
                          onPressed: _toggleBookmark,
                        ),
                        IconButton(
                          icon: Icon(Icons.search_rounded, color: fg),
                          tooltip: AppLocalizations.of(context)!.readerTooltipSearch,
                          onPressed: _openSearchScreen,
                        ),
                        IconButton(
                          icon: Icon(Icons.sticky_note_2_outlined, color: fg),
                          onPressed: _showAnnotationsSheet,
                        ),
                        IconButton(
                          icon: Icon(Icons.text_fields_rounded, color: fg),
                          onPressed: _showSettingsSheet,
                        ),
                        if (_chapters.isNotEmpty)
                          IconButton(
                            icon: Icon(Icons.list_rounded, color: fg),
                            onPressed: _showChapterList,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Bottom progress bar overlay
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: AnimatedOpacity(
              opacity: _showControls ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: IgnorePointer(
                ignoring: !_showControls,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [bg.withValues(alpha: 1.0), bg.withValues(alpha: 0.6)],
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildMediaBar(fg, accent),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: _progress.clamp(0.0, 1.0),
                              minHeight: 3,
                              backgroundColor: fg.withValues(alpha: 0.1),
                              valueColor: AlwaysStoppedAnimation(accent),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              if (_chapterPageTotal > 0)
                                Text(
                                  '$_chapterPage / $_chapterPageTotal',
                                  style: TextStyle(color: fgDim, fontSize: 11),
                                ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  child: Text(
                                    _currentChapterTitle ?? '',
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: fgDim, fontSize: 11),
                                  ),
                                ),
                              ),
                              Text(
                                '${(_progress * 100).toStringAsFixed(1)}%',
                                style: TextStyle(color: fgDim, fontSize: 11),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Selection toolbar - appears when text is selected
          if (_selectionRect != null && _selectionCfi != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: MediaQuery.of(context).padding.bottom + 16,
              child: Center(
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(28),
                  color: cs.surfaceContainer,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final color in HighlightColor.values)
                          _HighlightColorButton(
                            color: Color(int.parse('FF${color.hex.substring(1)}', radix: 16)),
                            onTap: () => _addHighlight(color),
                          ),
                        _divider(cs),
                        IconButton(
                          icon: Icon(Icons.copy_rounded, size: 20, color: cs.onSurfaceVariant),
                          onPressed: _copySelection,
                          tooltip: AppLocalizations.of(context)!.readerTooltipCopy,
                          visualDensity: VisualDensity.compact,
                        ),
                        IconButton(
                          icon: Icon(Icons.search_rounded, size: 20, color: cs.onSurfaceVariant),
                          onPressed: _searchSelection,
                          tooltip: AppLocalizations.of(context)!.readerTooltipSearch,
                          visualDensity: VisualDensity.compact,
                        ),
                        IconButton(
                          icon: Icon(Icons.menu_book_rounded, size: 20, color: cs.onSurfaceVariant),
                          onPressed: _defineSelection,
                          tooltip: AppLocalizations.of(context)!.readerTooltipDefine,
                          visualDensity: VisualDensity.compact,
                        ),
                        _divider(cs),
                        IconButton(
                          icon: Icon(Icons.close_rounded, size: 20, color: cs.onSurfaceVariant),
                          onPressed: _dismissSelection,
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

        ],
      );
    return _wrap(viewerBody, bg);
  }
}

/// Payload returned from [_EbookSearchScreen]'s runSearch callback.
class _SearchPayload {
  final String query;
  final List<EpubSearchResult> results;
  final List<String?> chapters;
  const _SearchPayload({required this.query, required this.results, required this.chapters});
}

/// Fullscreen search screen. Opaque route — covers the reader entirely so
/// soft-keyboard taps can't reach the underlying WebView's JS swipe/tap
/// handlers. Pop with a result to ask the reader to jump there.
class _EbookSearchScreen extends StatefulWidget {
  final String initialQuery;
  final List<EpubSearchResult> initialResults;
  final List<String?> initialChapters;
  final String initialLastQuery;
  final Future<_SearchPayload> Function(String) runSearch;

  const _EbookSearchScreen({
    required this.initialQuery,
    required this.initialResults,
    required this.initialChapters,
    required this.initialLastQuery,
    required this.runSearch,
  });

  @override
  State<_EbookSearchScreen> createState() => _EbookSearchScreenState();
}

class _EbookSearchScreenState extends State<_EbookSearchScreen> {
  late final TextEditingController _controller;
  late String _lastQuery;
  late List<EpubSearchResult> _results;
  late List<String?> _chapters;
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
    _lastQuery = widget.initialLastQuery;
    _results = widget.initialResults;
    _chapters = widget.initialChapters;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    final q = _controller.text.trim();
    if (q.isEmpty) return;
    setState(() => _searching = true);
    try {
      final payload = await widget.runSearch(q);
      if (!mounted) return;
      setState(() {
        _results = payload.results;
        _chapters = payload.chapters;
        _lastQuery = payload.query;
        _searching = false;
      });
    } catch (e) {
      debugPrint('[Search] runSearch error: $e');
      if (!mounted) return;
      setState(() {
        _results = [];
        _chapters = [];
        _searching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        title: TextField(
          controller: _controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.readerSearchHint,
            border: InputBorder.none,
          ),
          onSubmitted: (_) => _run(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: _searching ? null : _run,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_searching)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else if (_results.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Row(
                children: [
                  Text(
                    AppLocalizations.of(context)!.readerSearchMatches(_results.length, _lastQuery),
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _searching
                ? const SizedBox.shrink()
                : _results.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            _lastQuery.isEmpty
                                ? AppLocalizations.of(context)!.readerSearchEmpty
                                : AppLocalizations.of(context)!.readerSearchNoResults(_lastQuery),
                            textAlign: TextAlign.center,
                            style: TextStyle(color: cs.onSurfaceVariant),
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        itemCount: _results.length,
                        separatorBuilder: (_, __) => Divider(
                          height: 1,
                          color: cs.onSurface.withValues(alpha: 0.06),
                        ),
                        itemBuilder: (ctx, i) {
                          final r = _results[i];
                          final chapter = i < _chapters.length ? _chapters[i] : null;
                          return ListTile(
                            title: _SearchExcerpt(excerpt: r.excerpt, query: _lastQuery),
                            subtitle: chapter == null
                                ? null
                                : Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      chapter,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: tt.bodySmall?.copyWith(
                                        color: cs.onSurfaceVariant,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                            dense: true,
                            onTap: () => Navigator.of(context).pop(r),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

/// Renders a search excerpt with the matched query bold + tinted so the user
/// can spot which word the hit was on.
class _SearchExcerpt extends StatelessWidget {
  final String excerpt;
  final String query;

  const _SearchExcerpt({required this.excerpt, required this.query});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final base = tt.bodyMedium ?? const TextStyle();
    if (query.isEmpty) {
      return Text(excerpt, maxLines: 3, overflow: TextOverflow.ellipsis, style: base);
    }
    final lower = excerpt.toLowerCase();
    final q = query.toLowerCase();
    final spans = <TextSpan>[];
    var i = 0;
    while (i < excerpt.length) {
      final hit = lower.indexOf(q, i);
      if (hit == -1) {
        spans.add(TextSpan(text: excerpt.substring(i)));
        break;
      }
      if (hit > i) spans.add(TextSpan(text: excerpt.substring(i, hit)));
      spans.add(TextSpan(
        text: excerpt.substring(hit, hit + q.length),
        style: TextStyle(fontWeight: FontWeight.w700, color: cs.primary),
      ));
      i = hit + q.length;
    }
    return Text.rich(
      TextSpan(style: base, children: spans),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _HighlightColorButton extends StatelessWidget {
  final Color color;
  final VoidCallback onTap;

  const _HighlightColorButton({required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.black.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
        ),
      ),
    );
  }
}
