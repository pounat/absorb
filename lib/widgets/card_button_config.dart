import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/chromecast_service.dart';
import '../services/wording.dart';
import '../utils/app_platform.dart';

class CardButtonDef {
  final String id;
  final String label;
  final IconData icon;
  const CardButtonDef(this.id, this.label, this.icon);
}

/// Localized label for a card button id. Falls back to the English label
/// stored on the [CardButtonDef] if no mapping exists.
String localizedCardButtonLabel(AppLocalizations l, CardButtonDef def) {
  switch (def.id) {
    case 'chapters':
      return l.chapters;
    case 'speed':
      return l.speed;
    case 'sleep':
      return l.timer;
    case 'bookmarks':
      return l.bookmarks;
    case 'details':
      return l.bookDetailsLabel;
    case 'equalizer':
      return l.equalizerLabel;
    case 'cast':
      return l.castToDevice;
    case 'airplay':
      return 'AirPlay';
    case 'history':
      return l.playbackHistory;
    case 'remove':
      return classicWordingNotifier.value ? 'Remove from Now Playing' : l.removeFromAbsorbing;
    case 'car':
      return l.carModeTitle;
    case 'notes':
      return l.notes;
    case 'download':
      return l.download;
    case 'ebook':
      return 'Read';
  }
  return def.label;
}

/// Button IDs hidden in this build / on this platform.
/// - iOS: cast UI not supported through the plugin yet.
/// - F-Droid (GMS-free): Chromecast needs Google Play Services, so the stub
///   service reports castSupported=false and the button is dropped entirely.
final Set<String> _hiddenButtons = {
  if (AppPlatform.isWeb || AppPlatform.isIOS) 'cast',
  if (!ChromecastService.castSupported) 'cast',
  // AirPlay is iOS-only (Chromecast covers Android).
  if (AppPlatform.isWeb || !AppPlatform.isIOS) 'airplay',
  if (AppPlatform.isWeb) ...{
    'car',
    'download',
    'ebook',
    'equalizer',
  },
};

const _allCardButtons = [
  CardButtonDef('chapters', 'Chapters', Icons.list_rounded),
  CardButtonDef('speed', 'Speed', Icons.speed_rounded),
  CardButtonDef('sleep', 'Timer', Icons.nightlight_round_outlined),
  CardButtonDef('bookmarks', 'Bookmarks', Icons.bookmark_outline_rounded),
  CardButtonDef('details', 'Book Details', Icons.info_outline_rounded),
  CardButtonDef('equalizer', 'Equalizer', Icons.equalizer_rounded),
  CardButtonDef('cast', 'Cast to Device', Icons.cast_rounded),
  CardButtonDef('airplay', 'AirPlay', Icons.airplay_rounded),
  CardButtonDef('history', 'Playback History', Icons.history_rounded),
  CardButtonDef('remove', 'Remove from Absorbing', Icons.remove_circle_outline_rounded),
  CardButtonDef('car', 'Car Mode', Icons.directions_car_rounded),
  CardButtonDef('notes', 'Notes', Icons.note_rounded),
  CardButtonDef('download', 'Download', Icons.download_outlined),
  CardButtonDef('ebook', 'Read', Icons.menu_book_rounded),
];

/// Card buttons filtered for the current platform.
final List<CardButtonDef> allCardButtons =
    _allCardButtons.where((b) => !_hiddenButtons.contains(b.id)).toList();

/// Look up a button definition by ID.
CardButtonDef? buttonDefById(String id) {
  for (final b in allCardButtons) {
    if (b.id == id) return b;
  }
  return null;
}
