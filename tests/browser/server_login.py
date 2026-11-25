"""Compiled Flutter login against two isolated synthetic ABS origins.
Prerequisites: release build/web, Node, OpenSSL, Python Playwright + Chromium.
Run from repository root: python tests/browser/server_login.py
No installed server, credentials or media are used. TLS keys live only in scratch.
"""
import json
import os
import pathlib
import subprocess
import tempfile
from playwright.sync_api import sync_playwright
ROOT = pathlib.Path(__file__).resolve().parents[2]

def run():
    with tempfile.TemporaryDirectory(prefix='absorb-browser-', dir=os.environ.get('TMPDIR')) as temporary:
        temporary = pathlib.Path(temporary)
        key, cert = temporary / 'synthetic.key', temporary / 'synthetic.crt'
        subprocess.run(['openssl', 'req', '-x509', '-newkey', 'rsa:2048', '-nodes', '-keyout', str(key), '-out', str(cert), '-days', '1', '-subj', '/CN=localhost'], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        fixture = subprocess.Popen(['node', 'server/test/browser-fixture.mjs', str(key), str(cert)], cwd=ROOT, stdout=subprocess.PIPE, text=True)
        try:
            config = json.loads(fixture.stdout.readline())
            with sync_playwright() as p:
                executable = os.environ.get('CHROME_BIN')
                browser = p.chromium.launch(headless=True, **({'executable_path': executable} if executable else {}), args=['--no-sandbox'])
                pages = []
                routes = {}
                for index, target in enumerate(config['urls']):
                    context = browser.new_context(ignore_https_errors=True, viewport={'width': 1100, 'height': 900})
                    page = context.new_page()
                    requests = []
                    page.on('response', lambda response, receipts=requests: receipts.append(response.url))
                    page.goto(config['origin'])
                    page.locator('flt-semantics-placeholder').wait_for(timeout=60000)
                    # Enable Flutter's real accessibility tree (not app/network stubs).
                    page.locator('flt-semantics-placeholder').evaluate('(el) => el.click()')
                    inputs = page.locator('input')
                    inputs.nth(2).wait_for(timeout=15000)
                    assert inputs.count() == 3
                    assert inputs.evaluate_all('(xs) => xs.map(x => x.value)') == ['', '', '']
                    assert inputs.evaluate_all('(xs) => xs.map(x => x.type)') == ['url', 'text', 'password']
                    inputs.nth(0).click()
                    page.keyboard.type(target + '/', delay=65)
                    page.wait_for_timeout(1200)
                    page.keyboard.press('Tab')
                    page.wait_for_timeout(300)
                    assert page.evaluate('document.activeElement.type') == 'text'
                    page.keyboard.type('synthetic', delay=90)
                    page.keyboard.press('Tab')
                    page.wait_for_timeout(300)
                    assert page.evaluate('document.activeElement.type') == 'password'
                    page.keyboard.type('synthetic-password', delay=90)
                    with page.expect_response(lambda r: r.url == config['origin'] + '/login', timeout=30000) as response:
                        page.keyboard.press('Enter')
                    assert response.value.status == 200
                    assert response.value.json()['user']['username'] == f'reader-{index}'
                    routes[page] = response.value.json()['webSessionRoute']
                    page.wait_for_timeout(2500)
                    assert all(url.startswith(config['origin'] + '/') or url.startswith('data:') or url.startswith('blob:') for url in requests), requests
                    cookies = context.cookies()
                    cookie = next(c for c in cookies if c['name'] == 'absorb_web_session')
                    assert cookie['httpOnly'] and cookie['secure'] and cookie['sameSite'] == 'Strict'
                    storage = page.evaluate('JSON.stringify([Object.entries(localStorage),Object.entries(sessionStorage)])')
                    for forbidden in ['synthetic-password', f'synthetic-access-{index}', f'synthetic-refresh-{index}']:
                        assert forbidden not in storage
                    assert page.evaluate('document.cookie').find('absorb_web_session') == -1
                    pages.append(page)
                def request(page, route, body=None):
                    if not route.startswith('/sessions/'):
                        route = routes[page] + route
                    return page.evaluate('''async ([route, body]) => {
                      const r = await fetch(route, body === null ? {} : {method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(body)});
                      return {status:r.status, body:await r.text()};
                    }''', [route, body])
                starts = []
                for i, page in enumerate(pages):
                    identity = request(page, '/api/me')
                    assert identity['status'] == 200 and json.loads(identity['body'])['username'] == f'reader-{i}'
                    progress = request(page, '/api/me/progress/item')
                    assert progress['status'] == 200 and json.loads(progress['body'])['currentTime'] == i
                    start = request(page, '/api/items/item/play', {'supportedMimeTypes':['audio/mpeg']})
                    assert start['status'] == 200, start
                    starts.append(json.loads(start['body']))
                # Both servers intentionally reuse user, item and playback IDs.
                # Starting B must neither supersede A nor route its media to B.
                for i, page in enumerate(pages):
                    media = request(page, starts[i]['audioTracks'][0]['contentUrl'])
                    assert media == {'status':200, 'body':f'synthetic-media-{i}'}, media
                    sync = request(page, '/api/session/shared-session/sync', {'webGeneration':starts[i]['webGeneration'], 'webSequence':1, 'currentTime':4, 'timeListened':1})
                    assert sync['status'] == 200, sync
                    assert request(page, '/auth/refresh', {})['status'] == 200
                assert request(pages[0], '/logout', {})['status'] == 200
                assert request(pages[0], '/api/me')['status'] == 401
                assert request(pages[1], '/api/me')['status'] == 200
                receipts = pages[1].request.get(config['origin'] + '/synthetic-receipts').json()
                for records in receipts:
                    assert sum(r['path'] == '/abs/login' and r['correctLogin'] for r in records) == 1
                    assert all(r['correctToken'] for r in records if r['path'].startswith('/abs/api/') or r['path'].startswith('/abs/public/'))
                print(json.dumps({'compiled_ui_logins':2,'blank_fields':True,'keyboard_order':True,'cookie_security':True,'storage_secret_exclusion':True,'origin_isolation':True,'same_id_playback_isolation':True,'media_bytes_scoped':True,'progress_scoped':True,'refresh_logout_scoped':True}))
                browser.close()
        finally:
            fixture.terminate()
            fixture.wait(timeout=15)

if __name__ == '__main__':
    run()
