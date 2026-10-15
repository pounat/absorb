import 'package:flutter_test/flutter_test.dart';

import 'package:absorb/l10n/app_localizations_en.dart';

void main() {
  group('Extracted English localization strings', () {
    final l = AppLocalizationsEn();

    test('dynamic list counts preserve both arguments', () {
      expect(l.libraryListsMixedCount(2, 3), '2 collections, 3 playlists');
    });

    test('metadata cleanup preserves counts and filename', () {
      expect(l.adminLibraryMetadataDeleteSuccess(2, 5, 'metadata.json'),
          'Removed 2 of 5 metadata.json files.');
      expect(l.adminLibraryMetadataDeleteConfirmTitle('metadata.json'),
          'Remove all metadata.json files?');
    });

    test('remaining time and schedule minute interpolate correctly', () {
      expect(l.homeRemainingHoursMinutes(2, 7), '2h 7m left');
      expect(l.adminLibraryMinuteInHour('05'), 'Minute 05');
    });

    test('new settings terminology has English source text', () {
      expect(l.settingsClassicWording, 'Classic wording');
      expect(l.settingsLockRotation, 'Lock rotation');
    });
  });
}
