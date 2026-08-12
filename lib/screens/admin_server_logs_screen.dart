import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../services/server_log_export_service.dart';
import '../services/socket_service.dart';
import '../widgets/absorb_page_header.dart';
import '../widgets/overlay_toast.dart';

class AdminServerLogsScreen extends StatefulWidget {
  const AdminServerLogsScreen({super.key});

  @override
  State<AdminServerLogsScreen> createState() => _AdminServerLogsScreenState();
}

class _AdminServerLogsScreenState extends State<AdminServerLogsScreen> {
  static const _maxLogs = 5000;
  static const _serverLevels = <int, String>{
    0: 'Trace',
    1: 'Debug',
    2: 'Info',
    3: 'Warning',
  };
  static const _filterLevels = <int, String>{
    -1: 'All levels',
    0: 'Trace and higher',
    1: 'Debug and higher',
    2: 'Info and higher',
    3: 'Warning and higher',
    4: 'Error and higher',
  };

  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  final _socket = SocketService();
  late final void Function(Map<String, dynamic>) _socketLogHandler;

  List<_ServerLogEntry> _logs = [];
  bool _loading = true;
  bool _refreshing = false;
  bool _loadFailed = false;
  bool _savingLogLevel = false;
  int _serverLogLevel = 2;
  int _visibleMinimumLevel = -1;
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _socketLogHandler = _onServerLog;
    final rawLevel = context.read<AuthProvider>().serverSettings?['logLevel'];
    _serverLogLevel = _parseServerLevel(rawLevel);
    _socket.addServerLogListener(_socketLogHandler, level: _serverLogLevel);
    _loadLogs();
  }

  @override
  void dispose() {
    _socket.removeServerLogListener(_socketLogHandler);
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  int _parseServerLevel(dynamic value) {
    final parsed = value is num
        ? value.toInt()
        : int.tryParse(value?.toString() ?? '');
    return _serverLevels.containsKey(parsed) ? parsed! : 2;
  }

  List<_ServerLogEntry> get _visibleLogs {
    final query = _searchText.trim().toLowerCase();
    return _logs
        .where((log) {
          if (_visibleMinimumLevel >= 0 && log.level < _visibleMinimumLevel) {
            return false;
          }
          return query.isEmpty || log.searchText.contains(query);
        })
        .toList(growable: false);
  }

  Future<void> _loadLogs() async {
    final api = context.read<AuthProvider>().apiService;
    if (api == null) {
      setState(() {
        _loading = false;
        _loadFailed = true;
      });
      return;
    }

    setState(() {
      if (_logs.isEmpty) {
        _loading = true;
      } else {
        _refreshing = true;
      }
      _loadFailed = false;
    });
    final rawLogs = await api.getServerLogs();
    if (!mounted) return;

    if (rawLogs == null) {
      setState(() {
        _loading = false;
        _refreshing = false;
        _loadFailed = true;
      });
      return;
    }

    final loaded = rawLogs
        .map(_ServerLogEntry.fromMap)
        .whereType<_ServerLogEntry>();
    final merged = <String, _ServerLogEntry>{};
    for (final log in [...loaded, ..._logs]) {
      merged[log.identity] = log;
    }
    var values = merged.values.toList(growable: false);
    if (values.length > _maxLogs) {
      values = values.sublist(values.length - _maxLogs);
    }
    setState(() {
      _logs = values;
      _loading = false;
      _refreshing = false;
    });
    _scrollToBottom(jump: true);
  }

  void _onServerLog(Map<String, dynamic> rawLog) {
    final log = _ServerLogEntry.fromMap(rawLog);
    if (log == null || !mounted) return;
    final shouldFollow =
        !_scrollController.hasClients ||
        _scrollController.position.maxScrollExtent -
                _scrollController.position.pixels <
            96;
    setState(() {
      _logs = [..._logs, log];
      if (_logs.length > _maxLogs + 50) {
        _logs = _logs.sublist(_logs.length - _maxLogs);
      }
    });
    if (shouldFollow) _scrollToBottom();
  }

  void _scrollToBottom({bool jump = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final target = _scrollController.position.maxScrollExtent;
      if (jump) {
        _scrollController.jumpTo(target);
      } else {
        _scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _changeServerLogLevel(int level) async {
    if (_savingLogLevel || level == _serverLogLevel) return;
    final auth = context.read<AuthProvider>();
    final api = auth.apiService;
    if (api == null) return;
    final previous = _serverLogLevel;
    setState(() {
      _serverLogLevel = level;
      _savingLogLevel = true;
    });

    final updated = await api.updateServerSettings({'logLevel': level});
    if (!mounted) return;
    if (updated == null) {
      setState(() {
        _serverLogLevel = previous;
        _savingLogLevel = false;
      });
      showOverlayToast(
        context,
        AppLocalizations.of(context)!.srvSaveFailed,
        icon: Icons.error_outline_rounded,
      );
      return;
    }

    auth.applyServerSettings(updated);
    _socket.updateServerLogListenerLevel(_socketLogHandler, level);
    setState(() => _savingLogLevel = false);
  }

  Future<void> _exportVisibleLogs(BuildContext buttonContext) async {
    final logs = _visibleLogs;
    if (logs.isEmpty) return;
    final now = DateTime.now();
    String two(int value) => value.toString().padLeft(2, '0');
    final fileName =
        'audiobookshelf_server_logs_${now.year}-${two(now.month)}-${two(now.day)}_${two(now.hour)}-${two(now.minute)}-${two(now.second)}.txt';
    final content = StringBuffer()
      ..writeln('Audiobookshelf server logs')
      ..writeln('Exported: ${now.toIso8601String()}')
      ..writeln('Server log level: ${_serverLevels[_serverLogLevel]}')
      ..writeln('Visible entries: ${logs.length} of ${_logs.length}')
      ..writeln(
        'Display filter: ${_filterLevels[_visibleMinimumLevel] ?? 'All levels'}',
      );
    if (_searchText.trim().isNotEmpty) {
      content.writeln('Search: ${_searchText.trim()}');
    }
    content.writeln();
    for (final log in logs) {
      content.writeln(log.exportLine);
    }

    final box = buttonContext.findRenderObject();
    final origin = box is RenderBox
        ? box.localToGlobal(Offset.zero) & box.size
        : null;
    try {
      await ServerLogExportService.exportText(
        fileName: fileName,
        content: content.toString(),
        sharePositionOrigin: origin,
      );
    } catch (error) {
      if (!mounted) return;
      showOverlayToast(
        context,
        AppLocalizations.of(context)!.failedToShare(error.toString()),
        icon: Icons.error_outline_rounded,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;
    final visibleLogs = _visibleLogs;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 8, 0),
              child: Row(
                children: [
                  const Expanded(
                    child: AbsorbPageHeader(
                      title: 'Server logs',
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  if (_refreshing)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  else
                    IconButton(
                      tooltip: l.refreshTooltip,
                      onPressed: _loadLogs,
                      icon: Icon(
                        Icons.refresh_rounded,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  Builder(
                    builder: (buttonContext) => IconButton(
                      tooltip: l.sendLogs,
                      onPressed: visibleLogs.isEmpty
                          ? null
                          : () => _exportVisibleLogs(buttonContext),
                      icon: const Icon(Icons.download_rounded),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: cs.onSurfaceVariant),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: _buildControls(cs, tt, l),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: _buildLogPanel(cs, tt, l, visibleLogs),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls(ColorScheme cs, TextTheme tt, AppLocalizations l) {
    final search = TextField(
      controller: _searchController,
      onChanged: (value) => setState(() => _searchText = value),
      decoration: InputDecoration(
        labelText: l.search,
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: _searchText.isEmpty
            ? null
            : IconButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchText = '');
                },
                icon: const Icon(Icons.close_rounded),
              ),
      ),
    );
    final displayFilter = _dropdown(
      cs,
      tt,
      label: 'Display',
      value: _visibleMinimumLevel,
      options: _filterLevels,
      onChanged: (value) => setState(() => _visibleMinimumLevel = value),
    );
    final serverLevel = _dropdown(
      cs,
      tt,
      label: _savingLogLevel ? 'Saving log level…' : 'Server log level',
      value: _serverLogLevel,
      options: _serverLevels,
      onChanged: _savingLogLevel ? null : _changeServerLogLevel,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 720) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: search),
              const SizedBox(width: 12),
              SizedBox(width: 190, child: displayFilter),
              const SizedBox(width: 12),
              SizedBox(width: 180, child: serverLevel),
            ],
          );
        }
        return Column(
          children: [
            search,
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: displayFilter),
                const SizedBox(width: 10),
                Expanded(child: serverLevel),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _dropdown(
    ColorScheme cs,
    TextTheme tt, {
    required String label,
    required int value,
    required Map<int, String> options,
    required ValueChanged<int>? onChanged,
  }) {
    return InputDecorator(
      decoration: InputDecoration(labelText: label),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: value,
          isDense: true,
          isExpanded: true,
          borderRadius: BorderRadius.circular(12),
          style: tt.bodyMedium?.copyWith(color: cs.onSurface),
          items: options.entries
              .map(
                (entry) => DropdownMenuItem<int>(
                  value: entry.key,
                  child: Text(
                    entry.value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(growable: false),
          onChanged: onChanged == null
              ? null
              : (selected) {
                  if (selected != null) onChanged(selected);
                },
        ),
      ),
    );
  }

  Widget _buildLogPanel(
    ColorScheme cs,
    TextTheme tt,
    AppLocalizations l,
    List<_ServerLogEntry> visibleLogs,
  ) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (_loadFailed && _logs.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 42,
              color: cs.error.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 12),
            Text(
              'Couldn’t load the server logs',
              style: tt.titleSmall?.copyWith(color: cs.onSurface),
            ),
            const SizedBox(height: 8),
            OutlinedButton(onPressed: _loadLogs, child: Text(l.retry)),
          ],
        ),
      );
    }

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: visibleLogs.isEmpty
          ? Center(
              child: Text(
                _logs.isEmpty ? 'No server logs yet' : 'No logs match',
                style: tt.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                ),
              ),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 760;
                return SelectionArea(
                  child: Scrollbar(
                    controller: _scrollController,
                    thumbVisibility: wide,
                    child: ListView.separated(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      itemCount: visibleLogs.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        thickness: 1,
                        color: cs.outlineVariant.withValues(alpha: 0.18),
                      ),
                      itemBuilder: (_, index) =>
                          _logRow(cs, tt, visibleLogs[index], wide: wide),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _logRow(
    ColorScheme cs,
    TextTheme tt,
    _ServerLogEntry log, {
    required bool wide,
  }) {
    final levelColor = _levelColor(cs, log.level);
    final level = Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: levelColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        log.levelName,
        style: tt.labelSmall?.copyWith(
          color: levelColor,
          fontWeight: FontWeight.w700,
          fontSize: 10,
        ),
      ),
    );

    if (!wide) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    log.timestamp,
                    style: tt.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                level,
              ],
            ),
            if (log.source.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(
                log.source,
                style: tt.labelSmall?.copyWith(
                  color: cs.primary.withValues(alpha: 0.7),
                  fontFamily: 'monospace',
                ),
              ),
            ],
            const SizedBox(height: 5),
            Text(
              log.message,
              style: tt.bodySmall?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.88),
                fontFamily: 'monospace',
                height: 1.35,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 176,
            child: Text(
              log.timestamp,
              style: tt.labelSmall?.copyWith(
                color: cs.onSurfaceVariant.withValues(alpha: 0.65),
                fontFamily: 'monospace',
              ),
            ),
          ),
          SizedBox(
            width: 82,
            child: Align(alignment: Alignment.topLeft, child: level),
          ),
          if (log.source.isNotEmpty)
            SizedBox(
              width: 150,
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Text(
                  log.source,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: tt.labelSmall?.copyWith(
                    color: cs.primary.withValues(alpha: 0.7),
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),
          Expanded(
            child: Text(
              log.message,
              style: tt.bodySmall?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.88),
                fontFamily: 'monospace',
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _levelColor(ColorScheme cs, int level) {
    return switch (level) {
      0 => cs.onSurfaceVariant,
      1 => cs.secondary,
      2 => cs.primary,
      3 => Colors.amber.shade700,
      4 => cs.error,
      5 => Colors.red.shade900,
      6 => cs.tertiary,
      _ => cs.onSurfaceVariant,
    };
  }
}

class _ServerLogEntry {
  final String timestamp;
  final String source;
  final String message;
  final String levelName;
  final int level;

  const _ServerLogEntry({
    required this.timestamp,
    required this.source,
    required this.message,
    required this.levelName,
    required this.level,
  });

  static _ServerLogEntry? fromMap(Map<String, dynamic> raw) {
    final rawMessage = raw['message'];
    if (rawMessage == null) return null;
    final rawLevel = raw['level'];
    final level = rawLevel is num
        ? rawLevel.toInt()
        : int.tryParse(rawLevel?.toString() ?? '') ?? 0;
    return _ServerLogEntry(
      timestamp: raw['timestamp']?.toString() ?? '',
      source: raw['source']?.toString() ?? '',
      message: rawMessage.toString(),
      levelName: raw['levelName']?.toString().toUpperCase() ?? 'UNKNOWN',
      level: level,
    );
  }

  String get identity => '$timestamp\u0000$level\u0000$source\u0000$message';

  String get searchText =>
      '$timestamp $levelName $source $message'.toLowerCase();

  String get exportLine {
    final sourceText = source.isEmpty ? '' : ' [$source]';
    return '$timestamp ${levelName.padRight(5)}$sourceText $message';
  }
}
