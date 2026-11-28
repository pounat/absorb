import pathlib
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[2]


class WebFontsTest(unittest.TestCase):
    def test_default_material_roboto_is_shipped_with_its_license(self):
        spec = (ROOT / 'pubspec.yaml').read_text()
        self.assertIn('- family: Roboto', spec)
        for filename in ['Roboto-Variable.ttf', 'Roboto-Italic-Variable.ttf']:
            path = ROOT / 'assets/fonts' / filename
            self.assertTrue(path.is_file(), filename)
            self.assertIn('assets/fonts/' + filename, spec)
            self.assertEqual(path.read_bytes()[:4], b'\x00\x01\x00\x00')
        self.assertIn('SIL OPEN FONT LICENSE', (ROOT / 'assets/fonts/Roboto-OFL.txt').read_text())


if __name__ == '__main__':
    unittest.main()
