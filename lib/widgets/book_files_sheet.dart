import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/library_provider.dart';
import '../screens/book_requests_screen.dart';
import '../services/api_service.dart';
import '../services/book_requests.dart';
import '../services/bookorbit_mapper.dart';
import '../services/ebook_cache.dart';
import '../services/narrated_books.dart';
import '../utils/duration_format.dart';
import '../utils/file_size.dart';
import 'adaptive_modal.dart';
import 'book_detail_sheet.dart' show showBookDetailSheet;
import 'overlay_toast.dart';
import 'read_along_panel.dart';

enum _FileKind { audio, ebook, other }

class _FileEntry {
  final _FileKind kind;
  final String? id;
  final String name;
  final String? path;
  final String? format;
  final String? codec;
  final int? bitRate;
  final int? channels;
  final String? channelLayout;
  final double? duration;
  final int? size;
  final bool readAlong;
  final String? role;

  const _FileEntry({
    required this.kind,
    this.id,
    required this.name,
    this.path,
    this.format,
    this.codec,
    this.bitRate,
    this.channels,
    this.channelLayout,
    this.duration,
    this.size,
    this.readAlong = false,
    this.role,
  });
}

/// A book's files with what the server knows about each: format, codec,
/// bitrate, channels, length and size. BookOrbit keeps no codec or bitrate,
/// so its rows carry format, size and length. On BookOrbit it's also where
/// a read along is made, as on BookOrbit's own Files tab; [onFilesChanged]
/// hears when one is added.
Future<void> showBookFilesSheet(BuildContext context, Map<String, dynamic> item, {VoidCallback? onFilesChanged}) {
  return showAdaptiveSheetDialog<void>(
    context: context,
    initialChildSize: 0.6,
    minChildSize: 0.4,
    builder: (ctx, scroll) => _BookFilesBody(item: item, onFilesChanged: onFilesChanged, scroll: scroll),
  );
}

List<_FileEntry> _entriesFor(Map<String, dynamic> item) {
  final bookOrbit = item['bookOrbit'];
  if (bookOrbit is Map && bookOrbit['files'] is List) {
    return [
      for (final f in (bookOrbit['files'] as List).whereType<Map>()) _bookOrbitEntry(f),
    ];
  }
  final media = item['media'] as Map<String, dynamic>? ?? const {};
  final entries = <_FileEntry>[];
  final seen = <String>{};
  for (final af in (media['audioFiles'] as List<dynamic>? ?? const []).whereType<Map>()) {
    final meta = af['metadata'] as Map? ?? const {};
    seen.add('${af['ino']}');
    entries.add(_FileEntry(
      kind: _FileKind.audio,
      id: af['ino']?.toString(),
      name: '${meta['filename'] ?? af['ino'] ?? ''}',
      path: meta['relPath'] as String? ?? meta['path'] as String?,
      format: (af['format'] as String?) ?? _extOf(meta),
      codec: af['codec'] as String?,
      bitRate: (af['bitRate'] as num?)?.toInt(),
      channels: (af['channels'] as num?)?.toInt(),
      channelLayout: af['channelLayout'] as String?,
      duration: (af['duration'] as num?)?.toDouble(),
      size: (meta['size'] as num?)?.toInt(),
    ));
  }
  final ebook = media['ebookFile'] as Map?;
  if (ebook != null) {
    final meta = ebook['metadata'] as Map? ?? const {};
    seen.add('${ebook['ino']}');
    final id = item['id'];
    entries.add(_FileEntry(
      kind: _FileKind.ebook,
      id: ebook['ino']?.toString(),
      name: '${meta['filename'] ?? ''}',
      path: meta['relPath'] as String? ?? meta['path'] as String?,
      format: (ebook['ebookFormat'] as String?) ?? _extOf(meta),
      size: (meta['size'] as num?)?.toInt(),
      readAlong: id is String && NarratedBooks.contains(id),
    ));
  }
  for (final lf in (item['libraryFiles'] as List<dynamic>? ?? const []).whereType<Map>()) {
    if (seen.contains('${lf['ino']}')) continue;
    final meta = lf['metadata'] as Map? ?? const {};
    final type = lf['fileType'] as String?;
    if (type == 'audio') continue;
    entries.add(_FileEntry(
      kind: type == 'ebook' ? _FileKind.ebook : _FileKind.other,
      id: lf['ino']?.toString(),
      name: '${meta['filename'] ?? ''}',
      path: meta['relPath'] as String? ?? meta['path'] as String?,
      format: _extOf(meta),
      size: (meta['size'] as num?)?.toInt(),
      role: type,
    ));
  }
  return entries;
}

_FileEntry _bookOrbitEntry(Map f) {
  final format = (f['format'] as String?)?.toLowerCase();
  final role = f['role'] as String?;
  final content = role == 'primary' || role == 'content';
  final kind = !content
      ? _FileKind.other
      : BookOrbitMapper.isAudioFormat(format)
          ? _FileKind.audio
          : allEbookFormats.contains(format)
              ? _FileKind.ebook
              : _FileKind.other;
  return _FileEntry(
    kind: kind,
    id: f['id']?.toString(),
    name: '${f['filename'] ?? ''}',
    path: f['path'] as String?,
    format: format,
    duration: (f['duration'] as num?)?.toDouble(),
    size: (f['size'] as num?)?.toInt(),
    readAlong: f['readAlong'] == true,
    role: content ? null : role,
  );
}

String? _extOf(Map meta) {
  final ext = (meta['ext'] as String?) ?? '';
  final clean = ext.startsWith('.') ? ext.substring(1) : ext;
  return clean.isEmpty ? null : clean;
}

class _BookFilesBody extends StatefulWidget {
  final Map<String, dynamic> item;
  final VoidCallback? onFilesChanged;
  final ScrollController scroll;

  const _BookFilesBody({required this.item, required this.onFilesChanged, required this.scroll});

  @override
  State<_BookFilesBody> createState() => _BookFilesBodyState();
}

class _BookFilesBodyState extends State<_BookFilesBody> {
  late Map<String, dynamic> _item = widget.item;
  late List<_FileEntry> _entries = _entriesFor(_item);

  MissingFormatRequest? _missing;
  bool _requesting = false;
  String? _deleting;
  int _panelVersion = 0;

  bool get bookOrbit => _item['bookOrbit'] is Map;
  ScrollController get scroll => widget.scroll;

  /// A BookOrbit book, not a Book Dock file.
  String? get _bookId {
    final id = _item['id'];
    return bookOrbit && id is String && !ApiService.isBookDockItem(id) ? id : null;
  }

  BookOrbitApiService? get _boApi {
    final api = context.read<AuthProvider?>()?.apiService;
    return api is BookOrbitApiService ? api : null;
  }

  @override
  void initState() {
    super.initState();
    _loadMissing();
  }

  Future<void> _loadMissing() async {
    final id = _bookId;
    final api = _boApi;
    if (id == null || api == null) return;
    final missing = await api.missingFormatRequest(id);
    if (mounted) setState(() => _missing = missing);
  }

  Future<void> _filesChanged() async {
    widget.onFilesChanged?.call();
    final id = _item['id'];
    final api = context.read<AuthProvider?>()?.apiService;
    if (id is! String || api == null) return;
    final fresh = await api.getLibraryItem(id);
    if (fresh == null || !mounted) return;
    setState(() {
      _item = fresh;
      _entries = _entriesFor(fresh);
    });
    // A read along is the audio and the text in one, and a deleted file can
    // leave a format missing.
    unawaited(_loadMissing());
  }

  bool get _canDelete {
    if (!(context.read<AuthProvider?>()?.canDelete ?? false)) return false;
    if (context.read<LibraryProvider?>()?.isOffline ?? true) return false;
    if (bookOrbit) return _bookId != null;
    return _item['id'] is String && _item['mediaType'] != 'podcast';
  }

  Future<void> _deleteFile(_FileEntry entry) async {
    final itemId = _item['id'];
    final fileId = entry.id;
    final api = context.read<AuthProvider?>()?.apiService;
    if (itemId is! String || fileId == null || api == null || _deleting != null) return;
    final l = AppLocalizations.of(context)!;
    final name = entry.name.isEmpty ? fileId : entry.name;
    final last = entry.kind != _FileKind.other && _entries.where((e) => e.kind != _FileKind.other).length == 1;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.fileInfoDeleteTitle),
        content: Text([l.fileInfoDeletePrompt(name), if (last) l.fileInfoDeleteLast].join('\n\n')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.delete, style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _deleting = fileId);
    final status = await api.deleteLibraryFile(itemId, fileId);
    if (!mounted) return;
    if (status < 200 || status >= 300) {
      setState(() => _deleting = null);
      showOverlayToast(context, status == 403 ? l.fileInfoDeleteNotAllowed : l.deleteFromServerFailed,
          icon: status == 403 ? Icons.lock_outline_rounded : Icons.error_outline_rounded);
      return;
    }
    setState(() {
      _deleting = null;
      _entries = _entries.where((e) => e.id != fileId).toList();
      // BookOrbit's read along choices list the files a read along can be
      // made from or replace, so it looks again.
      _panelVersion++;
    });
    showOverlayToast(context, l.deletedFromServer(name), icon: Icons.delete_outline_rounded);
    await _filesChanged();
  }

  Future<void> _requestMissing() async {
    final id = _bookId;
    final api = _boApi;
    final missing = _missing;
    if (id == null || api == null || missing == null || _requesting) return;
    final l = AppLocalizations.of(context)!;
    setState(() => _requesting = true);
    final result = await api.requestMissingFormat(id, missing.mediaKind);
    if (!mounted) return;
    setState(() {
      _requesting = false;
      final request = result.request;
      if (request != null) {
        _missing = MissingFormatRequest(
          missing.mediaKind,
          BookRequestAvailability(
            existingRequestId: request.id,
            existingRequestStatus: request.status,
            alreadySubscribed: true,
          ),
        );
      }
    });
    if (result.ok) {
      showOverlayToast(context, result.subscribed ? l.breqJoined : l.breqJoinsOwned,
          icon: Icons.check_circle_outline_rounded);
    } else {
      showOverlayToast(context, result.error != null ? l.breqFailedReason(result.error!) : l.breqFailed,
          icon: Icons.error_outline_rounded);
    }
  }

  /// Where the missing format's files would be: a placeholder saying it
  /// isn't here yet, with the way to ask for it.
  List<Widget> _missingSection(BuildContext context, String title, MissingFormatRequest missing) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final audiobook = missing.mediaKind == 'audiobook';
    final owned = missing.ownedBookId;
    final status = owned != null
        ? l.fileInfoOwnedSeparately
        : missing.following
            ? l.breqRequested
            : missing.joinable
                ? l.fileInfoRequestedBySomeone
                : audiobook
                    ? l.fileInfoNoAudiobook
                    : l.fileInfoNoEbook;
    final Widget action;
    if (owned != null) {
      action = TextButton(onPressed: () => showBookDetailSheet(context, '$owned'), child: Text(l.breqOpenBook));
    } else if (missing.following) {
      action = TextButton(onPressed: () => BookRequestsScreen.open(context, openList: true), child: Text(l.breqView));
    } else {
      action = FilledButton.tonal(
        onPressed: _requesting ? null : _requestMissing,
        child: _requesting
            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
            : Text(missing.joinable ? l.breqAddMeToo : (audiobook ? l.breqRequestAudiobook : l.breqRequestEbook)),
      );
    }
    return [
      const SizedBox(height: 20),
      Text(title, style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      Row(children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Icon(audiobook ? Icons.headphones_rounded : Icons.menu_book_rounded, size: 16, color: cs.onSurfaceVariant),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(status, style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant))),
        const SizedBox(width: 8),
        action,
      ]),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final entries = _entries;
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final totalSize = entries.fold<int>(0, (sum, e) => sum + (e.size ?? 0));
    final audio = entries.where((e) => e.kind == _FileKind.audio).toList();
    final ebooks = entries.where((e) => e.kind == _FileKind.ebook).toList();
    final other = entries.where((e) => e.kind == _FileKind.other).toList();

    return ListView(
      controller: scroll,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: cs.onSurface.withValues(alpha: 0.24),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        Text(l.fileInfoTitle, style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(
          [l.fileInfoFileCount(entries.length), if (totalSize > 0) formatFileSize(totalSize)].join(' · '),
          style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
        ),
        if (bookOrbit && _item['id'] is String && !ApiService.isBookDockItem(_item['id'] as String))
          ReadAlongPanel(
            key: ValueKey(_panelVersion),
            bookId: _item['id'] as String,
            bookLanguage: ((_item['media'] as Map?)?['metadata'] as Map?)?['language'] as String?,
            onAdded: _filesChanged,
          ),
        if (entries.isEmpty) ...[
          const SizedBox(height: 24),
          Text(l.fileInfoNone, style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
        ],
        if (audio.isNotEmpty) ..._section(context, l.fileInfoAudio, audio, shared: _sharedSpecs(context, audio)),
        if (audio.isNotEmpty && bookOrbit)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(l.fileInfoBookOrbitNote, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
          ),
        if (_missing case final missing? when missing.mediaKind == 'audiobook')
          ..._missingSection(context, l.fileInfoAudio, missing),
        if (ebooks.isNotEmpty) ..._section(context, l.fileInfoEbook, ebooks),
        if (_missing case final missing? when missing.mediaKind == 'ebook') ..._missingSection(context, l.fileInfoEbook, missing),
        if (other.isNotEmpty) ..._section(context, l.fileInfoOther, other),
      ],
    );
  }

  /// Specs every audio file shares, shown once above the list instead of on
  /// each of a few dozen tracks.
  List<String> _sharedSpecs(BuildContext context, List<_FileEntry> audio) {
    if (audio.length < 2) return const [];
    final first = _specs(context, audio.first, withLength: false);
    return [
      for (final spec in first)
        if (audio.every((e) => _specs(context, e, withLength: false).contains(spec))) spec,
    ];
  }

  List<String> _specs(BuildContext context, _FileEntry e, {bool withLength = true}) {
    final l = AppLocalizations.of(context)!;
    final codec = e.codec?.toUpperCase();
    final format = e.format?.toUpperCase();
    final layout = e.channelLayout?.trim();
    return [
      if (format != null && format.isNotEmpty) format,
      if (codec != null && codec.isNotEmpty && codec != format) codec,
      if ((e.bitRate ?? 0) > 0) l.kbpsValue((e.bitRate! / 1000).round()),
      if (layout != null && layout.isNotEmpty)
        layout[0].toUpperCase() + layout.substring(1)
      else if ((e.channels ?? 0) > 0)
        l.fileInfoChannels(e.channels!),
      if (withLength && (e.duration ?? 0) > 0) formatHm(e.duration!),
      if (withLength && (e.size ?? 0) > 0) formatFileSize(e.size!),
    ];
  }

  List<Widget> _section(BuildContext context, String title, List<_FileEntry> files, {List<String> shared = const []}) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final canDelete = _canDelete;
    return [
      const SizedBox(height: 20),
      Row(children: [
        Text(title, style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        if (files.length > 1) ...[
          const SizedBox(width: 8),
          Text('${files.length}', style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant)),
        ],
      ]),
      if (shared.isNotEmpty) ...[
        const SizedBox(height: 8),
        _SpecWrap(specs: shared),
      ],
      const SizedBox(height: 8),
      for (final f in files)
        _FileTile(
          entry: f,
          specs: _specs(context, f).where((s) => !shared.contains(s)).toList(),
          deleting: f.id != null && f.id == _deleting,
          onDelete: canDelete && f.id != null ? () => _deleteFile(f) : null,
        ),
    ];
  }
}

class _SpecWrap extends StatelessWidget {
  final List<String> specs;
  final bool readAlong;
  const _SpecWrap({required this.specs, this.readAlong = false});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;
    Widget chip(Widget child) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(6),
          ),
          child: child,
        );
    return Wrap(spacing: 6, runSpacing: 6, children: [
      for (final s in specs) chip(Text(s, style: tt.labelSmall)),
      if (readAlong)
        chip(Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.headphones_rounded, size: 12, color: cs.primary),
          const SizedBox(width: 4),
          Text(l.readAlong, style: tt.labelSmall?.copyWith(color: cs.primary)),
        ])),
    ]);
  }
}

class _FileTile extends StatelessWidget {
  final _FileEntry entry;
  final List<String> specs;
  final bool deleting;
  final VoidCallback? onDelete;
  const _FileTile({required this.entry, required this.specs, this.deleting = false, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;
    final icon = switch (entry.kind) {
      _FileKind.audio => Icons.audio_file_rounded,
      _FileKind.ebook => Icons.menu_book_rounded,
      _FileKind.other => entry.role == 'cover' || entry.role == 'image' ? Icons.image_rounded : Icons.insert_drive_file_rounded,
    };
    final path = entry.path;
    final roleLabel = switch (entry.role) {
      'cover' => l.fileInfoCover,
      'metadata' => l.fileInfoMetadata,
      'supplement' => l.fileInfoSupplement,
      _ => null,
    };
    final copyPath = path == null || path.isEmpty
        ? null
        : () async {
            await Clipboard.setData(ClipboardData(text: path));
            if (context.mounted) {
              showOverlayToast(context, l.fileInfoPathCopied, icon: Icons.content_copy_rounded);
            }
          };
    final onDelete = this.onDelete;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onLongPress: copyPath,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, size: 20, color: cs.onSurfaceVariant),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(entry.name.isEmpty ? '-' : entry.name,
                  style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
              if (path != null && path.isNotEmpty && path != entry.name) ...[
                const SizedBox(height: 2),
                Text(path,
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
              if (specs.isNotEmpty || entry.readAlong || roleLabel != null) ...[
                const SizedBox(height: 6),
                _SpecWrap(specs: [?roleLabel, ...specs], readAlong: entry.readAlong),
              ],
            ]),
          ),
          if (deleting)
            const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else if (onDelete != null)
            PopupMenuButton<VoidCallback>(
              tooltip: l.moreActions,
              icon: Icon(Icons.more_vert_rounded, size: 20, color: cs.onSurfaceVariant),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 160),
              onSelected: (action) => action(),
              itemBuilder: (_) => [
                if (copyPath != null)
                  PopupMenuItem(
                    value: copyPath,
                    child: Row(children: [
                      const Icon(Icons.content_copy_rounded, size: 18),
                      const SizedBox(width: 12),
                      Text(l.fileInfoCopyPath),
                    ]),
                  ),
                PopupMenuItem(
                  value: onDelete,
                  child: Row(children: [
                    Icon(Icons.delete_outline_rounded, size: 18, color: cs.error),
                    const SizedBox(width: 12),
                    Text(l.delete, style: TextStyle(color: cs.error)),
                  ]),
                ),
              ],
            ),
        ]),
      ),
    );
  }
}
