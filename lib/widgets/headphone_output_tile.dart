import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _headphoneChannel = MethodChannel('com.absorb.headphones');

class HeadphoneOutputTile extends StatefulWidget {
  const HeadphoneOutputTile({super.key});

  @override
  State<HeadphoneOutputTile> createState() => _HeadphoneOutputTileState();
}

class _HeadphoneOutputTileState extends State<HeadphoneOutputTile> {
  String _subtitle = 'Use headphones while Android Auto stays connected';

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    try {
      final state = await _headphoneChannel.invokeMapMethod<String, dynamic>(
        'state',
      );
      if (!mounted || state == null) return;
      final selected = state['selectedKey'] as String? ?? '';
      setState(() {
        _subtitle = selected.isEmpty
            ? 'Use headphones while Android Auto stays connected'
            : '${state['selectedName']} ${state['connected'] == true ? "selected" : "disconnected"}';
      });
    } on PlatformException {
      if (mounted)
        setState(() => _subtitle = 'Tap to retry audio output settings');
    } on MissingPluginException {
      if (mounted)
        setState(() => _subtitle = 'Headphone controls are unavailable');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: const Icon(Icons.headphones_rounded),
        title: const Text('Headphone output'),
        subtitle: Text(_subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () async {
          await showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            showDragHandle: true,
            builder: (_) => const HeadphoneOutputSheet(),
          );
          await _refresh();
        },
      ),
    );
  }
}

class HeadphoneOutputSheet extends StatefulWidget {
  const HeadphoneOutputSheet({super.key});

  @override
  State<HeadphoneOutputSheet> createState() => _HeadphoneOutputSheetState();
}

class _HeadphoneOutputSheetState extends State<HeadphoneOutputSheet>
    with WidgetsBindingObserver {
  Map<String, dynamic>? _state;
  String? _error;
  bool _changing = false;
  bool _reading = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) => _refresh());
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    if (_reading || _changing) return;
    _reading = true;
    try {
      final state = await _headphoneChannel.invokeMapMethod<String, dynamic>(
        'state',
      );
      if (mounted) setState(() => _state = state);
    } on PlatformException catch (error) {
      if (mounted)
        setState(
          () => _error = error.message ?? 'Could not read audio outputs.',
        );
    } on MissingPluginException {
      if (mounted)
        setState(
          () => _error = 'Headphone controls are unavailable in this build.',
        );
    } finally {
      _reading = false;
    }
  }

  Future<void> _select(String key) async {
    setState(() {
      _changing = true;
      _error = null;
    });
    try {
      final state = await _headphoneChannel.invokeMapMethod<String, dynamic>(
        'select',
        {'key': key},
      );
      if (mounted) setState(() => _state = state);
    } on PlatformException catch (error) {
      if (mounted)
        setState(
          () => _error = error.message ?? 'Could not change the audio output.',
        );
    } on MissingPluginException {
      if (mounted)
        setState(
          () => _error = 'Headphone controls are unavailable in this build.',
        );
    } finally {
      if (mounted) setState(() => _changing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = _state?['selectedKey'] as String? ?? '';
    final connected = _state?['connected'] == true;
    final reported = (_state?['reportedOutputs'] as List? ?? const [])
        .cast<String>();
    final devices = (_state?['devices'] as List? ?? const [])
        .map((device) => Map<String, dynamic>.from(device as Map))
        .toList();
    final colors = Theme.of(context).colorScheme;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Headphone output',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              const Text(
                'Choose your headphones to try listening privately while Android Auto stays on the car screen. This mode is experimental.',
              ),
              const SizedBox(height: 8),
              const Text(
                'Playback pauses if the selected headphones disconnect. Reconnect them and press Play to continue.',
              ),
              const SizedBox(height: 12),
              if (reported.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text('Android reports: ${reported.join(', ')}'),
                ),
              if (_state == null && _error == null)
                const Center(child: CircularProgressIndicator()),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(_error!, style: TextStyle(color: colors.error)),
                ),
              if (selected.isNotEmpty && !connected)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    '${_state?['selectedName'] ?? 'Headphones'} disconnected. Playback will stay paused.',
                    style: TextStyle(color: colors.error),
                  ),
                ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.speaker_group_outlined),
                title: const Text('Normal audio output'),
                subtitle: const Text('Let Android choose the output'),
                trailing: selected.isEmpty
                    ? const Icon(Icons.check_circle_rounded)
                    : null,
                enabled: !_changing && _state != null,
                onTap: () => _select(''),
              ),
              const Divider(),
              for (final device in devices)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    device['bluetooth'] == true
                        ? Icons.bluetooth_audio_rounded
                        : Icons.headphones_rounded,
                  ),
                  title: Text(device['name'] as String),
                  subtitle: Text(
                    device['key'] == selected
                        ? 'Selected for headphone mode'
                        : 'Tap to use this output',
                  ),
                  trailing: device['key'] == selected
                      ? const Icon(Icons.check_circle_rounded)
                      : null,
                  enabled: !_changing,
                  onTap: () => _select(device['key'] as String),
                ),
              if (devices.isEmpty && _state != null)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Connect your headphones in Android Bluetooth settings, then refresh.',
                  ),
                ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _changing ? null : _refresh,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Refresh devices'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
