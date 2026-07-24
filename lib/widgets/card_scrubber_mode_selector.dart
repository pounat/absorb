import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/player_settings.dart';

class CardScrubberModeSelector extends StatelessWidget {
  const CardScrubberModeSelector({
    super.key,
    required this.mode,
    required this.onChanged,
    this.enabled = true,
  });

  final CardScrubberMode mode;
  final ValueChanged<CardScrubberMode> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return LayoutBuilder(
      builder: (context, constraints) {
        final scaledLabelSize = MediaQuery.textScalerOf(context).scale(14);
        final compact = constraints.maxWidth < 360 || scaledLabelSize > 18;

        Widget label(String text) => Padding(
          padding: EdgeInsets.symmetric(horizontal: compact ? 0 : 4),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(text, maxLines: 1, softWrap: false),
          ),
        );

        return SizedBox(
          width: double.infinity,
          child: SegmentedButton<CardScrubberMode>(
            key: const Key('card-scrubber-mode-selector'),
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                value: CardScrubberMode.both,
                label: label(l.cardScrubbersBoth),
              ),
              ButtonSegment(
                value: CardScrubberMode.chapter,
                label: label(l.cardScrubbersChapter),
              ),
              ButtonSegment(
                value: CardScrubberMode.locked,
                label: label(l.cardScrubbersLocked),
              ),
            ],
            selected: {mode},
            onSelectionChanged: enabled
                ? (selection) {
                    if (selection.isNotEmpty) onChanged(selection.first);
                  }
                : null,
            style: ButtonStyle(
              visualDensity: compact
                  ? VisualDensity.compact
                  : VisualDensity.standard,
              padding: WidgetStatePropertyAll(
                EdgeInsets.symmetric(horizontal: compact ? 4 : 10),
              ),
            ),
          ),
        );
      },
    );
  }
}
