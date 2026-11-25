import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('shared real-player controls observe browser recovery state', () {
    final source = File('lib/widgets/absorbing_card.dart').readAsStringSync();
    expect(source, contains('child: PlaybackRecoveryNotice('));
    expect(source, contains('isWeb: kIsWeb'));
    expect(source, contains('recoveryRequired: widget.player.webPlaybackRecoveryRequired'));
    expect(source, contains('message: widget.player.webPlaybackRecoveryMessage'));
    expect(source, contains('isActive: _isActive'));
    expect(source, contains('listenable: widget.player'));
  });
  test('real book card selects scroll-safe Tesla book layout before desktop layout', () {
    final source = File('lib/widgets/absorbing_card.dart').readAsStringSync();
    expect(source.contains('return TeslaBookPane('), isTrue);
    expect(source.contains('title: _title'), isTrue);
    expect(source.contains('progress: CardDualProgressBar('), isTrue);
    expect(source.contains('controlsRow,'), isTrue);
  });
}
