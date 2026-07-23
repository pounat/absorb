String normalizeServerUrl(String value) {
  var url = value.trim().replaceAll(RegExp(r'\s+'), '');
  if (url.isEmpty) return '';

  if (!RegExp(r'^https?://', caseSensitive: false).hasMatch(url)) {
    url = 'http://$url';
  }

  return url.replaceAll(RegExp(r'/+$'), '');
}
