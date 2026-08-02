class UpdateReleaseAsset {
  final String name;
  final String downloadUrl;

  const UpdateReleaseAsset({
    required this.name,
    required this.downloadUrl,
  });
}

const supportedAndroidUpdateAbis = <String>{
  'armeabi-v7a',
  'arm64-v8a',
  'x86_64',
};

UpdateReleaseAsset? selectAndroidUpdateAsset({
  required List<UpdateReleaseAsset> assets,
  required List<String> supportedAbis,
}) {
  final apks = assets
      .where((asset) => asset.name.toLowerCase().endsWith('.apk'))
      .toList();

  for (final abi in supportedAbis.map((value) => value.toLowerCase())) {
    if (!supportedAndroidUpdateAbis.contains(abi)) continue;
    for (final asset in apks) {
      if (_hasFilenameToken(asset.name, abi)) return asset;
    }
  }

  for (final asset in apks) {
    if (_hasFilenameToken(asset.name, 'universal')) return asset;
  }

  if (apks.length == 1 &&
      !supportedAndroidUpdateAbis.any(
        (abi) => _hasFilenameToken(apks.single.name, abi),
      )) {
    return apks.single;
  }
  return null;
}

String currentUpdateVersion({
  required String versionName,
  required String packageBuildNumber,
  int? baseBuildNumber,
}) {
  final build = baseBuildNumber != null && baseBuildNumber > 0
      ? baseBuildNumber.toString()
      : packageBuildNumber;
  return '$versionName+$build';
}

int compareUpdateVersions(String a, String b) {
  final (aSem, aBuild) = _parseVersion(a);
  final (bSem, bBuild) = _parseVersion(b);
  for (int i = 0; i < 3; i++) {
    if (aSem[i] != bSem[i]) return aSem[i] - bSem[i];
  }
  if (aBuild != null && bBuild != null) return aBuild - bBuild;
  return 0;
}

String androidUpdatePackageLabel(UpdateReleaseAsset asset) {
  var packageKind = 'Universal';
  for (final abi in supportedAndroidUpdateAbis) {
    if (_hasFilenameToken(asset.name, abi)) {
      packageKind = abi;
      break;
    }
  }

  final build = RegExp(
    r'-(\d+)-(?:universal|armeabi-v7a|arm64-v8a|x86_64)(?:-pre)?\.apk$',
    caseSensitive: false,
  ).firstMatch(asset.name)?.group(1);
  return build == null
      ? '$packageKind APK'
      : '$packageKind APK • build $build';
}

bool _hasFilenameToken(String filename, String token) {
  final pattern = RegExp(
    '(^|[-_.])${RegExp.escape(token)}(?=[-_.]|\$)',
    caseSensitive: false,
  );
  return pattern.hasMatch(filename);
}

(List<int>, int?) _parseVersion(String version) {
  final sem = RegExp(r'(\d+)\.(\d+)\.(\d+)').firstMatch(version);
  final parts = [
    for (var i = 1; i <= 3; i++) int.parse(sem?.group(i) ?? '0'),
  ];
  final build = RegExp(r'[-+](\d+)$').firstMatch(version);
  return (parts, build == null ? null : int.parse(build.group(1)!));
}
