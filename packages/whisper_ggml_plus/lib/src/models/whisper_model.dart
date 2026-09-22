/// Available whisper models
enum WhisperModel {
  /// tiny model for all languages
  tiny('tiny'),

  /// base model for all languages
  base('base'),

  /// small model for all languages
  small('small'),

  /// medium model for all languages
  medium('medium'),

  /// large model for all languages
  large('large-v3'),

  /// large-v3-turbo model for all languages
  largeV3Turbo('large-v3-turbo'),

  /// tiny model for english only
  tinyEn('tiny.en'),

  /// base model for english only
  baseEn('base.en'),

  /// small model for english only
  smallEn('small.en'),

  /// medium model for english only
  mediumEn('medium.en');

  const WhisperModel(this.modelName);

  /// Public name of model
  final String modelName;

  /// Huggingface url to download model
  Uri get modelUri {
    return Uri.parse(
      'https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-$modelName.bin',
    );
  }
}
