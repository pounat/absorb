import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/rmab_service.dart';
import '../services/scoped_prefs.dart';
import 'html_description.dart';
import 'overlay_toast.dart';
import 'rmab_config_sheet.dart' show kRmabBaseUrlKey, kRmabApiTokenKey;
import 'rmab_request_status_chip.dart';
import 'stackable_sheet.dart';

/// Show the RMAB book detail sheet for [book]. The sheet renders without any
/// extra network roundtrip — the search response already carries every field
/// we need.
Future<void> showRmabBookDetailSheet(
  BuildContext context, {
  required RmabSearchResult book,
}) {
  debugPrint('[RMAB] detail sheet opened (asin=${book.asin} '
      'title="${book.title}" isAvailable=${book.isAvailable} '
      'isRequested=${book.isRequested} status=${book.requestStatus ?? '-'})');
  return showStackableSheet<void>(
    context: context,
    initialChildSize: 0.85,
    maxChildSize: 0.95,
    showHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    useSafeArea: true,
    builder: (ctx, sc) =>
        _RmabBookDetailContent(book: book, scrollController: sc),
  );
}

class _RmabBookDetailContent extends StatefulWidget {
  const _RmabBookDetailContent({
    required this.book,
    required this.scrollController,
  });

  final RmabSearchResult book;
  final ScrollController scrollController;

  @override
  State<_RmabBookDetailContent> createState() =>
      _RmabBookDetailContentState();
}

class _RmabBookDetailContentState extends State<_RmabBookDetailContent> {
  bool _submitting = false;

  /// Local mirror of the book's request state. Seeded from (a) the search
  /// result we were handed, OR (b) the session-local cache for cases where
  /// the user just requested this book moments ago via a different open of
  /// this sheet. The cache means dismiss + reopen no longer "forgets" the
  /// request.
  late bool _isRequested = widget.book.isRequested ||
      RmabLocalRequestCache.statusFor(widget.book.asin) != null;
  late String? _localRequestStatus = widget.book.requestStatus ??
      RmabLocalRequestCache.statusFor(widget.book.asin);

  Future<void> _submitRequest() async {
    final l = AppLocalizations.of(context)!;
    debugPrint('[RMAB] detail Request tapped (asin=${widget.book.asin})');
    final base = await ScopedPrefs.getString(kRmabBaseUrlKey);
    final token = await ScopedPrefs.getString(kRmabApiTokenKey);
    if (!mounted) return;
    if (base == null || base.isEmpty || token == null || token.isEmpty) {
      debugPrint('[RMAB] detail Request: missing creds, prompting reconnect');
      _toast(l.rmabRequestErrorTokenRejected);
      return;
    }

    setState(() => _submitting = true);

    try {
      final result = await RmabService(baseUrl: base, apiToken: token)
          .createRequest(RmabRequestInput.fromSearchResult(widget.book));

      if (!mounted) return;

      if (result is RmabCreateSuccess) {
        RmabLocalRequestCache.markRequested(
            widget.book.asin, result.request.status);
        setState(() {
          _submitting = false;
          _isRequested = true;
          _localRequestStatus = result.request.status;
        });
        _toast(l.rmabRequestSent);
        return;
      }

      if (result is RmabCreateNamedError) {
        setState(() => _submitting = false);
        _toast(_messageForCreateError(result.kind, l));
        // For already-available / duplicate / processed, flip the UI to
        // reflect the server's view of the world — and remember it for
        // subsequent re-opens of this sheet.
        if (result.kind == RmabCreateErrorKind.duplicateRequest ||
            result.kind == RmabCreateErrorKind.beingProcessed) {
          final inferredStatus =
              result.kind == RmabCreateErrorKind.beingProcessed
                  ? 'processing'
                  : 'pending';
          RmabLocalRequestCache.markRequested(
              widget.book.asin, inferredStatus);
          setState(() {
            _isRequested = true;
            _localRequestStatus ??= inferredStatus;
          });
        }
      }
    } on RmabException catch (e) {
      if (!mounted) return;
      debugPrint('[RMAB] detail submit exception: ${e.kind} ${e.message}');
      setState(() => _submitting = false);
      _toast(e.localizedMessage(l, l.rmabRequestErrorGeneric));
    } catch (e) {
      if (!mounted) return;
      debugPrint('[RMAB] detail submit unexpected: $e');
      setState(() => _submitting = false);
      _toast('${l.rmabRequestErrorGeneric}: $e');
    }
  }

  String _messageForCreateError(
      RmabCreateErrorKind kind, AppLocalizations l) {
    switch (kind) {
      case RmabCreateErrorKind.alreadyAvailable:
        return l.rmabRequestErrorAlreadyAvailable;
      case RmabCreateErrorKind.beingProcessed:
        return l.rmabRequestErrorBeingProcessed;
      case RmabCreateErrorKind.duplicateRequest:
        return l.rmabRequestErrorDuplicate;
      case RmabCreateErrorKind.ignored:
        return l.rmabRequestErrorIgnored;
      case RmabCreateErrorKind.userNotFound:
        return l.rmabRequestErrorUserNotFound;
      case RmabCreateErrorKind.validationError:
        return l.rmabRequestErrorValidation;
      case RmabCreateErrorKind.requestError:
        return l.rmabRequestErrorGeneric;
    }
  }

  void _toast(String msg) {
    showOverlayToast(context, msg);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;
    final book = widget.book;

    final hasDescription =
        book.description != null && book.description!.trim().isNotEmpty;

    return ClipRRect(
      borderRadius:
          const BorderRadius.vertical(top: Radius.circular(24)),
      child: Container(
        color: cs.surface,
        child: ListView(
          controller: widget.scrollController,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            // ── Cover + headline ────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Cover(url: book.coverArtUrl),
                const SizedBox(width: 16),
                Expanded(child: _Headline(book: book)),
              ],
            ),
            const SizedBox(height: 16),

            // ── Meta row (year + duration + rating) ────
            _MetaRow(book: book),

            // ── Status banner if relevant ──────────────
            if (book.isAvailable) ...[
              const SizedBox(height: 14),
              _Banner(
                icon: Icons.check_circle_rounded,
                color: Colors.green.shade600,
                text: l.rmabBookAlreadyAvailable,
              ),
            ] else if (_isRequested) ...[
              const SizedBox(height: 14),
              _RequestedBanner(rawStatus: _localRequestStatus ?? 'pending'),
            ],

            // ── Explainer ──────────────────────────────
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 18, color: cs.onSurfaceVariant),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l.rmabBookDetailExplainer,
                      style: tt.bodySmall
                          ?.copyWith(color: cs.onSurfaceVariant, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),

            // ── Description ────────────────────────────
            if (hasDescription) ...[
              const SizedBox(height: 18),
              HtmlDescription(html: book.description!, maxLines: 8),
            ],

            // ── Request CTA ────────────────────────────
            const SizedBox(height: 24),
            _RequestButton(
              disabled: book.isAvailable || _isRequested,
              submitting: _submitting,
              onPressed: _submitRequest,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ─── Sub-widgets ───────────────────────────────────────────────────

class _Cover extends StatelessWidget {
  const _Cover({required this.url});
  final String? url;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 110,
        height: 110,
        child: url == null || url!.isEmpty
            ? Container(
                color: cs.surfaceContainerHighest,
                child: Icon(Icons.menu_book_rounded,
                    color: cs.onSurfaceVariant, size: 36),
              )
            : CachedNetworkImage(
                imageUrl: url!,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: cs.surfaceContainerHighest),
                errorWidget: (_, __, ___) => Container(
                  color: cs.surfaceContainerHighest,
                  child: Icon(Icons.broken_image_rounded,
                      color: cs.onSurfaceVariant, size: 36),
                ),
              ),
      ),
    );
  }
}

class _Headline extends StatelessWidget {
  const _Headline({required this.book});
  final RmabSearchResult book;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          book.title,
          style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        if (book.author.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(book.author,
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
        ],
        if (book.narrator != null && book.narrator!.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(l.narratedBy(book.narrator!),
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
        ],
        if (book.series != null && book.series!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            book.seriesPart != null && book.seriesPart!.isNotEmpty
                ? '${book.series}, ${book.seriesPart}'
                : book.series!,
            style: tt.bodySmall?.copyWith(
                color: cs.primary, fontWeight: FontWeight.w600),
          ),
        ],
      ],
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.book});
  final RmabSearchResult book;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final items = <Widget>[];

    final year = book.releaseYear;
    if (year != null) {
      items.add(_chip(cs, tt, Icons.event_rounded, '$year'));
    }
    if (book.durationMinutes != null && book.durationMinutes! > 0) {
      final h = book.durationMinutes! ~/ 60;
      final m = book.durationMinutes! % 60;
      final text = h > 0 ? '${h}h ${m.toString().padLeft(2, '0')}m' : '${m}m';
      items.add(_chip(cs, tt, Icons.schedule_rounded, text));
    }
    if (book.rating != null && book.rating! > 0) {
      items.add(_chip(
          cs, tt, Icons.star_rounded, book.rating!.toStringAsFixed(1)));
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items,
    );
  }

  Widget _chip(
      ColorScheme cs, TextTheme tt, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: cs.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(label, style: tt.labelMedium?.copyWith(color: cs.onSurface)),
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner(
      {required this.icon, required this.color, required this.text});
  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: tt.bodyMedium
                  ?.copyWith(color: color, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestedBanner extends StatelessWidget {
  const _RequestedBanner({required this.rawStatus});
  final String rawStatus;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.send_rounded, size: 18, color: cs.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l.rmabBookAlreadyRequested,
              style: tt.bodyMedium?.copyWith(
                  color: cs.onSurface, fontWeight: FontWeight.w600),
            ),
          ),
          RmabRequestStatusChip(rawStatus: rawStatus),
        ],
      ),
    );
  }
}

class _RequestButton extends StatelessWidget {
  const _RequestButton({
    required this.disabled,
    required this.submitting,
    required this.onPressed,
  });
  final bool disabled;
  final bool submitting;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: (disabled || submitting) ? null : onPressed,
        icon: submitting
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: cs.onPrimary,
                ),
              )
            : const Icon(Icons.menu_book_rounded, size: 18),
        label: Text(
            submitting ? l.rmabRequestSubmitting : l.rmabRequestCta),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
