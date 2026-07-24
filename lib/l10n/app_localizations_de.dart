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
    return 'Sign in as $username?';
  }

  @override
  String get loginSignInToServer => 'Sign in to this server?';

  @override
  String loginSignedInAs(String username) {
    return 'Signed in as $username';
  }

  @override
  String get adminCreateSetupFile => 'Share sign-in';

  @override
  String adminSetupFileDescription(String username) {
    return 'Creates a private sign-in link for $username that only works in the Absorb app.';
  }

  @override
  String get adminSetupFileServerUrl => 'Server URL the new user will use';

  @override
  String get adminSetupFileNoteWithHeaders =>
      'A dedicated API key and your custom headers will be included so they can reach the server. Treat the link like a password.';

  @override
  String get adminSetupFileNote =>
      'A dedicated API key will be included. Treat the link like a password.';

  @override
  String get adminSetupFileCreate => 'Create link';

  @override
  String get adminSetupFileSaveTitle => 'Save setup file';

  @override
  String get adminSetupFileKeyError =>
      'Could not create an API key for this user';

  @override
  String adminSetupFileSaved(String username) {
    return 'Setup file for $username saved';
  }

  @override
  String adminSetupFileFailed(String error) {
    return 'Failed to create sign-in: $error';
  }

  @override
  String get setupLinkShareTitle => 'Share sign-in';

  @override
  String setupLinkShareDescription(String username) {
    return 'Send this private link or have them scan the QR code to sign in as $username.';
  }

  @override
  String setupLinkPrivateWarning(String username) {
    return 'Anyone with this link can sign in as $username. Treat it like a password.';
  }

  @override
  String get setupLinkShare => 'Share link';

  @override
  String get setupLinkCopy => 'Copy link';

  @override
  String get setupLinkCopied => 'Sign-in link copied';

  @override
  String get setupLinkSaveFile => 'Save setup file';

  @override
  String get setupLinkQrError =>
      'This setup link is too large for a QR code. Share the link instead.';

  @override
  String setupLinkShareSubject(String username) {
    return 'Absorb sign-in for $username';
  }

  @override
  String get setupLinkConfirmTitle => 'Sign in with this link?';

  @override
  String setupLinkConfirmBody(String server, String username) {
    return 'Sign in to $server as $username? Only continue if you trust who sent this link.';
  }

  @override
  String get setupLinkInvalid => 'This sign-in link is invalid or incomplete';

  @override
  String get setupLinkSigningIn => 'Checking sign-in link...';

  @override
  String get loginPasteLink => 'Paste login link';

  @override
  String get loginPasteLinkHelp =>
      'Paste the complete sign-in link you received. Treat it like a password.';

  @override
  String get loginFailed => 'Anmeldung fehlgeschlagen';

  @override
  String get loginSsoFailed => 'SSO-Anmeldung fehlgeschlagen oder abgebrochen';

  @override
  String get loginSsoAuthFailed =>
      'SSO-Authentifizierung fehlgeschlagen. Bitte versuche es erneut.';

  @override
  String get loginRestoreFromBackup => 'Aus Backup wiederherstellen';

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
  String get libraryNoUnfinishedBooks => 'No unfinished books';

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
      'No books are missing this metadata';

  @override
  String get libraryNoItemsMatchingFilter => 'No items match this filter';

  @override
  String libraryNoBooksInGenre(String genre) {
    return 'Keine Bücher in \"$genre\"';
  }

  @override
  String libraryNoBooksWithTag(String tag) {
    return 'No books tagged \"$tag\"';
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
  String get notFinished => 'Not Finished';

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
  String get noEbook => 'No eBook';

  @override
  String get hasSupplementaryEbook => 'Has Supplementary eBook';

  @override
  String get noSupplementaryEbook => 'No Supplementary eBook';

  @override
  String get noSeries => 'No Series';

  @override
  String get publishedDecade => 'Published Decade';

  @override
  String get tracks => 'Tracks';

  @override
  String get noTracks => 'No Tracks';

  @override
  String get singleTrack => 'Single Track';

  @override
  String get multipleTracks => 'Multiple Tracks';

  @override
  String get abridged => 'Abridged';

  @override
  String get issues => 'Issues';

  @override
  String get rssFeedOpen => 'RSS Feed Open';

  @override
  String get explicitContent => 'Explicit';

  @override
  String get missingMetadata => 'Missing Metadata';

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
  String get fileSize => 'File Size';

  @override
  String get lastUpdated => 'Last Updated';

  @override
  String get fileCreated => 'File Created';

  @override
  String get lastModified => 'Last Modified';

  @override
  String get authorFirstLast => 'Author (First Last)';

  @override
  String get authorLastFirst => 'Author (Last, First)';

  @override
  String get progressSort => 'Progress';

  @override
  String get dateStarted => 'Date Started';

  @override
  String get dateFinished => 'Date Finished';

  @override
  String get episodeCount => 'Episode Count';

  @override
  String get sequence => 'Series Sequence';

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
  String get statsRemoveFromYearTitle => 'Remove from this year';

  @override
  String statsRemoveFromYearWithDate(String date, String title) {
    return 'The finished date will still be $date on the server. This only removes \"$title\" from your Absorb books-this-year list.';
  }

  @override
  String statsRemoveFromYearNoDate(String title) {
    return 'The finished date stays on the server. This only removes \"$title\" from your Absorb books-this-year list.';
  }

  @override
  String get statsRemovedFromYear => 'Removed from this year';

  @override
  String get statsAddBackToYearTitle => 'Add back to this year';

  @override
  String statsAddBackToYearBody(String title) {
    return 'Add \"$title\" back to your Absorb books-this-year list?';
  }

  @override
  String get statsAddBack => 'Add back';

  @override
  String get statsAddedBackToYear => 'Added back to this year';

  @override
  String get statsHiddenFromYear => 'Hidden from this year';

  @override
  String get statsNothingHidden => 'Nothing hidden';

  @override
  String get settingsCustomizeStats => 'Customize stats';

  @override
  String get statsGoalTitle => 'Listening goal';

  @override
  String get statsGoalOff => 'Off';

  @override
  String get statsGoalDaily => 'Daily';

  @override
  String get statsGoalWeekly => 'Weekly';

  @override
  String get statsGoalMonthly => 'Monthly';

  @override
  String get statsGoalTarget => 'Target';

  @override
  String get statsGoalEnterTitle => 'Set target';

  @override
  String get statsGoalEnterTimeHint => 'Minutes or h:mm';

  @override
  String statsBooksShort(int count) {
    return '$count books';
  }

  @override
  String get statsBookChallengeTitle => 'Reading challenge';

  @override
  String get statsBookChallengeDesc => 'Books to finish this year';

  @override
  String get statsDailyGoal => 'Daily goal';

  @override
  String get statsWeeklyGoal => 'Weekly goal';

  @override
  String get statsMonthlyGoal => 'Monthly goal';

  @override
  String statsGoalProgress(String done, String target) {
    return '$done / $target';
  }

  @override
  String statsBookChallengeProgress(int done, int target) {
    return '$done of $target books';
  }

  @override
  String get statsGoalReached => 'Goal reached';

  @override
  String get statsChartTitle => 'Listening chart';

  @override
  String get statsChartBar => 'Bar';

  @override
  String get statsChartLine => 'Line';

  @override
  String get statsChartHeatmap => 'Heatmap';

  @override
  String get statsChartDays7 => '7 days';

  @override
  String get statsChartDays30 => '30 days';

  @override
  String get statsLast30Days => 'Last 30 days';

  @override
  String get statsThisYearTitle => 'This year';

  @override
  String get statsSectionsTitle => 'Sections';

  @override
  String get statsSectionTimePeriods => 'Time periods';

  @override
  String get statsHeatmapLess => 'Less';

  @override
  String get statsHeatmapMore => 'More';

  @override
  String get statsDayOfWeek => 'Average by day of week';

  @override
  String get statsTimeSavedLabel => 'Saved by speed';

  @override
  String statsTimeSavedSince(String date) {
    return 'since $date';
  }

  @override
  String get statsTimeSavedReset => 'Reset time saved';

  @override
  String get statsTimeSavedResetConfirm =>
      'Time saved will start counting again from today.';

  @override
  String get statsTimeSavedResetDone => 'Time saved reset';

  @override
  String statsOnPaceFor(int count) {
    return 'On pace for $count books';
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
  String get libraryTabEpisodes => 'Episodes';

  @override
  String get filterAllEpisodes => 'All';

  @override
  String get filterUnplayed => 'Unplayed';

  @override
  String get episodeFeedEmpty => 'No episodes match this filter';

  @override
  String get settingsPodcastTab => 'Podcasts tab';

  @override
  String get settingsPodcastTabDesc =>
      'Give one podcast library its own tab in the bottom bar';

  @override
  String get settingsPodcastTabLibrary => 'Podcasts tab library';

  @override
  String get settingsMergeImpliedByPodcastTab =>
      'Always on while the Podcasts tab is enabled';

  @override
  String get settingsEpisodeNotifs => 'New episode notifications';

  @override
  String get settingsEpisodeNotifsDesc =>
      'Check subscribed shows in the background';

  @override
  String get notifIntervalOff => 'Off';

  @override
  String notifIntervalMinutes(int n) {
    return 'Every $n minutes';
  }

  @override
  String get notifIntervalHour => 'Every hour';

  @override
  String notifIntervalHours(int n) {
    return 'Every $n hours';
  }

  @override
  String get settingsBatteryUnrestricted => 'Allow unrestricted battery use';

  @override
  String get settingsBatteryUnrestrictedDesc =>
      'Keeps the system from pausing background checks on some phones';

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
  String get colorSourceDynamic => 'Dynamic';

  @override
  String get colorSourceManual => 'Manual';

  @override
  String get colorSourceManualDescription =>
      'Use a fixed app color you choose below';

  @override
  String get colorSourceCustom => 'Custom';

  @override
  String get useColorEverywhereLabel => 'Use this color everywhere';

  @override
  String get useColorEverywhereSubtitle =>
      'Also color book detail pages and the player card with your set color instead of each book\'s cover';

  @override
  String get flatBackgroundLabel => 'Flat background';

  @override
  String get flatBackgroundSubtitle =>
      'Remove the background gradient. Pure black in dark mode for OLED screens.';

  @override
  String get backgroundIntensityLabel => 'Background intensity';

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
  String get progressTextSize => 'Progress text size';

  @override
  String get rectangleBookCoversOnSubtitle =>
      'Cover werden im 2:3-Buchformat angezeigt';

  @override
  String get rectangleBookCoversOffSubtitle => 'Cover sind quadratisch';

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
  String get queueModeCollection => 'Collection';

  @override
  String get queueModeInfoPlaylist => 'Playlist Queue';

  @override
  String get queueModeInfoPlaylistDesc =>
      'Plays items in order from a chosen playlist, skipping anything already finished. Stops at the end of the list.';

  @override
  String get queuePlaylistPickerTitle => 'Choose a playlist';

  @override
  String get queuePlaylistNone => 'Keine Wiedergabeliste ausgewählt';

  @override
  String queuePlaylistActiveLabel(String name) {
    return 'Wiedergabeliste: $name';
  }

  @override
  String get queueModePlaylistHint =>
      'Start a playlist queue by opening a playlist on the home page.';

  @override
  String get exit => 'Beenden';

  @override
  String upNext(String label) {
    return 'Als Nächstes: $label';
  }

  @override
  String get nothingUpNext => 'Nothing up next';

  @override
  String get showUpNextLabel => 'Show Up next on the absorbing page';

  @override
  String get openSeries => 'Open series';

  @override
  String get openPlaylist => 'Open playlist';

  @override
  String get openCollection => 'Open collection';

  @override
  String get playlistPlayAction => 'Play playlist';

  @override
  String get playlistAllFinished => 'Alle abgeschlossen';

  @override
  String get queueModeBooks => 'Bücher';

  @override
  String get queueModePodcasts => 'Podcasts';

  @override
  String get autoDownloadQueue => 'Auto-Download-Warteschlange';

  @override
  String autoDownloadQueueOnSubtitle(int count) {
    return 'Die nächsten $count Inhalte heruntergeladen halten';
  }

  @override
  String get autoDownloadQueueOffSubtitle => 'Aus - nur manuelle Downloads';

  @override
  String get sectionPlayback => 'Wiedergabe';

  @override
  String get sectionMediaControls => 'Media Controls';

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
  String get longSkipButtons => 'Long skip buttons';

  @override
  String get longSkipButtonsOnSubtitle =>
      'On - the player shows a second, bigger skip pair';

  @override
  String get longSkipButtonsOffSubtitle =>
      'Off - just the regular skip buttons';

  @override
  String get longSkipBack => 'Long skip back';

  @override
  String get longSkipForward => 'Long skip forward';

  @override
  String get coverShapeDefault => 'Default';

  @override
  String get coverShapeSquare => 'Square';

  @override
  String get coverShapeRectangle => 'Rectangle';

  @override
  String get coverShapeLabel => 'Cover shape';

  @override
  String currentLibrarySettingsTitle(String name) {
    return 'Current library: $name';
  }

  @override
  String get currentLibrarySkipOverride => 'Custom skip amounts';

  @override
  String get currentLibrarySkipOverrideOnSubtitle =>
      'On - this library uses its own skip amounts';

  @override
  String get currentLibrarySkipOverrideOffSubtitle =>
      'Off - this library uses the global skip amounts';

  @override
  String get currentLibrarySkipBack => 'Skip back';

  @override
  String get currentLibrarySkipForward => 'Skip forward';

  @override
  String get chapterProgressInNotification =>
      'Kapitelfortschritt in der Benachrichtigung';

  @override
  String get chapterProgressOnSubtitle =>
      'An - Sperrbildschirm zeigt Kapitelfortschritt';

  @override
  String get chapterProgressOffSubtitle =>
      'Aus - Sperrbildschirm zeigt Fortschritt des gesamten Buchs';

  @override
  String get chapterProgressInNotificationIos =>
      'Chapter progress on lock screen & CarPlay';

  @override
  String get chapterProgressOnSubtitleIos =>
      'On - lock screen & CarPlay show chapter progress';

  @override
  String get speedBookmarkInControls => 'Speed & bookmark in media controls';

  @override
  String get speedBookmarkOnSubtitle =>
      'On - notification shows speed & bookmark; chapter skip stays in Android Auto';

  @override
  String get speedBookmarkOffSubtitle =>
      'Off - notification shows chapter skip; speed & bookmark stay in Android Auto';

  @override
  String get lockSeekBar => 'Lock the seek bar';

  @override
  String get lockSeekBarOnSubtitle =>
      'On - the scrubber in the notification, lockscreen and car shows progress but can\'t be dragged';

  @override
  String get lockSeekBarOffSubtitle =>
      'Off - drag the scrubber in the notification, lockscreen and car to jump around';

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
  String get downloadOverWifiOnly => 'Nur über WLAN herunterladen';

  @override
  String get downloadOverWifiOnSubtitle =>
      'An - mobile Daten für Downloads blockiert';

  @override
  String get downloadOverWifiOffSubtitle =>
      'Aus - Downloads über jede Verbindung';

  @override
  String get autoDownloadOnWifi => 'Auto-Download im WLAN';

  @override
  String get autoDownloadOnWifiInfoTitle => 'Auto-Download im WLAN';

  @override
  String get autoDownloadOnWifiInfoContent =>
      'Wenn du ein Buch über WLAN streamst, wird das vollständige Buch automatisch im Hintergrund heruntergeladen. So hast du es offline verfügbar, ohne den Download manuell starten zu müssen.';

  @override
  String get autoDownloadOnWifiOnSubtitle =>
      'Bücher werden im Hintergrund heruntergeladen, wenn du im WLAN streamst';

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
      'Wenn aktiviert, werden heruntergeladene Bücher oder Episoden automatisch von deinem Gerät gelöscht, nachdem du sie zu Ende gehört hast. Das hilft, Speicherplatz freizugeben, während du dich durch deine Bibliothek arbeitest.';

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
  String get editServerAddressTitle => 'Edit Server Address';

  @override
  String editServerAddressSubtitle(String username) {
    return 'Update the address for $username. Use this if your server\'s address changed - it\'s still the same server, just a new URL. Your stats and downloads are kept.';
  }

  @override
  String get editServerAddressField => 'Server Address';

  @override
  String get editServerAddressUpdated => 'Server address updated';

  @override
  String get editServerAddressFailed => 'Couldn\'t update server address';

  @override
  String get editServerAddressAction => 'Edit server address';

  @override
  String get removeAccountAction => 'Remove account';

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
          '$count downloads are in an old custom folder that can no longer be opened. Re-download them or dismiss this notice.',
      one:
          '1 download is in an old custom folder that can no longer be opened. Re-download it or dismiss this notice.',
    );
    return '$_temp0';
  }

  @override
  String get redownload => 'Re-download';

  @override
  String get redownloadStarted => 'Re-downloading';

  @override
  String get dismiss => 'Dismiss';

  @override
  String get tipsAndHiddenFeatures => 'Tipps & versteckte Funktionen';

  @override
  String get tipsSubtitle => 'Hol das Beste aus Absorb heraus';

  @override
  String get adminTitle => 'Server-Admin';

  @override
  String get adminTasksTitle => 'Server activity';

  @override
  String adminTasksRunning(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tasks running',
      one: '1 task running',
    );
    return '$_temp0';
  }

  @override
  String get adminTasksRecent => 'Recent server activity';

  @override
  String get adminTasksEmpty => 'No server tasks are running';

  @override
  String adminTaskScanSummary(int added, int updated, int missing) {
    return '$added added - $updated updated - $missing missing';
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
  String get rmabConfigTitle => 'Connect ReadMeABook';

  @override
  String get rmabConfigExplainerAdmin =>
      'ReadMeABook is a self-hosted service for requesting audiobooks. Generate an API token in RMAB under Admin Dashboard > Settings > API, then paste the server URL and token below. Absorb doesn\'t host or download any content, it just sends requests to your server.';

  @override
  String get rmabConfigExplainerUser =>
      'ReadMeABook is a self-hosted service for requesting audiobooks. Ask your server admin for the RMAB URL and an API token. Absorb doesn\'t host or download any content, it just sends requests to your server.';

  @override
  String get rmabConfigLearnMore => 'Learn more about ReadMeABook';

  @override
  String get rmabConfigBaseUrlLabel => 'RMAB server URL';

  @override
  String get rmabConfigBaseUrlHint => 'https://rmab.example.com';

  @override
  String get rmabConfigTokenLabel => 'API-Token';

  @override
  String get rmabConfigTokenHint => 'rmab_...';

  @override
  String get rmabConfigLegacyUrlLabel => 'Web UI login URL (optional)';

  @override
  String get rmabConfigLegacyUrlHint => 'https://rmab.example.com/?token=...';

  @override
  String get rmabConfigLegacyUrlHelp =>
      'Paste your auto-login URL so \'Open in browser view\' lands you signed in. Leave blank to use a regular login.';

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
      'This token isn\'t allowed for that action';

  @override
  String get rmabConfigErrorNetwork => 'Couldn\'t reach RMAB. Check the URL.';

  @override
  String get rmabConfigErrorGeneric =>
      'Verbindung konnte nicht hergestellt werden';

  @override
  String get rmabConfigSavedSnackbar => 'ReadMeABook connected';

  @override
  String get rmabConfigDisconnectedSnackbar => 'ReadMeABook disconnected';

  @override
  String get rmabRequestCta => 'Request via ReadMeABook';

  @override
  String get rmabSearchHeader => 'Request via ReadMeABook';

  @override
  String get rmabSearchHint => 'Nach Titel oder Autor suchen';

  @override
  String get rmabSearchEmpty => 'No matches on your ReadMeABook server';

  @override
  String get rmabSearchError => 'Couldn\'t search ReadMeABook';

  @override
  String get rmabSearchPrompt => 'Type a title or author to search';

  @override
  String get rmabSearchFooterPrompt => 'Looking for something else?';

  @override
  String rmabSearchFooterCta(String query) {
    return 'Search ReadMeABook for \"$query\"';
  }

  @override
  String get rmabBookDetailExplainer =>
      'This request will be sent through your ReadMeABook server. The admin will review and process it. You can track it under My Requests on the ReadMeABook tile.';

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
  String get rmabRequestErrorDuplicate => 'You\'ve already requested this';

  @override
  String get rmabRequestErrorValidation => 'Couldn\'t send the request';

  @override
  String get rmabRequestErrorUserNotFound =>
      'Token user no longer exists. Reconnect ReadMeABook.';

  @override
  String get rmabRequestErrorIgnored => 'This book is on your ignore list';

  @override
  String get rmabRequestErrorGeneric => 'Couldn\'t send the request';

  @override
  String get rmabRequestErrorTokenRejected =>
      'Token rejected by server. Reconnect ReadMeABook.';

  @override
  String get rmabMyRequestsTab => 'Meine Anfragen';

  @override
  String get rmabSetupTab => 'Einrichtung';

  @override
  String get rmabMyRequestsEmpty => 'You haven\'t requested any books yet';

  @override
  String get rmabMyRequestsError => 'Couldn\'t load requests';

  @override
  String get rmabMyRequestsRefresh => 'Aktualisieren';

  @override
  String get rmabRequestDetailTitle => 'Request details';

  @override
  String get rmabRequestDetailStatus => 'Status';

  @override
  String get rmabRequestDetailRequestedOn => 'Requested on';

  @override
  String get rmabRequestDetailCompletedOn => 'Completed on';

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
  String get removeFromContinueListening => 'Remove from Continue Listening';

  @override
  String get removedFromContinueListening => 'Removed from Continue Listening';

  @override
  String get removeSeriesFromContinueSeries => 'Remove from Continue Series';

  @override
  String get removedSeriesFromContinueSeries => 'Removed from Continue Series';

  @override
  String get couldNotUpdate => 'Could not update, try again';

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
  String get startM4bEncode => 'Start M4B Encode';

  @override
  String get encodeStarted => 'M4B Encodierung gestartet';

  @override
  String get encodeFailed => 'Failed to start encode';

  @override
  String get encodeFinished => 'M4B encode finished';

  @override
  String get currentlyLabel => 'Momentan:';

  @override
  String encodeOutputPathNote(String path) {
    return 'Finished M4B will be put into your audiobook folder at: $path/';
  }

  @override
  String encodeBackupNote(String itemId) {
    return 'A backup of your original audio files will be stored in: /metadata/cache/items/$itemId/. Make sure to periodically purge items cache.';
  }

  @override
  String get encodeTimeNote => 'Encoding can take up to 30 minutes.';

  @override
  String get encodeRescanNote =>
      'If you have the watcher disabled you will need to re-scan this audiobook afterwards.';

  @override
  String get aboutSection => 'Info';

  @override
  String chaptersCount(int count) {
    return 'Kapitel ($count)';
  }

  @override
  String get chapters => 'Kapitel';

  @override
  String get noChaptersBook => 'This book has no chapters';

  @override
  String get noChaptersPodcast => 'This podcast has no chapters';

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
  String get historyLocalTab => 'History';

  @override
  String get historyServerTab => 'Sessions';

  @override
  String get historyNoServerSessions => 'No server sessions for this item yet';

  @override
  String get historyServerLoadFailed => 'Could not load server sessions';

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
  String get quickMatchNoUpdates => 'No updates necessary';

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
  String get deleteCollectionFailed => 'Couldn\'t delete the collection';

  @override
  String get deletePermissionRequired =>
      'Delete permission required. Ask the root admin to grant you the delete permission.';

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
  String get saved => 'Gespeichert';

  @override
  String get selectLibrary => 'Bibliothek auswählen';

  @override
  String get switchLibraryTooltip => 'Bibliothek wechseln';

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
  String get cardBackground => 'Card background';

  @override
  String get cardBackgroundBlurred => 'Blurred';

  @override
  String get cardBackgroundGradient => 'Gradient';

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
      'Install permission denied. Enable \"Install unknown apps\" for Absorb in system settings.';

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
  String bookmarkAtPosition(String position) {
    return 'Lesezeichen bei $position';
  }

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
      other: '$count missing or invalid items',
      one: '1 missing or invalid item',
    );
    return '$_temp0';
  }

  @override
  String get adminLibraryReview => 'Review';

  @override
  String get adminMissingTitle => 'Missing Items';

  @override
  String adminMissingSubtitle(String library) {
    return 'Entries in $library whose files are missing or unreadable';
  }

  @override
  String get adminMissingNone => 'No missing or invalid items';

  @override
  String get adminMissingBadge => 'Missing';

  @override
  String get adminInvalidBadge => 'Invalid';

  @override
  String get adminMissingDeleteTitle => 'Remove entry';

  @override
  String adminMissingDeleteOneContent(String title) {
    return 'Remove \"$title\" from Audiobookshelf? The files on disk are not deleted.';
  }

  @override
  String adminMissingDeleteManyContent(int count) {
    return 'Remove $count entries from Audiobookshelf? The files on disk are not deleted.';
  }

  @override
  String adminMissingDeleteCount(int count) {
    return 'Delete $count';
  }

  @override
  String adminMissingRemovedOne(String title) {
    return 'Removed $title';
  }

  @override
  String adminMissingRemovedMany(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Removed $count entries',
      one: 'Removed 1 entry',
    );
    return '$_temp0';
  }

  @override
  String get adminMissingDeleteFailed => 'Failed to delete entry';

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
  String get adminUsersUnlinkOpenId => 'Unlink OpenID';

  @override
  String get adminUsersUnlinkOpenIdTitle => 'Unlink OpenID?';

  @override
  String adminUsersUnlinkOpenIdContent(String name) {
    return 'Remove the OpenID connection for $name? They\'ll need to sign in with OpenID again to re-link.';
  }

  @override
  String get adminUsersOpenIdUnlinked => 'OpenID unlinked';

  @override
  String get adminUsersFailedUnlinkOpenId => 'Failed to unlink OpenID';

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
    return 'Search iTunes for \"$query\"';
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
  String get adminPodcastsSelectAll => 'Select all';

  @override
  String get adminPodcastsSelectAllNew => 'New only';

  @override
  String get adminPodcastsSortNewestFirst => 'Newest first';

  @override
  String get adminPodcastsSortOldestFirst => 'Oldest first';

  @override
  String get adminPodcastsEditInfo => 'Edit Info';

  @override
  String get adminPodcastsEditInfoSubtitle =>
      'Change title, description, cover and more';

  @override
  String get adminPodcastsEditTitle => 'Edit Podcast';

  @override
  String get adminPodcastsReleaseDate => 'Release date';

  @override
  String get adminPodcastsExplicit => 'Explicit';

  @override
  String get adminPodcastsExplicitSubtitle => 'Mark this podcast as explicit';

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
  String get episodeListShowSettings => 'Show Settings';

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
      other: '$count unfinished',
      one: '1 unfinished',
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
  String get sessionEditTitle => 'Edit session';

  @override
  String get sessionDayLabel => 'Day';

  @override
  String get sessionEndPosition => 'Ending position';

  @override
  String get sessionEndPositionHint =>
      'Changing this may also update your current progress.';

  @override
  String get statsViewSessions => 'View sessions';

  @override
  String statsSessionsForDate(String date) {
    return 'Sessions for $date';
  }

  @override
  String get statsNoSessionsForDate =>
      'No listening sessions found for this day';

  @override
  String get statsSearchSessions => 'Search sessions';

  @override
  String get statsNoSessionSearchResults => 'No sessions match your search';

  @override
  String get statsSessionsLoadFailed => 'Could not load sessions for this day';

  @override
  String get sessionDeleteConfirmTitle => 'Delete session?';

  @override
  String get sessionDeleteConfirmBody =>
      'This removes the session and lowers your listening totals by its time. It cannot be undone.';

  @override
  String get sessionSaved => 'Session updated';

  @override
  String get sessionDeleted => 'Session deleted';

  @override
  String get sessionSaveFailed => 'Could not save changes';

  @override
  String get sessionDeleteFailed => 'Could not delete this session';

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
  String get upcomingReleasesRemoveFromList => 'Remove from list';

  @override
  String get upcomingReleasesRemovedFromList => 'Removed from list';

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
  String get audibleSeriesAddToUpcoming => 'Add to upcoming releases';

  @override
  String get audibleSeriesAddedToUpcoming => 'Added to upcoming releases';

  @override
  String get audibleSeriesAlreadyInUpcoming => 'Already on the upcoming page';

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
      'On the Series tab, tap the tab again to open its sort and filter sheet, then choose Upcoming Releases to see new and upcoming books across your series, sorted by release date.';

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
      'Open a series and use the overflow menu (the three dots) to pull the full series list from Audible, including missing entries and books you haven\'t started.';

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
    return '$showTitle added to the top of your queue';
  }

  @override
  String lpSubscribedEpisodeAddedSecond(String showTitle) {
    return '$showTitle added 2nd in your queue';
  }

  @override
  String lpSubscribedEpisodeAddedEnd(String showTitle) {
    return '$showTitle added to the end of your queue';
  }

  @override
  String get episodeListNewEpisodePosition => 'New episode position';

  @override
  String get episodeListPositionTop => 'Top of queue';

  @override
  String get episodeListPositionSecond => 'Second in queue';

  @override
  String get episodeListPositionEnd => 'End of queue';

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
  String get authorMatched => 'Author updated from match';

  @override
  String get authorNoMatchFound => 'Kein Treffer gefunden';

  @override
  String authorMergedInto(String name) {
    return 'Zusammengeführt in $name';
  }

  @override
  String get authorQuickMatchHint =>
      'Pull name, ASIN, description and image from Audible for the chosen region.';

  @override
  String get region => 'Region';

  @override
  String get editTabDetails => 'Details';

  @override
  String get editTabCover => 'Cover';

  @override
  String get editTabMatch => 'Match';

  @override
  String get editTabEmbed => 'Embed';

  @override
  String get chapterEditorTitle => 'Edit Chapters';

  @override
  String get chapterNotConnected => 'Not connected to a server';

  @override
  String get chapterErrorFirstNotZero => 'First chapter must start at 0:00';

  @override
  String get chapterErrorStartAfterPrevious =>
      'Start must come after the previous chapter';

  @override
  String get chapterErrorStartBeforeEnd => 'Start must be before the book ends';

  @override
  String get chapterErrorTitleRequired => 'Title required';

  @override
  String get chapterEditStartTitle => 'Edit start time';

  @override
  String get chapterTimeHintSeconds => 'Seconds';

  @override
  String get chapterTimeHintFull => 'HH:MM:SS or seconds';

  @override
  String get chapterInvalidTime => 'Invalid time';

  @override
  String get chapterLocked => 'Chapter is locked';

  @override
  String get chapterAllLocked => 'All chapters are locked';

  @override
  String chapterTrackTitle(int number) {
    return 'Track $number';
  }

  @override
  String get chapterNoAudioForPosition => 'No audio for this position';

  @override
  String get chapterCouldNotPlayPreview => 'Could not play preview';

  @override
  String chapterStartSetTo(String time) {
    return 'Start set to $time';
  }

  @override
  String get chapterAddNumberedTitle => 'Add numbered chapters';

  @override
  String chapterNextPreview(String first, String second) {
    return 'Next: \"$first\", \"$second\", ...';
  }

  @override
  String get chapterHowMany => 'How many chapters';

  @override
  String get add => 'Add';

  @override
  String get chapterCountRange => 'Enter a count between 1 and 150';

  @override
  String get chapterTitlesUpdated => 'Chapter titles updated';

  @override
  String get chaptersApplied => 'Chapters applied';

  @override
  String get chapterDiscardTitle => 'Discard changes?';

  @override
  String get chapterDiscardMessage => 'Revert to the saved chapters.';

  @override
  String get chapterRemoveAllTitle => 'Remove all chapters?';

  @override
  String get chapterRemoveAllMessage =>
      'This removes every chapter from this book.';

  @override
  String get chapterAllRemoved => 'All chapters removed';

  @override
  String get chapterFixHighlighted => 'Fix the highlighted chapters first';

  @override
  String get chaptersUpdated => 'Chapters updated';

  @override
  String get ok => 'OK';

  @override
  String get chapterSaveButton => 'Save chapters';

  @override
  String get chapterAddHint => 'Kapitel hinzufügen (z.B. \"Kapitel 01\")';

  @override
  String get chapterAddTooltip => 'Add chapter(s)';

  @override
  String get chapterRemoveAll => 'Alle entfernen';

  @override
  String get chapterShiftTimes => 'Zeiten verschieben';

  @override
  String get chapterFromTracks => 'From Tracks';

  @override
  String get chapterLookup => 'Lookup';

  @override
  String get chapterShowSeconds => 'Sekunden anzeigen';

  @override
  String get chapterShiftBySeconds => 'Verschieben um (Sekunden)';

  @override
  String get chapterShiftHint =>
      'Shifts every unlocked chapter. Use a negative value to move them earlier.';

  @override
  String get chapterBack1Second => 'Back 1 second';

  @override
  String get chapterForward1Second => 'Forward 1 second';

  @override
  String get chapterTitleHint => 'Chapter title';

  @override
  String get chapterStopPreview => 'Stop preview';

  @override
  String get chapterPreviewFromHere => 'Preview from here';

  @override
  String get chapterScrubHint => 'Scrub to the exact spot, then set';

  @override
  String chapterStartAt(String time) {
    return 'Start at $time';
  }

  @override
  String get chapterSetStartHere => 'Set start here';

  @override
  String get chapterMore => 'More';

  @override
  String get chapterUnlock => 'Unlock';

  @override
  String get chapterLock => 'Lock';

  @override
  String get chapterInsertBelow => 'Insert below';

  @override
  String get chapterFindTitle => 'Find chapters';

  @override
  String get chapterFindSubtitle =>
      'Looks up chapters from Audible/Audnexus by ASIN.';

  @override
  String get chapterEnterAsin => 'Enter an ASIN';

  @override
  String get chapterLookupFailed => 'Lookup failed - check the ASIN';

  @override
  String get chapterNoChaptersFound => 'No chapters found for that ASIN';

  @override
  String get chapterRemoveBranding => 'Remove Audible branding (intro/outro)';

  @override
  String chapterFoundCount(int count) {
    return '$count chapters found';
  }

  @override
  String chapterAudibleVsBook(String audible, String book) {
    return 'Audible $audible  -  Book $book';
  }

  @override
  String get chapterAudibleLonger =>
      'The Audible version is longer than your file - later chapters may not line up.';

  @override
  String get chapterAudibleShorter =>
      'The Audible version is shorter than your file - chapters may not line up.';

  @override
  String get chapterTitlesOnly => 'Titles only';

  @override
  String get chapterApplyChapters => 'Apply chapters';

  @override
  String get coverSearchTitle => 'Nach einem Cover suchen';

  @override
  String get coverSearchRefineHint =>
      'Refine the title/author to clean up results - this does not change the book.';

  @override
  String get coverNoneFound => 'No covers found';

  @override
  String get coverEnterTitleFirst => 'Gebe zuerst einen Titel ein';

  @override
  String get coverUpdated => 'Cover updated';

  @override
  String get coverCouldNotUpdate => 'Could not update cover';

  @override
  String get coverApply => 'Apply cover';

  @override
  String get coverUnknownResolution => 'Unknown resolution';

  @override
  String get embedIntro =>
      'Embed metadata into audio files including cover image and chapters.';

  @override
  String get embedBackupOption => 'Back up audio files first';

  @override
  String get embedNoteInFolder =>
      'Metadata will be embedded in the audio tracks inside your audiobook folder.';

  @override
  String get embedNoteMultiTrack =>
      'Chapters are not embedded in multi-track audiobooks.';

  @override
  String get embedNoteNavigateAway =>
      'Once the task is started you can navigate away from this page.';

  @override
  String get embedStartButton => 'Start Metadata Embed';

  @override
  String embedProgress(String percent) {
    return 'Embedding $percent%';
  }

  @override
  String get embedProgressIndeterminate => 'Embedding...';

  @override
  String taskProgressKeepsRunning(String percent) {
    return '$percent% - keeps running if you leave this page';
  }

  @override
  String get taskStarting => 'Starting...';

  @override
  String get embedBackupNoteIntro =>
      'A backup of your original audio files will be stored on the server in ';

  @override
  String embedBackupNotePath(String itemId) {
    return '/metadata/cache/items/$itemId/';
  }

  @override
  String get embedBackupNoteOutro =>
      '. Make sure to periodically purge the items cache.';

  @override
  String get embedDialogTitle => 'Embed metadata';

  @override
  String embedConfirmMessage(int count, String backup) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# audio files',
      one: '# audio file',
    );
    return 'Embed metadata into $_temp0? Your audio files will be rewritten$backup.';
  }

  @override
  String get embedConfirmBackupClause => ' (originals backed up first)';

  @override
  String get embedConfirmAction => 'Embed';

  @override
  String get embedCouldNotStart => 'Could not start embed';

  @override
  String get embedStarted => 'Embed started';

  @override
  String get embedComplete => 'Embed complete';

  @override
  String get embedFailed => 'Embed failed';

  @override
  String get encodeComplete => 'Encode complete';

  @override
  String get encodeFailedTask => 'Encode failed';

  @override
  String encodeProgress(String percent) {
    return 'Encoding $percent%';
  }

  @override
  String get encodeProgressIndeterminate => 'Encoding...';

  @override
  String get adminApiKeys => 'API Keys';

  @override
  String get adminApiKeysSubtitle => 'Programmatic access tokens';

  @override
  String get adminApiKeysNewTitle => 'New API Key';

  @override
  String get adminApiKeysName => 'Name';

  @override
  String get adminApiKeysNameHint => 'e.g. Home Assistant';

  @override
  String get adminApiKeysOwner => 'User';

  @override
  String get adminApiKeysExpiration => 'Expiration';

  @override
  String get adminApiKeysActive => 'Active';

  @override
  String get adminApiKeysActiveSub => 'Key works as soon as it\'s created';

  @override
  String get adminApiKeysInactive => 'Inactive';

  @override
  String get adminApiKeysExpired => 'Expired';

  @override
  String get adminApiKeysCreate => 'Create Key';

  @override
  String get adminApiKeysCreated => 'API key created';

  @override
  String get adminApiKeysTokenLabel => 'Your new API key';

  @override
  String get adminApiKeysCopyWarning =>
      'Copy this key now. For security it won\'t be shown again.';

  @override
  String get adminApiKeysCopy => 'Copy';

  @override
  String get adminApiKeysCopied => 'Copied to clipboard';

  @override
  String get adminApiKeysDone => 'Done';

  @override
  String get adminApiKeysDeleteTitle => 'Revoke API key?';

  @override
  String get adminApiKeysDeleted => 'API key revoked';

  @override
  String get adminApiKeysRevoke => 'Revoke';

  @override
  String get adminApiKeysSetActive => 'Set active';

  @override
  String get adminApiKeysSetInactive => 'Set inactive';

  @override
  String get adminApiKeysFailedCreate => 'Couldn\'t create API key';

  @override
  String get adminApiKeysFailedDelete => 'Couldn\'t revoke API key';

  @override
  String get adminApiKeysFailedUpdate => 'Couldn\'t update API key';

  @override
  String get adminApiKeysEmpty => 'No API keys yet';

  @override
  String get adminApiKeysEmptySub =>
      'Create one to let apps and scripts reach your server';

  @override
  String get adminApiKeysNeverUsed => 'Never used';

  @override
  String get adminApiKeysNeverExpires => 'No expiration';

  @override
  String get adminApiKeysNameRequired => 'Enter a name';

  @override
  String get adminApiKeysUserRequired => 'Pick a user';

  @override
  String get adminApiKeysExpNever => 'Never';

  @override
  String get adminApiKeysExp7d => '7 days';

  @override
  String get adminApiKeysExp30d => '30 days';

  @override
  String get adminApiKeysExp90d => '90 days';

  @override
  String get adminApiKeysExp1y => '1 year';

  @override
  String adminApiKeysLastUsed(String time) {
    return 'Last used $time';
  }

  @override
  String adminApiKeysExpiresOn(String date) {
    return 'Expires $date';
  }

  @override
  String adminApiKeysDeleteContent(String name) {
    return 'Revoke \"$name\"? Apps using this key will lose access immediately.';
  }

  @override
  String get endOfEpisode => 'End of Episode';

  @override
  String get sleepTimerSheetEpisodeSleepStart => 'Sleep at end of episode';

  @override
  String get bookmarkListen => 'Listen';

  @override
  String get bookmarkPause => 'Pause';

  @override
  String get bookmarkPreviewFailed => 'Couldn\'t play this spot.';

  @override
  String get clipExport => 'Export clip';

  @override
  String get clipJumpToStart => 'Jump to start';

  @override
  String get clipJumpToEnd => 'Jump to end';

  @override
  String get clipSetStart => 'Set start';

  @override
  String get clipSetEnd => 'Set end';

  @override
  String get clipInLabel => 'In';

  @override
  String get clipOutLabel => 'Out';

  @override
  String get clipSave => 'Save clip';

  @override
  String clipExportSaved(String filename) {
    return 'Saved $filename';
  }

  @override
  String get clipExportClamped =>
      'Clip saved, shortened to the end of this track';

  @override
  String get clipExportFailed => 'Couldn\'t export the clip.';

  @override
  String get clipDownloadToExport =>
      'Download this book first to export a clip on iPhone.';

  @override
  String get fsPickerTitle => 'Select folder';

  @override
  String get fsServerRoot => 'Server root';

  @override
  String get fsEmptyFolder => 'No subfolders here';

  @override
  String get fsUseThisFolder => 'Use this folder';

  @override
  String get adminLibrariesManage => 'Libraries';

  @override
  String get adminLibrariesManageSubtitle => 'Create, edit and reorder';

  @override
  String get adminUploadTitle => 'Upload media';

  @override
  String get adminUploadSubtitle => 'Add books and podcasts from files';

  @override
  String get adminUploadNoLibraries =>
      'Create a library before uploading media.';

  @override
  String get adminUploadDestination => 'Destination';

  @override
  String get adminUploadFolder => 'Library folder';

  @override
  String get adminUploadDetails => 'Item details';

  @override
  String get adminUploadOptional => 'Optional';

  @override
  String get adminUploadAutoMetadata => 'Auto-fetch metadata';

  @override
  String get adminUploadAutoMetadataSubtitle =>
      'Fill title, author and series from the best match';

  @override
  String get adminUploadMetadataProvider => 'Metadata provider';

  @override
  String get adminUploadMetadataSearching => 'Searching for metadata...';

  @override
  String get adminUploadMetadataNoResults =>
      'No metadata match found. You can still upload this item.';

  @override
  String get adminUploadMetadataFailed =>
      'Couldn\'t search for metadata. You can still upload this item.';

  @override
  String get adminUploadDestinationPreview => 'Server destination';

  @override
  String get adminUploadFiles => 'Files';

  @override
  String adminUploadSelectedFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files',
      one: '1 file',
    );
    return '$_temp0';
  }

  @override
  String get adminUploadChooseFiles => 'Choose files';

  @override
  String get adminUploadAddFiles => 'Add files';

  @override
  String get adminUploadBookFilesHint =>
      'Choose audio or ebook files. You can also include covers and metadata files.';

  @override
  String get adminUploadPodcastFilesHint =>
      'Choose one or more audio files. You can also include covers and metadata files.';

  @override
  String get adminUploadUnsupportedFiles =>
      'Some selected files are not supported by Audiobookshelf.';

  @override
  String get adminUploadFilePickerFailed =>
      'Couldn\'t open the selected files.';

  @override
  String get adminUploadTitleRequired => 'Enter a title';

  @override
  String get adminUploadLibraryRequired => 'Choose a library';

  @override
  String get adminUploadFolderRequired => 'Choose a library folder';

  @override
  String get adminUploadFilesRequired => 'Choose at least one file';

  @override
  String get adminUploadPodcastFileRequired =>
      'Choose at least one audio file for this podcast.';

  @override
  String get adminUploadBookFileRequired =>
      'Choose at least one audio or ebook file for this book.';

  @override
  String get adminUploadPathCheckFailed =>
      'Couldn\'t check the destination folder. Nothing was uploaded.';

  @override
  String get adminUploadDestinationExists =>
      'That destination folder already exists on the server.';

  @override
  String adminUploadDestinationUsedBy(String title) {
    return 'That destination is already used by \"$title\".';
  }

  @override
  String get adminUploadUploading => 'Uploading...';

  @override
  String adminUploadProgress(int percent) {
    return 'Uploading $percent%';
  }

  @override
  String get adminUploadButton => 'Upload';

  @override
  String adminUploadComplete(String title) {
    return 'Uploaded \"$title\"';
  }

  @override
  String get adminUploadFailed => 'Upload failed';

  @override
  String adminUploadFailedReason(String error) {
    return 'Upload failed: $error';
  }

  @override
  String get adminUploadReselectFiles =>
      'Choose the files again before retrying.';

  @override
  String get adminServerSettings => 'Server settings';

  @override
  String get adminServerSettingsSubtitle => 'Scanner, storage and sorting';

  @override
  String get adminStats => 'Statistics';

  @override
  String get adminStatsSubtitle => 'Library and listening totals';

  @override
  String get adminAllSessions => 'All sessions';

  @override
  String get adminAllSessionsSubtitle =>
      'View and manage all listening sessions';

  @override
  String get adminSessionsAllUsers => 'All users';

  @override
  String get adminSessionsEmpty => 'No sessions';

  @override
  String get statsLibraryTotals => 'Library totals';

  @override
  String get statsTotalItems => 'Items';

  @override
  String get statsAudioFiles => 'Audio files';

  @override
  String get statsTotalSize => 'Total size';

  @override
  String get statsBooks => 'Books';

  @override
  String get statsPodcasts => 'Podcasts';

  @override
  String get statsBooksSize => 'Books size';

  @override
  String get statsYearReview => 'Year in review';

  @override
  String get statsNoYearData => 'No data for this year';

  @override
  String get statsListeningTime => 'Listening time';

  @override
  String get statsSessions => 'Sessions';

  @override
  String get statsBooksAdded => 'Books added';

  @override
  String get statsAuthorsAdded => 'Authors added';

  @override
  String get statsTopAuthors => 'Top authors';

  @override
  String get statsTopNarrators => 'Top narrators';

  @override
  String get statsTopGenres => 'Top genres';

  @override
  String get srvScannerSection => 'Scanner';

  @override
  String get srvFindCovers => 'Find covers';

  @override
  String get srvCoverProvider => 'Cover provider';

  @override
  String get srvParseSubtitles => 'Parse subtitles from filename';

  @override
  String get srvPreferMatched => 'Prefer matched metadata';

  @override
  String get srvDisableWatcher => 'Disable folder watcher';

  @override
  String get srvStorageSection => 'Storage';

  @override
  String get srvStoreCover => 'Store cover with item';

  @override
  String get srvStoreMetadata => 'Store metadata with item';

  @override
  String get srvMetadataFormat => 'Metadata file format';

  @override
  String get srvFormatSection => 'Display and format';

  @override
  String get srvDateFormat => 'Date format';

  @override
  String get srvTimeFormat => 'Time format';

  @override
  String get srvLanguage => 'Server language';

  @override
  String get srvChromecast => 'Chromecast support';

  @override
  String get srvAllowIframe => 'Allow iframe embedding';

  @override
  String get srvSortingSection => 'Sorting';

  @override
  String get srvIgnorePrefixes => 'Ignore prefixes when sorting';

  @override
  String get srvSortingPrefixes => 'Sorting prefixes';

  @override
  String get srvAddPrefix => 'Add prefix';

  @override
  String get srvSave => 'Save settings';

  @override
  String get srvSavePrefixes => 'Save prefixes';

  @override
  String get srvSaved => 'Settings saved';

  @override
  String get srvSaveFailed => 'Couldn\'t save settings';

  @override
  String get srvPrefixesSaved => 'Sorting prefixes updated';

  @override
  String get libNoneYet => 'No libraries yet';

  @override
  String get libReorderFailed => 'Couldn\'t save the new order';

  @override
  String get libDeleteTitle => 'Delete library?';

  @override
  String get libDeleteBody =>
      'This permanently removes the library and all of its items from the server.';

  @override
  String get libDeleted => 'Library deleted';

  @override
  String get libDeleteFailed => 'Couldn\'t delete library';

  @override
  String libFolderCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count folders',
      one: '1 folder',
    );
    return '$_temp0';
  }

  @override
  String get libNewTitle => 'New library';

  @override
  String get libEditTitle => 'Edit library';

  @override
  String get libName => 'Library name';

  @override
  String get libMediaType => 'Media type';

  @override
  String get libMediaBook => 'Books';

  @override
  String get libMediaPodcast => 'Podcasts';

  @override
  String get libProvider => 'Metadata provider';

  @override
  String get libIcon => 'Icon';

  @override
  String get libFolders => 'Folders';

  @override
  String get libAddFolder => 'Add folder';

  @override
  String get libNoFolders => 'Add at least one folder';

  @override
  String get libAdvanced => 'Advanced settings';

  @override
  String get libCoverShape => 'Cover shape';

  @override
  String get libCoverSquare => 'Square';

  @override
  String get libCoverStandard => 'Standard';

  @override
  String get libDisableWatcher => 'Disable folder watcher';

  @override
  String get libSkipAsin => 'Skip matching books that have an ASIN';

  @override
  String get libSkipIsbn => 'Skip matching books that have an ISBN';

  @override
  String get libHideSingleSeries => 'Hide single-book series';

  @override
  String get libAudiobooksOnly => 'Audiobooks only';

  @override
  String get libEpubScripted => 'Allow scripted ePub content';

  @override
  String get libLaterBooksOnly => 'Only show later books in Continue Series';

  @override
  String get libPodcastRegion => 'Podcast search region';

  @override
  String get libMarkPercent => 'Finished at % complete';

  @override
  String get libMarkTime => 'Finished with seconds left';

  @override
  String get libAutoScan => 'Auto-scan schedule (cron)';

  @override
  String get libCreate => 'Create library';

  @override
  String get libUpdate => 'Save changes';

  @override
  String get libNameRequired => 'Enter a library name';

  @override
  String get libCreated => 'Library created';

  @override
  String get libCreateFailed => 'Couldn\'t create library';

  @override
  String get libUpdated => 'Library updated';

  @override
  String get libUpdateFailed => 'Couldn\'t update library';

  @override
  String get libRemoveFoldersTitle => 'Remove folders?';

  @override
  String get libRemoveFoldersBody =>
      'Removing a folder deletes its items from the library. This can\'t be undone.';

  @override
  String get readEbook => 'Read';

  @override
  String get ebookDownload => 'Download';

  @override
  String get ebookDownloaded => 'Downloaded';

  @override
  String get ebookSavedOffline => 'Saved for offline reading';

  @override
  String get ebookRemovedOffline => 'Removed from offline';

  @override
  String get ebookOfflineFailed => 'Couldn\'t download the ebook';

  @override
  String get ebookSaveToDevice => 'Save to device';

  @override
  String get ebookSaveToDeviceTitle => 'Save to device?';

  @override
  String get ebookSaveToDeviceBody =>
      'This saves a copy of the ebook file somewhere on your device (you pick where). It won\'t make the book available offline in the reader - use Download for that.';

  @override
  String get readerFormatUnsupported =>
      'This ebook format can\'t be opened in the reader yet';

  @override
  String get moreActions => 'More';

  @override
  String get readerChapters => 'Chapters';

  @override
  String get readerSettings => 'Reader Settings';

  @override
  String get readerFontSize => 'Font Size';

  @override
  String get readerLineSpacing => 'Line Spacing';

  @override
  String get readerSideMargins => 'Side margins';

  @override
  String get readerTopBottom => 'Top & bottom';

  @override
  String get readerPageLayout => 'Page layout';

  @override
  String get readerLayoutAuto => 'Auto';

  @override
  String get readerLayoutSingle => 'Single';

  @override
  String get readerLayoutTwoPage => 'Two-page';

  @override
  String get readerTheme => 'Theme';

  @override
  String get readerFont => 'Font';

  @override
  String get readerVolumeNav => 'Volume keys turn pages';

  @override
  String get readerVolumeNavOff => 'Off';

  @override
  String get readerVolumeNavNormal => 'Normal';

  @override
  String get readerVolumeNavMirrored => 'Mirrored';

  @override
  String get readerVolumeNavWhilePlaying => 'Even while audio is playing';

  @override
  String get readerMoreFonts => 'Download more fonts';

  @override
  String get readerFontRemove => 'Remove download';

  @override
  String readerFontDownloadFailed(String font) {
    return 'Couldn\'t download $font';
  }

  @override
  String get readerAnnotations => 'Annotations';

  @override
  String readerHighlights(int count) {
    return 'Highlights ($count)';
  }

  @override
  String readerBookmarks(int count) {
    return 'Bookmarks ($count)';
  }

  @override
  String get readerNoHighlights => 'No highlights yet';

  @override
  String get readerNoBookmarks => 'No bookmarks yet';

  @override
  String get readerBookmarkDefault => 'Bookmark';

  @override
  String get readerNoteTitle => 'Note';

  @override
  String get readerNoteHint => 'Add a note...';

  @override
  String get readerCopied => 'Copied to clipboard';

  @override
  String get readerTooltipCopy => 'Copy';

  @override
  String get readerTooltipSearch => 'Search';

  @override
  String get readerTooltipDefine => 'Define';

  @override
  String get readerSearchHint => 'Search this book…';

  @override
  String readerSearchMatches(int count, String query) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count matches for \"$query\"',
      one: '$count match for \"$query\"',
    );
    return '$_temp0';
  }

  @override
  String get readerSearchEmpty => 'Type a word or phrase and tap search.';

  @override
  String readerSearchNoResults(String query) {
    return 'No matches for \"$query\".';
  }
}
