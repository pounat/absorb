import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/aaos_service.dart';
import '../services/android_auto_service.dart';
import 'settings_screen.dart';

/// What a signed-in user sees on an Android Automotive head unit while parked.
/// Listening happens in the car's media browser, so this is deliberately just
/// a launch point for the browser plus setup actions, not the full app.
class AaosParkedScreen extends StatefulWidget {
  const AaosParkedScreen({super.key});

  @override
  State<AaosParkedScreen> createState() => _AaosParkedScreenState();
}

class _AaosParkedScreenState extends State<AaosParkedScreen> {
  @override
  void initState() {
    super.initState();
    // Warm the browse tree so content is ready if the user opens the media
    // browser from here. (Sign-in itself bounces straight to the car and
    // triggers its own refresh.)
    AndroidAutoService().refresh(force: true);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.directions_car_rounded, size: 72, color: cs.primary),
                const SizedBox(height: 16),
                Text(
                  'Absorb is ready in your car',
                  style: text.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Use the media browser to listen. This screen is just for setup while parked.',
                  style: text.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                FilledButton.icon(
                  icon: const Icon(Icons.play_circle_outline),
                  label: const Text('Open media browser'),
                  onPressed: () =>
                      AaosService.instance.launchMediaCenter(finishActivity: true),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.settings),
                  label: const Text('Settings'),
                  onPressed: () => Navigator.of(context)
                      .push(MaterialPageRoute(
                          builder: (_) => const SettingsScreen()))
                      .then((_) => AaosService.instance
                          .launchMediaCenter(finishActivity: true)),
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign out'),
                  onPressed: () => context.read<AuthProvider>().logout(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
