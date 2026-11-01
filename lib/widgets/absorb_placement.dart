import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/library_provider.dart';
import '../services/wording.dart';
import 'adaptive_modal.dart';
import 'overlay_toast.dart';

enum _Placement { next, last }

/// Adds [key] to the Absorbing list, first asking whether it goes right
/// after what's playing or to the end. With nothing else on the list there's
/// nothing to choose, so it just adds. [item] should already carry anything
/// the card needs (an episode's `recentEpisode`). Returns false when the
/// picker was dismissed.
Future<bool> addToAbsorbingWithPicker(
  BuildContext context,
  String key, {
  Map<String, dynamic>? item,
  required String addedToast,
}) async {
  final lib = context.read<LibraryProvider>();
  var placement = _Placement.last;
  if (lib.absorbingBookIds.any((k) => k != key)) {
    final picked = await _pickPlacement(context);
    if (picked == null) return false;
    placement = picked;
  }
  if (placement == _Placement.next) {
    await lib.playNextInAbsorbing(key, item: item);
  } else {
    await lib.addToAbsorbingQueue(key, item: item);
  }
  HapticFeedback.mediumImpact();
  if (context.mounted) {
    showOverlayToast(
      context,
      placement == _Placement.next ? Wording.of(context).absorbNextAdded : addedToast,
      icon: placement == _Placement.next
          ? Icons.queue_play_next_rounded
          : Icons.add_circle_outline_rounded,
    );
  }
  return true;
}

Future<_Placement?> _pickPlacement(BuildContext context) {
  final cs = Theme.of(context).colorScheme;
  final l = AppLocalizations.of(context)!;
  final w = Wording.of(context);
  return showAdaptiveActionMenu<_Placement>(
    context: context,
    backgroundColor: Theme.of(context).bottomSheetTheme.backgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    desktopWidth: 400,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (!ModalSurface.isDesktopOf(ctx))
            Center(child: Container(width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.24),
                borderRadius: BorderRadius.circular(2)))),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Align(alignment: Alignment.centerLeft, child: Text(
              w.addToAbsorbing,
              style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600))),
          ),
          ListTile(
            leading: Icon(Icons.queue_play_next_rounded, color: cs.primary),
            title: Text(w.absorbNext),
            subtitle: Text(l.absorbNextHint),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            onTap: () => Navigator.pop(ctx, _Placement.next),
          ),
          ListTile(
            leading: Icon(Icons.playlist_add_rounded, color: cs.primary),
            title: Text(w.absorbLast),
            subtitle: Text(l.absorbLastHint),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            onTap: () => Navigator.pop(ctx, _Placement.last),
          ),
        ]),
      ),
    ),
  );
}
