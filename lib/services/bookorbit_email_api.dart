part of 'api_service.dart';

const _keep = Object();

/// BookOrbit's email: sending books and everything set up for it. Each call
/// throws a [BookOrbitAdminError] carrying the server's reason when it refuses.
extension BookOrbitEmailApi on BookOrbitApiService {
  List<T> _list<T>(Object? res, T Function(Map<String, dynamic>) parse) => [
        for (final e in (res is List ? res : const []).whereType<Map<String, dynamic>>()) parse(e),
      ];

  ({bool ok, String? error}) _testResult(Object? res) {
    final m = res is Map ? res : const {};
    return (ok: m['success'] == true, error: m['error'] is String ? m['error'] as String : null);
  }

  /// Whether the server can strip the narration from a read along EPUB before
  /// it goes out.
  Future<bool> emailReadAlongChoice() async => (await _features()).contains('read-aloud-delivery');

  Future<List<BoMailServer>> emailServers() =>
      _admin(() async => _list(await _boGet('/email/providers'), BoMailServer.fromJson));

  Future<BoMailServer> emailSaveServer(int? id, Map<String, dynamic> body) => _admin(() async {
        final res = id == null ? await _boPost('/email/providers', body) : await _boPut('/email/providers/$id', body);
        return BoMailServer.fromJson(res as Map<String, dynamic>);
      });

  Future<void> emailDeleteServer(int id) => _admin(() async {
        await _boDelete('/email/providers/$id');
      });

  /// Shares the server with everyone, or stops sharing it.
  Future<BoMailServer> emailToggleShared(int id) => _admin(() async =>
      BoMailServer.fromJson(await _boPatch('/email/providers/$id/share', const {}) as Map<String, dynamic>));

  /// Makes this the server BookOrbit sends its own mail through (password
  /// resets, sign-in links). Superusers only.
  Future<void> emailSetSystemServer(int id) => _admin(() async {
        await _boPatch('/email/providers/$id/system', const {});
      });

  Future<void> emailClearSystemServer() => _admin(() async {
        await _boDelete('/email/providers/system');
      });

  Future<({bool ok, String? error})> emailTestServer(int id) =>
      _admin(() async => _testResult(await _boPost('/email/providers/$id/test', null, const Duration(seconds: 45))));

  Future<List<BoEmailDevice>> emailDevices() =>
      _admin(() async => _list(await _boGet('/email/recipients'), BoEmailDevice.fromJson));

  Future<BoEmailDevice> emailSaveDevice(int? id, Map<String, dynamic> body) => _admin(() async {
        final res = id == null ? await _boPost('/email/recipients', body) : await _boPut('/email/recipients/$id', body);
        return BoEmailDevice.fromJson(res as Map<String, dynamic>);
      });

  Future<void> emailDeleteDevice(int id) => _admin(() async {
        await _boDelete('/email/recipients/$id');
      });

  /// Sends a short message to the device, written in the app's language
  /// since the server has none of its own.
  Future<({bool ok, String? error})> emailTestDevice(int id, {required String subject, required String text}) =>
      _admin(() async => _testResult(
          await _boPost('/email/recipients/$id/test', {'subject': subject, 'text': text}, const Duration(seconds: 45))));

  Future<List<BoEmailGroup>> emailGroups() =>
      _admin(() async => _list(await _boGet('/email/recipient-groups'), BoEmailGroup.fromJson));

  Future<int> emailCreateGroup(String name, {int? templateId}) => _admin(() async {
        final res = await _boPost('/email/recipient-groups', {
          'name': name.trim(),
          'defaultTemplateId': ?templateId,
        }) as Map<String, dynamic>;
        return (res['id'] as num).toInt();
      });

  Future<void> emailUpdateGroup(int id, {required String name, int? templateId}) => _admin(() async {
        await _boPut('/email/recipient-groups/$id', {'name': name.trim(), 'defaultTemplateId': templateId});
      });

  Future<void> emailDeleteGroup(int id) => _admin(() async {
        await _boDelete('/email/recipient-groups/$id');
      });

  Future<void> emailAddToGroup(int groupId, int deviceId) => _admin(() async {
        await _boPost('/email/recipient-groups/$groupId/members', {'recipientId': deviceId});
      });

  Future<void> emailRemoveFromGroup(int groupId, int deviceId) => _admin(() async {
        await _boDelete('/email/recipient-groups/$groupId/members/$deviceId');
      });

  Future<List<BoEmailTemplate>> emailTemplates() =>
      _admin(() async => _list(await _boGet('/email/templates'), BoEmailTemplate.fromJson));

  Future<BoEmailTemplate> emailSaveTemplate(int? id, {required String name, required String subject, required String body}) =>
      _admin(() async {
        final payload = {'name': name.trim(), 'subject': subject, 'bodyText': body};
        final res =
            id == null ? await _boPost('/email/templates', payload) : await _boPut('/email/templates/$id', payload);
        return BoEmailTemplate.fromJson(res as Map<String, dynamic>);
      });

  Future<void> emailDeleteTemplate(int id) => _admin(() async {
        await _boDelete('/email/templates/$id');
      });

  /// [subject] and [body] filled in with [bookId]'s details, and the file a
  /// send of it would attach.
  Future<({String subject, String body, String? attachment})> emailPreviewTemplate(
          {required String subject, required String body, required int bookId}) =>
      _admin(() async {
        final res = await _boPost('/email/templates/preview', {'subject': subject, 'bodyText': body, 'bookId': bookId})
            as Map<String, dynamic>;
        final file = res['attachment'];
        return (
          subject: '${res['subject'] ?? ''}',
          body: '${res['bodyText'] ?? ''}',
          attachment: file is Map ? file['fileName'] as String? : null,
        );
      });

  Future<BoEmailDefaults> emailDefaults() => _admin(
      () async => BoEmailDefaults.fromJson(await _boGet('/email/preferences') as Map<String, dynamic>?));

  /// Changes only the defaults given; null clears one.
  Future<BoEmailDefaults> emailSetDefaults({Object? serverId = _keep, Object? deviceId = _keep, Object? templateId = _keep}) =>
      _admin(() async => BoEmailDefaults.fromJson(await _boPut('/email/preferences', {
            if (!identical(serverId, _keep)) 'defaultProviderId': serverId,
            if (!identical(deviceId, _keep)) 'defaultRecipientId': deviceId,
            if (!identical(templateId, _keep)) 'defaultTemplateId': templateId,
          }) as Map<String, dynamic>?));

  /// Queues the book for each device. Returns how many emails were queued.
  Future<int> emailSendBook(
    int bookId, {
    required List<int> deviceIds,
    int? serverId,
    int? templateId,
    int? fileId,
  }) =>
      _admin(() async {
        final res = await _boPost('/email/send', {
          'bookIds': [bookId],
          'recipientIds': deviceIds,
          'providerId': ?serverId,
          'templateId': ?templateId,
          'fileId': ?fileId,
        }) as Map<String, dynamic>?;
        return (res?['queued'] as num?)?.toInt() ?? deviceIds.length;
      });

  Future<List<BoEmailSend>> emailHistory({int page = 0, int size = 30, int? bookId, String? status, int? deviceId}) =>
      _admin(() async => _list(
          await _boGet('/email/log', {
            'page': page,
            'size': size,
            'bookId': ?bookId,
            'status': ?status,
            'recipientId': ?deviceId,
          }),
          BoEmailSend.fromJson));

  /// Every user's sends. Superusers only.
  Future<List<BoEmailSend>> emailEveryonesHistory({int page = 0, int size = 30}) =>
      _admin(() async => _list(await _boGet('/email/admin/log', {'page': page, 'size': size}), BoEmailSend.fromJson));

  Future<void> emailResend(int sendId) => _admin(() async {
        await _boPost('/email/log/$sendId/resend');
      });

  Future<void> emailForget(int sendId) => _admin(() async {
        await _boDelete('/email/log/$sendId');
      });
}
