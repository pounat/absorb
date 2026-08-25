// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'whisper_version_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$WhisperVersionResponse {
  @JsonKey(name: '@type')
  String get type;
  String get message;

  /// Create a copy of WhisperVersionResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $WhisperVersionResponseCopyWith<WhisperVersionResponse> get copyWith =>
      _$WhisperVersionResponseCopyWithImpl<WhisperVersionResponse>(
          this as WhisperVersionResponse, _$identity);

  /// Serializes this WhisperVersionResponse to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is WhisperVersionResponse &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.message, message) || other.message == message));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, type, message);

  @override
  String toString() {
    return 'WhisperVersionResponse(type: $type, message: $message)';
  }
}

/// @nodoc
abstract mixin class $WhisperVersionResponseCopyWith<$Res> {
  factory $WhisperVersionResponseCopyWith(WhisperVersionResponse value,
          $Res Function(WhisperVersionResponse) _then) =
      _$WhisperVersionResponseCopyWithImpl;
  @useResult
  $Res call({@JsonKey(name: '@type') String type, String message});
}

/// @nodoc
class _$WhisperVersionResponseCopyWithImpl<$Res>
    implements $WhisperVersionResponseCopyWith<$Res> {
  _$WhisperVersionResponseCopyWithImpl(this._self, this._then);

  final WhisperVersionResponse _self;
  final $Res Function(WhisperVersionResponse) _then;

  /// Create a copy of WhisperVersionResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = null,
    Object? message = null,
  }) {
    return _then(_self.copyWith(
      type: null == type
          ? _self.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      message: null == message
          ? _self.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// Adds pattern-matching-related methods to [WhisperVersionResponse].
extension WhisperVersionResponsePatterns on WhisperVersionResponse {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_WhisperVersionResponse value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _WhisperVersionResponse() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_WhisperVersionResponse value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _WhisperVersionResponse():
        return $default(_that);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_WhisperVersionResponse value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _WhisperVersionResponse() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(@JsonKey(name: '@type') String type, String message)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _WhisperVersionResponse() when $default != null:
        return $default(_that.type, _that.message);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(@JsonKey(name: '@type') String type, String message)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _WhisperVersionResponse():
        return $default(_that.type, _that.message);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(@JsonKey(name: '@type') String type, String message)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _WhisperVersionResponse() when $default != null:
        return $default(_that.type, _that.message);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _WhisperVersionResponse extends WhisperVersionResponse {
  const _WhisperVersionResponse(
      {@JsonKey(name: '@type') required this.type, required this.message})
      : super._();
  factory _WhisperVersionResponse.fromJson(Map<String, dynamic> json) =>
      _$WhisperVersionResponseFromJson(json);

  @override
  @JsonKey(name: '@type')
  final String type;
  @override
  final String message;

  /// Create a copy of WhisperVersionResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$WhisperVersionResponseCopyWith<_WhisperVersionResponse> get copyWith =>
      __$WhisperVersionResponseCopyWithImpl<_WhisperVersionResponse>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$WhisperVersionResponseToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _WhisperVersionResponse &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.message, message) || other.message == message));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, type, message);

  @override
  String toString() {
    return 'WhisperVersionResponse(type: $type, message: $message)';
  }
}

/// @nodoc
abstract mixin class _$WhisperVersionResponseCopyWith<$Res>
    implements $WhisperVersionResponseCopyWith<$Res> {
  factory _$WhisperVersionResponseCopyWith(_WhisperVersionResponse value,
          $Res Function(_WhisperVersionResponse) _then) =
      __$WhisperVersionResponseCopyWithImpl;
  @override
  @useResult
  $Res call({@JsonKey(name: '@type') String type, String message});
}

/// @nodoc
class __$WhisperVersionResponseCopyWithImpl<$Res>
    implements _$WhisperVersionResponseCopyWith<$Res> {
  __$WhisperVersionResponseCopyWithImpl(this._self, this._then);

  final _WhisperVersionResponse _self;
  final $Res Function(_WhisperVersionResponse) _then;

  /// Create a copy of WhisperVersionResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? type = null,
    Object? message = null,
  }) {
    return _then(_WhisperVersionResponse(
      type: null == type
          ? _self.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      message: null == message
          ? _self.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

// dart format on
