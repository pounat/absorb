import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

/// Whether to use classic player vocabulary ("Play", "Now Playing", "Finished")
/// instead of the Absorb-themed vocabulary ("Absorb", "Absorbing", "Fully
/// Absorbed"). Lives at app level so any widget rebuilds when it flips.
final ValueNotifier<bool> classicWordingNotifier = ValueNotifier(false);

/// Returns either the Absorb-branded localization or a plain-English
/// equivalent depending on [classicWordingNotifier]. Only the English
/// surface is overridden — translated locales keep their existing strings.
class Wording {
  final AppLocalizations _l;
  final bool classic;
  const Wording._(this._l, this.classic);

  static Wording of(BuildContext context) =>
      Wording._(AppLocalizations.of(context)!, classicWordingNotifier.value);

  /// For code that already holds the strings but has no context to hand -
  /// helpers called from a build method's callee, mostly.
  static Wording from(AppLocalizations l) =>
      Wording._(l, classicWordingNotifier.value);

  // ── Card primary action ──
  String get absorb => classic ? 'Play' : _l.absorb;
  String get absorbing => classic ? 'Playing...' : _l.absorbing;
  String get absorbAgain => classic ? 'Play Again' : _l.absorbAgain;
  String get fullyAbsorbed => classic ? 'Finished' : _l.fullyAbsorbed;
  String get fullyAbsorbAction => classic ? 'Mark Finished' : _l.fullyAbsorbAction;

  // ── Now Playing list ──
  String get addToAbsorbing => classic ? 'Add to Now Playing' : _l.addToAbsorbing;
  String get removeFromAbsorbing => classic ? 'Remove from Now Playing' : _l.removeFromAbsorbing;
  String get addedToAbsorbing => classic ? 'Added to Now Playing' : _l.addedToAbsorbing;
  String get removedFromAbsorbing => classic ? 'Removed from Now Playing' : _l.removedFromAbsorbing;

  String episodeListAddedToAbsorbing(String title) =>
      classic ? 'Added "$title" to Now Playing' : _l.episodeListAddedToAbsorbing(title);
  String playlistDetailAddedToAbsorbing(String title) =>
      classic ? 'Added "$title" to Now Playing' : _l.playlistDetailAddedToAbsorbing(title);
  String collectionDetailAddedToAbsorbing(String title) =>
      classic ? 'Added "$title" to Now Playing' : _l.collectionDetailAddedToAbsorbing(title);
  String sectionDetailAddedToAbsorbing(String title) =>
      classic ? 'Added "$title" to Now Playing' : _l.sectionDetailAddedToAbsorbing(title);

  // ── Navigation / sections ──
  String get absorbingTitle => classic ? 'Now Playing' : _l.absorbingTitle;
  String get appShellAbsorbingTab => classic ? 'Now Playing' : _l.appShellAbsorbingTab;
  String get startScreenAbsorb => classic ? 'Now Playing' : _l.startScreenAbsorb;
  String get sectionAbsorbingCards => classic ? 'Player Cards' : _l.sectionAbsorbingCards;

  // ── Unified Absorbing page setting ──
  String get mergeLibraries =>
      classic ? 'Unified Now Playing page' : _l.mergeLibraries;
  String get mergeLibrariesInfoTitle =>
      classic ? 'Unified Now Playing Page' : _l.mergeLibrariesInfoTitle;
  String get mergeLibrariesInfoContent => classic
      ? 'When enabled, the Now Playing screen shows all your in-progress books and podcasts from every library in a single view. When disabled, only items from the library you currently have selected are shown.'
      : _l.mergeLibrariesInfoContent;
  String get mergeLibrariesOnSubtitle => classic
      ? 'Now Playing page shows items from all libraries'
      : _l.mergeLibrariesOnSubtitle;
  String get mergeLibrariesOffSubtitle => classic
      ? 'Now Playing page shows current library only'
      : _l.mergeLibrariesOffSubtitle;

  // ── Empty / placeholder ──
  String get absorbingNothingAbsorbingYet =>
      classic ? 'Nothing playing yet' : _l.absorbingNothingAbsorbingYet;

  // ── Mark-finished dialogs ──
  String get markAsFullyAbsorbedQuestion =>
      classic ? 'Mark as finished?' : _l.markAsFullyAbsorbedQuestion;
  String get fullyAbsorbSeries =>
      classic ? 'Mark series finished?' : _l.fullyAbsorbSeries;

  // ── Settings labels ──
  String get whenAbsorbed => classic ? 'When finished' : _l.whenAbsorbed;
  String get whenAbsorbedInfoTitle => classic ? 'When Finished' : _l.whenAbsorbedInfoTitle;
  String get whenAbsorbedSubtitle => classic
      ? 'What happens to the player card when a book or episode finishes'
      : _l.whenAbsorbedSubtitle;
  String get deleteAbsorbedDownloads =>
      classic ? 'Delete finished downloads' : _l.deleteAbsorbedDownloads;
  String get deleteAbsorbedDownloadsInfoTitle =>
      classic ? 'Delete Finished Downloads' : _l.deleteAbsorbedDownloadsInfoTitle;

  // ── Login ──
  String get loginTagline => classic ? 'Start Listening' : _l.loginTagline;

  // ── Tips ──
  String get tipsSheetQuickAddAbsorbingTitle =>
      classic ? 'Quick Add to Now Playing' : _l.tipsSheetQuickAddAbsorbingTitle;
  String get tipsSheetQuickAddAbsorbingDesc => classic
      ? 'Swipe right on any book in a list sheet (series, author, search results) to instantly add it to your Now Playing queue.'
      : _l.tipsSheetQuickAddAbsorbingDesc;

  // ── Queue mode info popup ──
  String get queueModeInfoManualDesc => classic
      ? 'Your Now Playing list acts as a playlist. When one finishes, the next non-finished item auto-plays. Add items with the "Add to Now Playing" button on a book or episode and reorder from the Now Playing screen.'
      : _l.queueModeInfoManualDesc;
}
