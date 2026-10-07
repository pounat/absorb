import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/library_provider.dart';
import 'overlay_toast.dart';
import 'sign_in_again.dart';

/// Cloud icon in page headers showing online/offline state.
///
/// Tap when offline triggers an immediate reconnect attempt; on failure shows
/// a "still offline" toast. Tap when online runs [onTapWhenOnline] (typically
/// switches to manual offline + stops the player when nothing is downloaded).
class OfflineStatusIcon extends StatelessWidget {
  final VoidCallback? onTapWhenOnline;

  const OfflineStatusIcon({super.key, this.onTapWhenOnline});

  @override
  Widget build(BuildContext context) {
    final lib = context.watch<LibraryProvider>();
    final auth = context.watch<AuthProvider>();
    final l = AppLocalizations.of(context)!;
    final offline = lib.isOffline;
    final reconnecting = lib.isReconnecting;
    final onLocal = !offline && auth.useLocalServer;
    if (auth.isSignedOut) {
      return Semantics(
        button: true,
        label: l.signedOutTapToSignIn,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => openSignInAgain(context),
          child: const Padding(
            padding: EdgeInsets.all(8),
            child: Icon(Icons.cloud_off_rounded, size: 20, color: Colors.redAccent),
          ),
        ),
      );
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: reconnecting
          ? null
          : () async {
              if (offline) {
                final ok = await lib.tryReconnect();
                if (!ok && context.mounted) {
                  showOverlayToast(context, l.stillOffline,
                      icon: Icons.cloud_off_rounded);
                }
              } else {
                onTapWhenOnline?.call();
              }
            },
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: SizedBox(
          width: 20,
          height: 20,
          child: reconnecting
              ? const Padding(
                  padding: EdgeInsets.all(1),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.orange,
                  ),
                )
              : Icon(
                  offline ? Icons.cloud_off_rounded : Icons.cloud_done_rounded,
                  size: 20,
                  color: offline
                      ? Colors.orange
                      : onLocal
                          ? Colors.lightBlueAccent
                          : Colors.green,
                ),
        ),
      ),
    );
  }
}
