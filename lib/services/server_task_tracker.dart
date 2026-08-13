import 'dart:async';

import 'package:flutter/foundation.dart';

import 'api_service.dart';
import 'socket_service.dart';

class ServerTask {
  final String id;
  final String action;
  final Map<String, dynamic> data;
  final String title;
  final String description;
  final String error;
  final bool showSuccess;
  final bool isFailed;
  final bool isFinished;
  final int startedAt;
  final int? finishedAt;
  final double? progress;

  const ServerTask({
    required this.id,
    required this.action,
    required this.data,
    required this.title,
    required this.description,
    required this.error,
    required this.showSuccess,
    required this.isFailed,
    required this.isFinished,
    required this.startedAt,
    required this.finishedAt,
    this.progress,
  });

  factory ServerTask.fromJson(Map<String, dynamic> json) {
    return ServerTask(
      id: json['id']?.toString() ?? '',
      action: json['action']?.toString() ?? '',
      data: _stringKeyedMap(json['data']),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      error: json['error']?.toString() ?? '',
      showSuccess: json['showSuccess'] == true,
      isFailed: json['isFailed'] == true,
      isFinished: json['isFinished'] == true,
      startedAt: (json['startedAt'] as num?)?.toInt() ?? 0,
      finishedAt: (json['finishedAt'] as num?)?.toInt(),
    );
  }

  bool get isRunning => !isFinished;
  String? get libraryItemId => _nonEmptyString(data['libraryItemId']);
  String? get libraryId => _nonEmptyString(data['libraryId']);

  Map<String, dynamic>? get scanResults {
    final results = data['scanResults'];
    return results is Map ? _stringKeyedMap(results) : null;
  }

  ServerTask withProgress(double value) => ServerTask(
    id: id,
    action: action,
    data: data,
    title: title,
    description: description,
    error: error,
    showSuccess: showSuccess,
    isFailed: isFailed,
    isFinished: isFinished,
    startedAt: startedAt,
    finishedAt: finishedAt,
    progress: value,
  );

  ServerTask preservingProgress(ServerTask? previous) => ServerTask(
    id: id,
    action: action,
    data: data,
    title: title,
    description: description,
    error: error,
    showSuccess: showSuccess,
    isFailed: isFailed,
    isFinished: isFinished,
    startedAt: startedAt,
    finishedAt: finishedAt,
    progress: progress ?? previous?.progress,
  );

  static Map<String, dynamic> _stringKeyedMap(Object? value) {
    if (value is! Map) return <String, dynamic>{};
    return value.map((key, item) => MapEntry(key.toString(), item));
  }

  static String? _nonEmptyString(Object? value) {
    final string = value?.toString() ?? '';
    return string.isEmpty ? null : string;
  }
}

class ServerTaskTracker extends ChangeNotifier {
  static const recentTaskDuration = Duration(minutes: 1);

  final SocketService _socketService;
  final Map<String, ServerTask> _tasks = {};
  final Map<String, Timer> _expiryTimers = {};
  final Set<String> _finishedTaskIds = {};
  var _eventRevision = 0;
  var _disposed = false;
  Future<void>? _refreshInFlight;
  ApiService? _refreshApi;

  ServerTaskTracker({SocketService? socketService})
    : _socketService = socketService ?? SocketService() {
    _socketService
      ..addTaskStartedListener(_onTaskStarted)
      ..addTaskProgressListener(_onTaskProgress)
      ..addTaskFinishedListener(_onTaskFinished);
  }

  List<ServerTask> get visibleTasks {
    final cutoff =
        DateTime.now().millisecondsSinceEpoch -
        recentTaskDuration.inMilliseconds;
    final tasks = _tasks.values.where((task) {
      if (task.isRunning) return true;
      if (!task.isFailed && !task.showSuccess) return false;
      return (task.finishedAt ?? 0) > cutoff;
    }).toList()..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return tasks;
  }

  int get runningCount => _tasks.values.where((task) => task.isRunning).length;

  bool isLibraryActionRunning(String action, String libraryId) {
    return _tasks.values.any(
      (task) =>
          task.isRunning &&
          task.action == action &&
          task.libraryId == libraryId,
    );
  }

  Future<void> refresh(ApiService api) async {
    final activeRefresh = _refreshInFlight;
    if (activeRefresh != null) {
      if (identical(api, _refreshApi)) return activeRefresh;
      await activeRefresh;
      return refresh(api);
    }

    late final Future<void> operation;
    operation = _performRefresh(api).whenComplete(() {
      if (identical(_refreshInFlight, operation)) {
        _refreshInFlight = null;
        _refreshApi = null;
      }
    });
    _refreshApi = api;
    _refreshInFlight = operation;
    return operation;
  }

  Future<void> _performRefresh(ApiService api) async {
    if (_disposed) return;
    final revisionBeforeRequest = _eventRevision;
    final rawTasks = await api.getServerTasks();
    if (_disposed || rawTasks == null) return;

    final fetched = rawTasks
        .map(ServerTask.fromJson)
        .where(
          (task) => task.id.isNotEmpty && !_finishedTaskIds.contains(task.id),
        )
        .toList();

    if (_eventRevision == revisionBeforeRequest) {
      final runningIds = _tasks.values
          .where((task) => task.isRunning)
          .map((task) => task.id)
          .toList();
      for (final id in runningIds) {
        _tasks.remove(id);
      }
    }

    for (final task in fetched) {
      _upsert(task, notify: false);
    }
    notifyListeners();
  }

  void _onTaskStarted(Map<String, dynamic> data) {
    _eventRevision++;
    final task = ServerTask.fromJson(data);
    if (task.id.isEmpty) return;
    if (task.isFinished) _finishedTaskIds.add(task.id);
    _upsert(task);
  }

  void _onTaskProgress(Map<String, dynamic> data) {
    final progress = _parseProgress(data['progress']);
    if (progress == null) return;
    final libraryItemId = data['libraryItemId']?.toString();
    final taskId = data['id']?.toString();
    var changed = false;
    for (final entry in _tasks.entries.toList()) {
      final matches = taskId != null && taskId.isNotEmpty
          ? entry.key == taskId
          : libraryItemId != null &&
                libraryItemId.isNotEmpty &&
                entry.value.libraryItemId == libraryItemId;
      if (!entry.value.isRunning || !matches) continue;
      _tasks[entry.key] = entry.value.withProgress(progress);
      changed = true;
    }
    if (changed) notifyListeners();
  }

  void _onTaskFinished(Map<String, dynamic> data) {
    _eventRevision++;
    final task = ServerTask.fromJson(data);
    if (task.id.isEmpty) return;
    _finishedTaskIds.add(task.id);
    _upsert(task);
  }

  void _upsert(ServerTask task, {bool notify = true}) {
    final previous = _tasks[task.id];
    final targetId = task.libraryItemId ?? task.libraryId;
    if (previous == null && targetId != null) {
      final duplicateIds = _tasks.values
          .where(
            (other) =>
                other.action == task.action &&
                (other.libraryItemId ?? other.libraryId) == targetId,
          )
          .map((other) => other.id)
          .toList();
      for (final id in duplicateIds) {
        _expiryTimers.remove(id)?.cancel();
        _tasks.remove(id);
      }
    }

    final next = task.preservingProgress(previous);
    if (next.isFinished && !next.isFailed && !next.showSuccess) {
      _expiryTimers.remove(next.id)?.cancel();
      _tasks.remove(next.id);
    } else {
      _tasks[next.id] = next;
      if (next.isFinished) _scheduleExpiry(next);
    }
    if (notify && !_disposed) notifyListeners();
  }

  void _scheduleExpiry(ServerTask task) {
    _expiryTimers.remove(task.id)?.cancel();
    final expiresAt =
        (task.finishedAt ?? DateTime.now().millisecondsSinceEpoch) +
        recentTaskDuration.inMilliseconds;
    final remaining = Duration(
      milliseconds: expiresAt - DateTime.now().millisecondsSinceEpoch,
    );
    if (remaining <= Duration.zero) {
      _tasks.remove(task.id);
      return;
    }
    _expiryTimers[task.id] = Timer(remaining, () {
      _expiryTimers.remove(task.id);
      if (_disposed) return;
      _tasks.remove(task.id);
      notifyListeners();
    });
  }

  static double? _parseProgress(Object? value) {
    final parsed = value is num
        ? value.toDouble()
        : double.tryParse(value?.toString().replaceAll('%', '') ?? '');
    return parsed?.clamp(0, 100).toDouble();
  }

  @override
  void dispose() {
    _disposed = true;
    _socketService
      ..removeTaskStartedListener(_onTaskStarted)
      ..removeTaskProgressListener(_onTaskProgress)
      ..removeTaskFinishedListener(_onTaskFinished);
    for (final timer in _expiryTimers.values) {
      timer.cancel();
    }
    _expiryTimers.clear();
    super.dispose();
  }
}
