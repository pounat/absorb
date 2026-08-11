#!/usr/bin/env python3
"""Merge a Crowdin translation branch without losing translations.

Crowdin's ARB export has two recurring faults that break the build or silently
undo work, and neither can be fixed on the Crowdin side (language mapping only
rewrites export paths, never file contents):

  1. It writes a region @@locale (es-ES, pt-PT, zh-CN) into files named with
     bare codes, which fails gen_l10n with "The locale specified in @@locale
     and the arb filename do not match."
  2. Keys added to a translated file by hand, after Crowdin's last source
     upload, are missing from its export and disappear on the round trip.

This merges the branch, then repairs both. Nothing is committed and nothing is
pushed - the result is left staged for review.

Usage: python scripts/crowdin-merge.py [branch]   (default: origin/l10n_main)
"""

import io
import json
import os
import re
import subprocess
import sys

L10N = 'lib/l10n'
SOURCE = f'{L10N}/app_en.arb'
LOCALE_RE = re.compile(r'("@@locale"\s*:\s*)"[^"]*"')


def run(args, check=True):
    r = subprocess.run(args, capture_output=True, text=True, encoding='utf-8')
    if check and r.returncode != 0:
        sys.exit(f'failed: {" ".join(args)}\n{r.stderr or r.stdout}')
    return r


def show(rev, path):
    """File contents at a revision, or None if it does not exist there."""
    r = subprocess.run(['git', 'show', f'{rev}:{path}'], capture_output=True)
    return r.stdout.decode('utf-8') if r.returncode == 0 else None


def keys_of(text):
    return set(json.loads(text)) if text else set()


def translation_keys(text):
    return {k for k in keys_of(text) if not k.startswith('@')}


def restore(theirs, ours, source_keys):
    """Put back keys Crowdin dropped, keeping their file's formatting.

    Only restores a key that still exists in the English source, so a string
    deliberately deleted from app_en.arb stays deleted.
    """
    theirs_keys = keys_of(theirs)
    ours_data = json.loads(ours)

    missing = []
    for k in ours_data:
        if k in theirs_keys or k.startswith('@@'):
            continue
        base = k[1:] if k.startswith('@') else k
        if base in source_keys:
            missing.append(k)

    if not missing:
        return theirs, []

    lines = ['  %s: %s' % (json.dumps(k, ensure_ascii=False),
                           json.dumps(ours_data[k], ensure_ascii=False))
             for k in missing]

    body = theirs.rstrip()
    assert body.endswith('}')
    body = body[:-1].rstrip()
    if not body.endswith(','):
        body += ','
    result = body + '\n' + ',\n'.join(lines) + '\n}\n'

    json.loads(result)
    return result, [k for k in missing if not k.startswith('@')]


def main():
    branch = sys.argv[1] if len(sys.argv) > 1 else 'origin/l10n_main'
    os.chdir(run(['git', 'rev-parse', '--show-toplevel']).stdout.strip())

    if run(['git', 'status', '--porcelain', '-uno']).stdout.strip():
        sys.exit('working tree has uncommitted changes - commit or stash first')

    if branch.startswith('origin/'):
        run(['git', 'fetch', 'origin', branch.split('/', 1)[1]])

    base = run(['git', 'merge-base', 'HEAD', branch]).stdout.strip()

    print(f'merging {branch}\n')
    subprocess.run(['git', 'merge', branch, '--no-commit', '--no-ff'],
                   capture_output=True)

    source_keys = translation_keys(show('HEAD', SOURCE))
    rows, notes = [], []

    for name in sorted(os.listdir(L10N)):
        if not name.startswith('app_') or not name.endswith('.arb'):
            continue
        path = f'{L10N}/{name}'
        code = name[len('app_'):-len('.arb')]

        if code == 'en':
            # Crowdin must never rewrite the source; excluded_target_languages
            # should prevent it, but restore unconditionally in case it slips.
            # Compare against the merge base, not HEAD - local edits to the
            # source since the branch forked are ours, not Crowdin's.
            if show(base, path) != show(branch, path):
                run(['git', 'checkout', 'HEAD', '--', path])
                notes.append('app_en.arb was modified by the branch and has '
                             'been restored - check excluded_target_languages '
                             'in crowdin.yml')
            continue

        ours, theirs = show('HEAD', path), show(branch, path)
        if theirs is None:
            continue
        if ours is None:
            ours = '{"@@locale": "%s"}' % code

        before = len(translation_keys(ours))

        fixed = LOCALE_RE.sub(r'\1"%s"' % code, theirs)
        locale_fixed = fixed != theirs
        fixed, restored = restore(fixed, ours, source_keys)

        if json.loads(fixed) == json.loads(ours):
            # Nothing gained - keep our copy rather than churn the file. If the
            # export was missing keys, ours is strictly better anyway.
            run(['git', 'checkout', 'HEAD', '--', path])
            rows.append((code, before, before, len(restored), locale_fixed,
                         'kept ours'))
            if restored:
                notes.append('%s: export was missing %d key(s), kept ours - %s'
                             % (code, len(restored), ', '.join(restored)))
            continue

        with io.open(path, 'w', encoding='utf-8', newline='\n') as f:
            f.write(fixed)
        run(['git', 'add', '--', path])

        after = len(translation_keys(fixed))
        rows.append((code, before, after, len(restored), locale_fixed,
                     '+%d' % (after - before) if after != before else 'same'))
        if restored:
            notes.append('%s: restored %d dropped - %s'
                         % (code, len(restored), ', '.join(restored)))

    print('%-6s %8s %8s %9s %8s' % ('lang', 'before', 'after', 'restored', 'locale'))
    for code, before, after, restored, locale_fixed, delta in rows:
        print('%-6s %8d %8d %9s %8s   %s'
              % (code, before, after, restored or '-',
                 'fixed' if locale_fixed else '-', delta))

    print(f'\nEnglish source: {len(source_keys)} keys')
    for n in notes:
        print(f'  {n}')

    print('\nrunning flutter gen-l10n')
    gen = subprocess.run('flutter gen-l10n', shell=True, capture_output=True,
                         text=True, encoding='utf-8')
    warnings = [l for l in (gen.stderr + gen.stdout).splitlines()
                if 'Warning' in l or 'Error' in l]
    if gen.returncode != 0:
        print(gen.stderr or gen.stdout)
        sys.exit('gen-l10n failed - merge left in place for inspection')
    if warnings:
        print(f'  {len(warnings)} warning(s), see output of flutter gen-l10n')

    run(['git', 'add', '--', L10N])
    print('\nStaged, not committed. Review with: git diff --cached HEAD')
    print('New language? Add it to _pickLanguage and _languageDisplayName in '
          'lib/screens/settings_screen.dart')


if __name__ == '__main__':
    main()
