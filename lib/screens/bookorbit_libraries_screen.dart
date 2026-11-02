import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/api_service.dart';
import '../services/bookorbit_admin.dart';
import '../widgets/absorb_page_header.dart';
import '../widgets/overlay_toast.dart';
import 'bookorbit_admin_screen.dart';

/// The libraries on the BookOrbit server, for people who manage them.
class BookOrbitLibrariesScreen extends StatefulWidget {
  const BookOrbitLibrariesScreen({super.key});

  @override
  State<BookOrbitLibrariesScreen> createState() => _BookOrbitLibrariesScreenState();
}

class _BookOrbitLibrariesScreenState extends State<BookOrbitLibrariesScreen> {
  List<BoLibrary> _libraries = [];
  Map<int, BoLibraryOverview> _overview = {};
  final Set<int> _starting = {};
  bool _loading = true;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _reload() async {
    final api = boAdminApi(context);
    if (api == null) return;
    setState(() => _loading = true);
    try {
      final libs = await api.adminLibraries();
      Map<int, BoLibraryOverview> overview = {};
      try {
        overview = await api.adminLibraryOverview();
      } on BookOrbitAdminError {
        // Counts and scans are extras; the list stands without them.
      }
      if (!mounted) return;
      setState(() {
        _libraries = libs;
        _overview = overview;
      });
      _pollWhileScanning();
    } catch (e) {
      if (mounted) showBoAdminError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Keeps the scan lines current while any library is scanning.
  void _pollWhileScanning() {
    final scanning = _overview.values.any((o) => o.lastScan?.running == true) || _starting.isNotEmpty;
    if (!scanning) {
      _poll?.cancel();
      _poll = null;
      return;
    }
    _poll ??= Timer.periodic(const Duration(seconds: 5), (_) async {
      final api = boAdminApi(context);
      if (api == null || !mounted) return;
      try {
        final overview = await api.adminLibraryOverview();
        if (!mounted) return;
        setState(() {
          _overview = overview;
          _starting.removeWhere((id) => overview[id]?.lastScan?.running == true);
        });
      } on BookOrbitAdminError {
        return;
      }
      _pollWhileScanning();
    });
  }

  Future<void> _scan(BoLibrary lib) async {
    final api = boAdminApi(context);
    final l = AppLocalizations.of(context)!;
    if (api == null) return;
    try {
      await api.adminScanLibrary(lib.id);
      if (!mounted) return;
      setState(() => _starting.add(lib.id));
      showOverlayToast(context, l.boLibScanStarted, icon: Icons.sync_rounded);
      _pollWhileScanning();
      // A scan that finishes before the first look leaves nothing running to
      // wait on, so stop waiting after a while either way.
      Timer(const Duration(seconds: 20), () {
        if (mounted) setState(() => _starting.remove(lib.id));
      });
    } catch (e) {
      if (mounted) showBoAdminError(context, e);
    }
  }

  Future<void> _reorder(int oldIndex, int newIndex) async {
    final api = boAdminApi(context);
    if (api == null) return;
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      _libraries.insert(newIndex, _libraries.removeAt(oldIndex));
    });
    try {
      await api.adminReorderLibraries([for (final lib in _libraries) lib.id]);
    } catch (e) {
      if (mounted) showBoAdminError(context, e);
      _reload();
    }
  }

  Future<void> _open([BoLibrary? lib]) async {
    final changed = await Navigator.push<bool>(
        context, MaterialPageRoute(builder: (_) => _BookOrbitLibraryScreen(library: lib)));
    if (changed == true) _reload();
  }

  String _status(AppLocalizations l, BoLibrary lib) {
    final o = _overview[lib.id];
    final count = l.boLibBookCount(o?.totalBooks ?? lib.bookCount ?? 0);
    final scan = o?.lastScan;
    final String scanText;
    if (_starting.contains(lib.id) || scan?.running == true) {
      scanText = l.boLibScanning;
    } else if (scan == null) {
      scanText = l.boLibNeverScanned;
    } else if (scan.failed) {
      scanText = l.boLibScanFailed;
    } else {
      final at = scan.completedAt ?? scan.startedAt;
      scanText = at == null
          ? l.boLibNeverScanned
          : l.boLibLastScan(l.backupDateFormat(at.month, at.day, at.year), scan.added, scan.updated, scan.missing);
    }
    return '$count\n$scanText';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 8, 0),
            child: Row(children: [
              Expanded(child: AbsorbPageHeader(title: l.boAdminLibraries, padding: EdgeInsets.zero)),
              IconButton(
                icon: Icon(Icons.add_rounded, color: cs.primary),
                tooltip: l.boLibNew,
                onPressed: () => _open(),
              ),
              IconButton(
                icon: Icon(Icons.close_rounded, color: cs.onSurfaceVariant),
                onPressed: () => Navigator.pop(context),
              ),
            ]),
          ),
          const SizedBox(height: 8),
          if (_loading) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _reload,
              child: _libraries.isEmpty && !_loading
                  ? ListView(children: [
                      const SizedBox(height: 120),
                      Center(
                        child: Text(l.boLibsNone,
                            style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant.withValues(alpha: 0.6))),
                      ),
                    ])
                  : ReorderableListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                      itemCount: _libraries.length,
                      onReorder: _reorder,
                      buildDefaultDragHandles: false,
                      itemBuilder: (context, i) {
                        final lib = _libraries[i];
                        final busy = _starting.contains(lib.id) || _overview[lib.id]?.lastScan?.running == true;
                        return Container(
                          key: ValueKey(lib.id),
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration:
                              BoxDecoration(color: cs.surfaceContainerHigh, borderRadius: BorderRadius.circular(16)),
                          child: ListTile(
                            onTap: () => _open(lib),
                            leading: Icon(boLibraryIcon(lib.icon), color: cs.primary),
                            title: Text(lib.name, style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                            subtitle: Text(_status(l, lib),
                                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant.withValues(alpha: 0.75))),
                            isThreeLine: true,
                            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                              busy
                                  ? const Padding(
                                      padding: EdgeInsets.all(12),
                                      child: SizedBox(
                                          width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                                    )
                                  : IconButton(
                                      icon: Icon(Icons.sync_rounded, color: cs.onSurfaceVariant),
                                      tooltip: l.boLibScanNow,
                                      onPressed: () => _scan(lib),
                                    ),
                              ReorderableDragStartListener(
                                index: i,
                                child: Icon(Icons.drag_handle_rounded, color: cs.onSurface.withValues(alpha: 0.3)),
                              ),
                            ]),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _BookOrbitLibraryScreen extends StatefulWidget {
  final BoLibrary? library;
  const _BookOrbitLibraryScreen({this.library});

  @override
  State<_BookOrbitLibraryScreen> createState() => _BookOrbitLibraryScreenState();
}

class _BookOrbitLibraryScreenState extends State<_BookOrbitLibraryScreen> {
  late final _name = TextEditingController(text: widget.library?.name ?? '');
  late String _icon = widget.library?.icon ?? 'Library';
  late List<String> _folders = [...?widget.library?.folders];
  late String _organization = widget.library?.organizationMode ?? 'book_per_folder';
  late bool _watch = widget.library?.watch ?? true;
  late String? _cron = widget.library?.autoScanCron;
  late String _cover = widget.library?.coverAspectRatio ?? '2/3';
  final Map<String, BoFolderCheck> _checks = {};
  List<BoLibraryAccess> _access = const [];
  bool _saving = false;
  bool _changed = false;

  BoLibrary? get _lib => widget.library;
  bool get _isNew => _lib == null;

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() {}));
    if (!_isNew) {
      _loadFull();
      _loadAccess();
    }
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  /// The list may come without every field (someone who manages libraries
  /// but isn't an admin), so read the library itself.
  Future<void> _loadFull() async {
    final api = boAdminApi(context);
    if (api == null) return;
    try {
      final full = await api.adminLibrary(_lib!.id);
      if (!mounted) return;
      setState(() {
        _folders = [...full.folders];
        _watch = full.watch;
        _cron = full.autoScanCron;
        _cover = full.coverAspectRatio;
        _organization = full.organizationMode;
        if (!boLibraryIcons.contains(_icon)) _icon = full.icon;
      });
      _checkFolders(_folders);
    } on BookOrbitAdminError {
      return;
    }
  }

  Future<void> _loadAccess() async {
    final api = boAdminApi(context);
    if (api == null) return;
    try {
      final access = await api.adminLibraryAccess(_lib!.id);
      if (mounted) setState(() => _access = access);
    } catch (e) {
      if (mounted) showBoAdminError(context, e);
    }
  }

  Future<void> _checkFolders(List<String> paths) async {
    final api = boAdminApi(context);
    if (api == null || paths.isEmpty) return;
    try {
      final checks = await api.adminCheckFolders(paths, libraryId: _lib?.id);
      if (!mounted) return;
      setState(() {
        for (final c in checks) {
          _checks[c.path] = c;
        }
      });
    } on BookOrbitAdminError {
      return;
    }
  }

  Future<void> _addFolder() async {
    final picked = await Navigator.push<String>(
        context, MaterialPageRoute(builder: (_) => const _BookOrbitFolderPicker()));
    if (picked == null || _folders.contains(picked)) return;
    setState(() => _folders = [..._folders, picked]);
    _checkFolders([picked]);
  }

  bool get _sameFolders {
    final saved = _lib?.folders ?? const [];
    return saved.length == _folders.length && saved.toSet().containsAll(_folders);
  }

  bool get _dirty {
    final lib = _lib;
    if (lib == null) return true;
    return _name.text.trim() != lib.name ||
        _icon != lib.icon ||
        !_sameFolders ||
        _watch != lib.watch ||
        _cron != lib.autoScanCron ||
        _cover != lib.coverAspectRatio;
  }

  Future<void> _save() async {
    final api = boAdminApi(context);
    final l = AppLocalizations.of(context)!;
    if (api == null) return;
    final name = _name.text.trim();
    if (name.isEmpty) {
      showOverlayToast(context, l.boLibNeedName, icon: Icons.error_outline_rounded);
      return;
    }
    if (_folders.isEmpty) {
      showOverlayToast(context, l.boLibNeedFolder, icon: Icons.error_outline_rounded);
      return;
    }
    setState(() => _saving = true);
    try {
      final lib = _lib;
      if (lib == null) {
        await api.adminCreateLibrary(
          name: name,
          icon: _icon,
          folders: _folders,
          organizationMode: _organization,
          coverAspectRatio: _cover,
          watch: _watch,
          autoScanCron: _cron,
        );
      } else {
        await api.adminUpdateLibrary(
          lib.id,
          name: name != lib.name ? name : null,
          icon: _icon != lib.icon ? _icon : null,
          folders: _sameFolders ? null : _folders,
          coverAspectRatio: _cover != lib.coverAspectRatio ? _cover : null,
          watch: _watch != lib.watch ? _watch : null,
          setAutoScan: _cron != lib.autoScanCron,
          autoScanCron: _cron,
        );
      }
      if (!mounted) return;
      showOverlayToast(context, l.boAdminSaved, icon: Icons.check_circle_outline_rounded);
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showBoAdminError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final api = boAdminApi(context);
    final l = AppLocalizations.of(context)!;
    final lib = _lib;
    if (api == null || lib == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.boLibDeleteTitle(lib.name)),
        content: Text(l.boLibDeleteBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.delete),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await api.adminDeleteLibrary(lib.id);
      if (!mounted) return;
      showOverlayToast(context, l.boLibDeleted, icon: Icons.check_circle_outline_rounded);
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showBoAdminError(context, e);
    }
  }

  Future<void> _setLevel(BoLibraryAccess a, String level) async {
    final api = boAdminApi(context);
    if (api == null || a.level == level) return;
    try {
      await api.adminSetLibraryAccess(_lib!.id, a.userId, level);
      _changed = true;
      await _loadAccess();
    } catch (e) {
      if (mounted) showBoAdminError(context, e);
    }
  }

  Future<void> _removeAccess(BoLibraryAccess a) async {
    final api = boAdminApi(context);
    if (api == null) return;
    try {
      await api.adminRemoveLibraryAccess(_lib!.id, a.userId);
      _changed = true;
      await _loadAccess();
    } catch (e) {
      if (mounted) showBoAdminError(context, e);
    }
  }

  Future<void> _addAccess() async {
    final api = boAdminApi(context);
    final l = AppLocalizations.of(context)!;
    if (api == null) return;
    List<BoAssignableUser> people;
    try {
      people = await api.adminAssignableUsers();
    } catch (e) {
      if (mounted) showBoAdminError(context, e);
      return;
    }
    final have = {for (final a in _access) a.userId};
    final options = [for (final p in people) if (!have.contains(p.id)) p];
    if (!mounted) return;
    if (options.isEmpty) {
      showOverlayToast(context, l.boLibAccessEveryoneHas, icon: Icons.info_outline_rounded);
      return;
    }
    final picked = await showModalBottomSheet<BoAssignableUser>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: ListView(shrinkWrap: true, children: [
          for (final p in options)
            ListTile(
              leading: const Icon(Icons.person_outline_rounded),
              title: Text(p.name),
              subtitle: Text('@${p.username}'),
              onTap: () => Navigator.pop(ctx, p),
            ),
        ]),
      ),
    );
    if (picked == null) return;
    try {
      await api.adminSetLibraryAccess(_lib!.id, picked.id, 'viewer');
      _changed = true;
      await _loadAccess();
    } catch (e) {
      if (mounted) showBoAdminError(context, e);
    }
  }

  String _levelLabel(AppLocalizations l, String level) => switch (level) {
        'editor' => l.boLibLevelEditor,
        'owner' => l.boLibLevelOwner,
        _ => l.boLibLevelViewer,
      };

  String _scheduleKey() {
    final cron = _cron;
    if (cron == null || cron.isEmpty) return 'off';
    for (final e in boScanSchedules.entries) {
      if (e.value == cron) return e.key;
    }
    return 'custom';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;
    final schedule = _scheduleKey();
    final icons = [...boLibraryIcons, if (!boLibraryIcons.contains(_icon)) _icon];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pop(context, _changed);
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: Row(children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => Navigator.pop(context, _changed),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: AbsorbPageHeader(
                      title: _isNew ? l.boLibNew : (_lib!.name), padding: EdgeInsets.zero),
                ),
                FilledButton(
                  onPressed: _dirty && !_saving ? _save : null,
                  child: Text(_isNew ? l.boUserCreate : l.save),
                ),
                const SizedBox(width: 8),
              ]),
            ),
            if (_saving) const LinearProgressIndicator(minHeight: 2),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                children: [
                  _Card(children: [
                    TextField(controller: _name, decoration: InputDecoration(labelText: l.boLibName)),
                    const SizedBox(height: 14),
                    Text(l.boLibIcon, style: tt.labelLarge?.copyWith(color: cs.onSurfaceVariant)),
                    const SizedBox(height: 6),
                    Wrap(spacing: 6, runSpacing: 6, children: [
                      for (final name in icons)
                        ChoiceChip(
                          label: Icon(boLibraryIcon(name), size: 20),
                          selected: _icon == name,
                          showCheckmark: false,
                          onSelected: (_) => setState(() => _icon = name),
                        ),
                    ]),
                  ]),
                  _Card(title: l.boLibFolders, hint: l.boLibFoldersHint, children: [
                    for (final f in _folders) _folderTile(l, cs, tt, f),
                    TextButton.icon(
                      onPressed: _addFolder,
                      icon: const Icon(Icons.create_new_folder_outlined),
                      label: Text(l.boLibAddFolder),
                    ),
                    if (!_isNew && !_sameFolders)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
                        child: Text(l.boLibFolderRescan, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                      ),
                  ]),
                  if (_isNew)
                    _Card(title: l.boLibOrganization, hint: l.boLibOrganizationFixed, children: [
                      RadioGroup<String>(
                        groupValue: _organization,
                        onChanged: (v) => setState(() => _organization = v ?? _organization),
                        child: Column(children: [
                          RadioListTile<String>(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                            value: 'book_per_folder',
                            title: Text(l.boLibPerFolder),
                          ),
                          RadioListTile<String>(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                            value: 'book_per_file',
                            title: Text(l.boLibPerFile),
                          ),
                        ]),
                      ),
                    ]),
                  _Card(children: [
                    SwitchListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                      title: Text(l.boLibWatch),
                      subtitle: Text(l.boLibWatchSubtitle),
                      value: _watch,
                      onChanged: (v) => setState(() => _watch = v),
                    ),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                      title: Text(l.boLibSchedule),
                      subtitle: schedule == 'daily' || schedule == 'weekly' ? Text(l.boLibScheduleHint) : null,
                      trailing: DropdownButton<String>(
                        value: schedule,
                        underline: const SizedBox.shrink(),
                        onChanged: (v) => setState(() {
                          if (v == 'off') _cron = null;
                          if (v != null && boScanSchedules.containsKey(v)) _cron = boScanSchedules[v];
                        }),
                        items: [
                          DropdownMenuItem(value: 'off', child: Text(l.boLibScheduleOff)),
                          DropdownMenuItem(value: 'daily', child: Text(l.boLibScheduleDaily)),
                          DropdownMenuItem(value: 'weekly', child: Text(l.boLibScheduleWeekly)),
                          if (schedule == 'custom')
                            DropdownMenuItem(value: 'custom', child: Text(l.boLibScheduleCustom(_cron ?? ''))),
                        ],
                      ),
                    ),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                      title: Text(l.boLibCovers),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                      child: SegmentedButton<String>(
                        segments: [
                          ButtonSegment(value: '2/3', label: Text(l.boLibCoverBook)),
                          ButtonSegment(value: '1/1', label: Text(l.boLibCoverSquare)),
                        ],
                        selected: {_cover},
                        onSelectionChanged: (s) => setState(() => _cover = s.first),
                      ),
                    ),
                  ]),
                  if (!_isNew)
                    _Card(title: l.boLibAccess, hint: l.boLibAccessHint, children: [
                      if (_access.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(4),
                          child: Text(l.boLibAccessNone, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                        ),
                      for (final a in _access)
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                          leading: const Icon(Icons.person_outline_rounded),
                          title: Text(a.name),
                          subtitle: Text('@${a.username}'),
                          trailing: PopupMenuButton<String>(
                            onSelected: (v) => v == 'remove' ? _removeAccess(a) : _setLevel(a, v),
                            itemBuilder: (_) => [
                              for (final level in boAccessLevels)
                                CheckedPopupMenuItem(
                                    value: level, checked: a.level == level, child: Text(_levelLabel(l, level))),
                              const PopupMenuDivider(),
                              PopupMenuItem(
                                value: 'remove',
                                child: Text(l.boLibAccessRemove, style: TextStyle(color: cs.error)),
                              ),
                            ],
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                Text(_levelLabel(l, a.level), style: tt.labelLarge),
                                const Icon(Icons.arrow_drop_down_rounded),
                              ]),
                            ),
                          ),
                        ),
                      TextButton.icon(
                        onPressed: _addAccess,
                        icon: const Icon(Icons.person_add_alt_1_rounded),
                        label: Text(l.boLibAccessAdd),
                      ),
                    ]),
                  if (!_isNew)
                    _Card(children: [
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                        leading: Icon(Icons.delete_outline_rounded, color: cs.error),
                        title: Text(l.boLibDelete, style: TextStyle(color: cs.error)),
                        onTap: _delete,
                      ),
                    ]),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _folderTile(AppLocalizations l, ColorScheme cs, TextTheme tt, String path) {
    final check = _checks[path];
    String? note;
    Color? noteColor;
    if (check != null) {
      if (!check.accessible) {
        note = check.error ?? l.boLibFolderUnreadable;
        noteColor = cs.error;
      } else if (check.overlapLibrary != null && check.overlapLibrary!.isNotEmpty) {
        note = l.boLibFolderInUse(check.overlapLibrary!);
        noteColor = cs.tertiary;
      } else {
        note = l.boLibFolderFiles(check.fileCount);
      }
    }
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: const Icon(Icons.folder_outlined),
      title: Text(path, style: tt.bodyMedium),
      subtitle: note == null ? null : Text(note, style: tt.bodySmall?.copyWith(color: noteColor ?? cs.onSurfaceVariant)),
      trailing: IconButton(
        icon: const Icon(Icons.close_rounded),
        onPressed: () => setState(() => _folders = [..._folders]..remove(path)),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final String? title;
  final String? hint;
  final List<Widget> children;

  const _Card({this.title, this.hint, required this.children});

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
          if (title != null || hint != null) const SizedBox(height: 6),
          ...children,
        ]),
      ),
    );
  }
}

/// Walks the server's library area to pick a folder.
class _BookOrbitFolderPicker extends StatefulWidget {
  const _BookOrbitFolderPicker();

  @override
  State<_BookOrbitFolderPicker> createState() => _BookOrbitFolderPickerState();
}

class _BookOrbitFolderPickerState extends State<_BookOrbitFolderPicker> {
  String? _root;
  String? _path;
  List<BoFolder> _folders = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    final api = boAdminApi(context);
    if (api == null) return;
    try {
      final root = await api.adminFolderRoot();
      if (!mounted) return;
      _root = root;
      await _go(root);
    } catch (e) {
      if (mounted) {
        showBoAdminError(context, e);
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _go(String path) async {
    final api = boAdminApi(context);
    if (api == null) return;
    setState(() => _loading = true);
    try {
      final folders = await api.adminFolders(path);
      if (!mounted) return;
      setState(() {
        _path = path;
        _folders = folders..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      });
    } catch (e) {
      if (mounted) showBoAdminError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool get _atRoot => _path == null || _path == _root;

  String _parent(String path) {
    final trimmed = path.endsWith('/') && path.length > 1 ? path.substring(0, path.length - 1) : path;
    final cut = trimmed.lastIndexOf('/');
    return cut <= 0 ? '/' : trimmed.substring(0, cut);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;
    return PopScope(
      canPop: _atRoot,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _path != null) _go(_parent(_path!));
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: Row(children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => _atRoot ? Navigator.pop(context) : _go(_parent(_path!)),
                ),
                const SizedBox(width: 4),
                Expanded(child: AbsorbPageHeader(title: l.boFolderPickTitle, padding: EdgeInsets.zero)),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Text(_path ?? '', style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
            ),
            if (_loading) const LinearProgressIndicator(minHeight: 2),
            Expanded(
              child: _folders.isEmpty && !_loading
                  ? Center(
                      child: Text(l.boFolderEmpty,
                          style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant.withValues(alpha: 0.6))))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
                      itemCount: _folders.length,
                      itemBuilder: (context, i) => ListTile(
                        leading: const Icon(Icons.folder_rounded),
                        title: Text(_folders[i].name),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => _go(_folders[i].path),
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _path == null ? null : () => Navigator.pop(context, _path),
                  icon: const Icon(Icons.check_rounded),
                  label: Text(l.boFolderUseThis),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
