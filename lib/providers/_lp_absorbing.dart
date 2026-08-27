part of 'library_provider.dart';

mixin _AbsorbingMixin on ChangeNotifier, _StateMixin, _CoreMixin {
  int _staleSourceCleanupGeneration = 0;

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
    // The user engaged with the queue, so the "keep a fresh episode on top"
    // protection has done its job - drop it.
    setFreshQueuedFront(null);
    if (_absorbingBookIds.first == key) return;
    _absorbingBookIds.remove(key);
    _absorbingBookIds.insert(0, key);
    _saveManualAbsorbing();
  }

  /// Mark (or clear) the just-arrived subscribed episode that should stay at the
  /// top of the queue. Persisted so it survives an app kill.
  void setFreshQueuedFront(String? key) {
    if (_freshQueuedFrontKey == key) return;
    _freshQueuedFrontKey = key;
    if (key == null) {
      ScopedPrefs.remove('absorbing_fresh_front');
    } else {
      ScopedPrefs.setString('absorbing_fresh_front', key);
    }
  }

  Future<void> _loadManualAbsorbing() async {
    _manualAbsorbAdds =
        (await ScopedPrefs.getStringList('absorbing_manual_adds')).toSet();
    _finishedManualAbsorbAdds = (await ScopedPrefs.getStringList(
      'absorbing_finished_manual_adds',
    ))
        .toSet()
      ..retainAll(_manualAbsorbAdds);
    _manualAbsorbRemoves =
        (await ScopedPrefs.getStringList('absorbing_manual_removes')).toSet();
    _absorbingBookIds =
        (await ScopedPrefs.getStringList('absorbing_seen_ids')).toList();
    final fresh = await ScopedPrefs.getString('absorbing_fresh_front');
    _freshQueuedFrontKey = (fresh != null && fresh.isNotEmpty) ? fresh : null;
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
      'absorbing_finished_manual_adds',
      _finishedManualAbsorbAdds.toList(),
    );
    await ScopedPrefs.setStringList(
        'absorbing_manual_removes', _manualAbsorbRemoves.toList());
    await ScopedPrefs.setStringList(
        'absorbing_seen_ids', _absorbingBookIds.toList());
    await ScopedPrefs.setStringList('absorbing_item_cache_v2',
        _absorbingItemCache.values.map((e) => jsonEncode(e)).toList());
  }

  void _pruneRemotelyFinishedBooks(Iterable<String> keys) {
    var changed = false;
    final player = AudioPlayerService();
    final activeKey = player.currentEpisodeId != null
        ? '${player.currentItemId}-${player.currentEpisodeId}'
        : player.currentItemId;
    for (final key in keys) {
      if (key.length > 36 ||
          shouldIncludeBookInAbsorbing(
            isFinished: (this as LibraryProvider).isItemFinishedByKey(key),
            addedAfterFinish: _finishedManualAbsorbAdds.contains(key),
            isActive: player.hasBook && key == activeKey,
          )) {
        continue;
      }
      changed = _absorbingBookIds.remove(key) || changed;
      changed = _absorbingItemCache.remove(key) != null || changed;
      changed = _manualAbsorbAdds.remove(key) || changed;
      changed = _finishedManualAbsorbAdds.remove(key) || changed;
    }
    if (changed) unawaited(_saveManualAbsorbing());
  }

  Future<void> _updateAbsorbingCache() async {
    final allowedKeys = <String>{};
    final showEntities = <String, Map<String, dynamic>>{};

    final continueSeriesKeys = <String>[];

    final existingIds = Set<String>.from(_absorbingBookIds);
    final player = AudioPlayerService();
    final activeKey = player.currentEpisodeId != null
        ? '${player.currentItemId}-${player.currentEpisodeId}'
        : player.currentItemId;
    bool shouldIncludeBook(String key) => shouldIncludeBookInAbsorbing(
          isFinished: (this as LibraryProvider).isItemFinishedByKey(key),
          addedAfterFinish: _finishedManualAbsorbAdds.contains(key),
          isActive: player.hasBook && key == activeKey,
        );

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
              if (!shouldIncludeBook(itemId)) continue;
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
          libraryId: cached['libraryId'] as String?,
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
        // The playing episode goes back to the front it held when it started;
        // everything else joins at the end so the queue order is untouched.
        final isActive = player.hasBook && key == activeKey;
        if (isActive) {
          debugPrint('[Absorbing] backfilled playing episode $key at front');
        }
        _absorbingIdsAdd(key, atFront: isActive);
        _absorbingItemCache[key] = syntheticEntry;
        allowedKeys.add(key);
      }

      _enrichEpisodeTitles();
    }

    final toRemove = <String>[];
    for (final key in _absorbingBookIds) {
      if (key.length <= 36 && !shouldIncludeBook(key)) {
        toRemove.add(key);
        continue;
      }
      if (allowedKeys.contains(key)) continue;
      if (_manualAbsorbAdds.contains(key)) continue;
      final hasProgress = key.length > 36
          ? _progressMap.containsKey(key)
          : _progressMap.keys.any((k) => k == key || k.startsWith('$key-'));
      if (!hasProgress) {
        // A just-started episode has no fetched progress yet, and the sections
        // can still name an older recentEpisode - evicting it here dumps the
        // playing item to the end of the queue once the backfill re-adds it.
        if (player.hasBook && key == activeKey) {
          debugPrint(
              '[Absorbing] sweep spared the playing item $key (no progress fetched yet)');
          continue;
        }
        toRemove.add(key);
      }
    }
    for (final id in toRemove) {
      _absorbingBookIds.remove(id);
      _absorbingItemCache.remove(id);
      if (id.length <= 36 &&
          (this as LibraryProvider).isItemFinishedByKey(id) &&
          !_finishedManualAbsorbAdds.contains(id)) {
        _manualAbsorbAdds.remove(id);
      }
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
      _absorbingIdsAdd(entry.key,
          atFront: player.hasBook && entry.key == activeKey);
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
          // Synthetic merged-library entries are built from show maps that
          // may lack a libraryId; without it the card controls and playback
          // fall back to the global skip amounts.
          final cachedLibId = cached['libraryId'] as String?;
          if (cachedLibId == null || cachedLibId.isEmpty) {
            cached['libraryId'] = fullItem['libraryId'];
          }
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
    if ((this as LibraryProvider).isItemFinishedByKey(itemId)) {
      _finishedManualAbsorbAdds.add(itemId);
    } else {
      _finishedManualAbsorbAdds.remove(itemId);
    }
    _manualAbsorbRemoves.remove(itemId);
    _absorbingIdsAdd(itemId);
    await _saveManualAbsorbing();
    notifyListeners();
    unawaited(_catchUpQueueAutoDownloads());
  }

  Future<void> addToAbsorbingQueue(String itemId) async {
    _manualAbsorbAdds.add(itemId);
    if ((this as LibraryProvider).isItemFinishedByKey(itemId)) {
      _finishedManualAbsorbAdds.add(itemId);
    } else {
      _finishedManualAbsorbAdds.remove(itemId);
    }
    _manualAbsorbRemoves.remove(itemId);
    _absorbingIdsAdd(itemId, atFront: false);
    await _saveManualAbsorbing();
    notifyListeners();
    unawaited(_catchUpQueueAutoDownloads());
  }

  Future<void> reorderAbsorbing(List<String> newOrder) async {
    _absorbingBookIds = newOrder;
    setFreshQueuedFront(null);
    await _saveManualAbsorbing();
    notifyListeners();
    unawaited(_catchUpQueueAutoDownloads());
  }

  Future<void> _prepareAbsorbingForPlayback(
    String key,
    double duration,
  ) async {
    final self = this as LibraryProvider;
    final wasFinished = self.isItemFinishedByKey(key);

    if (wasFinished) {
      _finishedManualAbsorbAdds.remove(key);
      _manualAbsorbAdds.remove(key);
      self.resetProgressFor(key);
    }

    unblockFromAbsorbing(key);
    if (!wasFinished) return;

    try {
      await _saveManualAbsorbing();
      final sync = ProgressSyncService();
      final saved = await sync.getLocal(key);
      final savedDuration = (saved?['duration'] as num?)?.toDouble() ?? 0;
      final savedSpeed = (saved?['speed'] as num?)?.toDouble() ?? 1;
      await sync.saveLocal(
        itemId: key,
        currentTime: 0,
        duration: duration > 0 ? duration : savedDuration,
        speed: savedSpeed,
        isFinished: false,
      );
      if (_api != null && !isOffline) {
        unawaited(sync.syncToServer(api: _api!, itemId: key));
      }
    } catch (e) {
      debugPrint('[Absorbing] Failed to prepare finished item replay: $e');
    }
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
    _finishedManualAbsorbAdds.remove(key);
    _absorbingBookIds.remove(key);
    _absorbingItemCache.remove(key);
    await _saveManualAbsorbing();
    notifyListeners();
    unawaited(_catchUpQueueAutoDownloads());
  }

  void markFinishedLocally(String itemId,
      {bool skipRefresh = false,
      bool skipAutoAdvance = false,
      bool fromRemote = false}) {
    _resetItems.remove(itemId);
    final existing = _progressMap[itemId] ?? {};
    if (itemId.length > 36 && existing['isFinished'] != true) {
      nudgeUnfinishedEpisodeCount(itemId.substring(0, 36), -1);
    }
    _progressMap[itemId] = {...existing, 'isFinished': true};
    _localProgressOverrides[itemId] = 1.0;
    _lastFinishedItemId = itemId;
    _locallyFinishedItems.add(itemId);
    // Stats widget shows "books finished this year"; force a refresh so it
    // reflects the new count without waiting on the 15-min throttle.
    HomeWidgetService().refreshStats(force: true);
    if (fromRemote) {
      // Finished on another device: leave Absorbing right away, same as when
      // the book isn't loaded - don't linger until the next play press
      _absorbingBookIds.remove(itemId);
    } else if (_absorbingBookIds.remove(itemId)) {
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
        } else if (mode == 'playlist') {
          _advanceInPlaylist(itemId);
        } else if (mode == 'collection') {
          _advanceInCollection(itemId);
        }
      });
    }

    _checkRollingDownloads(itemId);
    unawaited(_catchUpQueueAutoDownloads());

    // The delete-absorbed-downloads setting promises that finishing an item
    // on the web or another device never deletes the download on this one.
    if (!fromRemote && DownloadService().isDownloaded(itemId)) {
      PlayerSettings.getRollingDownloadDeleteFinished().then((delete) {
        if (!delete) return;
        DownloadService().deleteDownload(itemId, skipStopCheck: true);
        _showRollingToast(_l()?.lpDeletedFinishedDownload ?? 'Deleted finished download',
            icon: Icons.delete_outline_rounded);
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
          libraryId: fullItem['libraryId'] as String?,
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
    final bookMode = await PlayerSettings.getBookQueueMode();
    final podMode = await PlayerSettings.getPodcastQueueMode();

    final finishedCached = _absorbingItemCache[finishedKey];
    final finishedLibId = finishedCached?['libraryId'] as String?;
    final finishedIsPodcast = finishedKey.length > 36;

    final finishedIdx = _absorbingBookIds.indexOf(finishedKey);
    final startIdx = finishedIdx >= 0 ? finishedIdx + 1 : 0;

    debugPrint('[Queue] _manualQueueAdvance: finished=$finishedKey '
        '(${finishedIsPodcast ? "podcast" : "book"}, lib=$finishedLibId) '
        'merged=$merged bookMode=$bookMode podMode=$podMode '
        'queueLen=${_absorbingBookIds.length} startIdx=$startIdx');

    for (int i = startIdx; i < _absorbingBookIds.length; i++) {
      final key = _absorbingBookIds[i];
      if ((this as LibraryProvider).isItemFinishedByKey(key)) {
        debugPrint('[Queue]   [$i] $key SKIP - already finished');
        continue;
      }

      final candidateIsPodcast = key.length > 36;
      final candidateMode = candidateIsPodcast ? podMode : bookMode;
      if (candidateMode == 'off') {
        debugPrint('[Queue]   [$i] $key SKIP - ${candidateIsPodcast ? "podcast" : "book"} mode is off');
        continue;
      }

      if (!merged && candidateIsPodcast != finishedIsPodcast) {
        debugPrint('[Queue]   [$i] $key SKIP - cross-type (unified off, finished=${finishedIsPodcast ? "podcast" : "book"} candidate=${candidateIsPodcast ? "podcast" : "book"})');
        continue;
      }

      final cached = _absorbingItemCache[key];
      if (cached == null) {
        debugPrint('[Queue]   [$i] $key SKIP - no cache entry');
        continue;
      }

      if (!merged && finishedLibId != null) {
        final candidateLibId = cached['libraryId'] as String?;
        if (candidateLibId != null && candidateLibId != finishedLibId) {
          debugPrint('[Queue]   [$i] $key SKIP - cross-library (finished=$finishedLibId candidate=$candidateLibId)');
          continue;
        }
      }

      debugPrint('[Queue]   [$i] $key PICK - ${candidateIsPodcast ? "podcast" : "book"} (lib=${cached['libraryId']})');

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
          libraryId: cached['libraryId'] as String?,
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
          libraryId: cached['libraryId'] as String?,
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
      if (_manualAbsorbRemoves.contains(key)) continue;
      if ((this as LibraryProvider).isItemFinishedByKey(key)) continue;
      final (sid, seq) = _StateMixin._extractSeries(entry.value);
      if (sid != seriesId || seq == null || seq <= currentSeq) continue;
      candidates[seq] = MapEntry(key, entry.value);
    }

    for (final dlInfo in DownloadService().downloadedItems) {
      final id = dlInfo.itemId;
      if (id == finishedBookId || id.length > 36) continue;
      if (_manualAbsorbRemoves.contains(id)) continue;
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
        if (_manualAbsorbRemoves.contains(id)) continue;
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

    final mode = await PlayerSettings.getBookQueueMode();
    if (mode == 'auto_next') {
      _absorbingIdsAdd(nextKey, afterKey: finishedBookId);
    } else {
      _absorbingIdsAdd(nextKey, atFront: false);
    }
    _absorbingItemCache[nextKey] = next.value;
    _manualAbsorbAdds.add(nextKey);
    _saveManualAbsorbing();
    notifyListeners();
    debugPrint('[Absorbing] Auto-added next series book: $nextKey (seq ${nextSeq.first})');

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
      libraryId: nextData['libraryId'] as String?,
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
        if (_manualAbsorbRemoves.contains(id)) continue;
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
        libraryId: nextData['libraryId'] as String?,
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
        libraryId: nextData['libraryId'] as String?,
      );
    });
  }

  // ── Playlist queue mode ──────────────────────────────────────────────

  String _playlistItemKey(Map<String, dynamic> item) {
    final lid = item['libraryItemId'] as String? ?? '';
    final eid = item['episodeId'] as String?;
    return queueItemKey(libraryItemId: lid, episodeId: eid);
  }

  /// Index of the first playlist item that isn't marked finished. Returns -1
  /// if every item is finished or the list is empty.
  int firstUnfinishedPlaylistIndex(List<dynamic> items) {
    final self = this as LibraryProvider;
    for (var i = 0; i < items.length; i++) {
      final m = items[i];
      if (m is! Map<String, dynamic>) continue;
      final key = _playlistItemKey(m);
      if (key.isEmpty) continue;
      if (!self.isItemFinishedByKey(key)) return i;
    }
    return -1;
  }

  Future<Map<String, dynamic>?> _getPlaylistById(String playlistId) async {
    final cached = _playlists.cast<Map<String, dynamic>>().where(
      (p) => p['id'] == playlistId,
    ).firstOrNull;
    if (cached != null) return cached;
    if (_api == null) return null;
    try {
      return await _api!.getPlaylist(playlistId);
    } catch (e) {
      debugPrint('[Playlist] getPlaylist($playlistId) failed: $e');
      return null;
    }
  }

  Future<bool> _playPlaylistItem(Map<String, dynamic> playlistItem) async {
    final api = _api;
    if (api == null) return false;
    final libraryItemId = playlistItem['libraryItemId'] as String? ?? '';
    if (libraryItemId.isEmpty) return false;
    final episodeId = playlistItem['episodeId'] as String?;
    final libraryItem =
        playlistItem['libraryItem'] as Map<String, dynamic>? ?? const {};
    final media = libraryItem['media'] as Map<String, dynamic>? ?? const {};
    final metadata = media['metadata'] as Map<String, dynamic>? ?? const {};
    String? playbackError;

    if (episodeId != null) {
      Map<String, dynamic>? episode =
          playlistItem['episode'] as Map<String, dynamic>?;
      episode ??= (media['episodes'] as List<dynamic>? ?? const [])
          .cast<Map<String, dynamic>>()
          .where((e) => e['id'] == episodeId)
          .firstOrNull;
      final epDuration = (episode?['duration'] as num?)?.toDouble() ??
          ((episode?['audioFile'] as Map<String, dynamic>?)?['duration']
                  as num?)
              ?.toDouble() ??
          0.0;
      playbackError = await AudioPlayerService().playItem(
        api: api,
        itemId: libraryItemId,
        title: metadata['title'] as String? ?? '',
        author: metadata['author'] as String? ??
            metadata['authorName'] as String? ??
            '',
        coverUrl: getCoverUrl(libraryItemId),
        totalDuration: epDuration,
        chapters: const [],
        episodeId: episodeId,
        episodeTitle: episode?['title'] as String?,
        libraryId: libraryItem['libraryId'] as String?,
      );
    } else {
      final duration = (media['duration'] as num?)?.toDouble() ?? 0;
      final chapters = media['chapters'] as List<dynamic>? ?? const [];
      playbackError = await AudioPlayerService().playItem(
        api: api,
        itemId: libraryItemId,
        title: metadata['title'] as String? ?? '',
        author: metadata['authorName'] as String? ?? '',
        coverUrl: getCoverUrl(libraryItemId),
        totalDuration: duration,
        chapters: chapters,
        libraryId: libraryItem['libraryId'] as String?,
      );
    }
    return playbackError == null;
  }

  /// Start playing the first unfinished item in [playlistId]. Returns true if
  /// playback started. Used by the "Play playlist" entry point.
  Future<bool> playPlaylistFromStart(String playlistId) async {
    final pl = await _getPlaylistById(playlistId);
    if (pl == null) return false;
    final items = (pl['items'] as List<dynamic>?) ?? const [];
    final idx = firstUnfinishedPlaylistIndex(items);
    if (idx < 0) return false;
    final item = items[idx] as Map<String, dynamic>? ?? const {};
    return _playPlaylistItem(item);
  }

  Future<bool?> _isInQueuePlaylist(
    String playlistId,
    String libraryItemId, {
    String? episodeId,
  }) async {
    final pl = await _getPlaylistById(playlistId);
    if (pl == null) return null;
    final items = pl['items'];
    if (items is! List) return null;
    final target =
        episodeId != null ? '$libraryItemId-$episodeId' : libraryItemId;
    for (final m in items) {
      if (m is! Map<String, dynamic>) return null;
      final key = _playlistItemKey(m);
      if (key.isEmpty) return null;
      if (key == target) return true;
    }
    return false;
  }

  /// Returns true if [libraryItemId] (+ optional [episodeId]) appears in the
  /// active queue playlist's items.
  Future<bool> isInActiveQueuePlaylist(String libraryItemId,
      {String? episodeId}) async {
    final playlistId = await PlayerSettings.getQueuePlaylistId();
    if (playlistId == null) return false;
    final membership = await _isInQueuePlaylist(
      playlistId,
      libraryItemId,
      episodeId: episodeId,
    );
    return membership ?? false;
  }

  Future<void> _advanceInPlaylist(String finishedKey) async {
    final playlistId = await PlayerSettings.getQueuePlaylistId();
    if (playlistId == null) {
      debugPrint('[AutoAdvance] Playlist mode but no queuePlaylistId; no-op');
      return;
    }
    final pl = await _getPlaylistById(playlistId);
    if (pl == null) {
      debugPrint('[AutoAdvance] Playlist $playlistId missing; exiting playlist queue mode');
      await PlayerSettings.clearQueueModePlaylistIfActive(playlistId);
      return;
    }
    final items = (pl['items'] as List<dynamic>?) ?? const [];
    int idx = -1;
    for (var i = 0; i < items.length; i++) {
      final m = items[i];
      if (m is! Map<String, dynamic>) continue;
      if (_playlistItemKey(m) == finishedKey) { idx = i; break; }
    }
    if (idx < 0) {
      debugPrint('[AutoAdvance] Finished item $finishedKey not in playlist $playlistId');
      return;
    }
    final self = this as LibraryProvider;
    for (var i = idx + 1; i < items.length; i++) {
      final m = items[i];
      if (m is! Map<String, dynamic>) continue;
      final key = _playlistItemKey(m);
      if (key.isEmpty) continue;
      if (self.isItemFinishedByKey(key)) continue;
      final ok = await _playPlaylistItem(m);
      if (ok) {
        debugPrint('[AutoAdvance] Playlist advanced to $key (index $i)');
        return;
      }
    }
    debugPrint('[AutoAdvance] Playlist $playlistId exhausted after $finishedKey');
  }

  // ── Collection queue mode (books only) ───────────────────────────────
  // Collections aren't a native queue in ABS, so we drive them through the
  // same machinery as playlists: a collection's books are normalized into the
  // playlist-item shape and run through _playPlaylistItem / the finished-item
  // advance, keyed on `queueCollectionId` instead of `queuePlaylistId`.

  Future<Map<String, dynamic>?> _getCollectionById(String collectionId) async {
    // Prefer the cached collection (works offline) before hitting the API,
    // mirroring _getPlaylistById.
    final cached = _collections.cast<Map<String, dynamic>>().where(
      (c) => c['id'] == collectionId,
    ).firstOrNull;
    if (cached != null) return cached;
    if (_api == null) return null;
    try {
      return await _api!.getCollection(collectionId);
    } catch (e) {
      debugPrint('[Collection] getCollection($collectionId) failed: $e');
      return null;
    }
  }

  List<Map<String, dynamic>> _collectionItems(Map<String, dynamic> collection) {
    final books = (collection['books'] as List<dynamic>?) ?? const [];
    return books
        .whereType<Map<String, dynamic>>()
        .map((b) => {'libraryItemId': b['id'] as String? ?? '', 'libraryItem': b})
        .where((m) => (m['libraryItemId'] as String).isNotEmpty)
        .toList();
  }

  Map<String, dynamic> _queueDownloadItem(
    String key,
    Map<String, dynamic> libraryItem, {
    Map<String, dynamic>? episode,
  }) {
    final isPodcast = key.length > 36;
    return {
      'libraryItemId': isPodcast ? key.substring(0, 36) : key,
      if (isPodcast) 'episodeId': key.substring(37),
      'libraryItem': libraryItem,
      if (episode != null) 'episode': episode,
    };
  }

  /// Returns the current item and the items after it in the active queue's
  /// actual playback order. Every entry uses the same shape as a playlist item.
  Future<List<Map<String, dynamic>>> _queueItemsForDownload(
    String currentKey,
    String mode,
    ApiService api, {
    required int limit,
    required String bookMode,
    required String podcastMode,
    required bool merged,
    required String? queueSourceId,
    required String? podcastAdvanceDir,
    required bool Function() isStale,
  }) async {
    final self = this as LibraryProvider;

    if (mode == 'manual') {
      final currentIsPodcast = currentKey.length > 36;

      Future<Map<String, dynamic>?> resolveItem(String key) async {
        final cached = _absorbingItemCache[key];
        if (cached != null) return cached;
        final isPodcast = key.length > 36;
        final libraryItemId = isPodcast ? key.substring(0, 36) : key;
        final fetched = await api.getLibraryItem(libraryItemId);
        if (fetched == null || isStale()) return null;
        final resolved = Map<String, dynamic>.from(fetched);
        resolved['_absorbingKey'] = key;
        if (isPodcast) {
          final episodeId = key.substring(37);
          final media = resolved['media'] as Map<String, dynamic>? ?? const {};
          for (final episode
              in (media['episodes'] as List<dynamic>? ?? const [])) {
            if (episode is Map<String, dynamic> &&
                episode['id'] == episodeId) {
              resolved['recentEpisode'] = episode;
              break;
            }
          }
        }
        return resolved;
      }

      Map<String, dynamic>? currentItem = _absorbingItemCache[currentKey];
      if (!merged && currentItem == null) {
        currentItem = await resolveItem(currentKey);
        if (isStale()) return const [];
      }
      final currentLibraryId = currentItem?['libraryId'] as String?;
      final keys = manualQueueTail(
        items: _absorbingBookIds,
        currentKey: currentKey,
        keyOf: (key) => key,
        isFinished: self.isItemFinishedByKey,
        isPodcast: (key) => key.length > 36,
        queueMode: (key) => key.length > 36 ? podcastMode : bookMode,
        libraryId: (key) =>
            _absorbingItemCache[key]?['libraryId'] as String?,
        merged: merged,
        currentIsPodcast: currentIsPodcast,
        currentLibraryId: currentLibraryId,
      );
      final result = <Map<String, dynamic>>[];
      final seen = <String>{};

      for (final key in keys) {
        if (result.length >= limit || isStale()) break;
        if (!seen.add(key) || self.isItemFinishedByKey(key)) continue;
        final cached = key == currentKey && currentItem != null
            ? currentItem
            : await resolveItem(key);
        if (cached == null || isStale()) continue;
        if (!merged && currentLibraryId != null) {
          final candidateLibraryId = cached['libraryId'] as String?;
          if (candidateLibraryId != null &&
              candidateLibraryId != currentLibraryId) {
            continue;
          }
        }
        result.add(_queueDownloadItem(
          key,
          cached,
          episode: cached['recentEpisode'] as Map<String, dynamic>?,
        ));
      }
      return result;
    }

    if (mode == 'playlist') {
      final playlistId = queueSourceId;
      if (playlistId == null) {
        debugPrint('[QueueDL] playlist: no active playlist id');
        return const [];
      }
      Map<String, dynamic>? playlist = _playlists
          .whereType<Map<String, dynamic>>()
          .where((item) => item['id'] == playlistId)
          .firstOrNull;
      final fromCache = playlist != null;
      playlist ??= await api.getPlaylist(playlistId);
      if (playlist == null) {
        debugPrint('[QueueDL] playlist: $playlistId not found (cache or api)');
        return const [];
      }
      if (isStale()) return const [];
      final items = (playlist['items'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .toList();
      final tail = queueTailFrom(
        items: items,
        currentKey: currentKey,
        keyOf: _playlistItemKey,
      );
      debugPrint(
          '[QueueDL] playlist $playlistId (${fromCache ? 'cached' : 'fetched'}): ${items.length} items, tail=${tail.length} from $currentKey');
      if (tail.isEmpty && items.isNotEmpty) {
        debugPrint(
            '[QueueDL] playing item not in playlist - member keys: ${items.map(_playlistItemKey).join(', ')}');
      }
      return tail;
    }

    if (mode == 'collection') {
      final collectionId = queueSourceId;
      if (collectionId == null) {
        debugPrint('[QueueDL] collection: no active collection id');
        return const [];
      }
      Map<String, dynamic>? collection = _collections
          .whereType<Map<String, dynamic>>()
          .where((item) => item['id'] == collectionId)
          .firstOrNull;
      final fromCache = collection != null;
      collection ??= await api.getCollection(collectionId);
      if (collection == null) {
        debugPrint(
            '[QueueDL] collection: $collectionId not found (cache or api)');
        return const [];
      }
      if (isStale()) return const [];
      final items = _collectionItems(collection);
      final tail = queueTailFrom(
        items: items,
        currentKey: currentKey,
        keyOf: _playlistItemKey,
      );
      debugPrint(
          '[QueueDL] collection $collectionId (${fromCache ? 'cached' : 'fetched'}): ${items.length} items, tail=${tail.length} from $currentKey');
      if (tail.isEmpty && items.isNotEmpty) {
        debugPrint(
            '[QueueDL] playing item not in collection - member keys: ${items.map(_playlistItemKey).join(', ')}');
      }
      return tail;
    }

    if (mode != 'auto_next') return const [];

    if (currentKey.length > 36) {
      final showId = currentKey.substring(0, 36);
      final currentEpisodeId = currentKey.substring(37);
      Map<String, dynamic>? show;
      for (final cached in _absorbingItemCache.values) {
        if (cached['id'] != showId) continue;
        final episodes = (cached['media'] as Map<String, dynamic>?)?['episodes']
            as List<dynamic>?;
        if (episodes != null && episodes.isNotEmpty) {
          show = cached;
          break;
        }
      }
      show ??= await api.getLibraryItem(showId);
      if (show == null || isStale()) return const [];

      final media = show['media'] as Map<String, dynamic>? ?? const {};
      final episodes = (media['episodes'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .where((episode) =>
              (episode['id'] as String? ?? '').isNotEmpty)
          .toList();
      final tail = podcastQueueTail(
        episodes: episodes,
        currentEpisodeId: currentEpisodeId,
        idOf: (episode) => episode['id'] as String? ?? '',
        publishedAt: (episode) =>
            (episode['publishedAt'] as num?)?.toInt() ?? 0,
        newestFirst: podcastAdvanceDir == 'newest_first',
      );
      return tail.map((episode) {
        return _queueDownloadItem(
          '$showId-${episode['id']}',
          show!,
          episode: episode,
        );
      }).toList();
    }

    var current = _itemDataWithSeries(currentKey);
    var (seriesId, currentSequence) = current != null
        ? _StateMixin._extractSeries(current)
        : (null, null);
    if (seriesId == null || currentSequence == null) {
      current = await api.getLibraryItem(currentKey);
      if (current != null) {
        (seriesId, currentSequence) = _StateMixin._extractSeries(current);
      }
    }
    if (isStale() ||
        current == null ||
        seriesId == null ||
        currentSequence == null) {
      return const [];
    }

    final libraryId = current['libraryId'] as String? ?? _selectedLibraryId;
    if (libraryId == null) {
      return [_queueDownloadItem(currentKey, current)];
    }

    List<dynamic> books;
    try {
      books = await api.getBooksBySeries(
        libraryId,
        seriesId,
        limit: 100,
      );
    } catch (error) {
      debugPrint('[QueueDownload] Series fetch failed: $error');
      return [_queueDownloadItem(currentKey, current)];
    }
    if (isStale()) return const [];

    final candidates = seriesQueueTail(
      current: current,
      books: books.whereType<Map<String, dynamic>>().where((book) {
        final id = book['id'] as String?;
        return id != null && !_manualAbsorbRemoves.contains(id);
      }),
      currentKey: currentKey,
      currentSeriesId: seriesId,
      currentSequence: currentSequence,
      keyOf: (book) => book['id'] as String? ?? '',
      seriesId: (book) => _StateMixin._extractSeries(book).$1,
      sequence: (book) => _StateMixin._extractSeries(book).$2,
    );
    return candidates.map((book) {
      return _queueDownloadItem(
        book['id'] as String? ?? currentKey,
        book,
      );
    }).toList();
  }

  /// Start playing the first unfinished book in [collectionId].
  Future<bool> playCollectionFromStart(String collectionId) async {
    final c = await _getCollectionById(collectionId);
    if (c == null) return false;
    final items = _collectionItems(c);
    final idx = firstUnfinishedPlaylistIndex(items);
    if (idx < 0) return false;
    return _playPlaylistItem(items[idx]);
  }

  Future<bool?> _isInQueueCollection(
    String collectionId,
    String libraryItemId, {
    String? episodeId,
  }) async {
    final c = await _getCollectionById(collectionId);
    if (c == null) return null;
    final books = c['books'];
    if (books is! List) return null;
    final target =
        episodeId != null ? '$libraryItemId-$episodeId' : libraryItemId;
    for (final book in books) {
      if (book is! Map<String, dynamic>) return null;
      final id = book['id'] as String? ?? '';
      if (id.isEmpty) return null;
      if (id == target) return true;
    }
    return false;
  }

  Future<bool> isInActiveQueueCollection(String libraryItemId,
      {String? episodeId}) async {
    final collectionId = await PlayerSettings.getQueueCollectionId();
    if (collectionId == null) return false;
    final membership = await _isInQueueCollection(
      collectionId,
      libraryItemId,
      episodeId: episodeId,
    );
    return membership ?? false;
  }

  Future<void> _clearStaleSourceQueueModeForCurrentPlayback() async {
    final cleanupGeneration = ++_staleSourceCleanupGeneration;
    final player = AudioPlayerService();
    final libraryItemId = player.currentItemId;
    if (libraryItemId == null) return;
    final episodeId = player.currentEpisodeId;

    bool playerStillMatches() =>
        cleanupGeneration == _staleSourceCleanupGeneration &&
        player.currentItemId == libraryItemId &&
        player.currentEpisodeId == episodeId;

    final bookMode = await PlayerSettings.getBookQueueMode();
    if (!playerStillMatches()) return;
    final podcastMode = await PlayerSettings.getPodcastQueueMode();
    if (!playerStillMatches()) return;
    final activeMode = episodeId == null ? bookMode : podcastMode;

    if (activeMode == 'playlist') {
      if (bookMode != 'playlist' || podcastMode != 'playlist') return;
      final playlistId = await PlayerSettings.getQueuePlaylistId();
      if (playlistId == null || !playerStillMatches()) return;
      final membership = await _isInQueuePlaylist(
        playlistId,
        libraryItemId,
        episodeId: episodeId,
      );
      if (membership != false || !playerStillMatches()) return;

      final latestBookMode = await PlayerSettings.getBookQueueMode();
      if (!playerStillMatches()) return;
      final latestPodcastMode = await PlayerSettings.getPodcastQueueMode();
      if (!playerStillMatches()) return;
      final latestPlaylistId = await PlayerSettings.getQueuePlaylistId();
      if (!playerStillMatches() ||
          latestBookMode != bookMode ||
          latestPodcastMode != podcastMode ||
          latestPlaylistId != playlistId) {
        return;
      }

      final cleared =
          await PlayerSettings.clearQueueModePlaylistIfActive(playlistId);
      if (!cleared) return;
      if (!playerStillMatches()) return;
      debugPrint(
        '[Queue] Cleared playlist mode because $libraryItemId is outside $playlistId',
      );
      unawaited(_catchUpQueueAutoDownloads());
      return;
    }

    if (activeMode != 'collection' || episodeId != null) return;
    final collectionId = await PlayerSettings.getQueueCollectionId();
    if (collectionId == null || !playerStillMatches()) return;
    final membership = await _isInQueueCollection(
      collectionId,
      libraryItemId,
    );
    if (membership != false || !playerStillMatches()) return;

    final latestBookMode = await PlayerSettings.getBookQueueMode();
    if (!playerStillMatches()) return;
    final latestCollectionId = await PlayerSettings.getQueueCollectionId();
    if (!playerStillMatches() ||
        latestBookMode != bookMode ||
        latestCollectionId != collectionId) {
      return;
    }

    final cleared =
        await PlayerSettings.clearQueueModeCollectionIfActive(collectionId);
    if (!cleared) return;
    if (!playerStillMatches()) return;
    debugPrint(
      '[Queue] Cleared collection mode because $libraryItemId is outside $collectionId',
    );
    unawaited(_catchUpQueueAutoDownloads());
  }

  Future<void> _advanceInCollection(String finishedKey) async {
    final collectionId = await PlayerSettings.getQueueCollectionId();
    if (collectionId == null) return;
    final c = await _getCollectionById(collectionId);
    if (c == null) {
      await PlayerSettings.clearQueueModeCollectionIfActive(collectionId);
      return;
    }
    final items = _collectionItems(c);
    int idx = -1;
    for (var i = 0; i < items.length; i++) {
      if (_playlistItemKey(items[i]) == finishedKey) { idx = i; break; }
    }
    if (idx < 0) return;
    final self = this as LibraryProvider;
    for (var i = idx + 1; i < items.length; i++) {
      final key = _playlistItemKey(items[i]);
      if (key.isEmpty) continue;
      if (self.isItemFinishedByKey(key)) continue;
      if (await _playPlaylistItem(items[i])) return;
    }
  }

  /// Returns the (seriesId, sequence) for [item]. Public wrapper around the
  /// private `_StateMixin._extractSeries` so sheets in other files can use
  /// it without reaching into private mixins.
  (String?, double?) extractSeries(Map<String, dynamic> item) =>
      _StateMixin._extractSeries(item);

  // ── Public fetch helpers for sheets ─────────────────────────────────

  Future<Map<String, dynamic>?> fetchLibraryItem(String itemId) async {
    if (_api == null) return null;
    final id = itemId.length > 36 ? itemId.substring(0, 36) : itemId;
    return _api!.getLibraryItem(id);
  }

  Future<List<Map<String, dynamic>>> fetchBooksBySeries(
      String libraryId, String seriesId) async {
    if (_api == null) return const [];
    final books = await _api!.getBooksBySeries(libraryId, seriesId, limit: 100);
    return books.whereType<Map<String, dynamic>>().toList();
  }

  Future<Map<String, dynamic>?> fetchPlaylistById(String playlistId) =>
      _getPlaylistById(playlistId);

  Future<Map<String, dynamic>?> fetchCollectionById(String collectionId) =>
      _getCollectionById(collectionId);

  // ── Up-next preview ─────────────────────────────────────────────────

  String? _playlistItemTitle(Map<String, dynamic> item) {
    final libraryItem = item['libraryItem'] as Map<String, dynamic>? ?? const {};
    final media = libraryItem['media'] as Map<String, dynamic>? ?? const {};
    final metadata = media['metadata'] as Map<String, dynamic>? ?? const {};
    final epId = item['episodeId'] as String?;
    if (epId != null) {
      final ep = item['episode'] as Map<String, dynamic>? ??
          (media['episodes'] as List<dynamic>? ?? const [])
              .cast<Map<String, dynamic>>()
              .where((e) => e['id'] == epId)
              .firstOrNull;
      return ep?['title'] as String? ?? metadata['title'] as String?;
    }
    return metadata['title'] as String?;
  }

  String? _entryTitle(Map<String, dynamic> entry) {
    final media = entry['media'] as Map<String, dynamic>? ?? const {};
    final metadata = media['metadata'] as Map<String, dynamic>? ?? const {};
    final ep = entry['recentEpisode'] as Map<String, dynamic>?;
    if (ep != null) return ep['title'] as String? ?? metadata['title'] as String?;
    return metadata['title'] as String?;
  }

  /// Returns metadata for the item that would auto-advance next in manual
  /// queue mode, formatted for AudioPlayerService's pre-buffer mechanism.
  /// Returns null when nothing's queued, mode isn't manual, or the next item
  /// isn't downloaded (MVP only pre-buffers local files).
  Future<Map<String, dynamic>?> peekNextQueueItemForPreBuffer(
      String currentItemId) async {
    final self = this as LibraryProvider;
    final isPodCurrent = currentItemId.length > 36;
    final mode = isPodCurrent
        ? await PlayerSettings.getPodcastQueueMode()
        : await PlayerSettings.getBookQueueMode();
    if (mode != 'manual') return null;

    final bookMode = await PlayerSettings.getBookQueueMode();
    final podMode = await PlayerSettings.getPodcastQueueMode();
    final merged = await PlayerSettings.getMergeAbsorbingLibraries();
    final currentLibId =
        _absorbingItemCache[currentItemId]?['libraryId'] as String?;
    final idx = _absorbingBookIds.indexOf(currentItemId);
    final start = idx >= 0 ? idx + 1 : 0;

    for (var i = start; i < _absorbingBookIds.length; i++) {
      final key = _absorbingBookIds[i];
      if (self.isItemFinishedByKey(key)) continue;
      final candidateIsPodcast = key.length > 36;
      final candidateMode = candidateIsPodcast ? podMode : bookMode;
      if (candidateMode == 'off') continue;
      if (!merged && candidateIsPodcast != isPodCurrent) continue;
      final cached = _absorbingItemCache[key];
      if (cached == null) continue;
      if (!merged && currentLibId != null) {
        final candidateLibId = cached['libraryId'] as String?;
        if (candidateLibId != null && candidateLibId != currentLibId) continue;
      }

      final itemIdRaw = candidateIsPodcast ? key.substring(0, 36) : key;
      final episodeIdRaw = candidateIsPodcast ? key.substring(37) : null;

      // Try downloaded first; fall back to cached session for streaming so
      // the pre-buffer + native handover path works for non-downloaded books.
      final localPaths = DownloadService().getLocalPaths(key);
      List<Map<String, dynamic>>? audioTracks;
      Map<String, String>? audioHeaders;
      if (localPaths == null || localPaths.isEmpty) {
        final api = self._api;
        if (api == null) {
          debugPrint('[PreBuffer] Next item $key no api context, skip');
          return null;
        }
        final cachedSession = await SessionCache.load(
          itemId: itemIdRaw,
          episodeId: episodeIdRaw,
        );
        final tracks = cachedSession?['audioTracks'] as List<dynamic>?;
        if (tracks == null || tracks.isEmpty) {
          debugPrint('[PreBuffer] Next item $key not downloaded and no cached session, skip');
          return null;
        }
        if (tracks.length != 1) {
          debugPrint('[PreBuffer] Next item $key streaming multi-track, skip (MVP)');
          return null;
        }
        audioTracks = tracks.map<Map<String, dynamic>>((t) {
          final track = t as Map<String, dynamic>;
          final contentUrl = track['contentUrl'] as String? ?? '';
          return {'url': api.buildTrackUrl(contentUrl)};
        }).toList();
        audioHeaders = api.playbackSessionHeaders;
      } else if (localPaths.length != 1) {
        debugPrint('[PreBuffer] Next item $key is multi-track, skip (MVP)');
        return null;
      }

      final media = cached['media'] as Map<String, dynamic>? ?? {};
      final metadata = media['metadata'] as Map<String, dynamic>? ?? {};
      final title = candidateIsPodcast
          ? ((cached['recentEpisode'] as Map<String, dynamic>?)?['title']
                  as String? ??
              metadata['title'] as String? ??
              '')
          : (metadata['title'] as String? ?? '');
      final author = metadata['authorName'] as String? ?? '';
      final duration = candidateIsPodcast
          ? (((cached['recentEpisode'] as Map<String, dynamic>?)?['duration']
                          as num?)
                      ?.toDouble() ??
                  (media['duration'] as num?)?.toDouble() ??
                  0)
          : ((media['duration'] as num?)?.toDouble() ?? 0);
      final chapters = (media['chapters'] as List<dynamic>?) ?? const [];
      return {
        'itemId': itemIdRaw,
        'episodeId': episodeIdRaw,
        'libraryId': cached['libraryId'] as String?,
        'title': title,
        'author': author,
        'coverUrl': getCoverUrl(itemIdRaw),
        'duration': duration,
        'chapters': chapters,
        if (localPaths != null && localPaths.isNotEmpty) 'localPaths': localPaths,
        if (audioTracks != null) 'audioTracks': audioTracks,
        if (audioHeaders != null) 'audioHeaders': audioHeaders,
      };
    }
    return null;
  }

  /// Returns a short label describing what would play next given the current
  /// queue mode and player state, or null when nothing is queued. Used by the
  /// "Up next: ..." chip under the queue-mode pill on the absorbing page.
  Future<String?> peekUpNext({required String? currentItemId}) async {
    final self = this as LibraryProvider;
    if (currentItemId == null) return null;

    final isPodCurrent = currentItemId.length > 36;
    final mode = isPodCurrent
        ? await PlayerSettings.getPodcastQueueMode()
        : await PlayerSettings.getBookQueueMode();
    if (mode == 'off') return null;

    if (mode == 'playlist') {
      final pid = await PlayerSettings.getQueuePlaylistId();
      if (pid == null) return null;
      final pl = await _getPlaylistById(pid);
      if (pl == null) return null;
      final items = (pl['items'] as List<dynamic>?) ?? const [];
      final playlistName = pl['name'] as String? ?? '';
      // The current item must be in the active playlist - otherwise we're
      // playing off-playlist and advance stops after this item.
      int currentIdx = -1;
      for (var i = 0; i < items.length; i++) {
        final m = items[i];
        if (m is Map<String, dynamic> && _playlistItemKey(m) == currentItemId) {
          currentIdx = i;
          break;
        }
      }
      if (currentIdx < 0) return null;
      for (var i = currentIdx + 1; i < items.length; i++) {
        final m = items[i];
        if (m is! Map<String, dynamic>) continue;
        final key = _playlistItemKey(m);
        if (key.isEmpty) continue;
        if (self.isItemFinishedByKey(key)) continue;
        final title = _playlistItemTitle(m);
        return playlistName.isNotEmpty ? '$playlistName - $title' : title;
      }
      return null;
    }

    if (mode == 'collection') {
      final cid = await PlayerSettings.getQueueCollectionId();
      if (cid == null) return null;
      final c = await _getCollectionById(cid);
      if (c == null) return null;
      final items = _collectionItems(c);
      final name = c['name'] as String? ?? '';
      int currentIdx = -1;
      for (var i = 0; i < items.length; i++) {
        if (_playlistItemKey(items[i]) == currentItemId) { currentIdx = i; break; }
      }
      if (currentIdx < 0) return null;
      for (var i = currentIdx + 1; i < items.length; i++) {
        final key = _playlistItemKey(items[i]);
        if (key.isEmpty) continue;
        if (self.isItemFinishedByKey(key)) continue;
        final title = _playlistItemTitle(items[i]);
        return name.isNotEmpty ? '$name - $title' : title;
      }
      return null;
    }

    if (mode == 'manual') {
      final bookMode = await PlayerSettings.getBookQueueMode();
      final podMode = await PlayerSettings.getPodcastQueueMode();
      final merged = await PlayerSettings.getMergeAbsorbingLibraries();
      final currentLibId =
          _absorbingItemCache[currentItemId]?['libraryId'] as String?;
      final idx = _absorbingBookIds.indexOf(currentItemId);
      final start = idx >= 0 ? idx + 1 : 0;
      debugPrint('[Queue] peekUpNext: current=$currentItemId '
          '(${isPodCurrent ? "podcast" : "book"}, lib=$currentLibId) '
          'merged=$merged bookMode=$bookMode podMode=$podMode '
          'queueLen=${_absorbingBookIds.length} startIdx=$start');
      for (var i = start; i < _absorbingBookIds.length; i++) {
        final key = _absorbingBookIds[i];
        if (self.isItemFinishedByKey(key)) {
          debugPrint('[Queue]   peek [$i] $key SKIP - already finished');
          continue;
        }
        final candidateIsPodcast = key.length > 36;
        final candidateMode = candidateIsPodcast ? podMode : bookMode;
        if (candidateMode == 'off') {
          debugPrint('[Queue]   peek [$i] $key SKIP - ${candidateIsPodcast ? "podcast" : "book"} mode is off');
          continue;
        }
        if (!merged && candidateIsPodcast != isPodCurrent) {
          debugPrint('[Queue]   peek [$i] $key SKIP - cross-type (unified off)');
          continue;
        }
        final cached = _absorbingItemCache[key];
        if (cached == null) {
          debugPrint('[Queue]   peek [$i] $key SKIP - no cache entry');
          continue;
        }
        if (!merged && currentLibId != null) {
          final candidateLibId = cached['libraryId'] as String?;
          if (candidateLibId != null && candidateLibId != currentLibId) {
            debugPrint('[Queue]   peek [$i] $key SKIP - cross-library (current=$currentLibId candidate=$candidateLibId)');
            continue;
          }
        }
        debugPrint('[Queue]   peek [$i] $key PICK - ${candidateIsPodcast ? "podcast" : "book"} (lib=${cached['libraryId']})');
        return _entryTitle(cached);
      }
      debugPrint('[Queue]   peek: no eligible item found');
      return null;
    }

    // auto_next
    if (isPodCurrent) {
      return await _peekNextPodcastEpisode(currentItemId);
    }
    return await _peekNextBookInSeries(currentItemId);
  }

  Future<String?> _peekNextBookInSeries(String currentBookId) async {
    final self = this as LibraryProvider;
    var data = _itemDataWithSeries(currentBookId);
    var (seriesId, currentSeq) =
        data != null ? _StateMixin._extractSeries(data) : (null, null);
    if ((seriesId == null || currentSeq == null) && _api != null) {
      final full = await _api!.getLibraryItem(currentBookId);
      if (full != null) {
        data = full;
        (seriesId, currentSeq) = _StateMixin._extractSeries(full);
      }
    }
    if (seriesId == null || currentSeq == null) return null;

    final candidates = <double, Map<String, dynamic>>{};
    void consider(String id, Map<String, dynamic> d) {
      if (id == currentBookId) return;
      if (_manualAbsorbRemoves.contains(id)) return;
      if (self.isItemFinishedByKey(id)) return;
      final (sid, seq) = _StateMixin._extractSeries(d);
      if (sid != seriesId || seq == null || seq <= currentSeq!) return;
      candidates[seq] = d;
    }

    for (final entry in _absorbingItemCache.entries) {
      consider(entry.key, entry.value);
    }
    final dl = DownloadService();
    for (final dlInfo in dl.downloadedItems) {
      final id = dlInfo.itemId;
      if (id.length > 36) continue;
      if (candidates.values.any((d) => d['id'] == id)) continue;
      final d = _itemDataWithSeries(id);
      if (d != null) consider(id, d);
    }

    // Server fallback when next book isn't loaded locally. Mirrors what
    // _addNextSeriesBookToAbsorbing does so the peek matches the eventual
    // advance behaviour.
    final libraryId = data?['libraryId'] as String? ?? _selectedLibraryId;
    if (candidates.isEmpty && _api != null && libraryId != null) {
      try {
        final books = await _api!.getBooksBySeries(
          libraryId,
          seriesId,
          limit: 100,
        );
        for (final book in books) {
          if (book is! Map<String, dynamic>) continue;
          final id = book['id'] as String?;
          if (id == null) continue;
          consider(id, book);
        }
      } catch (e) {
        debugPrint('[UpNext] series fetch failed: $e');
      }
    }

    if (candidates.isEmpty) return null;
    final nextSeq = candidates.keys.toList()..sort();
    final next = candidates[nextSeq.first]!;
    return _entryTitle(next);
  }

  Future<String?> _peekNextPodcastEpisode(String currentCompoundKey) async {
    if (currentCompoundKey.length < 37) return null;
    final showId = currentCompoundKey.substring(0, 36);
    final currentEpId = currentCompoundKey.substring(37);
    final self = this as LibraryProvider;

    // Mirror _addNextPodcastEpisode: the absorbing cache stores per-episode
    // synthetic entries (recentEpisode), not the full episodes list, so read
    // the full list from a cached entry that has it or fall back to the API,
    // then sort by the same advance direction. Without this the peek looks at
    // the raw API order and shows nothing even though advancing works.
    List<dynamic> eps = const [];
    final showCached = _absorbingItemCache.values
        .cast<Map<String, dynamic>>()
        .where((e) => (e['id'] as String?) == showId)
        .firstOrNull;
    final cachedEps = (showCached?['media'] as Map<String, dynamic>?)?['episodes']
        as List<dynamic>?;
    if (cachedEps != null && cachedEps.isNotEmpty) {
      eps = cachedEps;
    } else if (_api != null) {
      final fullItem = await _api!.getLibraryItem(showId);
      final media = fullItem?['media'] as Map<String, dynamic>? ?? const {};
      eps = media['episodes'] as List<dynamic>? ?? const [];
    }
    final episodes = eps.whereType<Map<String, dynamic>>().toList();
    if (episodes.isEmpty) return null;

    final prefs = await SharedPreferences.getInstance();
    final advanceNewestFirst =
        (prefs.getString('podcast_advance_dir_$showId') ?? 'oldest_first') ==
            'newest_first';
    episodes.sort((a, b) {
      final aTime = (a['publishedAt'] as num?)?.toInt() ?? 0;
      final bTime = (b['publishedAt'] as num?)?.toInt() ?? 0;
      return advanceNewestFirst ? bTime.compareTo(aTime) : aTime.compareTo(bTime);
    });

    final currentIdx = episodes.indexWhere((e) => e['id'] == currentEpId);
    final start = currentIdx >= 0 ? currentIdx + 1 : 0;
    for (var i = start; i < episodes.length; i++) {
      final epId = episodes[i]['id'] as String?;
      if (epId == null) continue;
      if (self.isItemFinishedByKey('$showId-$epId')) continue;
      return episodes[i]['title'] as String?;
    }
    return null;
  }
}
