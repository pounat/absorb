#!/usr/bin/env python3
"""Build a deterministic GPL corresponding-source archive, never a secret backup."""
import argparse
import gzip
import hashlib
import io
import json
import pathlib
import tarfile

EXCLUDED_DIRECTORIES = {'.git', '.dart_tool', '.idea', '.vscode', '__pycache__',
                        'build', 'node_modules', 'dist-source', 'secrets',
                        'credentials', '.cloudflared', 'operator', '.pub-cache', '.pub',
                        'coverage', 'screenshots'}
EXCLUDED_SUFFIXES = {'.log', '.db', '.sqlite', '.sqlite3', '.pem', '.key', '.p12',
                     '.bak', '.backup', '.pyc'}


def permitted(path):
    if path.name in {'SOURCE-MANIFEST.json', '.flutter-plugins-dependencies',
                     '.flutter-plugins', 'local.properties', 'Generated.xcconfig',
                     '.gitconfig', '.git-credentials'} or 'receipt' in path.name.lower():
        return False
    if any(part in EXCLUDED_DIRECTORIES for part in path.parts):
        return False
    if any(part.startswith('.env') for part in path.parts):
        return False
    if path.suffix.lower() in EXCLUDED_SUFFIXES:
        return False
    # Operator planning/evidence is not needed to compile distributed software.
    if path.parts[:2] == ('docs', 'superpowers'):
        return False
    return True


def build(root, output):
    root = root.resolve(strict=True)
    output = output.resolve()
    rows = []
    for path in sorted(root.rglob('*')):
        relative = path.relative_to(root)
        if path == output or not permitted(relative) or path.is_symlink() or not path.is_file():
            continue
        rows.append((relative.as_posix(), path.read_bytes(), bool(path.stat().st_mode & 0o111)))
    manifest = {'format': 1, 'files': [{'path': name, 'sha256': hashlib.sha256(data).hexdigest()}
                                    for name, data, _ in rows]}
    rows.append(('SOURCE-MANIFEST.json', (json.dumps(manifest, sort_keys=True, indent=2) + '\n').encode(), False))
    output.parent.mkdir(parents=True, exist_ok=True)
    with output.open('wb') as raw, gzip.GzipFile(fileobj=raw, filename='', mode='wb', mtime=0) as compressed:
        with tarfile.open(fileobj=compressed, mode='w') as archive:
            for name, data, executable in rows:
                info = tarfile.TarInfo('absorb-web/' + name)
                info.size = len(data)
                info.mode = 0o755 if executable else 0o644
                info.uid = info.gid = info.mtime = 0
                archive.addfile(info, io.BytesIO(data))
    return {'files': len(rows), 'archive_sha256': hashlib.sha256(output.read_bytes()).hexdigest()}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root', type=pathlib.Path, required=True)
    parser.add_argument('--output', type=pathlib.Path, required=True)
    args = parser.parse_args()
    print(json.dumps(build(args.root, args.output), sort_keys=True))


if __name__ == '__main__':
    main()
