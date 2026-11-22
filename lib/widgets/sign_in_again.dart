import 'package:flutter/material.dart';
import '../screens/login_screen.dart';
import '../services/signed_out_playback.dart';

/// Sign-in for the account whose session ended, filled in. Signing in pops
/// back to wherever the user was.
Future<void> openSignInAgain(BuildContext context) =>
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => LoginScreen(prefillAccount: SignedOutPlayback.expiredAccount()),
      ),
    );
