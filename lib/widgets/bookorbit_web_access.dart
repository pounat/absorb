import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart';

/// Only the additional web provider has this limited capability surface.
/// Native BookOrbit and every Audiobookshelf action retain their original path.
bool usesBookOrbitWebFiles(BuildContext context) =>
    kIsWeb && context.read<AuthProvider>().isBookOrbit;

const bookOrbitWebCapabilityNotice =
    'Embedded reading is not available for BookOrbit in Absorb Web. '
    'Use the book’s Absorb action to listen here, or open permitted files in your reader.';

Uri? bookOrbitWebAccessUri(String itemId) {
  if (!RegExp(r'^[1-9][0-9]*$').hasMatch(itemId)) return null;
  return Uri.base.resolve('/bookorbit/api/v1/books/$itemId/access');
}

Widget bookOrbitWebFilesButton(BuildContext context, String itemId) => Column(
  mainAxisSize: MainAxisSize.min,
  children: [
    FilledButton.icon(
      onPressed: () => showBookOrbitWebAccess(context, itemId),
      icon: const Icon(Icons.folder_open_outlined),
      label: const Text('Open book files'),
    ),
    const SizedBox(height: 8),
    const Text(bookOrbitWebCapabilityNotice, textAlign: TextAlign.center),
  ],
);

/// A synchronous provider gate: no unsupported detail/manifest/reader work is
/// dispatched before the user sees the supported file action.
bool showBookOrbitWebAccess(BuildContext context, String itemId) {
  if (!usesBookOrbitWebFiles(context)) return false;
  final base = context.read<AuthProvider>().apiService?.cleanBaseUrl;
  final uri = base != null && bookOrbitWebAccessUri(itemId) != null
      ? Uri.parse('$base/api/v1/books/$itemId/access') : null;
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('BookOrbit book files'),
      content: Text(uri == null ? 'Invalid BookOrbit book identifier.' : bookOrbitWebCapabilityNotice),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        if (uri != null) FilledButton(
          onPressed: () async {
            // Relative same-origin BFF URL only; no tokens or upstream URL.
            final opened = await launchUrl(uri, webOnlyWindowName: '_blank');
            if (!opened && ctx.mounted) {
              ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                content: Text('Could not open book files. Allow a new tab and try again.')));
            }
          },
          child: const Text('Open book files'),
        ),
      ],
    ),
  );
  return true;
}
