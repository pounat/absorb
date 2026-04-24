part of 'library_provider.dart';

mixin _AbsorbingMixin on ChangeNotifier, _StateMixin, _CoreMixin {
  bool _dedupeAbsorbingIds() {
    final seen = <String>{};
    final deduped = <String>[];
    for (final key in _absorbingBookIds) {
      if (seen.add(key)) deduped.add(key);
    }
    if (deduped.length == _absorbingBookIds.length) return false;
    _absorbingBookIds = deduped;
    return true;
  }

  void moveAbsorbingToFront(String key) {
    if (!_absorbingBookIds.contains(key)) return;
    if (_absorbingBookIds.first == key) return;
    _absorbingBookIds.remove(key);
    _absorbingBookIds.insert(0, key);
    _saveManualAbsorbing();
  }

  Future<void> _loadManualAbsorbing() async {
    _manualAbsorbAdds =
        (await ScopedPrefs.getStringList('absorbing_manual_adds')).toSet();
    _manualAbsorbRemoves =
        (await ScopedPrefs.getStringList('absorbing_manual_removes')).toSet();
    _absorbingBookIds =
        (await ScopedPrefs.getStringList('absorbing_seen_ids')).toList();
    final cacheList =
        await ScopedPrefs.getStringList('absorbing_item_cache_v2');
    _absorbingItemCache = {};
    for (final s in cacheList) {
      try {
        final m = jsonDecode(s) as Map<String, dynamic>;
        final key = m['_absorbingKey'] as String? ?? m['id'] as String?;
        if (key != null) _absorbingItemCache[key] = m;
      } catch (_) {}
    }
    if (_dedupeAbsorbingIds()) {
      await _saveManualAbsorbing();
    }
  }

  Future<void> _saveManualAbsorbing() async {
    _dedupeAbsorbingIds();
    await ScopedPrefs.setStringList(
        'absorbing_manual_adds', _manualAbsorbAdds.toList());
    await ScopedPrefs.setStringList(
        'absorbing_manual_removes', _manualAbsorbRemoves.toList());
    await ScopedPrefs.setStringList(
        'absorbing_seen_ids', _absorbingBookIds.toList());
    await ScopedPrefs.setStringList('absorbing_item_cache_v2',
        _absorbingItemCache.values.map((e) => jsonEncode(e)).toList());
  }

  Future<void> _updateAbsorbingCache() async {
    final allowedKeys = <String>{};
    final showEntities = <String, Map<String, dynamic>>{};

    final continueSeriesKeys = <String>[];

    final existingIds = Set<String>.from(_absorbingBookIds);

    for (final section in _personalizedSections) {
      final id = section['id'] as String? ?? '';
      if (id == 'continue-listening' ||
          id == 'continue-series' ||
          id == 'downloaded-books') {
        final isContinueSeries = id == 'continue-series';
        final isDownloadedOnly = id == 'downloaded-books';
        for (final e in (section['entities'] as List<dynamic>? ?? [])) {
          if (e is Map<String, dynamic>) {
            final itemId = e['id'] as String?;
            if (itemId == null) continue;
            final recentEpisode = e['recentEpisode'] as Map<String, dynamic>?;
            if (recentEpisode != null) {
              final episodeId = recentEpisode['id'] as String?;
              if (episodeId != null) {
                final key = '$itemId-$episodeId';
                // Downloads are shared across accounts on disk; don't auto-add
                // them to this account's absorbing list unless this account has
                // played them or manually added them.
                if (isDownloadedOnly &&
                    !_progressMap.containsKey(key) &&
                    !_manualAbsorbAdds.contains(key)) {
                  continue;
                }
                allowedKeys.add(key);
                showEntities[itemId] = e;
                if (!_manualAbsorbRemoves.contains(key)) {
                  _absorbingIdsAdd(key, atFront: false);
                  _absorbingItemCache[key] = {...e, '_absorbingKey': key};
                  if (isContinueSeries) continueSeriesKeys.add(key);
                }
              }
            } else {
              if (isDownloadedOnly &&
                  !_progressMap.containsKey(itemId) &&
                  !_manualAbsorbAdds.contains(itemId)) {
                continue;
              }
              allowedKeys.add(itemId);
              if (!_manualAbsorbRemoves.contains(itemId)) {
                _absorbingIdsAdd(itemId, atFront: false);
                _absorbingItemCache[itemId] = e;
                if (isContinueSeries) continueSeriesKeys.add(itemId);
              }
            }
          }
        }
      }
    }

    String? newContinueSeriesKey;
    if (_lastFinishedItemId != null && continueSeriesKeys.isNotEmpty) {
      for (final key in continueSeriesKeys) {
        if (!existingIds.contains(key)) {
          _absorbingIdsAdd(key, afterKey: _lastFinishedItemId);
          _manualAbsorbAdds.add(key);
          newContinueSeriesKey ??= key;
        }
      }
    }

    if (newContinueSeriesKey != null && _api != null) {
      PlayerSettings.getBookQueueMode().then((mode) {
        if (mode != 'auto_next') return;
        if (AudioPlayerService.wasNoisyPause) return;
        if (AudioPlayerService().isPlaying) return;

        final finishedData = _lastFinishedItemId != null
            ? _itemDataWithSeries(_lastFinishedItemId!)
            : null;
        final (finSeriesId, finSeq) =
            finishedData != null ? _StateMixin._extractSeries(finishedData) : (null, null);

        String actualNextKey = newContinueSeriesKey!;
        if (finSeriesId != null && finSeq != null) {
          double lowestSeq = double.infinity;
          for (final key in _absorbingBookIds) {
            if (key.length > 36) continue;
            if ((this as LibraryProvider).isItemFinishedByKey(key)) continue;
            final data = _absorbingItemCache[key];
            if (data == null) continue;
            final (sid, seq) = _StateMixin._extractSeries(data);
            if (sid != finSeriesId || seq == null || seq <= finSeq) continue;
            if (seq < lowestSeq) {
              lowestSeq = seq;
              actualNextKey = key;
            }
          }
        }

        final cached = _absorbingItemCache[actualNextKey];
        if (cached == null) return;
        final media = cached['media'] as Map<String, dynamic>? ?? {};
        final metadata = media['metadata'] as Map<String, dynamic>? ?? {};
        final title = metadata['title'] as String? ?? '';
        final author = metadata['authorName'] as String? ?? '';
        final duration = (media['duration'] as num?)?.toDouble() ?? 0;
        final chapters = media['chapters'] as List<dynamic>? ?? [];
        AudioPlayerService().playItem(
          api: _api!,
          itemId: actualNextKey,
          title: title,
          author: author,
          coverUrl: getCoverUrl(actualNextKey),
          totalDuration: duration,
          chapters: chapters,
        );
      });
    }

    if (isPodcastLibrary) {
      final knownShowIds = <String>{};
      for (final key in _absorbingBookIds) {
        if (key.length > 36) {
          knownShowIds.add(key.substring(0, 36));
        }
      }
      knownShowIds.addAll(showEntities.keys);

      for (final entry in _progressMap.entries) {
        final key = entry.key;
        if (key.length <= 36) continue;
        final mp = entry.value;
        if (mp['isFinished'] == true) continue;
        final progress = (mp['progress'] as num?)?.toDouble() ?? 0;
        if (progress <= 0) continue;

        final showId = key.substring(0, 36);
        final episodeId = key.substring(37);

        if (_absorbingBookIds.contains(key)) continue;
        if (_manualAbsorbRemoves.contains(key)) continue;
        if (!knownShowIds.contains(showId)) continue;

        final showData = showEntities[showId] ??
            _absorbingItemCache.values.cast<Map<String, dynamic>?>().firstWhere(
                  (c) => c != null && (c['id'] as String?) == showId,
                  orElse: () => null,
                );
        if (showData == null) continue;

        final duration = (mp['duration'] as num?)?.toDouble() ?? 0;
        final currentTime = (mp['currentTime'] as num?)?.toDouble() ?? 0;
        final syntheticEntry = Map<String, dynamic>.from(showData);
        syntheticEntry['recentEpisode'] = {
          'id': episodeId,
          'duration': duration,
          'currentTime': currentTime,
          'title': 'Episode',
        };
        syntheticEntry['_absorbingKey'] = key;
        _absorbingIdsAdd(key, atFront: false);
        _absorbingItemCache[key] = syntheticEntry;
        allowedKeys.add(key);
      }

      _enrichEpisodeTitles();
    }

    final toRemove = <String>[];
    for (final key in _absorbingBookIds) {
      if (allowedKeys.contains(key)) continue;
      if (_manualAbsorbAdds.contains(key)) continue;
      final hasProgress = key.length > 36
          ? _progressMap.containsKey(key)
          : _progressMap.keys.any((k) => k == key || k.startsWith('$key-'));
      if (!hasProgress) toRemove.add(key);
    }
    for (final id in toRemove) {
      _absorbingBookIds.remove(id);
      _absorbingItemCache.remove(id);
    }

    final migrateRemove = <String>[];
    final migrateAdd = <String, Map<String, dynamic>>{};
    for (final key in _absorbingBookIds) {
      if (key.length > 36) continue;
      final cached = _absorbingItemCache[key];
      if (cached == null) continue;
      final re = cached['recentEpisode'] as Map<String, dynamic>?;
      if (re == null) continue;
      final epId = re['id'] as String?;
      if (epId == null) continue;
      final newKey = '$key-$epId';
      if (!_absorbingBookIds.contains(newKey)) {
        migrateRemove.add(key);
        migrateAdd[newKey] = {...cached, '_absorbingKey': newKey};
      }
    }
    for (final old in migrateRemove) {
      _absorbingBookIds.remove(old);
      _absorbingItemCache.remove(old);
    }
    for (final entry in migrateAdd.entries) {
      _absorbingIdsAdd(entry.key, atFront: false);
      _absorbingItemCache[entry.key] = entry.value;
    }

    await _saveManualAbsorbing();
  }

  Future<void> _enrichEpisodeTitles() async {
    if (_api == null) return;
    final needsEnrich = <String, List<String>>{};
    for (final entry in _absorbingItemCache.entries) {
      final ep = entry.value['recentEpisode'] as Map<String, dynamic>?;
      if (ep == null) continue;
      if ((ep['title'] as String?) != 'Episode')
        continue;
      final showId = entry.value['id'] as String?;
      final epId = ep['id'] as String?;
      if (showId == null || epId == null) continue;
      needsEnrich.putIfAbsent(showId, () => []).add(epId);
    }
    for (final showId in needsEnrich.keys) {
      try {
        final fullItem = await _api!.getLibraryItem(showId);
        if (fullItem == null) continue;
        final media = fullItem['media'] as Map<String, dynamic>? ?? {};
        final episodes = media['episodes'] as List<dynamic>? ?? [];
        for (final epId in needsEnrich[showId]!) {
          final key = '$showId-$epId';
          final cached = _absorbingItemCache[key];
          if (cached == null) continue;
          final ep = episodes.cast<Map<String, dynamic>?>().firstWhere(
                (e) => e != null && (e['id'] as String?) == epId,
                orElse: () => null,
              );
          if (ep != null) {
            cached['recentEpisode'] = Map<String, dynamic>.from(ep);
            _absorbingItemCache[key] = cached;
          }
        }
      } catch (_) {}
    }
    if (needsEnrich.isNotEmpty) {
      await _saveManualAbsorbing();
      notifyListeners();
    }
  }

  Future<void> addToAbsorbing(String itemId) async {
    _manualAbsorbAdds.add(itemId);
    _manualAbsorbRemoves.remove(itemId);
    _absorbingIdsAdd(itemId);
    await _saveManualAbsorbing();
    notifyListeners();
  }

  Future<void> addToAbsorbingQueue(String itemId) async {
    _manualAbsorbAdds.add(itemId);
    _manualAbsorbRemoves.remove(itemId);
    _absorbingIdsAdd(itemId, atFront: false);
    await _saveManualAbsorbing();
    notifyListeners();
  }

  Future<void> reorderAbsorbing(List<String> newOrder) async {
    _absorbingBookIds = newOrder;
    await _saveManualAbsorbing();
    notifyListeners();
    _catchUpQueueAutoDownloads();
  }

  void unblockFromAbsorbing(String key,
      {String? episodeTitle, double? episodeDuration}) {
    _localProgressOverrides.remove(key);
    _locallyFinishedItems.remove(key);
    final pm = _progressMap[key];
    if (pm != null && pm['isFinished'] == true) {
      _progressMap[key] = {...pm, 'isFinished': false};
    }
    bool changed = _manualAbsorbRemoves.remove(key);
    final isCompound = key.length > 36;
    if (!_absorbingBookIds.contains(key)) {
      _absorbingIdsAdd(key);
      changed = true;
      final showId = isCompound ? key.substring(0, 36) : key;
      for (final section in _personalizedSections) {
        for (final e in (section['entities'] as List<dynamic>? ?? [])) {
          if (e is Map<String, dynamic> && (e['id'] as String?) == showId) {
            if (isCompound) {
              final episodeId = key.substring(37);
              final cached = Map<String, dynamic>.from(e);
              cached['_absorbingKey'] = key;
              cached['recentEpisode'] = {
                ...?(cached['recentEpisode'] as Map<String, dynamic>?),
                'id': episodeId,
                if (episodeTitle != null) 'title': episodeTitle,
                if (episodeDuration != null && episodeDuration > 0)
                  'duration': episodeDuration,
              };
              _absorbingItemCache[key] = cached;
            } else {
              _absorbingItemCache[key] = e;
            }
            break;
          }
        }
      }
    }
    if (isCompound && _absorbingItemCache.containsKey(key)) {
      final cached = _absorbingItemCache[key]!;
      if (cached['_absorbingKey'] == null) cached['_absorbingKey'] = key;
      final episodeId = key.substring(37);
      final re = cached['recentEpisode'] as Map<String, dynamic>?;
      if (re == null || (re['id'] as String?) != episodeId) {
        cached['recentEpisode'] = {
          ...?re,
          'id': episodeId,
          if (episodeTitle != null) 'title': episodeTitle,
          if (episodeDuration != null && episodeDuration > 0)
            'duration': episodeDuration,
        };
      } else if (episodeTitle != null && re['title'] == null) {
        cached['recentEpisode'] = {...re, 'title': episodeTitle};
      }
    }
    if (changed) _saveManualAbsorbing();
  }

  void clearAbsorbingBlock(String key) {
    if (_manualAbsorbRemoves.remove(key)) _saveManualAbsorbing();
  }

  Future<void> removeFromAbsorbing(String key) async {
    _manualAbsorbRemoves.add(key);
    _manualAbsorbAdds.remove(key);
    _absorbingBookIds.remove(key);
    _absorbingItemCache.remove(key);
    await _saveManualAbsorbing();
    notifyListeners();
  }

  void markFinishedLocally(String itemId,
      {bool skipRefresh = false, bool skipAutoAdvance = false}) {
    _resetItems.remove(itemId);
    final existing = _progressMap[itemId] ?? {};
    _progressMap[itemId] = {...existing, 'isFinished': true};
    _localProgressOverrides[itemId] = 1.0;
    _lastFinishedItemId = itemId;
    _locallyFinishedItems.add(itemId);
    // Stats widget shows "books finished this year"; force a refresh so it
    // reflects the new count without waiting on the 15-min throttle.
    HomeWidgetService().refreshStats(force: true);
    if (_absorbingBookIds.remove(itemId)) {
      _absorbingBookIds.insert(0, itemId);
    }
    if (itemId.length > 36) {
      final cached = _absorbingItemCache[itemId];
      if (cached != null && cached['_absorbingKey'] == null) {
        cached['_absorbingKey'] = itemId;
      }
    }
    notifyListeners();

    if (itemId.length <= 36) {
      _addNextSeriesBookToAbsorbing(itemId);
    }

    if (!skipAutoAdvance) {
      final isPodcast = itemId.length > 36;
      final modeFuture = isPodcast
          ? PlayerSettings.getPodcastQueueMode()
          : PlayerSettings.getBookQueueMode();
      modeFuture.then((mode) {
        debugPrint('[AutoAdvance] queueMode=$mode (${isPodcast ? 'podcast' : 'book'}) for finished item $itemId');
        if (mode == 'manual') {
          _manualQueueAdvance(itemId);
        } else if (mode == 'auto_next') {
          _autoAdvanceOffline(itemId);
        }
      });
    }

    _checkRollingDownloads(itemId);
    _checkQueueAutoDownloads(itemId);

    if (DownloadService().isDownloaded(itemId)) {
      PlayerSettings.getRollingDownloadDeleteFinished().then((delete) {
        if (!delete) return;
        DownloadService().deleteDownload(itemId, skipStopCheck: true);
        _showRollingSnackBar(_l()?.lpDeletedFinishedDownload ?? 'Deleted finished download');
      });
    }

    final isCompound = itemId.length > 36;
    if (isCompound && !skipRefresh && _api != null && !isOffline) {
      final showId = itemId.substring(0, 36);
      final episodeId = itemId.substring(37);
      PlayerSettings.getPodcastQueueMode().then((queueMode) {
        if (queueMode == 'auto_next') {
          _addNextPodcastEpisode(showId, episodeId, itemId).then((_) {
            if (_selectedLibraryId != null && !isOffline) {
              refreshProgressShelves(force: true, reason: 'podcast-finished');
            }
            removeFromAbsorbing(itemId);
          });
        } else {
          if (_selectedLibraryId != null && !isOffline) {
            refreshProgressShelves(force: true, reason: 'item-finished');
          }
          removeFromAbsorbing(itemId);
        }
      });
      return;
    }

    if (!skipRefresh &&
        _api != null &&
        _selectedLibraryId != null &&
        !isOffline) {
      Future.delayed(const Duration(milliseconds: 500), () async {
        await _refreshProgress();
        refreshProgressShelves(force: true, reason: 'item-finished');
        removeFromAbsorbing(itemId);
      });
    }

    if (isOffline) {
      removeFromAbsorbing(itemId);
    }
  }

  Future<void> _addNextPodcastEpisode(
      String showId, String finishedEpisodeId, String finishedKey) async {
    await Future.delayed(const Duration(milliseconds: 500));
    try {
      if (_api == null) return;
      final fullItem = await _api!.getLibraryItem(showId);
      if (fullItem == null) return;
      final media = fullItem['media'] as Map<String, dynamic>? ?? {};
      final episodes =
          List<dynamic>.from(media['episodes'] as List<dynamic>? ?? []);
      if (episodes.isEmpty) return;

      final prefs = await SharedPreferences.getInstance();
      final advanceNewestFirst =
          (prefs.getString('podcast_advance_dir_$showId') ?? 'oldest_first') == 'newest_first';

      episodes.sort((a, b) {
        final aTime = (a['publishedAt'] as num?)?.toInt() ?? 0;
        final bTime = (b['publishedAt'] as num?)?.toInt() ?? 0;
        return advanceNewestFirst ? bTime.compareTo(aTime) : aTime.compareTo(bTime);
      });

      final currentIdx = episodes.indexWhere(
        (e) =>
            e is Map<String, dynamic> &&
            (e['id'] as String?) == finishedEpisodeId,
      );
      if (currentIdx < 0 || currentIdx >= episodes.length - 1) return;

      Map<String, dynamic>? nextEp;
      String? nextEpId;
      String? nextKey;
      int serverChecks = 0;
      bool trustCache = false;
      for (int i = currentIdx + 1; i < episodes.length; i++) {
        final candidate = episodes[i] as Map<String, dynamic>;
        final candidateId = candidate['id'] as String?;
        if (candidateId == null) continue;
        final candidateKey = '$showId-$candidateId';
        final cachedFinished = _progressMap[candidateKey]?['isFinished'] == true;
        if (cachedFinished) {
          if (trustCache) continue;
          final freshProg = await _api?.getEpisodeProgress(showId, candidateId);
          serverChecks++;
          if (freshProg?['isFinished'] == true) {
            if (serverChecks >= 5) trustCache = true;
            continue;
          }
          if (freshProg != null) {
            _progressMap[candidateKey] = freshProg;
            _localProgressOverrides.remove(candidateKey);
          }
        }
        nextEp = candidate;
        nextEpId = candidateId;
        nextKey = candidateKey;
        break;
      }
      if (nextEp == null || nextEpId == null || nextKey == null) return;

      final showData =
          _absorbingItemCache.values.cast<Map<String, dynamic>?>().firstWhere(
                    (c) => c != null && (c['id'] as String?) == showId,
                    orElse: () => null,
                  ) ??
              fullItem;
      final syntheticEntry = Map<String, dynamic>.from(showData);
      syntheticEntry['recentEpisode'] = Map<String, dynamic>.from(nextEp);
      syntheticEntry['_absorbingKey'] = nextKey;

      _manualAbsorbRemoves.remove(nextKey);
      _manualAbsorbAdds.add(nextKey);
      _absorbingIdsAdd(nextKey, afterKey: finishedKey);
      _absorbingItemCache[nextKey] = syntheticEntry;
      await _saveManualAbsorbing();
      notifyListeners();

      if ((await PlayerSettings.getPodcastQueueMode()) == 'auto_next' &&
          _api != null &&
          !AudioPlayerService().isPlaying) {
        final metadata = media['metadata'] as Map<String, dynamic>? ?? {};
        final title = metadata['title'] as String? ?? '';
        final author = metadata['authorName'] as String? ?? '';
        final duration = (nextEp['duration'] as num?)?.toDouble() ??
            (nextEp['audioFile'] as Map<String, dynamic>?)?['duration']
                as double? ??
            0;
        final savedProgress = _progressMap[nextKey];
        final startTime =
            (savedProgress?['currentTime'] as num?)?.toDouble() ?? 0.0;
        AudioPlayerService().playItem(
          api: _api!,
          itemId: showId,
          title: title,
          author: author,
          coverUrl: getCoverUrl(showId),
          totalDuration: duration,
          chapters: [],
          episodeId: nextEpId,
          episodeTitle: nextEp['title'] as String?,
          startTime: startTime,
        );
      }
    } catch (e, st) {
      debugPrint('[AutoAdvance] _addNextPodcastEpisode error: $e\n$st');
    }
  }

  void _manualQueueAdvance(String finishedKey) async {
    if (AudioPlayerService.wasNoisyPause) {
      debugPrint('[AutoAdvance] Skipping manual advance - noisy pause active');
      return;
    }

    final merged = await PlayerSettings.getMergeAbsorbingLibraries();

    final finishedCached = _absorbingItemCache[finishedKey];
    final finishedLibId = finishedCached?['libraryId'] as String?;

    final finishedIdx = _absorbingBookIds.indexOf(finishedKey);
    final startIdx = finishedIdx >= 0 ? finishedIdx + 1 : 0;

    for (int i = startIdx; i < _absorbingBookIds.length; i++) {
      final key = _absorbingBookIds[i];
      if ((this as LibraryProvider).isItemFinishedByKey(key)) continue;

      final cached = _absorbingItemCache[key];
      if (cached == null) continue;

      if (!merged && finishedLibId != null) {
        final candidateLibId = cached['libraryId'] as String?;
        if (candidateLibId != null && candidateLibId != finishedLibId) continue;
      }

      final media = cached['media'] as Map<String, dynamic>? ?? {};
      final metadata = media['metadata'] as Map<String, dynamic>? ?? {};
      final title = metadata['title'] as String? ?? '';
      final author = metadata['authorName'] as String? ?? '';

      if (key.length > 36) {
        final showId = key.substring(0, 36);
        final epId = key.substring(37);
        final ep = cached['recentEpisode'] as Map<String, dynamic>?;
        final epDuration = (ep?['duration'] as num?)?.toDouble() ??
            (media['duration'] as num?)?.toDouble() ??
            0;
        AudioPlayerService().playItem(
          api: _api ?? ApiService(baseUrl: '', token: ''),
          itemId: showId,
          title: title,
          author: author,
          coverUrl: getCoverUrl(showId),
          totalDuration: epDuration,
          chapters: [],
          episodeId: epId,
          episodeTitle: ep?['title'] as String?,
        );
      } else {
        final duration = (media['duration'] as num?)?.toDouble() ?? 0;
        final chapters = media['chapters'] as List<dynamic>? ?? [];
        AudioPlayerService().playItem(
          api: _api ?? ApiService(baseUrl: '', token: ''),
          itemId: key,
          title: title,
          author: author,
          coverUrl: getCoverUrl(key),
          totalDuration: duration,
          chapters: chapters,
        );
      }
      debugPrint('[AutoAdvance] Manual queue: starting next item $key');
      return;
    }
    debugPrint('[AutoAdvance] Manual queue: no next item found after $finishedKey');
  }

  void _autoAdvanceOffline(String finishedKey) {
    if (AudioPlayerService.wasNoisyPause) {
      debugPrint('[AutoAdvance] Skipping auto advance - noisy pause active');
      return;
    }

    final isCompound = finishedKey.length > 36;
    if (isCompound) {
      _autoAdvanceOfflinePodcast(finishedKey);
    } else {
      _autoAdvanceOfflineBook(finishedKey);
    }
  }

  Future<void> _addNextSeriesBookToAbsorbing(String finishedBookId) async {
    var finished = _itemDataWithSeries(finishedBookId);
    var (seriesId, currentSeq) =
        finished != null ? _StateMixin._extractSeries(finished) : (null, null);
    if (seriesId == null || currentSeq == null) {
      if (_api == null) {
        debugPrint('[Absorbing] No series info and no API for $finishedBookId');
        return;
      }
      final fullItem = await _api!.getLibraryItem(finishedBookId);
      if (fullItem == null) {
        debugPrint('[Absorbing] Could not fetch item $finishedBookId from server');
        return;
      }
      finished = fullItem;
      (seriesId, currentSeq) = _StateMixin._extractSeries(fullItem);
    }
    if (seriesId == null || currentSeq == null) {
      debugPrint('[Absorbing] $finishedBookId is not in a series');
      return;
    }
    debugPrint('[Absorbing] Looking for next book after seq $currentSeq in series $seriesId');

    final candidates = <double, MapEntry<String, Map<String, dynamic>>>{};

    for (final entry in _absorbingItemCache.entries) {
      final key = entry.key;
      if (key == finishedBookId || key.length > 36) continue;
      if ((this as LibraryProvider).isItemFinishedByKey(key)) continue;
      final (sid, seq) = _StateMixin._extractSeries(entry.value);
      if (sid != seriesId || seq == null || seq <= currentSeq) continue;
      candidates[seq] = MapEntry(key, entry.value);
    }

    for (final dlInfo in DownloadService().downloadedItems) {
      final id = dlInfo.itemId;
      if (id == finishedBookId || id.length > 36) continue;
      if (candidates.values.any((e) => e.key == id)) continue;
      if (_progressMap[id]?['isFinished'] == true) continue;
      final data = _itemDataWithSeries(id);
      if (data == null) continue;
      final (sid, seq) = _StateMixin._extractSeries(data);
      if (sid != seriesId || seq == null || seq <= currentSeq) continue;
      candidates[seq] = MapEntry(id, data);
    }

    if (candidates.isEmpty && _api != null && _selectedLibraryId != null) {
      final books = await _api!.getBooksBySeries(
        _selectedLibraryId!,
        seriesId,
        limit: 100,
      );
      for (final book in books) {
        if (book is! Map<String, dynamic>) continue;
        final id = book['id'] as String?;
        if (id == null || id == finishedBookId) continue;
        if (_progressMap[id]?['isFinished'] == true) continue;
        final (sid, seq) = _StateMixin._extractSeries(book);
        if (sid != seriesId || seq == null || seq <= currentSeq) continue;
        candidates[seq] = MapEntry(id, book);
      }
    }

    if (candidates.isEmpty) {
      debugPrint('[Absorbing] No next book found in series $seriesId after seq $currentSeq');
      return;
    }

    final nextSeq = candidates.keys.toList()..sort();
    final next = candidates[nextSeq.first]!;
    final nextKey = next.key;

    if (_manualAbsorbRemoves.contains(nextKey)) {
      debugPrint('[Absorbing] Next book $nextKey was manually removed, skipping');
      return;
    }

    _absorbingIdsAdd(nextKey, afterKey: finishedBookId);
    _absorbingItemCache[nextKey] = next.value;
    _manualAbsorbAdds.add(nextKey);
    _saveManualAbsorbing();
    notifyListeners();
    debugPrint('[Absorbing] Auto-added next series book: $nextKey (seq ${nextSeq.first})');

    final mode = await PlayerSettings.getBookQueueMode();
    if (mode != 'auto_next') return;
    if (AudioPlayerService.wasNoisyPause) return;
    if (AudioPlayerService().isPlaying) return;
    if (_api == null) return;

    final nextData = next.value;
    final media = nextData['media'] as Map<String, dynamic>? ?? {};
    final metadata = media['metadata'] as Map<String, dynamic>? ?? {};
    AudioPlayerService().playItem(
      api: _api!,
      itemId: nextKey,
      title: metadata['title'] as String? ?? '',
      author: metadata['authorName'] as String? ?? '',
      coverUrl: getCoverUrl(nextKey),
      totalDuration: (media['duration'] as num?)?.toDouble() ?? 0,
      chapters: media['chapters'] as List<dynamic>? ?? [],
    );
  }

  void _autoAdvanceOfflineBook(String finishedBookId) {
    PlayerSettings.getBookQueueMode().then((mode) {
      // Alpha: bail-reason logs for GH #186 (book restart). Each silent return
      // here was a suspect in the advance-didn't-fire hypothesis.
      if (mode != 'auto_next') {
        debugPrint('[AutoAdvance] Offline book bail: mode=$mode (not auto_next) finished=$finishedBookId');
        return;
      }
      if (AudioPlayerService.wasNoisyPause) {
        debugPrint('[AutoAdvance] Offline book bail: wasNoisyPause=true finished=$finishedBookId');
        return;
      }

      final finished = _itemDataWithSeries(finishedBookId);
      if (finished == null) {
        debugPrint('[AutoAdvance] Offline book bail: no series data for finished=$finishedBookId');
        return;
      }
      final (seriesId, currentSeq) = _StateMixin._extractSeries(finished);
      if (seriesId == null || currentSeq == null) {
        debugPrint('[AutoAdvance] Offline book bail: seriesId=$seriesId currentSeq=$currentSeq finished=$finishedBookId');
        return;
      }

      final dl = DownloadService();
      final candidates = <double, MapEntry<String, Map<String, dynamic>>>{};
      for (final dlInfo in dl.downloadedItems) {
        final id = dlInfo.itemId;
        if (id == finishedBookId) continue;
        if (id.length > 36) continue;
        if (_progressMap[id]?['isFinished'] == true) continue;

        final data = _itemDataWithSeries(id);
        if (data == null) continue;
        final (sid, seq) = _StateMixin._extractSeries(data);
        if (sid != seriesId || seq == null || seq <= currentSeq) continue;
        candidates[seq] = MapEntry(id, data);
      }
      if (candidates.isEmpty) {
        debugPrint('[AutoAdvance] Offline book bail: no downloaded next book in series=$seriesId after seq=$currentSeq');
        return;
      }

      final nextSeq = candidates.keys.toList()..sort();
      final next = candidates[nextSeq.first]!;
      final nextKey = next.key;
      final nextData = next.value;

      _absorbingIdsAdd(nextKey, afterKey: finishedBookId);
      _absorbingItemCache[nextKey] = nextData;
      _saveManualAbsorbing();
      notifyListeners();

      final nextMedia = nextData['media'] as Map<String, dynamic>? ?? {};
      final nextMeta = nextMedia['metadata'] as Map<String, dynamic>? ?? {};
      AudioPlayerService().playItem(
        api: _api ?? ApiService(baseUrl: '', token: ''),
        itemId: nextKey,
        title: nextMeta['title'] as String? ?? '',
        author: nextMeta['authorName'] as String? ?? '',
        coverUrl: getCoverUrl(nextKey),
        totalDuration: (nextMedia['duration'] as num?)?.toDouble() ?? 0,
        chapters: nextMedia['chapters'] as List<dynamic>? ?? [],
      );
    });
  }

  void _autoAdvanceOfflinePodcast(String finishedKey) {
    PlayerSettings.getPodcastQueueMode().then((mode) async {
      if (mode != 'auto_next') return;
      if (AudioPlayerService.wasNoisyPause) return;

      final showId = finishedKey.substring(0, 36);
      final finishedEpId = finishedKey.substring(37);

      final prefs = await SharedPreferences.getInstance();
      final advanceNewestFirst =
          (prefs.getString('podcast_advance_dir_$showId') ?? 'oldest_first') == 'newest_first';

      final dl = DownloadService();
      final episodes = <int, MapEntry<String, Map<String, dynamic>>>{};
      int? finishedTimestamp;

      for (final entry in _absorbingItemCache.entries) {
        if (!entry.key.startsWith('$showId-')) continue;
        final ep = entry.value['recentEpisode'] as Map<String, dynamic>?;
        if (ep == null) continue;
        final epId = ep['id'] as String?;
        if (epId == null) continue;
        final publishedAt = (ep['publishedAt'] as num?)?.toInt() ?? 0;

        if (epId == finishedEpId) {
          finishedTimestamp = publishedAt;
        } else if (!(_progressMap[entry.key]?['isFinished'] == true) &&
            dl.isDownloaded(entry.key)) {
          episodes[publishedAt] = entry;
        }
      }
      if (finishedTimestamp == null || episodes.isEmpty) return;

      final sorted = episodes.keys.toList()..sort();
      final int? nextTimestamp;
      if (advanceNewestFirst) {
        nextTimestamp = sorted.where((t) => t < finishedTimestamp!).lastOrNull;
      } else {
        nextTimestamp = sorted.where((t) => t > finishedTimestamp!).firstOrNull;
      }
      if (nextTimestamp == null) return;

      final nextEntry = episodes[nextTimestamp]!;
      final nextKey = nextEntry.key;
      final nextData = nextEntry.value;
      final ep = nextData['recentEpisode'] as Map<String, dynamic>;
      final nextEpId = ep['id'] as String;

      _absorbingIdsAdd(nextKey, afterKey: finishedKey);
      _saveManualAbsorbing();
      notifyListeners();

      final media = nextData['media'] as Map<String, dynamic>? ?? {};
      final metadata = media['metadata'] as Map<String, dynamic>? ?? {};
      final duration = (ep['duration'] as num?)?.toDouble() ??
          (ep['audioFile'] as Map<String, dynamic>?)?['duration'] as double? ??
          0;
      AudioPlayerService().playItem(
        api: _api ?? ApiService(baseUrl: '', token: ''),
        itemId: showId,
        title: metadata['title'] as String? ?? '',
        author: metadata['authorName'] as String? ?? '',
        coverUrl: getCoverUrl(showId),
        totalDuration: duration,
        chapters: [],
        episodeId: nextEpId,
        episodeTitle: ep['title'] as String?,
      );
    });
  }
}
