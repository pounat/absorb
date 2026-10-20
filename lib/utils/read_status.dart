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
