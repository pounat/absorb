import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/library_provider.dart';
import 'adaptive_modal.dart';
import 'overlay_toast.dart';

/// Opens a full-screen editor for an author (root admin only).
/// Two tabs:
///   Quick Match - asks the server to pull name / asin / description / image
///                 from the configured provider (Audible) for the given region.
///   Custom      - manual editing of name / asin / description / image URL.
///
/// [onUpdated] is called after a successful save/match so the parent sheet can
/// reload its data. [onMerged] is called when the server reports the author was
/// merged into another author (because the new name matched an existing one);
/// the parent should close itself since this author id no longer exists.
void showEditAuthorSheet(
  BuildContext context, {
  required String authorId,
  required String currentName,
  String? currentDescription,
  String? currentAsin,
  String? currentImageUrl,
  required VoidCallback onUpdated,
  required void Function(String mergedIntoId, String mergedIntoName) onMerged,
}) {
  showAdaptiveSheetDialog(
    context: context,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    expand: false,
    initialChildSize: 0.85,
    minChildSize: 0.3,
    maxChildSize: 0.95,
    snap: true,
    builder: (ctx, sc) => _EditAuthorContent(
      authorId: authorId,
      currentName: currentName,
      currentDescription: currentDescription,
      currentAsin: currentAsin,
      currentImageUrl: currentImageUrl,
      scrollController: sc,
      onUpdated: onUpdated,
      onMerged: onMerged,
    ),
  );
}

class _EditAuthorContent extends StatefulWidget {
  final String authorId;
  final String currentName;
  final String? currentDescription;
  final String? currentAsin;
  final String? currentImageUrl;
  final ScrollController scrollController;
  final VoidCallback onUpdated;
  final void Function(String mergedIntoId, String mergedIntoName) onMerged;

  const _EditAuthorContent({
    required this.authorId,
    required this.currentName,
    required this.currentDescription,
    required this.currentAsin,
    required this.currentImageUrl,
    required this.scrollController,
    required this.onUpdated,
    required this.onMerged,
  });

  @override
  State<_EditAuthorContent> createState() => _EditAuthorContentState();
}

class _EditAuthorContentState extends State<_EditAuthorContent>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  // Custom edit controllers
  late final TextEditingController _nameCtrl;
  late final TextEditingController _asinCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _imageUrlCtrl;

  // Quick match
  late final TextEditingController _searchCtrl;
  String _region = 'us';
  bool _matching = false;
  Map<String, dynamic>? _matchResult;
  bool _matchEmpty = false;

  bool _saving = false;

  // Audible region codes - matches ABS web client
  static const _regions = ['us', 'ca', 'uk', 'au', 'fr', 'de', 'jp', 'it', 'in', 'es'];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _nameCtrl = TextEditingController(text: widget.currentName);
    _asinCtrl = TextEditingController(text: widget.currentAsin ?? '');
    _descCtrl = TextEditingController(text: widget.currentDescription ?? '');
    _imageUrlCtrl = TextEditingController();
    _searchCtrl = TextEditingController(text: widget.currentName);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _nameCtrl.dispose();
    _asinCtrl.dispose();
    _descCtrl.dispose();
    _imageUrlCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ─── Quick Match ────────────────────────────────────────────

  Future<void> _runMatch() async {
    final q = _searchCtrl.text.trim();
    if (q.isEmpty) return;
    final api = context.read<AuthProvider>().apiService;
    if (api == null) return;

    setState(() { _matching = true; _matchResult = null; _matchEmpty = false; });

    final match = await api.quickMatchAuthor(
      widget.authorId,
      q: q,
      region: _region,
    );
    final result = match.author;

    if (!mounted) return;
    setState(() {
      _matching = false;
      if (result == null || result.isEmpty) {
        _matchEmpty = match.statusCode == 404;
      } else {
        _matchResult = result;
        // Sync the Custom tab fields with the matched values so editing
        // continues from the new data instead of the old.
        final matchedName = result['name'] as String?;
        final matchedAsin = result['asin'] as String?;
        final matchedDesc = result['description'] as String?;
        if (matchedName != null) _nameCtrl.text = matchedName;
        if (matchedAsin != null) _asinCtrl.text = matchedAsin;
        if (matchedDesc != null) _descCtrl.text = matchedDesc;
      }
    });

    final l = AppLocalizations.of(context)!;
    if (match.found) {
      if (match.updated) widget.onUpdated();
      _showToast(
        match.updated ? l.authorMatched : l.quickMatchNoUpdates,
        icon: Icons.check_circle_rounded,
      );
    } else if (match.statusCode == 404) {
      _showToast(l.authorNoMatchFound, icon: Icons.search_off_rounded);
    } else {
      _showToast(l.failedToUpdateMetadata, icon: Icons.error_outline_rounded);
    }
  }

  // ─── Custom Save ────────────────────────────────────────────

  Future<void> _saveCustom() async {
    final api = context.read<AuthProvider>().apiService;
    if (api == null) return;

    setState(() => _saving = true);

    final name = _nameCtrl.text.trim();
    final asin = _asinCtrl.text.trim();
    final desc = _descCtrl.text.trim();
    final imageUrl = _imageUrlCtrl.text.trim();

    final result = await api.updateAuthor(
      widget.authorId,
      name: name,
      asin: asin,
      description: desc,
    );

    if (!mounted) return;

    if (result['ok'] != true) {
      setState(() => _saving = false);
      _showToast(AppLocalizations.of(context)!.authorUpdateFailed, icon: Icons.error_outline_rounded);
      return;
    }

    // Handle "merged into another author" response
    if (result['merged'] is Map) {
      final merged = result['merged'] as Map<String, dynamic>;
      setState(() => _saving = false);
      final mergedId = merged['id'] as String? ?? '';
      final mergedName = merged['name'] as String? ?? '';
      if (mounted) Navigator.of(context).pop();
      widget.onMerged(mergedId, mergedName);
      return;
    }

    // If the user provided an image URL, upload it after the patch.
    if (imageUrl.isNotEmpty) {
      final imgOk = await api.updateAuthorImageFromUrl(widget.authorId, imageUrl);
      if (!imgOk && mounted) {
        setState(() => _saving = false);
        _showToast(AppLocalizations.of(context)!.authorImageFailed, icon: Icons.error_outline_rounded);
        return;
      }
    }

    widget.onUpdated();

    if (mounted) {
      setState(() => _saving = false);
      Navigator.of(context).pop();
      _showToast(AppLocalizations.of(context)!.authorUpdated, icon: Icons.check_circle_rounded);
    }
  }

  Future<void> _removeImage() async {
    final api = context.read<AuthProvider>().apiService;
    if (api == null) return;
    final l = AppLocalizations.of(context)!;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.authorRemoveImageTitle),
        content: Text(l.authorRemoveImageConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade600),
            child: Text(l.remove),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _saving = true);
    final ok = await api.deleteAuthorImage(widget.authorId);
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      widget.onUpdated();
      _showToast(l.authorImageRemoved, icon: Icons.check_circle_rounded);
    } else {
      _showToast(l.authorImageFailed, icon: Icons.error_outline_rounded);
    }
  }

  void _showToast(String text, {IconData? icon}) {
    showOverlayToast(context, text, icon: icon);
  }

  // ─── Build ──────────────────────────────────────────────────

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
      child: Column(children: [
        Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(top: 12, bottom: 8),
          decoration: BoxDecoration(color: cs.onSurface.withValues(alpha: 0.24), borderRadius: BorderRadius.circular(2)))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(children: [
            Text(l.editAuthor, style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            const Spacer(),
            if (_saving || _matching)
              const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
          ]),
        ),
        const SizedBox(height: 8),
        TabBar(
          controller: _tabCtrl,
          labelColor: cs.primary,
          unselectedLabelColor: cs.onSurfaceVariant,
          indicatorColor: cs.primary,
          tabs: [
            Tab(text: l.quickMatch),
            Tab(text: l.custom),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: [
              _buildQuickMatchTab(cs, tt, l),
              _buildCustomTab(cs, tt, l),
            ],
          ),
        ),
      ]),
    );
  }

  // ─── Quick Match Tab ────────────────────────────────────────

  Widget _buildQuickMatchTab(ColorScheme cs, TextTheme tt, AppLocalizations l) {
    return ListView(
      controller: widget.scrollController,
      padding: EdgeInsets.fromLTRB(20, 16, 20, 32 + MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).viewPadding.bottom),
      children: [
        Text(l.authorQuickMatchHint, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
        const SizedBox(height: 12),
        _searchField(_searchCtrl, l.authorName, Icons.person_rounded, cs, tt),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.onSurface.withValues(alpha: 0.08)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _region,
                  isExpanded: true,
                  dropdownColor: cs.surfaceContainerHigh,
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  icon: Icon(Icons.expand_more_rounded, size: 18, color: cs.onSurfaceVariant),
                  items: _regions.map((r) => DropdownMenuItem(
                    value: r,
                    child: Text('${l.region}: ${r.toUpperCase()}'),
                  )).toList(),
                  onChanged: (v) { if (v != null) setState(() => _region = v); },
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            height: 44,
            child: FilledButton.icon(
              onPressed: _matching ? null : _runMatch,
              icon: _matching
                  ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: cs.onPrimary))
                  : const Icon(Icons.search_rounded, size: 18),
              label: Text(l.quickMatch),
              style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            ),
          ),
        ]),
        const SizedBox(height: 20),
        if (_matchResult != null) _matchResultCard(_matchResult!, cs, tt, l)
        else if (_matchEmpty) Padding(
          padding: const EdgeInsets.only(top: 24),
          child: Center(child: Text(
            l.authorNoMatchFound,
            textAlign: TextAlign.center,
            style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant.withValues(alpha: 0.6)),
          )),
        ),
      ],
    );
  }

  Widget _matchResultCard(Map<String, dynamic> result, ColorScheme cs, TextTheme tt, AppLocalizations l) {
    final name = result['name'] as String? ?? '';
    final asin = result['asin'] as String? ?? '';
    final desc = (result['description'] as String? ?? '').replaceAll(RegExp(r'<[^>]*>'), '').trim();
    // ABS saves the matched image server-side and returns the author with an
    // imagePath. Build the URL through the API service (with the auth token)
    // and cache-bust with updatedAt so we don't show the previous cached image.
    final api = context.read<AuthProvider>().apiService;
    final hasImagePath = (result['imagePath'] as String?)?.isNotEmpty == true;
    final ts = (result['updatedAt'] as num?)?.toInt();
    final imageUrl = (api != null && hasImagePath)
        ? api.getAuthorImageUrl(widget.authorId, updatedAt: ts)
        : '';
    final headers = context.read<LibraryProvider>().mediaHeaders;

    return Card(
      elevation: 0,
      color: cs.onSurface.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: cs.onSurface.withValues(alpha: 0.06)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (imageUrl.isNotEmpty)
              ClipOval(
                child: SizedBox(
                  width: 60, height: 60,
                  child: CachedNetworkImage(imageUrl: imageUrl, fit: BoxFit.cover,
                    httpHeaders: headers,
                    placeholder: (_, __) => Container(color: cs.surfaceContainerHighest),
                    errorWidget: (_, __, ___) => Container(color: cs.surfaceContainerHighest,
                      child: Icon(Icons.person_rounded, size: 28, color: cs.onSurfaceVariant)),
                  ),
                ),
              )
            else
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(shape: BoxShape.circle, color: cs.surfaceContainerHighest),
                child: Icon(Icons.person_rounded, size: 28, color: cs.onSurfaceVariant),
              ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (name.isNotEmpty) Text(name, style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
              if (asin.isNotEmpty) Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('ASIN: $asin', style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
              ),
            ])),
          ]),
          if (desc.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(desc, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.4)),
          ],
        ]),
      ),
    );
  }

  Widget _searchField(TextEditingController ctrl, String label, IconData icon, ColorScheme cs, TextTheme tt) {
    return SizedBox(
      height: 44,
      child: TextField(
        controller: ctrl,
        textInputAction: TextInputAction.search,
        onSubmitted: (_) => _runMatch(),
        style: tt.bodyMedium,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          prefixIcon: Icon(icon, size: 18, color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
          filled: true,
          fillColor: cs.onSurface.withValues(alpha: 0.06),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cs.onSurface.withValues(alpha: 0.08))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cs.onSurface.withValues(alpha: 0.08))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cs.primary.withValues(alpha: 0.5))),
        ),
      ),
    );
  }

  // ─── Custom Tab ─────────────────────────────────────────────

  Widget _buildCustomTab(ColorScheme cs, TextTheme tt, AppLocalizations l) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 8, 0),
        child: Row(children: [
          const Spacer(),
          FilledButton.icon(
            onPressed: _saving ? null : _saveCustom,
            icon: _saving
                ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: cs.onPrimary))
                : const Icon(Icons.check_rounded, size: 18),
            label: Text(l.save),
            style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          ),
        ]),
      ),
      const SizedBox(height: 8),
      Expanded(
        child: ListView(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 32 + MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).viewPadding.bottom),
          children: [
            _field(l.authorName, _nameCtrl, tt),
            _field(l.asinLabel, _asinCtrl, tt),
            _field(l.descriptionLabel, _descCtrl, tt, maxLines: 6),
            const SizedBox(height: 12),
            Text(l.authorImage, style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _field(l.coverUrlLabel, _imageUrlCtrl, tt, hint: l.coverUrlHint),
            if (widget.currentImageUrl != null && widget.currentImageUrl!.isNotEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _saving ? null : _removeImage,
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: Text(l.authorRemoveImage),
                  style: TextButton.styleFrom(foregroundColor: cs.error),
                ),
              ),
          ],
        ),
      ),
    ]);
  }

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
