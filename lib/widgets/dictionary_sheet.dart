import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../services/dictionary_service.dart';

/// In-app word lookup: opens instantly with a spinner, then renders the
/// definition (or a not-found / error state with a web-search escape hatch).
/// Tapping a synonym looks that word up in place.
Future<void> showDictionarySheet(BuildContext context, String word) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => _DictionarySheet(word: word),
  );
}

class _DictionarySheet extends StatefulWidget {
  final String word;
  const _DictionarySheet({required this.word});

  @override
  State<_DictionarySheet> createState() => _DictionarySheetState();
}

class _DictionarySheetState extends State<_DictionarySheet> {
  late Future<DictionaryResult> _lookup;
  late String _word;

  @override
  void initState() {
    super.initState();
    _word = widget.word;
    _lookup = DictionaryService.lookup(_word);
  }

  void _lookupWord(String word) {
    setState(() {
      _word = word;
      _lookup = DictionaryService.lookup(word);
    });
  }

  void _searchWeb() {
    final query = Uri.encodeComponent('define $_word');
    launchUrl(Uri.parse('https://www.google.com/search?q=$query'),
        mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.7,
        ),
        child: FutureBuilder<DictionaryResult>(
          future: _lookup,
          builder: (context, snap) {
            final result = snap.data;
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Flexible(
                        child: Text(_word,
                            style: tt.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w700)),
                      ),
                      if (result?.phonetic != null) ...[
                        const SizedBox(width: 10),
                        Text(result!.phonetic!,
                            style: tt.bodyMedium
                                ?.copyWith(color: cs.onSurfaceVariant)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (result == null)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  else if (result.status == DictionaryStatus.found)
                    ..._buildMeanings(result, cs, tt)
                  else ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        result.status == DictionaryStatus.notFound
                            ? l.dictionaryNotFound
                            : l.dictionaryError,
                        style: tt.bodyMedium
                            ?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(children: [
                      if (result.status == DictionaryStatus.error)
                        OutlinedButton.icon(
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: Text(l.dictionaryRetry),
                          onPressed: () => _lookupWord(_word),
                        ),
                      if (result.status == DictionaryStatus.error)
                        const SizedBox(width: 12),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.travel_explore_rounded, size: 18),
                        label: Text(l.dictionarySearchWeb),
                        onPressed: _searchWeb,
                      ),
                    ]),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildMeanings(
      DictionaryResult result, ColorScheme cs, TextTheme tt) {
    final widgets = <Widget>[];
    for (final m in result.meanings) {
      widgets.add(Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 4),
        child: Text(m.partOfSpeech,
            style: tt.titleSmall?.copyWith(
                color: cs.primary,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w600)),
      ));
      for (var i = 0; i < m.definitions.length; i++) {
        final d = m.definitions[i];
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${i + 1}. ${d.definition}', style: tt.bodyMedium),
              if (d.example != null && d.example!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 16, top: 2),
                  child: Text('"${d.example}"',
                      style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontStyle: FontStyle.italic)),
                ),
            ],
          ),
        ));
      }
      if (m.synonyms.isNotEmpty) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 2, bottom: 6),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final s in m.synonyms)
                ActionChip(
                  label: Text(s, style: tt.labelSmall),
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _lookupWord(s),
                ),
            ],
          ),
        ));
      }
    }
    return widgets;
  }
}
