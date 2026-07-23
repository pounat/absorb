String? safeCarPlayImageUrl(String? value) {
  if (value == null || value.isEmpty || RegExp(r'\s').hasMatch(value)) {
    return null;
  }

  try {
    final uri = Uri.tryParse(value);
    if (uri == null) return null;

    if (uri.scheme == 'file') {
      return uri.pathSegments.isNotEmpty ? value : null;
    }

    if ((uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty) {
      uri.port;
      return value;
    }
  } on FormatException {
    return null;
  }

  return null;
}
