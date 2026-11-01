part of 'api_service.dart';

/// BookOrbit's user and library administration. Each call throws a
/// [BookOrbitAdminError] carrying the server's reason when it refuses.
extension BookOrbitAdminApi on BookOrbitApiService {
  Future<T> _admin<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on _BoHttpError catch (e) {
      throw BookOrbitAdminError(e.status, e.serverMessage, e.serverCode);
    } on TimeoutException {
      throw const BookOrbitAdminError(0);
    } on http.ClientException {
      throw const BookOrbitAdminError(0);
    }
  }

  void _librariesChanged() {
    BookOrbitApiService._librariesCache = null;
    BookOrbitApiService._librariesAt = null;
  }

  Future<BoUserPage> adminUsers({int page = 0, String search = '', BoUserFilter filter = BoUserFilter.all}) =>
      _admin(() async {
        final res = await _boGet('/users', {
          'page': '$page',
          'pageSize': '50',
          if (search.trim().isNotEmpty) 'search': search.trim(),
          if (filter != BoUserFilter.all) 'state': filter.name,
          'sortBy': 'username',
          'sortDir': 'asc',
        }) as Map<String, dynamic>;
        return BoUserPage(
          [for (final u in (res['users'] as List? ?? const []).whereType<Map<String, dynamic>>()) BoUser.fromJson(u)],
          (res['total'] as num?)?.toInt() ?? 0,
        );
      });

  Future<BoUserCounts> adminUserCounts() =>
      _admin(() async => BoUserCounts.fromJson(await _boGet('/users/summary') as Map<String, dynamic>));

  /// The user's library ids. Empty for an admin, who sees every library.
  Future<List<int>> adminUserLibraries(int userId) => _admin(() async => [
        for (final id in (await _boGet('/users/$userId/libraries') as List? ?? const []))
          if (id is num) id.toInt(),
      ]);

  Future<List<int>> adminDefaultLibraryAccess() => _admin(() async {
        final res = await _boGet('/app-settings/default-library-access') as Map<String, dynamic>;
        return [for (final id in (res['libraryIds'] as List? ?? const [])) if (id is num) id.toInt()];
      });

  Future<BoCreatedUser> adminCreateUser({
    required String username,
    required String name,
    required String email,
    required Set<String> permissions,
    required List<int> libraryIds,
  }) =>
      _admin(() async {
        final res = await _boPost('/users', {
          'username': username.trim(),
          'name': name.trim(),
          'email': email.trim(),
          'permissionNames': boWithRequiredPermissions(permissions).toList(),
          'libraryIds': libraryIds,
        }) as Map<String, dynamic>;
        return BoCreatedUser((res['id'] as num).toInt(), '${res['username'] ?? username}', res['resetUrl'] as String?);
      });

  Future<void> adminUpdateUser(int userId, {String? name, String? email, bool? active}) => _admin(() async {
        await _boPatch('/users/$userId', {
          'name': ?name?.trim(),
          'email': ?email?.trim(),
          'active': ?active,
        });
      });

  Future<void> adminSetUserPermissions(int userId, Set<String> permissions) => _admin(() async {
        await _boPut('/users/$userId/permissions', {'permissionNames': boWithRequiredPermissions(permissions).toList()});
      });

  Future<void> adminSetUserSuperuser(int userId, bool superuser) => _admin(() async {
        await _boPut('/users/$userId/superuser', {'isSuperuser': superuser});
      });

  Future<void> adminSetUserLibraries(int userId, List<int> libraryIds) => _admin(() async {
        await _boPut('/users/$userId/libraries', {'libraryIds': libraryIds});
      });

  /// A link that lets the user set a new password. It lasts 15 minutes.
  Future<String?> adminResetPassword(int userId) => _admin(() async {
        final res = await _boPost('/users/$userId/reset-password') as Map<String, dynamic>?;
        return res?['resetUrl'] as String?;
      });

  Future<void> adminUnlockUser(int userId) => _admin(() async {
        await _boPost('/users/$userId/unlock');
      });

  Future<void> adminDeleteUser(int userId) => _admin(() async {
        await _boDelete('/users/$userId');
      });

  /// Every library for an admin; for someone who only manages libraries,
  /// the ones they have access to.
  Future<List<BoLibrary>> adminLibraries() => _admin(() async {
        final res = await _boGet('/libraries') as List<dynamic>;
        final libs = [for (final l in res.whereType<Map<String, dynamic>>()) BoLibrary.fromJson(l)]
          ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
        return libs;
      });

  Future<Map<int, BoLibraryOverview>> adminLibraryOverview() => _admin(() async {
        final res = await _boGet('/libraries/overview') as List<dynamic>;
        return {
          for (final o in res.whereType<Map<String, dynamic>>())
            (o['libraryId'] as num).toInt(): BoLibraryOverview.fromJson(o),
        };
      });

  Future<BoLibrary> adminLibrary(int libraryId) =>
      _admin(() async => BoLibrary.fromJson(await _boGet('/libraries/$libraryId') as Map<String, dynamic>));

  Future<BoLibrary> adminCreateLibrary({
    required String name,
    required String icon,
    required List<String> folders,
    required String organizationMode,
    String coverAspectRatio = '2/3',
    bool watch = false,
    String? autoScanCron,
  }) =>
      _admin(() async {
        final res = await _boPost('/libraries', {
          'name': name.trim(),
          'icon': icon,
          'folders': folders,
          'type': 'books',
          'organizationMode': organizationMode,
          'coverAspectRatio': coverAspectRatio,
          'watch': watch,
          'autoScanCronExpression': autoScanCron,
        }) as Map<String, dynamic>;
        _librariesChanged();
        return BoLibrary.fromJson(res);
      });

  /// Only the fields given change. Changing the folders starts a rescan.
  Future<BoLibrary> adminUpdateLibrary(
    int libraryId, {
    String? name,
    String? icon,
    List<String>? folders,
    String? coverAspectRatio,
    bool? watch,
    bool setAutoScan = false,
    String? autoScanCron,
  }) =>
      _admin(() async {
        final res = await _boPatch('/libraries/$libraryId', {
          'name': ?name?.trim(),
          'icon': ?icon,
          'folders': ?folders,
          'coverAspectRatio': ?coverAspectRatio,
          'watch': ?watch,
          if (setAutoScan) 'autoScanCronExpression': autoScanCron,
        }) as Map<String, dynamic>;
        _librariesChanged();
        return BoLibrary.fromJson(res);
      });

  /// Removes the library from BookOrbit. Its files stay on disk.
  Future<void> adminDeleteLibrary(int libraryId) => _admin(() async {
        await _boDelete('/libraries/$libraryId');
        _librariesChanged();
      });

  Future<void> adminReorderLibraries(List<int> ids) => _admin(() async {
        await _boPost('/libraries/reorder', {
          'order': [for (var i = 0; i < ids.length; i++) {'id': ids[i], 'displayOrder': i}],
        });
        _librariesChanged();
      });

  Future<void> adminScanLibrary(int libraryId) => _admin(() async {
        await _boPost('/scanner/libraries/$libraryId/scan');
      });

  Future<List<BoLibraryAccess>> adminLibraryAccess(int libraryId) => _admin(() async {
        final res = await _boGet('/libraries/$libraryId/access') as List<dynamic>;
        return [for (final a in res.whereType<Map<String, dynamic>>()) BoLibraryAccess.fromJson(a)];
      });

  /// Gives [userId] access at [level], or changes the level they have.
  Future<void> adminSetLibraryAccess(int libraryId, int userId, String level) => _admin(() async {
        await _boPost('/libraries/$libraryId/access', {'userId': userId, 'accessLevel': level});
      });

  Future<void> adminRemoveLibraryAccess(int libraryId, int userId) => _admin(() async {
        await _boDelete('/libraries/$libraryId/access/$userId');
      });

  Future<List<BoAssignableUser>> adminAssignableUsers() => _admin(() async {
        final res = await _boGet('/users/assignable') as List<dynamic>;
        return [
          for (final u in res.whereType<Map<String, dynamic>>())
            BoAssignableUser((u['id'] as num).toInt(), '${u['username'] ?? ''}', '${u['name'] ?? u['username'] ?? ''}'),
        ];
      });

  /// The top of the area library folders must sit in.
  Future<String> adminFolderRoot() => _admin(() async {
        final res = await _boGet('/path/config') as Map<String, dynamic>;
        return '${res['root'] ?? '/'}';
      });

  Future<List<BoFolder>> adminFolders(String path) => _admin(() async {
        final res = await _boGet('/path', {'path': path}) as List<dynamic>;
        return [
          for (final f in res.whereType<Map<String, dynamic>>()) BoFolder('${f['name'] ?? ''}', '${f['path'] ?? ''}'),
        ];
      });

  Future<List<BoFolderCheck>> adminCheckFolders(List<String> paths, {int? libraryId}) => _admin(() async {
        final res = await _boPost('/libraries/prescan', {
          'paths': paths,
          'libraryId': ?libraryId,
        }) as Map<String, dynamic>;
        return [
          for (final p in (res['paths'] as List? ?? const []).whereType<Map<String, dynamic>>()) BoFolderCheck.fromJson(p),
        ];
      });
}
