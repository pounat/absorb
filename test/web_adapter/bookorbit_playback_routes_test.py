"""Playback UI source tripwires, complementary to compiled browser tests."""
from pathlib import Path
import unittest
ROOT = Path(__file__).resolve().parents[2]

class BookOrbitPlaybackRoutes(unittest.TestCase):
    def test_native_player_actions_are_not_download_handoffs(self):
        lib = ROOT / 'lib'
        self.assertNotIn('showBookOrbitWebAccess', (lib / 'widgets/book_detail_sheet.dart').read_text())
        self.assertNotIn('return [bookOrbitWebFilesButton', (lib / 'widgets/card_buttons.dart').read_text())
        home = (lib / 'screens/home_screen.dart').read_text().split('Future<void> _startBook(', 1)[1]
        self.assertNotIn('showBookOrbitWebAccess', home)

    def test_reader_remains_explicitly_unsupported(self):
        source = (ROOT / 'lib/widgets/ebook_router.dart').read_text()
        self.assertIn('showBookOrbitWebAccess(context, itemId)', source)
        copy = (ROOT / 'lib/widgets/bookorbit_web_access.dart').read_text()
        self.assertIn('Embedded reading is not available', copy)

    def test_source_transitions_do_not_complete_or_checkpoint_old_time(self):
        source = (ROOT / 'lib/services/audio_player_service.dart').read_text()
        complete = source.split('Future<void> _onPlaybackComplete(', 1)[1].split('final webGeneration', 1)[0]
        checkpoint = source.split('Future<void> _webCheckpoint(', 1)[1].split('final owner', 1)[0]
        self.assertIn('_api?.isBookOrbit == true', complete)
        self.assertIn('ProcessingState.completed', complete)
        self.assertIn('_api?.isBookOrbit == true', checkpoint)
        self.assertIn('ProcessingState.loading', checkpoint)

if __name__ == '__main__':
    unittest.main()
