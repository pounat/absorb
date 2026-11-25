import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Web-only source offer; Settings keeps the native GPL notices unchanged.
class SourceLicenseSetting extends StatelessWidget {
  const SourceLicenseSetting({super.key, this.openUri});

  final Future<bool> Function(Uri)? openUri;

  @override
  Widget build(BuildContext context) => ListTile(
    minTileHeight: 48,
    leading: const Icon(Icons.code),
    title: const Text('Source and license'),
    onTap: () => showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Source and license'),
        scrollable: true,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Based on Absorb by Nathan Poulson. '
              'Licensed under GPL-3.0-or-later. '
              'Download the corresponding source for this web build below.',
            ),
            const SizedBox(height: 12),
            for (final link in const {
              'Download source': '/source/absorb-web-source.tar.gz',
              'View license': '/source/LICENSE',
            }.entries)
              TextButton(
                style: TextButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  visualDensity: VisualDensity.standard,
                  tapTargetSize: MaterialTapTargetSize.padded,
                ),
                onPressed: () =>
                    (openUri ?? launchUrl)(Uri.base.resolve(link.value)),
                child: Text(link.key, textAlign: TextAlign.center),
              ),
          ],
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              minimumSize: const Size(48, 48),
              visualDensity: VisualDensity.standard,
              tapTargetSize: MaterialTapTargetSize.padded,
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    ),
  );
}
