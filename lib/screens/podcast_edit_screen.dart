import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/library_provider.dart';
import '../widgets/overlay_toast.dart';

/// Full-screen editor for a podcast show's info (title, author, description,
/// genres, tags, language, release date, explicit flag and cover art).
/// Admin-only; saves via [ApiService.updateItemMedia], which PATCHes
/// /api/items/:id/media. ABS merges the metadata partially, so only the fields
/// edited here are sent - feedUrl, itunes ids etc. are left untouched.
class PodcastEditScreen extends StatefulWidget {
  final String itemId;
  final Map<String, dynamic> metadata;
  final List<String> tags;
  final VoidCallback? onSaved;

  const PodcastEditScreen({
    super.key,
    required this.itemId,
    required this.metadata,
    this.tags = const [],
    this.onSaved,
  });

  @override
  State<PodcastEditScreen> createState() => _PodcastEditScreenState();
}

class _PodcastEditScreenState extends State<PodcastEditScreen> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _authorCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _genresCtrl;
  late final TextEditingController _tagsCtrl;
  late final TextEditingController _languageCtrl;
  late final TextEditingController _releaseDateCtrl;
  late final TextEditingController _coverUrlCtrl;
  late final TextEditingController _coverSearchCtrl;

  bool _explicit = false;
  bool _saving = false;
  String? _coverFilePath;
  int _coverVersion = 0;
  List<String> _coverResults = [];
  bool _coverSearching = false;

  @override
  void initState() {
    super.initState();
    final m = widget.metadata;
    _titleCtrl = TextEditingController(text: m['title'] as String? ?? '');
    _authorCtrl = TextEditingController(text: m['author'] as String? ?? '');
    _descCtrl = TextEditingController(text: m['description'] as String? ?? '');
    final genres = (m['genres'] as List<dynamic>?)?.whereType<String>() ?? const [];
    _genresCtrl = TextEditingController(text: genres.join(', '));
    _tagsCtrl = TextEditingController(text: widget.tags.join(', '));
    _languageCtrl = TextEditingController(text: m['language'] as String? ?? '');
    _releaseDateCtrl = TextEditingController(text: m['releaseDate'] as String? ?? '');
    _coverUrlCtrl = TextEditingController();
    _coverSearchCtrl = TextEditingController(text: m['title'] as String? ?? '');
    _explicit = m['explicit'] == true;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _authorCtrl.dispose();
    _descCtrl.dispose();
    _genresCtrl.dispose();
    _tagsCtrl.dispose();
    _languageCtrl.dispose();
    _releaseDateCtrl.dispose();
    _coverUrlCtrl.dispose();
    _coverSearchCtrl.dispose();
    super.dispose();
  }

  void _msg(String s) => showOverlayToast(context, s);

  List<String> _splitList(String text) => text.trim().isEmpty
      ? <String>[]
      : text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

  Future<void> _pickCover() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image, allowMultiple: false);
    if (result != null && result.files.single.path != null) {
      setState(() {
        _coverFilePath = result.files.single.path;
        _coverUrlCtrl.clear();
      });
    }
  }

  Future<void> _searchCovers() async {
    final api = context.read<AuthProvider>().apiService;
    final query = _coverSearchCtrl.text.trim();
    if (api == null || query.isEmpty) return;
    setState(() => _coverSearching = true);
    final results = await api.searchCovers(query, author: _authorCtrl.text.trim(), provider: 'itunes');
    if (!mounted) return;
    setState(() {
      _coverResults = results;
      _coverSearching = false;
    });
  }

  Future<void> _save() async {
    final api = context.read<AuthProvider>().apiService;
    if (api == null) return;
    setState(() => _saving = true);

    final metadata = <String, dynamic>{
      'title': _titleCtrl.text.trim(),
      'author': _authorCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'releaseDate': _releaseDateCtrl.text.trim(),
      'language': _languageCtrl.text.trim(),
      'explicit': _explicit,
      'genres': _splitList(_genresCtrl.text),
    };

    bool ok = await api.updateItemMedia(widget.itemId, metadata, tags: _splitList(_tagsCtrl.text));
    if (ok && _coverFilePath != null) {
      ok = await api.uploadItemCover(widget.itemId, _coverFilePath!);
    } else if (ok && _coverUrlCtrl.text.trim().isNotEmpty) {
      ok = await api.updateItemCoverUrl(widget.itemId, _coverUrlCtrl.text.trim());
    }

    if (!mounted) return;
    final l = AppLocalizations.of(context)!;
    setState(() {
      _saving = false;
      if (ok) {
        _coverVersion++;
        _coverFilePath = null;
        _coverResults = [];
      }
    });
    _msg(ok ? l.metadataUpdated : l.failedToUpdateMetadata);
    if (ok) {
      context.read<LibraryProvider>().refresh();
      widget.onSaved?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;
    final auth = context.read<AuthProvider>();
    final serverCover = '${auth.serverUrl}/api/items/${widget.itemId}/cover';

    return Scaffold(
      appBar: AppBar(
        title: Text(l.adminPodcastsEditTitle),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: cs.onPrimary))
                  : const Icon(Icons.check_rounded, size: 18),
              label: Text(l.save),
              style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(20, 12, 20,
            32 + MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).viewPadding.bottom),
        children: [
          // Cover
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 160,
                height: 160,
                child: _coverPreview(cs, serverCover),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: OutlinedButton.icon(
              onPressed: _pickCover,
              icon: const Icon(Icons.image_rounded, size: 18),
              label: Text(l.file),
              style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            )),
          ]),
          const SizedBox(height: 8),
          TextField(
            controller: _coverUrlCtrl,
            decoration: InputDecoration(
              labelText: l.coverUrlLabel,
              hintText: l.coverUrlHint,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              isDense: true,
            ),
            style: tt.bodyMedium,
            onChanged: (_) => setState(() => _coverFilePath = null),
          ),
          const SizedBox(height: 8),
          // Cover search (iTunes)
          Row(children: [
            Expanded(child: TextField(
              controller: _coverSearchCtrl,
              decoration: InputDecoration(
                labelText: l.coverSearchTitle,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                isDense: true,
              ),
              style: tt.bodyMedium,
              onSubmitted: (_) => _searchCovers(),
            )),
            const SizedBox(width: 8),
            FilledButton.tonalIcon(
              onPressed: _coverSearching ? null : _searchCovers,
              icon: _coverSearching
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.search_rounded, size: 18),
              label: Text(l.search),
            ),
          ]),
          if (_coverResults.isNotEmpty) ...[
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              children: [
                for (final url in _coverResults)
                  GestureDetector(
                    onTap: () => setState(() {
                      _coverUrlCtrl.text = url;
                      _coverFilePath = null;
                    }),
                    child: Container(
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                        border: _coverUrlCtrl.text == url ? Border.all(color: cs.primary, width: 2) : null,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: CachedNetworkImage(imageUrl: url, fit: BoxFit.cover),
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 24),

          // Text fields
          _field(l.titleLabel, _titleCtrl, tt),
          _field(l.authorLabel, _authorCtrl, tt),
          _field(l.descriptionLabel, _descCtrl, tt, maxLines: 6),
          _field(l.genresLabel, _genresCtrl, tt, hint: l.commaSeparated),
          _field(l.tagsLabel, _tagsCtrl, tt, hint: l.commaSeparated),
          Row(children: [
            Expanded(child: _field(l.languageLabel, _languageCtrl, tt)),
            const SizedBox(width: 12),
            Expanded(child: _field(l.adminPodcastsReleaseDate, _releaseDateCtrl, tt)),
          ]),
          const SizedBox(height: 4),
          // Explicit
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(color: cs.surfaceContainerHigh, borderRadius: BorderRadius.circular(12)),
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l.adminPodcastsExplicit, style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: cs.onSurface)),
              subtitle: Text(l.adminPodcastsExplicitSubtitle, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
              value: _explicit,
              onChanged: (v) => setState(() => _explicit = v),
            ),
          ),
        ],
      ),
    );
  }

  Widget _coverPreview(ColorScheme cs, String serverCover) {
    if (_coverFilePath != null) {
      return Image.file(File(_coverFilePath!), fit: BoxFit.cover, errorBuilder: (_, __, ___) => _coverPlaceholder(cs));
    }
    final url = _coverUrlCtrl.text.trim();
    final headers = context.read<AuthProvider>().apiService?.mediaHeaders;
    if (url.isNotEmpty) {
      return CachedNetworkImage(imageUrl: url, fit: BoxFit.cover,
        placeholder: (_, __) => _coverPlaceholder(cs), errorWidget: (_, __, ___) => _coverPlaceholder(cs));
    }
    return CachedNetworkImage(
      imageUrl: '$serverCover?v=$_coverVersion',
      httpHeaders: headers,
      fit: BoxFit.cover,
      placeholder: (_, __) => _coverPlaceholder(cs),
      errorWidget: (_, __, ___) => _coverPlaceholder(cs),
    );
  }

  Widget _coverPlaceholder(ColorScheme cs) => Container(
        color: cs.surfaceContainerHighest,
        child: Icon(Icons.podcasts_rounded, color: cs.onSurfaceVariant.withValues(alpha: 0.3), size: 32),
      );

  Widget _field(String label, TextEditingController ctrl, TextTheme tt, {int maxLines = 1, String? hint}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          isDense: true,
        ),
        style: tt.bodyMedium,
      ),
    );
  }
}
