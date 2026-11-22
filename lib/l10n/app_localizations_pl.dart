// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class AppLocalizationsPl extends AppLocalizations {
  AppLocalizationsPl([String locale = 'pl']) : super(locale);

  @override
  String get appTitle => 'A B S O R B';

  @override
  String get online => 'Online';

  @override
  String get offline => 'Offline';

  @override
  String get stillOffline => 'Nadal offline. Dotknij, aby spróbować ponownie.';

  @override
  String get retry => 'Ponów';

  @override
  String get listsNone => 'Brak kolekcji i list odtwarzania';

  @override
  String get listsNoneHint =>
      'Kolekcje i listy odtwarzania tworzy się na serwerze Audiobookshelf, a następnie pojawiają się tutaj.';

  @override
  String get listsLoadFailed => 'Nie udało się wczytać list';

  @override
  String get listsLoadFailedHint =>
      'Absorb nie mógł połączyć się z serwerem, aby pobrać kolekcje i listy odtwarzania.';

  @override
  String get listsNoneBookOrbit => 'Brak kolekcji i Smart Scopes';

  @override
  String get listsNoneHintBookOrbit =>
      'Kolekcje i Smart Scopes tworzy się na serwerze BookOrbit, a następnie pojawiają się tutaj.';

  @override
  String get listsLoadFailedHintBookOrbit =>
      'Absorb nie mógł połączyć się z serwerem, aby pobrać kolekcje i Smart Scopes.';

  @override
  String get cancel => 'Anuluj';

  @override
  String get delete => 'Usuń';

  @override
  String get remove => 'Usuń';

  @override
  String get save => 'Zapisz';

  @override
  String get done => 'Gotowe';

  @override
  String get edit => 'Edytuj';

  @override
  String get search => 'Szukaj';

  @override
  String get apply => 'Zastosuj';

  @override
  String get enable => 'Włącz';

  @override
  String get clear => 'Wyczyść';

  @override
  String get off => 'Wył.';

  @override
  String get disabled => 'Wyłączone';

  @override
  String get later => 'Później';

  @override
  String get whatsNewTitle => 'Absorb został zaktualizowany';

  @override
  String whatsNewContent(String version) {
    return 'Masz teraz wersję $version.';
  }

  @override
  String get whatsNewButton => 'Zobacz, co nowego';

  @override
  String get whatsNewKeepShowing => 'Pokazuj po każdej aktualizacji';

  @override
  String get whatsNewKeepShowingHint =>
      'Możesz to ponownie włączyć w Ustawieniach';

  @override
  String get settingsWhatsNew => 'Pokazuj nowości po aktualizacjach';

  @override
  String get settingsWhatsNewSubtitle =>
      'Po aktualizacji Absorb wyświetli okno z linkiem do informacji o wydaniu';

  @override
  String get gotIt => 'Rozumiem';

  @override
  String get betaLoggingTitle => 'Logi są włączone';

  @override
  String get betaLoggingContent =>
      'Ponieważ to wersja beta, Absorb zapisuje teraz logi, aby pomóc w wykrywaniu problemów. Zostają na tym urządzeniu, dopóki ich nie udostępnisz.\n\nMożesz je wysłać lub wyłączyć w Ustawieniach, w sekcji Problemy i pomoc. Jeśli je wyłączysz, kolejne wersje beta pozostawią je wyłączone.';

  @override
  String get preview => 'Podgląd';

  @override
  String get or => 'lub';

  @override
  String get file => 'Plik';

  @override
  String get more => 'Więcej';

  @override
  String get unknown => 'Nieznane';

  @override
  String get untitled => 'Bez tytułu';

  @override
  String get noThanks => 'Nie, dziękuję';

  @override
  String get stay => 'Zostań';

  @override
  String get homeTitle => 'Strona główna';

  @override
  String get continueListening => 'Kontynuuj słuchanie';

  @override
  String get continueReading => 'Kontynuuj czytanie';

  @override
  String get continueSeries => 'Kontynuuj serię';

  @override
  String get recentlyAdded => 'Ostatnio dodane';

  @override
  String get listenAgain => 'Posłuchaj ponownie';

  @override
  String get discover => 'Odkrywaj';

  @override
  String get newEpisodes => 'Nowe odcinki';

  @override
  String get downloads => 'Pobrane';

  @override
  String get noDownloadedBooks => 'Brak pobranych książek';

  @override
  String get yourLibraryIsEmpty => 'Twoja biblioteka jest pusta';

  @override
  String get downloadBooksWhileOnline =>
      'Pobierz książki będąc online, aby słuchać offline';

  @override
  String get customizeHome => 'Dostosuj stronę główną';

  @override
  String get dragToReorderTapEye =>
      'Przeciągnij, aby zmienić kolejność, dotknij oka, aby pokazać/ukryć';

  @override
  String get loginTagline => 'Zacznij słuchać';

  @override
  String get loginConnectToServer => 'Połącz z serwerem';

  @override
  String get loginServerAddress => 'Adres serwera';

  @override
  String get loginServerHint => 'moj.serwer.com';

  @override
  String get loginServerHelper =>
      'IP:port także działa (np. 192.168.1.5:13378)';

  @override
  String get loginCouldNotReachServer => 'Nie można połączyć się z serwerem';

  @override
  String get loginAdvanced => 'Zaawansowane';

  @override
  String get loginCustomHttpHeaders => 'Własne nagłówki HTTP';

  @override
  String get loginCustomHeadersDescription =>
      'Dla tuneli Cloudflare lub serwerów reverse proxy wymagających dodatkowych nagłówków. Dodaj nagłówki przed wpisaniem adresu serwera.';

  @override
  String get loginHeaderName => 'Nazwa nagłówka';

  @override
  String get loginHeaderValue => 'Wartość';

  @override
  String get loginAddHeader => 'Dodaj nagłówek';

  @override
  String get loginSelfSignedCertificates => 'Certyfikaty z podpisem własnym';

  @override
  String get loginTrustAllCertificates =>
      'Ufaj wszystkim certyfikatom (dla certyfikatów samopodpisanych / własnego urzędu certyfikacji)';

  @override
  String get loginApiKey => 'Klucz API';

  @override
  String get loginApiKeyDescription =>
      'Użyj klucza API wygenerowanego przez administratora zamiast nazwy użytkownika i hasła. Przydatne, gdy odświeżanie tokenu nie działa dla Twojego konta.';

  @override
  String get loginWaitingForSso => 'Oczekiwanie na SSO...';

  @override
  String get loginRedirectUri => 'Redirect URI: absorb://oauth';

  @override
  String get loginOrSignInManually => 'lub zaloguj się ręcznie';

  @override
  String get loginUsername => 'Nazwa użytkownika';

  @override
  String get loginUsernameRequired => 'Podaj nazwę użytkownika';

  @override
  String get loginPassword => 'Hasło';

  @override
  String get loginSignIn => 'Zaloguj się';

  @override
  String loginSignInAs(String username) {
    return 'Zalogować jako $username?';
  }

  @override
  String get loginSignInToServer => 'Zalogować się na tym serwerze?';

  @override
  String loginSignedInAs(String username) {
    return 'Zalogowano jako $username';
  }

  @override
  String get adminCreateSetupFile => 'Udostępnij logowanie';

  @override
  String adminSetupFileDescription(String username) {
    return 'Tworzy prywatny link logowania dla użytkownika $username, który działa tylko w aplikacji Absorb.';
  }

  @override
  String get adminSetupFileServerUrl =>
      'Adres serwera, którego użyje nowy użytkownik';

  @override
  String get adminSetupFileNoteWithHeaders =>
      'Zostanie dołączony dedykowany klucz API oraz Twoje niestandardowe nagłówki, aby można było połączyć się z serwerem. Traktuj ten link jak hasło.';

  @override
  String get adminSetupFileNote =>
      'Zostanie dołączony dedykowany klucz API. Traktuj ten link jak hasło.';

  @override
  String get adminSetupFileCreate => 'Utwórz link';

  @override
  String get adminSetupFileSaveTitle => 'Zapisz plik konfiguracyjny';

  @override
  String get adminSetupFileKeyError =>
      'Nie udało się utworzyć klucza API dla tego użytkownika';

  @override
  String adminSetupFileSaved(String username) {
    return 'Zapisano plik konfiguracyjny dla $username';
  }

  @override
  String adminSetupFileFailed(String error) {
    return 'Nie udało się utworzyć logowania: $error';
  }

  @override
  String get setupLinkShareTitle => 'Udostępnij logowanie';

  @override
  String setupLinkShareDescription(String username) {
    return 'Wyślij ten prywatny link lub poproś o zeskanowanie kodu QR, aby zalogować się jako $username.';
  }

  @override
  String setupLinkPrivateWarning(String username) {
    return 'Każdy, kto ma ten link, może zalogować się jako $username. Traktuj go jak hasło.';
  }

  @override
  String get setupLinkShare => 'Udostępnij link';

  @override
  String get setupLinkCopy => 'Kopiuj link';

  @override
  String get setupLinkCopied => 'Skopiowano link logowania';

  @override
  String get setupLinkSaveFile => 'Zapisz plik konfiguracyjny';

  @override
  String get setupLinkQrError =>
      'Ten link konfiguracyjny jest zbyt duży na kod QR. Udostępnij zamiast tego sam link.';

  @override
  String setupLinkShareSubject(String username) {
    return 'Logowanie do Absorb dla $username';
  }

  @override
  String get setupLinkConfirmTitle => 'Zalogować się za pomocą tego linku?';

  @override
  String setupLinkConfirmBody(String server, String username) {
    return 'Zalogować się na $server jako $username? Kontynuuj tylko, jeśli ufasz osobie, która przysłała ten link.';
  }

  @override
  String get setupLinkInvalid =>
      'Ten link logowania jest nieprawidłowy lub niepełny';

  @override
  String get setupLinkSigningIn => 'Sprawdzanie linku logowania...';

  @override
  String get loginPlayDownloads => 'Odtwarzaj pobrane';

  @override
  String signedOutDownloadsNote(String username) {
    return 'Jesteś wylogowany. Wszystko, czego tu posłuchasz, zsynchronizuje się z kontem $username po ponownym zalogowaniu.';
  }

  @override
  String get loginPasteLink => 'Wklej link logowania';

  @override
  String get loginPasteLinkHelp =>
      'Wklej cały otrzymany link logowania. Traktuj go jak hasło.';

  @override
  String get loginFailed => 'Logowanie nie powiodło się';

  @override
  String get loginSsoFailed =>
      'Logowanie SSO nie powiodło się lub zostało anulowane';

  @override
  String get loginSsoAuthFailed =>
      'Uwierzytelnianie SSO nie powiodło się. Spróbuj ponownie.';

  @override
  String get loginRestoreFromBackup => 'Importuj';

  @override
  String get loginInvalidBackupFile => 'Nieprawidłowy plik kopii zapasowej';

  @override
  String get loginRestoreBackupTitle => 'Przywrócić kopię zapasową?';

  @override
  String loginRestoreBackupWithAccounts(int count) {
    return 'Zostaną przywrócone wszystkie ustawienia oraz zapisane konta ($count). Zostaniesz zalogowany automatycznie.';
  }

  @override
  String get loginRestoreBackupNoAccounts =>
      'Zostaną przywrócone wszystkie ustawienia. Ta kopia zapasowa nie zawiera kont.';

  @override
  String get loginRestore => 'Przywróć';

  @override
  String loginRestoredAndSignedIn(String username) {
    return 'Przywrócono ustawienia i zalogowano jako $username';
  }

  @override
  String get loginSessionExpired =>
      'Ustawienia przywrócone. Sesja wygasła - zaloguj się, aby kontynuować.';

  @override
  String get loginSettingsRestored => 'Przywrócono ustawienia';

  @override
  String loginRestoreFailed(String error) {
    return 'Przywracanie nie powiodło się: $error';
  }

  @override
  String get loginSavedAccounts => 'zapisane konta';

  @override
  String get libraryTitle => 'Biblioteka';

  @override
  String get librarySearchBooksHint =>
      'Szukaj książek, serii, autorów, lektorów...';

  @override
  String get librarySearchShowsHint => 'Szukaj podcastów i odcinków...';

  @override
  String get libraryTabLibrary => 'Biblioteka';

  @override
  String get libraryTabSeries => 'Serie';

  @override
  String get libraryTabAuthors => 'Autorzy';

  @override
  String get libraryTabNarrators => 'Lektorzy';

  @override
  String get libraryNoBooks => 'Nie znaleziono książek';

  @override
  String get libraryNoUnfinishedBooks => 'Brak nieukończonych książek';

  @override
  String get libraryNoBooksInProgress => 'Brak książek w trakcie';

  @override
  String get libraryNoFinishedBooks => 'Brak ukończonych książek';

  @override
  String get libraryAllBooksStarted => 'Wszystkie książki zostały rozpoczęte';

  @override
  String get libraryNoDownloadedBooks => 'Brak pobranych książek';

  @override
  String get libraryNoSeriesFound => 'Nie znaleziono serii';

  @override
  String get libraryNoBooksWithEbooks => 'Brak książek z e-bookami';

  @override
  String get libraryNoBooksMissingMetadata =>
      'Żadnej książce nie brakuje tych metadanych';

  @override
  String get libraryNoItemsMatchingFilter =>
      'Brak pozycji pasujących do filtra';

  @override
  String libraryNoBooksInGenre(String genre) {
    return 'Brak książek w gatunku „$genre”';
  }

  @override
  String libraryNoBooksWithTag(String tag) {
    return 'Brak książek z tagiem „$tag”';
  }

  @override
  String get libraryClearFilter => 'Wyczyść filtr';

  @override
  String get libraryNoAuthorsFound => 'Nie znaleziono autorów';

  @override
  String get libraryNoNarratorsFound => 'Nie znaleziono lektorów';

  @override
  String get libraryNoResults => 'Brak wyników';

  @override
  String get librarySearchBooks => 'Książki';

  @override
  String get librarySearchShows => 'Podcasty';

  @override
  String get librarySearchEpisodes => 'Odcinki';

  @override
  String get librarySearchSeries => 'Serie';

  @override
  String get librarySearchAuthors => 'Autorzy';

  @override
  String get librarySearchTags => 'Tagi';

  @override
  String get librarySearchGenres => 'Gatunki';

  @override
  String librarySeriesCount(int count) {
    return '$count serii';
  }

  @override
  String libraryAuthorsCount(int count) {
    return '$count autorów';
  }

  @override
  String libraryNarratorsCount(int count) {
    return '$count lektorów';
  }

  @override
  String libraryBooksCount(int loaded, int total) {
    return '$loaded/$total książek';
  }

  @override
  String get sort => 'Sortuj';

  @override
  String get filter => 'Filtruj';

  @override
  String get filterActive => 'Filtr ●';

  @override
  String get name => 'Nazwa';

  @override
  String get title => 'Tytuł';

  @override
  String get author => 'Autor';

  @override
  String get dateAdded => 'Data dodania';

  @override
  String get numberOfBooks => 'Liczba książek';

  @override
  String get sortTotalDuration => 'Łączny czas trwania';

  @override
  String get sortLastBookAdded => 'Ostatnio dodana książka';

  @override
  String get sortLastBookUpdated => 'Ostatnio zaktualizowana książka';

  @override
  String get publishedYear => 'Rok wydania';

  @override
  String get duration => 'Czas trwania';

  @override
  String get random => 'Losowo';

  @override
  String get collapseSeries => 'Zwiń serie';

  @override
  String get notFinished => 'Nieukończone';

  @override
  String get inProgress => 'W trakcie';

  @override
  String get filterFinished => 'Ukończone';

  @override
  String get notStarted => 'Nierozpoczęte';

  @override
  String get downloaded => 'Pobrane';

  @override
  String get hasEbook => 'Z e-bookiem';

  @override
  String get noEbook => 'Bez e-booka';

  @override
  String get hasSupplementaryEbook => 'Ma dodatkowy e-book';

  @override
  String get noSupplementaryEbook => 'Brak dodatkowego e-booka';

  @override
  String get noSeries => 'Bez serii';

  @override
  String get publishedDecade => 'Dekada wydania';

  @override
  String get tracks => 'Ścieżki';

  @override
  String get noTracks => 'Brak ścieżek';

  @override
  String get singleTrack => 'Jedna ścieżka';

  @override
  String get multipleTracks => 'Wiele ścieżek';

  @override
  String get abridged => 'Skrócone';

  @override
  String get issues => 'Problemy';

  @override
  String get rssFeedOpen => 'Otwarty kanał RSS';

  @override
  String get explicitContent => 'Treści dla dorosłych';

  @override
  String get missingMetadata => 'Brakujące metadane';

  @override
  String get genre => 'Gatunek';

  @override
  String get tag => 'Tag';

  @override
  String get clearFilter => 'Wyczyść filtr';

  @override
  String get noGenresFound => 'Nie znaleziono gatunków';

  @override
  String get noTagsFound => 'Nie znaleziono tagów';

  @override
  String get asc => 'ROSN.';

  @override
  String get desc => 'MAL.';

  @override
  String get fileSize => 'Rozmiar pliku';

  @override
  String get lastUpdated => 'Ostatnia aktualizacja';

  @override
  String get fileCreated => 'Data utworzenia pliku';

  @override
  String get lastModified => 'Ostatnia modyfikacja';

  @override
  String get authorFirstLast => 'Autor (Imię Nazwisko)';

  @override
  String get authorLastFirst => 'Autor (Nazwisko, Imię)';

  @override
  String get progressSort => 'Postęp';

  @override
  String get dateStarted => 'Data rozpoczęcia';

  @override
  String get dateFinished => 'Data ukończenia';

  @override
  String get episodeCount => 'Liczba odcinków';

  @override
  String get sequence => 'Numer w serii';

  @override
  String get absorbingTitle => 'Słuchane';

  @override
  String get absorbingStop => 'Zatrzymaj';

  @override
  String get absorbingManageQueue => 'Zarządzaj kolejką';

  @override
  String get desktopAbsorbingQueueHint =>
      'Użyj opcji Dodaj do Absorbing przy książce lub odcinku, aby umieścić ją tutaj. Pozycje są odtwarzane w tej kolejności.';

  @override
  String get absorbingDone => 'Gotowe';

  @override
  String get absorbingNoDownloadedEpisodes => 'Brak pobranych odcinków';

  @override
  String get absorbingNoDownloadedBooks => 'Brak pobranych książek';

  @override
  String get absorbingNothingPlayingYet => 'Nic jeszcze nie jest odtwarzane';

  @override
  String get absorbingNothingAbsorbingYet => 'Nic jeszcze nie słuchasz';

  @override
  String get absorbingDownloadEpisodesToListen =>
      'Pobierz odcinki, aby słuchać offline';

  @override
  String get absorbingDownloadBooksToListen =>
      'Pobierz książki, aby słuchać offline';

  @override
  String get absorbingStartEpisodeFromShows =>
      'Rozpocznij odcinek z zakładki Podcasty';

  @override
  String get absorbingStartBookFromLibrary =>
      'Rozpocznij książkę z zakładki Biblioteka';

  @override
  String get carModeTitle => 'Tryb samochodowy';

  @override
  String get carModeNoBookLoaded => 'Nie załadowano książki';

  @override
  String get carModeBookLabel => 'Książka';

  @override
  String get carModeChapterLabel => 'Rozdział';

  @override
  String get carModeBookmarkDefault => 'Zakładka';

  @override
  String get carModeBookmarkAdded => 'Dodano zakładkę';

  @override
  String get downloadsTitle => 'Pobrane';

  @override
  String get downloadsCancelSelection => 'Anuluj zaznaczenie';

  @override
  String get downloadsSelect => 'Wybierz';

  @override
  String get downloadsNoDownloads => 'Brak pobranych';

  @override
  String get downloadsDownloading => 'Pobieranie';

  @override
  String get downloadsQueued => 'W kolejce';

  @override
  String get downloadsCompleted => 'Ukończone';

  @override
  String get downloadsEbooks => 'E-booki';

  @override
  String get downloadsWaiting => 'Oczekiwanie...';

  @override
  String get downloadsCancel => 'Anuluj';

  @override
  String get downloadsDelete => 'Usuń';

  @override
  String downloadsDeleteCount(int count) {
    return 'Usunąć pobrane ($count)?';
  }

  @override
  String get downloadsDeleteContent =>
      'Pobrane pliki zostaną usunięte z tego urządzenia.';

  @override
  String downloadsDeletedCount(int count) {
    return 'Usunięto pobrane: $count';
  }

  @override
  String get downloadsRemoveTitle => 'Usunąć pobrane?';

  @override
  String downloadsRemoveContent(String title) {
    return 'Usunąć „$title” z tego urządzenia?';
  }

  @override
  String downloadsRemovedTitle(String title) {
    return 'Usunięto „$title”';
  }

  @override
  String downloadFailedMissingFile(String title) {
    return 'Nie udało się pobrać „$title” - jednego z plików nie ma na serwerze. Skanowanie biblioteki może to naprawić.';
  }

  @override
  String downloadFailedNoSpace(String title) {
    return 'Nie udało się pobrać „$title” - brak miejsca w pamięci';
  }

  @override
  String downloadFailedPermission(String title) {
    return 'Nie udało się pobrać „$title” - sprawdź lokalizację pobierania w Ustawieniach';
  }

  @override
  String downloadFailedGeneric(String title) {
    return 'Nie udało się pobrać „$title”';
  }

  @override
  String downloadsSelectedCount(int count) {
    return 'Wybrano: $count';
  }

  @override
  String get bookmarksTitle => 'Wszystkie zakładki';

  @override
  String get bookmarksTabBookmarks => 'Zakładki';

  @override
  String get bookmarksTabHighlights => 'Zaznaczenia';

  @override
  String get highlightOpenInBook => 'Otwórz w książce';

  @override
  String get highlightDeleteAction => 'Usuń zaznaczenie';

  @override
  String get highlightDeleted => 'Usunięto zaznaczenie';

  @override
  String highlightsDeleteCount(int count) {
    return 'Usunąć zaznaczenia: $count?';
  }

  @override
  String highlightsDeletedCount(int count) {
    return 'Usunięto zaznaczenia: $count';
  }

  @override
  String get quoteShareTitle => 'Udostępnij cytat';

  @override
  String get quoteShareAction => 'Udostępnij';

  @override
  String get quoteShareFailed => 'Nie udało się utworzyć obrazu cytatu';

  @override
  String get quoteShapePortrait => 'Pionowy';

  @override
  String get quoteShapeSquare => 'Kwadrat';

  @override
  String get quoteShapeStory => 'Relacja';

  @override
  String get quoteStyleBlur => 'Rozmyty';

  @override
  String get quoteStyleDim => 'Przyciemniony';

  @override
  String get quoteStyleNone => 'Zwykła okładka';

  @override
  String get quoteTextLight => 'Jasny tekst';

  @override
  String get quoteTextDark => 'Ciemny tekst';

  @override
  String get quoteFieldTitle => 'Tytuł';

  @override
  String get quoteFieldDetail => 'Szczegóły';

  @override
  String get quoteFieldDetailHint =>
      'Autor, rozdział, strona, kto to powiedział';

  @override
  String highlightsMeta(String chapter, String date) {
    return '$chapter · $date';
  }

  @override
  String get bookmarksCancelSelection => 'Anuluj zaznaczenie';

  @override
  String get bookmarksSortedByNewest => 'Od najnowszych';

  @override
  String get bookmarksSortedByPosition => 'Wg pozycji';

  @override
  String get bookmarksSelect => 'Wybierz';

  @override
  String get bookmarksNoBookmarks => 'Brak zakładek';

  @override
  String get bookmarksSearchHint => 'Szukaj zakładek';

  @override
  String get bookmarksNoMatches => 'Żadne zakładki nie pasują do wyszukiwania';

  @override
  String batchDownloadQueued(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Pobieranie $count książki',
      many: 'Pobieranie $count książek',
      few: 'Pobieranie $count książek',
      one: 'Pobieranie $count książki',
    );
    return '$_temp0';
  }

  @override
  String get batchDownloadNothingNew => 'Już pobrano';

  @override
  String bookmarksDeleteCount(int count) {
    return 'Usunąć zakładki: $count?';
  }

  @override
  String get bookmarksDeleteContent => 'Tej czynności nie można cofnąć.';

  @override
  String bookmarksDeletedCount(int count) {
    return 'Usunięto zakładki: $count';
  }

  @override
  String get bookmarksJumpTitle => 'Przejść do zakładki?';

  @override
  String bookmarksJumpContent(String title, String position, String bookTitle) {
    return '„$title” w pozycji $position\nw $bookTitle';
  }

  @override
  String get bookmarksJump => 'Przejdź';

  @override
  String get bookmarksNotConnected => 'Brak połączenia z serwerem';

  @override
  String get bookmarksCouldNotLoad => 'Nie udało się wczytać książki';

  @override
  String bookmarksSelectedCount(int count) {
    return 'Wybrano: $count';
  }

  @override
  String get statsTitle => 'Twoje statystyki';

  @override
  String get statsCouldNotLoad => 'Nie można wczytać statystyk';

  @override
  String get statsTotalListeningTime => 'ŁĄCZNY CZAS SŁUCHANIA';

  @override
  String get statsHoursUnit => 'godz.';

  @override
  String get statsMinutesUnit => 'min';

  @override
  String get statsSecondsUnit => 's';

  @override
  String statsDaysOfAudio(String days) {
    return 'To $days dni audio';
  }

  @override
  String statsHoursOfAudio(String hours) {
    return 'To $hours godzin audio';
  }

  @override
  String get statsToday => 'Dziś';

  @override
  String get statsThisWeek => 'Ten tydzień';

  @override
  String get statsThisMonth => 'Ten miesiąc';

  @override
  String get statsActivity => 'Aktywność';

  @override
  String get statsCurrentStreak => 'Obecna seria';

  @override
  String get statsBestStreak => 'Najlepsza seria';

  @override
  String get statsFinished => 'Ukończone';

  @override
  String get statsBooksFinished => 'Książki';

  @override
  String get statsEpisodesFinished => 'Odcinki';

  @override
  String get statsBooksThisYear => 'Książki w tym roku';

  @override
  String get statsEpisodesThisYear => 'Odcinki w tym roku';

  @override
  String get statsRemoveFromYearTitle => 'Usuń z tego roku';

  @override
  String statsRemoveFromYearWithDate(String date, String title) {
    return 'Data ukończenia na serwerze nadal będzie wynosić $date. To usuwa „$title” tylko z listy książek tego roku w Absorb.';
  }

  @override
  String statsRemoveFromYearNoDate(String title) {
    return 'Data ukończenia pozostaje na serwerze. To usuwa „$title” tylko z listy książek tego roku w Absorb.';
  }

  @override
  String get statsRemovedFromYear => 'Usunięto z tego roku';

  @override
  String get statsAddBackToYearTitle => 'Dodaj z powrotem do tego roku';

  @override
  String statsAddBackToYearBody(String title) {
    return 'Dodać „$title” z powrotem do listy książek tego roku w Absorb?';
  }

  @override
  String get statsAddBack => 'Dodaj z powrotem';

  @override
  String get statsAddedBackToYear => 'Dodano z powrotem do tego roku';

  @override
  String get statsHiddenFromYear => 'Ukryte w tym roku';

  @override
  String get statsNothingHidden => 'Nic nie jest ukryte';

  @override
  String get settingsCustomizeStats => 'Dostosuj statystyki';

  @override
  String get statsGoalTitle => 'Cel słuchania';

  @override
  String get statsGoalOff => 'Wyłączony';

  @override
  String get statsGoalDaily => 'Dzienny';

  @override
  String get statsGoalWeekly => 'Tygodniowy';

  @override
  String get statsGoalMonthly => 'Miesięczny';

  @override
  String get statsGoalTarget => 'Cel';

  @override
  String get statsGoalEnterTitle => 'Ustaw cel';

  @override
  String get statsGoalEnterTimeHint => 'Minuty lub g:mm';

  @override
  String statsBooksShort(int count) {
    return 'Książki: $count';
  }

  @override
  String get statsBookChallengeTitle => 'Wyzwanie czytelnicze';

  @override
  String get statsBookChallengeDesc => 'Książki do ukończenia w tym roku';

  @override
  String get statsDailyGoal => 'Cel dzienny';

  @override
  String get statsWeeklyGoal => 'Cel tygodniowy';

  @override
  String get statsMonthlyGoal => 'Cel miesięczny';

  @override
  String statsGoalProgress(String done, String target) {
    return '$done / $target';
  }

  @override
  String statsBookChallengeProgress(int done, int target) {
    return '$done z $target książek';
  }

  @override
  String get statsGoalReached => 'Cel osiągnięty';

  @override
  String get statsChartTitle => 'Wykres słuchania';

  @override
  String get statsChartBar => 'Słupkowy';

  @override
  String get statsChartLine => 'Liniowy';

  @override
  String get statsChartHeatmap => 'Mapa cieplna';

  @override
  String get statsChartDays7 => '7 dni';

  @override
  String get statsChartDays30 => '30 dni';

  @override
  String get statsLast30Days => 'Ostatnie 30 dni';

  @override
  String get statsThisYearTitle => 'Ten rok';

  @override
  String get statsSectionsTitle => 'Sekcje';

  @override
  String get statsSectionTimePeriods => 'Okresy czasu';

  @override
  String get statsHeatmapLess => 'Mniej';

  @override
  String get statsHeatmapMore => 'Więcej';

  @override
  String get statsDayOfWeek => 'Średnia wg dnia tygodnia';

  @override
  String get statsTimeSavedLabel => 'Zaoszczędzone dzięki prędkości';

  @override
  String statsTimeSavedSince(String date) {
    return 'od $date';
  }

  @override
  String get statsTimeSavedReset => 'Zresetuj zaoszczędzony czas';

  @override
  String get statsTimeSavedResetConfirm =>
      'Zaoszczędzony czas będzie liczony od nowa, począwszy od dzisiaj.';

  @override
  String get statsTimeSavedResetDone => 'Zresetowano zaoszczędzony czas';

  @override
  String statsOnPaceFor(int count) {
    return 'W tym tempie: $count książek';
  }

  @override
  String get statsDaysActive => 'Aktywne dni';

  @override
  String get statsDailyAverage => 'Średnia dzienna';

  @override
  String get statsLast7Days => 'Ostatnie 7 dni';

  @override
  String get statsMostListened => 'Najczęściej słuchane';

  @override
  String get statsRecentSessions => 'Ostatnie sesje';

  @override
  String get appShellHomeTab => 'Start';

  @override
  String get appShellLibraryTab => 'Biblioteka';

  @override
  String get appShellAbsorbingTab => 'Słuchane';

  @override
  String get appShellStatsTab => 'Statystyki';

  @override
  String get appShellSettingsTab => 'Ustawienia';

  @override
  String get appShellDiscoverTab => 'Odkrywaj';

  @override
  String get appShellShowsTab => 'Podcasty';

  @override
  String get appShellPodcastsTab => 'Podcasty';

  @override
  String get libraryTabEpisodes => 'Odcinki';

  @override
  String get filterAllEpisodes => 'Wszystkie';

  @override
  String get filterUnplayed => 'Nieodtworzone';

  @override
  String get episodeFeedEmpty => 'Brak odcinków pasujących do filtra';

  @override
  String get podcastFilterUpNext => 'Następne';

  @override
  String get podcastFilterNew => 'Nowe';

  @override
  String get settingsPodcastTab => 'Zakładka Podcasty';

  @override
  String get settingsPodcastTabDesc =>
      'Przyznaj jednej bibliotece podcastów własną zakładkę na dolnym pasku';

  @override
  String get settingsPodcastTabLibrary => 'Biblioteka zakładki Podcasty';

  @override
  String get settingsStatsTab => 'Zakładka Statystyki';

  @override
  String get settingsStatsTabDesc =>
      'Zachowaj Statystyki na dolnym pasku. Wyłącz, aby zyskać miejsce na małym ekranie';

  @override
  String get settingsOpenStats => 'Otwórz Statystyki';

  @override
  String get liquidGlassNavLabel => 'Liquid Glass';

  @override
  String get liquidGlassNavSubtitle =>
      'iOS glass for the tab bar, library pills and toasts';

  @override
  String get materialExpressiveLabel => 'Material 3 Expressive';

  @override
  String get materialExpressiveSubtitle =>
      'Playful shapes in the tab bar, play button and switches';

  @override
  String get settingsMergeImpliedByPodcastTab =>
      'Zawsze włączone, gdy zakładka Podcasty jest aktywna';

  @override
  String get settingsEpisodeNotifs => 'Ustawienia powiadomień';

  @override
  String get settingsEpisodeNotifsDesc =>
      'Nowe odcinki podcastów, nadchodzące premiery książek i powiadomienia BookOrbit, sprawdzane w tle';

  @override
  String get notifIntervalOff => 'Wyłączone';

  @override
  String notifIntervalMinutes(int n) {
    return 'Co $n min';
  }

  @override
  String get notifIntervalHour => 'Co godzinę';

  @override
  String notifIntervalHours(int n) {
    return 'Co $n godz.';
  }

  @override
  String get settingsBatteryUnrestricted =>
      'Zezwól na nieograniczone użycie baterii';

  @override
  String get settingsBatteryUnrestrictedDesc =>
      'Zapobiega wstrzymywaniu sprawdzania w tle przez system na niektórych telefonach';

  @override
  String get appShellPressBackToExit => 'Naciśnij wstecz ponownie, aby wyjść';

  @override
  String get settingsTitle => 'Ustawienia';

  @override
  String get sectionAppearance => 'Wygląd';

  @override
  String get appIconLabel => 'App icon';

  @override
  String get appIconClassic => 'Classic';

  @override
  String get appIconAurora => 'Aurora';

  @override
  String get appIconLight => 'Light';

  @override
  String get appIconTeal => 'Teal';

  @override
  String get appIconBlue => 'Blue';

  @override
  String get appIconSky => 'Sky';

  @override
  String get appIconPurple => 'Purple';

  @override
  String get appIconPink => 'Pink';

  @override
  String get appIconRed => 'Red';

  @override
  String get appIconOrange => 'Orange';

  @override
  String get appIconYellow => 'Yellow';

  @override
  String get appIconGreen => 'Green';

  @override
  String get appIconFailed => 'Couldn\'t change the app icon';

  @override
  String get appIconAndroidNote =>
      'Your launcher can take a moment to show the new icon, and an Absorb shortcut on the home screen may need adding back.';

  @override
  String get languageLabel => 'Język';

  @override
  String get languageSystemDefault => 'Domyślny systemowy';

  @override
  String get languageHelpTranslateInvite =>
      'Chcesz pomóc w tłumaczeniu Absorb na swój język?';

  @override
  String get themeLabel => 'Motyw';

  @override
  String get themeDark => 'Ciemny';

  @override
  String get themeOled => 'OLED';

  @override
  String get themeLight => 'Jasny';

  @override
  String get themeAuto => 'Auto';

  @override
  String get colorSourceLabel => 'Źródło kolorów';

  @override
  String get colorSourceCoverDescription =>
      'Kolory aplikacji zależą od okładki aktualnie odtwarzanej książki';

  @override
  String get colorSourceWallpaperDescription =>
      'Kolory aplikacji zależą od tapety systemowej';

  @override
  String get colorSourceWallpaper => 'Tapeta';

  @override
  String get colorSourceNowPlaying => 'Odtwarzane';

  @override
  String get colorSourceDynamic => 'Dynamiczne';

  @override
  String get colorSourceManual => 'Ręczne';

  @override
  String get colorSourceManualDescription =>
      'Użyj stałego koloru aplikacji wybranego poniżej';

  @override
  String get colorSourceCustom => 'Własny';

  @override
  String get useColorEverywhereLabel => 'Użyj tego koloru wszędzie';

  @override
  String get useColorEverywhereSubtitle =>
      'Koloruje też strony szczegółów książki i kartę odtwarzacza wybranym kolorem zamiast okładką każdej książki';

  @override
  String get flatBackgroundLabel => 'Płaskie tło';

  @override
  String get flatBackgroundSubtitle =>
      'Usuń gradient tła. Czysta czerń w trybie ciemnym dla ekranów OLED.';

  @override
  String get einkModeLabel => 'Tryb e-ink';

  @override
  String get einkModeSubtitle =>
      'Wysoki kontrast czerni i bieli bez animacji, stworzony dla ekranów e-ink';

  @override
  String get einkModeIntroBody =>
      'Stworzony dla ekranów e-ink. Aplikacja przełącza się na płaski, czarno-biały wygląd o wysokim kontraście, animacje są wyłączone, karta odtwarzania traci tło, a połączenie na żywo z serwerem pozostaje wyłączone, aby oszczędzać baterię. Odtwarzanie i postępy nadal synchronizują się normalnie. Ustawienia wyglądu są zachowane i wrócą po wyłączeniu tego trybu.';

  @override
  String get einkModeIntroConfirm => 'Włącz';

  @override
  String get backgroundIntensityLabel => 'Intensywność tła';

  @override
  String get startScreenLabel => 'Ekran startowy';

  @override
  String get startScreenSubtitle =>
      'Zakładka otwierana po uruchomieniu aplikacji';

  @override
  String get startScreenHome => 'Start';

  @override
  String get startScreenLibrary => 'Biblioteka';

  @override
  String get startScreenAbsorb => 'Absorb';

  @override
  String get startScreenStats => 'Statystyki';

  @override
  String get disablePageFade => 'Wyłącz zanikanie stron';

  @override
  String get disablePageFadeOnSubtitle => 'Strony przełączają się natychmiast';

  @override
  String get disablePageFadeOffSubtitle =>
      'Strony zanikają przy przełączaniu zakładek';

  @override
  String get rectangleBookCovers => 'Prostokątne okładki książek';

  @override
  String get progressTextSize => 'Rozmiar tekstu postępu';

  @override
  String get rectangleBookCoversOnSubtitle =>
      'Okładki wyświetlane w proporcji książki 2:3';

  @override
  String get rectangleBookCoversOffSubtitle => 'Okładki są kwadratowe';

  @override
  String get coverSize => 'Rozmiar okładek';

  @override
  String get coverSizeSubtitle =>
      'Ile okładek mieści się w rzędzie siatki biblioteki';

  @override
  String get coverSizeSmall => 'Małe';

  @override
  String get coverSizeMedium => 'Średnie';

  @override
  String get coverSizeLarge => 'Duże';

  @override
  String get sectionAbsorbingCards => 'Karty Absorbing';

  @override
  String get fullScreenPlayer => 'Odtwarzacz pełnoekranowy';

  @override
  String get fullScreenPlayerOnSubtitle =>
      'Włączone - książki otwierają się na pełnym ekranie po odtworzeniu';

  @override
  String get fullScreenPlayerOffSubtitle =>
      'Wyłączone - odtwarzanie w widoku karty';

  @override
  String get fullBookScrubber => 'Suwak całej książki';

  @override
  String get fullBookScrubberOnSubtitle =>
      'Włączone - suwak przewijania obejmujący całą książkę';

  @override
  String get fullBookScrubberOffSubtitle => 'Wyłączone - tylko pasek postępu';

  @override
  String get cardScrubbers => 'Paski postępu';

  @override
  String get cardScrubbersBoth => 'Oba';

  @override
  String get cardScrubbersChapter => 'Rozdział';

  @override
  String get cardScrubbersLocked => 'Zablokowane';

  @override
  String get cardScrubbersBothSubtitle =>
      'Paski całej książki i rozdziału umożliwiają przewijanie';

  @override
  String get cardScrubbersChapterSubtitle =>
      'Tylko pasek rozdziału umożliwia przewijanie';

  @override
  String get cardScrubbersLockedSubtitle =>
      'Postęp jest wyświetlany bez możliwości przewijania';

  @override
  String get speedAdjustedTime => 'Czas dostosowany do prędkości';

  @override
  String get speedAdjustedTimeOnSubtitle =>
      'Włączone - wszystkie czasy uwzględniają prędkość odtwarzania';

  @override
  String get speedAdjustedTimeOffSubtitle =>
      'Wyłączone - pokazuje surowy czas trwania audio';

  @override
  String get buttonLayout => 'Układ przycisków';

  @override
  String get buttonLayoutSubtitle =>
      'Sposób rozmieszczenia przycisków akcji na karcie';

  @override
  String get whenAbsorbed => 'Po przyswojeniu';

  @override
  String get whenAbsorbedInfoTitle => 'Po przyswojeniu';

  @override
  String get whenAbsorbedInfoContent =>
      'Określa, co dzieje się z kartą Absorbing po ukończeniu książki lub odcinka.\n\nUkończone karty są automatycznie usuwane z ekranu Absorbing.';

  @override
  String get whenAbsorbedSubtitle =>
      'Co dzieje się z kartą Absorbing po ukończeniu książki lub odcinka';

  @override
  String get whenAbsorbedShowOverlay => 'Pokaż nakładkę';

  @override
  String get whenAbsorbedAutoRelease => 'Zwolnij automatycznie';

  @override
  String get mergeLibraries => 'Zunifikowany Absorbing';

  @override
  String get mergeLibrariesInfoTitle => 'Zunifikowany Absorbing';

  @override
  String get mergeLibrariesInfoContent =>
      'Po włączeniu Absorbing pokazuje i kolejkuje razem książki i odcinki podcastów ze wszystkich bibliotek. Po wyłączeniu strona i kolejka ręczna pozostają w obrębie bieżącej biblioteki lub typu mediów.';

  @override
  String get mergeLibrariesOnSubtitle =>
      'Pokazuj i kolejkuj pozycje ze wszystkich bibliotek razem';

  @override
  String get mergeLibrariesOffSubtitle =>
      'Zachowaj stronę i kolejkę ręczną w bieżącej bibliotece';

  @override
  String get queueMode => 'Tryb kolejki';

  @override
  String get queueModeInfoTitle => 'Tryb kolejki';

  @override
  String get queueModeInfoOff => 'Wyłączony';

  @override
  String get queueModeInfoOffDesc =>
      'Odtwarzanie zatrzymuje się po zakończeniu bieżącej książki lub odcinka.';

  @override
  String get queueModeInfoManual => 'Kolejka ręczna';

  @override
  String get queueModeInfoManualDesc =>
      'Pozycje w Absorbing tworzą Twoją kolejkę ręczną. Po zakończeniu jednej odtwarzana jest następna nieukończona. Użyj opcji Dodaj do Absorbing przy książce lub odcinku, a następnie zmień kolejność w panelu Kolejka.';

  @override
  String get queueModeOff => 'Wył.';

  @override
  String get queueModeManual => 'Ręczny';

  @override
  String get queueModeAuto => 'Auto';

  @override
  String get queueModePlaylist => 'Lista odtwarzania';

  @override
  String get queueModeCollection => 'Kolekcja';

  @override
  String get queueModeInfoPlaylist => 'Kolejka z listy odtwarzania';

  @override
  String get queueModeInfoPlaylistDesc =>
      'Odtwarza pozycje po kolei z wybranej listy odtwarzania, pomijając już ukończone. Zatrzymuje się na końcu listy.';

  @override
  String get queuePlaylistPickerTitle => 'Wybierz listę odtwarzania';

  @override
  String get queuePlaylistNone => 'Nie wybrano listy odtwarzania';

  @override
  String queuePlaylistActiveLabel(String name) {
    return 'Lista odtwarzania: $name';
  }

  @override
  String get queueModePlaylistHint =>
      'Uruchom kolejkę z listy odtwarzania, otwierając listę na stronie głównej.';

  @override
  String get exit => 'Wyjdź';

  @override
  String upNext(String label) {
    return 'Następne: $label';
  }

  @override
  String get nothingUpNext => 'Nic w kolejce';

  @override
  String get showUpNextLabel => 'Pokazuj Następne na stronie Absorbing';

  @override
  String get openSeries => 'Otwórz serię';

  @override
  String get openPlaylist => 'Otwórz listę odtwarzania';

  @override
  String get openCollection => 'Otwórz kolekcję';

  @override
  String get playlistPlayAction => 'Odtwórz listę';

  @override
  String get playlistAllFinished => 'Wszystko ukończone';

  @override
  String get queueModeBooks => 'Książki';

  @override
  String get queueModePodcasts => 'Podcasty';

  @override
  String get autoDownloadQueue => 'Automatyczne pobieranie kolejki';

  @override
  String get autoDownloadThisSeriesLabel => 'Automatycznie pobieraj tę serię';

  @override
  String get autoDownloadThisShowLabel => 'Automatycznie pobieraj ten podcast';

  @override
  String get autoDownloadThisPlaylistLabel =>
      'Automatycznie pobieraj tę listę odtwarzania';

  @override
  String get autoDownloadThisCollectionLabel =>
      'Automatycznie pobieraj tę kolekcję';

  @override
  String autoDownloadQueueOnSubtitle(int count) {
    return 'Trzymaj pobrane następne pozycje: $count';
  }

  @override
  String get autoDownloadQueueOffSubtitle =>
      'Wyłączone - tylko ręczne pobieranie';

  @override
  String get sectionPlayback => 'Odtwarzanie';

  @override
  String get sectionMediaControls => 'Sterowanie multimediami';

  @override
  String get defaultSpeed => 'Domyślna prędkość';

  @override
  String get defaultSpeedSubtitle =>
      'Nowe książki zaczynają z tą prędkością - każda książka zapamiętuje własną';

  @override
  String get skipBack => 'Przewiń wstecz';

  @override
  String get skipForward => 'Przewiń do przodu';

  @override
  String get iosLockScreenSkipHint =>
      'Ekran blokady wyświetla tylko liczby, dla których iOS ma ikony (5, 10, 15, 30, 45, 60, 75, 90). Inne wartości pokazują + na przycisku, ale nadal przeskakują zgodnie z ustawieniem.';

  @override
  String get longSkipButtons => 'Przyciski długiego przeskoku';

  @override
  String get longSkipButtonsOnSubtitle =>
      'Włączone - odtwarzacz pokazuje drugą, większą parę przycisków przeskoku';

  @override
  String get longSkipButtonsOffSubtitle =>
      'Wyłączone - tylko zwykłe przyciski przeskoku';

  @override
  String get longSkipBack => 'Długi przeskok do tyłu';

  @override
  String get longSkipForward => 'Długi przeskok do przodu';

  @override
  String get coverShapeDefault => 'Domyślny';

  @override
  String get coverShapeSquare => 'Kwadrat';

  @override
  String get coverShapeRectangle => 'Prostokąt';

  @override
  String get coverShapeLabel => 'Kształt okładki';

  @override
  String get showSubtitles => 'Pokazuj podtytuły';

  @override
  String get showSubtitlesOnSubtitle =>
      'Podtytuły wyświetlane pod tytułami książek w bibliotece i na stronie głównej';

  @override
  String get showSubtitlesOffSubtitle =>
      'Wyłączone - podtytuły tylko w arkuszu szczegółów książki';

  @override
  String get subtitleVisibilityLabel => 'Podtytuły';

  @override
  String get subtitleVisibilityDefault => 'Domyślnie';

  @override
  String get subtitleVisibilityShow => 'Pokaż';

  @override
  String get subtitleVisibilityHide => 'Ukryj';

  @override
  String currentLibrarySettingsTitle(String name) {
    return 'Bieżąca biblioteka: $name';
  }

  @override
  String get currentLibrarySkipOverride => 'Własne wartości przeskoku';

  @override
  String get currentLibrarySkipOverrideOnSubtitle =>
      'Włączone - ta biblioteka używa własnych wartości przeskoku';

  @override
  String get currentLibrarySkipOverrideOffSubtitle =>
      'Wyłączone - ta biblioteka używa globalnych wartości przeskoku';

  @override
  String get currentLibrarySpeedOverride => 'Własna prędkość domyślna';

  @override
  String get currentLibrarySpeedOverrideOnSubtitle =>
      'Włączone - nowe pozycje w tej bibliotece zaczynają z własną prędkością';

  @override
  String get currentLibrarySpeedOverrideOffSubtitle =>
      'Wyłączone - nowe pozycje w tej bibliotece zaczynają z globalną prędkością domyślną';

  @override
  String get currentLibrarySpeed => 'Prędkość domyślna';

  @override
  String get currentLibrarySkipBack => 'Przeskok do tyłu';

  @override
  String get currentLibrarySkipForward => 'Przeskok do przodu';

  @override
  String get chapterProgressInNotification =>
      'Postęp rozdziału w powiadomieniu i Android Auto';

  @override
  String get chapterProgressOnSubtitle =>
      'Włączone - powiadomienie i Android Auto pokazują postęp rozdziału';

  @override
  String get chapterProgressOffSubtitle =>
      'Wyłączone - pokazują postęp całej książki';

  @override
  String get chapterProgressInNotificationIos =>
      'Postęp rozdziału na ekranie blokady i w CarPlay';

  @override
  String get chapterProgressOnSubtitleIos =>
      'Włączone - ekran blokady i CarPlay pokazują postęp rozdziału';

  @override
  String get chapterProgressInNowPlayingBar =>
      'Postęp rozdziału na pasku odtwarzania';

  @override
  String get chapterProgressInNowPlayingBarOnSubtitle =>
      'Włączone - dolny odtwarzacz pokazuje postęp bieżącego rozdziału';

  @override
  String get chapterProgressInNowPlayingBarOffSubtitle =>
      'Wyłączone - dolny odtwarzacz pokazuje postęp całej książki';

  @override
  String get nowPlayingText => 'Tekst odtwarzania';

  @override
  String get nowPlayingTextSubtitle =>
      'Wybierz, co sterowanie multimediami pokazuje w każdym wierszu';

  @override
  String get nowPlayingTopLine => 'Górny wiersz';

  @override
  String get nowPlayingSecondLine => 'Drugi wiersz';

  @override
  String get nowPlayingNotShown => 'Nie pokazuj';

  @override
  String get nowPlayingTopLineRequired =>
      'Górny wiersz wymaga co najmniej jednej pozycji';

  @override
  String get nowPlayingPieceChapter => 'Rozdział';

  @override
  String get nowPlayingPieceTitle => 'Tytuł książki';

  @override
  String get nowPlayingPieceNarrator => 'Lektor';

  @override
  String get nowPlayingPieceSeries => 'Seria';

  @override
  String get nowPlayingPiecePercent => 'Procent książki';

  @override
  String get nowPlayingPieceChapterNumber => 'Numer rozdziału';

  @override
  String get nowPlayingPieceTimeLeft => 'Pozostały czas';

  @override
  String nowPlayingChapterNumber(int number, int total) {
    return 'Rozdz. $number/$total';
  }

  @override
  String nowPlayingTimeLeft(String time) {
    return 'Zostało $time';
  }

  @override
  String get bookDockBadgePending => 'Oczekuje';

  @override
  String get bookDockBadgeExtracting => 'Odczyt pliku';

  @override
  String get bookDockBadgeFetching => 'Wyszukiwanie';

  @override
  String get bookDockBadgeError => 'Błąd';

  @override
  String get bookDockNeedsReview => 'Wymaga przeglądu';

  @override
  String get bookDockNoMatch => 'Brak dopasowania';

  @override
  String get bookDockApplied => 'Zastosowano';

  @override
  String get bookDockNotApplied => 'Znalezione szczegóły nie zostały użyte';

  @override
  String get bookDockNoDestination => 'Nie ustawiono miejsca docelowego';

  @override
  String get bookDockNoAuthor => 'Brak autora';

  @override
  String get bookDockLookUpAgain => 'Wyszukaj ponownie';

  @override
  String get bookDockLookingUp => 'Ponowne wyszukiwanie szczegółów';

  @override
  String get bookDockLookUpFailed => 'Nie udało się wyszukać szczegółów';

  @override
  String get bookDockProposedChanges => 'Proponowane zmiany';

  @override
  String get bookDockNoChanges => 'Nie znaleziono jeszcze szczegółów online';

  @override
  String get bookDockStillReading => 'Serwer wciąż odczytuje ten plik';

  @override
  String get bookDockRoleBook => 'Książka';

  @override
  String get bookDockRoleCover => 'Okładka';

  @override
  String get bookDockRoleMetadata => 'Metadane';

  @override
  String get bookDockRoleExtra => 'Dodatek';

  @override
  String get bookDockFieldTitle => 'Tytuł';

  @override
  String get bookDockFieldSubtitle => 'Podtytuł';

  @override
  String get bookDockFieldAuthors => 'Autorzy';

  @override
  String get bookDockFieldSeries => 'Seria';

  @override
  String get bookDockFieldPublisher => 'Wydawca';

  @override
  String get bookDockFieldYear => 'Rok';

  @override
  String get bookDockFieldLanguage => 'Język';

  @override
  String get bookDockFieldIsbn => 'ISBN';

  @override
  String bookDockMatch(int percent) {
    return 'Dopasowanie $percent%';
  }

  @override
  String bookDockFileCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pliku',
      many: '$count plików',
      few: '$count pliki',
      one: '1 plik',
    );
    return '$_temp0';
  }

  @override
  String bookDockGoesTo(String library) {
    return 'Trafi do: $library';
  }

  @override
  String bookDockChangedFields(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pola',
      many: '$count pól',
      few: '$count pola',
      one: '1 pole',
    );
    return '$_temp0';
  }

  @override
  String bookDockFilesInEntry(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pliku w tym wpisie',
      many: '$count plików w tym wpisie',
      few: '$count pliki w tym wpisie',
      one: 'Plik w tym wpisie',
    );
    return '$_temp0';
  }

  @override
  String bookDockAdded(String date) {
    return 'Dodano $date';
  }

  @override
  String get bookDockAddToLibrary => 'Dodaj do biblioteki';

  @override
  String get bookDockUseFound => 'Użyj znalezionych szczegółów';

  @override
  String get bookDockRemoveTitle => 'Usunąć z Book Dock?';

  @override
  String get bookDockRemoveFailed => 'Nie udało się usunąć tego pliku';

  @override
  String get bookDockPickLibrary => 'Do której biblioteki dodać?';

  @override
  String get bookDockNoLibraries =>
      'Twoje konto nie może dodawać książek do biblioteki';

  @override
  String get bookDockFileFailed =>
      'Nie udało się dodać tego pliku do biblioteki';

  @override
  String get bookDockDuplicateBody =>
      'Plik o tej nazwie już istnieje w tej bibliotece. Usunąć go z Book Dock?';

  @override
  String get bookDockDetailsUpdated => 'Zaktualizowano szczegóły';

  @override
  String get bookDockUseFoundFailed => 'Brak znalezionych szczegółów do użycia';

  @override
  String bookDockRemoveBody(String title) {
    return 'To usuwa $title z serwera.';
  }

  @override
  String bookDockRemoved(String title) {
    return 'Usunięto $title z Book Dock';
  }

  @override
  String bookDockFiled(String title, String library) {
    return 'Dodano $title do $library';
  }

  @override
  String bookDockFileFailedReason(String reason) {
    return 'Nie udało się dodać tego pliku: $reason';
  }

  @override
  String bookDockDuplicateTitle(String library) {
    return 'Już w: $library';
  }

  @override
  String get bomatchSearchAll => 'Szukaj we wszystkich źródłach';

  @override
  String get bomatchSearching => 'Wyszukiwanie...';

  @override
  String get bomatchSearchFailed =>
      'Nie udało się wyszukać dopasowań. Sprawdź połączenie i spróbuj ponownie.';

  @override
  String get bomatchNoResults => 'Nie znaleziono dopasowań';

  @override
  String get bomatchStrong => 'Mocne dopasowania';

  @override
  String get bomatchPossible => 'Możliwe dopasowania';

  @override
  String get bomatchSourceTimeout => 'przekroczono czas';

  @override
  String get bomatchSourceBusy => 'zajęte';

  @override
  String get bomatchSourceFailed => 'błąd';

  @override
  String get bomatchLinked => 'Powiązano';

  @override
  String get bomatchSameIsbn => 'Ten sam ISBN';

  @override
  String get bomatchFewDetails => 'Mało szczegółów';

  @override
  String get bomatchBack => 'Wszystkie wyniki';

  @override
  String get bomatchFillEmpty => 'Uzupełnij puste';

  @override
  String get bomatchTakeAll => 'Weź wszystko';

  @override
  String get bomatchOnlyDifferences => 'Tylko różnice';

  @override
  String get bomatchNow => 'Teraz';

  @override
  String get bomatchEmpty => 'Puste';

  @override
  String get bomatchKindNew => 'Nowe';

  @override
  String get bomatchKindChange => 'Zmiana';

  @override
  String get bomatchKindSmall => 'Drobna zmiana';

  @override
  String get bomatchKindSame => 'Takie samo';

  @override
  String get bomatchKindNone => 'Brak w wyniku';

  @override
  String get bomatchKeep => 'Zachowaj';

  @override
  String get bomatchUse => 'Użyj';

  @override
  String get bomatchMerge => 'Scal';

  @override
  String get bomatchReplace => 'Zastąp';

  @override
  String get bomatchUseThis => 'Użyj tego';

  @override
  String get bomatchChosen => 'Wybrano';

  @override
  String bomatchOther(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count innej książki',
      many: '$count innych książek',
      few: '$count inne książki',
      one: '1 inna książka',
    );
    return '$_temp0';
  }

  @override
  String bomatchChanged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count zmiany',
      many: '$count zmian',
      few: '$count zmiany',
      one: '1 zmiana',
    );
    return '$_temp0';
  }

  @override
  String bomatchNew(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nowego',
      many: '$count nowych',
      few: '$count nowe',
      one: '1 nowe',
    );
    return '$_temp0';
  }

  @override
  String bomatchApply(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Zastosuj $count zmiany',
      many: 'Zastosuj $count zmian',
      few: 'Zastosuj $count zmiany',
      one: 'Zastosuj 1 zmianę',
      zero: 'Zastosuj',
    );
    return '$_temp0';
  }

  @override
  String bomatchOtherSources(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count innego źródła',
      many: '$count innych źródeł',
      few: '$count inne źródła',
      one: '1 inne źródło',
    );
    return '$_temp0';
  }

  @override
  String bomatchFrom(String source) {
    return 'Z: $source';
  }

  @override
  String get breqTitle => 'Prośby o książki';

  @override
  String get breqTabRequest => 'Poproś o książkę';

  @override
  String get breqTabMine => 'Moje prośby';

  @override
  String get breqTabAll => 'Wszystkie prośby';

  @override
  String get breqNoAccess =>
      'Twoje konto nie może prosić o książki na tym serwerze.';

  @override
  String get breqTitleHint => 'Tytuł książki';

  @override
  String get breqAuthorHint => 'Autor';

  @override
  String get breqKindAudiobook => 'Audiobook';

  @override
  String get breqKindEbook => 'E-book';

  @override
  String get breqKindComic => 'Komiks';

  @override
  String get breqSearch => 'Szukaj';

  @override
  String get breqSearching => 'Wyszukiwanie...';

  @override
  String get breqSearchFailed =>
      'Nie udało się wyszukać. Sprawdź połączenie i spróbuj ponownie.';

  @override
  String get breqSearchPrompt =>
      'Wyszukaj książkę, której nie ma jeszcze w bibliotece, aby o nią poprosić.';

  @override
  String get breqNoResults => 'Nie znaleziono pasujących książek';

  @override
  String get breqInLibrary => 'W Twojej bibliotece';

  @override
  String get breqYouAsked => 'Poprosiłeś o to';

  @override
  String get breqSomeoneAsked => 'Ktoś inny już o to poprosił';

  @override
  String get breqView => 'Zobacz';

  @override
  String get breqRequest => 'Poproś';

  @override
  String get breqRequested => 'Zgłoszono prośbę';

  @override
  String get breqAddMeToo => 'Dodaj też mnie';

  @override
  String get breqLibrary => 'Biblioteka';

  @override
  String get breqLibraryApprover => 'Pozwól zdecydować zatwierdzającemu';

  @override
  String get breqLibraryChoose => 'Wybierz bibliotekę';

  @override
  String get breqNote => 'Notatka dla zatwierdzającego';

  @override
  String get breqNoteHint => 'Cokolwiek wartego uwagi w tej prośbie';

  @override
  String get breqAutoApproved => 'Twoje prośby są zatwierdzane od razu.';

  @override
  String get breqSubmitted => 'Prośba wysłana';

  @override
  String get breqJoined => 'Dodano Cię do istniejącej prośby';

  @override
  String get breqFailed => 'Nie udało się wysłać prośby';

  @override
  String get breqStatusPending => 'Oczekuje';

  @override
  String get breqStatusApproved => 'Zatwierdzona';

  @override
  String get breqStatusRejected => 'Odrzucona';

  @override
  String get breqStatusCancelled => 'Anulowana';

  @override
  String get breqStatusSearching => 'Wyszukiwanie';

  @override
  String get breqStatusGrabbed => 'Znaleziono wydanie';

  @override
  String get breqStatusDownloading => 'Pobieranie';

  @override
  String get breqStatusImporting => 'Importowanie';

  @override
  String get breqStatusNeedsReview => 'Wymaga przeglądu';

  @override
  String get breqStatusAvailable => 'Dostępna';

  @override
  String get breqStatusFailed => 'Niepowodzenie';

  @override
  String get breqWaitingApproval => 'Oczekuje na zatwierdzenie';

  @override
  String get breqWaitingRelease => 'Oczekuje na wybór wydania';

  @override
  String get breqLookingForRelease => 'Szukanie wydania';

  @override
  String get breqStartingDownload => 'Rozpoczynanie pobierania';

  @override
  String get breqAddingToLibrary => 'Dodawanie do biblioteki';

  @override
  String get breqWaitingCheck => 'Oczekuje na ręczne sprawdzenie';

  @override
  String get breqReady => 'Gotowe w Twojej bibliotece';

  @override
  String get breqSomethingWrong => 'Coś poszło nie tak';

  @override
  String get breqShowHidden => 'Pokaż ukryte';

  @override
  String get breqHidden => 'Ukryte';

  @override
  String get breqMineEmpty => 'Nie poprosiłeś jeszcze o żadne książki.';

  @override
  String get breqAllEmpty => 'Brak próśb.';

  @override
  String get breqLoadFailed => 'Nie udało się wczytać próśb.';

  @override
  String get breqLoadMore => 'Wczytaj więcej';

  @override
  String get breqApprove => 'Zatwierdź';

  @override
  String get breqReject => 'Odrzuć';

  @override
  String get breqCancel => 'Anuluj prośbę';

  @override
  String get breqHide => 'Ukryj na mojej liście';

  @override
  String get breqUnhide => 'Pokaż na mojej liście';

  @override
  String get breqLeave => 'Opuść prośbę';

  @override
  String get breqDelete => 'Usuń prośbę';

  @override
  String get breqOpenBook => 'Otwórz książkę';

  @override
  String get breqCancelConfirm =>
      'Anulować tę prośbę? Trwające pobieranie również zostanie zatrzymane.';

  @override
  String get breqDeleteConfirm =>
      'Usunąć tę prośbę? Tej operacji nie można cofnąć.';

  @override
  String get breqRejectTitle => 'Odrzuć prośbę';

  @override
  String get breqRejectReason => 'Powód (opcjonalnie)';

  @override
  String get breqApproveTitle => 'Zatwierdź prośbę';

  @override
  String get breqApproveLibraryNeeded =>
      'Wybierz bibliotekę, do której trafi ta książka.';

  @override
  String get breqApprovedToast => 'Prośba zatwierdzona';

  @override
  String get breqRejectedToast => 'Prośba odrzucona';

  @override
  String get breqCancelledToast => 'Prośba anulowana';

  @override
  String get breqHiddenToast => 'Ukryto na Twojej liście';

  @override
  String get breqRestoredToast => 'Przywrócono na Twojej liście';

  @override
  String get breqDeletedToast => 'Prośba usunięta';

  @override
  String get breqLeftToast => 'Opuszczono prośbę';

  @override
  String get breqActionFailed => 'Nie udało się zaktualizować prośby';

  @override
  String get breqFactRequestedBy => 'Zgłosił(a)';

  @override
  String get breqFactRequestedOn => 'Zgłoszono';

  @override
  String get breqFactLibrary => 'Biblioteka';

  @override
  String get breqFactDecidedBy => 'Decyzja:';

  @override
  String get breqFactNote => 'Notatka zgłaszającego';

  @override
  String get breqFactDecisionNote => 'Notatka do decyzji';

  @override
  String get breqFactAlsoWanted => 'Chcą też';

  @override
  String get breqLibraryCta => 'Poproś o książkę';

  @override
  String get breqSettingsSubtitle =>
      'Proś o książki, których nie ma jeszcze w bibliotece';

  @override
  String get navHoldBookRequests => 'Prośby o książki';

  @override
  String breqLibraryDefault(String library) {
    return 'Domyślna ($library)';
  }

  @override
  String breqFailedReason(String reason) {
    return 'Nie udało się wysłać prośby: $reason';
  }

  @override
  String breqBookCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count książki',
      many: '$count książek',
      few: '$count książki',
      one: '1 książka',
    );
    return '$_temp0';
  }

  @override
  String breqDownloadingPercent(int percent) {
    return 'Pobieranie, $percent%';
  }

  @override
  String breqAddedTo(String library) {
    return 'Dodano do: $library';
  }

  @override
  String breqRejectedWithNote(String note) {
    return 'Odrzucono: $note';
  }

  @override
  String breqFailedWithReason(String reason) {
    return 'Niepowodzenie: $reason';
  }

  @override
  String breqRequestedBy(String name) {
    return 'Zgłosił(a): $name';
  }

  @override
  String breqActionFailedReason(String reason) {
    return 'Nie udało się zaktualizować prośby: $reason';
  }

  @override
  String breqFooterCta(String query) {
    return 'Poproś o „$query”';
  }

  @override
  String breqCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count prośby',
      many: '$count próśb',
      few: '$count prośby',
      one: '1 prośba',
      zero: 'Brak próśb',
    );
    return '$_temp0';
  }

  @override
  String get breqFindRelease => 'Znajdź wydanie';

  @override
  String get breqTryAnotherRelease => 'Spróbuj innego wydania';

  @override
  String get breqApproveAndFind => 'Zatwierdź i znajdź wydanie';

  @override
  String get breqReviewButton => 'Przejrzyj pobranie';

  @override
  String get breqStopDownload => 'Zatrzymaj pobieranie';

  @override
  String get breqStopDownloadConfirm =>
      'Zatrzymać to pobieranie? Prośba wróci do stanu zatwierdzonej, aby można było wybrać inne wydanie.';

  @override
  String get breqDiscardImport => 'Odrzuć pobranie';

  @override
  String get breqDiscardConfirm =>
      'Odrzucić to pobranie? Prośba zostanie oznaczona jako nieudana i można ją ponowić z innym wydaniem.';

  @override
  String get breqFileAnyway => 'Dodaj do biblioteki';

  @override
  String get breqFiledToast => 'Dodano do biblioteki';

  @override
  String get breqDiscardedToast => 'Pobranie odrzucone';

  @override
  String get breqStoppedToast => 'Pobieranie zatrzymane';

  @override
  String get breqGrabTitle => 'Pobrać to wydanie?';

  @override
  String get breqGrab => 'Pobierz';

  @override
  String get breqGrabbed => 'Rozpoczęto pobieranie';

  @override
  String get breqGrabFailed => 'Nie udało się rozpocząć pobierania';

  @override
  String get breqReleaseVipWarning =>
      'Ten tracker pozwala pobierać to tylko kontom VIP.';

  @override
  String get breqReleaseNoBookFile =>
      'To wydanie nie zawiera pliku książki, który BookOrbit mógłby dodać do biblioteki.';

  @override
  String get breqReleaseCheckFailed =>
      'Nie udało się sprawdzić zawartości tego wydania. Spróbuj ponownie lub wybierz inne.';

  @override
  String get breqCheckingRelease => 'Sprawdzanie plików...';

  @override
  String get breqSearchAgain => 'Szukaj ponownie';

  @override
  String get breqSearchTerms => 'Szukane frazy';

  @override
  String get breqIsbnHint => 'Zostaw puste, aby szukać po tytule i autorze';

  @override
  String get breqSearchingIndexers =>
      'Przeszukiwanie Twoich indeksatorów. Może to potrwać do minuty.';

  @override
  String get breqReleasesFailed => 'Nie udało się wyszukać wydań.';

  @override
  String get breqNoSourcesSetUp =>
      'W BookOrbit nie skonfigurowano żadnych źródeł wyszukiwania.';

  @override
  String get breqNoSourcesOn =>
      'Wszystkie źródła wyszukiwania są wyłączone w BookOrbit.';

  @override
  String get breqNoSourceCarries =>
      'Żadne z Twoich źródeł wyszukiwania nie obejmuje tego rodzaju książek.';

  @override
  String get breqNoReleases => 'Nie znaleziono wydań. Spróbuj innych fraz.';

  @override
  String get breqFromCache => 'z niedawnego wyszukiwania';

  @override
  String get breqIndexerUnauthorized => 'logowanie nie powiodło się';

  @override
  String get breqIndexerThrottled => 'zajęte';

  @override
  String get breqIndexerTimeout => 'przekroczono czas';

  @override
  String get breqIndexerUnreachable => 'nieosiągalne';

  @override
  String get breqIndexerNoMedium => 'nie obejmuje tego';

  @override
  String get breqIndexerError => 'błąd';

  @override
  String get breqSortBest => 'Najlepsze dopasowanie';

  @override
  String get breqSortSeeders => 'Seedery';

  @override
  String get breqSortSize => 'Rozmiar';

  @override
  String get breqSortNewest => 'Najnowsze';

  @override
  String get breqFreeleech => 'Freeleech';

  @override
  String get breqVipOnly => 'Tylko VIP';

  @override
  String get breqAlreadyGrabbed => 'Pobrano wcześniej';

  @override
  String get breqReasonIsbn => 'ISBN';

  @override
  String get breqReasonTitle => 'Tytuł';

  @override
  String get breqReasonAuthor => 'Autor';

  @override
  String get breqReasonUnknownFormat => 'Nieznany format';

  @override
  String get breqReasonExpectedSize => 'Rozmiar';

  @override
  String get breqReasonSuspiciousSize => 'Nietypowy rozmiar';

  @override
  String get breqReasonFreeleech => 'Freeleech';

  @override
  String get breqReasonSeveralBooks => 'Kilka książek';

  @override
  String get breqReviewTitle => 'Pobranie czeka na sprawdzenie';

  @override
  String get breqReviewFailed => 'Nie udało się wczytać szczegółów pobrania.';

  @override
  String get breqReviewDockGone => 'Pobranych plików nie ma już w Book Dock.';

  @override
  String get breqReviewNoLibrary =>
      'Ta prośba nie ma biblioteki, do której można dodać książkę.';

  @override
  String breqGrabFailedReason(String reason) {
    return 'Nie udało się rozpocząć pobierania: $reason';
  }

  @override
  String breqReleaseCheckFailedReason(String reason) {
    return 'Nie udało się sprawdzić zawartości tego wydania: $reason';
  }

  @override
  String breqReleasesFailedReason(String reason) {
    return 'Nie udało się wyszukać wydań: $reason';
  }

  @override
  String breqReviewFailedReason(String reason) {
    return 'Nie udało się wczytać szczegółów pobrania: $reason';
  }

  @override
  String breqReleaseCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count wydania',
      many: '$count wydań',
      few: '$count wydania',
      one: '1 wydanie',
      zero: 'Brak wydań',
    );
    return '$_temp0';
  }

  @override
  String breqFileCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pliku',
      many: '$count plików',
      few: '$count pliki',
      one: '1 plik',
    );
    return '$_temp0';
  }

  @override
  String breqReviewFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pliku',
      many: '$count plików',
      few: '$count pliki',
      one: '1 plik',
    );
    return '$_temp0';
  }

  @override
  String breqSeeders(int seeders, int leechers) {
    return 'Seedery: $seeders, leecherzy: $leechers';
  }

  @override
  String breqScore(int score) {
    return 'Wynik $score';
  }

  @override
  String breqReasonPreferredFormat(String format) {
    return 'Preferowany $format';
  }

  @override
  String breqReasonFormat(String format) {
    return '$format';
  }

  @override
  String breqReasonSeeders(String count) {
    return 'Seedery: $count';
  }

  @override
  String breqReviewScore(int score, int threshold) {
    return 'Wynik dopasowania: $score. Pobrania z wynikiem $threshold lub wyższym są dodawane automatycznie.';
  }

  @override
  String breqReviewRequested(String value) {
    return 'Zgłoszono: $value';
  }

  @override
  String breqReviewImported(String value) {
    return 'Pobrano: $value';
  }

  @override
  String get breqKindBoth => 'Oba';

  @override
  String get breqEbookLibrary => 'Biblioteka e-booków';

  @override
  String get breqAudiobookLibrary => 'Biblioteka audiobooków';

  @override
  String get breqRequestBoth => 'Poproś o oba';

  @override
  String get breqAddMeToBoth => 'Dodaj mnie do obu';

  @override
  String get breqRequestEbook => 'Poproś o e-book';

  @override
  String get breqRequestAudiobook => 'Poproś o audiobook';

  @override
  String get breqAddMeEbook => 'Dodaj mnie do prośby o e-book';

  @override
  String get breqAddMeAudiobook => 'Dodaj mnie do prośby o audiobook';

  @override
  String get breqPairSubmitted => 'Zgłoszono prośbę o e-book i audiobook';

  @override
  String get breqPairOneJoined =>
      'Zgłoszono oba. Jedna prośba była już w toku, więc dodano Cię do niej';

  @override
  String get breqJoinedBoth => 'Dodano Cię do obu próśb';

  @override
  String get breqJoinsOwned =>
      'Zgłoszono. Zostanie dołączone do kopii, która już jest w Twojej bibliotece';

  @override
  String get speedBookmarkInControls =>
      'Prędkość i zakładka w sterowaniu multimediami';

  @override
  String get speedBookmarkOnSubtitle =>
      'Włączone - powiadomienie pokazuje prędkość i zakładkę; przeskok rozdziału pozostaje w Android Auto';

  @override
  String get speedBookmarkOffSubtitle =>
      'Wyłączone - powiadomienie pokazuje przeskok rozdziału; prędkość i zakładka pozostają w Android Auto';

  @override
  String get lockSeekBar => 'Zablokuj pasek przewijania';

  @override
  String get lockSeekBarOnSubtitle =>
      'Włączone - suwak w powiadomieniu, na ekranie blokady i w samochodzie pokazuje postęp, ale nie można go przeciągać';

  @override
  String get lockSeekBarOffSubtitle =>
      'Wyłączone - przeciągaj suwak w powiadomieniu, na ekranie blokady i w samochodzie, aby przeskakiwać';

  @override
  String get autoRewindOnResume => 'Automatyczne cofanie po wznowieniu';

  @override
  String autoRewindOnSubtitle(String min, String max) {
    return 'Włączone - od $min s do $max s, zależnie od długości pauzy';
  }

  @override
  String get autoRewindOffSubtitle => 'Wyłączone';

  @override
  String get rewindRange => 'Zakres cofania';

  @override
  String get rewindAfterPausedFor => 'Cofaj po pauzie trwającej';

  @override
  String get rewindAnyPause => 'Każda pauza';

  @override
  String get rewindAlwaysLabel => 'Zawsze';

  @override
  String get rewindAlwaysDescription =>
      'Cofa przy każdym wznowieniu, nawet po krótkich przerwach';

  @override
  String rewindAfterDescription(String seconds) {
    return 'Cofa tylko po pauzie trwającej co najmniej $seconds s';
  }

  @override
  String get chapterBarrier => 'Granica rozdziału';

  @override
  String get chapterBarrierSubtitle =>
      'Nie cofaj automatycznie poza początek bieżącego rozdziału';

  @override
  String get rewindInstant => 'Natychmiast';

  @override
  String rewindPause(String duration) {
    return 'Pauza $duration';
  }

  @override
  String get rewindNoRewind => 'bez cofania';

  @override
  String rewindSeconds(String seconds) {
    return 'cofnięcie o $seconds s';
  }

  @override
  String get sectionSleepTimer => 'Wyłącznik czasowy';

  @override
  String get sleep => 'Sen';

  @override
  String get sleepTimer => 'Wyłącznik czasowy';

  @override
  String get shakeDuringSleepTimer =>
      'Potrząśnięcie podczas wyłącznika czasowego';

  @override
  String get shakeOff => 'Wył.';

  @override
  String get shakeAddTime => 'Dodaj czas';

  @override
  String get shakeReset => 'Resetuj';

  @override
  String get shakeAdds => 'Potrząśnięcie dodaje';

  @override
  String get sleepAddAmount => 'Ilość dodawanego czasu';

  @override
  String shakeAddsValue(int minutes) {
    return '$minutes min';
  }

  @override
  String get shakeSensitivity => 'Czułość potrząśnięcia';

  @override
  String get shakeSensitivityVeryLow => 'Bardzo niska';

  @override
  String get shakeSensitivityLow => 'Niska';

  @override
  String get shakeSensitivityMedium => 'Średnia';

  @override
  String get shakeSensitivityHigh => 'Wysoka';

  @override
  String get shakeSensitivityVeryHigh => 'Bardzo wysoka';

  @override
  String get buttonDuringSleepTimer => 'Przycisk słuchawek podczas wyciszania';

  @override
  String get buttonDuringSleepTimerHint =>
      'W ostatnich chwilach wyciszania jedno naciśnięcie resetuje timer zamiast wstrzymywać. Dwukrotne naciśnięcie nadal przeskakuje.';

  @override
  String get resetTimerOnPause => 'Resetuj timer przy pauzie';

  @override
  String get resetTimerOnPauseOnSubtitle =>
      'Timer startuje od pełnego czasu po wznowieniu';

  @override
  String get resetTimerOnPauseOffSubtitle =>
      'Timer kontynuuje odliczanie od miejsca zatrzymania';

  @override
  String get fadeVolumeBeforeSleep => 'Ściszaj przed uśnięciem';

  @override
  String get fadeVolumeOnSubtitle =>
      'Stopniowo zmniejsza głośność w ostatnich 30 sekundach';

  @override
  String get fadeVolumeOffSubtitle =>
      'Odtwarzanie zatrzymuje się natychmiast po zakończeniu timera';

  @override
  String get autoSleepTimer => 'Automatyczny wyłącznik czasowy';

  @override
  String autoSleepTimerOnSubtitle(String start, String end, int duration) {
    return '$start - $end - $duration min';
  }

  @override
  String get autoSleepTimerOffSubtitle =>
      'Automatycznie uruchamiaj wyłącznik czasowy w wybranym przedziale czasu';

  @override
  String get windowStart => 'Początek przedziału';

  @override
  String get windowEnd => 'Koniec przedziału';

  @override
  String get timerDuration => 'Czas trwania timera';

  @override
  String get timer => 'Timer';

  @override
  String get endOfChapter => 'Koniec rozdziału';

  @override
  String startMinTimer(int minutes) {
    return 'Uruchom timer na $minutes min';
  }

  @override
  String sleepAfterChapters(int count, String label) {
    return 'Wyłącz po $count $label';
  }

  @override
  String get addMoreTime => 'Dodaj więcej czasu';

  @override
  String get cancelTimer => 'Anuluj timer';

  @override
  String chaptersLeftCount(int count) {
    return 'Zostało rozdz.: $count';
  }

  @override
  String get sectionDownloadsAndStorage => 'Pobrane i pamięć';

  @override
  String get downloadOverWifiOnly => 'Sieć do pobierania';

  @override
  String get downloadOverWifiOnSubtitle => 'Tylko Wi-Fi';

  @override
  String get downloadOverWifiOffSubtitle => 'Dowolne połączenie';

  @override
  String get autoDownloadOnWifi => 'Automatycznie pobieraj rozpoczęte książki';

  @override
  String get autoDownloadOnWifiInfoTitle =>
      'Automatyczne pobieranie rozpoczętych książek';

  @override
  String get autoDownloadOnWifiInfoContent =>
      'Gdy zaczniesz streamować książkę, cała książka pobiera się w tle, dzięki czemu będzie dostępna offline bez ręcznego rozpoczynania pobierania. Pobieranie to podlega powyższemu ustawieniu Sieć do pobierania, więc ustaw Dowolne połączenie, jeśli ma działać także w sieci komórkowej.';

  @override
  String get autoDownloadOnWifiOnSubtitle =>
      'Streamowane książki pobierają się automatycznie w tle';

  @override
  String get autoDownloadOnWifiOffSubtitle => 'Wyłączone';

  @override
  String get concurrentDownloads => 'Jednoczesne pobierania';

  @override
  String get autoDownload => 'Automatyczne pobieranie';

  @override
  String get autoDownloadSubtitle =>
      'Włącz dla serii, podcastu, listy odtwarzania lub kolekcji na ich stronach szczegółów';

  @override
  String get autoDownloadEnabledFor => 'Włączone dla';

  @override
  String get autoDownloadEnabledForNone => 'Jeszcze nic';

  @override
  String get autoDownloadSourceUnnamed => 'Jeszcze nie wczytano';

  @override
  String get keepNext => 'Zachowaj następne';

  @override
  String get keepNextInfoTitle => 'Zachowaj następne';

  @override
  String get keepNextInfoContent =>
      'Liczba pozycji, które mają pozostać pobrane, wliczając tę, której aktualnie słuchasz. Na przykład „Zachowaj następne 3” oznacza, że bieżąca książka oraz kolejne 2 z tej serii, podcastu, listy odtwarzania lub kolekcji pozostaną pobrane. Dotyczy każdego włączonego automatycznego pobierania.';

  @override
  String get deleteAbsorbedDownloads => 'Usuwaj pobrane po przyswojeniu';

  @override
  String get deleteAbsorbedDownloadsInfoTitle =>
      'Usuwanie pobranych po przyswojeniu';

  @override
  String get deleteAbsorbedDownloadsInfoContent =>
      'Po włączeniu pobrane książki lub odcinki są automatycznie usuwane z tego urządzenia po ukończeniu ich w Absorb. Ukończenie pozycji w sieci lub na innym urządzeniu nie usunie jej pobranej wersji tutaj.';

  @override
  String get deleteAbsorbedOnSubtitle =>
      'Ukończone pozycje są usuwane, aby zaoszczędzić miejsce';

  @override
  String get deleteAbsorbedOffSubtitle =>
      'Wyłączone - ukończone pobrane pozycje zostają';

  @override
  String get downloadLocation => 'Lokalizacja pobierania';

  @override
  String get storageUsed => 'Zajęta pamięć';

  @override
  String storageUsedByDownloads(String size) {
    return '$size zajmują pobrane';
  }

  @override
  String storageFreeOfTotal(String free, String total) {
    return 'Wolne $free z $total';
  }

  @override
  String get manageDownloads => 'Zarządzaj pobranymi';

  @override
  String get streamingCache => 'Pamięć podręczna streamingu';

  @override
  String get streamingCacheInfoTitle => 'Pamięć podręczna streamingu';

  @override
  String get streamingCacheInfoContent =>
      'Zapisuje streamowane audio na dysku, aby nie trzeba go było pobierać ponownie przy przewijaniu wstecz lub ponownym słuchaniu fragmentów. Pamięć podręczna jest zarządzana automatycznie - po osiągnięciu limitu rozmiaru najstarsze pliki są usuwane. Jest to oddzielne od w pełni pobranych książek.';

  @override
  String get streamingCacheOff => 'Wyłączona';

  @override
  String get streamingCacheOffSubtitle =>
      'Wyłączone - audio jest streamowane bez zapisywania w pamięci podręcznej';

  @override
  String streamingCacheOnSubtitle(int size) {
    return '$size MB - ostatnio streamowane audio jest zapisywane na dysku';
  }

  @override
  String get clearCache => 'Wyczyść pamięć podręczną';

  @override
  String get streamingCacheCleared =>
      'Wyczyszczono pamięć podręczną streamingu';

  @override
  String get sectionLibrary => 'Biblioteka';

  @override
  String get hideEbookOnlyTitles => 'Ukryj tytuły tylko z e-bookiem';

  @override
  String get hideEbookOnlyOnSubtitle => 'Książki bez plików audio są ukryte';

  @override
  String get hideEbookOnlyOffSubtitle =>
      'Wyłączone - wszystkie pozycje biblioteki są widoczne';

  @override
  String get audibleRatings => 'Oceny Audible';

  @override
  String get audibleRatingsOnSubtitle =>
      'Włączone - szczegóły książki pokazują ocenę Audible';

  @override
  String get audibleRatingsOffSubtitle =>
      'Wyłączone - bez wyszukiwania w Audible i gwiazdek';

  @override
  String get homeCardsOpenDetails => 'Otwieraj szczegóły ze strony głównej';

  @override
  String get homeCardsOpenDetailsOnSubtitle =>
      'Dotknięcie karty Kontynuuj słuchanie lub Kontynuuj czytanie otwiera jej szczegóły';

  @override
  String get homeCardsOpenDetailsOffSubtitle =>
      'Dotknięcie karty Kontynuuj słuchanie lub Kontynuuj czytanie wznawia od miejsca zatrzymania';

  @override
  String get showGoodreadsButton => 'Pokaż przycisk Goodreads';

  @override
  String get showGoodreadsOnSubtitle =>
      'Arkusz szczegółów książki pokazuje link do Goodreads';

  @override
  String get showGoodreadsOffSubtitle =>
      'Wyłączone - przycisk Goodreads ukryty';

  @override
  String get sectionPermissions => 'Uprawnienia';

  @override
  String get notifications => 'Powiadomienia';

  @override
  String get notificationsSubtitle =>
      'Dla postępu pobierania i sterowania odtwarzaniem';

  @override
  String get notificationsAlreadyEnabled => 'Powiadomienia są już włączone';

  @override
  String get unrestrictedBattery => 'Bateria bez ograniczeń';

  @override
  String get unrestrictedBatterySubtitle =>
      'Zapobiega zamykaniu przez Androida odtwarzania w tle';

  @override
  String get batteryAlreadyUnrestricted => 'Bateria jest już bez ograniczeń';

  @override
  String get sectionIssuesAndSupport => 'Problemy i pomoc';

  @override
  String get bugsAndFeatureRequests => 'Błędy i propozycje funkcji';

  @override
  String get bugsAndFeatureRequestsSubtitle => 'Otwórz zgłoszenie na GitHubie';

  @override
  String get joinDiscord => 'Dołącz do Discorda';

  @override
  String get joinDiscordSubtitle => 'Społeczność, pomoc i aktualności';

  @override
  String get contact => 'Kontakt';

  @override
  String get contactSubtitle => 'Wyślij informacje o urządzeniu e-mailem';

  @override
  String get enableLogging => 'Włącz logowanie';

  @override
  String get enableLoggingOnSubtitle =>
      'Włączone - logi są zapisywane (uruchom ponownie, aby zastosować)';

  @override
  String get enableLoggingOffSubtitle => 'Wyłączone - logi nie są zapisywane';

  @override
  String get loggingEnabledSnackbar =>
      'Logowanie włączone - uruchom ponownie aplikację, aby zacząć zapisywać';

  @override
  String get loggingDisabledSnackbar =>
      'Logowanie wyłączone - uruchom ponownie aplikację, aby przestać zapisywać';

  @override
  String get sendLogs => 'Eksportuj logi';

  @override
  String get sendLogsSubtitle => 'Pobierz lub udostępnij plik logów .txt';

  @override
  String failedToShare(String error) {
    return 'Nie udało się wyeksportować: $error';
  }

  @override
  String get clearLogs => 'Wyczyść logi';

  @override
  String get logsCleared => 'Logi wyczyszczone';

  @override
  String get clearLogsQuestion => 'Wyczyścić logi?';

  @override
  String get clearLogsContent =>
      'Tej operacji nie można cofnąć. Wyślij je wcześniej, jeśli mogą Ci się przydać.';

  @override
  String get sectionAdvanced => 'Zaawansowane';

  @override
  String get localServer => 'Serwer lokalny';

  @override
  String get localServerInfoTitle => 'Serwer lokalny';

  @override
  String get localServerInfoContent =>
      'Jeśli uruchamiasz serwer Audiobookshelf w domu, możesz tu ustawić lokalny adres URL (LAN). Absorb automatycznie przełączy się na szybsze połączenie lokalne, gdy wykryje, że jesteś w sieci domowej, a po wyjściu wróci do zdalnego adresu URL.';

  @override
  String get localServerOnConnectedSubtitle => 'Połączono przez serwer lokalny';

  @override
  String get localServerOnRemoteSubtitle => 'Włączone - używany serwer zdalny';

  @override
  String get localServerOffSubtitle =>
      'Automatycznie przełączaj na serwer LAN w domowej sieci WiFi';

  @override
  String get localServerUrlLabel => 'Adres URL serwera lokalnego';

  @override
  String get localServerUrlHint => 'http://192.168.1.100:13378';

  @override
  String get localServerUrlSetSnackbar =>
      'Ustawiono adres URL serwera lokalnego - połączenie nastąpi automatycznie w sieci domowej';

  @override
  String get disableAudioFocus => 'Wyłącz fokus audio';

  @override
  String get disableAudioFocusInfoTitle => 'Fokus audio';

  @override
  String get disableAudioFocusInfoContent =>
      'Domyślnie Android przyznaje „fokus” audio jednej aplikacji naraz - gdy gra Absorb, inne dźwięki (muzyka, filmy) są wstrzymywane. Wyłączenie fokusu audio pozwala Absorb grać razem z innymi aplikacjami. Połączenia telefoniczne nadal wstrzymają odtwarzanie niezależnie od tego ustawienia.';

  @override
  String get disableAudioFocusOnSubtitle =>
      'Włączone - gra razem z innym dźwiękiem (nadal wstrzymuje się na czas połączeń)';

  @override
  String get disableAudioFocusOffSubtitle =>
      'Wyłączone - inny dźwięk jest wstrzymywany, gdy gra Absorb';

  @override
  String get restartRequired => 'Wymagany restart';

  @override
  String get restartRequiredContent =>
      'Zmiana fokusu audio wymaga pełnego restartu, aby zadziałać. Zamknąć aplikację teraz?';

  @override
  String get closeApp => 'Zamknij aplikację';

  @override
  String get trustAllCertificates => 'Ufaj wszystkim certyfikatom';

  @override
  String get trustAllCertificatesInfoTitle => 'Certyfikaty samopodpisane';

  @override
  String get mp3IndexSeeking => 'Przewijanie MP3 wg indeksu';

  @override
  String get mp3IndexSeekingInfoTitle => 'Przewijanie MP3 wg indeksu';

  @override
  String get mp3IndexSeekingInfoContent =>
      'Włącz tylko wtedy, gdy masz pliki MP3, które nie przewijają się do właściwej pozycji. Niedokładne przewijanie zwykle dotyczy plików MP3 o zmiennej przepływności (VBR). Przewijanie wg indeksu buduje dokładną mapę czasu podczas odczytu pliku, więc skok blisko końca dużego pliku MP3 może chwilę potrwać - zwłaszcza przy streamingu, bo plik trzeba odczytać aż do tego miejsca. Zmiana zadziała przy następnym uruchomieniu książki lub odcinka podcastu.';

  @override
  String get mp3IndexSeekingOnSubtitle =>
      'Włączone - dokładne przewijanie plików MP3 VBR';

  @override
  String get mp3IndexSeekingOffSubtitle => 'Wyłączone - normalne przewijanie';

  @override
  String get trustAllCertificatesInfoContent =>
      'Włącz, jeśli Twój serwer Audiobookshelf używa certyfikatu samopodpisanego lub własnego głównego urzędu certyfikacji. Po włączeniu Absorb pominie weryfikację certyfikatów TLS dla wszystkich połączeń. Włącz tylko, jeśli ufasz swojej sieci.';

  @override
  String get trustAllCertificatesOnSubtitle =>
      'Włączone - akceptowane są wszystkie certyfikaty';

  @override
  String get trustAllCertificatesOffSubtitle =>
      'Wyłączone - akceptowane są tylko zaufane certyfikaty';

  @override
  String get supportTheDev => 'Wesprzyj twórcę';

  @override
  String get buyMeACoffee => 'Postaw mi kawę';

  @override
  String appVersionFormat(String version) {
    return 'Absorb v$version';
  }

  @override
  String betaLabel(int number) {
    return 'Beta $number';
  }

  @override
  String appVersionWithServerFormat(String version, String serverVersion) {
    return 'Absorb v$version  -  Serwer $serverVersion';
  }

  @override
  String get backupAndRestore => 'Kopia zapasowa i przywracanie';

  @override
  String get backupAndRestoreSubtitle =>
      'Zapisz lub przywróć wszystkie ustawienia z pliku';

  @override
  String get backUp => 'Utwórz kopię';

  @override
  String get restore => 'Przywróć';

  @override
  String get allBookmarks => 'Wszystkie zakładki';

  @override
  String get allBookmarksSubtitle => 'Zobacz zakładki ze wszystkich książek';

  @override
  String get switchAccount => 'Przełącz konto';

  @override
  String get addAccount => 'Dodaj konto';

  @override
  String get logOut => 'Wyloguj';

  @override
  String get includeLoginInfoTitle => 'Dołączyć dane logowania?';

  @override
  String get includeLoginInfoContent =>
      'Czy dołączyć do kopii zapasowej dane logowania wszystkich zapisanych kont?\n\nUłatwia to przywrócenie na nowym urządzeniu, ale plik będzie zawierał Twoje tokeny uwierzytelniania.';

  @override
  String get noSettingsOnly => 'Nie, tylko ustawienia';

  @override
  String get yesIncludeAccounts => 'Tak, dołącz konta';

  @override
  String get backupSavedWithAccounts => 'Zapisano kopię zapasową (z kontami)';

  @override
  String get backupSavedSettingsOnly =>
      'Zapisano kopię zapasową (tylko ustawienia)';

  @override
  String backupFailed(String error) {
    return 'Tworzenie kopii nie powiodło się: $error';
  }

  @override
  String get restoreBackupTitle => 'Przywrócić kopię zapasową?';

  @override
  String get restoreBackupContent =>
      'Wszystkie bieżące ustawienia zostaną zastąpione wartościami z kopii zapasowej.';

  @override
  String fromAbsorbVersion(String version) {
    return 'Z Absorb v$version';
  }

  @override
  String restoreAccountsChip(int count) {
    return 'Konta: $count';
  }

  @override
  String restoreBookmarksChip(int count) {
    return 'Zakładki dla książek: $count';
  }

  @override
  String get restoreCustomHeadersChip => 'Niestandardowe nagłówki';

  @override
  String get invalidBackupFile => 'Nieprawidłowy plik kopii zapasowej';

  @override
  String get settingsRestoredSuccessfully => 'Ustawienia przywrócone pomyślnie';

  @override
  String restoreFailed(String error) {
    return 'Przywracanie nie powiodło się: $error';
  }

  @override
  String get logOutTitle => 'Wylogować?';

  @override
  String get logOutContent =>
      'Zostaniesz wylogowany. Pobrane pozycje pozostaną na tym urządzeniu.';

  @override
  String get signOut => 'Wyloguj';

  @override
  String get changePasswordTitle => 'Zmień hasło';

  @override
  String get changePasswordSubtitle =>
      'Bezpiecznie zaktualizuj hasło do Audiobookshelf';

  @override
  String get currentPassword => 'Obecne hasło';

  @override
  String get newPassword => 'Nowe hasło';

  @override
  String get confirmNewPassword => 'Potwierdź nowe hasło';

  @override
  String get passwordChangeEffect =>
      'Zmiana hasła wylogowuje Twoje pozostałe sesje Audiobookshelf. To urządzenie pozostanie zalogowane.';

  @override
  String get passwordFieldsRequired => 'Wypełnij wszystkie pola hasła';

  @override
  String get passwordsDoNotMatch => 'Nowe hasła nie są takie same';

  @override
  String get passwordChanged =>
      'Hasło zmienione. Pozostałe zalogowane urządzenia zostały rozłączone.';

  @override
  String get passwordInvalid => 'Obecne hasło jest nieprawidłowe';

  @override
  String get passwordChangeUnsupported =>
      'Ta wersja serwera nie obsługuje bezpiecznej zmiany hasła w Absorb';

  @override
  String get passwordChangeFailed => 'Nie udało się zmienić hasła';

  @override
  String get otherUserPasswordResetWarning =>
      'Zmiana tego hasła wyloguje użytkownika na wszystkich urządzeniach.';

  @override
  String get manageSessionsTitle => 'Zalogowane urządzenia';

  @override
  String get manageSessionsSubtitle =>
      'Przeglądaj i usuwaj sesje Audiobookshelf';

  @override
  String get sessionsCurrent => 'To urządzenie';

  @override
  String get sessionsUnknownDevice => 'Nieznane urządzenie';

  @override
  String sessionsLastActive(String date) {
    return 'Ostatnia aktywność: $date';
  }

  @override
  String get sessionsNone => 'Brak aktywnych sesji';

  @override
  String get sessionsLoadMore => 'Wczytaj więcej';

  @override
  String get sessionsUnsupported =>
      'Zarządzanie sesjami wymaga Audiobookshelf 2.36 lub nowszego.';

  @override
  String get sessionsLoadFailed =>
      'Nie udało się wczytać zalogowanych urządzeń';

  @override
  String get sessionsLegacyNotice =>
      'To logowanie nie ma sesji odświeżania, więc Absorb nie może zidentyfikować tego urządzenia na liście.';

  @override
  String get sessionsRemove => 'Wyloguj urządzenie';

  @override
  String get sessionsRemoveTitle => 'Wylogować to urządzenie?';

  @override
  String get sessionsRemoveContent =>
      'To usuwa jego sesję odświeżania. Jego bieżący dostęp może działać, dopóki nie wygaśnie krótkotrwały token.';

  @override
  String get sessionsRemoved => 'Urządzenie wylogowane';

  @override
  String get sessionsRemoveFailed => 'Nie udało się wylogować tego urządzenia';

  @override
  String get sessionsSignOutAll => 'Wyloguj wszystkie urządzenia';

  @override
  String get sessionsSignOutAllTitle => 'Wylogować wszędzie?';

  @override
  String get sessionsSignOutAllContent =>
      'To usuwa wszystkie sesje odświeżania, w tym tego urządzenia. Istniejące tokeny dostępu mogą działać do czasu ich wygaśnięcia.';

  @override
  String podcastScheduleServerTime(String timeZone) {
    return 'Harmonogram używa czasu serwera ($timeZone)';
  }

  @override
  String get podcastScheduleServerTimeUnknown =>
      'Harmonogram używa czasu serwera';

  @override
  String get editServerAddressTitle => 'Edytuj adres serwera';

  @override
  String editServerAddressSubtitle(String username) {
    return 'Zaktualizuj adres dla $username. Użyj tego, jeśli adres Twojego serwera się zmienił - to nadal ten sam serwer, tylko nowy URL. Statystyki i pobrane pozycje zostaną zachowane.';
  }

  @override
  String get editServerAddressField => 'Adres serwera';

  @override
  String get editServerAddressUpdated => 'Adres serwera zaktualizowany';

  @override
  String get editServerAddressFailed =>
      'Nie udało się zaktualizować adresu serwera';

  @override
  String get editServerAddressAction => 'Edytuj adres serwera';

  @override
  String get editServerConnectionTitle => 'Edytuj połączenie z serwerem';

  @override
  String editServerConnectionSubtitle(String username) {
    return 'Zaktualizuj adres serwera i niestandardowe nagłówki dla $username. Statystyki i pobrane pozycje zostaną zachowane.';
  }

  @override
  String get editServerConnectionAction => 'Edytuj połączenie z serwerem';

  @override
  String get editServerConnectionUpdated =>
      'Połączenie z serwerem zaktualizowane';

  @override
  String get editServerConnectionFailed =>
      'Nie udało się zaktualizować połączenia z serwerem';

  @override
  String get editCustomHeadersDescription =>
      'Używane dla tuneli Cloudflare lub serwerów reverse proxy. Te nagłówki dotyczą tylko tego zapisanego konta.';

  @override
  String get removeAccountAction => 'Usuń konto';

  @override
  String get removeAccountTitle => 'Usunąć konto?';

  @override
  String removeAccountContent(String username, String server) {
    return 'Usunąć $username na $server z zapisanych kont?\n\nZawsze możesz dodać je ponownie, logując się jeszcze raz.';
  }

  @override
  String get switchAccountTitle => 'Przełączyć konto?';

  @override
  String switchAccountContent(String username, String server) {
    return 'Przełączyć na $username na $server?\n\nBieżące odtwarzanie zostanie zatrzymane, a aplikacja przeładuje się z danymi drugiego konta.';
  }

  @override
  String get switchButton => 'Przełącz';

  @override
  String get downloadLocationSheetTitle => 'Lokalizacja pobierania';

  @override
  String get downloadLocationSheetSubtitle =>
      'Wybierz, gdzie zapisywane są audiobooki';

  @override
  String get currentLocation => 'Bieżąca lokalizacja';

  @override
  String get existingDownloadsWarning =>
      'Istniejące pobrane pozycje zostają w dotychczasowej lokalizacji. Nowa ścieżka dotyczy tylko nowych pobrań.';

  @override
  String get chooseFolder => 'Wybierz folder';

  @override
  String get chooseDownloadFolder => 'Wybierz folder pobierania';

  @override
  String get storagePermissionDenied =>
      'Uprawnienie do pamięci zostało trwale odrzucone - włącz je w ustawieniach aplikacji';

  @override
  String get openSettings => 'Otwórz Ustawienia';

  @override
  String get storagePermissionRequired =>
      'Uprawnienie do pamięci jest wymagane dla własnych lokalizacji pobierania';

  @override
  String get cannotWriteToFolder =>
      'Nie można zapisywać w tym folderze - wybierz inną lokalizację lub przyznaj dostęp do plików w ustawieniach systemu';

  @override
  String downloadLocationSetTo(String label) {
    return 'Lokalizacja pobierania ustawiona na $label';
  }

  @override
  String get resetToDefault => 'Przywróć domyślne';

  @override
  String get resetToDefaultStorage => 'Przywróć domyślną pamięć';

  @override
  String legacyDownloadsNotice(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count pobranej pozycji znajduje się w starym folderze niestandardowym, którego nie można już otworzyć. Pobierz je ponownie lub zamknij to powiadomienie.',
      many:
          '$count pobranych pozycji znajduje się w starym folderze niestandardowym, którego nie można już otworzyć. Pobierz je ponownie lub zamknij to powiadomienie.',
      few:
          '$count pobrane pozycje znajdują się w starym folderze niestandardowym, którego nie można już otworzyć. Pobierz je ponownie lub zamknij to powiadomienie.',
      one:
          '1 pobrana pozycja znajduje się w starym folderze niestandardowym, którego nie można już otworzyć. Pobierz ją ponownie lub zamknij to powiadomienie.',
    );
    return '$_temp0';
  }

  @override
  String get redownload => 'Pobierz ponownie';

  @override
  String get redownloadStarted => 'Ponowne pobieranie';

  @override
  String get dismiss => 'Zamknij';

  @override
  String get tipsAndHiddenFeatures => 'Wskazówki i ukryte funkcje';

  @override
  String get tipsSubtitle => 'Wykorzystaj Absorb w pełni';

  @override
  String get adminTitle => 'Administracja serwera';

  @override
  String get adminTasksTitle => 'Aktywność serwera';

  @override
  String adminTasksRunning(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count zadania w toku',
      many: '$count zadań w toku',
      few: '$count zadania w toku',
      one: '1 zadanie w toku',
    );
    return '$_temp0';
  }

  @override
  String get adminTasksRecent => 'Ostatnia aktywność serwera';

  @override
  String get adminTasksEmpty => 'Żadne zadania serwera nie są uruchomione';

  @override
  String adminTaskScanSummary(int added, int updated, int missing) {
    return '$added dodano - $updated zaktualizowano - $missing brakuje';
  }

  @override
  String get adminServer => 'Serwer';

  @override
  String get adminVersion => 'Wersja';

  @override
  String get adminUsers => 'Użytkownicy';

  @override
  String get adminOnline => 'Online';

  @override
  String get adminBackup => 'Kopia zapasowa';

  @override
  String get adminPurgeCache => 'Wyczyść pamięć podręczną';

  @override
  String get adminManage => 'Zarządzaj';

  @override
  String adminUsersSubtitle(int userCount, int onlineCount) {
    return 'Konta: $userCount - online: $onlineCount';
  }

  @override
  String get adminPodcasts => 'Podcasty';

  @override
  String get adminPodcastsSubtitle => 'Szukaj, dodawaj i zarządzaj podcastami';

  @override
  String get adminScan => 'Skanuj';

  @override
  String get adminScanning => 'Skanowanie...';

  @override
  String get adminMatchAll => 'Dopasuj wszystko';

  @override
  String get adminMatching => 'Dopasowywanie...';

  @override
  String get adminMatchAllTitle => 'Dopasować wszystkie pozycje?';

  @override
  String adminMatchAllContent(String name) {
    return 'Dopasować metadane wszystkich pozycji w bibliotece $name? Może to chwilę potrwać.';
  }

  @override
  String adminScanStarted(String name) {
    return 'Rozpoczęto skanowanie: $name';
  }

  @override
  String get adminBackupCreated => 'Kopia zapasowa utworzona';

  @override
  String get adminBackupFailed => 'Tworzenie kopii zapasowej nie powiodło się';

  @override
  String get adminCachePurged => 'Pamięć podręczna wyczyszczona';

  @override
  String get adminRmab => 'ReadMeABook';

  @override
  String get adminRmabSubtitle => 'Otwórz w aplikacji';

  @override
  String get adminRmabAdd => 'Dodaj integrację ReadMeABook';

  @override
  String get adminRmabUrlTitle => 'Adres URL ReadMeABook';

  @override
  String get adminRmabUrlHelp =>
      'Wklej swój adres URL z tokenem logowania. Wygeneruj go w RMAB, Admin, Users.';

  @override
  String get adminRmabUrlHint => 'https://rmab.example.com/?token=...';

  @override
  String get adminRmabInvalidUrl => 'Wpisz prawidłowy adres URL http(s)';

  @override
  String get adminRmabSaved => 'Zapisano ReadMeABook';

  @override
  String get adminRmabRemoved => 'Usunięto ReadMeABook';

  @override
  String get adminRmabReload => 'Wczytaj ponownie';

  @override
  String get adminRmabLoadFailed =>
      'Nie udało się wczytać ReadMeABook. Sprawdź adres URL.';

  @override
  String get adminRmabConnected => 'Połączono';

  @override
  String get adminRmabAskAdmin =>
      'Poproś administratora serwera o adres URL logowania';

  @override
  String get adminRmabUrlHelpUser =>
      'Poproś administratora serwera o adres URL logowania. Generuje się go w RMAB > Admin > Users.';

  @override
  String get adminRmabSettingsInfo =>
      'ReadMeABook to samodzielnie hostowana usługa do zgłaszania próśb o audiobooki i ich pobierania. Musi zostać zainstalowana i skonfigurowana przez administratora serwera.';

  @override
  String get rmabConfigTitle => 'Połącz ReadMeABook';

  @override
  String get rmabConfigExplainerAdmin =>
      'ReadMeABook to samodzielnie hostowana usługa do zgłaszania próśb o audiobooki. Wygeneruj token API w RMAB w Admin Dashboard > Settings > API, a następnie wklej poniżej adres URL serwera i token. Absorb niczego nie hostuje ani nie pobiera, jedynie wysyła prośby do Twojego serwera.';

  @override
  String get rmabConfigExplainerUser =>
      'ReadMeABook to samodzielnie hostowana usługa do zgłaszania próśb o audiobooki. Poproś administratora serwera o adres URL RMAB i token API. Absorb niczego nie hostuje ani nie pobiera, jedynie wysyła prośby do Twojego serwera.';

  @override
  String get rmabConfigLearnMore => 'Dowiedz się więcej o ReadMeABook';

  @override
  String get rmabConfigBaseUrlLabel => 'Adres URL serwera RMAB';

  @override
  String get rmabConfigBaseUrlHint => 'https://rmab.example.com';

  @override
  String get rmabConfigTokenLabel => 'Token API';

  @override
  String get rmabConfigTokenHint => 'rmab_...';

  @override
  String get rmabConfigLegacyUrlLabel =>
      'Adres URL logowania do interfejsu WWW (opcjonalnie)';

  @override
  String get rmabConfigLegacyUrlHint => 'https://rmab.example.com/?token=...';

  @override
  String get rmabConfigLegacyUrlHelp =>
      'Wklej adres URL z automatycznym logowaniem, aby „Otwórz w widoku przeglądarki” zalogował Cię od razu. Zostaw puste, aby użyć zwykłego logowania.';

  @override
  String get rmabConfigHeadersHelp =>
      'Dodatkowe nagłówki wysyłane z każdym żądaniem do ReadMeABook, dla serwerów reverse proxy takich jak Cloudflare Access.';

  @override
  String get rmabConfigConnect => 'Połącz';

  @override
  String get rmabConfigDisconnect => 'Rozłącz';

  @override
  String get rmabConfigOpenWebView => 'Otwórz w widoku przeglądarki';

  @override
  String rmabConfigConnectedAs(String name) {
    return 'Połączono jako $name';
  }

  @override
  String get rmabConfigErrorInvalidUrl => 'Wpisz prawidłowy adres URL http(s)';

  @override
  String get rmabConfigErrorMissingToken => 'Wpisz swój token API';

  @override
  String get rmabConfigErrorUnauthorized => 'Token odrzucony przez serwer';

  @override
  String get rmabConfigErrorForbidden =>
      'Ten token nie ma uprawnień do tej akcji';

  @override
  String get rmabConfigErrorNetwork =>
      'Nie można połączyć się z RMAB. Sprawdź adres URL.';

  @override
  String get rmabConfigErrorGeneric => 'Nie udało się połączyć';

  @override
  String get rmabConfigSavedSnackbar => 'ReadMeABook połączony';

  @override
  String get rmabConfigDisconnectedSnackbar => 'ReadMeABook rozłączony';

  @override
  String get rmabRequestCta => 'Poproś przez ReadMeABook';

  @override
  String get rmabSearchHeader => 'Poproś przez ReadMeABook';

  @override
  String get rmabSearchHint => 'Szukaj po tytule lub autorze';

  @override
  String get rmabSearchEmpty => 'Brak dopasowań na Twoim serwerze ReadMeABook';

  @override
  String get rmabSearchError => 'Nie udało się przeszukać ReadMeABook';

  @override
  String get rmabSearchPrompt => 'Wpisz tytuł lub autora, aby wyszukać';

  @override
  String get rmabSearchFooterPrompt => 'Szukasz czegoś innego?';

  @override
  String rmabSearchFooterCta(String query) {
    return 'Szukaj „$query” w ReadMeABook';
  }

  @override
  String get rmabBookDetailExplainer =>
      'Ta prośba zostanie wysłana przez Twój serwer ReadMeABook. Administrator ją sprawdzi i zrealizuje. Możesz ją śledzić w Moje prośby na kafelku ReadMeABook.';

  @override
  String get rmabBookAlreadyAvailable => 'Już w Twojej bibliotece';

  @override
  String get rmabBookAlreadyRequested => 'Już zgłoszono prośbę';

  @override
  String get rmabRequestSubmitting => 'Wysyłanie…';

  @override
  String get rmabRequestSent => 'Prośba wysłana';

  @override
  String get rmabRequestErrorAlreadyAvailable => 'Już w Twojej bibliotece';

  @override
  String get rmabRequestErrorBeingProcessed => 'Już jest przetwarzana';

  @override
  String get rmabRequestErrorDuplicate => 'Już o to poprosiłeś';

  @override
  String get rmabRequestErrorValidation => 'Nie udało się wysłać prośby';

  @override
  String get rmabRequestErrorUserNotFound =>
      'Użytkownik tokenu już nie istnieje. Połącz ponownie ReadMeABook.';

  @override
  String get rmabRequestErrorIgnored =>
      'Ta książka jest na Twojej liście ignorowanych';

  @override
  String get rmabRequestErrorGeneric => 'Nie udało się wysłać prośby';

  @override
  String get rmabRequestErrorTokenRejected =>
      'Token odrzucony przez serwer. Połącz ponownie ReadMeABook.';

  @override
  String get rmabMyRequestsTab => 'Moje prośby';

  @override
  String get rmabSetupTab => 'Konfiguracja';

  @override
  String get rmabMyRequestsEmpty => 'Nie poprosiłeś jeszcze o żadne książki';

  @override
  String get rmabMyRequestsError => 'Nie udało się wczytać próśb';

  @override
  String get rmabMyRequestsRefresh => 'Odśwież';

  @override
  String get rmabRequestDetailTitle => 'Szczegóły prośby';

  @override
  String get rmabRequestDetailStatus => 'Status';

  @override
  String get rmabRequestDetailRequestedOn => 'Zgłoszono';

  @override
  String get rmabRequestDetailCompletedOn => 'Ukończono';

  @override
  String get rmabRequestDetailProgress => 'Postęp';

  @override
  String get rmabStatusActive => 'W toku';

  @override
  String get rmabStatusWaiting => 'Oczekuje';

  @override
  String get rmabStatusAvailable => 'Dostępna';

  @override
  String get rmabStatusDownloaded => 'Pobrana';

  @override
  String get rmabStatusFailed => 'Niepowodzenie';

  @override
  String get rmabStatusCancelled => 'Anulowana';

  @override
  String get rmabStatusDenied => 'Odmówiono';

  @override
  String get rmabStatusUnknown => 'Nieznany';

  @override
  String narratedBy(String narrator) {
    return 'Czyta: $narrator';
  }

  @override
  String get onAudible => 'w Audible';

  @override
  String percentComplete(String percent) {
    return 'Ukończono $percent%';
  }

  @override
  String get absorbing => 'Przyswajanie...';

  @override
  String get absorbAgain => 'Przyswój ponownie';

  @override
  String get absorb => 'Przyswój';

  @override
  String get ebookOnlyNoAudio => 'Tylko e-book - bez audio';

  @override
  String get absorbAudioNotDownloaded => 'Audio nie zostało pobrane';

  @override
  String get absorbAudioNotDownloadedEbookOnly =>
      'Audio nie zostało pobrane, tylko e-book';

  @override
  String get fullyAbsorbed => 'W pełni przyswojone';

  @override
  String get fullyAbsorbAction => 'Przyswój w pełni';

  @override
  String get removeFromAbsorbing => 'Usuń z Absorbing';

  @override
  String get addToAbsorbing => 'Dodaj do Absorbing';

  @override
  String get absorbNext => 'Przyswój następne';

  @override
  String get absorbNextAdded => 'Następne w Absorbing';

  @override
  String get absorbLast => 'Przyswój na końcu';

  @override
  String get absorbNextHint => 'Zaraz po tym, co teraz gra';

  @override
  String get absorbLastHint => 'Na końcu listy';

  @override
  String get removedFromAbsorbing => 'Usunięto z Absorbing';

  @override
  String get addedToAbsorbing => 'Dodano do Absorbing';

  @override
  String get removeFromContinueListening => 'Usuń z Kontynuuj słuchanie';

  @override
  String get removedFromContinueListening => 'Usunięto z Kontynuuj słuchanie';

  @override
  String get removeFromContinueReading => 'Usuń z Kontynuuj czytanie';

  @override
  String get removedFromContinueReading => 'Usunięto z Kontynuuj czytanie';

  @override
  String get sessionAdd => 'Dodaj sesję';

  @override
  String get sessionStartLabel => 'Rozpoczęto o';

  @override
  String get sessionAdded => 'Dodano sesję';

  @override
  String get sessionAddFailed => 'Nie udało się dodać sesji';

  @override
  String get removeSeriesFromContinueSeries => 'Usuń z Kontynuuj serię';

  @override
  String get removedSeriesFromContinueSeries => 'Usunięto z Kontynuuj serię';

  @override
  String get couldNotUpdate => 'Nie udało się zaktualizować, spróbuj ponownie';

  @override
  String get addToPlaylist => 'Dodaj do playlisty';

  @override
  String get addToCollection => 'Dodaj do kolekcji';

  @override
  String get downloadEbook => 'Pobierz e-book';

  @override
  String get downloadEbookAgain => 'Pobierz e-book ponownie';

  @override
  String get resetProgress => 'Zresetuj postęp';

  @override
  String get lookupLocalMetadata => 'Wyszukaj lokalne metadane';

  @override
  String get reLookupLocalMetadata => 'Wyszukaj lokalne metadane ponownie';

  @override
  String get clearLocalMetadata => 'Wyczyść lokalne metadane';

  @override
  String get searchOnGoodreads => 'Szukaj w Goodreads';

  @override
  String get editServerDetails => 'Edytuj dane serwera';

  @override
  String get encodeTab => 'Kodowanie';

  @override
  String get codec => 'Kodek';

  @override
  String get bitrate => 'Przepływność';

  @override
  String get channels => 'Kanały';

  @override
  String get mono => 'Mono';

  @override
  String get stereo => 'Stereo';

  @override
  String get startM4bEncode => 'Rozpocznij kodowanie M4B';

  @override
  String get encodeStarted => 'Rozpoczęto kodowanie M4B';

  @override
  String get encodeFailed => 'Nie udało się rozpocząć kodowania';

  @override
  String get encodeFinished => 'Zakończono kodowanie M4B';

  @override
  String get currentlyLabel => 'Obecnie:';

  @override
  String encodeOutputPathNote(String path) {
    return 'Gotowy plik M4B zostanie umieszczony w folderze z audiobookami: $path/';
  }

  @override
  String encodeBackupNote(String itemId) {
    return 'Kopia zapasowa oryginalnych plików audio zostanie zapisana w: /metadata/cache/items/$itemId/. Pamiętaj, aby co jakiś czas czyścić pamięć podręczną elementów.';
  }

  @override
  String get encodeTimeNote => 'Kodowanie może potrwać do 30 minut.';

  @override
  String get encodeRescanNote =>
      'Jeśli obserwator jest wyłączony, po zakończeniu trzeba ponownie przeskanować ten audiobook.';

  @override
  String get aboutSection => 'Informacje';

  @override
  String chaptersCount(int count) {
    return 'Rozdziały ($count)';
  }

  @override
  String audioTracksCount(int count) {
    return 'Ścieżki audio ($count)';
  }

  @override
  String libraryFilesCount(int count) {
    return 'Pliki biblioteki ($count)';
  }

  @override
  String get chapters => 'Rozdziały';

  @override
  String get noChaptersBook => 'Ta książka nie ma rozdziałów';

  @override
  String get noChaptersPodcast => 'Ten podcast nie ma rozdziałów';

  @override
  String get failedToLoad => 'Nie udało się wczytać';

  @override
  String startedDate(String date) {
    return 'Rozpoczęto $date';
  }

  @override
  String finishedDate(String date) {
    return 'Ukończono $date';
  }

  @override
  String andCountMore(int count) {
    return 'i $count więcej';
  }

  @override
  String get markAsFullyAbsorbedQuestion =>
      'Oznaczyć jako w pełni przesłuchane?';

  @override
  String get markAsFullyAbsorbedContent =>
      'Postęp zostanie ustawiony na 100%, a odtwarzanie zatrzymane, jeśli ta książka jest odtwarzana.';

  @override
  String get markedAsFinishedNiceWork =>
      'Oznaczono jako ukończone – dobra robota!';

  @override
  String get failedToUpdateCheckConnection =>
      'Nie udało się zaktualizować – sprawdź połączenie';

  @override
  String get markedFinishedWillSync =>
      'Oznaczono jako ukończone – zsynchronizuje się po powrocie do sieci';

  @override
  String get markAsNotFinishedQuestion => 'Oznaczyć jako nieukończone?';

  @override
  String get markAsNotFinishedContent =>
      'Status ukończenia zostanie usunięty, a pozycja wróci na początek.';

  @override
  String get unmark => 'Odznacz';

  @override
  String get markedAsNotFinishedBackAtIt =>
      'Oznaczono jako nieukończone – wracamy do słuchania!';

  @override
  String get resetProgressQuestion => 'Zresetować postęp?';

  @override
  String get resetProgressListeningAndReading =>
      'Postęp słuchania i czytania wróci do 0%.';

  @override
  String get resetProgressListening => 'Postęp słuchania wróci do 0%.';

  @override
  String get resetProgressReading => 'Postęp czytania wróci do 0%.';

  @override
  String get resetProgressMarksUnread =>
      'Książka zostanie też oznaczona jako nieprzeczytana.';

  @override
  String get resetProgressCantUndo => 'Tej operacji nie można cofnąć.';

  @override
  String get progressResetFreshStart => 'Postęp zresetowany – świeży start!';

  @override
  String get clearLocalMetadataQuestion => 'Wyczyścić lokalne metadane?';

  @override
  String get clearLocalMetadataContent =>
      'Zapisane lokalnie metadane zostaną usunięte i przywrócone zostaną te z serwera.';

  @override
  String get localMetadataCleared => 'Lokalne metadane wyczyszczone';

  @override
  String get saveEbook => 'Zapisz e-book';

  @override
  String get noEbookFileFound => 'Nie znaleziono pliku e-booka';

  @override
  String get bookmark => 'Zakładka';

  @override
  String get bookmarks => 'Zakładki';

  @override
  String bookmarksWithCount(int count) {
    return 'Zakładki ($count)';
  }

  @override
  String get playbackSpeed => 'Prędkość odtwarzania';

  @override
  String get noBookmarksYet => 'Brak zakładek';

  @override
  String get longPressBookmarkHint =>
      'Przytrzymaj przycisk zakładki, aby szybko zapisać';

  @override
  String get addBookmark => 'Dodaj zakładkę';

  @override
  String get editBookmark => 'Edytuj zakładkę';

  @override
  String get titleLabel => 'Tytuł';

  @override
  String get noteOptionalLabel => 'Notatka (opcjonalnie)';

  @override
  String get editLayout => 'Edytuj układ';

  @override
  String get inMenu => 'W menu';

  @override
  String get bookmarkAdded => 'Dodano zakładkę';

  @override
  String get startPlayingSomethingFirst => 'Najpierw włącz odtwarzanie';

  @override
  String get playbackHistory => 'Historia odtwarzania';

  @override
  String get historyLocalTab => 'Historia';

  @override
  String get historyServerTab => 'Sesje';

  @override
  String get historyNoServerSessions => 'Brak sesji serwera dla tego elementu';

  @override
  String get historyServerLoadFailed => 'Nie udało się wczytać sesji serwera';

  @override
  String get clearHistoryTooltip => 'Wyczyść historię';

  @override
  String get tapEventToJump => 'Dotknij zdarzenia, aby przejść do tej pozycji';

  @override
  String get noHistoryYet => 'Brak historii';

  @override
  String jumpedToPosition(String position) {
    return 'Przeskoczono do $position';
  }

  @override
  String booksInSeriesCount(int count) {
    return 'Książek w serii: $count';
  }

  @override
  String bookNumber(String number) {
    return 'Książka $number';
  }

  @override
  String downloadRemainingCount(int count) {
    return 'Pobierz pozostałe ($count)';
  }

  @override
  String get downloadAll => 'Pobierz wszystkie';

  @override
  String get markAllNotFinished => 'Oznacz wszystkie jako nieukończone';

  @override
  String get markAllFinished => 'Oznacz wszystkie jako ukończone';

  @override
  String get markAllNotFinishedQuestion =>
      'Oznaczyć wszystkie jako nieukończone?';

  @override
  String get fullyAbsorbSeries => 'Przesłuchać całą serię?';

  @override
  String get turnAutoDownloadOff => 'Wyłącz automatyczne pobieranie';

  @override
  String get turnAutoDownloadOn => 'Włącz automatyczne pobieranie';

  @override
  String get autoDownloadThisSeries => 'Automatycznie pobierać tę serię?';

  @override
  String get autoDownloadSeriesContent =>
      'Kolejne książki będą pobierane automatycznie podczas słuchania.';

  @override
  String get standalone => 'Samodzielne';

  @override
  String get episodes => 'Odcinki';

  @override
  String get noEpisodesFound => 'Nie znaleziono odcinków';

  @override
  String get markFinished => 'Oznacz jako ukończone';

  @override
  String get markUnfinished => 'Oznacz jako nieukończone';

  @override
  String get allEpisodes => 'Wszystkie odcinki';

  @override
  String get aboutThisEpisode => 'O tym odcinku';

  @override
  String get reversePlayOrder => 'Odwróć kolejność odtwarzania';

  @override
  String selectedCount(int count) {
    return 'Wybrano: $count';
  }

  @override
  String get selectAll => 'Zaznacz wszystko';

  @override
  String get deselectAll => 'Odznacz wszystko';

  @override
  String get autoDownloadThisPodcast => 'Automatycznie pobierać ten podcast?';

  @override
  String get autoDownloadPodcastContent =>
      'Kolejne odcinki będą pobierane automatycznie podczas słuchania.';

  @override
  String get download => 'Pobierz';

  @override
  String get deleteDownload => 'Usuń pobrane';

  @override
  String get casting => 'Przesyłanie';

  @override
  String get castingTo => 'Przesyłanie do';

  @override
  String get editDetails => 'Edytuj szczegóły';

  @override
  String get quickMatch => 'Szybkie dopasowanie';

  @override
  String get quickMatchNoUpdates => 'Aktualizacja nie jest potrzebna';

  @override
  String get custom => 'Własne';

  @override
  String get authorOptionalLabel => 'Autor (opcjonalnie)';

  @override
  String get noResultsFound =>
      'Brak wyników.\nSpróbuj zmienić wyszukiwanie lub dostawcę.';

  @override
  String get searchForMetadataAbove => 'Wyszukaj metadane powyżej';

  @override
  String get applyThisMatch => 'Zastosować to dopasowanie?';

  @override
  String get metadataUpdated => 'Zaktualizowano metadane';

  @override
  String get failedToUpdateMetadata => 'Nie udało się zaktualizować metadanych';

  @override
  String get subtitleLabel => 'Podtytuł';

  @override
  String get authorLabel => 'Autor';

  @override
  String get narratorLabel => 'Lektor';

  @override
  String get seriesLabel => 'Seria';

  @override
  String get addSeries => 'Dodaj serię';

  @override
  String get removeSeries => 'Usuń serię';

  @override
  String get descriptionLabel => 'Opis';

  @override
  String get publisherLabel => 'Wydawca';

  @override
  String get yearLabel => 'Rok';

  @override
  String get genresLabel => 'Gatunki';

  @override
  String get tagsLabel => 'Tagi';

  @override
  String get commaSeparated => 'Oddzielone przecinkami';

  @override
  String get asinLabel => 'ASIN';

  @override
  String get isbnLabel => 'ISBN';

  @override
  String get coverImage => 'Okładka';

  @override
  String get coverRemove => 'Usuń okładkę';

  @override
  String get coverRemoveConfirm =>
      'Usunąć okładkę tej książki? Zamiast niej zostanie pokazana wygenerowana karta z tytułem.';

  @override
  String get coverRemoved => 'Okładka usunięta';

  @override
  String get coverRemoveFailed => 'Nie udało się usunąć okładki';

  @override
  String get coverUrlLabel => 'URL okładki';

  @override
  String get coverUrlHint => 'https://...';

  @override
  String get localMetadata => 'Lokalne metadane';

  @override
  String get overrideLocalDisplay => 'Zastąp lokalny wygląd';

  @override
  String get metadataSavedLocally => 'Metadane zapisane lokalnie';

  @override
  String get notes => 'Notatki';

  @override
  String get newNote => 'Nowa notatka';

  @override
  String get editNote => 'Edytuj notatkę';

  @override
  String get noNotesYet => 'Brak notatek';

  @override
  String get markdownIsSupported => 'Obsługiwany jest Markdown';

  @override
  String get markdownMd => 'Markdown (.md)';

  @override
  String get keepsFormattingIntact => 'Zachowuje formatowanie';

  @override
  String get plainTextTxt => 'Zwykły tekst (.txt)';

  @override
  String get simpleTextNoFormatting => 'Prosty tekst, bez formatowania';

  @override
  String get untitledNote => 'Notatka bez tytułu';

  @override
  String get titleHint => 'Tytuł';

  @override
  String get noteBodyHint => 'Napisz notatkę... (obsługuje Markdown)';

  @override
  String get nothingToPreview => 'Brak podglądu';

  @override
  String get audioEnhancements => 'Ulepszenia dźwięku';

  @override
  String get presets => 'PRESETY';

  @override
  String get equalizer => 'EKWALIZER';

  @override
  String get effects => 'EFEKTY';

  @override
  String get bassBoost => 'Wzmocnienie basów';

  @override
  String get surround => 'Surround';

  @override
  String get loudness => 'Głośność (loudness)';

  @override
  String get pitch => 'Wysokość tonu';

  @override
  String get monoAudio => 'Dźwięk mono';

  @override
  String get skipSilence => 'Pomijaj ciszę';

  @override
  String get resetAll => 'Zresetuj wszystko';

  @override
  String get collectionNotFound => 'Nie znaleziono kolekcji';

  @override
  String get deleteCollection => 'Usuń kolekcję';

  @override
  String get deleteCollectionContent => 'Na pewno usunąć tę kolekcję?';

  @override
  String get deleteCollectionFailed => 'Nie udało się usunąć kolekcji';

  @override
  String get deletePermissionRequired =>
      'Wymagane uprawnienie do usuwania. Poproś głównego administratora o jego nadanie.';

  @override
  String get deleteFilesCheckbox => 'Usuń też pliki z serwera';

  @override
  String get deleteFilesCheckedHint =>
      'Pliki zostaną trwale usunięte z serwera.';

  @override
  String get deleteFilesUncheckedHint =>
      'Pliki pozostaną na serwerze, więc kolejne skanowanie biblioteki może je dodać z powrotem.';

  @override
  String get deleteFromServerAction => 'Usuń z serwera';

  @override
  String get deleteFromServerTitle => 'Usuń z serwera';

  @override
  String deleteFromServerContent(String title) {
    return 'Usunąć „$title” z Audiobookshelf?';
  }

  @override
  String deletedFromServer(String title) {
    return 'Usunięto „$title”';
  }

  @override
  String get deleteFromServerFailed =>
      'Nie udało się usunąć. Sprawdź logi serwera.';

  @override
  String get playlistNotFound => 'Nie znaleziono playlisty';

  @override
  String get deletePlaylist => 'Usuń playlistę';

  @override
  String get deletePlaylistContent => 'Na pewno usunąć tę playlistę?';

  @override
  String get newPlaylist => 'Nowa playlista';

  @override
  String get playlistNameHint => 'Nazwa playlisty';

  @override
  String addedToName(String name) {
    return 'Dodano do „$name”';
  }

  @override
  String get failedToAdd => 'Nie udało się dodać';

  @override
  String get newCollection => 'Nowa kolekcja';

  @override
  String get collectionNameHint => 'Nazwa kolekcji';

  @override
  String get listsNewCollectionSubtitle => 'Zgrupuj książki na własnej liście';

  @override
  String get listsNewCollectionNeedsBookSubtitle =>
      'Zacznij od co najmniej jednej książki';

  @override
  String get listsNewPlaylistSubtitle => 'Ułóż książki do słuchania po kolei';

  @override
  String get listsAddBooksNow => 'Dodaj książki teraz';

  @override
  String get listsPickBooksNext =>
      'Za chwilę wybierzesz książki. Kolekcja na tym serwerze wymaga co najmniej jednej.';

  @override
  String get listsCreate => 'Utwórz';

  @override
  String get listsCollectionNeedsBook =>
      'Kolekcja wymaga co najmniej jednej książki, więc nic nie utworzono.';

  @override
  String get listsCreateFailed => 'Nie udało się utworzyć';

  @override
  String get castToDevice => 'Prześlij na urządzenie';

  @override
  String get searchingForCastDevices => 'Szukanie urządzeń Cast...';

  @override
  String get castDevice => 'Urządzenie Cast';

  @override
  String get stopCasting => 'Zatrzymaj przesyłanie';

  @override
  String get disconnect => 'Rozłącz';

  @override
  String get audioOutput => 'Wyjście audio';

  @override
  String get noOutputDevicesFound => 'Nie znaleziono urządzeń wyjściowych';

  @override
  String get welcomeToAbsorb => 'Witaj w Absorb';

  @override
  String get welcomeTagline => 'Klient Audiobookshelf.';

  @override
  String get welcomeAbsorbingTitle => 'Absorbowanie';

  @override
  String get welcomeAbsorbingIntro =>
      'Zamiast „odtwarzaj” i „słuchaj” używamy słowa „absorbuj”. Wolisz klasyczne nazewnictwo? Zmienisz je w Ustawieniach.';

  @override
  String get welcomeAbsorbingTabBullet =>
      'Karta Absorbowanie – to, czego aktualnie słuchasz';

  @override
  String get welcomeAbsorbButtonBullet =>
      'Przycisk Absorbuj – rozpoczyna odtwarzanie';

  @override
  String get welcomeFullyAbsorbBullet =>
      'Przesłuchaj w całości – oznacza jako ukończone';

  @override
  String get welcomeGettingAroundTitle => 'Poruszanie się po aplikacji';

  @override
  String get welcomeGettingAroundBody =>
      'Dotknij dowolnej okładki, aby otworzyć szczegóły. Karty Kontynuuj słuchanie działają inaczej – dotknij, aby od razu odtworzyć, przytrzymaj, aby otworzyć szczegóły.';

  @override
  String get welcomeMakeItYoursTitle => 'Dostosuj do siebie';

  @override
  String get welcomeMakeItYoursBody =>
      'Poeksperymentuj w Ustawieniach, aby dopasować Absorb do swoich upodobań. Warto zajrzeć do sekcji Wskazówki i ukryte funkcje.';

  @override
  String get getStarted => 'Zaczynamy';

  @override
  String get showMore => 'Pokaż więcej';

  @override
  String get showLess => 'Pokaż mniej';

  @override
  String get readMore => 'Czytaj więcej';

  @override
  String get removeDownloadQuestion => 'Usunąć pobrane?';

  @override
  String get removeDownloadContent => 'Zostanie usunięte z tego urządzenia.';

  @override
  String get removeWhichDownload =>
      'Audiobook i e-book są na tym urządzeniu. Wybierz, co usunąć.';

  @override
  String get downloadRemoved => 'Usunięto pobrane';

  @override
  String get finished => 'Ukończone';

  @override
  String get saved => 'Pobrane';

  @override
  String get selectLibrary => 'Wybierz bibliotekę';

  @override
  String get switchLibraryTooltip => 'Zmień bibliotekę';

  @override
  String get refreshTooltip => 'Odśwież';

  @override
  String get openNowPlayingTooltip => 'Otwórz Teraz odtwarzane';

  @override
  String get previousChapterTooltip => 'Poprzedni rozdział';

  @override
  String get nextChapterTooltip => 'Następny rozdział';

  @override
  String get noBooksFound => 'Nie znaleziono książek';

  @override
  String get userFallback => 'Użytkownik';

  @override
  String get rootAdmin => 'Główny administrator';

  @override
  String get admin => 'Administrator';

  @override
  String get serverAdmin => 'Administracja serwerem';

  @override
  String get serverAdminSubtitle =>
      'Zarządzaj użytkownikami, bibliotekami i ustawieniami serwera';

  @override
  String serverUpdateAvailable(String version) {
    return 'Dostępna aktualizacja serwera $version';
  }

  @override
  String get justNow => 'Przed chwilą';

  @override
  String minutesAgo(int count) {
    return '$count min temu';
  }

  @override
  String hoursAgo(int count) {
    return '$count godz. temu';
  }

  @override
  String daysAgo(int count) {
    return '$count d. temu';
  }

  @override
  String get audible => 'Audible';

  @override
  String get iTunes => 'iTunes';

  @override
  String get openLibrary => 'Open Library';

  @override
  String get root => 'Root';

  @override
  String get coverPlayPause => 'Odtwarzanie/pauza na okładce';

  @override
  String get coverPlayPauseOnSubtitle =>
      'Włączone – dotknij okładki, aby odtworzyć/wstrzymać';

  @override
  String get coverPlayPauseOffSubtitle =>
      'Wyłączone – osobny przycisk odtwarzania/pauzy w sterowaniu';

  @override
  String get cardBackground => 'Tło karty';

  @override
  String get cardBackgroundBlurred => 'Rozmyte';

  @override
  String get cardBackgroundGradient => 'Gradient';

  @override
  String get cardBackgroundSolid => 'Solid';

  @override
  String get cardSwipeStyle => 'Card swipe style';

  @override
  String get cardSwipeStyleClassic => 'Classic';

  @override
  String get cardSwipeStyleCarousel => 'Carousel';

  @override
  String get cardSwipeStyleStack => 'Stack';

  @override
  String get queueModeMergedSubtitle =>
      'Odtwarzanie się zatrzymuje, ręczna kolejka lub automatyczne odtwarzanie następnego elementu';

  @override
  String get queueModeSeriesLabel => 'Seria';

  @override
  String get queueModeShowLabel => 'Audycja';

  @override
  String get queueModeInfoSeries => 'Seria';

  @override
  String get queueModeInfoSeriesDesc =>
      'Automatycznie odtwarza następną książkę w serii lub następny odcinek audycji podcastowej.';

  @override
  String get resetButtonGridQuestion => 'Zresetować siatkę przycisków?';

  @override
  String get resetButtonGridContent =>
      'Przywróci to domyślny układ, kolejność i przełączniki przycisków.';

  @override
  String get reset => 'Zresetuj';

  @override
  String get buttonGridReset => 'Siatka przycisków zresetowana';

  @override
  String get resetButtonGrid => 'Zresetuj siatkę przycisków';

  @override
  String get chapterBarrierOnRewind =>
      'Bariera rozdziału przy przewijaniu wstecz';

  @override
  String get chapterBarrierInfoTitle => 'Bariera rozdziału';

  @override
  String get chapterBarrierInfoContent =>
      'Przy przewijaniu wstecz odtwarzanie zatrzyma się na początku bieżącego rozdziału zamiast przechodzić do poprzedniego.\n\nDotknij dwukrotnie przycisku przewijania wstecz w ciągu 2 sekund, aby przejść przez barierę.';

  @override
  String get chapterBarrierOnRewindOnSubtitle =>
      'Włączone – przewijanie wstecz zatrzymuje się na początku rozdziału';

  @override
  String get chapterBarrierOnRewindOffSubtitle =>
      'Wyłączone – przewijanie wstecz przekracza granice rozdziałów';

  @override
  String autoRewindOnSubtitleFormat(String min, String max) {
    return 'Włączone – od $min s do $max s w zależności od długości pauzy';
  }

  @override
  String get rewindOnSessionStart => 'Cofnij na początku sesji';

  @override
  String get rewindOnSessionStartInfoContent =>
      'Zwykłe automatyczne cofanie działa po wznowieniu z pauzy w aktywnej sesji. To ustawienie dodaje cofnięcie na początku zupełnie nowej sesji – na przykład po zamknięciu aplikacji, zatrzymaniu odtwarzania lub świeżym uruchomieniu aplikacji.\n\nGdy jest włączone, odtwarzanie cofa się o maksymalną wartość na początku każdej nowej sesji, aby można było ponownie usłyszeć miejsce, w którym skończyłeś.';

  @override
  String rewindOnSessionStartOnSubtitle(String seconds) {
    return 'Włączone – cofa o $seconds s na początku nowej sesji';
  }

  @override
  String rewindActivationDelayValue(String seconds) {
    return '$seconds s+';
  }

  @override
  String rewindRangeValue(String min, String max) {
    return '$min s – $max s';
  }

  @override
  String rewindSecondsPause(String seconds) {
    return 'pauza $seconds s';
  }

  @override
  String rewindMinPause(String minutes) {
    return 'pauza $minutes min';
  }

  @override
  String rewindHrPause(String hours) {
    return 'pauza $hours godz.';
  }

  @override
  String get rewindOneHrPause => 'pauza 1 godz.';

  @override
  String speedValue(String speed) {
    return '${speed}x';
  }

  @override
  String secondsValue(String seconds) {
    return '$seconds s';
  }

  @override
  String minutesValue(int minutes) {
    return '$minutes min';
  }

  @override
  String get chimeBeforeSleep => 'Dźwięk przed uśpieniem';

  @override
  String get chimeBeforeSleepOnSubtitle =>
      'Odtwarza delikatny dzwonek, gdy timer zaraz się skończy';

  @override
  String get chimeBeforeSleepOffSubtitle =>
      'Brak dźwiękowego ostrzeżenia przed uśpieniem';

  @override
  String get windDownDuration => 'Czas wyciszania';

  @override
  String windDownDurationSubtitle(int seconds) {
    return 'Wyciszanie i dzwonek zaczynają się $seconds s przed uśpieniem';
  }

  @override
  String fadeVolumeOnSubtitleDynamic(int seconds) {
    return 'Stopniowo zmniejsza głośność przez ostatnie $seconds s';
  }

  @override
  String autoSleepTimerEnabledSubtitle(
    String start,
    String end,
    String duration,
  ) {
    return '$start – $end · $duration';
  }

  @override
  String get endOfChapterShort => 'Koniec rozdziału';

  @override
  String get endOfChapterOnSubtitle => 'Zatrzymaj na końcu bieżącego rozdziału';

  @override
  String get endOfChapterOffSubtitle => 'Użyj timera uśpienia z czasem';

  @override
  String get showExplicitBadge => 'Pokaż znaczek treści dla dorosłych';

  @override
  String get showExplicitBadgeOnSubtitle =>
      'Elementy z treściami dla dorosłych mają znaczek „E”';

  @override
  String get showExplicitBadgeOffSubtitle => 'Wyłączone – znaczek ukryty';

  @override
  String get showEbookBadge => 'Pokaż znaczek e-booka';

  @override
  String get showEbookBadgeOnSubtitle =>
      'Książki z e-bookiem mają na okładce ikonę książki';

  @override
  String get showEbookBadgeOffSubtitle => 'Wyłączone – znaczek e-booka ukryty';

  @override
  String get libraryFallback => 'Biblioteka';

  @override
  String get preReleaseUpdatesInfoTitle =>
      'Aktualizacje wersji przedpremierowych';

  @override
  String get preReleaseUpdatesInfoContent =>
      'Gdy opcja jest włączona, sprawdzanie aktualizacji powiadomi także o wersjach alfa i przedpremierowych z GitHub. Mogą być mniej stabilne, ale zawierają najnowsze funkcje i poprawki.';

  @override
  String get includePreReleases => 'Uwzględnij wersje przedpremierowe';

  @override
  String get includePreReleasesOnSubtitle =>
      'Włączone – sprawdzanie wersji alfa i przedpremierowych';

  @override
  String get includePreReleasesOffSubtitle =>
      'Wyłączone – tylko wersje stabilne';

  @override
  String get setTooltip => 'Ustaw';

  @override
  String get saveAbsorbBackup => 'Zapisz kopię zapasową Absorb';

  @override
  String get checkForUpdate => 'Sprawdź aktualizacje';

  @override
  String get onLatestVersion => 'Masz najnowszą wersję';

  @override
  String get updateAvailable => 'Dostępna aktualizacja';

  @override
  String get preReleaseAvailable => 'Dostępna wersja przedpremierowa';

  @override
  String updateDialogContent(String kind, String latest, String current) {
    return 'Dostępna jest nowa $kind Absorb: $latest\n\nMasz wersję $current.';
  }

  @override
  String get updateKindPreRelease => 'wersja przedpremierowa';

  @override
  String get updateKindVersion => 'wersja';

  @override
  String get downloadButton => 'Pobierz';

  @override
  String get updateDownloading => 'Pobieranie aktualizacji...';

  @override
  String get updateInstallPermissionDenied =>
      'Odmówiono uprawnień do instalacji. Włącz „Instalowanie nieznanych aplikacji” dla Absorb w ustawieniach systemu.';

  @override
  String get updateOpeningInBrowser =>
      'Aktualizacja w aplikacji nie powiodła się, otwieranie przeglądarki';

  @override
  String get sendToEreader => 'Wyślij na czytnik e-booków';

  @override
  String sendingToEreader(String device) {
    return 'Wysyłanie do $device...';
  }

  @override
  String sendToEreaderSuccess(String device) {
    return 'Wysłano do $device';
  }

  @override
  String get sendToEreaderFailed => 'Nie udało się wysłać e-booka';

  @override
  String get pickEreaderDevice => 'Wybierz urządzenie';

  @override
  String get adminEmail => 'E-mail';

  @override
  String get adminEmailSubtitle => 'SMTP i czytniki e-booków';

  @override
  String get smtpSection => 'SMTP';

  @override
  String get smtpSetupGuide => 'Przewodnik konfiguracji';

  @override
  String get smtpHost => 'Host';

  @override
  String get smtpPort => 'Port';

  @override
  String get smtpSecure => 'Bezpieczne';

  @override
  String get smtpRejectUnauthorized => 'Odrzucaj nieautoryzowane TLS';

  @override
  String get smtpUser => 'Nazwa użytkownika';

  @override
  String get smtpPass => 'Hasło';

  @override
  String get smtpFromAddress => 'Adres nadawcy';

  @override
  String get smtpTestAddress => 'Adres testowy';

  @override
  String get smtpSendTest => 'Wyślij test';

  @override
  String get smtpSaveSettings => 'Zapisz';

  @override
  String get smtpSaved => 'Zapisano ustawienia e-mail';

  @override
  String get smtpSaveFailed => 'Nie udało się zapisać ustawień e-mail';

  @override
  String get smtpTestSent => 'Wysłano e-mail testowy';

  @override
  String get smtpTestFailed => 'Nie udało się wysłać e-maila testowego';

  @override
  String get ereaderDevicesTitle => 'Czytniki e-booków';

  @override
  String get ereaderDevicesEmpty => 'Brak urządzeń. Dodaj je poniżej.';

  @override
  String get addEreaderDevice => 'Dodaj urządzenie';

  @override
  String get editEreaderDevice => 'Edytuj urządzenie';

  @override
  String get deleteEreaderDevice => 'Usuń';

  @override
  String get ereaderDeviceName => 'Nazwa';

  @override
  String get ereaderDeviceEmail => 'E-mail';

  @override
  String get ereaderAvailability => 'Kto może używać tego urządzenia';

  @override
  String get ereaderAvailAdminOrUp => 'Tylko administratorzy';

  @override
  String get ereaderAvailUserOrUp => 'Wszyscy użytkownicy';

  @override
  String get ereaderAvailGuestOrUp => 'Wszyscy';

  @override
  String get ereaderAvailSpecificUsers => 'Wybrani użytkownicy';

  @override
  String ereaderSpecificUsersN(int count) {
    return 'Wybrani użytkownicy ($count)';
  }

  @override
  String get ereaderDevicesSaved => 'Zapisano urządzenia';

  @override
  String get ereaderDevicesSaveFailed => 'Nie udało się zapisać urządzeń';

  @override
  String libraryCountOne(int count) {
    return '$count biblioteka';
  }

  @override
  String libraryCountOther(int count) {
    return '$count bibliotek';
  }

  @override
  String serverVersionLabel(String version) {
    return 'Serwer $version';
  }

  @override
  String appVersionServerSuffix(String version) {
    return '  ·  Serwer $version';
  }

  @override
  String backupDateFormat(int month, int day, int year) {
    return '$day.$month.$year';
  }

  @override
  String get backupDetailsSeparator => ' · ';

  @override
  String get bookmarksSortedByPositionReversed =>
      'Posortowano według pozycji (odwrotnie)';

  @override
  String bookmarksJumpShortContent(String title, String position) {
    return '„$title” przy $position';
  }

  @override
  String get deleteBookmarkQuestion => 'Usunąć zakładkę?';

  @override
  String get cardIconsOnlyChip => 'Tylko ikony';

  @override
  String get cardMoreInGridChip => '„Więcej” w siatce';

  @override
  String get cardLayoutHidden => 'Ukryte';

  @override
  String get speed => 'Prędkość';

  @override
  String get details => 'Szczegóły';

  @override
  String get episodeDetailsLabel => 'Szczegóły odcinka';

  @override
  String get bookDetailsLabel => 'Szczegóły książki';

  @override
  String get equalizerShort => 'EQ';

  @override
  String get equalizerLabel => 'Ekwalizer';

  @override
  String get cast => 'Cast';

  @override
  String castingToDevice(String device) {
    return 'Przesyłanie do $device';
  }

  @override
  String castToDeviceNamed(String device) {
    return 'Prześlij do $device';
  }

  @override
  String get historyShort => 'Historia';

  @override
  String atPosition(String position) {
    return 'przy $position';
  }

  @override
  String chaptersChip(int count) {
    return 'Rozdziałów: $count';
  }

  @override
  String chapterNumber(int number) {
    return 'Rozdział $number';
  }

  @override
  String kbpsValue(int value) {
    return '$value kb/s';
  }

  @override
  String get fileInfoTitle => 'Informacje o plikach';

  @override
  String fileInfoFileCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pliku',
      many: '$count plików',
      few: '$count pliki',
      one: '$count plik',
    );
    return '$_temp0';
  }

  @override
  String get fileInfoNone => 'Ta książka nie ma szczegółów plików.';

  @override
  String get fileInfoAudio => 'Audio';

  @override
  String get fileInfoEbook => 'E-book';

  @override
  String get fileInfoOther => 'Inne pliki';

  @override
  String get fileInfoBookOrbitNote =>
      'BookOrbit nie podaje kodeka ani przepływności.';

  @override
  String fileInfoChannels(int count) {
    return 'Kanałów: $count';
  }

  @override
  String get fileInfoCover => 'Okładka';

  @override
  String get fileInfoMetadata => 'Metadane';

  @override
  String get fileInfoSupplement => 'Dodatek';

  @override
  String get fileInfoPathCopied => 'Skopiowano ścieżkę';

  @override
  String get resetMayNotHaveSynced =>
      'Reset mógł się nie zsynchronizować – sprawdź serwer';

  @override
  String failedToDownloadEbook(int code) {
    return 'Nie udało się pobrać e-booka ($code)';
  }

  @override
  String get serverReturnedErrorPage =>
      'Serwer zwrócił stronę błędu zamiast pliku e-booka';

  @override
  String ebookSaved(String filename) {
    return 'Zapisano: $filename';
  }

  @override
  String errorSavingEbook(String error) {
    return 'Błąd zapisu e-booka: $error';
  }

  @override
  String failedToSaveError(String error) {
    return 'Nie udało się zapisać: $error';
  }

  @override
  String get adminBackupsLabel => 'Kopie zapasowe';

  @override
  String get adminListeningNow => 'Słuchają teraz';

  @override
  String get adminLibraries => 'Biblioteki';

  @override
  String get adminLibraryShows => 'audycje';

  @override
  String get adminLibraryBooks => 'książki';

  @override
  String get adminLibraryFolders => 'foldery';

  @override
  String get adminLibrarySize => 'rozmiar';

  @override
  String get adminLibraryDuration => 'czas trwania';

  @override
  String adminLibraryIssues(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count brakującego lub nieprawidłowego elementu',
      many: '$count brakujących lub nieprawidłowych elementów',
      few: '$count brakujące lub nieprawidłowe elementy',
      one: '$count brakujący lub nieprawidłowy element',
    );
    return '$_temp0';
  }

  @override
  String get adminLibraryReview => 'Przejrzyj';

  @override
  String get adminMissingTitle => 'Brakujące elementy';

  @override
  String adminMissingSubtitle(String library) {
    return 'Wpisy w $library, których pliki są brakujące lub nieczytelne';
  }

  @override
  String get adminMissingNone =>
      'Brak brakujących lub nieprawidłowych elementów';

  @override
  String get adminMissingBadge => 'Brakujący';

  @override
  String get adminInvalidBadge => 'Nieprawidłowy';

  @override
  String get adminMissingDeleteTitle => 'Usuń wpis';

  @override
  String adminMissingDeleteOneContent(String title) {
    return 'Usunąć „$title” z Audiobookshelf?';
  }

  @override
  String adminMissingDeleteManyContent(int count) {
    return 'Usunąć wpisy z Audiobookshelf (liczba: $count)?';
  }

  @override
  String adminMissingDeleteCount(int count) {
    return 'Usuń ($count)';
  }

  @override
  String adminMissingRemovedOne(String title) {
    return 'Usunięto $title';
  }

  @override
  String adminMissingRemovedMany(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Usunięto $count wpisu',
      many: 'Usunięto $count wpisów',
      few: 'Usunięto $count wpisy',
      one: 'Usunięto $count wpis',
    );
    return '$_temp0';
  }

  @override
  String get adminMissingDeleteFailed => 'Nie udało się usunąć wpisu';

  @override
  String get adminMatchAction => 'Dopasuj';

  @override
  String adminMatchingStarted(String name) {
    return 'Rozpoczęto dopasowywanie dla $name';
  }

  @override
  String get adminMatchFailed => 'Niepowodzenie';

  @override
  String adminScanFailed(String name) {
    return 'Nie udało się przeskanować $name';
  }

  @override
  String get adminPurgeCacheFailed => 'Niepowodzenie';

  @override
  String get adminUsersRootBadge => 'root';

  @override
  String get adminUsersAdminBadge => 'admin';

  @override
  String get adminUsersDisabledBadge => 'wyłączony';

  @override
  String get adminUsersEditUserTooltip => 'Edytuj użytkownika';

  @override
  String get adminUsersOnlineNow => 'Online teraz';

  @override
  String adminUsersLastSeen(String time) {
    return 'Ostatnio widziany $time';
  }

  @override
  String get adminUsersNever => 'Nigdy';

  @override
  String get adminUsersTotal => 'Łącznie';

  @override
  String get adminUsersNoReadingActivity => 'Brak aktywności czytelniczej';

  @override
  String get adminUsersLoadingDots => 'Ładowanie...';

  @override
  String get adminUsersLoadMoreSessions => 'Wczytaj więcej sesji';

  @override
  String get adminUsersNoRecentSessions => 'Brak ostatnich sesji';

  @override
  String get adminUsersLibraryProgress => 'Postęp w bibliotece';

  @override
  String adminUsersLoadMoreRemaining(int count) {
    return 'Wczytaj więcej (pozostało $count)';
  }

  @override
  String adminUsersMonthsAgo(int count) {
    return '$count mies. temu';
  }

  @override
  String get adminUsersNewUser => 'Nowy użytkownik';

  @override
  String get adminUsersEditUser => 'Edytuj użytkownika';

  @override
  String get adminUsersUsername => 'Nazwa użytkownika';

  @override
  String get adminUsersEnterUsername => 'Wpisz nazwę użytkownika';

  @override
  String get adminUsersPassword => 'Hasło';

  @override
  String get adminUsersNewPassword => 'Nowe hasło';

  @override
  String get adminUsersEnterPassword => 'Wpisz hasło';

  @override
  String get adminUsersLeaveBlankToKeep => 'Zostaw puste, aby zachować obecne';

  @override
  String get adminUsersAccountType => 'Typ konta';

  @override
  String get adminUsersTypeGuest => 'Gość';

  @override
  String get adminUsersTypeUser => 'Użytkownik';

  @override
  String get adminUsersTypeAdmin => 'Administrator';

  @override
  String get adminUsersStatus => 'Status';

  @override
  String get adminUsersAccountActive => 'Konto aktywne';

  @override
  String get adminUsersAccountActiveSub =>
      'Wyłączone konta nie mogą się logować';

  @override
  String get adminUsersLocked => 'Zablokowane';

  @override
  String get adminUsersLockedSub => 'Uniemożliwia zmianę hasła';

  @override
  String get adminUsersPermissions => 'Uprawnienia';

  @override
  String get adminUsersPermDownload => 'Pobieranie';

  @override
  String get adminUsersPermUpdate => 'Aktualizacja';

  @override
  String get adminUsersPermUpdateSub =>
      'Edycja metadanych i elementów biblioteki';

  @override
  String get adminUsersPermDelete => 'Usuwanie';

  @override
  String get adminUsersPermUpload => 'Wysyłanie';

  @override
  String get adminUsersPermExplicit => 'Treści dla dorosłych';

  @override
  String get adminUsersLibraryAccess => 'Dostęp do bibliotek';

  @override
  String get adminUsersAccessAllLibraries => 'Dostęp do wszystkich bibliotek';

  @override
  String get adminUsersCreateUser => 'Utwórz użytkownika';

  @override
  String get adminUsersSaveChanges => 'Zapisz zmiany';

  @override
  String get adminUsersUsernameRequired => 'Nazwa użytkownika jest wymagana';

  @override
  String get adminUsersPickLibrary =>
      'Pick at least one library, or turn on access to all libraries';

  @override
  String get adminUsersPasswordRequired => 'Hasło jest wymagane';

  @override
  String get adminUsersUserCreated => 'Użytkownik utworzony';

  @override
  String get adminUsersUserUpdated => 'Użytkownik zaktualizowany';

  @override
  String get adminUsersFailedCreate => 'Nie udało się utworzyć użytkownika';

  @override
  String get adminUsersFailedUpdate =>
      'Nie udało się zaktualizować użytkownika';

  @override
  String get adminUsersThisUser => 'tego użytkownika';

  @override
  String get adminUsersDeleteUserTitle => 'Usunąć użytkownika?';

  @override
  String adminUsersDeleteUserContent(String name) {
    return 'Trwale usunąć $name?';
  }

  @override
  String adminUsersUserDeleted(String name) {
    return 'Usunięto $name';
  }

  @override
  String get adminUsersFailedDelete => 'Nie udało się usunąć użytkownika';

  @override
  String get adminUsersUnlinkOpenId => 'Odłącz OpenID';

  @override
  String get adminUsersUnlinkOpenIdTitle => 'Odłączyć OpenID?';

  @override
  String adminUsersUnlinkOpenIdContent(String name) {
    return 'Usunąć połączenie OpenID dla $name? Aby połączyć ponownie, trzeba będzie znów zalogować się przez OpenID.';
  }

  @override
  String get adminUsersOpenIdUnlinked => 'OpenID odłączony';

  @override
  String get adminUsersFailedUnlinkOpenId => 'Nie udało się odłączyć OpenID';

  @override
  String adminUsersByAuthor(String author) {
    return 'autor: $author';
  }

  @override
  String get adminUsersListened => 'Odsłuchano';

  @override
  String get adminUsersStartedAtPosition => 'Rozpoczęto na pozycji';

  @override
  String get adminUsersEndedAtPosition => 'Zakończono na pozycji';

  @override
  String get adminUsersTotalDuration => 'Łączny czas';

  @override
  String get adminUsersStarted => 'Rozpoczęto';

  @override
  String get adminUsersUpdated => 'Zaktualizowano';

  @override
  String get adminUsersClient => 'Klient';

  @override
  String get adminUsersDevice => 'Urządzenie';

  @override
  String get adminUsersOs => 'System';

  @override
  String get adminUsersPlayMethod => 'Metoda odtwarzania';

  @override
  String get adminUsersPlayDirect => 'Odtwarzanie bezpośrednie';

  @override
  String get adminUsersPlayDirectStream => 'Strumień bezpośredni';

  @override
  String get adminUsersPlayTranscode => 'Transkodowanie';

  @override
  String get adminUsersPlayLocal => 'Lokalnie';

  @override
  String get adminPodcastsCheckNewEpisodesTitle => 'Sprawdź nowe odcinki';

  @override
  String get adminPodcastsCheckNewEpisodesContent =>
      'Sprawdzi kanały RSS wszystkich podcastów i pobierze znalezione nowe odcinki (jeśli włączone jest automatyczne pobieranie).';

  @override
  String get adminPodcastsCheckNewEpisodesSubtitle =>
      'Przeskanuj kanał RSS i pobierz nowe odcinki';

  @override
  String get adminPodcastsCheck => 'Sprawdź';

  @override
  String get adminPodcastsCheckingForNew => 'Sprawdzanie nowych odcinków…';

  @override
  String get adminPodcastsCheckingForNewDots =>
      'Sprawdzanie nowych odcinków...';

  @override
  String get adminPodcastsFailedCheckEpisodes =>
      'Nie udało się sprawdzić odcinków';

  @override
  String get adminPodcastsCheckFeedsTooltip =>
      'Sprawdź kanały pod kątem nowych odcinków';

  @override
  String get adminPodcastsNoPodcastsYet => 'Brak podcastów';

  @override
  String get adminPodcastsTapPlusHint =>
      'Dotknij +, aby wyszukać i dodać audycje';

  @override
  String adminPodcastsEpisodesCount(int count) {
    return 'Odcinków: $count';
  }

  @override
  String get adminPodcastsAddPodcast => 'Dodaj podcast';

  @override
  String get adminPodcastsCouldNotFindFeed => 'Nie znaleziono kanału podcastu';

  @override
  String get adminPodcastsSearchHint => 'Szukaj podcastów…';

  @override
  String get adminPodcastsSearchItunesHint => 'Szukaj w iTunes...';

  @override
  String adminPodcastsSearchItunesFor(String query) {
    return 'Szukaj w iTunes: „$query”';
  }

  @override
  String get adminPodcastsNoPodcastsFound => 'Nie znaleziono podcastów';

  @override
  String get adminPodcastsRelToday => 'Dziś';

  @override
  String adminPodcastsWeeksAgo(int count) {
    return '$count tyg. temu';
  }

  @override
  String adminPodcastsMonthsAgo(int count) {
    return '$count mies. temu';
  }

  @override
  String adminPodcastsYearsAgo(int count) {
    return '$count l. temu';
  }

  @override
  String adminPodcastsUpdated(String when) {
    return 'Zaktualizowano $when';
  }

  @override
  String get adminPodcastsGenreAll => 'Wszystkie';

  @override
  String get adminPodcastsGenreArts => 'Sztuka';

  @override
  String get adminPodcastsGenreComedy => 'Komedia';

  @override
  String get adminPodcastsGenreEducation => 'Edukacja';

  @override
  String get adminPodcastsGenreTvFilm => 'TV i film';

  @override
  String get adminPodcastsGenreMusic => 'Muzyka';

  @override
  String get adminPodcastsGenreNews => 'Wiadomości';

  @override
  String get adminPodcastsGenreReligion => 'Religia';

  @override
  String get adminPodcastsGenreScience => 'Nauka';

  @override
  String get adminPodcastsGenreSports => 'Sport';

  @override
  String get adminPodcastsGenreTechnology => 'Technologia';

  @override
  String get adminPodcastsGenreBusiness => 'Biznes';

  @override
  String get adminPodcastsGenreFiction => 'Fikcja';

  @override
  String get adminPodcastsGenreSocietyCulture => 'Społeczeństwo i kultura';

  @override
  String get adminPodcastsGenreHealthFitness => 'Zdrowie i fitness';

  @override
  String get adminPodcastsGenreTrueCrime => 'Kryminalne historie';

  @override
  String get adminPodcastsGenreHistory => 'Historia';

  @override
  String get adminPodcastsGenreKidsFamily => 'Dzieci i rodzina';

  @override
  String get adminPodcastsPodcastFallback => 'Podcast';

  @override
  String get adminPodcastsEpisodeFallback => 'Odcinek';

  @override
  String get adminPodcastsNoFeedFound => 'Nie znaleziono adresu URL kanału';

  @override
  String get adminPodcastsNoFeedAvailable =>
      'Brak dostępnego adresu URL kanału';

  @override
  String adminPodcastsAddedToLibrary(String title) {
    return 'Dodano $title do biblioteki';
  }

  @override
  String adminPodcastsFailedToAdd(String title) {
    return 'Nie udało się dodać $title';
  }

  @override
  String adminPodcastsEpisodesInFeed(int count) {
    return 'Odcinków w kanale: $count';
  }

  @override
  String adminPodcastsMoreEpisodes(int count) {
    return '+ $count więcej odcinków';
  }

  @override
  String get adminPodcastsAdding => 'Dodawanie…';

  @override
  String get adminPodcastsAddToLibrary => 'Dodaj do biblioteki';

  @override
  String get adminPodcastsRemoveShowTitle => 'Usunąć audycję?';

  @override
  String adminPodcastsRemoveShowContent(String title) {
    return 'Usunąć „$title” i wszystkie jej odcinki z serwera? Tej operacji nie można cofnąć.';
  }

  @override
  String adminPodcastsRemovedShow(String title) {
    return 'Usunięto „$title”';
  }

  @override
  String get adminPodcastsFailedRemoveShow => 'Nie udało się usunąć audycji';

  @override
  String get adminPodcastsRemoveShowTooltip => 'Usuń audycję';

  @override
  String get adminPodcastsSelectMultipleTooltip => 'Zaznacz wiele';

  @override
  String adminPodcastsDownloadedCount(int count) {
    return 'Pobrano: $count';
  }

  @override
  String get adminPodcastsTabDownloaded => 'Pobrane';

  @override
  String get adminPodcastsTabFeed => 'Kanał';

  @override
  String get adminPodcastsTabSettings => 'Ustawienia';

  @override
  String adminPodcastsDownloadingEpisode(String title) {
    return 'Pobieranie „$title”';
  }

  @override
  String get adminPodcastsFailedDownload => 'Nie udało się pobrać';

  @override
  String get adminPodcastsDeleteEpisodeTitle => 'Usunąć odcinek?';

  @override
  String adminPodcastsDeleteEpisodeContent(String title) {
    return 'Usunąć „$title”?';
  }

  @override
  String get adminPodcastsDeleted => 'Usunięto';

  @override
  String get adminPodcastsFailed => 'Niepowodzenie';

  @override
  String get adminPodcastsDeleteEpisodesTitle => 'Usunąć odcinki?';

  @override
  String adminPodcastsDeleteEpisodesContent(int count) {
    return 'Usunąć z serwera odcinki (liczba: $count)?';
  }

  @override
  String adminPodcastsDeletedEpisodes(int count) {
    return 'Usunięto odcinki (liczba: $count)';
  }

  @override
  String get adminPodcastsBrowseFeedToDownload =>
      'Przeglądaj kanał, aby pobrać';

  @override
  String get adminPodcastsDownloadingDots => 'Pobieranie...';

  @override
  String adminPodcastsDeleteEpisodesCount(int count) {
    return 'Usuń odcinki ($count)';
  }

  @override
  String adminPodcastsDownloadingCount(int count) {
    return 'Pobieranie odcinków: $count';
  }

  @override
  String adminPodcastsDownloadEpisodesCount(int count) {
    return 'Pobierz odcinki ($count)';
  }

  @override
  String get adminPodcastsLookForEpisodesAfter => 'Szukaj odcinków po';

  @override
  String get adminPodcastsSelectDate => 'Wybierz datę';

  @override
  String get adminPodcastsMaxEpisodes => 'Maks. liczba odcinków do pobrania';

  @override
  String adminPodcastsNoNewEpisodesAfter(String date) {
    return 'Nie znaleziono nowych odcinków po $date';
  }

  @override
  String adminPodcastsFoundNewEpisodes(int count) {
    return 'Znaleziono nowe odcinki ($count) – pobieranie';
  }

  @override
  String get adminPodcastsFailedToCheckNew =>
      'Nie udało się sprawdzić nowych odcinków';

  @override
  String get adminPodcastsCheckAndDownload => 'Sprawdź i pobierz';

  @override
  String get adminPodcastsMatchPodcast => 'Dopasuj podcast';

  @override
  String get adminPodcastsMatchPodcastSubtitle =>
      'Wyszukaj w iTunes, aby zaktualizować okładkę i metadane';

  @override
  String get adminPodcastsAutoDownloadNewEpisodes =>
      'Automatycznie pobieraj nowe odcinki';

  @override
  String get adminPodcastsAutoDownloadOnSubtitle =>
      'Serwer automatycznie pobiera nowe odcinki';

  @override
  String get adminPodcastsAutoDownloadOffSubtitle =>
      'Nowe odcinki nie są pobierane automatycznie';

  @override
  String get adminPodcastsFailedAutoDownloadUpdate =>
      'Nie udało się zmienić ustawienia automatycznego pobierania';

  @override
  String get adminPodcastsMaxEpisodesToKeep =>
      'Maks. liczba odcinków do zachowania';

  @override
  String get adminPodcastsMaxEpisodesToKeepHelp =>
      '0 zachowuje wszystkie odcinki. Po automatycznym pobraniu nowego odcinka Audiobookshelf usuwa najstarszy, gdy audycja przekracza ten limit.';

  @override
  String get adminPodcastsNoEpisodeLimit => 'Bez limitu';

  @override
  String get adminPodcastsEpisodeLimitInvalid => 'Wpisz 0 lub liczbę całkowitą';

  @override
  String get adminPodcastsCheckSchedule => 'Harmonogram sprawdzania';

  @override
  String get adminPodcastsFrequency => 'Częstotliwość';

  @override
  String get adminPodcastsFreqHourly => 'Co godzinę';

  @override
  String get adminPodcastsFreqDaily => 'Codziennie';

  @override
  String get adminPodcastsFreqWeekly => 'Co tydzień';

  @override
  String get adminPodcastsDay => 'Dzień';

  @override
  String get adminPodcastsTime => 'Godzina';

  @override
  String get adminPodcastsDaySun => 'Niedz.';

  @override
  String get adminPodcastsDayMon => 'Pon.';

  @override
  String get adminPodcastsDayTue => 'Wt.';

  @override
  String get adminPodcastsDayWed => 'Śr.';

  @override
  String get adminPodcastsDayThu => 'Czw.';

  @override
  String get adminPodcastsDayFri => 'Pt.';

  @override
  String get adminPodcastsDaySat => 'Sob.';

  @override
  String get adminPodcastsFeedUrl => 'URL kanału';

  @override
  String get adminPodcastsBack => 'Wstecz';

  @override
  String get adminPodcastsRootOnly => 'Tylko root';

  @override
  String get adminPodcastsDeleting => 'Usuwanie...';

  @override
  String get adminPodcastsDeleteEpisode => 'Usuń odcinek';

  @override
  String adminPodcastsSeasonChip(String season) {
    return 'Sezon $season';
  }

  @override
  String adminPodcastsEpChip(String number) {
    return 'Odc. $number';
  }

  @override
  String get adminPodcastsApplyingMatch => 'Stosowanie dopasowania...';

  @override
  String get adminPodcastsNoResults => 'Brak wyników';

  @override
  String get adminPodcastsPodcastMatched =>
      'Podcast dopasowany i zaktualizowany';

  @override
  String get adminPodcastsFailedMatch => 'Nie udało się dopasować podcastu';

  @override
  String get adminPodcastsSelectAll => 'Zaznacz wszystko';

  @override
  String get adminPodcastsSelectAllNew => 'Tylko nowe';

  @override
  String get adminPodcastsSortNewestFirst => 'Od najnowszych';

  @override
  String get adminPodcastsSortOldestFirst => 'Od najstarszych';

  @override
  String get adminPodcastsEditInfo => 'Edytuj informacje';

  @override
  String get adminPodcastsEditInfoSubtitle =>
      'Zmień tytuł, opis, okładkę i więcej';

  @override
  String get adminPodcastsEditTitle => 'Edytuj podcast';

  @override
  String get adminPodcastsReleaseDate => 'Data wydania';

  @override
  String get adminPodcastsExplicit => 'Treści dla dorosłych';

  @override
  String get adminPodcastsExplicitSubtitle =>
      'Oznacz ten podcast jako zawierający treści dla dorosłych';

  @override
  String get episodeListEpisodeFallback => 'Odcinek';

  @override
  String get episodeListUnknownPodcast => 'Nieznany podcast';

  @override
  String episodeListMarkedFinished(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count odcinka oznaczonego jako ukończone',
      many: '$count odcinków oznaczonych jako ukończone',
      few: '$count odcinki oznaczone jako ukończone',
      one: '$count odcinek oznaczony jako ukończony',
    );
    return '$_temp0';
  }

  @override
  String episodeListMarkedUnfinished(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count odcinka oznaczonego jako nieukończone',
      many: '$count odcinków oznaczonych jako nieukończone',
      few: '$count odcinki oznaczone jako nieukończone',
      one: '$count odcinek oznaczony jako nieukończony',
    );
    return '$_temp0';
  }

  @override
  String get episodeListUnsubscribeFromNewEpisodes =>
      'Przestań subskrybować nowe odcinki';

  @override
  String get episodeListSubscribeToNewEpisodes => 'Subskrybuj nowe odcinki';

  @override
  String get episodeListSubscribeTitle => 'Subskrybować ten podcast?';

  @override
  String get episodeListSubscribeContent =>
      'Nowe odcinki będą automatycznie pobierane i dodawane do kolejki absorbowania, gdy pojawią się na serwerze.';

  @override
  String get episodeListSubscribe => 'Subskrybuj';

  @override
  String get episodeListShowFinishedEpisodes => 'Pokaż ukończone odcinki';

  @override
  String get episodeListHideFinishedEpisodes => 'Ukryj ukończone odcinki';

  @override
  String get episodeListShowSettings => 'Ustawienia audycji';

  @override
  String get episodeListPlaysNewerToOlder =>
      'Odtwarza od nowszych do starszych odcinków';

  @override
  String get episodeListPlaysOlderToNewer =>
      'Odtwarza od starszych do nowszych odcinków';

  @override
  String episodeListEpisodeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count odcinka',
      many: '$count odcinków',
      few: '$count odcinki',
      one: '$count odcinek',
    );
    return '$_temp0';
  }

  @override
  String episodeListUnfinishedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nieukończonego',
      many: '$count nieukończonych',
      few: '$count nieukończone',
      one: '$count nieukończony',
    );
    return '$_temp0';
  }

  @override
  String get episodeListAutoDownloadChip => 'Automatyczne pobieranie';

  @override
  String get episodeListSubscribedChip => 'Subskrybowane';

  @override
  String get episodeListExplicitChip => 'Dla dorosłych';

  @override
  String get episodeListSortNewest => 'Najnowsze';

  @override
  String get episodeListSortOldest => 'Najstarsze';

  @override
  String get episodeListSortBy => 'Sortuj odcinki';

  @override
  String get episodeListSortPubDate => 'Data publikacji';

  @override
  String get episodeListSortTitle => 'Tytuł';

  @override
  String get episodeListSortSeason => 'Sezon';

  @override
  String get episodeListSortEpisode => 'Numer odcinka';

  @override
  String get episodeListSortFileName => 'Nazwa pliku';

  @override
  String get episodeListSortReverseHint =>
      'Dotknij ponownie, aby odwrócić kolejność';

  @override
  String episodeListAddedToAbsorbing(String title) {
    return 'Dodano „$title” do Absorbowania';
  }

  @override
  String get episodeDetailEpisodeFallback => 'Odcinek';

  @override
  String get episodeDetailMarkedNotFinished => 'Oznaczono jako nieukończone';

  @override
  String get episodeDetailMarkedFinishedNice =>
      'Oznaczono jako ukończone – świetnie!';

  @override
  String get episodeDetailMarkAbsorbedContent =>
      'Postęp tego odcinka zostanie ustawiony na 100%.';

  @override
  String get episodeDetailResetProgressContent =>
      'Cały postęp tego odcinka zostanie usunięty, a odcinek wróci na początek. Tej operacji nie można cofnąć.';

  @override
  String get episodeDetailToday => 'Dziś';

  @override
  String get episodeDetailYesterday => 'Wczoraj';

  @override
  String episodeDetailDaysAgo(int count) {
    return '$count d. temu';
  }

  @override
  String episodeDetailWeeksAgo(int count) {
    return '$count tyg. temu';
  }

  @override
  String episodeDetailDurationHm(int hours, int minutes) {
    return '$hours godz. $minutes min';
  }

  @override
  String episodeDetailDurationM(int minutes) {
    return '$minutes min';
  }

  @override
  String get episodeDetailResume => 'Wznów';

  @override
  String get episodeDetailPlayEpisode => 'Odtwórz odcinek';

  @override
  String episodeDetailEpisodeNumber(String number) {
    return 'Odcinek $number';
  }

  @override
  String episodeDetailSeasonNumber(String number) {
    return 'Sezon $number';
  }

  @override
  String get editMetadataUpdatedFromMatch =>
      'Metadane zaktualizowane na podstawie dopasowania';

  @override
  String editMetadataConfirmMatch(String title) {
    return 'Spowoduje to zaktualizowanie metadanych tej książki na serwerze na podstawie:\n\n„$title”\n\nWszystkie pola i okładka zostaną nadpisane na serwerze.';
  }

  @override
  String editMetadataConfirmMatchWithAuthor(String title, String author) {
    return 'Spowoduje to zaktualizowanie metadanych tej książki na serwerze na podstawie:\n\n„$title”, autor: $author\n\nWszystkie pola i okładka zostaną nadpisane na serwerze.';
  }

  @override
  String get seriesBooksFindMissingTitle => 'Znajdź brakujące książki';

  @override
  String get seriesBooksFindMissingContent =>
      'Przeszuka Audible w poszukiwaniu książek z tej serii, których może brakować w Twojej bibliotece.\n\nKsiążki są najpierw dopasowywane po ASIN (jeśli serwer ma ASIN-y dla swoich książek), a następnie po tytule. Wyniki mogą nie być w pełni dokładne.';

  @override
  String get seriesBooksCouldNotFindOnAudible =>
      'Nie znaleziono tej serii w Audible';

  @override
  String seriesBooksMarkAllNotFinishedContent(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Spowoduje to usunięcie statusu ukończenia dla wszystkich $count książek w tej serii.',
      many:
          'Spowoduje to usunięcie statusu ukończenia dla wszystkich $count książek w tej serii.',
      few:
          'Spowoduje to usunięcie statusu ukończenia dla wszystkich $count książek w tej serii.',
      one:
          'Spowoduje to usunięcie statusu ukończenia dla $count książki w tej serii.',
    );
    return '$_temp0';
  }

  @override
  String seriesBooksFullyAbsorbContent(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Spowoduje to oznaczenie wszystkich $count książek w tej serii jako ukończonych.',
      many:
          'Spowoduje to oznaczenie wszystkich $count książek w tej serii jako ukończonych.',
      few:
          'Spowoduje to oznaczenie wszystkich $count książek w tej serii jako ukończonych.',
      one:
          'Spowoduje to oznaczenie $count książki w tej serii jako ukończonej.',
    );
    return '$_temp0';
  }

  @override
  String get seriesBooksUnmarkAll => 'Odznacz wszystkie';

  @override
  String get seriesBooksShowAllBooks => 'Pokaż wszystkie książki';

  @override
  String get seriesBooksGroupBySubSeries => 'Grupuj według podserii';

  @override
  String get seriesBooksLoadingSubSeries => 'Wczytywanie podserii...';

  @override
  String seriesBooksBookCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count książki',
      many: '$count książek',
      few: '$count książki',
      one: '$count książka',
    );
    return '$_temp0';
  }

  @override
  String get seriesBooksDone => 'Gotowe';

  @override
  String get seriesBooksExplicitBadge => 'E';

  @override
  String get expandedCardStreaming => 'Strumieniowanie';

  @override
  String get expandedCardDeviceFallback => 'Urządzenie';

  @override
  String bookmarksScreenPositionInBook(String position, String bookTitle) {
    return '$position w $bookTitle';
  }

  @override
  String get bookmarksScreenClose => 'Zamknij';

  @override
  String get bookmarksScreenSortNewest => 'Najnowsze';

  @override
  String get bookmarksScreenSortPosition => 'Pozycja';

  @override
  String statsScreenStreakDays(int count) {
    return '$count d.';
  }

  @override
  String statsScreenSessionCountOne(int count) {
    return '$count sesja';
  }

  @override
  String statsScreenSessionCountOther(int count) {
    return '$count sesji';
  }

  @override
  String get statsScreenDayMon => 'Pon.';

  @override
  String get statsScreenDayTue => 'Wt.';

  @override
  String get statsScreenDayWed => 'Śr.';

  @override
  String get statsScreenDayThu => 'Czw.';

  @override
  String get statsScreenDayFri => 'Pt.';

  @override
  String get statsScreenDaySat => 'Sob.';

  @override
  String get statsScreenDaySun => 'Niedz.';

  @override
  String statsScreenDurationHm(int h, int m) {
    return '$h godz. $m min';
  }

  @override
  String statsScreenDurationM(int m) {
    return '$m min';
  }

  @override
  String get statsScreenDurationLessThanMin => '<1 min';

  @override
  String get statsScreenDurationZero => '0 min';

  @override
  String statsScreenDurationShortH(int h) {
    return '$h godz.';
  }

  @override
  String statsScreenDurationShortM(int m) {
    return '$m min';
  }

  @override
  String get statsScreenCouldNotLoadItem => 'Nie udało się wczytać elementu';

  @override
  String get statsScreenCouldNotFindEpisode => 'Nie znaleziono odcinka';

  @override
  String statsScreenByAuthor(String author) {
    return 'autor: $author';
  }

  @override
  String get statsScreenListened => 'Odsłuchano';

  @override
  String get sessionEditTitle => 'Edytuj sesję';

  @override
  String get sessionDayLabel => 'Dzień';

  @override
  String get sessionEndPosition => 'Pozycja końcowa';

  @override
  String get sessionEndPositionHint =>
      'Zmiana tej wartości może też zaktualizować Twój bieżący postęp.';

  @override
  String get statsViewSessions => 'Pokaż sesje';

  @override
  String statsSessionsForDate(String date) {
    return 'Sesje z dnia $date';
  }

  @override
  String get statsNoSessionsForDate =>
      'Nie znaleziono sesji słuchania z tego dnia';

  @override
  String get statsSearchSessions => 'Szukaj sesji';

  @override
  String get statsNoSessionSearchResults =>
      'Żadna sesja nie pasuje do wyszukiwania';

  @override
  String get statsSessionsLoadFailed =>
      'Nie udało się wczytać sesji z tego dnia';

  @override
  String get sessionDeleteConfirmTitle => 'Usunąć sesję?';

  @override
  String get sessionDeleteConfirmBody =>
      'Sesja zostanie usunięta, a łączny czas słuchania zmniejszy się o jej długość. Tej operacji nie można cofnąć.';

  @override
  String get sessionSaved => 'Sesja zaktualizowana';

  @override
  String get sessionDeleted => 'Sesja usunięta';

  @override
  String get sessionSaveFailed => 'Nie udało się zapisać zmian';

  @override
  String get sessionDeleteFailed => 'Nie udało się usunąć tej sesji';

  @override
  String get statsScreenStartedAtPosition => 'Rozpoczęto na pozycji';

  @override
  String get statsScreenEndedAtPosition => 'Zakończono na pozycji';

  @override
  String get statsScreenTotalDuration => 'Łączny czas';

  @override
  String get statsScreenStarted => 'Rozpoczęto';

  @override
  String get statsScreenUpdated => 'Zaktualizowano';

  @override
  String get statsScreenClient => 'Klient';

  @override
  String get statsScreenDevice => 'Urządzenie';

  @override
  String get statsScreenOs => 'System';

  @override
  String get statsScreenPlayMethod => 'Metoda odtwarzania';

  @override
  String get statsScreenLoading => 'Ładowanie...';

  @override
  String get statsScreenJumpToStart => 'Przejdź na początek';

  @override
  String get statsScreenJumpToEnd => 'Przejdź na koniec';

  @override
  String get statsScreenPlayMethodDirect => 'Odtwarzanie bezpośrednie';

  @override
  String get statsScreenPlayMethodDirectStream => 'Strumień bezpośredni';

  @override
  String get statsScreenPlayMethodTranscode => 'Transkodowanie';

  @override
  String get statsScreenPlayMethodLocal => 'Lokalnie';

  @override
  String get statsScreenAmLabel => 'AM';

  @override
  String get statsScreenPmLabel => 'PM';

  @override
  String statsScreenDateAtTime(
    String month,
    int day,
    int year,
    int hour,
    String minute,
    String ampm,
  ) {
    return '$day $month $year, $hour:$minute $ampm';
  }

  @override
  String get statsScreenMonthJan => 'sty';

  @override
  String get statsScreenMonthFeb => 'lut';

  @override
  String get statsScreenMonthMar => 'mar';

  @override
  String get statsScreenMonthApr => 'kwi';

  @override
  String get statsScreenMonthMay => 'maj';

  @override
  String get statsScreenMonthJun => 'cze';

  @override
  String get statsScreenMonthJul => 'lip';

  @override
  String get statsScreenMonthAug => 'sie';

  @override
  String get statsScreenMonthSep => 'wrz';

  @override
  String get statsScreenMonthOct => 'paź';

  @override
  String get statsScreenMonthNov => 'lis';

  @override
  String get statsScreenMonthDec => 'gru';

  @override
  String get upcomingReleasesTitle => 'Nadchodzące premiery';

  @override
  String get upcomingReleasesRescanTitle => 'Przeskanować ponownie?';

  @override
  String upcomingReleasesRescanContent(int days) {
    return 'Te wyniki mają $days dni. Daty premier mogły się zmienić – czy chcesz przeskanować ponownie?';
  }

  @override
  String get upcomingReleasesNotNow => 'Nie teraz';

  @override
  String get upcomingReleasesRescan => 'Skanuj ponownie';

  @override
  String get upcomingReleasesRescanReleaseDate => 'Przeskanuj datę premiery';

  @override
  String get upcomingReleasesRescanning => 'Ponowne skanowanie...';

  @override
  String upcomingReleasesUpdatedWithDate(String date) {
    return 'Zaktualizowano – $date';
  }

  @override
  String get upcomingReleasesNoReleaseDateFound =>
      'Nie znaleziono daty premiery';

  @override
  String get upcomingReleasesRescanFailed =>
      'Ponowne skanowanie nie powiodło się';

  @override
  String get upcomingReleasesRemoveFromList => 'Usuń z listy';

  @override
  String get upcomingReleasesRemovedFromList => 'Usunięto z listy';

  @override
  String get upcomingReleasesDateChip => 'Data';

  @override
  String upcomingReleasesCheckingSeries(String name, int processed, int total) {
    return 'Sprawdzanie $name... ($processed/$total)';
  }

  @override
  String get upcomingReleasesLoadingSeries => 'Wczytywanie serii...';

  @override
  String get upcomingReleasesScannedToday => '(zeskanowano dziś)';

  @override
  String get upcomingReleasesScannedYesterday => '(zeskanowano wczoraj)';

  @override
  String upcomingReleasesScannedDaysAgo(int days) {
    return '(zeskanowano $days dni temu)';
  }

  @override
  String upcomingReleasesUpcomingCount(int count) {
    return 'Nadchodzące: $count';
  }

  @override
  String upcomingReleasesRecentCount(int count) {
    return 'Ostatnie: $count';
  }

  @override
  String get upcomingReleasesNoneFound =>
      'Nie znaleziono nadchodzących ani ostatnich premier';

  @override
  String upcomingReleasesAcrossSeries(String summary, int count) {
    return '$summary w seriach: $count';
  }

  @override
  String upcomingReleasesCheckedSeries(int count) {
    return 'Sprawdzono serie w Audible: $count';
  }

  @override
  String upcomingReleasesDateFormat(String month, int day, int year) {
    return '$day $month $year';
  }

  @override
  String upcomingReleasesSequenceLabel(String sequence) {
    return '#$sequence';
  }

  @override
  String get upcomingReleasesBadgeUpcoming => 'WKRÓTCE';

  @override
  String get upcomingReleasesBadgeAdded => 'DODANO';

  @override
  String get upcomingReleasesBadgeMissing => 'BRAKUJE';

  @override
  String get upcomingReleasesScanSettingsTitle => 'Ustawienia skanowania';

  @override
  String get upcomingReleasesFinishedAfterTitle =>
      'Uznaj serię za zakończoną po';

  @override
  String get upcomingReleasesFinishedAfterDesc =>
      'Serie, których ostatnia książka jest starsza niż ten okres, są pomijane podczas skanowania i sprawdzane ponownie tylko co miesiąc lub dwa.';

  @override
  String upcomingReleasesFinishedAfterYears(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lat',
      many: '$count lat',
      few: '$count lat',
      one: '$count roku',
    );
    return '$_temp0';
  }

  @override
  String get upcomingReleasesFinishedAfterNever => 'Nigdy';

  @override
  String get upcomingReleasesSkippedTitle => 'Pominięte serie';

  @override
  String get upcomingReleasesSkippedNone => 'Nic jeszcze nie pominięto';

  @override
  String upcomingReleasesSkippedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pominiętej',
      many: '$count pominiętych',
      few: '$count pominięte',
      one: '$count pominięta',
    );
    return '$_temp0';
  }

  @override
  String upcomingReleasesSkippedLastBook(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ostatnia książka sprzed $count lat',
      many: 'Ostatnia książka sprzed $count lat',
      few: 'Ostatnia książka sprzed $count lat',
      one: 'Ostatnia książka sprzed $count roku',
      zero: 'Ostatnia książka sprzed mniej niż roku',
    );
    return '$_temp0';
  }

  @override
  String get upcomingReleasesSkippedUnmatched =>
      'Nie udało się dopasować tej serii w Audible';

  @override
  String get upcomingReleasesSkippedScanNow => 'Skanuj teraz';

  @override
  String get upcomingReleasesSkippedAlwaysScan => 'Zawsze skanuj';

  @override
  String get upcomingReleasesSkippedNeverScan => 'Nigdy nie skanuj';

  @override
  String upcomingReleasesSkippedScanFound(String name) {
    return 'Znaleziono nowe premiery w $name';
  }

  @override
  String upcomingReleasesSkippedScanNone(String name) {
    return 'Brak nowości w $name';
  }

  @override
  String get upcomingReleasesSkippedOtherLibrary =>
      'Ta lista pochodzi z innej biblioteki. Uruchom ponowne skanowanie, aby ją odświeżyć.';

  @override
  String get upcomingReleasesChipUpcoming => 'Nadchodzące';

  @override
  String upcomingReleasesChipMissing(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count brakującej',
      many: '$count brakujących',
      few: '$count brakujące',
      one: '$count brakująca',
      zero: 'Brakujące',
    );
    return '$_temp0';
  }

  @override
  String get upcomingReleasesNoMissing => 'Nie znaleziono brakujących książek';

  @override
  String get upcomingReleasesScanSeries => 'Skanuj serie';

  @override
  String get upcomingReleasesScanUpcomingOption => 'Nadchodzące premiery';

  @override
  String get upcomingReleasesScanUpcomingOptionDesc =>
      'Szybkie skanowanie w poszukiwaniu nowych i nadchodzących książek';

  @override
  String get upcomingReleasesScanDeepOption => 'Głębokie skanowanie';

  @override
  String get upcomingReleasesScanDeepOptionDesc =>
      'Znajduje też brakujące książki w każdej serii – trwa dłużej';

  @override
  String get upcomingReleasesFirstScanNote =>
      'Pierwsze skanowanie sprawdza każdą serię w Audible i może potrwać kilka minut. Kolejne są znacznie szybsze, gdy Twoje serie zostaną uporządkowane.';

  @override
  String get upcomingReleasesLastScanReport => 'Raport z ostatniego skanowania';

  @override
  String upcomingReleasesReportChecked(int count) {
    return 'Sprawdzono w Audible: $count';
  }

  @override
  String upcomingReleasesReportSkipped(int count) {
    return 'Pominięto: $count';
  }

  @override
  String upcomingReleasesReportUnmatched(int count) {
    return 'Nie udało się dopasować w Audible: $count';
  }

  @override
  String upcomingReleasesReportFailed(int count) {
    return 'Nie udało się sprawdzić: $count';
  }

  @override
  String upcomingReleasesReportFound(int upcoming, int recent) {
    return 'Znaleziono: nadchodzące $upcoming, ostatnie $recent';
  }

  @override
  String upcomingReleasesReportFoundDeep(
    int upcoming,
    int recent,
    int missing,
  ) {
    return 'Znaleziono: nadchodzące $upcoming, ostatnie $recent, brakujące $missing';
  }

  @override
  String upcomingReleasesReportMore(int count) {
    return '+$count więcej';
  }

  @override
  String get upcomingReleasesBadgeNew => 'NOWE';

  @override
  String get upcomingReleasesOpenSeries => 'Otwórz serię w Audible';

  @override
  String get upcomingReleasesOpenLibrarySeries => 'Otwórz serię w bibliotece';

  @override
  String get upcomingReleasesAsinCopied => 'Skopiowano ASIN serii';

  @override
  String get upcomingReleasesSetSeriesAsin => 'Ustaw ASIN serii';

  @override
  String get upcomingReleasesSetAsinInstructions =>
      'Znajdź serię na audible.com i skopiuj link do strony – ASIN to 10-znakowy kod zaczynający się od B0 (np. B08S2YN3YS). Można też wkleić cały link.';

  @override
  String get upcomingReleasesSetAsinHint => 'B0… lub link audible.com';

  @override
  String get upcomingReleasesSetAsinSave => 'Zapisz';

  @override
  String get upcomingReleasesSetAsinInvalid =>
      'Nie znaleziono ASIN w tym tekście';

  @override
  String get upcomingReleasesSetAsinSaved =>
      'Seria powiązana – trwa skanowanie';

  @override
  String upcomingReleasesRemoveTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Usuń $count książki',
      many: 'Usuń $count książek',
      few: 'Usuń $count książki',
      one: 'Usuń $count książkę',
    );
    return '$_temp0';
  }

  @override
  String get upcomingReleasesRemoveThisScan => 'Usuń z tego skanowania';

  @override
  String get upcomingReleasesRemoveThisScanDesc =>
      'Może wrócić przy przyszłym skanowaniu';

  @override
  String get upcomingReleasesRemoveForever =>
      'Usuń z tego i przyszłych skanowań';

  @override
  String get upcomingReleasesRemoveForeverDesc =>
      'Trafia na listę usuniętych, można przywrócić w dowolnym momencie';

  @override
  String get upcomingReleasesRemovedForeverToast =>
      'Usunięto – nie pojawi się przy przyszłych skanowaniach';

  @override
  String get upcomingReleasesRemovedBooksTitle => 'Usunięte książki';

  @override
  String upcomingReleasesRemovedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count książki',
      many: '$count książek',
      few: '$count książki',
      one: '$count książka',
    );
    return '$_temp0';
  }

  @override
  String get upcomingReleasesRemovedNone => 'Brak usuniętych książek';

  @override
  String get upcomingReleasesRestore => 'Przywróć';

  @override
  String get upcomingReleasesRestoredToast => 'Przywrócono';

  @override
  String get upcomingReleasesRestoredNextScan =>
      'Przywrócono – pojawi się po następnym skanowaniu';

  @override
  String upcomingReleasesSelectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count zaznaczonej',
      many: '$count zaznaczonych',
      few: '$count zaznaczone',
      one: '$count zaznaczona',
    );
    return '$_temp0';
  }

  @override
  String get upcomingReleasesBulkRequest => 'Zażądaj';

  @override
  String get upcomingReleasesBulkRemove => 'Usuń';

  @override
  String upcomingReleasesBulkRemoved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count usuniętej',
      many: '$count usuniętych',
      few: '$count usunięte',
      one: '$count usunięta',
    );
    return '$_temp0';
  }

  @override
  String upcomingReleasesBulkRequestDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Wysłano $count żądania',
      many: 'Wysłano $count żądań',
      few: 'Wysłano $count żądania',
      one: 'Wysłano $count żądanie',
    );
    return '$_temp0';
  }

  @override
  String upcomingReleasesBulkRequestSkipped(int count) {
    return 'Pominięto: $count';
  }

  @override
  String upcomingReleasesBulkScanned(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ponownie przeskanowano $count serii',
      many: 'Ponownie przeskanowano $count serii',
      few: 'Ponownie przeskanowano $count serie',
      one: 'Ponownie przeskanowano $count serię',
    );
    return '$_temp0';
  }

  @override
  String upcomingReleasesBulkScanFound(int count) {
    return 'Z nowymi książkami: $count';
  }

  @override
  String get seriesExcludeFromScan => 'Wyklucz ze skanowania serii';

  @override
  String get seriesIncludeInScan => 'Uwzględnij w skanowaniu serii';

  @override
  String get homeScreenEpisodeFallback => 'Odcinek';

  @override
  String get libraryScreenUnknownTitle => 'Nieznany tytuł';

  @override
  String get playlistDetailDefaultName => 'Playlista';

  @override
  String playlistDetailItemCount(int count) {
    return 'Elementów: $count';
  }

  @override
  String get playlistDetailUnfinished => 'Nieukończone';

  @override
  String get playlistDetailRemoveFromPlaylist => 'Usuń z playlisty';

  @override
  String get playlistDetailDone => 'Gotowe';

  @override
  String playlistDetailItemsMarkedFinished(int count) {
    return 'Oznaczono jako ukończone: $count';
  }

  @override
  String playlistDetailItemsMarkedUnfinished(int count) {
    return 'Oznaczono jako nieukończone: $count';
  }

  @override
  String playlistDetailItemsRemoved(int count) {
    return 'Usunięto elementów: $count';
  }

  @override
  String playlistDetailAddedToAbsorbing(String title) {
    return 'Dodano „$title” do Absorbowania';
  }

  @override
  String get collectionDetailDefaultName => 'Kolekcja';

  @override
  String smartScopeBookCount(int count) {
    return 'Inteligentny zakres · książek: $count';
  }

  @override
  String get smartScopeNew => 'Nowy inteligentny zakres';

  @override
  String get smartScopeNewSubtitle =>
      'Zapisz zestaw filtrów jako listę, która sama się aktualizuje';

  @override
  String get smartScopeEditTitle => 'Edytuj inteligentny zakres';

  @override
  String get smartScopeIcon => 'Ikona';

  @override
  String get smartScopePublic => 'Widoczny dla wszystkich użytkowników';

  @override
  String get smartScopeKobo => 'Synchronizuj z Kobo';

  @override
  String get smartScopeRules => 'Reguły';

  @override
  String get smartScopeMatchAll => 'Spełnione wszystkie';

  @override
  String get smartScopeMatchAny => 'Spełniona dowolna';

  @override
  String get smartScopeAddRule => 'Dodaj regułę';

  @override
  String get smartScopeAddGroup => 'Dodaj grupę';

  @override
  String get smartScopeGroup => 'Grupa';

  @override
  String get smartScopeStartFrom => 'Zacznij od';

  @override
  String get smartScopeFromScratch => 'Utwórz od zera';

  @override
  String get smartScopeTplHasSeries => 'Ma serię';

  @override
  String get smartScopeTplRecent => 'Ostatnio dodane';

  @override
  String get smartScopeTplPdf => 'Tylko PDF';

  @override
  String get smartScopeTplNoGenres => 'Bez gatunków';

  @override
  String get smartScopeTplEpub => 'Tylko EPUB';

  @override
  String get smartScopeCounting => 'Liczenie...';

  @override
  String get smartScopeSort => 'Domyślne sortowanie';

  @override
  String get smartScopeAddSort => 'Dodaj poziom sortowania';

  @override
  String get smartScopeSortNone =>
      'Nie ustawiono sortowania, więc książki są sortowane według tytułu.';

  @override
  String get smartScopeAscending => 'Rosnąco';

  @override
  String get smartScopeDescending => 'Malejąco';

  @override
  String get smartScopeDelete => 'Usuń inteligentny zakres';

  @override
  String get smartScopeSaveFailed =>
      'Nie udało się zapisać inteligentnego zakresu';

  @override
  String get smartScopeDeleteFailed =>
      'Nie udało się usunąć inteligentnego zakresu';

  @override
  String get smartScopeLoadFailed =>
      'Nie udało się wczytać inteligentnego zakresu';

  @override
  String get smartScopeUnsupportedRule =>
      'Tę regułę można zmienić tylko w wersji webowej BookOrbit. Zostanie zachowana bez zmian.';

  @override
  String get smartScopeAnd => 'i';

  @override
  String get smartScopeDays => 'dni';

  @override
  String get smartScopeWeeks => 'tygodni';

  @override
  String get smartScopeMonths => 'miesięcy';

  @override
  String get smartScopePickDate => 'Wybierz datę';

  @override
  String get smartScopeAddValue => 'Dodaj wartość';

  @override
  String get smartScopeValue => 'Wartość';

  @override
  String get smartScopeCustomFields => 'Pola własne';

  @override
  String get smartScopeAnyProvider => 'Dowolny dostawca';

  @override
  String get smartScopeScoreOutstanding => 'Wybitny';

  @override
  String get smartScopeScoreGood => 'Dobry';

  @override
  String get smartScopeScoreFair => 'Przeciętny';

  @override
  String get smartScopeScorePoor => 'Słaby';

  @override
  String get smartScopeMb => 'MB';

  @override
  String get smartScopeMaxValues => 'Do 20 wartości';

  @override
  String get scopeFieldTitle => 'Tytuł';

  @override
  String get scopeFieldAuthor => 'Autor';

  @override
  String get scopeFieldSeries => 'Seria';

  @override
  String get scopeFieldSeriesIndex => 'Numer w serii';

  @override
  String get scopeFieldGenre => 'Gatunek';

  @override
  String get scopeFieldTag => 'Tag';

  @override
  String get scopeFieldReadStatus => 'Status przeczytania';

  @override
  String get scopeFieldReadProgress => 'Postęp czytania';

  @override
  String get scopeFieldRating => 'Twoja ocena';

  @override
  String get scopeFieldFormat => 'Format';

  @override
  String get scopeFieldLibrary => 'Biblioteka';

  @override
  String get scopeFieldCollection => 'Kolekcja';

  @override
  String get scopeFieldPublisher => 'Wydawca';

  @override
  String get scopeFieldLanguage => 'Język';

  @override
  String get scopeFieldPublishedDate => 'Data publikacji';

  @override
  String get scopeFieldPublishedYear => 'Rok publikacji';

  @override
  String get scopeFieldAddedAt => 'Data dodania';

  @override
  String get scopeFieldStartedAt => 'Data rozpoczęcia';

  @override
  String get scopeFieldFinishedAt => 'Data ukończenia';

  @override
  String get scopeFieldPageCount => 'Liczba stron';

  @override
  String get scopeFieldFileSize => 'Rozmiar pliku';

  @override
  String get scopeFieldCommunityRating => 'Ocena społeczności';

  @override
  String get scopeFieldCommunityRatingCount => 'Liczba recenzji społeczności';

  @override
  String get scopeFieldMetadataScore => 'Ocena metadanych';

  @override
  String get scopeFieldIsbn => 'ISBN';

  @override
  String get scopeFieldDescription => 'Opis';

  @override
  String get scopeFieldCover => 'Okładka';

  @override
  String get scopeFieldAudioCover => 'Okładka audiobooka';

  @override
  String get scopeFieldFileAvailability => 'Dostępność pliku';

  @override
  String get scopeFieldLockStatus => 'Status blokady';

  @override
  String get scopeFieldSeriesStatus => 'Status serii';

  @override
  String get scopeSortUpdatedAt => 'Data aktualizacji';

  @override
  String get scopeSortLastReadAt => 'Ostatnio czytane';

  @override
  String get scopeSortRandom => 'Losowo';

  @override
  String get scopeOpContains => 'zawiera';

  @override
  String get scopeOpNotContains => 'nie zawiera';

  @override
  String get scopeOpStartsWith => 'zaczyna się od';

  @override
  String get scopeOpEndsWith => 'kończy się na';

  @override
  String get scopeOpEq => 'jest';

  @override
  String get scopeOpNotEq => 'nie jest';

  @override
  String get scopeOpIsEmpty => 'jest puste';

  @override
  String get scopeOpIsNotEmpty => 'nie jest puste';

  @override
  String get scopeOpGt => 'większe niż';

  @override
  String get scopeOpGte => 'co najmniej';

  @override
  String get scopeOpLt => 'mniejsze niż';

  @override
  String get scopeOpLte => 'co najwyżej';

  @override
  String get scopeOpBetween => 'między';

  @override
  String get scopeOpIncludesAny => 'zawiera dowolne z';

  @override
  String get scopeOpIncludesAll => 'zawiera wszystkie z';

  @override
  String get scopeOpExcludesAll => 'wyklucza wszystkie z';

  @override
  String get scopeOpBefore => 'przed';

  @override
  String get scopeOpAfter => 'po';

  @override
  String get scopeOpWithinLast => 'w ciągu ostatnich';

  @override
  String get scopeOpIsMissing => 'brakuje';

  @override
  String get scopeOpIsPresent => 'jest obecne';

  @override
  String get scopeOpIsUnread => 'nieprzeczytane';

  @override
  String get scopeOpIsInProgress => 'w trakcie';

  @override
  String get scopeOpIsFinished => 'ukończone';

  @override
  String get scopeOpIsLocked => 'jest zablokowane';

  @override
  String get scopeOpIsUnlocked => 'jest odblokowane';

  @override
  String get scopeOpIsUpNext => 'jest następne w kolejce';

  @override
  String get scopeOpIsTrue => 'tak';

  @override
  String get scopeOpIsFalse => 'nie';

  @override
  String smartScopeMatchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Pasuje $count książki',
      many: 'Pasuje $count książek',
      few: 'Pasują $count książki',
      one: 'Pasuje $count książka',
      zero: 'Brak pasujących książek',
    );
    return '$_temp0';
  }

  @override
  String smartScopeDeleteConfirm(String name) {
    return 'Usunąć „$name”? Tej operacji nie można cofnąć.';
  }

  @override
  String collectionDetailBookCount(int count) {
    return 'Książek: $count';
  }

  @override
  String get collectionDetailDone => 'Gotowe';

  @override
  String collectionDetailAddedToAbsorbing(String title) {
    return 'Dodano „$title” do Absorbowania';
  }

  @override
  String get audibleSeriesNoBooksFound => 'Nie znaleziono książek w Audible';

  @override
  String get audibleSeriesFailedToLoad =>
      'Nie udało się wczytać serii z Audible';

  @override
  String audibleSeriesSummary(int total, int missing) {
    return '$total w Audible · brakuje $missing';
  }

  @override
  String audibleSeriesSummaryWithUpcoming(
    int total,
    int missing,
    int upcoming,
  ) {
    return '$total w Audible · brakuje $missing · nadchodzi $upcoming';
  }

  @override
  String audibleSeriesFilterMissing(int count) {
    return 'Brakujące ($count)';
  }

  @override
  String audibleSeriesFilterUpcoming(int count) {
    return 'Nadchodzące ($count)';
  }

  @override
  String audibleSeriesFilterAll(int count) {
    return 'Wszystkie ($count)';
  }

  @override
  String get audibleSeriesSearching => 'Przeszukiwanie Audible...';

  @override
  String get audibleSeriesCompleteSeries => 'Masz kompletną serię!';

  @override
  String get audibleSeriesNoUpcoming => 'Nie znaleziono nadchodzących premier';

  @override
  String get audibleSeriesUpcomingBadge => 'WKRÓTCE';

  @override
  String get audibleSeriesAbridged => 'Skrócona';

  @override
  String get audibleSeriesRegionTitle => 'Region Audible';

  @override
  String get audibleSeriesOpenOnAudible => 'Otwórz w Audible';

  @override
  String get audibleSeriesAddToCalendar => 'Dodaj do kalendarza';

  @override
  String get audibleSeriesAddToUpcoming => 'Dodaj do nadchodzących premier';

  @override
  String get audibleSeriesAddedToUpcoming => 'Dodano do nadchodzących premier';

  @override
  String get audibleSeriesAlreadyInUpcoming =>
      'Już jest na stronie nadchodzących';

  @override
  String get audibleSeriesCouldNotOpenAudible => 'Nie można otworzyć Audible';

  @override
  String get audibleSeriesCouldNotOpenCalendar =>
      'Nie można otworzyć kalendarza';

  @override
  String audibleSeriesCalendarDescription(String seriesName) {
    return 'Nowa premiera audiobooka z serii $seriesName';
  }

  @override
  String get authorBooksGroupBySeries => 'Grupuj według serii';

  @override
  String get authorBooksList => 'Lista';

  @override
  String get authorBooksGrid => 'Siatka';

  @override
  String authorBooksBookCount(int count) {
    return '$count książek';
  }

  @override
  String get metadataLookupCover => 'Okładka';

  @override
  String get metadataLookupChooseFields => 'Wybierz pola do zastosowania';

  @override
  String metadataLookupApplyFields(int count) {
    return 'Zastosuj pola: $count';
  }

  @override
  String metadataLookupFieldsSavedLocally(int count) {
    return 'Pola zapisane lokalnie: $count';
  }

  @override
  String get metadataLookupOverrideLocalDisplay => 'Zastąp lokalny wygląd';

  @override
  String get equalizerPresetFlat => 'Płaski';

  @override
  String get equalizerPresetVoiceBoost => 'Wzmocnienie głosu';

  @override
  String get equalizerPresetBassBoost => 'Wzmocnienie basów';

  @override
  String get equalizerPresetTrebleBoost => 'Wzmocnienie tonów wysokich';

  @override
  String get equalizerPresetPodcast => 'Podcast';

  @override
  String get equalizerPresetAudiobook => 'Audiobook';

  @override
  String get equalizerPresetReduceNoise => 'Redukcja szumów';

  @override
  String get equalizerPresetLoudness => 'Loudness';

  @override
  String equalizerEditingSavedNamed(String title) {
    return 'Edycja zapisanego EQ dla „$title”';
  }

  @override
  String get equalizerEditingSavedGeneric => 'Edycja zapisanego EQ';

  @override
  String get equalizerPerBookEq => 'EQ dla każdej książki';

  @override
  String get notesDeleteNoteQuestion => 'Usunąć notatkę?';

  @override
  String notesDeleteNoteContent(String title) {
    return 'Usunąć „$title”?';
  }

  @override
  String get notesExport => 'Eksportuj';

  @override
  String get notesNewNote => 'Nowa notatka';

  @override
  String get librarySortFilterUpcomingReleases => 'Skanuj serie';

  @override
  String get librarySortFilterMatchAllAuthorsSubtitle =>
      'Pobierz zdjęcie i biogram każdego autora od dostawcy metadanych';

  @override
  String get librarySortFilterUpcomingReleasesSubtitle =>
      'Sprawdź w Audible nadchodzące i brakujące książki w swoich seriach';

  @override
  String sleepTimerSheetChaptersLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Zostało $count rozdziału',
      many: 'Zostało $count rozdziałów',
      few: 'Zostały $count rozdziały',
      one: 'Został 1 rozdział',
    );
    return '$_temp0';
  }

  @override
  String sleepTimerSheetAddMinutesChip(int minutes) {
    return '+$minutes min';
  }

  @override
  String sleepTimerSheetAddChaptersChip(int count) {
    return '+$count rozd.';
  }

  @override
  String sleepTimerSheetMinShort(int minutes) {
    return '$minutes min';
  }

  @override
  String sleepTimerSheetSecondsShort(int seconds) {
    return '$seconds s';
  }

  @override
  String sleepTimerSheetMinSecShort(int minutes, int seconds) {
    return '$minutes min $seconds s';
  }

  @override
  String sleepTimerSheetChaptersValue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rozdziału',
      many: '$count rozdziałów',
      few: '$count rozdziały',
      one: '1 rozdział',
    );
    return '$_temp0';
  }

  @override
  String sleepTimerSheetChaptersChip(int count) {
    return '$count rozd.';
  }

  @override
  String sleepTimerSheetStartChapterSleep(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Uśpij po $count rozdziałach',
      many: 'Uśpij po $count rozdziałach',
      few: 'Uśpij po $count rozdziałach',
      one: 'Uśpij po 1 rozdziale',
    );
    return '$_temp0';
  }

  @override
  String get sleepTimerSheetRewindOnSleep => 'Przewiń do tyłu po uśpieniu';

  @override
  String get sleepTimerSheetShake => 'Potrząśnięcie';

  @override
  String sleepTimerSheetAddsMinutes(int minutes) {
    return 'Dodaje $minutes min';
  }

  @override
  String get sleepTimerSheetAddsOneChapter => 'Dodaje 1 rozdział';

  @override
  String get sleepTimerSheetResetsToFull => 'Przywraca pełny czas';

  @override
  String get sleepTimerSheetTabSpecificChapter => 'Rozdział';

  @override
  String get sleepTimerSheetSpecificNoChapters => 'Brak dostępnych rozdziałów';

  @override
  String sleepTimerSheetSpecificChapterFallback(int number) {
    return 'Rozdział $number';
  }

  @override
  String get sleepTimerSheetSpecificPassedShort => 'minął';

  @override
  String get sleepTimerSheetSpecificStart => 'Początek rozdziału';

  @override
  String get sleepTimerSheetSpecificEnd => 'Koniec rozdziału';

  @override
  String get sleepTimerSheetSpecificEndsAt =>
      'Wyłącznik czasowy zakończy się o';

  @override
  String sleepTimerSheetSpecificCountdown(String countdown) {
    return 'za $countdown';
  }

  @override
  String get sleepTimerSheetSpecificAlreadyPassed => 'Ten punkt już minął';

  @override
  String get sleepTimerSheetSpecificStartButton => 'Uruchom wyłącznik';

  @override
  String get sleepTimerSheetSpecificStartButtonPassed => 'Już minął';

  @override
  String get timeAm => 'AM';

  @override
  String get timePm => 'PM';

  @override
  String get collectionPickerCollectionFallback => 'Kolekcja';

  @override
  String collectionPickerNameWithCount(String name, int count) {
    return '$name ($count)';
  }

  @override
  String get playlistPickerPlaylistFallback => 'Playlista';

  @override
  String playlistPickerNameWithCount(String name, int count) {
    return '$name ($count)';
  }

  @override
  String get cardChaptersPlayFromChapterTitle => 'Odtworzyć od rozdziału?';

  @override
  String cardChaptersPlayFromChapterContent(String title) {
    return 'Rozpocząć odtwarzanie od „$title”?';
  }

  @override
  String get cardChaptersPlay => 'Odtwórz';

  @override
  String get absorbingSharedToday => 'Dzisiaj';

  @override
  String get absorbingSharedYesterday => 'Wczoraj';

  @override
  String get absorbingSharedMonday => 'Poniedziałek';

  @override
  String get absorbingSharedTuesday => 'Wtorek';

  @override
  String get absorbingSharedWednesday => 'Środa';

  @override
  String get absorbingSharedThursday => 'Czwartek';

  @override
  String get absorbingSharedFriday => 'Piątek';

  @override
  String get absorbingSharedSaturday => 'Sobota';

  @override
  String get absorbingSharedSunday => 'Niedziela';

  @override
  String get absorbingSharedAm => 'AM';

  @override
  String get absorbingSharedPm => 'PM';

  @override
  String sectionDetailAddedToAbsorbing(String title) {
    return 'Dodano „$title” do Absorbing';
  }

  @override
  String get sectionDetailDoneBadge => 'Ukończono';

  @override
  String get homeCustomizeAddGenreTitle => 'Dodaj sekcję gatunku';

  @override
  String get homeCustomizeAddGenreSubtitle =>
      'Wybierz gatunek do wyświetlenia na ekranie głównym';

  @override
  String get homeSectionDoneBadge => 'Ukończono';

  @override
  String get tipsSheetQuickBookmarksTitle => 'Szybkie zakładki';

  @override
  String get tipsSheetQuickBookmarksDesc =>
      'Przytrzymaj przycisk zakładki na dowolnej karcie, aby natychmiast dodać zakładkę w bieżącej pozycji bez otwierania arkusza zakładek.';

  @override
  String get tipsSheetCoverPlayPauseTitle => 'Odtwarzanie/pauza z okładki';

  @override
  String get tipsSheetCoverPlayPauseDesc =>
      'Dotknij okładki na dowolnej karcie, aby odtworzyć lub wstrzymać. Możesz to przełączyć w Ustawieniach w sekcji Karty Absorbing. Podczas odtwarzania widać delikatną ikonę pauzy, więc wiesz, że okładka jest klikalna.';

  @override
  String get tipsSheetFullScreenPlayerTitle => 'Odtwarzacz pełnoekranowy';

  @override
  String get tipsSheetFullScreenPlayerDesc =>
      'Przesuń w górę na dowolnej karcie Absorbing, aby otworzyć odtwarzacz pełnoekranowy. Przesuń w dół, aby go zamknąć.';

  @override
  String get tipsSheetQuickAddAbsorbingTitle =>
      'Szybkie dodawanie do Absorbing';

  @override
  String get tipsSheetQuickAddAbsorbingDesc =>
      'Przesuń w prawo dowolną książkę na liście (seria, autor, wyniki wyszukiwania), aby od razu dodać ją do kolejki Absorbing.';

  @override
  String get tipsSheetShakeExtendSleepTitle =>
      'Potrząśnij, aby przedłużyć uśpienie';

  @override
  String get tipsSheetShakeExtendSleepDesc =>
      'Jeśli działa wyłącznik czasowy i potrząśniesz telefonem, doda on dodatkowe minuty. Ilość ustawisz w Ustawieniach w sekcji Wyłącznik czasowy.';

  @override
  String get tipsSheetSeriesNavigationTitle => 'Nawigacja po seriach';

  @override
  String get tipsSheetSeriesNavigationDesc =>
      'Dotknij nazwy serii w oknie szczegółów dowolnej książki, aby zobaczyć wszystkie książki z serii, ułożone w kolejności czytania, z numerami na okładkach.';

  @override
  String get tipsSheetSwipeBetweenBooksTitle => 'Przesuwanie między książkami';

  @override
  String get tipsSheetSwipeBetweenBooksDesc =>
      'Przesuwaj w lewo i w prawo na ekranie Absorbing, aby przełączać się między rozpoczętymi książkami. Przy włączonym trybie kolejki ręcznej karty działają też jak kolejka, więc następna odtworzy się automatycznie po zakończeniu bieżącej.';

  @override
  String get tipsSheetTapToSeekTitle => 'Dotknij, aby przewinąć';

  @override
  String get tipsSheetTapToSeekDesc =>
      'Dotknij dowolnego miejsca paska postępu rozdziału lub książki, aby przeskoczyć do tej pozycji. Paski można też przeciągać dla dokładniejszej kontroli.';

  @override
  String get tipsSheetSpeedAdjustedTimeTitle => 'Czas dostosowany do prędkości';

  @override
  String get tipsSheetSpeedAdjustedTimeDesc =>
      'Każdy wyświetlany czas - pozycja, pozostały czas, rozdziały, zakładki - dostosowuje się do prędkości odtwarzania. Słuchasz w 1,5x? Wyświetlane czasy odpowiadają temu, ile faktycznie to zajmie.';

  @override
  String get tipsSheetPlaybackHistoryTitle => 'Historia odtwarzania';

  @override
  String get tipsSheetPlaybackHistoryDesc =>
      'Dotknij przycisku Historia na dowolnej karcie, aby zobaczyć oś czasu każdego odtworzenia, pauzy, przewinięcia i zmiany prędkości. Dotknij dowolnego zdarzenia, aby wrócić do tej pozycji.';

  @override
  String get tipsSheetAutoRewindTitle => 'Automatyczne cofanie';

  @override
  String get tipsSheetAutoRewindDesc =>
      'Po wznowieniu po pauzie Absorb automatycznie cofa kilka sekund, abyś nie stracił wątku. Długość cofnięcia zależy od tego, jak długo cię nie było. Skonfigurujesz to w Ustawieniach.';

  @override
  String get tipsSheetSeriesQueueModeTitle => 'Tryb kolejki serii';

  @override
  String get tipsSheetSeriesQueueModeDesc =>
      'Gdy skończysz książkę będącą częścią serii, Absorb może automatycznie odtworzyć następną. Ustaw tryb kolejki na „Seria” w Ustawieniach.';

  @override
  String get tipsSheetOfflineModeTitle => 'Tryb offline';

  @override
  String get tipsSheetOfflineModeDesc =>
      'Dotknij zielonej chmurki u góry ekranu Absorbing, aby przejść w tryb offline. Synchronizacja się zatrzymuje, nic nie zużywa danych i widać tylko pobrane pozycje. W trybie offline chmurka jest pomarańczowa, a ponowne dotknięcie łączy z powrotem. Czerwona chmurka oznacza wylogowanie: pobrane pozycje nadal się odtwarzają, a to, czego słuchasz, zsynchronizuje się po ponownym zalogowaniu. Tryb offline można też przełączać przytrzymaniem karty, w Ustawieniach w sekcji Skróty przytrzymania kart.';

  @override
  String get tipsSheetUpcomingReleasesTitle => 'Nadchodzące premiery';

  @override
  String get tipsSheetUpcomingReleasesDesc =>
      'Na karcie Serie dotknij jej ponownie, aby otworzyć arkusz sortowania i filtrów, a następnie wybierz Nadchodzące premiery, aby zobaczyć nowe i nadchodzące książki w swoich seriach, posortowane według daty premiery.';

  @override
  String get tipsSheetPerBookEqTitle => 'Korektor dla każdej książki';

  @override
  String get tipsSheetPerBookEqDesc =>
      'Każda książka pamięta własne ustawienia korektora. Dostosuj EQ raz dla epickiej space opery, a przy następnym odtworzeniu zabrzmi tak samo.';

  @override
  String get tipsSheetPerBookSpeedTitle => 'Prędkość dla każdej książki';

  @override
  String get tipsSheetPerBookSpeedDesc =>
      'Prędkość odtwarzania jest zapisywana dla każdej książki. Słuchaj literatury faktu w 1,5x, a dramatycznej fikcji w 1,0x bez ustawiania tego za każdym razem.';

  @override
  String get tipsSheetAutoSleepWindowTitle => 'Automatyczne okno snu';

  @override
  String get tipsSheetAutoSleepWindowDesc =>
      'Wybierz godziny, o których zwykle zasypiasz, a wyłącznik czasowy uruchomi się sam, gdy zaczniesz słuchać w tym przedziale.';

  @override
  String get tipsSheetSleepFadeChimeTitle =>
      'Wyciszanie i dzwonek przy uśpieniu';

  @override
  String get tipsSheetSleepFadeChimeDesc =>
      'Gdy wyłącznik czasowy się kończy, dźwięk stopniowo cichnie, a opcjonalny dzwonek gra, by nie urwać w pół zdania.';

  @override
  String get tipsSheetCarModeTitle => 'Tryb samochodowy';

  @override
  String get tipsSheetCarModeDesc =>
      'Dotknij ikony samochodu, aby przełączyć na tryb z wielkimi przyciskami, zaprojektowany dla większego bezpieczeństwa podczas jazdy.';

  @override
  String get tipsSheetAudibleSeriesTitle => 'Odkrywanie serii z Audible';

  @override
  String get tipsSheetAudibleSeriesDesc =>
      'Otwórz serię i użyj menu dodatkowego (trzy kropki), aby pobrać z Audible pełną listę serii, w tym brakujące pozycje i książki, których jeszcze nie zacząłeś.';

  @override
  String get tipsSheetTranscribeBookmarkTitle => 'Transkrypcja zakładek';

  @override
  String get tipsSheetTranscribeBookmarkDesc =>
      'Zamień dźwięk w dowolnej zakładce na tekst, w całości na swoim urządzeniu. Włącz to w Ustawieniach w sekcji Zaawansowane > Transkrypcja i pobierz model, a następnie dotknij Transkrybuj przy zakładce - tekst trafi do jej notatki, gotowy do poprawienia lub udostępnienia.';

  @override
  String get tipsSheetFindBetweenFormatsTitle =>
      'Przeskakuj między audiobookiem a ebookiem';

  @override
  String get tipsSheetFindBetweenFormatsDesc =>
      'Gdy transkrypcja jest włączona, a książka pobrana, wstrzymaj i dotknij w odtwarzaczu Znajdź pozycję w ebooku, aby otworzyć ebooka w miejscu, które właśnie usłyszałeś. W czytniku zaznacz tekst i dotknij słuchawek, aby uruchomić audiobooka dokładnie tam.';

  @override
  String get tipsSheetShareQuoteTitle => 'Udostępnianie cytatów';

  @override
  String get tipsSheetShareQuoteDesc =>
      'Udostępnij zakreślenie z ebooka lub notatkę z zakładki jako obraz z cytatem na okładce książki. Szukaj opcji udostępniania przy zakreśleniach i w arkuszu zakładek.';

  @override
  String get tipsSheetClipExportTitle => 'Eksport fragmentów audio';

  @override
  String get tipsSheetClipExportDesc =>
      'Otwórz zakładkę i dotknij Eksportuj fragment, aby przyciąć i zapisać krótki fragment audio książki wraz z okładką - świetne do dzielenia się ulubioną sceną.';

  @override
  String get tipsSheetAllHighlightsTitle =>
      'Wszystkie zakreślenia w jednym miejscu';

  @override
  String get tipsSheetAllHighlightsDesc =>
      'Strona Wszystkie zakładki ma kartę Zakreślenia, zbierającą każde zakreślenie z ebooków ze wszystkich książek. Dotknij jednego, aby je udostępnić lub wrócić do książki.';

  @override
  String get tipsSheetVolumeKeyPagesTitle =>
      'Zmiana stron klawiszami głośności';

  @override
  String get tipsSheetVolumeKeyPagesDesc =>
      'Przewracaj strony ebooka klawiszami głośności. Włącz to w ustawieniach czytnika - kierunek normalny lub odwrócony, może działać nawet podczas odtwarzania dźwięku.';

  @override
  String get tipsSheetSettingsSyncTitle => 'Synchronizacja ustawień';

  @override
  String get tipsSheetSettingsSyncDesc =>
      'Utrzymuj ustawienia, prędkości poszczególnych książek i kolejność Absorbing zsynchronizowane między urządzeniami przez własny serwer WebDAV. Skonfigurujesz to w Ustawieniach w sekcji Kopia zapasowa i synchronizacja.';

  @override
  String get tipsSheetNavLongPressTitle => 'Przytrzymanie dolnych kart';

  @override
  String get tipsSheetNavLongPressDesc =>
      'Przytrzymaj kartę Start, aby przełączyć biblioteki z dowolnej strony. Przytrzymaj kartę Biblioteka, aby od razu przejść do wyszukiwania.';

  @override
  String get bookCardUnknownTitle => 'Nieznany tytuł';

  @override
  String get bookCardExplicitBadge => 'E';

  @override
  String get bookCardDone => 'Ukończono';

  @override
  String get bookCardSaved => 'Zapisano';

  @override
  String get episodeRowEpisode => 'Odcinek';

  @override
  String get episodeRowToday => 'Dzisiaj';

  @override
  String get episodeRowYesterday => 'Wczoraj';

  @override
  String episodeRowDaysAgo(int count) {
    return '$count d temu';
  }

  @override
  String episodeRowWeeksAgo(int count) {
    return '$count tyg. temu';
  }

  @override
  String episodeRowDurationHm(int hours, int minutes) {
    return '$hours godz. $minutes min';
  }

  @override
  String episodeRowDurationM(int minutes) {
    return '$minutes min';
  }

  @override
  String episodeRowSeasonShort(String number) {
    return 'S$number';
  }

  @override
  String episodeRowEpisodeShort(String number) {
    return 'E$number';
  }

  @override
  String get librarySearchResultsExplicitBadge => 'E';

  @override
  String get librarySearchResultsDone => 'Ukończono';

  @override
  String get librarySearchResultsSaved => 'Zapisano';

  @override
  String librarySearchResultsSequence(String number) {
    return '#$number';
  }

  @override
  String get librarySearchResultsUnknownSeries => 'Nieznana seria';

  @override
  String get librarySearchResultsUnknownEpisode => 'Nieznany odcinek';

  @override
  String librarySearchResultsBookCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count książki',
      many: '$count książek',
      few: '$count książki',
      one: '1 książka',
    );
    return '$_temp0';
  }

  @override
  String get libraryGridTilesExplicitBadge => 'E';

  @override
  String get libraryGridTilesDone => 'Ukończono';

  @override
  String get libraryGridTilesSaved => 'Zapisano';

  @override
  String libraryGridTilesSequence(String number) {
    return '#$number';
  }

  @override
  String get libraryGridTilesUnknownSeries => 'Nieznana seria';

  @override
  String get seriesCardUnknownSeries => 'Nieznana seria';

  @override
  String seriesCardBookCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count książki',
      many: '$count książek',
      few: '$count książki',
      one: '1 książka',
    );
    return '$_temp0';
  }

  @override
  String get cardProgressFineScrubbing => 'Precyzyjne przewijanie';

  @override
  String get cardProgressQuarterSpeed => 'Jedna czwarta prędkości';

  @override
  String get cardProgressHalfSpeed => 'Połowa prędkości';

  @override
  String cardProgressChapterPrefix(String number) {
    return 'Rozdział $number';
  }

  @override
  String get cardEdgeProgressFineScrubbing => 'Precyzyjne przewijanie';

  @override
  String get cardEdgeProgressQuarterSpeed => 'Jedna czwarta prędkości';

  @override
  String get cardEdgeProgressHalfSpeed => 'Połowa prędkości';

  @override
  String get authSessionExpired => 'Sesja wygasła. Zaloguj się ponownie.';

  @override
  String authCannotReachServer(String url) {
    return 'Nie można połączyć się z serwerem $url';
  }

  @override
  String get authInvalidUsernameOrPassword =>
      'Nieprawidłowa nazwa użytkownika lub hasło';

  @override
  String get authInvalidApiKey => 'Nieprawidłowy klucz API';

  @override
  String get authLoginFailedDetail =>
      'Logowanie nie powiodło się - sprawdź adres serwera i dane logowania';

  @override
  String get authUnexpectedServerResponse => 'Nieoczekiwana odpowiedź serwera';

  @override
  String get authSsoUnexpectedResponse =>
      'SSO zwróciło nieoczekiwaną odpowiedź';

  @override
  String get authSwitchedToLocalServer => 'Przełączono na serwer lokalny';

  @override
  String get authSwitchedToRemoteServer => 'Przełączono na serwer zdalny';

  @override
  String get lpDeletedFinishedDownload => 'Usunięto ukończone pobranie';

  @override
  String lpSubscribedPodcastDownloading(String showTitle, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'pobieranie $count nowego odcinka',
      many: 'pobieranie $count nowych odcinków',
      few: 'pobieranie $count nowych odcinków',
      one: 'pobieranie 1 nowego odcinka',
    );
    return '$showTitle: $_temp0';
  }

  @override
  String lpSubscribedEpisodeAddedStart(String showTitle) {
    return '$showTitle dodano na początek kolejki';
  }

  @override
  String lpSubscribedEpisodeAddedSecond(String showTitle) {
    return '$showTitle dodano jako 2. w kolejce';
  }

  @override
  String lpSubscribedEpisodeAddedEnd(String showTitle) {
    return '$showTitle dodano na koniec kolejki';
  }

  @override
  String lpSubscribedEpisodeDownloaded(String showTitle) {
    return 'Pobrano nowy odcinek $showTitle';
  }

  @override
  String get statsWeekStartsOn => 'Tydzień zaczyna się w';

  @override
  String get episodeListNewEpisodePosition => 'Pozycja nowego odcinka';

  @override
  String get episodeListPositionTop => 'Początek kolejki';

  @override
  String get episodeListPositionSecond => 'Drugi w kolejce';

  @override
  String get episodeListPositionEnd => 'Koniec kolejki';

  @override
  String get episodeListPositionNone => 'Nie dodawaj do kolejki';

  @override
  String get episodeListPositionNoneDesc => 'Nadal powiadamiaj i pobieraj';

  @override
  String sleepRewindUndoNote(int minutes) {
    return 'Naciśnij odtwarzanie w ciągu $minutes min, a cofnięcie zostanie anulowane';
  }

  @override
  String lpQueueDownloadingItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Kolejka: pobieranie $count pozycji',
      many: 'Kolejka: pobieranie $count pozycji',
      few: 'Kolejka: pobieranie $count pozycji',
      one: 'Kolejka: pobieranie 1 pozycji',
    );
    return '$_temp0';
  }

  @override
  String lpDownloadingBooks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Pobieranie $count książki',
      many: 'Pobieranie $count książek',
      few: 'Pobieranie $count książek',
      one: 'Pobieranie 1 książki',
    );
    return '$_temp0';
  }

  @override
  String lpDownloadingEpisodes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Pobieranie $count odcinka',
      many: 'Pobieranie $count odcinków',
      few: 'Pobieranie $count odcinków',
      one: 'Pobieranie 1 odcinka',
    );
    return '$_temp0';
  }

  @override
  String get downloadNotifProgressChannelName => 'Postęp pobierania';

  @override
  String get downloadNotifProgressChannelDesc =>
      'Pokazuje postęp podczas pobierania audiobooków';

  @override
  String get downloadNotifAlertChannelName => 'Alerty pobierania';

  @override
  String get downloadNotifAlertChannelDesc =>
      'Powiadomienia o zakończeniu lub niepowodzeniu pobierania';

  @override
  String get downloadNotifDownloadingTitle => 'Pobieranie…';

  @override
  String downloadNotifActiveCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count aktywnego pobierania',
      many: '$count aktywnych pobierań',
      few: '$count aktywne pobierania',
      one: '1 aktywne pobieranie',
    );
    return '$_temp0';
  }

  @override
  String downloadNotifSlotTitle(String title) {
    return 'Pobieranie: $title';
  }

  @override
  String get downloadNotifStartingLabel => 'Uruchamianie…';

  @override
  String get downloadNotifCompleteTitle => 'Pobieranie zakończone';

  @override
  String downloadNotifCompleteBody(String title) {
    return '$title jest gotowy do słuchania offline';
  }

  @override
  String get downloadNotifFailedTitle => 'Pobieranie nie powiodło się';

  @override
  String get upcomingNotifChannelName => 'Skanowanie nadchodzących premier';

  @override
  String get upcomingNotifChannelDesc =>
      'Pokazuje postęp skanowania nadchodzących premier';

  @override
  String get upcomingNotifScanTitle => 'Skanowanie nadchodzących premier';

  @override
  String get upcomingNotifStartingScan => 'Rozpoczynanie skanowania…';

  @override
  String upcomingNotifCheckingSeries(
    String seriesName,
    int current,
    int total,
  ) {
    return 'Sprawdzanie: $seriesName… ($current/$total)';
  }

  @override
  String get upcomingNotifFoundTitle => 'Znaleziono nadchodzące premiery!';

  @override
  String upcomingNotifFoundBody(int books, int series) {
    String _temp0 = intl.Intl.pluralLogic(
      series,
      locale: localeName,
      other: '$series seriach',
      many: '$series seriach',
      few: '$series seriach',
      one: '1 serii',
    );
    return 'Nadchodzące: $books w $_temp0';
  }

  @override
  String get androidAutoTabContinue => 'Kontynuuj';

  @override
  String get androidAutoTabLibrary => 'Biblioteka';

  @override
  String get androidAutoTabDownloads => 'Pobrane';

  @override
  String get settingsSearchHint => 'Szukaj w ustawieniach...';

  @override
  String get settingsSearchNoResults => 'Brak pasujących ustawień';

  @override
  String get carConnectAutoplay =>
      'Rozpocznij odtwarzanie po połączeniu z Android Auto';

  @override
  String get carConnectAutoplayIos =>
      'Rozpocznij odtwarzanie po połączeniu z CarPlay';

  @override
  String get carConnectAutoplayOnSubtitle =>
      'Ostatnio słuchana książka uruchamia się sama po połączeniu z samochodem';

  @override
  String get carConnectAutoplayOffSubtitle =>
      'Odtwarzanie czeka, aż naciśniesz odtwarzanie';

  @override
  String get sectionCar => 'Android Auto';

  @override
  String get sectionCarIos => 'CarPlay';

  @override
  String get sectionSiri => 'Siri';

  @override
  String get siriUseWithSiri => 'Używaj z Siri';

  @override
  String get siriStatusOn =>
      'Włączone. Siri może znaleźć i odtworzyć twoje książki i podcasty po nazwie.';

  @override
  String get siriStatusAsk =>
      'Pozwól Siri znajdować i odtwarzać twoje książki i podcasty po nazwie.';

  @override
  String get siriStatusOff =>
      'Siri jest wyłączona dla Absorb. Włącz ją w Ustawieniach iOS.';

  @override
  String get siriAllow => 'Zezwól';

  @override
  String get siriOpenSettings => 'Otwórz Ustawienia';

  @override
  String get siriThingsToSay => 'Co powiedzieć';

  @override
  String get siriExamples =>
      '„Odtwórz [tytuł książki] w Absorb”\n„Odtwórz [nazwa serii] w Absorb”\n„Odtwórz coś autorstwa [autor] w Absorb”\n„Odtwórz najnowszy odcinek [podcast] w Absorb”\n„Wznów Absorb”\n„Cofnij w Absorb”\n„Następny rozdział w Absorb”\n„Ustaw wyłącznik czasowy w Absorb”\n„Dodaj zakładkę w Absorb”\n„Czego słucham w Absorb”';

  @override
  String get siriShortcutsNote =>
      'Wznawianie, pauza, przewijanie, rozdziały, wyłącznik czasowy, zakładki i informacja o tym, co gra, działają nawet bez tego uprawnienia. Są też w aplikacji Skróty, do automatyzacji i przycisku czynności.';

  @override
  String get carBookOrder => 'Kolejność książek w samochodzie';

  @override
  String get carBookOrderReverse => 'Odwróć kolejność książek';

  @override
  String get carBookOrderReverseSubtitle =>
      'Od Z do A lub najpierw najstarsze dodane';

  @override
  String get carPodcastOrder => 'Kolejność podcastów w samochodzie';

  @override
  String get carEpisodesOldestFirst => 'Najpierw najstarsze odcinki';

  @override
  String get carEpisodesOldestFirstSubtitle =>
      'Dla programów słuchanych od początku';

  @override
  String get androidAutoCatBooks => 'Książki';

  @override
  String get androidAutoCatSeries => 'Serie';

  @override
  String get androidAutoCatAuthors => 'Autorzy';

  @override
  String get androidAutoCatCollections => 'Kolekcje';

  @override
  String get androidAutoCatPlaylists => 'Playlisty';

  @override
  String get showTipsAgain => 'Pokaż wskazówki ponownie';

  @override
  String get showTipsAgainSubtitle =>
      'Przywróć wskazówki o funkcjach, które zostały odrzucone';

  @override
  String get tipsRestored => 'Wskazówki przywrócone';

  @override
  String get resetSpeedPresets => 'Resetuj ustawienia prędkości';

  @override
  String get resetSpeedPresetsSubtitle =>
      'Przywróć domyślne przyciski prędkości odtwarzania';

  @override
  String get speedPresetsReset => 'Ustawienia prędkości zresetowane';

  @override
  String get editAuthor => 'Edytuj autora';

  @override
  String get authorName => 'Imię i nazwisko';

  @override
  String get authorImage => 'Zdjęcie autora';

  @override
  String get authorRemoveImage => 'Usuń zdjęcie';

  @override
  String get authorRemoveImageTitle => 'Usunąć zdjęcie autora?';

  @override
  String get authorRemoveImageConfirm =>
      'Spowoduje to usunięcie zdjęcia na serwerze.';

  @override
  String get authorImageRemoved => 'Zdjęcie usunięte';

  @override
  String get authorImageFailed => 'Nie udało się zaktualizować zdjęcia autora';

  @override
  String get authorUpdated => 'Autor zaktualizowany';

  @override
  String get authorUpdateFailed => 'Nie udało się zaktualizować autora';

  @override
  String get authorMatched => 'Autor zaktualizowany na podstawie dopasowania';

  @override
  String get authorNoMatchFound => 'Nie znaleziono dopasowania';

  @override
  String authorMergedInto(String name) {
    return 'Scalono z $name';
  }

  @override
  String get authorQuickMatchHint =>
      'Pobierz imię i nazwisko, ASIN, opis i zdjęcie z Audible dla wybranego regionu.';

  @override
  String get region => 'Region';

  @override
  String get editTabDetails => 'Szczegóły';

  @override
  String get editTabCover => 'Okładka';

  @override
  String get editTabMatch => 'Dopasuj';

  @override
  String get editTabEmbed => 'Osadź';

  @override
  String get chapterEditorTitle => 'Edytuj rozdziały';

  @override
  String get chapterNotConnected => 'Brak połączenia z serwerem';

  @override
  String get chapterErrorFirstNotZero =>
      'Pierwszy rozdział musi zaczynać się od 0:00';

  @override
  String get chapterErrorStartAfterPrevious =>
      'Początek musi być po poprzednim rozdziale';

  @override
  String get chapterErrorStartBeforeEnd =>
      'Początek musi być przed końcem książki';

  @override
  String get chapterErrorTitleRequired => 'Wymagany tytuł';

  @override
  String get chapterEditStartTitle => 'Edytuj czas rozpoczęcia';

  @override
  String get chapterTimeHintSeconds => 'Sekundy';

  @override
  String get chapterTimeHintFull => 'GG:MM:SS lub sekundy';

  @override
  String get chapterInvalidTime => 'Nieprawidłowy czas';

  @override
  String get chapterLocked => 'Rozdział jest zablokowany';

  @override
  String get chapterAllLocked => 'Wszystkie rozdziały są zablokowane';

  @override
  String chapterTrackTitle(int number) {
    return 'Ścieżka $number';
  }

  @override
  String get chapterNoAudioForPosition => 'Brak dźwięku dla tej pozycji';

  @override
  String get chapterCouldNotPlayPreview => 'Nie można odtworzyć podglądu';

  @override
  String chapterStartSetTo(String time) {
    return 'Początek ustawiony na $time';
  }

  @override
  String get chapterAddNumberedTitle => 'Dodaj numerowane rozdziały';

  @override
  String chapterNextPreview(String first, String second) {
    return 'Dalej: „$first”, „$second”, ...';
  }

  @override
  String get chapterHowMany => 'Ile rozdziałów';

  @override
  String get add => 'Dodaj';

  @override
  String get chapterCountRange => 'Wpisz liczbę od 1 do 150';

  @override
  String get chapterTitlesUpdated => 'Tytuły rozdziałów zaktualizowane';

  @override
  String get chaptersApplied => 'Rozdziały zastosowane';

  @override
  String get chapterDiscardTitle => 'Odrzucić zmiany?';

  @override
  String get chapterDiscardMessage => 'Przywróć zapisane rozdziały.';

  @override
  String get chapterRemoveAllTitle => 'Usunąć wszystkie rozdziały?';

  @override
  String get chapterRemoveAllMessage =>
      'Spowoduje to usunięcie każdego rozdziału z tej książki.';

  @override
  String get chapterAllRemoved => 'Wszystkie rozdziały usunięte';

  @override
  String get chapterFixHighlighted => 'Najpierw popraw zaznaczone rozdziały';

  @override
  String get chaptersUpdated => 'Rozdziały zaktualizowane';

  @override
  String get ok => 'OK';

  @override
  String get chapterSaveButton => 'Zapisz rozdziały';

  @override
  String get chapterAddHint => 'Dodaj rozdział (np. „Rozdział 01”)';

  @override
  String get chapterAddTooltip => 'Dodaj rozdziały';

  @override
  String get chapterRemoveAll => 'Usuń wszystkie';

  @override
  String get chapterShiftTimes => 'Przesuń czasy';

  @override
  String get chapterFromTracks => 'Ze ścieżek';

  @override
  String get chapterLookup => 'Wyszukaj';

  @override
  String get chapterShowSeconds => 'Pokaż sekundy';

  @override
  String chapterWindowMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get chapterLoopCut => 'Zapętl fragment';

  @override
  String get chapterFindStart => 'Znajdź początek';

  @override
  String get chapterFindStartListening => 'Nasłuchiwanie wokół znacznika';

  @override
  String get chapterFindStartNone => 'Nic tu nie brzmi jak początek rozdziału';

  @override
  String get chapterFindStartWider => 'Szukaj szerzej';

  @override
  String get chapterFindStartCeiling =>
      'Przeszukano pół godziny wokół znacznika. Początek jest dalej albo nie ma zapowiedzi rozdziału do usłyszenia.';

  @override
  String get chapterFindStartStrong => 'Brzmi jak ten rozdział';

  @override
  String get chapterFindStartMaybe => 'Słowa podobne do rozdziału';

  @override
  String chapterFindStartGap(String seconds) {
    return 'przerwa $seconds s';
  }

  @override
  String chapterFindStartRange(String from, String to) {
    return 'Przeszukano od $from do $to';
  }

  @override
  String get chapterFindStartNeedsModel =>
      'Najpierw włącz transkrypcję w Ustawieniach i pobierz model';

  @override
  String get chapterFindStartUseThis => 'Użyj tego';

  @override
  String chapterFindStartTitle(String title) {
    return 'Tytuł: $title';
  }

  @override
  String get chapterShiftBySeconds => 'Przesuń o (sekundy)';

  @override
  String get chapterShiftHint =>
      'Przesuwa każdy odblokowany rozdział. Użyj wartości ujemnej, aby przesunąć je wcześniej.';

  @override
  String get chapterTitleHint => 'Tytuł rozdziału';

  @override
  String get chapterStopPreview => 'Zatrzymaj podgląd';

  @override
  String get chapterPreviewFromHere => 'Podgląd od tego miejsca';

  @override
  String get chapterScrubHint =>
      'Przeciągnij lub przesuń, aby zmienić początek';

  @override
  String chapterStartAt(String time) {
    return 'Początek o $time';
  }

  @override
  String get chapterUnlock => 'Odblokuj';

  @override
  String get chapterLock => 'Zablokuj';

  @override
  String get chapterInsertBelow => 'Wstaw poniżej';

  @override
  String get chapterFindTitle => 'Znajdź rozdziały';

  @override
  String get chapterFindSubtitle =>
      'Wyszukuje rozdziały w Audible/Audnexus według ASIN.';

  @override
  String get chapterEnterAsin => 'Wpisz ASIN';

  @override
  String get chapterLookupFailed =>
      'Wyszukiwanie nie powiodło się - sprawdź ASIN';

  @override
  String get chapterNoChaptersFound =>
      'Nie znaleziono rozdziałów dla tego ASIN';

  @override
  String get chapterRemoveBranding => 'Usuń oznaczenia Audible (intro/outro)';

  @override
  String chapterFoundCount(int count) {
    return 'Znaleziono rozdziałów: $count';
  }

  @override
  String chapterAudibleVsBook(String audible, String book) {
    return 'Audible $audible  -  Książka $book';
  }

  @override
  String get chapterAudibleLonger =>
      'Wersja z Audible jest dłuższa niż twój plik - późniejsze rozdziały mogą się nie zgadzać.';

  @override
  String get chapterAudibleShorter =>
      'Wersja z Audible jest krótsza niż twój plik - rozdziały mogą się nie zgadzać.';

  @override
  String get chapterTitlesOnly => 'Tylko tytuły';

  @override
  String get chapterApplyChapters => 'Zastosuj rozdziały';

  @override
  String get coverSearchTitle => 'Wyszukaj okładkę';

  @override
  String get coverSearchRefineHint =>
      'Doprecyzuj tytuł/autora, aby oczyścić wyniki - nie zmienia to książki.';

  @override
  String get coverNoneFound => 'Nie znaleziono okładek';

  @override
  String get coverEnterTitleFirst => 'Najpierw wpisz tytuł';

  @override
  String get coverUpdated => 'Okładka zaktualizowana';

  @override
  String get coverCouldNotUpdate => 'Nie udało się zaktualizować okładki';

  @override
  String get coverApply => 'Zastosuj okładkę';

  @override
  String get coverUnknownResolution => 'Nieznana rozdzielczość';

  @override
  String get embedIntro =>
      'Osadź metadane w plikach audio, w tym okładkę i rozdziały.';

  @override
  String get embedBackupOption => 'Najpierw utwórz kopię zapasową plików audio';

  @override
  String get embedNoteInFolder =>
      'Metadane zostaną osadzone w ścieżkach audio w folderze twojego audiobooka.';

  @override
  String get embedNoteMultiTrack =>
      'Rozdziały nie są osadzane w audiobookach wielościeżkowych.';

  @override
  String get embedNoteNavigateAway =>
      'Po uruchomieniu zadania możesz opuścić tę stronę.';

  @override
  String get embedStartButton => 'Rozpocznij osadzanie metadanych';

  @override
  String embedProgress(String percent) {
    return 'Osadzanie $percent%';
  }

  @override
  String get embedProgressIndeterminate => 'Osadzanie...';

  @override
  String taskProgressKeepsRunning(String percent) {
    return '$percent% - działa dalej po opuszczeniu tej strony';
  }

  @override
  String get taskStarting => 'Uruchamianie...';

  @override
  String get embedBackupNoteIntro =>
      'Kopia zapasowa oryginalnych plików audio zostanie zapisana na serwerze w ';

  @override
  String embedBackupNotePath(String itemId) {
    return '/metadata/cache/items/$itemId/';
  }

  @override
  String get embedBackupNoteOutro =>
      '. Pamiętaj, aby okresowo czyścić pamięć podręczną elementów.';

  @override
  String get embedDialogTitle => 'Osadź metadane';

  @override
  String embedConfirmMessage(int count, String backup) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# pliku audio',
      many: '# plikach audio',
      few: '# plikach audio',
      one: '# pliku audio',
    );
    return 'Osadzić metadane w $_temp0? Twoje pliki audio zostaną przepisane$backup.';
  }

  @override
  String get embedConfirmBackupClause =>
      ' (oryginały najpierw zostaną zapisane w kopii zapasowej)';

  @override
  String get embedConfirmAction => 'Osadź';

  @override
  String get embedCouldNotStart => 'Nie udało się rozpocząć osadzania';

  @override
  String get embedStarted => 'Osadzanie rozpoczęte';

  @override
  String get embedComplete => 'Osadzanie zakończone';

  @override
  String get embedFailed => 'Osadzanie nie powiodło się';

  @override
  String get encodeComplete => 'Kodowanie zakończone';

  @override
  String get encodeFailedTask => 'Kodowanie nie powiodło się';

  @override
  String encodeProgress(String percent) {
    return 'Kodowanie $percent%';
  }

  @override
  String get encodeProgressIndeterminate => 'Kodowanie...';

  @override
  String get adminApiKeys => 'Klucze API';

  @override
  String get adminApiKeysSubtitle => 'Tokeny dostępu programistycznego';

  @override
  String get adminApiKeysNewTitle => 'Nowy klucz API';

  @override
  String get adminApiKeysName => 'Nazwa';

  @override
  String get adminApiKeysNameHint => 'np. Home Assistant';

  @override
  String get adminApiKeysOwner => 'Użytkownik';

  @override
  String get adminApiKeysExpiration => 'Wygaśnięcie';

  @override
  String get adminApiKeysActive => 'Aktywny';

  @override
  String get adminApiKeysActiveSub => 'Klucz działa od razu po utworzeniu';

  @override
  String get adminApiKeysInactive => 'Nieaktywny';

  @override
  String get adminApiKeysExpired => 'Wygasły';

  @override
  String get adminApiKeysCreate => 'Utwórz klucz';

  @override
  String get adminApiKeysCreated => 'Klucz API utworzony';

  @override
  String get adminApiKeysTokenLabel => 'Twój nowy klucz API';

  @override
  String get adminApiKeysCopyWarning =>
      'Skopiuj ten klucz teraz. Ze względów bezpieczeństwa nie zostanie pokazany ponownie.';

  @override
  String get adminApiKeysCopy => 'Kopiuj';

  @override
  String get adminApiKeysCopied => 'Skopiowano do schowka';

  @override
  String get adminApiKeysDone => 'Gotowe';

  @override
  String get adminApiKeysDeleteTitle => 'Unieważnić klucz API?';

  @override
  String get adminApiKeysDeleted => 'Klucz API unieważniony';

  @override
  String get adminApiKeysRevoke => 'Unieważnij';

  @override
  String get adminApiKeysSetActive => 'Ustaw jako aktywny';

  @override
  String get adminApiKeysSetInactive => 'Ustaw jako nieaktywny';

  @override
  String get adminApiKeysFailedCreate => 'Nie udało się utworzyć klucza API';

  @override
  String get adminApiKeysFailedDelete => 'Nie udało się unieważnić klucza API';

  @override
  String get adminApiKeysFailedUpdate =>
      'Nie udało się zaktualizować klucza API';

  @override
  String get adminApiKeysEmpty => 'Brak kluczy API';

  @override
  String get adminApiKeysEmptySub =>
      'Utwórz jeden, aby aplikacje i skrypty miały dostęp do twojego serwera';

  @override
  String get adminApiKeysNeverUsed => 'Nigdy nie używany';

  @override
  String get adminApiKeysNeverExpires => 'Bez wygaśnięcia';

  @override
  String get adminApiKeysNameRequired => 'Wpisz nazwę';

  @override
  String get adminApiKeysUserRequired => 'Wybierz użytkownika';

  @override
  String get adminApiKeysExpNever => 'Nigdy';

  @override
  String get adminApiKeysExp7d => '7 dni';

  @override
  String get adminApiKeysExp30d => '30 dni';

  @override
  String get adminApiKeysExp90d => '90 dni';

  @override
  String get adminApiKeysExp1y => '1 rok';

  @override
  String adminApiKeysLastUsed(String time) {
    return 'Ostatnio użyty $time';
  }

  @override
  String adminApiKeysExpiresOn(String date) {
    return 'Wygasa $date';
  }

  @override
  String adminApiKeysDeleteContent(String name) {
    return 'Unieważnić „$name”? Aplikacje używające tego klucza natychmiast utracą dostęp.';
  }

  @override
  String get endOfEpisode => 'Koniec odcinka';

  @override
  String get sleepTimerSheetEpisodeSleepStart => 'Uśpij na końcu odcinka';

  @override
  String get bookmarkListen => 'Słuchaj';

  @override
  String get bookmarkPause => 'Pauza';

  @override
  String get bookmarkPreviewFailed => 'Nie można odtworzyć tego miejsca.';

  @override
  String get clipExport => 'Eksportuj fragment';

  @override
  String get clipJumpToStart => 'Przejdź do początku';

  @override
  String get clipJumpToEnd => 'Przejdź do końca';

  @override
  String get clipSetStart => 'Ustaw początek';

  @override
  String get clipSetEnd => 'Ustaw koniec';

  @override
  String get clipInLabel => 'Od';

  @override
  String get clipOutLabel => 'Do';

  @override
  String get clipSave => 'Zapisz fragment';

  @override
  String clipExportSaved(String filename) {
    return 'Zapisano $filename';
  }

  @override
  String get clipExportClamped =>
      'Fragment zapisany, skrócony do końca tej ścieżki';

  @override
  String get clipExportFailed => 'Nie udało się wyeksportować fragmentu.';

  @override
  String get clipDownloadToExport =>
      'Najpierw pobierz tę książkę, aby wyeksportować fragment na iPhonie.';

  @override
  String get fsPickerTitle => 'Wybierz folder';

  @override
  String get fsServerRoot => 'Katalog główny serwera';

  @override
  String get fsEmptyFolder => 'Brak podfolderów';

  @override
  String get fsUseThisFolder => 'Użyj tego folderu';

  @override
  String get adminLibrariesManage => 'Biblioteki';

  @override
  String get adminLibrariesManageSubtitle =>
      'Twórz, edytuj i zmieniaj kolejność';

  @override
  String get adminUploadTitle => 'Prześlij media';

  @override
  String get adminUploadSubtitle => 'Dodawaj książki i podcasty z plików';

  @override
  String get adminUploadNoLibraries =>
      'Utwórz bibliotekę przed przesłaniem mediów.';

  @override
  String get adminUploadDestination => 'Miejsce docelowe';

  @override
  String get adminUploadFolder => 'Folder biblioteki';

  @override
  String get adminUploadDetails => 'Szczegóły pozycji';

  @override
  String get adminUploadOptional => 'Opcjonalne';

  @override
  String get adminUploadAutoMetadata => 'Automatycznie pobierz metadane';

  @override
  String get adminUploadAutoMetadataSubtitle =>
      'Uzupełnij tytuł, autora i serię na podstawie najlepszego dopasowania';

  @override
  String get adminUploadMetadataProvider => 'Dostawca metadanych';

  @override
  String get adminUploadMetadataSearching => 'Wyszukiwanie metadanych...';

  @override
  String get adminUploadMetadataNoResults =>
      'Nie znaleziono dopasowania metadanych. Nadal możesz przesłać tę pozycję.';

  @override
  String get adminUploadMetadataFailed =>
      'Nie udało się wyszukać metadanych. Nadal możesz przesłać tę pozycję.';

  @override
  String get adminUploadDestinationPreview => 'Miejsce docelowe na serwerze';

  @override
  String get adminUploadFiles => 'Pliki';

  @override
  String adminUploadSelectedFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pliku',
      many: '$count plików',
      few: '$count pliki',
      one: '1 plik',
    );
    return '$_temp0';
  }

  @override
  String get adminUploadChooseFiles => 'Wybierz pliki';

  @override
  String get adminUploadAddFiles => 'Dodaj pliki';

  @override
  String get adminUploadBookFilesHint =>
      'Wybierz pliki audio lub ebooki. Możesz też dołączyć okładki i pliki metadanych.';

  @override
  String get adminUploadPodcastFilesHint =>
      'Wybierz jeden lub więcej plików audio. Możesz też dołączyć okładki i pliki metadanych.';

  @override
  String get adminUploadUnsupportedFiles =>
      'Niektóre wybrane pliki nie są obsługiwane przez Audiobookshelf.';

  @override
  String get adminUploadFilePickerFailed =>
      'Nie udało się otworzyć wybranych plików.';

  @override
  String get adminUploadTitleRequired => 'Wpisz tytuł';

  @override
  String get adminUploadLibraryRequired => 'Wybierz bibliotekę';

  @override
  String get adminUploadFolderRequired => 'Wybierz folder biblioteki';

  @override
  String get adminUploadFilesRequired => 'Wybierz co najmniej jeden plik';

  @override
  String get adminUploadPodcastFileRequired =>
      'Wybierz co najmniej jeden plik audio dla tego podcastu.';

  @override
  String get adminUploadBookFileRequired =>
      'Wybierz co najmniej jeden plik audio lub ebook dla tej książki.';

  @override
  String get adminUploadPathCheckFailed =>
      'Nie udało się sprawdzić folderu docelowego. Nic nie zostało przesłane.';

  @override
  String get adminUploadDestinationExists =>
      'Ten folder docelowy już istnieje na serwerze.';

  @override
  String adminUploadDestinationUsedBy(String title) {
    return 'To miejsce docelowe jest już używane przez „$title”.';
  }

  @override
  String get adminUploadAddToExistingTitle => 'Folder już istnieje';

  @override
  String adminUploadAddToExisting(String title) {
    return 'Ten folder należy do „$title”. Dodać do niego pliki? Serwer wykryje je przy następnym skanowaniu.';
  }

  @override
  String get adminUploadAddToExistingNoItem =>
      'Ten folder już istnieje na serwerze. Dodać do niego pliki?';

  @override
  String get adminUploadAddToBook => 'Dodaj do istniejącej książki';

  @override
  String get adminUploadAddToBookHint => 'Przeszukaj tę bibliotekę';

  @override
  String get adminUploadNoBooksFound => 'Nie znaleziono książek';

  @override
  String adminUploadAddingTo(String title) {
    return 'Dodawanie plików do „$title”';
  }

  @override
  String adminUploadAddedTo(String title) {
    return 'Dodano pliki do „$title”';
  }

  @override
  String get adminUploadTargetNoFolder =>
      'Nie znaleziono folderu tej książki na serwerze.';

  @override
  String adminUploadTargetFolderMismatch(String preview, String folder) {
    return 'Serwer umieściłby te pliki w „$preview”, a nie w folderze tej książki „$folder”. Nic nie zostało przesłane.';
  }

  @override
  String get adminUploadUploading => 'Przesyłanie...';

  @override
  String adminUploadProgress(int percent) {
    return 'Przesyłanie $percent%';
  }

  @override
  String get adminUploadButton => 'Prześlij';

  @override
  String adminUploadComplete(String title) {
    return 'Przesłano „$title”';
  }

  @override
  String get adminUploadFailed => 'Przesyłanie nie powiodło się';

  @override
  String adminUploadFailedReason(String error) {
    return 'Przesyłanie nie powiodło się: $error';
  }

  @override
  String get adminUploadReselectFiles =>
      'Wybierz pliki ponownie przed ponowną próbą.';

  @override
  String get adminServerSettings => 'Ustawienia serwera';

  @override
  String get adminServerSettingsSubtitle =>
      'Skaner, przechowywanie i sortowanie';

  @override
  String get adminAuthentication => 'Uwierzytelnianie';

  @override
  String get adminAuthenticationSubtitle =>
      'Logowanie hasłem i przez OpenID Connect';

  @override
  String get adminStats => 'Statystyki';

  @override
  String get adminStatsSubtitle => 'Sumy biblioteki i słuchania';

  @override
  String get adminAllSessions => 'Wszystkie sesje';

  @override
  String get adminAllSessionsSubtitle =>
      'Przeglądaj i zarządzaj wszystkimi sesjami słuchania';

  @override
  String get adminSessionsAllUsers => 'Wszyscy użytkownicy';

  @override
  String get adminSessionsEmpty => 'Brak sesji';

  @override
  String get statsLibraryTotals => 'Sumy biblioteki';

  @override
  String get statsTotalItems => 'Pozycje';

  @override
  String get statsAudioFiles => 'Pliki audio';

  @override
  String get statsTotalSize => 'Łączny rozmiar';

  @override
  String get statsBooks => 'Książki';

  @override
  String get statsPodcasts => 'Podcasty';

  @override
  String get statsBooksSize => 'Rozmiar książek';

  @override
  String get statsYearReview => 'Podsumowanie roku';

  @override
  String get statsNoYearData => 'Brak danych dla tego roku';

  @override
  String get statsListeningTime => 'Czas słuchania';

  @override
  String get statsSessions => 'Sesje';

  @override
  String get statsBooksAdded => 'Dodane książki';

  @override
  String get statsAuthorsAdded => 'Dodani autorzy';

  @override
  String get statsTopAuthors => 'Najczęstsi autorzy';

  @override
  String get statsTopNarrators => 'Najczęstsi lektorzy';

  @override
  String get statsTopGenres => 'Najczęstsze gatunki';

  @override
  String get srvScannerSection => 'Skaner';

  @override
  String get srvFindCovers => 'Znajdź okładki';

  @override
  String get srvCoverProvider => 'Dostawca okładek';

  @override
  String get srvParseSubtitles => 'Wyodrębnij podtytuły z nazwy pliku';

  @override
  String get srvPreferMatched => 'Preferuj dopasowane metadane';

  @override
  String get srvDisableWatcher => 'Wyłącz obserwatora folderów';

  @override
  String get srvStorageSection => 'Przechowywanie';

  @override
  String get srvStoreCover => 'Przechowuj okładkę wraz z pozycją';

  @override
  String get srvStoreMetadata => 'Przechowuj metadane wraz z pozycją';

  @override
  String get srvMetadataFormat => 'Format pliku metadanych';

  @override
  String get srvFormatSection => 'Wyświetlanie i format';

  @override
  String get srvDateFormat => 'Format daty';

  @override
  String get srvTimeFormat => 'Format czasu';

  @override
  String get srvLanguage => 'Język serwera';

  @override
  String get srvChromecast => 'Obsługa Chromecast';

  @override
  String get srvAllowIframe => 'Zezwalaj na osadzanie w iframe';

  @override
  String get srvSortingSection => 'Sortowanie';

  @override
  String get srvIgnorePrefixes => 'Ignoruj przedrostki przy sortowaniu';

  @override
  String get srvSortingPrefixes => 'Przedrostki sortowania';

  @override
  String get srvAddPrefix => 'Dodaj przedrostek';

  @override
  String get srvSave => 'Zapisz ustawienia';

  @override
  String get srvSavePrefixes => 'Zapisz przedrostki';

  @override
  String get srvSaved => 'Ustawienia zapisane';

  @override
  String get srvSaveFailed => 'Nie udało się zapisać ustawień';

  @override
  String get srvPrefixesSaved => 'Przedrostki sortowania zaktualizowane';

  @override
  String get authSetLoadFailed =>
      'Nie udało się wczytać ustawień uwierzytelniania';

  @override
  String get authSetCustomMessage => 'Własna wiadomość przy logowaniu';

  @override
  String get authSetMessage => 'Wiadomość';

  @override
  String get authSetPasswordAuth => 'Uwierzytelnianie hasłem';

  @override
  String get authSetOpenId => 'Uwierzytelnianie OpenID Connect';

  @override
  String get authSetGuide => 'Przewodnik konfiguracji';

  @override
  String get authSetIssuerUrl => 'Issuer URL';

  @override
  String get authSetAutoPopulate => 'Wypełnij automatycznie';

  @override
  String get authSetAuthorizeUrl => 'Authorize URL';

  @override
  String get authSetTokenUrl => 'Token URL';

  @override
  String get authSetUserinfoUrl => 'Userinfo URL';

  @override
  String get authSetJwksUrl => 'JWKS URL';

  @override
  String get authSetLogoutUrl => 'Logout URL';

  @override
  String get authSetClientId => 'Client ID';

  @override
  String get authSetClientSecret => 'Client secret';

  @override
  String get authSetSigningAlgorithm => 'Algorytm podpisu';

  @override
  String get authSetRedirectUris => 'Dozwolone mobilne URI przekierowania';

  @override
  String get authSetRedirectUrisInfo =>
      'Aplikacje mogą wracać po zalogowaniu tylko pod te adresy. Absorb używa absorb://oauth. Gwiazdka (*) jako jedyny wpis zezwala na dowolny adres.';

  @override
  String get authSetAddRedirectUri => 'Dodaj URI';

  @override
  String get authSetAddAbsorbRedirect => 'Dodaj absorb://oauth';

  @override
  String get authSetSubfolder => 'Podfolder dla adresów przekierowania';

  @override
  String get authSetSubfolderNone => 'Brak';

  @override
  String get authSetWebRedirectInfo =>
      'Zezwól na te adresy URL u swojego dostawcy OAuth, aby logowanie mogło wrócić do aplikacji webowej:';

  @override
  String get authSetButtonText => 'Tekst przycisku';

  @override
  String get authSetMatchExisting => 'Dopasuj istniejących użytkowników według';

  @override
  String get authSetMatchNone => 'Nie dopasowuj';

  @override
  String get authSetMatchEmail => 'E-mail';

  @override
  String get authSetMatchUsername => 'Nazwa użytkownika';

  @override
  String get authSetMatchExistingInfo =>
      'Służy do powiązania istniejących użytkowników. Po powiązaniu użytkownicy są dopasowywani według unikalnego ID od dostawcy.';

  @override
  String get authSetAutoLaunch => 'Uruchom automatycznie';

  @override
  String get authSetAutoLaunchInfo =>
      'Otwórz dostawcę automatycznie ze strony logowania w wersji webowej. /login?autoLaunch=0 pomija to.';

  @override
  String get authSetAutoRegister => 'Rejestruj automatycznie';

  @override
  String get authSetAutoRegisterInfo =>
      'Automatycznie twórz nowych użytkowników po ich zalogowaniu';

  @override
  String get authSetClaimsInfo =>
      'Zostaw te pola puste, aby wyłączyć przypisywanie grup i uprawnień. Nowi użytkownicy otrzymają wtedy rolę Użytkownik.';

  @override
  String get authSetGroupClaim => 'Claim grup';

  @override
  String get authSetGroupClaimInfo =>
      'Claim zawierający listę grup użytkownika, zwykle groups. Grupy o nazwach admin, user lub guest ustawiają rolę, a wygrywa najwyższa. Jeśli żadna grupa nie pasuje, logowanie jest odrzucane.';

  @override
  String get authSetPermsClaim => 'Claim uprawnień zaawansowanych';

  @override
  String get authSetPermsClaimInfo =>
      'Claim z uprawnieniami dla użytkowników niebędących administratorami. Jeśli claim jest nieobecny, logowanie jest odrzucane, a brakująca opcja liczy się jako wyłączona. Oczekiwany format:';

  @override
  String get authSetRestartNote =>
      'Po zapisaniu uruchom serwer ponownie, aby zastosować zmiany OpenID Connect.';

  @override
  String get authSetNoChanges => 'Brak zmian do zapisania';

  @override
  String get authSetNeedOneMethod => 'Włącz co najmniej jedną metodę logowania';

  @override
  String authSetFieldRequired(String field) {
    return 'Pole $field jest wymagane';
  }

  @override
  String authSetInvalidRedirectUri(String uri) {
    return 'Nieprawidłowy URI przekierowania: $uri';
  }

  @override
  String get authSetAsteriskAlone =>
      'Gwiazdka (*) musi być jedynym URI przekierowania';

  @override
  String authSetInvalidClaim(String field) {
    return '$field nie jest prawidłową nazwą claimu';
  }

  @override
  String authSetIssuerFailed(String error) {
    return 'Nie udało się odczytać issuera: $error';
  }

  @override
  String get libNoneYet => 'Brak bibliotek';

  @override
  String get libReorderFailed => 'Nie udało się zapisać nowej kolejności';

  @override
  String get libDeleteTitle => 'Usunąć bibliotekę?';

  @override
  String get libDeleteBody =>
      'Spowoduje to trwałe usunięcie biblioteki i wszystkich jej pozycji z serwera.';

  @override
  String get libDeleted => 'Biblioteka usunięta';

  @override
  String get libDeleteFailed => 'Nie udało się usunąć biblioteki';

  @override
  String libFolderCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count folderu',
      many: '$count folderów',
      few: '$count foldery',
      one: '1 folder',
    );
    return '$_temp0';
  }

  @override
  String get libNewTitle => 'Nowa biblioteka';

  @override
  String get libEditTitle => 'Edytuj bibliotekę';

  @override
  String get libName => 'Nazwa biblioteki';

  @override
  String get libMediaType => 'Typ mediów';

  @override
  String get libMediaBook => 'Książki';

  @override
  String get libMediaPodcast => 'Podcasty';

  @override
  String get libProvider => 'Dostawca metadanych';

  @override
  String get libIcon => 'Ikona';

  @override
  String get libFolders => 'Foldery';

  @override
  String get libAddFolder => 'Dodaj folder';

  @override
  String get libNoFolders => 'Dodaj co najmniej jeden folder';

  @override
  String get libAdvanced => 'Ustawienia zaawansowane';

  @override
  String get libCoverShape => 'Kształt okładki';

  @override
  String get libCoverSquare => 'Kwadratowa';

  @override
  String get libCoverStandard => 'Standardowa';

  @override
  String get libDisableWatcher => 'Wyłącz obserwatora folderów';

  @override
  String get libSkipAsin => 'Pomijaj dopasowywanie książek z ASIN';

  @override
  String get libSkipIsbn => 'Pomijaj dopasowywanie książek z ISBN';

  @override
  String get libHideSingleSeries => 'Ukryj serie jednoksiążkowe';

  @override
  String get libAudiobooksOnly => 'Tylko audiobooki';

  @override
  String get libEpubScripted => 'Zezwalaj na zawartość ePub ze skryptami';

  @override
  String get libLaterBooksOnly =>
      'W Kontynuuj serię pokazuj tylko późniejsze książki';

  @override
  String get libPodcastRegion => 'Region wyszukiwania podcastów';

  @override
  String get libMarkPercent => 'Ukończone przy % postępu';

  @override
  String get libMarkTime => 'Ukończone przy pozostałych sekundach';

  @override
  String get libAutoScan => 'Harmonogram automatycznego skanowania (cron)';

  @override
  String get libCreate => 'Utwórz bibliotekę';

  @override
  String get libUpdate => 'Zapisz zmiany';

  @override
  String get libNameRequired => 'Wpisz nazwę biblioteki';

  @override
  String get libCreated => 'Biblioteka utworzona';

  @override
  String get libCreateFailed => 'Nie udało się utworzyć biblioteki';

  @override
  String get libUpdated => 'Biblioteka zaktualizowana';

  @override
  String get libUpdateFailed => 'Nie udało się zaktualizować biblioteki';

  @override
  String get libRemoveFoldersTitle => 'Usunąć foldery?';

  @override
  String get libRemoveFoldersBody =>
      'Usunięcie folderu usuwa jego pozycje z biblioteki. Tej czynności nie można cofnąć.';

  @override
  String get readEbook => 'Czytaj';

  @override
  String get ebookDownload => 'Pobierz';

  @override
  String get ebookDownloaded => 'Pobrano';

  @override
  String get ebookSavedOffline => 'Zapisano do czytania offline';

  @override
  String get ebookRemovedOffline => 'Usunięto z offline';

  @override
  String get ebookOfflineFailed => 'Nie udało się pobrać ebooka';

  @override
  String get ebookSaveToDevice => 'Zapisz na urządzeniu';

  @override
  String get ebookSaveToDeviceTitle => 'Zapisać na urządzeniu?';

  @override
  String get ebookSaveToDeviceBody =>
      'Zapisuje kopię pliku ebooka w wybranym miejscu na urządzeniu. Nie udostępni to książki offline w czytniku - użyj do tego opcji Pobierz.';

  @override
  String get ebookSaveNarratedBody =>
      'This EPUB has its narration built in, so the full file is large. Text only saves just the book\'s text and pictures, which is much smaller.';

  @override
  String get ebookSaveTextOnly => 'Text only';

  @override
  String get ebookSaveWithNarration => 'With narration';

  @override
  String get readerFormatUnsupported =>
      'Ten format ebooka nie może jeszcze zostać otwarty w czytniku';

  @override
  String get readerCouldNotOpen =>
      'Nie udało się otworzyć tego ebooka. Plik może być uszkodzony.';

  @override
  String get moreActions => 'Więcej';

  @override
  String get readerChapters => 'Rozdziały';

  @override
  String get readerSettings => 'Ustawienia czytnika';

  @override
  String get readerFontSize => 'Rozmiar czcionki';

  @override
  String get readerLineSpacing => 'Odstęp między wierszami';

  @override
  String get readerTextAlignment => 'Wyrównanie';

  @override
  String get readerAlignJustified => 'Wyjustowane';

  @override
  String get readerAlignLeft => 'Do lewej';

  @override
  String get readerSideMargins => 'Marginesy boczne';

  @override
  String get readerTopBottom => 'Góra i dół';

  @override
  String get readerPageLayout => 'Układ strony';

  @override
  String get readerPinTopBar => 'Zachowaj tytuł i pasek postępu na ekranie';

  @override
  String get readerPinTopBarHint =>
      'Przypina je nad stroną zamiast pokazywać po dotknięciu. Strona jest nieco krótsza, aby żaden tekst nie był zasłonięty.';

  @override
  String get readerTopBarProgress => 'Postęp na górnym pasku';

  @override
  String get readerTopBarProgressBook => 'Książka';

  @override
  String get readerTopBarProgressChapter => 'Rozdział';

  @override
  String get readerTopBarProgressBoth => 'Oba';

  @override
  String get readerSectionText => 'Tekst';

  @override
  String get readerSectionPage => 'Strona';

  @override
  String get readerSectionTopBar => 'Górny pasek i ekran';

  @override
  String get readerSectionControls => 'Sterowanie';

  @override
  String get readerSectionStats => 'Statystyki';

  @override
  String get readerSectionReading => 'Czytanie';

  @override
  String get readerSectionScreen => 'Ekran';

  @override
  String get readerParagraphSpacing => 'Odstęp między akapitami';

  @override
  String get readerParagraphSpacingBook => 'Domyślny dla książki';

  @override
  String get readerTapZones => 'Strefy dotyku';

  @override
  String get readerTapZonesHint =>
      'Przeciągnij linie, aby zmienić rozmiar pól. Dotknij pola, aby zmienić jego działanie, lub zacznij od gotowego układu.';

  @override
  String get readerTapZonesCardTop => 'Przesuń na górę';

  @override
  String get readerTapZonesCardBottom => 'Przesuń na dół';

  @override
  String get readerTapZonesCardHide => 'Zwiń kartę';

  @override
  String get readerTapZonesCardShow => 'Pokaż kartę';

  @override
  String get readerTapPrev => 'Poprzednia strona';

  @override
  String get readerTapNext => 'Następna strona';

  @override
  String get readerTapMenu => 'Pokaż sterowanie';

  @override
  String get readerTapNothing => 'Nic';

  @override
  String get readerTapKeepMenu => 'Jedno pole musi pokazywać sterowanie';

  @override
  String get readerHideControls => 'Ukryj sterowanie po';

  @override
  String get readerHideControlsNever => 'Nigdy';

  @override
  String get readerBarNotes => 'Notatki i zakreślenia';

  @override
  String readerHideControlsAfter(int seconds) {
    return '$seconds s';
  }

  @override
  String get playerDownloadStreamingInstead =>
      'Nie udało się odtworzyć tego pobrania, więc jest strumieniowane z serwera. Ponowne pobranie może to naprawić.';

  @override
  String get readerPageTurn => 'Przewracanie stron';

  @override
  String get readerPageTurnNone => 'Brak';

  @override
  String get readerPageTurnSlide => 'Przesunięcie';

  @override
  String get readerPageTurnCurl => 'Zawinięcie';

  @override
  String get readerPageTurnRipple => 'Fala';

  @override
  String get readerScrollMode => 'Tryb przewijania';

  @override
  String get readerSentenceMode => 'Tryb zdań';

  @override
  String get readerSentenceModeHint =>
      'Jedno zdanie naraz, dotknij lub przesuń, aby iść dalej. Dotyczy każdej książki.';

  @override
  String get readerSentencesAtATime => 'Zdań naraz';

  @override
  String get readerSentenceTransition => 'Przejście';

  @override
  String get readerSentenceTransitionFade => 'Zanikanie';

  @override
  String get readerSentenceTransitionBurst => 'Rozbłysk';

  @override
  String get readerSentenceSpeed => 'Prędkość';

  @override
  String get readerSentenceAutoAdvance => 'Automatyczne przechodzenie';

  @override
  String readerSentenceWpmValue(int wpm) {
    return '$wpm słów na minutę';
  }

  @override
  String get readerSentencePreparing => 'Przygotowywanie zdań';

  @override
  String get readerSentenceEnd => 'To koniec książki';

  @override
  String get readerScrollModeHint =>
      'Przewijaj książkę w dół zamiast przewracać strony. Dotyczy każdej książki.';

  @override
  String get readerKeepAwake => 'Nie wygaszaj ekranu';

  @override
  String get readerKeepAwakeHint =>
      'Zapobiega wygaszaniu ekranu, gdy czytasz we własnym tempie. Automatyczne przewijanie i czytanie wraz z lektorem zawsze go utrzymują.';

  @override
  String get readerLayoutAuto => 'Auto';

  @override
  String get readerLayoutSingle => 'Pojedyncza';

  @override
  String get readerLayoutTwoPage => 'Dwustronicowa';

  @override
  String get readerTheme => 'Motyw';

  @override
  String get readerFont => 'Czcionka';

  @override
  String get readerVolumeNav => 'Klawisze głośności zmieniają strony';

  @override
  String get readerVolumeNavOff => 'Wyłączone';

  @override
  String get readerVolumeNavNormal => 'Normalnie';

  @override
  String get readerVolumeNavMirrored => 'Odwrotnie';

  @override
  String get readerAutoScroll => 'Automatyczne przewijanie';

  @override
  String get readerAutoScrollSubtitle =>
      'Następna strona nakłada się na tę od góry w dół - przeciągnij środek ekranu, aby zmienić prędkość, dotknij, aby zatrzymać';

  @override
  String get readerAutoScrollStarted => 'Automatyczne przewijanie rozpoczęte';

  @override
  String get readerAutoScrollPaused =>
      'Wstrzymano - przytrzymaj, aby zatrzymać';

  @override
  String get readerAutoScrollResumed => 'Automatyczne przewijanie wznowione';

  @override
  String get readerAutoScrollStopped => 'Automatyczne przewijanie wyłączone';

  @override
  String get readerAutoScrollEndOfBook =>
      'Koniec książki - automatyczne przewijanie wyłączone';

  @override
  String get readerMoreControls => 'Więcej opcji sterowania';

  @override
  String get readerAutoScrollSleep =>
      'Wyłącznik czasowy automatycznego przewijania';

  @override
  String get readerAutoScrollSleepHint =>
      'Zatrzymuje przewijanie po pewnym czasie i pozwala ekranowi zgasnąć.';

  @override
  String readerAutoScrollSleepMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String readerAutoScrollSleepLeft(int minutes) {
    return 'Zostało $minutes min';
  }

  @override
  String readerAutoScrollSleepIn(int minutes) {
    return 'Automatyczne przewijanie zatrzyma się za $minutes min';
  }

  @override
  String get readerAutoScrollSleepOff =>
      'Wyłącznik czasowy automatycznego przewijania wyłączony';

  @override
  String get readerAutoScrollSleepEnded =>
      'Wyłącznik czasowy - automatyczne przewijanie wyłączone';

  @override
  String get readerDownloadStarted => 'Pobieranie rozpoczęte';

  @override
  String get detailChaptersJumpTitle => 'Przejść do tego rozdziału?';

  @override
  String detailChaptersJumpContent(String title) {
    return 'Odtwarzanie przeniesie się do „$title”.';
  }

  @override
  String get detailChaptersJump => 'Przejdź';

  @override
  String detailChaptersFinished(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ukończono $count rozdziału',
      many: 'Ukończono $count rozdziałów',
      few: 'Ukończono $count rozdziały',
      one: 'Ukończono 1 rozdział',
    );
    return '$_temp0';
  }

  @override
  String detailOtherListeners(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count innego słuchacza',
      many: '$count innych słuchaczy',
      few: '$count innych słuchaczy',
      one: '1 inny słuchacz',
      zero: 'Brak innych słuchaczy',
    );
    return '$_temp0';
  }

  @override
  String get seriesUpNext => 'Następne';

  @override
  String get seriesJumpToUpNext => 'Przejdź do następnej';

  @override
  String get seriesStatsFinished => 'Ukończone';

  @override
  String get seriesStatsListened => 'Odsłuchane';

  @override
  String get seriesStatsLeft => 'Pozostało';

  @override
  String seriesFinishedOf(int done, int total) {
    return '$done z $total';
  }

  @override
  String get detailSessionsNone => 'Brak sesji słuchania';

  @override
  String detailSessionsAll(int count) {
    return 'Wszystkie sesje: $count';
  }

  @override
  String get readerVolumeNavWhilePlaying => 'Nawet podczas odtwarzania dźwięku';

  @override
  String get readerTranslateWith => 'Tłumacz za pomocą';

  @override
  String get readerTranslateApp => 'Aplikacja na tym urządzeniu';

  @override
  String get readerTranslateApple => 'Wbudowane w iOS';

  @override
  String get readerTranslateWeb => 'Otwiera się w przeglądarce';

  @override
  String get readerTranslateHint =>
      'Zaznaczony tekst jest wysyłany do wybranego tłumacza.';

  @override
  String get readerMoreFonts => 'Pobierz więcej czcionek';

  @override
  String get readerFontRemove => 'Usuń pobraną';

  @override
  String readerFontDownloadFailed(String font) {
    return 'Nie udało się pobrać czcionki $font';
  }

  @override
  String get readerAnnotations => 'Adnotacje';

  @override
  String readerHighlights(int count) {
    return 'Zakreślenia ($count)';
  }

  @override
  String readerBookmarks(int count) {
    return 'Zakładki ($count)';
  }

  @override
  String get readerNoHighlights => 'Brak zakreśleń';

  @override
  String get readerHistory => 'Historia';

  @override
  String get sessionReading => 'Czytanie';

  @override
  String get readerHistoryEmpty =>
      'Strony, które opuścisz, są tu wymienione, abyś zawsze mógł do nich wrócić.';

  @override
  String get readerHistoryClosed => 'Zamknięto książkę';

  @override
  String get readerHistoryBeforeJump => 'Przed skokiem';

  @override
  String get readerHistoryBeforeSync => 'Przed dopasowaniem dźwięku';

  @override
  String get readerLogReading => 'Wliczaj czas czytania do statystyk';

  @override
  String get readerLogReadingHint =>
      'Zapisuje czas spędzony w czytniku jako sesję, aby był widoczny w statystykach. W Audiobookshelf liczy się jako czas słuchania.';

  @override
  String get readerNoBookmarks => 'Brak zakładek';

  @override
  String get readerBookmarkDefault => 'Zakładka';

  @override
  String get readerNoteTitle => 'Notatka';

  @override
  String get readerNoteHint => 'Dodaj notatkę...';

  @override
  String get backupAndSync => 'Kopia zapasowa i synchronizacja';

  @override
  String get backupAndSyncSubtitle =>
      'Zapisz plik kopii zapasowej lub synchronizuj ustawienia między urządzeniami';

  @override
  String get syncSettingsExperimental => 'Eksperymentalne';

  @override
  String get syncSettingsExperimentalBody =>
      'Synchronizacja jest nowa i wciąż rozwijana. Jeśli dwa urządzenia zmienią coś, gdy są rozłączone, jedna strona może utracić swoje zmiany. Traktuj plik kopii zapasowej jako bezpieczną kopię.';

  @override
  String get syncSettingsNeedServer => 'Potrzebujesz serwera?';

  @override
  String get syncSettingsNeedServerSub =>
      'Działa każdy serwer WebDAV. Nextcloud to darmowy, samodzielnie hostowany.';

  @override
  String get syncSettingsConnection => 'Połączenie';

  @override
  String get syncSettingsConnectionNotSet => 'Jeszcze nie skonfigurowano';

  @override
  String get syncSettingsBackupFile => 'Plik kopii zapasowej';

  @override
  String get syncSettingsBackupFilePlain =>
      'Zapisz wszystko do pliku, który przechowujesz.';

  @override
  String get syncSettingsBackupFileWithSync =>
      'Zapisz wszystko do pliku, który przechowujesz. Dołącz dane logowania, a przywrócenie go na innym telefonie włączy tam też synchronizację.';

  @override
  String get syncSettingsStatusOff => 'Brak synchronizacji';

  @override
  String get syncSettingsStatusProblem => 'Nie można połączyć się z serwerem';

  @override
  String get syncSettings => 'Synchronizuj ustawienia między urządzeniami';

  @override
  String get syncSettingsExtras => 'Synchronizuj także';

  @override
  String get syncSettingsIncludeRmab => 'Ustawienia ReadMeABook';

  @override
  String get syncSettingsIncludeRmabSub =>
      'Umieszcza twój token API ReadMeABook w synchronizowanym pliku';

  @override
  String get syncSettingsSubtitle =>
      'Utrzymuj synchronizację ustawień przez własny serwer WebDAV';

  @override
  String get syncSettingsEnable => 'Synchronizuj ustawienia';

  @override
  String get syncSettingsServerUrl => 'URL folderu WebDAV';

  @override
  String get syncSettingsServerUrlHint =>
      'https://cloud.example.com/remote.php/dav/files/you/Absorb';

  @override
  String get syncSettingsUsername => 'Nazwa użytkownika';

  @override
  String get syncSettingsPassword => 'Hasło';

  @override
  String get syncSettingsHeaders => 'Własne nagłówki (opcjonalnie)';

  @override
  String get syncSettingsHeadersHint =>
      'Jeden w wierszu, np. CF-Access-Client-Id: abc123';

  @override
  String get syncSettingsTest => 'Testuj połączenie';

  @override
  String get syncSettingsHoldToUpload => 'Przytrzymaj, aby wysłać teraz';

  @override
  String get syncSettingsUploadNow => 'Wyślij teraz';

  @override
  String get syncSettingsDownloadNow => 'Pobierz teraz';

  @override
  String get syncSettingsOk => 'Połączono';

  @override
  String get syncSettingsNoRemote =>
      'Połączono - nic jeszcze nie zsynchronizowano';

  @override
  String get syncSettingsAuthFailed =>
      'Nieprawidłowa nazwa użytkownika lub hasło';

  @override
  String get syncSettingsNetworkError => 'Nie można połączyć się z tym adresem';

  @override
  String get syncSettingsNotConfigured =>
      'Najpierw wpisz adres, nazwę użytkownika i hasło';

  @override
  String get syncSettingsTooLarge =>
      'Twoje ustawienia są zbyt duże do synchronizacji';

  @override
  String get syncSettingsUploaded => 'Ustawienia wysłane';

  @override
  String get syncSettingsApplied =>
      'Ustawienia zaktualizowane z drugiego urządzenia';

  @override
  String syncSettingsAppliedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Zaktualizowano $count ustawienia z drugiego urządzenia',
      many: 'Zaktualizowano $count ustawień z drugiego urządzenia',
      few: 'Zaktualizowano $count ustawienia z drugiego urządzenia',
      one: 'Zaktualizowano 1 ustawienie z drugiego urządzenia',
    );
    return '$_temp0';
  }

  @override
  String get syncSettingsUpToDate => 'Już aktualne';

  @override
  String syncSettingsLastSynced(String when) {
    return 'Ostatnia synchronizacja: $when';
  }

  @override
  String get syncSettingsNever => 'Jeszcze nie zsynchronizowano';

  @override
  String navHoldPickTitle(String tab) {
    return 'Przytrzymanie $tab będzie...';
  }

  @override
  String get navHoldPickBody =>
      'Wybierz, co robi długie naciśnięcie tej karty. Możesz to później zmienić w Ustawieniach.';

  @override
  String get navHoldSettingTitle => 'Skróty przytrzymania kart';

  @override
  String get navHoldSettingSubtitle => 'Co robi przytrzymanie każdej karty';

  @override
  String get navHoldAskNextTime => 'Zapytaj następnym razem';

  @override
  String get navHoldNothing => 'Nic';

  @override
  String get navHoldPlayPause => 'Odtwarzaj / pauza';

  @override
  String get navHoldOfflineMode => 'Tryb offline';

  @override
  String get navHoldOfflineOn => 'Tryb offline włączony';

  @override
  String get navHoldOfflineOff => 'Tryb offline wyłączony';

  @override
  String get navHoldMenu => 'Zawsze pokazuj menu';

  @override
  String get navHoldStop => 'Zatrzymaj odtwarzanie';

  @override
  String get navHoldRmabSearch => 'Wyszukiwanie ReadMeABook';

  @override
  String get navHoldRmabRequests => 'Moje prośby o książki';

  @override
  String get navHoldRmabWeb => 'Strona ReadMeABook';

  @override
  String get navHoldAdd => 'Dodaj';

  @override
  String get navHoldMoveLeft => 'Przesuń w lewo';

  @override
  String get navHoldMoveRight => 'Przesuń w prawo';

  @override
  String get navHoldRemoveFromMenu => 'Usuń z menu';

  @override
  String get navHoldEditHint =>
      'Przytrzymaj pozycję, aby ją przesunąć lub usunąć';

  @override
  String get navHoldResetMenu => 'Resetuj pozycje menu przytrzymania';

  @override
  String get navHoldMenuReset => 'Pozycje menu zresetowane';

  @override
  String get bookStatsAction => 'Statystyki słuchania';

  @override
  String get bookStatsYou => 'Ty';

  @override
  String get bookStatsEveryone => 'Wszyscy';

  @override
  String get bookStatsListened => 'Czas słuchania';

  @override
  String get bookStatsSessions => 'Sesje';

  @override
  String get bookStatsFirst => 'Pierwsze słuchanie';

  @override
  String get bookStatsLast => 'Ostatnie słuchanie';

  @override
  String get bookStatsListeners => 'Osoby, które zaczęły';

  @override
  String get bookStatsFinishedCount => 'Osoby, które skończyły';

  @override
  String get bookStatsTotalTime => 'Czas słuchania wszystkich';

  @override
  String get bookStatsNobody => 'Nikt jeszcze tego nie zaczął';

  @override
  String get bookStatsScanning =>
      'Przeglądanie sesji, może to chwilę potrwać...';

  @override
  String bookStatsScanningCount(int done, int total) {
    return 'Przeglądanie sesji, $done z $total osób...';
  }

  @override
  String bookStatsLastChecked(String when) {
    return 'Sprawdzono $when';
  }

  @override
  String get activityYourReading => 'Twoje czytanie';

  @override
  String get activityYourListening => 'Twoje słuchanie';

  @override
  String activityLastRead(String when) {
    return 'Ostatnio czytano $when';
  }

  @override
  String activityLastListened(String when) {
    return 'Ostatnio słuchano $when';
  }

  @override
  String get activityNotStarted => 'Nie rozpoczęto';

  @override
  String get activityNoReading => 'Brak sesji czytania';

  @override
  String get activityTime => 'Czas';

  @override
  String get activityAverage => 'Śr.';

  @override
  String get activityProgress => 'Postęp';

  @override
  String activityReached(String percent) {
    return 'Osiągnięto $percent';
  }

  @override
  String get readingLogTitle => 'Dziennik czytania';

  @override
  String get readingLogTotalTime => 'Łączny czas';

  @override
  String get readingLogAverageSession => 'Średnia sesja';

  @override
  String get readingLogActiveDays => 'Aktywne dni';

  @override
  String readingLogActiveDaysOf(int active, int total) {
    return '$active z $total';
  }

  @override
  String get readingLogPace => 'Tempo';

  @override
  String readingLogPacePerHour(String percent) {
    return '$percent%/godz.';
  }

  @override
  String get readingLogLastRead => 'Ostatnio czytano';

  @override
  String get readingLogStarted => 'Rozpoczęto';

  @override
  String get readingLogFinished => 'Ukończono';

  @override
  String get readingLogNotSet => 'Nie ustawiono';

  @override
  String readingLogLeftMinutes(int m) {
    return 'Około $m min do końca';
  }

  @override
  String readingLogLeftHours(int h) {
    return 'Około $h godz. do końca';
  }

  @override
  String readingLogLeftHoursMinutes(int h, int m) {
    return 'Około $h godz. $m min do końca';
  }

  @override
  String get readingLogLeftMax => 'Ponad 99 godz. do końca';

  @override
  String readingLogUpOnLastWeek(int percent) {
    return 'O $percent% więcej niż tydzień wcześniej';
  }

  @override
  String readingLogDownOnLastWeek(int percent) {
    return 'O $percent% mniej niż tydzień wcześniej';
  }

  @override
  String get readingLogNewThisWeek => 'Nowe w tym tygodniu';

  @override
  String get readingLogSameAsLastWeek => 'Tyle samo co tydzień wcześniej';

  @override
  String get readingLogQuietTwoWeeks => 'Nic w ciągu ostatnich dwóch tygodni';

  @override
  String get readingLogWhereYouRead => 'Gdzie to czytałeś';

  @override
  String get readingLogSourceIos => 'Aplikacja iOS';

  @override
  String get readingLogSourceAndroid => 'Aplikacja Android';

  @override
  String get readingLogChartTitle => 'Postęp w czasie';

  @override
  String get readingLogChartPosition => 'Osiągnięta pozycja';

  @override
  String get readingLogChartMinutes => 'Minuty';

  @override
  String get readingLogRecords => 'Rekordy';

  @override
  String get readingLogLongestSession => 'Najdłuższa sesja';

  @override
  String get readingLogBestDay => 'Najlepszy dzień';

  @override
  String get readingLogLongestStreak => 'Najdłuższa seria';

  @override
  String readingLogStreakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dnia',
      many: '$count dni',
      few: '$count dni',
      one: '1 dzień',
    );
    return '$_temp0';
  }

  @override
  String get readingLogJumpedBack => 'Cofnięto';

  @override
  String readingLogJumpedBackTimes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count raza',
      many: '$count razy',
      few: '$count razy',
      one: '1 raz',
    );
    return '$_temp0';
  }

  @override
  String get readingLogFirstOpened => 'Pierwsze otwarcie';

  @override
  String get readingLogAttempts => 'Podejścia';

  @override
  String readingLogAttempt(int index) {
    return 'Podejście $index';
  }

  @override
  String readingLogAttemptBegan(int index) {
    return 'Rozpoczęto podejście $index';
  }

  @override
  String get readingLogOutcomeCompleted => 'Ukończono';

  @override
  String get readingLogOutcomeSkimmed => 'Przejrzano';

  @override
  String get readingLogOutcomeAbandoned => 'Porzucono';

  @override
  String get readingLogOutcomeInProgress => 'W toku';

  @override
  String readingLogSpanRange(String from, String to) {
    return '$from - $to';
  }

  @override
  String readingLogSpanSince(String from) {
    return 'Od $from';
  }

  @override
  String readingLogSpanEnded(String to) {
    return 'Zakończono $to';
  }

  @override
  String get readingLogSpanUnknown => 'Brak zapisanych dat';

  @override
  String readingLogSessionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sesji',
      many: '$count sesji',
      few: '$count sesje',
      one: '1 sesja',
    );
    return '$_temp0';
  }

  @override
  String readingLogShowing(int shown, int total) {
    return '$shown z $total';
  }

  @override
  String readingLogGapDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dnia bez czytania',
      many: '$count dni bez czytania',
      few: '$count dni bez czytania',
      one: '1 dzień bez czytania',
    );
    return '$_temp0';
  }

  @override
  String get readingLogEmpty => 'Brak zapisanych sesji';

  @override
  String get readingLogEmptyHint =>
      'Sesje pojawiają się tutaj podczas czytania lub słuchania, z dowolnej aplikacji lub urządzenia synchronizującego się z BookOrbit.';

  @override
  String get readingLogNoMatches => 'Brak sesji w tym zakresie';

  @override
  String get readingLogAllTime => 'Cały czas';

  @override
  String get readingLogLast30 => 'Ostatnie 30 dni';

  @override
  String get readingLogLast90 => 'Ostatnie 90 dni';

  @override
  String get readingLogThisYear => 'Ten rok';

  @override
  String get readingLogAllFormats => 'Wszystkie formaty';

  @override
  String get readingLogSortBy => 'Sortuj według';

  @override
  String get readingLogSortDay => 'Dzień';

  @override
  String get readingLogSortLength => 'Długość';

  @override
  String get readingLogSortChange => 'Zmiana';

  @override
  String get readingLogSortReached => 'Osiągnięte';

  @override
  String get readingLogNewestFirst => 'Najnowsze najpierw';

  @override
  String get readingLogOldestFirst => 'Najstarsze najpierw';

  @override
  String get readingLogMostFirst => 'Najwięcej najpierw';

  @override
  String get readingLogLeastFirst => 'Najmniej najpierw';

  @override
  String get readingLogDeleteTitle => 'Usunąć tę sesję?';

  @override
  String get readingLogDeleteBody =>
      'Zostanie usunięta z dziennika czytania książki i twoich statystyk w BookOrbit.';

  @override
  String get readingLogDeleteFailed => 'Nie udało się usunąć sesji';

  @override
  String get readingLogLoadFailed => 'Nie udało się wczytać dziennika czytania';

  @override
  String get navHoldServerScan => 'Skanowanie serwera';

  @override
  String get navHoldScanAll => 'Skanuj wszystkie biblioteki';

  @override
  String navHoldScanLibrary(String name) {
    return 'Skanuj $name';
  }

  @override
  String get navHoldScanStarted => 'Skanowanie rozpoczęte';

  @override
  String get navHoldScanFailed => 'Nie udało się rozpocząć skanowania';

  @override
  String get navHoldAdminLogs => 'Logi serwera';

  @override
  String navHoldAdminPage(String page) {
    return 'Administracja: $page';
  }

  @override
  String get navHoldNothingPlaying => 'Nie ma jeszcze nic do odtworzenia';

  @override
  String get navHoldReadBook => 'Czytaj bieżącą książkę';

  @override
  String get navHoldBookDetails => 'Szczegóły bieżącej książki';

  @override
  String get syncSourceTitle => 'Którą kopię ma zachować synchronizacja?';

  @override
  String get syncSourceBody =>
      'Ta kopia zapasowa włączyła synchronizację ustawień. Użyć ostatniej synchronizacji z serwera, czy uczynić tę kopię źródłem prawdy? Wybranie kopii zapasowej zastępuje kopię na serwerze dla wszystkich twoich zsynchronizowanych urządzeń.';

  @override
  String get syncSourceUseServer => 'Ostatnia synchronizacja z serwera';

  @override
  String get syncSourceUseBackup => 'Ta kopia zapasowa';

  @override
  String get syncSettingsWhatTravels =>
      'Synchronizowane są twoje preferencje, prędkości poszczególnych książek, układ ekranu głównego, kolejność Absorbing, notatki i zakreślenia w ebookach. Dane logowania, foldery pobierania, przełączniki automatycznego pobierania, wygląd czytnika i wszystko, co nie zostało jeszcze wysłane na serwer, zostają na tym urządzeniu.';

  @override
  String get syncSettingsDownloadWarnTitle =>
      'Zastąpić ustawienia tego urządzenia?';

  @override
  String get syncSettingsDownloadWarnBody =>
      'Zsynchronizowana kopia nadpisze ustawienia na tym urządzeniu.';

  @override
  String get syncSettingsDownloadWarnConfirm => 'Zastąp';

  @override
  String get readerCopied => 'Skopiowano do schowka';

  @override
  String get dictionaryNotFound => 'Nie znaleziono definicji tego słowa.';

  @override
  String get dictionaryError =>
      'Nie można połączyć się ze słownikiem. Sprawdź połączenie.';

  @override
  String get dictionaryRetry => 'Ponów';

  @override
  String get dictionarySearchWeb => 'Szukaj w sieci';

  @override
  String get readerTooltipCopy => 'Kopiuj';

  @override
  String get readerTooltipSearch => 'Szukaj';

  @override
  String get readerTooltipDefine => 'Definicja';

  @override
  String get readerTooltipTranslate => 'Tłumacz';

  @override
  String get readerSearchHint => 'Szukaj w tej książce…';

  @override
  String readerSearchMatches(int count, String query) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count wyniku dla „$query”',
      many: '$count wyników dla „$query”',
      few: '$count wyniki dla „$query”',
      one: '$count wynik dla „$query”',
    );
    return '$_temp0';
  }

  @override
  String get readerSearchEmpty => 'Wpisz słowo lub frazę i dotknij szukaj.';

  @override
  String readerSearchNoResults(String query) {
    return 'Brak wyników dla „$query”.';
  }

  @override
  String get transcriptionTitle => 'Transkrypcja';

  @override
  String get transcriptionAdvancedSubtitle =>
      'Do transkrypcji zakładek i odnajdywania miejsca między audiobookiem a ebookiem';

  @override
  String get transcriptionEnable => 'Włącz transkrypcję';

  @override
  String get transcriptionEnableSubtitle =>
      'Dodaje Transkrybuj do zakładek, Znajdź pozycję w ebooku do odtwarzacza i Znajdź w audiobooku do czytnika';

  @override
  String get transcriptionDisclaimer =>
      'Działa w całości na twoim urządzeniu, nic nie jest nigdzie wysyłane. Podczas pracy zużywa dodatkową baterię i moc obliczeniową, a transkrybować można tylko pobrane książki.';

  @override
  String get transcriptionNeedModelHint =>
      'Pobierz model poniżej, aby zacząć transkrypcję.';

  @override
  String get transcriptionModelSection => 'Modele';

  @override
  String get transcriptionModelTiny => 'Tiny';

  @override
  String get transcriptionModelTinyDesc =>
      'Najszybszy, mniej dokładny. Około 31 MB.';

  @override
  String get transcriptionModelBase => 'Base';

  @override
  String get transcriptionModelBaseDesc => 'Dobry kompromis. Około 57 MB.';

  @override
  String get transcriptionModelSmall => 'Small';

  @override
  String get transcriptionModelSmallDesc =>
      'Wolniejszy, ale najdokładniejszy - najlepszy na wydajnym telefonie. Około 182 MB.';

  @override
  String get transcriptionAutoHint =>
      'Gdy pobrano więcej niż jeden, każde zadanie wybiera spośród nich. Książki z ebookiem dostają najszybszy, bo dokładne słowa i tak pochodzą z ebooka. Książki bez niego dostają najdokładniejszy - poza czytaniem wraz z lektorem, które pozostaje poniżej Small, by nadążać za narracją.';

  @override
  String get transcriptionDownload => 'Pobierz';

  @override
  String get transcriptionDownloadFailed =>
      'Pobieranie nie powiodło się. Sprawdź połączenie i spróbuj ponownie.';

  @override
  String get transcribe => 'Transkrybuj';

  @override
  String get transcribing => 'Transkrybowanie...';

  @override
  String get transcriptionResultTitle => 'Transkrypcja';

  @override
  String get transcriptionSaveToNote => 'Zapisz w notatce';

  @override
  String get transcriptionSavedToNote => 'Zapisano w notatce zakładki';

  @override
  String get transcriptionDisabledHint =>
      'Włącz transkrypcję zakładek w Ustawieniach, w sekcji Zaawansowane.';

  @override
  String get transcriptionNoModelDownloaded =>
      'Najpierw pobierz model transkrypcji w Ustawieniach.';

  @override
  String get transcriptionNotDownloadedBook =>
      'Pobierz tę książkę lub połącz się z serwerem, aby ją transkrybować.';

  @override
  String get transcriptionNoMetadataMsg =>
      'Nie można zlokalizować tego miejsca w pobranym pliku. Spróbuj pobrać książkę ponownie.';

  @override
  String get transcriptionBusyMsg => 'Trwa już transkrypcja. Poczekaj chwilę.';

  @override
  String get transcriptionEmptyMsg => 'W tym miejscu nie znaleziono mowy.';

  @override
  String get transcriptionFailedMsg =>
      'Nie udało się transkrybować tego miejsca. Spróbuj ponownie.';

  @override
  String get transcriptionPlaySnippet => 'Słuchaj';

  @override
  String get transcriptionPauseSnippet => 'Pauza';

  @override
  String get transcriptionIntroBody =>
      'Odsłuchuje wybraną ilość dźwięku, zaczynając tuż przed zakładką, i zamienia ją na tekst na twoim urządzeniu. Dłuższe fragmenty trwają dłużej, a transkrypcja nie jest w 100% dokładna. Po zakończeniu tekst jest zapisywany w notatce zakładki, gotowy do poprawienia lub udostępnienia.';

  @override
  String get transcriptionUseEbookText =>
      'Użyj dokładnego tekstu ebooka, gdy da się go dopasować';

  @override
  String get lyricsMode => 'Transkrypcja na żywo';

  @override
  String get lyricsListeningAhead => 'Nasłuchiwanie do przodu...';

  @override
  String get lyricsDisplaySection => 'Transkrypcja na żywo';

  @override
  String get lyricsFontSize => 'Rozmiar wierszy';

  @override
  String get lyricsMaxLines => 'Wyświetlane wiersze';

  @override
  String get lyricsFullCover => 'Użyj całej okładki';

  @override
  String get lyricsFullCoverHint =>
      'Pokazuje transkrypcję zamiast grafiki podczas działania, mieszcząc tyle wierszy, ile jest miejsca.';

  @override
  String get lyricsBatteryInfo =>
      'Transkrypcja na żywo i czytanie wraz z lektorem zużywają dodatkową baterię i moc obliczeniową podczas działania. Na telefonach z wolniejszymi procesorami wiersze mogą pojawiać się dłużej.';

  @override
  String get lyricsClearCache => 'Wyczyść pamięć podręczną transkrypcji';

  @override
  String lyricsClearCacheHint(String size) {
    return '$size zapisanych wierszy transkrypcji. Wyczyszczone książki i odcinki są transkrybowane ponownie w trakcie słuchania.';
  }

  @override
  String get lyricsClearCacheConfirm =>
      'Usunąć zapisane transkrypcje każdej książki i odcinka? Odbudowują się automatycznie podczas słuchania.';

  @override
  String get lyricsCacheCleared => 'Pamięć podręczna transkrypcji wyczyszczona';

  @override
  String get lyricsIntroBody =>
      'Ta funkcja nasłuchuje trochę przed lektorem i pokazuje każdą linię w trakcie jej wypowiadania, transkrybowaną na telefonie – nic nie opuszcza urządzenia. Po włączeniu poczekaj kilka sekund z odtwarzaniem, aż uzyska przewagę. Transkrypcja pojawi się, gdy przewaga będzie gotowa, a start w pauzie zapewnia najpłynniejsze działanie. Podczas pracy zużywa więcej baterii i mocy obliczeniowej.';

  @override
  String lyricsBuildingLead(String percent) {
    return 'Wyprzedzanie lektora... $percent';
  }

  @override
  String lyricsCantKeepUp(String speed) {
    return 'Nie można transkrybować tak szybko, jak słuchasz przy $speed';
  }

  @override
  String get lyricsTurnOn => 'Włącz';

  @override
  String get readAlong => 'Czytaj razem';

  @override
  String get readAlongNeedsPlaying => 'Najpierw odtwórz audiobook tej książki';

  @override
  String get narrationListen => 'Słuchaj';

  @override
  String get narrationPlayFromHere => 'Odtwarzaj stąd';

  @override
  String get narrationPreparing => 'Przygotowywanie narracji';

  @override
  String get narrationNone => 'Ten ebook nie ma narracji do odtworzenia';

  @override
  String get narrationDownloadTitle => 'Pobierz, aby słuchać';

  @override
  String get narrationDownloadBody =>
      'Ta książka to EPUB3, który czyta sam siebie na głos. Audiobookshelf nie może strumieniować jej narracji, więc audio trzeba pobrać przed odtworzeniem.';

  @override
  String get narrationDownloadStarted =>
      'Pobieranie narracji. Po zakończeniu dotknij Absorb.';

  @override
  String get narrationTextBody =>
      'EPUB tej książki ma własne słowa dla każdej chwili audio, więc tekst jest kopiowany prosto z książki. Wybierz, ile dodać do notatki zakładki.';

  @override
  String get narrationTextLoading => 'Pobieranie słów z książki';

  @override
  String get downloadToAbsorb => 'Pobierz do Absorb';

  @override
  String get narrationUpNextTitle => 'Pobierz następną pozycję';

  @override
  String narrationUpNextBody(String title) {
    return '$title jest następna w kolejce. To EPUB3, który czyta sam siebie na głos, więc trzeba go pobrać, zanim będzie można go odtworzyć.';
  }

  @override
  String narrationQueueStopped(String title) {
    return 'Zatrzymano przed: $title. Pobierz, aby kontynuować.';
  }

  @override
  String get transcriptionNeedsDownload =>
      'Potrzebne jest audio na telefonie. Pobrać je teraz?';

  @override
  String get transcriptionDownloadStarted =>
      'Pobieranie. Włącz to ponownie po zakończeniu';

  @override
  String get readAlongFollow => 'Czytanie razem podąża za';

  @override
  String get syncReadingListening => 'Synchronizuj czytanie i słuchanie';

  @override
  String get syncReadingListeningHint =>
      'Dla książek z audiobookiem i ebookiem. Gdy przestaniesz słuchać, ebook przejdzie do miejsca, w którym skończyłeś. Gdy opuścisz czytnik, audiobook przejdzie do Twojej strony. Przesuwa tylko do przodu.';

  @override
  String get syncEbookMoved =>
      'Ebook przeszedł do miejsca, w którym przestałeś słuchać';

  @override
  String get syncAudioMoved =>
      'Audiobook przeszedł do miejsca, w którym przestałeś czytać';

  @override
  String get syncAudioOffer =>
      'Dotknij, aby przejść do miejsca, w którym przestałeś czytać';

  @override
  String get syncFindingAudio => 'Szukanie Twojej strony w audiobooku';

  @override
  String get syncFindingEbook => 'Szukanie Twojego miejsca w ebooku';

  @override
  String get syncFailed => 'Nie udało się zsynchronizować pozycji';

  @override
  String get syncAlreadyTogether => 'Już zsynchronizowano';

  @override
  String get syncPosition => 'Synchronizuj pozycję';

  @override
  String get readAlongFollowHint =>
      'Czas słów jest obliczany między znacznikami czasu transkrypcji, więc może się nieznacznie rozjeżdżać w obrębie zdania.';

  @override
  String get readAlongFollowWord => 'Słowo';

  @override
  String get readAlongFollowSentence => 'Zdanie';

  @override
  String get readAlongColor => 'Kolor czytania razem';

  @override
  String get readAlongLost => 'Nie można znaleźć narracji na stronie';

  @override
  String get readAlongBackToNarration => 'Wróć do narracji';

  @override
  String get findInEbook => 'Znajdź w ebooku';

  @override
  String get findInEbookSearching => 'Szukanie tego miejsca w ebooku...';

  @override
  String get findInEbookNotFound =>
      'Nie udało się znaleźć tego miejsca w ebooku.';

  @override
  String get findInEbookNeedsEpub => 'Znajdowanie w ebooku wymaga ebooka EPUB.';

  @override
  String get findInEbookNoEbook => 'Ta książka nie ma ebooka.';

  @override
  String get findInAudiobook => 'Znajdź w audiobooku';

  @override
  String get findInAudiobookSearching =>
      'Szukanie tego miejsca w audiobooku...';

  @override
  String get findInAudiobookStillSearching =>
      'Wciąż szukam tego miejsca w audio...';

  @override
  String get findInAudiobookSearchingLong =>
      'Długi rozdział, wciąż szukam. Może to potrwać minutę lub dwie...';

  @override
  String get findInAudiobookNotFound =>
      'Nie udało się znaleźć tego miejsca w audiobooku.';

  @override
  String get transcriptionWhisperInfo =>
      'Transkrypcję zapewnia Whisper, otwarty model rozpoznawania mowy, który słucha narracji i zapisuje słowa – wszystko na tym urządzeniu.';

  @override
  String get transcriptionWhisperLearnMore => 'Dowiedz się więcej o Whisper';

  @override
  String get findInAudiobookIntroBody =>
      'Ta funkcja słucha audiobooka w pobliżu miejsca, w którym czytasz, i dopasowuje go do tego fragmentu, wszystko na Twoim urządzeniu. Może to potrwać do minuty. Jeśli nie uda się pewnie dopasować miejsca, nic się nie przesunie.';

  @override
  String get findInAudiobookAfterLabel => 'Gdy miejsce zostanie znalezione';

  @override
  String get findInAudiobookStay => 'Czytaj dalej';

  @override
  String get findInAudiobookGoPlayer => 'Otwórz odtwarzacz';

  @override
  String get findInAudiobookPlaying =>
      'Odtwarzanie tego fragmentu w audiobooku';

  @override
  String get catchUpAudioAhead =>
      'Audiobook jest dalej. Dotknij, aby tam przejść.';

  @override
  String get catchUpPageAhead =>
      'Ta strona jest przed audiobookiem. Dotknij, aby przesunąć audiobook tutaj.';

  @override
  String get readerShortcutButton => 'Przycisk skrótu';

  @override
  String get keepScreenOn => 'Nie wygaszaj ekranu';

  @override
  String get keepScreenOnActive => 'Ekran pozostaje włączony';

  @override
  String get keepScreenOnUntilClosed =>
      'Ekran pozostaje włączony, dopóki nie zamkniesz aplikacji';

  @override
  String get keepScreenOnOff => 'Ekran może się znowu wyłączać';

  @override
  String get keepScreenOnOffUntilRestart =>
      'Wyłączone do ponownego uruchomienia aplikacji. Przełącznik w Ustawieniach pozostaje włączony';

  @override
  String get keepScreenOnPlayer => 'Nie wygaszaj ekranu w odtwarzaczu';

  @override
  String get keepScreenOnPlayerSubtitle =>
      'Ekran pozostaje włączony, gdy odtwarzacz jest otwarty';

  @override
  String get keepScreenOnCarMode => 'Nie wygaszaj ekranu w trybie samochodowym';

  @override
  String get keepScreenOnCarModeSubtitle =>
      'Ekran pozostaje włączony, gdy tryb samochodowy jest otwarty';

  @override
  String get loginServerType => 'Typ serwera';

  @override
  String get authBookOrbitDefaultPassword =>
      'To konto nadal ma hasło domyślne. Zmień je w BookOrbit, a następnie zaloguj się ponownie.';

  @override
  String get authBookOrbitPasswordOff =>
      'Logowanie hasłem jest wyłączone na tym serwerze. Zaloguj się za pomocą magicznego linku lub logowania jednokrotnego.';

  @override
  String get authServerIsBookOrbit =>
      'To serwer BookOrbit. Wybierz BookOrbit nad adresem serwera.';

  @override
  String get authServerIsAudiobookshelf =>
      'To serwer Audiobookshelf. Wybierz Audiobookshelf nad adresem serwera.';

  @override
  String get castNotAvailableBookOrbit =>
      'Przesyłanie nie jest dostępne z serwerami BookOrbit';

  @override
  String get loginMagicLink => 'Magiczny link';

  @override
  String get loginMagicLinkDescription =>
      'Zaloguj się magicznym linkiem BookOrbit lub wklej link do hasła, aby ustawić hasło.';

  @override
  String get collectionPublicTitle => 'Publiczna';

  @override
  String get collectionPublicSubtitle =>
      'Każdy na tym serwerze może zobaczyć tę kolekcję';

  @override
  String loginSignInWithProvider(String provider) {
    return 'Zaloguj się przez $provider';
  }

  @override
  String get loginSignInWithSso => 'Zaloguj się przez SSO';

  @override
  String get loginChooseSsoProvider => 'Wybierz sposób logowania';

  @override
  String get loginRedirectUriBookOrbit =>
      'Redirect URI: bookorbit://oauth2-callback';

  @override
  String get readStatusTitle => 'Status czytania';

  @override
  String get readStatusHint =>
      'Słuchanie lub czytanie książki może ponownie go zmienić.';

  @override
  String get readStatusUnread => 'Nieprzeczytana';

  @override
  String get readStatusWantToRead => 'Chcę przeczytać';

  @override
  String get readStatusReading => 'Czytam';

  @override
  String get readStatusOnHold => 'Wstrzymana';

  @override
  String get readStatusRereading => 'Czytam ponownie';

  @override
  String get readStatusRead => 'Przeczytana';

  @override
  String get readStatusSkimmed => 'Przejrzana';

  @override
  String get readStatusAbandoned => 'Porzucona';

  @override
  String get personalNoteTitle => 'Twoja notatka';

  @override
  String get personalNoteAdd => 'Dodaj prywatną notatkę';

  @override
  String get personalNoteHint => 'Tylko Ty widzisz tę notatkę.';

  @override
  String get moreLikeThis => 'Więcej podobnych';

  @override
  String get coverSlotAudiobook => 'Okładka audiobooka';

  @override
  String get coverSlotBook => 'Okładka książki';

  @override
  String get cardButtonFill => 'Tło przycisków';

  @override
  String get cardButtonFillSubtitle =>
      'Jak wypełnione są przyciski na karcie odtwarzacza';

  @override
  String get cardButtonFillClear => 'Przezroczyste';

  @override
  String get cardButtonFillSubtle => 'Delikatne';

  @override
  String get cardButtonFillSolid => 'Pełne';

  @override
  String get loginBookOrbitPreview =>
      'Obsługa BookOrbit jest nowa. Odtwarzanie, pobieranie i przeglądanie działają, ale niektóre ekrany mogą jeszcze wyglądać lub działać jak w Audiobookshelf. Śledź postępy na GitHubie i daj nam znać, jeśli coś wydaje się nie tak.';

  @override
  String get signedOutTapToSignIn =>
      'Wylogowano. Dotknij, aby zalogować się ponownie.';

  @override
  String get authSignedOutKeepListening =>
      'Zostałeś wylogowany. Pobrane pozycje nadal się odtwarzają. Dotknij czerwonej chmurki, aby zalogować się ponownie.';

  @override
  String signedOutSyncNote(String username, String server) {
    return 'To, czego słuchasz po wylogowaniu, jest zapisywane na tym telefonie i synchronizuje się po ponownym zalogowaniu jako $username na $server. Działa każdy sposób logowania na to konto.';
  }

  @override
  String get comicReadingDirection => 'Kierunek czytania';

  @override
  String comicPageNumber(int page) {
    return 'Strona $page';
  }

  @override
  String get comicBookmarkRemoveFailed =>
      'Nie udało się usunąć zakładki z serwera. Spróbuj ponownie, gdy będziesz online.';

  @override
  String get comicLeftToRight => 'Od lewej do prawej';

  @override
  String get comicRightToLeft => 'Od prawej do lewej (manga)';

  @override
  String get comicNeedsConnection =>
      'Ten komiks otwiera się strona po stronie z serwera, więc wymaga połączenia.';

  @override
  String get comicNoPages => 'Nie znaleziono stron w tym komiksie.';

  @override
  String get boAdminTitle => 'Administracja serwera';

  @override
  String get boAdminSubtitle =>
      'Użytkownicy i biblioteki na tym serwerze BookOrbit';

  @override
  String get boAdminUsers => 'Użytkownicy';

  @override
  String get boAdminLibraries => 'Biblioteki';

  @override
  String boAdminUserCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count osoby',
      many: '$count osób',
      few: '$count osoby',
      one: '1 osoba',
    );
    return '$_temp0';
  }

  @override
  String boAdminLibraryCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count biblioteki',
      many: '$count bibliotek',
      few: '$count biblioteki',
      one: '1 biblioteka',
    );
    return '$_temp0';
  }

  @override
  String get boAdminSaved => 'Zapisano';

  @override
  String get boAdminFailed => 'Nie udało się. Spróbuj ponownie.';

  @override
  String get boAdminOffline => 'Nie można połączyć się z serwerem.';

  @override
  String get boUsersSearch => 'Szukaj użytkowników';

  @override
  String get boUsersNone => 'Brak użytkowników';

  @override
  String get boUsersFilterAll => 'Wszyscy';

  @override
  String get boUsersFilterAdmins => 'Administratorzy';

  @override
  String get boUsersFilterActive => 'Aktywni';

  @override
  String get boUsersFilterInactive => 'Nieaktywni';

  @override
  String get boUsersFilterAttention => 'Wymagają uwagi';

  @override
  String get boUserBadgeAdmin => 'Admin';

  @override
  String get boUserBadgeInactive => 'Nieaktywny';

  @override
  String get boUserBadgeLocked => 'Zablokowany';

  @override
  String get boUserBadgeNoPassword => 'Brak hasła';

  @override
  String boUserLastActive(String date) {
    return 'Ostatnia aktywność: $date';
  }

  @override
  String get boUserNeverSignedIn => 'Nigdy się nie logował';

  @override
  String get boUserNew => 'Nowy użytkownik';

  @override
  String get boUserCreate => 'Utwórz';

  @override
  String get boUserUsername => 'Nazwa użytkownika';

  @override
  String get boUserUsernameHint =>
      'Co najmniej 3 znaki. Nie można tego później zmienić.';

  @override
  String get boUserName => 'Nazwa';

  @override
  String get boUserEmail => 'E-mail';

  @override
  String get boUserEmailInvalid => 'Wpisz prawidłowy adres e-mail';

  @override
  String get boUserActive => 'Aktywny';

  @override
  String get boUserActiveSubtitle =>
      'Nieaktywni użytkownicy nie mogą się logować';

  @override
  String get boUserAdmin => 'Administrator';

  @override
  String get boUserAdminSubtitle => 'Pełny dostęp do wszystkiego na serwerze';

  @override
  String get boUserAdminHasAll =>
      'Administratorzy mają wszystkie uprawnienia i widzą każdą bibliotekę.';

  @override
  String get boUserPermissions => 'Uprawnienia';

  @override
  String get boUserPresetNone => 'Brak';

  @override
  String get boUserPresetStandard => 'Standardowe';

  @override
  String get boUserPresetEverything => 'Wszystkie';

  @override
  String get boUserLibraries => 'Biblioteki';

  @override
  String get boUserLibrariesHint => 'Biblioteki, które ta osoba może widzieć.';

  @override
  String get boUserPasswordLink => 'Wyślij link do hasła';

  @override
  String get boUserPasswordLinkSubtitle =>
      'Link do ustawienia nowego hasła, ważny przez 15 minut';

  @override
  String get boUserExternal =>
      'Loguje się przez logowanie jednokrotne, więc hasłem zarządza się tam.';

  @override
  String get boUserUnlock => 'Odblokuj konto';

  @override
  String get boUserUnlocked => 'Konto odblokowane';

  @override
  String get boUserDelete => 'Usuń użytkownika';

  @override
  String boUserDeleteTitle(String name) {
    return 'Usunąć $name?';
  }

  @override
  String get boUserDeleteBody =>
      'Jego konto i wszystko, co ma na tym serwerze, zostaną usunięte. Tej operacji nie można cofnąć.';

  @override
  String get boUserDeleted => 'Użytkownik usunięty';

  @override
  String get boUserLinkTitle => 'Link do hasła';

  @override
  String boUserLinkBody(String name) {
    return 'Udostępnij ten link użytkownikowi $name. Pozwala ustawić hasło i działa przez 15 minut.';
  }

  @override
  String get boPasswordRules =>
      'Co najmniej 8 znaków, z wielką literą, małą literą i cyfrą.';

  @override
  String get boSetPasswordTitle => 'Ustaw hasło';

  @override
  String get boSetPasswordSubmit => 'Ustaw hasło i zaloguj się';

  @override
  String boSetPasswordLinkBody(String username, String server) {
    return 'Wybierz hasło dla $username na $server.';
  }

  @override
  String boSetPasswordLinkBodyNoName(String server) {
    return 'Wybierz hasło do swojego konta na $server.';
  }

  @override
  String get boSetPasswordStartingBody =>
      'To konto nadal ma hasło, z którym zostało utworzone. Wybierz nowe, aby dokończyć logowanie.';

  @override
  String get boSetPasswordTrust =>
      'Kontynuuj tylko, jeśli ufasz osobie, która wysłała ten link.';

  @override
  String get boPasswordLinkExpired =>
      'Ten link wygasł lub został już użyty. Poproś administratora serwera o nowy.';

  @override
  String boPasswordSetSignInFailed(String error) {
    return 'Hasło zostało ustawione, ale logowanie się nie powiodło: $error';
  }

  @override
  String get boChangePasswordSubtitle => 'Zaktualizuj hasło BookOrbit';

  @override
  String get boPasswordChangeEffect =>
      'Zmiana hasła wylogowuje Twoje pozostałe sesje BookOrbit. To urządzenie pozostanie zalogowane.';

  @override
  String get boPasswordChanged =>
      'Hasło zmienione. Pozostałe zalogowane urządzenia zostały wylogowane.';

  @override
  String boPasswordShareDescription(String username) {
    return 'Wyślij ten link lub poproś $username o zeskanowanie kodu QR, aby wybrać hasło i zalogować się do Absorb. Działa przez 15 minut.';
  }

  @override
  String boPasswordShareWarning(String username) {
    return 'Każdy, kto ma ten link, może wybrać hasło dla $username, dopóki nie zostanie użyty lub nie wygaśnie.';
  }

  @override
  String get setupLinkCopyWebLink => 'Kopiuj link webowy';

  @override
  String get boUserLinkCopy => 'Kopiuj link';

  @override
  String get boUserLinkCopied => 'Skopiowano link';

  @override
  String get boUserLinkShare => 'Udostępnij';

  @override
  String get boUserNoLink =>
      'Użytkownik został dodany, ale serwer nie wysłał linku do hasła. Wyślij go ze strony użytkownika.';

  @override
  String get boPermGroupLibrary => 'Biblioteka i książki';

  @override
  String get boPermGroupRequests => 'Prośby o książki';

  @override
  String get boPermGroupDevices => 'Urządzenia';

  @override
  String get boPermGroupIntegrations => 'Integracje czytania';

  @override
  String get boPermGroupDock => 'Book Dock';

  @override
  String get boPermGroupEmail => 'E-mail i powiadomienia';

  @override
  String get boPermGroupAdmin => 'Administracja';

  @override
  String get boPermLibraryDownload => 'Pobieranie książek';

  @override
  String get boPermLibraryUpload => 'Przesyłanie książek';

  @override
  String get boPermLibraryEditMetadata => 'Edycja metadanych';

  @override
  String get boPermLibraryDeleteBooks => 'Usuwanie książek';

  @override
  String get boPermBookRequestAccess => 'Prośby o książki';

  @override
  String get boPermBookRequestAutoApprove =>
      'Prośby zatwierdzane automatycznie';

  @override
  String get boPermBookRequestSelfFulfill =>
      'Bezpośrednie pobieranie żądanych książek';

  @override
  String get boPermManageBookRequests => 'Zarządzanie prośbami o książki';

  @override
  String get boPermKoboSync => 'Synchronizacja Kobo';

  @override
  String get boPermKoreaderSync => 'Synchronizacja KOReader';

  @override
  String get boPermOpdsAccess => 'Dostęp OPDS';

  @override
  String get boPermHardcoverSync => 'Synchronizacja Hardcover';

  @override
  String get boPermReadwiseSync => 'Synchronizacja Readwise';

  @override
  String get boPermStorygraphSync => 'Synchronizacja StoryGraph';

  @override
  String get boPermBookDockAccess => 'Korzystanie z Book Dock';

  @override
  String get boPermManageBookDock => 'Zarządzanie Book Dock';

  @override
  String get boPermEmailSend => 'Wysyłanie książek e-mailem';

  @override
  String get boPermNotificationAccess => 'Powiadomienia';

  @override
  String get boPermManageEmail => 'Zarządzanie e-mailem';

  @override
  String get boPermManageLibraries => 'Zarządzanie bibliotekami';

  @override
  String get boPermManageMetadataConfig => 'Ustawienia metadanych';

  @override
  String get boPermManageIcons => 'Zarządzanie ikonami';

  @override
  String get boPermManageUsers => 'Zarządzanie użytkownikami';

  @override
  String get boPermViewUserActivity => 'Podgląd aktywności użytkowników';

  @override
  String get boPermViewAuditLog => 'Podgląd dziennika audytu';

  @override
  String get boPermManageAppSettings => 'Ustawienia aplikacji';

  @override
  String get boLibsNone => 'Brak bibliotek';

  @override
  String boLibBookCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count książki',
      many: '$count książek',
      few: '$count książki',
      one: '1 książka',
    );
    return '$_temp0';
  }

  @override
  String get boLibScanNow => 'Skanuj teraz';

  @override
  String get boLibScanStarted => 'Rozpoczęto skanowanie';

  @override
  String get boLibScanning => 'Skanowanie';

  @override
  String boLibLastScan(String date, int added, int updated, int missing) {
    return 'Skanowano $date: dodano $added, zaktualizowano $updated, brakuje $missing';
  }

  @override
  String get boLibScanFailed => 'Ostatnie skanowanie nie powiodło się';

  @override
  String get boLibNeverScanned => 'Jeszcze nie skanowano';

  @override
  String get boLibNew => 'Nowa biblioteka';

  @override
  String get boLibName => 'Nazwa';

  @override
  String get boLibNeedName => 'Nadaj bibliotece nazwę';

  @override
  String get boLibIcon => 'Ikona';

  @override
  String get boLibFolders => 'Foldery';

  @override
  String get boLibFoldersHint =>
      'Foldery na serwerze, w których znajdują się książki tej biblioteki.';

  @override
  String get boLibNeedFolder => 'Dodaj co najmniej jeden folder';

  @override
  String get boLibAddFolder => 'Dodaj folder';

  @override
  String boLibFolderFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pliku',
      many: '$count plików',
      few: '$count pliki',
      one: '1 plik',
    );
    return '$_temp0';
  }

  @override
  String boLibFolderInUse(String library) {
    return 'Już w $library';
  }

  @override
  String get boLibFolderUnreadable => 'Serwer nie może odczytać tego folderu';

  @override
  String get boLibFolderRescan =>
      'Zmiana folderów powoduje ponowne skanowanie biblioteki.';

  @override
  String get boLibOrganization => 'Książki są przechowywane jako';

  @override
  String get boLibPerFolder => 'Jedna książka na folder';

  @override
  String get boLibPerFile => 'Jedna książka na plik';

  @override
  String get boLibOrganizationFixed =>
      'Nie można tego zmienić po utworzeniu biblioteki.';

  @override
  String get boLibWatch => 'Obserwuj zmiany';

  @override
  String get boLibWatchSubtitle =>
      'Wykrywaj nowe i zmienione pliki, gdy się pojawią';

  @override
  String get boLibSchedule => 'Zaplanowane skanowanie';

  @override
  String get boLibScheduleOff => 'Wyłączone';

  @override
  String get boLibScheduleDaily => 'Codziennie';

  @override
  String get boLibScheduleWeekly => 'Co tydzień';

  @override
  String boLibScheduleCustom(String cron) {
    return 'Własne ($cron)';
  }

  @override
  String get boLibScheduleHint => 'Uruchamia się o 3:00 czasu serwera.';

  @override
  String get boLibCovers => 'Kształt okładki';

  @override
  String get boLibCoverBook => 'Książka (2:3)';

  @override
  String get boLibCoverSquare => 'Kwadrat (1:1)';

  @override
  String get boLibAccess => 'Kto może ją widzieć';

  @override
  String get boLibAccessHint =>
      'Administratorzy widzą każdą bibliotekę. Pozostali potrzebują tu dostępu.';

  @override
  String get boLibAccessNone => 'Na razie tylko administratorzy';

  @override
  String get boLibAccessAdd => 'Dodaj osobę';

  @override
  String get boLibAccessEveryoneHas => 'Wszyscy już mają dostęp';

  @override
  String get boLibLevelViewer => 'Przeglądający';

  @override
  String get boLibLevelEditor => 'Edytor';

  @override
  String get boLibLevelOwner => 'Właściciel';

  @override
  String get boLibAccessRemove => 'Usuń dostęp';

  @override
  String get boLibDelete => 'Usuń bibliotekę';

  @override
  String boLibDeleteTitle(String name) {
    return 'Usunąć $name?';
  }

  @override
  String get boLibDeleteBody =>
      'Biblioteka zostanie usunięta z BookOrbit wraz z postępem i zakreśleniami jej książek. Pliki na serwerze pozostaną tam, gdzie są.';

  @override
  String get boLibDeleted => 'Biblioteka usunięta';

  @override
  String get boFolderPickTitle => 'Wybierz folder';

  @override
  String get boFolderUseThis => 'Użyj tego folderu';

  @override
  String get boFolderEmpty => 'Brak folderów w środku';

  @override
  String get statsTotalTime => 'ŁĄCZNY CZAS';

  @override
  String get statsTotalReadingTime => 'ŁĄCZNY CZAS CZYTANIA';

  @override
  String statsDaysOfTime(String days) {
    return 'To $days dni';
  }

  @override
  String statsHoursOfTime(String hours) {
    return 'To $hours godz.';
  }

  @override
  String get statsMediaAll => 'Wszystko';

  @override
  String get statsMediaListening => 'Słuchanie';

  @override
  String get statsMediaReading => 'Czytanie';

  @override
  String statsZoneMismatch(String server, String phone) {
    return 'BookOrbit liczy Twoje dni w strefie $server, ale ten telefon ma ustawioną strefę $phone. Czas pod koniec dnia może trafić na niewłaściwy dzień.';
  }

  @override
  String statsZoneUse(String zone) {
    return 'Użyj $zone';
  }

  @override
  String statsZoneSaved(String zone) {
    return 'BookOrbit używa teraz $zone. Starsze dni mogą potrzebować kilku minut na aktualizację.';
  }

  @override
  String get statsZoneFailed =>
      'Nie udało się zmienić strefy czasowej w BookOrbit';

  @override
  String get statsTimeOfDay => 'Pora dnia';

  @override
  String statsBusiestAround(String time) {
    return 'Najaktywniej około $time';
  }

  @override
  String get statsFinishedByMonth => 'Ukończone książki według miesięcy';

  @override
  String statsFinishedLast12(int count) {
    return '$count w ciągu ostatnich 12 miesięcy';
  }

  @override
  String get statsWhereTitle => 'Gdzie słuchasz i czytasz';

  @override
  String get statsLast12Months => 'Ostatnie 12 miesięcy';

  @override
  String get statsHabits => 'Nawyki';

  @override
  String get statsTypicalSession => 'Typowa sesja';

  @override
  String get statsProgressPerSession => 'Postęp na sesję';

  @override
  String get statsTimeToFinish => 'Czas do ukończenia';

  @override
  String statsDayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dnia',
      many: '$count dni',
      few: '$count dni',
      one: '1 dzień',
    );
    return '$_temp0';
  }

  @override
  String get statsBooksStarted => 'Rozpoczęte książki';

  @override
  String get statsBooksInProgress => 'W trakcie';

  @override
  String get statsAverageProgress => 'Średni postęp';

  @override
  String get statsTopBooks => 'Najlepsze książki';

  @override
  String get statsYearRead => 'Przeczytane';

  @override
  String boNotificationsUnread(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nieprzeczytanych',
      many: '$count nieprzeczytanych',
      few: '$count nieprzeczytane',
      one: '1 nieprzeczytane',
      zero: 'Nic nowego',
    );
    return '$_temp0';
  }

  @override
  String get boNotificationsMarkAllRead => 'Oznacz wszystkie jako przeczytane';

  @override
  String get boNotificationsClearAll => 'Wyczyść wszystkie';

  @override
  String get boNotificationsClearTitle => 'Wyczyścić wszystkie powiadomienia?';

  @override
  String get boNotificationsClearBody =>
      'Spowoduje to usunięcie wszystkich powiadomień z Twojego konta BookOrbit.';

  @override
  String get boNotificationsEmpty => 'Brak powiadomień';

  @override
  String get boNotificationsLoadFailed => 'Nie udało się wczytać powiadomień';

  @override
  String get boNotificationsUpdateFailed =>
      'Nie udało się zaktualizować powiadomień w BookOrbit';

  @override
  String boNotificationsOccurrences(int count) {
    return 'Wystąpiło $count razy';
  }

  @override
  String get boNotificationsSettings => 'Ustawienia powiadomień';

  @override
  String get boNotificationsSettingsIntro =>
      'Wybierz, które powiadomienia BookOrbit ma dla Ciebie zachowywać.';

  @override
  String get boNotificationsProblemsHint =>
      'Tryb „Problemy” powiadamia tylko wtedy, gdy coś zawiedzie lub wymaga uwagi.';

  @override
  String get boNotificationLevelOff => 'Wyłączone';

  @override
  String get boNotificationLevelProblems => 'Problemy';

  @override
  String get boNotificationLevelAll => 'Wszystkie';

  @override
  String get boNotificationsSaved => 'Zapisano ustawienia powiadomień';

  @override
  String get boNotificationsSaveFailed =>
      'Nie udało się zapisać ustawień powiadomień';

  @override
  String get boNotificationGroupLibrary => 'Biblioteka';

  @override
  String get boNotificationGroupFiles => 'Pliki';

  @override
  String get boNotificationGroupIntegrations => 'Integracje';

  @override
  String get boNotificationGroupPersonal => 'Osobiste';

  @override
  String get boNotifyScanning => 'Skanowanie biblioteki';

  @override
  String get boNotifyScanningDesc =>
      'Gdy skanowanie biblioteki się zakończy, zawiedzie lub znajdzie brakujące książki.';

  @override
  String get boNotifyMetadata => 'Pobieranie metadanych';

  @override
  String get boNotifyMetadataDesc =>
      'Gdy wyszukiwanie metadanych dla Twoich książek się zakończy lub zawiedzie.';

  @override
  String get boNotifyAuthorEnrichment => 'Szczegóły autora';

  @override
  String get boNotifyAuthorEnrichmentDesc =>
      'Gdy biografie i zdjęcia autorów zostaną pobrane.';

  @override
  String get boNotifyFileWriteBack => 'Zapisywanie do plików';

  @override
  String get boNotifyFileWriteBackDesc =>
      'Gdy edytowane dane są zapisywane w plikach książek na dysku.';

  @override
  String get boNotifyFileRename => 'Zmiana nazw plików';

  @override
  String get boNotifyFileRenameDesc =>
      'Gdy plik książki zostaje przemianowany zgodnie z Twoim wzorcem nazw.';

  @override
  String get boNotifyBulkRename => 'Zbiorcza zmiana nazw';

  @override
  String get boNotifyBulkRenameDesc =>
      'Gdy zmiana nazw wielu książek lub przenoszenie książek między bibliotekami się zakończy lub zawiedzie.';

  @override
  String get boNotifyMigration => 'Importy';

  @override
  String get boNotifyMigrationDesc =>
      'Gdy import z innej aplikacji bibliotecznej się zakończy lub zawiedzie.';

  @override
  String get boNotifyBookDock => 'Book Dock';

  @override
  String get boNotifyBookDockDesc =>
      'Gdy Book Dock zakończy dodawanie książek lub napotka problemy.';

  @override
  String get boNotifyBookRequests => 'Prośby o książki';

  @override
  String get boNotifyBookRequestsDesc =>
      'Gdy prośba o książkę zostanie złożona lub rozpatrzona albo książka stanie się dostępna.';

  @override
  String get boNotifyEmail => 'Dostarczanie e-maili';

  @override
  String get boNotifyEmailDesc =>
      'Gdy wysłanie książki e-mailem się powiedzie lub zawiedzie.';

  @override
  String get boNotifyAchievements => 'Osiągnięcia';

  @override
  String get boNotifyAchievementsDesc => 'Gdy odblokujesz nowe osiągnięcie.';

  @override
  String get achievementsTitle => 'Osiągnięcia';

  @override
  String achievementsEarnedSummary(int earned, int total) {
    return 'Zdobyto $earned z $total';
  }

  @override
  String get achievementsFilterAll => 'Wszystkie';

  @override
  String get achievementsFilterEarned => 'Zdobyte';

  @override
  String get achievementsFilterInProgress => 'W trakcie';

  @override
  String get achievementsFilterLocked => 'Zablokowane';

  @override
  String get achievementsCategoryReading => 'Czytanie';

  @override
  String get achievementsCategoryLibrary => 'Biblioteka';

  @override
  String get achievementsCategoryExploration => 'Odkrywanie';

  @override
  String get achievementsCategoryDedication => 'Zaangażowanie';

  @override
  String get achievementsCategoryDevices => 'Urządzenia';

  @override
  String get achievementsRarityCommon => 'Zwykłe';

  @override
  String get achievementsRarityRare => 'Rzadkie';

  @override
  String get achievementsRarityEpic => 'Epickie';

  @override
  String get achievementsRarityLegendary => 'Legendarne';

  @override
  String get achievementsLoadFailed => 'Nie udało się wczytać osiągnięć';

  @override
  String get achievementsNoneMatch =>
      'Żadne osiągnięcia nie pasują do tego filtra';

  @override
  String get achievementsSecretName => 'Tajne osiągnięcie';

  @override
  String get achievementsSecretHint => 'Czytaj dalej, aby je odkryć.';

  @override
  String achievementsEarnedOn(String date) {
    return 'Zdobyto $date';
  }

  @override
  String achievementsWhileReading(String title) {
    return 'Podczas czytania: $title';
  }

  @override
  String achievementsTierOf(int earned, int total) {
    return 'Poziom $earned z $total';
  }

  @override
  String get achievementsTiers => 'Poziomy';

  @override
  String get achievementsAllTiers => 'Zdobyto każdy poziom';

  @override
  String achievementsProgress(String current, String threshold) {
    return '$current / $threshold';
  }

  @override
  String achievementsProgressBooks(String current, String threshold) {
    return '$current / $threshold książek';
  }

  @override
  String achievementsProgressPages(String current, String threshold) {
    return '$current / $threshold stron';
  }

  @override
  String achievementsProgressHours(String current, String threshold) {
    return '$current / $threshold godzin';
  }

  @override
  String achievementsProgressAnnotations(String current, String threshold) {
    return '$current / $threshold zakreśleń i notatek';
  }

  @override
  String achievementsProgressRatings(String current, String threshold) {
    return '$current / $threshold ocen';
  }

  @override
  String achievementsProgressGenres(String current, String threshold) {
    return '$current / $threshold gatunków';
  }

  @override
  String achievementsProgressLanguages(String current, String threshold) {
    return '$current / $threshold języków';
  }

  @override
  String achievementsProgressDays(String current, String threshold) {
    return '$current / $threshold dni';
  }

  @override
  String get achievementsHowToGetIt => 'Jak to zdobyć';

  @override
  String achievementsHintReadingPace(int count, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'W ciągu ostatnich $days dni czytasz $count godziny.',
      many: 'W ciągu ostatnich $days dni czytasz $count godzin.',
      few: 'W ciągu ostatnich $days dni czytasz $count godziny.',
      one: 'W ciągu ostatnich $days dni czytasz 1 godzinę.',
    );
    return '$_temp0';
  }

  @override
  String achievementsHintEtaDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Około $count dnia w tym tempie.',
      many: 'Około $count dni w tym tempie.',
      few: 'Około $count dni w tym tempie.',
      one: 'Około 1 dnia w tym tempie.',
    );
    return '$_temp0';
  }

  @override
  String achievementsHintEtaWeeks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Około $count tygodnia w tym tempie.',
      many: 'Około $count tygodni w tym tempie.',
      few: 'Około $count tygodni w tym tempie.',
      one: 'Około 1 tygodnia w tym tempie.',
    );
    return '$_temp0';
  }

  @override
  String achievementsHintEtaMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Około $count miesiąca w tym tempie.',
      many: 'Około $count miesięcy w tym tempie.',
      few: 'Około $count miesięcy w tym tempie.',
      one: 'Około 1 miesiąca w tym tempie.',
    );
    return '$_temp0';
  }

  @override
  String achievementsHintDecadeUnread(int count, String decade) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count książki z lat $decade czeka na Twoich półkach.',
      many: '$count książek z lat $decade czeka na Twoich półkach.',
      few: '$count książki z lat $decade czekają na Twoich półkach.',
      one: '1 książka z lat $decade czeka na Twoich półkach.',
    );
    return '$_temp0';
  }

  @override
  String achievementsHintCenturyUnread(int count, String century) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count książki z wieku $century czeka na Twoich półkach.',
      many: '$count książek z wieku $century czeka na Twoich półkach.',
      few: '$count książki z wieku $century czekają na Twoich półkach.',
      one: '1 książka z wieku $century czeka na Twoich półkach.',
    );
    return '$_temp0';
  }

  @override
  String achievementsHintStalled(String title, String percent, String date) {
    return '$title jest przeczytana w $percent i została rozpoczęta $date.';
  }

  @override
  String achievementsHintStalledNoProgress(String title, String date) {
    return '$title została rozpoczęta $date.';
  }

  @override
  String get achievementsHintUntitledBook => 'Książka w trakcie czytania';

  @override
  String achievementsHintNearlyFinished(int count, String percent) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count książki w trakcie jest po $percent.',
      many: '$count książek w trakcie jest po $percent.',
      few: '$count książki w trakcie są po $percent.',
      one: '1 książka w trakcie jest po $percent.',
    );
    return '$_temp0';
  }

  @override
  String achievementsHintUnrated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ukończonej książki nie ma jeszcze oceny.',
      many: '$count ukończonych książek nie ma jeszcze oceny.',
      few: '$count ukończone książki nie mają jeszcze oceny.',
      one: '1 ukończona książka nie ma jeszcze oceny.',
    );
    return '$_temp0';
  }

  @override
  String achievementsHintShortBooks(int count, String pages) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count książki poniżej $pages stron czeka na Twoich półkach.',
      many: '$count książek poniżej $pages stron czeka na Twoich półkach.',
      few: '$count książki poniżej $pages stron czekają na Twoich półkach.',
      one: '1 książka poniżej $pages stron czeka na Twoich półkach.',
    );
    return '$_temp0';
  }

  @override
  String achievementsHintAlreadyStarted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jest już w trakcie.',
      many: '$count jest już w trakcie.',
      few: '$count są już w trakcie.',
      one: '1 jest już w trakcie.',
    );
    return '$_temp0';
  }

  @override
  String achievementsHintLongBooks(int count, String pages) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count książki mającej $pages stron lub więcej czeka na Twoich półkach.',
      many:
          '$count książek mających $pages stron lub więcej czeka na Twoich półkach.',
      few:
          '$count książki mające $pages stron lub więcej czekają na Twoich półkach.',
      one: '1 książka mająca $pages stron lub więcej czeka na Twoich półkach.',
    );
    return '$_temp0';
  }

  @override
  String achievementsHintOldBooks(int count, String year) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count książki wydanej przed $year czeka na Twoich półkach.',
      many: '$count książek wydanych przed $year czeka na Twoich półkach.',
      few: '$count książki wydane przed $year czekają na Twoich półkach.',
      one: '1 książka wydana przed $year czeka na Twoich półkach.',
    );
    return '$_temp0';
  }

  @override
  String achievementsHintAuthorUnread(String author, int finished, int count) {
    return '$author: ukończono $finished, jeszcze $count na Twoich półkach.';
  }

  @override
  String achievementsHintLanguageUnread(int count, String language) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count książki w języku $language czeka na Twoich półkach.',
      many: '$count książek w języku $language czeka na Twoich półkach.',
      few: '$count książki w języku $language czekają na Twoich półkach.',
      one: '1 książka w języku $language czeka na Twoich półkach.',
    );
    return '$_temp0';
  }

  @override
  String achievementsHintMonthsRead(int count, String year) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'W $year czytasz dotąd w $count miesiąca.',
      many: 'W $year czytasz dotąd w $count miesiącach.',
      few: 'W $year czytasz dotąd w $count miesiącach.',
      one: 'W $year czytasz dotąd w 1 miesiącu.',
    );
    return '$_temp0';
  }

  @override
  String achievementsHintMonthsLeft(int count, String months) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Pozostało: $months.',
      many: 'Pozostało: $months.',
      few: 'Pozostały: $months.',
      one: 'Pozostał $months.',
    );
    return '$_temp0';
  }

  @override
  String achievementsHintNoLongBook(String pages) {
    return 'Żadna książka na Twoich półkach nie ma jeszcze $pages stron lub więcej.';
  }

  @override
  String achievementsHintNothingBefore(String year) {
    return 'Nic na Twoich półkach nie zostało wydane przed $year.';
  }

  @override
  String achievementsHintTooFewDecades(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Twoje półki obejmują dotąd tylko $count dekady.',
      many: 'Twoje półki obejmują dotąd tylko $count dekad.',
      few: 'Twoje półki obejmują dotąd tylko $count dekady.',
      one: 'Twoje półki obejmują dotąd tylko 1 dekadę.',
    );
    return '$_temp0';
  }

  @override
  String achievementsHintTooFewCenturies(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Twoje półki obejmują dotąd tylko $count wieku.',
      many: 'Twoje półki obejmują dotąd tylko $count wieków.',
      few: 'Twoje półki obejmują dotąd tylko $count wieki.',
      one: 'Twoje półki obejmują dotąd tylko 1 wiek.',
    );
    return '$_temp0';
  }

  @override
  String achievementsHintMissedMonth(String month, String year) {
    return 'Nie czytasz w $month, więc $year jest poza zasięgiem. Liczenie zaczyna się od nowa w styczniu.';
  }

  @override
  String get achievementsSwitch => 'Osiągnięcia';

  @override
  String get achievementsSwitchSubtitle =>
      'Śledź osiągnięcia w BookOrbit. Wyłączenie ukrywa je tutaj i w wersji webowej.';

  @override
  String get achievementsTurnedOn => 'Osiągnięcia włączone';

  @override
  String get achievementsTurnedOff => 'Osiągnięcia wyłączone';

  @override
  String get achievementsSwitchFailed =>
      'Nie udało się zmienić osiągnięć w BookOrbit';

  @override
  String get boLibraryVisibilityTitle => 'Library visibility';

  @override
  String get boLibraryVisibilityIntro =>
      'Hide a library from any of these places. It stays in the library list, search and its own page. This is saved on your account, so the web app follows it too.';

  @override
  String get boLibraryVisibilityShelves => 'Shelves';

  @override
  String get boLibraryVisibilityShelvesDesc =>
      'Continue Reading, Continue Listening, Up Next in Series and Discover Something New.';

  @override
  String get boLibraryVisibilitySeries => 'Series';

  @override
  String get boLibraryVisibilitySeriesDesc =>
      'The Series page. A series split across libraries keeps the books from libraries still shown.';

  @override
  String get boLibraryVisibilityStats => 'Stats';

  @override
  String get boLibraryVisibilityStatsDesc =>
      'Stats, reading history and Year in Review. Reading is still recorded, so showing the library again brings its numbers back.';

  @override
  String get boLibraryVisibilitySaveFailed =>
      'Couldn\'t save library visibility';

  @override
  String get readAlongPaused => 'Paused';

  @override
  String get readAlongPausedHint =>
      'It keeps its place and starts again once resumed.';

  @override
  String get readAlongPause => 'Pause';

  @override
  String get readAlongResume => 'Resume';

  @override
  String boQuickMatchStillRunning(int count) {
    return 'Still matching on the server ($count)';
  }

  @override
  String get boQuickMatchBusy =>
      'The server already has too many matches waiting. Try again once some finish.';

  @override
  String get boNotifyStoryGuides => 'Story guides';

  @override
  String get boNotifyStoryGuidesDesc =>
      'When a story guide you started building is ready or fails.';

  @override
  String get boNotifyBulkActions => 'Bulk actions';

  @override
  String get boNotifyBulkActionsDesc =>
      'When a bulk action you started finishes after you left it, stops, or is cut short by a restart.';

  @override
  String get boNotifyReadAlong => 'Czytanie razem';

  @override
  String get boNotifyReadAlongDesc =>
      'Gdy rozpoczęte przez Ciebie czytanie razem jest gotowe, wymaga przejrzenia lub zawiedzie.';

  @override
  String get readAlongCreate => 'Utwórz czytanie razem';

  @override
  String get readAlongLoadFailed =>
      'Nie udało się sprawdzić, czy dla tej książki można utworzyć czytanie razem.';

  @override
  String get readAlongCheckAgain => 'Sprawdź ponownie';

  @override
  String get readAlongWhyWorkerOffline =>
      'Proces roboczy czytania razem BookOrbit jest teraz offline.';

  @override
  String get readAlongWhyWorkerOutdated =>
      'Proces roboczy czytania razem BookOrbit wymaga aktualizacji, aby działać z tym serwerem.';

  @override
  String get readAlongWhyFilesMissing =>
      'Przywróć brakujące pliki tej książki, aby utworzyć czytanie razem.';

  @override
  String get readAlongWhyNoEpub =>
      'Dodaj do tej książki zwykły EPUB, aby utworzyć czytanie razem.';

  @override
  String get readAlongWhyNoEpubHasOne =>
      'Ta książka ma już czytanie razem i nie ma zwykłego EPUB, z którego można utworzyć kolejne.';

  @override
  String get readAlongWhyTooManyTracks =>
      'Ten audiobook ma więcej plików, niż pozwala utworzyć czytanie razem.';

  @override
  String get readAlongWhyEpubNotAllowed =>
      'Ta biblioteka nie przyjmuje plików EPUB, więc nie można dodać czytania razem.';

  @override
  String get readAlongWhyNotMounted =>
      'Proces roboczy czytania razem BookOrbit nie ma dostępu do folderu tej biblioteki.';

  @override
  String get readAlongWhyRunning =>
      'Czytanie razem dla tej książki jest już tworzone.';

  @override
  String get readAlongWhyUnknown =>
      'Nie można teraz utworzyć czytania razem dla tej książki.';

  @override
  String get readAlongSheetTitle => 'Utwórz czytanie razem';

  @override
  String get readAlongSheetIntro =>
      'BookOrbit dopasowuje narrację do tekstu ebooka i dodaje EPUB, który podświetla tekst zgodnie z audio.';

  @override
  String get readAlongEbook => 'Ebook';

  @override
  String get readAlongEbookHint => 'Wybierz zwykły EPUB pasujący do narracji.';

  @override
  String get readAlongAudio => 'Audiobook';

  @override
  String readAlongTracks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ścieżki',
      many: '$count ścieżek',
      few: '$count ścieżki',
      one: '1 ścieżka',
    );
    return '$_temp0';
  }

  @override
  String readAlongExistingTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ta książka ma już $count czytania razem',
      many: 'Ta książka ma już $count czytań razem',
      few: 'Ta książka ma już $count czytania razem',
      one: 'Ta książka ma już czytanie razem',
    );
    return '$_temp0';
  }

  @override
  String readAlongReplace(String name) {
    return 'Zastąp $name';
  }

  @override
  String readAlongKeepBoth(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Zachowaj wszystkie',
      many: 'Zachowaj wszystkie',
      few: 'Zachowaj wszystkie',
      one: 'Zachowaj oba',
    );
    return '$_temp0';
  }

  @override
  String get readAlongKeepHint =>
      'Nowe czytanie razem zostanie dodane jako kolejny plik.';

  @override
  String get readAlongReplaceHint =>
      'Stary plik zostanie zastąpiony dopiero po pomyślnym przejściu kontroli przez nowy, a miejsca czytania zostaną zachowane.';

  @override
  String get readAlongReplaceNotAllowed =>
      'Zastąpienie czytania razem wymaga uprawnienia do usuwania książek, więc nowe zostanie dodane jako kolejny plik.';

  @override
  String get readAlongMadeByBookOrbit => 'Utworzone przez BookOrbit';

  @override
  String get readAlongImported => 'Zaimportowane';

  @override
  String get readAlongLanguage => 'Język narracji';

  @override
  String get readAlongPickLanguage => 'Wybierz język';

  @override
  String readAlongLanguageUnsupported(String language) {
    return 'Model mowy nie zna języka tej książki ($language).';
  }

  @override
  String get readAlongLanguageFromBook => 'Ze szczegółów tej książki.';

  @override
  String get readAlongLanguageIsDefault => 'Twój język domyślny.';

  @override
  String get readAlongLanguageSaved => 'Zapisano jako Twój język domyślny.';

  @override
  String get readAlongSetDefault => 'Ustaw jako domyślny';

  @override
  String get readAlongDefaultFailed =>
      'Nie udało się zapisać Twojego języka domyślnego.';

  @override
  String get readAlongHighlighting => 'Podświetlanie';

  @override
  String get readAlongSentence => 'Zdanie';

  @override
  String get readAlongSentenceHint =>
      'Podświetla jedno zdanie naraz. Zalecane.';

  @override
  String get readAlongWord => 'Słowo';

  @override
  String get readAlongWordHint =>
      'Podświetla każde słowo. Trwa dłużej i tworzy większy plik. Wciąż eksperymentalne.';

  @override
  String readAlongEstimatedSize(String size) {
    return 'Szacowany rozmiar: $size';
  }

  @override
  String get readAlongBackgroundNote =>
      'Działa na serwerze, więc możesz to zamknąć. Długie audiobooki mogą zająć godziny, a pierwsze uruchomienie dla danego języka pobiera jego model mowy.';

  @override
  String readAlongLowDisk(String needed, String free) {
    return 'Mało miejsca na dysku: potrzeba około $needed miejsca roboczego na procesie roboczym, który ma $free wolnego.';
  }

  @override
  String get readAlongStart => 'Rozpocznij';

  @override
  String get readAlongStartFailed =>
      'Nie udało się rozpocząć czytania razem. Spróbuj ponownie.';

  @override
  String get readAlongStartInvalid =>
      'Niektórych wybranych plików nie ma już w tej książce. Sprawdź je i spróbuj ponownie.';

  @override
  String get readAlongStartOffline =>
      'Proces roboczy czytania razem BookOrbit jest offline. Spróbuj ponownie później.';

  @override
  String get readAlongNotAllowed => 'Nie masz uprawnień do tej czynności.';

  @override
  String get readAlongGone => 'To zadanie czytania razem już nie istnieje.';

  @override
  String get readAlongMovedOn =>
      'To zadanie jest już dalej. Teraz pokazuje, na jakim jest etapie.';

  @override
  String get readAlongActionFailed => 'Nie udało się. Spróbuj ponownie.';

  @override
  String readAlongStartedBy(String name) {
    return 'Rozpoczął(a): $name';
  }

  @override
  String get readAlongStartedByOther => 'Rozpoczęte przez innego użytkownika';

  @override
  String get readAlongWaiting => 'Oczekiwanie na start';

  @override
  String get readAlongNextInLine => 'Następne w kolejce';

  @override
  String readAlongJobsAhead(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count zadania przed',
      many: '$count zadań przed',
      few: '$count zadania przed',
      one: '1 zadanie przed',
    );
    return '$_temp0';
  }

  @override
  String get readAlongStopping => 'Zatrzymywanie';

  @override
  String get readAlongStoppingHint =>
      'Kończenie bieżącego kroku, po czym się zatrzyma. Nic nie zostanie dodane do tej książki.';

  @override
  String get readAlongStagePreparingAudio => 'Przygotowywanie audio';

  @override
  String get readAlongStageDownloadingModel => 'Pobieranie modelu mowy';

  @override
  String get readAlongStageListening => 'Słuchanie narracji';

  @override
  String get readAlongStageMarkingUp => 'Znakowanie tekstu ebooka';

  @override
  String get readAlongStageAligning => 'Dopasowywanie tekstu do narracji';

  @override
  String get readAlongStageChecking => 'Sprawdzanie wyniku';

  @override
  String get readAlongStagePublishing =>
      'Dodawanie czytania razem do tej książki';

  @override
  String get readAlongStageWorking => 'Praca';

  @override
  String readAlongFileOf(int current, int total) {
    return 'Plik $current z $total';
  }

  @override
  String readAlongTrackOf(int current, int total) {
    return 'Ścieżka $current z $total';
  }

  @override
  String readAlongChapterOf(int current, int total) {
    return 'Rozdział $current z $total';
  }

  @override
  String readAlongStepOf(int current, int total) {
    return 'Krok $current z $total';
  }

  @override
  String get readAlongFirstRun => 'Pierwsze uruchomienie dla tego języka';

  @override
  String get readAlongJustStarted => 'Dopiero rozpoczęto';

  @override
  String readAlongRunningFor(String duration) {
    return 'Trwa od $duration';
  }

  @override
  String get readAlongStepAudio => 'Audio';

  @override
  String get readAlongStepSpeech => 'Mowa';

  @override
  String get readAlongStepText => 'Tekst';

  @override
  String get readAlongStepAlign => 'Dopasowanie';

  @override
  String get readAlongStepCheck => 'Kontrola';

  @override
  String get readAlongStepAdd => 'Dodanie';

  @override
  String get readAlongReviewTitle => 'Gotowe do przejrzenia';

  @override
  String readAlongReviewMatched(String percent) {
    return '$percent tekstu pasuje do narracji. Sprawdź je przed dodaniem do książki.';
  }

  @override
  String get readAlongReviewPlain => 'Sprawdź je przed dodaniem do książki.';

  @override
  String get readAlongReviewWeb =>
      'Aby pominąć rozdziały i dopasować ponownie, otwórz tę książkę w BookOrbit w przeglądarce.';

  @override
  String readAlongReviewExpires(String date) {
    return 'Zostanie automatycznie odrzucone $date, jeśli go nie przejrzysz.';
  }

  @override
  String get readAlongAddAnyway => 'Dodaj mimo to';

  @override
  String get readAlongDiscard => 'Odrzuć';

  @override
  String get readAlongDiscardPrompt => 'Odrzucić to czytanie razem?';

  @override
  String get readAlongKeepIt => 'Zachowaj';

  @override
  String get readAlongReady => 'Czytanie razem gotowe';

  @override
  String get readAlongReadyWarnings => 'Czytanie razem gotowe, z ostrzeżeniami';

  @override
  String get readAlongAdded => 'Dodano do tej książki jako nowy EPUB.';

  @override
  String get readAlongReplaced =>
      'Zastąpiono stare czytanie razem. Miejsca czytania zostały zachowane.';

  @override
  String readAlongMatchedSentences(String matched, String total) {
    return '$matched z $total zdań pasuje do narracji';
  }

  @override
  String readAlongAudioUsed(String percent) {
    return 'Wykorzystano $percent audio';
  }

  @override
  String readAlongOutside(String chapters) {
    return 'Poza narracją, więc bez audio: $chapters.';
  }

  @override
  String readAlongOutsideMore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'jeszcze $count rozdziału',
      many: 'jeszcze $count rozdziałów',
      few: 'jeszcze $count rozdziały',
      one: 'jeszcze 1 rozdział',
    );
    return '$_temp0';
  }

  @override
  String get readAlongWarnUnaligned =>
      'Nie udało się dopasować jednej lub więcej ścieżek audio.';

  @override
  String get readAlongWarnUnmatched =>
      'Zauważalna część tekstu ebooka nie została dopasowana do narracji.';

  @override
  String get readAlongWarnInterpolated =>
      'Czas części tekstu oszacowano między pewnymi dopasowaniami.';

  @override
  String get readAlongWarnDropped =>
      'Część tekstu ebooka pominięto w podświetlaniu.';

  @override
  String get readAlongFailed => 'Czytanie razem nie powiodło się';

  @override
  String get readAlongCancelled => 'Czytanie razem anulowano';

  @override
  String get readAlongDiscarded => 'Czytanie razem odrzucono';

  @override
  String get readAlongNothingAdded => 'Nic nie dodano do tej książki.';

  @override
  String get readAlongExpired =>
      'Nie przejrzano go w ciągu 14 dni, więc nic nie dodano do tej książki.';

  @override
  String readAlongRetryUntil(String date) {
    return 'Ponowienie wznawia od ostatniego ukończonego kroku do $date.';
  }

  @override
  String get readAlongStartOver => 'Zacznij od nowa';

  @override
  String get readAlongCancel => 'Anuluj czytanie razem';

  @override
  String get readAlongCancelPrompt => 'Anulować to czytanie razem?';

  @override
  String get readAlongKeepRunning => 'Kontynuuj';

  @override
  String get readAlongErrorWorkerOffline =>
      'BookOrbit nie mógł połączyć się ze swoim procesem roboczym czytania razem.';

  @override
  String get readAlongErrorWorkerCrashed =>
      'Proces roboczy czytania razem nieoczekiwanie się zatrzymał.';

  @override
  String get readAlongErrorSourceMissing => 'Wybranego pliku już nie ma.';

  @override
  String get readAlongErrorSourceChanged =>
      'Wybrany plik zmienił się po rozpoczęciu zadania.';

  @override
  String get readAlongErrorInvalidSource =>
      'Nie udało się odczytać EPUB lub audiobooka.';

  @override
  String get readAlongErrorLanguage => 'Model mowy nie zna wybranego języka.';

  @override
  String get readAlongErrorStorage =>
      'Na procesie roboczym brakuje wolnego miejsca na dysku, aby zakończyć.';

  @override
  String get readAlongErrorAudio => 'Nie udało się przygotować audiobooka.';

  @override
  String get readAlongErrorModel => 'Nie udało się pobrać modelu mowy.';

  @override
  String get readAlongErrorListening =>
      'Rozpoznawanie mowy nie powiodło się podczas słuchania narracji.';

  @override
  String get readAlongErrorMarkup =>
      'Nie udało się przygotować tekstu ebooka do dopasowania.';

  @override
  String get readAlongErrorAlignment =>
      'Nie udało się dopasować tekstu do narracji.';

  @override
  String get readAlongErrorOutput => 'Nowy EPUB nie przeszedł kontroli.';

  @override
  String get readAlongErrorPublish =>
      'Nie udało się dodać nowego EPUB do tej książki.';

  @override
  String get readAlongErrorDiscarded => 'Odrzucono go podczas przeglądu.';

  @override
  String get readAlongErrorCancelled => 'Anulowano go.';

  @override
  String get readAlongErrorUnknown =>
      'Coś poszło nie tak podczas tworzenia czytania razem.';

  @override
  String get fileInfoNoAudiobook => 'Brak audiobooka';

  @override
  String get fileInfoNoEbook => 'Brak ebooka';

  @override
  String get fileInfoRequestedBySomeone => 'Poproszona przez kogoś innego';

  @override
  String get fileInfoOwnedSeparately =>
      'W Twojej bibliotece jako osobna książka';

  @override
  String get fileInfoCopyPath => 'Kopiuj ścieżkę';

  @override
  String get fileInfoDeleteTitle => 'Usunąć plik?';

  @override
  String fileInfoDeletePrompt(String name) {
    return '„$name” zostanie usunięty z serwera. Tej operacji nie można cofnąć.';
  }

  @override
  String get fileInfoDeleteLast =>
      'To ostatni plik audio lub ebook tej książki, więc książka będzie widoczna jako brakująca.';

  @override
  String get fileInfoDeleteNotAllowed =>
      'Nie masz uprawnień do usuwania plików';

  @override
  String get chapterSourceEmbedded => 'Odczytane z plików audio';

  @override
  String get chapterSourceTracks => 'Jeden rozdział na plik audio, niezapisane';

  @override
  String get chapterSourceProvider => 'Z pobranych metadanych';

  @override
  String get chapterSourceMigration => 'Zaimportowane z Audiobookshelf';

  @override
  String get chapterSourceManual => 'Edytowane w BookOrbit';

  @override
  String chapterSourceManualBy(String name) {
    return 'Edytował(a): $name';
  }

  @override
  String get chapterSourceNone => 'Brak rozdziałów';

  @override
  String get chapterProtected => 'Chronione przed ponownym skanowaniem';

  @override
  String get chapterNotProtected => 'Ponowne skanowanie może je zastąpić';

  @override
  String get chapterProtectOnSave => 'Chroń przed ponownym skanowaniem';

  @override
  String get chapterGetFrom => 'Pobierz rozdziały z';

  @override
  String get chapterFromFiles => 'Plików audio';

  @override
  String get chapterFromEbookToc => 'Spisu treści ebooka';

  @override
  String get chapterFromReadAlong => 'Czytania razem';

  @override
  String get chapterFromHistory => 'Wcześniejszych wersji';

  @override
  String get chapterHistoryTitle => 'Wcześniejsze wersje';

  @override
  String get chapterHistoryEmpty => 'Zapisane wersje pojawią się tutaj.';

  @override
  String chapterHistoryBy(String source, String name) {
    return '$source – $name';
  }

  @override
  String get chapterReadingFiles => 'Odczytywanie plików audio...';

  @override
  String get chapterRevertToFiles => 'Przywróć z plików';

  @override
  String get chapterRevertTitle => 'Wrócić do rozdziałów z plików?';

  @override
  String get chapterRevertMessage =>
      'BookOrbit ponownie odczyta rozdziały z plików audio i przestanie chronić je przed ponownym skanowaniem. Niezapisane zmiany zostaną utracone. Bieżąca lista pozostanie we wcześniejszych wersjach.';

  @override
  String get chapterReverted => 'Przywrócono rozdziały z plików audio';

  @override
  String get chapterWriteFiles => 'Zapisz do plików';

  @override
  String get chapterWriteTitle => 'Zapisać rozdziały w plikach audio?';

  @override
  String chapterWriteMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'To przepisze $count pliku audio książki z tymi rozdziałami.',
      many: 'To przepisze $count plików audio książki z tymi rozdziałami.',
      few: 'To przepisze $count pliki audio książki z tymi rozdziałami.',
      one: 'To przepisze plik audio książki z tymi rozdziałami.',
    );
    return '$_temp0 Samo audio jest kopiowane bez zmian. Telefony, które już pobrały książkę, zachowają swoją kopię do ponownego pobrania.';
  }

  @override
  String get chapterWriteConfirm => 'Zapisz';

  @override
  String get chapterWriting => 'Zapisywanie rozdziałów w plikach audio...';

  @override
  String chapterWritten(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Rozdziały zapisano we wszystkich $count pliku audio',
      many: 'Rozdziały zapisano we wszystkich $count plikach audio',
      few: 'Rozdziały zapisano we wszystkich $count plikach audio',
      one: 'Rozdziały zapisano w pliku audio',
    );
    return '$_temp0';
  }

  @override
  String chapterWrittenPartly(int written, int total) {
    return 'Rozdziały zapisano w $written z $total plików. Pozostałe pozostawiono bez zmian.';
  }

  @override
  String get chapterStaleTitle => 'Te rozdziały się zmieniły';

  @override
  String get chapterStaleMessage =>
      'Ktoś inny zapisał te rozdziały po ich otwarciu przez Ciebie. Wczytaj ponownie, aby zobaczyć jego wersję. Twoje zmiany pozostaną, dopóki tego nie zrobisz.';

  @override
  String get chapterReload => 'Wczytaj ponownie';

  @override
  String get chapterKeepEditing => 'Edytuj dalej';

  @override
  String get matchExplicitYes => 'Oznaczone jako dla dorosłych';

  @override
  String get matchExplicitNo => 'Nie dla dorosłych';

  @override
  String get matchAbridgedYes => 'Skrócona';

  @override
  String get matchAbridgedNo => 'Nieskrócona';

  @override
  String boQuickMatchBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'te $count książki',
      many: 'te $count książek',
      few: 'te $count książki',
      one: 'tę książkę',
    );
    return 'BookOrbit wyszukuje $_temp0 i uzupełnia znalezione dane zgodnie ze swoimi ustawieniami metadanych.';
  }

  @override
  String get boQuickMatchIgnoreCache => 'Zapytaj ponownie każde źródło';

  @override
  String get boQuickMatchIgnoreCacheHint =>
      'Pomija zapisane odpowiedzi. Wolniej i zużywa więcej limitu zapytań każdego źródła.';

  @override
  String boAdminServerCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count serwera poczty',
      many: '$count serwerów poczty',
      few: '$count serwery poczty',
      one: '1 serwer poczty',
      zero: 'Brak',
    );
    return '$_temp0';
  }

  @override
  String get boEmailTitle => 'Wyślij e-mailem';

  @override
  String get boEmailSubtitle =>
      'Urządzenia, serwery poczty i szablony do wysyłania książek';

  @override
  String get boEmailTabDevices => 'Urządzenia';

  @override
  String get boEmailTabServers => 'Serwery poczty';

  @override
  String get boEmailTabTemplates => 'Szablony';

  @override
  String get boEmailTabHistory => 'Historia';

  @override
  String get boEmailName => 'Nazwa';

  @override
  String boEmailDeleteTitle(String name) {
    return 'Usunąć $name?';
  }

  @override
  String get boEmailMakeDefault => 'Ustaw jako domyślne';

  @override
  String get boEmailBadgeDefault => 'Domyślne';

  @override
  String get boEmailBadgeShared => 'Udostępnione';

  @override
  String get boEmailBadgeSystem => 'Resetowanie haseł';

  @override
  String get boEmailBadgeBuiltIn => 'Wbudowane';

  @override
  String get boEmailDevicesEmpty =>
      'Brak urządzeń. Dodaj adres e-mail swojego czytnika, aby wysyłać mu książki.';

  @override
  String get boEmailAddDevice => 'Dodaj urządzenie';

  @override
  String get boEmailNewDevice => 'Nowe urządzenie';

  @override
  String get boEmailDeviceNameHint => 'Mój Kindle';

  @override
  String get boEmailDeviceAddress => 'Adres e-mail';

  @override
  String get boEmailDeviceType => 'Urządzenie';

  @override
  String get boEmailDeviceNone => 'Osoba lub skrzynka';

  @override
  String get boEmailDeviceKindle => 'Kindle';

  @override
  String get boEmailDeviceKobo => 'Kobo';

  @override
  String get boEmailDeviceOther => 'Inny czytnik';

  @override
  String get boEmailKindleHint =>
      'Kindle otrzymuje temat „convert” i przyjmuje e-mailem tylko EPUB i PDF.';

  @override
  String boEmailKindleApprove(String address) {
    return 'Kindle odrzuca pocztę z nieznanych adresów. W ustawieniach dokumentów osobistych Amazon dodaj $address do listy zatwierdzonych.';
  }

  @override
  String get boEmailKindleApproveNoServer =>
      'Najpierw dodaj serwer poczty, aby zobaczyć adres, który Kindle musi zatwierdzić.';

  @override
  String get boEmailFormat => 'Format';

  @override
  String get boEmailFormatPrimary => 'Główny plik książki';

  @override
  String get boEmailFormatHint =>
      'Książka bez tego formatu otrzyma swój główny plik.';

  @override
  String get boEmailReadAlong => 'Książki do czytania razem';

  @override
  String get boEmailReadAlongAuto => 'Automatycznie';

  @override
  String get boEmailReadAlongAutoHint =>
      'Sam tekst, gdy można utworzyć kopię, w przeciwnym razie oryginał.';

  @override
  String get boEmailReadAlongText => 'Tylko tekst';

  @override
  String get boEmailReadAlongTextHint =>
      'Bez narracji. Wystarczająco mały do wysłania e-mailem.';

  @override
  String get boEmailReadAlongOriginal => 'Z narracją';

  @override
  String get boEmailReadAlongOriginalHint =>
      'Zachowuje narrację. Często 100 MB lub więcej, powyżej limitów większości serwerów poczty.';

  @override
  String get boEmailTemplate => 'Szablon';

  @override
  String get boEmailTemplateYourDefault => 'Twój domyślny';

  @override
  String get boEmailTemplateKindleHint =>
      'Kindle nigdy nie wyświetla wiadomości, więc pomija szablon.';

  @override
  String get boEmailDefaultDevice => 'Urządzenie domyślne';

  @override
  String get boEmailDefaultDeviceHint =>
      'Wybierane jako pierwsze przy wysyłaniu książki.';

  @override
  String get boEmailSendTest => 'Wyślij testowy e-mail';

  @override
  String get boEmailTestSubject => 'Testowy e-mail z Absorb';

  @override
  String boEmailTestBody(String name) {
    return 'To test z Absorb. Jeśli możesz to przeczytać, książki wysłane do $name również tu dotrą.';
  }

  @override
  String boEmailTestSent(String name) {
    return 'Wysłano testowy e-mail do $name';
  }

  @override
  String boEmailTestFailed(String error) {
    return 'Testowy e-mail nie został wysłany: $error';
  }

  @override
  String get boEmailDeleteDevice => 'Usuń urządzenie';

  @override
  String get boEmailDeleteDeviceBody => 'Jego historia wysyłania pozostanie.';

  @override
  String get boEmailDeviceRequired => 'Wpisz nazwę i adres e-mail';

  @override
  String get boEmailLastSendFailed => 'Ostatnie wysłanie nie powiodło się';

  @override
  String get boEmailGroups => 'Grupy';

  @override
  String get boEmailGroupsHint => 'Wysyłaj do kilku urządzeń naraz.';

  @override
  String get boEmailNewGroup => 'Nowa grupa';

  @override
  String get boEmailGroupNameHint => 'Klub książki';

  @override
  String get boEmailGroupMembers => 'Urządzenia w tej grupie';

  @override
  String get boEmailGroupMembersEmpty => 'Najpierw dodaj urządzenie.';

  @override
  String boEmailGroupMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count urządzenia',
      many: '$count urządzeń',
      few: '$count urządzenia',
      one: '1 urządzenie',
      zero: 'Brak urządzeń',
    );
    return '$_temp0';
  }

  @override
  String get boEmailDeleteGroup => 'Usuń grupę';

  @override
  String get boEmailDeleteGroupBody => 'Urządzenia w niej pozostaną.';

  @override
  String get boEmailGroupRequired => 'Wpisz nazwę grupy';

  @override
  String get boEmailServersEmptyManage =>
      'Brak serwerów poczty. Dodaj jeden, aby zacząć wysyłać książki.';

  @override
  String get boEmailServersEmpty =>
      'Brak serwerów poczty. Poproś administratora o dodanie.';

  @override
  String get boEmailAddServer => 'Dodaj serwer poczty';

  @override
  String get boEmailNewServer => 'Nowy serwer poczty';

  @override
  String get boEmailServerPresetOther => 'Inny';

  @override
  String get boEmailServerPresetHint =>
      'Ustawienie wstępne uzupełnia host, port i zabezpieczenia. Nadal możesz je zmienić.';

  @override
  String get boEmailServerHost => 'Host';

  @override
  String get boEmailServerPort => 'Port';

  @override
  String get boEmailServerSecurity => 'Zabezpieczenia';

  @override
  String get boEmailServerSecurityNone => 'Brak';

  @override
  String get boEmailServerSecurityHint =>
      'STARTTLS na porcie 587, SSL/TLS na 465.';

  @override
  String get boEmailServerNeedsPassword => 'Loguje się hasłem';

  @override
  String get boEmailServerUsername => 'Nazwa użytkownika';

  @override
  String get boEmailServerPassword => 'Hasło';

  @override
  String get boEmailServerAppPassword => 'Hasło aplikacji';

  @override
  String get boEmailServerPasswordKeep => 'Zapisano. Wpisz, aby zastąpić';

  @override
  String get boEmailServerAppPasswordHint =>
      'Gmail i iCloud wymagają hasła aplikacji, a nie hasła do konta.';

  @override
  String get boEmailServerFromName => 'Nazwa nadawcy';

  @override
  String get boEmailServerFromAddress => 'Adres nadawcy';

  @override
  String get boEmailServerFromAddressHint =>
      'Właściciele Kindle muszą zatwierdzić ten adres.';

  @override
  String get boEmailServerShare => 'Udostępnij wszystkim';

  @override
  String get boEmailServerShareHint =>
      'Inne osoby mogą wysyłać książki przez ten serwer bez widoczności hasła.';

  @override
  String get boEmailServerSystem =>
      'Wysyłaj resetowanie haseł i linki logowania';

  @override
  String get boEmailServerSystemHint =>
      'Serwer, którego BookOrbit używa do własnej poczty.';

  @override
  String get boEmailServerVerifyTls => 'Sprawdzaj certyfikat serwera';

  @override
  String get boEmailServerVerifyTlsHint =>
      'Wyłącz tylko dla serwera we własnej sieci z certyfikatem z podpisem własnym.';

  @override
  String get boEmailServerTest => 'Testuj połączenie';

  @override
  String get boEmailServerTestSaveFirst => 'Najpierw zapisz, potem testuj';

  @override
  String get boEmailServerTestOk => 'Połączono';

  @override
  String boEmailServerTestFailed(String error) {
    return 'Nie można połączyć: $error';
  }

  @override
  String get boEmailServerDelete => 'Usuń serwer poczty';

  @override
  String get boEmailServerDeleteBody =>
      'Wszyscy, którym go udostępniono, go stracą.';

  @override
  String get boEmailServerSystemFirst =>
      'Przed usunięciem wyłącz resetowanie haseł na tym serwerze.';

  @override
  String get boEmailServerRequired => 'Wpisz nazwę i host';

  @override
  String get boEmailServerNotYours =>
      'Ten serwer dodał ktoś inny. Tylko ta osoba może go zmienić.';

  @override
  String get boEmailTemplatesEmpty => 'Brak szablonów.';

  @override
  String get boEmailNewTemplate => 'Nowy szablon';

  @override
  String get boEmailTemplateSubject => 'Temat';

  @override
  String get boEmailTemplateMessage => 'Wiadomość';

  @override
  String get boEmailTemplateInsert => 'Wstaw';

  @override
  String get boEmailTemplateInsertHint =>
      'Wstawiane w miejscu kursora. Szczegóły, których książka nie ma, nic nie wypiszą.';

  @override
  String get boEmailVarBook => 'Książka';

  @override
  String get boEmailVarFile => 'Plik';

  @override
  String get boEmailVarOther => 'Inne';

  @override
  String get boEmailTemplatePreview => 'Podgląd';

  @override
  String get boEmailTemplatePreviewNone =>
      'Wyślij raz książkę, aby zobaczyć podgląd szablonu z nią.';

  @override
  String boEmailTemplateAttached(String name) {
    return 'Załączono: $name';
  }

  @override
  String get boEmailTemplateBuiltIn =>
      'Wbudowany. Tylko administrator może go zmienić.';

  @override
  String get boEmailTemplateKindleNote =>
      'Kindle nigdy nie wyświetla szablonu. Zawsze otrzymuje temat „convert”.';

  @override
  String get boEmailTemplateDelete => 'Usuń szablon';

  @override
  String get boEmailTemplateDeleteBody =>
      'Urządzenia, które go używają, wrócą do Twojego szablonu domyślnego.';

  @override
  String get boEmailTemplateRequired => 'Wpisz nazwę i temat';

  @override
  String get boEmailHistoryEmpty => 'Nic jeszcze nie wysłano.';

  @override
  String get boEmailHistoryAll => 'Wszystko';

  @override
  String get boEmailHistoryEveryone => 'Wszyscy';

  @override
  String get boEmailStatusSent => 'Wysłano';

  @override
  String get boEmailStatusSending => 'Wysyłanie';

  @override
  String boEmailStatusRetrying(int attempt) {
    return 'Ponawianie ($attempt)';
  }

  @override
  String get boEmailStatusFailed => 'Niepowodzenie';

  @override
  String boEmailTo(String name) {
    return 'Do $name';
  }

  @override
  String get boEmailResend => 'Wyślij ponownie';

  @override
  String get boEmailResent => 'Wysyłanie ponowne';

  @override
  String get boEmailForget => 'Usuń z historii';

  @override
  String get boEmailLoadMore => 'Wczytaj więcej';

  @override
  String get boEmailUnknownBook => 'Usunięta książka';

  @override
  String get boEmailSendNoServer =>
      'Na tym serwerze nie skonfigurowano jeszcze serwera poczty.';

  @override
  String get boEmailSendAskAdmin => 'Poproś administratora o dodanie.';

  @override
  String get boEmailSendNoDevices =>
      'Dodaj urządzenie, do którego wyślesz tę książkę.';

  @override
  String get boEmailSendOptions => 'Opcje';

  @override
  String get boEmailSendFormatEach => 'Własny format każdego urządzenia';

  @override
  String get boEmailSendServer => 'Serwer poczty';

  @override
  String get boEmailSendButton => 'Wyślij';

  @override
  String boEmailSendGets(String format, String size) {
    return 'Otrzyma $format · $size';
  }

  @override
  String boEmailSendMissing(String format, String got) {
    return 'Brak $format, otrzyma: $got';
  }

  @override
  String boEmailSendKindleRejects(String format) {
    return 'Kindle nie przyjmuje $format e-mailem';
  }

  @override
  String boEmailSendOverKindle(String size) {
    return '$size, powyżej limitu Kindle 50 MB';
  }

  @override
  String boEmailSendOverGmail(String size) {
    return '$size, powyżej limitu Gmaila 25 MB';
  }

  @override
  String get boEmailSendTextOnly =>
      'Gets the text only EPUB, narration left out';

  @override
  String boEmailSendNarrated(String size) {
    return 'Otrzyma kopię z narracją · $size';
  }

  @override
  String boEmailSendHanding(String server) {
    return 'Wysyłanie przez $server';
  }

  @override
  String boEmailSendAccepted(String server) {
    return 'Wysłano przez $server';
  }

  @override
  String boEmailSendFailedLine(String error) {
    return 'Nie wysłano: $error';
  }

  @override
  String get boEmailSendStillGoing =>
      'Nadal wysyłanie. Dostaniesz powiadomienie po zakończeniu.';

  @override
  String get boEmailKindleOriginal =>
      'Kindle nie przyjmie kopii z narracją. Ustaw tylko tekst.';

  @override
  String get boEmailNoCopy => 'Nie udało się utworzyć kopii bez narracji.';

  @override
  String get boForgotLink => 'Nie pamiętasz hasła?';

  @override
  String get boForgotTitle => 'Zresetuj hasło';

  @override
  String get boForgotBody =>
      'Wpisz e-mail przypisany do konta, a serwer wyśle Ci link do wybrania nowego hasła.';

  @override
  String get boForgotSend => 'Wyślij link';

  @override
  String get boForgotSent =>
      'Jeśli ten e-mail jest przypisany do konta, link jest w drodze. Otwórz go, aby wybrać nowe hasło, a następnie zaloguj się tutaj.';

  @override
  String get boForgotNotSetUp =>
      'Ten serwer nie jest skonfigurowany do wysyłania e-maili. Poproś osobę, która nim zarządza, o link do hasła.';

  @override
  String get boForgotTooMany =>
      'Zbyt wiele prób. Poczekaj chwilę i spróbuj ponownie.';

  @override
  String get boActivityTitle => 'Aktywność czytelnicza';

  @override
  String get boActivityPrivate =>
      'Zachowuje swoją aktywność czytelniczą w prywatności';

  @override
  String get boActivitySharesSummary =>
      'Udostępnia podsumowanie. Widzi, kiedy je oglądasz.';

  @override
  String get boActivitySharesDetails =>
      'Udostępnia szczegóły, w tym książki. Widzi, kiedy je oglądasz.';

  @override
  String get boActivityNotice => 'Ta osoba widzi, że to obejrzałeś.';

  @override
  String get boActivityNowPrivate =>
      'Ta osoba nie udostępnia już swojej aktywności czytelniczej.';

  @override
  String get boActivityLoadFailed =>
      'Nie udało się wczytać aktywności czytelniczej.';

  @override
  String get boActivityEmpty => 'Brak czytania w tym okresie';

  @override
  String get boActivityReadingTime => 'Czas czytania';

  @override
  String get boActivitySessions => 'Sesje';

  @override
  String get boActivityActiveDays => 'Aktywne dni';

  @override
  String get boActivityStarted => 'Rozpoczęte książki';

  @override
  String get boActivityFinished => 'Ukończone książki';

  @override
  String get boActivityTrend => 'Dzienne czytanie';

  @override
  String get boActivitySources => 'Czytano na';

  @override
  String get boActivityFormats => 'Formaty';

  @override
  String get boActivityGenres => 'Gatunki';

  @override
  String get boActivityTopBooks => 'Najczęściej czytane';

  @override
  String get boActivityRecentBooks => 'Ostatnio czytane';

  @override
  String get boActivityTopAuthors => 'Najczęstsi autorzy';

  @override
  String get boActivityTopGenres => 'Najczęstsze gatunki';

  @override
  String get boActivityTopSeries => 'Najczęstsze serie';

  @override
  String get boActivityTopNarrators => 'Najczęstsi lektorzy';

  @override
  String get boActivityUntitled => 'Książka bez tytułu';

  @override
  String get boActivitySourceWeb => 'Czytnik webowy';

  @override
  String get boActivitySourceIos => 'Aplikacja iOS';

  @override
  String get boActivitySourceWatch => 'Apple Watch';

  @override
  String get boActivitySourceAndroid => 'Aplikacja Android';

  @override
  String get boActivitySourceManual => 'Ręcznie';

  @override
  String get boActivitySourceUnknown => 'Nieznane';

  @override
  String get boActivityGenreSciFi => 'Science fiction';

  @override
  String get boActivityGenreFantasy => 'Fantasy';

  @override
  String get boActivityGenreMystery => 'Kryminał i thriller';

  @override
  String get boActivityGenreRomance => 'Romans';

  @override
  String get boActivityGenreHorror => 'Horror';

  @override
  String get boActivityGenreHistory => 'Historia i biografie';

  @override
  String get boActivityGenreScience => 'Nauka i technologia';

  @override
  String get boActivityGenreBusiness => 'Biznes i ekonomia';

  @override
  String get boActivityGenreSelf => 'Rozwój osobisty';

  @override
  String get boActivityGenreSociety => 'Społeczeństwo i kultura';

  @override
  String get boActivityGenreChildren => 'Dla dzieci i młodzieży';

  @override
  String get boActivityGenreComics => 'Komiksy i powieści graficzne';

  @override
  String get boActivityGenrePoetry => 'Poezja';

  @override
  String get boActivityGenreOther => 'Inne';

  @override
  String boActivityDays(int count) {
    return '$count dni';
  }

  @override
  String boActivityMinutes(int count) {
    return '$count min';
  }

  @override
  String boActivityHours(double count) {
    return '$count godz.';
  }

  @override
  String get loginBoKeyOrLink => 'Klucz API lub magiczny link';

  @override
  String get loginBoKeyOrLinkDescription =>
      'Zaloguj się kluczem API z BookOrbit, magicznym linkiem lub wklej link do hasła, aby ustawić hasło.';

  @override
  String get boPermLibraryMergeBooks => 'Łączenie i powiązywanie książek';

  @override
  String get boPermLibraryGenerateReadAloud =>
      'Generowanie książek do czytania na głos';

  @override
  String get boPermApiKeys => 'Tworzenie kluczy API';

  @override
  String get boAdminApiKeysSubtitle =>
      'Zezwól na klucze na tym serwerze i ogranicz czas ich ważności';

  @override
  String get boAccountApiKeysSubtitle => 'Klucze, które logują bez hasła';

  @override
  String get boAccountKeySession => 'Zalogowano kluczem API';

  @override
  String get boAccountKeySessionSubtitle =>
      'Hasłem, sesjami i kluczami zarządza się po zalogowaniu hasłem';

  @override
  String get boAccountKeyReadOnly =>
      'Ten klucz jest tylko do odczytu, więc nic z tego, co robisz, nie jest zapisywane na serwerze';

  @override
  String get boUserApiKeysSubtitle =>
      'Wystaw klucz, który loguje tę osobę do Absorb, lub unieważnij jej klucze';

  @override
  String get boApiKeysTitle => 'Klucze API';

  @override
  String boApiKeysForUser(String name) {
    return 'Klucze API użytkownika $name';
  }

  @override
  String get boApiKeysIntro =>
      'Klucz loguje bez Twojego hasła, na potrzeby skryptu lub innego Absorb. Nie może więcej niż Ty, a możesz go dodatkowo ograniczyć.';

  @override
  String boApiKeysIntroAdmin(String name) {
    return 'Klucz loguje użytkownika $name bez jego hasła. Nie może więcej niż on i działa jako on.';
  }

  @override
  String get boApiKeysDisabled => 'Klucze API są wyłączone na tym serwerze';

  @override
  String get boApiKeysNoPermission =>
      'Twoje konto nie może tworzyć kluczy API. Administrator może to przyznać lub wystawić klucz za Ciebie.';

  @override
  String boApiKeysLimit(int count) {
    return 'Jedna osoba może mieć co najwyżej $count aktywnych kluczy. Unieważnij jeden, aby zrobić miejsce.';
  }

  @override
  String get boApiKeysEmpty => 'Brak kluczy API';

  @override
  String get boApiKeyCreate => 'Nowy klucz';

  @override
  String get boApiKeyIssue => 'Wystaw klucz';

  @override
  String boApiKeyIssueFor(String name) {
    return 'Wystaw klucz dla $name';
  }

  @override
  String get boApiKeyCreateHint =>
      'Klucz jest pokazywany raz, zaraz po utworzeniu.';

  @override
  String get boApiKeyName => 'Nazwa';

  @override
  String get boApiKeyNameHint => 'Do czego służy ten klucz?';

  @override
  String get boApiKeyAccess => 'Dostęp';

  @override
  String get boApiKeyAccessRead => 'Odczyt';

  @override
  String get boApiKeyAccessWrite => 'Odczyt i zapis';

  @override
  String get boApiKeyAccessReadHint =>
      'Może wyszukiwać, ale niczego nie zmienia. Absorb nie może zapisywać postępu kluczem tylko do odczytu.';

  @override
  String get boApiKeyAccessWriteHint =>
      'To, czego Absorb potrzebuje do zapisywania postępu, zakładek i ustawień.';

  @override
  String get boApiKeyExpires => 'Wygasa';

  @override
  String get boApiKeyExpiryNever => 'Nigdy';

  @override
  String boApiKeyExpiryDays(int count) {
    return '$count dni';
  }

  @override
  String boApiKeyExpiryCapped(int count) {
    return 'Ten serwer ogranicza klucze do $count dni.';
  }

  @override
  String get boApiKeyAdmin => 'Dostęp administratora';

  @override
  String get boApiKeyAdminHint =>
      'Klucz może wszystko, co administrator. Nie można go ograniczyć do bibliotek.';

  @override
  String get boApiKeyPermissions => 'Uprawnienia';

  @override
  String get boApiKeyPermissionsHint =>
      'Wybierz, z czego klucz może korzystać. Bez wyboru nadal może odczytywać biblioteki i dane osobiste.';

  @override
  String get boApiKeyAdminHasAll =>
      'Klucz administratora ma wszystkie uprawnienia.';

  @override
  String get boApiKeyNoGrantable =>
      'Konto nie ma uprawnień, które mógłby nieść klucz.';

  @override
  String get boApiKeyLibraries => 'Biblioteki';

  @override
  String get boApiKeyAllLibraries => 'Wszystkie biblioteki';

  @override
  String get boApiKeyRename => 'Zmień nazwę';

  @override
  String get boApiKeyRegenerate => 'Wygeneruj ponownie';

  @override
  String get boApiKeyRegenerateTitle => 'Wygenerować ten klucz ponownie?';

  @override
  String boApiKeyRegenerateBody(String name) {
    return '„$name” otrzyma nowy sekret, a stary natychmiast przestanie działać. Wszystko, co używa starego, trzeba zaktualizować.';
  }

  @override
  String get boApiKeyRevoke => 'Unieważnij';

  @override
  String get boApiKeyRevokeTitle => 'Unieważnić ten klucz?';

  @override
  String boApiKeyRevokeBody(String name) {
    return '„$name” natychmiast przestaje działać. Wszystko, co z niego korzysta, zostanie wylogowane.';
  }

  @override
  String get boApiKeyRevoked => 'Klucz unieważniony';

  @override
  String get boApiKeyRevokeAll => 'Unieważnij wszystkie';

  @override
  String get boApiKeyRevokeAllTitle => 'Unieważnić każdy klucz?';

  @override
  String boApiKeyRevokeAllBody(int count) {
    return 'Liczba kluczy, które natychmiast przestaną działać: $count. Wszystko, co z nich korzysta, zostanie wylogowane.';
  }

  @override
  String boApiKeyRevokedCount(int count) {
    return 'Unieważniono kluczy: $count';
  }

  @override
  String boApiKeyRevokedOn(String date) {
    return 'Unieważniono $date';
  }

  @override
  String boApiKeyExpiredOn(String date) {
    return 'Wygasł $date';
  }

  @override
  String boApiKeyExpiresSoon(String date) {
    return 'Wkrótce wygasa, $date';
  }

  @override
  String boApiKeyExpiresOn(String date) {
    return 'Wygasa $date';
  }

  @override
  String get boApiKeyNeverExpires => 'Nigdy nie wygasa';

  @override
  String get boApiKeyNeverUsed => 'Nigdy nie użyto';

  @override
  String boApiKeyLastUsed(String date) {
    return 'Ostatnio użyto $date';
  }

  @override
  String boApiKeyLastUsedFrom(String date, String ip) {
    return 'Ostatnio użyto $date z $ip';
  }

  @override
  String boApiKeyLibrariesOnly(String names) {
    return 'Tylko $names';
  }

  @override
  String boApiKeyIssuedBy(String name) {
    return 'Wystawił(a): $name';
  }

  @override
  String get boApiKeyAdminBadge => 'Admin';

  @override
  String get boApiKeyExpiringBadge => 'Wygasa';

  @override
  String get boApiKeyExpiredBadge => 'Wygasł';

  @override
  String get boApiKeyRevokedBadge => 'Unieważniony';

  @override
  String get boApiKeyRevealHint =>
      'Skopiuj go teraz lub wyślij na drugie urządzenie. Nie zostanie pokazany ponownie.';

  @override
  String get boApiKeyCopy => 'Kopiuj klucz';

  @override
  String get boApiKeyCopied => 'Skopiowano klucz';

  @override
  String get boApiKeySignInElsewhere => 'Zaloguj się na innym urządzeniu';

  @override
  String get boApiKeyRevealWarning =>
      'Klucz jest pokazywany tylko ten jeden raz. Jeśli go zgubisz, wygeneruj go ponownie.';

  @override
  String boApiKeyShareDescription(String username) {
    return 'Otwórz ten link lub zeskanuj kod QR na drugim urządzeniu, aby zalogować się do Absorb jako $username za pomocą tego klucza.';
  }

  @override
  String boApiKeyShareWarning(String name) {
    return 'Każdy, kto ma ten link, może używać klucza „$name”, dopóki nie zostanie unieważniony.';
  }

  @override
  String get boApiKeyErrorExpiryCap =>
      'Ten czas ważności jest dłuższy, niż pozwala serwer';

  @override
  String get boApiKeyErrorOwner =>
      'To konto nie może teraz mieć kluczy: jest zawieszone lub nie może ich tworzyć';

  @override
  String get boApiKeyErrorAdminLibraries =>
      'Klucza administratora nie można ograniczyć do bibliotek';

  @override
  String get boApiKeyErrorScope =>
      'Klucz zażądał więcej, niż ma jego właściciel';

  @override
  String get boApiKeyErrorKeySession =>
      'Kluczami nie można zarządzać z sesji zalogowanej kluczem';

  @override
  String get boPasswordSessionTitle => 'Sign in to continue';

  @override
  String get boPasswordSessionBody =>
      'BookOrbit doesn\'t let an API key do this. Sign in once and Absorb keeps it for next time.';

  @override
  String get boPasswordSessionSignIn => 'Sign in';

  @override
  String boPasswordSessionWith(String provider) {
    return 'Sign in with $provider';
  }

  @override
  String get boPasswordSessionWrongPassword => 'That password didn\'t work';

  @override
  String get boPasswordSessionOtherAccount => 'That\'s a different account';

  @override
  String get boPasswordSessionFailed => 'Couldn\'t sign in';

  @override
  String get boPasswordSessionNoMethods =>
      'This server has no password or single sign-on to sign in with';

  @override
  String get boPasswordSessionUsed => 'Using your password sign-in';

  @override
  String boPasswordSessionUsedWith(String provider) {
    return 'Using your $provider sign-in';
  }

  @override
  String get boPasswordSessionNeeded => 'This needs a password sign-in';

  @override
  String get coverNotSavedYet => 'Tap Save to use this cover';

  @override
  String get boApiKeySettingsSaved => 'Zapisano ustawienia kluczy API';

  @override
  String get boApiKeySettingsIntro => 'Dotyczą każdego klucza na serwerze.';

  @override
  String get boApiKeySettingsEnabled => 'Zezwalaj na klucze API';

  @override
  String get boApiKeySettingsEnabledHint =>
      'Wyłączenie odrzuca każdy klucz bez unieważniania żadnego i blokuje tworzenie nowych';

  @override
  String get boApiKeySettingsMaxLifetime => 'Najdłuższy czas ważności';

  @override
  String get boApiKeySettingsMaxLifetimeHint =>
      'Nowe i ponownie wygenerowane klucze nie mogą działać dłużej. Istniejące klucze zachowują swoje wygaśnięcie.';

  @override
  String get boApiKeySettingsNoLimit => 'Bez limitu';

  @override
  String get boApiKeySettingsCustom => 'Inny';

  @override
  String get boApiKeySettingsCustomDays => 'Dni';

  @override
  String boApiKeySettingsCustomRange(int max) {
    return 'Od 1 do $max dni';
  }

  @override
  String get boUserKeyLink => 'Link logowania z kluczem API';

  @override
  String get boUserKeyLinkSubtitle =>
      'Tworzy klucz ze wszystkim, co ma ta osoba, i pokazuje kod QR logujący ją do Absorb';

  @override
  String get boApiKeyLinkName => 'Logowanie do Absorb';

  @override
  String boApiKeyLinkFor(String name) {
    return 'Link logowania dla $name';
  }

  @override
  String get tvSignInTitle => 'Sign in from your phone';

  @override
  String get tvSignInStep1 => 'Point your phone\'s camera at this code';

  @override
  String get tvSignInStep2 => 'Tap Open in Absorb, then Sign in TV';

  @override
  String get tvSignInNeedsPhone =>
      'Absorb on your phone needs to be signed in, on the same Wi-Fi as this TV.';

  @override
  String get tvSignInHere => 'Sign in on the TV instead';

  @override
  String get tvSignInNoNetwork =>
      'This TV isn\'t on a network. Connect it to Wi-Fi to sign in from your phone.';

  @override
  String get tvSignInRetry => 'Try again';

  @override
  String get tvHomeEmpty =>
      'Nothing to continue yet. Find something in Library or Search, and it shows up here.';

  @override
  String get signInTvTitle => 'Sign in your TV';

  @override
  String get signInTvKeyNote =>
      'The TV gets its own API key named Absorb TV. You can remove it later under API Keys.';

  @override
  String get signInTvPasswordNote =>
      'Type your password to sign the TV in. It goes straight to the TV and isn\'t kept on this phone.';

  @override
  String get signInTvButton => 'Sign in TV';

  @override
  String get signInTvDone => 'Your TV is signed in';

  @override
  String get signInTvNotSignedIn =>
      'Sign in on this phone first, then scan the code on the TV again.';

  @override
  String get signInTvRefused =>
      'The TV turned this down. Scan the code on the TV again.';

  @override
  String get signInTvBusy => 'The TV is already signing in';

  @override
  String get signInTvNoAnswer => 'The TV didn\'t answer';

  @override
  String get signInTvUnreachable =>
      'Can\'t reach the TV. Check that this phone is on the same Wi-Fi.';

  @override
  String get signInTvFailed => 'The TV couldn\'t sign in';

  @override
  String get signInTvKeyFailed => 'Couldn\'t make a key for the TV';

  @override
  String get signInTvKeyName => 'Absorb TV';

  @override
  String signInTvAs(String server, String username) {
    return '$server as $username';
  }

  @override
  String get tvHome => 'Home';

  @override
  String get tvLibrary => 'Library';

  @override
  String get tvSearch => 'Search';

  @override
  String get tvLibraries => 'Libraries';

  @override
  String get tvSortAdded => 'Recently added';

  @override
  String get tvSortTitle => 'Title';

  @override
  String get tvSortAuthor => 'Author';

  @override
  String get tvNothingHere => 'Nothing here';

  @override
  String get tvSearchHint => 'Search this library';

  @override
  String get tvPlay => 'Play';

  @override
  String get tvContinue => 'Continue';

  @override
  String get tvNoAudio => 'No audio';

  @override
  String get tvSignedInAs => 'Signed in';

  @override
  String get tvSignOut => 'Sign out';

  @override
  String tvBookCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count books',
      one: '1 book',
    );
    return '$_temp0';
  }

  @override
  String get tvNowPlayingHint => 'Hold OK to open';

  @override
  String get tvStartOver => 'Start over';

  @override
  String get tvFinished => 'Finished';

  @override
  String tvNarratedBy(String name) {
    return 'Narrated by $name';
  }

  @override
  String tvTimeLeft(String time) {
    return '$time left';
  }

  @override
  String get tvNightMode => 'Night mode';

  @override
  String get tvAccounts => 'Accounts';

  @override
  String get tvLayoutHint =>
      'Hold OK to pick a button up, move it with up and down, then press OK to put it down';

  @override
  String get tvRead => 'Read';

  @override
  String get tvRefreshed => 'Up to date with the server';

  @override
  String get tvStop => 'Stop';

  @override
  String tvSignOutQuestion(String name) {
    return 'Sign $name out on this TV?';
  }

  @override
  String get tvBooks => 'Books';

  @override
  String get tvLists => 'Lists';

  @override
  String get tvMoreInSeries => 'More in series';

  @override
  String get tvPlayback => 'Playback';

  @override
  String tvSkipBack(int seconds) {
    return 'Back ${seconds}s';
  }

  @override
  String tvSkipForward(int seconds) {
    return 'Forward ${seconds}s';
  }

  @override
  String get tvSleep => 'Sleep';

  @override
  String get tvRewindOff => 'No rewind on resume';

  @override
  String get tvAutoSleepOn => 'Auto sleep timer on';

  @override
  String get tvAutoSleepOff => 'Auto sleep timer off';

  @override
  String get tvAutoNightOff => 'No night mode with sleep timer';

  @override
  String get tvAutoNightHint =>
      'With a sleep timer running, night mode comes on once the remote has been still this long.';

  @override
  String tvDefaultSpeed(String speed) {
    return 'Speed ${speed}x for new books';
  }

  @override
  String tvRewindOnResume(int seconds) {
    return 'Rewind ${seconds}s on resume';
  }

  @override
  String tvSleepDefault(int minutes) {
    return 'Sleep timer $minutes min';
  }

  @override
  String tvAutoSleepFrom(String time) {
    return 'From $time';
  }

  @override
  String tvAutoSleepUntil(String time) {
    return 'Until $time';
  }

  @override
  String tvAutoNightAfter(int minutes) {
    return 'Night mode after $minutes min';
  }

  @override
  String get tvLoginTitle => 'Sign in on this TV';

  @override
  String get tvLoginServerHint => 'Server address, like 192.168.1.10:13378';

  @override
  String get tvLoginUsername => 'Username';

  @override
  String get tvLoginFillIn => 'Enter the server address and your username';

  @override
  String tvPodcastCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count podcasts',
      one: '1 podcast',
    );
    return '$_temp0';
  }

  @override
  String get tvPodcastDetails => 'Podcast Details';
}
