import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../l10n/app_localizations.dart';

class AdminRmabScreen extends StatefulWidget {
  final String url;
  const AdminRmabScreen({super.key, required this.url});

  @override
  State<AdminRmabScreen> createState() => _AdminRmabScreenState();
}

class _AdminRmabScreenState extends State<AdminRmabScreen> {
  late final WebViewController _controller;
  int _progress = 0;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Theme.of(context).colorScheme.surface)
      ..setNavigationDelegate(NavigationDelegate(
        onProgress: (p) => mounted ? setState(() => _progress = p) : null,
        onPageStarted: (_) => mounted ? setState(() => _failed = false) : null,
        onWebResourceError: (e) {
          if (e.isForMainFrame == true && mounted) {
            setState(() => _failed = true);
          }
        },
      ))
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        title: Text(l.adminRmab),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: l.adminRmabReload,
            onPressed: () => _controller.reload(),
          ),
        ],
        bottom: _progress > 0 && _progress < 100
            ? PreferredSize(
                preferredSize: const Size.fromHeight(2),
                child: LinearProgressIndicator(
                  value: _progress / 100,
                  minHeight: 2,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation(cs.primary),
                ),
              )
            : null,
      ),
      body: _failed
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline_rounded,
                        size: 40, color: cs.onSurfaceVariant),
                    const SizedBox(height: 12),
                    Text(l.adminRmabLoadFailed,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        setState(() => _failed = false);
                        _controller.reload();
                      },
                      child: Text(l.adminRmabReload),
                    ),
                  ],
                ),
              ),
            )
          : WebViewWidget(controller: _controller),
    );
  }
}
