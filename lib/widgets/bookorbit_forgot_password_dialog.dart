import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/api_service.dart';
import '../services/bookorbit_admin.dart';

/// Asks for an email and has the BookOrbit server send a password link to it.
Future<void> showBookOrbitForgotPassword(
  BuildContext context, {
  required String serverUrl,
  Map<String, String> customHeaders = const {},
  String initialEmail = '',
}) =>
    showDialog<void>(
      context: context,
      builder: (_) => _ForgotPasswordDialog(
        serverUrl: serverUrl,
        customHeaders: customHeaders,
        initialEmail: initialEmail,
      ),
    );

class _ForgotPasswordDialog extends StatefulWidget {
  final String serverUrl;
  final Map<String, String> customHeaders;
  final String initialEmail;

  const _ForgotPasswordDialog({
    required this.serverUrl,
    required this.customHeaders,
    required this.initialEmail,
  });

  @override
  State<_ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<_ForgotPasswordDialog> {
  late final _email = TextEditingController(text: widget.initialEmail);
  bool _sending = false;
  BoPasswordResetResult? _result;
  bool _badEmail = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_sending) return;
    final email = _email.text.trim();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      setState(() => _badEmail = true);
      return;
    }
    setState(() {
      _badEmail = false;
      _sending = true;
    });
    final result = await BookOrbitApiService.requestPasswordReset(
      serverUrl: widget.serverUrl,
      email: email,
      customHeaders: widget.customHeaders,
    );
    if (!mounted) return;
    setState(() {
      _sending = false;
      _result = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final result = _result;
    // Sending again can't help once the server has answered these two.
    final finished = result == BoPasswordResetResult.sent || result == BoPasswordResetResult.notSetUp;

    return AlertDialog(
      title: Text(l.boForgotTitle),
      content: finished
          ? Text(result == BoPasswordResetResult.sent ? l.boForgotSent : l.boForgotNotSetUp)
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.boForgotBody),
                const SizedBox(height: 12),
                TextField(
                  controller: _email,
                  enabled: !_sending,
                  autofocus: widget.initialEmail.isEmpty,
                  autocorrect: false,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.send,
                  autofillHints: const [AutofillHints.email],
                  onSubmitted: (_) => _send(),
                  decoration: InputDecoration(
                    labelText: l.boUserEmail,
                    errorText: _badEmail ? l.boUserEmailInvalid : null,
                  ),
                ),
                if (result != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    result == BoPasswordResetResult.tooManyTries ? l.boForgotTooMany : l.boAdminOffline,
                    style: TextStyle(color: cs.error),
                  ),
                ],
              ],
            ),
      actions: finished
          ? [FilledButton(onPressed: () => Navigator.pop(context), child: Text(l.done))]
          : [
              TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
              FilledButton(onPressed: _sending ? null : _send, child: Text(l.boForgotSend)),
            ],
    );
  }
}
