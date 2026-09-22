/// Enum representing RFC 5646 language codes.
///
/// This enum contains language codes following the RFC 5646 standard
/// for identifying languages and language variants.
enum Rfc5646Language {
  /// Afrikaans language.
  afrikaans('af'),

  /// Afrikaans as spoken in South Africa.
  afrikaansSouthAfrica('af-ZA'),

  /// Arabic language.
  arabic('ar'),

  /// Arabic as spoken in United Arab Emirates.
  arabicUae('ar-AE'),

  /// Arabic as spoken in Bahrain.
  arabicBahrain('ar-BH'),

  /// Arabic as spoken in Algeria.
  arabicAlgeria('ar-DZ'),

  /// Arabic as spoken in Egypt.
  arabicEgypt('ar-EG'),

  /// Arabic as spoken in Iraq.
  arabicIraq('ar-IQ'),

  /// Arabic as spoken in Jordan.
  arabicJordan('ar-JO'),

  /// Arabic as spoken in Kuwait.
  arabicKuwait('ar-KW'),

  /// Arabic as spoken in Lebanon.
  arabicLebanon('ar-LB'),

  /// Arabic as spoken in Libya.
  arabicLibya('ar-LY'),

  /// Arabic as spoken in Morocco.
  arabicMorocco('ar-MA'),

  /// Arabic as spoken in Oman.
  arabicOman('ar-OM'),

  /// Arabic as spoken in Qatar.
  arabicQatar('ar-QA'),

  /// Arabic as spoken in Saudi Arabia.
  arabicSaudiArabia('ar-SA'),

  /// Arabic as spoken in Syria.
  arabicSyria('ar-SY'),

  /// Arabic as spoken in Tunisia.
  arabicTunisia('ar-TN'),

  /// Arabic as spoken in Yemen.
  arabicYemen('ar-YE'),

  /// Azeri Latin script.
  azeriLatin('az'),

  /// Azeri Latin script as used in Azerbaijan.
  azeriLatinAzerbaijan('az-AZ'),

  /// Azeri Cyrillic script as used in Azerbaijan.
  azeriCyrillicAzerbaijan('az-Cyrl-AZ'),

  /// Belarusian language.
  belarusian('be'),

  /// Belarusian as spoken in Belarus.
  belarusianBelarus('be-BY'),

  /// Bulgarian language.
  bulgarian('bg'),

  /// Bulgarian as spoken in Bulgaria.
  bulgarianBulgaria('bg-BG'),

  /// Bosnian as spoken in Bosnia and Herzegovina.
  bosnianBosniaAndHerzegovina('bs-BA'),

  /// Catalan language.
  catalan('ca'),

  /// Catalan as spoken in Spain.
  catalanSpain('ca-ES'),

  /// Czech language.
  czech('cs'),

  /// Czech as spoken in Czech Republic.
  czechCzechRepublic('cs-CZ'),

  /// Welsh language.
  welsh('cy'),

  /// Welsh as spoken in United Kingdom.
  welshUnitedKingdom('cy-GB'),

  /// Danish language.
  danish('da'),

  /// Danish as spoken in Denmark.
  danishDenmark('da-DK'),

  /// German language.
  german('de'),

  /// German as spoken in Austria.
  germanAustria('de-AT'),

  /// German as spoken in Switzerland.
  germanSwitzerland('de-CH'),

  /// German as spoken in Germany.
  germanGermany('de-DE'),

  /// German as spoken in Liechtenstein.
  germanLiechtenstein('de-LI'),

  /// German as spoken in Luxembourg.
  germanLuxembourg('de-LU'),

  /// Divehi language.
  divehi('dv'),

  /// Divehi as spoken in Maldives.
  divehiMaldives('dv-MV'),

  /// Greek language.
  greek('el'),

  /// Greek as spoken in Greece.
  greekGreece('el-GR'),

  /// English language.
  english('en'),

  /// English as spoken in Australia.
  englishAustralia('en-AU'),

  /// English as spoken in Belize.
  englishBelize('en-BZ'),

  /// English as spoken in Canada.
  englishCanada('en-CA'),

  /// English as spoken in Caribbean.
  englishCaribbean('en-CB'),

  /// English as spoken in United Kingdom.
  englishUnitedKingdom('en-GB'),

  /// English as spoken in Ireland.
  englishIreland('en-IE'),

  /// English as spoken in Jamaica.
  englishJamaica('en-JM'),

  /// English as spoken in New Zealand.
  englishNewZealand('en-NZ'),

  /// English as spoken in Republic of the Philippines.
  englishRepublicOfThePhilippines('en-PH'),

  /// English as spoken in Trinidad and Tobago.
  englishTrinidadAndTobago('en-TT'),

  /// English as spoken in United States.
  englishUnitedStates('en-US'),

  /// English as spoken in South Africa.
  englishSouthAfrica('en-ZA'),

  /// English as spoken in Zimbabwe.
  englishZimbabwe('en-ZW'),

  /// Esperanto language.
  esperanto('eo'),

  /// Spanish language.
  spanish('es'),

  /// Spanish as spoken in Argentina.
  spanishArgentina('es-AR'),

  /// Spanish as spoken in Bolivia.
  spanishBolivia('es-BO'),

  /// Spanish as spoken in USA.
  spanishEua('es-US'),

  /// Spanish as spoken in Chile.
  spanishChile('es-CL'),

  /// Spanish as spoken in Colombia.
  spanishColombia('es-CO'),

  /// Spanish as spoken in Costa Rica.
  spanishCostaRica('es-CR'),

  /// Spanish as spoken in the Dominican Republic.
  spanishDominicanRepublic('es-DO'),

  /// Spanish as spoken in Ecuador.
  spanishEcuador('es-EC'),

  /// Spanish as spoken in Spain.
  spanishSpain('es-ES'),

  /// Spanish as spoken in Guatemala.
  spanishGuatemala('es-GT'),

  /// Spanish as spoken in Honduras.
  spanishHonduras('es-HN'),

  /// Spanish as spoken in Mexico.
  spanishMexico('es-MX'),

  /// Spanish as spoken in Nicaragua.
  spanishNicaragua('es-NI'),

  /// Spanish as spoken in Panama.
  spanishPanama('es-PA'),

  /// Spanish as spoken in Peru.
  spanishPeru('es-PE'),

  /// Spanish as spoken in Puerto Rico.
  spanishPuertoRico('es-PR'),

  /// Spanish as spoken in Paraguay.
  spanishParaguay('es-PY'),

  /// Spanish as spoken in El Salvador.
  spanishElSalvador('es-SV'),

  /// Spanish as spoken in Uruguay.
  spanishUruguay('es-UY'),

  /// Spanish as spoken in Venezuela.
  spanishVenezuela('es-VE'),

  /// Estonian language.
  estonian('et'),

  /// Estonian as spoken in Estonia.
  estonianEstonia('et-EE'),

  /// Basque language.
  basque('eu'),

  /// Basque as spoken in Spain.
  basqueSpain('eu-ES'),

  /// Farsi language.
  farsi('fa'),

  /// Farsi as spoken in Iran.
  farsiIran('fa-IR'),

  /// Finnish language.
  finnish('fi'),

  /// Finnish as spoken in Finland.
  finnishFinland('fi-FI'),

  /// Faroese language.
  faroese('fo'),

  /// Faroese as spoken in Faroe Islands.
  faroeseFaroeIslands('fo-FO'),

  /// French language.
  french('fr'),

  /// French as spoken in Belgium.
  frenchBelgium('fr-BE'),

  /// French as spoken in Canada.
  frenchCanada('fr-CA'),

  /// French as spoken in Switzerland.
  frenchSwitzerland('fr-CH'),

  /// French as spoken in France.
  frenchFrance('fr-FR'),

  /// French as spoken in Luxembourg.
  frenchLuxembourg('fr-LU'),

  /// French as spoken in Monaco.
  frenchPrincipalityOfMonaco('fr-MC'),

  /// Galician language.
  galician('gl'),

  /// Galician as spoken in Spain.
  galicianSpain('gl-ES'),

  /// Gujarati language.
  gujarati('gu'),

  /// Gujarati as spoken in India.
  gujaratiIndia('gu-IN'),

  /// Hebrew language.
  hebrew('he'),

  /// Hebrew as spoken in Israel.
  hebrewIsrael('he-IL'),

  /// Hindi language.
  hindi('hi'),

  /// Hindi as spoken in India.
  hindiIndia('hi-IN'),

  /// Croatian language.
  croatian('hr'),

  /// Croatian as spoken in Bosnia and Herzegovina.
  croatianBosniaAndHerzegovina('hr-BA'),

  /// Croatian as spoken in Croatia.
  croatianCroatia('hr-HR'),

  /// Hungarian language.
  hungarian('hu'),

  /// Hungarian as spoken in Hungary.
  hungarianHungary('hu-HU'),

  /// Armenian language.
  armenian('hy'),

  /// Armenian as spoken in Armenia.
  armenianArmenia('hy-AM'),

  /// Indonesian language.
  indonesian('id'),

  /// Indonesian as spoken in Indonesia.
  indonesianIndonesia('id-ID'),

  /// Icelandic language.
  icelandic('is'),

  /// Icelandic as spoken in Iceland.
  icelandicIceland('is-IS'),

  /// Italian language.
  italian('it'),

  /// Italian as spoken in Switzerland.
  italianSwitzerland('it-CH'),

  /// Italian as spoken in Italy.
  italianItaly('it-IT'),

  /// Japanese language.
  japanese('ja'),

  /// Japanese as spoken in Japan.
  japaneseJapan('ja-JP'),

  /// Georgian language.
  georgian('ka'),

  /// Georgian as spoken in Georgia.
  georgianGeorgia('ka-GE'),

  /// Kazakh language.
  kazakh('kk'),

  /// Kazakh as spoken in Kazakhstan.
  kazakhKazakhstan('kk-KZ'),

  /// Kannada language.
  kannada('kn'),

  /// Kannada as spoken in India.
  kannadaIndia('kn-IN'),

  /// Korean language.
  korean('ko'),

  /// Korean as spoken in Korea.
  koreanKorea('ko-KR'),

  /// Konkani language.
  konkani('kok'),

  /// Konkani as spoken in India.
  konkaniIndia('kok-IN'),

  /// Kyrgyz language.
  kyrgyz('ky'),

  /// Kyrgyz as spoken in Kyrgyzstan.
  kyrgyzKyrgyzstan('ky-KG'),

  /// Lithuanian language.
  lithuanian('lt'),

  /// Lithuanian as spoken in Lithuania.
  lithuanianLithuania('lt-LT'),

  /// Latvian language.
  latvian('lv'),

  /// Latvian as spoken in Latvia.
  latvianLatvia('lv-LV'),

  /// Maori language.
  maori('mi'),

  /// Maori as spoken in New Zealand.
  maoriNewZealand('mi-NZ'),

  /// Macedonian language.
  fyroMacedonian('mk'),

  /// Macedonian as spoken in North Macedonia.
  fyroMacedonianFormerYugoslavRepublicOfMacedonia('mk-MK'),

  /// Mongolian language.
  mongolian('mn'),

  /// Mongolian as spoken in Mongolia.
  mongolianMongolia('mn-MN'),

  /// Marathi language.
  marathi('mr'),

  /// Marathi as spoken in India.
  marathiIndia('mr-IN'),

  /// Malay language.
  malay('ms'),

  /// Malay as spoken in Brunei Darussalam.
  malayBruneiDarussalam('ms-BN'),

  /// Malay as spoken in Malaysia.
  malayMalaysia('ms-MY'),

  /// Maltese language.
  maltese('mt'),

  /// Maltese as spoken in Malta.
  malteseMalta('mt-MT'),

  /// Norwegian Bokmål language.
  norwegianBokml('nb'),

  /// Norwegian Bokmål as spoken in Norway.
  norwegianBokmlNorway('nb-NO'),

  /// Dutch language.
  dutch('nl'),

  /// Dutch as spoken in Belgium.
  dutchBelgium('nl-BE'),

  /// Dutch as spoken in the Netherlands.
  dutchNetherlands('nl-NL'),

  /// Norwegian Nynorsk as spoken in Norway.
  norwegianNynorskNorway('nn-NO'),

  /// Northern Sotho language.
  northernSotho('ns'),

  /// Northern Sotho as spoken in South Africa.
  northernSothoSouthAfrica('ns-ZA'),

  /// Punjabi language.
  punjabi('pa'),

  /// Punjabi as spoken in India.
  punjabiIndia('pa-IN'),

  /// Polish language.
  polish('pl'),

  /// Polish as spoken in Poland.
  polishPoland('pl-PL'),

  /// Pashto language.
  pashto('ps'),

  /// Pashto as spoken in Afghanistan.
  pashtoAfghanistan('ps-AR'),

  /// Portuguese language.
  portuguese('pt'),

  /// Portuguese as spoken in Brazil.
  portugueseBrazil('pt-BR'),

  /// Portuguese as spoken in Portugal.
  portuguesePortugal('pt-PT'),

  /// Quechua language.
  quechua('qu'),

  /// Quechua as spoken in Bolivia.
  quechuaBolivia('qu-BO'),

  /// Quechua as spoken in Ecuador.
  quechuaEcuador('qu-EC'),

  /// Quechua as spoken in Peru.
  quechuaPeru('qu-PE'),

  /// Romanian language.
  romanian('ro'),

  /// Romanian as spoken in Romania.
  romanianRomania('ro-RO'),

  /// Russian language.
  russian('ru'),

  /// Russian as spoken in Russia.
  russianRussia('ru-RU'),

  /// Sanskrit language.
  sanskrit('sa'),

  /// Sanskrit as spoken in India.
  sanskritIndia('sa-IN'),

  /// Sami language.
  sami('se'),

  /// Sami as spoken in Finland.
  samiFinland('se-FI'),

  /// Sami as spoken in Norway.
  samiNorway('se-NO'),

  /// Sami as spoken in Sweden.
  samiSweden('se-SE'),

  /// Slovak language.
  slovak('sk'),

  /// Slovak as spoken in Slovakia.
  slovakSlovakia('sk-SK'),

  /// Slovenian language.
  slovenian('sl'),

  /// Slovenian as spoken in Slovenia.
  slovenianSlovenia('sl-SI'),

  /// Albanian language.
  albanian('sq'),

  /// Albanian as spoken in Albania.
  albanianAlbania('sq-AL'),

  /// Serbian Latin script as spoken in Bosnia and Herzegovina.
  serbianLatinBosniaAndHerzegovina('sr-BA'),

  /// Serbian Cyrillic script as spoken in Bosnia and Herzegovina.
  serbianCyrillicBosniaAndHerzegovina('sr-Cyrl-BA'),

  /// Serbian Latin script as spoken in Serbia and Montenegro.
  serbianLatinSerbiaAndMontenegro('sr-SP'),

  /// Serbian Cyrillic script as spoken in Serbia and Montenegro.
  serbianCyrillicSerbiaAndMontenegro('sr-Cyrl-SP'),

  /// Swedish language.
  swedish('sv'),

  /// Swedish as spoken in Finland.
  swedishFinland('sv-FI'),

  /// Swedish as spoken in Sweden.
  swedishSweden('sv-SE'),

  /// Swahili language.
  swahili('sw'),

  /// Swahili as spoken in Kenya.
  swahiliKenya('sw-KE'),

  /// Syriac language.
  syriac('syr'),

  /// Syriac as spoken in Syria.
  syriacSyria('syr-SY'),

  /// Tamil language.
  tamil('ta'),

  /// Tamil as spoken in India.
  tamilIndia('ta-IN'),

  /// Telugu language.
  telugu('te'),

  /// Telugu as spoken in India.
  teluguIndia('te-IN'),

  /// Thai language.
  thai('th'),

  /// Thai as spoken in Thailand.
  thaiThailand('th-TH'),

  /// Tagalog language.
  tagalog('tl'),

  /// Tagalog as spoken in Philippines.
  tagalogPhilippines('tl-PH'),

  /// Tswana language.
  tswana('tn'),

  /// Tswana as spoken in South Africa.
  tswanaSouthAfrica('tn-ZA'),

  /// Turkish language.
  turkish('tr'),

  /// Turkish as spoken in Turkey.
  turkishTurkey('tr-TR'),

  /// Tatar language.
  tatar('tt'),

  /// Tatar as spoken in Russia.
  tatarRussia('tt-RU'),

  /// Tsonga language.
  tsonga('ts'),

  /// Ukrainian language.
  ukrainian('uk'),

  /// Ukrainian as spoken in Ukraine.
  ukrainianUkraine('uk-UA'),

  /// Urdu language.
  urdu('ur'),

  /// Urdu as spoken in Islamic Republic Of Pakistan.
  urduIslamicRepublicOfPakistan('ur-PK'),

  /// Uzbek Latin script.
  uzbekLatin('uz'),

  /// Uzbek Latin script as spoken in Uzbekistan.
  uzbekLatinUzbekistan('uz-UZ'),

  /// Uzbek Cyrillic script as spoken in Uzbekistan.
  uzbekCyrillicUzbekistan('uz-Cyrl-UZ'),

  /// Vietnamese language.
  vietnamese('vi'),

  /// Vietnamese as spoken in Viet Nam.
  vietnameseVietNam('vi-VN'),

  /// Xhosa language.
  xhosa('xh'),

  /// Xhosa as spoken in South Africa.
  xhosaSouthAfrica('xh-ZA'),

  /// Chinese language.
  chinese('zh'),

  /// Chinese as spoken in China.
  chineseS('zh-CN'),

  /// Chinese as spoken in Hong Kong.
  chineseHongKong('zh-HK'),

  /// Chinese as spoken in Macau.
  chineseMacau('zh-MO'),

  /// Chinese as spoken in Singapore.
  chineseSingapore('zh-SG'),

  /// Chinese as spoken in Taiwan.
  chineseT('zh-TW'),

  /// Zulu language.
  zulu('zu'),

  /// Zulu as spoken in South Africa.
  zuluSouthAfrica('zu-ZA');

  /// The string value representing the language code.
  final String value;

  /// Creates a [Rfc5646Language] with the given [value].
  const Rfc5646Language(this.value);

  @override
  String toString() {
    return value;
  }

  /// Creates a [Rfc5646Language] from a string value.
  ///
  /// [value] - The string representation of the language code.
  ///
  /// Returns the corresponding [Rfc5646Language] enum value.
  /// Throws a [StateError] if no matching language code is found.
  factory Rfc5646Language.fromMap(String? value) {
    if (value == null) return english;
    return values.firstWhere((element) => element.toString() == value,
        orElse: () => english);
  }
}
