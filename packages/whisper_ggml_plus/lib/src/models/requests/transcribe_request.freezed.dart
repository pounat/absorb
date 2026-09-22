// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'transcribe_request.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TranscribeRequest {
  String get audio;
  bool get isTranslate;
  int get threads;
  bool get isVerbose;
  String get language;
  bool get isSpecialTokens;
  bool get isNoTimestamps;
  bool get isRealtime;
  int get nProcessors;
  bool get splitOnWord;
  bool get noFallback;
  bool get diarize;
  bool get speedUp;
  WhisperVadMode get vadMode;
  String? get vadModelPath;
  Stream<String>? get realtimeStream;

  /// Create a copy of TranscribeRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $TranscribeRequestCopyWith<TranscribeRequest> get copyWith =>
      _$TranscribeRequestCopyWithImpl<TranscribeRequest>(
          this as TranscribeRequest, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is TranscribeRequest &&
            (identical(other.audio, audio) || other.audio == audio) &&
            (identical(other.isTranslate, isTranslate) ||
                other.isTranslate == isTranslate) &&
            (identical(other.threads, threads) || other.threads == threads) &&
            (identical(other.isVerbose, isVerbose) ||
                other.isVerbose == isVerbose) &&
            (identical(other.language, language) ||
                other.language == language) &&
            (identical(other.isSpecialTokens, isSpecialTokens) ||
                other.isSpecialTokens == isSpecialTokens) &&
            (identical(other.isNoTimestamps, isNoTimestamps) ||
                other.isNoTimestamps == isNoTimestamps) &&
            (identical(other.isRealtime, isRealtime) ||
                other.isRealtime == isRealtime) &&
            (identical(other.nProcessors, nProcessors) ||
                other.nProcessors == nProcessors) &&
            (identical(other.splitOnWord, splitOnWord) ||
                other.splitOnWord == splitOnWord) &&
            (identical(other.noFallback, noFallback) ||
                other.noFallback == noFallback) &&
            (identical(other.diarize, diarize) || other.diarize == diarize) &&
            (identical(other.speedUp, speedUp) || other.speedUp == speedUp) &&
            (identical(other.vadMode, vadMode) || other.vadMode == vadMode) &&
            (identical(other.vadModelPath, vadModelPath) ||
                other.vadModelPath == vadModelPath) &&
            (identical(other.realtimeStream, realtimeStream) ||
                other.realtimeStream == realtimeStream));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      audio,
      isTranslate,
      threads,
      isVerbose,
      language,
      isSpecialTokens,
      isNoTimestamps,
      isRealtime,
      nProcessors,
      splitOnWord,
      noFallback,
      diarize,
      speedUp,
      vadMode,
      vadModelPath,
      realtimeStream);

  @override
  String toString() {
    return 'TranscribeRequest(audio: $audio, isTranslate: $isTranslate, threads: $threads, isVerbose: $isVerbose, language: $language, isSpecialTokens: $isSpecialTokens, isNoTimestamps: $isNoTimestamps, isRealtime: $isRealtime, nProcessors: $nProcessors, splitOnWord: $splitOnWord, noFallback: $noFallback, diarize: $diarize, speedUp: $speedUp, vadMode: $vadMode, vadModelPath: $vadModelPath, realtimeStream: $realtimeStream)';
  }
}

/// @nodoc
abstract mixin class $TranscribeRequestCopyWith<$Res> {
  factory $TranscribeRequestCopyWith(
          TranscribeRequest value, $Res Function(TranscribeRequest) _then) =
      _$TranscribeRequestCopyWithImpl;
  @useResult
  $Res call(
      {String audio,
      bool isTranslate,
      int threads,
      bool isVerbose,
      String language,
      bool isSpecialTokens,
      bool isNoTimestamps,
      bool isRealtime,
      int nProcessors,
      bool splitOnWord,
      bool noFallback,
      bool diarize,
      bool speedUp,
      WhisperVadMode vadMode,
      String? vadModelPath,
      Stream<String>? realtimeStream});
}

/// @nodoc
class _$TranscribeRequestCopyWithImpl<$Res>
    implements $TranscribeRequestCopyWith<$Res> {
  _$TranscribeRequestCopyWithImpl(this._self, this._then);

  final TranscribeRequest _self;
  final $Res Function(TranscribeRequest) _then;

  /// Create a copy of TranscribeRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? audio = null,
    Object? isTranslate = null,
    Object? threads = null,
    Object? isVerbose = null,
    Object? language = null,
    Object? isSpecialTokens = null,
    Object? isNoTimestamps = null,
    Object? isRealtime = null,
    Object? nProcessors = null,
    Object? splitOnWord = null,
    Object? noFallback = null,
    Object? diarize = null,
    Object? speedUp = null,
    Object? vadMode = null,
    Object? vadModelPath = freezed,
    Object? realtimeStream = freezed,
  }) {
    return _then(_self.copyWith(
      audio: null == audio
          ? _self.audio
          : audio // ignore: cast_nullable_to_non_nullable
              as String,
      isTranslate: null == isTranslate
          ? _self.isTranslate
          : isTranslate // ignore: cast_nullable_to_non_nullable
              as bool,
      threads: null == threads
          ? _self.threads
          : threads // ignore: cast_nullable_to_non_nullable
              as int,
      isVerbose: null == isVerbose
          ? _self.isVerbose
          : isVerbose // ignore: cast_nullable_to_non_nullable
              as bool,
      language: null == language
          ? _self.language
          : language // ignore: cast_nullable_to_non_nullable
              as String,
      isSpecialTokens: null == isSpecialTokens
          ? _self.isSpecialTokens
          : isSpecialTokens // ignore: cast_nullable_to_non_nullable
              as bool,
      isNoTimestamps: null == isNoTimestamps
          ? _self.isNoTimestamps
          : isNoTimestamps // ignore: cast_nullable_to_non_nullable
              as bool,
      isRealtime: null == isRealtime
          ? _self.isRealtime
          : isRealtime // ignore: cast_nullable_to_non_nullable
              as bool,
      nProcessors: null == nProcessors
          ? _self.nProcessors
          : nProcessors // ignore: cast_nullable_to_non_nullable
              as int,
      splitOnWord: null == splitOnWord
          ? _self.splitOnWord
          : splitOnWord // ignore: cast_nullable_to_non_nullable
              as bool,
      noFallback: null == noFallback
          ? _self.noFallback
          : noFallback // ignore: cast_nullable_to_non_nullable
              as bool,
      diarize: null == diarize
          ? _self.diarize
          : diarize // ignore: cast_nullable_to_non_nullable
              as bool,
      speedUp: null == speedUp
          ? _self.speedUp
          : speedUp // ignore: cast_nullable_to_non_nullable
              as bool,
      vadMode: null == vadMode
          ? _self.vadMode
          : vadMode // ignore: cast_nullable_to_non_nullable
              as WhisperVadMode,
      vadModelPath: freezed == vadModelPath
          ? _self.vadModelPath
          : vadModelPath // ignore: cast_nullable_to_non_nullable
              as String?,
      realtimeStream: freezed == realtimeStream
          ? _self.realtimeStream
          : realtimeStream // ignore: cast_nullable_to_non_nullable
              as Stream<String>?,
    ));
  }
}

/// Adds pattern-matching-related methods to [TranscribeRequest].
extension TranscribeRequestPatterns on TranscribeRequest {
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
    TResult Function(_TranscribeRequest value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _TranscribeRequest() when $default != null:
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
    TResult Function(_TranscribeRequest value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TranscribeRequest():
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
    TResult? Function(_TranscribeRequest value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TranscribeRequest() when $default != null:
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
            String audio,
            bool isTranslate,
            int threads,
            bool isVerbose,
            String language,
            bool isSpecialTokens,
            bool isNoTimestamps,
            bool isRealtime,
            int nProcessors,
            bool splitOnWord,
            bool noFallback,
            bool diarize,
            bool speedUp,
            WhisperVadMode vadMode,
            String? vadModelPath,
            Stream<String>? realtimeStream)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _TranscribeRequest() when $default != null:
        return $default(
            _that.audio,
            _that.isTranslate,
            _that.threads,
            _that.isVerbose,
            _that.language,
            _that.isSpecialTokens,
            _that.isNoTimestamps,
            _that.isRealtime,
            _that.nProcessors,
            _that.splitOnWord,
            _that.noFallback,
            _that.diarize,
            _that.speedUp,
            _that.vadMode,
            _that.vadModelPath,
            _that.realtimeStream);
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
            String audio,
            bool isTranslate,
            int threads,
            bool isVerbose,
            String language,
            bool isSpecialTokens,
            bool isNoTimestamps,
            bool isRealtime,
            int nProcessors,
            bool splitOnWord,
            bool noFallback,
            bool diarize,
            bool speedUp,
            WhisperVadMode vadMode,
            String? vadModelPath,
            Stream<String>? realtimeStream)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TranscribeRequest():
        return $default(
            _that.audio,
            _that.isTranslate,
            _that.threads,
            _that.isVerbose,
            _that.language,
            _that.isSpecialTokens,
            _that.isNoTimestamps,
            _that.isRealtime,
            _that.nProcessors,
            _that.splitOnWord,
            _that.noFallback,
            _that.diarize,
            _that.speedUp,
            _that.vadMode,
            _that.vadModelPath,
            _that.realtimeStream);
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
            String audio,
            bool isTranslate,
            int threads,
            bool isVerbose,
            String language,
            bool isSpecialTokens,
            bool isNoTimestamps,
            bool isRealtime,
            int nProcessors,
            bool splitOnWord,
            bool noFallback,
            bool diarize,
            bool speedUp,
            WhisperVadMode vadMode,
            String? vadModelPath,
            Stream<String>? realtimeStream)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TranscribeRequest() when $default != null:
        return $default(
            _that.audio,
            _that.isTranslate,
            _that.threads,
            _that.isVerbose,
            _that.language,
            _that.isSpecialTokens,
            _that.isNoTimestamps,
            _that.isRealtime,
            _that.nProcessors,
            _that.splitOnWord,
            _that.noFallback,
            _that.diarize,
            _that.speedUp,
            _that.vadMode,
            _that.vadModelPath,
            _that.realtimeStream);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _TranscribeRequest extends TranscribeRequest {
  const _TranscribeRequest(
      {required this.audio,
      this.isTranslate = false,
      this.threads = 6,
      this.isVerbose = false,
      this.language = 'en',
      this.isSpecialTokens = false,
      this.isNoTimestamps = false,
      this.isRealtime = false,
      this.nProcessors = 1,
      this.splitOnWord = false,
      this.noFallback = false,
      this.diarize = false,
      this.speedUp = false,
      this.vadMode = WhisperVadMode.auto,
      this.vadModelPath,
      this.realtimeStream = null})
      : super._();

  @override
  final String audio;
  @override
  @JsonKey()
  final bool isTranslate;
  @override
  @JsonKey()
  final int threads;
  @override
  @JsonKey()
  final bool isVerbose;
  @override
  @JsonKey()
  final String language;
  @override
  @JsonKey()
  final bool isSpecialTokens;
  @override
  @JsonKey()
  final bool isNoTimestamps;
  @override
  @JsonKey()
  final bool isRealtime;
  @override
  @JsonKey()
  final int nProcessors;
  @override
  @JsonKey()
  final bool splitOnWord;
  @override
  @JsonKey()
  final bool noFallback;
  @override
  @JsonKey()
  final bool diarize;
  @override
  @JsonKey()
  final bool speedUp;
  @override
  @JsonKey()
  final WhisperVadMode vadMode;
  @override
  final String? vadModelPath;
  @override
  @JsonKey()
  final Stream<String>? realtimeStream;

  /// Create a copy of TranscribeRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$TranscribeRequestCopyWith<_TranscribeRequest> get copyWith =>
      __$TranscribeRequestCopyWithImpl<_TranscribeRequest>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _TranscribeRequest &&
            (identical(other.audio, audio) || other.audio == audio) &&
            (identical(other.isTranslate, isTranslate) ||
                other.isTranslate == isTranslate) &&
            (identical(other.threads, threads) || other.threads == threads) &&
            (identical(other.isVerbose, isVerbose) ||
                other.isVerbose == isVerbose) &&
            (identical(other.language, language) ||
                other.language == language) &&
            (identical(other.isSpecialTokens, isSpecialTokens) ||
                other.isSpecialTokens == isSpecialTokens) &&
            (identical(other.isNoTimestamps, isNoTimestamps) ||
                other.isNoTimestamps == isNoTimestamps) &&
            (identical(other.isRealtime, isRealtime) ||
                other.isRealtime == isRealtime) &&
            (identical(other.nProcessors, nProcessors) ||
                other.nProcessors == nProcessors) &&
            (identical(other.splitOnWord, splitOnWord) ||
                other.splitOnWord == splitOnWord) &&
            (identical(other.noFallback, noFallback) ||
                other.noFallback == noFallback) &&
            (identical(other.diarize, diarize) || other.diarize == diarize) &&
            (identical(other.speedUp, speedUp) || other.speedUp == speedUp) &&
            (identical(other.vadMode, vadMode) || other.vadMode == vadMode) &&
            (identical(other.vadModelPath, vadModelPath) ||
                other.vadModelPath == vadModelPath) &&
            (identical(other.realtimeStream, realtimeStream) ||
                other.realtimeStream == realtimeStream));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      audio,
      isTranslate,
      threads,
      isVerbose,
      language,
      isSpecialTokens,
      isNoTimestamps,
      isRealtime,
      nProcessors,
      splitOnWord,
      noFallback,
      diarize,
      speedUp,
      vadMode,
      vadModelPath,
      realtimeStream);

  @override
  String toString() {
    return 'TranscribeRequest(audio: $audio, isTranslate: $isTranslate, threads: $threads, isVerbose: $isVerbose, language: $language, isSpecialTokens: $isSpecialTokens, isNoTimestamps: $isNoTimestamps, isRealtime: $isRealtime, nProcessors: $nProcessors, splitOnWord: $splitOnWord, noFallback: $noFallback, diarize: $diarize, speedUp: $speedUp, vadMode: $vadMode, vadModelPath: $vadModelPath, realtimeStream: $realtimeStream)';
  }
}

/// @nodoc
abstract mixin class _$TranscribeRequestCopyWith<$Res>
    implements $TranscribeRequestCopyWith<$Res> {
  factory _$TranscribeRequestCopyWith(
          _TranscribeRequest value, $Res Function(_TranscribeRequest) _then) =
      __$TranscribeRequestCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String audio,
      bool isTranslate,
      int threads,
      bool isVerbose,
      String language,
      bool isSpecialTokens,
      bool isNoTimestamps,
      bool isRealtime,
      int nProcessors,
      bool splitOnWord,
      bool noFallback,
      bool diarize,
      bool speedUp,
      WhisperVadMode vadMode,
      String? vadModelPath,
      Stream<String>? realtimeStream});
}

/// @nodoc
class __$TranscribeRequestCopyWithImpl<$Res>
    implements _$TranscribeRequestCopyWith<$Res> {
  __$TranscribeRequestCopyWithImpl(this._self, this._then);

  final _TranscribeRequest _self;
  final $Res Function(_TranscribeRequest) _then;

  /// Create a copy of TranscribeRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? audio = null,
    Object? isTranslate = null,
    Object? threads = null,
    Object? isVerbose = null,
    Object? language = null,
    Object? isSpecialTokens = null,
    Object? isNoTimestamps = null,
    Object? isRealtime = null,
    Object? nProcessors = null,
    Object? splitOnWord = null,
    Object? noFallback = null,
    Object? diarize = null,
    Object? speedUp = null,
    Object? vadMode = null,
    Object? vadModelPath = freezed,
    Object? realtimeStream = freezed,
  }) {
    return _then(_TranscribeRequest(
      audio: null == audio
          ? _self.audio
          : audio // ignore: cast_nullable_to_non_nullable
              as String,
      isTranslate: null == isTranslate
          ? _self.isTranslate
          : isTranslate // ignore: cast_nullable_to_non_nullable
              as bool,
      threads: null == threads
          ? _self.threads
          : threads // ignore: cast_nullable_to_non_nullable
              as int,
      isVerbose: null == isVerbose
          ? _self.isVerbose
          : isVerbose // ignore: cast_nullable_to_non_nullable
              as bool,
      language: null == language
          ? _self.language
          : language // ignore: cast_nullable_to_non_nullable
              as String,
      isSpecialTokens: null == isSpecialTokens
          ? _self.isSpecialTokens
          : isSpecialTokens // ignore: cast_nullable_to_non_nullable
              as bool,
      isNoTimestamps: null == isNoTimestamps
          ? _self.isNoTimestamps
          : isNoTimestamps // ignore: cast_nullable_to_non_nullable
              as bool,
      isRealtime: null == isRealtime
          ? _self.isRealtime
          : isRealtime // ignore: cast_nullable_to_non_nullable
              as bool,
      nProcessors: null == nProcessors
          ? _self.nProcessors
          : nProcessors // ignore: cast_nullable_to_non_nullable
              as int,
      splitOnWord: null == splitOnWord
          ? _self.splitOnWord
          : splitOnWord // ignore: cast_nullable_to_non_nullable
              as bool,
      noFallback: null == noFallback
          ? _self.noFallback
          : noFallback // ignore: cast_nullable_to_non_nullable
              as bool,
      diarize: null == diarize
          ? _self.diarize
          : diarize // ignore: cast_nullable_to_non_nullable
              as bool,
      speedUp: null == speedUp
          ? _self.speedUp
          : speedUp // ignore: cast_nullable_to_non_nullable
              as bool,
      vadMode: null == vadMode
          ? _self.vadMode
          : vadMode // ignore: cast_nullable_to_non_nullable
              as WhisperVadMode,
      vadModelPath: freezed == vadModelPath
          ? _self.vadModelPath
          : vadModelPath // ignore: cast_nullable_to_non_nullable
              as String?,
      realtimeStream: freezed == realtimeStream
          ? _self.realtimeStream
          : realtimeStream // ignore: cast_nullable_to_non_nullable
              as Stream<String>?,
    ));
  }
}

// dart format on
