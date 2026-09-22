// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'whisper_transcribe_segment.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$WhisperTranscribeSegment {
  @JsonKey(name: 'from_ts', fromJson: WhisperTranscribeSegment._durationFromInt)
  Duration get fromTs;
  @JsonKey(name: 'to_ts', fromJson: WhisperTranscribeSegment._durationFromInt)
  Duration get toTs;
  String get text;

  /// Create a copy of WhisperTranscribeSegment
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $WhisperTranscribeSegmentCopyWith<WhisperTranscribeSegment> get copyWith =>
      _$WhisperTranscribeSegmentCopyWithImpl<WhisperTranscribeSegment>(
          this as WhisperTranscribeSegment, _$identity);

  /// Serializes this WhisperTranscribeSegment to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is WhisperTranscribeSegment &&
            (identical(other.fromTs, fromTs) || other.fromTs == fromTs) &&
            (identical(other.toTs, toTs) || other.toTs == toTs) &&
            (identical(other.text, text) || other.text == text));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, fromTs, toTs, text);

  @override
  String toString() {
    return 'WhisperTranscribeSegment(fromTs: $fromTs, toTs: $toTs, text: $text)';
  }
}

/// @nodoc
abstract mixin class $WhisperTranscribeSegmentCopyWith<$Res> {
  factory $WhisperTranscribeSegmentCopyWith(WhisperTranscribeSegment value,
          $Res Function(WhisperTranscribeSegment) _then) =
      _$WhisperTranscribeSegmentCopyWithImpl;
  @useResult
  $Res call(
      {@JsonKey(
          name: 'from_ts', fromJson: WhisperTranscribeSegment._durationFromInt)
      Duration fromTs,
      @JsonKey(
          name: 'to_ts', fromJson: WhisperTranscribeSegment._durationFromInt)
      Duration toTs,
      String text});
}

/// @nodoc
class _$WhisperTranscribeSegmentCopyWithImpl<$Res>
    implements $WhisperTranscribeSegmentCopyWith<$Res> {
  _$WhisperTranscribeSegmentCopyWithImpl(this._self, this._then);

  final WhisperTranscribeSegment _self;
  final $Res Function(WhisperTranscribeSegment) _then;

  /// Create a copy of WhisperTranscribeSegment
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? fromTs = null,
    Object? toTs = null,
    Object? text = null,
  }) {
    return _then(_self.copyWith(
      fromTs: null == fromTs
          ? _self.fromTs
          : fromTs // ignore: cast_nullable_to_non_nullable
              as Duration,
      toTs: null == toTs
          ? _self.toTs
          : toTs // ignore: cast_nullable_to_non_nullable
              as Duration,
      text: null == text
          ? _self.text
          : text // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// Adds pattern-matching-related methods to [WhisperTranscribeSegment].
extension WhisperTranscribeSegmentPatterns on WhisperTranscribeSegment {
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
    TResult Function(_WhisperTranscribeSegment value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _WhisperTranscribeSegment() when $default != null:
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
    TResult Function(_WhisperTranscribeSegment value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _WhisperTranscribeSegment():
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
    TResult? Function(_WhisperTranscribeSegment value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _WhisperTranscribeSegment() when $default != null:
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
            @JsonKey(
                name: 'from_ts',
                fromJson: WhisperTranscribeSegment._durationFromInt)
            Duration fromTs,
            @JsonKey(
                name: 'to_ts',
                fromJson: WhisperTranscribeSegment._durationFromInt)
            Duration toTs,
            String text)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _WhisperTranscribeSegment() when $default != null:
        return $default(_that.fromTs, _that.toTs, _that.text);
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
    TResult Function(
            @JsonKey(
                name: 'from_ts',
                fromJson: WhisperTranscribeSegment._durationFromInt)
            Duration fromTs,
            @JsonKey(
                name: 'to_ts',
                fromJson: WhisperTranscribeSegment._durationFromInt)
            Duration toTs,
            String text)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _WhisperTranscribeSegment():
        return $default(_that.fromTs, _that.toTs, _that.text);
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
            @JsonKey(
                name: 'from_ts',
                fromJson: WhisperTranscribeSegment._durationFromInt)
            Duration fromTs,
            @JsonKey(
                name: 'to_ts',
                fromJson: WhisperTranscribeSegment._durationFromInt)
            Duration toTs,
            String text)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _WhisperTranscribeSegment() when $default != null:
        return $default(_that.fromTs, _that.toTs, _that.text);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _WhisperTranscribeSegment implements WhisperTranscribeSegment {
  const _WhisperTranscribeSegment(
      {@JsonKey(
          name: 'from_ts', fromJson: WhisperTranscribeSegment._durationFromInt)
      required this.fromTs,
      @JsonKey(
          name: 'to_ts', fromJson: WhisperTranscribeSegment._durationFromInt)
      required this.toTs,
      required this.text});
  factory _WhisperTranscribeSegment.fromJson(Map<String, dynamic> json) =>
      _$WhisperTranscribeSegmentFromJson(json);

  @override
  @JsonKey(name: 'from_ts', fromJson: WhisperTranscribeSegment._durationFromInt)
  final Duration fromTs;
  @override
  @JsonKey(name: 'to_ts', fromJson: WhisperTranscribeSegment._durationFromInt)
  final Duration toTs;
  @override
  final String text;

  /// Create a copy of WhisperTranscribeSegment
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$WhisperTranscribeSegmentCopyWith<_WhisperTranscribeSegment> get copyWith =>
      __$WhisperTranscribeSegmentCopyWithImpl<_WhisperTranscribeSegment>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$WhisperTranscribeSegmentToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _WhisperTranscribeSegment &&
            (identical(other.fromTs, fromTs) || other.fromTs == fromTs) &&
            (identical(other.toTs, toTs) || other.toTs == toTs) &&
            (identical(other.text, text) || other.text == text));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, fromTs, toTs, text);

  @override
  String toString() {
    return 'WhisperTranscribeSegment(fromTs: $fromTs, toTs: $toTs, text: $text)';
  }
}

/// @nodoc
abstract mixin class _$WhisperTranscribeSegmentCopyWith<$Res>
    implements $WhisperTranscribeSegmentCopyWith<$Res> {
  factory _$WhisperTranscribeSegmentCopyWith(_WhisperTranscribeSegment value,
          $Res Function(_WhisperTranscribeSegment) _then) =
      __$WhisperTranscribeSegmentCopyWithImpl;
  @override
  @useResult
  $Res call(
      {@JsonKey(
          name: 'from_ts', fromJson: WhisperTranscribeSegment._durationFromInt)
      Duration fromTs,
      @JsonKey(
          name: 'to_ts', fromJson: WhisperTranscribeSegment._durationFromInt)
      Duration toTs,
      String text});
}

/// @nodoc
class __$WhisperTranscribeSegmentCopyWithImpl<$Res>
    implements _$WhisperTranscribeSegmentCopyWith<$Res> {
  __$WhisperTranscribeSegmentCopyWithImpl(this._self, this._then);

  final _WhisperTranscribeSegment _self;
  final $Res Function(_WhisperTranscribeSegment) _then;

  /// Create a copy of WhisperTranscribeSegment
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? fromTs = null,
    Object? toTs = null,
    Object? text = null,
  }) {
    return _then(_WhisperTranscribeSegment(
      fromTs: null == fromTs
          ? _self.fromTs
          : fromTs // ignore: cast_nullable_to_non_nullable
              as Duration,
      toTs: null == toTs
          ? _self.toTs
          : toTs // ignore: cast_nullable_to_non_nullable
              as Duration,
      text: null == text
          ? _self.text
          : text // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

// dart format on
