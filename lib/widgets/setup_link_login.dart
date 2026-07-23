import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../services/setup_link_service.dart';
import 'overlay_toast.dart';

Future<bool> handleSetupLinkLogin(
  BuildContext context,
  Uri link, {
  bool askForConfirmation = true,
}) async {
  final l = AppLocalizations.of(context)!;
  late final SetupLinkData setup;
  try {
    setup = SetupLinkService.parseLink(link);
  } on SetupLinkException {
    showOverlayToast(
      context,
      l.setupLinkInvalid,
      icon: Icons.error_outline_rounded,
    );
    return false;
  }

  if (askForConfirmation) {
    final server = Uri.parse(setup.serverUrl);
    final serverLabel = [
      server.host,
      if (server.hasPort) ':${server.port}',
      if (server.path.isNotEmpty && server.path != '/') server.path,
    ].join();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l.setupLinkConfirmTitle),
        content: Text(l.setupLinkConfirmBody(serverLabel, setup.username)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l.loginSignIn),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return false;
  }

  showOverlayToast(context, l.setupLinkSigningIn, icon: Icons.login_rounded);
  final auth = context.read<AuthProvider>();
  final success = await auth.loginWithApiKey(
    serverUrl: setup.serverUrl,
    apiKey: setup.apiKey,
    customHeaders: setup.customHeaders,
    l: l,
  );
  if (!context.mounted) return success;

  showOverlayToast(
    context,
    success
        ? l.loginSignedInAs(auth.username ?? setup.username)
        : auth.errorMessage ?? l.loginFailed,
    icon: success
        ? Icons.check_circle_outline_rounded
        : Icons.error_outline_rounded,
  );
  return success;
}
