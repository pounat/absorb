// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'transcribe_request_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TranscribeRequestDto {
  String get audio;
  String get model;
  @JsonKey(name: 'is_translate')
  bool get isTranslate;
  int get threads;
  @JsonKey(name: 'is_verbose')
  bool get isVerbose;
  String get language;
  @JsonKey(name: 'is_special_tokens')
  bool get isSpecialTokens;
  @JsonKey(name: 'is_no_timestamps')
  bool get isNoTimestamps;
  @JsonKey(name: 'n_processors')
  int get nProcessors;
  @JsonKey(name: 'split_on_word')
  bool get splitOnWord;
  @JsonKey(name: 'no_fallback')
  bool get noFallback;
  @JsonKey(name: 'is_realtime')
  bool get isRealtime;
  bool get diarize;
  @JsonKey(name: 'speed_up')
  bool get speedUp;
  @JsonKey(name: 'vad_mode')
  String get vadMode;
  @JsonKey(name: 'vad_model_path')
  String? get vadModelPath;

  /// Create a copy of TranscribeRequestDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $TranscribeRequestDtoCopyWith<TranscribeRequestDto> get copyWith =>
      _$TranscribeRequestDtoCopyWithImpl<TranscribeRequestDto>(
          this as TranscribeRequestDto, _$identity);

  /// Serializes this TranscribeRequestDto to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is TranscribeRequestDto &&
            (identical(other.audio, audio) || other.audio == audio) &&
            (identical(other.model, model) || other.model == model) &&
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
            (identical(other.nProcessors, nProcessors) ||
                other.nProcessors == nProcessors) &&
            (identical(other.splitOnWord, splitOnWord) ||
                other.splitOnWord == splitOnWord) &&
            (identical(other.noFallback, noFallback) ||
                other.noFallback == noFallback) &&
            (identical(other.isRealtime, isRealtime) ||
                other.isRealtime == isRealtime) &&
            (identical(other.diarize, diarize) || other.diarize == diarize) &&
            (identical(other.speedUp, speedUp) || other.speedUp == speedUp) &&
            (identical(other.vadMode, vadMode) || other.vadMode == vadMode) &&
            (identical(other.vadModelPath, vadModelPath) ||
                other.vadModelPath == vadModelPath));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      audio,
      model,
      isTranslate,
      threads,
      isVerbose,
      language,
      isSpecialTokens,
      isNoTimestamps,
      nProcessors,
      splitOnWord,
      noFallback,
      isRealtime,
      diarize,
      speedUp,
      vadMode,
      vadModelPath);

  @override
  String toString() {
    return 'TranscribeRequestDto(audio: $audio, model: $model, isTranslate: $isTranslate, threads: $threads, isVerbose: $isVerbose, language: $language, isSpecialTokens: $isSpecialTokens, isNoTimestamps: $isNoTimestamps, nProcessors: $nProcessors, splitOnWord: $splitOnWord, noFallback: $noFallback, isRealtime: $isRealtime, diarize: $diarize, speedUp: $speedUp, vadMode: $vadMode, vadModelPath: $vadModelPath)';
  }
}

/// @nodoc
abstract mixin class $TranscribeRequestDtoCopyWith<$Res> {
  factory $TranscribeRequestDtoCopyWith(TranscribeRequestDto value,
          $Res Function(TranscribeRequestDto) _then) =
      _$TranscribeRequestDtoCopyWithImpl;
  @useResult
  $Res call(
      {String audio,
      String model,
      @JsonKey(name: 'is_translate') bool isTranslate,
      int threads,
      @JsonKey(name: 'is_verbose') bool isVerbose,
      String language,
      @JsonKey(name: 'is_special_tokens') bool isSpecialTokens,
      @JsonKey(name: 'is_no_timestamps') bool isNoTimestamps,
      @JsonKey(name: 'n_processors') int nProcessors,
      @JsonKey(name: 'split_on_word') bool splitOnWord,
      @JsonKey(name: 'no_fallback') bool noFallback,
      @JsonKey(name: 'is_realtime') bool isRealtime,
      bool diarize,
      @JsonKey(name: 'speed_up') bool speedUp,
      @JsonKey(name: 'vad_mode') String vadMode,
      @JsonKey(name: 'vad_model_path') String? vadModelPath});
}

/// @nodoc
class _$TranscribeRequestDtoCopyWithImpl<$Res>
    implements $TranscribeRequestDtoCopyWith<$Res> {
  _$TranscribeRequestDtoCopyWithImpl(this._self, this._then);

  final TranscribeRequestDto _self;
  final $Res Function(TranscribeRequestDto) _then;

  /// Create a copy of TranscribeRequestDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? audio = null,
    Object? model = null,
    Object? isTranslate = null,
    Object? threads = null,
    Object? isVerbose = null,
    Object? language = null,
    Object? isSpecialTokens = null,
    Object? isNoTimestamps = null,
    Object? nProcessors = null,
    Object? splitOnWord = null,
    Object? noFallback = null,
    Object? isRealtime = null,
    Object? diarize = null,
    Object? speedUp = null,
    Object? vadMode = null,
    Object? vadModelPath = freezed,
  }) {
    return _then(_self.copyWith(
      audio: null == audio
          ? _self.audio
          : audio // ignore: cast_nullable_to_non_nullable
              as String,
      model: null == model
          ? _self.model
          : model // ignore: cast_nullable_to_non_nullable
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
      isRealtime: null == isRealtime
          ? _self.isRealtime
          : isRealtime // ignore: cast_nullable_to_non_nullable
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
              as String,
      vadModelPath: freezed == vadModelPath
          ? _self.vadModelPath
          : vadModelPath // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// Adds pattern-matching-related methods to [TranscribeRequestDto].
extension TranscribeRequestDtoPatterns on TranscribeRequestDto {
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
    TResult Function(_TranscribeRequestDto value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _TranscribeRequestDto() when $default != null:
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
    TResult Function(_TranscribeRequestDto value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TranscribeRequestDto():
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
    TResult? Function(_TranscribeRequestDto value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TranscribeRequestDto() when $default != null:
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
            String model,
            @JsonKey(name: 'is_translate') bool isTranslate,
            int threads,
            @JsonKey(name: 'is_verbose') bool isVerbose,
            String language,
            @JsonKey(name: 'is_special_tokens') bool isSpecialTokens,
            @JsonKey(name: 'is_no_timestamps') bool isNoTimestamps,
            @JsonKey(name: 'n_processors') int nProcessors,
            @JsonKey(name: 'split_on_word') bool splitOnWord,
            @JsonKey(name: 'no_fallback') bool noFallback,
            @JsonKey(name: 'is_realtime') bool isRealtime,
            bool diarize,
            @JsonKey(name: 'speed_up') bool speedUp,
            @JsonKey(name: 'vad_mode') String vadMode,
            @JsonKey(name: 'vad_model_path') String? vadModelPath)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _TranscribeRequestDto() when $default != null:
        return $default(
            _that.audio,
            _that.model,
            _that.isTranslate,
            _that.threads,
            _that.isVerbose,
            _that.language,
            _that.isSpecialTokens,
            _that.isNoTimestamps,
            _that.nProcessors,
            _that.splitOnWord,
            _that.noFallback,
            _that.isRealtime,
            _that.diarize,
            _that.speedUp,
            _that.vadMode,
            _that.vadModelPath);
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
            String model,
            @JsonKey(name: 'is_translate') bool isTranslate,
            int threads,
            @JsonKey(name: 'is_verbose') bool isVerbose,
            String language,
            @JsonKey(name: 'is_special_tokens') bool isSpecialTokens,
            @JsonKey(name: 'is_no_timestamps') bool isNoTimestamps,
            @JsonKey(name: 'n_processors') int nProcessors,
            @JsonKey(name: 'split_on_word') bool splitOnWord,
            @JsonKey(name: 'no_fallback') bool noFallback,
            @JsonKey(name: 'is_realtime') bool isRealtime,
            bool diarize,
            @JsonKey(name: 'speed_up') bool speedUp,
            @JsonKey(name: 'vad_mode') String vadMode,
            @JsonKey(name: 'vad_model_path') String? vadModelPath)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TranscribeRequestDto():
        return $default(
            _that.audio,
            _that.model,
            _that.isTranslate,
            _that.threads,
            _that.isVerbose,
            _that.language,
            _that.isSpecialTokens,
            _that.isNoTimestamps,
            _that.nProcessors,
            _that.splitOnWord,
            _that.noFallback,
            _that.isRealtime,
            _that.diarize,
            _that.speedUp,
            _that.vadMode,
            _that.vadModelPath);
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
            String model,
            @JsonKey(name: 'is_translate') bool isTranslate,
            int threads,
            @JsonKey(name: 'is_verbose') bool isVerbose,
            String language,
            @JsonKey(name: 'is_special_tokens') bool isSpecialTokens,
            @JsonKey(name: 'is_no_timestamps') bool isNoTimestamps,
            @JsonKey(name: 'n_processors') int nProcessors,
            @JsonKey(name: 'split_on_word') bool splitOnWord,
            @JsonKey(name: 'no_fallback') bool noFallback,
            @JsonKey(name: 'is_realtime') bool isRealtime,
            bool diarize,
            @JsonKey(name: 'speed_up') bool speedUp,
            @JsonKey(name: 'vad_mode') String vadMode,
            @JsonKey(name: 'vad_model_path') String? vadModelPath)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TranscribeRequestDto() when $default != null:
        return $default(
            _that.audio,
            _that.model,
            _that.isTranslate,
            _that.threads,
            _that.isVerbose,
            _that.language,
            _that.isSpecialTokens,
            _that.isNoTimestamps,
            _that.nProcessors,
            _that.splitOnWord,
            _that.noFallback,
            _that.isRealtime,
            _that.diarize,
            _that.speedUp,
            _that.vadMode,
            _that.vadModelPath);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _TranscribeRequestDto extends TranscribeRequestDto {
  const _TranscribeRequestDto(
      {required this.audio,
      required this.model,
      @JsonKey(name: 'is_translate') required this.isTranslate,
      required this.threads,
      @JsonKey(name: 'is_verbose') required this.isVerbose,
      required this.language,
      @JsonKey(name: 'is_special_tokens') required this.isSpecialTokens,
      @JsonKey(name: 'is_no_timestamps') required this.isNoTimestamps,
      @JsonKey(name: 'n_processors') required this.nProcessors,
      @JsonKey(name: 'split_on_word') required this.splitOnWord,
      @JsonKey(name: 'no_fallback') required this.noFallback,
      @JsonKey(name: 'is_realtime') required this.isRealtime,
      required this.diarize,
      @JsonKey(name: 'speed_up') required this.speedUp,
      @JsonKey(name: 'vad_mode') required this.vadMode,
      @JsonKey(name: 'vad_model_path') this.vadModelPath})
      : super._();
  factory _TranscribeRequestDto.fromJson(Map<String, dynamic> json) =>
      _$TranscribeRequestDtoFromJson(json);

  @override
  final String audio;
  @override
  final String model;
  @override
  @JsonKey(name: 'is_translate')
  final bool isTranslate;
  @override
  final int threads;
  @override
  @JsonKey(name: 'is_verbose')
  final bool isVerbose;
  @override
  final String language;
  @override
  @JsonKey(name: 'is_special_tokens')
  final bool isSpecialTokens;
  @override
  @JsonKey(name: 'is_no_timestamps')
  final bool isNoTimestamps;
  @override
  @JsonKey(name: 'n_processors')
  final int nProcessors;
  @override
  @JsonKey(name: 'split_on_word')
  final bool splitOnWord;
  @override
  @JsonKey(name: 'no_fallback')
  final bool noFallback;
  @override
  @JsonKey(name: 'is_realtime')
  final bool isRealtime;
  @override
  final bool diarize;
  @override
  @JsonKey(name: 'speed_up')
  final bool speedUp;
  @override
  @JsonKey(name: 'vad_mode')
  final String vadMode;
  @override
  @JsonKey(name: 'vad_model_path')
  final String? vadModelPath;

  /// Create a copy of TranscribeRequestDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$TranscribeRequestDtoCopyWith<_TranscribeRequestDto> get copyWith =>
      __$TranscribeRequestDtoCopyWithImpl<_TranscribeRequestDto>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$TranscribeRequestDtoToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _TranscribeRequestDto &&
            (identical(other.audio, audio) || other.audio == audio) &&
            (identical(other.model, model) || other.model == model) &&
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
            (identical(other.nProcessors, nProcessors) ||
                other.nProcessors == nProcessors) &&
            (identical(other.splitOnWord, splitOnWord) ||
                other.splitOnWord == splitOnWord) &&
            (identical(other.noFallback, noFallback) ||
                other.noFallback == noFallback) &&
            (identical(other.isRealtime, isRealtime) ||
                other.isRealtime == isRealtime) &&
            (identical(other.diarize, diarize) || other.diarize == diarize) &&
            (identical(other.speedUp, speedUp) || other.speedUp == speedUp) &&
            (identical(other.vadMode, vadMode) || other.vadMode == vadMode) &&
            (identical(other.vadModelPath, vadModelPath) ||
                other.vadModelPath == vadModelPath));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      audio,
      model,
      isTranslate,
      threads,
      isVerbose,
      language,
      isSpecialTokens,
      isNoTimestamps,
      nProcessors,
      splitOnWord,
      noFallback,
      isRealtime,
      diarize,
      speedUp,
      vadMode,
      vadModelPath);

  @override
  String toString() {
    return 'TranscribeRequestDto(audio: $audio, model: $model, isTranslate: $isTranslate, threads: $threads, isVerbose: $isVerbose, language: $language, isSpecialTokens: $isSpecialTokens, isNoTimestamps: $isNoTimestamps, nProcessors: $nProcessors, splitOnWord: $splitOnWord, noFallback: $noFallback, isRealtime: $isRealtime, diarize: $diarize, speedUp: $speedUp, vadMode: $vadMode, vadModelPath: $vadModelPath)';
  }
}

/// @nodoc
abstract mixin class _$TranscribeRequestDtoCopyWith<$Res>
    implements $TranscribeRequestDtoCopyWith<$Res> {
  factory _$TranscribeRequestDtoCopyWith(_TranscribeRequestDto value,
          $Res Function(_TranscribeRequestDto) _then) =
      __$TranscribeRequestDtoCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String audio,
      String model,
      @JsonKey(name: 'is_translate') bool isTranslate,
      int threads,
      @JsonKey(name: 'is_verbose') bool isVerbose,
      String language,
      @JsonKey(name: 'is_special_tokens') bool isSpecialTokens,
      @JsonKey(name: 'is_no_timestamps') bool isNoTimestamps,
      @JsonKey(name: 'n_processors') int nProcessors,
      @JsonKey(name: 'split_on_word') bool splitOnWord,
      @JsonKey(name: 'no_fallback') bool noFallback,
      @JsonKey(name: 'is_realtime') bool isRealtime,
      bool diarize,
      @JsonKey(name: 'speed_up') bool speedUp,
      @JsonKey(name: 'vad_mode') String vadMode,
      @JsonKey(name: 'vad_model_path') String? vadModelPath});
}

/// @nodoc
class __$TranscribeRequestDtoCopyWithImpl<$Res>
    implements _$TranscribeRequestDtoCopyWith<$Res> {
  __$TranscribeRequestDtoCopyWithImpl(this._self, this._then);

  final _TranscribeRequestDto _self;
  final $Res Function(_TranscribeRequestDto) _then;

  /// Create a copy of TranscribeRequestDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? audio = null,
    Object? model = null,
    Object? isTranslate = null,
    Object? threads = null,
    Object? isVerbose = null,
    Object? language = null,
    Object? isSpecialTokens = null,
    Object? isNoTimestamps = null,
    Object? nProcessors = null,
    Object? splitOnWord = null,
    Object? noFallback = null,
    Object? isRealtime = null,
    Object? diarize = null,
    Object? speedUp = null,
    Object? vadMode = null,
    Object? vadModelPath = freezed,
  }) {
    return _then(_TranscribeRequestDto(
      audio: null == audio
          ? _self.audio
          : audio // ignore: cast_nullable_to_non_nullable
              as String,
      model: null == model
          ? _self.model
          : model // ignore: cast_nullable_to_non_nullable
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
      isRealtime: null == isRealtime
          ? _self.isRealtime
          : isRealtime // ignore: cast_nullable_to_non_nullable
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
              as String,
      vadModelPath: freezed == vadModelPath
          ? _self.vadModelPath
          : vadModelPath // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

// dart format on
