import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../widgets/overlay_toast.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context)!;
    if (_currentController.text.isEmpty ||
        _newController.text.isEmpty ||
        _confirmController.text.isEmpty) {
      showOverlayToast(
        context,
        l.passwordFieldsRequired,
        icon: Icons.error_outline_rounded,
      );
      return;
    }
    if (_newController.text != _confirmController.text) {
      showOverlayToast(
        context,
        l.passwordsDoNotMatch,
        icon: Icons.error_outline_rounded,
      );
      return;
    }

    final api = context.read<AuthProvider>().apiService;
    if (api == null) return;
    setState(() => _saving = true);
    final result = await api.changeMyPassword(
      currentPassword: _currentController.text,
      newPassword: _newController.text,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    switch (result.status) {
      case PasswordChangeStatus.success:
        showOverlayToast(
          context,
          l.passwordChanged,
          icon: Icons.check_circle_outline_rounded,
        );
        Navigator.pop(context, true);
        break;
      case PasswordChangeStatus.invalidPassword:
        showOverlayToast(
          context,
          l.passwordInvalid,
          icon: Icons.error_outline_rounded,
        );
        break;
      case PasswordChangeStatus.unsupported:
        showOverlayToast(
          context,
          l.passwordChangeUnsupported,
          icon: Icons.info_outline_rounded,
        );
        break;
      case PasswordChangeStatus.failed:
        showOverlayToast(
          context,
          l.passwordChangeFailed,
          icon: Icons.error_outline_rounded,
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l.changePasswordTitle)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            l.passwordChangeEffect,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            key: const Key('currentPasswordField'),
            controller: _currentController,
            obscureText: true,
            autofillHints: const [AutofillHints.password],
            decoration: InputDecoration(labelText: l.currentPassword),
          ),
          const SizedBox(height: 16),
          TextField(
            key: const Key('newPasswordField'),
            controller: _newController,
            obscureText: true,
            autofillHints: const [AutofillHints.newPassword],
            decoration: InputDecoration(labelText: l.newPassword),
          ),
          const SizedBox(height: 16),
          TextField(
            key: const Key('confirmPasswordField'),
            controller: _confirmController,
            obscureText: true,
            autofillHints: const [AutofillHints.newPassword],
            decoration: InputDecoration(labelText: l.confirmNewPassword),
            onSubmitted: (_) => _saving ? null : _save(),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            key: const Key('changePasswordButton'),
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.password_rounded),
            label: Text(l.changePasswordTitle),
          ),
        ],
      ),
    );
  }
}
