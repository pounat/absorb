import 'package:flutter_chrome_cast/entities/request.dart';

/// Represents a request specific to iOS for Google Cast operations.
///
/// Extends [GoogleCastRequest] to include iOS-specific request handling.
class GoogleCastIosRequest extends GoogleCastRequest {
  /// Creates a [GoogleCastIosRequest] instance.
  ///
  /// [inProgress] indicates if the request is currently in progress.
  /// [isExternal] specifies if the request is external.
  /// [requestID] is the unique identifier for the request.
  /// [error] is an optional error message if the request failed.
  GoogleCastIosRequest({
    required super.inProgress,
    required super.isExternal,
    required super.requestID,
    super.error,
  });

  /// Creates a [GoogleCastIosRequest] from a map, typically decoded from JSON.
  ///
  /// The [map] must contain the keys 'inProgress', 'isExternal', and 'requestID'.
  /// The 'error' key is optional.
  factory GoogleCastIosRequest.fromMap(Map<String, dynamic> map) {
    return GoogleCastIosRequest(
      inProgress: map['inProgress'] as bool,
      isExternal: map['isExternal'] as bool,
      requestID: map['requestID'] as int,
      error: map['error'] as String?,
    );
  }
}
