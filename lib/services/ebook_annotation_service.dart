import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'scoped_prefs.dart';
import 'settings_sync_service.dart';

/// Types of ebook annotations.
enum AnnotationType { highlight, bookmark }

/// Highlight colors: BookOrbit's ten, so a highlight keeps its color there
/// and in every reader it syncs with.
enum HighlightColor {
  yellow('#FACC15'),
  green('#4ADE80'),
  blue('#38BDF8'),
  pink('#F472B6'),
  orange('#FB923C'),
  red('#F87171'),
  olive('#84CC16'),
  cyan('#22D3EE'),
  purple('#C084FC'),
  gray('#9CA3AF');

  final String hex;
  const HighlightColor(this.hex);
}

/// A single ebook annotation (highlight, bookmark, or note).
class EbookAnnotation {
  final String id;
  final AnnotationType type;
  final String cfi;
  final String? selectedText;
  HighlightColor? color;
  String? note;
  /// Chapter title captured when the annotation was made. Older annotations
  /// predate this and stay null - the CFI alone can't name a chapter without
  /// reopening the book.
  final String? chapter;
  final DateTime createdAt;
  /// The annotation's id on the server, for the ones also kept there (a
  /// picture EPUB's bookmarks and any book's highlights on BookOrbit). Null
  /// when it lives only here.
  String? serverId;

  EbookAnnotation({
    required this.id,
    required this.type,
    required this.cfi,
    this.selectedText,
    this.color,
    this.note,
    this.chapter,
    this.serverId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'cfi': cfi,
        if (selectedText != null) 'text': selectedText,
        if (color != null) 'color': color!.name,
        if (note != null && note!.isNotEmpty) 'note': note,
        if (chapter != null && chapter!.isNotEmpty) 'ch': chapter,
        if (serverId != null) 'sid': serverId,
        'ts': createdAt.millisecondsSinceEpoch,
      };

  factory EbookAnnotation.fromJson(Map<String, dynamic> json) {
    return EbookAnnotation(
      id: json['id'] as String,
      type: AnnotationType.values.byName(json['type'] as String),
      cfi: json['cfi'] as String,
      selectedText: json['text'] as String?,
      color: json['color'] != null
          ? HighlightColor.values.byName(json['color'] as String)
          : null,
      note: json['note'] as String?,
      chapter: json['ch'] as String?,
      serverId: json['sid'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['ts'] as int),
    );
  }
}

/// A highlight's CFI collapsed to the point where it starts.
///
/// Highlights are saved as range CFIs (`epubcfi(base,start,end)`) because
/// that's what a text selection produces. epub.js resolves a range to its
/// bounding rect, and at load time - before the section has laid out - that
/// rect is empty, so `display()` scrolls nowhere and the reader stays on
/// whatever page it was already showing. The start point alone always
/// resolves. Non-range CFIs come back untouched.
String pointCfi(String cfi) {
  final open = cfi.indexOf('(');
  final close = cfi.lastIndexOf(')');
  if (open == -1 || close <= open) return cfi;
  final parts = cfi.substring(open + 1, close).split(',');
  if (parts.length < 2) return cfi;
  return 'epubcfi(${parts[0]}${parts[1]})';
}

/// Stores per-book ebook annotations in SharedPreferences.
class EbookAnnotationService {
  static final EbookAnnotationService _instance = EbookAnnotationService._();
  factory EbookAnnotationService() => _instance;
  EbookAnnotationService._();

  static const _keyPrefix = 'ebook_annotations_';
  // Highlight deletes and edits made here that the server hasn't had yet.
  static const _pendingPrefix = 'ebook_highlight_sync_';

  // Two annotations made in the same millisecond used to share an id, which
  // made them one row to anything that works by id - selecting, deleting,
  // noting. The counter keeps them apart.
  int _idSeq = 0;

  String _newId() =>
      '${DateTime.now().millisecondsSinceEpoch}-${_idSeq++}';

  String _key(String itemId) => '$_keyPrefix$itemId';

  /// Get all annotations for a book.
  Future<List<EbookAnnotation>> getAnnotations(String itemId) async {
    final raw = await ScopedPrefs.getString(_key(itemId));
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => EbookAnnotation.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      debugPrint('[EbookAnnotations] Failed to parse: $e');
      return [];
    }
  }

  /// Get only highlights for a book.
  Future<List<EbookAnnotation>> getHighlights(String itemId) async {
    final all = await getAnnotations(itemId);
    return all.where((a) => a.type == AnnotationType.highlight).toList();
  }

  /// Get only bookmarks for a book.
  Future<List<EbookAnnotation>> getBookmarks(String itemId) async {
    final all = await getAnnotations(itemId);
    return all.where((a) => a.type == AnnotationType.bookmark).toList();
  }

  /// Every highlight on the device, keyed by item ID. Books are ordered by
  /// their newest highlight and each book's list stays newest first.
  Future<Map<String, List<EbookAnnotation>>> getAllHighlights() async {
    final itemIds = await ScopedPrefs.suffixesWithPrefix(_keyPrefix);
    final byItem = <String, List<EbookAnnotation>>{};
    for (final itemId in itemIds) {
      if (itemId.isEmpty) continue;
      final highlights = await getHighlights(itemId);
      if (highlights.isNotEmpty) byItem[itemId] = highlights;
    }
    final ordered = byItem.entries.toList()
      ..sort((a, b) => b.value.first.createdAt.compareTo(a.value.first.createdAt));
    return {for (final e in ordered) e.key: e.value};
  }

  Future<void> _save(String itemId, List<EbookAnnotation> annotations) async {
    final json = jsonEncode(annotations.map((a) => a.toJson()).toList());
    await ScopedPrefs.setString(_key(itemId), json);
    // Highlights and bookmarks live only on the device, so settings sync is
    // their only way to another one. Writing straight to prefs like this is
    // invisible to the settings-changed notifier, so tell sync directly rather
    // than leaving it to the periodic sweep.
    SettingsSyncService().noteLocalChange();
  }

  /// Add a highlight. [fromServer] is one brought in from the server.
  Future<EbookAnnotation> addHighlight({
    required String itemId,
    required String cfi,
    required String selectedText,
    HighlightColor color = HighlightColor.yellow,
    String? note,
    String? chapter,
    String? serverId,
    DateTime? createdAt,
    bool fromServer = false,
  }) async {
    final annotation = EbookAnnotation(
      id: _newId(),
      type: AnnotationType.highlight,
      cfi: cfi,
      selectedText: selectedText,
      color: color,
      note: note,
      chapter: chapter,
      serverId: serverId,
      createdAt: createdAt,
    );
    final annotations = await getAnnotations(itemId);
    annotations.insert(0, annotation);
    await _save(itemId, annotations);
    debugPrint('[EbookAnnotations] Added highlight: ${selectedText.substring(0, selectedText.length.clamp(0, 30))}...');
    return annotation;
  }

  /// Add a bookmark at the current location.
  Future<EbookAnnotation> addBookmark({
    required String itemId,
    required String cfi,
    String? note,
    String? chapter,
    String? serverId,
  }) async {
    final annotation = EbookAnnotation(
      id: _newId(),
      type: AnnotationType.bookmark,
      cfi: cfi,
      note: note,
      chapter: chapter,
      serverId: serverId,
    );
    final annotations = await getAnnotations(itemId);
    annotations.insert(0, annotation);
    await _save(itemId, annotations);
    debugPrint('[EbookAnnotations] Added bookmark');
    return annotation;
  }

  /// Change a highlight's color. [fromServer] is a change brought in from
  /// the server, which has nothing to send back.
  Future<void> updateColor({
    required String itemId,
    required String annotationId,
    required HighlightColor color,
    bool fromServer = false,
  }) async {
    final annotations = await getAnnotations(itemId);
    final idx = annotations.indexWhere((a) => a.id == annotationId);
    if (idx == -1) return;
    annotations[idx].color = color;
    await _save(itemId, annotations);
    if (!fromServer) await _noteServerChange(itemId, annotations[idx], deleted: false);
  }

  Future<void> updateNote({
    required String itemId,
    required String annotationId,
    required String? note,
    bool fromServer = false,
  }) async {
    final annotations = await getAnnotations(itemId);
    final idx = annotations.indexWhere((a) => a.id == annotationId);
    if (idx == -1) return;
    annotations[idx].note = note;
    await _save(itemId, annotations);
    if (!fromServer) await _noteServerChange(itemId, annotations[idx], deleted: false);
  }

  Future<void> setServerId({
    required String itemId,
    required String annotationId,
    required String serverId,
  }) async {
    final annotations = await getAnnotations(itemId);
    final idx = annotations.indexWhere((a) => a.id == annotationId);
    if (idx == -1) return;
    annotations[idx].serverId = serverId;
    await _save(itemId, annotations);
  }

  /// Delete an annotation. [fromServer] is one already gone from the server.
  Future<void> delete({
    required String itemId,
    required String annotationId,
    bool fromServer = false,
  }) async {
    final annotations = await getAnnotations(itemId);
    final gone = annotations.where((a) => a.id == annotationId).firstOrNull;
    annotations.removeWhere((a) => a.id == annotationId);
    await _save(itemId, annotations);
    if (gone != null && !fromServer) await _noteServerChange(itemId, gone, deleted: true);
    debugPrint('[EbookAnnotations] Deleted annotation $annotationId');
  }

  /// Highlight deletes and edits made here that the server hasn't had, by
  /// server id. A delete waiting here also keeps the next sync from bringing
  /// the highlight back.
  Future<({Set<String> deletes, Set<String> edits})> pendingServerChanges(String itemId) async {
    final raw = await ScopedPrefs.getString('$_pendingPrefix$itemId');
    if (raw == null) return (deletes: <String>{}, edits: <String>{});
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      return (
        deletes: {for (final v in (j['delete'] as List? ?? const [])) '$v'},
        edits: {for (final v in (j['edit'] as List? ?? const [])) '$v'},
      );
    } catch (_) {
      return (deletes: <String>{}, edits: <String>{});
    }
  }

  Future<void> _savePending(String itemId, Set<String> deletes, Set<String> edits) async {
    final key = '$_pendingPrefix$itemId';
    if (deletes.isEmpty && edits.isEmpty) {
      await ScopedPrefs.remove(key);
    } else {
      await ScopedPrefs.setString(key, jsonEncode({'delete': deletes.toList(), 'edit': edits.toList()}));
    }
  }

  Future<void> _noteServerChange(String itemId, EbookAnnotation a, {required bool deleted}) async {
    final id = a.serverId;
    if (a.type != AnnotationType.highlight || id == null) return;
    final p = await pendingServerChanges(itemId);
    if (deleted) {
      p.deletes.add(id);
      p.edits.remove(id);
    } else {
      p.edits.add(id);
    }
    await _savePending(itemId, p.deletes, p.edits);
  }

  /// The server has the change made here to the highlight [serverId].
  Future<void> serverChangeDone(String itemId, String serverId) async {
    final p = await pendingServerChanges(itemId);
    if (!p.deletes.remove(serverId) && !p.edits.remove(serverId)) return;
    await _savePending(itemId, p.deletes, p.edits);
  }

  /// Check if a bookmark exists at the given CFI.
  Future<bool> hasBookmarkAt(String itemId, String cfi) async {
    final bookmarks = await getBookmarks(itemId);
    return bookmarks.any((b) => b.cfi == cfi);
  }
}
