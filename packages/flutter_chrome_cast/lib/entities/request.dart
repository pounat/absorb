/// Represents a request, including progress, external status, request ID, and error.
class GoogleCastRequest {
  /// Whether the request is in progress.
  final bool inProgress;

  /// Whether the request is external.
  final bool isExternal;

  /// The unique request ID.
  final int requestID;

  /// Error message, if any.
  final String? error;

  /// Creates a new [GoogleCastRequest] instance.
  GoogleCastRequest({
    required this.inProgress,
    required this.isExternal,
    required this.requestID,
    this.error,
  });

  /// Creates a [GoogleCastRequest] from a map, typically decoded from JSON.
  ///
  /// The [map] must contain the keys 'inProgress', 'isExternal', and 'requestID'.
  /// The 'error' key is optional.
  factory GoogleCastRequest.fromMap(Map<String, dynamic> map) {
    return GoogleCastRequest(
      inProgress: map['inProgress'] as bool? ?? false,
      isExternal: map['isExternal'] as bool? ?? false,
      requestID: map['requestID'] as int? ?? map['requestId'] as int? ?? 0,
      error: map['error'] as String?,
    );
  }
}
