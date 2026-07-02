import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../l10n/app_localizations.dart';

/// HTTP client for the ReadMeABook (RMAB) native API.
///
/// Covers the user-scoped allowlisted endpoints: me, search, listRequests,
/// getRequest, createRequest. Admin-only endpoints (metrics / active downloads
/// / recent requests) will land in a follow-up.
///
/// See: documentation/backend/services/api-tokens.md in the RMAB repo.
class RmabService {
  RmabService({required String baseUrl, required this.apiToken})
      : baseUrl = _trimTrailingSlash(baseUrl);

  /// Bare RMAB server URL with no trailing slash (e.g. https://rmab.example.com).
  final String baseUrl;

  /// `rmab_…` bearer token issued by the RMAB server.
  final String apiToken;

  static String _trimTrailingSlash(String s) =>
      s.endsWith('/') ? s.substring(0, s.length - 1) : s;

  Map<String, String> get _headers => {
        'Authorization': 'Bearer $apiToken',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  // ─── /api/auth/me ───────────────────────────────────────────────

  /// GET /api/auth/me — verifies the token and returns the connected user.
  Future<RmabMe> me() async {
    final uri = Uri.parse('$baseUrl/api/auth/me');
    final res = await _get(uri, label: 'me');
    final result = _decode(res, (json) {
      final user = json['user'];
      if (user is! Map<String, dynamic>) {
        throw const FormatException('Response missing "user" object');
      }
      return RmabMe.fromJson(user);
    }, label: 'me');
    debugPrint(
        '[RMAB] me() ok username=${result.username} role=${result.role}');
    return result;
  }

  // ─── /api/audiobooks/search ─────────────────────────────────────

  /// GET /api/audiobooks/search?q=…&page=… — search Audible via RMAB.
  ///
  /// Results are per-user enriched (isRequested, requestStatus, isAvailable,
  /// isIgnored, hasReportedIssue) when called with a valid `rmab_` token.
  Future<RmabSearchResponse> search(String query, {int page = 1}) async {
    debugPrint('[RMAB] search(query="$query", page=$page)');
    final uri = Uri.parse('$baseUrl/api/audiobooks/search').replace(
      queryParameters: {'q': query, 'page': '$page'},
    );
    final res = await _get(uri, label: 'search');
    final out = _decode(res, (json) {
      final list = (json['results'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(RmabSearchResult.fromJson)
          .toList();
      return RmabSearchResponse(
        query: (json['query'] as String?) ?? query,
        results: list,
        page: _asInt(json['page']) ?? page,
        hasMore: (json['hasMore'] as bool?) ?? false,
      );
    }, label: 'search');
    final requestedCount = out.results.where((r) => r.isRequested).length;
    final availableCount = out.results.where((r) => r.isAvailable).length;
    debugPrint('[RMAB] search() -> ${out.results.length} results '
        '(${out.hasMore ? 'hasMore' : 'last page'}, '
        'requested=$requestedCount available=$availableCount)');
    return out;
  }

  // ─── /api/requests ──────────────────────────────────────────────

  /// GET /api/requests — paginated list of the user's requests.
  Future<RmabRequestsPage> listRequests({
    RmabStatusGroup? statusGroup,
    String? cursor,
    int take = 20,
    bool myOnly = true,
    String type = 'audiobook',
  }) async {
    debugPrint(
        '[RMAB] listRequests(statusGroup=${statusGroup?.name ?? 'all'}, '
        'cursor=${cursor ?? '-'}, take=$take, myOnly=$myOnly, type=$type)');
    final qp = <String, String>{
      'take': '$take',
      if (statusGroup != null) 'status': statusGroup.name,
      if (cursor != null) 'cursor': cursor,
      if (myOnly) 'myOnly': 'true',
      'type': type,
    };
    final uri =
        Uri.parse('$baseUrl/api/requests').replace(queryParameters: qp);
    final res = await _get(uri, label: 'listRequests');
    final out = _decode(res, (json) {
      final requests = (json['requests'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(RmabRequest.fromJson)
          .toList();
      final countsJson = (json['counts'] as Map<String, dynamic>?) ?? const {};
      return RmabRequestsPage(
        requests: requests,
        nextCursor: json['nextCursor'] as String?,
        counts: RmabRequestCounts(
          all: _asInt(countsJson['all']) ?? requests.length,
          active: _asInt(countsJson['active']) ?? 0,
          waiting: _asInt(countsJson['waiting']) ?? 0,
          completed: _asInt(countsJson['completed']) ?? 0,
          failed: _asInt(countsJson['failed']) ?? 0,
          cancelled: _asInt(countsJson['cancelled']) ?? 0,
        ),
      );
    }, label: 'listRequests');
    debugPrint('[RMAB] listRequests() -> ${out.requests.length} '
        '(counts: all=${out.counts.all} active=${out.counts.active} '
        'waiting=${out.counts.waiting} completed=${out.counts.completed} '
        'failed=${out.counts.failed} cancelled=${out.counts.cancelled})');
    return out;
  }

  /// GET /api/requests/:id — full detail for a single request.
  Future<RmabRequest> getRequest(String id) async {
    debugPrint('[RMAB] getRequest(id=$id)');
    final uri = Uri.parse('$baseUrl/api/requests/${Uri.encodeComponent(id)}');
    final res = await _get(uri, label: 'getRequest');
    final out = _decode(res, (json) {
      final req = json['request'];
      if (req is! Map<String, dynamic>) {
        throw const FormatException('Response missing "request"');
      }
      return RmabRequest.fromJson(req);
    }, label: 'getRequest');
    debugPrint('[RMAB] getRequest() -> status=${out.status} '
        'progress=${out.progress}%');
    return out;
  }

  /// POST /api/requests — create a request. Returns a typed success or named
  /// error. Throws [RmabException] only for transport / auth / 5xx failures.
  Future<RmabCreateResult> createRequest(RmabRequestInput input) async {
    debugPrint('[RMAB] createRequest(asin=${input.asin} '
        'title="${input.title}" author="${input.author}")');
    final uri = Uri.parse('$baseUrl/api/requests');
    final http.Response res;
    try {
      res = await http
          .post(
            uri,
            headers: _headers,
            body: jsonEncode({'audiobook': input.toJson()}),
          )
          .timeout(const Duration(seconds: 15));
      debugPrint('[RMAB] createRequest <- ${res.statusCode} '
          '(${res.body.length} bytes, '
          'content-type: ${res.headers['content-type']})');
    } on TimeoutException {
      throw RmabException(RmabErrorKind.network, 'Request timed out');
    } on SocketException catch (e) {
      throw RmabException(RmabErrorKind.network, e.message);
    } on http.ClientException catch (e) {
      throw RmabException(RmabErrorKind.network, e.message);
    } catch (e) {
      throw RmabException(RmabErrorKind.network, e.toString());
    }

    if (res.statusCode == 401) {
      throw RmabException(RmabErrorKind.unauthorized,
          _safeServerMessage(res) ?? 'Unauthorized');
    }
    if (res.statusCode == 403) {
      throw RmabException(RmabErrorKind.forbidden,
          _safeServerMessage(res) ?? 'Forbidden');
    }

    if (res.statusCode == 201) {
      try {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final reqJson = body['request'];
        if (reqJson is! Map<String, dynamic>) {
          throw const FormatException('Response missing "request"');
        }
        final created = RmabRequest.fromJson(reqJson);
        debugPrint('[RMAB] createRequest ok '
            'requestId=${created.id} status=${created.status}');
        return RmabCreateSuccess(created);
      } catch (e) {
        debugPrint('[RMAB] createRequest parse error: $e');
        throw RmabException(
            RmabErrorKind.parse, 'Unexpected response from server');
      }
    }

    // Named errors — server returns 4xx / 5xx with { error, message }
    try {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final errorName = (body['error'] as String?) ?? '';
      final message = (body['message'] as String?) ?? '';
      final kind = _mapCreateError(errorName);
      debugPrint(
          '[RMAB] createRequest named error: $errorName -> ${kind.name} '
          '("$message")');
      return RmabCreateNamedError(kind, message);
    } catch (_) {
      throw RmabException(RmabErrorKind.server,
          'Server returned HTTP ${res.statusCode}');
    }
  }

  RmabCreateErrorKind _mapCreateError(String name) {
    switch (name) {
      case 'AlreadyAvailable':
        return RmabCreateErrorKind.alreadyAvailable;
      case 'BeingProcessed':
        return RmabCreateErrorKind.beingProcessed;
      case 'DuplicateRequest':
        return RmabCreateErrorKind.duplicateRequest;
      case 'Ignored':
        return RmabCreateErrorKind.ignored;
      case 'UserNotFound':
        return RmabCreateErrorKind.userNotFound;
      case 'ValidationError':
        return RmabCreateErrorKind.validationError;
      default:
        return RmabCreateErrorKind.requestError;
    }
  }

  // ─── /api/admin/requests/pending-approval ───────────────────────

  /// GET /api/admin/requests/pending-approval — admin-only list of requests
  /// in `awaiting_approval`. Requires an admin-scoped token; a user token
  /// gets [RmabErrorKind.forbidden].
  Future<List<RmabPendingApproval>> listPendingApprovals() async {
    debugPrint('[RMAB] listPendingApprovals()');
    final uri = Uri.parse('$baseUrl/api/admin/requests/pending-approval');
    final res = await _get(uri, label: 'pendingApprovals');
    final out = _decode(res, (json) {
      return (json['requests'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(RmabPendingApproval.fromJson)
          .toList();
    }, label: 'pendingApprovals');
    debugPrint('[RMAB] listPendingApprovals() -> ${out.length} pending');
    return out;
  }

  // ─── /api/admin/requests/:id/approve ────────────────────────────

  /// POST /api/admin/requests/:id/approve — approve or deny a pending request.
  /// Admin-only. Returns the updated request on success.
  ///
  /// Throws [RmabException]: `forbidden` (not admin / token not allowed),
  /// `unauthorized`, `network`, or `server` (the latter carries the server's
  /// message, e.g. the 400 "no longer awaiting approval" stale case).
  Future<RmabRequest> respondToApproval(String id,
      {required bool approve}) async {
    final action = approve ? 'approve' : 'deny';
    debugPrint('[RMAB] respondToApproval(id=$id action=$action)');
    final uri = Uri.parse('$baseUrl/api/admin/requests/${Uri.encodeComponent(id)}/approve');
    final http.Response res;
    try {
      res = await http
          .post(uri,
              headers: _headers, body: jsonEncode({'action': action}))
          .timeout(const Duration(seconds: 20));
      debugPrint('[RMAB] respondToApproval <- ${res.statusCode} '
          '(${res.body.length} bytes)');
    } on TimeoutException {
      throw RmabException(RmabErrorKind.network, 'Request timed out');
    } on SocketException catch (e) {
      throw RmabException(RmabErrorKind.network, e.message);
    } on http.ClientException catch (e) {
      throw RmabException(RmabErrorKind.network, e.message);
    } catch (e) {
      throw RmabException(RmabErrorKind.network, e.toString());
    }

    if (res.statusCode == 401) {
      throw RmabException(RmabErrorKind.unauthorized,
          _safeServerMessage(res) ?? 'Unauthorized');
    }
    if (res.statusCode == 403) {
      throw RmabException(RmabErrorKind.forbidden,
          _safeServerMessage(res) ?? 'Forbidden');
    }
    if (res.statusCode == 200) {
      return _decode(res, (json) {
        final req = json['request'];
        if (req is! Map<String, dynamic>) {
          throw const FormatException('Response missing "request"');
        }
        return RmabRequest.fromJson(req);
      }, label: 'respondToApproval');
    }
    // 400 InvalidStatus/ValidationError, 404 NotFound, 5xx — surface message.
    throw RmabException(RmabErrorKind.server,
        _safeServerMessage(res) ?? 'Server returned HTTP ${res.statusCode}');
  }

  // ─── Shared helpers ─────────────────────────────────────────────

  Future<http.Response> _get(Uri uri, {required String label}) async {
    debugPrint('[RMAB] $label GET $uri');
    final http.Response res;
    try {
      res = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 15));
      debugPrint('[RMAB] $label <- ${res.statusCode} '
          '(${res.body.length} bytes, '
          'content-type: ${res.headers['content-type']})');
    } on TimeoutException {
      debugPrint('[RMAB] $label network: timeout');
      throw RmabException(RmabErrorKind.network, 'Request timed out');
    } on SocketException catch (e) {
      debugPrint('[RMAB] $label network: socket ${e.message}');
      throw RmabException(RmabErrorKind.network, e.message);
    } on http.ClientException catch (e) {
      debugPrint('[RMAB] $label network: client ${e.message}');
      throw RmabException(RmabErrorKind.network, e.message);
    } catch (e) {
      debugPrint('[RMAB] $label network: $e');
      throw RmabException(RmabErrorKind.network, e.toString());
    }

    if (res.statusCode == 401) {
      throw RmabException(RmabErrorKind.unauthorized,
          _safeServerMessage(res) ?? 'Unauthorized');
    }
    if (res.statusCode == 403) {
      throw RmabException(RmabErrorKind.forbidden,
          _safeServerMessage(res) ?? 'Forbidden');
    }
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw RmabException(
          RmabErrorKind.server,
          _safeServerMessage(res) ??
              'Server returned HTTP ${res.statusCode}');
    }
    return res;
  }

  /// Wrap a JSON decode in [RmabException]-aware error handling so callers
  /// don't have to repeat the try/catch.
  T _decode<T>(http.Response res, T Function(Map<String, dynamic>) builder,
      {required String label}) {
    try {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      return builder(body);
    } catch (e) {
      debugPrint('[RMAB] $label() parse error: $e');
      throw RmabException(
          RmabErrorKind.parse, 'Unexpected response from server');
    }
  }

  String? _safeServerMessage(http.Response res) {
    try {
      final body = jsonDecode(res.body);
      if (body is Map<String, dynamic>) {
        final msg = body['message'] ?? body['error'];
        if (msg is String && msg.isNotEmpty) return msg;
      }
    } catch (_) {}
    return null;
  }
}

// ─── Error model ──────────────────────────────────────────────────

enum RmabErrorKind {
  /// Connection refused, DNS failure, timeout, TLS error, etc.
  network,

  /// HTTP 401 — token rejected.
  unauthorized,

  /// HTTP 403 — token valid but not allowed (e.g. user-scoped token hitting
  /// an admin endpoint).
  forbidden,

  /// HTTP 4xx / 5xx that isn't 401/403.
  server,

  /// Response was 2xx but the body didn't match the expected shape.
  parse,
}

class RmabException implements Exception {
  RmabException(this.kind, this.message);

  final RmabErrorKind kind;
  final String message;

  /// User-facing message for this error. [genericPrefix] labels the
  /// fallback case (e.g. request vs search wording).
  String localizedMessage(AppLocalizations l, String genericPrefix) {
    switch (kind) {
      case RmabErrorKind.unauthorized:
        return l.rmabRequestErrorTokenRejected;
      case RmabErrorKind.network:
        return l.rmabConfigErrorNetwork;
      default:
        return '$genericPrefix: $message';
    }
  }

  @override
  String toString() => 'RmabException($kind): $message';
}

// ─── /api/auth/me models ──────────────────────────────────────────

class RmabMe {
  RmabMe({
    required this.id,
    required this.username,
    required this.role,
    required this.isLocalAdmin,
  });

  final String id;
  final String username;
  final String role; // 'user' | 'admin'
  final bool isLocalAdmin;

  bool get isAdmin => role == 'admin';

  factory RmabMe.fromJson(Map<String, dynamic> json) => RmabMe(
        id: (json['id'] ?? '') as String,
        username: (json['username'] ?? '') as String,
        role: (json['role'] ?? 'user') as String,
        isLocalAdmin: (json['isLocalAdmin'] ?? false) as bool,
      );
}

// ─── /api/audiobooks/search models ────────────────────────────────

class RmabSearchResponse {
  RmabSearchResponse({
    required this.query,
    required this.results,
    required this.page,
    required this.hasMore,
  });

  final String query;
  final List<RmabSearchResult> results;
  final int page;
  final bool hasMore;
}

class RmabSearchResult {
  RmabSearchResult({
    required this.asin,
    required this.title,
    required this.author,
    this.narrator,
    this.description,
    this.coverArtUrl,
    this.durationMinutes,
    this.releaseDate,
    this.rating,
    this.series,
    this.seriesPart,
    this.language,
    this.publisherName,
    this.isAvailable = false,
    this.isRequested = false,
    this.requestStatus,
    this.requestId,
    this.isIgnored = false,
    this.hasReportedIssue = false,
  });

  final String asin;
  final String title;
  final String author;
  final String? narrator;
  final String? description;
  final String? coverArtUrl;
  final int? durationMinutes;
  final String? releaseDate;
  final double? rating;
  final String? series;
  final String? seriesPart;
  final String? language;
  final String? publisherName;

  /// Per-user enrichment (set by RMAB when called with a valid token).
  final bool isAvailable;
  final bool isRequested;
  final String? requestStatus;
  final String? requestId;
  final bool isIgnored;
  final bool hasReportedIssue;

  /// Year extracted from [releaseDate] (best-effort parse, null on failure).
  int? get releaseYear {
    final raw = releaseDate;
    if (raw == null || raw.isEmpty) return null;
    final dt = DateTime.tryParse(raw);
    return dt?.year;
  }

  factory RmabSearchResult.fromJson(Map<String, dynamic> json) =>
      RmabSearchResult(
        asin: (json['asin'] ?? '') as String,
        title: (json['title'] ?? '') as String,
        author: (json['author'] ?? '') as String,
        narrator: json['narrator'] as String?,
        description: json['description'] as String?,
        coverArtUrl: json['coverArtUrl'] as String?,
        durationMinutes: _asInt(json['durationMinutes']),
        releaseDate: json['releaseDate'] as String?,
        rating: _asDouble(json['rating']),
        series: json['series'] as String?,
        seriesPart: json['seriesPart'] as String?,
        language: json['language'] as String?,
        publisherName: json['publisherName'] as String?,
        isAvailable: (json['isAvailable'] as bool?) ?? false,
        isRequested: (json['isRequested'] as bool?) ?? false,
        requestStatus: json['requestStatus'] as String?,
        requestId: json['requestId'] as String?,
        isIgnored: (json['isIgnored'] as bool?) ?? false,
        hasReportedIssue: (json['hasReportedIssue'] as bool?) ?? false,
      );

  /// Bridge a book map from the Absorb upcoming-releases service into a
  /// [RmabSearchResult] we can hand to the detail sheet. The upcoming-side
  /// map uses different field names (authors/narrators as lists, coverUrl,
  /// publisherSummary) so do the translation here in one place.
  factory RmabSearchResult.fromUpcomingBookMap(Map<String, dynamic> m) {
    String joinList(dynamic v) {
      if (v is List) {
        return v
            .map((e) {
              if (e is String) return e;
              if (e is Map && e['name'] is String) return e['name'] as String;
              return '';
            })
            .where((s) => s.isNotEmpty)
            .join(', ');
      }
      if (v is String) return v;
      return '';
    }

    return RmabSearchResult(
      asin: (m['asin'] ?? '') as String,
      title: (m['title'] ?? '') as String,
      author: joinList(m['authors'] ?? m['author']),
      narrator: () {
        final s = joinList(m['narrators'] ?? m['narrator']);
        return s.isEmpty ? null : s;
      }(),
      description: (m['publisherSummary'] ?? m['description']) as String?,
      coverArtUrl: (m['coverUrl'] ?? m['coverArtUrl']) as String?,
      durationMinutes: _asInt(m['runtimeMinutes'] ?? m['durationMinutes']),
      releaseDate: m['releaseDate'] as String?,
      rating: _asDouble(m['rating']),
      series: m['series'] as String?,
      seriesPart: (m['sequence'] ?? m['seriesPart']) as String?,
    );
  }
}

// ─── /api/requests models ─────────────────────────────────────────

class RmabRequest {
  RmabRequest({
    required this.id,
    required this.status,
    required this.progress,
    required this.createdAt,
    required this.updatedAt,
    required this.audiobook,
    this.completedAt,
    this.errorMessage,
    this.type = 'audiobook',
    this.downloadAvailable = false,
  });

  final String id;
  final String status;
  final int progress;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
  final String? errorMessage;
  final String type;
  final bool downloadAvailable;
  final RmabAudiobookSummary audiobook;

  RmabStatusGroup? get statusGroup => status.rmabGroup;

  factory RmabRequest.fromJson(Map<String, dynamic> json) {
    final book = json['audiobook'] as Map<String, dynamic>?;
    return RmabRequest(
      id: (json['id'] ?? '') as String,
      status: (json['status'] ?? '') as String,
      progress: _asInt(json['progress']) ?? 0,
      createdAt: _asDate(json['createdAt']) ?? DateTime.now(),
      updatedAt: _asDate(json['updatedAt']) ?? DateTime.now(),
      completedAt: _asDate(json['completedAt']),
      errorMessage: json['errorMessage'] as String?,
      type: (json['type'] ?? 'audiobook') as String,
      downloadAvailable: (json['downloadAvailable'] as bool?) ?? false,
      audiobook: book != null
          ? RmabAudiobookSummary.fromJson(book)
          : RmabAudiobookSummary.empty(),
    );
  }
}

class RmabAudiobookSummary {
  RmabAudiobookSummary({
    required this.id,
    required this.title,
    required this.author,
    this.audibleAsin,
    this.narrator,
    this.coverArtUrl,
    this.series,
    this.seriesPart,
    this.year,
  });

  final String id;
  final String title;
  final String author;
  final String? audibleAsin;
  final String? narrator;
  final String? coverArtUrl;
  final String? series;
  final String? seriesPart;
  final int? year;

  factory RmabAudiobookSummary.empty() =>
      RmabAudiobookSummary(id: '', title: '', author: '');

  factory RmabAudiobookSummary.fromJson(Map<String, dynamic> json) =>
      RmabAudiobookSummary(
        id: (json['id'] ?? '') as String,
        title: (json['title'] ?? '') as String,
        author: (json['author'] ?? '') as String,
        audibleAsin: json['audibleAsin'] as String?,
        narrator: json['narrator'] as String?,
        coverArtUrl: json['coverArtUrl'] as String?,
        series: json['series'] as String?,
        seriesPart: json['seriesPart'] as String?,
        year: _asInt(json['year']),
      );
}

class RmabRequestsPage {
  RmabRequestsPage({
    required this.requests,
    required this.counts,
    this.nextCursor,
  });

  final List<RmabRequest> requests;
  final String? nextCursor;
  final RmabRequestCounts counts;
}

class RmabRequestCounts {
  const RmabRequestCounts({
    required this.all,
    required this.active,
    required this.waiting,
    required this.completed,
    required this.failed,
    required this.cancelled,
  });

  final int all;
  final int active;
  final int waiting;
  final int completed;
  final int failed;
  final int cancelled;
}

// ─── pending-approval models ──────────────────────────────────────

/// A request awaiting admin approval, as returned by
/// GET /api/admin/requests/pending-approval. Unlike [RmabRequest], this
/// carries the requesting user so an admin can see who asked for it.
class RmabPendingApproval {
  RmabPendingApproval({
    required this.id,
    required this.createdAt,
    required this.audiobook,
    required this.requester,
  });

  final String id;
  final DateTime createdAt;
  final RmabAudiobookSummary audiobook;
  final RmabApprovalRequester requester;

  factory RmabPendingApproval.fromJson(Map<String, dynamic> json) {
    final book = json['audiobook'] as Map<String, dynamic>?;
    final user = json['user'] as Map<String, dynamic>?;
    return RmabPendingApproval(
      id: (json['id'] ?? '') as String,
      createdAt: _asDate(json['createdAt']) ?? DateTime.now(),
      audiobook: book != null
          ? RmabAudiobookSummary.fromJson(book)
          : RmabAudiobookSummary.empty(),
      requester: RmabApprovalRequester.fromJson(user ?? const {}),
    );
  }
}

/// The user behind a pending request. `username` comes from the server's
/// `plexUsername`; `avatarUrl` may be null.
class RmabApprovalRequester {
  RmabApprovalRequester({
    required this.id,
    required this.username,
    this.avatarUrl,
  });

  final String id;
  final String username;
  final String? avatarUrl;

  factory RmabApprovalRequester.fromJson(Map<String, dynamic> json) =>
      RmabApprovalRequester(
        id: (json['id'] ?? '') as String,
        username:
            (json['plexUsername'] ?? json['username'] ?? '') as String,
        avatarUrl: json['avatarUrl'] as String?,
      );
}

// ─── createRequest models ─────────────────────────────────────────

class RmabRequestInput {
  RmabRequestInput({
    required this.asin,
    required this.title,
    required this.author,
    this.narrator,
    this.description,
    this.coverArtUrl,
    this.durationMinutes,
    this.releaseDate,
    this.rating,
  });

  final String asin;
  final String title;
  final String author;
  final String? narrator;
  final String? description;
  final String? coverArtUrl;
  final int? durationMinutes;
  final String? releaseDate;
  final double? rating;

  Map<String, dynamic> toJson() => {
        'asin': asin,
        'title': title,
        'author': author,
        if (narrator != null) 'narrator': narrator,
        if (description != null) 'description': description,
        if (coverArtUrl != null) 'coverArtUrl': coverArtUrl,
        if (durationMinutes != null) 'durationMinutes': durationMinutes,
        if (releaseDate != null) 'releaseDate': releaseDate,
        if (rating != null) 'rating': rating,
      };

  factory RmabRequestInput.fromSearchResult(RmabSearchResult r) =>
      RmabRequestInput(
        asin: r.asin,
        title: r.title,
        author: r.author,
        narrator: r.narrator,
        description: r.description,
        coverArtUrl: r.coverArtUrl,
        durationMinutes: r.durationMinutes,
        releaseDate: r.releaseDate,
        rating: r.rating,
      );
}

sealed class RmabCreateResult {
  const RmabCreateResult();
}

class RmabCreateSuccess extends RmabCreateResult {
  const RmabCreateSuccess(this.request);
  final RmabRequest request;
}

class RmabCreateNamedError extends RmabCreateResult {
  const RmabCreateNamedError(this.kind, this.message);
  final RmabCreateErrorKind kind;
  final String message;
}

enum RmabCreateErrorKind {
  alreadyAvailable,
  beingProcessed,
  duplicateRequest,
  /// `bypassIgnore: true` is hardcoded for token requests so this shouldn't
  /// fire, but model it for completeness.
  ignored,
  userNotFound,
  validationError,
  requestError,
}

// ─── Local in-memory request cache ────────────────────────────────

/// In-memory bridge between "I just submitted a request" and "the server's
/// next enrichment will reflect it."
///
/// Without this, dismissing and reopening the detail sheet for a freshly
/// requested book would reset the UI to the unrequested state (because the
/// `RmabSearchResult` we were handed by the parent still has
/// `isRequested: false` from the last search).
///
/// All RMAB widgets consult this on render. The cache only adds requested
/// state — it never claims a book ISN'T requested. So a stale "Already
/// requested" badge is the worst case (better UX than showing a Request
/// button that would just 409 with `DuplicateRequest`).
///
/// In-memory only. Cleared on app restart and on disconnect.
class RmabLocalRequestCache {
  RmabLocalRequestCache._();

  static final Map<String, String> _statusByAsin = {};

  /// The locally-cached status for [asin], or null if we haven't recorded
  /// a fresh request for it during this app session.
  static String? statusFor(String asin) => _statusByAsin[asin];

  /// Record a freshly-created request. [status] should be the server's
  /// returned status string (e.g. `pending`, `searching`).
  static void markRequested(String asin, String status) {
    if (asin.isEmpty) return;
    _statusByAsin[asin] = status;
  }

  /// Clear every cached entry. Called on disconnect.
  static void clear() {
    _statusByAsin.clear();
  }
}

// ─── Status taxonomy ──────────────────────────────────────────────

/// The five status buckets the server groups by in `STATUS_GROUPS`
/// (src/app/api/requests/route.ts).
enum RmabStatusGroup { active, waiting, completed, failed, cancelled }

extension RmabStatusGroupOf on String {
  /// Map a raw status string to its visual group. Returns null for `warn`
  /// or any unknown status (callers should treat null as "unknown" rather
  /// than miscategorising).
  RmabStatusGroup? get rmabGroup {
    switch (this) {
      case 'pending':
      case 'searching':
      case 'downloading':
      case 'processing':
        return RmabStatusGroup.active;
      case 'awaiting_search':
      case 'awaiting_import':
      case 'awaiting_approval':
      case 'awaiting_release':
        return RmabStatusGroup.waiting;
      case 'available':
      case 'downloaded':
        return RmabStatusGroup.completed;
      case 'failed':
        return RmabStatusGroup.failed;
      case 'cancelled':
      case 'denied':
        return RmabStatusGroup.cancelled;
      default:
        return null;
    }
  }
}

// ─── tiny coercion helpers ────────────────────────────────────────

int? _asInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

double? _asDouble(dynamic v) {
  if (v == null) return null;
  if (v is double) return v;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

DateTime? _asDate(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  if (v is String && v.isNotEmpty) return DateTime.tryParse(v);
  return null;
}
