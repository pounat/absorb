import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../l10n/app_localizations.dart';

class SetupLinkShareSheet extends StatelessWidget {
  final String username;
  final Uri setupLink;
  final Future<void> Function() onShare;
  final Future<void> Function() onCopy;
  final Future<void> Function() onSaveFile;

  const SetupLinkShareSheet({
    super.key,
    required this.username,
    required this.setupLink,
    required this.onShare,
    required this.onCopy,
    required this.onSaveFile,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l.setupLinkShareTitle,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              l.setupLinkShareDescription(username),
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            Semantics(
              label: l.setupLinkShareTitle,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: QrImageView(
                  key: const Key('setup-link-qr'),
                  data: setupLink.toString(),
                  version: QrVersions.auto,
                  size: 220,
                  padding: EdgeInsets.zero,
                  backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Colors.black,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Colors.black,
                  ),
                  errorStateBuilder: (_, __) => SizedBox(
                    width: 220,
                    height: 220,
                    child: Center(
                      child: Text(
                        l.setupLinkQrError,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: cs.onSurfaceVariant),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.errorContainer.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lock_outline_rounded,
                    size: 20,
                    color: cs.onErrorContainer,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l.setupLinkPrivateWarning(username),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              key: const Key('setup-link-share'),
              onPressed: onShare,
              icon: const Icon(Icons.ios_share_rounded),
              label: Text(l.setupLinkShare),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              key: const Key('setup-link-copy'),
              onPressed: onCopy,
              icon: const Icon(Icons.content_copy_rounded),
              label: Text(l.setupLinkCopy),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
            const SizedBox(height: 6),
            TextButton.icon(
              key: const Key('setup-link-save-file'),
              onPressed: onSaveFile,
              icon: const Icon(Icons.download_rounded),
              label: Text(l.setupLinkSaveFile),
            ),
          ],
        ),
      ),
    );
  }
}
