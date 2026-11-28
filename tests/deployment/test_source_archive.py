import pathlib
import subprocess
import sys
import tarfile
import tempfile
import unittest

SCRIPT = pathlib.Path(__file__).resolve().parents[2] / 'tools' / 'build_source_archive.py'


class SourceArchiveTest(unittest.TestCase):
    def test_archive_contains_corresponding_source_but_not_local_secrets_or_builds(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = pathlib.Path(temporary) / 'project'
            root.mkdir()
            for name, text in {'lib/main.dart': 'source', 'LICENSE': 'GPL notice',
                               'pubspec.yaml': 'name: fixture', 'pubspec.lock': 'locked',
                               '.env': 'PRIVATE=secret', '.env.backup': 'PRIVATE=secret',
                               '.env.example': 'PUBLIC_ORIGINS=https://example.com',
                               '.git/config': 'local checkout', 'build/compiled.js': 'compiled',
                               'operator/config.yaml': 'private operator config',
                               'credentials/tunnel.json': 'synthetic credential',
                               'secrets/cookie-key': 'synthetic key',
                               'backup.bak': 'synthetic backup',
                               'server/test/RECEIPTS.md': 'private test receipt',
                               '.flutter-plugins-dependencies': 'synthetic SDK path',
                               'android/local.properties': 'synthetic SDK path',
                               'SOURCE-MANIFEST.json': 'stale manifest',
                               'server/app.mjs': 'server source'}.items():
                p = root / name
                p.parent.mkdir(parents=True, exist_ok=True)
                p.write_text(text)
            output = root / 'dist-source' / 'absorb-web-source.tar.gz'
            result = subprocess.run([sys.executable, str(SCRIPT), '--root', str(root),
                                     '--output', str(output)], capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, result.stderr)
            with tarfile.open(output) as archive:
                members = [p.name for p in archive.getmembers() if p.isfile()]
                names = set(members)
                self.assertEqual(len(members), len(names), 'duplicate archive member')
            for name in ['lib/main.dart', 'LICENSE', 'pubspec.yaml', 'pubspec.lock',
                         'server/app.mjs', 'SOURCE-MANIFEST.json']:
                self.assertIn('absorb-web/' + name, names)
            for name in ['.env', '.env.backup', '.env.example', '.git/config', 'build/compiled.js',
                         'operator/config.yaml', 'credentials/tunnel.json',
                         'secrets/cookie-key', 'backup.bak', 'server/test/RECEIPTS.md',
                         '.flutter-plugins-dependencies', 'android/local.properties']:
                self.assertNotIn('absorb-web/' + name, names)


if __name__ == '__main__':
    unittest.main()
