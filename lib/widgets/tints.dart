/// The only strengths an accent-colored background comes in. The accent is
/// for things that are on, selected or in progress; everything else is gray.
abstract final class Tints {
  /// Hover and pressed washes, the track behind a progress bar.
  static const double faint = 0.08;

  /// The background of something selected or switched on.
  static const double soft = 0.14;

  /// A selected thing that has to stand out from other tinted things.
  static const double strong = 0.24;
}
