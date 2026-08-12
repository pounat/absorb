import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../widgets/absorb_page_header.dart';
import '../widgets/filesystem_picker_screen.dart';
import '../widgets/overlay_toast.dart';

enum _LibraryEditorSection { details, settings, scanner, schedule, tools }

class _MetadataSource {
  final String id;
  bool enabled;

  _MetadataSource(this.id, {required this.enabled});
}

/// Create or edit a library. Pass [library] (the GET /api/libraries object) to
/// edit; omit it to create. Returns true via Navigator.pop when a change was
/// saved so the caller can refresh.
class AdminLibraryEditScreen extends StatefulWidget {
  final Map<String, dynamic>? library;

  const AdminLibraryEditScreen({super.key, this.library});

  @override
  State<AdminLibraryEditScreen> createState() => _AdminLibraryEditScreenState();
}

class _AdminLibraryEditScreenState extends State<AdminLibraryEditScreen> {
  static const _icons = [
    'database',
    'audiobookshelf',
    'books-1',
    'books-2',
    'book-1',
    'microphone-1',
    'microphone-3',
    'radio',
    'podcast',
    'rss',
    'headphones',
    'music',
    'file-picture',
    'rocket',
    'power',
    'star',
    'heart',
  ];

  static const _defaultMetadataPrecedence = [
    'folderStructure',
    'audioMetatags',
    'nfoFile',
    'txtFiles',
    'opfFile',
    'absMetadata',
  ];

  static IconData _absIcon(String name) {
    switch (name) {
      case 'audiobookshelf':
        return Icons.library_books_rounded;
      case 'books-1':
        return Icons.menu_book_rounded;
      case 'books-2':
        return Icons.auto_stories_rounded;
      case 'book-1':
        return Icons.book_rounded;
      case 'microphone-1':
        return Icons.mic_rounded;
      case 'microphone-3':
        return Icons.mic_external_on_rounded;
      case 'radio':
        return Icons.radio_rounded;
      case 'podcast':
        return Icons.podcasts_rounded;
      case 'rss':
        return Icons.rss_feed_rounded;
      case 'headphones':
        return Icons.headphones_rounded;
      case 'music':
        return Icons.music_note_rounded;
      case 'file-picture':
        return Icons.image_rounded;
      case 'rocket':
        return Icons.rocket_launch_rounded;
      case 'power':
        return Icons.power_rounded;
      case 'star':
        return Icons.star_rounded;
      case 'heart':
        return Icons.favorite_rounded;
      case 'database':
      default:
        return Icons.storage_rounded;
    }
  }

  bool get _isEdit => widget.library != null;

  final _name = TextEditingController();
  String _mediaType = 'book';
  String _provider = 'google';
  String _icon = 'database';
  List<Map<String, dynamic>> _folders = [];
  List<String> _originalFolderIds = [];
  Map<String, dynamic> _originalSettings = {};

  num _coverAspectRatio = 1.0;
  bool _disableWatcher = false;
  bool _skipAsin = false;
  bool _skipIsbn = false;
  bool _hideSingleSeries = false;
  bool _audiobooksOnly = false;
  bool _epubScripted = false;
  bool _laterBooksOnly = false;
  final _podcastRegion = TextEditingController();
  final _markPercent = TextEditingController();
  final _markTime = TextEditingController();
  String _finishedMode = 'time';

  final _autoScan = TextEditingController();
  final _sectionScrollController = ScrollController();
  bool _scheduleEnabled = false;
  String _scheduleMode = 'weekly';
  int _scheduleMinute = 0;
  TimeOfDay _scheduleTime = const TimeOfDay(hour: 0, minute: 0);
  int _scheduleWeekday = DateTime.monday;

  List<_MetadataSource> _metadataSources = [];
  _LibraryEditorSection _selectedSection = _LibraryEditorSection.details;
  List<String> _providers = const [
    'google',
    'audible',
    'openlibrary',
    'itunes',
    'audnexus',
    'fantlab',
  ];
  bool _saving = false;
  String? _removingMetadataExtension;

  bool get _interactionLocked => _saving || _removingMetadataExtension != null;

  @override
  void initState() {
    super.initState();
    final lib = widget.library;
    if (lib != null) {
      _name.text = (lib['name'] as String?) ?? '';
      _mediaType = (lib['mediaType'] as String?) ?? 'book';
      _provider = (lib['provider'] as String?) ?? 'google';
      _icon = (lib['icon'] as String?) ?? 'database';
      _folders = ((lib['folders'] as List?) ?? [])
          .whereType<Map>()
          .map(
            (folder) => <String, dynamic>{
              'id': folder['id'],
              'fullPath': folder['fullPath'],
            },
          )
          .toList();
      _originalFolderIds = _folders
          .map((folder) => folder['id'].toString())
          .toList();
      _originalSettings = Map<String, dynamic>.from(
        (lib['settings'] as Map?)?.cast<String, dynamic>() ?? const {},
      );

      final settings = _originalSettings;
      _coverAspectRatio = (settings['coverAspectRatio'] as num?) ?? 1;
      _disableWatcher = settings['disableWatcher'] as bool? ?? false;
      _skipAsin = settings['skipMatchingMediaWithAsin'] as bool? ?? false;
      _skipIsbn = settings['skipMatchingMediaWithIsbn'] as bool? ?? false;
      _hideSingleSeries = settings['hideSingleBookSeries'] as bool? ?? false;
      _audiobooksOnly = settings['audiobooksOnly'] as bool? ?? false;
      _epubScripted = settings['epubsAllowScriptedContent'] as bool? ?? false;
      _laterBooksOnly =
          settings['onlyShowLaterBooksInContinueSeries'] as bool? ?? false;
      _podcastRegion.text =
          (settings['podcastSearchRegion'] as String?) ?? 'us';

      final timeRemaining = settings['markAsFinishedTimeRemaining'];
      final percentComplete = settings['markAsFinishedPercentComplete'];
      if (timeRemaining != null) {
        _finishedMode = 'time';
        _markTime.text = '$timeRemaining';
        _markPercent.text = percentComplete == null ? '90' : '$percentComplete';
      } else if (percentComplete != null) {
        _finishedMode = 'percent';
        _markPercent.text = '$percentComplete';
        _markTime.text = '10';
      } else {
        _markTime.text = '10';
        _markPercent.text = '90';
      }

      _initializeSchedule(settings['autoScanCronExpression']);
      _initializeMetadataSources(settings['metadataPrecedence']);
    } else {
      _markTime.text = '10';
      _markPercent.text = '90';
      _podcastRegion.text = 'us';
      _initializeSchedule(null);
      _resetMetadataSources();
    }
    _loadProviders();
  }

  Future<void> _loadProviders() async {
    final api = context.read<AuthProvider>().apiService;
    if (api == null) return;
    final list = await api.getMetadataProviders();
    if (!mounted) return;
    setState(() {
      _providers = list;
      if (!_providers.contains(_provider)) {
        _providers = [_provider, ..._providers];
      }
    });
  }

  void _initializeMetadataSources(dynamic rawPrecedence) {
    if (rawPrecedence is! List) {
      _resetMetadataSources();
      return;
    }
    final stored = rawPrecedence.map((value) => value.toString()).toList();
    if (stored.isEmpty) {
      _metadataSources = _defaultMetadataPrecedence.reversed
          .map((id) => _MetadataSource(id, enabled: false))
          .toList();
      return;
    }

    final seen = <String>{};
    final activeDisplayOrder = stored.reversed
        .where((id) => seen.add(id))
        .map((id) => _MetadataSource(id, enabled: true))
        .toList();
    for (final id in _defaultMetadataPrecedence.reversed) {
      if (seen.add(id)) {
        activeDisplayOrder.add(_MetadataSource(id, enabled: false));
      }
    }
    _metadataSources = activeDisplayOrder;
  }

  void _resetMetadataSources() {
    _metadataSources = _defaultMetadataPrecedence.reversed
        .map((id) => _MetadataSource(id, enabled: true))
        .toList();
  }

  void _initializeSchedule(dynamic rawCron) {
    final cron = rawCron?.toString().trim() ?? '';
    _autoScan.text = cron;
    _scheduleEnabled = cron.isNotEmpty;
    if (!_scheduleEnabled) return;

    final parts = cron.split(RegExp(r'\s+'));
    if (parts.length != 5) {
      _scheduleMode = 'advanced';
      return;
    }

    final minute = int.tryParse(parts[0]);
    final hour = int.tryParse(parts[1]);
    final dayOfWeek = int.tryParse(parts[4]);
    final validMinute = minute != null && minute >= 0 && minute <= 59;
    final validHour = hour != null && hour >= 0 && hour <= 23;

    if (validMinute &&
        parts[1] == '*' &&
        parts[2] == '*' &&
        parts[3] == '*' &&
        parts[4] == '*') {
      _scheduleMode = 'hourly';
      _scheduleMinute = minute;
    } else if (validMinute &&
        validHour &&
        parts[2] == '*' &&
        parts[3] == '*' &&
        parts[4] == '*') {
      _scheduleMode = 'daily';
      _scheduleTime = TimeOfDay(hour: hour, minute: minute);
    } else if (validMinute &&
        validHour &&
        parts[2] == '*' &&
        parts[3] == '*' &&
        dayOfWeek != null &&
        dayOfWeek >= 0 &&
        dayOfWeek <= 6) {
      _scheduleMode = 'weekly';
      _scheduleTime = TimeOfDay(hour: hour, minute: minute);
      _scheduleWeekday = dayOfWeek == 0 ? DateTime.sunday : dayOfWeek;
    } else {
      _scheduleMode = 'advanced';
    }
  }

  void _setScheduleEnabled(bool enabled) {
    setState(() {
      _scheduleEnabled = enabled;
      if (enabled && _autoScan.text.trim().isEmpty) {
        _scheduleMode = 'weekly';
        _scheduleTime = const TimeOfDay(hour: 0, minute: 0);
        _scheduleWeekday = DateTime.monday;
        _rebuildCron();
      }
    });
  }

  void _setScheduleMode(String mode) {
    setState(() {
      _scheduleMode = mode;
      if (mode != 'advanced') _rebuildCron();
    });
  }

  void _rebuildCron() {
    switch (_scheduleMode) {
      case 'hourly':
        _autoScan.text = '$_scheduleMinute * * * *';
      case 'daily':
        _autoScan.text = '${_scheduleTime.minute} ${_scheduleTime.hour} * * *';
      case 'weekly':
        final cronDay = _scheduleWeekday == DateTime.sunday
            ? 0
            : _scheduleWeekday;
        _autoScan.text =
            '${_scheduleTime.minute} ${_scheduleTime.hour} * * $cronDay';
      case 'advanced':
        break;
    }
  }

  Future<void> _pickScheduleTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _scheduleTime,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _scheduleTime = picked;
      _rebuildCron();
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _podcastRegion.dispose();
    _markPercent.dispose();
    _markTime.dispose();
    _autoScan.dispose();
    _sectionScrollController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _settings() {
    final base = Map<String, dynamic>.from(_originalSettings);
    final percentText = _markPercent.text.trim();
    final timeText = _markTime.text.trim();
    base.addAll({
      'coverAspectRatio': _coverAspectRatio,
      'disableWatcher': _disableWatcher,
      'markAsFinishedPercentComplete': _finishedMode == 'percent'
          ? num.tryParse(percentText)
          : null,
      'markAsFinishedTimeRemaining': _finishedMode == 'time'
          ? (num.tryParse(timeText) ?? 10)
          : null,
      'autoScanCronExpression': _scheduleEnabled ? _autoScan.text.trim() : null,
    });

    if (_mediaType == 'podcast') {
      base['podcastSearchRegion'] = _podcastRegion.text.trim().isEmpty
          ? 'us'
          : _podcastRegion.text.trim();
    } else {
      base.addAll({
        'skipMatchingMediaWithAsin': _skipAsin,
        'skipMatchingMediaWithIsbn': _skipIsbn,
        'hideSingleBookSeries': _hideSingleSeries,
        'audiobooksOnly': _audiobooksOnly,
        'epubsAllowScriptedContent': _epubScripted,
        'onlyShowLaterBooksInContinueSeries': _laterBooksOnly,
        'metadataPrecedence': _metadataSources
            .where((source) => source.enabled)
            .map((source) => source.id)
            .toList()
            .reversed
            .toList(),
      });
    }
    return base;
  }

  Future<void> _addFolder() async {
    final path = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const FilesystemPickerScreen()),
    );
    if (path == null || !mounted) return;
    if (_folders.any((folder) => folder['fullPath'] == path)) return;
    setState(
      () => _folders = [
        ..._folders,
        {'fullPath': path},
      ],
    );
  }

  bool _hasValidCron() {
    if (!_scheduleEnabled) return true;
    final cron = _autoScan.text.trim();
    return cron.isNotEmpty && cron.split(RegExp(r'\s+')).length == 5;
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context)!;
    if (_name.text.trim().isEmpty) {
      showOverlayToast(
        context,
        l.libNameRequired,
        icon: Icons.error_outline_rounded,
      );
      _selectSection(_LibraryEditorSection.details);
      return;
    }
    if (_folders.isEmpty) {
      showOverlayToast(
        context,
        l.libNoFolders,
        icon: Icons.error_outline_rounded,
      );
      _selectSection(_LibraryEditorSection.details);
      return;
    }
    if (!_hasValidCron()) {
      showOverlayToast(
        context,
        'Enter a five-part cron expression before saving.',
        icon: Icons.error_outline_rounded,
      );
      _selectSection(_LibraryEditorSection.schedule);
      return;
    }

    final api = context.read<AuthProvider>().apiService;
    if (api == null) return;
    final cron = _autoScan.text.trim();
    final originalCron =
        _originalSettings['autoScanCronExpression']?.toString().trim() ?? '';
    if (_scheduleEnabled &&
        _scheduleMode == 'advanced' &&
        cron != originalCron) {
      setState(() => _saving = true);
      final cronError = await api.validateCronExpression(cron);
      if (!mounted) return;
      setState(() => _saving = false);
      if (cronError != null) {
        showOverlayToast(context, cronError, icon: Icons.error_outline_rounded);
        _selectSection(_LibraryEditorSection.schedule);
        return;
      }
    }

    if (_isEdit) {
      final keptIds = _folders
          .where((folder) => folder['id'] != null)
          .map((folder) => folder['id'].toString())
          .toSet();
      final removed = _originalFolderIds
          .where((id) => !keptIds.contains(id))
          .toList();
      if (removed.isNotEmpty) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(l.libRemoveFoldersTitle),
            content: Text(l.libRemoveFoldersBody),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(l.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(l.remove),
              ),
            ],
          ),
        );
        if (confirmed != true) return;
      }
    }

    setState(() => _saving = true);

    final body = <String, dynamic>{
      'name': _name.text.trim(),
      'mediaType': _mediaType,
      'icon': _icon,
      'provider': _provider,
      'folders': _folders,
      'settings': _settings(),
    };

    bool succeeded;
    if (_isEdit) {
      succeeded = await api.updateLibrary(
        widget.library!['id'].toString(),
        body,
      );
    } else {
      body['folders'] = _folders
          .map((folder) => {'fullPath': folder['fullPath']})
          .toList();
      succeeded = (await api.createLibrary(body)) != null;
    }
    if (!mounted) return;
    setState(() => _saving = false);
    final message = _isEdit
        ? (succeeded ? l.libUpdated : l.libUpdateFailed)
        : (succeeded ? l.libCreated : l.libCreateFailed);
    showOverlayToast(
      context,
      message,
      icon: succeeded
          ? Icons.check_circle_outline_rounded
          : Icons.error_outline_rounded,
    );
    if (succeeded) Navigator.pop(context, true);
  }

  Future<void> _removeMetadataFiles(String extension) async {
    final l = AppLocalizations.of(context)!;
    final filename = 'metadata.$extension';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Remove all $filename files?'),
        content: Text(
          'This permanently removes $filename from every item folder in this library. The media files are not changed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l.remove),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final api = context.read<AuthProvider>().apiService;
    if (api == null) return;
    setState(() => _removingMetadataExtension = extension);
    final result = await api.removeLibraryMetadataFiles(
      widget.library!['id'].toString(),
      extension,
    );
    if (!mounted) return;
    setState(() => _removingMetadataExtension = null);

    if (result == null) {
      showOverlayToast(
        context,
        'Could not remove $filename files.',
        icon: Icons.error_outline_rounded,
      );
    } else if (result.found == 0) {
      showOverlayToast(
        context,
        'No $filename files were found.',
        icon: Icons.info_outline_rounded,
      );
    } else if (result.removed == 0) {
      showOverlayToast(
        context,
        '${result.found} $filename files were found, but none could be removed.',
        icon: Icons.error_outline_rounded,
      );
    } else {
      showOverlayToast(
        context,
        'Removed ${result.removed} of ${result.found} $filename files.',
        icon: Icons.check_circle_outline_rounded,
      );
    }
  }

  List<_LibraryEditorSection> get _availableSections => [
    _LibraryEditorSection.details,
    _LibraryEditorSection.settings,
    if (_mediaType == 'book') _LibraryEditorSection.scanner,
    _LibraryEditorSection.schedule,
    if (_isEdit) _LibraryEditorSection.tools,
  ];

  String _sectionLabel(_LibraryEditorSection section, AppLocalizations l) {
    return switch (section) {
      _LibraryEditorSection.details => l.details,
      _LibraryEditorSection.settings => l.settingsTitle,
      _LibraryEditorSection.scanner => l.srvScannerSection,
      _LibraryEditorSection.schedule => 'Schedule',
      _LibraryEditorSection.tools => 'Tools',
    };
  }

  IconData _sectionIcon(_LibraryEditorSection section) {
    return switch (section) {
      _LibraryEditorSection.details => Icons.info_outline_rounded,
      _LibraryEditorSection.settings => Icons.tune_rounded,
      _LibraryEditorSection.scanner => Icons.document_scanner_outlined,
      _LibraryEditorSection.schedule => Icons.schedule_rounded,
      _LibraryEditorSection.tools => Icons.build_outlined,
    };
  }

  void _selectSection(_LibraryEditorSection section) {
    if (_interactionLocked) return;
    setState(() => _selectedSection = section);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_sectionScrollController.hasClients) return;
      _sectionScrollController.jumpTo(0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: AbsorbPageHeader(
                      title: _isEdit ? l.libEditTitle : l.libNewTitle,
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: colors.onSurfaceVariant,
                    ),
                    onPressed: _interactionLocked
                        ? null
                        : () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final desktop = constraints.maxWidth >= 760;
                  if (desktop) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(width: 220, child: _desktopNavigation(l)),
                        VerticalDivider(
                          width: 1,
                          color: colors.outlineVariant.withValues(alpha: 0.5),
                        ),
                        Expanded(child: _sectionScrollView()),
                      ],
                    );
                  }
                  return Column(
                    children: [
                      _mobileNavigation(l),
                      const SizedBox(height: 8),
                      Expanded(child: _sectionScrollView()),
                    ],
                  );
                },
              ),
            ),
            if (_selectedSection != _LibraryEditorSection.tools)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 320),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _interactionLocked ? null : _save,
                        icon: _saving
                            ? SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: colors.onPrimary,
                                ),
                              )
                            : const Icon(Icons.save_rounded, size: 18),
                        label: Text(_isEdit ? l.libUpdate : l.libCreate),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _desktopNavigation(AppLocalizations l) {
    final colors = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
      children: [
        for (final section in _availableSections)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              selected: _selectedSection == section,
              selectedTileColor: colors.secondaryContainer,
              leading: Icon(_sectionIcon(section), size: 20),
              title: Text(_sectionLabel(section, l)),
              onTap: _interactionLocked ? null : () => _selectSection(section),
            ),
          ),
      ],
    );
  }

  Widget _mobileNavigation(AppLocalizations l) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          for (final section in _availableSections)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                avatar: Icon(_sectionIcon(section), size: 17),
                label: Text(_sectionLabel(section, l)),
                selected: _selectedSection == section,
                onSelected: _interactionLocked
                    ? null
                    : (_) => _selectSection(section),
              ),
            ),
        ],
      ),
    );
  }

  Widget _sectionScrollView() {
    return ListView(
      controller: _sectionScrollController,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      children: [
        Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: SizedBox(width: double.infinity, child: _sectionContent()),
          ),
        ),
      ],
    );
  }

  Widget _sectionContent() {
    return switch (_selectedSection) {
      _LibraryEditorSection.details => _detailsSection(),
      _LibraryEditorSection.settings => _settingsSection(),
      _LibraryEditorSection.scanner =>
        _mediaType == 'book' ? _scannerSection() : _settingsSection(),
      _LibraryEditorSection.schedule => _scheduleSection(),
      _LibraryEditorSection.tools =>
        _isEdit ? _toolsSection() : _detailsSection(),
    };
  }

  Widget _sectionHeading(String title, String description) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(
            description,
            style: textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailsSection() {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;
    final isPodcast = _mediaType == 'podcast';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeading(
          l.details,
          'Set the library name, media type, provider, icon, and folders.',
        ),
        TextField(
          controller: _name,
          decoration: InputDecoration(labelText: l.libName),
        ),
        const SizedBox(height: 16),
        Text(
          l.libMediaType,
          style: textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: 6),
        if (_isEdit)
          Chip(label: Text(isPodcast ? l.libMediaPodcast : l.libMediaBook))
        else
          SegmentedButton<String>(
            segments: [
              ButtonSegment(
                value: 'book',
                label: Text(l.libMediaBook),
                icon: const Icon(Icons.menu_book_rounded),
              ),
              ButtonSegment(
                value: 'podcast',
                label: Text(l.libMediaPodcast),
                icon: const Icon(Icons.podcasts_rounded),
              ),
            ],
            selected: {_mediaType},
            onSelectionChanged: (selection) {
              setState(() {
                _mediaType = selection.first;
                if (_mediaType == 'podcast' &&
                    _selectedSection == _LibraryEditorSection.scanner) {
                  _selectedSection = _LibraryEditorSection.settings;
                }
              });
            },
          ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final stack = constraints.maxWidth < 520;
            final provider = _labeledDropdown(
              colors,
              textTheme,
              l.libProvider,
              _provider,
              _providers,
              (value) => setState(() => _provider = value),
            );
            final icon = _iconDropdown(
              colors,
              textTheme,
              _icon,
              _icons.contains(_icon) ? _icons : [_icon, ..._icons],
              (value) => setState(() => _icon = value),
            );
            if (stack) {
              return Column(
                children: [provider, const SizedBox(height: 12), icon],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: provider),
                const SizedBox(width: 16),
                Expanded(child: icon),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        Text(
          l.libFolders,
          style: textTheme.labelLarge?.copyWith(
            color: colors.onSurfaceVariant.withValues(alpha: 0.7),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: colors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              if (_folders.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    l.libNoFolders,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ..._folders.asMap().entries.map(
                (entry) => ListTile(
                  dense: true,
                  leading: Icon(
                    Icons.folder_rounded,
                    color: colors.primary.withValues(alpha: 0.8),
                  ),
                  title: Text(
                    entry.value['fullPath']?.toString() ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: colors.onSurfaceVariant,
                    ),
                    onPressed: () => setState(() {
                      _folders = [..._folders]..removeAt(entry.key);
                    }),
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: _addFolder,
                icon: const Icon(Icons.add_rounded),
                label: Text(l.libAddFolder),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _settingsSection() {
    final textTheme = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;
    final isPodcast = _mediaType == 'podcast';
    final watcherDisabledGlobally =
        context
            .watch<AuthProvider>()
            .serverSettings?['scannerDisableWatcher'] ==
        true;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeading(
          l.settingsTitle,
          'Control cover display, matching, completion, and library behavior.',
        ),
        _coverShape(textTheme, l),
        _switch(
          textTheme,
          l.libDisableWatcher,
          watcherDisabledGlobally ? true : _disableWatcher,
          watcherDisabledGlobally
              ? null
              : (value) => setState(() => _disableWatcher = value),
          subtitle: watcherDisabledGlobally
              ? 'The folder watcher is disabled in the server scanner settings.'
              : null,
        ),
        if (!isPodcast) ...[
          _switch(
            textTheme,
            l.libSkipAsin,
            _skipAsin,
            (value) => setState(() => _skipAsin = value),
          ),
          _switch(
            textTheme,
            l.libSkipIsbn,
            _skipIsbn,
            (value) => setState(() => _skipIsbn = value),
          ),
          _switch(
            textTheme,
            l.libHideSingleSeries,
            _hideSingleSeries,
            (value) => setState(() => _hideSingleSeries = value),
          ),
          _switch(
            textTheme,
            l.libAudiobooksOnly,
            _audiobooksOnly,
            (value) => setState(() => _audiobooksOnly = value),
          ),
          _switch(
            textTheme,
            l.libEpubScripted,
            _epubScripted,
            (value) => setState(() => _epubScripted = value),
          ),
          _switch(
            textTheme,
            l.libLaterBooksOnly,
            _laterBooksOnly,
            (value) => setState(() => _laterBooksOnly = value),
          ),
        ],
        if (isPodcast) ...[
          const SizedBox(height: 12),
          TextField(
            controller: _podcastRegion,
            decoration: InputDecoration(
              labelText: l.libPodcastRegion,
              hintText: 'us',
            ),
          ),
        ],
        const SizedBox(height: 20),
        Text('Mark finished', style: textTheme.titleMedium),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _finishedMode,
          decoration: const InputDecoration(labelText: 'Completion rule'),
          items: [
            DropdownMenuItem(value: 'time', child: Text(l.libMarkTime)),
            DropdownMenuItem(value: 'percent', child: Text(l.libMarkPercent)),
          ],
          onChanged: (value) {
            if (value != null) setState(() => _finishedMode = value);
          },
        ),
        const SizedBox(height: 12),
        if (_finishedMode == 'time')
          TextField(
            controller: _markTime,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: l.libMarkTime),
          )
        else
          TextField(
            controller: _markPercent,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: l.libMarkPercent),
          ),
      ],
    );
  }

  Widget _scannerSection() {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;
    final activeSources = _metadataSources
        .where((source) => source.enabled)
        .toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeading(
          l.srvScannerSection,
          'Choose which metadata sources are used. Drag them from highest to lowest priority.',
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () => setState(_resetMetadataSources),
            icon: const Icon(Icons.restart_alt_rounded),
            label: Text(l.resetToDefault),
          ),
        ),
        const SizedBox(height: 8),
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          itemCount: _metadataSources.length,
          onReorder: (oldIndex, newIndex) {
            setState(() {
              if (newIndex > oldIndex) newIndex--;
              final source = _metadataSources.removeAt(oldIndex);
              _metadataSources.insert(newIndex, source);
            });
          },
          itemBuilder: (context, index) {
            final source = _metadataSources[index];
            final activeIndex = activeSources.indexOf(source);
            final priority = !source.enabled
                ? 'Ignored'
                : activeIndex == 0
                ? 'Highest priority'
                : activeIndex == activeSources.length - 1
                ? 'Lowest priority'
                : 'Priority ${activeIndex + 1}';
            return Container(
              key: ValueKey(source.id),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(14),
              ),
              child: ListTile(
                leading: Switch(
                  value: source.enabled,
                  onChanged: (enabled) {
                    setState(() => source.enabled = enabled);
                  },
                ),
                title: Text(_metadataSourceLabel(source.id)),
                subtitle: Text(priority),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Move up',
                      onPressed: index == 0
                          ? null
                          : () => _moveMetadataSource(index, -1),
                      icon: const Icon(Icons.keyboard_arrow_up_rounded),
                    ),
                    IconButton(
                      tooltip: 'Move down',
                      onPressed: index == _metadataSources.length - 1
                          ? null
                          : () => _moveMetadataSource(index, 1),
                      icon: const Icon(Icons.keyboard_arrow_down_rounded),
                    ),
                    ReorderableDragStartListener(
                      index: index,
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(Icons.drag_handle_rounded),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        Text(
          'Disabled sources are ignored when the scanner reads metadata.',
          style: textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
        ),
      ],
    );
  }

  void _moveMetadataSource(int index, int offset) {
    final target = index + offset;
    if (target < 0 || target >= _metadataSources.length) return;
    setState(() {
      final source = _metadataSources.removeAt(index);
      _metadataSources.insert(target, source);
    });
  }

  String _metadataSourceLabel(String id) {
    return switch (id) {
      'folderStructure' => 'Folder structure',
      'audioMetatags' =>
        _mediaType == 'book'
            ? 'Audio file metadata or ebook metadata'
            : 'Audio file metadata',
      'nfoFile' => 'NFO file',
      'txtFiles' => 'desc.txt and reader.txt files',
      'opfFile' => 'OPF file',
      'absMetadata' => 'Audiobookshelf metadata file',
      _ => id,
    };
  }

  Widget _scheduleSection() {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;
    final serverTimeZone =
        context.watch<AuthProvider>().serverSettings?['timeZone'] as String?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeading(
          'Schedule',
          'Run a library scan automatically on a recurring schedule.',
        ),
        _switch(
          textTheme,
          l.libAutoScan,
          _scheduleEnabled,
          _setScheduleEnabled,
        ),
        if (_scheduleEnabled) ...[
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _scheduleMode,
            decoration: InputDecoration(labelText: l.adminPodcastsFrequency),
            items: [
              DropdownMenuItem(
                value: 'hourly',
                child: Text(l.adminPodcastsFreqHourly),
              ),
              DropdownMenuItem(
                value: 'daily',
                child: Text(l.adminPodcastsFreqDaily),
              ),
              DropdownMenuItem(
                value: 'weekly',
                child: Text(l.adminPodcastsFreqWeekly),
              ),
              const DropdownMenuItem(
                value: 'advanced',
                child: Text('Advanced cron'),
              ),
            ],
            onChanged: (value) {
              if (value != null) _setScheduleMode(value);
            },
          ),
          const SizedBox(height: 16),
          if (_scheduleMode == 'hourly') ...[
            Text('Minute ${_scheduleMinute.toString().padLeft(2, '0')}'),
            Slider(
              min: 0,
              max: 59,
              divisions: 59,
              label: _scheduleMinute.toString(),
              value: _scheduleMinute.toDouble(),
              onChanged: (value) {
                setState(() {
                  _scheduleMinute = value.round();
                  _rebuildCron();
                });
              },
            ),
          ],
          if (_scheduleMode == 'daily' || _scheduleMode == 'weekly') ...[
            if (_scheduleMode == 'weekly') ...[
              DropdownButtonFormField<int>(
                value: _scheduleWeekday,
                decoration: InputDecoration(labelText: l.adminPodcastsDay),
                items: _weekdayLabels(l).entries
                    .map(
                      (entry) => DropdownMenuItem(
                        value: entry.key,
                        child: Text(entry.value),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _scheduleWeekday = value;
                    _rebuildCron();
                  });
                },
              ),
              const SizedBox(height: 12),
            ],
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Time'),
              subtitle: Text(_scheduleTime.format(context)),
              trailing: const Icon(Icons.schedule_rounded),
              onTap: _pickScheduleTime,
            ),
          ],
          if (_scheduleMode == 'advanced')
            TextField(
              controller: _autoScan,
              decoration: InputDecoration(
                labelText: l.libAutoScan,
                hintText: '0 0 * * *',
                helperText: 'Minute  Hour  Day  Month  Weekday',
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SelectableText(
                _autoScan.text,
                style: textTheme.bodyLarge?.copyWith(fontFamily: 'monospace'),
              ),
            ),
          const SizedBox(height: 12),
          Text(
            serverTimeZone == null || serverTimeZone.isEmpty
                ? l.podcastScheduleServerTimeUnknown
                : l.podcastScheduleServerTime(serverTimeZone),
            style: textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  Map<int, String> _weekdayLabels(AppLocalizations l) => {
    DateTime.sunday: l.adminPodcastsDaySun,
    DateTime.monday: l.adminPodcastsDayMon,
    DateTime.tuesday: l.adminPodcastsDayTue,
    DateTime.wednesday: l.adminPodcastsDayWed,
    DateTime.thursday: l.adminPodcastsDayThu,
    DateTime.friday: l.adminPodcastsDayFri,
    DateTime.saturday: l.adminPodcastsDaySat,
  };

  Widget _toolsSection() {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeading(
          'Tools',
          'Clean up generated sidecar metadata files across this library.',
        ),
        _metadataRemovalCard(
          colors,
          extension: 'json',
          description:
              'Remove every metadata.json file found in the library item folders.',
        ),
        const SizedBox(height: 12),
        _metadataRemovalCard(
          colors,
          extension: 'abs',
          description:
              'Remove every metadata.abs file found in the library item folders.',
        ),
      ],
    );
  }

  Widget _metadataRemovalCard(
    ColorScheme colors, {
    required String extension,
    required String description,
  }) {
    final busy = _removingMetadataExtension == extension;
    final anyBusy = _removingMetadataExtension != null;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final button = OutlinedButton.icon(
            onPressed: anyBusy ? null : () => _removeMetadataFiles(extension),
            icon: busy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.delete_outline_rounded),
            label: Text('Remove metadata.$extension'),
          );
          final copy = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'metadata.$extension',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(description),
            ],
          );
          if (constraints.maxWidth < 600) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [copy, const SizedBox(height: 14), button],
            );
          }
          return Row(
            children: [
              Expanded(child: copy),
              const SizedBox(width: 20),
              button,
            ],
          );
        },
      ),
    );
  }

  Widget _coverShape(TextTheme textTheme, AppLocalizations l) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final selector = SegmentedButton<num>(
          segments: [
            ButtonSegment(value: 1, label: Text(l.libCoverSquare)),
            ButtonSegment(value: 0, label: Text(l.libCoverStandard)),
          ],
          selected: {_coverAspectRatio == 0 ? 0 : 1},
          onSelectionChanged: (selection) {
            setState(() => _coverAspectRatio = selection.first);
          },
        );
        if (constraints.maxWidth < 500) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.libCoverShape, style: textTheme.bodyMedium),
              const SizedBox(height: 8),
              selector,
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: Text(l.libCoverShape, style: textTheme.bodyMedium)),
            selector,
          ],
        );
      },
    ),
  );

  Widget _switch(
    TextTheme textTheme,
    String label,
    bool value,
    ValueChanged<bool>? onChanged, {
    String? subtitle,
  }) => SwitchListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(label, style: textTheme.bodyMedium),
    subtitle: subtitle == null ? null : Text(subtitle),
    value: value,
    onChanged: onChanged,
  );

  Widget _iconDropdown(
    ColorScheme colors,
    TextTheme textTheme,
    String value,
    List<String> options,
    ValueChanged<String> onChanged,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        AppLocalizations.of(context)!.libIcon,
        style: textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
      ),
      DropdownButton<String>(
        value: options.contains(value) ? value : options.first,
        isExpanded: true,
        borderRadius: BorderRadius.circular(12),
        items: options
            .map(
              (option) => DropdownMenuItem(
                value: option,
                child: Row(
                  children: [
                    Icon(
                      _absIcon(option),
                      size: 18,
                      color: colors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(option, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
        onChanged: (newValue) {
          if (newValue != null) onChanged(newValue);
        },
      ),
    ],
  );

  Widget _labeledDropdown(
    ColorScheme colors,
    TextTheme textTheme,
    String label,
    String value,
    List<String> options,
    ValueChanged<String> onChanged,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
      ),
      DropdownButton<String>(
        value: options.contains(value) ? value : options.first,
        isExpanded: true,
        borderRadius: BorderRadius.circular(12),
        items: options
            .map(
              (option) => DropdownMenuItem(
                value: option,
                child: Text(option, overflow: TextOverflow.ellipsis),
              ),
            )
            .toList(),
        onChanged: (newValue) {
          if (newValue != null) onChanged(newValue);
        },
      ),
    ],
  );
}
