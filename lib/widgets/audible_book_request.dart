import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../screens/book_requests_screen.dart';
import '../services/api_service.dart';
import '../services/book_requests.dart';
import 'overlay_toast.dart';

typedef AudibleRequestBook = ({Map<String, dynamic> book, String? seriesName});

/// Whether missing series books can be asked for on this account's
/// BookOrbit server, which needs the request permission and requests not
/// hidden in the user's settings.
Future<bool> canRequestAudibleBooks(ApiService? api) async {
  if (api == null || !api.isBookOrbit) return false;
  return (await api.bookRequestAccess()).canRequest;
}

/// Asks the BookOrbit server for audiobooks found on Audible. One sheet
/// covers them all: where they land and a note for the approver. True once
/// at least one request went in.
Future<bool> requestAudibleBooks(
  BuildContext context,
  ApiService api,
  List<AudibleRequestBook> books,
) async {
  final l = AppLocalizations.of(context)!;
  if (books.isEmpty) return false;
  final setup = await loadBookRequestSetup(api);
  if (!context.mounted) return false;
  if (!setup.access.canRequest) {
    showOverlayToast(context, l.breqFailed, icon: Icons.error_outline_rounded);
    return false;
  }
  final single = books.length == 1 ? books.single.book : null;
  final cover = '${single?['coverUrl'] ?? ''}';
  final choice = await showBookRequestSheet(
    context,
    title: single != null ? '${single['title'] ?? ''}' : l.breqBookCount(books.length),
    authors: single != null ? audibleBookAuthors(single) : const [],
    coverUrl: cover.isEmpty ? null : cover,
    kinds: const ['audiobook'],
    setup: setup,
  );
  if (choice == null || !context.mounted) return false;
  var sent = 0;
  var joined = 0;
  var failed = 0;
  String? reason;
  for (final b in books) {
    final body = audibleBookRequestPayload(
      b.book,
      seriesName: b.seriesName,
      note: choice.note,
      libraryId: choice.libraries['audiobook'],
    );
    if (body == null) {
      failed++;
      continue;
    }
    final result = await api.submitBookRequest(body);
    if (!result.ok) {
      failed++;
      reason ??= result.error;
    } else if (result.subscribed) {
      joined++;
    } else {
      sent++;
    }
  }
  debugPrint('[BookRequests] Audible requests: $sent sent, $joined joined, $failed failed');
  final ok = sent + joined > 0;
  if (!context.mounted) return ok;
  final String message;
  if (single != null) {
    message = failed > 0
        ? (reason != null ? l.breqFailedReason(reason) : l.breqFailed)
        : joined > 0
            ? l.breqJoined
            : l.breqSubmitted;
  } else {
    final done = l.upcomingReleasesBulkRequestDone(sent + joined);
    message = failed == 0 ? done : '$done - ${l.upcomingReleasesBulkRequestSkipped(failed)}';
  }
  showOverlayToast(context, message, icon: ok ? Icons.check_circle_outline_rounded : Icons.error_outline_rounded);
  return ok;
}
