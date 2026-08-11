import 'package:flutter/material.dart';

class DesktopCoverSizeControl extends StatelessWidget {
  final int value;
  final int minimum;
  final int maximum;
  final VoidCallback? onDecrease;
  final VoidCallback? onIncrease;

  const DesktopCoverSizeControl({
    super.key,
    required this.value,
    required this.onDecrease,
    required this.onIncrease,
    this.minimum = 60,
    this.maximum = 220,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final canDecrease = value > minimum && onDecrease != null;
    final canIncrease = value < maximum && onIncrease != null;

    return Semantics(
      container: true,
      label: 'Cover size',
      value: '$value',
      child: Material(
        elevation: 6,
        shadowColor: Colors.black.withValues(alpha: 0.28),
        color: cs.surfaceContainerHigh.withValues(alpha: 0.96),
        shape: StadiumBorder(
          side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.55)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: canDecrease ? onDecrease : null,
              tooltip: 'Decrease cover size',
              icon: const Icon(Icons.remove_rounded),
              iconSize: 20,
              visualDensity: VisualDensity.compact,
            ),
            Semantics(
              excludeSemantics: true,
              child: SizedBox(
                width: 42,
                child: Text(
                  '$value',
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            IconButton(
              onPressed: canIncrease ? onIncrease : null,
              tooltip: 'Increase cover size',
              icon: const Icon(Icons.add_rounded),
              iconSize: 20,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}
