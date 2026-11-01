import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../screens/bookorbit_set_password_screen.dart';
import '../services/api_service.dart';
import '../services/setup_link_service.dart';
import '../utils/server_url.dart';
import 'overlay_toast.dart';

/// Whether [text] is a link [handleSetupLinkLogin] can take: an Absorb setup
/// link or a BookOrbit password link.
bool isLoginLink(String text) {
  if (BookOrbitApiService.passwordLink(text) != null) return true;
  final uri = Uri.tryParse(text.trim());
  if (uri == null) return false;
  try {
    SetupLinkService.parseLink(uri);
    return true;
  } on SetupLinkException {
    return false;
  }
}

/// Signs in from an Absorb setup link, or from a BookOrbit password link
/// after the person picks their password. [customHeaders] go with a
/// BookOrbit password link, which carries none of its own.
Future<bool> handleSetupLinkLogin(
  BuildContext context,
  Uri link, {
  bool askForConfirmation = true,
  Map<String, String> customHeaders = const {},
}) async {
  final l = AppLocalizations.of(context)!;
  late final SetupLinkData setup;
  final passwordLink = BookOrbitApiService.passwordLink(link.toString());
  try {
    setup = passwordLink != null
        ? SetupLinkData(
            serverUrl: normalizeServerUrl(passwordLink.server.toString()),
            username: '',
            apiKey: null,
            passwordToken: passwordLink.token,
            userId: null,
            customHeaders: customHeaders,
          )
        : SetupLinkService.parseLink(link);
  } on SetupLinkException {
    showOverlayToast(
      context,
      l.setupLinkInvalid,
      icon: Icons.error_outline_rounded,
    );
    return false;
  }

  if (setup.setsPassword) {
    final signedIn = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => BookOrbitSetPasswordScreen.fromLink(
          serverUrl: setup.serverUrl,
          token: setup.passwordToken!,
          username: setup.username.isEmpty ? null : setup.username,
          customHeaders: setup.customHeaders,
        ),
      ),
    );
    if (signedIn != true || !context.mounted) return false;
    final auth = context.read<AuthProvider>();
    showOverlayToast(
      context,
      l.loginSignedInAs(auth.username ?? setup.username),
      icon: Icons.check_circle_outline_rounded,
    );
    return true;
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
    apiKey: setup.apiKey!,
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
