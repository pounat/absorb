import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/rmab_service.dart';
import '../services/scoped_prefs.dart';
import 'rmab_book_detail_sheet.dart';
import 'rmab_config_sheet.dart'
    show kRmabBaseUrlKey, kRmabApiTokenKey, loadRmabCustomHeaders;
import 'rmab_request_status_chip.dart';
import 'stackable_sheet.dart';

/// Open the RMAB search-results sheet, prefilled with [initialQuery] and
/// running the first search automatically when the query is non-empty.
Future<void> showRmabSearchResultsSheet(
  BuildContext context, {
  required String initialQuery,
}) {
  return showStackableSheet<void>(
    context: context,
    initialChildSize: 0.85,
    maxChildSize: 0.95,
    showHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    useSafeArea: true,
    builder: (ctx, sc) => _RmabSearchSheetContent(
      initialQuery: initialQuery,
      scrollController: sc,
    ),
  );
}

class _RmabSearchSheetContent extends StatefulWidget {
  const _RmabSearchSheetContent({
    required this.initialQuery,
    required this.scrollController,
  });

  final String initialQuery;
  final ScrollController scrollController;

  @override
  State<_RmabSearchSheetContent> createState() =>
      _RmabSearchSheetContentState();
}

class _RmabSearchSheetContentState extends State<_RmabSearchSheetContent> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialQuery);
  final _focus = FocusNode();
  Timer? _debounce;

  bool _loadingPrefs = true;
  String? _baseUrl;
  String? _apiToken;
  Map<String, String> _customHeaders = const {};

  bool _searching = false;
  String? _error;
  List<RmabSearchResult> _results = [];

  /// Query that produced the current [_results] — used to ignore stale
  /// responses after the user has typed something new.
  String _lastQuery = '';

  @override
  void initState() {
    super.initState();
    _loadCreds();
  }

  Future<void> _loadCreds() async {
    final base = await ScopedPrefs.getString(kRmabBaseUrlKey);
    final token = await ScopedPrefs.getString(kRmabApiTokenKey);
    final headers = await loadRmabCustomHeaders();
    if (!mounted) return;
    debugPrint('[RMAB] search sheet opened '
        '(initialQuery="${widget.initialQuery}" '
        'configured=${(base ?? '').isNotEmpty && (token ?? '').isNotEmpty})');
    setState(() {
      _baseUrl = base;
      _apiToken = token;
      _customHeaders = headers;
      _loadingPrefs = false;
    });
    if (base != null &&
        base.isNotEmpty &&
        token != null &&
        token.isNotEmpty &&
        widget.initialQuery.trim().isNotEmpty) {
      _runSearch(widget.initialQuery.trim());
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _results = [];
        _error = null;
        _searching = false;
        _lastQuery = '';
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _runSearch(trimmed);
    });
  }

  Future<void> _runSearch(String query) async {
    final base = _baseUrl;
    final token = _apiToken;
    if (base == null || base.isEmpty || token == null || token.isEmpty) {
      return;
    }
    setState(() {
      _searching = true;
      _error = null;
    });
    try {
      final res = await RmabService(
              baseUrl: base, apiToken: token, customHeaders: _customHeaders)
          .search(query);
      if (!mounted) return;
      // Drop stale results
      if (_controller.text.trim() != query) return;
      setState(() {
        _results = res.results;
        _searching = false;
        _lastQuery = query;
      });
    } on RmabException catch (e) {
      if (!mounted) return;
      debugPrint('[RMAB] search sheet error: ${e.kind} ${e.message}');
      final l = AppLocalizations.of(context)!;
      setState(() {
        _searching = false;
        _error = e.localizedMessage(l, l.rmabSearchError);
      });
    } catch (e) {
      if (!mounted) return;
      debugPrint('[RMAB] search sheet unexpected error: $e');
      setState(() {
        _searching = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;

    return ClipRRect(
      borderRadius:
          const BorderRadius.vertical(top: Radius.circular(24)),
      child: Container(
        color: cs.surface,
        child: Column(
          children: [
            // ── Header row ────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 12, 4),
              child: Row(
                children: [
                  Icon(Icons.menu_book_rounded,
                      color: cs.primary, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l.rmabSearchHeader,
                      style: tt.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: l.cancel,
                  ),
                ],
              ),
            ),

            // ── Search field ──────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: TextField(
                controller: _controller,
                focusNode: _focus,
                autocorrect: false,
                onChanged: _onQueryChanged,
                onSubmitted: (v) => _runSearch(v.trim()),
                decoration: InputDecoration(
                  hintText: l.rmabSearchHint,
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _controller.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            _controller.clear();
                            _onQueryChanged('');
                            _focus.requestFocus();
                          },
                        ),
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),

            const Divider(height: 1),

            // ── Body ──────────────────────────────────
            Expanded(child: _buildBody(cs, tt, l)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
      ColorScheme cs, TextTheme tt, AppLocalizations l) {
    if (_loadingPrefs) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (_searching) {
      return ListView(
        controller: widget.scrollController,
        children: const [
          SizedBox(height: 80),
          Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ],
      );
    }
    if (_error != null) {
      return ListView(
        controller: widget.scrollController,
        padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
        children: [
          Icon(Icons.error_outline_rounded,
              size: 40, color: cs.error),
          const SizedBox(height: 12),
          Center(
            child: Text(
              _error!,
              textAlign: TextAlign.center,
              style: tt.bodyMedium?.copyWith(color: cs.error),
            ),
          ),
        ],
      );
    }
    if (_lastQuery.isEmpty) {
      return ListView(
        controller: widget.scrollController,
        padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
        children: [
          Icon(Icons.search_rounded,
              size: 40, color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          Center(
            child: Text(
              l.rmabSearchPrompt,
              textAlign: TextAlign.center,
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
        ],
      );
    }
    if (_results.isEmpty) {
      return ListView(
        controller: widget.scrollController,
        padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
        children: [
          Icon(Icons.search_off_rounded,
              size: 40, color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          Center(
            child: Text(
              l.rmabSearchEmpty,
              textAlign: TextAlign.center,
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      controller: widget.scrollController,
      padding: EdgeInsets.fromLTRB(
          16, 8, 16, 24 + MediaQuery.of(context).viewPadding.bottom),
      itemCount: _results.length,
      itemBuilder: (_, i) => _RmabResultRow(
        book: _results[i],
        onTap: () => showRmabBookDetailSheet(context, book: _results[i]),
      ),
    );
  }
}

class _RmabResultRow extends StatelessWidget {
  const _RmabResultRow({required this.book, required this.onTap});
  final RmabSearchResult book;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;

    // Merge the server's view with our session-local cache so a freshly
    // requested book shows the status chip immediately, even before the
    // next search round-trip refreshes the data.
    final cachedStatus = RmabLocalRequestCache.statusFor(book.asin);
    final effectiveStatus = book.requestStatus ?? cachedStatus;
    final effectiveRequested = book.isRequested || cachedStatus != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 64,
                    height: 64,
                    child: (book.coverArtUrl == null ||
                            book.coverArtUrl!.isEmpty)
                        ? Container(
                            color: cs.surfaceContainerHighest,
                            child: Icon(Icons.menu_book_rounded,
                                color: cs.onSurfaceVariant, size: 22),
                          )
                        : CachedNetworkImage(
                            imageUrl: book.coverArtUrl!,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                                color: cs.surfaceContainerHighest),
                            errorWidget: (_, __, ___) => Container(
                              color: cs.surfaceContainerHighest,
                              child: Icon(Icons.broken_image_rounded,
                                  color: cs.onSurfaceVariant, size: 22),
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: tt.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      if (book.author.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          book.author,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: tt.bodySmall
                              ?.copyWith(color: cs.onSurfaceVariant),
                        ),
                      ],
                      if (book.narrator != null &&
                          book.narrator!.isNotEmpty) ...[
                        const SizedBox(height: 1),
                        Text(
                          l.narratedBy(book.narrator!),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: tt.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant
                                  .withValues(alpha: 0.7)),
                        ),
                      ],
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          if (book.releaseYear != null)
                            _miniTag(
                                cs, tt, Icons.event_rounded,
                                '${book.releaseYear}'),
                          if (book.isAvailable)
                            _miniTag(
                              cs,
                              tt,
                              Icons.check_circle_rounded,
                              l.rmabBookAlreadyAvailable,
                              color: Colors.green.shade600,
                            ),
                          if (effectiveRequested && effectiveStatus != null)
                            RmabRequestStatusChip(
                                rawStatus: effectiveStatus),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _miniTag(
    ColorScheme cs,
    TextTheme tt,
    IconData icon,
    String label, {
    Color? color,
  }) {
    final c = color ?? cs.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: c),
          const SizedBox(width: 4),
          Text(label,
              style:
                  tt.labelSmall?.copyWith(color: c, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
