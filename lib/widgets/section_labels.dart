import '../l10n/app_localizations.dart';

/// Returns the localized display label for a known ABS personalized shelf
/// section ID. Falls back to [fallback] (typically the server-provided label,
/// which is English) when the ID isn't one we recognize. As a last resort it
/// title-cases the ID.
String sectionLabel(String id, String? fallback, AppLocalizations l) {
  switch (id) {
    case 'continue-listening':
      return l.continueListening;
    case 'continue-series':
      return l.continueSeries;
    case 'recently-added':
      return l.recentlyAdded;
    case 'listen-again':
      return l.listenAgain;
    case 'discover':
      return l.discover;
    case 'episodes-recently-added':
      return l.newEpisodes;
    case 'downloaded-books':
      return l.downloads;
  }
  if (fallback != null && fallback.isNotEmpty) return fallback;
  return id
      .replaceAll('-', ' ')
      .split(' ')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}
