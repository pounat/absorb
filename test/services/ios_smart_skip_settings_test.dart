import 'package:absorb/services/player_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uses Android-inspired conservative defaults', () {
    const settings = IosSmartSkipSettings.defaults;

    expect(settings.thresholdDb, -38);
    expect(settings.minimumSilenceMs, 250);
    expect(settings.mergeGapMs, 120);
    expect(settings.guardMs, 40);
  });

  test('normalizes unsafe silence and guard combinations', () {
    final settings = IosSmartSkipSettings.defaults.copyWith(thresholdDb: -80, minimumSilenceMs: 100, mergeGapMs: 500, guardMs: 100);

    expect(settings.thresholdDb, -60);
    expect(settings.minimumSilenceMs, 100);
    expect(settings.mergeGapMs, 300);
    expect(settings.guardMs, 40);
  });

  test('restores partial backup data with defaults', () {
    final settings = IosSmartSkipSettings.fromJson({'thresholdDb': -35});

    expect(settings.thresholdDb, -35);
    expect(settings.minimumSilenceMs, 250);
    expect(settings.mergeGapMs, 120);
    expect(settings.guardMs, 40);
  });
}
