/// Which beta of the current release cycle this build belongs to. Bump it in
/// the same commit as the version bump for each beta. Full releases use an
/// even patch number and never show it, so a stale value can't leak into a
/// stable build - it only has to be right during a beta cycle.
const int kBetaNumber = 6;

/// The beta number to show for [version] (`1.9.3+240` or `1.9.3`), or null
/// when this isn't a beta build. Odd patch = beta cycle, even = full release.
int? betaNumberFor(String version) {
  final parts = version.split('+').first.split('.');
  if (parts.length < 3) return null;
  final patch = int.tryParse(parts[2]);
  if (patch == null || patch.isEven || kBetaNumber <= 0) return null;
  return kBetaNumber;
}

/// `1.9.3+240 (Beta 6)` for logs and other unlocalized places; the settings
/// screen formats its own copy through l10n.
String versionWithBeta(String version) {
  final beta = betaNumberFor(version);
  return beta == null ? version : '$version (Beta $beta)';
}
