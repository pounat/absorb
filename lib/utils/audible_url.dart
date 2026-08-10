String audibleDomainForCountryCode(String? countryCode) {
  const domains = {
    'US': 'audible.com',
    'GB': 'audible.co.uk',
    'AU': 'audible.com.au',
    'CA': 'audible.ca',
    'DE': 'audible.de',
    'FR': 'audible.fr',
    'IT': 'audible.it',
    'ES': 'audible.es',
    'JP': 'audible.co.jp',
    'IN': 'audible.in',
    'BR': 'audible.com.br',
  };

  return domains[countryCode?.toUpperCase()] ?? 'audible.com';
}

Uri audibleReviewsUri(String asin, {String? countryCode}) {
  final domain = audibleDomainForCountryCode(countryCode);
  return Uri(
    scheme: 'https',
    host: 'www.$domain',
    pathSegments: ['pd', asin],
    fragment: 'customer-reviews',
  );
}
