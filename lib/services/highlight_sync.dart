import 'package:flutter/foundation.dart';

import 'api_service.dart';
import 'ebook_annotation_service.dart';

// KOReader's and Kobo's own shades, which BookOrbit can pass along from a
// highlight made there, by the name it gives each. Pale ones are too far
// from every color here to be matched by nearness.
const _deviceColors = {
  '#ff3300': HighlightColor.red,
  '#ff8800': HighlightColor.orange,
  '#ffff33': HighlightColor.yellow,
  '#00aa66': HighlightColor.green,
  '#88ff77': HighlightColor.olive,
  '#00ffee': HighlightColor.cyan,
  '#0066ff': HighlightColor.blue,
  '#ee00ff': HighlightColor.purple,
  '#808080': HighlightColor.gray,
  '#f6f3b3': HighlightColor.yellow,
  '#c6e09e': HighlightColor.green,
  '#b2e1e8': HighlightColor.blue,
  '#e8afcf': HighlightColor.pink,
};

String serverHighlightColor(HighlightColor color) => color.hex;

HighlightColor highlightColorFromServer(String? color) {
  final c = (color ?? '').trim().toLowerCase();
  for (final h in HighlightColor.values) {
    if (h.name == c || h.hex.toLowerCase() == c) return h;
  }
  final device = _deviceColors[c];
  if (device != null) return device;
  final hex = c.startsWith('#') ? c.substring(1) : c;
  final value = hex.length == 6 ? int.tryParse(hex, radix: 16) : null;
  if (value == null) return HighlightColor.yellow;
  int r(int v) => v >> 16 & 0xFF;
  int g(int v) => v >> 8 & 0xFF;
  int b(int v) => v & 0xFF;
  var best = HighlightColor.yellow;
  var bestDistance = 1 << 30;
  for (final h in HighlightColor.values) {
    final v = int.parse(h.hex.substring(1), radix: 16);
    final d = (r(v) - r(value)) * (r(v) - r(value)) +
        (g(v) - g(value)) * (g(v) - g(value)) +
        (b(v) - b(value)) * (b(v) - b(value));
    if (d < bestDistance) {
      bestDistance = d;
      best = h;
    }
  }
  return best;
}

/// Keeps ebook highlights in step with a server that holds them too
/// (BookOrbit). Highlights made, recolored, noted or deleted here go up, and
/// opening a book brings in what was done there. Changes that couldn't reach
/// the server wait in [EbookAnnotationService] until the next try.
class HighlightSync {
  HighlightSync._();
  static final instance = HighlightSync._();

  final Map<String, Future<bool>> _chains = {};

  /// Sends what changed here and brings in what changed on the server. True
  /// when the highlights here changed.
  Future<bool> sync(ApiService api, String itemId, String fileId) =>
      _queue(itemId, () => _run(api, itemId, fileId, pull: true));

  /// Sends what changed here, without asking the server for its own. With no
  /// [fileId] new highlights wait, since the server files them by book file.
  Future<void> push(ApiService api, String itemId, String? fileId) =>
      _queue(itemId, () => _run(api, itemId, fileId, pull: false));

  Future<bool> _queue(String itemId, Future<bool> Function() job) {
    final previous = _chains[itemId] ?? Future.value(false);
    final next = previous.then((_) => job()).catchError((Object e) {
      debugPrint('[HighlightSync] $itemId failed: $e');
      return false;
    });
    _chains[itemId] = next;
    return next;
  }

  Future<bool> _run(ApiService api, String itemId, String? fileId, {required bool pull}) async {
    if (!api.keepsEbookHighlights) return false;
    final store = EbookAnnotationService();
    var changed = false;
    var removed = 0;
    var added = 0;
    var sent = 0;

    // Deletes and edits made here that haven't reached the server yet.
    final pending = await store.pendingServerChanges(itemId);
    for (final id in pending.deletes) {
      if (await api.deleteEbookHighlight(itemId, id)) await store.serverChangeDone(itemId, id);
    }
    if (pending.edits.isNotEmpty) {
      final local = await store.getAnnotations(itemId);
      for (final id in pending.edits) {
        final a = local.where((x) => x.serverId == id).firstOrNull;
        if (a == null ||
            await api.updateEbookHighlight(itemId, id,
                color: serverHighlightColor(a.color ?? HighlightColor.yellow), note: a.note)) {
          await store.serverChangeDone(itemId, id);
        }
      }
    }

    if (pull && fileId != null) {
      final server = await api.ebookHighlights(itemId, fileId: fileId);
      if (server == null) return false;
      final waiting = await store.pendingServerChanges(itemId);
      var local = await store.getAnnotations(itemId);
      final seen = <String>{};
      for (final s in server) {
        final id = s['id'] as String;
        seen.add(id);
        if (waiting.deletes.contains(id)) continue;
        final cfi = s['cfi'];
        if (cfi is! String || cfi.isEmpty) continue;
        // Another file of the same book (an EPUB beside a narrated one).
        final file = s['fileId'];
        if (file != null && file != fileId) continue;
        final color = highlightColorFromServer(s['color'] as String?);
        final note = (s['note'] as String?)?.trim();
        final mine = local.where((a) => a.serverId == id).firstOrNull ??
            local
                .where((a) => a.type == AnnotationType.highlight && a.serverId == null && a.cfi == cfi)
                .firstOrNull;
        if (mine == null) {
          await store.addHighlight(
            itemId: itemId,
            cfi: cfi,
            selectedText: (s['text'] as String?) ?? '',
            color: color,
            note: note == null || note.isEmpty ? null : note,
            chapter: s['chapter'] as String?,
            serverId: id,
            createdAt: DateTime.tryParse('${s['at']}')?.toLocal(),
            fromServer: true,
          );
          added++;
          changed = true;
          continue;
        }
        if (mine.serverId == null) {
          await store.setServerId(itemId: itemId, annotationId: mine.id, serverId: id);
        }
        // An edit made here wins until it has been sent.
        if (waiting.edits.contains(id)) continue;
        if (mine.color != color) {
          await store.updateColor(itemId: itemId, annotationId: mine.id, color: color, fromServer: true);
          changed = true;
        }
        if ((mine.note ?? '') != (note ?? '')) {
          await store.updateNote(
              itemId: itemId, annotationId: mine.id, note: note == null || note.isEmpty ? null : note, fromServer: true);
          changed = true;
        }
      }
      // Deleted on the server since they were sent or brought in.
      local = await store.getAnnotations(itemId);
      for (final a in local) {
        if (a.type == AnnotationType.highlight && a.serverId != null && !seen.contains(a.serverId)) {
          await store.delete(itemId: itemId, annotationId: a.id, fromServer: true);
          removed++;
          changed = true;
        }
      }
    }

    // Made here and not on the server yet, including any from before.
    if (fileId != null) {
      for (final a in await store.getAnnotations(itemId)) {
        if (a.type != AnnotationType.highlight || a.serverId != null) continue;
        final text = a.selectedText ?? '';
        if (text.trim().isEmpty) continue;
        final id = await api.addEbookHighlight(itemId, fileId,
            cfi: a.cfi,
            text: text,
            color: serverHighlightColor(a.color ?? HighlightColor.yellow),
            note: a.note,
            chapter: a.chapter);
        // Offline or refused: the rest wait for the next try.
        if (id == null) break;
        await store.setServerId(itemId: itemId, annotationId: a.id, serverId: id);
        sent++;
      }
    }

    if (added + removed + sent > 0 || pending.deletes.isNotEmpty || pending.edits.isNotEmpty) {
      debugPrint('[HighlightSync] $itemId: $added from the server, $removed deleted there, $sent sent, '
          '${pending.deletes.length} deletes and ${pending.edits.length} edits caught up');
    }
    return changed;
  }
}
