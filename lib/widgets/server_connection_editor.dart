import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

class ServerConnectionSettings {
  final String serverUrl;
  final Map<String, String> customHeaders;

  const ServerConnectionSettings({
    required this.serverUrl,
    required this.customHeaders,
  });
}

class ServerConnectionEditor extends StatefulWidget {
  final String username;
  final String serverUrl;
  final Map<String, String> customHeaders;

  const ServerConnectionEditor({
    super.key,
    required this.username,
    required this.serverUrl,
    this.customHeaders = const {},
  });

  @override
  State<ServerConnectionEditor> createState() => _ServerConnectionEditorState();
}

class _ServerConnectionEditorState extends State<ServerConnectionEditor> {
  late final TextEditingController _serverController;
  final List<(TextEditingController, TextEditingController)>
  _headerControllers = [];
  late bool _headersExpanded;

  @override
  void initState() {
    super.initState();
    _serverController = TextEditingController(text: widget.serverUrl);
    _headerControllers.addAll(
      widget.customHeaders.entries.map(
        (entry) => (
          TextEditingController(text: entry.key),
          TextEditingController(text: entry.value),
        ),
      ),
    );
    _headersExpanded = widget.customHeaders.isNotEmpty;
  }

  @override
  void dispose() {
    _serverController.dispose();
    for (final (key, value) in _headerControllers) {
      key.dispose();
      value.dispose();
    }
    super.dispose();
  }

  Map<String, String> _collectHeaders() {
    final headers = <String, String>{};
    for (final (keyController, valueController) in _headerControllers) {
      final key = keyController.text.trim();
      final value = valueController.text.trim();
      if (key.isNotEmpty && value.isNotEmpty) headers[key] = value;
    }
    return headers;
  }

  void _addHeader() {
    setState(() {
      _headersExpanded = true;
      _headerControllers.add((
        TextEditingController(),
        TextEditingController(),
      ));
    });
  }

  void _removeHeader(int index) {
    final (key, value) = _headerControllers.removeAt(index);
    key.dispose();
    value.dispose();
    setState(() {});
  }

  void _save() {
    final serverUrl = _serverController.text.trim();
    if (serverUrl.isEmpty) return;
    Navigator.pop(
      context,
      ServerConnectionSettings(
        serverUrl: serverUrl,
        customHeaders: _collectHeaders(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AlertDialog(
      title: Text(l.editServerConnectionTitle),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.editServerConnectionSubtitle(widget.username),
                style: textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                key: const Key('server-connection-url'),
                controller: _serverController,
                autofocus: true,
                keyboardType: TextInputType.url,
                autocorrect: false,
                decoration: InputDecoration(
                  labelText: l.editServerAddressField,
                  hintText: 'https://example.com',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                key: const Key('toggle-custom-headers'),
                borderRadius: BorderRadius.circular(8),
                onTap: () =>
                    setState(() => _headersExpanded = !_headersExpanded),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.vpn_key_rounded,
                        size: 18,
                        color: cs.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l.loginCustomHttpHeaders,
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (_headerControllers.isNotEmpty)
                        Text(
                          '${_headerControllers.length}',
                          style: textTheme.labelMedium?.copyWith(
                            color: cs.primary,
                          ),
                        ),
                      const SizedBox(width: 4),
                      Icon(
                        _headersExpanded
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        color: cs.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
              if (_headersExpanded) ...[
                Text(
                  l.editCustomHeadersDescription,
                  style: textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 10),
                ..._headerControllers.asMap().entries.map((entry) {
                  final index = entry.key;
                  final (keyController, valueController) = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            key: Key('custom-header-name-$index'),
                            controller: keyController,
                            autocorrect: false,
                            decoration: InputDecoration(
                              labelText: l.loginHeaderName,
                              border: const OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 3,
                          child: TextField(
                            key: Key('custom-header-value-$index'),
                            controller: valueController,
                            autocorrect: false,
                            enableSuggestions: false,
                            decoration: InputDecoration(
                              labelText: l.loginHeaderValue,
                              border: const OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        IconButton(
                          key: Key('remove-custom-header-$index'),
                          tooltip: l.remove,
                          onPressed: () => _removeHeader(index),
                          icon: const Icon(Icons.close_rounded),
                          color: cs.error,
                        ),
                      ],
                    ),
                  );
                }),
                TextButton.icon(
                  key: const Key('add-custom-header'),
                  onPressed: _addHeader,
                  icon: const Icon(Icons.add_rounded),
                  label: Text(l.loginAddHeader),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.cancel),
        ),
        FilledButton(
          key: const Key('save-server-connection'),
          onPressed: _save,
          child: Text(l.save),
        ),
      ],
    );
  }
}
