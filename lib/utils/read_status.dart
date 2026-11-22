import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// BookOrbit's reading statuses, in the server's order.
const bookOrbitReadStatuses = [
  'unread',
  'want_to_read',
  'reading',
  'on_hold',
  'rereading',
  'read',
  'skimmed',
  'abandoned',
];

String readStatusLabel(AppLocalizations l, String s) => switch (s) {
      'want_to_read' => l.readStatusWantToRead,
      'reading' => l.readStatusReading,
      'on_hold' => l.readStatusOnHold,
      'rereading' => l.readStatusRereading,
      'read' => l.readStatusRead,
      'skimmed' => l.readStatusSkimmed,
      'abandoned' => l.readStatusAbandoned,
      _ => l.readStatusUnread,
    };

IconData readStatusIcon(String s) => switch (s) {
      'want_to_read' => Icons.bookmark_add_outlined,
      'reading' || 'rereading' => Icons.auto_stories_outlined,
      'on_hold' => Icons.pause_circle_outline_rounded,
      'read' || 'skimmed' => Icons.check_circle_outline_rounded,
      'abandoned' => Icons.do_not_disturb_on_outlined,
      _ => Icons.radio_button_unchecked_rounded,
    };
