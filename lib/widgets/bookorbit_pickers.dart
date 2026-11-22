import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../screens/bookorbit_admin_screen.dart';
import '../services/bookorbit_admin.dart';

/// Grouped permission checkboxes with BookOrbit's presets on top. [only]
/// narrows the list to those permissions, for a key that can hold no more
/// than its owner has; the presets then mean none or all of those.
class BoPermissionPicker extends StatelessWidget {
  final Set<String> selected;
  final bool enabled;
  final Set<String>? only;
  final ValueChanged<Set<String>> onChanged;

  const BoPermissionPicker({
    super.key,
    required this.selected,
    required this.onChanged,
    this.enabled = true,
    this.only,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;
    final limit = only;
    final all = limit == null ? boAllPermissions : boAllPermissions.where(limit.contains).toSet();
    Widget preset(String label, Set<String> perms) {
      final on = selected.length == perms.length && selected.containsAll(perms);
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(label),
          selected: on,
          onSelected: enabled ? (_) => onChanged({...perms}) : null,
        ),
      );
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Wrap(children: [
          preset(l.boUserPresetNone, const {}),
          if (limit == null) preset(l.boUserPresetStandard, boStandardPermissions),
          preset(l.boUserPresetEverything, all),
        ]),
      ),
      for (final group in boPermissionGroups)
        if (limit == null || group.permissions.any(limit.contains)) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 14, 4, 2),
            child: Text(boPermissionGroupLabel(l, group.key),
                style: tt.labelLarge?.copyWith(color: cs.primary, fontWeight: FontWeight.w600)),
          ),
          for (final p in group.permissions)
            if (limit == null || limit.contains(p))
              CheckboxListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                value: selected.contains(p),
                title: Text(boPermissionLabel(l, p)),
                onChanged: enabled
                    ? (v) => onChanged(v == true ? {...selected, p} : ({...selected}..remove(p)))
                    : null,
              ),
        ],
    ]);
  }
}

class BoLibraryPicker extends StatelessWidget {
  final List<BoLibrary> libraries;
  final Set<int> selected;
  final bool enabled;
  final ValueChanged<Set<int>> onChanged;

  const BoLibraryPicker({
    super.key,
    required this.libraries,
    required this.selected,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      for (final lib in libraries)
        CheckboxListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          secondary: Icon(boLibraryIcon(lib.icon)),
          value: selected.contains(lib.id),
          title: Text(lib.name),
          onChanged: enabled
              ? (v) => onChanged(v == true ? {...selected, lib.id} : ({...selected}..remove(lib.id)))
              : null,
        ),
    ]);
  }
}

/// A rounded card of settings with an optional title and hint, the way the
/// BookOrbit admin pages lay theirs out.
class BoSection extends StatelessWidget {
  final String? title;
  final String? hint;
  final List<Widget> children;

  const BoSection({super.key, this.title, this.hint, required this.children});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        decoration: BoxDecoration(color: cs.surfaceContainerHigh, borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(title!, style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
            ),
          if (hint != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 2, 4, 0),
              child: Text(hint!, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
            ),
          const SizedBox(height: 6),
          ...children,
        ]),
      ),
    );
  }
}
