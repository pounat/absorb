class MediaCardGesturePolicy {
  const MediaCardGesturePolicy({required this.isWeb});

  final bool isWeb;

  bool get allowsLongPressShortcuts => !isWeb;

  bool get continueListeningTapOpensDetails => isWeb;
}
