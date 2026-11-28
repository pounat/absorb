import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../screens/bookorbit_admin_screen.dart';
import '../services/book_dock.dart';
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

/// A row naming the library folder something goes to, which opens a list
/// of them to pick from. [noneLabel] is the choice of no library.
class BoDestinationTile extends StatelessWidget {
  final String title;
  final List<BookDockDestination> destinations;
  final int? libraryId;
  final int? folderId;
  final String noneLabel;
  final bool enabled;
  final void Function(int? libraryId, int? folderId) onChanged;

  const BoDestinationTile({
    super.key,
    required this.title,
    required this.destinations,
    required this.libraryId,
    required this.folderId,
    required this.noneLabel,
    required this.onChanged,
    this.enabled = true,
  });

  bool _manyFolders(String libraryId) => destinations.where((d) => d.libraryId == libraryId).length > 1;

  String _label(BookDockDestination d) =>
      _manyFolders(d.libraryId) ? '${d.libraryName} / ${d.folderName}' : d.libraryName;

  /// The saved folder, or the library's first when only the library is set.
  BookDockDestination? get _current {
    if (libraryId == null) return null;
    final inLibrary = destinations.where((d) => d.libraryId == '$libraryId');
    for (final d in inLibrary) {
      if (d.folderId == '$folderId') return d;
    }
    return inLibrary.isEmpty ? null : inLibrary.first;
  }

  Future<void> _pick(BuildContext context) async {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final current = _current;
    final picked = await showModalBottomSheet<({int? libraryId, int? folderId})>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.6),
          child: ListView(shrinkWrap: true, padding: const EdgeInsets.symmetric(vertical: 12), children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
              child: Text(l.boDestinationPick,
                  style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
            ),
            ListTile(
              leading: Icon(Icons.block_rounded, color: cs.onSurfaceVariant),
              title: Text(noneLabel),
              trailing: libraryId == null ? Icon(Icons.check_circle_rounded, color: cs.primary) : null,
              onTap: () => Navigator.pop(ctx, (libraryId: null, folderId: null)),
            ),
            for (final d in destinations)
              ListTile(
                leading: Icon(Icons.auto_stories_rounded, color: cs.onSurfaceVariant),
                title: Text(d.libraryName),
                subtitle: _manyFolders(d.libraryId) ? Text(d.folderName) : null,
                trailing: identical(d, current) ? Icon(Icons.check_circle_rounded, color: cs.primary) : null,
                onTap: () => Navigator.pop(
                    ctx, (libraryId: int.tryParse(d.libraryId), folderId: int.tryParse(d.folderId))),
              ),
          ]),
        ),
      ),
    );
    if (picked != null) onChanged(picked.libraryId, picked.folderId);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final current = _current;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      enabled: enabled,
      title: Text(title),
      // A library this account can't see still has to read as set.
      subtitle: Text(current != null ? _label(current) : (libraryId == null ? noneLabel : '#$libraryId')),
      trailing: Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
      onTap: enabled ? () => _pick(context) : null,
    );
  }
}

/// A number picked on a slider, under a line that says what it is.
class BoSliderTile extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final bool enabled;
  final ValueChanged<int> onChanged;

  const BoSliderTile({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: tt.bodyMedium?.copyWith(color: enabled ? null : cs.onSurfaceVariant)),
        Slider(
          value: value.clamp(min, max).toDouble(),
          min: min.toDouble(),
          max: max.toDouble(),
          divisions: max - min,
          onChanged: enabled ? (v) => onChanged(v.round()) : null,
        ),
      ]),
    );
  }
}
