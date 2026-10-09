import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/api_service.dart';
import '../services/book_search_index.dart';
import '../widgets/absorb_page_header.dart';
import '../widgets/overlay_toast.dart';
import '../widgets/stackable_sheet.dart';

typedef UploadFilePicker = Future<List<MediaUploadFile>?> Function();
typedef UploadPathChecker =
    Future<UploadPathCheckResult> Function(String directory, String folderPath);
typedef MediaUploader =
    Future<MediaUploadResult> Function(
      MediaUploadRequest request, {
      void Function(int sentBytes, int totalBytes)? onProgress,
    });
typedef BookMetadataSearcher =
    Future<List<Map<String, dynamic>>> Function({
      required String title,
      String? author,
      required String provider,
    });

class AdminUploadScreen extends StatefulWidget {
  static const titleFieldKey = Key('adminUploadTitleField');
  static const authorFieldKey = Key('adminUploadAuthorField');
  static const seriesFieldKey = Key('adminUploadSeriesField');
  static const libraryFieldKey = Key('adminUploadLibraryField');
  static const folderFieldKey = Key('adminUploadFolderField');
  static const mediaTypeKey = Key('adminUploadMediaType');
  static const autoMetadataKey = Key('adminUploadAutoMetadata');
  static const metadataProviderKey = Key('adminUploadMetadataProvider');
  static const chooseFilesKey = Key('adminUploadChooseFiles');
  static const submitKey = Key('adminUploadSubmit');

  final List<dynamic> libraries;
  final String? initialLibraryId;
  final ApiService? apiService;
  final UploadFilePicker? filePicker;
  final UploadPathChecker? pathChecker;
  final MediaUploader? uploader;
  final BookMetadataSearcher? metadataSearcher;
  final VoidCallback? onNavigationGuardChanged;

  const AdminUploadScreen({
    super.key,
    required this.libraries,
    this.initialLibraryId,
    this.apiService,
    this.filePicker,
    this.pathChecker,
    this.uploader,
    this.metadataSearcher,
    this.onNavigationGuardChanged,
  });

  @override
  State<AdminUploadScreen> createState() => _AdminUploadScreenState();
}

class _AdminUploadScreenState extends State<AdminUploadScreen> {
  static const _audioExtensions = <String>{
    'm4b',
    'mp3',
    'm4a',
    'flac',
    'opus',
    'ogg',
    'oga',
    'mp4',
    'aac',
    'wma',
    'aiff',
    'aif',
    'wav',
    'webm',
    'webma',
    'mka',
    'awb',
    'caf',
    'mpeg',
    'mpg',
  };
  static const _ebookExtensions = <String>{
    'epub',
    'pdf',
    'mobi',
    'azw3',
    'cbr',
    'cbz',
  };
  static const _otherExtensions = <String>{
    'png',
    'jpg',
    'jpeg',
    'webp',
    'nfo',
    'txt',
    'opf',
    'abs',
    'xml',
    'json',
  };
  static const _supportedExtensions = <String>{
    ..._audioExtensions,
    ..._ebookExtensions,
    ..._otherExtensions,
  };

  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _author = TextEditingController();
  final _series = TextEditingController();

  late final List<Map<String, dynamic>> _libraries;
  String? _selectedLibraryId;
  String? _selectedFolderId;
  List<MediaUploadFile> _files = [];
  bool _uploading = false;
  bool _autoFetchMetadata = false;
  bool _metadataSearching = false;
  List<String> _metadataProviders = [];
  String _metadataProvider = 'audible';
  String? _lastMetadataQuery;
  int _metadataRequestId = 0;
  double? _progress;
  DateTime _lastProgressUpdate = DateTime.fromMillisecondsSinceEpoch(0);
  // A book already on the server whose folder the files should join. The
  // server only takes author, series and title, so they are filled from the
  // book's real folder path and the fields lock until it is cleared.
  _ExistingBook? _existingTarget;

  Future<void> _pickExistingBook() async {
    final api = widget.apiService;
    final libraryId = _selectedLibraryId;
    if (api == null || libraryId == null) return;
    final l = AppLocalizations.of(context)!;
    final picked = await showStackableSheet<Map<String, dynamic>>(
      context: context,
      showHandle: true,
      useSafeArea: true,
      initialChildSize: 0.92,
      maxChildSize: 0.95,
      builder: (_, __) => _ExistingBookPicker(api: api, libraryId: libraryId),
    );
    if (picked == null || !mounted) return;
    final id = picked['id'] as String? ?? '';
    final full = await api.getLibraryItem(id) ?? picked;
    if (!mounted) return;
    final relPath = (full['relPath'] as String? ?? picked['relPath'] as String? ?? '')
        .replaceAll('\\', '/')
        .replaceAll(RegExp(r'^/+|/+$'), '');
    if (relPath.isEmpty) {
      _showError(l.adminUploadTargetNoFolder);
      return;
    }
    final metadata =
        (full['media'] as Map<String, dynamic>?)?['metadata'] as Map<String, dynamic>? ?? {};
    final title = metadata['title'] as String? ?? l.unknown;
    final folderId = full['folderId'] as String? ?? picked['folderId'] as String?;
    final parts = relPath.split('/');
    // The server joins author, series and title; a shallower folder means
    // the missing levels were empty, counted from the top.
    String author = '', series = '', bookFolder = parts.last;
    if (!_isPodcast) {
      if (parts.length >= 3) {
        author = parts[parts.length - 3];
        series = parts[parts.length - 2];
      } else if (parts.length == 2) {
        author = parts[0];
      }
    }
    setState(() {
      _existingTarget = _ExistingBook(id: id, title: title, relPath: relPath);
      _title.text = bookFolder;
      _author.text = author;
      _series.text = series;
      if (folderId != null && _folders.any((f) => f['id']?.toString() == folderId)) {
        _selectedFolderId = folderId;
      }
      _autoFetchMetadata = false;
      _lastMetadataQuery = null;
      if (_metadataSearching) {
        _metadataRequestId++;
        _metadataSearching = false;
      }
    });
  }

  void _clearExistingTarget() {
    setState(() => _existingTarget = null);
  }

  @override
  void initState() {
    super.initState();
    _libraries = widget.libraries
        .whereType<Map>()
        .map((library) => Map<String, dynamic>.from(library))
        .toList();

    Map<String, dynamic>? initialLibrary;
    if (widget.initialLibraryId != null) {
      for (final library in _libraries) {
        if (library['id']?.toString() == widget.initialLibraryId) {
          initialLibrary = library;
          break;
        }
      }
    }
    initialLibrary ??= _libraries.firstOrNull;
    _selectedLibraryId = initialLibrary?['id']?.toString();
    _selectedFolderId = _foldersFor(
      initialLibrary,
    ).firstOrNull?['id']?.toString();
    _metadataProvider = _providerFor(initialLibrary);
    _metadataProviders = [_metadataProvider];
    _loadMetadataProviders();
  }

  @override
  void dispose() {
    _title.dispose();
    _author.dispose();
    _series.dispose();
    super.dispose();
  }

  Map<String, dynamic>? get _selectedLibrary {
    for (final library in _libraries) {
      if (library['id']?.toString() == _selectedLibraryId) return library;
    }
    return null;
  }

  List<Map<String, dynamic>> get _folders => _foldersFor(_selectedLibrary);

  Map<String, dynamic>? get _selectedFolder {
    for (final folder in _folders) {
      if (folder['id']?.toString() == _selectedFolderId) return folder;
    }
    return null;
  }

  String get _mediaType => _selectedLibrary?['mediaType']?.toString() ?? 'book';
  bool get _isPodcast => _mediaType == 'podcast';
  String get _folderPath =>
      _selectedFolder?['fullPath']?.toString() ??
      _selectedFolder?['path']?.toString() ??
      '';

  String _providerFor(Map<String, dynamic>? library) {
    final provider = library?['provider']?.toString().trim() ?? '';
    return provider.isEmpty ? 'audible' : provider;
  }

  Future<void> _loadMetadataProviders() async {
    final api = widget.apiService;
    if (api == null) return;
    final providers = await api.getMetadataProviders();
    if (!mounted) return;
    setState(() {
      _metadataProviders = {
        _metadataProvider,
        ...providers.where((provider) => provider.isNotEmpty),
      }.toList();
    });
  }

  List<Map<String, dynamic>> _foldersFor(Map<String, dynamic>? library) {
    final folders = library?['folders'] as List? ?? const [];
    return folders
        .whereType<Map>()
        .map((folder) => Map<String, dynamic>.from(folder))
        .toList();
  }

  void _selectLibrary(String? id) {
    if (id == null) return;
    Map<String, dynamic>? library;
    for (final candidate in _libraries) {
      if (candidate['id']?.toString() == id) {
        library = candidate;
        break;
      }
    }
    setState(() {
      _selectedLibraryId = id;
      _selectedFolderId = _folders.firstOrNull?['id']?.toString();
      _metadataProvider = _providerFor(library);
      if (!_metadataProviders.contains(_metadataProvider)) {
        _metadataProviders = [_metadataProvider, ..._metadataProviders];
      }
      _lastMetadataQuery = null;
      _metadataSearching = false;
      _metadataRequestId++;
    });
  }

  String _extension(String filename) {
    final dot = filename.lastIndexOf('.');
    if (dot < 0 || dot == filename.length - 1) return '';
    return filename.substring(dot + 1).toLowerCase();
  }

  bool _isSupported(MediaUploadFile file) =>
      _supportedExtensions.contains(_extension(file.name));

  bool _isPrimaryFile(MediaUploadFile file) {
    final extension = _extension(file.name);
    return _audioExtensions.contains(extension) ||
        (!_isPodcast && _ebookExtensions.contains(extension));
  }

  String _metadataValue(dynamic value) {
    if (value is String) return value.trim();
    if (value is num) return value.toString();
    return '';
  }

  String _seriesValue(dynamic value) {
    if (value is List && value.isNotEmpty) return _seriesValue(value.first);
    if (value is Map) {
      return _metadataValue(value['series'] ?? value['name']);
    }
    return _metadataValue(value);
  }

  String get _metadataQuery => [
    _metadataProvider,
    _title.text.trim(),
    _author.text.trim(),
  ].join('\u0000');

  void _detailsChanged() {
    setState(() {
      _lastMetadataQuery = null;
      if (_metadataSearching) {
        _metadataRequestId++;
        _metadataSearching = false;
      }
    });
  }

  Future<void> _setAutoFetchMetadata(bool value) async {
    setState(() {
      _autoFetchMetadata = value;
      _lastMetadataQuery = null;
      if (!value) {
        _metadataRequestId++;
        _metadataSearching = false;
      }
    });
    if (value) await _fetchMetadata();
  }

  Future<void> _selectMetadataProvider(String? provider) async {
    if (provider == null || provider == _metadataProvider) return;
    setState(() {
      _metadataProvider = provider;
      _lastMetadataQuery = null;
      _metadataRequestId++;
      _metadataSearching = false;
    });
    if (_autoFetchMetadata) await _fetchMetadata();
  }

  Future<void> _fetchMetadata({bool showNoResults = true}) async {
    if (!_autoFetchMetadata || _isPodcast || _metadataSearching) return;
    final title = _title.text.trim();
    if (title.isEmpty) return;

    final searcher = widget.metadataSearcher;
    final api = widget.apiService;
    if (searcher == null && api == null) return;

    final query = _metadataQuery;
    final requestId = ++_metadataRequestId;
    setState(() => _metadataSearching = true);

    List<Map<String, dynamic>> results;
    try {
      results = searcher != null
          ? await searcher(
              title: title,
              author: _author.text.trim(),
              provider: _metadataProvider,
            )
          : await api!.searchBooks(
              title: title,
              author: _author.text.trim(),
              provider: _metadataProvider,
            );
    } catch (_) {
      if (!mounted || requestId != _metadataRequestId) return;
      setState(() {
        _metadataSearching = false;
        _lastMetadataQuery = query;
      });
      _showError(AppLocalizations.of(context)!.adminUploadMetadataFailed);
      return;
    }

    if (!mounted || requestId != _metadataRequestId) return;
    if (results.isEmpty) {
      setState(() {
        _metadataSearching = false;
        _lastMetadataQuery = query;
      });
      if (showNoResults) {
        showOverlayToast(
          context,
          AppLocalizations.of(context)!.adminUploadMetadataNoResults,
          icon: Icons.search_off_rounded,
        );
      }
      return;
    }

    final result = results.first;
    final nestedBook = result['book'];
    final book = nestedBook is Map
        ? Map<String, dynamic>.from(nestedBook)
        : result;
    final matchedTitle = _metadataValue(book['title']);
    final matchedAuthor = _metadataValue(book['author'] ?? book['authorName']);
    final matchedSeries = _seriesValue(book['series']);

    setState(() {
      if (matchedTitle.isNotEmpty) _title.text = matchedTitle;
      if (matchedAuthor.isNotEmpty) _author.text = matchedAuthor;
      if (matchedSeries.isNotEmpty) _series.text = matchedSeries;
      _metadataSearching = false;
      _lastMetadataQuery = _metadataQuery;
    });
  }

  Future<List<MediaUploadFile>?> _pickWithFilePicker() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: _supportedExtensions.toList()..sort(),
      withReadStream: true,
    );
    if (result == null) return null;
    return result.files
        .map(
          (file) => MediaUploadFile(
            name: file.name,
            size: file.size,
            path: file.path,
            bytes: file.bytes,
            readStream: file.readStream,
          ),
        )
        .toList();
  }

  Future<void> _pickFiles() async {
    final l = AppLocalizations.of(context)!;
    try {
      final picked = await (widget.filePicker ?? _pickWithFilePicker)();
      if (picked == null || picked.isEmpty || !mounted) return;
      final supported = picked.where(_isSupported).toList();
      if (supported.length != picked.length) {
        showOverlayToast(
          context,
          l.adminUploadUnsupportedFiles,
          icon: Icons.warning_amber_rounded,
        );
      }
      if (supported.isEmpty) return;

      final existing = <String>{
        for (final file in _files) '${file.name}\u0000${file.size}',
      };
      final newFiles = supported
          .where((file) => existing.add('${file.name}\u0000${file.size}'))
          .toList();
      if (newFiles.isEmpty) return;

      setState(() {
        _files = [..._files, ...newFiles];
        if (_title.text.trim().isEmpty && _files.length == 1) {
          final filename = _files.single.name;
          final dot = filename.lastIndexOf('.');
          _title.text = dot > 0 ? filename.substring(0, dot) : filename;
        }
      });
      if (_autoFetchMetadata) await _fetchMetadata();
    } catch (_) {
      if (!mounted) return;
      showOverlayToast(
        context,
        l.adminUploadFilePickerFailed,
        icon: Icons.error_outline_rounded,
      );
    }
  }

  void _removeFile(int index) {
    if (_uploading) return;
    setState(() => _files = [..._files]..removeAt(index));
  }

  void _showError(String message) {
    showOverlayToast(context, message, icon: Icons.error_outline_rounded);
  }

  void _updateProgress(int sentBytes, int totalBytes) {
    if (!mounted || totalBytes <= 0) return;
    final now = DateTime.now();
    if (sentBytes < totalBytes &&
        now.difference(_lastProgressUpdate) <
            const Duration(milliseconds: 100)) {
      return;
    }
    _lastProgressUpdate = now;
    setState(() {
      _progress = (sentBytes / totalBytes).clamp(0.0, 1.0);
    });
  }

  Future<void> _submit() async {
    final l = AppLocalizations.of(context)!;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedLibraryId == null) {
      _showError(l.adminUploadLibraryRequired);
      return;
    }
    if (_selectedFolderId == null || _folderPath.isEmpty) {
      _showError(l.adminUploadFolderRequired);
      return;
    }
    if (_files.isEmpty) {
      _showError(l.adminUploadFilesRequired);
      return;
    }
    if (!_files.any(_isPrimaryFile)) {
      _showError(
        _isPodcast
            ? l.adminUploadPodcastFileRequired
            : l.adminUploadBookFileRequired,
      );
      return;
    }

    if (_autoFetchMetadata &&
        !_isPodcast &&
        _lastMetadataQuery != _metadataQuery) {
      await _fetchMetadata();
      if (!mounted) return;
    }

    final request = MediaUploadRequest(
      libraryId: _selectedLibraryId!,
      folderId: _selectedFolderId!,
      mediaType: _mediaType,
      title: _title.text.trim(),
      author: _author.text.trim(),
      series: _series.text.trim(),
      files: _files,
    );

    ApiService? api;
    if (widget.pathChecker == null || widget.uploader == null) {
      api = widget.apiService;
      if (api == null) {
        _showError(l.adminUploadFailed);
        return;
      }
    }

    setState(() {
      _uploading = true;
      _progress = null;
    });
    widget.onNavigationGuardChanged?.call();

    final pathResult = widget.pathChecker != null
        ? await widget.pathChecker!(request.directory, _folderPath)
        : await api!.checkUploadPathExists(
            directory: request.directory,
            folderPath: _folderPath,
          );
    if (!mounted) return;
    if (!pathResult.success) {
      setState(() => _uploading = false);
      widget.onNavigationGuardChanged?.call();
      _showError(l.adminUploadPathCheckFailed);
      return;
    }
    final target = _existingTarget;
    if (target != null && !pathResult.exists) {
      // The folder the server would build does not match the book's real
      // one, usually a character it strips from names. Better a clear stop
      // than a second copy of the book.
      setState(() => _uploading = false);
      widget.onNavigationGuardChanged?.call();
      _showError(l.adminUploadTargetFolderMismatch(request.directory, target.relPath));
      return;
    }
    if (pathResult.exists && target == null) {
      // The server happily writes into an existing folder, which is how an
      // ebook joins an audiobook that is already there. Ask instead of
      // refusing, since a slip here would merge two different books.
      final existingTitle = pathResult.libraryItemTitle;
      final addAnyway = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l.adminUploadAddToExistingTitle),
          content: Text(
            existingTitle == null || existingTitle.isEmpty
                ? l.adminUploadAddToExistingNoItem
                : l.adminUploadAddToExisting(existingTitle),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l.adminUploadAddFiles),
            ),
          ],
        ),
      );
      if (!mounted) return;
      if (addAnyway != true) {
        setState(() => _uploading = false);
        widget.onNavigationGuardChanged?.call();
        return;
      }
    }

    final result = widget.uploader != null
        ? await widget.uploader!(request, onProgress: _updateProgress)
        : await api!.uploadMedia(request, onProgress: _updateProgress);
    if (!mounted) return;

    final uploadedTitle = target?.title ?? request.title;
    final mustReselectFiles =
        !result.success &&
        _files.any(
          (file) =>
              file.path == null &&
              file.bytes == null &&
              file.readStream != null,
        );
    setState(() {
      _uploading = false;
      _progress = null;
      if (result.success) {
        _title.clear();
        _author.clear();
        _series.clear();
        _files = [];
        _lastMetadataQuery = null;
        _existingTarget = null;
      } else if (mustReselectFiles) {
        _files = [];
      }
    });
    widget.onNavigationGuardChanged?.call();

    if (result.success) {
      showOverlayToast(
        context,
        target != null
            ? l.adminUploadAddedTo(uploadedTitle)
            : l.adminUploadComplete(uploadedTitle),
        icon: Icons.check_circle_outline_rounded,
      );
    } else {
      final error = result.error?.trim();
      final message = error == null || error.isEmpty
          ? l.adminUploadFailed
          : l.adminUploadFailedReason(error);
      _showError(
        mustReselectFiles ? '$message ${l.adminUploadReselectFiles}' : message,
      );
    }
  }

  MediaUploadRequest? get _draft {
    if (_selectedLibraryId == null || _selectedFolderId == null) return null;
    final title = _title.text.trim();
    if (title.isEmpty) return null;
    return MediaUploadRequest(
      libraryId: _selectedLibraryId!,
      folderId: _selectedFolderId!,
      mediaType: _mediaType,
      title: title,
      author: _author.text.trim(),
      series: _series.text.trim(),
      files: _files,
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(kb >= 10 ? 0 : 1)} KB';
    final mb = kb / 1024;
    if (mb < 1024) return '${mb.toStringAsFixed(mb >= 10 ? 0 : 1)} MB';
    final gb = mb / 1024;
    return '${gb.toStringAsFixed(gb >= 10 ? 1 : 2)} GB';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;

    return PopScope(
      canPop: !_uploading,
      child: Scaffold(
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
                      title: l.adminUploadTitle,
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: cs.onSurfaceVariant),
                    onPressed: _uploading ? null : () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _libraries.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          l.adminUploadNoLibraries,
                          textAlign: TextAlign.center,
                          style: tt.bodyMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                    )
                  : Form(
                      key: _formKey,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                        children: [
                          Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 760),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _destinationCard(cs, tt, l),
                                  const SizedBox(height: 12),
                                  _detailsCard(cs, tt, l),
                                  const SizedBox(height: 12),
                                  _filesCard(cs, tt, l),
                                  const SizedBox(height: 16),
                                  if (_uploading) ...[
                                    LinearProgressIndicator(value: _progress),
                                    const SizedBox(height: 8),
                                    Text(
                                      _progress == null
                                          ? l.adminUploadUploading
                                          : l.adminUploadProgress(
                                              (_progress! * 100).round(),
                                            ),
                                      textAlign: TextAlign.center,
                                      style: tt.bodySmall?.copyWith(
                                        color: cs.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                  ],
                                  FilledButton.icon(
                                    key: AdminUploadScreen.submitKey,
                                    onPressed: _uploading || _metadataSearching
                                        ? null
                                        : _submit,
                                    icon: _uploading
                                        ? SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: cs.onPrimary,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.cloud_upload_rounded,
                                          ),
                                    label: Text(
                                      _uploading
                                          ? l.adminUploadUploading
                                          : l.adminUploadButton,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _destinationCard(ColorScheme cs, TextTheme tt, AppLocalizations l) {
    return _card(
      cs,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l.adminUploadDestination,
            style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          _dropdown<String>(
            key: AdminUploadScreen.libraryFieldKey,
            cs: cs,
            label: l.libraryTitle,
            value: _selectedLibraryId,
            enabled: !_uploading,
            items: [
              for (final library in _libraries)
                DropdownMenuItem(
                  value: library['id']?.toString(),
                  child: Text(
                    library['name']?.toString() ?? l.libraryFallback,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: _selectLibrary,
          ),
          const SizedBox(height: 12),
          _dropdown<String>(
            key: AdminUploadScreen.folderFieldKey,
            cs: cs,
            label: l.adminUploadFolder,
            value: _selectedFolderId,
            enabled: !_uploading && _folders.isNotEmpty,
            items: [
              for (final folder in _folders)
                DropdownMenuItem(
                  value: folder['id']?.toString(),
                  child: Text(
                    folder['fullPath']?.toString() ??
                        folder['path']?.toString() ??
                        '',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: (id) => setState(() => _selectedFolderId = id),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                '${l.libMediaType}:',
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(width: 8),
              Container(
                key: AdminUploadScreen.mediaTypeKey,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _isPodcast ? l.libMediaPodcast : l.libMediaBook,
                  style: tt.labelMedium?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detailsCard(ColorScheme cs, TextTheme tt, AppLocalizations l) {
    final draft = _draft;
    final destination = draft == null || _folderPath.isEmpty
        ? null
        : '${_folderPath.replaceAll(RegExp(r'[\\/]+$'), '')}/${draft.directory}';
    return _card(
      cs,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l.adminUploadDetails,
            style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          // BookOrbit items carry file names, not a folder path, so the
          // picker cannot aim an upload there.
          if (_existingTarget == null && widget.apiService?.isBookOrbit != true)
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: _uploading || _selectedLibraryId == null
                    ? null
                    : _pickExistingBook,
                icon: const Icon(Icons.library_add_rounded, size: 18),
                label: Text(l.adminUploadAddToBook),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.library_add_rounded, size: 18, color: cs.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.adminUploadAddingTo(_existingTarget!.title),
                          style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          _existingTarget!.relPath,
                          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _uploading ? null : _clearExistingTarget,
                    icon: const Icon(Icons.close_rounded, size: 18),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          TextFormField(
            key: AdminUploadScreen.titleFieldKey,
            controller: _title,
            enabled: !_uploading && _existingTarget == null,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(labelText: l.title),
            validator: (value) => value == null || value.trim().isEmpty
                ? l.adminUploadTitleRequired
                : null,
            onChanged: (_) => _detailsChanged(),
          ),
          if (!_isPodcast) ...[
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final author = TextFormField(
                  key: AdminUploadScreen.authorFieldKey,
                  controller: _author,
                  enabled: !_uploading && _existingTarget == null,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: l.author,
                    hintText: l.adminUploadOptional,
                  ),
                  onChanged: (_) => _detailsChanged(),
                );
                final series = TextFormField(
                  key: AdminUploadScreen.seriesFieldKey,
                  controller: _series,
                  enabled: !_uploading && _existingTarget == null,
                  decoration: InputDecoration(
                    labelText: l.seriesLabel,
                    hintText: l.adminUploadOptional,
                  ),
                  onChanged: (_) => _detailsChanged(),
                );
                if (constraints.maxWidth < 560) {
                  return Column(
                    children: [author, const SizedBox(height: 12), series],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: author),
                    const SizedBox(width: 12),
                    Expanded(child: series),
                  ],
                );
              },
            ),
            if (_existingTarget == null) ...[
              const SizedBox(height: 16),
              _metadataControls(cs, tt, l),
            ],
          ],
          if (destination != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.adminUploadDestinationPreview,
                    style: tt.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    destination,
                    style: tt.bodySmall?.copyWith(fontFamily: 'monospace'),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _metadataControls(ColorScheme cs, TextTheme tt, AppLocalizations l) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.adminUploadAutoMetadata,
                      style: tt.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _metadataSearching
                          ? l.adminUploadMetadataSearching
                          : l.adminUploadAutoMetadataSubtitle,
                      style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              if (_metadataSearching) ...[
                const SizedBox(width: 12),
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ],
              Switch(
                key: AdminUploadScreen.autoMetadataKey,
                value: _autoFetchMetadata,
                onChanged: _uploading
                    ? null
                    : (value) async => _setAutoFetchMetadata(value),
              ),
            ],
          ),
          if (_autoFetchMetadata) ...[
            const SizedBox(height: 10),
            _dropdown<String>(
              key: AdminUploadScreen.metadataProviderKey,
              cs: cs,
              label: l.adminUploadMetadataProvider,
              value: _metadataProvider,
              enabled: !_uploading && !_metadataSearching,
              items: [
                for (final provider in _metadataProviders)
                  DropdownMenuItem(value: provider, child: Text(provider)),
              ],
              onChanged: (provider) async => _selectMetadataProvider(provider),
            ),
          ],
        ],
      ),
    );
  }

  Widget _filesCard(ColorScheme cs, TextTheme tt, AppLocalizations l) {
    final totalBytes = _files.fold<int>(0, (total, file) => total + file.size);
    return _card(
      cs,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.adminUploadFiles,
                      style: tt.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (_files.isNotEmpty)
                      Text(
                        '${l.adminUploadSelectedFiles(_files.length)} · ${_formatBytes(totalBytes)}',
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                key: AdminUploadScreen.chooseFilesKey,
                onPressed: _uploading ? null : _pickFiles,
                icon: Icon(
                  _files.isEmpty
                      ? Icons.attach_file_rounded
                      : Icons.add_rounded,
                  size: 18,
                ),
                label: Text(
                  _files.isEmpty
                      ? l.adminUploadChooseFiles
                      : l.adminUploadAddFiles,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_files.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.upload_file_rounded,
                    size: 32,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isPodcast
                        ? l.adminUploadPodcastFilesHint
                        : l.adminUploadBookFilesHint,
                    textAlign: TextAlign.center,
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            )
          else
            ...List.generate(_files.length, (index) {
              final file = _files[index];
              return Container(
                margin: EdgeInsets.only(top: index == 0 ? 0 : 8),
                padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isPrimaryFile(file)
                          ? Icons.audio_file_rounded
                          : Icons.description_outlined,
                      color: cs.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            file.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: tt.bodyMedium,
                          ),
                          Text(
                            _formatBytes(file.size),
                            style: tt.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: l.remove,
                      onPressed: _uploading ? null : () => _removeFile(index),
                      icon: const Icon(Icons.close_rounded, size: 19),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _card(ColorScheme cs, {required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }

  Widget _dropdown<T>({
    required Key key,
    required ColorScheme cs,
    required String label,
    required T? value,
    required bool enabled,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return InputDecorator(
      decoration: InputDecoration(labelText: label),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          key: key,
          value: value,
          isExpanded: true,
          isDense: true,
          icon: Icon(Icons.expand_more_rounded, color: cs.onSurfaceVariant),
          items: items,
          onChanged: enabled ? onChanged : null,
        ),
      ),
    );
  }
}

class _ExistingBook {
  final String id;
  final String title;
  final String relPath;
  const _ExistingBook({required this.id, required this.title, required this.relPath});
}

/// Search sheet that hands back the one book tapped.
class _ExistingBookPicker extends StatefulWidget {
  final ApiService api;
  final String libraryId;
  const _ExistingBookPicker({required this.api, required this.libraryId});

  @override
  State<_ExistingBookPicker> createState() => _ExistingBookPickerState();
}

class _ExistingBookPickerState extends State<_ExistingBookPicker> {
  final _controller = TextEditingController();
  Timer? _debounce;
  List<Map<String, dynamic>> _results = [];
  bool _searching = false;
  bool _searched = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    final query = value.trim();
    if (query.isEmpty) {
      setState(() {
        _results = [];
        _searched = false;
        _searching = false;
      });
      return;
    }
    setState(() => _searching = true);
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(query));
  }

  Future<void> _search(String query) async {
    final api = widget.api;
    final index = BookSearchIndex();
    List<Map<String, dynamic>> results = [];
    try {
      await index.ensureIndex(api, widget.libraryId);
      if (!mounted || _controller.text.trim() != query) return;
      if (index.isReady(widget.libraryId)) {
        results = index.search(widget.libraryId, query).map((h) => h.item).toList();
      }
      if (results.isEmpty || index.isTruncated(widget.libraryId)) {
        final server = await api.searchLibrary(widget.libraryId, query);
        if (!mounted || _controller.text.trim() != query) return;
        final seen = results.map((i) => i['id']).toSet();
        for (final r in (server?['book'] as List<dynamic>? ?? const [])) {
          final m = r as Map<String, dynamic>;
          final item = (m['libraryItem'] as Map<String, dynamic>?) ?? m;
          if (!seen.contains(item['id'])) results.add(item);
        }
      }
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _results = results;
      _searching = false;
      _searched = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.adminUploadAddToBook,
                  style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              TextField(
                controller: _controller,
                autofocus: true,
                onChanged: _onChanged,
                decoration: InputDecoration(
                  hintText: l.adminUploadAddToBookHint,
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searching
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                              width: 18, height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2)),
                        )
                      : null,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _searched && _results.isEmpty && !_searching
              ? Center(
                  child: Text(l.adminUploadNoBooksFound,
                      style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  itemCount: _results.length,
                  itemBuilder: (context, i) => _row(cs, tt, l, _results[i]),
                ),
        ),
      ],
    );
  }

  Widget _row(ColorScheme cs, TextTheme tt, AppLocalizations l, Map<String, dynamic> item) {
    final itemId = item['id'] as String? ?? '';
    final metadata =
        (item['media'] as Map<String, dynamic>?)?['metadata'] as Map<String, dynamic>? ?? {};
    final title = metadata['title'] as String? ?? l.unknown;
    final author = metadata['authorName'] as String? ?? '';
    final relPath = item['relPath'] as String? ?? '';
    final coverUrl = widget.api.getCoverUrl(itemId);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.of(context).pop(item),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: CachedNetworkImage(
                    imageUrl: coverUrl,
                    fit: BoxFit.cover,
                    httpHeaders: widget.api.mediaHeaders,
                    placeholder: (_, __) => ColoredBox(color: cs.surfaceContainerHighest),
                    errorWidget: (_, __, ___) => ColoredBox(
                      color: cs.surfaceContainerHighest,
                      child: Icon(Icons.menu_book_rounded, color: cs.onSurfaceVariant),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                    if (author.isNotEmpty)
                      Text(author,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                    if (relPath.isNotEmpty)
                      Text(relPath,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: tt.labelSmall?.copyWith(
                              color: cs.onSurfaceVariant.withValues(alpha: 0.7))),
                  ],
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
