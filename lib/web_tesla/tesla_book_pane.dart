import 'package:flutter/material.dart';

/// Reuses the book's real cover, metadata, progress stream and control callbacks.
/// Vertical scrolling is deliberate: text scaling and short panes must not
/// shrink touch targets or clip the end of the book title.
class TeslaBookPane extends StatelessWidget {
  final String title, author;
  final Widget cover, progress, controls;
  const TeslaBookPane({super.key, required this.title, required this.author,
    required this.cover, required this.progress, required this.controls});
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    child: Center(child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 640),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Center(child: SizedBox(width: 112, height: 144, child: cover)),
        const SizedBox(height: 12),
        Text(title, style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center),
        if (author.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(author, style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center),
        ],
        const SizedBox(height: 12),
        DefaultTextStyle.merge(style: const TextStyle(fontSize: 16), child: progress),
        const SizedBox(height: 16),
        controls,
      ]),
    )),
  );
}
