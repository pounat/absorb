// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'whisper_transcribe_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$WhisperTranscribeResponse {
  @JsonKey(name: '@type')
  String get type;
  String get text;
  @JsonKey(name: 'segments')
  List<WhisperTranscribeSegment>? get segments;

  /// Create a copy of WhisperTranscribeResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $WhisperTranscribeResponseCopyWith<WhisperTranscribeResponse> get copyWith =>
      _$WhisperTranscribeResponseCopyWithImpl<WhisperTranscribeResponse>(
          this as WhisperTranscribeResponse, _$identity);

  /// Serializes this WhisperTranscribeResponse to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is WhisperTranscribeResponse &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.text, text) || other.text == text) &&
            const DeepCollectionEquality().equals(other.segments, segments));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, type, text, const DeepCollectionEquality().hash(segments));

  @override
  String toString() {
    return 'WhisperTranscribeResponse(type: $type, text: $text, segments: $segments)';
  }
}

/// @nodoc
abstract mixin class $WhisperTranscribeResponseCopyWith<$Res> {
  factory $WhisperTranscribeResponseCopyWith(WhisperTranscribeResponse value,
          $Res Function(WhisperTranscribeResponse) _then) =
      _$WhisperTranscribeResponseCopyWithImpl;
  @useResult
  $Res call(
      {@JsonKey(name: '@type') String type,
      String text,
      @JsonKey(name: 'segments') List<WhisperTranscribeSegment>? segments});
}

/// @nodoc
class _$WhisperTranscribeResponseCopyWithImpl<$Res>
    implements $WhisperTranscribeResponseCopyWith<$Res> {
  _$WhisperTranscribeResponseCopyWithImpl(this._self, this._then);

  final WhisperTranscribeResponse _self;
  final $Res Function(WhisperTranscribeResponse) _then;

  /// Create a copy of WhisperTranscribeResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = null,
    Object? text = null,
    Object? segments = freezed,
  }) {
    return _then(_self.copyWith(
      type: null == type
          ? _self.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      text: null == text
          ? _self.text
          : text // ignore: cast_nullable_to_non_nullable
              as String,
      segments: freezed == segments
          ? _self.segments
          : segments // ignore: cast_nullable_to_non_nullable
              as List<WhisperTranscribeSegment>?,
    ));
  }
}

/// Adds pattern-matching-related methods to [WhisperTranscribeResponse].
extension WhisperTranscribeResponsePatterns on WhisperTranscribeResponse {
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
    TResult Function(_WhisperTranscribeResponse value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _WhisperTranscribeResponse() when $default != null:
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
    TResult Function(_WhisperTranscribeResponse value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _WhisperTranscribeResponse():
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
    TResult? Function(_WhisperTranscribeResponse value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _WhisperTranscribeResponse() when $default != null:
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
    TResult Function(
            @JsonKey(name: '@type') String type,
            String text,
            @JsonKey(name: 'segments')
            List<WhisperTranscribeSegment>? segments)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _WhisperTranscribeResponse() when $default != null:
        return $default(_that.type, _that.text, _that.segments);
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
    TResult Function(@JsonKey(name: '@type') String type, String text,
            @JsonKey(name: 'segments') List<WhisperTranscribeSegment>? segments)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _WhisperTranscribeResponse():
        return $default(_that.type, _that.text, _that.segments);
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
    TResult? Function(
            @JsonKey(name: '@type') String type,
            String text,
            @JsonKey(name: 'segments')
            List<WhisperTranscribeSegment>? segments)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _WhisperTranscribeResponse() when $default != null:
        return $default(_that.type, _that.text, _that.segments);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _WhisperTranscribeResponse extends WhisperTranscribeResponse {
  const _WhisperTranscribeResponse(
      {@JsonKey(name: '@type') required this.type,
      required this.text,
      @JsonKey(name: 'segments')
      required final List<WhisperTranscribeSegment>? segments})
      : _segments = segments,
        super._();
  factory _WhisperTranscribeResponse.fromJson(Map<String, dynamic> json) =>
      _$WhisperTranscribeResponseFromJson(json);

  @override
  @JsonKey(name: '@type')
  final String type;
  @override
  final String text;
  final List<WhisperTranscribeSegment>? _segments;
  @override
  @JsonKey(name: 'segments')
  List<WhisperTranscribeSegment>? get segments {
    final value = _segments;
    if (value == null) return null;
    if (_segments is EqualUnmodifiableListView) return _segments;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  /// Create a copy of WhisperTranscribeResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$WhisperTranscribeResponseCopyWith<_WhisperTranscribeResponse>
      get copyWith =>
          __$WhisperTranscribeResponseCopyWithImpl<_WhisperTranscribeResponse>(
              this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$WhisperTranscribeResponseToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _WhisperTranscribeResponse &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.text, text) || other.text == text) &&
            const DeepCollectionEquality().equals(other._segments, _segments));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, type, text, const DeepCollectionEquality().hash(_segments));

  @override
  String toString() {
    return 'WhisperTranscribeResponse(type: $type, text: $text, segments: $segments)';
  }
}

/// @nodoc
abstract mixin class _$WhisperTranscribeResponseCopyWith<$Res>
    implements $WhisperTranscribeResponseCopyWith<$Res> {
  factory _$WhisperTranscribeResponseCopyWith(_WhisperTranscribeResponse value,
          $Res Function(_WhisperTranscribeResponse) _then) =
      __$WhisperTranscribeResponseCopyWithImpl;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: '@type') String type,
      String text,
      @JsonKey(name: 'segments') List<WhisperTranscribeSegment>? segments});
}

/// @nodoc
class __$WhisperTranscribeResponseCopyWithImpl<$Res>
    implements _$WhisperTranscribeResponseCopyWith<$Res> {
  __$WhisperTranscribeResponseCopyWithImpl(this._self, this._then);

  final _WhisperTranscribeResponse _self;
  final $Res Function(_WhisperTranscribeResponse) _then;

  /// Create a copy of WhisperTranscribeResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? type = null,
    Object? text = null,
    Object? segments = freezed,
  }) {
    return _then(_WhisperTranscribeResponse(
      type: null == type
          ? _self.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      text: null == text
          ? _self.text
          : text // ignore: cast_nullable_to_non_nullable
              as String,
      segments: freezed == segments
          ? _self._segments
          : segments // ignore: cast_nullable_to_non_nullable
              as List<WhisperTranscribeSegment>?,
    ));
  }
}

// dart format on
