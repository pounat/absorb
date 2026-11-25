import pathlib
import re
import unittest


class LocalRendererPolicy(unittest.TestCase):
    def test_custom_bootstrap_pins_renderer_to_same_origin(self):
        root = pathlib.Path(__file__).resolve().parents[2]
        text = (root / 'web/flutter_bootstrap.js').read_text()
        compact = re.sub(r'\s+', '', text)
        self.assertIn('canvasKitBaseUrl:"canvaskit/"', compact)
        self.assertNotIn('https://', text)
        self.assertIn('{{flutter_js}}', text)
        self.assertIn('{{flutter_build_config}}', text)
        self.assertIn('{{flutter_service_worker_version}}', text)

    def test_runtime_static_assets_belong_to_nginx_uid(self):
        root = pathlib.Path(__file__).resolve().parents[2]
        docker = (root / 'Dockerfile').read_text()
        self.assertIn('COPY --from=build --chown=101:101 /src/build/web /usr/share/nginx/html/absorb', docker)
        self.assertIn('COPY --from=source --chown=101:101 /out/absorb-web-source.tar.gz /usr/share/nginx/html/source/absorb-web-source.tar.gz', docker)
        self.assertIn('COPY --chown=101:101 LICENSE /usr/share/nginx/html/source/LICENSE', docker)
        self.assertIn('USER nginx', docker)
        legacy = (root / 'Dockerfile.web').read_text()
        self.assertIn('COPY --from=build --chown=101:101 /src/build/web /usr/share/nginx/html/absorb', legacy)


if __name__ == '__main__':
    unittest.main()
