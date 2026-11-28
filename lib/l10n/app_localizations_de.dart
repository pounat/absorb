// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'A B S O R B';

  @override
  String get online => 'Online';

  @override
  String get offline => 'Offline';

  @override
  String get stillOffline =>
      'Immer noch offline. Tippe, um es erneut zu versuchen.';

  @override
  String get retry => 'Erneut versuchen';

  @override
  String get listsNone => 'Keine Sammlungen oder Wiedergabelisten vorhanden';

  @override
  String get listsNoneHint =>
      'Sammlungen und Wiedergabelisten werden auf Ihrem Audiobookshelf-Server erstellt und hier angezeigt.';

  @override
  String get listsLoadFailed => 'Listen konnten nicht geladen werden';

  @override
  String get listsLoadFailedHint =>
      'Absorb konnte deinen Server für Sammlungen und Wiedergabelisten nicht erreichen.';

  @override
  String get listsNoneBookOrbit => 'Keine Sammlungen oder Smart Scopes';

  @override
  String get listsNoneHintBookOrbit =>
      'Sammlungen und Smart Scopes werden auf deinem BookOrbit-Server erstellt und hier angezeigt.';

  @override
  String get listsLoadFailedHintBookOrbit =>
      'Absorb konnte deinen Server für Sammlungen und Smart Scopes nicht erreichen.';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get delete => 'Löschen';

  @override
  String get remove => 'Entfernen';

  @override
  String get save => 'Speichern';

  @override
  String get done => 'Fertig';

  @override
  String get edit => 'Bearbeiten';

  @override
  String get search => 'Suche';

  @override
  String get apply => 'Anwenden';

  @override
  String get enable => 'Aktivieren';

  @override
  String get clear => 'Zurücksetzen';

  @override
  String get off => 'Aus';

  @override
  String get disabled => 'Deaktiviert';

  @override
  String get later => 'Später';

  @override
  String get whatsNewTitle => 'Absorb wurde aktualisiert';

  @override
  String whatsNewContent(String version) {
    return 'Du bist jetzt auf $version.';
  }

  @override
  String get whatsNewButton => 'Was gibt\'s neues';

  @override
  String get whatsNewKeepShowing => 'Nach jedem Update anzeigen';

  @override
  String get whatsNewKeepShowingHint =>
      'Du kannst es in den Einstellungen wieder einschalten';

  @override
  String get settingsWhatsNew => 'Zeige Neuigkeiten nach Updates';

  @override
  String get settingsWhatsNewSubtitle =>
      'Nach Absorb Updates verlinkt ein Pop-up auf die Release Notes';

  @override
  String get gotIt => 'Verstanden';

  @override
  String get betaLoggingTitle => 'Protokolle sind aktiviert';

  @override
  String get betaLoggingContent =>
      'Da dies eine Beta ist, erstellt Absorb Protokolle zur Aufspürung von Problemen. Diese bleiben auf deinem Gerät, es sei denn du teilst sie.\n\nDu kannst die Protokollierung in den Einstellungen unter Fragen & Support ausschalten. Diese bleiben auch nach zukünftigen Updates deaktiviert.';

  @override
  String get preview => 'Vorschau';

  @override
  String get or => 'oder';

  @override
  String get file => 'Datei';

  @override
  String get more => 'Mehr';

  @override
  String get unknown => 'Unbekannt';

  @override
  String get untitled => 'Ohne Titel';

  @override
  String get noThanks => 'Nein, danke';

  @override
  String get stay => 'Bleiben';

  @override
  String get homeTitle => 'Start';

  @override
  String get continueListening => 'Weiterhören';

  @override
  String get continueReading => 'Weiterlesen';

  @override
  String get continueSeries => 'Serie fortsetzen';

  @override
  String get recentlyAdded => 'Kürzlich hinzugefügt';

  @override
  String get listenAgain => 'Nochmal hören';

  @override
  String get discover => 'Entdecken';

  @override
  String get newEpisodes => 'Neue Episoden';

  @override
  String get downloads => 'Downloads';

  @override
  String get noDownloadedBooks => 'Keine heruntergeladenen Bücher';

  @override
  String get yourLibraryIsEmpty => 'Deine Bibliothek ist leer';

  @override
  String get downloadBooksWhileOnline =>
      'Lade Bücher herunter, solange du online bist, um sie offline zu hören';

  @override
  String get customizeHome => 'Startseite anpassen';

  @override
  String get dragToReorderTapEye =>
      'Zum Umsortieren ziehen, Auge antippen zum Ein-/Ausblenden';

  @override
  String get loginTagline => 'Start Absorbing';

  @override
  String get loginConnectToServer => 'Verbinde dich mit deinem Server';

  @override
  String get loginServerAddress => 'Serveradresse';

  @override
  String get loginServerHint => 'my.server.com';

  @override
  String get loginServerHelper =>
      'IP:Port funktioniert auch (z. B. 192.168.1.5:13378)';

  @override
  String get loginCouldNotReachServer => 'Server nicht erreichbar';

  @override
  String get loginAdvanced => 'Erweitert';

  @override
  String get loginCustomHttpHeaders => 'Eigene HTTP-Header';

  @override
  String get loginCustomHeadersDescription =>
      'Für Cloudflare-Tunnel oder Reverse-Proxys, die zusätzliche Header benötigen. Header hinzufügen, bevor du die Server-URL eingibst.';

  @override
  String get loginHeaderName => 'Header-Name';

  @override
  String get loginHeaderValue => 'Wert';

  @override
  String get loginAddHeader => 'Header hinzufügen';

  @override
  String get loginSelfSignedCertificates => 'Selbstsignierte Zertifikate';

  @override
  String get loginTrustAllCertificates =>
      'Allen Zertifikaten vertrauen (für selbstsignierte / eigene CA-Setups)';

  @override
  String get loginApiKey => 'API-Schlüssel';

  @override
  String get loginApiKeyDescription =>
      'Verwende einen vom Admin generierten API-Schlüssel statt Benutzername/Passwort. Praktisch, wenn die Token-Erneuerung für dein Konto fehlschlägt.';

  @override
  String get loginWaitingForSso => 'Warte auf SSO...';

  @override
  String get loginRedirectUri => 'Redirect URI: absorb://oauth';

  @override
  String get loginOrSignInManually => 'oder manuell anmelden';

  @override
  String get loginUsername => 'Benutzername';

  @override
  String get loginUsernameRequired => 'Bitte gib deinen Benutzernamen ein';

  @override
  String get loginPassword => 'Passwort';

  @override
  String get loginSignIn => 'Anmelden';

  @override
  String loginSignInAs(String username) {
    return 'Als $username anmelden?';
  }

  @override
  String get loginSignInToServer => 'Auf diesem Server anmelden?';

  @override
  String loginSignedInAs(String username) {
    return 'Als $username angemeldet';
  }

  @override
  String get adminCreateSetupFile => 'Anmeldung teilen';

  @override
  String adminSetupFileDescription(String username) {
    return 'Erstellt einen privaten Anmelde-Link für $username, der nur in der Absorb-App funktioniert.';
  }

  @override
  String get adminSetupFileServerUrl =>
      'Server-URL, die der neue Benutzer verwenden wird';

  @override
  String get adminSetupFileNoteWithHeaders =>
      'Ein API-Key und die benutzerdefinierten Header werden mit eingeschlossen, um die Anmeldung auf dem Server zu ermöglichen. Behandle den Link wie ein Passwort.';

  @override
  String get adminSetupFileNote =>
      'Ein spezieller API-Schlüssel wird hinzugefügt. Behandle den Link wie ein Passwort.';

  @override
  String get adminSetupFileCreate => 'Link erstellen';

  @override
  String get adminSetupFileSaveTitle => 'Setup Datei speichern';

  @override
  String get adminSetupFileKeyError =>
      'Für diesen Benutzer konnte kein API Key erstellt werden';

  @override
  String adminSetupFileSaved(String username) {
    return 'Setup-Datei für $username gespeichert';
  }

  @override
  String adminSetupFileFailed(String error) {
    return 'Fehler beim Erstellen der Anmeldung: $error';
  }

  @override
  String get setupLinkShareTitle => 'Anmeldung teilen';

  @override
  String setupLinkShareDescription(String username) {
    return 'Versende diesen privaten Link oder lasse den QR-Code scannen, um eine Anmeldung als $username zu ermöglichen.';
  }

  @override
  String setupLinkPrivateWarning(String username) {
    return 'Jeder mit diesem Link kann sich als $username anmelden. Behandle ihn wie ein Passwort.';
  }

  @override
  String get setupLinkShare => 'Link teilen';

  @override
  String get setupLinkCopy => 'Link kopieren';

  @override
  String get setupLinkCopied => 'Anmelde-Link kopiert';

  @override
  String get setupLinkSaveFile => 'Setup Datei speichern';

  @override
  String get setupLinkQrError =>
      'Dieser Setup-Link ist zu groß für einen QR-Code. Teile stattdessen den Link.';

  @override
  String setupLinkShareSubject(String username) {
    return 'Absorb Anmeldung für $username';
  }

  @override
  String get setupLinkConfirmTitle => 'Mit diesem Link anmelden?';

  @override
  String setupLinkConfirmBody(String server, String username) {
    return 'Bei $server als $username anmelden? Fahre nur fort, wenn du diesem Link vertraust.';
  }

  @override
  String get setupLinkInvalid =>
      'Dieser Anmelde-Link ist ungültig oder unvollständig';

  @override
  String get setupLinkSigningIn => 'Anmelde-Link wird überprüft...';

  @override
  String get loginPlayDownloads => 'Deine Downloads abspielen';

  @override
  String signedOutDownloadsNote(String username) {
    return 'Du bist abgemeldet. Alles was du hier hörst wird zu $username synchronisiert wenn du dich wieder einloggst.';
  }

  @override
  String get loginPasteLink => 'Anmelde-Link einfügen';

  @override
  String get loginPasteLinkHelp =>
      'Füge den vollständigen Anmelde-Link ein, den du erhalten hast. Behandle ihn wie ein Passwort.';

  @override
  String get loginFailed => 'Anmeldung fehlgeschlagen';

  @override
  String get loginSsoFailed => 'SSO-Anmeldung fehlgeschlagen oder abgebrochen';

  @override
  String get loginSsoAuthFailed =>
      'SSO-Authentifizierung fehlgeschlagen. Bitte versuche es erneut.';

  @override
  String get loginRestoreFromBackup => 'Importieren';

  @override
  String get loginInvalidBackupFile => 'Ungültige Backup-Datei';

  @override
  String get loginRestoreBackupTitle => 'Backup wiederherstellen?';

  @override
  String loginRestoreBackupWithAccounts(int count) {
    return 'Damit werden alle Einstellungen und $count gespeicherte Konten wiederhergestellt. Du wirst automatisch angemeldet.';
  }

  @override
  String get loginRestoreBackupNoAccounts =>
      'Damit werden alle Einstellungen wiederhergestellt. Es waren keine Konten in diesem Backup enthalten.';

  @override
  String get loginRestore => 'Wiederherstellen';

  @override
  String loginRestoredAndSignedIn(String username) {
    return 'Einstellungen wiederhergestellt und als $username angemeldet';
  }

  @override
  String get loginSessionExpired =>
      'Einstellungen wiederhergestellt. Sitzung abgelaufen - melde dich an, um fortzufahren.';

  @override
  String get loginSettingsRestored => 'Einstellungen wiederhergestellt';

  @override
  String loginRestoreFailed(String error) {
    return 'Wiederherstellung fehlgeschlagen: $error';
  }

  @override
  String get loginSavedAccounts => 'gespeicherte Konten';

  @override
  String get libraryTitle => 'Bibliothek';

  @override
  String get librarySearchBooksHint =>
      'Bücher, Serien, Autoren, Sprecher suchen...';

  @override
  String get librarySearchShowsHint => 'Sendungen und Episoden suchen...';

  @override
  String get libraryTabLibrary => 'Bibliothek';

  @override
  String get libraryTabSeries => 'Serien';

  @override
  String get libraryTabAuthors => 'Autoren';

  @override
  String get libraryTabNarrators => 'Sprecher';

  @override
  String get libraryNoBooks => 'Keine Bücher gefunden';

  @override
  String get libraryNoUnfinishedBooks => 'Keine unerledigten Bücher';

  @override
  String get libraryNoBooksInProgress => 'Keine angefangenen Bücher';

  @override
  String get libraryNoFinishedBooks => 'Keine beendeten Bücher';

  @override
  String get libraryAllBooksStarted => 'Alle Bücher wurden begonnen';

  @override
  String get libraryNoDownloadedBooks => 'Keine heruntergeladenen Bücher';

  @override
  String get libraryNoSeriesFound => 'Keine Serien gefunden';

  @override
  String get libraryNoBooksWithEbooks => 'Keine Bücher mit eBooks';

  @override
  String get libraryNoBooksMissingMetadata =>
      'Diese Metadaten fehlen in keinem Buch';

  @override
  String get libraryNoItemsMatchingFilter =>
      'Keine Elemente entsprechen diesem Filter';

  @override
  String libraryNoBooksInGenre(String genre) {
    return 'Keine Bücher in \"$genre\"';
  }

  @override
  String libraryNoBooksWithTag(String tag) {
    return 'Keine Bücher mit dem Schlagwort \"$tag\"';
  }

  @override
  String get libraryClearFilter => 'Filter zurücksetzen';

  @override
  String get libraryNoAuthorsFound => 'Keine Autoren gefunden';

  @override
  String get libraryNoNarratorsFound => 'Keine Sprecher gefunden';

  @override
  String get libraryNoResults => 'Keine Ergebnisse gefunden';

  @override
  String get librarySearchBooks => 'Bücher';

  @override
  String get librarySearchShows => 'Sendungen';

  @override
  String get librarySearchEpisodes => 'Episoden';

  @override
  String get librarySearchSeries => 'Serien';

  @override
  String get librarySearchAuthors => 'Autoren';

  @override
  String get librarySearchTags => 'Schlagwörter';

  @override
  String get librarySearchGenres => 'Genres';

  @override
  String librarySeriesCount(int count) {
    return '$count Serien';
  }

  @override
  String libraryAuthorsCount(int count) {
    return '$count Autoren';
  }

  @override
  String libraryNarratorsCount(int count) {
    return '$count Sprecher';
  }

  @override
  String libraryBooksCount(int loaded, int total) {
    return '$loaded/$total Bücher';
  }

  @override
  String get sort => 'Sortieren';

  @override
  String get filter => 'Filter';

  @override
  String get filterActive => 'Filter ●';

  @override
  String get name => 'Name';

  @override
  String get title => 'Titel';

  @override
  String get author => 'Autor';

  @override
  String get dateAdded => 'Hinzugefügt am';

  @override
  String get numberOfBooks => 'Anzahl Bücher';

  @override
  String get sortTotalDuration => 'Gesamtdauer';

  @override
  String get sortLastBookAdded => 'Zuletzt hinzugefügtes Buch';

  @override
  String get sortLastBookUpdated => 'Zuletzt aktualisiertes Buch';

  @override
  String get publishedYear => 'Erscheinungsjahr';

  @override
  String get duration => 'Dauer';

  @override
  String get random => 'Zufällig';

  @override
  String get collapseSeries => 'Serien zusammenklappen';

  @override
  String get notFinished => 'Unerledigt';

  @override
  String get inProgress => 'Angefangen';

  @override
  String get filterFinished => 'Beendet';

  @override
  String get notStarted => 'Nicht begonnen';

  @override
  String get downloaded => 'Heruntergeladen';

  @override
  String get hasEbook => 'Mit eBook';

  @override
  String get noEbook => 'Kein E-Book';

  @override
  String get hasSupplementaryEbook => 'Hat ergänzendes E-Book';

  @override
  String get noSupplementaryEbook => 'Kein ergänzendes E-Book';

  @override
  String get noSeries => 'Keine Reihe';

  @override
  String get publishedDecade => 'Veröffentlichtes Jahrzehnt';

  @override
  String get tracks => 'Titel';

  @override
  String get noTracks => 'Keine Titel';

  @override
  String get singleTrack => 'Einzelner Titel';

  @override
  String get multipleTracks => 'Mehrere Titel';

  @override
  String get abridged => 'Gekürzt';

  @override
  String get issues => 'Probleme';

  @override
  String get rssFeedOpen => 'RSS-Feed geöffnet';

  @override
  String get explicitContent => 'Explizit';

  @override
  String get missingMetadata => 'Fehlende Metadaten';

  @override
  String get genre => 'Genre';

  @override
  String get tag => 'Schlagwort';

  @override
  String get clearFilter => 'Filter zurücksetzen';

  @override
  String get noGenresFound => 'Keine Genres gefunden';

  @override
  String get noTagsFound => 'Keine Schlagwörter gefunden';

  @override
  String get asc => 'AUF';

  @override
  String get desc => 'AB';

  @override
  String get fileSize => 'Dateigröße';

  @override
  String get lastUpdated => 'Zuletzt aktualisiert';

  @override
  String get fileCreated => 'Datei erstellt';

  @override
  String get lastModified => 'Zuletzt geändert';

  @override
  String get authorFirstLast => 'Autor (Erster Letzter)';

  @override
  String get authorLastFirst => 'Autor (Letzter, Erster)';

  @override
  String get progressSort => 'Fortschritt';

  @override
  String get dateStarted => 'Startdatum';

  @override
  String get dateFinished => 'Abschlussdatum';

  @override
  String get episodeCount => 'Anzahl Folgen';

  @override
  String get sequence => 'Reihe-Reihenfolge';

  @override
  String get absorbingTitle => 'Absorbing';

  @override
  String get absorbingStop => 'Stopp';

  @override
  String get absorbingManageQueue => 'Warteschlange verwalten';

  @override
  String get desktopAbsorbingQueueHint =>
      'Benutze Hinzufügen zum Absorbieren eines Buchs oder einer Episode, um es hier anzuzeigen. Elemente werden in dieser Reihenfolge wiedergegeben.';

  @override
  String get absorbingDone => 'Fertig';

  @override
  String get absorbingNoDownloadedEpisodes =>
      'Keine heruntergeladenen Episoden';

  @override
  String get absorbingNoDownloadedBooks => 'Keine heruntergeladenen Bücher';

  @override
  String get absorbingNothingPlayingYet => 'Es läuft noch nichts';

  @override
  String get absorbingNothingAbsorbingYet => 'Noch nichts am Absorbing';

  @override
  String get absorbingDownloadEpisodesToListen =>
      'Episoden herunterladen, um offline zu hören';

  @override
  String get absorbingDownloadBooksToListen =>
      'Bücher herunterladen, um offline zu hören';

  @override
  String get absorbingStartEpisodeFromShows =>
      'Starte eine Episode aus dem Sendungen-Tab';

  @override
  String get absorbingStartBookFromLibrary =>
      'Starte ein Buch aus dem Bibliothek-Tab';

  @override
  String get carModeTitle => 'Auto-Modus';

  @override
  String get carModeNoBookLoaded => 'Kein Buch geladen';

  @override
  String get carModeBookLabel => 'Buch';

  @override
  String get carModeChapterLabel => 'Kapitel';

  @override
  String get carModeBookmarkDefault => 'Lesezeichen';

  @override
  String get carModeBookmarkAdded => 'Lesezeichen hinzugefügt';

  @override
  String get downloadsTitle => 'Downloads';

  @override
  String get downloadsCancelSelection => 'Auswahl aufheben';

  @override
  String get downloadsSelect => 'Auswählen';

  @override
  String get downloadsNoDownloads => 'Keine Downloads';

  @override
  String get downloadsDownloading => 'Wird heruntergeladen';

  @override
  String get downloadsQueued => 'In Warteschlange';

  @override
  String get downloadsCompleted => 'Abgeschlossen';

  @override
  String get downloadsEbooks => 'E-Books';

  @override
  String get downloadsWaiting => 'Warten...';

  @override
  String get downloadsCancel => 'Abbrechen';

  @override
  String get downloadsDelete => 'Löschen';

  @override
  String downloadsDeleteCount(int count) {
    return '$count Download(s) löschen?';
  }

  @override
  String get downloadsDeleteContent =>
      'Heruntergeladene Dateien werden von diesem Gerät entfernt.';

  @override
  String downloadsDeletedCount(int count) {
    return '$count Download(s) gelöscht';
  }

  @override
  String get downloadsRemoveTitle => 'Download entfernen?';

  @override
  String downloadsRemoveContent(String title) {
    return '\"$title\" von diesem Gerät löschen?';
  }

  @override
  String downloadsRemovedTitle(String title) {
    return '\"$title\" entfernt';
  }

  @override
  String downloadFailedMissingFile(String title) {
    return 'Konnte \"$title\" nicht herunterladen - eine der Dateien ist nicht auf dem Server. Ein Bibliothek-Scan könnte das beheben.';
  }

  @override
  String downloadFailedNoSpace(String title) {
    return 'Konnte \"$title\" nicht herunterladen - nicht genügend Speicherplatz';
  }

  @override
  String downloadFailedPermission(String title) {
    return 'Konnte \"$title\" nicht herunterladen - überprüfe den Download-Speicherort in den Einstellungen';
  }

  @override
  String downloadFailedGeneric(String title) {
    return 'Konnte \"$title \" nicht herunterladen';
  }

  @override
  String downloadsSelectedCount(int count) {
    return '$count ausgewählt';
  }

  @override
  String get bookmarksTitle => 'Alle Lesezeichen';

  @override
  String get bookmarksTabBookmarks => 'Lesezeichen';

  @override
  String get bookmarksTabHighlights => 'Highlights';

  @override
  String get highlightOpenInBook => 'In Buch öffnen';

  @override
  String get highlightDeleteAction => 'Highlight löschen';

  @override
  String get highlightDeleted => 'Highlight gelöscht';

  @override
  String highlightsDeleteCount(int count) {
    return '$count Highlight(s) löschen?';
  }

  @override
  String highlightsDeletedCount(int count) {
    return '$count Highlight(s) gelöscht';
  }

  @override
  String get quoteShareTitle => 'Zitat teilen';

  @override
  String get quoteShareAction => 'Teilen';

  @override
  String get quoteShareFailed => 'Konnte das Zitatbild nicht erstellen';

  @override
  String get quoteShapePortrait => 'Portrait';

  @override
  String get quoteShapeSquare => 'Quadrat';

  @override
  String get quoteShapeStory => 'Geschichte';

  @override
  String get quoteStyleBlur => 'Verschwommen';

  @override
  String get quoteStyleDim => 'Abgedunkelt';

  @override
  String get quoteStyleNone => 'Einfaches Cover';

  @override
  String get quoteTextLight => 'Heller Text';

  @override
  String get quoteTextDark => 'Dunkler Text';

  @override
  String get quoteFieldTitle => 'Titel';

  @override
  String get quoteFieldDetail => 'Details';

  @override
  String get quoteFieldDetailHint => 'Autor, Kapitel, Seite, Wer hat es gesagt';

  @override
  String highlightsMeta(String chapter, String date) {
    return '$chapter · $date';
  }

  @override
  String get bookmarksCancelSelection => 'Auswahl aufheben';

  @override
  String get bookmarksSortedByNewest => 'Sortiert nach neuesten';

  @override
  String get bookmarksSortedByPosition => 'Sortiert nach Position';

  @override
  String get bookmarksSelect => 'Auswählen';

  @override
  String get bookmarksNoBookmarks => 'Noch keine Lesezeichen';

  @override
  String get bookmarksSearchHint => 'Lesezeichen durchsuchen';

  @override
  String get bookmarksNoMatches => 'Keine Lesezeichen entsprechen deiner Suche';

  @override
  String batchDownloadQueued(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Bücher werden heruntergeladen',
      one: '1 Buch wird heruntergeladen',
    );
    return '$_temp0';
  }

  @override
  String get batchDownloadNothingNew => 'Bereits heruntergeladen';

  @override
  String bookmarksDeleteCount(int count) {
    return '$count Lesezeichen löschen?';
  }

  @override
  String get bookmarksDeleteContent =>
      'Das kann nicht rückgängig gemacht werden.';

  @override
  String bookmarksDeletedCount(int count) {
    return '$count Lesezeichen gelöscht';
  }

  @override
  String get bookmarksJumpTitle => 'Zum Lesezeichen springen?';

  @override
  String bookmarksJumpContent(String title, String position, String bookTitle) {
    return '\"$title\" bei $position\nin $bookTitle';
  }

  @override
  String get bookmarksJump => 'Springen';

  @override
  String get bookmarksNotConnected => 'Nicht mit dem Server verbunden';

  @override
  String get bookmarksCouldNotLoad => 'Buch konnte nicht geladen werden';

  @override
  String bookmarksSelectedCount(int count) {
    return '$count ausgewählt';
  }

  @override
  String get statsTitle => 'Deine Statistiken';

  @override
  String get statsCouldNotLoad => 'Statistiken konnten nicht geladen werden';

  @override
  String get statsTotalListeningTime => 'GESAMTE HÖRZEIT';

  @override
  String get statsHoursUnit => 'h';

  @override
  String get statsMinutesUnit => 'm';

  @override
  String get statsSecondsUnit => 's';

  @override
  String statsDaysOfAudio(String days) {
    return 'Das sind $days Tage Audio';
  }

  @override
  String statsHoursOfAudio(String hours) {
    return 'Das sind $hours Stunden Audio';
  }

  @override
  String get statsToday => 'Heute';

  @override
  String get statsThisWeek => 'Diese Woche';

  @override
  String get statsThisMonth => 'Diesen Monat';

  @override
  String get statsActivity => 'Aktivität';

  @override
  String get statsCurrentStreak => 'Aktueller Streak';

  @override
  String get statsBestStreak => 'Bester Streak';

  @override
  String get statsFinished => 'Beendet';

  @override
  String get statsBooksFinished => 'Bücher';

  @override
  String get statsEpisodesFinished => 'Episoden';

  @override
  String get statsBooksThisYear => 'Bücher dieses Jahr';

  @override
  String get statsEpisodesThisYear => 'Episoden dieses Jahr';

  @override
  String get statsRemoveFromYearTitle => 'Aus diesem Jahr entfernen';

  @override
  String statsRemoveFromYearWithDate(String date, String title) {
    return 'Das Enddatum wird weiterhin als $date auf dem Server erhalten bleiben. Dies entfernt nur \"$title\" von deiner Absorb \"Bücher-des-Jahres\" Liste.';
  }

  @override
  String statsRemoveFromYearNoDate(String title) {
    return 'Das Enddatum wird weiterhin auf dem Server erhalten bleiben. Dies entfernt nur \"$title\" von deiner Absorb \"Bücher-des-Jahres\" Liste.';
  }

  @override
  String get statsRemovedFromYear => 'Aus diesem Jahr entfernt';

  @override
  String get statsAddBackToYearTitle => 'Diesem Jahr wieder hinzufügen';

  @override
  String statsAddBackToYearBody(String title) {
    return '\"$title\" zurück zu deiner Absorb \"Bücher-des-Jahres\" Liste hinzufügen?';
  }

  @override
  String get statsAddBack => 'Wieder hinzufügen';

  @override
  String get statsAddedBackToYear => 'Diesem Jahr wieder hinzugefügt';

  @override
  String get statsHiddenFromYear => 'Aus diesem Jahr ausgeblendet';

  @override
  String get statsNothingHidden => 'Nichts ausgeblendet';

  @override
  String get settingsCustomizeStats => 'Statistiken anpassen';

  @override
  String get statsGoalTitle => 'Hörziel';

  @override
  String get statsGoalOff => 'Aus';

  @override
  String get statsGoalDaily => 'Täglich';

  @override
  String get statsGoalWeekly => 'Wöchentlich';

  @override
  String get statsGoalMonthly => 'Monatlich';

  @override
  String get statsGoalTarget => 'Ziel';

  @override
  String get statsGoalEnterTitle => 'Ziel festlegen';

  @override
  String get statsGoalEnterTimeHint => 'Minuten oder h:mm';

  @override
  String statsBooksShort(int count) {
    return '$count Bücher';
  }

  @override
  String get statsBookChallengeTitle => 'Lese-Challenge';

  @override
  String get statsBookChallengeDesc => 'Zu beendende Bücher für dieses Jahr';

  @override
  String get statsDailyGoal => 'Tagesziel';

  @override
  String get statsWeeklyGoal => 'Wochenziel';

  @override
  String get statsMonthlyGoal => 'Monatsziel';

  @override
  String statsGoalProgress(String done, String target) {
    return '$done / $target';
  }

  @override
  String statsBookChallengeProgress(int done, int target) {
    return '$done von $target Büchern';
  }

  @override
  String get statsGoalReached => 'Ziel erreicht';

  @override
  String get statsChartTitle => 'Hörstatistik';

  @override
  String get statsChartBar => 'Leiste';

  @override
  String get statsChartLine => 'Linie';

  @override
  String get statsChartHeatmap => 'Heatmap';

  @override
  String get statsChartDays7 => '7 Tage';

  @override
  String get statsChartDays30 => '30 Tage';

  @override
  String get statsLast30Days => 'Letzten 30 Tage';

  @override
  String get statsThisYearTitle => 'Dieses Jahr';

  @override
  String get statsSectionsTitle => 'Kategorien';

  @override
  String get statsSectionTimePeriods => 'Zeiträume';

  @override
  String get statsHeatmapLess => 'Weniger';

  @override
  String get statsHeatmapMore => 'Mehr';

  @override
  String get statsDayOfWeek => 'Durchschnitt nach Wochentag';

  @override
  String get statsTimeSavedLabel => 'Nach Geschwindigkeit gespeichert';

  @override
  String statsTimeSavedSince(String date) {
    return 'seit $date';
  }

  @override
  String get statsTimeSavedReset => 'Gesparte Zeit zurücksetzen';

  @override
  String get statsTimeSavedResetConfirm =>
      'Die gesparte Zeit beginnt ab heute wieder zu zählen.';

  @override
  String get statsTimeSavedResetDone => 'Gesparte Zeit zurückgesetzt';

  @override
  String statsOnPaceFor(int count) {
    return 'Auf Kurs für $count Bücher';
  }

  @override
  String get statsDaysActive => 'Aktive Tage';

  @override
  String get statsDailyAverage => 'Täglicher Durchschnitt';

  @override
  String get statsLast7Days => 'Letzte 7 Tage';

  @override
  String get statsMostListened => 'Meistgehört';

  @override
  String get statsRecentSessions => 'Letzte Sitzungen';

  @override
  String get appShellHomeTab => 'Start';

  @override
  String get appShellLibraryTab => 'Bibliothek';

  @override
  String get appShellAbsorbingTab => 'Absorbing';

  @override
  String get appShellStatsTab => 'Statistiken';

  @override
  String get appShellSettingsTab => 'Einstellungen';

  @override
  String get appShellDiscoverTab => 'Entdecken';

  @override
  String get appShellShowsTab => 'Sendungen';

  @override
  String get appShellPodcastsTab => 'Podcasts';

  @override
  String get libraryTabEpisodes => 'Folgen';

  @override
  String get filterAllEpisodes => 'Alle';

  @override
  String get filterUnplayed => 'Ungespielt';

  @override
  String get episodeFeedEmpty => 'Keine Folgen entsprechen diesem Filter';

  @override
  String get podcastFilterUpNext => 'Als Nächstes';

  @override
  String get podcastFilterNew => 'Neu';

  @override
  String get settingsPodcastTab => 'Podcast-Tab';

  @override
  String get settingsPodcastTabDesc =>
      'Gib einer Podcast-Bibliothek einen eigenen Tab in der unteren Leiste';

  @override
  String get settingsPodcastTabLibrary => 'Podcasts Registerkarte';

  @override
  String get settingsStatsTab => 'Statistik Tab';

  @override
  String get settingsStatsTabDesc =>
      'Statistiken in der unteren Leiste anzeigen. Deaktivieren Sie diese Option, um auf einem kleinen Bildschirm mehr Platz zu schaffen.';

  @override
  String get settingsOpenStats => 'Statistiken öffnen';

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
      'Immer eingeschaltet, während der Podcasts-Tab aktiviert ist';

  @override
  String get settingsEpisodeNotifs => 'Benachrichtigungseinstellungen';

  @override
  String get settingsEpisodeNotifsDesc =>
      'Neue Podcast-Episoden, bevorstehende Buchveröffentlichungen und BookOrbit-Benachrichtigungen – im Hintergrund überprüft';

  @override
  String get notifIntervalOff => 'Aus';

  @override
  String notifIntervalMinutes(int n) {
    return 'Alle $n Minuten';
  }

  @override
  String get notifIntervalHour => 'Jede Stunde';

  @override
  String notifIntervalHours(int n) {
    return 'Alle $n Stunden';
  }

  @override
  String get settingsBatteryUnrestricted =>
      'Unbeschränkten Akkuverbrauch zulassen';

  @override
  String get settingsBatteryUnrestrictedDesc =>
      'Hindert das System daran, Hintergrundüberprüfungen auf einigen Telefonen anzuhalten';

  @override
  String get appShellPressBackToExit => 'Erneut zurück drücken zum Beenden';

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get sectionAppearance => 'Darstellung';

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
  String get languageLabel => 'Sprache';

  @override
  String get languageSystemDefault => 'Systemstandard';

  @override
  String get languageHelpTranslateInvite =>
      'Möchtest du Absorb in deine Sprache übersetzen?';

  @override
  String get themeLabel => 'Theme';

  @override
  String get themeDark => 'Dunkel';

  @override
  String get themeOled => 'OLED';

  @override
  String get themeLight => 'Hell';

  @override
  String get themeAuto => 'Automatisch';

  @override
  String get colorSourceLabel => 'Farbquelle';

  @override
  String get colorSourceCoverDescription =>
      'App-Farben richten sich nach dem Cover des aktuell laufenden Buchs';

  @override
  String get colorSourceWallpaperDescription =>
      'App-Farben richten sich nach deinem System-Hintergrundbild';

  @override
  String get colorSourceWallpaper => 'Hintergrundbild';

  @override
  String get colorSourceNowPlaying => 'Wiedergabe';

  @override
  String get colorSourceDynamic => 'Dynamisch';

  @override
  String get colorSourceManual => 'Manuell';

  @override
  String get colorSourceManualDescription => 'Wähle unten eine feste App-Farbe';

  @override
  String get colorSourceCustom => 'Benutzerdefiniert';

  @override
  String get useColorEverywhereLabel => 'Diese Farbe überall verwenden';

  @override
  String get useColorEverywhereSubtitle =>
      'Nutze die benutzerdefinierte Farbe statt der dynamischen für die Buchdetails und die Wiedergabekarten';

  @override
  String get flatBackgroundLabel => 'Flacher Hintergrund';

  @override
  String get flatBackgroundSubtitle =>
      'Hintergrundverlauf entfernen. Schwarz im Dunkelmodus für OLED-Bildschirme.';

  @override
  String get einkModeLabel => 'E-Ink Modus';

  @override
  String get einkModeSubtitle =>
      'Hoher Kontrast Schwarz und Weiß ohne Animationen, entwickelt für E-Ink-Bildschirme';

  @override
  String get einkModeIntroBody =>
      'Entwickelt für E-Ink-Displays. Die App wechselt zu einem flachen Schwarzweiß-Look mit hohem Kontrast. Animationen werden ausgeschaltet, die Abspiel-Karte verliert ihren Hintergrund und die Verbindung zum Server wird minimiert, um Batterie zu sparen. Wiedergabe und Fortschritt werden weiterhin normal synchronisiert. Deine Einstellungen zur Darstellung bleiben erhalten und werden wiederhergestellt, sobald du diese Einstellung deaktivierst.';

  @override
  String get einkModeIntroConfirm => 'Einschalten';

  @override
  String get backgroundIntensityLabel => 'Hintergrundintensität';

  @override
  String get startScreenLabel => 'Startbildschirm';

  @override
  String get startScreenSubtitle =>
      'Welcher Tab beim Start der App geöffnet wird';

  @override
  String get startScreenHome => 'Start';

  @override
  String get startScreenLibrary => 'Bibliothek';

  @override
  String get startScreenAbsorb => 'Absorb';

  @override
  String get startScreenStats => 'Statistiken';

  @override
  String get disablePageFade => 'Seiten-Überblendung deaktivieren';

  @override
  String get disablePageFadeOnSubtitle => 'Seiten wechseln sofort';

  @override
  String get disablePageFadeOffSubtitle =>
      'Seiten blenden beim Tab-Wechsel über';

  @override
  String get rectangleBookCovers => 'Rechteckige Buchcover';

  @override
  String get progressTextSize => 'Fortschritts-Textgröße';

  @override
  String get rectangleBookCoversOnSubtitle =>
      'Cover werden im 2:3-Buchformat angezeigt';

  @override
  String get rectangleBookCoversOffSubtitle => 'Cover sind quadratisch';

  @override
  String get coverSize => 'Cover Größe';

  @override
  String get coverSizeSubtitle => 'Anzahl der sichtbaren Cover';

  @override
  String get coverSizeSmall => 'Klein';

  @override
  String get coverSizeMedium => 'Mittel';

  @override
  String get coverSizeLarge => 'Groß';

  @override
  String get sectionAbsorbingCards => 'Absorbing-Karten';

  @override
  String get fullScreenPlayer => 'Vollbild-Player';

  @override
  String get fullScreenPlayerOnSubtitle =>
      'An - Bücher öffnen sich beim Abspielen im Vollbild';

  @override
  String get fullScreenPlayerOffSubtitle =>
      'Aus - Wiedergabe in der Kartenansicht';

  @override
  String get fullBookScrubber => 'Ganzes-Buch-Scrubber';

  @override
  String get fullBookScrubberOnSubtitle =>
      'An - durchziehbarer Slider über das gesamte Buch';

  @override
  String get fullBookScrubberOffSubtitle => 'Aus - nur Fortschrittsbalken';

  @override
  String get cardScrubbers => 'Fortschrittsanzeige';

  @override
  String get cardScrubbersBoth => 'Beides';

  @override
  String get cardScrubbersChapter => 'Kapitel';

  @override
  String get cardScrubbersLocked => 'Gesperrt';

  @override
  String get cardScrubbersBothSubtitle =>
      'Vollständige Buch- und Kapitelleisten können suchen';

  @override
  String get cardScrubbersChapterSubtitle =>
      'Nur die Kapitelleiste kann suchen';

  @override
  String get cardScrubbersLockedSubtitle =>
      'Fortschritt wird angezeigt, ohne zu suchen';

  @override
  String get speedAdjustedTime => 'Geschwindigkeitsangepasste Zeit';

  @override
  String get speedAdjustedTimeOnSubtitle =>
      'An - Alle Zeiten spiegeln deine Wiedergabegeschwindigkeit wider';

  @override
  String get speedAdjustedTimeOffSubtitle => 'Aus - zeigt die reine Audiodauer';

  @override
  String get buttonLayout => 'Button-Anordnung';

  @override
  String get buttonLayoutSubtitle =>
      'Wie die Aktions-Buttons auf der Karte angeordnet sind';

  @override
  String get whenAbsorbed => 'Beim Absorb';

  @override
  String get whenAbsorbedInfoTitle => 'Beim Absorb';

  @override
  String get whenAbsorbedInfoContent =>
      'Steuert, was mit einer Absorbing-Karte passiert, wenn du ein Buch oder eine Episode beendest.\n\nBeendete Karten werden automatisch von deinem Absorbing-Bildschirm entfernt.';

  @override
  String get whenAbsorbedSubtitle =>
      'Was mit der Absorbing-Karte passiert, wenn ein Buch oder eine Episode endet';

  @override
  String get whenAbsorbedShowOverlay => 'Overlay anzeigen';

  @override
  String get whenAbsorbedAutoRelease => 'Automatisch entfernen';

  @override
  String get mergeLibraries =>
      'Absorbing-Seite zeigt Inhalte aus allen Bibliotheken';

  @override
  String get mergeLibrariesInfoTitle => 'Bibliotheken zusammenführen';

  @override
  String get mergeLibrariesInfoContent =>
      'Wenn aktiviert, zeigt der Absorbing-Bildschirm alle deine angefangenen Bücher und Podcasts aus jeder Bibliothek in einer Ansicht. Wenn deaktiviert, werden nur Inhalte aus der aktuell ausgewählten Bibliothek angezeigt.';

  @override
  String get mergeLibrariesOnSubtitle => 'Bibliotheken zusammenführen';

  @override
  String get mergeLibrariesOffSubtitle =>
      'Absorbing-Seite zeigt nur die aktuelle Bibliothek';

  @override
  String get queueMode => 'Warteschlangenmodus';

  @override
  String get queueModeInfoTitle => 'Warteschlangenmodus';

  @override
  String get queueModeInfoOff => 'Aus';

  @override
  String get queueModeInfoOffDesc =>
      'Die Wiedergabe stoppt, wenn das aktuelle Buch oder die Episode endet.';

  @override
  String get queueModeInfoManual => 'Manuelle Warteschlange';

  @override
  String get queueModeInfoManualDesc =>
      'Elemente unter „Absorbing“ bilden deine manuelle Warteschlange. Sobald ein Element abgeschlossen ist, wird das nächste noch offene Element abgespielt. Füge ein Buch oder eine Episode über die Funktion „Zu Absorbing hinzufügen“ hinzu und ändere anschließend die Reihenfolge im Bereich „Warteschlange“.';

  @override
  String get queueModeOff => 'Aus';

  @override
  String get queueModeManual => 'Manuell';

  @override
  String get queueModeAuto => 'Auto';

  @override
  String get queueModePlaylist => 'Wiedergabeliste';

  @override
  String get queueModeCollection => 'Sammlung';

  @override
  String get queueModeInfoPlaylist => 'Playlist Warteschlange';

  @override
  String get queueModeInfoPlaylistDesc =>
      'Spielt von einer Wiedergabeliste alle Einträge der Reihenfolge nach ab und überspringt bereits abgeschlossene Elemente. Die Wiedergabe stoppt am Ende der Liste.';

  @override
  String get queuePlaylistPickerTitle => 'Wähle eine Playlist';

  @override
  String get queuePlaylistNone => 'Keine Wiedergabeliste ausgewählt';

  @override
  String queuePlaylistActiveLabel(String name) {
    return 'Wiedergabeliste: $name';
  }

  @override
  String get queueModePlaylistHint =>
      'Starte eine Wiedergabeliste-Warteschlange, indem du eine Wiedergabeliste auf der Startseite öffnest.';

  @override
  String get exit => 'Beenden';

  @override
  String upNext(String label) {
    return 'Als Nächstes: $label';
  }

  @override
  String get nothingUpNext => '\"Als Nächstes\" ist leer';

  @override
  String get showUpNextLabel =>
      '\"Als Nächstes\" auf der Absorbing Seite anzeigen';

  @override
  String get openSeries => 'Serie öffnen';

  @override
  String get openPlaylist => 'Playlist öffnen';

  @override
  String get openCollection => 'Sammlung öffnen';

  @override
  String get playlistPlayAction => 'Playlist abspielen';

  @override
  String get playlistAllFinished => 'Alle abgeschlossen';

  @override
  String get queueModeBooks => 'Bücher';

  @override
  String get queueModePodcasts => 'Podcasts';

  @override
  String get autoDownloadQueue => 'Auto-Download-Warteschlange';

  @override
  String get autoDownloadThisSeriesLabel =>
      'Diese Serie automatisch herunterladen';

  @override
  String get autoDownloadThisShowLabel =>
      'Diesen Podcast automatisch herunterladen';

  @override
  String get autoDownloadThisPlaylistLabel =>
      'Wiedergabeliste automatisch herunterladen';

  @override
  String get autoDownloadThisCollectionLabel =>
      'Diese Sammlung automatisch herunterladen';

  @override
  String autoDownloadQueueOnSubtitle(int count) {
    return 'Die nächsten $count Inhalte heruntergeladen halten';
  }

  @override
  String get autoDownloadQueueOffSubtitle => 'Aus - nur manuelle Downloads';

  @override
  String get sectionPlayback => 'Wiedergabe';

  @override
  String get sectionMediaControls => 'Mediensteuerung';

  @override
  String get defaultSpeed => 'Standardgeschwindigkeit';

  @override
  String get defaultSpeedSubtitle =>
      'Neue Bücher starten mit dieser Geschwindigkeit - jedes Buch merkt sich seine eigene';

  @override
  String get skipBack => 'Zurückspulen';

  @override
  String get skipForward => 'Vorspulen';

  @override
  String get iosLockScreenSkipHint =>
      'Auf dem Sperrbildschirm werden nur die Zahlen angezeigt, für die iOS Symbole bereithält (5, 10, 15, 30, 45, 60, 75, 90). Bei anderen Werten wird auf der Schaltfläche ein „+“ angezeigt, die Werte werden jedoch entsprechend der Einstellungen übersprungen.';

  @override
  String get longSkipButtons => 'Lange Überspringen Tasten';

  @override
  String get longSkipButtonsOnSubtitle =>
      'An - Der Player zeigt ein zweites, größeres Überspringen Paar';

  @override
  String get longSkipButtonsOffSubtitle =>
      'Aus - nur die regulären Überspringen Schaltflächen';

  @override
  String get longSkipBack => 'Langes Zurückspringen';

  @override
  String get longSkipForward => 'Langes Vorwärtsspringen';

  @override
  String get coverShapeDefault => 'Standard';

  @override
  String get coverShapeSquare => 'Quadratisch';

  @override
  String get coverShapeRectangle => 'Rechteck';

  @override
  String get coverShapeLabel => 'Cover Format';

  @override
  String get showSubtitles => 'Untertitel anzeigen';

  @override
  String get showSubtitlesOnSubtitle =>
      'Untertitel wird unter dem Buchtitel in der Bibliothek und auf dem Start-Bildschirm angezeigt';

  @override
  String get showSubtitlesOffSubtitle =>
      'Aus - Untertitel nur bei den Buchdetails';

  @override
  String get subtitleVisibilityLabel => 'Untertitel';

  @override
  String get subtitleVisibilityDefault => 'Standard';

  @override
  String get subtitleVisibilityShow => 'Anzeigen';

  @override
  String get subtitleVisibilityHide => 'Ausblenden';

  @override
  String currentLibrarySettingsTitle(String name) {
    return 'Aktuelle Bibliothek: $name';
  }

  @override
  String get currentLibrarySkipOverride => 'Eigene Überspringen Länge';

  @override
  String get currentLibrarySkipOverrideOnSubtitle =>
      'An - diese Bibliothek verwendet eigene Überspringen-längen';

  @override
  String get currentLibrarySkipOverrideOffSubtitle =>
      'Aus - diese Bibliothek verwendet die globalen Überspringen-längen';

  @override
  String get currentLibrarySpeedOverride => 'Eigene Standardgeschwindigkeit';

  @override
  String get currentLibrarySpeedOverrideOnSubtitle =>
      'An - neue Elemente in dieser Bibliothek starten mit eigener Geschwindigkeit';

  @override
  String get currentLibrarySpeedOverrideOffSubtitle =>
      'Aus - neue Elemente in dieser Bibliothek starten bei der globalen Standardgeschwindigkeit';

  @override
  String get currentLibrarySpeed => 'Standardgeschwindigkeit';

  @override
  String get currentLibrarySkipBack => 'Zurückspringen';

  @override
  String get currentLibrarySkipForward => 'Vorwärts springen';

  @override
  String get chapterProgressInNotification =>
      'Kapitelfortschritt in Benachrichtigung & Android Auto';

  @override
  String get chapterProgressOnSubtitle =>
      'An - Benachrichtigung & Android Auto zeigen Kapitel Fortschritt';

  @override
  String get chapterProgressOffSubtitle =>
      'Aus - Gesamtfortschritt des Buches wird angezeigt';

  @override
  String get chapterProgressInNotificationIos =>
      'Kapitel Fortschritt auf Sperrbildschirm & CarPlay';

  @override
  String get chapterProgressOnSubtitleIos =>
      'An - Sperrbildschirm & CarPlay zeigen Kapitel Fortschritt';

  @override
  String get chapterProgressInNowPlayingBar =>
      'Kapitelfortschritt in der Wiedergabeleiste';

  @override
  String get chapterProgressInNowPlayingBarOnSubtitle =>
      'Ein – der Player unten zeigt den aktuellen Fortschritt im Kapitel an';

  @override
  String get chapterProgressInNowPlayingBarOffSubtitle =>
      'Aus – der Player unten zeigt den aktuellen Fortschritt im gesamten Buch an';

  @override
  String get nowPlayingText => 'Text der aktuellen Wiedergabe';

  @override
  String get nowPlayingTextSubtitle =>
      'Wähle aus, was in den Mediensteuerelementen in der jeweiligen Zeile angezeigt wird';

  @override
  String get nowPlayingTopLine => 'Obere Zeile';

  @override
  String get nowPlayingSecondLine => 'Zweite Zeile';

  @override
  String get nowPlayingNotShown => 'Nicht angezeigt';

  @override
  String get nowPlayingTopLineRequired =>
      'Die obere Zeile benötigt mindestens ein Element';

  @override
  String get nowPlayingPieceChapter => 'Kapitel';

  @override
  String get nowPlayingPieceTitle => 'Buchtitel';

  @override
  String get nowPlayingPieceNarrator => 'Erzähler';

  @override
  String get nowPlayingPieceSeries => 'Serien';

  @override
  String get nowPlayingPiecePercent => 'Buch-Prozentsatz';

  @override
  String get nowPlayingPieceChapterNumber => 'Kapitelnummer';

  @override
  String get nowPlayingPieceTimeLeft => 'Restzeit';

  @override
  String nowPlayingChapterNumber(int number, int total) {
    return 'K. $number/$total';
  }

  @override
  String nowPlayingTimeLeft(String time) {
    return '$time übrig';
  }

  @override
  String get bookDockBadgePending => 'Ausstehend';

  @override
  String get bookDockBadgeExtracting => 'Lese Datei';

  @override
  String get bookDockBadgeFetching => 'Wird gesucht';

  @override
  String get bookDockBadgeError => 'Fehler';

  @override
  String get bookDockNeedsReview => 'Prüfung erforderlich';

  @override
  String get bookDockNoMatch => 'Keine Übereinstimmung';

  @override
  String get bookDockApplied => 'Angewandt';

  @override
  String get bookDockNotApplied => 'Gefunden Details nicht verwendet';

  @override
  String get bookDockNoDestination => 'Kein Ziel gesetzt';

  @override
  String get bookDockNoAuthor => 'Noch kein Autor';

  @override
  String get bookDockLookUpAgain => 'Erneut nachschlagen';

  @override
  String get bookDockLookingUp => 'Details werden erneut nachgeschlagen';

  @override
  String get bookDockLookUpFailed => 'Details konnten nicht gefunden werden';

  @override
  String get bookDockProposedChanges => 'Vorgeschlagene Änderungen';

  @override
  String get bookDockNoChanges => 'Noch keine Details online gefunden';

  @override
  String get bookDockStillReading =>
      'Der Server liest diese Datei immer noch aus';

  @override
  String get bookDockRoleBook => 'Buch';

  @override
  String get bookDockRoleCover => 'Cover';

  @override
  String get bookDockRoleMetadata => 'Metadaten';

  @override
  String get bookDockRoleExtra => 'Extra';

  @override
  String get bookDockFieldTitle => 'Titel';

  @override
  String get bookDockFieldSubtitle => 'Untertitel';

  @override
  String get bookDockFieldAuthors => 'Autoren';

  @override
  String get bookDockFieldSeries => 'Serien';

  @override
  String get bookDockFieldPublisher => 'Verlag';

  @override
  String get bookDockFieldYear => 'Jahr';

  @override
  String get bookDockFieldLanguage => 'Sprache';

  @override
  String get bookDockFieldIsbn => 'ISBN';

  @override
  String bookDockMatch(int percent) {
    return '$percent % Übereinstimmung';
  }

  @override
  String bookDockFileCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Dateien',
      one: '1 Datei',
    );
    return '$_temp0';
  }

  @override
  String bookDockGoesTo(String library) {
    return 'Gehe zu $library';
  }

  @override
  String bookDockChangedFields(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Felder',
      one: '1 Feld',
    );
    return '$_temp0';
  }

  @override
  String bookDockFilesInEntry(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Dateien in diesem Eintrag',
      one: 'Datei in diesem Eintrag',
    );
    return '$_temp0';
  }

  @override
  String bookDockAdded(String date) {
    return 'Hinzugefügt $date';
  }

  @override
  String get bookDockAddToLibrary => 'Zur Bibliothek hinzufügen';

  @override
  String get bookDockUseFound => 'Gefundene Details verwenden';

  @override
  String get bookDockRemoveTitle => 'Vom Buch-Dock entfernen?';

  @override
  String get bookDockRemoveFailed => 'Diese Datei konnte nicht entfernt werden';

  @override
  String get bookDockPickLibrary => 'Zu welcher Bibliothek hinzufügen?';

  @override
  String get bookDockNoLibraries =>
      'Dein Konto kann keine Bücher zu einer Bibliothek hinzufügen';

  @override
  String get bookDockFileFailed =>
      'Diese Datei konnte nicht zur Bibliothek hinzugefügt werden';

  @override
  String get bookDockDuplicateBody =>
      'Eine Datei mit diesem Namen ist bereits in dieser Bibliothek vorhanden. Aus dem Buch-Dock entfernen?';

  @override
  String get bookDockDetailsUpdated => 'Details aktualisiert';

  @override
  String get bookDockUseFoundFailed =>
      'Es wurden keine verwertbaren Details gefunden';

  @override
  String bookDockRemoveBody(String title) {
    return 'Dies löscht $title auf dem Server.';
  }

  @override
  String bookDockRemoved(String title) {
    return '$title wurde aus dem Buch Dock entfernt';
  }

  @override
  String bookDockFiled(String title, String library) {
    return '$title zu $library hinzugefügt';
  }

  @override
  String bookDockFileFailedReason(String reason) {
    return 'Datei konnte nicht hinzugefügt werden: $reason';
  }

  @override
  String bookDockDuplicateTitle(String library) {
    return 'Bereits in $library';
  }

  @override
  String get bomatchSearchAll => 'Alle Quellen durchsuchen';

  @override
  String get bomatchSearching => 'Suche läuft...';

  @override
  String get bomatchSearchFailed =>
      'Suche nicht möglich. Überprüfe deine Verbindung und versuche es erneut.';

  @override
  String get bomatchNoResults => 'Keine Treffer gefunden';

  @override
  String get bomatchStrong => 'Starke Treffer';

  @override
  String get bomatchPossible => 'Mögliche Treffer';

  @override
  String get bomatchSourceTimeout => 'Zeitüberschreitung';

  @override
  String get bomatchSourceBusy => 'beschäftigt';

  @override
  String get bomatchSourceFailed => 'fehlgeschlagen';

  @override
  String get bomatchLinked => 'verknüpft';

  @override
  String get bomatchSameIsbn => 'Gleiche ISBN';

  @override
  String get bomatchFewDetails => 'Wenig Details';

  @override
  String get bomatchBack => 'Alle Ergebnisse';

  @override
  String get bomatchFillEmpty => 'Feld leer';

  @override
  String get bomatchTakeAll => 'Alles nehmen';

  @override
  String get bomatchOnlyDifferences => 'Nur Unterschiede';

  @override
  String get bomatchNow => 'Jetzt';

  @override
  String get bomatchEmpty => 'Leer';

  @override
  String get bomatchKindNew => 'Neu';

  @override
  String get bomatchKindChange => 'Ändern';

  @override
  String get bomatchKindSmall => 'Kleine Änderung';

  @override
  String get bomatchKindSame => 'Das Gleiche';

  @override
  String get bomatchKindNone => 'Nicht im Ergebnis';

  @override
  String get bomatchKeep => 'Behalten';

  @override
  String get bomatchUse => 'Verwenden';

  @override
  String get bomatchMerge => 'Zusammenführen';

  @override
  String get bomatchReplace => 'Ersetzen';

  @override
  String get bomatchUseThis => 'Dies verwenden';

  @override
  String get bomatchChosen => 'Ausgewählt';

  @override
  String bomatchOther(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count andere Bücher',
      one: '1 anderes Buch',
    );
    return '$_temp0';
  }

  @override
  String bomatchChanged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Änderungen',
      one: '1 Änderung',
    );
    return '$_temp0';
  }

  @override
  String bomatchNew(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count neue',
      one: '1 neu',
    );
    return '$_temp0';
  }

  @override
  String bomatchApply(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Änderungen anwenden',
      one: '1 Änderung anwenden',
      zero: 'Anwenden',
    );
    return '$_temp0';
  }

  @override
  String bomatchOtherSources(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count weitere Quellen',
      one: '1 weitere Quelle',
    );
    return '$_temp0';
  }

  @override
  String bomatchFrom(String source) {
    return 'Von $source';
  }

  @override
  String get breqTitle => 'Buchanfragen';

  @override
  String get breqTabRequest => 'Buch anfragen';

  @override
  String get breqTabMine => 'Meine Anfragen';

  @override
  String get breqTabAll => 'Alle Anfragen';

  @override
  String get breqNoAccess =>
      'Ihr Konto kann keine Bücher auf diesem Server anfordern.';

  @override
  String get breqTitleHint => 'Buchtitel';

  @override
  String get breqAuthorHint => 'Autor';

  @override
  String get breqKindAudiobook => 'Hörbuch';

  @override
  String get breqKindEbook => 'E-Book';

  @override
  String get breqKindComic => 'Comic';

  @override
  String get breqSearch => 'Suche';

  @override
  String get breqSearching => 'Sucht...';

  @override
  String get breqSearchFailed =>
      'Suche nicht möglich. Überprüfe deine Verbindung und versuche es erneut.';

  @override
  String get breqSearchPrompt =>
      'Suche nach einem Buch, das noch nicht in der Bibliothek vorhanden ist, um dieses anzufordern.';

  @override
  String get breqNoResults => 'Keine passenden Bücher gefunden';

  @override
  String get breqInLibrary => 'In deiner Bibliothek';

  @override
  String get breqYouAsked => 'Du hast dies angefordert';

  @override
  String get breqSomeoneAsked => 'Bereits von jemand anderem angefragt';

  @override
  String get breqView => 'Anzeigen';

  @override
  String get breqRequest => 'Anfragen';

  @override
  String get breqRequested => 'Angefordert';

  @override
  String get breqAddMeToo => 'Auch mich hinzufügen';

  @override
  String get breqLibrary => 'Bibliothek';

  @override
  String get breqLibraryApprover => 'Den Genehmiger entscheiden lassen';

  @override
  String get breqLibraryChoose => 'Eine Bibliothek auswählen';

  @override
  String get breqNote => 'Hinweis an den Genehmiger';

  @override
  String get breqNoteHint => 'Alles Wissenswerte zu dieser Anfrage';

  @override
  String get breqAutoApproved => 'Deine Anfragen werden sofort bearbeitet.';

  @override
  String get breqSubmitted => 'Anfrage übermittelt';

  @override
  String get breqJoined => 'Du wurdest zur bestehenden Anfrage hinzugefügt';

  @override
  String get breqFailed => 'Anfrage konnte nicht gesendet werden';

  @override
  String get breqStatusPending => 'Ausstehend';

  @override
  String get breqStatusApproved => 'Bestätigt';

  @override
  String get breqStatusRejected => 'Abgelehnt';

  @override
  String get breqStatusCancelled => 'Abgebrochen';

  @override
  String get breqStatusSearching => 'Sucht';

  @override
  String get breqStatusGrabbed => 'Release gefunden';

  @override
  String get breqStatusDownloading => 'Wird heruntergeladen';

  @override
  String get breqStatusImporting => 'Importieren';

  @override
  String get breqStatusNeedsReview => 'Prüfung erforderlich';

  @override
  String get breqStatusAvailable => 'Verfügbar';

  @override
  String get breqStatusFailed => 'Fehlgeschlagen';

  @override
  String get breqWaitingApproval => 'Wartet auf Freigabe';

  @override
  String get breqWaitingRelease => 'Wartet auf die Auswahl eines Releases';

  @override
  String get breqLookingForRelease =>
      'Auf der Suche nach einer Veröffentlichung';

  @override
  String get breqStartingDownload => 'Download wird gestartet';

  @override
  String get breqAddingToLibrary => 'Zur Bibliothek hinzufügen';

  @override
  String get breqWaitingCheck => 'Warten auf eine manuelle Überprüfung';

  @override
  String get breqReady => 'Bereit in deiner Bibliothek';

  @override
  String get breqSomethingWrong => 'Ein Fehler ist aufgetreten';

  @override
  String get breqShowHidden => 'Ausgeblendete anzeigen';

  @override
  String get breqHidden => 'Ausgeblendet';

  @override
  String get breqMineEmpty => 'Du hast bisher keine Bücher angefragt.';

  @override
  String get breqAllEmpty => 'Noch keine Anfragen.';

  @override
  String get breqLoadFailed => 'Anfragen konnten nicht geladen werden.';

  @override
  String get breqLoadMore => 'Mehr laden';

  @override
  String get breqApprove => 'Genehmigen';

  @override
  String get breqReject => 'Ablehnen';

  @override
  String get breqCancel => 'Anfrage stornieren';

  @override
  String get breqHide => 'Aus meiner Liste ausblenden';

  @override
  String get breqUnhide => 'In meiner Liste anzeigen';

  @override
  String get breqLeave => 'Anfrage einreichen';

  @override
  String get breqDelete => 'Anfrage löschen';

  @override
  String get breqOpenBook => 'Buch öffnen';

  @override
  String get breqCancelConfirm =>
      'Diese Anfrage abbrechen? Ein Download wird ebenfalls beendet.';

  @override
  String get breqDeleteConfirm =>
      'Diese Anfrage löschen? Der Vorgang kann nicht rückgängig gemacht werden.';

  @override
  String get breqRejectTitle => 'Anfrage ablehnen';

  @override
  String get breqRejectReason => 'Grund (optional)';

  @override
  String get breqApproveTitle => 'Anfrage genehmigen';

  @override
  String get breqApproveLibraryNeeded =>
      'Wähle die Bibliothek, in die dieses Buch geht.';

  @override
  String get breqApprovedToast => 'Anfrage genehmigt';

  @override
  String get breqRejectedToast => 'Anfrage abgelehnt';

  @override
  String get breqCancelledToast => 'Anfrage storniert';

  @override
  String get breqHiddenToast => 'Aus deiner Liste ausgeblendet';

  @override
  String get breqRestoredToast => 'Wiederhergestellt';

  @override
  String get breqDeletedToast => 'Anfrage gelöscht';

  @override
  String get breqLeftToast => 'Du hast diese Anfrage eingereicht';

  @override
  String get breqActionFailed => 'Anfrage konnte nicht aktualisiert werden';

  @override
  String get breqFactRequestedBy => 'Angefragt von';

  @override
  String get breqFactRequestedOn => 'Angefragt am';

  @override
  String get breqFactLibrary => 'Bibliothek';

  @override
  String get breqFactDecidedBy => 'Entschieden von';

  @override
  String get breqFactNote => 'Anmerkung vom Anfragendem';

  @override
  String get breqFactDecisionNote => 'Entscheidungsgrund';

  @override
  String get breqFactAlsoWanted => 'Auch gewünscht von';

  @override
  String get breqLibraryCta => 'Buch anfragen';

  @override
  String get breqSettingsSubtitle =>
      'Bücher anfragen, die noch nicht in der Bibliothek sind';

  @override
  String get navHoldBookRequests => 'Buchanfragen';

  @override
  String breqLibraryDefault(String library) {
    return 'Standard ($library)';
  }

  @override
  String breqFailedReason(String reason) {
    return 'Anfrage konnte nicht gesendet werden: $reason';
  }

  @override
  String breqBookCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Bücher',
      one: '1 Buch',
    );
    return '$_temp0';
  }

  @override
  String breqDownloadingPercent(int percent) {
    return 'Wird heruntergeladen: $percent%';
  }

  @override
  String breqAddedTo(String library) {
    return 'Zu \"$library\" hinzugefügt';
  }

  @override
  String breqRejectedWithNote(String note) {
    return 'Abgelehnt: $note';
  }

  @override
  String breqFailedWithReason(String reason) {
    return 'Fehler: $reason';
  }

  @override
  String breqRequestedBy(String name) {
    return 'Angefragt von $name';
  }

  @override
  String breqActionFailedReason(String reason) {
    return 'Die Anfrage konnte nicht aktualisiert werden: $reason';
  }

  @override
  String breqFooterCta(String query) {
    return '\"$query\" anfragen';
  }

  @override
  String breqCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Anfragen',
      one: '1 Anfrage',
      zero: 'Keine Anfragen',
    );
    return '$_temp0';
  }

  @override
  String get breqFindRelease => 'Finde eine Version';

  @override
  String get breqTryAnotherRelease => 'Versuche es mit einer anderen Version';

  @override
  String get breqApproveAndFind => 'Freigabe und finde eine Version';

  @override
  String get breqReviewButton => 'Download überprüfen';

  @override
  String get breqStopDownload => 'Download anhalten';

  @override
  String get breqStopDownloadConfirm =>
      'Diesen Download abbrechen? Die Anfrage wird auf den Status „genehmigt“ zurückgesetzt, sodass eine andere Version ausgewählt werden kann.';

  @override
  String get breqDiscardImport => 'Download verwerfen';

  @override
  String get breqDiscardConfirm =>
      'Diesen Download verwerfen? Die Anfrage ist als fehlgeschlagen markiert und kann mit einer anderen Version erneut versucht werden.';

  @override
  String get breqFileAnyway => 'Zur Bibliothek hinzufügen';

  @override
  String get breqFiledToast => 'Zur Bibliothek hinzugefügt';

  @override
  String get breqDiscardedToast => 'Download abgebrochen';

  @override
  String get breqStoppedToast => 'Download unterbrochen';

  @override
  String get breqGrabTitle => 'Diese Version herunterladen?';

  @override
  String get breqGrab => 'Herunterladen';

  @override
  String get breqGrabbed => 'Download gestartet';

  @override
  String get breqGrabFailed => 'Der Download konnte nicht gestartet werden';

  @override
  String get breqReleaseVipWarning =>
      'Dieser Tracker erlaubt es nur VIP-Konten ihn herunterzuladen.';

  @override
  String get breqReleaseNoBookFile =>
      'Diese Version hat keine Buchdatei, die BookOrbit einer Bibliothek hinzufügen kann.';

  @override
  String get breqReleaseCheckFailed =>
      'Der Inhalt dieser Version konnte nicht überprüft werden. Versuche es erneut oder wähle eine andere aus.';

  @override
  String get breqCheckingRelease => 'Dateien werden geprüft...';

  @override
  String get breqSearchAgain => 'Nochmal suchen';

  @override
  String get breqSearchTerms => 'Suchbegriffe';

  @override
  String get breqIsbnHint => 'Leer lassen, um nach Titel und Autor zu suchen';

  @override
  String get breqSearchingIndexers =>
      'Deine Indexer werden durchsucht. Dies kann bis zu einer Minute dauern.';

  @override
  String get breqReleasesFailed =>
      'Es konnte nicht nach Veröffentlichungen gesucht werden.';

  @override
  String get breqNoSourcesSetUp =>
      'In BookOrbit sind keine Suchquellen eingerichtet.';

  @override
  String get breqNoSourcesOn => 'In BookOrbit ist jede Suchquelle deaktiviert.';

  @override
  String get breqNoSourceCarries =>
      'Keine deiner Suchquellen führt diese Art von Buch.';

  @override
  String get breqNoReleases =>
      'Keine Veröffentlichungen gefunden. Versuchen Sie es mit anderen Suchbegriffen.';

  @override
  String get breqFromCache => 'aus einer kürzlichen Suche';

  @override
  String get breqIndexerUnauthorized => 'Anmeldung fehlgeschlagen';

  @override
  String get breqIndexerThrottled => 'Beschäftigt';

  @override
  String get breqIndexerTimeout => 'Zeitüberschreitung';

  @override
  String get breqIndexerUnreachable => 'Nicht erreichbar';

  @override
  String get breqIndexerNoMedium => 'trägt dies nicht';

  @override
  String get breqIndexerError => 'fehlgeschlagen';

  @override
  String get breqSortBest => 'Beste Übereinstimmung';

  @override
  String get breqSortSeeders => 'Seeder';

  @override
  String get breqSortSize => 'Größe';

  @override
  String get breqSortNewest => 'Neueste';

  @override
  String get breqFreeleech => 'Freeleech';

  @override
  String get breqVipOnly => 'Nur für VIP';

  @override
  String get breqAlreadyGrabbed => 'Bereits heruntergeladen';

  @override
  String get breqReasonIsbn => 'ISBN';

  @override
  String get breqReasonTitle => 'Titel';

  @override
  String get breqReasonAuthor => 'Autor';

  @override
  String get breqReasonUnknownFormat => 'Unbekanntes Format';

  @override
  String get breqReasonExpectedSize => 'Größe';

  @override
  String get breqReasonSuspiciousSize => 'Ungewöhnliche Größe';

  @override
  String get breqReasonFreeleech => 'Freeleech';

  @override
  String get breqReasonSeveralBooks => 'Mehrere Bücher';

  @override
  String get breqReviewTitle => 'Download wartet auf Überprüfung';

  @override
  String get breqReviewFailed =>
      'Die Downloaddetails konnten nicht geladen werden.';

  @override
  String get breqReviewDockGone =>
      'Die heruntergeladenen Dateien befinden sich nicht mehr im Book Dock.';

  @override
  String get breqReviewNoLibrary =>
      'Diese Anfrage hat keine Bibliothek, zu der das Buch hinzugefügt werden kann.';

  @override
  String breqGrabFailedReason(String reason) {
    return 'Der Download konnte nicht gestartet werden: $reason';
  }

  @override
  String breqReleaseCheckFailedReason(String reason) {
    return 'Konnte nicht überprüfen, was in dieser Version ist: $reason';
  }

  @override
  String breqReleasesFailedReason(String reason) {
    return 'Suche nach Veröffentlichungen nicht möglich: $reason';
  }

  @override
  String breqReviewFailedReason(String reason) {
    return 'Die Download-Details konnten nicht geladen werden: $reason';
  }

  @override
  String breqReleaseCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Veröffentlichungen',
      one: '1 Veröffentlichung',
      zero: 'Keine Veröffentlichungen',
    );
    return '$_temp0';
  }

  @override
  String breqFileCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Dateien',
      one: '1 Datei',
    );
    return '$_temp0';
  }

  @override
  String breqReviewFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Dateien',
      one: '1 Datei',
    );
    return '$_temp0';
  }

  @override
  String breqSeeders(int seeders, int leechers) {
    return '$seeders Seeder, $leechers Leecher';
  }

  @override
  String breqScore(int score) {
    return 'Ergebnis $score';
  }

  @override
  String breqReasonPreferredFormat(String format) {
    return 'Bevorzugtes $format';
  }

  @override
  String breqReasonFormat(String format) {
    return '$format';
  }

  @override
  String breqReasonSeeders(String count) {
    return '$count Seeder';
  }

  @override
  String breqReviewScore(int score, int threshold) {
    return 'Übereinstimmungswert $score. Downloads mit einem Wert von $threshold oder mehr werden separat hinzugefügt.';
  }

  @override
  String breqReviewRequested(String value) {
    return 'Angefragt: $value';
  }

  @override
  String breqReviewImported(String value) {
    return 'Heruntergeladen: $value';
  }

  @override
  String get breqKindBoth => 'Beide';

  @override
  String get breqEbookLibrary => 'E-Book-Bibliothek';

  @override
  String get breqAudiobookLibrary => 'Hörbuch-Bibliothek';

  @override
  String get breqRequestBoth => 'Beide anfordern';

  @override
  String get breqAddMeToBoth => 'Zu beiden hinzufügen';

  @override
  String get breqRequestEbook => 'E-Book anfragen';

  @override
  String get breqRequestAudiobook => 'Hörbuch anfordern';

  @override
  String get breqAddMeEbook => 'Füge mich zur E-Book-Anfrage hinzu';

  @override
  String get breqAddMeAudiobook => 'Füge mich zur Hörbuch-Anfrage hinzu';

  @override
  String get breqPairSubmitted => 'Das E-Book und Hörbuch wurden angefordert';

  @override
  String get breqPairOneJoined =>
      'Habe beides angefordert. Eines war bereits auf dem Weg, daher wurdest du dieser Anfrage hinzugefügt';

  @override
  String get breqJoinedBoth => 'Du wurdest zu beiden Anfragen hinzugefügt';

  @override
  String get breqJoinsOwned =>
      'Angefordert. Es wird dem Exemplar hinzugefügt, das sich bereits in deiner Bibliothek befindet';

  @override
  String get speedBookmarkInControls =>
      'Geschwindigkeit & Lesezeichen in Mediensteuerung';

  @override
  String get speedBookmarkOnSubtitle =>
      'An - Benachrichtigung zeigt Geschwindigkeit & Lesezeichen; Kapitel Überspringen bleibt in Android Auto';

  @override
  String get speedBookmarkOffSubtitle =>
      'Aus - Benachrichtigung zeigt Kapitel-Überspringen; Geschwindigkeit & Lesezeichen bleiben in Android Auto';

  @override
  String get lockSeekBar => 'Suchleiste sperren';

  @override
  String get lockSeekBarOnSubtitle =>
      'An - Der Fortschrittsregler wird in den Benachrichtigungen, Sperrbildschirm und Auto angezeigt, ist aber nicht verschiebbar';

  @override
  String get lockSeekBarOffSubtitle =>
      'Aus - Verschiebe den Fortschrittsregler in den Benachrichtigungen, Sperrbildschirm und Auto zum umherspringen';

  @override
  String get autoRewindOnResume => 'Auto-Zurückspulen beim Fortsetzen';

  @override
  String autoRewindOnSubtitle(String min, String max) {
    return 'An - ${min}s bis ${max}s je nach Pausendauer';
  }

  @override
  String get autoRewindOffSubtitle => 'Aus';

  @override
  String get rewindRange => 'Rückspulbereich';

  @override
  String get rewindAfterPausedFor => 'Zurückspulen nach Pause von';

  @override
  String get rewindAnyPause => 'Jede Pause';

  @override
  String get rewindAlwaysLabel => 'Immer';

  @override
  String get rewindAlwaysDescription =>
      'Spult jedes Mal beim Fortsetzen zurück, auch nach kurzen Unterbrechungen';

  @override
  String rewindAfterDescription(String seconds) {
    return 'Spult nur zurück, wenn länger als $seconds Sekunden pausiert wurde';
  }

  @override
  String get chapterBarrier => 'Kapitelgrenze';

  @override
  String get chapterBarrierSubtitle =>
      'Nicht über den Anfang des aktuellen Kapitels hinaus zurückspulen';

  @override
  String get rewindInstant => 'Sofort';

  @override
  String rewindPause(String duration) {
    return '$duration Pause';
  }

  @override
  String get rewindNoRewind => 'kein Rückspulen';

  @override
  String rewindSeconds(String seconds) {
    return '${seconds}s zurückspulen';
  }

  @override
  String get sectionSleepTimer => 'Sleep-Timer';

  @override
  String get sleep => 'Sleep';

  @override
  String get sleepTimer => 'Sleep-Timer';

  @override
  String get shakeDuringSleepTimer => 'Schütteln während Sleep-Timer';

  @override
  String get shakeOff => 'Aus';

  @override
  String get shakeAddTime => 'Zeit hinzufügen';

  @override
  String get shakeReset => 'Zurücksetzen';

  @override
  String get shakeAdds => 'Schütteln fügt hinzu';

  @override
  String get sleepAddAmount => 'Zeit hinzufügen';

  @override
  String shakeAddsValue(int minutes) {
    return '$minutes Min.';
  }

  @override
  String get shakeSensitivity => 'Schüttel-Empfindlichkeit';

  @override
  String get shakeSensitivityVeryLow => 'Sehr niedrig';

  @override
  String get shakeSensitivityLow => 'Niedrig';

  @override
  String get shakeSensitivityMedium => 'Mittel';

  @override
  String get shakeSensitivityHigh => 'Hoch';

  @override
  String get shakeSensitivityVeryHigh => 'Sehr hoch';

  @override
  String get buttonDuringSleepTimer => 'Kopfhörer-Taste beim Abschalten';

  @override
  String get buttonDuringSleepTimerHint =>
      'In der abschließenden Abschaltphase setzt ein einmaliges Drücken den Timer zurück, anstatt ihn zu pausieren. Zweimaliges Drücken bewirkt weiterhin ein Überspringen.';

  @override
  String get resetTimerOnPause => 'Timer bei Pause zurücksetzen';

  @override
  String get resetTimerOnPauseOnSubtitle =>
      'Timer startet bei Fortsetzung von der vollen Dauer neu';

  @override
  String get resetTimerOnPauseOffSubtitle =>
      'Timer läuft dort weiter, wo er aufgehört hat';

  @override
  String get fadeVolumeBeforeSleep => 'Lautstärke vor dem Sleep ausblenden';

  @override
  String get fadeVolumeOnSubtitle =>
      'Senkt die Lautstärke in den letzten 30 Sekunden allmählich ab';

  @override
  String get fadeVolumeOffSubtitle =>
      'Wiedergabe stoppt sofort, wenn der Timer endet';

  @override
  String get autoSleepTimer => 'Automatischer Sleep-Timer';

  @override
  String autoSleepTimerOnSubtitle(String start, String end, int duration) {
    return '$start - $end - $duration Min.';
  }

  @override
  String get autoSleepTimerOffSubtitle =>
      'Sleep-Timer in einem Zeitfenster automatisch starten';

  @override
  String get windowStart => 'Fensterbeginn';

  @override
  String get windowEnd => 'Fensterende';

  @override
  String get timerDuration => 'Timer-Dauer';

  @override
  String get timer => 'Timer';

  @override
  String get endOfChapter => 'Kapitelende';

  @override
  String startMinTimer(int minutes) {
    return '$minutes-Min.-Timer starten';
  }

  @override
  String sleepAfterChapters(int count, String label) {
    return 'Sleep nach $count $label';
  }

  @override
  String get addMoreTime => 'Mehr Zeit hinzufügen';

  @override
  String get cancelTimer => 'Timer abbrechen';

  @override
  String chaptersLeftCount(int count) {
    return '$count Kap. übrig';
  }

  @override
  String get sectionDownloadsAndStorage => 'Downloads & Speicher';

  @override
  String get downloadOverWifiOnly => 'Download Netzwerk';

  @override
  String get downloadOverWifiOnSubtitle => 'Nur über WLAN';

  @override
  String get downloadOverWifiOffSubtitle => 'Beliebige Verbindungsart';

  @override
  String get autoDownloadOnWifi =>
      'Automatisches Herunterladen von angefangenen Büchern';

  @override
  String get autoDownloadOnWifiInfoTitle =>
      'Automatisches Herunterladen von angefangenen Büchern';

  @override
  String get autoDownloadOnWifiInfoContent =>
      'Wenn du ein Hörbuch streamst, wird im Hintergrund automatisch das gesamte Buch zur Offline Nutzung heruntergeladen. Der Download beachtet deine obigen Einstellungen zum Download Netzwerk. Wähle \"Beliebige Verbindungsart\", wenn Downloads auch über die mobile Datenverbindung erfolgen sollen.';

  @override
  String get autoDownloadOnWifiOnSubtitle =>
      'Gestreamte Bücher laden im Hintergrund automatisch herunter';

  @override
  String get autoDownloadOnWifiOffSubtitle => 'Aus';

  @override
  String get concurrentDownloads => 'Gleichzeitige Downloads';

  @override
  String get autoDownload => 'Auto-Download';

  @override
  String get autoDownloadSubtitle =>
      'Aktiviere pro Serie, Podcast, Wiedergabeliste oder Sammlung über deren Detailseiten';

  @override
  String get autoDownloadEnabledFor => 'Eingeschaltet für';

  @override
  String get autoDownloadEnabledForNone => 'Noch nichts';

  @override
  String get autoDownloadSourceUnnamed => 'Noch nicht geladen';

  @override
  String get keepNext => 'Nächste behalten';

  @override
  String get keepNextInfoTitle => 'Nächste behalten';

  @override
  String get keepNextInfoContent =>
      'Die Anzahl der Elemente, die heruntergeladen bleiben sollen – einschließlich des Titels, den du gerade anhörst. „Die nächsten 3 behalten“ bedeutet beispielsweise, dass das aktuelle Buch sowie die beiden nachfolgenden Titel der jeweiligen Reihe, des Podcasts, der Playlist oder der Sammlung heruntergeladen bleiben. Dies gilt für jeden automatischen Download, den du aktivierst.';

  @override
  String get deleteAbsorbedDownloads => 'Absorbed Downloads löschen';

  @override
  String get deleteAbsorbedDownloadsInfoTitle => 'Absorbed Downloads löschen';

  @override
  String get deleteAbsorbedDownloadsInfoContent =>
      'Wenn diese Funktion aktiviert ist, werden heruntergeladene Bücher oder Episoden automatisch von diesem Gerät gelöscht, sobald Sie sie in Absorb abgeschlossen haben. Das Abschließen eines Inhalts im Browser oder auf einem anderen Gerät führt nicht dazu, dass der entsprechende Download hier gelöscht wird.';

  @override
  String get deleteAbsorbedOnSubtitle =>
      'Beendete Elemente werden entfernt, um Platz zu sparen';

  @override
  String get deleteAbsorbedOffSubtitle =>
      'Aus - beendete Downloads werden behalten';

  @override
  String get downloadLocation => 'Download-Speicherort';

  @override
  String get storageUsed => 'Speicher belegt';

  @override
  String storageUsedByDownloads(String size) {
    return '$size von Downloads belegt';
  }

  @override
  String storageFreeOfTotal(String free, String total) {
    return '$free frei von $total';
  }

  @override
  String get manageDownloads => 'Downloads verwalten';

  @override
  String get streamingCache => 'Streaming-Cache';

  @override
  String get streamingCacheInfoTitle => 'Streaming-Cache';

  @override
  String get streamingCacheInfoContent =>
      'Cached gestreamtes Audio auf der Festplatte, damit es nicht erneut heruntergeladen werden muss, wenn du zurückspulst oder Abschnitte erneut hörst. Der Cache wird automatisch verwaltet - älteste Dateien werden entfernt, wenn die Größenbegrenzung erreicht ist. Das ist getrennt von vollständig heruntergeladenen Büchern.';

  @override
  String get streamingCacheOff => 'Aus';

  @override
  String get streamingCacheOffSubtitle =>
      'Aus - Audio wird ohne Caching gestreamt';

  @override
  String streamingCacheOnSubtitle(int size) {
    return '$size MB - kürzlich gestreamtes Audio wird auf der Festplatte gecached';
  }

  @override
  String get clearCache => 'Cache leeren';

  @override
  String get streamingCacheCleared => 'Streaming-Cache geleert';

  @override
  String get sectionLibrary => 'Bibliothek';

  @override
  String get hideEbookOnlyTitles => 'Nur-eBook-Titel ausblenden';

  @override
  String get hideEbookOnlyOnSubtitle =>
      'Bücher ohne Audiodateien werden ausgeblendet';

  @override
  String get hideEbookOnlyOffSubtitle =>
      'Aus - alle Bibliothekselemente werden angezeigt';

  @override
  String get audibleRatings => 'Audible Bewertungen';

  @override
  String get audibleRatingsOnSubtitle =>
      'An - Buchdetails zeigen die Audible Bewertung an';

  @override
  String get audibleRatingsOffSubtitle =>
      'Aus - keine Audible Suche oder Sterne';

  @override
  String get homeCardsOpenDetails => 'Details von der Startseite aus öffnen';

  @override
  String get homeCardsOpenDetailsOnSubtitle =>
      'Tippen  auf eine Wiedergabe-Karte oder Lesekarte öffnet ihre Details';

  @override
  String get homeCardsOpenDetailsOffSubtitle =>
      'Wenn Sie auf eine Karte „Weiterhören“ oder „Weiterlesen“ tippen, geht es dort weiter, wo Sie aufgehört haben';

  @override
  String get showGoodreadsButton => 'Goodreads-Button anzeigen';

  @override
  String get showGoodreadsOnSubtitle =>
      'Buchdetails zeigen einen Link zu Goodreads';

  @override
  String get showGoodreadsOffSubtitle => 'Aus - Goodreads-Button ausgeblendet';

  @override
  String get sectionPermissions => 'Berechtigungen';

  @override
  String get notifications => 'Benachrichtigungen';

  @override
  String get notificationsSubtitle =>
      'Für Download-Fortschritt und Wiedergabesteuerung';

  @override
  String get notificationsAlreadyEnabled =>
      'Benachrichtigungen sind bereits aktiviert';

  @override
  String get unrestrictedBattery => 'Uneingeschränkte Akkunutzung';

  @override
  String get unrestrictedBatterySubtitle =>
      'Verhindert, dass Android die Hintergrundwiedergabe beendet';

  @override
  String get batteryAlreadyUnrestricted =>
      'Akkunutzung ist bereits uneingeschränkt';

  @override
  String get sectionIssuesAndSupport => 'Probleme & Support';

  @override
  String get bugsAndFeatureRequests => 'Bugs & Feature-Wünsche';

  @override
  String get bugsAndFeatureRequestsSubtitle => 'Issue auf GitHub eröffnen';

  @override
  String get joinDiscord => 'Discord beitreten';

  @override
  String get joinDiscordSubtitle => 'Community, Support und Updates';

  @override
  String get contact => 'Kontakt';

  @override
  String get contactSubtitle => 'Geräteinfos per E-Mail senden';

  @override
  String get enableLogging => 'Logging aktivieren';

  @override
  String get enableLoggingOnSubtitle =>
      'An - Protokolle werden erfasst (zum Anwenden neu starten)';

  @override
  String get enableLoggingOffSubtitle => 'Aus - keine Logs werden erfasst';

  @override
  String get loggingEnabledSnackbar =>
      'Logging aktiviert - App neu starten, um Aufzeichnung zu beginnen';

  @override
  String get loggingDisabledSnackbar =>
      'Logging deaktiviert - App neu starten, um Aufzeichnung zu beenden';

  @override
  String get sendLogs => 'Logdateien exportieren';

  @override
  String get sendLogsSubtitle => 'Download oder Teilen der .txt Protokolldatei';

  @override
  String failedToShare(String error) {
    return 'Export fehlgeschlagen: $error';
  }

  @override
  String get clearLogs => 'Logs löschen';

  @override
  String get logsCleared => 'Logs gelöscht';

  @override
  String get clearLogsQuestion => 'Logs löschen?';

  @override
  String get clearLogsContent =>
      'Das lässt sich nicht rückgängig machen. Sende sie zuerst, falls du sie noch brauchen könntest.';

  @override
  String get sectionAdvanced => 'Erweitert';

  @override
  String get localServer => 'Lokaler Server';

  @override
  String get localServerInfoTitle => 'Lokaler Server';

  @override
  String get localServerInfoContent =>
      'Wenn du deinen Audiobookshelf-Server zu Hause betreibst, kannst du hier eine lokale/LAN-URL festlegen. Absorb wechselt automatisch zur schnelleren lokalen Verbindung, wenn erkannt wird, dass du in deinem Heimnetzwerk bist, und greift unterwegs auf deine Remote-URL zurück.';

  @override
  String get localServerOnConnectedSubtitle => 'Verbunden über lokalen Server';

  @override
  String get localServerOnRemoteSubtitle =>
      'Aktiviert - Remote-Server wird verwendet';

  @override
  String get localServerOffSubtitle =>
      'Auto-Wechsel zu LAN-Server in deinem Heim-WLAN';

  @override
  String get localServerUrlLabel => 'URL des lokalen Servers';

  @override
  String get localServerUrlHint => 'http://192.168.1.100:13378';

  @override
  String get localServerUrlSetSnackbar =>
      'URL des lokalen Servers gesetzt - verbindet sich automatisch in deinem Heimnetzwerk';

  @override
  String get disableAudioFocus => 'Audiofokus deaktivieren';

  @override
  String get disableAudioFocusInfoTitle => 'Audiofokus';

  @override
  String get disableAudioFocusInfoContent =>
      'Standardmäßig gibt Android jeweils einer App den Audio-\"Fokus\" - wenn Absorb spielt, pausiert anderes Audio (Musik, Videos). Wenn du den Audiofokus deaktivierst, kann Absorb neben anderen Apps wiedergegeben werden. Telefonate pausieren die Wiedergabe unabhängig von dieser Einstellung trotzdem.';

  @override
  String get disableAudioFocusOnSubtitle =>
      'An - spielt neben anderem Audio (pausiert weiterhin bei Anrufen)';

  @override
  String get disableAudioFocusOffSubtitle =>
      'Aus - anderes Audio pausiert, wenn Absorb spielt';

  @override
  String get restartRequired => 'Neustart erforderlich';

  @override
  String get restartRequiredContent =>
      'Die Änderung des Audiofokus erfordert einen vollständigen Neustart. App jetzt schließen?';

  @override
  String get closeApp => 'App schließen';

  @override
  String get trustAllCertificates => 'Allen Zertifikaten vertrauen';

  @override
  String get trustAllCertificatesInfoTitle => 'Selbstsignierte Zertifikate';

  @override
  String get mp3IndexSeeking => 'MP3-Indexsuche';

  @override
  String get mp3IndexSeekingInfoTitle => 'MP3-Indexsuche';

  @override
  String get mp3IndexSeekingInfoContent =>
      'Aktivieren dies nur, wenn deine MP3-Dateien nicht an die richtige Stelle springen. Dies ist gewöhnlicherweise eine Auswirkung von variablen Bitraten (VBR) MP3s. Die Indexsuche erstellt eine exakte Zeitkarte beim Wiedergeben der Datei, so dass ein Sprung ans Ende einer großen MP3 einen Moment dauern kann - vor allem beim Streamen, da die Datei bis zu diesem Punkt gelesen werden muss. Die Aktivierung wird erst beim nächsten Start eines Buches oder einer Podcast-Episode wirksam.';

  @override
  String get mp3IndexSeekingOnSubtitle =>
      'An - exakte Suche bei VBR MP3 Dateien';

  @override
  String get mp3IndexSeekingOffSubtitle => 'Aus - normale Suche';

  @override
  String get trustAllCertificatesInfoContent =>
      'Aktiviere dies, wenn dein Audiobookshelf-Server ein selbstsigniertes Zertifikat oder eine eigene Root-CA verwendet. Wenn aktiviert, überspringt Absorb die TLS-Zertifikatsprüfung für alle Verbindungen. Aktiviere dies nur, wenn du deinem Netzwerk vertraust.';

  @override
  String get trustAllCertificatesOnSubtitle =>
      'An - alle Zertifikate werden akzeptiert';

  @override
  String get trustAllCertificatesOffSubtitle =>
      'Aus - nur vertrauenswürdige Zertifikate akzeptiert';

  @override
  String get supportTheDev => 'Den Entwickler unterstützen';

  @override
  String get buyMeACoffee => 'Spendier mir einen Kaffee';

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
    return 'Absorb v$version  -  Server $serverVersion';
  }

  @override
  String get backupAndRestore => 'Sichern & Wiederherstellen';

  @override
  String get backupAndRestoreSubtitle =>
      'Alle Einstellungen in einer Datei speichern oder wiederherstellen';

  @override
  String get backUp => 'Sichern';

  @override
  String get restore => 'Wiederherstellen';

  @override
  String get allBookmarks => 'Alle Lesezeichen';

  @override
  String get allBookmarksSubtitle => 'Lesezeichen aus allen Büchern anzeigen';

  @override
  String get switchAccount => 'Konto wechseln';

  @override
  String get addAccount => 'Konto hinzufügen';

  @override
  String get logOut => 'Abmelden';

  @override
  String get includeLoginInfoTitle => 'Login-Daten einschließen?';

  @override
  String get includeLoginInfoContent =>
      'Möchtest du die Login-Daten aller deiner gespeicherten Konten in die Sicherung einschließen?\n\nDas erleichtert die Wiederherstellung auf einem neuen Gerät, aber die Datei enthält dann deine Auth-Tokens.';

  @override
  String get noSettingsOnly => 'Nein, nur Einstellungen';

  @override
  String get yesIncludeAccounts => 'Ja, Konten einschließen';

  @override
  String get backupSavedWithAccounts => 'Sicherung gespeichert (mit Konten)';

  @override
  String get backupSavedSettingsOnly =>
      'Sicherung gespeichert (nur Einstellungen)';

  @override
  String backupFailed(String error) {
    return 'Sicherung fehlgeschlagen: $error';
  }

  @override
  String get restoreBackupTitle => 'Sicherung wiederherstellen?';

  @override
  String get restoreBackupContent =>
      'Dadurch werden alle deine aktuellen Einstellungen durch die Werte aus der Sicherung ersetzt.';

  @override
  String fromAbsorbVersion(String version) {
    return 'Von Absorb v$version';
  }

  @override
  String restoreAccountsChip(int count) {
    return '$count Konto/Konten';
  }

  @override
  String restoreBookmarksChip(int count) {
    return 'Lesezeichen für $count Buch/Bücher';
  }

  @override
  String get restoreCustomHeadersChip => 'Benutzerdefinierte Header';

  @override
  String get invalidBackupFile => 'Ungültige Sicherungsdatei';

  @override
  String get settingsRestoredSuccessfully =>
      'Einstellungen erfolgreich wiederhergestellt';

  @override
  String restoreFailed(String error) {
    return 'Wiederherstellung fehlgeschlagen: $error';
  }

  @override
  String get logOutTitle => 'Abmelden?';

  @override
  String get logOutContent =>
      'Du wirst abgemeldet. Deine Downloads bleiben auf diesem Gerät.';

  @override
  String get signOut => 'Abmelden';

  @override
  String get changePasswordTitle => 'Passwort ändern';

  @override
  String get changePasswordSubtitle =>
      'Aktualisiere sicher dein Audiobookshelf Passwort';

  @override
  String get currentPassword => 'Aktuelles Passwort';

  @override
  String get newPassword => 'Neues Passwort';

  @override
  String get confirmNewPassword => 'Neues Passwort bestätigen';

  @override
  String get passwordChangeEffect =>
      'Das Ändern deines Passworts meldet dich von allen anderen Audiobookshelf Sitzungen ab. Dieses Gerät bleibt angemeldet.';

  @override
  String get passwordFieldsRequired => 'Alle Passwortfelder ausfüllen';

  @override
  String get passwordsDoNotMatch =>
      'Die neuen Passwörter stimmen nicht überein';

  @override
  String get passwordChanged =>
      'Passwort geändert. Andere angemeldete Geräte wurden getrennt.';

  @override
  String get passwordInvalid => 'Das aktuelle Kennwort ist falsch';

  @override
  String get passwordChangeUnsupported =>
      'Diese Server-Version unterstützt keine sicheren Passwortänderungen in Absorb';

  @override
  String get passwordChangeFailed =>
      'Dein Passwort konnte nicht geändert werden';

  @override
  String get otherUserPasswordResetWarning =>
      'Das Ändern dieses Passworts meldet den Benutzer auf allen Geräten ab.';

  @override
  String get manageSessionsTitle => 'Angemeldete Geräte';

  @override
  String get manageSessionsSubtitle =>
      'Audiobookshelf Sitzungen überprüfen und entfernen';

  @override
  String get sessionsCurrent => 'Aktuelles Gerät';

  @override
  String get sessionsUnknownDevice => 'Unbekanntes Gerät';

  @override
  String sessionsLastActive(String date) {
    return 'Zuletzt aktiv $date';
  }

  @override
  String get sessionsNone => 'Keine aktiven Sitzungen';

  @override
  String get sessionsLoadMore => 'Mehr laden';

  @override
  String get sessionsUnsupported =>
      'Das Session-Management benötigt Audiobookshelf 2.36 oder neuer.';

  @override
  String get sessionsLoadFailed =>
      'Angemeldete Geräte konnten nicht geladen werden';

  @override
  String get sessionsLegacyNotice =>
      'Dieser Login hat keine Sitzungsaktualisierung, daher kann Absorb dieses Gerät nicht in der Liste identifizieren.';

  @override
  String get sessionsRemove => 'Gerät abmelden';

  @override
  String get sessionsRemoveTitle => 'Dieses Gerät abmelden?';

  @override
  String get sessionsRemoveContent =>
      'Dies entfernt die Sitzungsaktualisierung. Der aktuelle Zugriff funktioniert eventuell weiter, bis das kurzlebige Token abläuft.';

  @override
  String get sessionsRemoved => 'Gerät abgemeldet';

  @override
  String get sessionsRemoveFailed => 'Das Gerät konnte nicht abgemeldet werden';

  @override
  String get sessionsSignOutAll => 'Alle Geräte abmelden';

  @override
  String get sessionsSignOutAllTitle => 'Überall abmelden?';

  @override
  String get sessionsSignOutAllContent =>
      'Dies entfernt jede Sitzungsaktualisierung, einschließlich dieses Geräts. Vorhandene Zugriffs-Token können bis zum Ablauf funktionieren.';

  @override
  String podcastScheduleServerTime(String timeZone) {
    return 'Zeitplan verwendet die Serverzeit ($timeZone)';
  }

  @override
  String get podcastScheduleServerTimeUnknown =>
      'Zeitplan verwendet die Serverzeit';

  @override
  String get editServerAddressTitle => 'Serveradresse bearbeiten';

  @override
  String editServerAddressSubtitle(String username) {
    return 'Aktualisiere die Adresse für $username. Nutze diese Option, wenn sich lediglich die URL geändert hat - es aber noch immer der gleiche Server ist. Deine Statistiken und Downloads werden beibehalten.';
  }

  @override
  String get editServerAddressField => 'Serveradresse';

  @override
  String get editServerAddressUpdated => 'Serveradresse aktualisiert';

  @override
  String get editServerAddressFailed =>
      'Serveradresse konnte nicht aktualisiert werden';

  @override
  String get editServerAddressAction => 'Serveradresse bearbeiten';

  @override
  String get editServerConnectionTitle => 'Server-Verbindung bearbeiten';

  @override
  String editServerConnectionSubtitle(String username) {
    return 'Aktualisieren die Serveradresse und die benutzerdefinierten Header für $username. Deine Statistiken und Downloads werden beibehalten.';
  }

  @override
  String get editServerConnectionAction => 'Server-Verbindung bearbeiten';

  @override
  String get editServerConnectionUpdated => 'Serververbindung aktualisiert';

  @override
  String get editServerConnectionFailed =>
      'Serververbindung konnte nicht aktualisiert werden';

  @override
  String get editCustomHeadersDescription =>
      'Wird für Cloudflare Tunnel oder Reverse Proxies verwendet. Diese Header gelten nur für dieses gespeicherte Konto.';

  @override
  String get removeAccountAction => 'Konto entfernen';

  @override
  String get removeAccountTitle => 'Konto entfernen?';

  @override
  String removeAccountContent(String username, String server) {
    return '$username auf $server aus den gespeicherten Konten entfernen?\n\nDu kannst es jederzeit wieder hinzufügen, indem du dich erneut anmeldest.';
  }

  @override
  String get switchAccountTitle => 'Konto wechseln?';

  @override
  String switchAccountContent(String username, String server) {
    return 'Zu $username auf $server wechseln?\n\nDie aktuelle Wiedergabe wird gestoppt und die App lädt mit den Daten des anderen Kontos neu.';
  }

  @override
  String get switchButton => 'Wechseln';

  @override
  String get downloadLocationSheetTitle => 'Download-Speicherort';

  @override
  String get downloadLocationSheetSubtitle =>
      'Wähle, wo Hörbücher gespeichert werden';

  @override
  String get currentLocation => 'Aktueller Speicherort';

  @override
  String get existingDownloadsWarning =>
      'Vorhandene Downloads bleiben an ihrem aktuellen Speicherort. Nur neue Downloads verwenden den neuen Pfad.';

  @override
  String get chooseFolder => 'Ordner wählen';

  @override
  String get chooseDownloadFolder => 'Download-Ordner wählen';

  @override
  String get storagePermissionDenied =>
      'Speicherberechtigung dauerhaft verweigert - aktiviere sie in den App-Einstellungen';

  @override
  String get openSettings => 'Einstellungen öffnen';

  @override
  String get storagePermissionRequired =>
      'Speicherberechtigung ist für eigene Download-Speicherorte erforderlich';

  @override
  String get cannotWriteToFolder =>
      'Kann nicht in diesen Ordner schreiben - wähle einen anderen Speicherort oder gewähre in den Systemeinstellungen Dateizugriff';

  @override
  String downloadLocationSetTo(String label) {
    return 'Download-Speicherort gesetzt auf $label';
  }

  @override
  String get resetToDefault => 'Auf Standard zurücksetzen';

  @override
  String get resetToDefaultStorage => 'Auf Standardspeicher zurücksetzen';

  @override
  String legacyDownloadsNotice(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count Downloads liegen in einem alten benutzerdefinierten Ordner, der nicht mehr geöffnet werden kann. Lade die Dateien erneut herunter oder schließe diese Mitteilung.',
      one:
          '1 Download liegt in einem alten benutzerdefinierten Ordner, der nicht mehr geöffnet werden kann. Lade ihn erneut herunter oder schließe diese Mitteilung.',
    );
    return '$_temp0';
  }

  @override
  String get redownload => 'Erneut herunterladen';

  @override
  String get redownloadStarted => 'Wird erneut heruntergeladen';

  @override
  String get dismiss => 'Verwerfen';

  @override
  String get tipsAndHiddenFeatures => 'Tipps & versteckte Funktionen';

  @override
  String get tipsSubtitle => 'Hol das Beste aus Absorb heraus';

  @override
  String get adminTitle => 'Server-Admin';

  @override
  String get adminTasksTitle => 'Server-Aktivität';

  @override
  String adminTasksRunning(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Aufgaben laufen',
      one: '1 Aufgabe läuft',
    );
    return '$_temp0';
  }

  @override
  String get adminTasksRecent => 'Letzte Server-Aktivität';

  @override
  String get adminTasksEmpty => 'Es laufen keine Server-Aufgaben';

  @override
  String adminTaskScanSummary(int added, int updated, int missing) {
    return '$added hinzugefügt - $updated aktualisiert - $missing fehlen';
  }

  @override
  String get adminServer => 'Server';

  @override
  String get adminVersion => 'Version';

  @override
  String get adminUsers => 'Benutzer';

  @override
  String get adminOnline => 'Online';

  @override
  String get adminBackup => 'Sicherung';

  @override
  String get adminPurgeCache => 'Cache leeren';

  @override
  String get adminManage => 'Verwalten';

  @override
  String adminUsersSubtitle(int userCount, int onlineCount) {
    return '$userCount Konten - $onlineCount online';
  }

  @override
  String get adminPodcasts => 'Podcasts';

  @override
  String get adminPodcastsSubtitle =>
      'Sendungen suchen, hinzufügen & verwalten';

  @override
  String get adminScan => 'Scannen';

  @override
  String get adminScanning => 'Scannt...';

  @override
  String get adminMatchAll => 'Alle abgleichen';

  @override
  String get adminMatching => 'Gleicht ab...';

  @override
  String get adminMatchAllTitle => 'Alle Elemente abgleichen?';

  @override
  String adminMatchAllContent(String name) {
    return 'Metadaten für alle Elemente in $name abgleichen? Das kann eine Weile dauern.';
  }

  @override
  String adminScanStarted(String name) {
    return 'Scan für $name gestartet';
  }

  @override
  String get adminBackupCreated => 'Sicherung erstellt';

  @override
  String get adminBackupFailed => 'Sicherung fehlgeschlagen';

  @override
  String get adminCachePurged => 'Cache geleert';

  @override
  String get adminRmab => 'ReadMeABook';

  @override
  String get adminRmabSubtitle => 'In App öffnen';

  @override
  String get adminRmabAdd => 'ReadMeABook-Integration hinzufügen';

  @override
  String get adminRmabUrlTitle => 'ReadMeABook-URL';

  @override
  String get adminRmabUrlHelp =>
      'Füge deine URL mit Login-Token ein. Generiere eine in RMAB, Admin, Users.';

  @override
  String get adminRmabUrlHint => 'https://rmab.example.com/?token=...';

  @override
  String get adminRmabInvalidUrl => 'Gib eine gültige http(s)-URL ein';

  @override
  String get adminRmabSaved => 'ReadMeABook gespeichert';

  @override
  String get adminRmabRemoved => 'ReadMeABook entfernt';

  @override
  String get adminRmabReload => 'Neu laden';

  @override
  String get adminRmabLoadFailed =>
      'ReadMeABook konnte nicht geladen werden. Prüfe deine URL.';

  @override
  String get adminRmabConnected => 'Verbunden';

  @override
  String get adminRmabAskAdmin =>
      'Hol dir eine Login-URL von deinem Server-Admin';

  @override
  String get adminRmabUrlHelpUser =>
      'Hol dir eine Login-URL von deinem Server-Admin. Diese wird in RMAB > Admin > Users generiert.';

  @override
  String get adminRmabSettingsInfo =>
      'ReadMeABook ist ein selbst gehosteter Dienst zum Anfordern und Herunterladen von Hörbüchern. Es muss von deinem Server-Admin installiert und eingerichtet werden.';

  @override
  String get rmabConfigTitle => 'ReadMeABook verbinden';

  @override
  String get rmabConfigExplainerAdmin =>
      'ReadMeABook ist ein selbst gehosteter Service für das Anfordern von Hörbüchern. Erzeuge in RMAB ein API-Token unter Admin Dashboard > Einstellungen > API, dann füge diesen und die Server-URL unten ein. Absorb speichert oder lädt keine Inhalte herunter, sondern sendet ausschließlich Anfragen an deinen Server.';

  @override
  String get rmabConfigExplainerUser =>
      'ReadMeABook ist ein selbst gehosteter Service für das Anfordern von Hörbüchern. Bitte deinen Server Administrator um die RMAB URL und ein API-Token. Absorb speichert oder lädt keine Inhalte herunter, sondern sendet ausschließlich Anfragen an deinen Server.';

  @override
  String get rmabConfigLearnMore => 'Mehr über ReadMeABook erfahren';

  @override
  String get rmabConfigBaseUrlLabel => 'RMAB Server URL';

  @override
  String get rmabConfigBaseUrlHint => 'https://rmab.example.com';

  @override
  String get rmabConfigTokenLabel => 'API-Token';

  @override
  String get rmabConfigTokenHint => 'rmab_...';

  @override
  String get rmabConfigLegacyUrlLabel => 'Web UI Login URL (Optional)';

  @override
  String get rmabConfigLegacyUrlHint => 'https://rmab.example.com/?token=...';

  @override
  String get rmabConfigLegacyUrlHelp =>
      'Füge deine Auto-Login-URL ein, sodass dich \'In Browseransicht öffnen\' direkt anmeldet. Für einen regulären Login lasse das Feld einfach leer.';

  @override
  String get rmabConfigHeadersHelp =>
      'Zusätzliche Header, die mit jeder ReadMeABook-Anfrage gesendet werden, für Reverse Proxies wie Cloudflare Access.';

  @override
  String get rmabConfigConnect => 'Verbinden';

  @override
  String get rmabConfigDisconnect => 'Trennen';

  @override
  String get rmabConfigOpenWebView => 'In der Browseransicht öffnen';

  @override
  String rmabConfigConnectedAs(String name) {
    return 'Verbunden als $name';
  }

  @override
  String get rmabConfigErrorInvalidUrl => 'Gültige http(s)-URL eingeben';

  @override
  String get rmabConfigErrorMissingToken => 'API-Token eingeben';

  @override
  String get rmabConfigErrorUnauthorized => 'Token vom Server abgelehnt';

  @override
  String get rmabConfigErrorForbidden =>
      'Dieses Token ist für diese Aktion nicht erlaubt';

  @override
  String get rmabConfigErrorNetwork =>
      'RMAB ist nicht erreichbar. Bitte überprüfe die URL.';

  @override
  String get rmabConfigErrorGeneric =>
      'Verbindung konnte nicht hergestellt werden';

  @override
  String get rmabConfigSavedSnackbar => 'ReadMeABook verbunden';

  @override
  String get rmabConfigDisconnectedSnackbar => 'ReadMeABook getrennt';

  @override
  String get rmabRequestCta => 'Über ReadMeABook anfragen';

  @override
  String get rmabSearchHeader => 'Über ReadMeABook anfragen';

  @override
  String get rmabSearchHint => 'Nach Titel oder Autor suchen';

  @override
  String get rmabSearchEmpty => 'Keine Treffer auf Ihrem ReadMeABook-Server';

  @override
  String get rmabSearchError => 'ReadMeABook konnte nicht durchsucht werden';

  @override
  String get rmabSearchPrompt => 'Um zu Suchen, gib einen Titel oder Autor ein';

  @override
  String get rmabSearchFooterPrompt => 'Suchst du etwas anderes?';

  @override
  String rmabSearchFooterCta(String query) {
    return 'Durchsuche ReadMeABook nach \"$query\"';
  }

  @override
  String get rmabBookDetailExplainer =>
      'Die Anfrage wird über deinen ReadMeABook-Server gesendet. Der Administrator wird diese überprüfen und bearbeiten. Unter \"Meine Anfragen\" auf der ReadMeABook Kachel kannst du den Status verfolgen.';

  @override
  String get rmabBookAlreadyAvailable => 'Bereits in deiner Bibliothek';

  @override
  String get rmabBookAlreadyRequested => 'Bereits angefordert';

  @override
  String get rmabRequestSubmitting => 'Wird übermittelt…';

  @override
  String get rmabRequestSent => 'Anfrage gesendet';

  @override
  String get rmabRequestErrorAlreadyAvailable => 'Bereits in deiner Bibliothek';

  @override
  String get rmabRequestErrorBeingProcessed => 'Wird bereits bearbeitet';

  @override
  String get rmabRequestErrorDuplicate => 'Du hast dies bereits angefragt';

  @override
  String get rmabRequestErrorValidation =>
      'Anfrage konnte nicht gesendet werden';

  @override
  String get rmabRequestErrorUserNotFound =>
      'Der Tokennutzer existiert nicht mehr. Bitte verbinde ReadMeABook erneut.';

  @override
  String get rmabRequestErrorIgnored =>
      'Dieses Buch ist auf deiner Ignorieren-Liste';

  @override
  String get rmabRequestErrorGeneric => 'Anfrage konnte nicht gesendet werden';

  @override
  String get rmabRequestErrorTokenRejected =>
      'Token wurde vom Server abgelegt. Bitte verbinde ReadMeABook erneut.';

  @override
  String get rmabMyRequestsTab => 'Meine Anfragen';

  @override
  String get rmabSetupTab => 'Einrichtung';

  @override
  String get rmabMyRequestsEmpty => 'Du hast bisher keine Bücher angefragt';

  @override
  String get rmabMyRequestsError => 'Anfragen konnten nicht geladen werden';

  @override
  String get rmabMyRequestsRefresh => 'Aktualisieren';

  @override
  String get rmabRequestDetailTitle => 'Details anfragen';

  @override
  String get rmabRequestDetailStatus => 'Status';

  @override
  String get rmabRequestDetailRequestedOn => 'Angefragt am';

  @override
  String get rmabRequestDetailCompletedOn => 'Erledigt am';

  @override
  String get rmabRequestDetailProgress => 'Fortschritt';

  @override
  String get rmabStatusActive => 'Im Gang';

  @override
  String get rmabStatusWaiting => 'Warten';

  @override
  String get rmabStatusAvailable => 'Verfügbar';

  @override
  String get rmabStatusDownloaded => 'Heruntergeladen';

  @override
  String get rmabStatusFailed => 'Fehlgeschlagen';

  @override
  String get rmabStatusCancelled => 'Abgebrochen';

  @override
  String get rmabStatusDenied => 'Verweigert';

  @override
  String get rmabStatusUnknown => 'Unbekannt';

  @override
  String narratedBy(String narrator) {
    return 'Gesprochen von $narrator';
  }

  @override
  String get onAudible => 'auf Audible';

  @override
  String percentComplete(String percent) {
    return '$percent% abgeschlossen';
  }

  @override
  String get absorbing => 'Absorbing...';

  @override
  String get absorbAgain => 'Nochmal Absorb';

  @override
  String get absorb => 'Absorb';

  @override
  String get ebookOnlyNoAudio => 'Nur eBook - kein Audio';

  @override
  String get absorbAudioNotDownloaded => 'Audio nicht heruntergeladen';

  @override
  String get absorbAudioNotDownloadedEbookOnly =>
      'Audio nicht heruntergeladen, nur E-Book';

  @override
  String get fullyAbsorbed => 'Vollständig Absorbed';

  @override
  String get fullyAbsorbAction => 'Vollständig Absorb';

  @override
  String get removeFromAbsorbing => 'Aus Absorbing entfernen';

  @override
  String get addToAbsorbing => 'Zu Absorbing hinzufügen';

  @override
  String get absorbNext => 'Nächstes absorbieren';

  @override
  String get absorbNextAdded => 'Als Nächstes bei „Absorbing“';

  @override
  String get absorbLast => 'Absorb Zuletzt';

  @override
  String get absorbNextHint => 'Direkt nach dem, was gerade gespielt wird';

  @override
  String get absorbLastHint => 'Am Ende der Liste';

  @override
  String get removedFromAbsorbing => 'Aus Absorbing entfernt';

  @override
  String get addedToAbsorbing => 'Zu Absorbing hinzugefügt';

  @override
  String get removeFromContinueListening => 'Aus \"Weiterhören\" entfernen';

  @override
  String get removedFromContinueListening => 'Aus \"Weiterhören\" entfernt';

  @override
  String get removeFromContinueReading => 'Aus „Weiterlesen“ entfernen';

  @override
  String get removedFromContinueReading => 'Aus „Weiterlesen“ entfernt';

  @override
  String get sessionAdd => 'Sitzung hinzufügen';

  @override
  String get sessionStartLabel => 'Begonnen am';

  @override
  String get sessionAdded => 'Sitzung hinzugefügt';

  @override
  String get sessionAddFailed => 'Sitzung konnte nicht hinzugefügt werden';

  @override
  String get removeSeriesFromContinueSeries =>
      'Aus \"Serie fortsetzen\" entfernen';

  @override
  String get removedSeriesFromContinueSeries =>
      'Aus \"Serie fortsetzen\" entfernt';

  @override
  String get couldNotUpdate =>
      'Konnte nicht aktualisieren werden, versuche es erneut';

  @override
  String get addToPlaylist => 'Zur Playlist hinzufügen';

  @override
  String get addToCollection => 'Zur Sammlung hinzufügen';

  @override
  String get downloadEbook => 'eBook herunterladen';

  @override
  String get downloadEbookAgain => 'eBook erneut herunterladen';

  @override
  String get resetProgress => 'Fortschritt zurücksetzen';

  @override
  String get lookupLocalMetadata => 'Lokale Metadaten suchen';

  @override
  String get reLookupLocalMetadata => 'Lokale Metadaten erneut suchen';

  @override
  String get clearLocalMetadata => 'Lokale Metadaten löschen';

  @override
  String get searchOnGoodreads => 'Auf Goodreads suchen';

  @override
  String get editServerDetails => 'Server-Details bearbeiten';

  @override
  String get encodeTab => 'Verschlüsseln';

  @override
  String get codec => 'Codec';

  @override
  String get bitrate => 'Bitrate';

  @override
  String get channels => 'Kanäle';

  @override
  String get mono => 'Mono';

  @override
  String get stereo => 'Stereo';

  @override
  String get startM4bEncode => 'M4B-Encodierung starten';

  @override
  String get encodeStarted => 'M4B Encodierung gestartet';

  @override
  String get encodeFailed => 'Encodieren konnte nicht gestartet werden';

  @override
  String get encodeFinished => 'M4B-Encodierung abgeschlossen';

  @override
  String get currentlyLabel => 'Momentan:';

  @override
  String encodeOutputPathNote(String path) {
    return 'Fertiggestellte M4B Dateien werden im Hörbuchordner abgelegt unter: $path/';
  }

  @override
  String encodeBackupNote(String itemId) {
    return 'Ein Backup der original Audiodateien wird gespeichert unter: /metadata/cache/items/$itemId/. Achte darauf regelmäßig den Cache zu löschen.';
  }

  @override
  String get encodeTimeNote => 'Die Encodierung kann bis zu 30 Minuten dauern.';

  @override
  String get encodeRescanNote =>
      'Wenn du den Beobachter deaktiviert hast, musst du dieses Hörbuch später erneut scannen.';

  @override
  String get aboutSection => 'Info';

  @override
  String chaptersCount(int count) {
    return 'Kapitel ($count)';
  }

  @override
  String audioTracksCount(int count) {
    return 'Audio-Tracks ($count)';
  }

  @override
  String libraryFilesCount(int count) {
    return 'Bibliotheks-Dateien ($count)';
  }

  @override
  String get chapters => 'Kapitel';

  @override
  String get noChaptersBook => 'Dieses Buch hat keine Kapitel';

  @override
  String get noChaptersPodcast => 'Dieser Podcast hat keine Kapitel';

  @override
  String get failedToLoad => 'Laden fehlgeschlagen';

  @override
  String startedDate(String date) {
    return 'Begonnen $date';
  }

  @override
  String finishedDate(String date) {
    return 'Beendet $date';
  }

  @override
  String andCountMore(int count) {
    return 'und $count weitere';
  }

  @override
  String get markAsFullyAbsorbedQuestion =>
      'Als vollständig Absorbed markieren?';

  @override
  String get markAsFullyAbsorbedContent =>
      'Dadurch wird dein Fortschritt auf 100% gesetzt und die Wiedergabe gestoppt, falls dieses Buch gerade läuft.';

  @override
  String get markedAsFinishedNiceWork => 'Als beendet markiert - gut gemacht!';

  @override
  String get failedToUpdateCheckConnection =>
      'Aktualisieren fehlgeschlagen - prüfe deine Verbindung';

  @override
  String get markedFinishedWillSync =>
      'Als abgeschlossen markiert – wird synchronisiert, sobald du wieder online bist';

  @override
  String get markAsNotFinishedQuestion => 'Als nicht beendet markieren?';

  @override
  String get markAsNotFinishedContent =>
      'Dadurch wird der Status „abgeschlossen“ gelöscht und Ihre Position wieder an den Anfang gesetzt.';

  @override
  String get unmark => 'Markierung entfernen';

  @override
  String get markedAsNotFinishedBackAtIt =>
      'Als nicht beendet markiert - weiter geht\'s!';

  @override
  String get resetProgressQuestion => 'Fortschritt zurücksetzen?';

  @override
  String get resetProgressListeningAndReading =>
      'Dein Hör- und Lesefortschritt wird jeweils auf 0 % zurückgesetzt.';

  @override
  String get resetProgressListening =>
      'Dein Hörfortschritt wird auf 0 % zurückgesetzt.';

  @override
  String get resetProgressReading =>
      'Dein Lesefortschritt wird auf 0 % zurückgesetzt.';

  @override
  String get resetProgressMarksUnread =>
      'Das Buch wird ebenfalls als ungelesen markiert.';

  @override
  String get resetProgressCantUndo =>
      'Das kann nicht rückgängig gemacht werden.';

  @override
  String get progressResetFreshStart =>
      'Fortschritt zurückgesetzt - frischer Start!';

  @override
  String get clearLocalMetadataQuestion => 'Lokale Metadaten löschen?';

  @override
  String get clearLocalMetadataContent =>
      'Dadurch werden die lokal gespeicherten Metadaten entfernt und auf das zurückgesetzt, was der Server hat.';

  @override
  String get localMetadataCleared => 'Lokale Metadaten gelöscht';

  @override
  String get saveEbook => 'eBook speichern';

  @override
  String get noEbookFileFound => 'Keine eBook-Datei gefunden';

  @override
  String get bookmark => 'Lesezeichen';

  @override
  String get bookmarks => 'Lesezeichen';

  @override
  String bookmarksWithCount(int count) {
    return 'Lesezeichen ($count)';
  }

  @override
  String get playbackSpeed => 'Wiedergabegeschwindigkeit';

  @override
  String get noBookmarksYet => 'Noch keine Lesezeichen';

  @override
  String get longPressBookmarkHint =>
      'Lange auf den Lesezeichen-Button drücken zum schnellen Speichern';

  @override
  String get addBookmark => 'Lesezeichen hinzufügen';

  @override
  String get editBookmark => 'Lesezeichen bearbeiten';

  @override
  String get titleLabel => 'Titel';

  @override
  String get noteOptionalLabel => 'Notiz (optional)';

  @override
  String get editLayout => 'Layout bearbeiten';

  @override
  String get inMenu => 'Im Menü';

  @override
  String get bookmarkAdded => 'Lesezeichen hinzugefügt';

  @override
  String get startPlayingSomethingFirst => 'Spiele zuerst etwas ab';

  @override
  String get playbackHistory => 'Wiedergabeverlauf';

  @override
  String get historyLocalTab => 'Verlauf';

  @override
  String get historyServerTab => 'Sitzungen';

  @override
  String get historyNoServerSessions =>
      'Noch keine Serversitzungen für dieses Element';

  @override
  String get historyServerLoadFailed =>
      'Serversitzungen konnten nicht geladen werden';

  @override
  String get clearHistoryTooltip => 'Verlauf löschen';

  @override
  String get tapEventToJump =>
      'Tippe auf ein Ereignis, um zu dieser Position zu springen';

  @override
  String get noHistoryYet => 'Noch kein Verlauf';

  @override
  String jumpedToPosition(String position) {
    return 'Zu $position gesprungen';
  }

  @override
  String booksInSeriesCount(int count) {
    return '$count Bücher in dieser Serie';
  }

  @override
  String bookNumber(String number) {
    return 'Buch $number';
  }

  @override
  String downloadRemainingCount(int count) {
    return 'Restliche herunterladen ($count)';
  }

  @override
  String get downloadAll => 'Alle herunterladen';

  @override
  String get markAllNotFinished => 'Alle als nicht beendet markieren';

  @override
  String get markAllFinished => 'Alle als beendet markieren';

  @override
  String get markAllNotFinishedQuestion => 'Alle als nicht beendet markieren?';

  @override
  String get fullyAbsorbSeries => 'Serie vollständig Absorb?';

  @override
  String get turnAutoDownloadOff => 'Auto-Download deaktivieren';

  @override
  String get turnAutoDownloadOn => 'Auto-Download aktivieren';

  @override
  String get autoDownloadThisSeries => 'Diese Serie automatisch herunterladen?';

  @override
  String get autoDownloadSeriesContent =>
      'Lädt die nächsten Bücher beim Hören automatisch herunter.';

  @override
  String get standalone => 'Eigenständig';

  @override
  String get episodes => 'Episoden';

  @override
  String get noEpisodesFound => 'Keine Episoden gefunden';

  @override
  String get markFinished => 'Als beendet markieren';

  @override
  String get markUnfinished => 'Als unbeendet markieren';

  @override
  String get allEpisodes => 'Alle Episoden';

  @override
  String get aboutThisEpisode => 'Über diese Episode';

  @override
  String get reversePlayOrder => 'Wiedergabereihenfolge umkehren';

  @override
  String selectedCount(int count) {
    return '$count ausgewählt';
  }

  @override
  String get selectAll => 'Alle auswählen';

  @override
  String get deselectAll => 'Alle abwählen';

  @override
  String get autoDownloadThisPodcast =>
      'Diesen Podcast automatisch herunterladen?';

  @override
  String get autoDownloadPodcastContent =>
      'Lädt die nächsten Episoden beim Hören automatisch herunter.';

  @override
  String get download => 'Herunterladen';

  @override
  String get deleteDownload => 'Download löschen';

  @override
  String get casting => 'Cast läuft';

  @override
  String get castingTo => 'Cast an';

  @override
  String get editDetails => 'Details bearbeiten';

  @override
  String get quickMatch => 'Schnellabgleich';

  @override
  String get quickMatchNoUpdates => 'Keine Aktualisierungen erforderlich';

  @override
  String get custom => 'Benutzerdefiniert';

  @override
  String get authorOptionalLabel => 'Autor (optional)';

  @override
  String get noResultsFound =>
      'Keine Ergebnisse gefunden.\nPasse deine Suche oder den Anbieter an.';

  @override
  String get searchForMetadataAbove => 'Oben nach Metadaten suchen';

  @override
  String get applyThisMatch => 'Diesen Treffer anwenden?';

  @override
  String get metadataUpdated => 'Metadaten aktualisiert';

  @override
  String get failedToUpdateMetadata =>
      'Metadaten konnten nicht aktualisiert werden';

  @override
  String get subtitleLabel => 'Untertitel';

  @override
  String get authorLabel => 'Autor';

  @override
  String get narratorLabel => 'Erzähler';

  @override
  String get seriesLabel => 'Serie';

  @override
  String get addSeries => 'Serie hinzufügen';

  @override
  String get removeSeries => 'Serie entfernen';

  @override
  String get descriptionLabel => 'Beschreibung';

  @override
  String get publisherLabel => 'Verlag';

  @override
  String get yearLabel => 'Jahr';

  @override
  String get genresLabel => 'Genres';

  @override
  String get tagsLabel => 'Schlagwörter';

  @override
  String get commaSeparated => 'Komma-getrennt';

  @override
  String get asinLabel => 'ASIN';

  @override
  String get isbnLabel => 'ISBN';

  @override
  String get coverImage => 'Coverbild';

  @override
  String get coverRemove => 'Cover entfernen';

  @override
  String get coverRemoveConfirm =>
      'Dieses Titelbild entfernen? Stattdessen wird die generierte Titelkarte angezeigt.';

  @override
  String get coverRemoved => 'Cover entfernt';

  @override
  String get coverRemoveFailed => 'Konnte Cover nicht entfernen';

  @override
  String get coverUrlLabel => 'Cover-URL';

  @override
  String get coverUrlHint => 'https://...';

  @override
  String get localMetadata => 'Lokale Metadaten';

  @override
  String get overrideLocalDisplay => 'Lokale Anzeige überschreiben';

  @override
  String get metadataSavedLocally => 'Metadaten lokal gespeichert';

  @override
  String get notes => 'Notizen';

  @override
  String get newNote => 'Neue Notiz';

  @override
  String get editNote => 'Notiz bearbeiten';

  @override
  String get noNotesYet => 'Noch keine Notizen';

  @override
  String get markdownIsSupported => 'Markdown wird unterstützt';

  @override
  String get markdownMd => 'Markdown (.md)';

  @override
  String get keepsFormattingIntact => 'Behält die Formatierung bei';

  @override
  String get plainTextTxt => 'Reiner Text (.txt)';

  @override
  String get simpleTextNoFormatting => 'Einfacher Text, keine Formatierung';

  @override
  String get untitledNote => 'Unbenannte Notiz';

  @override
  String get titleHint => 'Titel';

  @override
  String get noteBodyHint => 'Schreibe deine Notiz... (unterstützt Markdown)';

  @override
  String get nothingToPreview => 'Nichts zur Vorschau';

  @override
  String get audioEnhancements => 'Audio-Verbesserungen';

  @override
  String get presets => 'VOREINSTELLUNGEN';

  @override
  String get equalizer => 'EQUALIZER';

  @override
  String get effects => 'EFFEKTE';

  @override
  String get bassBoost => 'Bass-Boost';

  @override
  String get surround => 'Surround';

  @override
  String get loudness => 'Lautheit';

  @override
  String get pitch => 'Stimmlage';

  @override
  String get monoAudio => 'Mono-Audio';

  @override
  String get skipSilence => 'Stille überspringen';

  @override
  String get resetAll => 'Alles zurücksetzen';

  @override
  String get collectionNotFound => 'Sammlung nicht gefunden';

  @override
  String get deleteCollection => 'Sammlung löschen';

  @override
  String get deleteCollectionContent =>
      'Möchtest du diese Sammlung wirklich löschen?';

  @override
  String get deleteCollectionFailed => 'Sammlung konnte nicht gelöscht werden';

  @override
  String get deletePermissionRequired =>
      'Löschberechtigung erforderlich. Bitte wende dich hierzu an den Administrator.';

  @override
  String get deleteFilesCheckbox => 'Dateien auf dem Server ebenfalls löschen';

  @override
  String get deleteFilesCheckedHint =>
      'Die Dateien werden auf dem Server endgültig gelöscht.';

  @override
  String get deleteFilesUncheckedHint =>
      'Die Dateien bleiben auf dem Server. Ein erneuter Scan kann sie wieder hinzufügen.';

  @override
  String get deleteFromServerAction => 'Vom Server löschen';

  @override
  String get deleteFromServerTitle => 'Vom Server löschen';

  @override
  String deleteFromServerContent(String title) {
    return '\"$title\" aus Audiobookshelf entfernen?';
  }

  @override
  String deletedFromServer(String title) {
    return '\"$title\" gelöscht';
  }

  @override
  String get deleteFromServerFailed =>
      'Konnte dies nicht löschen. Überprüfe die Server-Protokolle.';

  @override
  String get playlistNotFound => 'Playlist nicht gefunden';

  @override
  String get deletePlaylist => 'Playlist löschen';

  @override
  String get deletePlaylistContent =>
      'Möchtest du diese Playlist wirklich löschen?';

  @override
  String get newPlaylist => 'Neue Playlist';

  @override
  String get playlistNameHint => 'Name der Playlist';

  @override
  String addedToName(String name) {
    return 'Zu \"$name\" hinzugefügt';
  }

  @override
  String get failedToAdd => 'Hinzufügen fehlgeschlagen';

  @override
  String get newCollection => 'Neue Sammlung';

  @override
  String get collectionNameHint => 'Name der Sammlung';

  @override
  String get listsNewCollectionSubtitle =>
      'Bücher in einer Liste gruppieren, die Sie behalten';

  @override
  String get listsNewCollectionNeedsBookSubtitle =>
      'Beginne mit mindestens einem Buch';

  @override
  String get listsNewPlaylistSubtitle =>
      'Stelle die Bücher in der Reihenfolge zusammen, in der du sie anhören möchtest';

  @override
  String get listsAddBooksNow => 'Bücher jetzt hinzufügen';

  @override
  String get listsPickBooksNext =>
      'Du wirst als nächstes Bücher aussuchen. Eine Sammlung auf diesem Server benötigt mindestens eines.';

  @override
  String get listsCreate => 'Erstellen';

  @override
  String get listsCollectionNeedsBook =>
      'Eine Sammlung muss mindestens ein Buch enthalten, daher wurde nichts angelegt.';

  @override
  String get listsCreateFailed => 'Konnte es nicht erstellen';

  @override
  String get castToDevice => 'An Gerät casten';

  @override
  String get settingsGroupCasting => 'Casting';

  @override
  String get castThroughPhoneLabel => 'Cast through this phone';

  @override
  String get castThroughPhoneSubtitle =>
      'For a server your cast device can\'t reach on its own. The phone has to stay on the same Wi-Fi while casting';

  @override
  String get castNarratedUnavailable =>
      'A book narrated from its ebook can\'t be cast';

  @override
  String get searchingForCastDevices => 'Suche nach Cast-Geräten...';

  @override
  String get castDevice => 'Cast-Gerät';

  @override
  String get stopCasting => 'Cast beenden';

  @override
  String get disconnect => 'Trennen';

  @override
  String get audioOutput => 'Audioausgabe';

  @override
  String get noOutputDevicesFound => 'Keine Ausgabegeräte gefunden';

  @override
  String get welcomeToAbsorb => 'Willkommen bei Absorb';

  @override
  String get welcomeTagline => 'Ein Audiobookshelf-Client.';

  @override
  String get welcomeAbsorbingTitle => 'Absorbing';

  @override
  String get welcomeAbsorbingIntro =>
      'Wir verwenden \"Absorb\" anstelle von \"abspielen\" und \"hören\".';

  @override
  String get welcomeAbsorbingTabBullet => 'Absorbing-Tab - was du gerade hörst';

  @override
  String get welcomeAbsorbButtonBullet => 'Absorb-Button - Wiedergabe starten';

  @override
  String get welcomeFullyAbsorbBullet => 'Fully Absorb - als beendet markieren';

  @override
  String get welcomeGettingAroundTitle => 'Zurechtfinden';

  @override
  String get welcomeGettingAroundBody =>
      'Tippe auf ein Cover, um die Details zu öffnen. Weiterhören-Karten sind anders - tippe für sofortige Wiedergabe, lange drücken für Details.';

  @override
  String get welcomeMakeItYoursTitle => 'Mach es zu deinem';

  @override
  String get welcomeMakeItYoursBody =>
      'Stöbere in den Einstellungen und passe Absorb deinem Geschmack an. Der Bereich Tipps & versteckte Funktionen lohnt sich auf jeden Fall.';

  @override
  String get getStarted => 'Los geht\'s';

  @override
  String get showMore => 'Mehr anzeigen';

  @override
  String get showLess => 'Weniger anzeigen';

  @override
  String get readMore => 'Weiterlesen';

  @override
  String get removeDownloadQuestion => 'Download entfernen?';

  @override
  String get removeDownloadContent => 'Dies wird von deinem Gerät entfernt.';

  @override
  String get removeWhichDownload =>
      'Das Hörbuch und E-Book sind beide auf diesem Gerät. Wähle was entfernt werden soll.';

  @override
  String get downloadRemoved => 'Download entfernt';

  @override
  String get finished => 'Beendet';

  @override
  String get saved => 'Heruntergeladen';

  @override
  String get selectLibrary => 'Bibliothek auswählen';

  @override
  String get switchLibraryTooltip => 'Bibliothek wechseln';

  @override
  String get refreshTooltip => 'Aktualisieren';

  @override
  String get openNowPlayingTooltip => 'Aktuelle Wiedergabe öffnen';

  @override
  String get previousChapterTooltip => 'Vorheriges Kapitel';

  @override
  String get nextChapterTooltip => 'Nächstes Kapitel';

  @override
  String get noBooksFound => 'Keine Bücher gefunden';

  @override
  String get userFallback => 'Benutzer';

  @override
  String get rootAdmin => 'Root-Admin';

  @override
  String get admin => 'Admin';

  @override
  String get serverAdmin => 'Server-Admin';

  @override
  String get serverAdminSubtitle =>
      'Benutzer, Bibliotheken & Server-Einstellungen verwalten';

  @override
  String serverUpdateAvailable(String version) {
    return 'Serverupdate $version verfügbar';
  }

  @override
  String get justNow => 'Gerade eben';

  @override
  String minutesAgo(int count) {
    return 'vor $count Min.';
  }

  @override
  String hoursAgo(int count) {
    return 'vor $count Std.';
  }

  @override
  String daysAgo(int count) {
    return 'vor $count T.';
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
  String get coverPlayPause => 'Cover Play/Pause';

  @override
  String get coverPlayPauseOnSubtitle =>
      'An - tippe auf das Cover für Play/Pause';

  @override
  String get coverPlayPauseOffSubtitle =>
      'Aus - eigener Play/Pause-Button in den Steuerelementen';

  @override
  String get cardBackground => 'Kartenhintergrund';

  @override
  String get cardBackgroundBlurred => 'Verschwommen';

  @override
  String get cardBackgroundGradient => 'Farbverlauf';

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
      'Wiedergabe stoppt, manuelle Warteschlange oder Auto-Absorb des nächsten Elements';

  @override
  String get queueModeSeriesLabel => 'Serie';

  @override
  String get queueModeShowLabel => 'Sendung';

  @override
  String get queueModeInfoSeries => 'Serie';

  @override
  String get queueModeInfoSeriesDesc =>
      'Spielt automatisch das nächste Buch einer Serie oder die nächste Episode einer Podcast-Sendung ab.';

  @override
  String get resetButtonGridQuestion => 'Button-Raster zurücksetzen?';

  @override
  String get resetButtonGridContent =>
      'Dies stellt das Standard-Button-Layout, die Reihenfolge und die Schaltereinstellungen wieder her.';

  @override
  String get reset => 'Zurücksetzen';

  @override
  String get buttonGridReset => 'Button-Raster zurückgesetzt';

  @override
  String get resetButtonGrid => 'Button-Raster zurücksetzen';

  @override
  String get chapterBarrierOnRewind => 'Kapitelgrenze beim Zurückspulen';

  @override
  String get chapterBarrierInfoTitle => 'Kapitelgrenze';

  @override
  String get chapterBarrierInfoContent =>
      'Beim Zurückspulen springt die Wiedergabe an den Anfang des aktuellen Kapitels, statt ins vorherige zu wechseln.\n\nTippe innerhalb von 2 Sekunden zweimal auf den Zurückspulen-Button, um die Grenze zu durchbrechen.';

  @override
  String get chapterBarrierOnRewindOnSubtitle =>
      'An - Zurückspulen springt zum Kapitelanfang';

  @override
  String get chapterBarrierOnRewindOffSubtitle =>
      'Aus - Zurückspulen überschreitet Kapitelgrenzen';

  @override
  String autoRewindOnSubtitleFormat(String min, String max) {
    return 'An - $min Sek. bis $max Sek. je nach Pausenlänge';
  }

  @override
  String get rewindOnSessionStart => 'Zurückspulen bei Sitzungsstart';

  @override
  String get rewindOnSessionStartInfoContent =>
      'Das normale Auto-Zurückspulen wird ausgelöst, wenn du innerhalb einer aktiven Sitzung aus einer Pause fortsetzt. Diese Einstellung fügt ein Zurückspulen beim Start einer komplett neuen Sitzung hinzu - zum Beispiel nach dem Schließen der App, gestoppter Wiedergabe oder beim frischen Öffnen der App.\n\nWenn aktiviert, springt die Wiedergabe zu Beginn jeder neuen Sitzung um den vollen maximalen Zurückspul-Wert zurück, damit du noch einmal hörst, wo du aufgehört hast.';

  @override
  String rewindOnSessionStartOnSubtitle(String seconds) {
    return 'An - spult bei einer neuen Sitzung um $seconds Sek. zurück';
  }

  @override
  String rewindActivationDelayValue(String seconds) {
    return '$seconds Sek.+';
  }

  @override
  String rewindRangeValue(String min, String max) {
    return '$min Sek. - $max Sek.';
  }

  @override
  String rewindSecondsPause(String seconds) {
    return '$seconds Sek. Pause';
  }

  @override
  String rewindMinPause(String minutes) {
    return '$minutes Min. Pause';
  }

  @override
  String rewindHrPause(String hours) {
    return '$hours Std. Pause';
  }

  @override
  String get rewindOneHrPause => '1 Std. Pause';

  @override
  String speedValue(String speed) {
    return '${speed}x';
  }

  @override
  String secondsValue(String seconds) {
    return '$seconds Sek.';
  }

  @override
  String minutesValue(int minutes) {
    return '$minutes Min.';
  }

  @override
  String get chimeBeforeSleep => 'Glocke vor Sleep';

  @override
  String get chimeBeforeSleepOnSubtitle =>
      'Spielt eine sanfte Glocke, bevor der Timer endet';

  @override
  String get chimeBeforeSleepOffSubtitle => 'Keine Tonwarnung vor Sleep';

  @override
  String get windDownDuration => 'Ausklingdauer';

  @override
  String windDownDurationSubtitle(int seconds) {
    return 'Ausblenden und Glocke beginnen $seconds Sek. vor Sleep';
  }

  @override
  String fadeVolumeOnSubtitleDynamic(int seconds) {
    return 'Senkt die Lautstärke schrittweise über die letzten $seconds Sek.';
  }

  @override
  String autoSleepTimerEnabledSubtitle(
    String start,
    String end,
    String duration,
  ) {
    return '$start - $end · $duration';
  }

  @override
  String get endOfChapterShort => 'Kapitelende';

  @override
  String get endOfChapterOnSubtitle => 'Am Ende des aktuellen Kapitels stoppen';

  @override
  String get endOfChapterOffSubtitle => 'Zeitgesteuerten Sleep-Timer verwenden';

  @override
  String get showExplicitBadge => 'Explicit-Abzeichen anzeigen';

  @override
  String get showExplicitBadgeOnSubtitle =>
      'Explicit-Inhalte zeigen ein \"E\"-Abzeichen';

  @override
  String get showExplicitBadgeOffSubtitle =>
      'Aus - Explicit-Abzeichen ausgeblendet';

  @override
  String get showEbookBadge => 'E-Book Abzeichen anzeigen';

  @override
  String get showEbookBadgeOnSubtitle =>
      'Bücher mit einem E-Book zeigen ein Buchsymbol auf dem Titelbild';

  @override
  String get showEbookBadgeOffSubtitle => 'Aus - E-Book Abzeichen versteckt';

  @override
  String get libraryFallback => 'Bibliothek';

  @override
  String get preReleaseUpdatesInfoTitle => 'Pre-Release-Updates';

  @override
  String get preReleaseUpdatesInfoContent =>
      'Wenn aktiviert, informiert dich der Update-Checker auch über Alpha- und Pre-Release-Builds von GitHub. Diese können instabiler sein, enthalten aber die neuesten Funktionen und Korrekturen.';

  @override
  String get includePreReleases => 'Pre-Releases einbeziehen';

  @override
  String get includePreReleasesOnSubtitle =>
      'An - sucht nach Alpha- & Pre-Release-Builds';

  @override
  String get includePreReleasesOffSubtitle => 'Aus - nur stabile Versionen';

  @override
  String get setTooltip => 'Festlegen';

  @override
  String get saveAbsorbBackup => 'Absorb-Backup speichern';

  @override
  String get checkForUpdate => 'Nach Update suchen';

  @override
  String get onLatestVersion => 'Du nutzt die neueste Version';

  @override
  String get updateAvailable => 'Update verfügbar';

  @override
  String get preReleaseAvailable => 'Pre-Release verfügbar';

  @override
  String updateDialogContent(String kind, String latest, String current) {
    return 'Eine neue $kind von Absorb ist verfügbar: $latest\n\nDu hast $current.';
  }

  @override
  String get updateKindPreRelease => 'Pre-Release-Version';

  @override
  String get updateKindVersion => 'Version';

  @override
  String get downloadButton => 'Herunterladen';

  @override
  String get updateDownloading => 'Update wird heruntergeladen...';

  @override
  String get updateInstallPermissionDenied =>
      'Installationsberechtigung verweigert. Aktiviere für Absorb in den Systemeinstellungen \"Unbekannte Apps installieren\".';

  @override
  String get updateOpeningInBrowser =>
      'Das In-App-Update ist fehlgeschlagen, Browser wird geöffnet';

  @override
  String get sendToEreader => 'An E-Reader senden';

  @override
  String sendingToEreader(String device) {
    return 'Sende an $device...';
  }

  @override
  String sendToEreaderSuccess(String device) {
    return 'Gesendet an $device';
  }

  @override
  String get sendToEreaderFailed => 'Das E-Book konnte nicht gesendet werden';

  @override
  String get pickEreaderDevice => 'Wähle ein Gerät';

  @override
  String get adminEmail => 'E-Mail';

  @override
  String get adminEmailSubtitle => 'SMTP und E-Reader-Geräte';

  @override
  String get smtpSection => 'SMTP';

  @override
  String get smtpSetupGuide => 'Einrichtungsanleitung';

  @override
  String get smtpHost => 'Host';

  @override
  String get smtpPort => 'Port';

  @override
  String get smtpSecure => 'Sicher';

  @override
  String get smtpRejectUnauthorized => 'Unzulässiges TLS ablehnen';

  @override
  String get smtpUser => 'Benutzername';

  @override
  String get smtpPass => 'Passwort';

  @override
  String get smtpFromAddress => 'Absenderadresse';

  @override
  String get smtpTestAddress => 'Testadresse';

  @override
  String get smtpSendTest => 'Test senden';

  @override
  String get smtpSaveSettings => 'Speichern';

  @override
  String get smtpSaved => 'E-Mail-Einstellungen gespeichert';

  @override
  String get smtpSaveFailed =>
      'Die E-Mail-Einstellungen konnten nicht gespeichert werden';

  @override
  String get smtpTestSent => 'Test-E-Mail gesendet';

  @override
  String get smtpTestFailed => 'Test-E-Mail fehlgeschlagen';

  @override
  String get ereaderDevicesTitle => 'E-Reader-Geräte';

  @override
  String get ereaderDevicesEmpty =>
      'Noch keine Geräte. Füge unten eines hinzu.';

  @override
  String get addEreaderDevice => 'Gerät hinzufügen';

  @override
  String get editEreaderDevice => 'Gerät bearbeiten';

  @override
  String get deleteEreaderDevice => 'Löschen';

  @override
  String get ereaderDeviceName => 'Name';

  @override
  String get ereaderDeviceEmail => 'E-Mail';

  @override
  String get ereaderAvailability => 'Wer kann dieses Gerät verwenden';

  @override
  String get ereaderAvailAdminOrUp => 'Nur für Administratoren';

  @override
  String get ereaderAvailUserOrUp => 'Alle Benutzer';

  @override
  String get ereaderAvailGuestOrUp => 'Jeder';

  @override
  String get ereaderAvailSpecificUsers => 'Bestimmte Benutzer';

  @override
  String ereaderSpecificUsersN(int count) {
    return 'Bestimmte Benutzer ($count)';
  }

  @override
  String get ereaderDevicesSaved => 'Geräte gespeichert';

  @override
  String get ereaderDevicesSaveFailed =>
      'Geräte konnten nicht gespeichert werden';

  @override
  String libraryCountOne(int count) {
    return '$count Bibliothek';
  }

  @override
  String libraryCountOther(int count) {
    return '$count Bibliotheken';
  }

  @override
  String serverVersionLabel(String version) {
    return 'Server $version';
  }

  @override
  String appVersionServerSuffix(String version) {
    return '  ·  Server $version';
  }

  @override
  String backupDateFormat(int month, int day, int year) {
    return '$day.$month.$year';
  }

  @override
  String get backupDetailsSeparator => ' · ';

  @override
  String get bookmarksSortedByPositionReversed =>
      'Nach Position sortiert (umgekehrt)';

  @override
  String bookmarksJumpShortContent(String title, String position) {
    return '\"$title\" bei $position';
  }

  @override
  String get deleteBookmarkQuestion => 'Lesezeichen löschen?';

  @override
  String get cardIconsOnlyChip => 'Nur Symbole';

  @override
  String get cardMoreInGridChip => '\"Mehr\" im Raster';

  @override
  String get cardLayoutHidden => 'Ausgeblendet';

  @override
  String get speed => 'Geschwindigkeit';

  @override
  String get details => 'Details';

  @override
  String get episodeDetailsLabel => 'Episoden-Details';

  @override
  String get bookDetailsLabel => 'Buch-Details';

  @override
  String get equalizerShort => 'EQ';

  @override
  String get equalizerLabel => 'Equalizer';

  @override
  String get cast => 'Cast';

  @override
  String castingToDevice(String device) {
    return 'Cast an $device';
  }

  @override
  String castToDeviceNamed(String device) {
    return 'An $device casten';
  }

  @override
  String get historyShort => 'Verlauf';

  @override
  String atPosition(String position) {
    return 'bei $position';
  }

  @override
  String chaptersChip(int count) {
    return '$count Kapitel';
  }

  @override
  String chapterNumber(int number) {
    return 'Kapitel $number';
  }

  @override
  String kbpsValue(int value) {
    return '$value kbps';
  }

  @override
  String get fileInfoTitle => 'Datei-Informationen';

  @override
  String fileInfoFileCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Dateien',
      one: '1 Datei',
    );
    return '$_temp0';
  }

  @override
  String get fileInfoNone => 'Dieses Buch hat keine Datei-Informationen.';

  @override
  String get fileInfoAudio => 'Audio';

  @override
  String get fileInfoEbook => 'E-Book';

  @override
  String get fileInfoOther => 'Andere Dateien';

  @override
  String get fileInfoBookOrbitNote =>
      'BookOrbit gibt weder den Codec noch die Bitrate an.';

  @override
  String fileInfoChannels(int count) {
    return '$count Kanäle';
  }

  @override
  String get fileInfoCover => 'Titelbild';

  @override
  String get fileInfoMetadata => 'Metadaten';

  @override
  String get fileInfoSupplement => 'Extra';

  @override
  String get fileInfoPathCopied => 'Pfad kopiert';

  @override
  String get resetMayNotHaveSynced =>
      'Zurücksetzen wurde möglicherweise nicht synchronisiert - prüfe deinen Server';

  @override
  String failedToDownloadEbook(int code) {
    return 'E-Book konnte nicht heruntergeladen werden ($code)';
  }

  @override
  String get serverReturnedErrorPage =>
      'Der Server hat eine Fehlerseite statt der E-Book-Datei zurückgegeben';

  @override
  String ebookSaved(String filename) {
    return 'Gespeichert: $filename';
  }

  @override
  String errorSavingEbook(String error) {
    return 'Fehler beim Speichern des E-Books: $error';
  }

  @override
  String failedToSaveError(String error) {
    return 'Speichern fehlgeschlagen: $error';
  }

  @override
  String get adminBackupsLabel => 'Backups';

  @override
  String get adminListeningNow => 'Hört gerade';

  @override
  String get adminLibraries => 'Bibliotheken';

  @override
  String get adminLibraryShows => 'Sendungen';

  @override
  String get adminLibraryBooks => 'Bücher';

  @override
  String get adminLibraryFolders => 'Ordner';

  @override
  String get adminLibrarySize => 'Größe';

  @override
  String get adminLibraryDuration => 'Dauer';

  @override
  String adminLibraryIssues(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fehlende oder ungültige Elemente',
      one: '1 fehlendes oder ungültiges Element',
    );
    return '$_temp0';
  }

  @override
  String get adminLibraryReview => 'Überprüfung';

  @override
  String get adminMissingTitle => 'Fehlende Elemente';

  @override
  String adminMissingSubtitle(String library) {
    return 'Einträge in $library, deren Dateien fehlen oder nicht lesbar sind';
  }

  @override
  String get adminMissingNone => 'Keine fehlenden oder ungültigen Elemente';

  @override
  String get adminMissingBadge => 'Fehlend';

  @override
  String get adminInvalidBadge => 'Ungültig';

  @override
  String get adminMissingDeleteTitle => 'Eintrag entfernen';

  @override
  String adminMissingDeleteOneContent(String title) {
    return '\"$title\" aus Audiobookshelf entfernen?';
  }

  @override
  String adminMissingDeleteManyContent(int count) {
    return '$count Einträge aus Audiobookshelf entfernen?';
  }

  @override
  String adminMissingDeleteCount(int count) {
    return '\"$count\" löschen';
  }

  @override
  String adminMissingRemovedOne(String title) {
    return '\"$title\" entfernt';
  }

  @override
  String adminMissingRemovedMany(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Einträge entfernt',
      one: '1 Eintrag entfernt',
    );
    return '$_temp0';
  }

  @override
  String get adminMissingDeleteFailed => 'Fehler beim Löschen des Eintrags';

  @override
  String get adminMatchAction => 'Abgleichen';

  @override
  String adminMatchingStarted(String name) {
    return 'Abgleich für $name gestartet';
  }

  @override
  String get adminMatchFailed => 'Fehlgeschlagen';

  @override
  String adminScanFailed(String name) {
    return 'Scan von $name fehlgeschlagen';
  }

  @override
  String get adminPurgeCacheFailed => 'Fehlgeschlagen';

  @override
  String get adminUsersRootBadge => 'root';

  @override
  String get adminUsersAdminBadge => 'admin';

  @override
  String get adminUsersDisabledBadge => 'deaktiviert';

  @override
  String get adminUsersEditUserTooltip => 'Benutzer bearbeiten';

  @override
  String get adminUsersOnlineNow => 'Jetzt online';

  @override
  String adminUsersLastSeen(String time) {
    return 'Zuletzt gesehen $time';
  }

  @override
  String get adminUsersNever => 'Nie';

  @override
  String get adminUsersTotal => 'Gesamt';

  @override
  String get adminUsersNoReadingActivity => 'Keine Leseaktivität';

  @override
  String get adminUsersLoadingDots => 'Wird geladen...';

  @override
  String get adminUsersLoadMoreSessions => 'Weitere Sitzungen laden';

  @override
  String get adminUsersNoRecentSessions => 'Keine aktuellen Sitzungen';

  @override
  String get adminUsersLibraryProgress => 'Bibliotheksfortschritt';

  @override
  String adminUsersLoadMoreRemaining(int count) {
    return 'Mehr laden ($count übrig)';
  }

  @override
  String adminUsersMonthsAgo(int count) {
    return 'vor $count Mon.';
  }

  @override
  String get adminUsersNewUser => 'Neuer Benutzer';

  @override
  String get adminUsersEditUser => 'Benutzer bearbeiten';

  @override
  String get adminUsersUsername => 'Benutzername';

  @override
  String get adminUsersEnterUsername => 'Benutzernamen eingeben';

  @override
  String get adminUsersPassword => 'Passwort';

  @override
  String get adminUsersNewPassword => 'Neues Passwort';

  @override
  String get adminUsersEnterPassword => 'Passwort eingeben';

  @override
  String get adminUsersLeaveBlankToKeep =>
      'Leer lassen, um aktuelles zu behalten';

  @override
  String get adminUsersAccountType => 'Kontotyp';

  @override
  String get adminUsersTypeGuest => 'Gast';

  @override
  String get adminUsersTypeUser => 'Benutzer';

  @override
  String get adminUsersTypeAdmin => 'Admin';

  @override
  String get adminUsersStatus => 'Status';

  @override
  String get adminUsersAccountActive => 'Konto aktiv';

  @override
  String get adminUsersAccountActiveSub =>
      'Deaktivierte Konten können sich nicht anmelden';

  @override
  String get adminUsersLocked => 'Gesperrt';

  @override
  String get adminUsersLockedSub => 'Verhindert Passwortänderungen';

  @override
  String get adminUsersPermissions => 'Berechtigungen';

  @override
  String get adminUsersPermDownload => 'Herunterladen';

  @override
  String get adminUsersPermUpdate => 'Aktualisieren';

  @override
  String get adminUsersPermUpdateSub =>
      'Metadaten und Bibliothekselemente bearbeiten';

  @override
  String get adminUsersPermDelete => 'Löschen';

  @override
  String get adminUsersPermUpload => 'Hochladen';

  @override
  String get adminUsersPermExplicit => 'Explicit-Inhalte';

  @override
  String get adminUsersLibraryAccess => 'Bibliothekszugriff';

  @override
  String get adminUsersAccessAllLibraries => 'Zugriff auf alle Bibliotheken';

  @override
  String get adminUsersCreateUser => 'Benutzer erstellen';

  @override
  String get adminUsersSaveChanges => 'Änderungen speichern';

  @override
  String get adminUsersUsernameRequired => 'Benutzername erforderlich';

  @override
  String get adminUsersPickLibrary =>
      'Pick at least one library, or turn on access to all libraries';

  @override
  String get adminUsersPasswordRequired => 'Passwort erforderlich';

  @override
  String get adminUsersUserCreated => 'Benutzer erstellt';

  @override
  String get adminUsersUserUpdated => 'Benutzer aktualisiert';

  @override
  String get adminUsersFailedCreate => 'Benutzer konnte nicht erstellt werden';

  @override
  String get adminUsersFailedUpdate =>
      'Benutzer konnte nicht aktualisiert werden';

  @override
  String get adminUsersThisUser => 'diesen Benutzer';

  @override
  String get adminUsersDeleteUserTitle => 'Benutzer löschen?';

  @override
  String adminUsersDeleteUserContent(String name) {
    return '$name dauerhaft löschen?';
  }

  @override
  String adminUsersUserDeleted(String name) {
    return '$name gelöscht';
  }

  @override
  String get adminUsersFailedDelete => 'Benutzer konnte nicht gelöscht werden';

  @override
  String get adminUsersUnlinkOpenId => 'OpenID trennen';

  @override
  String get adminUsersUnlinkOpenIdTitle => 'OpenID trennen?';

  @override
  String adminUsersUnlinkOpenIdContent(String name) {
    return 'OpenID-Verbindung für $name entfernen? Der Benutzer muss sich später erneut mit OpenID anmelden, um wieder Zugriff zu erhalten.';
  }

  @override
  String get adminUsersOpenIdUnlinked => 'OpenID getrennt';

  @override
  String get adminUsersFailedUnlinkOpenId => 'Konnte OpenID nicht trennen';

  @override
  String adminUsersByAuthor(String author) {
    return 'von $author';
  }

  @override
  String get adminUsersListened => 'Gehört';

  @override
  String get adminUsersStartedAtPosition => 'Gestartet bei Position';

  @override
  String get adminUsersEndedAtPosition => 'Beendet bei Position';

  @override
  String get adminUsersTotalDuration => 'Gesamtdauer';

  @override
  String get adminUsersStarted => 'Gestartet';

  @override
  String get adminUsersUpdated => 'Aktualisiert';

  @override
  String get adminUsersClient => 'Client';

  @override
  String get adminUsersDevice => 'Gerät';

  @override
  String get adminUsersOs => 'Betriebssystem';

  @override
  String get adminUsersPlayMethod => 'Wiedergabemethode';

  @override
  String get adminUsersPlayDirect => 'Direktwiedergabe';

  @override
  String get adminUsersPlayDirectStream => 'Direkt-Stream';

  @override
  String get adminUsersPlayTranscode => 'Transcodieren';

  @override
  String get adminUsersPlayLocal => 'Lokal';

  @override
  String get adminPodcastsCheckNewEpisodesTitle => 'Auf neue Episoden prüfen';

  @override
  String get adminPodcastsCheckNewEpisodesContent =>
      'Dies prüft die RSS-Feeds aller Podcasts und lädt alle gefundenen neuen Episoden herunter (sofern Auto-Download aktiviert ist).';

  @override
  String get adminPodcastsCheckNewEpisodesSubtitle =>
      'RSS-Feed durchsuchen und neue Episoden herunterladen';

  @override
  String get adminPodcastsCheck => 'Prüfen';

  @override
  String get adminPodcastsCheckingForNew => 'Suche nach neuen Episoden…';

  @override
  String get adminPodcastsCheckingForNewDots => 'Suche nach neuen Episoden...';

  @override
  String get adminPodcastsFailedCheckEpisodes =>
      'Episoden konnten nicht geprüft werden';

  @override
  String get adminPodcastsCheckFeedsTooltip => 'Feeds auf neue Episoden prüfen';

  @override
  String get adminPodcastsNoPodcastsYet => 'Noch keine Podcasts';

  @override
  String get adminPodcastsTapPlusHint =>
      'Tippe auf +, um Sendungen zu suchen und hinzuzufügen';

  @override
  String adminPodcastsEpisodesCount(int count) {
    return '$count Episoden';
  }

  @override
  String get adminPodcastsAddPodcast => 'Podcast hinzufügen';

  @override
  String get adminPodcastsCouldNotFindFeed => 'Podcast-Feed nicht gefunden';

  @override
  String get adminPodcastsSearchHint => 'Podcasts suchen…';

  @override
  String get adminPodcastsSearchItunesHint => 'iTunes durchsuchen...';

  @override
  String adminPodcastsSearchItunesFor(String query) {
    return 'Durchsuche iTunes nach \"$query\"';
  }

  @override
  String get adminPodcastsNoPodcastsFound => 'Keine Podcasts gefunden';

  @override
  String get adminPodcastsRelToday => 'Heute';

  @override
  String adminPodcastsWeeksAgo(int count) {
    return 'vor $count Wo.';
  }

  @override
  String adminPodcastsMonthsAgo(int count) {
    return 'vor $count Mon.';
  }

  @override
  String adminPodcastsYearsAgo(int count) {
    return 'vor $count J.';
  }

  @override
  String adminPodcastsUpdated(String when) {
    return 'Aktualisiert $when';
  }

  @override
  String get adminPodcastsGenreAll => 'Alle';

  @override
  String get adminPodcastsGenreArts => 'Kunst';

  @override
  String get adminPodcastsGenreComedy => 'Comedy';

  @override
  String get adminPodcastsGenreEducation => 'Bildung';

  @override
  String get adminPodcastsGenreTvFilm => 'TV & Film';

  @override
  String get adminPodcastsGenreMusic => 'Musik';

  @override
  String get adminPodcastsGenreNews => 'Nachrichten';

  @override
  String get adminPodcastsGenreReligion => 'Religion';

  @override
  String get adminPodcastsGenreScience => 'Wissenschaft';

  @override
  String get adminPodcastsGenreSports => 'Sport';

  @override
  String get adminPodcastsGenreTechnology => 'Technik';

  @override
  String get adminPodcastsGenreBusiness => 'Wirtschaft';

  @override
  String get adminPodcastsGenreFiction => 'Fiktion';

  @override
  String get adminPodcastsGenreSocietyCulture => 'Gesellschaft & Kultur';

  @override
  String get adminPodcastsGenreHealthFitness => 'Gesundheit & Fitness';

  @override
  String get adminPodcastsGenreTrueCrime => 'True Crime';

  @override
  String get adminPodcastsGenreHistory => 'Geschichte';

  @override
  String get adminPodcastsGenreKidsFamily => 'Kinder & Familie';

  @override
  String get adminPodcastsPodcastFallback => 'Podcast';

  @override
  String get adminPodcastsEpisodeFallback => 'Episode';

  @override
  String get adminPodcastsNoFeedFound => 'Keine Feed-URL gefunden';

  @override
  String get adminPodcastsNoFeedAvailable => 'Keine Feed-URL verfügbar';

  @override
  String adminPodcastsAddedToLibrary(String title) {
    return '$title zur Bibliothek hinzugefügt';
  }

  @override
  String adminPodcastsFailedToAdd(String title) {
    return '$title konnte nicht hinzugefügt werden';
  }

  @override
  String adminPodcastsEpisodesInFeed(int count) {
    return '$count Episoden im Feed';
  }

  @override
  String adminPodcastsMoreEpisodes(int count) {
    return '+ $count weitere Episoden';
  }

  @override
  String get adminPodcastsAdding => 'Wird hinzugefügt…';

  @override
  String get adminPodcastsAddToLibrary => 'Zur Bibliothek hinzufügen';

  @override
  String get adminPodcastsRemoveShowTitle => 'Sendung entfernen?';

  @override
  String adminPodcastsRemoveShowContent(String title) {
    return '\"$title\" und alle Episoden vom Server entfernen? Dies kann nicht rückgängig gemacht werden.';
  }

  @override
  String adminPodcastsRemovedShow(String title) {
    return '\"$title\" entfernt';
  }

  @override
  String get adminPodcastsFailedRemoveShow =>
      'Sendung konnte nicht entfernt werden';

  @override
  String get adminPodcastsRemoveShowTooltip => 'Sendung entfernen';

  @override
  String get adminPodcastsSelectMultipleTooltip => 'Mehrere auswählen';

  @override
  String adminPodcastsDownloadedCount(int count) {
    return '$count heruntergeladen';
  }

  @override
  String get adminPodcastsTabDownloaded => 'Heruntergeladen';

  @override
  String get adminPodcastsTabFeed => 'Feed';

  @override
  String get adminPodcastsTabSettings => 'Einstellungen';

  @override
  String adminPodcastsDownloadingEpisode(String title) {
    return '\"$title\" wird heruntergeladen';
  }

  @override
  String get adminPodcastsFailedDownload => 'Download fehlgeschlagen';

  @override
  String get adminPodcastsDeleteEpisodeTitle => 'Episode löschen?';

  @override
  String adminPodcastsDeleteEpisodeContent(String title) {
    return '\"$title\" löschen?';
  }

  @override
  String get adminPodcastsDeleted => 'Gelöscht';

  @override
  String get adminPodcastsFailed => 'Fehlgeschlagen';

  @override
  String get adminPodcastsDeleteEpisodesTitle => 'Episoden löschen?';

  @override
  String adminPodcastsDeleteEpisodesContent(int count) {
    return '$count Episode(n) vom Server löschen?';
  }

  @override
  String adminPodcastsDeletedEpisodes(int count) {
    return '$count Episode(n) gelöscht';
  }

  @override
  String get adminPodcastsBrowseFeedToDownload =>
      'Feed durchsuchen, um herunterzuladen';

  @override
  String get adminPodcastsDownloadingDots => 'Wird heruntergeladen...';

  @override
  String adminPodcastsDeleteEpisodesCount(int count) {
    return '$count Episode(n) löschen';
  }

  @override
  String adminPodcastsDownloadingCount(int count) {
    return '$count Episode(n) werden heruntergeladen';
  }

  @override
  String adminPodcastsDownloadEpisodesCount(int count) {
    return '$count Episode(n) herunterladen';
  }

  @override
  String get adminPodcastsLookForEpisodesAfter => 'Nach Episoden suchen ab';

  @override
  String get adminPodcastsSelectDate => 'Datum auswählen';

  @override
  String get adminPodcastsMaxEpisodes => 'Max. Episoden zum Herunterladen';

  @override
  String adminPodcastsNoNewEpisodesAfter(String date) {
    return 'Keine neuen Episoden nach $date gefunden';
  }

  @override
  String adminPodcastsFoundNewEpisodes(int count) {
    return '$count neue Episode(n) gefunden - werden heruntergeladen';
  }

  @override
  String get adminPodcastsFailedToCheckNew =>
      'Suche nach neuen Episoden fehlgeschlagen';

  @override
  String get adminPodcastsCheckAndDownload => 'Prüfen & Herunterladen';

  @override
  String get adminPodcastsMatchPodcast => 'Podcast zuordnen';

  @override
  String get adminPodcastsMatchPodcastSubtitle =>
      'iTunes durchsuchen, um Cover und Metadaten zu aktualisieren';

  @override
  String get adminPodcastsAutoDownloadNewEpisodes =>
      'Neue Episoden automatisch herunterladen';

  @override
  String get adminPodcastsAutoDownloadOnSubtitle =>
      'Server lädt neue Episoden automatisch herunter';

  @override
  String get adminPodcastsAutoDownloadOffSubtitle =>
      'Neue Episoden werden nicht automatisch heruntergeladen';

  @override
  String get adminPodcastsFailedAutoDownloadUpdate =>
      'Auto-Download-Einstellung konnte nicht aktualisiert werden';

  @override
  String get adminPodcastsMaxEpisodesToKeep => 'Anzahl zu behaltender Episoden';

  @override
  String get adminPodcastsMaxEpisodesToKeepHelp =>
      '0 behält alle Episoden. Nachdem eine neue Episode heruntergeladen wurde, wird die älteste Episode entfernt so fern das Limit erreicht wurde.';

  @override
  String get adminPodcastsNoEpisodeLimit => 'Kein Limit';

  @override
  String get adminPodcastsEpisodeLimitInvalid =>
      '0 oder eine ganze Zahl eingeben';

  @override
  String get adminPodcastsCheckSchedule => 'Prüfplan';

  @override
  String get adminPodcastsFrequency => 'Häufigkeit';

  @override
  String get adminPodcastsFreqHourly => 'Stündlich';

  @override
  String get adminPodcastsFreqDaily => 'Täglich';

  @override
  String get adminPodcastsFreqWeekly => 'Wöchentlich';

  @override
  String get adminPodcastsDay => 'Tag';

  @override
  String get adminPodcastsTime => 'Uhrzeit';

  @override
  String get adminPodcastsDaySun => 'So';

  @override
  String get adminPodcastsDayMon => 'Mo';

  @override
  String get adminPodcastsDayTue => 'Di';

  @override
  String get adminPodcastsDayWed => 'Mi';

  @override
  String get adminPodcastsDayThu => 'Do';

  @override
  String get adminPodcastsDayFri => 'Fr';

  @override
  String get adminPodcastsDaySat => 'Sa';

  @override
  String get adminPodcastsFeedUrl => 'Feed-URL';

  @override
  String get adminPodcastsBack => 'Zurück';

  @override
  String get adminPodcastsRootOnly => 'Nur Hauptverzeichnis';

  @override
  String get adminPodcastsDeleting => 'Wird gelöscht...';

  @override
  String get adminPodcastsDeleteEpisode => 'Episode löschen';

  @override
  String adminPodcastsSeasonChip(String season) {
    return 'Staffel $season';
  }

  @override
  String adminPodcastsEpChip(String number) {
    return 'Ep. $number';
  }

  @override
  String get adminPodcastsApplyingMatch => 'Zuordnung wird angewendet...';

  @override
  String get adminPodcastsNoResults => 'Keine Ergebnisse';

  @override
  String get adminPodcastsPodcastMatched =>
      'Podcast zugeordnet und aktualisiert';

  @override
  String get adminPodcastsFailedMatch =>
      'Podcast konnte nicht zugeordnet werden';

  @override
  String get adminPodcastsSelectAll => 'Alles auswählen';

  @override
  String get adminPodcastsSelectAllNew => 'Nur neue';

  @override
  String get adminPodcastsSortNewestFirst => 'Neueste zuerst';

  @override
  String get adminPodcastsSortOldestFirst => 'Älteste zuerst';

  @override
  String get adminPodcastsEditInfo => 'Info bearbeiten';

  @override
  String get adminPodcastsEditInfoSubtitle =>
      'Titel, Beschreibung, Cover und mehr ändern';

  @override
  String get adminPodcastsEditTitle => 'Podcast bearbeiten';

  @override
  String get adminPodcastsReleaseDate => 'Erscheinungsdatum';

  @override
  String get adminPodcastsExplicit => 'Explizit';

  @override
  String get adminPodcastsExplicitSubtitle =>
      'Diesen Podcast als explizit markieren';

  @override
  String get episodeListEpisodeFallback => 'Episode';

  @override
  String get episodeListUnknownPodcast => 'Unbekannter Podcast';

  @override
  String episodeListMarkedFinished(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Episoden als beendet markiert',
      one: '1 Episode als beendet markiert',
    );
    return '$_temp0';
  }

  @override
  String episodeListMarkedUnfinished(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Episoden als unbeendet markiert',
      one: '1 Episode als unbeendet markiert',
    );
    return '$_temp0';
  }

  @override
  String get episodeListUnsubscribeFromNewEpisodes =>
      'Neue Episoden abbestellen';

  @override
  String get episodeListSubscribeToNewEpisodes => 'Neue Episoden abonnieren';

  @override
  String get episodeListSubscribeTitle => 'Diesen Podcast abonnieren?';

  @override
  String get episodeListSubscribeContent =>
      'Neue Episoden werden automatisch heruntergeladen und zu deiner Absorbing-Warteschlange hinzugefügt, sobald sie auf dem Server erscheinen.';

  @override
  String get episodeListSubscribe => 'Abonnieren';

  @override
  String get episodeListShowFinishedEpisodes => 'Beendete Episoden anzeigen';

  @override
  String get episodeListHideFinishedEpisodes => 'Beendete Episoden ausblenden';

  @override
  String get episodeListShowSettings => 'Serien Einstellungen';

  @override
  String get episodeListPlaysNewerToOlder =>
      'Spielt von neueren zu älteren Episoden';

  @override
  String get episodeListPlaysOlderToNewer =>
      'Spielt von älteren zu neueren Episoden';

  @override
  String episodeListEpisodeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Episoden',
      one: '1 Episode',
    );
    return '$_temp0';
  }

  @override
  String episodeListUnfinishedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Folgen',
      one: '1 Folge',
    );
    return '$_temp0';
  }

  @override
  String get episodeListAutoDownloadChip => 'Auto-Download';

  @override
  String get episodeListSubscribedChip => 'Abonniert';

  @override
  String get episodeListExplicitChip => 'Explizit';

  @override
  String get episodeListSortNewest => 'Neueste';

  @override
  String get episodeListSortOldest => 'Älteste';

  @override
  String get episodeListSortBy => 'Episoden sortieren';

  @override
  String get episodeListSortPubDate => 'Veröffentlichungsdatum';

  @override
  String get episodeListSortTitle => 'Titel';

  @override
  String get episodeListSortSeason => 'Staffel';

  @override
  String get episodeListSortEpisode => 'Episoden Nummer';

  @override
  String get episodeListSortFileName => 'Dateiname';

  @override
  String get episodeListSortReverseHint =>
      'Erneut tippen, um Reihenfolge umzukehren';

  @override
  String episodeListAddedToAbsorbing(String title) {
    return '\"$title\" zu Absorbing hinzugefügt';
  }

  @override
  String get episodeDetailEpisodeFallback => 'Episode';

  @override
  String get episodeDetailMarkedNotFinished => 'Als unbeendet markiert';

  @override
  String get episodeDetailMarkedFinishedNice => 'Als beendet markiert - super!';

  @override
  String get episodeDetailMarkAbsorbedContent =>
      'Dies setzt deinen Fortschritt für diese Episode auf 100 %.';

  @override
  String get episodeDetailResetProgressContent =>
      'Dies löscht den gesamten Fortschritt für diese Episode und setzt sie auf den Anfang zurück. Das kann nicht rückgängig gemacht werden.';

  @override
  String get episodeDetailToday => 'Heute';

  @override
  String get episodeDetailYesterday => 'Gestern';

  @override
  String episodeDetailDaysAgo(int count) {
    return 'vor $count T.';
  }

  @override
  String episodeDetailWeeksAgo(int count) {
    return 'vor $count Wo.';
  }

  @override
  String episodeDetailDurationHm(int hours, int minutes) {
    return '$hours Std. $minutes Min.';
  }

  @override
  String episodeDetailDurationM(int minutes) {
    return '$minutes Min.';
  }

  @override
  String get episodeDetailResume => 'Fortsetzen';

  @override
  String get episodeDetailPlayEpisode => 'Episode abspielen';

  @override
  String episodeDetailEpisodeNumber(String number) {
    return 'Episode $number';
  }

  @override
  String episodeDetailSeasonNumber(String number) {
    return 'Staffel $number';
  }

  @override
  String get editMetadataUpdatedFromMatch =>
      'Metadaten aus Zuordnung aktualisiert';

  @override
  String editMetadataConfirmMatch(String title) {
    return 'Dies aktualisiert die Server-Metadaten für dieses Buch mit:\n\n\"$title\"\n\nAlle Felder und das Cover werden auf dem Server überschrieben.';
  }

  @override
  String editMetadataConfirmMatchWithAuthor(String title, String author) {
    return 'Dies aktualisiert die Server-Metadaten für dieses Buch mit:\n\n\"$title\" von $author\n\nAlle Felder und das Cover werden auf dem Server überschrieben.';
  }

  @override
  String get seriesBooksFindMissingTitle => 'Fehlende Bücher finden';

  @override
  String get seriesBooksFindMissingContent =>
      'Dies durchsucht Audible nach Büchern dieser Serie, die in deiner Bibliothek fehlen könnten.\n\nBücher werden zuerst über die ASIN abgeglichen (sofern dein Server ASINs für seine Bücher hat) und greifen dann auf den Titelabgleich zurück. Die Ergebnisse sind möglicherweise nicht ganz genau.';

  @override
  String get seriesBooksCouldNotFindOnAudible =>
      'Diese Serie konnte auf Audible nicht gefunden werden';

  @override
  String seriesBooksMarkAllNotFinishedContent(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Damit wird der Beendet-Status für alle $count Bücher dieser Serie zurückgesetzt.',
      one:
          'Damit wird der Beendet-Status für 1 Buch dieser Serie zurückgesetzt.',
    );
    return '$_temp0';
  }

  @override
  String seriesBooksFullyAbsorbContent(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Damit werden alle $count Bücher dieser Serie als beendet markiert.',
      one: 'Damit wird 1 Buch dieser Serie als beendet markiert.',
    );
    return '$_temp0';
  }

  @override
  String get seriesBooksUnmarkAll => 'Alle aufheben';

  @override
  String get seriesBooksShowAllBooks => 'Alle Bücher anzeigen';

  @override
  String get seriesBooksGroupBySubSeries => 'Nach Unterserie gruppieren';

  @override
  String get seriesBooksLoadingSubSeries => 'Unterserie wird geladen...';

  @override
  String seriesBooksBookCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Bücher',
      one: '1 Buch',
    );
    return '$_temp0';
  }

  @override
  String get seriesBooksDone => 'Fertig';

  @override
  String get seriesBooksExplicitBadge => 'E';

  @override
  String get expandedCardStreaming => 'Streaming';

  @override
  String get expandedCardDeviceFallback => 'Gerät';

  @override
  String bookmarksScreenPositionInBook(String position, String bookTitle) {
    return '$position in $bookTitle';
  }

  @override
  String get bookmarksScreenClose => 'Schließen';

  @override
  String get bookmarksScreenSortNewest => 'Neueste';

  @override
  String get bookmarksScreenSortPosition => 'Position';

  @override
  String statsScreenStreakDays(int count) {
    return '$count T.';
  }

  @override
  String statsScreenSessionCountOne(int count) {
    return '$count Sitzung';
  }

  @override
  String statsScreenSessionCountOther(int count) {
    return '$count Sitzungen';
  }

  @override
  String get statsScreenDayMon => 'Mo';

  @override
  String get statsScreenDayTue => 'Di';

  @override
  String get statsScreenDayWed => 'Mi';

  @override
  String get statsScreenDayThu => 'Do';

  @override
  String get statsScreenDayFri => 'Fr';

  @override
  String get statsScreenDaySat => 'Sa';

  @override
  String get statsScreenDaySun => 'So';

  @override
  String statsScreenDurationHm(int h, int m) {
    return '$h Std. $m Min.';
  }

  @override
  String statsScreenDurationM(int m) {
    return '$m Min.';
  }

  @override
  String get statsScreenDurationLessThanMin => '<1 Min.';

  @override
  String get statsScreenDurationZero => '0 Min.';

  @override
  String statsScreenDurationShortH(int h) {
    return '$h Std.';
  }

  @override
  String statsScreenDurationShortM(int m) {
    return '$m Min.';
  }

  @override
  String get statsScreenCouldNotLoadItem =>
      'Element konnte nicht geladen werden';

  @override
  String get statsScreenCouldNotFindEpisode =>
      'Episode konnte nicht gefunden werden';

  @override
  String statsScreenByAuthor(String author) {
    return 'von $author';
  }

  @override
  String get statsScreenListened => 'Gehört';

  @override
  String get sessionEditTitle => 'Sitzung bearbeiten';

  @override
  String get sessionDayLabel => 'Tag';

  @override
  String get sessionEndPosition => 'Endposition';

  @override
  String get sessionEndPositionHint =>
      'Dies zu ändern kann auch deinen aktuellen Fortschritt aktualisieren.';

  @override
  String get statsViewSessions => 'Sitzungen anzeigen';

  @override
  String statsSessionsForDate(String date) {
    return 'Sitzungen für $date';
  }

  @override
  String get statsNoSessionsForDate =>
      'Keine Hörsitzungen für diesen Tag gefunden';

  @override
  String get statsSearchSessions => 'Sitzungen durchsuchen';

  @override
  String get statsNoSessionSearchResults =>
      'Keine Sitzungen entsprechen deiner Suche';

  @override
  String get statsSessionsLoadFailed =>
      'Sitzungen für diesen Tag konnten nicht geladen werden';

  @override
  String get sessionDeleteConfirmTitle => 'Sitzung löschen?';

  @override
  String get sessionDeleteConfirmBody =>
      'Dies entfernt die Sitzung und senkt die Hörstatistik um deren Zeit. Es kann nicht rückgängig gemacht werden.';

  @override
  String get sessionSaved => 'Sitzung aktualisiert';

  @override
  String get sessionDeleted => 'Sitzung gelöscht';

  @override
  String get sessionSaveFailed => 'Änderungen konnten nicht gespeichert werden';

  @override
  String get sessionDeleteFailed => 'Sitzung konnte nicht gelöscht werden';

  @override
  String get statsScreenStartedAtPosition => 'Gestartet bei Position';

  @override
  String get statsScreenEndedAtPosition => 'Beendet bei Position';

  @override
  String get statsScreenTotalDuration => 'Gesamtdauer';

  @override
  String get statsScreenStarted => 'Gestartet';

  @override
  String get statsScreenUpdated => 'Aktualisiert';

  @override
  String get statsScreenClient => 'Client';

  @override
  String get statsScreenDevice => 'Gerät';

  @override
  String get statsScreenOs => 'Betriebssystem';

  @override
  String get statsScreenPlayMethod => 'Wiedergabemethode';

  @override
  String get statsScreenLoading => 'Lädt...';

  @override
  String get statsScreenJumpToStart => 'Springe zum Anfang';

  @override
  String get statsScreenJumpToEnd => 'Springe zum Ende';

  @override
  String get statsScreenPlayMethodDirect => 'Direktwiedergabe';

  @override
  String get statsScreenPlayMethodDirectStream => 'Direkt-Stream';

  @override
  String get statsScreenPlayMethodTranscode => 'Transcodieren';

  @override
  String get statsScreenPlayMethodLocal => 'Lokal';

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
    return '$day. $month $year um $hour:$minute $ampm';
  }

  @override
  String get statsScreenMonthJan => 'Jan.';

  @override
  String get statsScreenMonthFeb => 'Feb.';

  @override
  String get statsScreenMonthMar => 'März';

  @override
  String get statsScreenMonthApr => 'Apr.';

  @override
  String get statsScreenMonthMay => 'Mai';

  @override
  String get statsScreenMonthJun => 'Juni';

  @override
  String get statsScreenMonthJul => 'Juli';

  @override
  String get statsScreenMonthAug => 'Aug.';

  @override
  String get statsScreenMonthSep => 'Sep.';

  @override
  String get statsScreenMonthOct => 'Okt.';

  @override
  String get statsScreenMonthNov => 'Nov.';

  @override
  String get statsScreenMonthDec => 'Dez.';

  @override
  String get upcomingReleasesTitle => 'Kommende Veröffentlichungen';

  @override
  String get upcomingReleasesRescanTitle => 'Erneut scannen?';

  @override
  String upcomingReleasesRescanContent(int days) {
    return 'Diese Ergebnisse sind $days Tage alt. Veröffentlichungstermine könnten sich geändert haben - möchtest du erneut scannen?';
  }

  @override
  String get upcomingReleasesNotNow => 'Nicht jetzt';

  @override
  String get upcomingReleasesRescan => 'Erneut scannen';

  @override
  String get upcomingReleasesRescanReleaseDate =>
      'Veröffentlichungstermin erneut scannen';

  @override
  String get upcomingReleasesRescanning => 'Wird erneut gescannt...';

  @override
  String upcomingReleasesUpdatedWithDate(String date) {
    return 'Aktualisiert - $date';
  }

  @override
  String get upcomingReleasesNoReleaseDateFound =>
      'Kein Veröffentlichungstermin gefunden';

  @override
  String get upcomingReleasesRescanFailed => 'Erneuter Scan fehlgeschlagen';

  @override
  String get upcomingReleasesRemoveFromList => 'Aus Liste entfernen';

  @override
  String get upcomingReleasesRemovedFromList => 'Aus Liste entfernt';

  @override
  String get upcomingReleasesDateChip => 'Datum';

  @override
  String upcomingReleasesCheckingSeries(String name, int processed, int total) {
    return 'Prüfe $name... ($processed/$total)';
  }

  @override
  String get upcomingReleasesLoadingSeries => 'Serien werden geladen...';

  @override
  String get upcomingReleasesScannedToday => '(heute gescannt)';

  @override
  String get upcomingReleasesScannedYesterday => '(gestern gescannt)';

  @override
  String upcomingReleasesScannedDaysAgo(int days) {
    return '(vor $days Tagen gescannt)';
  }

  @override
  String upcomingReleasesUpcomingCount(int count) {
    return '$count kommend';
  }

  @override
  String upcomingReleasesRecentCount(int count) {
    return '$count kürzlich';
  }

  @override
  String get upcomingReleasesNoneFound =>
      'Keine kommenden oder kürzlichen Veröffentlichungen gefunden';

  @override
  String upcomingReleasesAcrossSeries(String summary, int count) {
    return '$summary in $count Serien';
  }

  @override
  String upcomingReleasesCheckedSeries(int count) {
    return '$count Serien auf Audible geprüft';
  }

  @override
  String upcomingReleasesDateFormat(String month, int day, int year) {
    return '$day. $month $year';
  }

  @override
  String upcomingReleasesSequenceLabel(String sequence) {
    return '#$sequence';
  }

  @override
  String get upcomingReleasesBadgeUpcoming => 'KOMMEND';

  @override
  String get upcomingReleasesBadgeAdded => 'HINZUGEFÜGT';

  @override
  String get upcomingReleasesBadgeMissing => 'FEHLT';

  @override
  String get upcomingReleasesScanSettingsTitle => 'Scan Einstellungen';

  @override
  String get upcomingReleasesFinishedAfterTitle =>
      'Betrachte eine Serie danach beendet an';

  @override
  String get upcomingReleasesFinishedAfterDesc =>
      'Serien, deren letztes Buch älter als das ist, werden während der Scans übersprungen und nur jeden oder jeden zweiten Monat erneut überprüft.';

  @override
  String upcomingReleasesFinishedAfterYears(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Tage',
      one: '1 Tag',
    );
    return '$_temp0';
  }

  @override
  String get upcomingReleasesFinishedAfterNever => 'Niemals';

  @override
  String get upcomingReleasesSkippedTitle => 'Übersprungene Serien';

  @override
  String get upcomingReleasesSkippedNone => 'Noch nichts übersprungen';

  @override
  String upcomingReleasesSkippedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count übersprungen',
      one: '1 übersprungen',
    );
    return '$_temp0';
  }

  @override
  String upcomingReleasesSkippedLastBook(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Das letzte Buch ist $count Jahre her',
      one: 'Das letzte Buch ist ein Jahr her',
      zero: 'Das letzte Buch ist weniger als ein Jahr her',
    );
    return '$_temp0';
  }

  @override
  String get upcomingReleasesSkippedUnmatched =>
      'Keine passende Serie auf Audible gefunden';

  @override
  String get upcomingReleasesSkippedScanNow => 'Jetzt scannen';

  @override
  String get upcomingReleasesSkippedAlwaysScan => 'Immer scannen';

  @override
  String get upcomingReleasesSkippedNeverScan => 'Niemals scannen';

  @override
  String upcomingReleasesSkippedScanFound(String name) {
    return 'Neue Veröffentlichungen in $name gefunden';
  }

  @override
  String upcomingReleasesSkippedScanNone(String name) {
    return 'Nichts Neues in $name';
  }

  @override
  String get upcomingReleasesSkippedOtherLibrary =>
      'Diese Liste kam aus einer anderen Bibliothek. Neu scannen zum Aktualisieren.';

  @override
  String get upcomingReleasesChipUpcoming => 'Bevorstehend';

  @override
  String upcomingReleasesChipMissing(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fehlen',
      one: '1 fehlt',
      zero: 'fehlt',
    );
    return '$_temp0';
  }

  @override
  String get upcomingReleasesNoMissing => 'Keine fehlenden Bücher gefunden';

  @override
  String get upcomingReleasesScanSeries => 'Serie scannen';

  @override
  String get upcomingReleasesScanUpcomingOption =>
      'Bevorstehende Veröffentlichungen';

  @override
  String get upcomingReleasesScanUpcomingOptionDesc =>
      'Schneller Scan nach neuen und bevorstehenden Büchern';

  @override
  String get upcomingReleasesScanDeepOption => 'Tiefer Scan';

  @override
  String get upcomingReleasesScanDeepOptionDesc =>
      'Findet auch fehlende Bücher in jeder Serie - dauert länger';

  @override
  String get upcomingReleasesFirstScanNote =>
      'Der erste Scan überprüft alle Serien auf Audible und kann einige Minuten in Anspruch nehmen. Nachfolgende Scans verlaufen deutlich schneller, sobald deine Serien sortiert sind.';

  @override
  String get upcomingReleasesLastScanReport => 'Letzter Scan-Report';

  @override
  String upcomingReleasesReportChecked(int count) {
    return 'Auf Audible überprüft: $count';
  }

  @override
  String upcomingReleasesReportSkipped(int count) {
    return 'Übersprungen: $count';
  }

  @override
  String upcomingReleasesReportUnmatched(int count) {
    return 'Nicht auf Audible gefunden: $count';
  }

  @override
  String upcomingReleasesReportFailed(int count) {
    return 'Fehler beim Überprüfen: $count';
  }

  @override
  String upcomingReleasesReportFound(int upcoming, int recent) {
    return 'Gefunden: $upcoming demnächst, $recent kürzlich';
  }

  @override
  String upcomingReleasesReportFoundDeep(
    int upcoming,
    int recent,
    int missing,
  ) {
    return 'Gefunden: $upcoming demnächst, $recent kürzlich, $missing fehlend';
  }

  @override
  String upcomingReleasesReportMore(int count) {
    return '+$count mehr';
  }

  @override
  String get upcomingReleasesBadgeNew => 'NEU';

  @override
  String get upcomingReleasesOpenSeries => 'Serie auf Audible öffnen';

  @override
  String get upcomingReleasesOpenLibrarySeries => 'Serie in Bibliothek öffnen';

  @override
  String get upcomingReleasesAsinCopied => 'Serien ASIN kopiert';

  @override
  String get upcomingReleasesSetSeriesAsin => 'Serien ASIN setzen';

  @override
  String get upcomingReleasesSetAsinInstructions =>
      'Suche die Serie auf audible.com und kopiere den Link zur Seite – die ASIN ist der 10-stellige Code, der mit „B0“ beginnt (zum Beispiel B08S2YN3YS). Du kannst auch einfach den gesamten Link einfügen.';

  @override
  String get upcomingReleasesSetAsinHint => 'B0… oder audible.com Link';

  @override
  String get upcomingReleasesSetAsinSave => 'Speichern';

  @override
  String get upcomingReleasesSetAsinInvalid =>
      'Keine ASIN in diesem Text gefunden';

  @override
  String get upcomingReleasesSetAsinSaved => 'Serie verknüpft - Scan läuft';

  @override
  String upcomingReleasesRemoveTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Entferne $count Bücher',
      one: 'Buch entfernt',
    );
    return '$_temp0';
  }

  @override
  String get upcomingReleasesRemoveThisScan => 'Aus diesem Scan entfernen';

  @override
  String get upcomingReleasesRemoveThisScanDesc =>
      'Kann bei einem zukünftigen Scan wieder kommen';

  @override
  String get upcomingReleasesRemoveForever =>
      'Von diesem und zukünftigen Scans entfernen';

  @override
  String get upcomingReleasesRemoveForeverDesc =>
      'Wird in die Liste der entfernten Elemente verschoben, kann jederzeit wiederhergestellt werden';

  @override
  String get upcomingReleasesRemovedForeverToast =>
      'Entfernt - wird bei zukünftigen Scans nicht angezeigt';

  @override
  String get upcomingReleasesRemovedBooksTitle => 'Entfernte Bücher';

  @override
  String upcomingReleasesRemovedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Bücher',
      one: '1 Buch',
    );
    return '$_temp0';
  }

  @override
  String get upcomingReleasesRemovedNone => 'Keine Bücher entfernt';

  @override
  String get upcomingReleasesRestore => 'Wiederherstellen';

  @override
  String get upcomingReleasesRestoredToast => 'Wiederhergestellt';

  @override
  String get upcomingReleasesRestoredNextScan =>
      'Wiederhergestellt - wird nach dem nächsten Scan angezeigt';

  @override
  String upcomingReleasesSelectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ausgewählt',
      one: '1 ausgewählt',
    );
    return '$_temp0';
  }

  @override
  String get upcomingReleasesBulkRequest => 'Anfragen';

  @override
  String get upcomingReleasesBulkRemove => 'Entfernen';

  @override
  String upcomingReleasesBulkRemoved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entfernt',
      one: '1 entfernt',
    );
    return '$_temp0';
  }

  @override
  String upcomingReleasesBulkRequestDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Anfragen gesendet',
      one: '1 Anfrage gesendet',
    );
    return '$_temp0';
  }

  @override
  String upcomingReleasesBulkRequestSkipped(int count) {
    return '$count Übersprungen';
  }

  @override
  String upcomingReleasesBulkScanned(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Serien neu eingescannt',
      one: '1 Serie neu eingescannt',
    );
    return '$_temp0';
  }

  @override
  String upcomingReleasesBulkScanFound(int count) {
    return '$count mit neuen Büchern';
  }

  @override
  String get seriesExcludeFromScan => 'Von Serienscan ausschließen';

  @override
  String get seriesIncludeInScan => 'In den Serien-Scan einbeziehen';

  @override
  String get homeScreenEpisodeFallback => 'Episode';

  @override
  String get libraryScreenUnknownTitle => 'Unbekannter Titel';

  @override
  String get playlistDetailDefaultName => 'Playlist';

  @override
  String playlistDetailItemCount(int count) {
    return '$count Einträge';
  }

  @override
  String get playlistDetailUnfinished => 'Nicht beendet';

  @override
  String get playlistDetailRemoveFromPlaylist => 'Aus Playlist entfernen';

  @override
  String get playlistDetailDone => 'Fertig';

  @override
  String playlistDetailItemsMarkedFinished(int count) {
    return '$count Einträge als beendet markiert';
  }

  @override
  String playlistDetailItemsMarkedUnfinished(int count) {
    return '$count Einträge als nicht beendet markiert';
  }

  @override
  String playlistDetailItemsRemoved(int count) {
    return '$count Einträge entfernt';
  }

  @override
  String playlistDetailAddedToAbsorbing(String title) {
    return '\"$title\" zu Absorbing hinzugefügt';
  }

  @override
  String get collectionDetailDefaultName => 'Sammlung';

  @override
  String smartScopeBookCount(int count) {
    return 'Smart Scope · $count Bücher';
  }

  @override
  String get smartScopeNew => 'Neuer Smart Scope';

  @override
  String get smartScopeNewSubtitle =>
      'Eine Reihe von Filtern als Liste speichern, die sich selbst aktualisiert';

  @override
  String get smartScopeEditTitle => 'Smart Scope bearbeiten';

  @override
  String get smartScopeIcon => 'Symbol';

  @override
  String get smartScopePublic => 'Für alle Benutzer sichtbar';

  @override
  String get smartScopeKobo => 'Mit Kobo synchronisieren';

  @override
  String get smartScopeRules => 'Regeln';

  @override
  String get smartScopeMatchAll => 'Alle Übereinstimmungen';

  @override
  String get smartScopeMatchAny => 'Beliebige Übereinstimmung';

  @override
  String get smartScopeAddRule => 'Regel hinzufügen';

  @override
  String get smartScopeAddGroup => 'Gruppe hinzufügen';

  @override
  String get smartScopeGroup => 'Gruppe';

  @override
  String get smartScopeStartFrom => 'Beginnen mit';

  @override
  String get smartScopeFromScratch => 'Von Grund auf neu erstellen';

  @override
  String get smartScopeTplHasSeries => 'Hat eine Serie';

  @override
  String get smartScopeTplRecent => 'Kürzlich hinzugefügt';

  @override
  String get smartScopeTplPdf => 'Nur PDF';

  @override
  String get smartScopeTplNoGenres => 'Keine Genres';

  @override
  String get smartScopeTplEpub => 'Nur EPUB';

  @override
  String get smartScopeCounting => 'Zählen...';

  @override
  String get smartScopeSort => 'Standardsortierung';

  @override
  String get smartScopeAddSort => 'Sortierebene hinzufügen';

  @override
  String get smartScopeSortNone =>
      'Keine Sortierung ausgewählt, daher werden Bücher nach Titel sortiert.';

  @override
  String get smartScopeAscending => 'Aufsteigend';

  @override
  String get smartScopeDescending => 'Absteigend';

  @override
  String get smartScopeDelete => 'Smart Scope löschen';

  @override
  String get smartScopeSaveFailed => 'Konnte den Smart Scope nicht speichern';

  @override
  String get smartScopeDeleteFailed => 'Konnte den Smart Scope nicht löschen';

  @override
  String get smartScopeLoadFailed => 'Smart Scope konnte nicht geladen werden';

  @override
  String get smartScopeUnsupportedRule =>
      'Diese Regel kann nur in der BookOrbit Web Oberfläche geändert werden. Die Regel bleibt wie sie ist.';

  @override
  String get smartScopeAnd => 'und';

  @override
  String get smartScopeDays => 'Tage';

  @override
  String get smartScopeWeeks => 'Wochen';

  @override
  String get smartScopeMonths => 'Monate';

  @override
  String get smartScopePickDate => 'Datum auswählen';

  @override
  String get smartScopeAddValue => 'Wert hinzufügen';

  @override
  String get smartScopeValue => 'Wert';

  @override
  String get smartScopeCustomFields => 'Benutzerdefinierte Felder';

  @override
  String get smartScopeAnyProvider => 'Beliebiger Anbieter';

  @override
  String get smartScopeScoreOutstanding => 'Hervorragend';

  @override
  String get smartScopeScoreGood => 'Gut';

  @override
  String get smartScopeScoreFair => 'Befriedigend';

  @override
  String get smartScopeScorePoor => 'Schlecht';

  @override
  String get smartScopeMb => 'MB';

  @override
  String get smartScopeMaxValues => 'Bis zu 20 Werte';

  @override
  String get scopeFieldTitle => 'Titel';

  @override
  String get scopeFieldAuthor => 'Autor';

  @override
  String get scopeFieldSeries => 'Serie';

  @override
  String get scopeFieldSeriesIndex => 'Seriennummer';

  @override
  String get scopeFieldGenre => 'Genre';

  @override
  String get scopeFieldTag => 'Schlagwort';

  @override
  String get scopeFieldReadStatus => 'Lesestatus';

  @override
  String get scopeFieldReadProgress => 'Lesefortschritt';

  @override
  String get scopeFieldRating => 'Deine Bewertung';

  @override
  String get scopeFieldFormat => 'Format';

  @override
  String get scopeFieldLibrary => 'Bibliothek';

  @override
  String get scopeFieldCollection => 'Sammlung';

  @override
  String get scopeFieldPublisher => 'Herausgeber';

  @override
  String get scopeFieldLanguage => 'Sprache';

  @override
  String get scopeFieldPublishedDate => 'Veröffentlichungsdatum';

  @override
  String get scopeFieldPublishedYear => 'Erscheinungsjahr';

  @override
  String get scopeFieldAddedAt => 'Hinzugefügt am';

  @override
  String get scopeFieldStartedAt => 'Startdatum';

  @override
  String get scopeFieldFinishedAt => 'Datum abgeschlossen';

  @override
  String get scopeFieldPageCount => 'Anzahl der Seiten';

  @override
  String get scopeFieldFileSize => 'Dateigröße';

  @override
  String get scopeFieldCommunityRating => 'Community-Bewertung';

  @override
  String get scopeFieldCommunityRatingCount =>
      'Anzahl der Community-Bewertungen';

  @override
  String get scopeFieldMetadataScore => 'Metadaten-Bewertung';

  @override
  String get scopeFieldIsbn => 'ISBN';

  @override
  String get scopeFieldDescription => 'Beschreibung';

  @override
  String get scopeFieldCover => 'Titelbild';

  @override
  String get scopeFieldAudioCover => 'Hörbuch Titelbild';

  @override
  String get scopeFieldFileAvailability => 'Verfügbarkeit der Datei';

  @override
  String get scopeFieldLockStatus => 'Sperrstatus';

  @override
  String get scopeFieldSeriesStatus => 'Serienstatus';

  @override
  String get scopeSortUpdatedAt => 'Datum aktualisiert';

  @override
  String get scopeSortLastReadAt => 'Zuletzt gelesen';

  @override
  String get scopeSortRandom => 'Zufällig';

  @override
  String get scopeOpContains => 'enthält';

  @override
  String get scopeOpNotContains => 'beinhaltet nicht';

  @override
  String get scopeOpStartsWith => 'beginnt mit';

  @override
  String get scopeOpEndsWith => 'endet mit';

  @override
  String get scopeOpEq => 'ist';

  @override
  String get scopeOpNotEq => 'ist nicht';

  @override
  String get scopeOpIsEmpty => 'ist leer';

  @override
  String get scopeOpIsNotEmpty => 'ist nicht leer';

  @override
  String get scopeOpGt => 'größer als';

  @override
  String get scopeOpGte => 'mindestens';

  @override
  String get scopeOpLt => 'weniger als';

  @override
  String get scopeOpLte => 'höchstens';

  @override
  String get scopeOpBetween => 'zwischen';

  @override
  String get scopeOpIncludesAny => 'beinhaltet eines von';

  @override
  String get scopeOpIncludesAll => 'beinhaltet alle';

  @override
  String get scopeOpExcludesAll => 'schließt alle aus';

  @override
  String get scopeOpBefore => 'vorher';

  @override
  String get scopeOpAfter => 'Nach';

  @override
  String get scopeOpWithinLast => 'innerhalb der letzten';

  @override
  String get scopeOpIsMissing => 'fehlt';

  @override
  String get scopeOpIsPresent => 'ist vorhanden';

  @override
  String get scopeOpIsUnread => 'ist ungelesen';

  @override
  String get scopeOpIsInProgress => 'ist angefangen';

  @override
  String get scopeOpIsFinished => 'ist beendet';

  @override
  String get scopeOpIsLocked => 'ist gesperrt';

  @override
  String get scopeOpIsUnlocked => 'ist entsperrt';

  @override
  String get scopeOpIsUpNext => 'ist als Nächstes';

  @override
  String get scopeOpIsTrue => 'ist ja';

  @override
  String get scopeOpIsFalse => 'ist nicht';

  @override
  String smartScopeMatchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Bücher gefunden',
      one: '1 Buch gefunden',
      zero: 'Keine Bücher gefunden',
    );
    return '$_temp0';
  }

  @override
  String smartScopeDeleteConfirm(String name) {
    return '„$name“ löschen? Dies kann nicht rückgängig gemacht werden.';
  }

  @override
  String collectionDetailBookCount(int count) {
    return '$count Bücher';
  }

  @override
  String get collectionDetailDone => 'Fertig';

  @override
  String collectionDetailAddedToAbsorbing(String title) {
    return '\"$title\" zu Absorbing hinzugefügt';
  }

  @override
  String get audibleSeriesNoBooksFound => 'Keine Bücher auf Audible gefunden';

  @override
  String get audibleSeriesFailedToLoad =>
      'Serie konnte nicht von Audible geladen werden';

  @override
  String audibleSeriesSummary(int total, int missing) {
    return '$total auf Audible · $missing fehlen';
  }

  @override
  String audibleSeriesSummaryWithUpcoming(
    int total,
    int missing,
    int upcoming,
  ) {
    return '$total auf Audible · $missing fehlen · $upcoming kommend';
  }

  @override
  String audibleSeriesFilterMissing(int count) {
    return 'Fehlend ($count)';
  }

  @override
  String audibleSeriesFilterUpcoming(int count) {
    return 'Kommend ($count)';
  }

  @override
  String audibleSeriesFilterAll(int count) {
    return 'Alle ($count)';
  }

  @override
  String get audibleSeriesSearching => 'Audible wird durchsucht...';

  @override
  String get audibleSeriesCompleteSeries => 'Du hast die komplette Serie!';

  @override
  String get audibleSeriesNoUpcoming =>
      'Keine kommenden Veröffentlichungen gefunden';

  @override
  String get audibleSeriesUpcomingBadge => 'KOMMEND';

  @override
  String get audibleSeriesAbridged => 'Gekürzt';

  @override
  String get audibleSeriesRegionTitle => 'Audible-Region';

  @override
  String get audibleSeriesOpenOnAudible => 'Auf Audible öffnen';

  @override
  String get audibleSeriesAddToCalendar => 'Zum Kalender hinzufügen';

  @override
  String get audibleSeriesAddToUpcoming =>
      'Zu kommenden Veröffentlichungen hinzufügen';

  @override
  String get audibleSeriesAddedToUpcoming =>
      'Zu kommenden Veröffentlichungen hinzugefügt';

  @override
  String get audibleSeriesAlreadyInUpcoming =>
      'Bereits auf der kommenden Seite';

  @override
  String get audibleSeriesCouldNotOpenAudible =>
      'Audible konnte nicht geöffnet werden';

  @override
  String get audibleSeriesCouldNotOpenCalendar =>
      'Kalender konnte nicht geöffnet werden';

  @override
  String audibleSeriesCalendarDescription(String seriesName) {
    return 'Neues Hörbuch in der Serie $seriesName';
  }

  @override
  String get authorBooksGroupBySeries => 'Nach Serie gruppieren';

  @override
  String get authorBooksList => 'Liste';

  @override
  String get authorBooksGrid => 'Raster';

  @override
  String authorBooksBookCount(int count) {
    return '$count Bücher';
  }

  @override
  String get metadataLookupCover => 'Cover';

  @override
  String get metadataLookupChooseFields => 'Felder zum Übernehmen wählen';

  @override
  String metadataLookupApplyFields(int count) {
    return '$count Felder übernehmen';
  }

  @override
  String metadataLookupFieldsSavedLocally(int count) {
    return '$count Felder lokal gespeichert';
  }

  @override
  String get metadataLookupOverrideLocalDisplay =>
      'Lokale Anzeige überschreiben';

  @override
  String get equalizerPresetFlat => 'Flach';

  @override
  String get equalizerPresetVoiceBoost => 'Stimme verstärken';

  @override
  String get equalizerPresetBassBoost => 'Bass-Boost';

  @override
  String get equalizerPresetTrebleBoost => 'Höhen-Boost';

  @override
  String get equalizerPresetPodcast => 'Podcast';

  @override
  String get equalizerPresetAudiobook => 'Hörbuch';

  @override
  String get equalizerPresetReduceNoise => 'Rauschen reduzieren';

  @override
  String get equalizerPresetLoudness => 'Lautheit';

  @override
  String equalizerEditingSavedNamed(String title) {
    return 'Bearbeite gespeicherten EQ für \"$title\"';
  }

  @override
  String get equalizerEditingSavedGeneric => 'Bearbeite gespeicherten EQ';

  @override
  String get equalizerPerBookEq => 'EQ pro Buch';

  @override
  String get notesDeleteNoteQuestion => 'Notiz löschen?';

  @override
  String notesDeleteNoteContent(String title) {
    return '\"$title\" löschen?';
  }

  @override
  String get notesExport => 'Exportieren';

  @override
  String get notesNewNote => 'Neue Notiz';

  @override
  String get librarySortFilterUpcomingReleases => 'Serien Scan';

  @override
  String get librarySortFilterMatchAllAuthorsSubtitle =>
      'Rufe für jeden Autor ein Foto sowie die Biografie vom Metadaten Anbieter ab';

  @override
  String get librarySortFilterUpcomingReleasesSubtitle =>
      'Prüfe bei Audible, welche Bücher deiner Reihe demnächst erscheinen oder noch fehlen';

  @override
  String sleepTimerSheetChaptersLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Noch $count Kapitel',
      one: 'Noch 1 Kapitel',
    );
    return '$_temp0';
  }

  @override
  String sleepTimerSheetAddMinutesChip(int minutes) {
    return '+$minutes Min';
  }

  @override
  String sleepTimerSheetAddChaptersChip(int count) {
    return '+$count Kap';
  }

  @override
  String sleepTimerSheetMinShort(int minutes) {
    return '$minutes Min';
  }

  @override
  String sleepTimerSheetSecondsShort(int seconds) {
    return '$seconds Sek';
  }

  @override
  String sleepTimerSheetMinSecShort(int minutes, int seconds) {
    return '$minutes Min $seconds Sek';
  }

  @override
  String sleepTimerSheetChaptersValue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Kapitel',
      one: '1 Kapitel',
    );
    return '$_temp0';
  }

  @override
  String sleepTimerSheetChaptersChip(int count) {
    return '$count Kap';
  }

  @override
  String sleepTimerSheetStartChapterSleep(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sleep nach $count Kapiteln',
      one: 'Sleep nach 1 Kapitel',
    );
    return '$_temp0';
  }

  @override
  String get sleepTimerSheetRewindOnSleep => 'Bei Sleep zurückspulen';

  @override
  String get sleepTimerSheetShake => 'Schütteln';

  @override
  String sleepTimerSheetAddsMinutes(int minutes) {
    return 'Fügt $minutes Min hinzu';
  }

  @override
  String get sleepTimerSheetAddsOneChapter => 'Fügt 1 Kapitel hinzu';

  @override
  String get sleepTimerSheetResetsToFull => 'Setzt auf volle Dauer zurück';

  @override
  String get sleepTimerSheetTabSpecificChapter => 'Kapitel';

  @override
  String get sleepTimerSheetSpecificNoChapters => 'Keine Kapitel verfügbar';

  @override
  String sleepTimerSheetSpecificChapterFallback(int number) {
    return 'Kapitel $number';
  }

  @override
  String get sleepTimerSheetSpecificPassedShort => 'vorbei';

  @override
  String get sleepTimerSheetSpecificStart => 'Kapitelanfang';

  @override
  String get sleepTimerSheetSpecificEnd => 'Kapitelende';

  @override
  String get sleepTimerSheetSpecificEndsAt => 'Sleep-Timer endet um';

  @override
  String sleepTimerSheetSpecificCountdown(String countdown) {
    return 'in $countdown';
  }

  @override
  String get sleepTimerSheetSpecificAlreadyPassed =>
      'Dieser Zeitpunkt ist bereits vorbei';

  @override
  String get sleepTimerSheetSpecificStartButton => 'Timer starten';

  @override
  String get sleepTimerSheetSpecificStartButtonPassed => 'Bereits vorbei';

  @override
  String get timeAm => 'AM';

  @override
  String get timePm => 'PM';

  @override
  String get collectionPickerCollectionFallback => 'Sammlung';

  @override
  String collectionPickerNameWithCount(String name, int count) {
    return '$name ($count)';
  }

  @override
  String get playlistPickerPlaylistFallback => 'Playlist';

  @override
  String playlistPickerNameWithCount(String name, int count) {
    return '$name ($count)';
  }

  @override
  String get cardChaptersPlayFromChapterTitle => 'Ab Kapitel abspielen?';

  @override
  String cardChaptersPlayFromChapterContent(String title) {
    return 'Wiedergabe ab \"$title\" starten?';
  }

  @override
  String get cardChaptersPlay => 'Abspielen';

  @override
  String get absorbingSharedToday => 'Heute';

  @override
  String get absorbingSharedYesterday => 'Gestern';

  @override
  String get absorbingSharedMonday => 'Montag';

  @override
  String get absorbingSharedTuesday => 'Dienstag';

  @override
  String get absorbingSharedWednesday => 'Mittwoch';

  @override
  String get absorbingSharedThursday => 'Donnerstag';

  @override
  String get absorbingSharedFriday => 'Freitag';

  @override
  String get absorbingSharedSaturday => 'Samstag';

  @override
  String get absorbingSharedSunday => 'Sonntag';

  @override
  String get absorbingSharedAm => 'AM';

  @override
  String get absorbingSharedPm => 'PM';

  @override
  String sectionDetailAddedToAbsorbing(String title) {
    return '\"$title\" zu Absorbing hinzugefügt';
  }

  @override
  String get sectionDetailDoneBadge => 'Fertig';

  @override
  String get homeCustomizeAddGenreTitle => 'Genre-Bereich hinzufügen';

  @override
  String get homeCustomizeAddGenreSubtitle =>
      'Wähle ein Genre für deinen Startbildschirm';

  @override
  String get homeSectionDoneBadge => 'Fertig';

  @override
  String get tipsSheetQuickBookmarksTitle => 'Schnelle Lesezeichen';

  @override
  String get tipsSheetQuickBookmarksDesc =>
      'Halte den Lesezeichen-Button auf einer Karte gedrückt, um sofort ein Lesezeichen an der aktuellen Position zu setzen, ohne das Lesezeichen-Menü zu öffnen.';

  @override
  String get tipsSheetCoverPlayPauseTitle => 'Cover zum Pausieren';

  @override
  String get tipsSheetCoverPlayPauseDesc =>
      'Tippe auf das Cover einer Karte, um abzuspielen oder zu pausieren. Schalte das in den Einstellungen unter Absorbing-Karten um. Ein dezentes Pause-Symbol zeigt sich beim Abspielen, damit du weißt, dass es antippbar ist.';

  @override
  String get tipsSheetFullScreenPlayerTitle => 'Vollbild-Player';

  @override
  String get tipsSheetFullScreenPlayerDesc =>
      'Wische auf einer Absorbing-Karte nach oben, um den Vollbild-Player zu öffnen. Wische nach unten, um ihn zu schließen.';

  @override
  String get tipsSheetQuickAddAbsorbingTitle =>
      'Schnell zu Absorbing hinzufügen';

  @override
  String get tipsSheetQuickAddAbsorbingDesc =>
      'Wische in einem Listen-Sheet (Serie, Autor, Suchergebnisse) nach rechts auf einem Buch, um es sofort zur Absorbing-Warteschlange hinzuzufügen.';

  @override
  String get tipsSheetShakeExtendSleepTitle => 'Schütteln verlängert Sleep';

  @override
  String get tipsSheetShakeExtendSleepDesc =>
      'Wenn ein Sleep-Timer läuft und du dein Handy schüttelst, werden zusätzliche Minuten draufgepackt. Stelle die Menge in den Einstellungen unter Sleep-Timer ein.';

  @override
  String get tipsSheetSeriesNavigationTitle => 'Serien-Navigation';

  @override
  String get tipsSheetSeriesNavigationDesc =>
      'Tippe in den Buchdetails auf den Seriennamen, um alle Bücher der Serie in Lesereihenfolge zu sehen, mit Reihenfolge-Badges auf jedem Cover.';

  @override
  String get tipsSheetSwipeBetweenBooksTitle => 'Zwischen Büchern wischen';

  @override
  String get tipsSheetSwipeBetweenBooksDesc =>
      'Wische auf dem Absorbing-Bildschirm nach links und rechts, um zwischen deinen angefangenen Büchern zu wechseln. Im manuellen Warteschlangenmodus dienen die Karten als Warteschlange, sodass das nächste Buch automatisch startet, wenn das aktuelle endet.';

  @override
  String get tipsSheetTapToSeekTitle => 'Tippen zum Spulen';

  @override
  String get tipsSheetTapToSeekDesc =>
      'Tippe irgendwo auf den Kapitel- oder Buchfortschrittsbalken, um direkt zu dieser Stelle zu springen. Du kannst die Balken auch ziehen, um feiner zu steuern.';

  @override
  String get tipsSheetSpeedAdjustedTimeTitle =>
      'Geschwindigkeitsangepasste Zeit';

  @override
  String get tipsSheetSpeedAdjustedTimeDesc =>
      'Alle angezeigten Zeitangaben – ob Position, Restlaufzeit, Kapitel oder Lesezeichen – passen sich Ihrer Wiedergabegeschwindigkeit an. Hören Sie mit 1,5-facher Geschwindigkeit? Die angezeigten Zeiten geben an, wie lange es tatsächlich dauern wird.';

  @override
  String get tipsSheetPlaybackHistoryTitle => 'Wiedergabe-Verlauf';

  @override
  String get tipsSheetPlaybackHistoryDesc =>
      'Tippe auf einer Karte auf den Verlaufs-Button, um eine Zeitleiste mit jeder Wiedergabe, Pause, Sprung und Geschwindigkeitsänderung zu sehen. Tippe auf ein Ereignis, um zu dieser Stelle zurückzuspringen.';

  @override
  String get tipsSheetAutoRewindTitle => 'Auto-Zurückspulen';

  @override
  String get tipsSheetAutoRewindDesc =>
      'Wenn du nach einer Pause weiterhörst, spult Absorb automatisch ein paar Sekunden zurück, damit du den Anschluss nicht verlierst. Wie weit zurückgespult wird, hängt davon ab, wie lange du weg warst. In den Einstellungen anpassbar.';

  @override
  String get tipsSheetSeriesQueueModeTitle => 'Serien-Warteschlangenmodus';

  @override
  String get tipsSheetSeriesQueueModeDesc =>
      'Wenn du ein Buch beendest, das Teil einer Serie ist, kann Absorb automatisch das nächste Buch abspielen. Stelle den Warteschlangenmodus in den Einstellungen auf \"Serie\".';

  @override
  String get tipsSheetOfflineModeTitle => 'Offline-Modus';

  @override
  String get tipsSheetOfflineModeDesc =>
      'Tippe auf die grüne Wolke oben auf dem „Absorbing“-Bildschirm, um in den Offline-Modus zu wechseln. Die Synchronisierung wird angehalten, es werden keine Daten verbraucht und es werden nur deine Downloads angezeigt. Im Offline-Modus färbt sich die Wolke orange; ein erneutes Tippen darauf stellt die Verbindung wieder her. Eine rote Wolke bedeutet, dass du abgemeldet wurdest: Deine Downloads lassen sich weiterhin abspielen, und deine Hörvorgänge werden synchronisiert, sobald du dich wieder anmeldest. Du kannst den Offline-Modus auch aktivieren, indem du einen Tab gedrückt hältst – die entsprechende Option findest du in den Einstellungen unter „Kurzbefehle durch Gedrückthalten von Tabs“.';

  @override
  String get tipsSheetUpcomingReleasesTitle => 'Kommende Veröffentlichungen';

  @override
  String get tipsSheetUpcomingReleasesDesc =>
      'Tippe im Serien-Tab erneut auf Serien, um die Sortierungs- und Filterfunktionen aufzurufen. Tippe dort auf \"Kommende Veröffentlichungen\" und wähle deine Audible Region, um neue Bücher zu deinen Serien zu entdecken, geordnet nach Veröffentlichungsdatum.';

  @override
  String get tipsSheetPerBookEqTitle => 'Equalizer pro Buch';

  @override
  String get tipsSheetPerBookEqDesc =>
      'Jedes Buch merkt sich seine eigenen EQ-Einstellungen. Stell den EQ einmal für ein Sci-Fi-Epos ein und beim nächsten Mal klingt es genauso.';

  @override
  String get tipsSheetPerBookSpeedTitle => 'Geschwindigkeit pro Buch';

  @override
  String get tipsSheetPerBookSpeedDesc =>
      'Die Wiedergabegeschwindigkeit wird pro Buch gespeichert. Sachbücher mit 1,5x und dramatische Romane mit 1,0x hören - ohne es jedes Mal neu einstellen zu müssen.';

  @override
  String get tipsSheetAutoSleepWindowTitle => 'Auto-Sleep-Zeitfenster';

  @override
  String get tipsSheetAutoSleepWindowDesc =>
      'Wähle die Stunden, in denen du normalerweise einschläfst, und der Sleep-Timer startet automatisch, wenn du in diesem Fenster zu hören beginnst.';

  @override
  String get tipsSheetSleepFadeChimeTitle => 'Sleep-Fade und Klangzeichen';

  @override
  String get tipsSheetSleepFadeChimeDesc =>
      'Wenn der Sleep-Timer endet, wird das Audio langsam ausgeblendet und ein optionales Klangzeichen ertönt, damit nicht mitten im Satz abgeschnitten wird.';

  @override
  String get tipsSheetCarModeTitle => 'Auto-Modus';

  @override
  String get tipsSheetCarModeDesc =>
      'Tippe auf das Auto-Symbol, um in den Modus mit großen Buttons zu wechseln, der für sicherere Bedienung beim Fahren gedacht ist.';

  @override
  String get tipsSheetAudibleSeriesTitle => 'Audible-Serien-Suche';

  @override
  String get tipsSheetAudibleSeriesDesc =>
      'Öffne eine Serie und tippe auf das Drei-Punkte-Symbol, um die komplette Serienliste von Audible zu laden, inklusive fehlender Einträge und noch nicht gestarteter Bücher.';

  @override
  String get tipsSheetTranscribeBookmarkTitle => 'Lesezeichen transkribieren';

  @override
  String get tipsSheetTranscribeBookmarkDesc =>
      'Wandeln Sie die Audioaufnahme an einem beliebigen Lesezeichen vollständig auf Ihrem Gerät in Text um. Aktivieren Sie diese Funktion in den Einstellungen unter „Erweitert“ > „Transkription“ und laden Sie ein Modell herunter. Tippen Sie anschließend bei einem Lesezeichen auf „Transkribieren“ – der Text wird in der zugehörigen Notiz gespeichert und kann sofort bearbeitet oder geteilt werden.';

  @override
  String get tipsSheetFindBetweenFormatsTitle =>
      'Wechsel zwischen Hörbuch und eBook';

  @override
  String get tipsSheetFindBetweenFormatsDesc =>
      'Wenn die Transkription aktiviert und das Buch heruntergeladen ist, halten Sie die Wiedergabe an und tippen Sie im Player auf „Position im E-Book finden“, um das E-Book an der Stelle zu öffnen, die Sie gerade gehört haben. Markieren Sie im E-Book einen Textabschnitt und tippen Sie auf das Kopfhörersymbol, um das Hörbuch genau an dieser Stelle zu starten.';

  @override
  String get tipsSheetShareQuoteTitle => 'Zitate teilen';

  @override
  String get tipsSheetShareQuoteDesc =>
      'Teile eine E-Book-Markierung oder eine Notiz als Bild, bei dem das Zitat über dem Buchcover eingeblendet wird. Die entsprechende Teilen-Option findest du bei Markierungen sowie in der Lesezeichen-Übersicht.';

  @override
  String get tipsSheetClipExportTitle => 'Audio-Clips exportieren';

  @override
  String get tipsSheetClipExportDesc =>
      'Öffne ein Lesezeichen und tippe Clip exportieren um einen kurzen Audioschnipsel des Buches, inklusive Coverart zu erstellen - Super um deine Lieblings Szenen zu teilen.';

  @override
  String get tipsSheetAllHighlightsTitle => 'Alle Highlights an einem Ort';

  @override
  String get tipsSheetAllHighlightsDesc =>
      'Die Seite „Alle Lesezeichen“ enthält einen Reiter „Markierungen“, in dem sämtliche Markierungen aus allen E-Books zusammengefasst sind. Tippe auf eine Markierung, um sie zu teilen oder direkt an die entsprechende Stelle im Buch zurückzukehren.';

  @override
  String get tipsSheetVolumeKeyPagesTitle => 'Umblättern per Lautstärke Taste';

  @override
  String get tipsSheetVolumeKeyPagesDesc =>
      'Blättere in E-Books mithilfe der Lautstärke Tasten. Aktiviere diese Funktion in den Einstellungen der Lese-App – wahlweise in normaler oder umgekehrter Richtung. Die Funktion kann auch dann aktiv bleiben, wenn gerade Audioinhalte wiedergegeben werden.';

  @override
  String get tipsSheetSettingsSyncTitle => 'Einstellungs-Synchronisation';

  @override
  String get tipsSheetSettingsSyncDesc =>
      'Halten Sie Ihre Einstellungen, die Geschwindigkeit pro Buch und die Aufnahmereihenfolge über Ihren eigenen WebDAV-Server geräteübergreifend auf dem gleichen Stand. Richten Sie es in den Einstellungen unter „Sichern und synchronisieren“ ein.';

  @override
  String get tipsSheetNavLongPressTitle =>
      'Die unteren Reiter lange gedrückt halten';

  @override
  String get tipsSheetNavLongPressDesc =>
      'Halte die „Start“-Registerkarte gedrückt, um von einer beliebigen Seite aus zwischen Bibliotheken zu wechseln. Halte die „Bibliothek“-Registerkarte gedrückt, um direkt zur Suche zu gelangen.';

  @override
  String get bookCardUnknownTitle => 'Unbekannter Titel';

  @override
  String get bookCardExplicitBadge => 'E';

  @override
  String get bookCardDone => 'Fertig';

  @override
  String get bookCardSaved => 'Gespeichert';

  @override
  String get episodeRowEpisode => 'Episode';

  @override
  String get episodeRowToday => 'Heute';

  @override
  String get episodeRowYesterday => 'Gestern';

  @override
  String episodeRowDaysAgo(int count) {
    return 'vor $count T';
  }

  @override
  String episodeRowWeeksAgo(int count) {
    return 'vor $count W';
  }

  @override
  String episodeRowDurationHm(int hours, int minutes) {
    return '$hours Std $minutes Min';
  }

  @override
  String episodeRowDurationM(int minutes) {
    return '$minutes Min';
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
  String get librarySearchResultsDone => 'Fertig';

  @override
  String get librarySearchResultsSaved => 'Gespeichert';

  @override
  String librarySearchResultsSequence(String number) {
    return '#$number';
  }

  @override
  String get librarySearchResultsUnknownSeries => 'Unbekannte Serie';

  @override
  String get librarySearchResultsUnknownEpisode => 'Unbekannte Episode';

  @override
  String librarySearchResultsBookCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Bücher',
      one: '1 Buch',
    );
    return '$_temp0';
  }

  @override
  String get libraryGridTilesExplicitBadge => 'E';

  @override
  String get libraryGridTilesDone => 'Fertig';

  @override
  String get libraryGridTilesSaved => 'Gespeichert';

  @override
  String libraryGridTilesSequence(String number) {
    return '#$number';
  }

  @override
  String get libraryGridTilesUnknownSeries => 'Unbekannte Serie';

  @override
  String get seriesCardUnknownSeries => 'Unbekannte Serie';

  @override
  String seriesCardBookCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Bücher',
      one: '1 Buch',
    );
    return '$_temp0';
  }

  @override
  String get cardProgressFineScrubbing => 'Feines Spulen';

  @override
  String get cardProgressQuarterSpeed => 'Viertelgeschwindigkeit';

  @override
  String get cardProgressHalfSpeed => 'Halbe Geschwindigkeit';

  @override
  String cardProgressChapterPrefix(String number) {
    return 'Kapitel $number';
  }

  @override
  String get cardEdgeProgressFineScrubbing => 'Feines Spulen';

  @override
  String get cardEdgeProgressQuarterSpeed => 'Viertelgeschwindigkeit';

  @override
  String get cardEdgeProgressHalfSpeed => 'Halbe Geschwindigkeit';

  @override
  String get authSessionExpired =>
      'Sitzung abgelaufen. Bitte melde dich erneut an.';

  @override
  String authCannotReachServer(String url) {
    return 'Server unter $url nicht erreichbar';
  }

  @override
  String get authInvalidUsernameOrPassword =>
      'Ungültiger Benutzername oder Passwort';

  @override
  String get authInvalidApiKey => 'Ungültiger API-Schlüssel';

  @override
  String get authLoginFailedDetail =>
      'Anmeldung fehlgeschlagen - prüfe Serveradresse und Zugangsdaten';

  @override
  String get authUnexpectedServerResponse => 'Unerwartete Server-Antwort';

  @override
  String get authSsoUnexpectedResponse =>
      'SSO hat eine unerwartete Antwort zurückgegeben';

  @override
  String get authSwitchedToLocalServer => 'Zu lokalem Server gewechselt';

  @override
  String get authSwitchedToRemoteServer => 'Zu Remote-Server gewechselt';

  @override
  String get lpDeletedFinishedDownload => 'Beendeten Download gelöscht';

  @override
  String lpSubscribedPodcastDownloading(String showTitle, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count neue Episoden werden heruntergeladen',
      one: '1 neue Episode wird heruntergeladen',
    );
    return '$showTitle: $_temp0';
  }

  @override
  String lpSubscribedEpisodeAddedStart(String showTitle) {
    return '$showTitle an den Anfang deiner Warteschlange hinzugefügt';
  }

  @override
  String lpSubscribedEpisodeAddedSecond(String showTitle) {
    return '$showTitle an Position 2 deiner Warteschlange hinzugefügt';
  }

  @override
  String lpSubscribedEpisodeAddedEnd(String showTitle) {
    return '$showTitle an das Ende deiner Warteschlange hinzugefügt';
  }

  @override
  String lpSubscribedEpisodeDownloaded(String showTitle) {
    return 'Neue Folge von $showTitle heruntergeladen';
  }

  @override
  String get statsWeekStartsOn => 'Wochenbeginn';

  @override
  String get episodeListNewEpisodePosition => 'Position neuer Folgen';

  @override
  String get episodeListPositionTop => 'Anfang der Warteschlange';

  @override
  String get episodeListPositionSecond => 'Zweite in der Warteschlange';

  @override
  String get episodeListPositionEnd => 'Ende der Warteschlange';

  @override
  String get episodeListPositionNone => 'Nicht zur Warteschlange hinzufügen';

  @override
  String get episodeListPositionNoneDesc =>
      'Weiterhin benachrichtigt und heruntergeladen';

  @override
  String sleepRewindUndoNote(int minutes) {
    return 'Klicke innerhalb von $minutes Minuten auf „Abspielen“, dann wird das Zurückspulen rückgängig gemacht';
  }

  @override
  String lpQueueDownloadingItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Warteschlange: $count Einträge werden heruntergeladen',
      one: 'Warteschlange: 1 Eintrag wird heruntergeladen',
    );
    return '$_temp0';
  }

  @override
  String lpDownloadingBooks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Bücher werden heruntergeladen',
      one: '1 Buch wird heruntergeladen',
    );
    return '$_temp0';
  }

  @override
  String lpDownloadingEpisodes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Episoden werden heruntergeladen',
      one: '1 Episode wird heruntergeladen',
    );
    return '$_temp0';
  }

  @override
  String get downloadNotifProgressChannelName => 'Download-Fortschritt';

  @override
  String get downloadNotifProgressChannelDesc =>
      'Zeigt den Fortschritt während Hörbuch-Downloads';

  @override
  String get downloadNotifAlertChannelName => 'Download-Benachrichtigungen';

  @override
  String get downloadNotifAlertChannelDesc =>
      'Benachrichtigungen, wenn Downloads beendet werden oder fehlschlagen';

  @override
  String get downloadNotifDownloadingTitle => 'Wird heruntergeladen…';

  @override
  String downloadNotifActiveCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Downloads aktiv',
      one: '1 Download aktiv',
    );
    return '$_temp0';
  }

  @override
  String downloadNotifSlotTitle(String title) {
    return 'Wird heruntergeladen: $title';
  }

  @override
  String get downloadNotifStartingLabel => 'Wird gestartet…';

  @override
  String get downloadNotifCompleteTitle => 'Download abgeschlossen';

  @override
  String downloadNotifCompleteBody(String title) {
    return '$title ist offline verfügbar';
  }

  @override
  String get downloadNotifFailedTitle => 'Download fehlgeschlagen';

  @override
  String get upcomingNotifChannelName =>
      'Suche nach kommenden Veröffentlichungen';

  @override
  String get upcomingNotifChannelDesc =>
      'Zeigt den Fortschritt beim Scannen nach kommenden Veröffentlichungen';

  @override
  String get upcomingNotifScanTitle =>
      'Suche nach kommenden Veröffentlichungen';

  @override
  String get upcomingNotifStartingScan => 'Suche wird gestartet…';

  @override
  String upcomingNotifCheckingSeries(
    String seriesName,
    int current,
    int total,
  ) {
    return 'Prüfe $seriesName… ($current/$total)';
  }

  @override
  String get upcomingNotifFoundTitle => 'Kommende Veröffentlichungen gefunden!';

  @override
  String upcomingNotifFoundBody(int books, int series) {
    String _temp0 = intl.Intl.pluralLogic(
      series,
      locale: localeName,
      other: '$series Serien',
      one: '1 Serie',
    );
    return '$books kommend in $_temp0';
  }

  @override
  String get androidAutoTabContinue => 'Weiterhören';

  @override
  String get androidAutoTabLibrary => 'Bibliothek';

  @override
  String get androidAutoTabDownloads => 'Downloads';

  @override
  String get settingsSearchHint => 'Einstellung suchen...';

  @override
  String get settingsSearchNoResults => 'Keine passende Einstellung gefunden';

  @override
  String get carConnectAutoplay =>
      'Wiedergabe starten, wenn Android Auto verbunden wird';

  @override
  String get carConnectAutoplayIos =>
      'Wiedergabe starten, wenn CarPlay verbunden wird';

  @override
  String get carConnectAutoplayOnSubtitle =>
      'Das letzte Buch, das du gerade gehört hast, startet von selbst, sobald sich das Auto verbindet';

  @override
  String get carConnectAutoplayOffSubtitle =>
      'Die Wiedergabe wartet darauf, dass du auf „Wiedergabe“ drückst';

  @override
  String get sectionCar => 'Android Auto';

  @override
  String get sectionCarIos => 'CarPlay';

  @override
  String get sectionSiri => 'Siri';

  @override
  String get siriUseWithSiri => 'Mit Siri verwenden';

  @override
  String get siriStatusOn =>
      'Ein. Siri kann deine Bücher und Podcasts anhand ihres Namens finden und abspielen.';

  @override
  String get siriStatusAsk =>
      'Lass Siri deine Bücher und Podcasts anhand ihres Namens suchen und abspielen.';

  @override
  String get siriStatusOff =>
      'Siri ist für Absorb deaktiviert. Aktiviere es in den iOS-Einstellungen.';

  @override
  String get siriAllow => 'Zulassen';

  @override
  String get siriOpenSettings => 'Einstellungen öffnen';

  @override
  String get siriThingsToSay => 'Dinge zu sagen';

  @override
  String get siriExamples =>
      '„[Buchtitel] in Absorb abspielen“\n„[Serienname] in Absorb abspielen“\n„Etwas von [Autor] in Absorb abspielen“\n„Die neueste Folge von [Podcast] in Absorb abspielen“\n„Wiedergabe in Absorb fortsetzen“\n„In Absorb zurückspringen“\n„Nächstes Kapitel in Absorb“\n„Sleep-Timer in Absorb einstellen“\n„Lesezeichen in Absorb hinzufügen“\n„Was höre ich gerade in Absorb?“';

  @override
  String get siriShortcutsNote =>
      'Fortsetzen, Anhalten, Überspringen, Kapitel, der Sleep-Timer, Lesezeichen sowie die Anzeige der aktuellen Wiedergabe funktionieren auch ohne diese Berechtigung. Sie stehen zudem in der Kurzbefehle-App für Automatisierungen sowie für die Aktionstaste zur Verfügung.';

  @override
  String get carBookOrder => 'Buch Reihenfolge im Auto';

  @override
  String get carBookOrderReverse => 'Buchreihenfolge umkehren';

  @override
  String get carBookOrderReverseSubtitle =>
      'Z bis A, oder älteste zuerst hinzugefügt';

  @override
  String get carPodcastOrder => 'Podcast-Reihenfolge im Auto';

  @override
  String get carEpisodesOldestFirst => 'Älteste Folgen zuerst';

  @override
  String get carEpisodesOldestFirstSubtitle =>
      'Für Serien, die du von Anfang an hörst';

  @override
  String get androidAutoCatBooks => 'Bücher';

  @override
  String get androidAutoCatSeries => 'Serien';

  @override
  String get androidAutoCatAuthors => 'Autoren';

  @override
  String get androidAutoCatCollections => 'Sammlungen';

  @override
  String get androidAutoCatPlaylists => 'Playlisten';

  @override
  String get showTipsAgain => 'Tipps wieder anzeigen';

  @override
  String get showTipsAgainSubtitle =>
      'Bringe ausgeblendete Funktions-Tipps zurück';

  @override
  String get tipsRestored => 'Tipps wiederhergestellt';

  @override
  String get resetSpeedPresets =>
      'Geschwindigkeits-Voreinstellungen zurücksetzen';

  @override
  String get resetSpeedPresetsSubtitle =>
      'Standard-Wiedergabegeschwindigkeiten wiederherstellen';

  @override
  String get speedPresetsReset =>
      'Geschwindigkeits-Voreinstellungen zurückgesetzt';

  @override
  String get editAuthor => 'Autor bearbeiten';

  @override
  String get authorName => 'Name';

  @override
  String get authorImage => 'Autorenbild';

  @override
  String get authorRemoveImage => 'Bild entfernen';

  @override
  String get authorRemoveImageTitle => 'Autorenbild entfernen?';

  @override
  String get authorRemoveImageConfirm =>
      'Dadurch wird das Bild auf dem Server gelöscht.';

  @override
  String get authorImageRemoved => 'Bild entfernt';

  @override
  String get authorImageFailed =>
      'Das Autorenbild konnte nicht aktualisiert werden';

  @override
  String get authorUpdated => 'Autor aktualisiert';

  @override
  String get authorUpdateFailed => 'Der Autor konnte nicht aktualisiert werden';

  @override
  String get authorMatched => 'Autor von Übereinstimmung aktualisiert';

  @override
  String get authorNoMatchFound => 'Kein Treffer gefunden';

  @override
  String authorMergedInto(String name) {
    return 'Zusammengeführt in $name';
  }

  @override
  String get authorQuickMatchHint =>
      'Name, ASIN, Beschreibung und Bild von Audible der gewählten Region abrufen.';

  @override
  String get region => 'Region';

  @override
  String get editTabDetails => 'Details';

  @override
  String get editTabCover => 'Cover';

  @override
  String get editTabMatch => 'Treffer';

  @override
  String get editTabEmbed => 'Einbetten';

  @override
  String get chapterEditorTitle => 'Kapitel bearbeiten';

  @override
  String get chapterNotConnected => 'Nicht mit dem Server verbunden';

  @override
  String get chapterErrorFirstNotZero =>
      'Das erste Kapitel muss bei 0:00 beginnen';

  @override
  String get chapterErrorStartAfterPrevious =>
      '\"Beginn\" muss nach dem vorherigen Kapitel liegen';

  @override
  String get chapterErrorStartBeforeEnd =>
      '\"Beginn\" muss vor dem Ende des Buches liegen';

  @override
  String get chapterErrorTitleRequired => 'Titel erforderlich';

  @override
  String get chapterEditStartTitle => 'Beginn Zeit ändern';

  @override
  String get chapterTimeHintSeconds => 'Sekunden';

  @override
  String get chapterTimeHintFull => 'HH:MM:SS oder Sekunden';

  @override
  String get chapterInvalidTime => 'Ungültige Zeitangabe';

  @override
  String get chapterLocked => 'Das Kapitel ist gesperrt';

  @override
  String get chapterAllLocked => 'Alle Kapitel sind gesperrt';

  @override
  String chapterTrackTitle(int number) {
    return 'Titel $number';
  }

  @override
  String get chapterNoAudioForPosition => 'Kein Audio für diese Position';

  @override
  String get chapterCouldNotPlayPreview =>
      'Vorschau konnte nicht abgespielt werden';

  @override
  String chapterStartSetTo(String time) {
    return 'Beginne bei $time';
  }

  @override
  String get chapterAddNumberedTitle => 'Nummerierte Kapitel hinzufügen';

  @override
  String chapterNextPreview(String first, String second) {
    return 'Nächstes: \"$first\", \"$second\", ...';
  }

  @override
  String get chapterHowMany => 'Wie viele Kapitel';

  @override
  String get add => 'Hinzufügen';

  @override
  String get chapterCountRange => 'Gib eine Zahl zwischen 1 und 150 ein';

  @override
  String get chapterTitlesUpdated => 'Kapiteltitel aktualisiert';

  @override
  String get chaptersApplied => 'Kapitel angewendet';

  @override
  String get chapterDiscardTitle => 'Änderungen verwerfen?';

  @override
  String get chapterDiscardMessage =>
      'Zu den gespeicherten Kapitel zurückkehren.';

  @override
  String get chapterRemoveAllTitle => 'Alle Kapitel entfernen?';

  @override
  String get chapterRemoveAllMessage =>
      'Dies entfernt alle Kapitel aus diesem Buch.';

  @override
  String get chapterAllRemoved => 'Alle Kapitel wurden entfernt';

  @override
  String get chapterFixHighlighted =>
      'Korrigiere zuerst die markierten Kapitel';

  @override
  String get chaptersUpdated => 'Kapitel aktualisiert';

  @override
  String get chapterReadAlongOnly =>
      'This book\'s chapters come from its read along ebook and can\'t be edited';

  @override
  String get ok => 'Ok';

  @override
  String get chapterSaveButton => 'Kapitel speichern';

  @override
  String get chapterAddHint => 'Kapitel hinzufügen (z.B. \"Kapitel 01\")';

  @override
  String get chapterAddTooltip => 'Kapitel hinzufügen(n)';

  @override
  String get chapterRemoveAll => 'Alle entfernen';

  @override
  String get chapterShiftTimes => 'Zeiten verschieben';

  @override
  String get chapterFromTracks => 'Aus Titel';

  @override
  String get chapterLookup => 'Suchen';

  @override
  String get chapterShowSeconds => 'Sekunden anzeigen';

  @override
  String chapterWindowMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get chapterLoopCut => 'Wiederhole den Schnitt';

  @override
  String get chapterFindStart => 'Finde den Start';

  @override
  String get chapterFindStartListening => 'Hören um die Markierung';

  @override
  String get chapterFindStartNone => 'Nichts hier klingt wie ein Kapitelbeginn';

  @override
  String get chapterFindStartWider => 'Suche breiter';

  @override
  String get chapterFindStartCeiling =>
      'Eine halbe Stunde um die Markierung gesucht. Der Start ist weiter entfernt oder es gibt keine Kapitel-Ankündigung zu hören.';

  @override
  String get chapterFindStartStrong => 'Klingt wie dieses Kapitel';

  @override
  String get chapterFindStartMaybe => 'Kapitel ähnliche Wörter';

  @override
  String chapterFindStartGap(String seconds) {
    return '$seconds s Abstand';
  }

  @override
  String chapterFindStartRange(String from, String to) {
    return 'Durchsucht von $from bis $to';
  }

  @override
  String get chapterFindStartNeedsModel =>
      'Transkription in den Einstellungen aktivieren und zuerst ein Modell herunterladen';

  @override
  String get chapterFindStartUseThis => 'Benutze das';

  @override
  String chapterFindStartTitle(String title) {
    return 'Titel: $title';
  }

  @override
  String get chapterShiftBySeconds => 'Verschieben um (Sekunden)';

  @override
  String get chapterShiftHint =>
      'Verschiebt jedes entsperrte Kapitel. Verwende einen negativen Wert, um sie früher zu verschieben.';

  @override
  String get chapterTitleHint => 'Kapitelname';

  @override
  String get chapterStopPreview => 'Vorschau stoppen';

  @override
  String get chapterPreviewFromHere => 'Vorschau ab hier';

  @override
  String get chapterScrubHint =>
      'Ziehe oder schiebe um den Anfang zu verschieben';

  @override
  String chapterStartAt(String time) {
    return 'Beginne bei $time';
  }

  @override
  String get chapterUnlock => 'Entsperren';

  @override
  String get chapterLock => 'Sperren';

  @override
  String get chapterInsertBelow => 'Unten einfügen';

  @override
  String get chapterFindTitle => 'Finde Kapitel';

  @override
  String get chapterFindSubtitle =>
      'Suche nach Kapitel bei Audible/Audnexus mittels ASIN.';

  @override
  String get chapterEnterAsin => 'ASIN eingeben';

  @override
  String get chapterLookupFailed => 'Suche fehlgeschlagen - Prüfe die ASIN';

  @override
  String get chapterNoChaptersFound => 'Keine Kapitel für die ASIN gefunden';

  @override
  String get chapterRemoveBranding => 'Entferne Audible Branding (Intro/Outro)';

  @override
  String chapterFoundCount(int count) {
    return '$count Kapitel gefunden';
  }

  @override
  String chapterAudibleVsBook(String audible, String book) {
    return 'Audible $audible  -  Buch $book';
  }

  @override
  String get chapterAudibleLonger =>
      'Die Audible Version ist länger als deine Datei - spätere Kapitel könnten abweichen.';

  @override
  String get chapterAudibleShorter =>
      'Die Audible Version ist kürzer als deine Datei - spätere Kapitel könnten abweichen.';

  @override
  String get chapterTitlesOnly => 'Nur Titel';

  @override
  String get chapterApplyChapters => 'Kapitel übernehmen';

  @override
  String get coverSearchTitle => 'Nach einem Cover suchen';

  @override
  String get coverSearchRefineHint =>
      'Den Titel/Autor verfeinern, um die Ergebnisse aufzuräumen - das ändert das Buch nicht.';

  @override
  String get coverNoneFound => 'Keine Cover gefunden';

  @override
  String get coverEnterTitleFirst => 'Gebe zuerst einen Titel ein';

  @override
  String get coverUpdated => 'Cover aktualisiert';

  @override
  String get coverCouldNotUpdate => 'Cover konnte nicht aktualisiert werden';

  @override
  String get coverApply => 'Cover anwenden';

  @override
  String get coverUnknownResolution => 'Unbekannte Auflösung';

  @override
  String get embedIntro =>
      'Bette Metadaten wie Cover und Kapitel in Audiodateien ein.';

  @override
  String get embedBackupOption => 'Audiodateien zuerst sichern';

  @override
  String get embedNoteInFolder =>
      'Metadaten werden in die Audiodateien in deinem Hörbuchordner eingebettet.';

  @override
  String get embedNoteMultiTrack =>
      'Kapitel werden nicht in Hörbücher eingebettet, die auf mehrere Dateien aufgeteilt sind.';

  @override
  String get embedNoteNavigateAway =>
      'Du kannst diese Seite verlassen, sobald die Aufgabe gestartet wurde.';

  @override
  String get embedStartButton => 'Metadaten einbetten';

  @override
  String embedProgress(String percent) {
    return 'Einbetten-Fortschritt: $percent%';
  }

  @override
  String get embedProgressIndeterminate => 'Einbetten...';

  @override
  String taskProgressKeepsRunning(String percent) {
    return '$percent% - läuft auch nach dem Verlassen der Seite weiter';
  }

  @override
  String get taskStarting => 'Wird gestartet...';

  @override
  String get embedBackupNoteIntro =>
      'Eine Sicherung der ursprünglichen Audiodateien erfolgt auf dem Server unter ';

  @override
  String embedBackupNotePath(String itemId) {
    return '/metadata/cache/items/$itemId/';
  }

  @override
  String get embedBackupNoteOutro =>
      '. Stelle sicher, dass du den Item-Cache regelmäßig löschst.';

  @override
  String get embedDialogTitle => 'Eingebettete Metadaten';

  @override
  String embedConfirmMessage(int count, String backup) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# Audiodateien',
      one: '# Audiodatei',
    );
    return 'Metadaten in $_temp0 einbetten? Deine Audiodateien werden überschrieben$backup.';
  }

  @override
  String get embedConfirmBackupClause => ' (Originale werden zuerst gesichert)';

  @override
  String get embedConfirmAction => 'Eingebettet';

  @override
  String get embedCouldNotStart => 'Einbetten konnte nicht gestartet werden';

  @override
  String get embedStarted => 'Einbetten gestartet';

  @override
  String get embedComplete => 'Einbetten abgeschlossen';

  @override
  String get embedFailed => 'Einbetten fehlgeschlagen';

  @override
  String get encodeComplete => 'Encodierung abgeschlossen';

  @override
  String get encodeFailedTask => 'Encodierung fehlgeschlagen';

  @override
  String encodeProgress(String percent) {
    return 'Encoding-Fortschritt $percent%';
  }

  @override
  String get encodeProgressIndeterminate => 'Encodiere...';

  @override
  String get adminApiKeys => 'API Keys';

  @override
  String get adminApiKeysSubtitle => 'Programmatische Zugriffstoken';

  @override
  String get adminApiKeysNewTitle => 'Neuer API Key';

  @override
  String get adminApiKeysName => 'Name';

  @override
  String get adminApiKeysNameHint => 'z.B. Home-Assistent';

  @override
  String get adminApiKeysOwner => 'Benutzer';

  @override
  String get adminApiKeysExpiration => 'Ablaufdatum';

  @override
  String get adminApiKeysActive => 'Aktiv';

  @override
  String get adminApiKeysActiveSub =>
      'Der Key funktioniert direkt nach dem Erstellen';

  @override
  String get adminApiKeysInactive => 'Inaktiv';

  @override
  String get adminApiKeysExpired => 'Abgelaufen';

  @override
  String get adminApiKeysCreate => 'Key erstellen';

  @override
  String get adminApiKeysCreated => 'API Key erstellt';

  @override
  String get adminApiKeysTokenLabel => 'Dein neuer API Key';

  @override
  String get adminApiKeysCopyWarning =>
      'Kopiere jetzt diesen Key. Aus Sicherheitsgründen wird dieser nicht mehr angezeigt.';

  @override
  String get adminApiKeysCopy => 'Kopieren';

  @override
  String get adminApiKeysCopied => 'In Zwischenablage kopiert';

  @override
  String get adminApiKeysDone => 'Erledigt';

  @override
  String get adminApiKeysDeleteTitle => 'API Key widerrufen?';

  @override
  String get adminApiKeysDeleted => 'Der API Key wurde widerrufen';

  @override
  String get adminApiKeysRevoke => 'Widerrufen';

  @override
  String get adminApiKeysSetActive => 'Als aktiv festlegen';

  @override
  String get adminApiKeysSetInactive => 'Als inaktiv festlegen';

  @override
  String get adminApiKeysFailedCreate => 'API Key konnte nicht erstellt werden';

  @override
  String get adminApiKeysFailedDelete =>
      'API Key konnte nicht widerrufen werden';

  @override
  String get adminApiKeysFailedUpdate =>
      'API Key konnte nicht aktualisiert werden';

  @override
  String get adminApiKeysEmpty => 'Noch keine API Key vorhanden';

  @override
  String get adminApiKeysEmptySub =>
      'Erstelle einen Key, damit Apps und Skripte deinen Server erreichen können';

  @override
  String get adminApiKeysNeverUsed => 'Nie benutzt';

  @override
  String get adminApiKeysNeverExpires => 'Kein Ablauf';

  @override
  String get adminApiKeysNameRequired => 'Namen eingeben';

  @override
  String get adminApiKeysUserRequired => 'Wähle einen Nutzer';

  @override
  String get adminApiKeysExpNever => 'Nie';

  @override
  String get adminApiKeysExp7d => '7 Tage';

  @override
  String get adminApiKeysExp30d => '30 Tage';

  @override
  String get adminApiKeysExp90d => '90 Tage';

  @override
  String get adminApiKeysExp1y => '1 Jahr';

  @override
  String adminApiKeysLastUsed(String time) {
    return 'Zuletzt genutzt $time';
  }

  @override
  String adminApiKeysExpiresOn(String date) {
    return 'Läuft ab am $date';
  }

  @override
  String adminApiKeysDeleteContent(String name) {
    return 'Widerrufe \"$name\"? Apps die diesen Key verwenden verlieren sofort den Zugriff.';
  }

  @override
  String get endOfEpisode => 'Ende der Folge';

  @override
  String get sleepTimerSheetEpisodeSleepStart => 'Sleep zum Ende der Folge';

  @override
  String get bookmarkListen => 'Anhören';

  @override
  String get bookmarkPause => 'Pausieren';

  @override
  String get bookmarkPreviewFailed => 'Stelle konnte nicht wiedergeben werden.';

  @override
  String get clipExport => 'Clip exportieren';

  @override
  String get clipJumpToStart => 'Zum Anfang springen';

  @override
  String get clipJumpToEnd => 'Zum Ende springen';

  @override
  String get clipSetStart => 'Anfang festlegen';

  @override
  String get clipSetEnd => 'Ende festlegen';

  @override
  String get clipInLabel => 'Rein';

  @override
  String get clipOutLabel => 'Raus';

  @override
  String get clipSave => 'Clip speichern';

  @override
  String clipExportSaved(String filename) {
    return 'Gespeichert: $filename';
  }

  @override
  String get clipExportClamped =>
      'Clip gespeichert, gekürzt bis zum Ende dieses Titels';

  @override
  String get clipExportFailed => 'Clip konnte nicht exportiert werden.';

  @override
  String get clipDownloadToExport =>
      'Lade dieses Buch zuerst herunter, um einen Clip auf das iPhone zu exportieren.';

  @override
  String get fsPickerTitle => 'Ordner auswählen';

  @override
  String get fsServerRoot => 'Server-Root';

  @override
  String get fsEmptyFolder => 'Keine Unterordner vorhanden';

  @override
  String get fsUseThisFolder => 'Diesen Ordner verwenden';

  @override
  String get adminLibrariesManage => 'Bibliotheken';

  @override
  String get adminLibrariesManageSubtitle =>
      'Erstellen, bearbeiten und umsortieren';

  @override
  String get adminUploadTitle => 'Medien Hochladen';

  @override
  String get adminUploadSubtitle =>
      'Bücher und Podcasts aus Dateien hinzufügen';

  @override
  String get adminUploadNoLibraries =>
      'Erstelle eine Bibliothek, bevor du die Medien hochlädst.';

  @override
  String get adminUploadDestination => 'Ziel';

  @override
  String get adminUploadFolder => 'Bibliotheksordner';

  @override
  String get adminUploadDetails => 'Eintrag-Details';

  @override
  String get adminUploadOptional => 'Optional';

  @override
  String get adminUploadAutoMetadata => 'Metadaten automatisch abrufen';

  @override
  String get adminUploadAutoMetadataSubtitle =>
      'Titel, Autor und Reihe aus der besten Übereinstimmung übernehmen';

  @override
  String get adminUploadMetadataProvider => 'Metadaten-Anbieter';

  @override
  String get adminUploadMetadataSearching => 'Suche nach Metadaten...';

  @override
  String get adminUploadMetadataNoResults =>
      'Keine Metadaten gefunden. Du kannst dieses Element trotzdem hochladen.';

  @override
  String get adminUploadMetadataFailed =>
      'Konnte nicht nach Metadaten suchen. Du kannst dieses Element trotzdem hochladen.';

  @override
  String get adminUploadDestinationPreview => 'Server Ziel';

  @override
  String get adminUploadFiles => 'Dateien';

  @override
  String adminUploadSelectedFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Dateien',
      one: '1 Datei',
    );
    return '$_temp0';
  }

  @override
  String get adminUploadChooseFiles => 'Datei auswählen';

  @override
  String get adminUploadAddFiles => 'Dateien hinzufügen';

  @override
  String get adminUploadBookFilesHint =>
      'Wähle Audio- oder eBook-Dateien. Du kannst auch Cover- und Metadatendateien einbinden.';

  @override
  String get adminUploadPodcastFilesHint =>
      'Wähle eine oder mehrere Audiodateien. Du kannst auch Cover- und Metadatendateien einfügen.';

  @override
  String get adminUploadUnsupportedFiles =>
      'Einige der ausgewählten Dateien werden von Audiobookshelf nicht unterstützt.';

  @override
  String get adminUploadFilePickerFailed =>
      'Konnte die gewählten Dateien nicht öffnen.';

  @override
  String get adminUploadTitleRequired => 'Titel eingeben';

  @override
  String get adminUploadLibraryRequired => 'Wähle eine Bibliothek';

  @override
  String get adminUploadFolderRequired => 'Wähle einen Bibliotheksordner';

  @override
  String get adminUploadFilesRequired => 'Mindestens eine Datei auswählen';

  @override
  String get adminUploadPodcastFileRequired =>
      'Wähle mindestens eine Audiodatei für diesen Podcast.';

  @override
  String get adminUploadBookFileRequired =>
      'Wähle mindestens eine Audio- oder eBook-Datei für dieses Buch.';

  @override
  String get adminUploadPathCheckFailed =>
      'Der Zielordner konnte nicht überprüft werden. Es wurde nichts hochgeladen.';

  @override
  String get adminUploadDestinationExists =>
      'Dieser Zielordner existiert bereits auf dem Server.';

  @override
  String adminUploadDestinationUsedBy(String title) {
    return 'Dieses Ziel wird bereits von \"$title\" verwendet.';
  }

  @override
  String get adminUploadAddToExistingTitle => 'Ordner existiert bereits';

  @override
  String adminUploadAddToExisting(String title) {
    return 'Dieser Ordner gehört zu \"$title\". Dateien hinzufügen? Der Server nimmt sie beim nächsten Scannen auf.';
  }

  @override
  String get adminUploadAddToExistingNoItem =>
      'Dieser Ordner ist auf dem Server bereits vorhanden. Dateien hinzufügen?';

  @override
  String get adminUploadAddToBook => 'Zu einem vorhandenen Buch hinzufügen';

  @override
  String get adminUploadAddToBookHint => 'Diese Bibliothek durchsuchen';

  @override
  String get adminUploadNoBooksFound => 'Keine Bücher gefunden';

  @override
  String adminUploadAddingTo(String title) {
    return 'Dateien zu \"$title \" hinzufügen';
  }

  @override
  String adminUploadAddedTo(String title) {
    return 'Dateien zu \"$title\" hinzugefügt';
  }

  @override
  String get adminUploadTargetNoFolder =>
      'Konnte den Ordner des Buches auf dem Server nicht finden.';

  @override
  String adminUploadTargetFolderMismatch(String preview, String folder) {
    return 'Der Server würde diese Dateien in „$preview“ ablegen, nicht in den Ordner „$folder“ des Buches. Es wurde nichts hochgeladen.';
  }

  @override
  String get adminUploadUploading => 'Wird hochgeladen...';

  @override
  String adminUploadProgress(int percent) {
    return 'Fortschritt beim Hochladen: $percent %';
  }

  @override
  String get adminUploadButton => 'Hochladen';

  @override
  String adminUploadComplete(String title) {
    return '\"$title\" hochgeladen';
  }

  @override
  String get adminUploadFailed => 'Hochladen fehlgeschlagen';

  @override
  String adminUploadFailedReason(String error) {
    return 'Hochladen fehlgeschlagen: $error';
  }

  @override
  String get adminUploadReselectFiles =>
      'Wähle die Dateien erneut aus, bevor du es wieder versuchst.';

  @override
  String get adminServerSettings => 'Servereinstellungen';

  @override
  String get adminServerSettingsSubtitle => 'Scanner, Speicher und Sortierung';

  @override
  String get adminAuthentication => 'Authentifizierung';

  @override
  String get adminAuthenticationSubtitle =>
      'Passwort und OpenID Connect Anmeldung';

  @override
  String get adminStats => 'Statistiken';

  @override
  String get adminStatsSubtitle => 'Bibliothek und Hörstatistik';

  @override
  String get adminAllSessions => 'Alle Sitzungen';

  @override
  String get adminAllSessionsSubtitle =>
      'Alle Hörsitzungen anzeigen und verwalten';

  @override
  String get adminSessionsAllUsers => 'Alle Benutzer';

  @override
  String get adminSessionsEmpty => 'Keine Sitzungen';

  @override
  String get statsLibraryTotals => 'Gesamtsumme der Bibliothek';

  @override
  String get statsTotalItems => 'Elemente';

  @override
  String get statsAudioFiles => 'Audiodateien';

  @override
  String get statsTotalSize => 'Größe (gesamt)';

  @override
  String get statsBooks => 'Bücher';

  @override
  String get statsPodcasts => 'Podcasts';

  @override
  String get statsBooksSize => 'Büchergröße';

  @override
  String get statsYearReview => 'Jahresrückblick';

  @override
  String get statsNoYearData => 'Keine Daten für dieses Jahr';

  @override
  String get statsListeningTime => 'Wiedergabedauer';

  @override
  String get statsSessions => 'Sitzungen';

  @override
  String get statsBooksAdded => 'Bücher hinzugefügt';

  @override
  String get statsAuthorsAdded => 'Autoren hinzugefügt';

  @override
  String get statsTopAuthors => 'Top Autoren';

  @override
  String get statsTopNarrators => 'Top Erzähler';

  @override
  String get statsTopGenres => 'Top Genres';

  @override
  String get srvScannerSection => 'Scanner';

  @override
  String get srvFindCovers => 'Cover suchen';

  @override
  String get srvCoverProvider => 'Cover Anbieter';

  @override
  String get srvParseSubtitles => 'Untertitel aus Dateinamen extrahieren';

  @override
  String get srvPreferMatched => 'Übereinstimmende Metadaten bevorzugen';

  @override
  String get srvDisableWatcher => 'Ordnerbeobachter deaktivieren';

  @override
  String get srvStorageSection => 'Speicher';

  @override
  String get srvStoreCover => 'Cover in Datei einbetten';

  @override
  String get srvStoreMetadata => 'Metadaten in Datei einbetten';

  @override
  String get srvMetadataFormat => 'Metadaten Dateiformat';

  @override
  String get srvFormatSection => 'Anzeige und Format';

  @override
  String get srvDateFormat => 'Datumsformat';

  @override
  String get srvTimeFormat => 'Zeitformat';

  @override
  String get srvLanguage => 'Serversprache';

  @override
  String get srvChromecast => 'Chromecast Unterstützung';

  @override
  String get srvAllowIframe => 'Iframe-Einbettung erlauben';

  @override
  String get srvSortingSection => 'Sortierung';

  @override
  String get srvIgnorePrefixes => 'Präfixe beim Sortieren ignorieren';

  @override
  String get srvSortingPrefixes => 'Präfixe sortieren';

  @override
  String get srvAddPrefix => 'Präfix hinzufügen';

  @override
  String get srvSave => 'Einstellungen speichern';

  @override
  String get srvSavePrefixes => 'Präfixe speichern';

  @override
  String get srvSaved => 'Einstellungen gespeichert';

  @override
  String get srvSaveFailed => 'Einstellungen konnten nicht gespeichert werden';

  @override
  String get srvPrefixesSaved => 'Sortierungspräfixe aktualisiert';

  @override
  String get authSetLoadFailed =>
      'Authentifizierungseinstellungen konnten nicht geladen werden';

  @override
  String get authSetCustomMessage =>
      'Benutzerdefinierte Nachricht beim Anmelden';

  @override
  String get authSetMessage => 'Nachricht';

  @override
  String get authSetPasswordAuth => 'Authentifizierung mit Passwort';

  @override
  String get authSetOpenId => 'OpenID Connect Authentifizierung';

  @override
  String get authSetGuide => 'Einrichtungsanleitung';

  @override
  String get authSetIssuerUrl => 'URL des Ausstellers';

  @override
  String get authSetAutoPopulate => 'automatisch ausgefüllt';

  @override
  String get authSetAuthorizeUrl => 'URL autorisieren';

  @override
  String get authSetTokenUrl => 'Token URL';

  @override
  String get authSetUserinfoUrl => 'Benutzerinfo-URL';

  @override
  String get authSetJwksUrl => 'JWKS URL';

  @override
  String get authSetLogoutUrl => 'Abmelde-URL';

  @override
  String get authSetClientId => 'Client ID';

  @override
  String get authSetClientSecret => 'Client-Secret';

  @override
  String get authSetSigningAlgorithm => 'Signatur-Algorithmus';

  @override
  String get authSetRedirectUris => 'Erlaubte mobile Weiterleitung-URIs';

  @override
  String get authSetRedirectUrisInfo =>
      'Apps können nach der Anmeldung nur zu diesen Adressen zurückkehren. Absorb verwendet absorb://oauth. Ein Sternchen (*) als einziger Eintrag lässt eine beliebige Adresse zu.';

  @override
  String get authSetAddRedirectUri => 'URI hinzufügen';

  @override
  String get authSetAddAbsorbRedirect => 'absorb://oauth hinzufügen';

  @override
  String get authSetSubfolder => 'Unterordner für Weiterleitungs-URLs';

  @override
  String get authSetSubfolderNone => 'Keine';

  @override
  String get authSetWebRedirectInfo =>
      'Erlaube diesen URLs in deinem OAuth-Anbieter, damit die Anmeldung zur Web-App zurückkehren kann:';

  @override
  String get authSetButtonText => 'Text der Schaltfläche';

  @override
  String get authSetMatchExisting => 'Bestehende Benutzer zuordnen nach';

  @override
  String get authSetMatchNone => 'Nicht passend';

  @override
  String get authSetMatchEmail => 'E-Mail';

  @override
  String get authSetMatchUsername => 'Benutzername';

  @override
  String get authSetMatchExistingInfo =>
      'Wird verwendet, um bestehende Benutzer zu verlinken. Sobald sie verlinkt sind, werden Benutzer mit ihrer einzigartigen ID des Anbieters verknüpft.';

  @override
  String get authSetAutoLaunch => 'Automatisch starten';

  @override
  String get authSetAutoLaunchInfo =>
      'Öffne den Provider automatisch von der Web-Login-Seite. /login?autoLaunch=0 überspringt diese.';

  @override
  String get authSetAutoRegister => 'Automatisch registrieren';

  @override
  String get authSetAutoRegisterInfo =>
      'Neue Benutzer automatisch erstellen, nachdem sie sich angemeldet haben';

  @override
  String get authSetClaimsInfo =>
      'Lassen Sie diese leer, um Gruppe und Berechtigung zu deaktivieren. Neue Benutzer erhalten dann die Benutzerrolle.';

  @override
  String get authSetGroupClaim => 'Gruppen Claim';

  @override
  String get authSetGroupClaimInfo =>
      'Ein Claim, der die Gruppen des Benutzers auflistet (üblicherweise unter der Bezeichnung „groups“). Gruppen mit den Namen „admin“, „user“ oder „guest“ legen die Rolle fest, wobei die ranghöchste Rolle maßgeblich ist. Stimmt keine der Gruppen überein, wird die Anmeldung verweigert.';

  @override
  String get authSetPermsClaim => 'Erweiterter Berechtigungs- Claim';

  @override
  String get authSetPermsClaimInfo =>
      'Claim mit Berechtigungen für Nicht-Administrator-Benutzer. Fehlt der Claim, wird die Anmeldung verweigert; eine fehlende Option wird als „deaktiviert“ gewertet. Erwartetes Format:';

  @override
  String get authSetRestartNote =>
      'Starten Sie den Server nach dem Speichern neu, um die OpenID Connect Änderungen zu übernehmen.';

  @override
  String get authSetNoChanges => 'Keine Änderungen zum Speichern';

  @override
  String get authSetNeedOneMethod =>
      'Mindestens eine Anmeldemethode aktivieren';

  @override
  String authSetFieldRequired(String field) {
    return '$field ist erforderlich';
  }

  @override
  String authSetInvalidRedirectUri(String uri) {
    return 'Ungültige Weiterleitungs-URI: $uri';
  }

  @override
  String get authSetAsteriskAlone =>
      'Ein Stern (*) muss die einzige Weiterleitung URI sein';

  @override
  String authSetInvalidClaim(String field) {
    return '$field ist kein gültiger Claim Name';
  }

  @override
  String authSetIssuerFailed(String error) {
    return 'Aussteller konnte nicht gelesen werden: $error';
  }

  @override
  String get libNoneYet => 'Noch keine Bibliotheken vorhanden';

  @override
  String get libReorderFailed =>
      'Neue Reihenfolge konnte nicht gespeichert werden';

  @override
  String get libDeleteTitle => 'Bibliothek löschen?';

  @override
  String get libDeleteBody =>
      'Dies entfernt die Bibliothek und alle Elemente dauerhaft vom Server.';

  @override
  String get libDeleted => 'Bibliothek gelöscht';

  @override
  String get libDeleteFailed => 'Bibliothek konnte nicht gelöscht werden';

  @override
  String libFolderCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Ordner',
      one: '1 Ordner',
    );
    return '$_temp0';
  }

  @override
  String get libNewTitle => 'Neue Bibliothek';

  @override
  String get libEditTitle => 'Bibliothek bearbeiten';

  @override
  String get libName => 'Name der Bibliothek';

  @override
  String get libMediaType => 'Medienart';

  @override
  String get libMediaBook => 'Bücher';

  @override
  String get libMediaPodcast => 'Podcasts';

  @override
  String get libProvider => 'Metadaten-Anbieter';

  @override
  String get libIcon => 'Icon';

  @override
  String get libFolders => 'Ordner';

  @override
  String get libAddFolder => 'Ordner hinzufügen';

  @override
  String get libNoFolders => 'Füge mindestens einen Ordner hinzu';

  @override
  String get libAdvanced => 'Erweiterte Einstellungen';

  @override
  String get libCoverShape => 'Form des Covers';

  @override
  String get libCoverSquare => 'Quadratisch';

  @override
  String get libCoverStandard => 'Standard';

  @override
  String get libDisableWatcher => 'Ordnerbeobachter deaktivieren';

  @override
  String get libSkipAsin =>
      'Überspringe den Abgleich von Büchern die über eine ASIN verfügen';

  @override
  String get libSkipIsbn =>
      'Überspringe den Abgleich von Büchern die über eine ISBN verfügen';

  @override
  String get libHideSingleSeries => 'Einzelbuchreihe ausblenden';

  @override
  String get libAudiobooksOnly => 'Nur Hörbücher';

  @override
  String get libEpubScripted => 'Scripted ePub Inhalt zulassen';

  @override
  String get libLaterBooksOnly =>
      'Nur aktuellere Bücher in Serie fortsetzen anzeigen';

  @override
  String get libPodcastRegion => 'Podcast Suchregion';

  @override
  String get libMarkPercent => 'Bei % als beendet markieren';

  @override
  String get libMarkTime => 'Beendet mit Sekunden verbleibend';

  @override
  String get libAutoScan => 'Auto-Scan Zeitplan (cron)';

  @override
  String get libCreate => 'Neue Bibliothek erstellen';

  @override
  String get libUpdate => 'Änderungen speichern';

  @override
  String get libNameRequired => 'Bibliotheksnamen eingeben';

  @override
  String get libCreated => 'Bibliothek erstellt';

  @override
  String get libCreateFailed => 'Bibliothek konnte nicht erstellt werden';

  @override
  String get libUpdated => 'Bibliothek aktualisiert';

  @override
  String get libUpdateFailed => 'Bibliothek konnte nicht aktualisiert werden';

  @override
  String get libRemoveFoldersTitle => 'Ordner löschen?';

  @override
  String get libRemoveFoldersBody =>
      'Das Löschen eines Ordners entfernt alle seine Einträge aus der Bibliothek. Der Vorgang kann nicht rückgängig gemacht werden.';

  @override
  String get readEbook => 'Lesen';

  @override
  String get ebookDownload => 'Herunterladen';

  @override
  String get ebookDownloaded => 'Heruntergeladen';

  @override
  String get ebookSavedOffline => 'Zum offline Lesen gespeichert';

  @override
  String get ebookRemovedOffline => 'Offlineinhalt entfernt';

  @override
  String get ebookOfflineFailed =>
      'Das eBook konnte nicht heruntergeladen werden';

  @override
  String get ebookSaveToDevice => 'Auf Gerät speichern';

  @override
  String get ebookSaveToDeviceTitle => 'Auf Gerät speichern?';

  @override
  String get ebookSaveToDeviceBody =>
      'Dies speichert eine Kopie der eBook-Datei auf deinem Gerät (du bestimmst das Verzeichnis). Das Buch wird nicht im offline Reader verfügbar sein - verwende dafür den Download.';

  @override
  String get ebookSaveNarratedBody =>
      'This EPUB has its narration built in, so the full file is large. Text only saves just the book\'s text and pictures, which is much smaller.';

  @override
  String get ebookSaveTextOnly => 'Text only';

  @override
  String get ebookSaveWithNarration => 'With narration';

  @override
  String get readerFormatUnsupported =>
      'Dieses eBook-Format kann noch nicht im Reader geöffnet werden';

  @override
  String get readerCouldNotOpen =>
      'Dieses E-Book konnte nicht geöffnet werden. Die Datei könnte beschädigt sein.';

  @override
  String get moreActions => 'Mehr';

  @override
  String get readerChapters => 'Kapitel';

  @override
  String get readerSettings => 'Reader-Einstellungen';

  @override
  String get readerFontSize => 'Schriftgröße';

  @override
  String get readerLineSpacing => 'Zeilenabstand';

  @override
  String get readerTextAlignment => 'Ausrichtung';

  @override
  String get readerAlignJustified => 'Blocksatz';

  @override
  String get readerAlignLeft => 'Links';

  @override
  String get readerSideMargins => 'Seitenrand';

  @override
  String get readerTopBottom => 'Oben & Unten';

  @override
  String get readerPageLayout => 'Seitenlayout';

  @override
  String get readerPinTopBar =>
      'Titel und Fortschrittsbalken auf dem Bildschirm beibehalten';

  @override
  String get readerPinTopBarHint =>
      'Fixiert sie oberhalb der Seite, anstatt sie beim Antippen einzublenden. Die Seite wird dadurch etwas kürzer, sodass kein Text verdeckt wird.';

  @override
  String get readerTopBarProgress => 'Fortschritt in der oberen Leiste';

  @override
  String get readerTopBarProgressBook => 'Buch';

  @override
  String get readerTopBarProgressChapter => 'Kapitel';

  @override
  String get readerTopBarProgressBoth => 'Beides';

  @override
  String get readerSectionText => 'Text';

  @override
  String get readerSectionPage => 'Seite';

  @override
  String get readerSectionTopBar => 'Obere Leiste und Bildschirm';

  @override
  String get readerSectionControls => 'Steuerung';

  @override
  String get readerSectionStats => 'Statistiken';

  @override
  String get readerSectionReading => 'Lesen';

  @override
  String get readerSectionScreen => 'Screen';

  @override
  String get readerParagraphSpacing => 'Absatzabstand';

  @override
  String get readerParagraphSpacingBook => 'Aus dem Buch';

  @override
  String get readerTapZones => 'Tippbereiche';

  @override
  String get readerTapZonesHint =>
      'Ziehe die Linien, um die Größe der Felder anzupassen. Tippe auf ein Feld, um dessen Funktion zu ändern, oder beginne mit einem vorgefertigten Layout.';

  @override
  String get readerTapZonesCardTop => 'Nach oben verschieben';

  @override
  String get readerTapZonesCardBottom => 'Nach unten verschieben';

  @override
  String get readerTapZonesCardHide => 'Karte verkleinern';

  @override
  String get readerTapZonesCardShow => 'Karte zeigen';

  @override
  String get readerTapPrev => 'Vorherige Seite';

  @override
  String get readerTapNext => 'Nächste Seite';

  @override
  String get readerTapMenu => 'Steuerung anzeigen';

  @override
  String get readerTapNothing => 'Nichts';

  @override
  String get readerTapKeepMenu => 'Ein Feld muss die Steuerelemente anzeigen';

  @override
  String get readerHideControls => 'Steuerung ausblenden nach';

  @override
  String get readerHideControlsNever => 'Niemals';

  @override
  String get readerBarNotes => 'Notizen und Hervorhebung';

  @override
  String readerHideControlsAfter(int seconds) {
    return '$seconds Sek';
  }

  @override
  String get playerDownloadStreamingInstead =>
      'Dieser Download konnte nicht abgespielt werden; es wird daher vom Server gestreamt. Ein erneuter Download könnte das Problem beheben.';

  @override
  String get readerPageTurn => 'Umblättern';

  @override
  String get readerPageTurnNone => 'Keine';

  @override
  String get readerPageTurnSlide => 'Gleiten';

  @override
  String get readerPageTurnCurl => 'Seitenrolle';

  @override
  String get readerPageTurnRipple => 'Welle';

  @override
  String get readerScrollMode => 'Scroll-Modus';

  @override
  String get readerSentenceMode => 'Satzmodus';

  @override
  String get readerSentenceModeHint =>
      'Satz für Satz – tippen oder wischen, um weiterzukommen. Gilt für jedes Buch.';

  @override
  String get readerSentencesAtATime => 'Satz für Satz';

  @override
  String get readerSentenceTransition => 'Übergangseffekte';

  @override
  String get readerSentenceTransitionFade => 'Überblenden';

  @override
  String get readerSentenceTransitionBurst => 'Platzen';

  @override
  String get readerSentenceSpeed => 'Geschwindigkeit';

  @override
  String get readerSentenceAutoAdvance => 'Automatisches Vorrücken';

  @override
  String readerSentenceWpmValue(int wpm) {
    return '$wpm Wörter pro Minute';
  }

  @override
  String get readerSentencePreparing => 'Sätze vorbereiten';

  @override
  String get readerSentenceEnd => 'Das ist das Ende des Buches';

  @override
  String get readerScrollModeHint =>
      'Scrollen Sie durch das Buch, anstatt Seiten zu drehen. Gilt für jedes Buch.';

  @override
  String get readerKeepAwake => 'Bildschirm ein lassen';

  @override
  String get readerKeepAwakeHint =>
      'Verhindert, dass der Bildschirm nach einer bestimmten Zeit automatisch ausgeschaltet wird, während Sie in Ihrem eigenen Tempo lesen. Durch die Funktionen automatischer Bildlauf und Mitlesen bleibt der Bildschirm stets eingeschaltet.';

  @override
  String get readerLayoutAuto => 'Automatisch';

  @override
  String get readerLayoutSingle => 'Eine Seite';

  @override
  String get readerLayoutTwoPage => 'Zwei Seiten';

  @override
  String get readerTheme => 'Thema';

  @override
  String get readerFont => 'Schriftart';

  @override
  String get readerVolumeNav => 'Lautstärketasten blättern Seiten um';

  @override
  String get readerVolumeNavOff => 'Aus';

  @override
  String get readerVolumeNavNormal => 'Normal';

  @override
  String get readerVolumeNavMirrored => 'Gespiegelt';

  @override
  String get readerAutoScroll => 'Automatischer Bildlauf';

  @override
  String get readerAutoScrollSubtitle =>
      'Die nächste Seite überdeckt diese von oben nach unten – ziehe in der Mitte des Bildschirms, um die Geschwindigkeit zu ändern; tippe, um anzuhalten';

  @override
  String get readerAutoScrollStarted => 'Automatischer Bildlauf gestartet';

  @override
  String get readerAutoScrollPaused =>
      'Pausiert - Drücke und halte um zu stoppen';

  @override
  String get readerAutoScrollResumed => 'Automatischer Bildlauf fortgesetzt';

  @override
  String get readerAutoScrollStopped => 'Automatischer Bildlauf aus';

  @override
  String get readerAutoScrollEndOfBook =>
      'Ende des Buchs - automatischer Bildlauf aus';

  @override
  String get readerMoreControls => 'Weitere Steuerelemente';

  @override
  String get readerAutoScrollSleep => 'Sleep-Timer automatischer Bildlauf';

  @override
  String get readerAutoScrollSleepHint =>
      'Stoppt den Bildlauf nach einer Weile und lässt den Bildschirm dunkel werden.';

  @override
  String readerAutoScrollSleepMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String readerAutoScrollSleepLeft(int minutes) {
    return '$minutes min übrig';
  }

  @override
  String readerAutoScrollSleepIn(int minutes) {
    return 'Bildlauf stoppt in $minutes Minuten';
  }

  @override
  String get readerAutoScrollSleepOff =>
      'Automatischer Bildlauf, Sleep-Timer aus';

  @override
  String get readerAutoScrollSleepEnded =>
      'Sleep-Timer – automatischer Bildlauf aus';

  @override
  String get readerDownloadStarted => 'Download gestartet';

  @override
  String get detailChaptersJumpTitle => 'Zu diesem Kapitel springen?';

  @override
  String detailChaptersJumpContent(String title) {
    return 'Die Wiedergabe wechselt zu „$title“.';
  }

  @override
  String get detailChaptersJump => 'Springen';

  @override
  String detailChaptersFinished(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Kapitel abgeschlossen',
      one: '1 Kapitel abgeschlossen',
    );
    return '$_temp0';
  }

  @override
  String detailOtherListeners(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count weitere Hörer',
      one: '1 weiterer Hörer',
      zero: 'Keine weiteren Hörer',
    );
    return '$_temp0';
  }

  @override
  String get seriesUpNext => 'Als nächstes';

  @override
  String get seriesJumpToUpNext => 'Weiter zu „Als Nächstes“';

  @override
  String get seriesStatsFinished => 'Beendet';

  @override
  String get seriesStatsListened => 'Gehört';

  @override
  String get seriesStatsLeft => 'Übrig';

  @override
  String seriesFinishedOf(int done, int total) {
    return '$done von $total';
  }

  @override
  String get detailSessionsNone => 'Noch keine Hörsitzungen';

  @override
  String detailSessionsAll(int count) {
    return 'Alle $count Sitzungen';
  }

  @override
  String get readerVolumeNavWhilePlaying =>
      'Selbst während Audio abgespielt wird';

  @override
  String get readerTranslateWith => 'Übersetzen mit';

  @override
  String get readerTranslateApp => 'Anwendung auf diesem Gerät';

  @override
  String get readerTranslateApple => 'In iOS integriert';

  @override
  String get readerTranslateWeb => 'Öffnet sich in deinem Browser';

  @override
  String get readerTranslateHint =>
      'Der ausgewählte Text wird an den von dir ausgewählten Übersetzer gesendet.';

  @override
  String get readerMoreFonts => 'Weitere Schriftarten herunterladen';

  @override
  String get readerFontRemove => 'Download entfernen';

  @override
  String readerFontDownloadFailed(String font) {
    return '$font konnte nicht heruntergeladen werden';
  }

  @override
  String get readerAnnotations => 'Anmerkungen';

  @override
  String readerHighlights(int count) {
    return 'Hervorhebungen ($count)';
  }

  @override
  String readerBookmarks(int count) {
    return 'Lesezeichen ($count)';
  }

  @override
  String get readerNoHighlights => 'Noch keine Hervorhebungen';

  @override
  String get readerHistory => 'Verlauf';

  @override
  String get sessionReading => 'Lesen';

  @override
  String get readerHistoryEmpty =>
      'Seiten, die du verlässt, werden hier aufgelistet, damit du jederzeit zu ihnen zurückkehren kannst.';

  @override
  String get readerHistoryClosed => 'Das Buch zugeklappt';

  @override
  String get readerHistoryBeforeJump => 'Vor einem Sprung';

  @override
  String get readerHistoryBeforeSync => 'Vor dem Abgleich mit der Audiodatei';

  @override
  String get readerLogReading => 'Lesezeit in Statistiken zählen';

  @override
  String get readerLogReadingHint =>
      'Deine Zeit im Reader wird als Sitzung erfasst, sodass sie in deinen Statistiken erscheint. Bei Audiobookshelf zählt dies als Hörzeit.';

  @override
  String get readerNoBookmarks => 'Noch keine Lesezeichen';

  @override
  String get readerBookmarkDefault => 'Lesezeichen';

  @override
  String get readerNoteTitle => 'Notiz';

  @override
  String get readerNoteHint => 'Notiz hinzufügen...';

  @override
  String get backupAndSync => 'Sicherung und Synchronisierung';

  @override
  String get backupAndSyncSubtitle =>
      'Erstellen Sie eine Sicherungsdatei oder halten Sie die Einstellungen geräteübergreifend synchron.';

  @override
  String get syncSettingsExperimental => 'Experimentell';

  @override
  String get syncSettingsExperimentalBody =>
      'Die Synchronisierungsfunktion ist neu und befindet sich noch in der Entwicklung. Wenn auf zwei Geräten während einer Zeit der Trennung Änderungen vorgenommen werden, können die Änderungen auf einer der Seiten verloren gehen. Bewahren Sie daher eine Sicherungsdatei als verlässliche Kopie auf.';

  @override
  String get syncSettingsNeedServer => 'Brauchst du einen Server?';

  @override
  String get syncSettingsNeedServerSub =>
      'Jeder WebDAV-Server funktioniert. Nextcloud ist eine kostenlose, selbst gehostete Lösung.';

  @override
  String get syncSettingsConnection => 'Verbindung';

  @override
  String get syncSettingsConnectionNotSet => 'Nicht eingerichtet';

  @override
  String get syncSettingsBackupFile => 'Sicherungsdatei';

  @override
  String get syncSettingsBackupFilePlain =>
      'Speichere alles in einer Datei, die du aufbewahrst.';

  @override
  String get syncSettingsBackupFileWithSync =>
      'Speichere alles in einer Datei, die du aufbewahrst. Wenn du deine Anmeldedaten verwendest, um die Daten auf einem anderen Telefon wiederherzustellen, wird dort auch die Synchronisierung aktiviert.';

  @override
  String get syncSettingsStatusOff => 'Keine Synchronisation';

  @override
  String get syncSettingsStatusProblem => 'Server nicht erreichbar';

  @override
  String get syncSettings => 'Einstellungen zwischen Geräten synchronisieren';

  @override
  String get syncSettingsExtras => 'Ebenfalls synchronisieren';

  @override
  String get syncSettingsIncludeRmab => 'ReadMeABook Einstellungen';

  @override
  String get syncSettingsIncludeRmabSub =>
      'Fügt dein ReadMeABook API-Token in die synchronisierte Datei ein';

  @override
  String get syncSettingsSubtitle =>
      'Halten Sie Ihre Einstellungen mithilfe eines eigenen WebDAV-Servers synchron';

  @override
  String get syncSettingsEnable => 'Synchronisierungseinstellungen';

  @override
  String get syncSettingsServerUrl => 'WebDAV Ordner URL';

  @override
  String get syncSettingsServerUrlHint =>
      'https://cloud.example.com/remote.php/dav/files/you/Absorb';

  @override
  String get syncSettingsUsername => 'Benutzername';

  @override
  String get syncSettingsPassword => 'Passwort';

  @override
  String get syncSettingsHeaders => 'Benutzerdefinierte Header (optional)';

  @override
  String get syncSettingsHeadersHint =>
      'Einer pro Zeile, zum Beispiel: CF-Access-Client-Id: abc123';

  @override
  String get syncSettingsTest => 'Verbindung testen';

  @override
  String get syncSettingsHoldToUpload =>
      'Gedrückt halten, um jetzt hochzuladen';

  @override
  String get syncSettingsUploadNow => 'Jetzt hochladen';

  @override
  String get syncSettingsDownloadNow => 'Jetzt herunterladen';

  @override
  String get syncSettingsOk => 'Verbunden';

  @override
  String get syncSettingsNoRemote => 'Verbunden - noch nichts Synchronisiert';

  @override
  String get syncSettingsAuthFailed => 'Falscher Benutzername oder Passwort';

  @override
  String get syncSettingsNetworkError => 'Adresse konnte nicht erreicht werden';

  @override
  String get syncSettingsNotConfigured =>
      'Zuerst Adresse, Benutzername und Passwort ausfüllen';

  @override
  String get syncSettingsTooLarge =>
      'Einstellungen zu groß zum synchronisieren';

  @override
  String get syncSettingsUploaded => 'Einstellungen hochgeladen';

  @override
  String get syncSettingsApplied =>
      'Einstellungen von anderem Gerät aktualisiert';

  @override
  String syncSettingsAppliedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Einstellungen von deinem anderen Gerät aktualisiert',
      one: '1 Einstellung von deinem anderen Gerät aktualisiert',
    );
    return '$_temp0';
  }

  @override
  String get syncSettingsUpToDate => 'Bereits auf dem neusten Stand';

  @override
  String syncSettingsLastSynced(String when) {
    return 'Zuletzt synchronisiert $when';
  }

  @override
  String get syncSettingsNever => 'Noch nicht synchronisiert';

  @override
  String navHoldPickTitle(String tab) {
    return 'Halten von $tab wird...';
  }

  @override
  String get navHoldPickBody =>
      'Wähle aus, was ein langes Drücken auf diesem Tab bewirkt. Du kannst das Verhalten jederzeit in den Einstellungen ändern.';

  @override
  String get navHoldSettingTitle => 'Tab hält Verknüpfungen';

  @override
  String get navHoldSettingSubtitle =>
      'Was passiert, wenn man den einzelnen Tab gedrückt hält';

  @override
  String get navHoldAskNextTime => 'Erneut fragen';

  @override
  String get navHoldNothing => 'Nichts';

  @override
  String get navHoldPlayPause => 'Play / Pause';

  @override
  String get navHoldOfflineMode => 'Offline Modus';

  @override
  String get navHoldOfflineOn => 'Offline Modus an';

  @override
  String get navHoldOfflineOff => 'Offline Modus aus';

  @override
  String get navHoldMenu => 'Menü immer anzeigen';

  @override
  String get navHoldStop => 'Wiedergabe stoppen';

  @override
  String get navHoldRmabSearch => 'ReadMeABook Suche';

  @override
  String get navHoldRmabRequests => 'Meine Buchanfragen';

  @override
  String get navHoldRmabWeb => 'ReadMeABook Seite';

  @override
  String get navHoldAdd => 'Hinzufügen';

  @override
  String get navHoldMoveLeft => 'Nach links verschieben';

  @override
  String get navHoldMoveRight => 'Nach rechts verschieben';

  @override
  String get navHoldRemoveFromMenu => 'Aus dem Menü entfernen';

  @override
  String get navHoldEditHint =>
      'Halte ein Element gedrückt, um es zu bewegen oder zu entfernen';

  @override
  String get navHoldResetMenu => 'Haltemenü-Elemente zurücksetzen';

  @override
  String get navHoldMenuReset => 'Menüeinträge zurücksetzen';

  @override
  String get bookStatsAction => 'Hörstatistik';

  @override
  String get bookStatsYou => 'Du';

  @override
  String get bookStatsEveryone => 'Jeder';

  @override
  String get bookStatsListened => 'Gehörte Zeit';

  @override
  String get bookStatsSessions => 'Sitzungen';

  @override
  String get bookStatsFirst => 'Zuerst gehört';

  @override
  String get bookStatsLast => 'Zuletzt gehört';

  @override
  String get bookStatsListeners => 'Nutzer die es angefangen haben';

  @override
  String get bookStatsFinishedCount => 'Nutzer die es beendet haben';

  @override
  String get bookStatsTotalTime => 'Gehörte Zeit aller Nutzer';

  @override
  String get bookStatsNobody => 'Noch niemand hat es gehört';

  @override
  String get bookStatsScanning =>
      'Durchsuche die Sitzungen, das könnte etwas dauern...';

  @override
  String bookStatsScanningCount(int done, int total) {
    return 'Durchsuchen der Sitzungen abgeschlossen, $done von $total Benutzer...';
  }

  @override
  String bookStatsLastChecked(String when) {
    return 'Überprüft $when';
  }

  @override
  String get activityYourReading => 'Dein Leseverlauf';

  @override
  String get activityYourListening => 'Dein Hörverlauf';

  @override
  String activityLastRead(String when) {
    return 'Zuletzt gelesen $when';
  }

  @override
  String activityLastListened(String when) {
    return 'Zuletzt gehört $when';
  }

  @override
  String get activityNotStarted => 'Nicht begonnen';

  @override
  String get activityNoReading => 'Noch keine Lesesitzungen';

  @override
  String get activityTime => 'Zeit';

  @override
  String get activityAverage => 'Durchschnitt';

  @override
  String get activityProgress => 'Fortschritt';

  @override
  String activityReached(String percent) {
    return '$percent erreicht';
  }

  @override
  String get readingLogTitle => 'Leseprotokoll';

  @override
  String get readingLogTotalTime => 'Gesamtzeit';

  @override
  String get readingLogAverageSession => 'Durchschnittliche Sitzung';

  @override
  String get readingLogActiveDays => 'Aktive Tage';

  @override
  String readingLogActiveDaysOf(int active, int total) {
    return '$active von $total';
  }

  @override
  String get readingLogPace => 'Geschwindigkeit';

  @override
  String readingLogPacePerHour(String percent) {
    return '$percent%/Std';
  }

  @override
  String get readingLogLastRead => 'Zuletzt gelesen';

  @override
  String get readingLogStarted => 'Begonnen';

  @override
  String get readingLogFinished => 'Beendet';

  @override
  String get readingLogNotSet => 'Nicht festgelegt';

  @override
  String readingLogLeftMinutes(int m) {
    return 'Ungefähr ${m}min zum Ende';
  }

  @override
  String readingLogLeftHours(int h) {
    return 'Ungefähr ${h}Std zum Ende';
  }

  @override
  String readingLogLeftHoursMinutes(int h, int m) {
    return 'Ungefähr ${h}Std ${m}min zum Ende';
  }

  @override
  String get readingLogLeftMax => 'Über 99Std bis zum Ende';

  @override
  String readingLogUpOnLastWeek(int percent) {
    return 'Ein Anstieg um $percent% gegenüber der Vorwoche';
  }

  @override
  String readingLogDownOnLastWeek(int percent) {
    return '$percent% Rückgang gegenüber der Vorwoche';
  }

  @override
  String get readingLogNewThisWeek => 'Neu in dieser Woche';

  @override
  String get readingLogSameAsLastWeek => 'Genauso wie in der Woche davor';

  @override
  String get readingLogQuietTwoWeeks => 'Nichts in den letzten zwei Wochen';

  @override
  String get readingLogWhereYouRead => 'Wo du es gelesen hast';

  @override
  String get readingLogSourceIos => 'iOS App';

  @override
  String get readingLogSourceAndroid => 'Android App';

  @override
  String get readingLogChartTitle => 'Fortschritt im Zeitverlauf';

  @override
  String get readingLogChartPosition => 'Position erreicht';

  @override
  String get readingLogChartMinutes => 'Minuten';

  @override
  String get readingLogRecords => 'Aufzeichnungen';

  @override
  String get readingLogLongestSession => 'Längste Serie';

  @override
  String get readingLogBestDay => 'Bester Tag';

  @override
  String get readingLogLongestStreak => 'Längste Serie';

  @override
  String readingLogStreakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Tage',
      one: '1 Tag',
    );
    return '$_temp0';
  }

  @override
  String get readingLogJumpedBack => 'Zurückgesprungen';

  @override
  String readingLogJumpedBackTimes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Mal',
      one: '1 Mal',
    );
    return '$_temp0';
  }

  @override
  String get readingLogFirstOpened => 'Zum ersten Mal geöffnet';

  @override
  String get readingLogAttempts => 'Versuche';

  @override
  String readingLogAttempt(int index) {
    return 'Versuch $index';
  }

  @override
  String readingLogAttemptBegan(int index) {
    return '$index Versuche gestartet';
  }

  @override
  String get readingLogOutcomeCompleted => 'Abgeschlossen';

  @override
  String get readingLogOutcomeSkimmed => 'Überflogen';

  @override
  String get readingLogOutcomeAbandoned => 'Anweisungen';

  @override
  String get readingLogOutcomeInProgress => 'Angefangen';

  @override
  String readingLogSpanRange(String from, String to) {
    return '$from bis $to';
  }

  @override
  String readingLogSpanSince(String from) {
    return 'Seit $from';
  }

  @override
  String readingLogSpanEnded(String to) {
    return '$to beendet';
  }

  @override
  String get readingLogSpanUnknown => 'Keine Daten erfasst';

  @override
  String readingLogSessionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Sitzungen',
      one: '1 Sitzung',
    );
    return '$_temp0';
  }

  @override
  String readingLogShowing(int shown, int total) {
    return '$shown von $total';
  }

  @override
  String readingLogGapDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Tage ohne Lesen',
      one: '1 Tag ohne Lesen',
    );
    return '$_temp0';
  }

  @override
  String get readingLogEmpty => 'Noch keine Sitzungen aufgezeichnet';

  @override
  String get readingLogEmptyHint =>
      'Hier erscheinen Sitzungen, während du liest oder hörst – von jeder App oder jedem Gerät aus, das mit BookOrbit synchronisiert ist.';

  @override
  String get readingLogNoMatches => 'Keine Sitzungen in diesem Bereich';

  @override
  String get readingLogAllTime => 'Gesamter Zeitraum';

  @override
  String get readingLogLast30 => 'Letzten 30 Tage';

  @override
  String get readingLogLast90 => 'Letzten 90 Tage';

  @override
  String get readingLogThisYear => 'Dieses Jahr';

  @override
  String get readingLogAllFormats => 'Alle Formate';

  @override
  String get readingLogSortBy => 'Sortieren nach';

  @override
  String get readingLogSortDay => 'Tag';

  @override
  String get readingLogSortLength => 'Länge';

  @override
  String get readingLogSortChange => 'Ändern';

  @override
  String get readingLogSortReached => 'Erreicht';

  @override
  String get readingLogNewestFirst => 'Neueste zuerst';

  @override
  String get readingLogOldestFirst => 'Älteste zuerst';

  @override
  String get readingLogMostFirst => 'Die meisten zuerst';

  @override
  String get readingLogLeastFirst => 'Das Geringste zuerst';

  @override
  String get readingLogDeleteTitle => 'Diese Sitzung löschen?';

  @override
  String get readingLogDeleteBody =>
      'Es basiert auf dem Leseprotokoll des Buches sowie deinen Statistiken auf BookOrbit.';

  @override
  String get readingLogDeleteFailed => 'Sitzung konnte nicht gelöscht werden';

  @override
  String get readingLogLoadFailed =>
      'Leseprotokoll konnte nicht geladen werden';

  @override
  String get navHoldServerScan => 'Server Scan';

  @override
  String get navHoldScanAll => 'Alle Bibliotheken scannen';

  @override
  String navHoldScanLibrary(String name) {
    return 'Scanne $name';
  }

  @override
  String get navHoldScanStarted => 'Scan gestartet';

  @override
  String get navHoldScanFailed => 'Kann Scan nicht starten';

  @override
  String get navHoldAdminLogs => 'Server Logs';

  @override
  String navHoldAdminPage(String page) {
    return 'Admin: $page';
  }

  @override
  String get navHoldNothingPlaying => 'Noch nichts zum Abspielen';

  @override
  String get navHoldReadBook => 'Aktuelles Buch lesen';

  @override
  String get navHoldBookDetails => 'Aktuelle Buchdetails';

  @override
  String get syncSourceTitle =>
      'Welche Kopie soll die Synchronisierung behalten?';

  @override
  String get syncSourceBody =>
      'Dieses Backup hat die Synchronisierung von Einstellungen aktiviert. Möchtest du den letzten Synchronisierungsstand vom Server verwenden oder soll dieses Backup als maßgebliche Quelle dienen? Wenn du dich für das Backup entscheidest, wird die auf dem Server gespeicherte Kopie für alle deine synchronisierten Geräte ersetzt.';

  @override
  String get syncSourceUseServer => 'Letzte Synchronisation des Servers';

  @override
  String get syncSourceUseBackup => 'Diese Sicherung';

  @override
  String get syncSettingsWhatTravels =>
      'Deine Einstellungen, buchspezifische Lesegeschwindigkeiten, das Layout der Startseite, die Reihenfolge beim Herunterladen von Inhalten, Notizen sowie E-Book-Markierungen werden synchronisiert. Anmeldedaten, Download-Ordner, Einstellungen für automatische Downloads, das Erscheinungsbild der Leseansicht sowie alle Daten, die noch nicht an den Server übertragen wurden, verbleiben auf diesem Gerät.';

  @override
  String get syncSettingsDownloadWarnTitle =>
      'Einstellungen dieses Geräts ersetzen?';

  @override
  String get syncSettingsDownloadWarnBody =>
      'Die synchronisierte Kopie überschreibt die Einstellungen auf diesem Gerät.';

  @override
  String get syncSettingsDownloadWarnConfirm => 'Ersetzen';

  @override
  String get readerCopied => 'In Zwischenablage kopiert';

  @override
  String get dictionaryNotFound =>
      'Für dieses Wort wurde keine Definition gefunden.';

  @override
  String get dictionaryError =>
      'Das Wörterbuch konnte nicht erreicht werden. Überprüfe deine Verbindung.';

  @override
  String get dictionaryRetry => 'Erneut versuchen';

  @override
  String get dictionarySearchWeb => 'Internet durchsuchen';

  @override
  String get readerTooltipCopy => 'Kopieren';

  @override
  String get readerTooltipSearch => 'Suchen';

  @override
  String get readerTooltipDefine => 'Definieren';

  @override
  String get readerTooltipTranslate => 'Übersetzen';

  @override
  String get readerSearchHint => 'Dieses Buch durchsuchen…';

  @override
  String readerSearchMatches(int count, String query) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Treffer für \"$query\"',
      one: '$count Treffer für \"$query\"',
    );
    return '$_temp0';
  }

  @override
  String get readerSearchEmpty =>
      'Gib ein Wort oder Phrase ein und tippe auf Suche.';

  @override
  String readerSearchNoResults(String query) {
    return 'Keine Treffer für \"$query\".';
  }

  @override
  String get transcriptionTitle => 'Transkription';

  @override
  String get transcriptionAdvancedSubtitle =>
      'Zum Übertragen von Lesezeichen und zum Wiederfinden der Stelle beim Wechsel zwischen Hörbuch und E-Book';

  @override
  String get transcriptionEnable => 'Transkription aktivieren';

  @override
  String get transcriptionEnableSubtitle =>
      'Fügt „Zu Lesezeichen transkribieren“, „Position im E-Book suchen“ für den Player und „Im Hörbuch suchen“ für den Reader hinzu';

  @override
  String get transcriptionDisclaimer =>
      'Läuft vollständig auf Ihrem Gerät; es werden keinerlei Daten übertragen. Während des Vorgangs werden zusätzliche Akkuleistung und Rechenkapazität beansprucht, und es können ausschließlich heruntergeladene Bücher transkribiert werden.';

  @override
  String get transcriptionNeedModelHint =>
      'Lade unten ein Modell herunter, um mit der Transkription zu beginnen.';

  @override
  String get transcriptionModelSection => 'Modelle';

  @override
  String get transcriptionModelTiny => 'Sehr klein';

  @override
  String get transcriptionModelTinyDesc =>
      'Schnell, weniger genau. Etwa 31 MB.';

  @override
  String get transcriptionModelBase => 'Standard';

  @override
  String get transcriptionModelBaseDesc => 'Ein guter Mittelweg. Etwa 57 MB.';

  @override
  String get transcriptionModelSmall => 'Klein';

  @override
  String get transcriptionModelSmallDesc =>
      'Langsamer, aber am genauesten – am besten auf einem High-End-Smartphone. Etwa 182 MB.';

  @override
  String get transcriptionAutoHint =>
      'Wenn mehr als eine Version heruntergeladen wurde, wählt der jeweilige Auftrag die passende aus. Bei Büchern, für die ein E-Book vorliegt, wird die schnellste Variante verwendet, da der exakte Wortlaut ohnehin aus dem E-Book stammt. Bei Büchern ohne E-Book wird die präziseste Variante gewählt – mit Ausnahme von „Read-Along“-Inhalten; diese bleiben unterhalb der Stufe Klein, damit sie mit der Erzählung Schritt halten können.';

  @override
  String get transcriptionDownload => 'Download';

  @override
  String get transcriptionDownloadFailed =>
      'Download fehlgeschlagen — überprüfe deine Verbindung und versuche es erneut.';

  @override
  String get transcribe => 'Transkribieren';

  @override
  String get transcribing => 'Transkribieren...';

  @override
  String get transcriptionResultTitle => 'Transkript';

  @override
  String get transcriptionSaveToNote => 'In Notiz speichern';

  @override
  String get transcriptionSavedToNote => 'In Lesezeichen gespeichert';

  @override
  String get transcriptionDisabledHint =>
      'Aktiviere die Lesezeichen-Transkription in den Einstellungen unter „Erweitert“.';

  @override
  String get transcriptionNoModelDownloaded =>
      'Lade zunächst in den Einstellungen ein Transkriptionsmodell herunter.';

  @override
  String get transcriptionNotDownloadedBook =>
      'Lade dieses Buch herunter oder stelle eine Verbindung zum Server her, um es zu transkribieren.';

  @override
  String get transcriptionNoMetadataMsg =>
      'Can\'t locate this spot in the download. Try re-downloading the book.';

  @override
  String get transcriptionBusyMsg =>
      'Already transcribing something. Give it a moment.';

  @override
  String get transcriptionEmptyMsg =>
      'An dieser Stelle wurde keine Rede gefunden.';

  @override
  String get transcriptionFailedMsg =>
      'Diese Stelle konnte nicht transkribiert werden. Bitte versuche es erneut.';

  @override
  String get transcriptionPlaySnippet => 'Anhören';

  @override
  String get transcriptionPauseSnippet => 'Pausieren';

  @override
  String get transcriptionIntroBody =>
      'This listens to the chosen amount of audio, starting just before the bookmark, and turns it into text on your device. Longer clips take longer, and transcription isn\'t 100% accurate. The text is saved into the bookmark\'s note when it\'s done, ready to fix up or share.';

  @override
  String get transcriptionUseEbookText =>
      'Use the ebook\'s exact text when it can be matched';

  @override
  String get lyricsMode => 'Live transcript';

  @override
  String get lyricsListeningAhead => 'Listening ahead...';

  @override
  String get lyricsDisplaySection => 'Live transcript';

  @override
  String get lyricsFontSize => 'Line size';

  @override
  String get lyricsMaxLines => 'Lines shown';

  @override
  String get lyricsFullCover => 'Use the whole cover';

  @override
  String get lyricsFullCoverHint =>
      'Shows the transcript in place of the artwork while it runs, fitting as many lines as there is room for.';

  @override
  String get lyricsBatteryInfo =>
      'Live transcript and read along use extra battery and processing while they run. On phones with slower processors, lines can take longer to appear.';

  @override
  String get lyricsClearCache => 'Clear transcript cache';

  @override
  String lyricsClearCacheHint(String size) {
    return '$size of saved transcript lines. Cleared books and episodes are transcribed again as you listen.';
  }

  @override
  String get lyricsClearCacheConfirm =>
      'Delete the saved transcripts for every book and episode? They rebuild automatically as you listen.';

  @override
  String get lyricsCacheCleared => 'Transcript cache cleared';

  @override
  String get lyricsIntroBody =>
      'This listens a little ahead of the narration and shows each line as it is spoken, transcribed on your phone - nothing leaves the device. After turning it on, hold off on pressing play for a few seconds while it gets ahead. The transcript appears once its head start is ready, and starting paused gives it the smoothest run. It uses extra battery and processing while it runs.';

  @override
  String lyricsBuildingLead(String percent) {
    return 'Getting ahead of the narration... $percent';
  }

  @override
  String lyricsCantKeepUp(String speed) {
    return 'Can\'t transcribe as fast as you\'re listening at $speed';
  }

  @override
  String get lyricsTurnOn => 'Turn on';

  @override
  String get readAlong => 'Read along';

  @override
  String get readAlongNeedsPlaying => 'Play this book\'s audiobook first';

  @override
  String get narrationListen => 'Listen';

  @override
  String get narrationPlayFromHere => 'Play from here';

  @override
  String get narrationPreparing => 'Getting the narration ready';

  @override
  String get narrationNone => 'This ebook has no narration to play';

  @override
  String get narrationDownloadTitle => 'Download to listen';

  @override
  String get narrationDownloadBody =>
      'This book is an EPUB3 that reads itself aloud. Audiobookshelf can\'t stream its narration, so the audio needs to be downloaded before it plays.';

  @override
  String get narrationDownloadStarted =>
      'Downloading the narration. Tap Absorb when it finishes.';

  @override
  String get narrationTextBody =>
      'This book\'s EPUB has its own words for every moment of the audio, so the text is copied straight from the book. Pick how much to add to the bookmark\'s note.';

  @override
  String get narrationTextLoading => 'Getting the words from the book';

  @override
  String get downloadToAbsorb => 'Download to Absorb';

  @override
  String get narrationUpNextTitle => 'Download what\'s up next';

  @override
  String narrationUpNextBody(String title) {
    return '$title is next in your queue. It\'s an EPUB3 that reads itself aloud, so it needs to be downloaded before it can play.';
  }

  @override
  String narrationQueueStopped(String title) {
    return 'Stopped before $title. Download it to keep going.';
  }

  @override
  String get transcriptionNeedsDownload =>
      'This needs the audio on your phone. Download it now?';

  @override
  String get transcriptionDownloadStarted =>
      'Downloading. Turn this on again when it finishes';

  @override
  String get readAlongFollow => 'Read along follows';

  @override
  String get syncReadingListening => 'Keep reading and listening in sync';

  @override
  String get syncReadingListeningHint =>
      'For books with an audiobook and an ebook. When you stop listening, the ebook moves to where you stopped. When you leave the reader, the audiobook moves to your page. Only moves forward.';

  @override
  String get syncEbookMoved => 'Ebook moved to where you stopped listening';

  @override
  String get syncAudioMoved => 'Audiobook moved to where you stopped reading';

  @override
  String get syncAudioOffer => 'Tap to jump to where you stopped reading';

  @override
  String get syncFindingAudio => 'Finding your page in the audiobook';

  @override
  String get syncFindingEbook => 'Finding your spot in the ebook';

  @override
  String get syncFailed => 'Couldn\'t sync your place';

  @override
  String get syncAlreadyTogether => 'Already in sync';

  @override
  String get syncPosition => 'Sync position';

  @override
  String get readAlongFollowHint =>
      'Word timing is worked out between the transcript\'s timestamps, so it can drift slightly inside a sentence.';

  @override
  String get readAlongFollowWord => 'Word';

  @override
  String get readAlongFollowSentence => 'Sentence';

  @override
  String get readAlongColor => 'Read along color';

  @override
  String get readAlongLost => 'Can\'t find the narration on the page';

  @override
  String get readAlongBackToNarration => 'Back to narration';

  @override
  String get findInEbook => 'Im eBook suchen';

  @override
  String get findInEbookSearching => 'Suche nach dieser Stelle im eBook...';

  @override
  String get findInEbookNotFound =>
      'Konnte diese Stelle im eBook nicht finden.';

  @override
  String get findInEbookNeedsEpub => 'Find in ebook needs an EPUB ebook.';

  @override
  String get findInEbookNoEbook => 'Dieses Buch hat kein eBook.';

  @override
  String get findInAudiobook => 'Im Hörbuch finden';

  @override
  String get findInAudiobookSearching =>
      'Suche nach dieser Stelle im Hörbuch...';

  @override
  String get findInAudiobookStillSearching =>
      'Still searching the audio for this spot...';

  @override
  String get findInAudiobookSearchingLong =>
      'Long chapter, still searching. This can take a minute or two...';

  @override
  String get findInAudiobookNotFound =>
      'Konnte diese Stelle nicht im Hörbuch finden.';

  @override
  String get transcriptionWhisperInfo =>
      'Transkriptionen werden von Whisper erstellt. Einer Open-Source Spracherkennung. Alles lokal auf diesem Gerät.';

  @override
  String get transcriptionWhisperLearnMore => 'Mehr über Whisper erfahren';

  @override
  String get findInAudiobookIntroBody =>
      'This listens to the audiobook near where you\'re reading and matches it to this passage, all on your device. It can take up to a minute. If the spot can\'t be matched confidently, nothing moves.';

  @override
  String get findInAudiobookAfterLabel => 'When the spot is found';

  @override
  String get findInAudiobookStay => 'Weiterlesen';

  @override
  String get findInAudiobookGoPlayer => 'Im Player öffnen';

  @override
  String get findInAudiobookPlaying => 'Diese Passage im Hörbuch abspielen';

  @override
  String get catchUpAudioAhead =>
      'The audiobook is further along. Tap to go there.';

  @override
  String get catchUpPageAhead =>
      'This page is ahead of the audiobook. Tap to move the audiobook here.';

  @override
  String get readerShortcutButton => 'Shortcut button';

  @override
  String get keepScreenOn => 'Keep screen on';

  @override
  String get keepScreenOnActive => 'Screen stays on';

  @override
  String get keepScreenOnUntilClosed =>
      'Screen stays on until you close the app';

  @override
  String get keepScreenOnOff => 'Screen can turn off again';

  @override
  String get keepScreenOnOffUntilRestart =>
      'Off until the app restarts. The Settings switch stays on';

  @override
  String get keepScreenOnPlayer => 'Bildschirm im Player aktiviert lassen';

  @override
  String get keepScreenOnPlayerSubtitle =>
      'Bildschirm im geöffneten Player nicht ausschalten';

  @override
  String get keepScreenOnCarMode =>
      'Bildschirm im Android-Auto Modus aktiviert lassen';

  @override
  String get keepScreenOnCarModeSubtitle =>
      'Bildschirm während aktiviertem Android-Auto Modus nicht ausschalten';

  @override
  String get loginServerType => 'Server type';

  @override
  String get authBookOrbitDefaultPassword =>
      'This account still has its default password. Change it in BookOrbit, then sign in again.';

  @override
  String get authBookOrbitPasswordOff =>
      'Password sign-in is turned off on this server. Sign in with a magic link or single sign-on.';

  @override
  String get authServerIsBookOrbit =>
      'This is a BookOrbit server. Choose BookOrbit above the server address.';

  @override
  String get authServerIsAudiobookshelf =>
      'This is an Audiobookshelf server. Choose Audiobookshelf above the server address.';

  @override
  String get castNotAvailableBookOrbit =>
      'Casting is not available with BookOrbit servers';

  @override
  String get loginMagicLink => 'Magic link';

  @override
  String get loginMagicLinkDescription =>
      'Sign in with a BookOrbit magic link, or paste a password link to set your password.';

  @override
  String get collectionPublicTitle => 'Public';

  @override
  String get collectionPublicSubtitle =>
      'Everyone on this server can see this collection';

  @override
  String loginSignInWithProvider(String provider) {
    return 'Sign in with $provider';
  }

  @override
  String get loginSignInWithSso => 'Sign in with SSO';

  @override
  String get loginChooseSsoProvider => 'Choose how to sign in';

  @override
  String get loginRedirectUriBookOrbit =>
      'Redirect URI: bookorbit://oauth2-callback';

  @override
  String get readStatusTitle => 'Reading status';

  @override
  String get readStatusHint =>
      'Listening to or reading the book can change this again.';

  @override
  String get readStatusUnread => 'Unread';

  @override
  String get readStatusWantToRead => 'Want to read';

  @override
  String get readStatusReading => 'Reading';

  @override
  String get readStatusOnHold => 'On hold';

  @override
  String get readStatusRereading => 'Rereading';

  @override
  String get readStatusRead => 'Read';

  @override
  String get readStatusSkimmed => 'Skimmed';

  @override
  String get readStatusAbandoned => 'Abandoned';

  @override
  String get personalNoteTitle => 'Your note';

  @override
  String get personalNoteAdd => 'Add a private note';

  @override
  String get personalNoteHint => 'Only you can see this note.';

  @override
  String get moreLikeThis => 'More like this';

  @override
  String get coverSlotAudiobook => 'Audiobook cover';

  @override
  String get coverSlotBook => 'Book cover';

  @override
  String get cardButtonFill => 'Button background';

  @override
  String get cardButtonFillSubtitle =>
      'How the buttons on the player card are filled';

  @override
  String get cardButtonFillClear => 'Clear';

  @override
  String get cardButtonFillSubtle => 'Subtle';

  @override
  String get cardButtonFillSolid => 'Solid';

  @override
  String get loginBookOrbitPreview =>
      'BookOrbit support is new. Playback, downloads and browsing work, but some screens may still look or act like Audiobookshelf. Follow the progress on GitHub, and let us know if something seems off.';

  @override
  String get signedOutTapToSignIn => 'Signed out. Tap to sign in again.';

  @override
  String get authSignedOutKeepListening =>
      'You\'ve been signed out. Downloads still play. Tap the red cloud to sign in again.';

  @override
  String signedOutSyncNote(String username, String server) {
    return 'What you listen to while signed out is kept on this phone and syncs when you sign back in as $username on $server. Any way of signing in to that account works.';
  }

  @override
  String get comicReadingDirection => 'Reading direction';

  @override
  String comicPageNumber(int page) {
    return 'Page $page';
  }

  @override
  String get comicBookmarkRemoveFailed =>
      'Couldn\'t remove the bookmark from the server. Try again when you\'re online.';

  @override
  String get comicLeftToRight => 'Left to right';

  @override
  String get comicRightToLeft => 'Right to left (manga)';

  @override
  String get comicNeedsConnection =>
      'This comic opens page by page from your server, so it needs a connection.';

  @override
  String get comicNoPages => 'No pages found in this comic.';

  @override
  String get boAdminTitle => 'Server admin';

  @override
  String get boAdminSubtitle => 'Users and libraries on this BookOrbit server';

  @override
  String get boAdminUsers => 'Users';

  @override
  String get boAdminLibraries => 'Libraries';

  @override
  String boAdminUserCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count people',
      one: '1 person',
    );
    return '$_temp0';
  }

  @override
  String boAdminLibraryCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count libraries',
      one: '1 library',
    );
    return '$_temp0';
  }

  @override
  String get boAdminSaved => 'Saved';

  @override
  String get boAdminFailed => 'That didn\'t work. Try again.';

  @override
  String get boAdminOffline => 'Couldn\'t reach the server.';

  @override
  String get boUsersSearch => 'Search users';

  @override
  String get boUsersNone => 'No users here';

  @override
  String get boUsersFilterAll => 'All';

  @override
  String get boUsersFilterAdmins => 'Admins';

  @override
  String get boUsersFilterActive => 'Active';

  @override
  String get boUsersFilterInactive => 'Inactive';

  @override
  String get boUsersFilterAttention => 'Needs attention';

  @override
  String get boUserBadgeAdmin => 'Admin';

  @override
  String get boUserBadgeInactive => 'Inactive';

  @override
  String get boUserBadgeLocked => 'Locked';

  @override
  String get boUserBadgeNoPassword => 'No password yet';

  @override
  String boUserLastActive(String date) {
    return 'Last active $date';
  }

  @override
  String get boUserNeverSignedIn => 'Never signed in';

  @override
  String get boUserNew => 'New user';

  @override
  String get boUserCreate => 'Create';

  @override
  String get boUserUsername => 'Username';

  @override
  String get boUserUsernameHint =>
      'At least 3 characters. It cannot be changed later.';

  @override
  String get boUserName => 'Name';

  @override
  String get boUserEmail => 'Email';

  @override
  String get boUserEmailInvalid => 'Enter a valid email address';

  @override
  String get boUserActive => 'Active';

  @override
  String get boUserActiveSubtitle => 'Inactive users can\'t sign in';

  @override
  String get boUserAdmin => 'Administrator';

  @override
  String get boUserAdminSubtitle => 'Full access to everything on the server';

  @override
  String get boUserAdminHasAll =>
      'Administrators have every permission and see every library.';

  @override
  String get boUserPermissions => 'Permissions';

  @override
  String get boUserPresetNone => 'None';

  @override
  String get boUserPresetStandard => 'Standard';

  @override
  String get boUserPresetEverything => 'Everything';

  @override
  String get boUserLibraries => 'Libraries';

  @override
  String get boUserLibrariesHint => 'The libraries this person can see.';

  @override
  String get boUserPasswordLink => 'Send password link';

  @override
  String get boUserPasswordLinkSubtitle =>
      'A link to set a new password, valid for 15 minutes';

  @override
  String get boUserExternal =>
      'Signs in through single sign-on, so the password is managed there.';

  @override
  String get boUserUnlock => 'Unlock account';

  @override
  String get boUserUnlocked => 'Account unlocked';

  @override
  String get boUserDelete => 'Delete user';

  @override
  String boUserDeleteTitle(String name) {
    return 'Delete $name?';
  }

  @override
  String get boUserDeleteBody =>
      'Their account and everything they have on this server are removed. This cannot be undone.';

  @override
  String get boUserDeleted => 'User deleted';

  @override
  String get boUserLinkTitle => 'Password link';

  @override
  String boUserLinkBody(String name) {
    return 'Share this link with $name. It lets them set a password and works for 15 minutes.';
  }

  @override
  String get boPasswordRules =>
      'At least 8 characters, with an uppercase letter, a lowercase letter and a number.';

  @override
  String get boSetPasswordTitle => 'Set your password';

  @override
  String get boSetPasswordSubmit => 'Set password and sign in';

  @override
  String boSetPasswordLinkBody(String username, String server) {
    return 'Choose a password for $username on $server.';
  }

  @override
  String boSetPasswordLinkBodyNoName(String server) {
    return 'Choose a password for your account on $server.';
  }

  @override
  String get boSetPasswordStartingBody =>
      'This account still has the password it was created with. Choose a new one to finish signing in.';

  @override
  String get boSetPasswordTrust =>
      'Only continue if you trust who sent this link.';

  @override
  String get boPasswordLinkExpired =>
      'This link has expired or was already used. Ask your server admin for a new one.';

  @override
  String boPasswordSetSignInFailed(String error) {
    return 'Your password is set, but signing in failed: $error';
  }

  @override
  String get boChangePasswordSubtitle => 'Update your BookOrbit password';

  @override
  String get boPasswordChangeEffect =>
      'Changing your password signs out your other BookOrbit sessions. This device stays signed in.';

  @override
  String get boPasswordChanged =>
      'Password changed. Other signed-in devices were signed out.';

  @override
  String boPasswordShareDescription(String username) {
    return 'Send this link or have $username scan the QR code to choose a password and sign in to Absorb. It works for 15 minutes.';
  }

  @override
  String boPasswordShareWarning(String username) {
    return 'Anyone with this link can choose the password for $username until it is used or expires.';
  }

  @override
  String get setupLinkCopyWebLink => 'Copy web link';

  @override
  String get boUserLinkCopy => 'Copy link';

  @override
  String get boUserLinkCopied => 'Link copied';

  @override
  String get boUserLinkShare => 'Share';

  @override
  String get boUserNoLink =>
      'The user was added, but the server sent no password link. Send one from their page.';

  @override
  String get boPermGroupLibrary => 'Library and books';

  @override
  String get boPermGroupRequests => 'Book requests';

  @override
  String get boPermGroupDevices => 'Devices';

  @override
  String get boPermGroupIntegrations => 'Reading integrations';

  @override
  String get boPermGroupDock => 'Book Dock';

  @override
  String get boPermGroupEmail => 'Email and notifications';

  @override
  String get boPermGroupAdmin => 'Administration';

  @override
  String get boPermLibraryDownload => 'Download books';

  @override
  String get boPermLibraryUpload => 'Upload books';

  @override
  String get boPermLibraryEditMetadata => 'Edit metadata';

  @override
  String get boPermLibraryDeleteBooks => 'Delete books';

  @override
  String get boPermBookRequestAccess => 'Request books';

  @override
  String get boPermBookRequestAutoApprove => 'Requests approved automatically';

  @override
  String get boPermBookRequestSelfFulfill =>
      'Download requested books directly';

  @override
  String get boPermManageBookRequests => 'Manage book requests';

  @override
  String get boPermKoboSync => 'Kobo sync';

  @override
  String get boPermKoreaderSync => 'KOReader sync';

  @override
  String get boPermOpdsAccess => 'OPDS access';

  @override
  String get boPermHardcoverSync => 'Hardcover sync';

  @override
  String get boPermReadwiseSync => 'Readwise sync';

  @override
  String get boPermStorygraphSync => 'StoryGraph sync';

  @override
  String get boPermBookDockAccess => 'Use the Book Dock';

  @override
  String get boPermManageBookDock => 'Manage the Book Dock';

  @override
  String get boPermEmailSend => 'Send books by email';

  @override
  String get boPermNotificationAccess => 'Notifications';

  @override
  String get boPermManageEmail => 'Manage email';

  @override
  String get boPermManageLibraries => 'Manage libraries';

  @override
  String get boPermManageMetadataConfig => 'Metadata settings';

  @override
  String get boPermManageIcons => 'Manage icons';

  @override
  String get boPermManageUsers => 'Manage users';

  @override
  String get boPermViewUserActivity => 'View user activity';

  @override
  String get boPermViewAuditLog => 'View the audit log';

  @override
  String get boPermManageAppSettings => 'App settings';

  @override
  String get boLibsNone => 'No libraries yet';

  @override
  String boLibBookCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count books',
      one: '1 book',
    );
    return '$_temp0';
  }

  @override
  String get boLibScanNow => 'Scan now';

  @override
  String get boLibScanStarted => 'Scan started';

  @override
  String get boLibScanning => 'Scanning';

  @override
  String boLibLastScan(String date, int added, int updated, int missing) {
    return 'Scanned $date: $added added, $updated updated, $missing missing';
  }

  @override
  String get boLibScanFailed => 'The last scan failed';

  @override
  String get boLibNeverScanned => 'Not scanned yet';

  @override
  String get boLibNew => 'New library';

  @override
  String get boLibName => 'Name';

  @override
  String get boLibNeedName => 'Give the library a name';

  @override
  String get boLibIcon => 'Icon';

  @override
  String get boLibFolders => 'Folders';

  @override
  String get boLibFoldersHint =>
      'Folders on the server where this library\'s books live.';

  @override
  String get boLibNeedFolder => 'Add at least one folder';

  @override
  String get boLibAddFolder => 'Add folder';

  @override
  String boLibFolderFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files',
      one: '1 file',
    );
    return '$_temp0';
  }

  @override
  String boLibFolderInUse(String library) {
    return 'Already in $library';
  }

  @override
  String get boLibFolderUnreadable => 'The server can\'t read this folder';

  @override
  String get boLibFolderRescan => 'Changing the folders rescans the library.';

  @override
  String get boLibOrganization => 'Books are stored as';

  @override
  String get boLibPerFolder => 'One book per folder';

  @override
  String get boLibPerFile => 'One book per file';

  @override
  String get boLibOrganizationFixed =>
      'This cannot be changed after the library is created.';

  @override
  String get boLibWatch => 'Watch for changes';

  @override
  String get boLibWatchSubtitle =>
      'Pick up new and changed files as they appear';

  @override
  String get boLibSchedule => 'Scheduled scan';

  @override
  String get boLibScheduleOff => 'Off';

  @override
  String get boLibScheduleDaily => 'Daily';

  @override
  String get boLibScheduleWeekly => 'Weekly';

  @override
  String boLibScheduleCustom(String cron) {
    return 'Custom ($cron)';
  }

  @override
  String get boLibScheduleHint => 'Runs at 3 AM server time.';

  @override
  String get boLibCovers => 'Cover shape';

  @override
  String get boLibCoverBook => 'Book (2:3)';

  @override
  String get boLibCoverSquare => 'Square (1:1)';

  @override
  String get boLibAccess => 'Who can see it';

  @override
  String get boLibAccessHint =>
      'Administrators see every library. Others need access here.';

  @override
  String get boLibAccessNone => 'Only administrators so far';

  @override
  String get boLibAccessAdd => 'Add person';

  @override
  String get boLibAccessEveryoneHas => 'Everyone already has access';

  @override
  String get boLibLevelViewer => 'Viewer';

  @override
  String get boLibLevelEditor => 'Editor';

  @override
  String get boLibLevelOwner => 'Owner';

  @override
  String get boLibAccessRemove => 'Remove access';

  @override
  String get boLibDelete => 'Delete library';

  @override
  String boLibDeleteTitle(String name) {
    return 'Delete $name?';
  }

  @override
  String get boLibDeleteBody =>
      'The library is removed from BookOrbit, with its books\' progress and highlights. The files on the server stay where they are.';

  @override
  String get boLibDeleted => 'Library deleted';

  @override
  String get boFolderPickTitle => 'Choose a folder';

  @override
  String get boFolderUseThis => 'Use this folder';

  @override
  String get boFolderEmpty => 'No folders inside';

  @override
  String get statsTotalTime => 'TOTAL TIME';

  @override
  String get statsTotalReadingTime => 'TOTAL READING TIME';

  @override
  String statsDaysOfTime(String days) {
    return 'That\'s $days days';
  }

  @override
  String statsHoursOfTime(String hours) {
    return 'That\'s $hours hours';
  }

  @override
  String get statsMediaAll => 'All';

  @override
  String get statsMediaListening => 'Listening';

  @override
  String get statsMediaReading => 'Reading';

  @override
  String statsZoneMismatch(String server, String phone) {
    return 'BookOrbit counts your days in $server, but this phone is set to $phone. Time late in the day can land on the wrong day.';
  }

  @override
  String statsZoneUse(String zone) {
    return 'Use $zone';
  }

  @override
  String statsZoneSaved(String zone) {
    return 'BookOrbit now uses $zone. Older days can take a few minutes to catch up.';
  }

  @override
  String get statsZoneFailed => 'Couldn\'t change the time zone on BookOrbit';

  @override
  String get statsTimeOfDay => 'Time of day';

  @override
  String statsBusiestAround(String time) {
    return 'Busiest around $time';
  }

  @override
  String get statsFinishedByMonth => 'Books finished by month';

  @override
  String statsFinishedLast12(int count) {
    return '$count in the last 12 months';
  }

  @override
  String get statsWhereTitle => 'Where you listen and read';

  @override
  String get statsLast12Months => 'Last 12 months';

  @override
  String get statsHabits => 'Habits';

  @override
  String get statsTypicalSession => 'Typical session';

  @override
  String get statsProgressPerSession => 'Progress per session';

  @override
  String get statsTimeToFinish => 'Time to finish';

  @override
  String statsDayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String get statsBooksStarted => 'Books started';

  @override
  String get statsBooksInProgress => 'In progress';

  @override
  String get statsAverageProgress => 'Average progress';

  @override
  String get statsTopBooks => 'Top books';

  @override
  String get statsYearRead => 'Read';

  @override
  String boNotificationsUnread(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count unread',
      one: '1 unread',
      zero: 'Nothing new',
    );
    return '$_temp0';
  }

  @override
  String get boNotificationsMarkAllRead => 'Mark all read';

  @override
  String get boNotificationsClearAll => 'Alle löschen';

  @override
  String get boNotificationsClearTitle => 'Alle Benachrichtigungen löschen?';

  @override
  String get boNotificationsClearBody =>
      'This removes every notification from your BookOrbit account.';

  @override
  String get boNotificationsEmpty => 'No notifications yet';

  @override
  String get boNotificationsLoadFailed => 'Couldn\'t load notifications';

  @override
  String get boNotificationsUpdateFailed =>
      'Couldn\'t update notifications on BookOrbit';

  @override
  String boNotificationsOccurrences(int count) {
    return '$count mal passiert';
  }

  @override
  String get boNotificationsSettings => 'Benachrichtigungseinstellungen';

  @override
  String get boNotificationsSettingsIntro =>
      'Wähle aus, welche Benachrichtigungen BookOrbit für dich behält.';

  @override
  String get boNotificationsProblemsHint =>
      'Problems only notifies you when something fails or needs attention.';

  @override
  String get boNotificationLevelOff => 'Aus';

  @override
  String get boNotificationLevelProblems => 'Probleme';

  @override
  String get boNotificationLevelAll => 'All';

  @override
  String get boNotificationsSaved => 'Notification settings saved';

  @override
  String get boNotificationsSaveFailed =>
      'Couldn\'t save notification settings';

  @override
  String get boNotificationGroupLibrary => 'Bibliothek';

  @override
  String get boNotificationGroupFiles => 'Dateien';

  @override
  String get boNotificationGroupIntegrations => 'Integrationen';

  @override
  String get boNotificationGroupPersonal => 'Personal';

  @override
  String get boNotifyScanning => 'Scannen der Bibliothek';

  @override
  String get boNotifyScanningDesc =>
      'Wenn ein Bibliotheksscan abgeschlossen ist, fehlschlägt oder fehlende Bücher findet.';

  @override
  String get boNotifyMetadata => 'Abrufen von Metadaten';

  @override
  String get boNotifyMetadataDesc =>
      'Wenn die Metadatensuche für deine Bücher abgeschlossen ist oder fehlschlägt.';

  @override
  String get boNotifyAuthorEnrichment => 'Autorendetails';

  @override
  String get boNotifyAuthorEnrichmentDesc =>
      'When author biographies and photos finish downloading.';

  @override
  String get boNotifyFileWriteBack => 'In Dateien speichern';

  @override
  String get boNotifyFileWriteBackDesc =>
      'When edited details are saved into the book files on disk.';

  @override
  String get boNotifyFileRename => 'File renaming';

  @override
  String get boNotifyFileRenameDesc =>
      'When a book file is renamed to match your naming pattern.';

  @override
  String get boNotifyBulkRename => 'Bulk renaming';

  @override
  String get boNotifyBulkRenameDesc =>
      'When renaming many books, or moving books between libraries, finishes or fails.';

  @override
  String get boNotifyMigration => 'Imports';

  @override
  String get boNotifyMigrationDesc =>
      'When an import from another library app finishes or fails.';

  @override
  String get boNotifyBookDock => 'Book Dock';

  @override
  String get boNotifyBookDockDesc =>
      'When Book Dock finishes adding books or runs into problems.';

  @override
  String get boNotifyBookRequests => 'Book requests';

  @override
  String get boNotifyBookRequestsDesc =>
      'When a book request is submitted or decided, or the book becomes available.';

  @override
  String get boNotifyEmail => 'Email delivery';

  @override
  String get boNotifyEmailDesc =>
      'When sending a book by email works or fails.';

  @override
  String get boNotifyAchievements => 'Achievements';

  @override
  String get boNotifyAchievementsDesc => 'When you unlock a new achievement.';

  @override
  String get achievementsTitle => 'Achievements';

  @override
  String achievementsEarnedSummary(int earned, int total) {
    return '$earned of $total earned';
  }

  @override
  String get achievementsFilterAll => 'All';

  @override
  String get achievementsFilterEarned => 'Earned';

  @override
  String get achievementsFilterInProgress => 'In progress';

  @override
  String get achievementsFilterLocked => 'Locked';

  @override
  String get achievementsCategoryReading => 'Reading';

  @override
  String get achievementsCategoryLibrary => 'Bibliothek';

  @override
  String get achievementsCategoryExploration => 'Exploration';

  @override
  String get achievementsCategoryDedication => 'Dedication';

  @override
  String get achievementsCategoryDevices => 'Geräte';

  @override
  String get achievementsRarityCommon => 'Common';

  @override
  String get achievementsRarityRare => 'Selten';

  @override
  String get achievementsRarityEpic => 'Episch';

  @override
  String get achievementsRarityLegendary => 'Legendär';

  @override
  String get achievementsLoadFailed => 'Erfolge konnten nicht geladen werden';

  @override
  String get achievementsNoneMatch => 'Keine Erfolge entsprechen diesem Filter';

  @override
  String get achievementsSecretName => 'Geheimer Erfolg';

  @override
  String get achievementsSecretHint => 'Lese weiter, um diesen aufzudecken.';

  @override
  String achievementsEarnedOn(String date) {
    return 'Verdient am: $date';
  }

  @override
  String achievementsWhileReading(String title) {
    return 'Beim Lesen von „$title“';
  }

  @override
  String achievementsTierOf(int earned, int total) {
    return 'Stufe $earned von $total';
  }

  @override
  String get achievementsTiers => 'Stufen';

  @override
  String get achievementsAllTiers => 'Jede verdiente Stufe';

  @override
  String achievementsProgress(String current, String threshold) {
    return '$current / $threshold';
  }

  @override
  String achievementsProgressBooks(String current, String threshold) {
    return '$current/$threshold Bücher';
  }

  @override
  String achievementsProgressPages(String current, String threshold) {
    return '$current / $threshold Seiten';
  }

  @override
  String achievementsProgressHours(String current, String threshold) {
    return '$current / $threshold Stunden';
  }

  @override
  String achievementsProgressAnnotations(String current, String threshold) {
    return '$current / $threshold Highlights und Notizen';
  }

  @override
  String achievementsProgressRatings(String current, String threshold) {
    return '$current / $threshold Bewertungen';
  }

  @override
  String achievementsProgressGenres(String current, String threshold) {
    return '$current / $threshold Genres';
  }

  @override
  String achievementsProgressLanguages(String current, String threshold) {
    return '$current / $threshold Sprachen';
  }

  @override
  String achievementsProgressDays(String current, String threshold) {
    return '$current / $threshold Tage';
  }

  @override
  String get achievementsHowToGetIt => 'Wie man es bekommt';

  @override
  String achievementsHintReadingPace(int count, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'You read $count hours in the last $days days.',
      one: 'You read 1 hour in the last $days days.',
    );
    return '$_temp0';
  }

  @override
  String achievementsHintEtaDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'About $count days at this pace.',
      one: 'About 1 day at this pace.',
    );
    return '$_temp0';
  }

  @override
  String achievementsHintEtaWeeks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'About $count weeks at this pace.',
      one: 'About 1 week at this pace.',
    );
    return '$_temp0';
  }

  @override
  String achievementsHintEtaMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'About $count months at this pace.',
      one: 'About 1 month at this pace.',
    );
    return '$_temp0';
  }

  @override
  String achievementsHintDecadeUnread(int count, String decade) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count books from the ${decade}s are waiting on your shelves.',
      one: '1 book from the ${decade}s is waiting on your shelves.',
    );
    return '$_temp0';
  }

  @override
  String achievementsHintCenturyUnread(int count, String century) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count books from the ${century}s are waiting on your shelves.',
      one: '1 book from the ${century}s is waiting on your shelves.',
    );
    return '$_temp0';
  }

  @override
  String achievementsHintStalled(String title, String percent, String date) {
    return '$title is $percent read and was started on $date.';
  }

  @override
  String achievementsHintStalledNoProgress(String title, String date) {
    return '$title was started on $date.';
  }

  @override
  String get achievementsHintUntitledBook => 'Ein Buch in Bearbeitung';

  @override
  String achievementsHintNearlyFinished(int count, String percent) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count books in progress are past $percent.',
      one: '1 book in progress is past $percent.',
    );
    return '$_temp0';
  }

  @override
  String achievementsHintUnrated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count books you finished have no rating yet.',
      one: '1 book you finished has no rating yet.',
    );
    return '$_temp0';
  }

  @override
  String achievementsHintShortBooks(int count, String pages) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count books under $pages pages are waiting on your shelves.',
      one: '1 book under $pages pages is waiting on your shelves.',
    );
    return '$_temp0';
  }

  @override
  String achievementsHintAlreadyStarted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count are already in progress.',
      one: '1 is already in progress.',
    );
    return '$_temp0';
  }

  @override
  String achievementsHintLongBooks(int count, String pages) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count books of $pages pages or more are waiting on your shelves.',
      one: '1 book of $pages pages or more is waiting on your shelves.',
    );
    return '$_temp0';
  }

  @override
  String achievementsHintOldBooks(int count, String year) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count books published before $year are waiting on your shelves.',
      one: '1 book published before $year is waiting on your shelves.',
    );
    return '$_temp0';
  }

  @override
  String achievementsHintAuthorUnread(String author, int finished, int count) {
    return '$author: $finished finished, $count more on your shelves.';
  }

  @override
  String achievementsHintLanguageUnread(int count, String language) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count books in $language are waiting on your shelves.',
      one: '1 book in $language is waiting on your shelves.',
    );
    return '$_temp0';
  }

  @override
  String achievementsHintMonthsRead(int count, String year) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'You have read in $count months of $year so far.',
      one: 'You have read in 1 month of $year so far.',
    );
    return '$_temp0';
  }

  @override
  String achievementsHintMonthsLeft(int count, String months) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$months are left.',
      one: '$months is left.',
    );
    return '$_temp0';
  }

  @override
  String achievementsHintNoLongBook(String pages) {
    return 'No book on your shelves has $pages pages or more yet.';
  }

  @override
  String achievementsHintNothingBefore(String year) {
    return 'Nothing on your shelves was published before $year.';
  }

  @override
  String achievementsHintTooFewDecades(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Your shelves span only $count decades so far.',
      one: 'Your shelves span only 1 decade so far.',
    );
    return '$_temp0';
  }

  @override
  String achievementsHintTooFewCenturies(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Your shelves span only $count centuries so far.',
      one: 'Your shelves span only 1 century so far.',
    );
    return '$_temp0';
  }

  @override
  String achievementsHintMissedMonth(String month, String year) {
    return 'You did not read in $month, so $year is out of reach. The count starts again in January.';
  }

  @override
  String get achievementsSwitch => 'Erfolge';

  @override
  String get achievementsSwitchSubtitle =>
      'Erfolge in BookOrbit tracken. Wenn du dies deaktivierst, werden sie hier und im Web ausgeblendet.';

  @override
  String get achievementsTurnedOn => 'Erfolge eingeschaltet';

  @override
  String get achievementsTurnedOff => 'Erfolge ausgeschaltet';

  @override
  String get achievementsSwitchFailed =>
      'Konnte die Erfolge auf BookOrbit nicht ändern';

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
  String get boNotifyReadAlong => 'Read alongs';

  @override
  String get boNotifyReadAlongDesc =>
      'When a read along you started is ready, needs a look, or fails.';

  @override
  String get readAlongCreate => 'Create read along';

  @override
  String get readAlongLoadFailed =>
      'Couldn\'t check whether a read along can be made for this book.';

  @override
  String get readAlongCheckAgain => 'Check again';

  @override
  String get readAlongWhyWorkerOffline =>
      'BookOrbit\'s read along worker is offline right now.';

  @override
  String get readAlongWhyWorkerOutdated =>
      'BookOrbit\'s read along worker needs an update to work with this server.';

  @override
  String get readAlongWhyFilesMissing =>
      'Restore this book\'s missing files to make a read along.';

  @override
  String get readAlongWhyNoEpub =>
      'Add a plain EPUB to this book to make a read along.';

  @override
  String get readAlongWhyNoEpubHasOne =>
      'This book already has a read along and no plain EPUB to make another from.';

  @override
  String get readAlongWhyTooManyTracks =>
      'This audiobook has more files than a read along can be made from.';

  @override
  String get readAlongWhyEpubNotAllowed =>
      'This library doesn\'t take EPUB files, so a read along can\'t be added.';

  @override
  String get readAlongWhyNotMounted =>
      'BookOrbit\'s read along worker can\'t reach this library\'s folder.';

  @override
  String get readAlongWhyRunning =>
      'A read along is already being made for this book.';

  @override
  String get readAlongWhyUnknown =>
      'A read along can\'t be made for this book right now.';

  @override
  String get readAlongSheetTitle => 'Create a read along';

  @override
  String get readAlongSheetIntro =>
      'BookOrbit matches the narration to the ebook text and adds an EPUB that highlights along with the audio.';

  @override
  String get readAlongEbook => 'Ebook';

  @override
  String get readAlongEbookHint =>
      'Pick the plain EPUB that matches the narration.';

  @override
  String get readAlongAudio => 'Audiobook';

  @override
  String readAlongTracks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tracks',
      one: '1 track',
    );
    return '$_temp0';
  }

  @override
  String readAlongExistingTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'This book already has $count read alongs',
      one: 'This book already has a read along',
    );
    return '$_temp0';
  }

  @override
  String readAlongReplace(String name) {
    return 'Replace $name';
  }

  @override
  String readAlongKeepBoth(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Keep all of them',
      one: 'Keep both',
    );
    return '$_temp0';
  }

  @override
  String get readAlongKeepHint =>
      'The new read along is added as another file.';

  @override
  String get readAlongReplaceHint =>
      'The old file is only replaced once the new one passes its checks, and reading spots carry over.';

  @override
  String get readAlongReplaceNotAllowed =>
      'Replacing a read along needs permission to delete books, so the new one is added as another file.';

  @override
  String get readAlongMadeByBookOrbit => 'Made by BookOrbit';

  @override
  String get readAlongImported => 'Imported';

  @override
  String get readAlongLanguage => 'Narration language';

  @override
  String get readAlongPickLanguage => 'Choose a language';

  @override
  String readAlongLanguageUnsupported(String language) {
    return 'The speech model doesn\'t know this book\'s language ($language).';
  }

  @override
  String get readAlongLanguageFromBook => 'From this book\'s details.';

  @override
  String get readAlongLanguageIsDefault => 'Your default language.';

  @override
  String get readAlongLanguageSaved => 'Saved as your default language.';

  @override
  String get readAlongSetDefault => 'Set as default';

  @override
  String get readAlongDefaultFailed => 'Couldn\'t save your default language.';

  @override
  String get readAlongHighlighting => 'Highlighting';

  @override
  String get readAlongSentence => 'Sentence';

  @override
  String get readAlongSentenceHint =>
      'Highlights one sentence at a time. Recommended.';

  @override
  String get readAlongWord => 'Word';

  @override
  String get readAlongWordHint =>
      'Highlights each word. Takes longer and makes a bigger file. Still experimental.';

  @override
  String readAlongEstimatedSize(String size) {
    return 'Estimated size: $size';
  }

  @override
  String get readAlongBackgroundNote =>
      'Runs on the server, so you can close this. Long audiobooks can take hours, and the first run for a language downloads its speech model.';

  @override
  String readAlongLowDisk(String needed, String free) {
    return 'Low disk space: this needs about $needed of working space on the worker, which has $free free.';
  }

  @override
  String get readAlongStart => 'Start';

  @override
  String get readAlongStartFailed =>
      'The read along couldn\'t be started. Try again.';

  @override
  String get readAlongStartInvalid =>
      'Some of the picked files are no longer on this book. Check them and try again.';

  @override
  String get readAlongStartOffline =>
      'BookOrbit\'s read along worker is offline. Try again later.';

  @override
  String get readAlongNotAllowed => 'You don\'t have permission to do that.';

  @override
  String get readAlongGone => 'This read along job is gone.';

  @override
  String get readAlongMovedOn =>
      'This job had already moved on. It now shows where it is.';

  @override
  String get readAlongActionFailed => 'That didn\'t go through. Try again.';

  @override
  String readAlongStartedBy(String name) {
    return 'Started by $name';
  }

  @override
  String get readAlongStartedByOther => 'Started by another user';

  @override
  String get readAlongWaiting => 'Waiting to start';

  @override
  String get readAlongNextInLine => 'Next in line';

  @override
  String readAlongJobsAhead(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jobs ahead',
      one: '1 job ahead',
    );
    return '$_temp0';
  }

  @override
  String get readAlongStopping => 'Stopping';

  @override
  String get readAlongStoppingHint =>
      'Finishing the current step, then it stops. Nothing will be added to this book.';

  @override
  String get readAlongStagePreparingAudio => 'Preparing the audio';

  @override
  String get readAlongStageDownloadingModel => 'Downloading the speech model';

  @override
  String get readAlongStageListening => 'Listening to the narration';

  @override
  String get readAlongStageMarkingUp => 'Marking up the ebook text';

  @override
  String get readAlongStageAligning => 'Matching the text to the narration';

  @override
  String get readAlongStageChecking => 'Checking the result';

  @override
  String get readAlongStagePublishing => 'Adding the read along to this book';

  @override
  String get readAlongStageWorking => 'Working';

  @override
  String readAlongFileOf(int current, int total) {
    return 'File $current of $total';
  }

  @override
  String readAlongTrackOf(int current, int total) {
    return 'Track $current of $total';
  }

  @override
  String readAlongChapterOf(int current, int total) {
    return 'Chapter $current of $total';
  }

  @override
  String readAlongStepOf(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get readAlongFirstRun => 'First run for this language';

  @override
  String get readAlongJustStarted => 'Just started';

  @override
  String readAlongRunningFor(String duration) {
    return 'Running for $duration';
  }

  @override
  String get readAlongStepAudio => 'Audio';

  @override
  String get readAlongStepSpeech => 'Speech';

  @override
  String get readAlongStepText => 'Text';

  @override
  String get readAlongStepAlign => 'Align';

  @override
  String get readAlongStepCheck => 'Check';

  @override
  String get readAlongStepAdd => 'Add';

  @override
  String get readAlongReviewTitle => 'Ready for review';

  @override
  String readAlongReviewMatched(String percent) {
    return '$percent of the text matched the narration. Check it before adding it to the book.';
  }

  @override
  String get readAlongReviewPlain => 'Check it before adding it to the book.';

  @override
  String get readAlongReviewWeb =>
      'To leave chapters out and match again, open this book in BookOrbit on the web.';

  @override
  String readAlongReviewExpires(String date) {
    return 'Thrown away on its own on $date unless you review it.';
  }

  @override
  String get readAlongAddAnyway => 'Add it anyway';

  @override
  String get readAlongDiscard => 'Discard';

  @override
  String get readAlongDiscardPrompt => 'Discard this read along?';

  @override
  String get readAlongKeepIt => 'Keep it';

  @override
  String get readAlongReady => 'Read along ready';

  @override
  String get readAlongReadyWarnings => 'Read along ready, with warnings';

  @override
  String get readAlongAdded => 'Added to this book as a new EPUB.';

  @override
  String get readAlongReplaced =>
      'Replaced the old read along. Reading spots carry over.';

  @override
  String readAlongMatchedSentences(String matched, String total) {
    return '$matched of $total sentences matched the narration';
  }

  @override
  String readAlongAudioUsed(String percent) {
    return '$percent of the audio used';
  }

  @override
  String readAlongOutside(String chapters) {
    return 'Not in the narration, so left without audio: $chapters.';
  }

  @override
  String readAlongOutsideMore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count more chapters',
      one: '1 more chapter',
    );
    return '$_temp0';
  }

  @override
  String get readAlongWarnUnaligned =>
      'One or more audio tracks couldn\'t be matched.';

  @override
  String get readAlongWarnUnmatched =>
      'A noticeable amount of the ebook text wasn\'t matched to the narration.';

  @override
  String get readAlongWarnInterpolated =>
      'Some text timing was estimated between confident matches.';

  @override
  String get readAlongWarnDropped =>
      'Some ebook text was left out of the highlighting.';

  @override
  String get readAlongFailed => 'Read along failed';

  @override
  String get readAlongCancelled => 'Read along cancelled';

  @override
  String get readAlongDiscarded => 'Read along thrown away';

  @override
  String get readAlongNothingAdded => 'Nothing was added to this book.';

  @override
  String get readAlongExpired =>
      'It wasn\'t reviewed within 14 days, so nothing was added to this book.';

  @override
  String readAlongRetryUntil(String date) {
    return 'Retry picks up from the last finished step until $date.';
  }

  @override
  String get readAlongStartOver => 'Start over';

  @override
  String get readAlongCancel => 'Cancel read along';

  @override
  String get readAlongCancelPrompt => 'Cancel this read along?';

  @override
  String get readAlongKeepRunning => 'Keep running';

  @override
  String get readAlongErrorWorkerOffline =>
      'BookOrbit couldn\'t reach its read along worker.';

  @override
  String get readAlongErrorWorkerCrashed =>
      'The read along worker stopped unexpectedly.';

  @override
  String get readAlongErrorSourceMissing => 'A picked file is no longer there.';

  @override
  String get readAlongErrorSourceChanged =>
      'A picked file changed after the job started.';

  @override
  String get readAlongErrorInvalidSource =>
      'The EPUB or audiobook couldn\'t be read.';

  @override
  String get readAlongErrorLanguage =>
      'The speech model doesn\'t know the picked language.';

  @override
  String get readAlongErrorStorage =>
      'There isn\'t enough free disk space on the worker to finish.';

  @override
  String get readAlongErrorAudio => 'The audiobook couldn\'t be prepared.';

  @override
  String get readAlongErrorModel => 'The speech model couldn\'t be downloaded.';

  @override
  String get readAlongErrorListening =>
      'Speech recognition failed while listening to the narration.';

  @override
  String get readAlongErrorMarkup =>
      'The ebook text couldn\'t be prepared for matching.';

  @override
  String get readAlongErrorAlignment =>
      'The text couldn\'t be matched to the narration.';

  @override
  String get readAlongErrorOutput => 'The new EPUB failed its checks.';

  @override
  String get readAlongErrorPublish =>
      'The new EPUB couldn\'t be added to this book.';

  @override
  String get readAlongErrorDiscarded => 'It was thrown away at review.';

  @override
  String get readAlongErrorCancelled => 'It was cancelled.';

  @override
  String get readAlongErrorUnknown =>
      'Something went wrong while making the read along.';

  @override
  String get fileInfoNoAudiobook => 'No audiobook yet';

  @override
  String get fileInfoNoEbook => 'No e-book yet';

  @override
  String get fileInfoRequestedBySomeone => 'Requested by someone else';

  @override
  String get fileInfoOwnedSeparately => 'In your library as a separate book';

  @override
  String get fileInfoCopyPath => 'Copy path';

  @override
  String get fileInfoDeleteTitle => 'Delete file?';

  @override
  String fileInfoDeletePrompt(String name) {
    return '\"$name\" will be deleted from the server. This can\'t be undone.';
  }

  @override
  String get fileInfoDeleteLast =>
      'It\'s the book\'s last audio or e-book file, so the book will show as missing.';

  @override
  String get fileInfoDeleteNotAllowed =>
      'You don\'t have permission to delete files';

  @override
  String get chapterSourceEmbedded => 'Read from the audio files';

  @override
  String get chapterSourceTracks => 'One chapter per audio file, not saved';

  @override
  String get chapterSourceProvider => 'From fetched metadata';

  @override
  String get chapterSourceMigration => 'Imported from Audiobookshelf';

  @override
  String get chapterSourceManual => 'Edited in BookOrbit';

  @override
  String chapterSourceManualBy(String name) {
    return 'Edited by $name';
  }

  @override
  String get chapterSourceNone => 'No chapters yet';

  @override
  String get chapterProtected => 'Protected from rescans';

  @override
  String get chapterNotProtected => 'A rescan can replace these';

  @override
  String get chapterProtectOnSave => 'Protect from rescans';

  @override
  String get chapterGetFrom => 'Get Chapters From';

  @override
  String get chapterFromFiles => 'The audio files';

  @override
  String get chapterFromEbookToc => 'The e-book\'s contents';

  @override
  String get chapterFromReadAlong => 'The read along';

  @override
  String get chapterFromHistory => 'Earlier versions';

  @override
  String get chapterHistoryTitle => 'Earlier versions';

  @override
  String get chapterHistoryEmpty => 'Saved versions show up here.';

  @override
  String chapterHistoryBy(String source, String name) {
    return '$source by $name';
  }

  @override
  String get chapterReadingFiles => 'Reading the audio files...';

  @override
  String get chapterRevertToFiles => 'Revert to Files';

  @override
  String get chapterRevertTitle => 'Go back to the chapters in the files?';

  @override
  String get chapterRevertMessage =>
      'BookOrbit reads the chapters in the audio files again and stops protecting them from rescans. Unsaved edits are lost. The current list stays in the earlier versions.';

  @override
  String get chapterReverted => 'Chapters set back to the audio files';

  @override
  String get chapterWriteFiles => 'Write to Files';

  @override
  String get chapterWriteTitle => 'Write the chapters into the audio files?';

  @override
  String chapterWriteMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'This rewrites the book\'s $count audio files with these chapters.',
      one: 'This rewrites the book\'s audio file with these chapters.',
    );
    return '$_temp0 The audio itself is copied unchanged. Phones that already downloaded the book keep their copy until it\'s downloaded again.';
  }

  @override
  String get chapterWriteConfirm => 'Write';

  @override
  String get chapterWriting => 'Writing the chapters into the audio files...';

  @override
  String chapterWritten(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Chapters written into all $count audio files',
      one: 'Chapters written into the audio file',
    );
    return '$_temp0';
  }

  @override
  String chapterWrittenPartly(int written, int total) {
    return 'Chapters written into $written of $total files. The rest were left as they were.';
  }

  @override
  String get chapterStaleTitle => 'These chapters changed';

  @override
  String get chapterStaleMessage =>
      'Someone else saved these chapters after you opened them. Reload to see their version. Your edits stay until you do.';

  @override
  String get chapterReload => 'Reload';

  @override
  String get chapterKeepEditing => 'Keep editing';

  @override
  String get matchExplicitYes => 'Marked explicit';

  @override
  String get matchExplicitNo => 'Not explicit';

  @override
  String get matchAbridgedYes => 'Abridged';

  @override
  String get matchAbridgedNo => 'Unabridged';

  @override
  String boQuickMatchBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'these $count books',
      one: 'this book',
    );
    return 'BookOrbit looks up $_temp0 and fills in what it finds, following its metadata settings.';
  }

  @override
  String get boQuickMatchIgnoreCache => 'Ask every source again';

  @override
  String get boQuickMatchIgnoreCacheHint =>
      'Skips saved answers. Slower, and uses more of each source\'s request limit.';

  @override
  String boAdminServerCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mail servers',
      one: '1 mail server',
      zero: 'None yet',
    );
    return '$_temp0';
  }

  @override
  String get boEmailTitle => 'Send by email';

  @override
  String get boEmailSubtitle =>
      'Devices, mail servers and templates for sending books';

  @override
  String get boEmailTabDevices => 'Devices';

  @override
  String get boEmailTabServers => 'Mail servers';

  @override
  String get boEmailTabTemplates => 'Templates';

  @override
  String get boEmailTabHistory => 'History';

  @override
  String get boEmailName => 'Name';

  @override
  String boEmailDeleteTitle(String name) {
    return 'Delete $name?';
  }

  @override
  String get boEmailMakeDefault => 'Make default';

  @override
  String get boEmailBadgeDefault => 'Default';

  @override
  String get boEmailBadgeShared => 'Shared';

  @override
  String get boEmailBadgeSystem => 'Password resets';

  @override
  String get boEmailBadgeBuiltIn => 'Built in';

  @override
  String get boEmailDevicesEmpty =>
      'No devices yet. Add your e-reader\'s email address to send it books.';

  @override
  String get boEmailAddDevice => 'Add device';

  @override
  String get boEmailNewDevice => 'New device';

  @override
  String get boEmailDeviceNameHint => 'My Kindle';

  @override
  String get boEmailDeviceAddress => 'Email address';

  @override
  String get boEmailDeviceType => 'Device';

  @override
  String get boEmailDeviceNone => 'Person or inbox';

  @override
  String get boEmailDeviceKindle => 'Kindle';

  @override
  String get boEmailDeviceKobo => 'Kobo';

  @override
  String get boEmailDeviceOther => 'Other e-reader';

  @override
  String get boEmailKindleHint =>
      'Kindle gets the subject \"convert\" and only takes EPUB and PDF by email.';

  @override
  String boEmailKindleApprove(String address) {
    return 'Kindle drops mail from addresses it doesn\'t know. In Amazon\'s Personal Document Settings, add $address to the approved list.';
  }

  @override
  String get boEmailKindleApproveNoServer =>
      'Add a mail server first to see the address Kindle needs to approve.';

  @override
  String get boEmailFormat => 'Format';

  @override
  String get boEmailFormatPrimary => 'Book\'s main file';

  @override
  String get boEmailFormatHint =>
      'A book without this format gets its main file.';

  @override
  String get boEmailReadAlong => 'Read along books';

  @override
  String get boEmailReadAlongAuto => 'Automatic';

  @override
  String get boEmailReadAlongAutoHint =>
      'Text only when a copy can be made, otherwise the original.';

  @override
  String get boEmailReadAlongText => 'Text only';

  @override
  String get boEmailReadAlongTextHint =>
      'Narration removed. Small enough for email.';

  @override
  String get boEmailReadAlongOriginal => 'With narration';

  @override
  String get boEmailReadAlongOriginalHint =>
      'Keeps the narration. Often 100 MB or more, over most mail servers\' limits.';

  @override
  String get boEmailTemplate => 'Template';

  @override
  String get boEmailTemplateYourDefault => 'Your default';

  @override
  String get boEmailTemplateKindleHint =>
      'Kindle never shows the message, so it skips the template.';

  @override
  String get boEmailDefaultDevice => 'Default device';

  @override
  String get boEmailDefaultDeviceHint => 'Picked first when you send a book.';

  @override
  String get boEmailSendTest => 'Send a test email';

  @override
  String get boEmailTestSubject => 'Test email from Absorb';

  @override
  String boEmailTestBody(String name) {
    return 'This is a test from Absorb. If you can read it, books sent to $name will arrive here too.';
  }

  @override
  String boEmailTestSent(String name) {
    return 'Test email sent to $name';
  }

  @override
  String boEmailTestFailed(String error) {
    return 'The test email didn\'t go out: $error';
  }

  @override
  String get boEmailDeleteDevice => 'Delete device';

  @override
  String get boEmailDeleteDeviceBody => 'Its send history stays.';

  @override
  String get boEmailDeviceRequired => 'Enter a name and an email address';

  @override
  String get boEmailLastSendFailed => 'Last send failed';

  @override
  String get boEmailGroups => 'Groups';

  @override
  String get boEmailGroupsHint => 'Send to several devices at once.';

  @override
  String get boEmailNewGroup => 'New group';

  @override
  String get boEmailGroupNameHint => 'Book club';

  @override
  String get boEmailGroupMembers => 'Devices in this group';

  @override
  String get boEmailGroupMembersEmpty => 'Add a device first.';

  @override
  String boEmailGroupMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count devices',
      one: '1 device',
      zero: 'No devices',
    );
    return '$_temp0';
  }

  @override
  String get boEmailDeleteGroup => 'Delete group';

  @override
  String get boEmailDeleteGroupBody => 'The devices in it stay.';

  @override
  String get boEmailGroupRequired => 'Enter a group name';

  @override
  String get boEmailServersEmptyManage =>
      'No mail servers yet. Add one to start sending books.';

  @override
  String get boEmailServersEmpty =>
      'No mail servers yet. Ask an admin to add one.';

  @override
  String get boEmailAddServer => 'Add mail server';

  @override
  String get boEmailNewServer => 'New mail server';

  @override
  String get boEmailServerPresetOther => 'Other';

  @override
  String get boEmailServerPresetHint =>
      'A preset fills in the host, port and security. You can still change them.';

  @override
  String get boEmailServerHost => 'Host';

  @override
  String get boEmailServerPort => 'Port';

  @override
  String get boEmailServerSecurity => 'Security';

  @override
  String get boEmailServerSecurityNone => 'None';

  @override
  String get boEmailServerSecurityHint =>
      'STARTTLS on port 587, SSL/TLS on 465.';

  @override
  String get boEmailServerNeedsPassword => 'Signs in with a password';

  @override
  String get boEmailServerUsername => 'Username';

  @override
  String get boEmailServerPassword => 'Password';

  @override
  String get boEmailServerAppPassword => 'App password';

  @override
  String get boEmailServerPasswordKeep => 'Saved. Type to replace it';

  @override
  String get boEmailServerAppPasswordHint =>
      'Gmail and iCloud need an app password, not your account password.';

  @override
  String get boEmailServerFromName => 'From name';

  @override
  String get boEmailServerFromAddress => 'From address';

  @override
  String get boEmailServerFromAddressHint =>
      'Kindle owners need to approve this address.';

  @override
  String get boEmailServerShare => 'Share with everyone';

  @override
  String get boEmailServerShareHint =>
      'Other people can send books through this server without seeing the password.';

  @override
  String get boEmailServerSystem => 'Send password resets and sign-in links';

  @override
  String get boEmailServerSystemHint =>
      'The server BookOrbit uses for its own mail.';

  @override
  String get boEmailServerVerifyTls => 'Check the server\'s certificate';

  @override
  String get boEmailServerVerifyTlsHint =>
      'Turn this off only for a server on your own network with a self-signed certificate.';

  @override
  String get boEmailServerTest => 'Test connection';

  @override
  String get boEmailServerTestSaveFirst => 'Save first, then test';

  @override
  String get boEmailServerTestOk => 'Connected';

  @override
  String boEmailServerTestFailed(String error) {
    return 'Can\'t connect: $error';
  }

  @override
  String get boEmailServerDelete => 'Delete mail server';

  @override
  String get boEmailServerDeleteBody => 'Everyone it\'s shared with loses it.';

  @override
  String get boEmailServerSystemFirst =>
      'Turn off password resets on this server before deleting it.';

  @override
  String get boEmailServerRequired => 'Enter a name and a host';

  @override
  String get boEmailServerNotYours =>
      'Someone else added this server. Only they can change it.';

  @override
  String get boEmailTemplatesEmpty => 'No templates yet.';

  @override
  String get boEmailNewTemplate => 'New template';

  @override
  String get boEmailTemplateSubject => 'Subject';

  @override
  String get boEmailTemplateMessage => 'Message';

  @override
  String get boEmailTemplateInsert => 'Insert';

  @override
  String get boEmailTemplateInsertHint =>
      'Goes in where the cursor is. Details a book doesn\'t have print nothing.';

  @override
  String get boEmailVarBook => 'Book';

  @override
  String get boEmailVarFile => 'File';

  @override
  String get boEmailVarOther => 'Other';

  @override
  String get boEmailTemplatePreview => 'Preview';

  @override
  String get boEmailTemplatePreviewNone =>
      'Send a book once to preview a template with it.';

  @override
  String boEmailTemplateAttached(String name) {
    return 'Attached: $name';
  }

  @override
  String get boEmailTemplateBuiltIn => 'Built in. Only an admin can change it.';

  @override
  String get boEmailTemplateKindleNote =>
      'Kindle never shows a template. It always gets the subject \"convert\".';

  @override
  String get boEmailTemplateDelete => 'Delete template';

  @override
  String get boEmailTemplateDeleteBody =>
      'Devices that use it go back to your default template.';

  @override
  String get boEmailTemplateRequired => 'Enter a name and a subject';

  @override
  String get boEmailHistoryEmpty => 'Nothing sent yet.';

  @override
  String get boEmailHistoryAll => 'All';

  @override
  String get boEmailHistoryEveryone => 'Everyone';

  @override
  String get boEmailStatusSent => 'Sent';

  @override
  String get boEmailStatusSending => 'Sending';

  @override
  String boEmailStatusRetrying(int attempt) {
    return 'Trying again ($attempt)';
  }

  @override
  String get boEmailStatusFailed => 'Failed';

  @override
  String boEmailTo(String name) {
    return 'To $name';
  }

  @override
  String get boEmailResend => 'Send again';

  @override
  String get boEmailResent => 'Sending again';

  @override
  String get boEmailForget => 'Remove from history';

  @override
  String get boEmailLoadMore => 'Load more';

  @override
  String get boEmailUnknownBook => 'Deleted book';

  @override
  String get boEmailSendNoServer =>
      'No mail server is set up on this server yet.';

  @override
  String get boEmailSendAskAdmin => 'Ask an admin to add one.';

  @override
  String get boEmailSendNoDevices => 'Add a device to send this book to.';

  @override
  String get boEmailSendOptions => 'Options';

  @override
  String get boEmailSendFormatEach => 'Each device\'s own';

  @override
  String get boEmailSendServer => 'Mail server';

  @override
  String get boEmailSendButton => 'Send';

  @override
  String boEmailSendGets(String format, String size) {
    return 'Gets $format · $size';
  }

  @override
  String boEmailSendMissing(String format, String got) {
    return 'No $format, gets the $got';
  }

  @override
  String boEmailSendKindleRejects(String format) {
    return 'Kindle doesn\'t take $format by email';
  }

  @override
  String boEmailSendOverKindle(String size) {
    return '$size, over Kindle\'s 50 MB limit';
  }

  @override
  String boEmailSendOverGmail(String size) {
    return '$size, over Gmail\'s 25 MB limit';
  }

  @override
  String get boEmailSendTextOnly =>
      'Gets the text only EPUB, narration left out';

  @override
  String boEmailSendNarrated(String size) {
    return 'Gets the narrated copy · $size';
  }

  @override
  String boEmailSendHanding(String server) {
    return 'Sending through $server';
  }

  @override
  String boEmailSendAccepted(String server) {
    return 'Sent through $server';
  }

  @override
  String boEmailSendFailedLine(String error) {
    return 'Didn\'t send: $error';
  }

  @override
  String get boEmailSendStillGoing =>
      'Still sending. You\'ll get a notification when it\'s done.';

  @override
  String get boEmailKindleOriginal =>
      'A Kindle can\'t take the narrated copy. Set it to text only.';

  @override
  String get boEmailNoCopy => 'Couldn\'t make a copy without the narration.';

  @override
  String get boForgotLink => 'Forgot password?';

  @override
  String get boForgotTitle => 'Reset your password';

  @override
  String get boForgotBody =>
      'Enter the email on your account and the server will send you a link to choose a new password.';

  @override
  String get boForgotSend => 'Send link';

  @override
  String get boForgotSent =>
      'If that email is on an account, a link is on its way. Open it to choose a new password, then sign in here.';

  @override
  String get boForgotNotSetUp =>
      'This server isn\'t set up to send email. Ask whoever runs it for a password link.';

  @override
  String get boForgotTooMany => 'Too many tries. Wait a while and try again.';

  @override
  String get boActivityTitle => 'Reading activity';

  @override
  String get boActivityPrivate => 'Keeps their reading activity private';

  @override
  String get boActivitySharesSummary =>
      'Shares a summary. They can see when you view it.';

  @override
  String get boActivitySharesDetails =>
      'Shares details, including books. They can see when you view it.';

  @override
  String get boActivityNotice => 'This person can see that you viewed this.';

  @override
  String get boActivityNowPrivate =>
      'This person isn\'t sharing their reading activity anymore.';

  @override
  String get boActivityLoadFailed => 'Couldn\'t load reading activity.';

  @override
  String get boActivityEmpty => 'No reading in this period';

  @override
  String get boActivityReadingTime => 'Reading time';

  @override
  String get boActivitySessions => 'Sessions';

  @override
  String get boActivityActiveDays => 'Active days';

  @override
  String get boActivityStarted => 'Books started';

  @override
  String get boActivityFinished => 'Books finished';

  @override
  String get boActivityTrend => 'Daily reading';

  @override
  String get boActivitySources => 'Read on';

  @override
  String get boActivityFormats => 'Formats';

  @override
  String get boActivityGenres => 'Genres';

  @override
  String get boActivityTopBooks => 'Most read';

  @override
  String get boActivityRecentBooks => 'Recently read';

  @override
  String get boActivityTopAuthors => 'Top authors';

  @override
  String get boActivityTopGenres => 'Top genres';

  @override
  String get boActivityTopSeries => 'Top series';

  @override
  String get boActivityTopNarrators => 'Top narrators';

  @override
  String get boActivityUntitled => 'Untitled book';

  @override
  String get boActivitySourceWeb => 'Web reader';

  @override
  String get boActivitySourceIos => 'iOS app';

  @override
  String get boActivitySourceWatch => 'Apple Watch';

  @override
  String get boActivitySourceAndroid => 'Android app';

  @override
  String get boActivitySourceManual => 'Manual';

  @override
  String get boActivitySourceUnknown => 'Unknown';

  @override
  String get boActivityGenreSciFi => 'Science fiction';

  @override
  String get boActivityGenreFantasy => 'Fantasy';

  @override
  String get boActivityGenreMystery => 'Mystery and thriller';

  @override
  String get boActivityGenreRomance => 'Romance';

  @override
  String get boActivityGenreHorror => 'Horror';

  @override
  String get boActivityGenreHistory => 'History and biography';

  @override
  String get boActivityGenreScience => 'Science and technology';

  @override
  String get boActivityGenreBusiness => 'Business and economics';

  @override
  String get boActivityGenreSelf => 'Self-development';

  @override
  String get boActivityGenreSociety => 'Society and culture';

  @override
  String get boActivityGenreChildren => 'Children and young adult';

  @override
  String get boActivityGenreComics => 'Comics and graphic novels';

  @override
  String get boActivityGenrePoetry => 'Poetry';

  @override
  String get boActivityGenreOther => 'Other';

  @override
  String boActivityDays(int count) {
    return '$count days';
  }

  @override
  String boActivityMinutes(int count) {
    return '$count min';
  }

  @override
  String boActivityHours(double count) {
    return '$count h';
  }

  @override
  String get loginBoKeyOrLink => 'API key or magic link';

  @override
  String get loginBoKeyOrLinkDescription =>
      'Sign in with an API key from BookOrbit, a magic link, or paste a password link to set your password.';

  @override
  String get boPermLibraryMergeBooks => 'Merge and link books';

  @override
  String get boPermLibraryGenerateReadAloud => 'Generate read-aloud books';

  @override
  String get boPermApiKeys => 'Create API keys';

  @override
  String get boAdminApiKeysSubtitle =>
      'Allow keys on this server and cap how long they last';

  @override
  String get boAccountApiKeysSubtitle =>
      'Keys that sign in without your password';

  @override
  String get boAccountKeySession => 'Signed in with an API key';

  @override
  String get boAccountKeySessionSubtitle =>
      'Changing your password or keys asks for a password sign-in first';

  @override
  String get boAccountKeyReadOnly =>
      'This key is read only, so nothing you do is saved to the server';

  @override
  String get boUserApiKeysSubtitle =>
      'Issue a key that signs this person in to Absorb, or revoke theirs';

  @override
  String get boApiKeysTitle => 'API keys';

  @override
  String boApiKeysForUser(String name) {
    return 'API keys for $name';
  }

  @override
  String get boApiKeysIntro =>
      'A key signs in without your password, for a script or another Absorb. It can do no more than you can, and you can narrow it further.';

  @override
  String boApiKeysIntroAdmin(String name) {
    return 'A key signs $name in without their password. It can do no more than they can, and runs as them.';
  }

  @override
  String get boApiKeysDisabled => 'API keys are turned off on this server';

  @override
  String get boApiKeysNoPermission =>
      'Your account is not allowed to create API keys. An administrator can grant that, or issue one for you.';

  @override
  String boApiKeysLimit(int count) {
    return 'A person can have $count active keys at most. Revoke one to make room.';
  }

  @override
  String get boApiKeysEmpty => 'No API keys yet';

  @override
  String get boApiKeyCreate => 'New key';

  @override
  String get boApiKeyIssue => 'Issue a key';

  @override
  String boApiKeyIssueFor(String name) {
    return 'Issue a key for $name';
  }

  @override
  String get boApiKeyCreateHint =>
      'The key is shown once, right after it is made.';

  @override
  String get boApiKeyName => 'Name';

  @override
  String get boApiKeyNameHint => 'What is this key for?';

  @override
  String get boApiKeyAccess => 'Access';

  @override
  String get boApiKeyAccessRead => 'Read';

  @override
  String get boApiKeyAccessWrite => 'Read and write';

  @override
  String get boApiKeyAccessReadHint =>
      'Can look things up but change nothing. Absorb cannot save progress with a read key.';

  @override
  String get boApiKeyAccessWriteHint =>
      'What Absorb needs to save progress, bookmarks and settings.';

  @override
  String get boApiKeyExpires => 'Expires';

  @override
  String get boApiKeyExpiryNever => 'Never';

  @override
  String boApiKeyExpiryDays(int count) {
    return '$count days';
  }

  @override
  String boApiKeyExpiryCapped(int count) {
    return 'This server caps keys at $count days.';
  }

  @override
  String get boApiKeyAdmin => 'Administrator access';

  @override
  String get boApiKeyAdminHint =>
      'The key can do everything an administrator can. It cannot be limited to libraries.';

  @override
  String get boApiKeyPermissions => 'Permissions';

  @override
  String get boApiKeyPermissionsHint =>
      'Pick what the key may use. With none, it can still read the libraries and personal data.';

  @override
  String get boApiKeyAdminHasAll =>
      'An administrator key has every permission.';

  @override
  String get boApiKeyNoGrantable =>
      'The account has no permissions a key could carry.';

  @override
  String get boApiKeyLibraries => 'Libraries';

  @override
  String get boApiKeyAllLibraries => 'All libraries';

  @override
  String get boApiKeyRename => 'Rename';

  @override
  String get boApiKeyRegenerate => 'Regenerate';

  @override
  String get boApiKeyRegenerateTitle => 'Regenerate this key?';

  @override
  String boApiKeyRegenerateBody(String name) {
    return '\"$name\" gets a new secret and the old one stops working at once. Anything using the old one has to be updated.';
  }

  @override
  String get boApiKeyRevoke => 'Revoke';

  @override
  String get boApiKeyRevokeTitle => 'Revoke this key?';

  @override
  String boApiKeyRevokeBody(String name) {
    return '\"$name\" stops working at once. Anything signed in with it is signed out.';
  }

  @override
  String get boApiKeyRevoked => 'Key revoked';

  @override
  String get boApiKeyRevokeAll => 'Revoke all';

  @override
  String get boApiKeyRevokeAllTitle => 'Revoke every key?';

  @override
  String boApiKeyRevokeAllBody(int count) {
    return '$count keys stop working at once. Anything signed in with them is signed out.';
  }

  @override
  String boApiKeyRevokedCount(int count) {
    return '$count keys revoked';
  }

  @override
  String boApiKeyRevokedOn(String date) {
    return 'Revoked $date';
  }

  @override
  String boApiKeyExpiredOn(String date) {
    return 'Expired $date';
  }

  @override
  String boApiKeyExpiresSoon(String date) {
    return 'Expires soon, on $date';
  }

  @override
  String boApiKeyExpiresOn(String date) {
    return 'Expires $date';
  }

  @override
  String get boApiKeyNeverExpires => 'Never expires';

  @override
  String get boApiKeyNeverUsed => 'Never used';

  @override
  String boApiKeyLastUsed(String date) {
    return 'Last used $date';
  }

  @override
  String boApiKeyLastUsedFrom(String date, String ip) {
    return 'Last used $date from $ip';
  }

  @override
  String boApiKeyLibrariesOnly(String names) {
    return 'Only $names';
  }

  @override
  String boApiKeyIssuedBy(String name) {
    return 'Issued by $name';
  }

  @override
  String get boApiKeyAdminBadge => 'Admin';

  @override
  String get boApiKeyExpiringBadge => 'Expiring';

  @override
  String get boApiKeyExpiredBadge => 'Expired';

  @override
  String get boApiKeyRevokedBadge => 'Revoked';

  @override
  String get boApiKeyRevealHint =>
      'Copy it now or send it to the other device. It is not shown again.';

  @override
  String get boApiKeyCopy => 'Copy key';

  @override
  String get boApiKeyCopied => 'Key copied';

  @override
  String get boApiKeySignInElsewhere => 'Sign in on another device';

  @override
  String get boApiKeyRevealWarning =>
      'This is the only time the key is shown. If it is lost, regenerate it.';

  @override
  String boApiKeyShareDescription(String username) {
    return 'Open this link or scan the QR code on the other device to sign in to Absorb as $username with this key.';
  }

  @override
  String boApiKeyShareWarning(String name) {
    return 'Anyone with this link can use the key \"$name\" until it is revoked.';
  }

  @override
  String get boApiKeyErrorExpiryCap =>
      'That lifetime is longer than this server allows';

  @override
  String get boApiKeyErrorOwner =>
      'This account cannot hold keys right now: it is suspended or not allowed to create them';

  @override
  String get boApiKeyErrorAdminLibraries =>
      'An administrator key cannot be limited to libraries';

  @override
  String get boApiKeyErrorScope => 'The key asked for more than its owner has';

  @override
  String get boApiKeyErrorKeySession =>
      'Keys cannot be managed from a session that signed in with a key';

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
  String get boApiKeySettingsSaved => 'API key settings saved';

  @override
  String get boApiKeySettingsIntro => 'These apply to every key on the server.';

  @override
  String get boApiKeySettingsEnabled => 'Allow API keys';

  @override
  String get boApiKeySettingsEnabledHint =>
      'Off turns every key away without revoking any, and stops new ones being made';

  @override
  String get boApiKeySettingsMaxLifetime => 'Longest lifetime';

  @override
  String get boApiKeySettingsMaxLifetimeHint =>
      'New and regenerated keys cannot last longer than this. Existing keys keep their expiry.';

  @override
  String get boApiKeySettingsNoLimit => 'No limit';

  @override
  String get boApiKeySettingsCustom => 'Other';

  @override
  String get boApiKeySettingsCustomDays => 'Days';

  @override
  String boApiKeySettingsCustomRange(int max) {
    return 'Between 1 and $max days';
  }

  @override
  String get boUserKeyLink => 'Sign-in link with an API key';

  @override
  String get boUserKeyLinkSubtitle =>
      'Makes a key with everything this person has and shows a QR code that signs them in to Absorb';

  @override
  String get boApiKeyLinkName => 'Absorb sign-in';

  @override
  String boApiKeyLinkFor(String name) {
    return 'Sign-in link for $name';
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
  String get tvSortListened => 'Recently listened';

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

  @override
  String get settingsGroupSpeed => 'Speed';

  @override
  String get settingsGroupSkipping => 'Skipping';

  @override
  String get settingsGroupRewind => 'Rewind on resume';

  @override
  String playbackSummary(String speed, int back, int forward) {
    return '${speed}x, skip back ${back}s, forward ${forward}s';
  }

  @override
  String get settingsGroupApp => 'App';

  @override
  String get settingsGroupLook => 'Look';

  @override
  String get settingsGroupColor => 'Color';

  @override
  String get settingsGroupCoversAndText => 'Covers and text';

  @override
  String get settingsGroupGoals => 'Goals';

  @override
  String get settingsGroupCharts => 'Charts';

  @override
  String get settingsGroupPlayer => 'Player';

  @override
  String get settingsGroupQueue => 'Queue';

  @override
  String get settingsGroupLockScreen => 'Notification and lock screen';

  @override
  String get settingsGroupSorting => 'Sorting';

  @override
  String get settingsGroupSleepTriggers => 'Shake and buttons';

  @override
  String get settingsGroupSleepEnd => 'When the timer ends';

  @override
  String get settingsGroupSleepSchedule => 'Schedule';

  @override
  String get settingsGroupDownloading => 'Downloading';

  @override
  String get settingsGroupAutoDownloads => 'Automatic downloads';

  @override
  String get settingsGroupStorage => 'Storage';

  @override
  String get settingsGroupBrowsing => 'Browsing';

  @override
  String get settingsGroupBadges => 'Badges and buttons';

  @override
  String get settingsGroupLibraries => 'Libraries';

  @override
  String get settingsGroupHelp => 'Help';

  @override
  String get settingsGroupContact => 'Get in touch';

  @override
  String get settingsGroupLogs => 'Logs';

  @override
  String get settingsGroupConnection => 'Connection';

  @override
  String get settingsGroupTools => 'Tools';

  @override
  String get trueCoverColorsLabel => 'True cover colors';

  @override
  String get trueCoverColorsSubtitle =>
      'Keep each book\'s color close to its cover instead of softening it';

  @override
  String get sectionGeneral => 'General';

  @override
  String get settingsGroupGlow => 'Glow';

  @override
  String get glowStrengthLabel => 'Glow strength';

  @override
  String get appColorLabel => 'App color';

  @override
  String get appColorSoftCover => 'Soft cover';

  @override
  String get appColorTrueCover => 'True cover';

  @override
  String get appColorMine => 'My color';

  @override
  String get appColorSoftCoverDescription =>
      'Follows the cover of the playing book, toned down';

  @override
  String get appColorTrueCoverDescription =>
      'Follows the cover of the playing book, close to its real color';

  @override
  String get appColorMineDescription =>
      'One color you pick, whatever is playing';

  @override
  String get bookDockJoinTitle => 'New book or one you have?';

  @override
  String get bookDockJoinHint =>
      'Adding to a book you have puts this file in that book\'s folder as another format.';

  @override
  String get bookDockJoinNewBook => 'Add as a new book';

  @override
  String get bookDockJoinSameIsbn => 'Same ISBN';

  @override
  String get bookDockJoinSameTitle => 'Same title and author';

  @override
  String get bookDockJoinLooksSame => 'Looks like the same book';

  @override
  String bookDockJoinSearch(String library) {
    return 'Search $library';
  }

  @override
  String get bookDockJoinSearchFailed => 'Couldn\'t search this library';

  @override
  String get bookDockJoinNoMatch => 'No books match';

  @override
  String bookDockJoined(String title) {
    return 'Added to $title as another format';
  }

  @override
  String get breqHoldForReview => 'Hold for review';

  @override
  String get breqHoldForReviewHint =>
      'Wait for you to check it instead of going straight to the library';

  @override
  String get breqGrabbedHeld => 'Download started. It will wait for your check';

  @override
  String get boSettingsSaved => 'Settings saved';

  @override
  String get boDestinationNone => 'None';

  @override
  String get boDestinationPick => 'Pick a library';

  @override
  String get boReqSettingsTitle => 'Request settings';

  @override
  String get boReqSettingsSubtitle =>
      'Downloading, checking and where requests go';

  @override
  String get boReqAutoSection => 'Downloading without asking';

  @override
  String get boReqAutoGrab => 'Download without asking';

  @override
  String get boReqAutoGrabHint =>
      'An approved request goes to the best release BookOrbit finds, with nobody picking it';

  @override
  String boReqAutoGrabScore(int score) {
    return 'Lowest score to download: $score';
  }

  @override
  String get boReqAutoRetry => 'Try the next release when one fails';

  @override
  String boReqAttempts(int count) {
    return 'Tries for each request: $count';
  }

  @override
  String get boReqSearchSection => 'Looking again';

  @override
  String get boReqAutoSearch => 'Keep looking when nothing is found';

  @override
  String get boReqAutoSearchHint =>
      'Only does anything with Download without asking turned on';

  @override
  String boReqSearchInterval(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours hours',
      one: 'hour',
    );
    return 'Look again every $_temp0';
  }

  @override
  String boReqSearchMaxAge(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    return 'Stop looking after $_temp0';
  }

  @override
  String get boReqVerifySection => 'Checking a download';

  @override
  String get boReqVerify => 'Check downloads against the request';

  @override
  String get boReqVerifyHint =>
      'A poor match waits in Book Dock instead of going to the library';

  @override
  String boReqVerifyThreshold(int percent) {
    return 'Match needed to add it: $percent%';
  }

  @override
  String get boReqFormatsSection => 'A download with several formats';

  @override
  String get boReqFormatsAll => 'Keep every format';

  @override
  String get boReqFormatsPreferred => 'Keep only the preferred format';

  @override
  String get boReqDestSection => 'Where requests go';

  @override
  String get boReqDestHint => 'Used when nobody picks a library for a request';

  @override
  String get boReqDestEbooks => 'E-books';

  @override
  String get boReqDestAudiobooks => 'Audiobooks';

  @override
  String get boReqProfilesNote =>
      'Release profiles are set on the BookOrbit web page.';

  @override
  String get boDockSettingsTitle => 'Book Dock settings';

  @override
  String get boDockSettingsSubtitle =>
      'What happens to a file when it lands in Book Dock';

  @override
  String get boDockPaused => 'Pause Book Dock';

  @override
  String get boDockPausedHint =>
      'Stops taking in and adding files until you turn this off';

  @override
  String get boDockFolder => 'Folder on the server';

  @override
  String get boDockLookUp => 'Look up details online';

  @override
  String get boDockLookUpHint =>
      'Searches for a file\'s details when it arrives';

  @override
  String get boDockAutoSection => 'Adding to a library without asking';

  @override
  String get boDockAutoFile => 'Add good matches without asking';

  @override
  String get boDockAutoFileHint =>
      'Off, every file waits in Book Dock until you add it';

  @override
  String boDockAutoThreshold(int percent) {
    return 'Match needed: $percent%';
  }

  @override
  String get boDockAutoLibrary => 'Library for files with no destination';

  @override
  String get boDockAutoLibraryNone => 'None, they wait for you';

  @override
  String get boDockModeSection => 'Details to use';

  @override
  String get boDockModeSafe =>
      'Found details first, the file\'s own for the rest';

  @override
  String get boDockModeFound => 'Only details found online';

  @override
  String get boDockModeFile => 'Only the file\'s own details';

  @override
  String get boDockModeFileHint => 'Adds every ready file, whatever its match';

  @override
  String get boDockUnsortedSection => 'Files with no library';

  @override
  String get boDockAutoJoin => 'Add to a matching book';

  @override
  String get boDockAutoJoinHint =>
      'Only when they share an ISBN, ASIN or provider id. Title and author alone never count.';

  @override
  String get boDockKeepOriginal => 'Keep the original file';

  @override
  String get boDockKeepOriginalHint =>
      'Leaves the file in Book Dock\'s folder, for a download client that is still sharing it';

  @override
  String get upcomingReleasesBulkRescanDates => 'Rescan dates';

  @override
  String upcomingReleasesBulkDatesChecked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dates checked',
      one: '1 date checked',
    );
    return '$_temp0';
  }

  @override
  String upcomingReleasesBulkDatesFailed(int count) {
    return '$count failed';
  }

  @override
  String get audibleSeriesBulkAddUpcoming => 'Add to upcoming';

  @override
  String audibleSeriesBulkAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count added to upcoming releases',
      one: '1 added to upcoming releases',
    );
    return '$_temp0';
  }
}
