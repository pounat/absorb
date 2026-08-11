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
      classic ? 'Unified Now Playing' : _l.mergeLibraries;
  String get mergeLibrariesInfoTitle =>
      classic ? 'Unified Now Playing' : _l.mergeLibrariesInfoTitle;
  String get mergeLibrariesInfoContent => classic
      ? 'When enabled, Now Playing shows and queues books and podcast episodes from every library together. When disabled, the page and Manual queue stay within the current library or media type.'
      : _l.mergeLibrariesInfoContent;
  String get mergeLibrariesOnSubtitle => classic
      ? 'Show and queue items from all libraries together'
      : _l.mergeLibrariesOnSubtitle;
  String get mergeLibrariesOffSubtitle => classic
      ? 'Keep the page and Manual queue in the current library'
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
      ? 'Items in Now Playing are your manual queue. When one finishes, the next unfinished item plays. Use Add to Now Playing on a book or episode, then reorder it in the Queue panel.'
      : _l.queueModeInfoManualDesc;

  String get desktopManualQueueHint => classic
      ? 'Use Add to Now Playing on a book or episode to put it here. Items play in this order.'
      : _l.desktopAbsorbingQueueHint;
}
