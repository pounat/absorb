"""Source boundary tripwires, not a replacement for Flutter/browser tests."""
import pathlib
import unittest
ROOT = pathlib.Path(__file__).resolve().parents[2]

class WebBoundaryTests(unittest.TestCase):
    def test_web_api_uses_browser_policy_at_transport_and_playback_boundaries(self):
        source = (ROOT / 'lib/services/api_service.dart').read_text()
        for marker in ['BrowserAdapter.currentOrigin', 'BrowserAdapter.requestHeaders',
                       'BrowserAdapter.playbackOptions', 'BrowserAdapter.mediaUrl',
                       '_webSessions.register', '_webSessions.next',
                       'if (kIsWeb) return const LocalSessionResult']:
            self.assertTrue(marker in source, f'Missing boundary: {marker}')

    def test_auth_mutations_reach_tested_browser_post_transport(self):
        source = (ROOT / 'lib/services/api_service.dart').read_text()
        post = source.split('Future<http.Response> _post(', 1)[1].split(
            'Future<http.Response> _patch(', 1)[0]
        self.assertIn('if (kIsWeb)', post)
        self.assertIn('return BrowserAdapter.post(Uri.base, url,', post)
        self.assertIn('client: _httpClient, headers: headers, body: body', post)
        refresh = source.split('Future<http.Response> _sendRefresh(', 1)[1].split(
            'Future<bool> _refreshTokenPairOnce', 1)[0]
        logout = source.split('Future<bool> revokeServerSession(', 1)[1].split(
            'Future<PasswordChangeResult>', 1)[0]
        self.assertIn('=> _post(', refresh)
        self.assertIn("/auth/refresh'", refresh)
        self.assertIn('await _post(', logout)
        self.assertIn('/logout$suffix', logout)

    def test_web_auth_blocks_secret_login_and_socket_paths(self):
        auth = (ROOT / 'lib/providers/auth_provider.dart').read_text()
        socket = (ROOT / 'lib/services/socket_service.dart').read_text()
        login = (ROOT / 'lib/screens/login_screen.dart').read_text()
        self.assertTrue('BrowserAdapter.isSessionLabel' in auth)
        self.assertTrue("if (kIsWeb || newToken == BrowserAdapter.cookieSentinel)" in socket)
        self.assertTrue("if (kIsWeb || token == BrowserAdapter.cookieSentinel)" in socket)
        self.assertTrue('_buildBackendPicker(cs)' in login)
        self.assertFalse('if (!AppPlatform.isWeb) _buildBackendPicker' in login)
        self.assertTrue('if (!AppPlatform.isWeb && _showAdvanced)' in login)
        self.assertTrue('if (!AppPlatform.isWeb) _buildSavedAccounts' in login)

if __name__ == '__main__':
    unittest.main()
