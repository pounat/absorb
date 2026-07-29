import 'package:flutter/material.dart';

import 'absorb_wave_icon.dart';

class AuthLoadingScreen extends StatelessWidget {
  static const screenKey = Key('authLoadingScreen');

  const AuthLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Scaffold(
      key: screenKey,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AbsorbWaveIcon(size: 48, color: primary),
            const SizedBox(height: 20),
            Text(
              'A B S O R B',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: primary,
                letterSpacing: 6,
                fontWeight: FontWeight.w300,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: primary.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
