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
  String get listsNone => 'No collections or playlists';

  @override
  String get listsNoneHint =>
      'Collections and playlists are made on your Audiobookshelf server, and show up here.';

  @override
  String get listsLoadFailed => 'Couldn\'t load your lists';

  @override
  String get listsLoadFailedHint =>
      'Absorb couldn\'t reach your server for collections and playlists.';

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
  String get gotIt => 'Verstanden';

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
  String get loginRedirectUri => 'Redirect-URI: audiobookshelf://oauth';

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
    return 'Versende diesen privaten Link oder lasse den QR Code scannen, um eine Anmeldung als $username zu ermöglichen.';
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
  String get noEbook => 'Kein eBook';

  @override
  String get hasSupplementaryEbook => 'Hat ergänzendes eBook';

  @override
  String get noSupplementaryEbook => 'Kein ergänzendes eBook';

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
  String downloadsSelectedCount(int count) {
    return '$count ausgewählt';
  }

  @override
  String get bookmarksTitle => 'Alle Lesezeichen';

  @override
  String get bookmarksTabBookmarks => 'Bookmarks';

  @override
  String get bookmarksTabHighlights => 'Highlights';

  @override
  String get highlightOpenInBook => 'Open in book';

  @override
  String get highlightDeleteAction => 'Delete highlight';

  @override
  String get highlightDeleted => 'Highlight deleted';

  @override
  String highlightsDeleteCount(int count) {
    return 'Delete $count highlight(s)?';
  }

  @override
  String highlightsDeletedCount(int count) {
    return 'Deleted $count highlight(s)';
  }

  @override
  String get quoteShareTitle => 'Share quote';

  @override
  String get quoteShareAction => 'Share';

  @override
  String get quoteShareFailed => 'Couldn\'t make the quote image';

  @override
  String get quoteShapePortrait => 'Portrait';

  @override
  String get quoteShapeSquare => 'Square';

  @override
  String get quoteShapeStory => 'Story';

  @override
  String get quoteStyleBlur => 'Blurred';

  @override
  String get quoteStyleDim => 'Dimmed';

  @override
  String get quoteStyleNone => 'Plain cover';

  @override
  String get quoteTextLight => 'Light text';

  @override
  String get quoteTextDark => 'Dark text';

  @override
  String get quoteFieldTitle => 'Title';

  @override
  String get quoteFieldDetail => 'Details';

  @override
  String get quoteFieldDetailHint => 'Author, chapter, page, who said it';

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
  String get settingsMergeImpliedByPodcastTab =>
      'Immer eingeschaltet, während der Podcasts-Tab aktiviert ist';

  @override
  String get settingsEpisodeNotifs => 'Benachrichtigung für neue Folgen';

  @override
  String get settingsEpisodeNotifsDesc =>
      'Abonnierte Podcasts im Hintergrund prüfen';

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
  String get einkModeLabel => 'E-ink mode';

  @override
  String get einkModeSubtitle =>
      'High-contrast black and white with no animations, made for e-ink screens';

  @override
  String get einkModeIntroBody =>
      'Made for e-ink screens. The app switches to a flat black-and-white look with high contrast, animations are turned off, the playing card loses its background, and the live server connection stays off to save battery. Playback and progress still sync normally. Your appearance settings are kept and come back when you turn this off.';

  @override
  String get einkModeIntroConfirm => 'Turn on';

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
  String get coverSize => 'Cover size';

  @override
  String get coverSizeSubtitle => 'How many covers fit across the library grid';

  @override
  String get coverSizeSmall => 'Small';

  @override
  String get coverSizeMedium => 'Medium';

  @override
  String get coverSizeLarge => 'Large';

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
  String get cardScrubbers => 'Karten scrubber';

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
      'An - verbleibende Zeit berücksichtigt die Wiedergabegeschwindigkeit';

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
  String get mergeLibraries => 'Bibliotheken zusammenführen';

  @override
  String get mergeLibrariesInfoTitle => 'Bibliotheken zusammenführen';

  @override
  String get mergeLibrariesInfoContent =>
      'Wenn aktiviert, zeigt der Absorbing-Bildschirm alle deine angefangenen Bücher und Podcasts aus jeder Bibliothek in einer Ansicht. Wenn deaktiviert, werden nur Inhalte aus der aktuell ausgewählten Bibliothek angezeigt.';

  @override
  String get mergeLibrariesOnSubtitle =>
      'Absorbing-Seite zeigt Inhalte aus allen Bibliotheken';

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
      'Deine Absorbing-Karten funktionieren wie eine Playlist. Wenn eine endet, läuft die nächste noch nicht beendete Karte automatisch weiter. Füge Inhalte über den Button \"Zu Absorbing hinzufügen\" bei einem Buch oder einer Episode hinzu und sortiere sie auf dem Absorbing-Bildschirm um.';

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
  String get autoDownloadThisSeriesLabel => 'Auto-download this series';

  @override
  String get autoDownloadThisShowLabel => 'Auto-download this podcast';

  @override
  String get autoDownloadThisPlaylistLabel => 'Auto-download this playlist';

  @override
  String get autoDownloadThisCollectionLabel => 'Auto-download this collection';

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
  String get sleepAddAmount => 'Add time amount';

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
  String get buttonDuringSleepTimer => 'Headphone button during wind-down';

  @override
  String get buttonDuringSleepTimerHint =>
      'In the final wind-down moments, one press resets the timer instead of pausing. Double press still skips.';

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
      'Pro Serie oder Podcast über deren Detailseiten aktivieren';

  @override
  String get autoDownloadEnabledFor => 'Turned on for';

  @override
  String get autoDownloadEnabledForNone => 'Nothing yet';

  @override
  String get autoDownloadSourceUnnamed => 'Not loaded yet';

  @override
  String get keepNext => 'Nächste behalten';

  @override
  String get keepNextInfoTitle => 'Nächste behalten';

  @override
  String get keepNextInfoContent =>
      'Die Anzahl der Elemente, die heruntergeladen bleiben sollen, einschließlich des Elements, das du gerade hörst. Beispiel: \"Nächste 3 behalten\" bedeutet, das aktuelle Buch plus die nächsten 2 in der Serie oder im Podcast bleiben heruntergeladen.';

  @override
  String get deleteAbsorbedDownloads => 'Absorbed Downloads löschen';

  @override
  String get deleteAbsorbedDownloadsInfoTitle => 'Absorbed Downloads löschen';

  @override
  String get deleteAbsorbedDownloadsInfoContent =>
      'Wenn aktiviert, werden heruntergeladene Bücher oder Episoden automatisch von diesem Gerät gelöscht, nachdem du sie in Absorb zu Ende gehört hast. Wenn du einen Titel im Web oder auf einem anderen Gerät beendest, bleibt der Download hier erhalten.';

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
  String get hideFinishedInCarTitle =>
      'Hide finished in CarPlay & Android Auto';

  @override
  String get hideFinishedInCarOnSubtitle =>
      'Finished books and episodes are hidden while browsing in the car (Continue is unaffected)';

  @override
  String get hideFinishedInCarOffSubtitle =>
      'Off - finished items shown in the car';

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
      'An - Logs werden in Datei gespeichert (Neustart nötig)';

  @override
  String get enableLoggingOffSubtitle => 'Aus - keine Logs werden erfasst';

  @override
  String get loggingEnabledSnackbar =>
      'Logging aktiviert - App neu starten, um Aufzeichnung zu beginnen';

  @override
  String get loggingDisabledSnackbar =>
      'Logging deaktiviert - App neu starten, um Aufzeichnung zu beenden';

  @override
  String get sendLogs => 'Logs senden';

  @override
  String get sendLogsSubtitle => 'Logdatei als Anhang teilen';

  @override
  String failedToShare(String error) {
    return 'Teilen fehlgeschlagen: $error';
  }

  @override
  String get clearLogs => 'Logs löschen';

  @override
  String get logsCleared => 'Logs gelöscht';

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
  String get fullyAbsorbed => 'Vollständig Absorbed';

  @override
  String get fullyAbsorbAction => 'Vollständig Absorb';

  @override
  String get removeFromAbsorbing => 'Aus Absorbing entfernen';

  @override
  String get addToAbsorbing => 'Zu Absorbing hinzufügen';

  @override
  String get removedFromAbsorbing => 'Aus Absorbing entfernt';

  @override
  String get addedToAbsorbing => 'Zu Absorbing hinzugefügt';

  @override
  String get removeFromContinueListening => 'Aus \"Weiterhören\" entfernen';

  @override
  String get removedFromContinueListening => 'Aus \"Weiterhören\" entfernt';

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
  String get markAsNotFinishedQuestion => 'Als nicht beendet markieren?';

  @override
  String get markAsNotFinishedContent =>
      'Dadurch wird der Beendet-Status entfernt, deine aktuelle Position bleibt aber erhalten.';

  @override
  String get unmark => 'Markierung entfernen';

  @override
  String get markedAsNotFinishedBackAtIt =>
      'Als nicht beendet markiert - weiter geht\'s!';

  @override
  String get resetProgressQuestion => 'Fortschritt zurücksetzen?';

  @override
  String get resetProgressContent =>
      'Dadurch wird der gesamte Fortschritt für dieses Buch gelöscht und es auf den Anfang zurückgesetzt. Das kann nicht rückgängig gemacht werden.';

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
  String get coverRemove => 'Remove cover';

  @override
  String get coverRemoveConfirm =>
      'Remove this book\'s cover? It will show the generated title card instead.';

  @override
  String get coverRemoved => 'Cover removed';

  @override
  String get coverRemoveFailed => 'Could not remove the cover';

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
  String get deleteFilesCheckbox => 'Also delete the files on the server';

  @override
  String get deleteFilesCheckedHint =>
      'The files are deleted from the server for good.';

  @override
  String get deleteFilesUncheckedHint =>
      'The files stay on the server, so the next library scan can add this back.';

  @override
  String get deleteFromServerAction => 'Delete from Server';

  @override
  String get deleteFromServerTitle => 'Delete from server';

  @override
  String deleteFromServerContent(String title) {
    return 'Delete \"$title\" from Audiobookshelf?';
  }

  @override
  String deletedFromServer(String title) {
    return 'Deleted \"$title\"';
  }

  @override
  String get deleteFromServerFailed =>
      'Couldn\'t delete that. Check the server logs.';

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
  String get castToDevice => 'An Gerät casten';

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
  String get refreshTooltip => 'Refresh';

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
    return '\"$title\" aus Audiobookshelf entfernen? Die Dateien auf der Festplatte werden nicht gelöscht.';
  }

  @override
  String adminMissingDeleteManyContent(int count) {
    return '\"$count\" aus Audiobookshelf entfernen? Die Dateien auf der Festplatte werden nicht gelöscht.';
  }

  @override
  String adminMissingDeleteCount(int count) {
    return '\"$count\" löschen?';
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
  String get adminPodcastsMaxEpisodesToKeep => 'Max episodes to keep';

  @override
  String get adminPodcastsMaxEpisodesToKeepHelp =>
      '0 keeps every episode. After a new episode is auto-downloaded, Audiobookshelf removes the oldest episode when the show is over this limit.';

  @override
  String get adminPodcastsNoEpisodeLimit => 'No limit';

  @override
  String get adminPodcastsEpisodeLimitInvalid => 'Enter 0 or a whole number';

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
  String get episodeListSortBy => 'Sort episodes';

  @override
  String get episodeListSortPubDate => 'Publish date';

  @override
  String get episodeListSortTitle => 'Title';

  @override
  String get episodeListSortSeason => 'Season';

  @override
  String get episodeListSortEpisode => 'Episode number';

  @override
  String get episodeListSortFileName => 'File name';

  @override
  String get episodeListSortReverseHint => 'Tap again to reverse the order';

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
  String statsScreenJumpToSessionStart(String position) {
    return 'Zum Sitzungsstart springen ($position)';
  }

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
  String get upcomingReleasesScanSettingsTitle => 'Scan settings';

  @override
  String get upcomingReleasesFinishedAfterTitle =>
      'Consider a series finished after';

  @override
  String get upcomingReleasesFinishedAfterDesc =>
      'Series whose last book is older than this are skipped during scans and only re-checked every month or two.';

  @override
  String upcomingReleasesFinishedAfterYears(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count years',
      one: '1 year',
    );
    return '$_temp0';
  }

  @override
  String get upcomingReleasesFinishedAfterNever => 'Never';

  @override
  String get upcomingReleasesSkippedTitle => 'Skipped series';

  @override
  String get upcomingReleasesSkippedNone => 'Nothing skipped yet';

  @override
  String upcomingReleasesSkippedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count skipped',
      one: '1 skipped',
    );
    return '$_temp0';
  }

  @override
  String upcomingReleasesSkippedLastBook(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Last book $count years ago',
      one: 'Last book 1 year ago',
      zero: 'Last book under a year ago',
    );
    return '$_temp0';
  }

  @override
  String get upcomingReleasesSkippedUnmatched =>
      'Couldn\'t match this series on Audible';

  @override
  String get upcomingReleasesSkippedScanNow => 'Scan now';

  @override
  String get upcomingReleasesSkippedAlwaysScan => 'Always scan';

  @override
  String get upcomingReleasesSkippedNeverScan => 'Never scan';

  @override
  String upcomingReleasesSkippedScanFound(String name) {
    return 'Found new releases in $name';
  }

  @override
  String upcomingReleasesSkippedScanNone(String name) {
    return 'Nothing new in $name';
  }

  @override
  String get upcomingReleasesSkippedOtherLibrary =>
      'This list came from a different library. Run a rescan to refresh it.';

  @override
  String get upcomingReleasesChipUpcoming => 'Upcoming';

  @override
  String upcomingReleasesChipMissing(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count missing',
      one: '1 missing',
      zero: 'Missing',
    );
    return '$_temp0';
  }

  @override
  String get upcomingReleasesNoMissing => 'No missing books found';

  @override
  String get upcomingReleasesScanSeries => 'Scan series';

  @override
  String get upcomingReleasesScanUpcomingOption => 'Upcoming releases';

  @override
  String get upcomingReleasesScanUpcomingOptionDesc =>
      'Quick scan for new and upcoming books';

  @override
  String get upcomingReleasesScanDeepOption => 'Deep scan';

  @override
  String get upcomingReleasesScanDeepOptionDesc =>
      'Also finds missing books in every series - takes longer';

  @override
  String get upcomingReleasesFirstScanNote =>
      'The first scan checks every series on Audible and can take a few minutes. Later scans get much quicker once your series are sorted.';

  @override
  String get upcomingReleasesLastScanReport => 'Last scan report';

  @override
  String upcomingReleasesReportChecked(int count) {
    return 'Checked on Audible: $count';
  }

  @override
  String upcomingReleasesReportSkipped(int count) {
    return 'Skipped: $count';
  }

  @override
  String upcomingReleasesReportUnmatched(int count) {
    return 'Couldn\'t match on Audible: $count';
  }

  @override
  String upcomingReleasesReportFailed(int count) {
    return 'Failed to check: $count';
  }

  @override
  String upcomingReleasesReportFound(int upcoming, int recent) {
    return 'Found $upcoming upcoming, $recent recent';
  }

  @override
  String upcomingReleasesReportFoundDeep(
    int upcoming,
    int recent,
    int missing,
  ) {
    return 'Found $upcoming upcoming, $recent recent, $missing missing';
  }

  @override
  String upcomingReleasesReportMore(int count) {
    return '+$count more';
  }

  @override
  String get upcomingReleasesBadgeNew => 'NEW';

  @override
  String get upcomingReleasesOpenLibrarySeries => 'Open series in library';

  @override
  String get upcomingReleasesAsinCopied => 'Series ASIN copied';

  @override
  String get upcomingReleasesSetSeriesAsin => 'Set series ASIN';

  @override
  String get upcomingReleasesSetAsinInstructions =>
      'Find the series on audible.com and copy the page link - the ASIN is the 10-character code starting with B0 (like B08S2YN3YS). Pasting the whole link works too.';

  @override
  String get upcomingReleasesSetAsinHint => 'B0… or audible.com link';

  @override
  String get upcomingReleasesSetAsinSave => 'Save';

  @override
  String get upcomingReleasesSetAsinInvalid => 'No ASIN found in that text';

  @override
  String get upcomingReleasesSetAsinSaved => 'Series linked - scanning now';

  @override
  String upcomingReleasesRemoveTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Remove $count books',
      one: 'Remove book',
    );
    return '$_temp0';
  }

  @override
  String get upcomingReleasesRemoveThisScan => 'Remove from this scan';

  @override
  String get upcomingReleasesRemoveThisScanDesc =>
      'Can come back on a future scan';

  @override
  String get upcomingReleasesRemoveForever =>
      'Remove from this and future scans';

  @override
  String get upcomingReleasesRemoveForeverDesc =>
      'Goes to the removed list, restore any time';

  @override
  String get upcomingReleasesRemovedForeverToast =>
      'Removed - won\'t show on future scans';

  @override
  String get upcomingReleasesRemovedBooksTitle => 'Removed books';

  @override
  String upcomingReleasesRemovedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count books',
      one: '1 book',
    );
    return '$_temp0';
  }

  @override
  String get upcomingReleasesRemovedNone => 'No removed books';

  @override
  String get upcomingReleasesRestore => 'Restore';

  @override
  String get upcomingReleasesRestoredToast => 'Restored';

  @override
  String get upcomingReleasesRestoredNextScan =>
      'Restored - it will show after the next scan';

  @override
  String upcomingReleasesSelectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count selected',
      one: '1 selected',
    );
    return '$_temp0';
  }

  @override
  String get upcomingReleasesBulkRequest => 'Request';

  @override
  String get upcomingReleasesBulkRemove => 'Remove';

  @override
  String upcomingReleasesBulkRemoved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count removed',
      one: '1 removed',
    );
    return '$_temp0';
  }

  @override
  String upcomingReleasesBulkRequestDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count requests sent',
      one: '1 request sent',
    );
    return '$_temp0';
  }

  @override
  String upcomingReleasesBulkRequestSkipped(int count) {
    return '$count skipped';
  }

  @override
  String upcomingReleasesBulkScanned(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count series rescanned',
      one: '1 series rescanned',
    );
    return '$_temp0';
  }

  @override
  String upcomingReleasesBulkScanFound(int count) {
    return '$count with new books';
  }

  @override
  String get seriesExcludeFromScan => 'Exclude from series scan';

  @override
  String get seriesIncludeInScan => 'Include in series scan';

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
  String get librarySortFilterUpcomingReleases => 'Kommende Veröffentlichungen';

  @override
  String get librarySortFilterUpcomingReleasesSubtitle =>
      'Audible nach neuen Veröffentlichungen in deinen Serien durchsuchen';

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
      'Restzeit und Kapitelzeiten passen sich automatisch deiner Wiedergabegeschwindigkeit an. Hörst du mit 1,5x? Die angezeigte Zeit zeigt, wie lange es tatsächlich dauert.';

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
      'Tippe auf dem Absorbing-Bildschirm auf den Flugzeug-Button, um in den Offline-Modus zu wechseln. Das stoppt die Synchronisierung, spart Daten und zeigt nur deine heruntergeladenen Bücher. Ideal für Flüge oder schlechten Empfang.';

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
  String get tipsSheetTranscribeBookmarkTitle => 'Transcribe Bookmarks';

  @override
  String get tipsSheetTranscribeBookmarkDesc =>
      'Turn the audio at any bookmark into text, fully on your device. Enable it in Settings under Advanced > Transcription and download a model, then tap Transcribe on a bookmark - the text lands in its note, ready to fix up or share.';

  @override
  String get tipsSheetFindBetweenFormatsTitle =>
      'Jump Between Audiobook and Ebook';

  @override
  String get tipsSheetFindBetweenFormatsDesc =>
      'With transcription on and the book downloaded, pause and tap Find position in ebook on the player to open the ebook at the passage you just heard. In the reader, select some text and tap the headphones to start the audiobook right there.';

  @override
  String get tipsSheetShareQuoteTitle => 'Share Quotes';

  @override
  String get tipsSheetShareQuoteDesc =>
      'Share an ebook highlight or a bookmark note as an image with the quote over the book cover. Look for the share option on highlights and in the bookmark sheet.';

  @override
  String get tipsSheetClipExportTitle => 'Export Audio Clips';

  @override
  String get tipsSheetClipExportDesc =>
      'Open a bookmark and tap Export clip to trim and save a short audio snippet of the book, cover art included - great for sharing a favorite scene.';

  @override
  String get tipsSheetAllHighlightsTitle => 'All Highlights in One Place';

  @override
  String get tipsSheetAllHighlightsDesc =>
      'The All Bookmarks page has a Highlights tab collecting every ebook highlight from every book. Tap one to share it or jump back into the book.';

  @override
  String get tipsSheetVolumeKeyPagesTitle => 'Volume-Key Page Turns';

  @override
  String get tipsSheetVolumeKeyPagesDesc =>
      'Turn ebook pages with the volume keys. Enable it in the reader\'s settings - normal or mirrored direction, and it can stay on even while audio is playing.';

  @override
  String get tipsSheetSettingsSyncTitle => 'Settings Sync';

  @override
  String get tipsSheetSettingsSyncDesc =>
      'Keep your settings, per-book speeds and reader preferences in step across devices through your own WebDAV server. Set it up in Settings under Backup and sync.';

  @override
  String get tipsSheetNavLongPressTitle => 'Long-Press the Bottom Tabs';

  @override
  String get tipsSheetNavLongPressDesc =>
      'Hold the Home tab to switch libraries from any page. Hold the Library tab to jump straight into search.';

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
    return 'New $showTitle episode downloaded';
  }

  @override
  String get statsWeekStartsOn => 'Week starts on';

  @override
  String get episodeListNewEpisodePosition => 'Position neuer Folgen';

  @override
  String get episodeListPositionTop => 'Anfang der Warteschlange';

  @override
  String get episodeListPositionSecond => 'Zweite in der Warteschlange';

  @override
  String get episodeListPositionEnd => 'Ende der Warteschlange';

  @override
  String get episodeListPositionNone => 'Don\'t add to queue';

  @override
  String get episodeListPositionNoneDesc => 'Still notified and downloaded';

  @override
  String sleepRewindUndoNote(int minutes) {
    return 'Hit play within $minutes minutes and the rewind is undone';
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
  String get androidAutoCatBooks => 'Bücher';

  @override
  String get androidAutoCatSeries => 'Serien';

  @override
  String get androidAutoCatAuthors => 'Autoren';

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
  String get chapterShiftBySeconds => 'Verschieben um (Sekunden)';

  @override
  String get chapterShiftHint =>
      'Verschiebt jedes entsperrte Kapitel. Verwende einen negativen Wert, um sie früher zu verschieben.';

  @override
  String get chapterBack1Second => '1 Sekunde zurück';

  @override
  String get chapterForward1Second => '1 Sekunde vorwärts';

  @override
  String get chapterTitleHint => 'Kapitelname';

  @override
  String get chapterStopPreview => 'Vorschau stoppen';

  @override
  String get chapterPreviewFromHere => 'Vorschau ab hier';

  @override
  String get chapterScrubHint => 'Spule an die exakte Stelle, lege dann fest';

  @override
  String chapterStartAt(String time) {
    return 'Beginne bei $time';
  }

  @override
  String get chapterSetStartHere => 'Beginn auf hier festlegen';

  @override
  String get chapterMore => 'Mehr';

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
  String get readerFormatUnsupported =>
      'Dieses eBook-Format kann noch nicht im Reader geöffnet werden';

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
  String get readerSideMargins => 'Seitenrand';

  @override
  String get readerTopBottom => 'Oben & Unten';

  @override
  String get readerPageLayout => 'Seitenlayout';

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
  String get readerVolumeNavWhilePlaying =>
      'Selbst während Audio abgespielt wird';

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
  String get readerNoBookmarks => 'Noch keine Lesezeichen';

  @override
  String get readerBookmarkDefault => 'Lesezeichen';

  @override
  String get readerNoteTitle => 'Notiz';

  @override
  String get readerNoteHint => 'Notiz hinzufügen...';

  @override
  String get backupAndSync => 'Backup and sync';

  @override
  String get backupAndSyncSubtitle =>
      'Save a backup file, or keep settings in step across devices';

  @override
  String get syncSettingsExperimental => 'Experimental';

  @override
  String get syncSettingsExperimentalBody =>
      'Sync is new and still being worked on. If two devices change things while they are apart, one side can lose its changes. Keep a backup file as your safe copy.';

  @override
  String get syncSettingsNeedServer => 'Need a server?';

  @override
  String get syncSettingsNeedServerSub =>
      'Any WebDAV server works. Nextcloud is a free self-hosted one.';

  @override
  String get syncSettingsConnection => 'Connection';

  @override
  String get syncSettingsConnectionNotSet => 'Not set up yet';

  @override
  String get syncSettingsBackupFile => 'Backup file';

  @override
  String get syncSettingsBackupFilePlain =>
      'Save everything to a file you keep.';

  @override
  String get syncSettingsBackupFileWithSync =>
      'Save everything to a file you keep. Include login info and restoring it on another phone turns sync on there too.';

  @override
  String get syncSettingsStatusOff => 'Not syncing';

  @override
  String get syncSettingsStatusProblem => 'Could not reach your server';

  @override
  String get syncSettings => 'Sync settings between devices';

  @override
  String get syncSettingsExtras => 'Also sync';

  @override
  String get syncSettingsIncludeRmab => 'ReadMeABook settings';

  @override
  String get syncSettingsIncludeRmabSub =>
      'Puts your ReadMeABook API token in the synced file';

  @override
  String get syncSettingsSubtitle =>
      'Keep your settings in step through your own WebDAV server';

  @override
  String get syncSettingsEnable => 'Sync settings';

  @override
  String get syncSettingsServerUrl => 'WebDAV folder URL';

  @override
  String get syncSettingsServerUrlHint =>
      'https://cloud.example.com/remote.php/dav/files/you/Absorb';

  @override
  String get syncSettingsUsername => 'Username';

  @override
  String get syncSettingsPassword => 'Password';

  @override
  String get syncSettingsHeaders => 'Custom headers (optional)';

  @override
  String get syncSettingsHeadersHint =>
      'One per line, like CF-Access-Client-Id: abc123';

  @override
  String get syncSettingsTest => 'Test connection';

  @override
  String get syncSettingsHoldToUpload => 'Hold to upload now';

  @override
  String get syncSettingsUploadNow => 'Upload now';

  @override
  String get syncSettingsDownloadNow => 'Download now';

  @override
  String get syncSettingsOk => 'Connected';

  @override
  String get syncSettingsNoRemote => 'Connected - nothing synced yet';

  @override
  String get syncSettingsAuthFailed => 'Wrong username or password';

  @override
  String get syncSettingsNetworkError => 'Could not reach that address';

  @override
  String get syncSettingsNotConfigured =>
      'Fill in the address, username and password first';

  @override
  String get syncSettingsTooLarge => 'Your settings are too big to sync';

  @override
  String get syncSettingsUploaded => 'Settings uploaded';

  @override
  String get syncSettingsApplied => 'Settings updated from your other device';

  @override
  String syncSettingsAppliedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count settings updated from your other device',
      one: '1 setting updated from your other device',
    );
    return '$_temp0';
  }

  @override
  String get syncSettingsUpToDate => 'Already up to date';

  @override
  String syncSettingsLastSynced(String when) {
    return 'Last synced $when';
  }

  @override
  String get syncSettingsNever => 'Not synced yet';

  @override
  String navHoldPickTitle(String tab) {
    return 'Holding $tab will...';
  }

  @override
  String get navHoldPickBody =>
      'Choose what a long press on this tab does. You can change it later in Settings.';

  @override
  String get navHoldSettingTitle => 'Tab hold shortcuts';

  @override
  String get navHoldSettingSubtitle => 'What holding each tab does';

  @override
  String get navHoldAskNextTime => 'Ask next time';

  @override
  String get navHoldNothing => 'Nothing';

  @override
  String get navHoldPlayPause => 'Play / pause';

  @override
  String get navHoldOfflineMode => 'Offline mode';

  @override
  String get navHoldOfflineOn => 'Offline mode on';

  @override
  String get navHoldOfflineOff => 'Offline mode off';

  @override
  String get navHoldMenu => 'Always show menu';

  @override
  String get navHoldStop => 'Stop playback';

  @override
  String get navHoldRmabSearch => 'ReadMeABook search';

  @override
  String get navHoldRmabRequests => 'My book requests';

  @override
  String get navHoldRmabWeb => 'ReadMeABook site';

  @override
  String get navHoldAdd => 'Add';

  @override
  String get navHoldMoveLeft => 'Move left';

  @override
  String get navHoldMoveRight => 'Move right';

  @override
  String get navHoldRemoveFromMenu => 'Remove from menu';

  @override
  String get navHoldEditHint => 'Hold an item to move or remove it';

  @override
  String get navHoldResetMenu => 'Reset the hold menu items';

  @override
  String get navHoldMenuReset => 'Menu items reset';

  @override
  String get bookStatsAction => 'Listening stats';

  @override
  String get bookStatsYou => 'You';

  @override
  String get bookStatsEveryone => 'Everyone';

  @override
  String get bookStatsListened => 'Time listened';

  @override
  String get bookStatsSessions => 'Sessions';

  @override
  String get bookStatsFirst => 'First listened';

  @override
  String get bookStatsLast => 'Last listened';

  @override
  String get bookStatsListeners => 'People who started it';

  @override
  String get bookStatsFinishedCount => 'People who finished it';

  @override
  String get bookStatsTotalTime => 'Time listened by everyone';

  @override
  String get bookStatsNobody => 'Nobody has started this yet';

  @override
  String get bookStatsScanning =>
      'Scanning through sessions, this could take a while...';

  @override
  String bookStatsScanningCount(int done, int total) {
    return 'Scanning through sessions, $done of $total people...';
  }

  @override
  String bookStatsLastChecked(String when) {
    return 'Checked $when';
  }

  @override
  String get navHoldServerScan => 'Server scan';

  @override
  String get navHoldScanAll => 'Scan all libraries';

  @override
  String navHoldScanLibrary(String name) {
    return 'Scan $name';
  }

  @override
  String get navHoldScanStarted => 'Scan started';

  @override
  String get navHoldScanFailed => 'Could not start the scan';

  @override
  String get navHoldAdminLogs => 'Server logs';

  @override
  String navHoldAdminPage(String page) {
    return 'Admin: $page';
  }

  @override
  String get navHoldNothingPlaying => 'Nothing to play yet';

  @override
  String get navHoldReadBook => 'Read current book';

  @override
  String get navHoldBookDetails => 'Current book details';

  @override
  String get syncSourceTitle => 'Which copy should sync keep?';

  @override
  String get syncSourceBody =>
      'This backup turned settings sync on. Use the server\'s last sync, or make this backup the source of truth? Choosing the backup replaces the copy on the server for all your synced devices.';

  @override
  String get syncSourceUseServer => 'Server\'s last sync';

  @override
  String get syncSourceUseBackup => 'This backup';

  @override
  String get syncSettingsWhatTravels =>
      'Your preferences, per-book speeds, home layout, notes and ebook highlights travel. Logins, download folders and anything not yet sent to your server stay on this device.';

  @override
  String get syncSettingsDownloadWarnTitle =>
      'Replace this device\'s settings?';

  @override
  String get syncSettingsDownloadWarnBody =>
      'The synced copy will overwrite the settings on this device.';

  @override
  String get syncSettingsDownloadWarnConfirm => 'Replace';

  @override
  String get readerCopied => 'In Zwischenablage kopiert';

  @override
  String get readerTooltipCopy => 'Kopieren';

  @override
  String get readerTooltipSearch => 'Suchen';

  @override
  String get readerTooltipDefine => 'Definieren';

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
  String get transcriptionTitle => 'Transcription';

  @override
  String get transcriptionAdvancedSubtitle =>
      'For transcribing bookmarks and finding your spot between audiobook and ebook';

  @override
  String get transcriptionEnable => 'Enable transcription';

  @override
  String get transcriptionEnableSubtitle =>
      'Adds Transcribe to bookmarks, Find position in ebook to the player, and Find in audiobook to the reader';

  @override
  String get transcriptionDisclaimer =>
      'Runs entirely on your device, nothing is sent anywhere. It uses extra battery and processing while it works, and only downloaded books can be transcribed.';

  @override
  String get transcriptionNeedModelHint =>
      'Download a model below to start transcribing.';

  @override
  String get transcriptionModelSection => 'Models';

  @override
  String get transcriptionModelTiny => 'Tiny';

  @override
  String get transcriptionModelTinyDesc =>
      'Quickest, less accurate. About 31 MB.';

  @override
  String get transcriptionModelBase => 'Base';

  @override
  String get transcriptionModelBaseDesc => 'A good middle ground. About 57 MB.';

  @override
  String get transcriptionModelSmall => 'Small';

  @override
  String get transcriptionModelSmallDesc =>
      'Slower but most accurate - best on a high-end phone. About 182 MB.';

  @override
  String get transcriptionAutoHint =>
      'With more than one downloaded, each job picks between them. Books with an ebook get the quickest one, since the exact words come from the ebook anyway. Bookmarks on books without one get the most accurate.';

  @override
  String get transcriptionDownload => 'Download';

  @override
  String get transcriptionDownloadFailed =>
      'Download failed. Check your connection and try again.';

  @override
  String get transcribe => 'Transcribe';

  @override
  String get transcribing => 'Transcribing...';

  @override
  String get transcriptionResultTitle => 'Transcript';

  @override
  String get transcriptionSaveToNote => 'Save to note';

  @override
  String get transcriptionSavedToNote => 'Saved to bookmark note';

  @override
  String get transcriptionDisabledHint =>
      'Turn on bookmark transcription in Settings, under Advanced.';

  @override
  String get transcriptionNoModelDownloaded =>
      'Download a transcription model in Settings first.';

  @override
  String get transcriptionNotDownloadedBook =>
      'Download this book first to transcribe its bookmarks.';

  @override
  String get transcriptionNoMetadataMsg =>
      'Can\'t locate this spot in the download. Try re-downloading the book.';

  @override
  String get transcriptionBusyMsg =>
      'Already transcribing something. Give it a moment.';

  @override
  String get transcriptionEmptyMsg => 'No speech was found at this spot.';

  @override
  String get transcriptionFailedMsg =>
      'Couldn\'t transcribe this spot. Please try again.';

  @override
  String get transcriptionPlaySnippet => 'Listen';

  @override
  String get transcriptionPauseSnippet => 'Pause';

  @override
  String get transcriptionIntroBody =>
      'This listens to the chosen amount of audio, starting just before the bookmark, and turns it into text on your device. Longer clips take longer, and transcription isn\'t 100% accurate. The text is saved into the bookmark\'s note when it\'s done, ready to fix up or share.';

  @override
  String get transcriptionUseEbookText =>
      'Use the ebook\'s exact text when it can be matched';

  @override
  String get findInEbook => 'Find in ebook';

  @override
  String get findInEbookSearching => 'Finding this spot in the ebook...';

  @override
  String get findInEbookNotFound => 'Couldn\'t find this spot in the ebook.';

  @override
  String get findInEbookNeedsEpub => 'Find in ebook needs an EPUB ebook.';

  @override
  String get findInEbookNoEbook => 'This book doesn\'t have an ebook.';

  @override
  String get findInAudiobook => 'Find in audiobook';

  @override
  String get findInAudiobookSearching =>
      'Finding this spot in the audiobook...';

  @override
  String get findInAudiobookNotFound =>
      'Couldn\'t find this spot in the audiobook.';

  @override
  String get transcriptionWhisperInfo =>
      'Transcription is powered by Whisper, an open speech recognition model that listens to the narration and writes out the words - all on this device.';

  @override
  String get transcriptionWhisperLearnMore => 'Learn more about Whisper';

  @override
  String get findInAudiobookIntroBody =>
      'This listens to the audiobook near where you\'re reading and matches it to this passage, all on your device. It can take up to a minute. If the spot can\'t be matched confidently, nothing moves.';

  @override
  String get findInAudiobookAfterLabel => 'When the spot is found';

  @override
  String get findInAudiobookStay => 'Keep reading';

  @override
  String get findInAudiobookGoPlayer => 'Open the player';

  @override
  String get findInAudiobookPlaying => 'Playing this passage in the audiobook';
}
