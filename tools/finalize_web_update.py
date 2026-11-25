#!/usr/bin/env python3
"""After flutter build web, pin mutable entrypoint URLs to exact content.

The bootstrap loader/configuration stays unchanged apart from its mainJsPath.
No cookie/storage/service-worker deletion is performed. Content query versions
also bypass previously cached unversioned URLs on an ordinary page reload.
"""
import argparse
import hashlib
import pathlib
import re


def finalize(root):
    main_hash = hashlib.sha256((root / 'main.dart.js').read_bytes()).hexdigest()
    bootstrap_path = root / 'flutter_bootstrap.js'
    bootstrap = bootstrap_path.read_text()
    bootstrap, count = re.subn(r'"mainJsPath":"main\.dart\.js(?:\?v=[0-9a-f]{64})?"',
                              f'"mainJsPath":"main.dart.js?v={main_hash}"', bootstrap)
    if count != 1:
        raise ValueError('Expected exactly one dart2js mainJsPath')
    bootstrap_path.write_text(bootstrap)
    bootstrap_hash = hashlib.sha256(bootstrap_path.read_bytes()).hexdigest()
    index_path = root / 'index.html'
    index = index_path.read_text()
    index, count = re.subn(r'src="flutter_bootstrap\.js(?:\?v=[0-9a-f]{64})?"',
                          f'src="flutter_bootstrap.js?v={bootstrap_hash}"', index)
    if count != 1:
        raise ValueError('Expected exactly one bootstrap script')
    index_path.write_text(index)
    return {'main': main_hash, 'bootstrap': bootstrap_hash}


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--web-root', type=pathlib.Path, default=pathlib.Path('build/web'))
    print(finalize(parser.parse_args().web_root))
