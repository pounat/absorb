"""Deployment regression probes; real HTTPS fixture enabled by ABSORB_TEST_ORIGIN."""
import os
import pathlib
import ssl
import unittest
import urllib.error
import urllib.request

ROOT = pathlib.Path(__file__).resolve().parents[2]


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None


class WebProxyTest(unittest.TestCase):
    def test_static_proxy_forces_same_origin_relative_redirects(self):
        config = (ROOT / 'deploy/nginx/web.conf').read_text()
        self.assertIn('absolute_redirect off;', config)

    @unittest.skipUnless(os.environ.get('ABSORB_TEST_ORIGIN'), 'requires real HTTPS qualification stack')
    def test_real_tls_root_redirect_does_not_escape_to_internal_http_listener(self):
        context = ssl._create_unverified_context()  # isolated fixture CA only
        opener = urllib.request.build_opener(NoRedirect(), urllib.request.HTTPSHandler(context=context))
        try:
            response = opener.open(os.environ['ABSORB_TEST_ORIGIN'] + '/', timeout=10)
        except urllib.error.HTTPError as error:
            response = error
        with response:
            self.assertEqual(response.status, 302)
            self.assertEqual(response.headers['Location'], '/absorb/')


if __name__ == '__main__':
    unittest.main()
