/// Turns BookOrbit API payloads into the Audiobookshelf JSON shapes the rest
/// of the app reads. Pure functions only, so the shapes can be unit tested
/// without a server.
class BookOrbitMapper {
  BookOrbitMapper._();

  static const audioFormats = {'m4b', 'mp3', 'm4a', 'opus', 'ogg', 'flac'};
  static const ebookFormats = {
    'epub',
    'kepub',
    'pdf',
    'mobi',
    'azw3',
    'azw',
    'fb2',
    'djvu',
    'cbz',
    'cbr',
    'cb7',
  };

  /// Formats the app's reader can open, best first.
  static const _readerPreference = ['epub', 'kepub', 'pdf', 'cbz', 'cbr', 'cb7', 'mobi', 'azw3', 'azw', 'fb2'];

  static const _mimeTypes = {
    'm4b': 'audio/mp4',
    'm4a': 'audio/mp4',
    'mp3': 'audio/mpeg',
    'opus': 'audio/ogg',
    'ogg': 'audio/ogg',
    'flac': 'audio/flac',
  };

  /// Prefix for author ids the app made up from a name. Book cards only
  /// carry author names, so a tap on one resolves the real id later.
  static const authorNamePrefix = 'name:';

  static bool isAudioFormat(String? format) =>
      format != null && audioFormats.contains(format.toLowerCase());

  static bool _isContent(Map<String, dynamic> file) {
    final role = file['role'] as String?;
    return role == 'primary' || role == 'content';
  }

  static String? _format(Map<String, dynamic> file) =>
      (file['format'] as String?)?.toLowerCase();

  static int? ms(Object? iso) {
    if (iso is num) return iso.toInt();
    if (iso is! String || iso.isEmpty) return null;
    return DateTime.tryParse(iso)?.millisecondsSinceEpoch;
  }

  static String _str(Object? v) => v == null ? '' : '$v';

  static List<Map<String, dynamic>> _maps(Object? list) =>
      (list as List<dynamic>? ?? const []).whereType<Map<String, dynamic>>().toList();

  static List<String> _strings(Object? list) =>
      (list as List<dynamic>? ?? const []).map((e) => '$e').where((e) => e.isNotEmpty).toList();

  static String _lastFirst(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length < 2) return name;
    final last = parts.removeLast();
    return '$last, ${parts.join(' ')}';
  }

  static Map<String, dynamic> library(Map<String, dynamic> lib) {
    final type = lib['type'] as String? ?? 'books';
    return {
      'id': _str(lib['id']),
      'name': lib['name'] ?? '',
      'displayOrder': lib['displayOrder'] ?? 0,
      'icon': 'database',
      'mediaType': type == 'podcasts' ? 'podcast' : 'book',
      'provider': 'audible',
      'folders': const [],
      'settings': {
        'coverAspectRatio': lib['coverAspectRatio'] == '1/1' ? 1 : 0,
      },
      'createdAt': ms(lib['createdAt']),
      'lastUpdate': ms(lib['updatedAt']),
      'bookCount': lib['bookCount'],
    };
  }

  static Map<String, dynamic> user(Map<String, dynamic> u) {
    final perms = _strings(u['permissions']);
    final superuser = u['isSuperuser'] == true || perms.contains('*');
    bool has(String p) => superuser || perms.contains(p);
    return {
      'id': _str(u['id']),
      'username': u['username'] ?? '',
      'email': u['email'],
      // Admin screens talk to Audiobookshelf-only endpoints, so everyone is
      // a plain user here until those screens learn BookOrbit.
      'type': 'user',
      'isActive': u['active'] != false,
      'isLocked': false,
      'permissions': {
        'download': has('library_download'),
        'update': has('library_edit_metadata'),
        'delete': has('library_delete_books'),
        'upload': false,
        'accessAllLibraries': true,
        'accessAllTags': true,
        'accessExplicitContent': true,
      },
      'librariesAccessible': const [],
      'itemTagsSelected': const [],
      'mediaProgress': const [],
      'bookmarks': const [],
      'seriesHideFromContinueListening': const [],
      'bookOrbit': {
        'name': u['name'],
        'isSuperuser': superuser,
        'permissions': perms,
        'timezone': (u['settings'] as Map?)?['timezone'],
      },
    };
  }

  static String trackContentUrl(String bookId, Object? fileId, String? assetId) {
    final asset = assetId == null ? '' : '?asset=$assetId';
    return '/api/items/$bookId/file/$fileId$asset';
  }

  /// Library item in the expanded Audiobookshelf shape. [detail] is a
  /// BookOrbit BookDetail, [card] a BookCard; either may be missing. With a
  /// [manifest] the tracks, chapters and duration come from it.
  static Map<String, dynamic> item({
    Map<String, dynamic>? card,
    Map<String, dynamic>? detail,
    Map<String, dynamic>? manifest,
    String? libraryId,
  }) {
    final src = detail ?? card ?? const <String, dynamic>{};
    final id = _str(src['id']);
    final files = _maps(src['files']);
    final contentFiles = files.where(_isContent).toList();

    final authorRefs = <Map<String, dynamic>>[];
    if (detail != null) {
      for (final a in _maps(detail['authors'])) {
        authorRefs.add({'id': _str(a['id']), 'name': a['name'] ?? ''});
      }
    } else {
      for (final name in _strings(src['authors'])) {
        authorRefs.add({'id': '$authorNamePrefix$name', 'name': name});
      }
    }
    final authorNames = authorRefs.map((a) => a['name'] as String).toList();

    final narratorNames = detail != null
        ? _maps((detail['audioMetadata'] as Map?)?['narrators'])
            .map((n) => '${n['name'] ?? ''}')
            .where((n) => n.isNotEmpty)
            .toList()
        : _strings(src['narrators']);

    final seriesList = <Map<String, dynamic>>[];
    final memberships = _maps(src['seriesMemberships']);
    if (memberships.isNotEmpty) {
      memberships.sort((a, b) =>
          ((a['displayOrder'] as num?) ?? 0).compareTo((b['displayOrder'] as num?) ?? 0));
      for (final m in memberships) {
        seriesList.add({
          'id': _str(m['seriesId']),
          'name': m['seriesName'] ?? '',
          'sequence': m['seriesIndex'],
        });
      }
    } else if (src['seriesName'] != null) {
      seriesList.add({
        'id': _str(src['seriesId'] ?? 'name:${src['seriesName']}'),
        'name': src['seriesName'],
        'sequence': src['seriesIndex'],
      });
    }
    final seriesName = seriesList
        .map((s) => s['sequence'] != null ? '${s['name']} #${s['sequence']}' : '${s['name']}')
        .join(', ');

    final title = (src['title'] as String?) ?? '';
    final providerIds = (detail?['providerIds'] as Map?) ?? const {};
    final audioMeta = detail?['audioMetadata'] as Map<String, dynamic>?;

    final metadata = <String, dynamic>{
      'title': title,
      'titleIgnorePrefix': title,
      'subtitle': src['subtitle'],
      'authors': authorRefs,
      'narrators': narratorNames,
      'series': seriesList,
      'genres': _strings(src['genres']),
      'publishedYear': src['publishedYear'] == null ? null : '${src['publishedYear']}',
      'publishedDate': src['publishedDate'],
      'publisher': src['publisher'],
      'description': detail?['description'],
      'isbn': detail?['isbn13'] ?? detail?['isbn10'] ?? src['isbn13'],
      'asin': providerIds['audible'] ?? providerIds['audnexus'],
      'language': src['language'],
      'explicit': false,
      'abridged': audioMeta?['abridged'] == true,
      'authorName': authorNames.join(', '),
      'authorNameLF': authorNames.map(_lastFirst).join(', '),
      'narratorName': narratorNames.join(', '),
      'seriesName': seriesName,
    };

    // Tracks: the manifest is the playback order; without one, fall back to
    // the file list (good enough to tell audio from ebook on a card).
    final audioFiles = <Map<String, dynamic>>[];
    final tracks = <Map<String, dynamic>>[];
    final assets = _maps(manifest?['assets']);
    final fileById = {for (final f in files) _str(f['id']): f};
    double offset = 0;
    if (assets.isNotEmpty) {
      for (var i = 0; i < assets.length; i++) {
        final a = assets[i];
        final fileId = _str(a['fileId']);
        final f = fileById[fileId] ?? const <String, dynamic>{};
        final fmt = ((a['format'] as String?) ?? _format(f) ?? 'mp3').toLowerCase();
        final dur = ((a['durationMs'] as num?) ?? 0) / 1000.0;
        final filename = (f['filename'] as String?) ?? 'track_${i + 1}.$fmt';
        final fileMeta = {
          'filename': filename,
          'ext': '.$fmt',
          'path': f['absolutePath'] ?? filename,
          'relPath': filename,
          'size': a['sizeBytes'] ?? f['sizeBytes'] ?? 0,
        };
        audioFiles.add({
          'index': i + 1,
          'ino': fileId,
          'metadata': fileMeta,
          'duration': dur,
          'mimeType': _mimeTypes[fmt] ?? 'audio/mpeg',
          'format': fmt,
          'assetId': a['assetId'],
        });
        tracks.add({
          'index': i + 1,
          'startOffset': offset,
          'duration': dur,
          'title': filename,
          'contentUrl': trackContentUrl(id, fileId, a['assetId'] as String?),
          'mimeType': _mimeTypes[fmt] ?? 'audio/mpeg',
          'metadata': fileMeta,
        });
        offset += dur;
      }
    } else {
      var i = 0;
      for (final f in contentFiles.where((f) => isAudioFormat(_format(f)))) {
        i++;
        final fmt = _format(f)!;
        final dur = ((f['durationSeconds'] as num?) ?? 0).toDouble();
        final filename = (f['filename'] as String?) ?? 'track_$i.$fmt';
        audioFiles.add({
          'index': i,
          'ino': _str(f['id']),
          'metadata': {
            'filename': filename,
            'ext': '.$fmt',
            'path': f['absolutePath'] ?? filename,
            'relPath': filename,
            'size': f['sizeBytes'] ?? 0,
          },
          'duration': dur,
          'mimeType': _mimeTypes[fmt] ?? 'audio/mpeg',
          'format': fmt,
        });
        offset += dur;
      }
    }

    final chapters = <Map<String, dynamic>>[];
    final manifestChapters = _maps(manifest?['chapters']);
    if (manifestChapters.isNotEmpty) {
      for (var i = 0; i < manifestChapters.length; i++) {
        final c = manifestChapters[i];
        chapters.add({
          'id': i,
          'start': ((c['startMs'] as num?) ?? 0) / 1000.0,
          'end': ((c['endMs'] as num?) ?? 0) / 1000.0,
          'title': c['title'] ?? 'Chapter ${i + 1}',
          'bookOrbitId': c['id'],
        });
      }
    } else {
      final raw = _maps(audioMeta?['chapters']);
      final total = _bookDurationSeconds(manifest, audioMeta, offset);
      for (var i = 0; i < raw.length; i++) {
        final start = ((raw[i]['startMs'] as num?) ?? 0) / 1000.0;
        final end = i + 1 < raw.length
            ? ((raw[i + 1]['startMs'] as num?) ?? 0) / 1000.0
            : total;
        chapters.add({'id': i, 'start': start, 'end': end, 'title': raw[i]['title'] ?? 'Chapter ${i + 1}'});
      }
    }

    final ebook = _primaryEbook(contentFiles);
    final ebookFormat = ebook == null ? null : _format(ebook);
    final duration = _bookDurationSeconds(manifest, audioMeta, offset);
    final size = files.fold<num>(0, (sum, f) => sum + ((f['sizeBytes'] as num?) ?? 0));
    final hasCover = detail != null
        ? detail['coverSource'] != null
        : src['hasCover'] == true;

    final media = <String, dynamic>{
      'id': id,
      'libraryItemId': id,
      'metadata': metadata,
      'coverPath': hasCover ? '/bookorbit/books/$id/cover' : null,
      'tags': _strings(src['tags']),
      'audioFiles': audioFiles,
      'chapters': chapters,
      'duration': duration,
      'size': size,
      'tracks': tracks,
      'ebookFile': ebook == null
          ? null
          : {
              'ino': _str(ebook['id']),
              'ebookFormat': ebookFormat,
              'metadata': {
                'filename': ebook['filename'] ?? 'book.$ebookFormat',
                'ext': '.$ebookFormat',
                'size': ebook['sizeBytes'] ?? 0,
              },
            },
      'ebookFormat': ebookFormat,
      'numTracks': audioFiles.length,
      'numAudioFiles': audioFiles.length,
      'numChapters': chapters.length,
    };

    final item = <String, dynamic>{
      'id': id,
      'ino': id,
      'libraryId': _str(detail?['libraryId'] ?? libraryId),
      'folderId': '',
      'path': detail?['folderPath'] ?? '',
      'relPath': '',
      'isFile': false,
      'mediaType': 'book',
      'addedAt': ms(src['addedAt']),
      'updatedAt': ms(src['updatedAt']) ?? ms(src['addedAt']),
      'isMissing': src['status'] == 'missing',
      'isInvalid': false,
      'size': size,
      'numFiles': files.length,
      'media': media,
      'libraryFiles': const [],
      'bookOrbit': {
        'coverVersion': src['coverVersion'],
        'audioCover': _hasAudio(files),
        'readStatus': src['readStatus'],
        'readingProgress': src['readingProgress'],
        if (detail != null) ...{
          'personalNote': detail['personalNote'],
          'communityRatings': detail['communityRatings'] ?? const [],
          'providerIds': detail['providerIds'] ?? const {},
        },
      },
    };

    final collapsed = card?['collapsedSeries'] as Map<String, dynamic>?;
    if (collapsed != null && seriesList.isNotEmpty) {
      final seriesId = card?['seriesId'] != null ? _str(card!['seriesId']) : seriesList.first['id'];
      final seriesTitle = card?['seriesName'] ?? seriesList.first['name'];
      item['collapsedSeries'] = {
        'id': seriesId,
        'name': seriesTitle,
        'nameIgnorePrefix': seriesTitle,
        'numBooks': collapsed['bookCount'] ?? 0,
        'libraryItemIds': (collapsed['coverBookIds'] as List<dynamic>? ?? const [])
            .map((e) => '$e')
            .toList(),
        'seriesSequenceList': '',
      };
    }
    return item;
  }

  static bool _hasAudio(List<Map<String, dynamic>> files) =>
      files.where(_isContent).any((f) => isAudioFormat(_format(f)));

  static Map<String, dynamic>? _primaryEbook(List<Map<String, dynamic>> contentFiles) {
    final ebooks = contentFiles.where((f) {
      final fmt = _format(f);
      return fmt != null && ebookFormats.contains(fmt);
    }).toList();
    if (ebooks.isEmpty) return null;
    bool narrated(Map<String, dynamic> f) => (f['mediaOverlay'] as Map?)?['available'] == true;
    for (final fmt in _readerPreference) {
      Map<String, dynamic>? fallback;
      for (final f in ebooks) {
        if (_format(f) != fmt) continue;
        if (!narrated(f)) return f;
        fallback ??= f;
      }
      if (fallback != null) return fallback;
    }
    return ebooks.first;
  }

  static double _bookDurationSeconds(
    Map<String, dynamic>? manifest,
    Map<String, dynamic>? audioMeta,
    double trackSum,
  ) {
    final total = manifest?['totalDurationMs'] as num?;
    if (total != null && total > 0) return total / 1000.0;
    if (trackSum > 0) return trackSum;
    final meta = audioMeta?['durationSeconds'] as num?;
    return meta?.toDouble() ?? 0;
  }

  /// Book-absolute seconds for a track-local playback state.
  static double absolutePosition(Map<String, dynamic> manifest, Map<String, dynamic> state) {
    final assetId = state['assetId'];
    final local = ((state['positionMs'] as num?) ?? 0) / 1000.0;
    double elapsed = 0;
    for (final a in _maps(manifest['assets'])) {
      if (a['assetId'] == assetId) return elapsed + local;
      elapsed += ((a['durationMs'] as num?) ?? 0) / 1000.0;
    }
    return local;
  }

  /// The asset and track-local milliseconds for a book-absolute position.
  static ({String assetId, int positionMs})? trackPosition(
    Map<String, dynamic> manifest,
    double absoluteSeconds,
  ) {
    final assets = _maps(manifest['assets']);
    if (assets.isEmpty) return null;
    var remainingMs = (absoluteSeconds * 1000).round();
    if (remainingMs < 0) remainingMs = 0;
    for (var i = 0; i < assets.length; i++) {
      final a = assets[i];
      final dur = (a['durationMs'] as num?)?.toInt();
      final last = i == assets.length - 1;
      if (dur == null || last || remainingMs < dur) {
        final pos = dur != null && remainingMs > dur ? dur : remainingMs;
        return (assetId: a['assetId'] as String, positionMs: pos);
      }
      remainingMs -= dur;
    }
    return null;
  }

  static double totalSeconds(Map<String, dynamic> manifest) =>
      ((manifest['totalDurationMs'] as num?) ?? 0) / 1000.0;

  static bool _finishedStatus(Map<String, dynamic>? readStatus) {
    final s = readStatus?['status'];
    return s == 'read' || s == 'skimmed';
  }

  /// Audiobookshelf media progress for a book. [state] is the audiobook
  /// playback state (may be null), [readStatus] the book's UserBookStatus.
  static Map<String, dynamic> progress({
    required String bookId,
    Map<String, dynamic>? manifest,
    Map<String, dynamic>? state,
    Map<String, dynamic>? readStatus,
    double? ebookPercent,
    String? ebookLocation,
    int? ebookUpdatedAt,
  }) {
    final duration = manifest != null ? totalSeconds(manifest) : 0.0;
    final current = manifest != null && state != null ? absolutePosition(manifest, state) : 0.0;
    final pct = ((state?['percentage'] as num?) ?? 0).toDouble();
    final finished = _finishedStatus(readStatus) || state?['completed'] == true;
    final stateUpdated = ms(state?['capturedAt']) ?? 0;
    final statusUpdated = ms(readStatus?['updatedAt']) ?? 0;
    final lastUpdate = [stateUpdated, statusUpdated, ebookUpdatedAt ?? 0].reduce((a, b) => a > b ? a : b);
    return {
      'id': 'bo-$bookId',
      'libraryItemId': bookId,
      'episodeId': null,
      'mediaItemId': bookId,
      'mediaItemType': 'book',
      'duration': duration,
      'progress': finished ? 1.0 : (pct / 100.0).clamp(0.0, 1.0),
      'currentTime': current,
      'isFinished': finished,
      'hideFromContinueListening': false,
      'ebookLocation': ebookLocation,
      'ebookProgress': ebookPercent == null ? null : (ebookPercent / 100.0).clamp(0.0, 1.0),
      'lastUpdate': lastUpdate,
      'startedAt': ms(readStatus?['startedAt']) ?? stateUpdated,
      'finishedAt': finished ? ms(readStatus?['finishedAt']) : null,
      'bookOrbitRevision': state?['revision'],
    };
  }

  /// Progress built from a book card alone, for list-level sync. It carries
  /// the percent and finished flag but no position, so callers must not
  /// treat its currentTime as a place to resume from.
  static Map<String, dynamic> cardProgress(Map<String, dynamic> card) {
    final id = _str(card['id']);
    final readStatus = card['readStatus'] as Map<String, dynamic>?;
    final finished = _finishedStatus(readStatus);
    final pct = ((card['readingProgress'] as num?) ?? 0).toDouble();
    return {
      'id': 'bo-$id',
      'libraryItemId': id,
      'episodeId': null,
      'mediaItemId': id,
      'mediaItemType': 'book',
      'duration': 0,
      'progress': finished ? 1.0 : (pct / 100.0).clamp(0.0, 1.0),
      'currentTime': 0,
      'isFinished': finished,
      'hideFromContinueListening': false,
      'lastUpdate': ms(readStatus?['updatedAt']) ?? 0,
      'startedAt': ms(readStatus?['startedAt']),
      'finishedAt': finished ? ms(readStatus?['finishedAt']) : null,
      'positionUnknown': true,
    };
  }

  static Map<String, dynamic> bookmark(Map<String, dynamic> b) => {
        'libraryItemId': _str(b['bookId']),
        'title': b['title'] ?? '',
        'time': ((b['positionMs'] as num?) ?? 0) / 1000.0,
        'createdAt': ms(b['createdAt']) ?? 0,
        'bookOrbitId': b['id'],
        'note': b['note'],
      };

  static Map<String, dynamic> series(Map<String, dynamic> s, {List<Map<String, dynamic>> books = const []}) {
    final coverIds = (s['coverBookIds'] as List<dynamic>? ?? const []).map((e) => '$e').toList();
    return {
      'id': _str(s['id']),
      'name': s['name'] ?? '',
      'nameIgnorePrefix': s['name'] ?? '',
      'type': 'series',
      'numBooks': s['bookCount'] ?? books.length,
      'addedAt': ms(s['lastAddedAt']),
      'updatedAt': ms(s['lastAddedAt']),
      'books': books,
      'coverBookIds': coverIds,
      'authors': _strings(s['authors']),
    };
  }

  static Map<String, dynamic> author(Map<String, dynamic> a) => {
        'id': _str(a['id']),
        'name': a['name'] ?? '',
        'description': a['description'],
        'imagePath': a['imageUrl'],
        'numBooks': a['bookCount'] ?? 0,
        'addedAt': ms(a['lastAddedAt']),
        // The image URL carries the file's time, so a new image busts caches.
        'updatedAt': int.tryParse(Uri.tryParse('${a['imageUrl'] ?? ''}')?.queryParameters['t'] ?? '') ??
            ms(a['lastAddedAt']),
        'bookOrbit': {
          'imageUrl': a['imageUrl'],
          'coverBookId': a['coverBookId'],
          'sortName': a['sortName'],
        },
      };

  /// Metadata providers in the order, colors and wording of BookOrbit's web
  /// book page.
  static const _providerOrder = [
    'google',
    'goodreads',
    'amazon',
    'hardcover',
    'openLibrary',
    'itunes',
    'audible',
    'librofm',
    'kobo',
    'comicvine',
    'ranobedb',
    'lubimyczytac',
    'aladin',
  ];

  static const providerColors = {
    'google': 0xFF34A853,
    'goodreads': 0xFF00D8D1,
    'amazon': 0xFFFF9900,
    'hardcover': 0xFF7772FF,
    'openLibrary': 0xFF49A4FF,
    'itunes': 0xFFFF4F5D,
    'audible': 0xFFFF8A00,
    'librofm': 0xFF62B9B6,
    'comicvine': 0xFFFFDB0F,
    'ranobedb': 0xFFA78CFF,
    'kobo': 0xFFE23434,
    'lubimyczytac': 0xFFF47373,
    'aladin': 0xFF3E7FFF,
  };

  static const _providerLabels = {
    'google': 'Google Books',
    'goodreads': 'Goodreads',
    'amazon': 'Amazon',
    'hardcover': 'Hardcover',
    'openLibrary': 'Open Library',
    'itunes': 'Apple Books',
    'audible': 'Audible',
    'librofm': 'Libro.fm',
    'kobo': 'Kobo',
    'comicvine': 'ComicVine',
    'ranobedb': 'RanobeDB',
    'lubimyczytac': 'LubimyCzytac',
    'aladin': 'Aladin',
  };

  /// Icon file names under the server's `/assets/provider-icons/`.
  static const _providerIcons = {
    'google': 'google.svg',
    'goodreads': 'goodreads.svg',
    'amazon': 'amazon.svg',
    'hardcover': 'hardcover.svg',
    'openLibrary': 'openlibrary.svg',
    'itunes': 'apple-books.svg',
    'audible': 'audible.svg',
    'librofm': 'librofm.svg',
    'kobo': 'kobo.svg',
    'ranobedb': 'ranobedb.svg',
    'lubimyczytac': 'lubimyczytac.svg',
    'aladin': 'aladin.svg',
  };

  static const _providerMarks = {
    'google': 'G',
    'goodreads': 'GR',
    'amazon': 'A',
    'hardcover': 'H',
    'openLibrary': 'OL',
    'itunes': 'AB',
    'audible': 'Au',
    'librofm': 'Lf',
    'kobo': 'K',
    'comicvine': 'CV',
    'ranobedb': 'RN',
    'lubimyczytac': 'LC',
    'aladin': 'Al',
  };

  /// The book's page on a provider's site, as the web app links it.
  static String? providerUrl(String key, String id) {
    final e = Uri.encodeComponent(id);
    return switch (key) {
      'google' => 'https://books.google.com/books?id=$e',
      'goodreads' => 'https://www.goodreads.com/book/show/$e',
      'amazon' => 'https://www.amazon.com/dp/$e',
      'hardcover' => 'https://hardcover.app/books/$e',
      'openLibrary' =>
        'https://openlibrary.org/works/${Uri.encodeComponent(id.startsWith('/works/') ? id.substring(7) : id)}',
      'itunes' => 'https://books.apple.com/book/id$e',
      'audible' => 'https://www.audible.com/pd/$e',
      'librofm' => 'https://libro.fm/audiobooks/$e',
      'kobo' => 'https://www.kobo.com/us/en/ebook/$e',
      'comicvine' => 'https://comicvine.gamespot.com/issue/4000-$e/',
      'ranobedb' => 'https://ranobedb.org/book/$e',
      'lubimyczytac' =>
        'https://lubimyczytac.pl/ksiazka/${(id.contains('/') ? id : '$id/-').split('/').map(Uri.encodeComponent).join('/')}',
      'aladin' => 'https://www.aladin.co.kr/shop/wproduct.aspx?ItemId=$e',
      _ => null,
    };
  }

  /// A badge for [key] with no link or rating yet.
  static Map<String, dynamic> providerBadge(String key) => {
        'key': key,
        'label': _providerLabels[key] ?? key,
        'url': null,
        'icon': _providerIcons[key],
        'mark': _providerMarks[key] ?? (key.length > 2 ? key.substring(0, 2) : key).toUpperCase(),
        'color': providerColors[key] ?? 0xFF7A7A7A,
      };

  /// One badge per provider the book links to or has a rating from, in the
  /// web app's order: {key, label, url, icon, mark, color, rating?, count?}.
  static List<Map<String, dynamic>> providerBadges(Map? providerIds, List? ratings) {
    final ids = <String, String>{
      for (final e in (providerIds ?? const {}).entries)
        if (e.value is String && (e.value as String).trim().isNotEmpty) '${e.key}': (e.value as String).trim(),
    };
    final rated = <String, Map>{};
    for (final r in (ratings ?? const []).whereType<Map>()) {
      final value = r['rating'];
      if (value is! num || !value.isFinite || value <= 0) continue;
      final key = r['provider'] == 'audnexus' ? 'audible' : '${r['provider']}';
      rated.putIfAbsent(key, () => r);
    }
    final keys = [
      ..._providerOrder.where((k) => ids.containsKey(k) || rated.containsKey(k)),
      ...rated.keys.where((k) => !_providerOrder.contains(k)),
    ];
    return [
      for (final k in keys)
        {
          ...providerBadge(k),
          'url': ids[k] == null ? null : providerUrl(k, ids[k]!),
          if (rated[k] != null) ...{
            'rating': (rated[k]!['rating'] as num).toDouble(),
            'count': (rated[k]!['ratingCount'] as num?)?.toInt(),
          },
        },
    ];
  }

  /// A BookOrbit "more like this" pick, trimmed to what a cover row shows.
  static Map<String, dynamic> similarBook(Map<String, dynamic> r) {
    final status = (r['readStatus'] as Map?)?['status'];
    return {
      'id': _str(r['id']),
      'title': r['title'] ?? '',
      'authorName': _strings(r['authors']).join(', '),
      'hasCover': r['hasCover'] == true,
      'isAudiobook': r['isAudiobook'] == true,
      'finished': status == 'read' || status == 'skimmed',
    };
  }

  static String? _text(Object? v) {
    final s = v?.toString().trim() ?? '';
    return s.isEmpty ? null : s;
  }

  static List<String> _names(Object? list) => (list as List<dynamic>? ?? const [])
      .map((e) => e is Map ? _text(e['name'] ?? e['series']) : _text(e))
      .whereType<String>()
      .toList();

  static bool _sameList(List<Object?> a, List<Object?> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static final _seriesIndexPattern = RegExp(r'^\d+(?:\.\d+)?$');

  /// BookOrbit only takes plain numbers ("2", "2.5") as a series index.
  static String? seriesIndex(Object? raw) {
    final s = _text(raw);
    if (s == null) return null;
    if (_seriesIndexPattern.hasMatch(s)) return s;
    final m = RegExp(r'\d+(?:\.\d+)?').firstMatch(s);
    return m?.group(0);
  }

  /// The BookOrbit metadata PATCH for an Audiobookshelf media update, holding
  /// only the fields that differ from [current] (the item as the app shows
  /// it). Untouched fields stay out so a locked field the user did not change
  /// can't make BookOrbit refuse the whole save.
  static Map<String, dynamic> metadataPatch({
    required Map<String, dynamic> metadata,
    List<String>? tags,
    required Map<String, dynamic> current,
    required bool hasAudio,
  }) {
    final cur = (current['metadata'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
    final out = <String, dynamic>{};
    final audio = <String, dynamic>{};

    void text(String key, String boKey, int? max) {
      if (!metadata.containsKey(key)) return;
      final next = _text(metadata[key]);
      if (next == _text(cur[key])) return;
      out[boKey] = next != null && max != null && next.length > max ? next.substring(0, max) : next;
    }

    text('title', 'title', 1000);
    text('subtitle', 'subtitle', 1000);
    text('description', 'description', null);
    text('publisher', 'publisher', 500);
    text('language', 'language', 100);

    if (metadata.containsKey('publishedYear')) {
      final next = _text(metadata['publishedYear']);
      if (next != _text(cur['publishedYear'])) {
        if (next == null) {
          out['publishedYear'] = null;
        } else if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(next)) {
          out['publishedDate'] = next;
        } else {
          final year = int.tryParse(RegExp(r'\d{4}').firstMatch(next)?.group(0) ?? '');
          if (year != null && year >= 1000 && year <= 2200) out['publishedYear'] = year;
        }
      }
    }

    if (metadata.containsKey('asin')) {
      final next = _text(metadata['asin']);
      if (next != _text(cur['asin']) && (next == null || next.length <= 20)) out['audibleId'] = next;
    }

    if (metadata.containsKey('isbn')) {
      final next = _text(metadata['isbn']);
      if (next != _text(cur['isbn'])) {
        final plain = next?.replaceAll(RegExp(r'[\s-]'), '');
        if (plain == null) {
          out['isbn13'] = null;
          out['isbn10'] = null;
        } else if (plain.length == 10) {
          // The app shows the 13-digit one first, so drop it or the edit
          // would look like it never saved.
          out['isbn10'] = plain;
          out['isbn13'] = null;
        } else if (plain.length <= 13) {
          out['isbn13'] = plain;
        }
      }
    }

    if (metadata.containsKey('authors')) {
      final next = _names(metadata['authors']);
      if (!_sameList(next, _names(cur['authors']))) out['authors'] = next;
    }

    if (metadata.containsKey('genres')) {
      final next = _names(metadata['genres']);
      if (!_sameList(next, _names(cur['genres']))) out['genres'] = next;
    }

    if (tags != null) {
      final next = tags.map(_text).whereType<String>().toList();
      if (!_sameList(next, _names(current['tags']))) out['tags'] = next;
    }

    if (metadata.containsKey('series')) {
      final next = <({String name, String? index})>[];
      for (final s in (metadata['series'] as List<dynamic>? ?? const []).whereType<Map>()) {
        final name = _text(s['name'] ?? s['series']);
        if (name == null) continue;
        next.add((name: name.length > 500 ? name.substring(0, 500) : name, index: seriesIndex(s['sequence'])));
      }
      final now = [
        for (final s in (cur['series'] as List<dynamic>? ?? const []).whereType<Map>())
          (name: _text(s['name']) ?? '', index: seriesIndex(s['sequence'])),
      ];
      if (!_sameList(next, now)) {
        out['seriesMemberships'] = next.isEmpty
            ? null
            : [for (final s in next) {'seriesName': s.name, 'seriesIndex': s.index}];
      }
    }

    if (hasAudio) {
      if (metadata.containsKey('narrators')) {
        final next = _names(metadata['narrators']);
        if (!_sameList(next, _names(cur['narrators']))) audio['narrators'] = next;
      }
      if (metadata.containsKey('abridged')) {
        final next = metadata['abridged'] == true;
        if (next != (cur['abridged'] == true)) audio['abridged'] = next;
      }
    }
    if (audio.isNotEmpty) out['audioMetadata'] = audio;
    return out;
  }

  /// Audiobookshelf chapters ({start, end, title} in seconds) as BookOrbit's
  /// audio chapters. Null clears them.
  static List<Map<String, dynamic>>? chapters(List<dynamic> abs) {
    final rows = abs.whereType<Map>().toList()
      ..sort((a, b) => ((a['start'] as num?) ?? 0).compareTo((b['start'] as num?) ?? 0));
    if (rows.isEmpty) return null;
    return [
      for (var i = 0; i < rows.length; i++)
        {
          'title': _text(rows[i]['title']) ?? 'Chapter ${i + 1}',
          'startMs': (((rows[i]['start'] as num?) ?? 0) * 1000).round(),
          if (rows[i]['end'] is num && (rows[i]['end'] as num) > ((rows[i]['start'] as num?) ?? 0))
            'durationMs': ((((rows[i]['end'] as num) - ((rows[i]['start'] as num?) ?? 0))) * 1000).round(),
        },
    ];
  }

  /// A BookOrbit metadata candidate in the shape Audiobookshelf's book
  /// search returns.
  static Map<String, dynamic> searchResult(Map<String, dynamic> c) {
    final memberships = _maps(c['seriesMemberships']);
    final year = c['publishedYear'] ??
        RegExp(r'^\d{4}').firstMatch('${c['publishedDate'] ?? ''}')?.group(0);
    final authors = _strings(c['authors']);
    final narrators = _strings(c['narrators']);
    return {
      'title': c['displayTitle'] ?? c['title'],
      'subtitle': c['subtitle'],
      'author': authors.isEmpty ? null : authors.join(', '),
      'narrator': narrators.isEmpty ? null : narrators.join(', '),
      'description': c['description'],
      'publisher': c['publisher'],
      'publishedYear': year?.toString(),
      'asin': c['audibleId'] ?? (c['provider'] == 'audible' ? c['providerId'] : null),
      'isbn': c['isbn13'] ?? c['isbn10'],
      'language': c['language'],
      'genres': _strings(c['genres']),
      'series': memberships.isNotEmpty
          ? [for (final m in memberships) {'name': m['seriesName'], 'sequence': m['seriesIndex']}]
          : c['seriesName'],
      'sequence': c['seriesIndex'],
      'cover': c['coverUrl'],
      'duration': c['durationSeconds'],
      'provider': c['provider'],
    };
  }
}
