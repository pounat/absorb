import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_carplay/flutter_carplay.dart';
import 'android_auto_service.dart';
import 'api_service.dart';
import 'audio_player_service.dart';

/// Manages Apple CarPlay browse tree and playback integration.
/// Mirrors the Android Auto layout: 3 tabs (Continue, Library, Downloads)
/// with hierarchical drilling into books/series/authors and podcasts.
class CarPlayService {
  static final CarPlayService _instance = CarPlayService._();
  factory CarPlayService() => _instance;
  CarPlayService._();

  final _autoService = AndroidAutoService();
  final _flutterCarplay = FlutterCarplay();
  bool _initialized = false;
  bool _buildingRoot = false;
  DateTime? _lastRootBuilt;
  CPTabBarTemplate? _rootTemplate;
  Future<void>? _inFlightBuild;

  void init() {
    if (!Platform.isIOS || _initialized) return;
    _initialized = true;
    _flutterCarplay.addListenerOnConnectionChange(_onConnectionChange);
    debugPrint('[CarPlay] Initialized');
    // Re-render the root template when the background server refresh
    // completes. AutoBrowse.refresh() returns immediately after downloads
    // are populated and continues the server fetch in the background;
    // this hook is how we know to swap the downloads-only tree for the
    // full one (or the other way for offline → online recovery).
    AndroidAutoService.onServerDataChanged = () {
      if (!_initialized || _rootTemplate == null) return;
      // _connectAndRender awaits its own refresh() which fires this callback
      // mid-flight; without this guard both paths call setRootTemplate within
      // ~0ms and CarPlay renders the tabs blank until the user backgrounds
      // and reopens the app.
      if (_inFlightBuild != null) {
        debugPrint('[CarPlay] onServerDataChanged - skipped (build in flight)');
        return;
      }
      if (_lastRootBuilt != null &&
          DateTime.now().difference(_lastRootBuilt!) < const Duration(milliseconds: 500)) {
        debugPrint('[CarPlay] onServerDataChanged - skipped (built ${DateTime.now().difference(_lastRootBuilt!).inMilliseconds}ms ago)');
        return;
      }
      debugPrint('[CarPlay] onServerDataChanged - rebuilding root template');
      refreshTemplates();
    };
    // Eagerly load auto browse data so the first CarPlay connect lands with
    // full content already cached. Without this, the user's first open would
    // either show empty Continue Listening / Library tabs or wait the full
    // server-fetch time before anything appeared.
    _autoService.refresh().then((_) {
      debugPrint('[CarPlay] Init refresh done'
          ' continue=${_autoService.continueListening.length}'
          ' downloads=${_autoService.downloaded.length}'
          ' libraries=${_autoService.libraries.length}');
    }).catchError((e) {
      debugPrint('[CarPlay] Init refresh failed: $e');
    });
  }

  void dispose() {
    _flutterCarplay.removeListenerOnConnectionChange();
  }

  void _onConnectionChange(ConnectionStatusTypes status) {
    debugPrint('[CarPlay] Connection status: $status');
    if (status == ConnectionStatusTypes.disconnected) {
      _rootTemplate = null;
      _lastRootBuilt = null;
      return;
    }
    if (status != ConnectionStatusTypes.connected) return;

    // Guard duplicate `connected` events that iOS fires in quick succession.
    final now = DateTime.now();
    if (_buildingRoot) return;
    if (_lastRootBuilt != null &&
        now.difference(_lastRootBuilt!) < const Duration(seconds: 1)) {
      return;
    }

    _connectAndRender();
  }

  Future<void> _connectAndRender() async {
    // Make sure data is loaded before rendering. Init kicked off a refresh at
    // app start, so this usually returns instantly. On a cold connect right
    // after app launch we wait the full ~1s so the very first template the
    // user sees has real content.
    //
    // We avoid calling setRootTemplate twice (once empty, once full) because
    // the flutter_carplay native side appears to leave the first template
    // visible and the second call doesn't re-render. Same for
    // updateTabBarTemplates - it updates the cached template but doesn't
    // refresh the displayed UI and (worse) breaks tap routing on the new
    // items. So we wait, then setRootTemplate once with full data.
    try {
      await _autoService.refresh();
    } catch (e) {
      debugPrint('[CarPlay] Pre-render refresh failed: $e');
    }
    await _setRootTemplate(label: 'on-connect');
  }

  /// Clear cache and rebuild templates (e.g. on account switch).
  Future<void> clearAndRefresh() async {
    if (!_initialized) return;
    await _autoService.refresh(force: true);
    await _setRootTemplate(label: 'clear-and-refresh');
  }

  /// Refresh CarPlay templates (e.g. after download completes).
  Future<void> refreshTemplates() async {
    if (!_initialized) return;
    await _setRootTemplate(label: 'refresh-templates');
  }

  // ─── Root template ──────────────────────────────────────────────────

  Future<List<CPListTemplate>> _buildTabs() async {
    final downloadsTab = await _buildDownloadsTab();
    // When the server is unreachable, Continue / New / Library are empty
    // anyway (we skip the server fetch). Drop them so CarPlay opens
    // straight into the user's downloads instead of showing three empty
    // tabs they have to swipe past.
    if (AudioPlayerService().knownOffline) {
      return [downloadsTab];
    }
    // Cold start race: knownOffline defaults to false and only flips after
    // the auth ping fails (~15s). If CarPlay connects before then with no
    // server data loaded yet, Continue/New/Library would render as empty
    // tabs and the user lands on a blank Continue tab. Skip any tab that
    // has nothing to show; onServerDataChanged will rebuild once data
    // arrives.
    final tabs = <CPListTemplate>[];
    if (_autoService.continueListening.isNotEmpty) {
      tabs.add(await _buildContinueTab());
    }
    if (_autoService.recentlyAdded.isNotEmpty) {
      tabs.add(await _buildRecentlyAddedTab());
    }
    if (_autoService.libraries.isNotEmpty) {
      tabs.add(await _buildLibraryTab());
    }
    tabs.add(downloadsTab);
    return tabs;
  }

  Future<void> _setRootTemplate({String label = ''}) async {
    // Coalesce concurrent calls. If a build is already in flight, await it
    // instead of starting a second one - two setRootTemplate invocations
    // racing within the same microtask leave CarPlay rendering blank tabs.
    if (_inFlightBuild != null) {
      debugPrint('[CarPlay] _setRootTemplate ($label) - awaiting in-flight build');
      return _inFlightBuild;
    }
    final fut = _doSetRootTemplate(label: label);
    _inFlightBuild = fut;
    try {
      await fut;
    } finally {
      _inFlightBuild = null;
    }
  }

  Future<void> _doSetRootTemplate({required String label}) async {
    _buildingRoot = true;
    try {
      final tabs = await _buildTabs();
      final root = CPTabBarTemplate(templates: tabs);
      _rootTemplate = root;
      await FlutterCarplay.setRootTemplate(rootTemplate: root, animated: false);
      // Without this the native side may not register onPress callbacks on
      // the new list items, leaving taps stuck on an infinite spinner.
      await _flutterCarplay.forceUpdateRootTemplate();
      _lastRootBuilt = DateTime.now();
      debugPrint('[CarPlay] Root template set ($label)'
          ' continue=${_autoService.continueListening.length}'
          ' downloads=${_autoService.downloaded.length}'
          ' libraries=${_autoService.libraries.length}');
    } finally {
      _buildingRoot = false;
    }
  }

  // ─── Continue Listening tab ─────────────────────────────────────────

  Future<CPListTemplate> _buildContinueTab() async {
    final api = await _autoService.getApi();
    final entries = _autoService.continueListening;
    final items = entries.map((e) => _playableListItem(e, api)).toList();
    return CPListTemplate(
      sections: [CPListSection(items: items)],
      title: 'Continue',
      systemIcon: 'play.circle.fill',
    );
  }

  // ─── Recently Added tab ────────────────────────────────────────────

  Future<CPListTemplate> _buildRecentlyAddedTab() async {
    final api = await _autoService.getApi();
    final entries = _autoService.recentlyAdded;
    final items = entries.map((e) => _playableListItem(e, api)).toList();
    return CPListTemplate(
      sections: [CPListSection(items: items)],
      title: 'New',
      systemIcon: 'sparkles',
    );
  }

  // ─── Library tab ────────────────────────────────────────────────────

  Future<CPListTemplate> _buildLibraryTab() async {
    final libs = _autoService.libraries;

    // Single library: skip picker, show sub-categories or shows directly
    if (libs.length == 1) {
      final lib = libs.first;
      if (lib.isPodcast) {
        return _buildPodcastShowsList(lib.id, lib.name);
      }
      return _buildBookSubCategories(lib.id, 'Library');
    }

    // Multiple libraries: show library picker
    final items = libs.map((lib) {
      return CPListItem(
        text: lib.name,
        accessoryType: CPListItemAccessoryTypes.disclosureIndicator,
        onPress: (complete, self) async {
          if (lib.isPodcast) {
            final template = await _buildPodcastShowsList(lib.id, lib.name);
            FlutterCarplay.push(template: template);
          } else {
            final template = await _buildBookSubCategories(lib.id, lib.name);
            FlutterCarplay.push(template: template);
          }
          complete();
        },
      );
    }).toList();

    return CPListTemplate(
      sections: [CPListSection(items: items)],
      title: 'Library',
      systemIcon: 'books.vertical.fill',
    );
  }

  // ─── Downloads tab ──────────────────────────────────────────────────

  Future<CPListTemplate> _buildDownloadsTab() async {
    final api = await _autoService.getApi();
    final entries = _autoService.downloaded;
    final items = entries.map((e) => _playableListItem(e, api)).toList();
    return CPListTemplate(
      sections: [CPListSection(items: items)],
      title: 'Downloads',
      systemIcon: 'arrow.down.circle.fill',
    );
  }

  // ─── Book library sub-categories ───────────────────────────────────

  Future<CPListTemplate> _buildBookSubCategories(String libraryId, String title) async {
    final items = [
      CPListItem(
        text: 'Books',
        accessoryType: CPListItemAccessoryTypes.disclosureIndicator,
        onPress: (complete, self) async {
          final template = await _buildBooksList(libraryId);
          FlutterCarplay.push(template: template);
          complete();
        },
      ),
      CPListItem(
        text: 'Series',
        accessoryType: CPListItemAccessoryTypes.disclosureIndicator,
        onPress: (complete, self) async {
          final template = await _buildSeriesList(libraryId);
          FlutterCarplay.push(template: template);
          complete();
        },
      ),
      CPListItem(
        text: 'Authors',
        accessoryType: CPListItemAccessoryTypes.disclosureIndicator,
        onPress: (complete, self) async {
          final template = await _buildAuthorsList(libraryId);
          FlutterCarplay.push(template: template);
          complete();
        },
      ),
    ];

    return CPListTemplate(
      sections: [CPListSection(items: items)],
      title: title,
      systemIcon: 'books.vertical',
    );
  }

  // ─── Books list ────────────────────────────────────────────────────

  Future<CPListTemplate> _buildBooksList(String libraryId) async {
    final api = await _autoService.getApi();
    final entries = await _autoService.fetchLibraryBooksData(libraryId);
    final items = entries.map((e) => _playableListItem(e, api)).toList();
    return CPListTemplate(
      sections: [CPListSection(items: items)],
      title: 'Books',
      systemIcon: 'book.fill',
    );
  }

  // ─── Series list ───────────────────────────────────────────────────

  Future<CPListTemplate> _buildSeriesList(String libraryId) async {
    final seriesData = await _autoService.fetchLibrarySeriesData(libraryId);
    final items = seriesData.map((s) {
      return CPListItem(
        text: s.name,
        accessoryType: CPListItemAccessoryTypes.disclosureIndicator,
        onPress: (complete, self) async {
          final template = await _buildSeriesBooks(s.id, libraryId, s.name);
          FlutterCarplay.push(template: template);
          complete();
        },
      );
    }).toList();

    return CPListTemplate(
      sections: [CPListSection(items: items)],
      title: 'Series',
      systemIcon: 'rectangle.stack.fill',
    );
  }

  Future<CPListTemplate> _buildSeriesBooks(String seriesId, String libraryId, String title) async {
    final api = await _autoService.getApi();
    final entries = await _autoService.fetchSeriesBooksData(seriesId, libraryId);
    final items = entries.map((e) => _playableListItem(e, api)).toList();
    return CPListTemplate(
      sections: [CPListSection(items: items)],
      title: title,
      systemIcon: 'rectangle.stack.fill',
    );
  }

  // ─── Authors list ──────────────────────────────────────────────────

  Future<CPListTemplate> _buildAuthorsList(String libraryId) async {
    final authorsData = await _autoService.fetchLibraryAuthorsData(libraryId);
    final items = authorsData.map((a) {
      return CPListItem(
        text: a.name,
        accessoryType: CPListItemAccessoryTypes.disclosureIndicator,
        onPress: (complete, self) async {
          final template = await _buildAuthorBooks(a.id, libraryId, a.name);
          FlutterCarplay.push(template: template);
          complete();
        },
      );
    }).toList();

    return CPListTemplate(
      sections: [CPListSection(items: items)],
      title: 'Authors',
      systemIcon: 'person.2.fill',
    );
  }

  Future<CPListTemplate> _buildAuthorBooks(String authorId, String libraryId, String title) async {
    final api = await _autoService.getApi();
    final entries = await _autoService.fetchAuthorBooksData(authorId, libraryId);
    final items = entries.map((e) => _playableListItem(e, api)).toList();
    return CPListTemplate(
      sections: [CPListSection(items: items)],
      title: title,
      systemIcon: 'person.fill',
    );
  }

  // ─── Podcast shows ─────────────────────────────────────────────────

  Future<CPListTemplate> _buildPodcastShowsList(String libraryId, String title) async {
    final showsData = await _autoService.fetchPodcastShowsData(libraryId);
    final items = showsData.map((s) {
      return CPListItem(
        text: s.title,
        image: s.coverUrl,
        accessoryType: CPListItemAccessoryTypes.disclosureIndicator,
        onPress: (complete, self) async {
          final template = await _buildShowEpisodes(s.id, libraryId, s.title);
          FlutterCarplay.push(template: template);
          complete();
        },
      );
    }).toList();

    return CPListTemplate(
      sections: [CPListSection(items: items)],
      title: title,
      systemIcon: 'mic.fill',
    );
  }

  Future<CPListTemplate> _buildShowEpisodes(String showId, String libraryId, String title) async {
    final api = await _autoService.getApi();
    final entries = await _autoService.fetchShowEpisodesData(showId, libraryId);
    final items = entries.map((e) => _playableListItem(e, api)).toList();
    return CPListTemplate(
      sections: [CPListSection(items: items)],
      title: title,
      systemIcon: 'mic.fill',
    );
  }

  // ─── Helpers ───────────────────────────────────────────────────────

  /// Build a playable CPListItem from an AutoBookEntry. Recently-added
  /// podcast shows aren't directly playable, so build a browseable item that
  /// drills into the show's episodes.
  CPListItem _playableListItem(AutoBookEntry entry, ApiService? api) {
    final coverItemId = entry.showId ?? entry.id;
    // Prefer the entry's own coverUrl when it's a local file:// path so
    // downloaded books still show artwork in the CarPlay browse list when
    // the server is unreachable. AndroidAutoService.refresh() populates
    // file:// for downloads on iOS; the server URL from api.getCoverUrl is
    // only useful when we can actually reach the server.
    final entryUrl = entry.coverUrl;
    final coverUrl = (entryUrl != null && entryUrl.startsWith('file://'))
        ? entryUrl
        : api?.getCoverUrl(coverItemId);

    final isPodcastShow = entry.mediaType == 'podcast' &&
        entry.episodeId == null &&
        entry.libraryId != null &&
        entry.libraryId!.isNotEmpty;

    if (isPodcastShow) {
      return CPListItem(
        text: entry.title,
        detailText: entry.author.isNotEmpty ? entry.author : null,
        image: coverUrl,
        accessoryType: CPListItemAccessoryTypes.disclosureIndicator,
        onPress: (complete, self) async {
          final template = await _buildShowEpisodes(
              entry.id, entry.libraryId!, entry.title);
          FlutterCarplay.push(template: template);
          complete();
        },
      );
    }

    final mediaId = (entry.episodeId != null && entry.showId != null)
        ? AutoMediaIds.itemId('${entry.showId}-${entry.episodeId}')
        : AutoMediaIds.itemId(entry.id);

    return CPListItem(
      text: entry.title,
      detailText: entry.author.isNotEmpty ? entry.author : null,
      image: coverUrl,
      playbackProgress: _playbackProgress(entry),
      onPress: (complete, self) {
        _playItem(mediaId);
        complete();
      },
    );
  }

  double _playbackProgress(AutoBookEntry entry) {
    if (entry.currentTime == null || entry.duration <= 0) return 0;
    return (entry.currentTime! / entry.duration).clamp(0.0, 1.0);
  }

  void _playItem(String mediaId) {
    debugPrint('[CarPlay] Playing: $mediaId');
    // Call the handler directly. The static AudioService.playFromMediaId is a
    // deprecated compat shim wired only in the old AudioService.start() flow;
    // with the modern AudioService.init() it routes to a no-op BaseAudioHandler.
    AudioPlayerService.handler?.playFromMediaId(mediaId);
  }
}
