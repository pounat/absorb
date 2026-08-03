import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/app_localizations.dart';
import '../services/notes_service.dart';
import 'adaptive_modal.dart';

/// Bottom sheet displaying notes for a library item.
class NotesSheet extends StatefulWidget {
  final String itemId;
  final String itemTitle;
  final Color accent;
  final ScrollController? scrollController;

  const NotesSheet({
    super.key,
    required this.itemId,
    required this.itemTitle,
    required this.accent,
    this.scrollController,
  });

  static void show(BuildContext context, {
    required String itemId,
    required String itemTitle,
    required Color accent,
  }) {
    showAdaptiveSheetDialog(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      initialChildSize: 0.75,
      minChildSize: 0.05,
      snap: true,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) => NotesSheet(
        itemId: itemId,
        itemTitle: itemTitle,
        accent: accent,
        scrollController: scrollController,
      ),
    );
  }

  @override
  State<NotesSheet> createState() => _NotesSheetState();
}

class _NotesSheetState extends State<NotesSheet> {
  List<Note> _notes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    final notes = await NotesService().getNotes(widget.itemId);
    if (mounted) setState(() { _notes = notes; _isLoading = false; });
  }

  Future<void> _addNote() async {
    final result = await _showEditor(context);
    if (result == null) return;
    await NotesService().addNote(widget.itemId, title: result.title, body: result.body);
    _loadNotes();
  }

  Future<void> _editNote(int index) async {
    final note = _notes[index];
    final result = await _showEditor(context, title: note.title, body: note.body);
    if (result == null) return;
    await NotesService().updateNote(widget.itemId, index, title: result.title, body: result.body);
    _loadNotes();
  }

  Future<void> _deleteNote(int index) async {
    final l = AppLocalizations.of(context)!;
    final noteTitle = _notes[index].title.isEmpty ? l.untitledNote : _notes[index].title;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.notesDeleteNoteQuestion),
        content: Text(l.notesDeleteNoteContent(noteTitle)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.delete)),
        ],
      ),
    );
    if (confirmed != true) return;
    await NotesService().deleteNote(widget.itemId, index);
    _loadNotes();
  }

  Future<void> _exportNotes(BuildContext context) async {
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    final format = await showAdaptiveActionMenu<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(child: Container(
              width: 32, height: 4, margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            )),
            ListTile(
              leading: const Icon(Icons.description_rounded),
              title: Text(l.markdownMd),
              subtitle: Text(l.keepsFormattingIntact),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onTap: () => Navigator.pop(ctx, 'md'),
            ),
            ListTile(
              leading: const Icon(Icons.text_snippet_rounded),
              title: Text(l.plainTextTxt),
              subtitle: Text(l.simpleTextNoFormatting),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onTap: () => Navigator.pop(ctx, 'txt'),
            ),
          ],
        ),
      ),
    );
    if (format == null || !mounted) return;

    final buffer = StringBuffer();
    final isMd = format == 'md';
    buffer.writeln(isMd ? '# ${widget.itemTitle} - ${l.notes}' : '${widget.itemTitle} - ${l.notes}');
    buffer.writeln();
    for (final note in _notes) {
      final title = note.title.isEmpty ? l.untitled : note.title;
      buffer.writeln(isMd ? '## $title' : '--- $title ---');
      if (note.body.isNotEmpty) {
        buffer.writeln();
        buffer.writeln(isMd ? note.body : note.body.replaceAll(RegExp(r'[*_`#>]'), ''));
      }
      buffer.writeln();
    }

    final dir = await getTemporaryDirectory();
    final safe = widget.itemTitle.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
    final file = File('${dir.path}/${safe}_notes.$format');
    await file.writeAsString(buffer.toString());
    final box = context.findRenderObject() as RenderBox?;
    final origin = box != null
        ? box.localToGlobal(Offset.zero) & box.size
        : null;
    await Share.shareXFiles([XFile(file.path)], sharePositionOrigin: origin);
  }

  Future<_NoteEditResult?> _showEditor(BuildContext context, {String title = '', String body = ''}) {
    return showAdaptiveActionMenu<_NoteEditResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NoteEditor(title: title, body: body, accent: widget.accent),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          const SizedBox(height: 8),
          Center(child: Container(
            width: 32, height: 4,
            decoration: BoxDecoration(
              color: cs.onSurface.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          )),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
            child: Row(children: [
              Icon(Icons.note_rounded, color: widget.accent, size: 22),
              const SizedBox(width: 10),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.notes, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                  Text(widget.itemTitle, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                ],
              )),
              if (_notes.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.ios_share_rounded),
                  tooltip: l.notesExport,
                  onPressed: () => _exportNotes(context),
                ),
              IconButton(
                icon: const Icon(Icons.add_rounded),
                tooltip: l.notesNewNote,
                onPressed: _addNote,
              ),
            ]),
          ),
          const Divider(height: 1),
          // Notes list
          Expanded(
            child: _isLoading
                ? ListView(controller: widget.scrollController, children: const [
                    SizedBox(height: 80),
                    Center(child: CircularProgressIndicator()),
                  ])
                : _notes.isEmpty
                    ? ListView(controller: widget.scrollController, children: [
                        const SizedBox(height: 80),
                        Icon(Icons.note_add_rounded, size: 48,
                          color: cs.onSurface.withValues(alpha: 0.15)),
                        const SizedBox(height: 12),
                        Center(child: Text(l.noNotesYet, style: tt.bodyMedium?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.4)))),
                        const SizedBox(height: 8),
                        Center(child: Text(l.markdownIsSupported, style: tt.bodySmall?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.25)))),
                      ])
                    : ListView.separated(
                        controller: widget.scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                        itemCount: _notes.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final note = _notes[index];
                          return Dismissible(
                            key: ValueKey('${note.createdAt.toIso8601String()}_$index'),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              decoration: BoxDecoration(
                                color: cs.error.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(Icons.delete_outline_rounded, color: cs.error),
                            ),
                            confirmDismiss: (_) async {
                              return await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: Text(l.notesDeleteNoteQuestion),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
                                    FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.delete)),
                                  ],
                                ),
                              ) ?? false;
                            },
                            onDismissed: (_) async {
                              await NotesService().deleteNote(widget.itemId, index);
                              _loadNotes();
                            },
                            child: _NoteCard(
                              note: note,
                              accent: widget.accent,
                              untitledLabel: l.untitled,
                              justNowLabel: l.justNow,
                              minutesAgoFn: l.minutesAgo,
                              hoursAgoFn: l.hoursAgo,
                              daysAgoFn: l.daysAgo,
                              onTap: () => _editNote(index),
                              onDelete: () => _deleteNote(index),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

// ── Note Card ──

class _NoteCard extends StatelessWidget {
  final Note note;
  final Color accent;
  final String untitledLabel;
  final String justNowLabel;
  final String Function(int) minutesAgoFn;
  final String Function(int) hoursAgoFn;
  final String Function(int) daysAgoFn;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _NoteCard({
    required this.note,
    required this.accent,
    required this.untitledLabel,
    required this.justNowLabel,
    required this.minutesAgoFn,
    required this.hoursAgoFn,
    required this.daysAgoFn,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final title = note.title.isEmpty ? untitledLabel : note.title;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onDelete,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(child: Text(title,
                style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                maxLines: 1, overflow: TextOverflow.ellipsis)),
              Text(_formatDate(note.updatedAt),
                style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
            ]),
            if (note.body.isNotEmpty) ...[
              const SizedBox(height: 8),
              MarkdownBody(
                data: note.body,
                shrinkWrap: true,
                selectable: true,
                onTapLink: (_, href, __) {
                  if (href != null) launchUrl(Uri.parse(href));
                },
                styleSheet: MarkdownStyleSheet(
                  p: tt.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.8), height: 1.5),
                  h1: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  h2: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  h3: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  code: tt.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    color: accent,
                    backgroundColor: cs.surfaceContainerHighest,
                  ),
                  codeblockDecoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  blockquoteDecoration: BoxDecoration(
                    border: Border(left: BorderSide(color: accent, width: 3)),
                  ),
                  blockquotePadding: const EdgeInsets.only(left: 12),
                  listBullet: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return justNowLabel;
    if (diff.inHours < 1) return minutesAgoFn(diff.inMinutes);
    if (diff.inDays < 1) return hoursAgoFn(diff.inHours);
    if (diff.inDays < 7) return daysAgoFn(diff.inDays);
    return '${dt.month}/${dt.day}/${dt.year}';
  }
}

// ── Note Editor ──

class _NoteEditResult {
  final String title;
  final String body;
  const _NoteEditResult(this.title, this.body);
}

class _NoteEditor extends StatefulWidget {
  final String title;
  final String body;
  final Color accent;

  const _NoteEditor({required this.title, required this.body, required this.accent});

  @override
  State<_NoteEditor> createState() => _NoteEditorState();
}

class _NoteEditorState extends State<_NoteEditor> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _bodyCtrl;
  bool _preview = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.title);
    _bodyCtrl = TextEditingController(text: widget.body);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Center(child: Container(
            width: 32, height: 4,
            decoration: BoxDecoration(
              color: cs.onSurface.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          )),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
            child: Row(children: [
              Expanded(child: Text(
                widget.title.isEmpty ? l.newNote : l.editNote,
                style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              )),
              IconButton(
                icon: Icon(_preview ? Icons.edit_rounded : Icons.preview_rounded),
                tooltip: _preview ? l.edit : l.preview,
                onPressed: () => setState(() => _preview = !_preview),
              ),
              TextButton(
                onPressed: () {
                  final title = _titleCtrl.text.trim();
                  final body = _bodyCtrl.text.trim();
                  if (title.isEmpty && body.isEmpty) {
                    Navigator.pop(context);
                    return;
                  }
                  Navigator.pop(context, _NoteEditResult(title, body));
                },
                child: Text(l.save),
              ),
            ]),
          ),
          const Divider(height: 1),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _titleCtrl,
                    decoration: InputDecoration(
                      hintText: l.titleHint,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  if (_preview)
                    Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(minHeight: 200),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _bodyCtrl.text.trim().isEmpty
                          ? Text(l.nothingToPreview, style: tt.bodySmall?.copyWith(
                              color: cs.onSurface.withValues(alpha: 0.3)))
                          : MarkdownBody(
                              data: _bodyCtrl.text,
                              selectable: true,
                              onTapLink: (_, href, __) {
                                if (href != null) launchUrl(Uri.parse(href));
                              },
                              styleSheet: MarkdownStyleSheet(
                                p: tt.bodySmall?.copyWith(
                                  color: cs.onSurface.withValues(alpha: 0.8), height: 1.5),
                                h1: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                                h2: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                                h3: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                                code: tt.bodySmall?.copyWith(
                                  fontFamily: 'monospace',
                                  color: widget.accent,
                                  backgroundColor: cs.surfaceContainerHighest,
                                ),
                                codeblockDecoration: BoxDecoration(
                                  color: cs.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                blockquoteDecoration: BoxDecoration(
                                  border: Border(left: BorderSide(color: widget.accent, width: 3)),
                                ),
                                blockquotePadding: const EdgeInsets.only(left: 12),
                                listBullet: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                              ),
                            ),
                    )
                  else
                    TextField(
                      controller: _bodyCtrl,
                      decoration: InputDecoration(
                        hintText: l.noteBodyHint,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.all(14),
                      ),
                      maxLines: null,
                      minLines: 8,
                      style: tt.bodySmall?.copyWith(height: 1.5),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
