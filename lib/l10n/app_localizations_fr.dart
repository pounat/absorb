// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'A B S O R B';

  @override
  String get online => 'Connecté';

  @override
  String get offline => 'Déconnecté';

  @override
  String get stillOffline =>
      'Toujours déconnecté. Touchez pour essayer encore.';

  @override
  String get retry => 'Réessayer';

  @override
  String get cancel => 'Annuler';

  @override
  String get delete => 'Effacer';

  @override
  String get remove => 'Retirer';

  @override
  String get save => 'Enregistrer';

  @override
  String get done => 'Fait';

  @override
  String get edit => 'Modifier';

  @override
  String get search => 'Rechercher';

  @override
  String get apply => 'Appliquer';

  @override
  String get enable => 'Activé';

  @override
  String get clear => 'Effacer';

  @override
  String get off => 'Arrêt';

  @override
  String get disabled => 'Désactivé';

  @override
  String get later => 'Plus tard';

  @override
  String get gotIt => 'Ok';

  @override
  String get preview => 'Aperçu';

  @override
  String get or => 'ou';

  @override
  String get file => 'Fichier';

  @override
  String get more => 'Plus';

  @override
  String get unknown => 'Inconnu';

  @override
  String get untitled => 'Sans titre';

  @override
  String get noThanks => 'Non merci';

  @override
  String get stay => 'Rester';

  @override
  String get homeTitle => 'Accueil';

  @override
  String get continueListening => 'Continuer l\'écoute';

  @override
  String get continueSeries => 'Continuer les séries';

  @override
  String get recentlyAdded => 'Ajouté récemment';

  @override
  String get listenAgain => 'Écouter à nouveau';

  @override
  String get discover => 'Découvrir';

  @override
  String get newEpisodes => 'Nouveaux épisodes';

  @override
  String get downloads => 'Téléchargements';

  @override
  String get noDownloadedBooks => 'Aucun livre téléchargé';

  @override
  String get yourLibraryIsEmpty => 'Votre bibliothèque est vide';

  @override
  String get downloadBooksWhileOnline =>
      'Télécharger des livres en ligne pour écouter hors ligne';

  @override
  String get customizeHome => 'Personnaliser l\'accueil';

  @override
  String get dragToReorderTapEye =>
      'Faites glisser pour réorganiser, appuyez sur l\'œil pour afficher/masquer';

  @override
  String get loginTagline => 'Commencer à Absorber';

  @override
  String get loginConnectToServer => 'Se connecter au serveur';

  @override
  String get loginServerAddress => 'Adresse du serveur';

  @override
  String get loginServerHint => 'mon.serveur.fr';

  @override
  String get loginServerHelper => 'IP + port (ex : 192.168.1.5:13378)';

  @override
  String get loginCouldNotReachServer =>
      'Impossible de se connecter au serveur';

  @override
  String get loginAdvanced => 'Avancé';

  @override
  String get loginCustomHttpHeaders => 'Entêtes HTTP personnalisés';

  @override
  String get loginCustomHeadersDescription =>
      'Pour les tunnels Cloudflare ou les reverse proxies qui nécessitent des en-têtes supplémentaires. Ajoutez les en-têtes avant d’entrer l’URL de votre serveur.';

  @override
  String get loginHeaderName => 'Nom de l\'en-tête';

  @override
  String get loginHeaderValue => 'Valeur';

  @override
  String get loginAddHeader => 'Ajouter un en-tête';

  @override
  String get loginSelfSignedCertificates => 'Certificat auto-signé';

  @override
  String get loginTrustAllCertificates =>
      'Faire confiance à tous les certificats (pour les configurations autosignées ou avec CA personnalisé)';

  @override
  String get loginApiKey => 'Clé API';

  @override
  String get loginApiKeyDescription =>
      'Utiliser une clé API générée par l’administrateur plutôt qu’un nom d’utilisateur et un mot de passe. Utile lorsque le rafraîchissement du jeton échoue pour votre compte.';

  @override
  String get loginWaitingForSso => 'En attente du SSO...';

  @override
  String get loginRedirectUri => 'URI de redirection : audiobookshelf://oauth';

  @override
  String get loginOrSignInManually => 'ou se connecter manuellement';

  @override
  String get loginUsername => 'Utilisateur';

  @override
  String get loginUsernameRequired => 'Entrez votre nom d\'utilisateur';

  @override
  String get loginPassword => 'Mot de passe';

  @override
  String get loginSignIn => 'Se connecter';

  @override
  String loginSignInAs(String username) {
    return 'Se connecter en tant que $username ?';
  }

  @override
  String get loginSignInToServer => 'Se connecter à ce serveur ?';

  @override
  String loginSignedInAs(String username) {
    return 'Connecté en tant que $username';
  }

  @override
  String get adminCreateSetupFile => 'Partager la connexion';

  @override
  String adminSetupFileDescription(String username) {
    return 'Crée un lien de connexion privé pour $username qui ne fonctionne que dans l\'application Absorb.';
  }

  @override
  String get adminSetupFileServerUrl =>
      'URL du serveur que le nouvel utilisateur va utiliser';

  @override
  String get adminSetupFileNoteWithHeaders =>
      'Une clé API dédiée et vos en-têtes personnalisés seront inclus afin qu\'ils puissent atteindre le serveur. Traitez le lien comme un mot de passe.';

  @override
  String get adminSetupFileNote =>
      'Une clé API dédiée sera incluse. Traitez le lien comme un mot de passe.';

  @override
  String get adminSetupFileCreate => 'Créer un lien';

  @override
  String get adminSetupFileSaveTitle =>
      'Enregistrer le fichier de configuration';

  @override
  String get adminSetupFileKeyError =>
      'Impossible de créer une clé API pour cet utilisateur';

  @override
  String adminSetupFileSaved(String username) {
    return 'Fichier de configuration enregistré pour $username';
  }

  @override
  String adminSetupFileFailed(String error) {
    return 'Impossible de créer la connexion : $error';
  }

  @override
  String get setupLinkShareTitle => 'Partager la connexion';

  @override
  String setupLinkShareDescription(String username) {
    return 'Envoyez ce lien privé ou demandez-leur de scanner le code QR pour se connecter en tant que $username.';
  }

  @override
  String setupLinkPrivateWarning(String username) {
    return 'N\'importe qui avec ce lien peut se connecter en tant que $username. Traitez-le comme un mot de passe.';
  }

  @override
  String get setupLinkShare => 'Share link';

  @override
  String get setupLinkCopy => 'Copier le lien';

  @override
  String get setupLinkCopied => 'Lien de connexion copié';

  @override
  String get setupLinkSaveFile => 'Enregistrer le fichier de configuration';

  @override
  String get setupLinkQrError =>
      'Ce lien de configuration est trop volumineux pour un code QR. Partagez le lien à la place.';

  @override
  String setupLinkShareSubject(String username) {
    return 'Connexion à Absorb pour $username';
  }

  @override
  String get setupLinkConfirmTitle => 'Se connecter avec ce lien ?';

  @override
  String setupLinkConfirmBody(String server, String username) {
    return 'Se Connecter à $server en tant que $username ? Ne continuez que si vous faites confiance à celui qui vous a envoyé ce lien.';
  }

  @override
  String get setupLinkInvalid =>
      'Ce lien de connexion est invalide ou incomplet';

  @override
  String get setupLinkSigningIn => 'Vérification du lien de connexion...';

  @override
  String get loginPasteLink => 'Coller le lien de connexion';

  @override
  String get loginPasteLinkHelp =>
      'Collez le lien complet de connexion que vous avez reçu. Traitez-le comme un mot de passe.';

  @override
  String get loginFailed => 'Échec de connexion';

  @override
  String get loginSsoFailed => 'La connexion SSO a échoué ou a été annulée';

  @override
  String get loginSsoAuthFailed =>
      'Échec de l\'authentification SSO. Veuillez réessayer.';

  @override
  String get loginRestoreFromBackup => 'Importer';

  @override
  String get loginInvalidBackupFile => 'Fichier de sauvegarde invalide';

  @override
  String get loginRestoreBackupTitle => 'Restaurer la sauvegarde ?';

  @override
  String loginRestoreBackupWithAccounts(int count) {
    return 'Tous les paramètres ainsi que $count compte(s) sauvegardé(s) seront restaurés. Vous serez connecté automatiquement.';
  }

  @override
  String get loginRestoreBackupNoAccounts =>
      'Tous les paramètres seront restaurés. Aucun compte n\'était inclus dans cette sauvegarde.';

  @override
  String get loginRestore => 'Restaurer';

  @override
  String loginRestoredAndSignedIn(String username) {
    return 'Paramètres restaurés, connecté en tant que $username';
  }

  @override
  String get loginSessionExpired =>
      'Paramètres restaurés. Session expirée - se connecter pour continuer.';

  @override
  String get loginSettingsRestored => 'Paramètres restaurés';

  @override
  String loginRestoreFailed(String error) {
    return 'Échec de la restauration : $error';
  }

  @override
  String get loginSavedAccounts => 'comptes enregistrés';

  @override
  String get libraryTitle => 'Bibliothèque';

  @override
  String get librarySearchBooksHint =>
      'Rechercher par livres, séries, auteurs, narrateurs ...';

  @override
  String get librarySearchShowsHint =>
      'Rechercher des séries et des épisodes...';

  @override
  String get libraryTabLibrary => 'Bibliothèque';

  @override
  String get libraryTabSeries => 'Séries';

  @override
  String get libraryTabAuthors => 'Auteurs';

  @override
  String get libraryTabNarrators => 'Narrateurs';

  @override
  String get libraryNoBooks => 'Aucun livre trouvé';

  @override
  String get libraryNoUnfinishedBooks => 'Aucun livre inachevé';

  @override
  String get libraryNoBooksInProgress => 'Aucun livre en cours de lecture';

  @override
  String get libraryNoFinishedBooks => 'Aucun livre achevé';

  @override
  String get libraryAllBooksStarted => 'Tous les livres ont été commencés';

  @override
  String get libraryNoDownloadedBooks => 'Aucun livre téléchargé';

  @override
  String get libraryNoSeriesFound => 'Aucune série trouvée';

  @override
  String get libraryNoBooksWithEbooks => 'Aucun livre avec eBooks';

  @override
  String get libraryNoBooksMissingMetadata =>
      'Cette métadonnée n\'est absente d\'aucun livre';

  @override
  String get libraryNoItemsMatchingFilter =>
      'Aucun élément ne correspond à ce filtre';

  @override
  String libraryNoBooksInGenre(String genre) {
    return 'Aucun livre du genre \"$genre\"';
  }

  @override
  String libraryNoBooksWithTag(String tag) {
    return 'Aucun livre étiqueté « $tag »';
  }

  @override
  String get libraryClearFilter => 'Effacer le filtre';

  @override
  String get libraryNoAuthorsFound => 'Aucun auteur trouvé';

  @override
  String get libraryNoNarratorsFound => 'Aucun narrateur trouvé';

  @override
  String get libraryNoResults => 'Aucun résultat';

  @override
  String get librarySearchBooks => 'Livres';

  @override
  String get librarySearchShows => 'Séries';

  @override
  String get librarySearchEpisodes => 'Épisodes';

  @override
  String get librarySearchSeries => 'Séries';

  @override
  String get librarySearchAuthors => 'Auteurs';

  @override
  String get librarySearchTags => 'Tags';

  @override
  String get librarySearchGenres => 'Genres';

  @override
  String librarySeriesCount(int count) {
    return '$count séries';
  }

  @override
  String libraryAuthorsCount(int count) {
    return '$count auteurs';
  }

  @override
  String libraryNarratorsCount(int count) {
    return '$count narrateurs';
  }

  @override
  String libraryBooksCount(int loaded, int total) {
    return '$loaded/$total livres';
  }

  @override
  String get sort => 'Trier';

  @override
  String get filter => 'Filtrer';

  @override
  String get filterActive => 'Filtrer';

  @override
  String get name => 'Nom';

  @override
  String get title => 'Titre';

  @override
  String get author => 'Auteur';

  @override
  String get dateAdded => 'Date d\'ajout';

  @override
  String get numberOfBooks => 'Nombre de livres';

  @override
  String get publishedYear => 'Année de publication';

  @override
  String get duration => 'Durée';

  @override
  String get random => 'Aléatoire';

  @override
  String get collapseSeries => 'Replier les séries';

  @override
  String get notFinished => 'Non terminé';

  @override
  String get inProgress => 'En cours';

  @override
  String get filterFinished => 'Fini';

  @override
  String get notStarted => 'Non commencé';

  @override
  String get downloaded => 'Téléchargé';

  @override
  String get hasEbook => 'A un eBook';

  @override
  String get noEbook => 'Aucun eBook';

  @override
  String get hasSupplementaryEbook => 'A un eBook supplémentaire';

  @override
  String get noSupplementaryEbook => 'Pas de eBook supplémentaire';

  @override
  String get noSeries => 'Pas de série';

  @override
  String get publishedDecade => 'Décennie de publication';

  @override
  String get tracks => 'Pistes';

  @override
  String get noTracks => 'Aucune piste';

  @override
  String get singleTrack => 'Piste unique';

  @override
  String get multipleTracks => 'Multiples pistes';

  @override
  String get abridged => 'Abridged';

  @override
  String get issues => 'Issues';

  @override
  String get rssFeedOpen => 'Flux RSS ouvert';

  @override
  String get explicitContent => 'Explicite';

  @override
  String get missingMetadata => 'Métadonnées manquantes';

  @override
  String get genre => 'Genre';

  @override
  String get tag => 'Mot-clé';

  @override
  String get clearFilter => 'Supprimer le filtre';

  @override
  String get noGenresFound => 'Aucun genre trouvé';

  @override
  String get noTagsFound => 'Aucun mot-clé trouvé';

  @override
  String get asc => 'Croissant';

  @override
  String get desc => 'Décroissant';

  @override
  String get fileSize => 'Taille du fichier';

  @override
  String get lastUpdated => 'Dernière mise à jour';

  @override
  String get fileCreated => 'Fichier créé';

  @override
  String get lastModified => 'Dernière modification';

  @override
  String get authorFirstLast => 'Auteur (Prénom Nom)';

  @override
  String get authorLastFirst => 'Auteur (Nom, Prénom)';

  @override
  String get progressSort => 'Progression';

  @override
  String get dateStarted => 'Date de démarrage';

  @override
  String get dateFinished => 'Date de complétion';

  @override
  String get episodeCount => 'Nombre d\'épisodes';

  @override
  String get sequence => 'Series Sequence';

  @override
  String get absorbingTitle => 'Lecture';

  @override
  String get absorbingStop => 'Stop';

  @override
  String get absorbingManageQueue => 'Gérer la file d\'attente';

  @override
  String get desktopAbsorbingQueueHint =>
      'Use Add to Absorbing on a book or episode to put it here. Items play in this order.';

  @override
  String get absorbingDone => 'Fait';

  @override
  String get absorbingNoDownloadedEpisodes => 'Aucun épisode téléchargé';

  @override
  String get absorbingNoDownloadedBooks => 'Aucun livre téléchargé';

  @override
  String get absorbingNothingPlayingYet => 'Rien en cours de lecture';

  @override
  String get absorbingNothingAbsorbingYet => 'Rien d\'absorbé pour le moment';

  @override
  String get absorbingDownloadEpisodesToListen =>
      'Télécharger les épisodes pour les écouter hors ligne';

  @override
  String get absorbingDownloadBooksToListen =>
      'Télécharger les livres pour les écouter hors ligne';

  @override
  String get absorbingStartEpisodeFromShows =>
      'Démarrer un épisode depuis l\'onglet Séries';

  @override
  String get absorbingStartBookFromLibrary =>
      'Démarrer un livre depuis l\'onglet Bibliothèque';

  @override
  String get carModeTitle => 'Mode Auto';

  @override
  String get carModeNoBookLoaded => 'Aucun livre chargé';

  @override
  String get carModeBookLabel => 'Livre';

  @override
  String get carModeChapterLabel => 'Chapitre';

  @override
  String get carModeBookmarkDefault => 'Signet';

  @override
  String get carModeBookmarkAdded => 'Signet ajouté';

  @override
  String get downloadsTitle => 'Téléchargements';

  @override
  String get downloadsCancelSelection => 'Annuler la sélection';

  @override
  String get downloadsSelect => 'Sélectionner';

  @override
  String get downloadsNoDownloads => 'Aucun téléchargement';

  @override
  String get downloadsDownloading => 'Téléchargement';

  @override
  String get downloadsQueued => 'En file d\'attente';

  @override
  String get downloadsCompleted => 'Terminé';

  @override
  String get downloadsWaiting => 'En attente...';

  @override
  String get downloadsCancel => 'Annuler';

  @override
  String get downloadsDelete => 'Supprimer';

  @override
  String downloadsDeleteCount(int count) {
    return 'Supprimer $count téléchargement(s) ?';
  }

  @override
  String get downloadsDeleteContent =>
      'Les fichiers téléchargés seront supprimés de cet appareil.';

  @override
  String downloadsDeletedCount(int count) {
    return '$count téléchargement(s) supprimés';
  }

  @override
  String get downloadsRemoveTitle => 'Retirer le téléchargement ?';

  @override
  String downloadsRemoveContent(String title) {
    return 'Supprimer \"$title\" de cet appareil ?';
  }

  @override
  String downloadsRemovedTitle(String title) {
    return '\"$title\" supprimé';
  }

  @override
  String downloadsSelectedCount(int count) {
    return '$count sélectionné(s)';
  }

  @override
  String get bookmarksTitle => 'Tous les signets';

  @override
  String get bookmarksCancelSelection => 'Annuler la sélection';

  @override
  String get bookmarksSortedByNewest => 'Plus récents d\'abord';

  @override
  String get bookmarksSortedByPosition => 'Triés par position';

  @override
  String get bookmarksSelect => 'Sélectionner';

  @override
  String get bookmarksNoBookmarks => 'Aucun signet pour l\'instant';

  @override
  String bookmarksDeleteCount(int count) {
    return 'Supprimer $count signet(s) ?';
  }

  @override
  String get bookmarksDeleteContent => 'Cette opération est irréversible.';

  @override
  String bookmarksDeletedCount(int count) {
    return '$count signet(s) supprimé(s)';
  }

  @override
  String get bookmarksJumpTitle => 'Aller au signet ?';

  @override
  String bookmarksJumpContent(String title, String position, String bookTitle) {
    return '\"$title\" à $position\ndans $bookTitle';
  }

  @override
  String get bookmarksJump => 'Allez à';

  @override
  String get bookmarksNotConnected => 'Non connecté au serveur';

  @override
  String get bookmarksCouldNotLoad => 'Impossible de charger le livre';

  @override
  String bookmarksSelectedCount(int count) {
    return '$count sélectionné(s)';
  }

  @override
  String get statsTitle => 'Vos statistiques';

  @override
  String get statsCouldNotLoad => 'Échec du chargement des statistiques';

  @override
  String get statsTotalListeningTime => 'TEMPS TOTAL D\'ÉCOUTE';

  @override
  String get statsHoursUnit => 'h';

  @override
  String get statsMinutesUnit => 'm';

  @override
  String get statsSecondsUnit => 's';

  @override
  String statsDaysOfAudio(String days) {
    return 'C\'est $days jours d\'audio';
  }

  @override
  String statsHoursOfAudio(String hours) {
    return 'C\'est $hours d\'audio';
  }

  @override
  String get statsToday => 'Aujourd\'hui';

  @override
  String get statsThisWeek => 'Cette semaine';

  @override
  String get statsThisMonth => 'Ce mois-ci';

  @override
  String get statsActivity => 'Activité';

  @override
  String get statsCurrentStreak => 'Série actuelle';

  @override
  String get statsBestStreak => 'Meilleure série';

  @override
  String get statsFinished => 'Terminé';

  @override
  String get statsBooksFinished => 'Livres';

  @override
  String get statsEpisodesFinished => 'Épisodes';

  @override
  String get statsBooksThisYear => 'Livres cette année';

  @override
  String get statsEpisodesThisYear => 'Épisodes cette année';

  @override
  String get statsRemoveFromYearTitle => 'Retirer de cette année';

  @override
  String statsRemoveFromYearWithDate(String date, String title) {
    return 'La date de fin sera toujours $date sur le serveur. Cela ne supprime que \"$title\" de votre liste des livres Absorb cette année.';
  }

  @override
  String statsRemoveFromYearNoDate(String title) {
    return 'La date de fin reste sur le serveur. Cela retire seulement « $title » de votre liste Absorb des livres lus cette année.';
  }

  @override
  String get statsRemovedFromYear => 'Retiré de cette année';

  @override
  String get statsAddBackToYearTitle => 'Ajouter de nouveau à cette année';

  @override
  String statsAddBackToYearBody(String title) {
    return 'Ajouter «$title» à votre liste des livres Absorb de cette année?';
  }

  @override
  String get statsAddBack => 'Ajouter à nouveau';

  @override
  String get statsAddedBackToYear => 'Ajouté de nouveau à cette année';

  @override
  String get statsHiddenFromYear => 'Masqué dans cette année';

  @override
  String get statsNothingHidden => 'Rien de masqué';

  @override
  String get settingsCustomizeStats => 'Personnaliser les statistiques';

  @override
  String get statsGoalTitle => 'Objectif d\'écoute';

  @override
  String get statsGoalOff => 'Désactivé';

  @override
  String get statsGoalDaily => 'Quotidien';

  @override
  String get statsGoalWeekly => 'Hebdomadaire';

  @override
  String get statsGoalMonthly => 'Mensuel';

  @override
  String get statsGoalTarget => 'Objectif';

  @override
  String get statsGoalEnterTitle => 'Définir l\'objectif';

  @override
  String get statsGoalEnterTimeHint => 'Minutes ou h:mm';

  @override
  String statsBooksShort(int count) {
    return '$count livres';
  }

  @override
  String get statsBookChallengeTitle => 'Défi de lecture';

  @override
  String get statsBookChallengeDesc => 'Livres à terminer cette année';

  @override
  String get statsDailyGoal => 'Objectif quotidien';

  @override
  String get statsWeeklyGoal => 'Objectif hebdomadaire';

  @override
  String get statsMonthlyGoal => 'Objectif mensuel';

  @override
  String statsGoalProgress(String done, String target) {
    return '$done / $target';
  }

  @override
  String statsBookChallengeProgress(int done, int target) {
    return '$done de $target livres';
  }

  @override
  String get statsGoalReached => 'Objectif atteint';

  @override
  String get statsChartTitle => 'Graphique d\'écoute';

  @override
  String get statsChartBar => 'Histogrammes';

  @override
  String get statsChartLine => 'Ligne';

  @override
  String get statsChartHeatmap => 'Heatmap';

  @override
  String get statsChartDays7 => '7 jours';

  @override
  String get statsChartDays30 => '30 jours';

  @override
  String get statsLast30Days => '30 derniers jours';

  @override
  String get statsThisYearTitle => 'Cette année';

  @override
  String get statsSectionsTitle => 'Sections';

  @override
  String get statsSectionTimePeriods => 'Périodes';

  @override
  String get statsHeatmapLess => 'Moins';

  @override
  String get statsHeatmapMore => 'Plus';

  @override
  String get statsDayOfWeek => 'Moyenne par jour de la semaine';

  @override
  String get statsTimeSavedLabel => 'Enregistré par vitesse';

  @override
  String statsTimeSavedSince(String date) {
    return 'depuis le $date';
  }

  @override
  String get statsTimeSavedReset => 'Remise à zéro du temps gagné';

  @override
  String get statsTimeSavedResetConfirm =>
      'Le temps gagné commencera à compter de nouveau à partir d\'aujourd\'hui.';

  @override
  String get statsTimeSavedResetDone => 'Remise à zéro du temps gagné';

  @override
  String statsOnPaceFor(int count) {
    return 'Bon rythme pour $count livres';
  }

  @override
  String get statsDaysActive => 'Nombre de jours actifs';

  @override
  String get statsDailyAverage => 'Moyenne quotidienne';

  @override
  String get statsLast7Days => '7 derniers jours';

  @override
  String get statsMostListened => 'Les plus écoutées';

  @override
  String get statsRecentSessions => 'Sessions récentes';

  @override
  String get appShellHomeTab => 'Accueil';

  @override
  String get appShellLibraryTab => 'Bibliothèque';

  @override
  String get appShellAbsorbingTab => 'Absorption';

  @override
  String get appShellStatsTab => 'Stats';

  @override
  String get appShellSettingsTab => 'Paramètres';

  @override
  String get appShellDiscoverTab => 'Découvrir';

  @override
  String get appShellShowsTab => 'Séries';

  @override
  String get appShellPodcastsTab => 'Podcasts';

  @override
  String get libraryTabEpisodes => 'Épisodes';

  @override
  String get filterAllEpisodes => 'Tous';

  @override
  String get filterUnplayed => 'Non lus';

  @override
  String get episodeFeedEmpty => 'Aucun épisode ne correspond à ce filtre';

  @override
  String get podcastFilterUpNext => 'Suivant';

  @override
  String get podcastFilterNew => 'Nouveau';

  @override
  String get settingsPodcastTab => 'Onglet Podcasts';

  @override
  String get settingsPodcastTabDesc =>
      'Donner à une bibliothèque de podcast son propre onglet dans la barre du bas';

  @override
  String get settingsPodcastTabLibrary =>
      'Bibliothèque pour l\'onglet podcasts';

  @override
  String get settingsMergeImpliedByPodcastTab =>
      'Toujours allumé lorsque l\'onglet Podcasts est activé';

  @override
  String get settingsEpisodeNotifs => 'Notifications de nouvel épisode';

  @override
  String get settingsEpisodeNotifsDesc =>
      'Vérifier les séries abonnées en arrière-plan';

  @override
  String get notifIntervalOff => 'Désactivé';

  @override
  String notifIntervalMinutes(int n) {
    return 'Toutes les $n minutes';
  }

  @override
  String get notifIntervalHour => 'Toutes les heures';

  @override
  String notifIntervalHours(int n) {
    return 'Toutes les $n heures';
  }

  @override
  String get settingsBatteryUnrestricted =>
      'Autoriser l\'utilisation sans restriction de la batterie';

  @override
  String get settingsBatteryUnrestrictedDesc =>
      'Empêche le système de mettre en pause les vérifications d\'arrière-plan sur certains téléphones';

  @override
  String get appShellPressBackToExit => 'Appuyez à nouveau pour quitter';

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get sectionAppearance => 'Apparence';

  @override
  String get languageLabel => 'Langage';

  @override
  String get languageSystemDefault => 'Valeurs par défaut du système';

  @override
  String get languageHelpTranslateInvite =>
      'Vous souhaitez aider à traduire Absorb ?';

  @override
  String get themeLabel => 'Thème';

  @override
  String get themeDark => 'Sombre';

  @override
  String get themeOled => 'OLED';

  @override
  String get themeLight => 'Clair';

  @override
  String get themeAuto => 'Auto';

  @override
  String get colorSourceLabel => 'Source de couleur';

  @override
  String get colorSourceCoverDescription =>
      'Les couleurs de l\'application suivent la couverture du livre en cours de lecture';

  @override
  String get colorSourceWallpaperDescription =>
      'Les couleurs de l\'application suivent votre fond d\'écran système';

  @override
  String get colorSourceWallpaper => 'Fond d\'écran';

  @override
  String get colorSourceNowPlaying => 'Lecture en cours';

  @override
  String get colorSourceDynamic => 'Dynamique';

  @override
  String get colorSourceManual => 'Manuel';

  @override
  String get colorSourceManualDescription =>
      'Utilisez une couleur fixe de l\'application que vous choisissez ci-dessous';

  @override
  String get colorSourceCustom => 'Personnalisée';

  @override
  String get useColorEverywhereLabel => 'Utiliser cette couleur partout';

  @override
  String get useColorEverywhereSubtitle =>
      'Colorer aussi les pages de détail des livres et la carte du lecteur avec ta couleur définie plutôt qu’avec la couverture de chaque livre';

  @override
  String get flatBackgroundLabel => 'Arrière-plan plat';

  @override
  String get flatBackgroundSubtitle =>
      'Supprime le dégradé d’arrière‑plan. Noir pur en mode sombre pour les écrans OLED.';

  @override
  String get backgroundIntensityLabel => 'Intensité de l\'arrière-plan';

  @override
  String get startScreenLabel => 'Écran d\'accueil';

  @override
  String get startScreenSubtitle =>
      'Quel onglet ouvrir au lancement de l\'application';

  @override
  String get startScreenHome => 'Accueil';

  @override
  String get startScreenLibrary => 'Bibliothèque';

  @override
  String get startScreenAbsorb => 'Absorb';

  @override
  String get startScreenStats => 'Stats';

  @override
  String get disablePageFade => 'Désactiver le fondu de page';

  @override
  String get disablePageFadeOnSubtitle =>
      'Le changement de page est instantané';

  @override
  String get disablePageFadeOffSubtitle =>
      'Les pages s\'estompent lors du changement d\'onglets';

  @override
  String get rectangleBookCovers => 'Couvertures de livres rectangulaires';

  @override
  String get progressTextSize => 'Taille du texte de la progression';

  @override
  String get rectangleBookCoversOnSubtitle =>
      'Les couvertures s\'affichent au format 2:3';

  @override
  String get rectangleBookCoversOffSubtitle => 'Les couvertures sont carrées';

  @override
  String get sectionAbsorbingCards => 'Cartes d\'absorption';

  @override
  String get fullScreenPlayer => 'Lecteur plein écran';

  @override
  String get fullScreenPlayerOnSubtitle =>
      'Activé - livres ouverts en plein écran lors de la lecture';

  @override
  String get fullScreenPlayerOffSubtitle => 'Stop - jouer dans la vue carte';

  @override
  String get fullBookScrubber => 'Barre de progression pour le livre complet';

  @override
  String get fullBookScrubberOnSubtitle =>
      'Activé - curseur de recherche sur tout le livre';

  @override
  String get fullBookScrubberOffSubtitle =>
      'Désactivé - barre de progression uniquement';

  @override
  String get cardScrubbers => 'Barres de lecture pour les cartes';

  @override
  String get cardScrubbersBoth => 'Les deux';

  @override
  String get cardScrubbersChapter => 'Chapitre';

  @override
  String get cardScrubbersLocked => 'Verrouillé';

  @override
  String get cardScrubbersBothSubtitle =>
      'Les barres de livre et de chapitre peuvent positionner la lecture';

  @override
  String get cardScrubbersChapterSubtitle =>
      'Seul la barre de chapitre peut positionner la lecture';

  @override
  String get cardScrubbersLockedSubtitle =>
      'La progression est affichée sans positionnement possible';

  @override
  String get speedAdjustedTime => 'Temps ajusté à la vitesse';

  @override
  String get speedAdjustedTimeOnSubtitle =>
      'Activé - le temps restant reflète la vitesse de lecture';

  @override
  String get speedAdjustedTimeOffSubtitle =>
      'Désactivé - affichage de la durée audio brute';

  @override
  String get buttonLayout => 'Disposition des boutons';

  @override
  String get buttonLayoutSubtitle =>
      'Comment les boutons d\'action sont disposés sur la carte';

  @override
  String get whenAbsorbed => 'Quand absorbé';

  @override
  String get whenAbsorbedInfoTitle => 'Quand absorbé';

  @override
  String get whenAbsorbedInfoContent =>
      'Contrôle ce qu’il arrive à une carte « en cours d’absorption » quand tu termines un livre ou un épisode.\n\nLes cartes terminées sont automatiquement retirées de ton écran Absorbing.';

  @override
  String get whenAbsorbedSubtitle =>
      'Ce qui arrive à la carte d’absorption quand un livre ou un épisode se termine';

  @override
  String get whenAbsorbedShowOverlay => 'Afficher la superposition';

  @override
  String get whenAbsorbedAutoRelease => 'Auto-release';

  @override
  String get mergeLibraries => 'Page d\'Absorption unifiée';

  @override
  String get mergeLibrariesInfoTitle => 'Page d\'Absorption unifiée';

  @override
  String get mergeLibrariesInfoContent =>
      'Quand activé, l’écran Absorbing affiche tous vos livres et podcasts en cours, provenant de toutes vos bibliothèques, dans une seule vue. Quand désactivé, il n’affiche que les éléments de la bibliothèque que vous avez actuellement sélectionnée.';

  @override
  String get mergeLibrariesOnSubtitle =>
      'La page d\'absorption affiche les éléments de toutes les bibliothèques';

  @override
  String get mergeLibrariesOffSubtitle =>
      'La page d\'Absorption ne montre que la bibliothèque actuelle';

  @override
  String get queueMode => 'Mode file d\'attente';

  @override
  String get queueModeInfoTitle => 'Mode file d\'attente';

  @override
  String get queueModeInfoOff => 'Désactivé';

  @override
  String get queueModeInfoOffDesc =>
      'La lecture s\'arrête à la fin du livre ou de l\'épisode en cours.';

  @override
  String get queueModeInfoManual => 'File d\'attente manuelle';

  @override
  String get queueModeInfoManualDesc =>
      'Vos cartes d\'absorption agissent comme une liste de lecture. Quand l\'une se termine, la prochaine carte non terminée se lance automatiquement. Ajoutez des éléments avec le bouton \"Ajouter à l\'Absorbation\" sur un livre ou un épisode et réorganisez à partir de l\'écran d\'absorption.';

  @override
  String get queueModeOff => 'Désactivé';

  @override
  String get queueModeManual => 'Manuel';

  @override
  String get queueModeAuto => 'Auto';

  @override
  String get queueModePlaylist => 'Liste de lecture';

  @override
  String get queueModeCollection => 'Collection';

  @override
  String get queueModeInfoPlaylist => 'File d\'attente de la playlist';

  @override
  String get queueModeInfoPlaylistDesc =>
      'Lit les éléments dans l’ordre depuis une playlist choisie, en sautant tout ce qui est déjà terminé. S’arrête à la fin de la liste.';

  @override
  String get queuePlaylistPickerTitle => 'Choisir une playlist';

  @override
  String get queuePlaylistNone => 'Aucune playlist sélectionnée';

  @override
  String queuePlaylistActiveLabel(String name) {
    return 'Playlist : $name';
  }

  @override
  String get queueModePlaylistHint =>
      'Démarrez une file de lecture en ouvrant une playlist depuis la page d’accueil.';

  @override
  String get exit => 'Quitter';

  @override
  String upNext(String label) {
    return 'Suivant : $label';
  }

  @override
  String get nothingUpNext => 'Rien à venir';

  @override
  String get showUpNextLabel => 'Afficher le suivant sur la page d\'absorption';

  @override
  String get openSeries => 'Open series';

  @override
  String get openPlaylist => 'Ouvrir une liste de lecture';

  @override
  String get openCollection => 'Ouvrir la collection';

  @override
  String get playlistPlayAction => 'Lire la playlist';

  @override
  String get playlistAllFinished => 'Tous les terminés';

  @override
  String get queueModeBooks => 'Livres';

  @override
  String get queueModePodcasts => 'Podcasts';

  @override
  String get autoDownloadQueue => 'File de téléchargement automatique';

  @override
  String get autoDownloadThisSeriesLabel =>
      'Télécharger automatiquement cette série';

  @override
  String get autoDownloadThisShowLabel =>
      'Télécharger automatiquement ce podcast';

  @override
  String get autoDownloadThisPlaylistLabel =>
      'Télécharger automatiquement cette playlist';

  @override
  String get autoDownloadThisCollectionLabel =>
      'Télécharger automatiquement cette collection';

  @override
  String autoDownloadQueueOnSubtitle(int count) {
    return 'Garder les $count prochains éléments téléchargés';
  }

  @override
  String get autoDownloadQueueOffSubtitle =>
      'Désactivé - téléchargements manuels uniquement';

  @override
  String get sectionPlayback => 'Lecture';

  @override
  String get sectionMediaControls => 'Contrôles multimédia';

  @override
  String get defaultSpeed => 'Vitesse par défaut';

  @override
  String get defaultSpeedSubtitle =>
      'Les nouveaux livres commencent à cette vitesse — chacun mémorise ensuite sa propre vitesse';

  @override
  String get skipBack => 'Reculer';

  @override
  String get skipForward => 'Avancer';

  @override
  String get longSkipButtons => 'Boutons de saut long';

  @override
  String get longSkipButtonsOnSubtitle =>
      'Activé - le lecteur affiche une seconde paire de sauts plus grands';

  @override
  String get longSkipButtonsOffSubtitle =>
      'Désactivé - juste les boutons de saut normaux';

  @override
  String get longSkipBack => 'Retour en arrière long';

  @override
  String get longSkipForward => 'Saut vers l\'avant long';

  @override
  String get coverShapeDefault => 'Défaut';

  @override
  String get coverShapeSquare => 'Carré';

  @override
  String get coverShapeRectangle => 'Rectangle';

  @override
  String get coverShapeLabel => 'Forme de couverture';

  @override
  String currentLibrarySettingsTitle(String name) {
    return 'Bibliothèque actuelle : $name';
  }

  @override
  String get currentLibrarySkipOverride => 'Longueurs de saut personnalisées';

  @override
  String get currentLibrarySkipOverrideOnSubtitle =>
      'Activé - cette bibliothèque utilise ses propres longueurs de saut';

  @override
  String get currentLibrarySkipOverrideOffSubtitle =>
      'Désactivé - cette bibliothèque utilise les longueurs de saut globales';

  @override
  String get currentLibrarySkipBack => 'Reculer';

  @override
  String get currentLibrarySkipForward => 'Avancer';

  @override
  String get chapterProgressInNotification =>
      'Progression du chapitre dans les notifications & Android Auto';

  @override
  String get chapterProgressOnSubtitle =>
      'Activé - notification & Android Auto montrent la progression du chapitre';

  @override
  String get chapterProgressOffSubtitle =>
      'Désactivé - ils montrent la progression du livre complet';

  @override
  String get chapterProgressInNotificationIos =>
      'Progression du chapitre sur l\'écran de verrouillage & CarPlay';

  @override
  String get chapterProgressOnSubtitleIos =>
      'Activé - l\'écran de verrouillage & CarPlay montrent la progression du chapitre';

  @override
  String get chapterProgressInNowPlayingBar =>
      'Chapter progress in now playing bar';

  @override
  String get chapterProgressInNowPlayingBarOnSubtitle =>
      'On - the bottom player shows current chapter progress';

  @override
  String get chapterProgressInNowPlayingBarOffSubtitle =>
      'Off - the bottom player shows full book progress';

  @override
  String get speedBookmarkInControls =>
      'Vitesse et signet dans les contrôles des médias';

  @override
  String get speedBookmarkOnSubtitle =>
      'Activé - la notification affiche la vitesse et le signet ; le saut de chapitre reste dans Android Auto';

  @override
  String get speedBookmarkOffSubtitle =>
      'Désactivé - la notification montre le saut de chapitre, la vitesse et le signet restent dans Android Auto';

  @override
  String get lockSeekBar => 'Verrouiller la barre de lecture';

  @override
  String get lockSeekBarOnSubtitle =>
      'Activé - la barre dans la notification, l\'écran de verrouillage et le mode voiture montre la progression mais ne peut pas être déplacée';

  @override
  String get lockSeekBarOffSubtitle =>
      'Off - drag the scrubber in the notification, lockscreen and car to jump around';

  @override
  String get autoRewindOnResume => 'Rembobiner lors de la reprise';

  @override
  String autoRewindOnSubtitle(String min, String max) {
    return 'Activé - ${min}s à ${max}s en fonction de la longueur de la pause';
  }

  @override
  String get autoRewindOffSubtitle => 'Désactivé';

  @override
  String get rewindRange => 'Plage de rembobinage';

  @override
  String get rewindAfterPausedFor => 'Rembobiner après une pause de';

  @override
  String get rewindAnyPause => 'N\'importe quelle durée';

  @override
  String get rewindAlwaysLabel => 'Toujours';

  @override
  String get rewindAlwaysDescription =>
      'Rembobine chaque fois que vous reprenez la lecture, même après de courtes interruptions';

  @override
  String rewindAfterDescription(String seconds) {
    return 'Rembobiner seulement après une pause de plus de $seconds seconde(s)';
  }

  @override
  String get chapterBarrier => 'Barrière de chapitre';

  @override
  String get chapterBarrierSubtitle =>
      'Ne pas rembobiner automatiquement après le début du chapitre en cours';

  @override
  String get rewindInstant => 'Instantané';

  @override
  String rewindPause(String duration) {
    return 'Pause de $duration';
  }

  @override
  String get rewindNoRewind => 'aucun rembobinage';

  @override
  String rewindSeconds(String seconds) {
    return 'Rembobinage de ${seconds}s';
  }

  @override
  String get sectionSleepTimer => 'Minuteur de veille';

  @override
  String get sleep => 'Veille';

  @override
  String get sleepTimer => 'Minuteur de veille';

  @override
  String get shakeDuringSleepTimer => 'Secouer pendant la mise en veille';

  @override
  String get shakeOff => 'Désactivé';

  @override
  String get shakeAddTime => 'Ajouter du temps';

  @override
  String get shakeReset => 'Réinitialiser';

  @override
  String get shakeAdds => 'Secouer ajoute';

  @override
  String shakeAddsValue(int minutes) {
    return '$minutes min';
  }

  @override
  String get shakeSensitivity => 'Intensité des vibrations';

  @override
  String get shakeSensitivityVeryLow => 'Très basse';

  @override
  String get shakeSensitivityLow => 'Basse';

  @override
  String get shakeSensitivityMedium => 'Moyenne';

  @override
  String get shakeSensitivityHigh => 'Haute';

  @override
  String get shakeSensitivityVeryHigh => 'Très haute';

  @override
  String get resetTimerOnPause => 'Réinitialiser le minuteur en cas de pause';

  @override
  String get resetTimerOnPauseOnSubtitle =>
      'Le minuteur redémarre à partir de la durée complète lorsque vous reprenez';

  @override
  String get resetTimerOnPauseOffSubtitle =>
      'Le minuteur se poursuit à partir de l\'endroit où il s\'est arrêté';

  @override
  String get fadeVolumeBeforeSleep => 'Fondu du volume avant la mise en veille';

  @override
  String get fadeVolumeOnSubtitle =>
      'Diminue progressivement le volume au cours des 30 dernières secondes';

  @override
  String get fadeVolumeOffSubtitle =>
      'La lecture s\'arrête immédiatement à la fin du minuteur';

  @override
  String get autoSleepTimer => 'Minuteur de mise en veille automatique';

  @override
  String autoSleepTimerOnSubtitle(String start, String end, int duration) {
    return '$start - $end - $duration min';
  }

  @override
  String get autoSleepTimerOffSubtitle =>
      'Démarrer automatiquement un minuteur de veille pendant une fenêtre de temps';

  @override
  String get windowStart => 'Début de la fenêtre';

  @override
  String get windowEnd => 'Fin de la fenêtre';

  @override
  String get timerDuration => 'Durée du minuteur';

  @override
  String get timer => 'Minuteur';

  @override
  String get endOfChapter => 'Fin du chapitre';

  @override
  String startMinTimer(int minutes) {
    return 'Démarrer le minuteur de $minutes min';
  }

  @override
  String sleepAfterChapters(int count, String label) {
    return 'Mise en veille après $count $label';
  }

  @override
  String get addMoreTime => 'Ajouter plus de temps';

  @override
  String get cancelTimer => 'Annuler le minuteur';

  @override
  String chaptersLeftCount(int count) {
    return '$count ch restants';
  }

  @override
  String get sectionDownloadsAndStorage => 'Téléchargements et stockage';

  @override
  String get downloadOverWifiOnly => 'Réseau de téléchargement';

  @override
  String get downloadOverWifiOnSubtitle => 'Wi-Fi uniquement';

  @override
  String get downloadOverWifiOffSubtitle => 'N\'importe quelle connexion';

  @override
  String get autoDownloadOnWifi =>
      'Télécharger automatiquement les livres que vous démarrez';

  @override
  String get autoDownloadOnWifiInfoTitle =>
      'Télécharger automatiquement les livres que vous démarrez';

  @override
  String get autoDownloadOnWifiInfoContent =>
      'Lorsque vous commencez à lire un livre, ce dernier se télécharge en arrière‑plan afin que vous l’ayez hors ligne sans lancer le téléchargement vous‑même. Ces téléchargements suivent votre réglage Réseau de téléchargement ci‑dessous, donc réglez‑le sur Toute connexion si vous voulez qu’ils s’exécutent aussi en données mobiles.';

  @override
  String get autoDownloadOnWifiOnSubtitle =>
      'Streamed books download in the background automatically';

  @override
  String get autoDownloadOnWifiOffSubtitle => 'Désactivé';

  @override
  String get concurrentDownloads => 'Téléchargements simultanés';

  @override
  String get autoDownload => 'Téléchargement automatique';

  @override
  String get autoDownloadSubtitle =>
      'Activer par série, podcast, playlist ou collection à partir de leurs pages de détails';

  @override
  String get autoDownloadEnabledFor => 'Activé pour';

  @override
  String get autoDownloadEnabledForNone => 'Rien pour l\'instant';

  @override
  String get autoDownloadSourceUnnamed => 'Pas encore chargées';

  @override
  String get keepNext => 'Garder le suivant';

  @override
  String get keepNextInfoTitle => 'Garder le suivant';

  @override
  String get keepNextInfoContent =>
      'Le nombre d\'éléments à garder téléchargés, y compris celui que vous écoutez actuellement. Par exemple, « Garder les 3 prochains » signifie que le livre actuel plus les 2 suivants de cette série, le podcast, la playlist ou la collection resteront téléchargés. Ceci s\'applique à chaque téléchargement automatique activé.';

  @override
  String get deleteAbsorbedDownloads =>
      'Supprimer les téléchargements absorbés';

  @override
  String get deleteAbsorbedDownloadsInfoTitle =>
      'Supprimer les téléchargements absorbés';

  @override
  String get deleteAbsorbedDownloadsInfoContent =>
      'Lorsque cette option est activée, les livres téléchargés ou les épisodes sont automatiquement supprimés de cet appareil une fois que vous les avez terminés dans Absorb. Terminer un élément sur le web ou un autre appareil ne supprimera pas son téléchargement ici.';

  @override
  String get deleteAbsorbedOnSubtitle =>
      'Les éléments achevés sont supprimés pour libérer de l\'espace';

  @override
  String get deleteAbsorbedOffSubtitle =>
      'Désactivé - les téléchargements terminés sont conservés';

  @override
  String get downloadLocation => 'Emplacement de téléchargement';

  @override
  String get storageUsed => 'Stockage utilisé';

  @override
  String storageUsedByDownloads(String size) {
    return '$size utilisé(s) par les téléchargements';
  }

  @override
  String storageFreeOfTotal(String free, String total) {
    return '$free libre(s) sur $total';
  }

  @override
  String get manageDownloads => 'Gérer les téléchargements';

  @override
  String get streamingCache => 'Cache de diffusion en continu';

  @override
  String get streamingCacheInfoTitle => 'Cache de diffusion en continu';

  @override
  String get streamingCacheInfoContent =>
      'Cache le flux audio vers le disque afin qu\'il ne soit pas téléchargé à nouveau si vous revenez en arrière ou réécoutez des sections. Le cache est géré automatiquement - les fichiers les plus anciens sont supprimés lorsque la taille limite est atteinte. Ceci est séparé des livres téléchargés complètement.';

  @override
  String get streamingCacheOff => 'Désactivé';

  @override
  String get streamingCacheOffSubtitle =>
      'Désactivé - l\'audio est diffusé sans mise en cache';

  @override
  String streamingCacheOnSubtitle(int size) {
    return '$size Mo - l\'audio diffusé récemment est mis en cache sur le disque';
  }

  @override
  String get clearCache => 'Effacer le cache';

  @override
  String get streamingCacheCleared => 'Cache de diffusion vidé';

  @override
  String get sectionLibrary => 'Bibliothèque';

  @override
  String get hideEbookOnlyTitles => 'Masquer les titres des ebooks seuls';

  @override
  String get hideEbookOnlyOnSubtitle =>
      'Les livres sans fichiers audio sont cachés';

  @override
  String get hideEbookOnlyOffSubtitle =>
      'Désactivé - tous les éléments de la bibliothèque sont affichés';

  @override
  String get showGoodreadsButton => 'Afficher le bouton Goodreads';

  @override
  String get showGoodreadsOnSubtitle =>
      'La fiche de détail du livre affiche un lien vers Goodreads';

  @override
  String get showGoodreadsOffSubtitle =>
      'Désactivé - Bouton « Goodreads» masqué';

  @override
  String get sectionPermissions => 'Permissions';

  @override
  String get notifications => 'Notifications';

  @override
  String get notificationsSubtitle =>
      'Pour l\'avancement des téléchargements et le contrôle de lecture';

  @override
  String get notificationsAlreadyEnabled => 'Notifications déjà activées';

  @override
  String get unrestrictedBattery => 'Ne pas limiter l\'usage de la batterie';

  @override
  String get unrestrictedBatterySubtitle =>
      'Évite qu\'Android arrête la lecture en arrière-plan';

  @override
  String get batteryAlreadyUnrestricted =>
      'L\'usage de la batterie n\'est pas limité';

  @override
  String get sectionIssuesAndSupport => 'Problèmes et assistance';

  @override
  String get bugsAndFeatureRequests => 'Bugs et demandes de fonctionnalités';

  @override
  String get bugsAndFeatureRequestsSubtitle => 'Ouvrir un ticket sur GitHub';

  @override
  String get joinDiscord => 'Rejoindre le serveur Discord';

  @override
  String get joinDiscordSubtitle => 'Communauté, assistance et mises à jour';

  @override
  String get contact => 'Contact';

  @override
  String get contactSubtitle =>
      'Envoyer les informations de l\'appareil par e-mail';

  @override
  String get enableLogging => 'Activer la journalisation';

  @override
  String get enableLoggingOnSubtitle =>
      'Activé - journaux enregistrés dans un fichier (redémarrez pour appliquer)';

  @override
  String get enableLoggingOffSubtitle => 'Désactivé - pas de logs capturés';

  @override
  String get loggingEnabledSnackbar =>
      'Journalisation activée - redémarrez l\'application pour démarrer l\'enregistrement';

  @override
  String get loggingDisabledSnackbar =>
      'Journalisation désactivée - redémarrez l\'application pour arrêter l\'enregistrement';

  @override
  String get sendLogs => 'Envoyer les journaux';

  @override
  String get sendLogsSubtitle =>
      'Partager le fichier de journalisation en pièce jointe';

  @override
  String failedToShare(String error) {
    return 'Échec du partage : $error';
  }

  @override
  String get clearLogs => 'Vider les journaux';

  @override
  String get logsCleared => 'Journaux effacés';

  @override
  String get sectionAdvanced => 'Avancé';

  @override
  String get localServer => 'Serveur local';

  @override
  String get localServerInfoTitle => 'Serveur local';

  @override
  String get localServerInfoContent =>
      'Si vous faites tourner votre serveur Audiobookshelf chez vous, vous pouvez définir ici une URL locale/LAN. Absorb basculera automatiquement sur cette connexion locale, plus rapide, lorsqu’il détecte que vous êtes sur votre réseau domestique, et reviendra à votre URL distante quand vous êtes ailleurs.';

  @override
  String get localServerOnConnectedSubtitle => 'Connecté via le serveur local';

  @override
  String get localServerOnRemoteSubtitle =>
      'Activé - utilise le serveur distant';

  @override
  String get localServerOffSubtitle =>
      'Basculement automatique vers un serveur LAN lorsque vous êtes sur votre Wi‑Fi domestique';

  @override
  String get localServerUrlLabel => 'URL locale du serveur';

  @override
  String get localServerUrlHint => 'http://192.168.1.100:13378';

  @override
  String get localServerUrlSetSnackbar =>
      'URL du serveur local définie - la connexion se fera automatiquement lorsque vous serez sur votre réseau domestique';

  @override
  String get disableAudioFocus => 'Désactiver le focus audio';

  @override
  String get disableAudioFocusInfoTitle => 'Audio Focus';

  @override
  String get disableAudioFocusInfoContent =>
      'Par défaut, Android donne le « focus » audio à une application à la fois - quand Absorb joue, d\'autres audio (musique, vidéos) seront mis en pause. La désactivation du focus audio permet à Absorb de jouer en même temps que les autres applications. Les appels téléphoniques mettront toujours en pause la lecture quel que soit la valeur de ce paramètre.';

  @override
  String get disableAudioFocusOnSubtitle =>
      'On - plays alongside other audio (still pauses for calls)';

  @override
  String get disableAudioFocusOffSubtitle =>
      'Off - other audio pauses when Absorb plays';

  @override
  String get restartRequired => 'Redémarrage requis';

  @override
  String get restartRequiredContent =>
      'Le changement sur le focus audio nécessite un redémarrage complet pour prendre effet. Fermer l\'application maintenant ?';

  @override
  String get closeApp => 'Fermer l\'application';

  @override
  String get trustAllCertificates => 'Faire confiance à tous les certificats';

  @override
  String get trustAllCertificatesInfoTitle => 'Certificats auto-signés';

  @override
  String get mp3IndexSeeking => 'Recherche d\'index MP3';

  @override
  String get mp3IndexSeekingInfoTitle => 'MP3 Index Seeking';

  @override
  String get mp3IndexSeekingInfoContent =>
      'Activez cette option uniquement si vous avez des fichiers MP3 qui ne se positionnent pas à la bonne position. Le positionnement inexact provient généralement de MP3 à débit variable (VBR). L\'index cherchant à construire une carte temporelle exacte lorsque le fichier est lu, sauter près de la fin d\'un grand MP3 peut prendre un moment - surtout en streaming, car le fichier doit être lu jusqu\'à ce point. Prend effet la prochaine fois qu\'un livre ou un podcast commence.';

  @override
  String get mp3IndexSeekingOnSubtitle =>
      'On - exact seeking for VBR MP3 files';

  @override
  String get mp3IndexSeekingOffSubtitle => 'Off - normal seeking';

  @override
  String get trustAllCertificatesInfoContent =>
      'Activez cette option si votre serveur Audiobookshelf utilise un certificat auto-signé ou une AC racine personnalisée. Lorsque cette option est activée, Absorb ignorera la vérification du certificat TLS pour toutes les connexions. N\'activez cette option que si vous faites confiance à votre réseau.';

  @override
  String get trustAllCertificatesOnSubtitle =>
      'On - accepting all certificates';

  @override
  String get trustAllCertificatesOffSubtitle =>
      'Off - only trusted certificates accepted';

  @override
  String get supportTheDev => 'Soutenir le développeur';

  @override
  String get buyMeACoffee => 'Offrez moi un café';

  @override
  String appVersionFormat(String version) {
    return 'Absorb v$version';
  }

  @override
  String appVersionWithServerFormat(String version, String serverVersion) {
    return 'Absorb v$version - Serveur $serverVersion';
  }

  @override
  String get backupAndRestore => 'Sauvegarder & Restaurer';

  @override
  String get backupAndRestoreSubtitle =>
      'Sauvegarder ou restaurer tous vos paramètres dans un fichier';

  @override
  String get backUp => 'Sauvegarder';

  @override
  String get restore => 'Restaurer';

  @override
  String get allBookmarks => 'Tous les signets';

  @override
  String get allBookmarksSubtitle => 'Voir les signets de tous les livres';

  @override
  String get switchAccount => 'Changer de compte';

  @override
  String get addAccount => 'Ajouter un compte';

  @override
  String get logOut => 'Se déconnecter';

  @override
  String get includeLoginInfoTitle => 'Inclure les informations de connexion ?';

  @override
  String get includeLoginInfoContent =>
      'Souhaitez‑vous inclure les identifiants de connexion de tous vos comptes enregistrés dans la sauvegarde ?\n\nCela facilite la restauration sur un nouvel appareil, mais le fichier contiendra vos jetons d’authentification.';

  @override
  String get noSettingsOnly => 'Non, paramètres uniquement';

  @override
  String get yesIncludeAccounts => 'Oui, inclure les comptes';

  @override
  String get backupSavedWithAccounts =>
      'Sauvegarde enregistrée (avec les comptes)';

  @override
  String get backupSavedSettingsOnly =>
      'Sauvegarde enregistrée (paramètres seulement)';

  @override
  String backupFailed(String error) {
    return 'Échec de la sauvegarde : $error';
  }

  @override
  String get restoreBackupTitle => 'Restaurer la sauvegarde ?';

  @override
  String get restoreBackupContent =>
      'Tous vos paramètres actuels seront remplacés par ceux de la sauvegarde.';

  @override
  String fromAbsorbVersion(String version) {
    return 'Depuis Absorb v$version';
  }

  @override
  String restoreAccountsChip(int count) {
    return '$count compte(s)';
  }

  @override
  String restoreBookmarksChip(int count) {
    return 'Signets pour $count livre(s)';
  }

  @override
  String get restoreCustomHeadersChip => 'En-têtes personnalisés';

  @override
  String get invalidBackupFile => 'Fichier de sauvegarde invalide';

  @override
  String get settingsRestoredSuccessfully =>
      'Les paramètres ont été restaurés avec succès';

  @override
  String restoreFailed(String error) {
    return 'Échec de la restauration : $error';
  }

  @override
  String get logOutTitle => 'Se déconnecter ?';

  @override
  String get logOutContent =>
      'Cela vous déconnectera. Vos téléchargements resteront sur cet appareil.';

  @override
  String get signOut => 'Se déconnecter';

  @override
  String get changePasswordTitle => 'Modifier le mot de passe';

  @override
  String get changePasswordSubtitle =>
      'Mettre à jour votre mot de passe de lecture audio en toute sécurité';

  @override
  String get currentPassword => 'Mot de passe actuel';

  @override
  String get newPassword => 'Nouveau mot de passe';

  @override
  String get confirmNewPassword => 'Confirmez le nouveau mot de passe';

  @override
  String get passwordChangeEffect =>
      'La modification de votre mot de passe déconnecte vos autres sessions d\'Audiobookshelf. Cet appareil reste connecté.';

  @override
  String get passwordFieldsRequired =>
      'Remplir tous les champs de mot de passe';

  @override
  String get passwordsDoNotMatch =>
      'Les nouveaux mots de passe ne correspondent pas';

  @override
  String get passwordChanged =>
      'Mot de passe modifié. Les autres appareils connectés ont été déconnectés.';

  @override
  String get passwordInvalid => 'Le mot de passe actuel est incorrect';

  @override
  String get passwordChangeUnsupported =>
      'Cette version du serveur ne prend pas en charge les changements de mot de passe sécurisés dans Absorb';

  @override
  String get passwordChangeFailed => 'Impossible de changer votre mot de passe';

  @override
  String get otherUserPasswordResetWarning =>
      'La modification de ce mot de passe déconnecte l\'utilisateur sur tous les autres appareils.';

  @override
  String get manageSessionsTitle => 'Appareils connectés';

  @override
  String get manageSessionsSubtitle =>
      'Examiner et supprimer les sessions Audiobookshelf';

  @override
  String get sessionsCurrent => 'Appareil actuel';

  @override
  String get sessionsUnknownDevice => 'Appareil inconnu';

  @override
  String sessionsLastActive(String date) {
    return 'Dernière activité le $date';
  }

  @override
  String get sessionsNone => 'Aucune session active';

  @override
  String get sessionsLoadMore => 'Charger plus';

  @override
  String get sessionsUnsupported =>
      'La gestion des sessions nécessite Audiobookshelf 2.36 ou plus récentes.';

  @override
  String get sessionsLoadFailed =>
      'Impossible de charger les appareils connectés';

  @override
  String get sessionsLegacyNotice =>
      'Cette connexion n\'a pas de session d\'actualisation, donc Absorb ne peut pas identifier cet appareil dans la liste.';

  @override
  String get sessionsRemove => 'Déconnecter l\'appareil';

  @override
  String get sessionsRemoveTitle => 'Déconnecter cet appareil ?';

  @override
  String get sessionsRemoveContent =>
      'Cela supprime sa session de rafraîchissement. Son accès actuel peut continuer à fonctionner jusqu\'à l\'expiration de ce jeton de courte durée.';

  @override
  String get sessionsRemoved => 'Appareil déconnecté';

  @override
  String get sessionsRemoveFailed => 'Impossible de déconnecter cet appareil';

  @override
  String get sessionsSignOutAll => 'Déconnecter tous les appareils';

  @override
  String get sessionsSignOutAllTitle => 'Déconnexion partout ?';

  @override
  String get sessionsSignOutAllContent =>
      'Cela supprime toutes les sessions de rafraîchissement, y compris cet appareil. Les jetons d\'accès existants peuvent fonctionner jusqu\'à ce qu\'ils expirent.';

  @override
  String podcastScheduleServerTime(String timeZone) {
    return 'Le calendrier utilise l\'heure du serveur ($timeZone)';
  }

  @override
  String get podcastScheduleServerTimeUnknown =>
      'Le calendrier utilise l\'heure du serveur';

  @override
  String get editServerAddressTitle => 'Modifier l\'adresse du serveur';

  @override
  String editServerAddressSubtitle(String username) {
    return 'Mettre à jour l\'adresse de $username. Utilisez ceci si l\'adresse de votre serveur a changé - c\'est toujours le même serveur, juste une nouvelle URL. Vos statistiques et vos téléchargements sont conservés.';
  }

  @override
  String get editServerAddressField => 'Adresse du serveur';

  @override
  String get editServerAddressUpdated => 'Server address updated';

  @override
  String get editServerAddressFailed => 'Couldn\'t update server address';

  @override
  String get editServerAddressAction => 'Edit server address';

  @override
  String get editServerConnectionTitle => 'Edit Server Connection';

  @override
  String editServerConnectionSubtitle(String username) {
    return 'Update the server address and custom headers for $username. Your stats and downloads are kept.';
  }

  @override
  String get editServerConnectionAction => 'Edit server connection';

  @override
  String get editServerConnectionUpdated => 'Server connection updated';

  @override
  String get editServerConnectionFailed => 'Couldn\'t update server connection';

  @override
  String get editCustomHeadersDescription =>
      'Used for Cloudflare tunnels or reverse proxies. These headers apply only to this saved account.';

  @override
  String get removeAccountAction => 'Supprimer le compte';

  @override
  String get removeAccountTitle => 'Supprimer le compte ?';

  @override
  String removeAccountContent(String username, String server) {
    return 'Supprimer $username sur $server des comptes enregistrés ?\n\nVous pouvez toujours l\'ajouter plus tard en vous connectant à nouveau.';
  }

  @override
  String get switchAccountTitle => 'Changer de compte ?';

  @override
  String switchAccountContent(String username, String server) {
    return 'Passer à $username sur $server?\n\nVotre lecture actuelle sera arrêtée et l\'application se rechargera avec les données de l\'autre compte.';
  }

  @override
  String get switchButton => 'Changer';

  @override
  String get downloadLocationSheetTitle => 'Emplacement des téléchargements';

  @override
  String get downloadLocationSheetSubtitle =>
      'Choose where audiobooks are saved';

  @override
  String get currentLocation => 'Emplacement actuel';

  @override
  String get existingDownloadsWarning =>
      'Les téléchargements existants restent à leur emplacement actuel. Seuls les nouveaux téléchargements utilisent le nouveau chemin.';

  @override
  String get chooseFolder => 'Choisir un dossier';

  @override
  String get chooseDownloadFolder => 'Choisir le dossier de téléchargement';

  @override
  String get storagePermissionDenied =>
      'Storage permission permanently denied - enable it in app settings';

  @override
  String get openSettings => 'Ouvrir les paramètres';

  @override
  String get storagePermissionRequired =>
      'Storage permission is required for custom download locations';

  @override
  String get cannotWriteToFolder =>
      'Impossible d\'écrire dans ce dossier - choisissez un autre emplacement ou accordez l\'accès aux fichiers dans les paramètres système';

  @override
  String downloadLocationSetTo(String label) {
    return 'Download location set to $label';
  }

  @override
  String get resetToDefault => 'Réinitialiser aux valeurs par défaut';

  @override
  String get resetToDefaultStorage => 'Reset to default storage';

  @override
  String legacyDownloadsNotice(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count téléchargements se trouvent dans un ancien dossier personnalisé qui ne peut plus être ouvert. Téléchargez-les à nouveau ou ignorez cette notification.',
      one:
          '1 téléchargement se trouve dans un ancien dossier personnalisé qui ne peut plus être ouvert. Téléchargez-le à nouveau ou ignorez cette notification.',
    );
    return '$_temp0';
  }

  @override
  String get redownload => 'Re-télécharger';

  @override
  String get redownloadStarted => 'Re-téléchargement';

  @override
  String get dismiss => 'Dismiss';

  @override
  String get tipsAndHiddenFeatures => 'Tips & Hidden Features';

  @override
  String get tipsSubtitle => 'Get the most out of Absorb';

  @override
  String get adminTitle => 'Administrateur du serveur';

  @override
  String get adminTasksTitle => 'Activité du serveur';

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
  String get adminTasksRecent => 'Activité récente du serveur';

  @override
  String get adminTasksEmpty => 'No server tasks are running';

  @override
  String adminTaskScanSummary(int added, int updated, int missing) {
    return '$added added - $updated updated - $missing missing';
  }

  @override
  String get adminServer => 'Serveur';

  @override
  String get adminVersion => 'Version';

  @override
  String get adminUsers => 'Utilisateurs';

  @override
  String get adminOnline => 'En ligne';

  @override
  String get adminBackup => 'Sauvegarder';

  @override
  String get adminPurgeCache => 'Purger le cache';

  @override
  String get adminManage => 'Gérer';

  @override
  String adminUsersSubtitle(int userCount, int onlineCount) {
    return '$userCount comptes - $onlineCount en ligne';
  }

  @override
  String get adminPodcasts => 'Podcasts';

  @override
  String get adminPodcastsSubtitle => 'Search, add & manage shows';

  @override
  String get adminScan => 'Scanner';

  @override
  String get adminScanning => 'Scanning...';

  @override
  String get adminMatchAll => 'Match All';

  @override
  String get adminMatching => 'Matching...';

  @override
  String get adminMatchAllTitle => 'Match All Items?';

  @override
  String adminMatchAllContent(String name) {
    return 'Faire correspondre les métadonnées de tous les éléments dans $name ? Cela peut prendre un certain temps.';
  }

  @override
  String adminScanStarted(String name) {
    return 'Scan started for $name';
  }

  @override
  String get adminBackupCreated => 'Sauvegarde créée';

  @override
  String get adminBackupFailed => 'Échec de la sauvegarde';

  @override
  String get adminCachePurged => 'Cache purgé';

  @override
  String get adminRmab => 'ReadMeABook';

  @override
  String get adminRmabSubtitle => 'Open in app';

  @override
  String get adminRmabAdd => 'Add ReadMeABook integration';

  @override
  String get adminRmabUrlTitle => 'URL ReadMeABook';

  @override
  String get adminRmabUrlHelp =>
      'Paste your URL with login token. Generate one in RMAB, Admin, Users.';

  @override
  String get adminRmabUrlHint => 'https://rmab.example.com/?token=...';

  @override
  String get adminRmabInvalidUrl => 'Enter a valid http(s) URL';

  @override
  String get adminRmabSaved => 'ReadMeABook saved';

  @override
  String get adminRmabRemoved => 'ReadMeABook removed';

  @override
  String get adminRmabReload => 'Recharger';

  @override
  String get adminRmabLoadFailed =>
      'Couldn\'t load ReadMeABook. Check your URL.';

  @override
  String get adminRmabConnected => 'Connecté';

  @override
  String get adminRmabAskAdmin => 'Get a login URL from your server admin';

  @override
  String get adminRmabUrlHelpUser =>
      'Obtenir une URL de connexion depuis l\'administrateur de votre serveur. Ils en génèrent une dans RMAB > Admin > Utilisateurs.';

  @override
  String get adminRmabSettingsInfo =>
      'ReadMeABook est un service auto-hébergé pour demander et télécharger des livres audio. Il doit être installé et configuré par l\'administrateur de votre serveur.';

  @override
  String get rmabConfigTitle => 'Connecter ReadMeABook';

  @override
  String get rmabConfigExplainerAdmin =>
      'ReadMeABook est un service auto-hébergé pour demander des livres audio. Générez un jeton d\'API dans RMAB sous Tableau de bord Admin > Paramètres > API, puis collez l\'URL du serveur et le jeton ci-dessous. Absorb n\'héberge ni ne télécharge aucun contenu, il envoie simplement des requêtes à votre serveur.';

  @override
  String get rmabConfigExplainerUser =>
      'ReadMeABook est un service auto-hébergé pour demander des livres audio. Demandez à l\'administrateur de votre serveur l\'URL RMAB et un jeton d\'API. Absorb n\'héberge ni ne télécharge aucun contenu, il envoie simplement des requêtes à votre serveur.';

  @override
  String get rmabConfigLearnMore => 'En savoir plus sur ReadMeABook';

  @override
  String get rmabConfigBaseUrlLabel => 'URL du serveur RMAB';

  @override
  String get rmabConfigBaseUrlHint => 'https://rmab.exemple.com';

  @override
  String get rmabConfigTokenLabel => 'Jeton d\'API';

  @override
  String get rmabConfigTokenHint => 'rmab_...';

  @override
  String get rmabConfigLegacyUrlLabel =>
      'URL de connexion à l\'interface Web (facultatif)';

  @override
  String get rmabConfigLegacyUrlHint => 'https://rmab.exemple.com/?token=...';

  @override
  String get rmabConfigLegacyUrlHelp =>
      'Collez votre URL de connexion automatique pour que vous soyez connecté dans \"Ouvrir dans la vue du navigateur\". Laissez vide pour utiliser une connexion normale.';

  @override
  String get rmabConfigHeadersHelp =>
      'En-têtes supplémentaires envoyés avec chaque requête ReadMeABook pour les proxy inversés comme Cloudflare Access.';

  @override
  String get rmabConfigConnect => 'Connecter';

  @override
  String get rmabConfigDisconnect => 'Déconnecter';

  @override
  String get rmabConfigOpenWebView => 'Ouvrir dans la vue du navigateur';

  @override
  String rmabConfigConnectedAs(String name) {
    return 'Connecté en tant que $name';
  }

  @override
  String get rmabConfigErrorInvalidUrl => 'Entrez une URL http(s) valide';

  @override
  String get rmabConfigErrorMissingToken => 'Entrez votre jeton API';

  @override
  String get rmabConfigErrorUnauthorized => 'Jeton rejeté par le serveur';

  @override
  String get rmabConfigErrorForbidden =>
      'Ce jeton n\'est pas autorisé pour cette action';

  @override
  String get rmabConfigErrorNetwork =>
      'Impossible d\'accéder à RMAB. Vérifiez l\'URL.';

  @override
  String get rmabConfigErrorGeneric => 'Connexion impossible';

  @override
  String get rmabConfigSavedSnackbar => 'ReadMeABook connecté';

  @override
  String get rmabConfigDisconnectedSnackbar => 'ReadMeABook déconnecté';

  @override
  String get rmabRequestCta => 'Demander via ReadMeABook';

  @override
  String get rmabSearchHeader => 'Demander via ReadMeABook';

  @override
  String get rmabSearchHint => 'Rechercher par titre ou auteur';

  @override
  String get rmabSearchEmpty =>
      'Aucune correspondance sur votre serveur ReadMeABook';

  @override
  String get rmabSearchError => 'Impossible de rechercher dans ReadMeABook';

  @override
  String get rmabSearchPrompt => 'Tapez un titre ou un auteur à rechercher';

  @override
  String get rmabSearchFooterPrompt => 'Vous cherchez autre chose ?';

  @override
  String rmabSearchFooterCta(String query) {
    return 'Rechercher \"$query\" sur ReadMeABook';
  }

  @override
  String get rmabBookDetailExplainer =>
      'Cette demande sera envoyée via votre serveur ReadMeABook. L\'administrateur l\'examinera et la traitera. Vous pouvez suivre son évolution dans « Mes demandes » dans la section ReadMeABook.';

  @override
  String get rmabBookAlreadyAvailable => 'Déjà dans votre bibliothèque';

  @override
  String get rmabBookAlreadyRequested => 'Déjà demandé';

  @override
  String get rmabRequestSubmitting => 'Soumission…';

  @override
  String get rmabRequestSent => 'Demande envoyée';

  @override
  String get rmabRequestErrorAlreadyAvailable => 'Déjà dans votre bibliothèque';

  @override
  String get rmabRequestErrorBeingProcessed => 'Déjà traitée';

  @override
  String get rmabRequestErrorDuplicate => 'Vous avez déjà demandé ceci';

  @override
  String get rmabRequestErrorValidation => 'Impossible d\'envoyer la requête';

  @override
  String get rmabRequestErrorUserNotFound =>
      'Le jeton utilisateur n\'existe plus. Reconnectez ReadMeABook.';

  @override
  String get rmabRequestErrorIgnored => 'This book is on your ignore list';

  @override
  String get rmabRequestErrorGeneric => 'Couldn\'t send the request';

  @override
  String get rmabRequestErrorTokenRejected =>
      'Token rejected by server. Reconnect ReadMeABook.';

  @override
  String get rmabMyRequestsTab => 'Mes demandes';

  @override
  String get rmabSetupTab => 'Configuration';

  @override
  String get rmabMyRequestsEmpty => 'You haven\'t requested any books yet';

  @override
  String get rmabMyRequestsError => 'Couldn\'t load requests';

  @override
  String get rmabMyRequestsRefresh => 'Actualiser';

  @override
  String get rmabRequestDetailTitle => 'Détails de la requête';

  @override
  String get rmabRequestDetailStatus => 'Statut';

  @override
  String get rmabRequestDetailRequestedOn => 'Demandé le';

  @override
  String get rmabRequestDetailCompletedOn => 'Complétée le';

  @override
  String get rmabRequestDetailProgress => 'Progression';

  @override
  String get rmabStatusActive => 'In progress';

  @override
  String get rmabStatusWaiting => 'Waiting';

  @override
  String get rmabStatusAvailable => 'Disponible';

  @override
  String get rmabStatusDownloaded => 'Téléchargé';

  @override
  String get rmabStatusFailed => 'Échec';

  @override
  String get rmabStatusCancelled => 'Annulé';

  @override
  String get rmabStatusDenied => 'Refusé';

  @override
  String get rmabStatusUnknown => 'Inconnu';

  @override
  String narratedBy(String narrator) {
    return 'Narrated by $narrator';
  }

  @override
  String get onAudible => 'sur Audible';

  @override
  String percentComplete(String percent) {
    return '$percent% complete';
  }

  @override
  String get absorbing => 'Absorption ...';

  @override
  String get absorbAgain => 'Absorber à nouveau';

  @override
  String get absorb => 'Absorb';

  @override
  String get ebookOnlyNoAudio => 'eBook Only - No Audio';

  @override
  String get fullyAbsorbed => 'Entièrement absorbé';

  @override
  String get fullyAbsorbAction => 'Absorber entièrement';

  @override
  String get removeFromAbsorbing => 'Remove from Absorbing';

  @override
  String get addToAbsorbing => 'Ajouter à l\'Absorption';

  @override
  String get removedFromAbsorbing => 'Removed from Absorbing';

  @override
  String get addedToAbsorbing => 'Added to Absorbing';

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
  String get addToPlaylist => 'Ajouter à la liste de lecture';

  @override
  String get addToCollection => 'Add to Collection';

  @override
  String get downloadEbook => 'Télécharger l\'eBook';

  @override
  String get downloadEbookAgain => 'Download eBook Again';

  @override
  String get resetProgress => 'Réinitialiser la progression';

  @override
  String get lookupLocalMetadata => 'Lookup Local Metadata';

  @override
  String get reLookupLocalMetadata => 'Re-Lookup Local Metadata';

  @override
  String get clearLocalMetadata => 'Effacer les métadonnées locales';

  @override
  String get searchOnGoodreads => 'Rechercher sur Goodreads';

  @override
  String get editServerDetails => 'Edit Server Details';

  @override
  String get encodeTab => 'Encode';

  @override
  String get codec => 'Codec';

  @override
  String get bitrate => 'Bitrate';

  @override
  String get channels => 'Channels';

  @override
  String get mono => 'Mono';

  @override
  String get stereo => 'Stéréo';

  @override
  String get startM4bEncode => 'Commencer l\'encodage M4B';

  @override
  String get encodeStarted => 'M4B encode started';

  @override
  String get encodeFailed => 'Failed to start encode';

  @override
  String get encodeFinished => 'M4B encode finished';

  @override
  String get currentlyLabel => 'Actuellement :';

  @override
  String encodeOutputPathNote(String path) {
    return 'Finished M4B will be put into your audiobook folder at: $path/';
  }

  @override
  String encodeBackupNote(String itemId) {
    return 'Une sauvegarde de vos fichiers audio d\'origine sera stockée dans : /metadata/cache/items/$itemId/. Assurez-vous de purger périodiquement le cache des éléments.';
  }

  @override
  String get encodeTimeNote => 'Encoding can take up to 30 minutes.';

  @override
  String get encodeRescanNote =>
      'If you have the watcher disabled you will need to re-scan this audiobook afterwards.';

  @override
  String get aboutSection => 'À propos';

  @override
  String chaptersCount(int count) {
    return 'Chapitres ($count)';
  }

  @override
  String audioTracksCount(int count) {
    return 'Audio Tracks ($count)';
  }

  @override
  String libraryFilesCount(int count) {
    return 'Library Files ($count)';
  }

  @override
  String get chapters => 'Chapitres';

  @override
  String get noChaptersBook => 'Ce livre n\'a pas de chapitres';

  @override
  String get noChaptersPodcast => 'Ce podcast n\'a pas de chapitres';

  @override
  String get failedToLoad => 'Échec du chargement';

  @override
  String startedDate(String date) {
    return 'Commencé le $date';
  }

  @override
  String finishedDate(String date) {
    return 'Achevé le $date';
  }

  @override
  String andCountMore(int count) {
    return 'et $count de plus';
  }

  @override
  String get markAsFullyAbsorbedQuestion => 'Mark as Fully Absorbed?';

  @override
  String get markAsFullyAbsorbedContent =>
      'This will set your progress to 100% and stop playback if this book is playing.';

  @override
  String get markedAsFinishedNiceWork => 'Marked as finished - nice work!';

  @override
  String get failedToUpdateCheckConnection =>
      'Failed to update - check your connection';

  @override
  String get markAsNotFinishedQuestion => 'Mark as Not Finished?';

  @override
  String get markAsNotFinishedContent =>
      'This will clear the finished status but keep your current position.';

  @override
  String get unmark => 'Désélectionner';

  @override
  String get markedAsNotFinishedBackAtIt =>
      'Marked as not finished - back at it!';

  @override
  String get resetProgressQuestion => 'Réinitialiser la progression ?';

  @override
  String get resetProgressContent =>
      'Ceci effacera toute la progression de ce livre et le réinitialisera au début. Cela ne peut pas être annulé.';

  @override
  String get progressResetFreshStart => 'Progress reset - fresh start!';

  @override
  String get clearLocalMetadataQuestion => 'Effacer les métadonnées locales ?';

  @override
  String get clearLocalMetadataContent =>
      'This will remove the locally stored metadata and revert to whatever the server has.';

  @override
  String get localMetadataCleared => 'Métadonnées locales effacées';

  @override
  String get saveEbook => 'Enregistrer l\'eBook';

  @override
  String get noEbookFileFound => 'No ebook file found';

  @override
  String get bookmark => 'Signet';

  @override
  String get bookmarks => 'Signets';

  @override
  String bookmarksWithCount(int count) {
    return 'Bookmarks ($count)';
  }

  @override
  String get playbackSpeed => 'Vitesse de lecture';

  @override
  String get noBookmarksYet => 'Aucun signet pour l\'instant';

  @override
  String get longPressBookmarkHint =>
      'Long-press the bookmark button to quick save';

  @override
  String get addBookmark => 'Ajouter un signet';

  @override
  String get editBookmark => 'Modifier le signet';

  @override
  String get titleLabel => 'Titre';

  @override
  String get noteOptionalLabel => 'Note (facultatif)';

  @override
  String get editLayout => 'Edit Layout';

  @override
  String get inMenu => 'In menu';

  @override
  String get bookmarkAdded => 'Signet ajouté';

  @override
  String get startPlayingSomethingFirst => 'Start playing something first';

  @override
  String get playbackHistory => 'Historique de lecture';

  @override
  String get historyLocalTab => 'History';

  @override
  String get historyServerTab => 'Sessions';

  @override
  String get historyNoServerSessions => 'No server sessions for this item yet';

  @override
  String get historyServerLoadFailed => 'Could not load server sessions';

  @override
  String get clearHistoryTooltip => 'Effacer l\'historique';

  @override
  String get tapEventToJump => 'Tap an event to jump to that position';

  @override
  String get noHistoryYet => 'L\'historique est vide pour l\'instant';

  @override
  String jumpedToPosition(String position) {
    return 'Jumped to $position';
  }

  @override
  String booksInSeriesCount(int count) {
    return '$count books in this series';
  }

  @override
  String bookNumber(String number) {
    return 'Livre $number';
  }

  @override
  String downloadRemainingCount(int count) {
    return 'Download Remaining ($count)';
  }

  @override
  String get downloadAll => 'Tout télécharger';

  @override
  String get markAllNotFinished => 'Mark All Not Finished';

  @override
  String get markAllFinished => 'Mark All Finished';

  @override
  String get markAllNotFinishedQuestion => 'Mark All Not Finished?';

  @override
  String get fullyAbsorbSeries => 'Fully Absorb Series?';

  @override
  String get turnAutoDownloadOff => 'Turn Auto-Download Off';

  @override
  String get turnAutoDownloadOn => 'Turn Auto-Download On';

  @override
  String get autoDownloadThisSeries => 'Auto-Download This Series?';

  @override
  String get autoDownloadSeriesContent =>
      'Automatically download the next books as you listen.';

  @override
  String get standalone => 'Autonome';

  @override
  String get episodes => 'Épisodes';

  @override
  String get noEpisodesFound => 'No episodes found';

  @override
  String get markFinished => 'Marqué comme terminé';

  @override
  String get markUnfinished => 'Marquer comme inachevé';

  @override
  String get allEpisodes => 'Tous les épisodes';

  @override
  String get aboutThisEpisode => 'About This Episode';

  @override
  String get reversePlayOrder => 'Reverse play order';

  @override
  String selectedCount(int count) {
    return '$count sélectionné(s)';
  }

  @override
  String get selectAll => 'Tout sélectionner';

  @override
  String get deselectAll => 'Tout désélectionner';

  @override
  String get autoDownloadThisPodcast => 'Auto-Download This Podcast?';

  @override
  String get autoDownloadPodcastContent =>
      'Automatically download the next episodes as you listen.';

  @override
  String get download => 'Télécharger';

  @override
  String get deleteDownload => 'Supprimer le téléchargement';

  @override
  String get casting => 'Casting';

  @override
  String get castingTo => 'Diffusion vers';

  @override
  String get editDetails => 'Modifier les détails';

  @override
  String get quickMatch => 'Quick Match';

  @override
  String get quickMatchNoUpdates => 'No updates necessary';

  @override
  String get custom => 'Personnalisé';

  @override
  String get authorOptionalLabel => 'Auteur (facultatif)';

  @override
  String get noResultsFound =>
      'No results found.\nTry adjusting your search or provider.';

  @override
  String get searchForMetadataAbove => 'Search for metadata above';

  @override
  String get applyThisMatch => 'Apply This Match?';

  @override
  String get metadataUpdated => 'Métadonnées mises à jour';

  @override
  String get failedToUpdateMetadata => 'Failed to update metadata';

  @override
  String get subtitleLabel => 'Sous-titre';

  @override
  String get authorLabel => 'Auteur';

  @override
  String get narratorLabel => 'Narrateur';

  @override
  String get seriesLabel => 'Séries';

  @override
  String get addSeries => 'Add series';

  @override
  String get removeSeries => 'Supprimer les séries';

  @override
  String get descriptionLabel => 'Description';

  @override
  String get publisherLabel => 'Éditeur';

  @override
  String get yearLabel => 'Année';

  @override
  String get genresLabel => 'Genres';

  @override
  String get tagsLabel => 'Tags';

  @override
  String get commaSeparated => 'Séparé par des virgules';

  @override
  String get asinLabel => 'ASIN';

  @override
  String get isbnLabel => 'ISBN';

  @override
  String get coverImage => 'Cover Image';

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
  String get coverUrlLabel => 'URL de la couverture';

  @override
  String get coverUrlHint => 'https://...';

  @override
  String get localMetadata => 'Métadonnées locales';

  @override
  String get overrideLocalDisplay => 'Override local display';

  @override
  String get metadataSavedLocally => 'Metadata saved locally';

  @override
  String get notes => 'Notes';

  @override
  String get newNote => 'Nouvelle note';

  @override
  String get editNote => 'Éditer la note';

  @override
  String get noNotesYet => 'Aucune note pour le moment';

  @override
  String get markdownIsSupported => 'Markdown is supported';

  @override
  String get markdownMd => 'Markdown (.md)';

  @override
  String get keepsFormattingIntact => 'Keeps formatting intact';

  @override
  String get plainTextTxt => 'Texte brut (.txt)';

  @override
  String get simpleTextNoFormatting => 'Simple text, no formatting';

  @override
  String get untitledNote => 'Note sans titre';

  @override
  String get titleHint => 'Titre';

  @override
  String get noteBodyHint => 'Write your note... (supports markdown)';

  @override
  String get nothingToPreview => 'Nothing to preview';

  @override
  String get audioEnhancements => 'Audio Enhancements';

  @override
  String get presets => 'PRESETS';

  @override
  String get equalizer => 'ÉGALISEUR';

  @override
  String get effects => 'EFFECTS';

  @override
  String get bassBoost => 'Amplification des basses';

  @override
  String get surround => 'Surround';

  @override
  String get loudness => 'Volume';

  @override
  String get monoAudio => 'Audio mono';

  @override
  String get skipSilence => 'Sauter les silences';

  @override
  String get resetAll => 'Tout réinitialiser';

  @override
  String get collectionNotFound => 'Collection not found';

  @override
  String get deleteCollection => 'Supprimer la collection';

  @override
  String get deleteCollectionContent =>
      'Are you sure you want to delete this collection?';

  @override
  String get deleteCollectionFailed => 'Couldn\'t delete the collection';

  @override
  String get deletePermissionRequired =>
      'Delete permission required. Ask the root admin to grant you the delete permission.';

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
  String get playlistNotFound => 'Playlist not found';

  @override
  String get deletePlaylist => 'Supprimer la liste de lecture';

  @override
  String get deletePlaylistContent =>
      'Are you sure you want to delete this playlist?';

  @override
  String get newPlaylist => 'Nouvelle liste de lecture';

  @override
  String get playlistNameHint => 'Nom de la liste de lecture';

  @override
  String addedToName(String name) {
    return 'Ajouté à \"$name\"';
  }

  @override
  String get failedToAdd => 'Échec de l\'ajout';

  @override
  String get newCollection => 'Nouvelle collection';

  @override
  String get collectionNameHint => 'Nom de la collection';

  @override
  String get castToDevice => 'Diffuser sur un appareil';

  @override
  String get searchingForCastDevices => 'Searching for Cast devices...';

  @override
  String get castDevice => 'Cast Device';

  @override
  String get stopCasting => 'Arrêter la diffusion';

  @override
  String get disconnect => 'Déconnecter';

  @override
  String get audioOutput => 'Sortie audio';

  @override
  String get noOutputDevicesFound => 'No output devices found';

  @override
  String get welcomeToAbsorb => 'Bienvenue dans Absorb';

  @override
  String get welcomeTagline => 'Un client Audiobookshelf.';

  @override
  String get welcomeAbsorbingTitle => 'Absorption';

  @override
  String get welcomeAbsorbingIntro =>
      'Nous utilisons \"absorber\" à la place de \"jouer\" et \"écouter\". Vous préférez le libellé classique ? Changez-le dans les paramètres.';

  @override
  String get welcomeAbsorbingTabBullet =>
      'Absorbing tab - what you\'re currently listening to';

  @override
  String get welcomeAbsorbButtonBullet => 'Absorb button - start playback';

  @override
  String get welcomeFullyAbsorbBullet => 'Fully Absorb - mark as finished';

  @override
  String get welcomeGettingAroundTitle => 'Getting around';

  @override
  String get welcomeGettingAroundBody =>
      'Appuyez sur n\'importe quelle couverture pour ouvrir ses détails. Les cartes de poursuite d\'écoute sont différentes - touchez pour jouer immédiatement, appuyez et maintenez pour ouvrir les détails.';

  @override
  String get welcomeMakeItYoursTitle => 'Personnalisez-le';

  @override
  String get welcomeMakeItYoursBody =>
      'Explorez les paramètres pour ajuster Absorb à votre goût. La section Astuce & Fonctionnalités cachées qui s\'y trouve vaut la peine d\'être regardée.';

  @override
  String get getStarted => 'Get Started';

  @override
  String get showMore => 'Afficher plus';

  @override
  String get showLess => 'Afficher moins';

  @override
  String get readMore => 'Lire plus';

  @override
  String get removeDownloadQuestion => 'Supprimer le téléchargement ?';

  @override
  String get removeDownloadContent => 'This will be removed from your device.';

  @override
  String get downloadRemoved => 'Téléchargement supprimé';

  @override
  String get finished => 'Terminé';

  @override
  String get saved => 'Téléchargé';

  @override
  String get selectLibrary => 'Select Library';

  @override
  String get switchLibraryTooltip => 'Switch library';

  @override
  String get refreshTooltip => 'Refresh';

  @override
  String get openNowPlayingTooltip => 'Open Now Playing';

  @override
  String get previousChapterTooltip => 'Previous chapter';

  @override
  String get nextChapterTooltip => 'Next chapter';

  @override
  String get noBooksFound => 'No books found';

  @override
  String get userFallback => 'Utilisateur';

  @override
  String get rootAdmin => 'Administrateur Root';

  @override
  String get admin => 'Admin';

  @override
  String get serverAdmin => 'Administrateur du serveur';

  @override
  String get serverAdminSubtitle => 'Manage users, libraries & server settings';

  @override
  String serverUpdateAvailable(String version) {
    return 'Server update $version available';
  }

  @override
  String get justNow => 'À l\'instant';

  @override
  String minutesAgo(int count) {
    return 'Il y a $count min';
  }

  @override
  String hoursAgo(int count) {
    return 'Il y a $count h';
  }

  @override
  String daysAgo(int count) {
    return 'Il y a $count j';
  }

  @override
  String get audible => 'Audible';

  @override
  String get iTunes => 'iTunes';

  @override
  String get openLibrary => 'Ouvrir la bibliothèque';

  @override
  String get root => 'Racine';

  @override
  String get coverPlayPause => 'Lecture/pause sur la couverture';

  @override
  String get coverPlayPauseOnSubtitle => 'On - tap cover art to play/pause';

  @override
  String get coverPlayPauseOffSubtitle =>
      'Off - dedicated play/pause button in controls';

  @override
  String get cardBackground => 'Arrière-plan de la carte';

  @override
  String get cardBackgroundBlurred => 'Blurred';

  @override
  String get cardBackgroundGradient => 'Dégradé';

  @override
  String get queueModeMergedSubtitle =>
      'Playback stops, manual queue, or auto-plays next item';

  @override
  String get queueModeSeriesLabel => 'Séries';

  @override
  String get queueModeShowLabel => 'Show';

  @override
  String get queueModeInfoSeries => 'Séries';

  @override
  String get queueModeInfoSeriesDesc =>
      'Automatically plays the next book in a series or the next episode in a podcast show.';

  @override
  String get resetButtonGridQuestion => 'Reset button grid?';

  @override
  String get resetButtonGridContent =>
      'This will restore the default button layout, order, and toggle settings.';

  @override
  String get reset => 'Réinitialiser';

  @override
  String get buttonGridReset => 'Réinitialiser la grille de boutons';

  @override
  String get resetButtonGrid => 'Réinitialiser la grille de boutons';

  @override
  String get chapterBarrierOnRewind => 'Chapter barrier on rewind';

  @override
  String get chapterBarrierInfoTitle => 'Barrière de chapitre';

  @override
  String get chapterBarrierInfoContent =>
      'Lorsque vous sautez en arrière, la lecture s\'accroche au début du chapitre actuel au lieu de passer au précédent.\n\nAppuyez deux fois sur le bouton retour en arrière en 2 secondes pour franchir la barrière.';

  @override
  String get chapterBarrierOnRewindOnSubtitle =>
      'On - rewind snaps to chapter start';

  @override
  String get chapterBarrierOnRewindOffSubtitle =>
      'Off - rewind crosses chapter boundaries';

  @override
  String autoRewindOnSubtitleFormat(String min, String max) {
    return 'On -${min}s to ${max}s based on pause length';
  }

  @override
  String get rewindOnSessionStart => 'Rewind on session start';

  @override
  String get rewindOnSessionStartInfoContent =>
      'Le retour automatique normal se déclenche lorsque vous redémarrez après une pause dans une session active. Ce paramètre ajoute un retour en arrière lors du démarrage d\'une nouvelle session - par exemple après la fermeture de l\'application, lorsque la lecture a été arrêtée, ou si vous ouvrez l\'application à nouveau.\n\nQuand activé, la lecture redémarre par la quantité maximum de rembobinage au début de chaque nouvelle session afin que vous puissiez réentendre là où vous vous êtiez arrêté.';

  @override
  String rewindOnSessionStartOnSubtitle(String seconds) {
    return 'On - rewinds ${seconds}s when starting a new session';
  }

  @override
  String rewindActivationDelayValue(String seconds) {
    return '${seconds}s+';
  }

  @override
  String rewindRangeValue(String min, String max) {
    return '${min}s – ${max}s';
  }

  @override
  String rewindSecondsPause(String seconds) {
    return 'Pause de ${seconds}s';
  }

  @override
  String rewindMinPause(String minutes) {
    return '$minutes min pause';
  }

  @override
  String rewindHrPause(String hours) {
    return 'Pause de $hours h';
  }

  @override
  String get rewindOneHrPause => '1 heure de pause';

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
  String get chimeBeforeSleep => 'Chime before sleep';

  @override
  String get chimeBeforeSleepOnSubtitle =>
      'Plays a gentle bell when the timer is about to end';

  @override
  String get chimeBeforeSleepOffSubtitle => 'No sound warning before sleep';

  @override
  String get windDownDuration => 'Wind-down duration';

  @override
  String windDownDurationSubtitle(int seconds) {
    return 'Fade and chime start ${seconds}s before sleep';
  }

  @override
  String fadeVolumeOnSubtitleDynamic(int seconds) {
    return 'Gradually lowers volume over the last ${seconds}s';
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
  String get endOfChapterShort => 'Fin de chapitre';

  @override
  String get endOfChapterOnSubtitle => 'Arrêter à la fin du chapitre en cours';

  @override
  String get endOfChapterOffSubtitle => 'Use a timed sleep timer';

  @override
  String get showExplicitBadge => 'Show explicit badge';

  @override
  String get showExplicitBadgeOnSubtitle =>
      'Explicit items show an \"E\" badge';

  @override
  String get showExplicitBadgeOffSubtitle => 'Off - explicit badge hidden';

  @override
  String get libraryFallback => 'Bibliothèque';

  @override
  String get preReleaseUpdatesInfoTitle => 'Pre-release Updates';

  @override
  String get preReleaseUpdatesInfoContent =>
      'Lorsque cette option est activée, le vérificateur de mise à jour vous informera également des versions alpha et pré-versions de GitHub. Elles peuvent être moins stables mais incluent les dernières fonctionnalités et correctifs.';

  @override
  String get includePreReleases => 'Include pre-releases';

  @override
  String get includePreReleasesOnSubtitle =>
      'On - checking for alpha & pre-release builds';

  @override
  String get includePreReleasesOffSubtitle => 'Off - stable releases only';

  @override
  String get setTooltip => 'Set';

  @override
  String get saveAbsorbBackup => 'Save Absorb backup';

  @override
  String get checkForUpdate => 'Rechercher les mises à jour';

  @override
  String get onLatestVersion => 'You\'re on the latest version';

  @override
  String get updateAvailable => 'Mise à jour disponible';

  @override
  String get preReleaseAvailable => 'Pre-release available';

  @override
  String updateDialogContent(String kind, String latest, String current) {
    return 'A new $kind of Absorb is available: $latest\n\nYou are on $current.';
  }

  @override
  String get updateKindPreRelease => 'pre-release';

  @override
  String get updateKindVersion => 'version';

  @override
  String get downloadButton => 'Télécharger';

  @override
  String get updateDownloading => 'Downloading update...';

  @override
  String get updateInstallPermissionDenied =>
      'Install permission denied. Enable \"Install unknown apps\" for Absorb in system settings.';

  @override
  String get updateOpeningInBrowser => 'In-app update failed, opening browser';

  @override
  String get sendToEreader => 'Envoyer vers l\'E-Reader';

  @override
  String sendingToEreader(String device) {
    return 'Envoi à $device...';
  }

  @override
  String sendToEreaderSuccess(String device) {
    return 'Envoyé à $device';
  }

  @override
  String get sendToEreaderFailed => 'Couldn\'t send the ebook';

  @override
  String get pickEreaderDevice => 'Choisissez un appareil';

  @override
  String get adminEmail => 'Courriel';

  @override
  String get adminEmailSubtitle => 'SMTP and e-reader devices';

  @override
  String get smtpSection => 'SMTP';

  @override
  String get smtpSetupGuide => 'Setup guide';

  @override
  String get smtpHost => 'Hôte';

  @override
  String get smtpPort => 'Port';

  @override
  String get smtpSecure => 'Sécurisé';

  @override
  String get smtpRejectUnauthorized => 'Reject unauthorized TLS';

  @override
  String get smtpUser => 'Utilisateur';

  @override
  String get smtpPass => 'Mot de passe';

  @override
  String get smtpFromAddress => 'Adresse de l\'expéditeur';

  @override
  String get smtpTestAddress => 'Adresse de test';

  @override
  String get smtpSendTest => 'Envoyer un test';

  @override
  String get smtpSaveSettings => 'Enregistrer';

  @override
  String get smtpSaved => 'Email settings saved';

  @override
  String get smtpSaveFailed => 'Couldn\'t save email settings';

  @override
  String get smtpTestSent => 'Email de test envoyé';

  @override
  String get smtpTestFailed => 'L\'email de test a échoué';

  @override
  String get ereaderDevicesTitle => 'Appareils de lecture électronique';

  @override
  String get ereaderDevicesEmpty => 'No devices yet. Add one below.';

  @override
  String get addEreaderDevice => 'Ajouter un appareil';

  @override
  String get editEreaderDevice => 'Edit device';

  @override
  String get deleteEreaderDevice => 'Supprimer';

  @override
  String get ereaderDeviceName => 'Nom';

  @override
  String get ereaderDeviceEmail => 'Courriel';

  @override
  String get ereaderAvailability => 'Who can use this device';

  @override
  String get ereaderAvailAdminOrUp => 'Admins only';

  @override
  String get ereaderAvailUserOrUp => 'Tous les utilisateurs';

  @override
  String get ereaderAvailGuestOrUp => 'Tout le monde';

  @override
  String get ereaderAvailSpecificUsers => 'Specific users';

  @override
  String ereaderSpecificUsersN(int count) {
    return 'Specific users ($count)';
  }

  @override
  String get ereaderDevicesSaved => 'Appareils enregistrés';

  @override
  String get ereaderDevicesSaveFailed => 'Couldn\'t save devices';

  @override
  String libraryCountOne(int count) {
    return '$count bibliothèque';
  }

  @override
  String libraryCountOther(int count) {
    return '$count bibliothèques';
  }

  @override
  String serverVersionLabel(String version) {
    return 'Serveur $version';
  }

  @override
  String appVersionServerSuffix(String version) {
    return '  ·  Serveur $version';
  }

  @override
  String backupDateFormat(int month, int day, int year) {
    return '$month/$day/$year';
  }

  @override
  String get backupDetailsSeparator => ' · ';

  @override
  String get bookmarksSortedByPositionReversed =>
      'Sorted by position (reversed)';

  @override
  String bookmarksJumpShortContent(String title, String position) {
    return '\"$title\" at $position';
  }

  @override
  String get deleteBookmarkQuestion => 'Supprimer le signet ?';

  @override
  String get cardIconsOnlyChip => 'Icônes uniquement';

  @override
  String get cardMoreInGridChip => '\"More\" in grid';

  @override
  String get cardLayoutHidden => 'Masqué';

  @override
  String get speed => 'Vitesse';

  @override
  String get details => 'Détails';

  @override
  String get episodeDetailsLabel => 'Détails de l\'épisode';

  @override
  String get bookDetailsLabel => 'Détails du livre';

  @override
  String get equalizerShort => 'EQ';

  @override
  String get equalizerLabel => 'Égaliseur';

  @override
  String get cast => 'Cast';

  @override
  String castingToDevice(String device) {
    return 'Casting to $device';
  }

  @override
  String castToDeviceNamed(String device) {
    return 'Diffuser vers $device';
  }

  @override
  String get historyShort => 'History';

  @override
  String atPosition(String position) {
    return 'à $position';
  }

  @override
  String chaptersChip(int count) {
    return '$count chapitres';
  }

  @override
  String chapterNumber(int number) {
    return 'Chapitre $number';
  }

  @override
  String kbpsValue(int value) {
    return '$value kbps';
  }

  @override
  String get resetMayNotHaveSynced =>
      'Reset may not have synced - check your server';

  @override
  String failedToDownloadEbook(int code) {
    return 'Failed to download ebook ($code)';
  }

  @override
  String get serverReturnedErrorPage =>
      'Server returned an error page instead of the ebook file';

  @override
  String ebookSaved(String filename) {
    return '$filename enregistré';
  }

  @override
  String errorSavingEbook(String error) {
    return 'Error saving ebook: $error';
  }

  @override
  String failedToSaveError(String error) {
    return 'Failed to save: $error';
  }

  @override
  String get adminBackupsLabel => 'Backups';

  @override
  String get adminListeningNow => 'À l\'écoute en ce moment';

  @override
  String get adminLibraries => 'Bibliothèques';

  @override
  String get adminLibraryShows => 'séries';

  @override
  String get adminLibraryBooks => 'livres';

  @override
  String get adminLibraryFolders => 'dossiers';

  @override
  String get adminLibrarySize => 'taille';

  @override
  String get adminLibraryDuration => 'durée';

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
  String get adminLibraryReview => 'Vérification';

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
  String get adminMissingDeleteTitle => 'Supprimer l\'élément';

  @override
  String adminMissingDeleteOneContent(String title) {
    return 'Remove \"$title\" from Audiobookshelf?';
  }

  @override
  String adminMissingDeleteManyContent(int count) {
    return 'Remove $count entries from Audiobookshelf?';
  }

  @override
  String adminMissingDeleteCount(int count) {
    return 'Delete $count';
  }

  @override
  String adminMissingRemovedOne(String title) {
    return '$title supprimé';
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
  String get adminMatchAction => 'Match';

  @override
  String adminMatchingStarted(String name) {
    return 'Matching started for $name';
  }

  @override
  String get adminMatchFailed => 'Échec';

  @override
  String adminScanFailed(String name) {
    return 'Failed to scan $name';
  }

  @override
  String get adminPurgeCacheFailed => 'Échec';

  @override
  String get adminUsersRootBadge => 'root';

  @override
  String get adminUsersAdminBadge => 'admin';

  @override
  String get adminUsersDisabledBadge => 'désactivé';

  @override
  String get adminUsersEditUserTooltip => 'Modifier l’utilisateur';

  @override
  String get adminUsersOnlineNow => 'En ligne actuellement';

  @override
  String adminUsersLastSeen(String time) {
    return 'Vu pour la dernière fois $time';
  }

  @override
  String get adminUsersNever => 'Jamais';

  @override
  String get adminUsersTotal => 'Total';

  @override
  String get adminUsersNoReadingActivity => 'No reading activity';

  @override
  String get adminUsersLoadingDots => 'Chargement...';

  @override
  String get adminUsersLoadMoreSessions => 'Load more sessions';

  @override
  String get adminUsersNoRecentSessions => 'No recent sessions';

  @override
  String get adminUsersLibraryProgress => 'Progression de la bibliothèque';

  @override
  String adminUsersLoadMoreRemaining(int count) {
    return 'Load More ($count remaining)';
  }

  @override
  String adminUsersMonthsAgo(int count) {
    return '${count}mo ago';
  }

  @override
  String get adminUsersNewUser => 'Nouvel utilisateur';

  @override
  String get adminUsersEditUser => 'Modifier l’utilisateur';

  @override
  String get adminUsersUsername => 'Utilisateur';

  @override
  String get adminUsersEnterUsername => 'Enter username';

  @override
  String get adminUsersPassword => 'Mot de passe';

  @override
  String get adminUsersNewPassword => 'Nouveau mot de passe';

  @override
  String get adminUsersEnterPassword => 'Enter password';

  @override
  String get adminUsersLeaveBlankToKeep => 'Leave blank to keep current';

  @override
  String get adminUsersAccountType => 'Type de compte';

  @override
  String get adminUsersTypeGuest => 'Invité';

  @override
  String get adminUsersTypeUser => 'Utilisateur';

  @override
  String get adminUsersTypeAdmin => 'Admin';

  @override
  String get adminUsersStatus => 'Statut';

  @override
  String get adminUsersAccountActive => 'Compte actif';

  @override
  String get adminUsersAccountActiveSub => 'Disabled accounts cannot log in';

  @override
  String get adminUsersLocked => 'Verrouillé';

  @override
  String get adminUsersLockedSub => 'Prevents password changes';

  @override
  String get adminUsersPermissions => 'Permissions';

  @override
  String get adminUsersPermDownload => 'Télécharger';

  @override
  String get adminUsersPermUpdate => 'Mise à jour';

  @override
  String get adminUsersPermUpdateSub => 'Edit metadata and library items';

  @override
  String get adminUsersPermDelete => 'Supprimer';

  @override
  String get adminUsersPermUpload => 'Téléverser';

  @override
  String get adminUsersPermExplicit => 'Contenu explicite';

  @override
  String get adminUsersLibraryAccess => 'Library Access';

  @override
  String get adminUsersAccessAllLibraries => 'Access All Libraries';

  @override
  String get adminUsersCreateUser => 'Create User';

  @override
  String get adminUsersSaveChanges => 'Enregistrer les modifications';

  @override
  String get adminUsersUsernameRequired => 'Username is required';

  @override
  String get adminUsersPasswordRequired => 'Password is required';

  @override
  String get adminUsersUserCreated => 'Utilisateur créé';

  @override
  String get adminUsersUserUpdated => 'Utilisateur mis à jour';

  @override
  String get adminUsersFailedCreate => 'Failed to create user';

  @override
  String get adminUsersFailedUpdate => 'Failed to update user';

  @override
  String get adminUsersThisUser => 'cet utilisateur';

  @override
  String get adminUsersDeleteUserTitle => 'Supprimer l\'utilisateur ?';

  @override
  String adminUsersDeleteUserContent(String name) {
    return 'Permanently delete $name?';
  }

  @override
  String adminUsersUserDeleted(String name) {
    return '$name supprimé';
  }

  @override
  String get adminUsersFailedDelete => 'Failed to delete user';

  @override
  String get adminUsersUnlinkOpenId => 'Unlink OpenID';

  @override
  String get adminUsersUnlinkOpenIdTitle => 'Unlink OpenID?';

  @override
  String adminUsersUnlinkOpenIdContent(String name) {
    return 'Supprimer la connexion OpenID pour $name? Il devra se connecter à nouveau avec OpenID pour ré-associer.';
  }

  @override
  String get adminUsersOpenIdUnlinked => 'OpenID dissocié';

  @override
  String get adminUsersFailedUnlinkOpenId => 'Failed to unlink OpenID';

  @override
  String adminUsersByAuthor(String author) {
    return 'par $author';
  }

  @override
  String get adminUsersListened => 'Écouté';

  @override
  String get adminUsersStartedAtPosition => 'Started at position';

  @override
  String get adminUsersEndedAtPosition => 'Terminé à la position';

  @override
  String get adminUsersTotalDuration => 'Durée totale';

  @override
  String get adminUsersStarted => 'Started';

  @override
  String get adminUsersUpdated => 'Updated';

  @override
  String get adminUsersClient => 'Client';

  @override
  String get adminUsersDevice => 'Appareil';

  @override
  String get adminUsersOs => 'OS';

  @override
  String get adminUsersPlayMethod => 'Play method';

  @override
  String get adminUsersPlayDirect => 'Direct play';

  @override
  String get adminUsersPlayDirectStream => 'Direct stream';

  @override
  String get adminUsersPlayTranscode => 'Transcoder';

  @override
  String get adminUsersPlayLocal => 'Local';

  @override
  String get adminPodcastsCheckNewEpisodesTitle => 'Check for New Episodes';

  @override
  String get adminPodcastsCheckNewEpisodesContent =>
      'Cela vérifiera les flux RSS de toutes les podcasts et téléchargera les nouveaux épisodes trouvés (si le téléchargement automatique est activé).';

  @override
  String get adminPodcastsCheckNewEpisodesSubtitle =>
      'Scan RSS feed and download new episodes';

  @override
  String get adminPodcastsCheck => 'Vérifier';

  @override
  String get adminPodcastsCheckingForNew => 'Checking for new episodes…';

  @override
  String get adminPodcastsCheckingForNewDots => 'Checking for new episodes...';

  @override
  String get adminPodcastsFailedCheckEpisodes => 'Failed to check episodes';

  @override
  String get adminPodcastsCheckFeedsTooltip => 'Check feeds for new episodes';

  @override
  String get adminPodcastsNoPodcastsYet => 'Pas encore de podcasts';

  @override
  String get adminPodcastsTapPlusHint => 'Tap + to search and add shows';

  @override
  String adminPodcastsEpisodesCount(int count) {
    return '$count épisodes';
  }

  @override
  String get adminPodcastsAddPodcast => 'Add Podcast';

  @override
  String get adminPodcastsCouldNotFindFeed => 'Could not find podcast feed';

  @override
  String get adminPodcastsSearchHint => 'Search for podcasts…';

  @override
  String get adminPodcastsSearchItunesHint => 'Rechercher dans iTunes...';

  @override
  String adminPodcastsSearchItunesFor(String query) {
    return 'Search iTunes for \"$query\"';
  }

  @override
  String get adminPodcastsNoPodcastsFound => 'Aucun podcast trouvé';

  @override
  String get adminPodcastsRelToday => 'Aujourd\'hui';

  @override
  String adminPodcastsWeeksAgo(int count) {
    return 'Il y a $count sem';
  }

  @override
  String adminPodcastsMonthsAgo(int count) {
    return 'Il y a $count mois';
  }

  @override
  String adminPodcastsYearsAgo(int count) {
    return 'Il y a $count a';
  }

  @override
  String adminPodcastsUpdated(String when) {
    return 'Updated $when';
  }

  @override
  String get adminPodcastsGenreAll => 'Tous';

  @override
  String get adminPodcastsGenreArts => 'Arts';

  @override
  String get adminPodcastsGenreComedy => 'Comédie';

  @override
  String get adminPodcastsGenreEducation => 'Éducation';

  @override
  String get adminPodcastsGenreTvFilm => 'TV & Film';

  @override
  String get adminPodcastsGenreMusic => 'Musique';

  @override
  String get adminPodcastsGenreNews => 'Actualités';

  @override
  String get adminPodcastsGenreReligion => 'Religion';

  @override
  String get adminPodcastsGenreScience => 'Science';

  @override
  String get adminPodcastsGenreSports => 'Sports';

  @override
  String get adminPodcastsGenreTechnology => 'Technologie';

  @override
  String get adminPodcastsGenreBusiness => 'Business';

  @override
  String get adminPodcastsGenreFiction => 'Fiction';

  @override
  String get adminPodcastsGenreSocietyCulture => 'Société & Culture';

  @override
  String get adminPodcastsGenreHealthFitness => 'Santé & Fitness';

  @override
  String get adminPodcastsGenreTrueCrime => 'Documentaire criminel';

  @override
  String get adminPodcastsGenreHistory => 'Historique';

  @override
  String get adminPodcastsGenreKidsFamily => 'Enfants & Famille';

  @override
  String get adminPodcastsPodcastFallback => 'Podcast';

  @override
  String get adminPodcastsEpisodeFallback => 'Épisode';

  @override
  String get adminPodcastsNoFeedFound => 'Aucune URL de flux trouvée';

  @override
  String get adminPodcastsNoFeedAvailable => 'No feed URL available';

  @override
  String adminPodcastsAddedToLibrary(String title) {
    return '$title ajouté à la bibliothèque';
  }

  @override
  String adminPodcastsFailedToAdd(String title) {
    return 'Failed to add $title';
  }

  @override
  String adminPodcastsEpisodesInFeed(int count) {
    return '$count episodes in feed';
  }

  @override
  String adminPodcastsMoreEpisodes(int count) {
    return '+ $count more episodes';
  }

  @override
  String get adminPodcastsAdding => 'Ajout en cours…';

  @override
  String get adminPodcastsAddToLibrary => 'Ajouter à la bibliothèque';

  @override
  String get adminPodcastsRemoveShowTitle => 'Remove Show?';

  @override
  String adminPodcastsRemoveShowContent(String title) {
    return 'Remove \"$title\" and all its episodes from the server? This cannot be undone.';
  }

  @override
  String adminPodcastsRemovedShow(String title) {
    return 'Removed \"$title\"';
  }

  @override
  String get adminPodcastsFailedRemoveShow => 'Failed to remove show';

  @override
  String get adminPodcastsRemoveShowTooltip => 'Remove show';

  @override
  String get adminPodcastsSelectMultipleTooltip => 'Sélection multiple';

  @override
  String adminPodcastsDownloadedCount(int count) {
    return '$count downloaded';
  }

  @override
  String get adminPodcastsTabDownloaded => 'Téléchargé';

  @override
  String get adminPodcastsTabFeed => 'Feed';

  @override
  String get adminPodcastsTabSettings => 'Paramètres';

  @override
  String adminPodcastsDownloadingEpisode(String title) {
    return 'Downloading \"$title\"';
  }

  @override
  String get adminPodcastsFailedDownload => 'Failed to download';

  @override
  String get adminPodcastsDeleteEpisodeTitle => 'Supprimer l\'épisode ?';

  @override
  String adminPodcastsDeleteEpisodeContent(String title) {
    return 'Supprimer \"$title\" ?';
  }

  @override
  String get adminPodcastsDeleted => 'Supprimé';

  @override
  String get adminPodcastsFailed => 'Échec';

  @override
  String get adminPodcastsDeleteEpisodesTitle => 'Supprimer les épisodes ?';

  @override
  String adminPodcastsDeleteEpisodesContent(int count) {
    return 'Supprimer $count épisode(s) du serveur ?';
  }

  @override
  String adminPodcastsDeletedEpisodes(int count) {
    return 'Deleted $count episode(s)';
  }

  @override
  String get adminPodcastsBrowseFeedToDownload => 'Browse feed to download';

  @override
  String get adminPodcastsDownloadingDots => 'Téléchargement...';

  @override
  String adminPodcastsDeleteEpisodesCount(int count) {
    return 'Supprimer $count épisode(s)';
  }

  @override
  String adminPodcastsDownloadingCount(int count) {
    return 'Téléchargement de $count épisode(s)';
  }

  @override
  String adminPodcastsDownloadEpisodesCount(int count) {
    return 'Télécharger $count épisode(s)';
  }

  @override
  String get adminPodcastsLookForEpisodesAfter => 'Look for episodes after';

  @override
  String get adminPodcastsSelectDate => 'Select date';

  @override
  String get adminPodcastsMaxEpisodes => 'Max episodes to download';

  @override
  String adminPodcastsNoNewEpisodesAfter(String date) {
    return 'No new episodes found after $date';
  }

  @override
  String adminPodcastsFoundNewEpisodes(int count) {
    return 'Found $count new episode(s) - downloading';
  }

  @override
  String get adminPodcastsFailedToCheckNew =>
      'Failed to check for new episodes';

  @override
  String get adminPodcastsCheckAndDownload => 'Vérifier & Télécharger';

  @override
  String get adminPodcastsMatchPodcast => 'Match Podcast';

  @override
  String get adminPodcastsMatchPodcastSubtitle =>
      'Search iTunes to update cover and metadata';

  @override
  String get adminPodcastsAutoDownloadNewEpisodes =>
      'Auto-Download New Episodes';

  @override
  String get adminPodcastsAutoDownloadOnSubtitle =>
      'Server downloads new episodes automatically';

  @override
  String get adminPodcastsAutoDownloadOffSubtitle =>
      'New episodes are not auto-downloaded';

  @override
  String get adminPodcastsFailedAutoDownloadUpdate =>
      'Failed to update auto-download setting';

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
  String get adminPodcastsCheckSchedule => 'Check Schedule';

  @override
  String get adminPodcastsFrequency => 'Fréquence';

  @override
  String get adminPodcastsFreqHourly => 'Toutes les heures';

  @override
  String get adminPodcastsFreqDaily => 'Quotidiennement';

  @override
  String get adminPodcastsFreqWeekly => 'Hebdomadaire';

  @override
  String get adminPodcastsDay => 'Jour';

  @override
  String get adminPodcastsTime => 'Time';

  @override
  String get adminPodcastsDaySun => 'Dim';

  @override
  String get adminPodcastsDayMon => 'Lun';

  @override
  String get adminPodcastsDayTue => 'Mar';

  @override
  String get adminPodcastsDayWed => 'Mer';

  @override
  String get adminPodcastsDayThu => 'Jeu';

  @override
  String get adminPodcastsDayFri => 'Ven';

  @override
  String get adminPodcastsDaySat => 'Sam';

  @override
  String get adminPodcastsFeedUrl => 'URL du flux';

  @override
  String get adminPodcastsBack => 'Back';

  @override
  String get adminPodcastsRootOnly => 'Root uniquement';

  @override
  String get adminPodcastsDeleting => 'Deleting...';

  @override
  String get adminPodcastsDeleteEpisode => 'Delete Episode';

  @override
  String adminPodcastsSeasonChip(String season) {
    return 'Saison $season';
  }

  @override
  String adminPodcastsEpChip(String number) {
    return 'Ép. $number';
  }

  @override
  String get adminPodcastsApplyingMatch => 'Applying match...';

  @override
  String get adminPodcastsNoResults => 'Aucun résultat';

  @override
  String get adminPodcastsPodcastMatched => 'Podcast matched and updated';

  @override
  String get adminPodcastsFailedMatch => 'Failed to match podcast';

  @override
  String get adminPodcastsSelectAll => 'Tout sélectionner';

  @override
  String get adminPodcastsSelectAllNew => 'Nouveaux uniquement';

  @override
  String get adminPodcastsSortNewestFirst => 'Les plus récents en premier';

  @override
  String get adminPodcastsSortOldestFirst => 'Les plus anciens en premier';

  @override
  String get adminPodcastsEditInfo => 'Modifier les informations';

  @override
  String get adminPodcastsEditInfoSubtitle =>
      'Change title, description, cover and more';

  @override
  String get adminPodcastsEditTitle => 'Modifier le podcast';

  @override
  String get adminPodcastsReleaseDate => 'Date de parution';

  @override
  String get adminPodcastsExplicit => 'Explicite';

  @override
  String get adminPodcastsExplicitSubtitle => 'Mark this podcast as explicit';

  @override
  String get episodeListEpisodeFallback => 'Épisode';

  @override
  String get episodeListUnknownPodcast => 'Podcast inconnu';

  @override
  String episodeListMarkedFinished(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count episodes marked as finished',
      one: '1 episode marked as finished',
    );
    return '$_temp0';
  }

  @override
  String episodeListMarkedUnfinished(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count épisodes marqués comme inachevés',
      one: '1 épisode marqué comme inachevé',
    );
    return '$_temp0';
  }

  @override
  String get episodeListUnsubscribeFromNewEpisodes =>
      'Unsubscribe from New Episodes';

  @override
  String get episodeListSubscribeToNewEpisodes => 'Subscribe to New Episodes';

  @override
  String get episodeListSubscribeTitle => 'Subscribe to this podcast?';

  @override
  String get episodeListSubscribeContent =>
      'Les nouveaux épisodes seront automatiquement téléchargés et ajoutés à votre file d’attente d’absorption lorsqu’ils apparaîtront sur le serveur.';

  @override
  String get episodeListSubscribe => 'S\'abonner';

  @override
  String get episodeListShowFinishedEpisodes => 'Afficher les épisodes achevés';

  @override
  String get episodeListHideFinishedEpisodes => 'Cacher les épisodes achevés';

  @override
  String get episodeListShowSettings => 'Show Settings';

  @override
  String get episodeListPlaysNewerToOlder => 'Plays newer to older episodes';

  @override
  String get episodeListPlaysOlderToNewer => 'Plays older to newer episodes';

  @override
  String episodeListEpisodeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count episodes',
      one: '1 episode',
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
  String get episodeListAutoDownloadChip => 'Téléchargement automatique';

  @override
  String get episodeListSubscribedChip => 'Abonné';

  @override
  String get episodeListExplicitChip => 'Explicite';

  @override
  String get episodeListSortNewest => 'Les plus récents';

  @override
  String get episodeListSortOldest => 'Les plus anciens';

  @override
  String episodeListAddedToAbsorbing(String title) {
    return 'Added \"$title\" to Absorbing';
  }

  @override
  String get episodeDetailEpisodeFallback => 'Épisode';

  @override
  String get episodeDetailMarkedNotFinished => 'Marked as not finished';

  @override
  String get episodeDetailMarkedFinishedNice => 'Marked as finished - nice!';

  @override
  String get episodeDetailMarkAbsorbedContent =>
      'This will set your progress to 100% for this episode.';

  @override
  String get episodeDetailResetProgressContent =>
      'Ceci effacera toute la progression de cet épisode et le réinitialisera au début. Cela ne peut pas être annulé.';

  @override
  String get episodeDetailToday => 'Aujourd\'hui';

  @override
  String get episodeDetailYesterday => 'Hier';

  @override
  String episodeDetailDaysAgo(int count) {
    return 'Il y a $count j';
  }

  @override
  String episodeDetailWeeksAgo(int count) {
    return 'Il y a $count sem';
  }

  @override
  String episodeDetailDurationHm(int hours, int minutes) {
    return '${hours}h ${minutes}m';
  }

  @override
  String episodeDetailDurationM(int minutes) {
    return '${minutes}m';
  }

  @override
  String get episodeDetailResume => 'Reprendre';

  @override
  String get episodeDetailPlayEpisode => 'Lire l\'épisode';

  @override
  String episodeDetailEpisodeNumber(String number) {
    return 'Épisode $number';
  }

  @override
  String episodeDetailSeasonNumber(String number) {
    return 'Saison $number';
  }

  @override
  String get editMetadataUpdatedFromMatch => 'Metadata updated from match';

  @override
  String editMetadataConfirmMatch(String title) {
    return 'Cela mettra à jour les métadonnées du serveur pour ce livre en utilisant :\n\n\"$title\"\n\nTous les champs et la couverture seront remplacés sur le serveur.';
  }

  @override
  String editMetadataConfirmMatchWithAuthor(String title, String author) {
    return 'Ceci mettra à jour les métadonnées du serveur pour ce livre en utilisant :\n\n\"$title\" par $author\n\nTous les champs et la couverture seront remplacés sur le serveur.';
  }

  @override
  String get seriesBooksFindMissingTitle => 'Find Missing Books';

  @override
  String get seriesBooksFindMissingContent =>
      'Ceci cherche sur Audible pour trouver dans cette série des livres qui peuvent être manquants dans votre bibliothèque.\n\nLes livres sont trouvés d\'abord par ASIN (selon que votre serveur a des ASINs pour ses livres), sinon fait une correspondance de titre. Il se peut que les résultats ne soient pas parfaitement exacts.';

  @override
  String get seriesBooksCouldNotFindOnAudible =>
      'Could not find this series on Audible';

  @override
  String seriesBooksMarkAllNotFinishedContent(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Cela va effacer le statut fini pour les $count livres de cette série.',
      one: 'Cela effacera le statut fini du livre de cette série.',
    );
    return '$_temp0';
  }

  @override
  String seriesBooksFullyAbsorbContent(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Cela marquera les $count livres de cette série comme terminé.',
      one: 'Cela marquera le livre de cette série comme terminé.',
    );
    return '$_temp0';
  }

  @override
  String get seriesBooksUnmarkAll => 'Décocher tout';

  @override
  String get seriesBooksShowAllBooks => 'Show all books';

  @override
  String get seriesBooksGroupBySubSeries => 'Group by sub-series';

  @override
  String get seriesBooksLoadingSubSeries => 'Loading sub-series...';

  @override
  String seriesBooksBookCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count books',
      one: '1 book',
    );
    return '$_temp0';
  }

  @override
  String get seriesBooksDone => 'Terminé';

  @override
  String get seriesBooksExplicitBadge => 'E';

  @override
  String get expandedCardStreaming => 'Diffusion';

  @override
  String get expandedCardDeviceFallback => 'Appareil';

  @override
  String bookmarksScreenPositionInBook(String position, String bookTitle) {
    return '$position in $bookTitle';
  }

  @override
  String get bookmarksScreenClose => 'Fermer';

  @override
  String get bookmarksScreenSortNewest => 'Newest';

  @override
  String get bookmarksScreenSortPosition => 'Position';

  @override
  String statsScreenStreakDays(int count) {
    return '${count}j';
  }

  @override
  String statsScreenSessionCountOne(int count) {
    return '$count session';
  }

  @override
  String statsScreenSessionCountOther(int count) {
    return '$count sessions';
  }

  @override
  String get statsScreenDayMon => 'Lun';

  @override
  String get statsScreenDayTue => 'Mar';

  @override
  String get statsScreenDayWed => 'Mer';

  @override
  String get statsScreenDayThu => 'Jeu';

  @override
  String get statsScreenDayFri => 'Ven';

  @override
  String get statsScreenDaySat => 'Sam';

  @override
  String get statsScreenDaySun => 'Dim';

  @override
  String statsScreenDurationHm(int h, int m) {
    return '${h}h ${m}m';
  }

  @override
  String statsScreenDurationM(int m) {
    return '${m}m';
  }

  @override
  String get statsScreenDurationLessThanMin => '<1m';

  @override
  String get statsScreenDurationZero => '0m';

  @override
  String statsScreenDurationShortH(int h) {
    return '${h}h';
  }

  @override
  String statsScreenDurationShortM(int m) {
    return '${m}m';
  }

  @override
  String get statsScreenCouldNotLoadItem => 'Could not load item';

  @override
  String get statsScreenCouldNotFindEpisode => 'Could not find episode';

  @override
  String statsScreenByAuthor(String author) {
    return 'by $author';
  }

  @override
  String get statsScreenListened => 'Écouté';

  @override
  String get sessionEditTitle => 'Modifier la session';

  @override
  String get sessionDayLabel => 'Jour';

  @override
  String get sessionEndPosition => 'Position de fin';

  @override
  String get sessionEndPositionHint =>
      'Changing this may also update your current progress.';

  @override
  String get statsViewSessions => 'Voir les sessions';

  @override
  String statsSessionsForDate(String date) {
    return 'Sessions for $date';
  }

  @override
  String get statsNoSessionsForDate =>
      'No listening sessions found for this day';

  @override
  String get statsSearchSessions => 'Sessions de recherche';

  @override
  String get statsNoSessionSearchResults => 'No sessions match your search';

  @override
  String get statsSessionsLoadFailed => 'Could not load sessions for this day';

  @override
  String get sessionDeleteConfirmTitle => 'Supprimer la session ?';

  @override
  String get sessionDeleteConfirmBody =>
      'This removes the session and lowers your listening totals by its time. It cannot be undone.';

  @override
  String get sessionSaved => 'Session mise à jour';

  @override
  String get sessionDeleted => 'Session supprimée';

  @override
  String get sessionSaveFailed => 'Could not save changes';

  @override
  String get sessionDeleteFailed => 'Could not delete this session';

  @override
  String get statsScreenStartedAtPosition => 'Started at position';

  @override
  String get statsScreenEndedAtPosition => 'Ended at position';

  @override
  String get statsScreenTotalDuration => 'Total duration';

  @override
  String get statsScreenStarted => 'Commencé';

  @override
  String get statsScreenUpdated => 'Mis à jour';

  @override
  String get statsScreenClient => 'Client';

  @override
  String get statsScreenDevice => 'Appareil';

  @override
  String get statsScreenOs => 'OS';

  @override
  String get statsScreenPlayMethod => 'Play method';

  @override
  String get statsScreenLoading => 'Chargement...';

  @override
  String statsScreenJumpToSessionStart(String position) {
    return 'Jump to session start ($position)';
  }

  @override
  String get statsScreenPlayMethodDirect => 'Direct play';

  @override
  String get statsScreenPlayMethodDirectStream => 'Flux direct';

  @override
  String get statsScreenPlayMethodTranscode => 'Transcodage';

  @override
  String get statsScreenPlayMethodLocal => 'Local';

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
    return '$month $day, $year at $hour:$minute $ampm';
  }

  @override
  String get statsScreenMonthJan => 'Jan';

  @override
  String get statsScreenMonthFeb => 'Fév';

  @override
  String get statsScreenMonthMar => 'Mar';

  @override
  String get statsScreenMonthApr => 'Avr';

  @override
  String get statsScreenMonthMay => 'Mai';

  @override
  String get statsScreenMonthJun => 'Jui';

  @override
  String get statsScreenMonthJul => 'Juil';

  @override
  String get statsScreenMonthAug => 'Aoû';

  @override
  String get statsScreenMonthSep => 'Sep';

  @override
  String get statsScreenMonthOct => 'Oct';

  @override
  String get statsScreenMonthNov => 'Nov';

  @override
  String get statsScreenMonthDec => 'Déc';

  @override
  String get upcomingReleasesTitle => 'Sorties à venir';

  @override
  String get upcomingReleasesRescanTitle => 'Rescanner ?';

  @override
  String upcomingReleasesRescanContent(int days) {
    return 'These results are $days days old. Release dates may have changed - would you like to rescan?';
  }

  @override
  String get upcomingReleasesNotNow => 'Plus tard';

  @override
  String get upcomingReleasesRescan => 'Rescan';

  @override
  String get upcomingReleasesRescanReleaseDate => 'Rescan Release Date';

  @override
  String get upcomingReleasesRescanning => 'Nouvelle analyse...';

  @override
  String upcomingReleasesUpdatedWithDate(String date) {
    return 'Mis à jour - $date';
  }

  @override
  String get upcomingReleasesNoReleaseDateFound => 'No release date found';

  @override
  String get upcomingReleasesRescanFailed => 'Échec du nouveau scan';

  @override
  String get upcomingReleasesRemoveFromList => 'Supprimer de la liste';

  @override
  String get upcomingReleasesRemovedFromList => 'Removed from list';

  @override
  String get upcomingReleasesDateChip => 'Date';

  @override
  String upcomingReleasesCheckingSeries(String name, int processed, int total) {
    return 'Checking $name... ($processed/$total)';
  }

  @override
  String get upcomingReleasesLoadingSeries => 'Loading series...';

  @override
  String get upcomingReleasesScannedToday => '(scanné aujourd\'hui)';

  @override
  String get upcomingReleasesScannedYesterday => '(scanned yesterday)';

  @override
  String upcomingReleasesScannedDaysAgo(int days) {
    return '(scanned $days days ago)';
  }

  @override
  String upcomingReleasesUpcomingCount(int count) {
    return '$count à venir';
  }

  @override
  String upcomingReleasesRecentCount(int count) {
    return '$count recent';
  }

  @override
  String get upcomingReleasesNoneFound =>
      'No upcoming or recent releases found';

  @override
  String upcomingReleasesAcrossSeries(String summary, int count) {
    return '$summary across $count series';
  }

  @override
  String upcomingReleasesCheckedSeries(int count) {
    return 'Checked $count series on Audible';
  }

  @override
  String upcomingReleasesDateFormat(String month, int day, int year) {
    return '$month $day, $year';
  }

  @override
  String upcomingReleasesSequenceLabel(String sequence) {
    return '#$sequence';
  }

  @override
  String get upcomingReleasesBadgeUpcoming => 'À VENIR';

  @override
  String get upcomingReleasesBadgeAdded => 'ADDED';

  @override
  String get upcomingReleasesBadgeMissing => 'MANQUANT';

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
  String get upcomingReleasesOpenSeries => 'Open series on Audible';

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
  String get homeScreenEpisodeFallback => 'Épisode';

  @override
  String get libraryScreenUnknownTitle => 'Titre inconnu';

  @override
  String get playlistDetailDefaultName => 'Liste de lecture';

  @override
  String playlistDetailItemCount(int count) {
    return '$count éléments';
  }

  @override
  String get playlistDetailUnfinished => 'Non terminé';

  @override
  String get playlistDetailRemoveFromPlaylist => 'Remove from playlist';

  @override
  String get playlistDetailDone => 'Terminé';

  @override
  String playlistDetailItemsMarkedFinished(int count) {
    return '$count items marked finished';
  }

  @override
  String playlistDetailItemsMarkedUnfinished(int count) {
    return '$count items marked unfinished';
  }

  @override
  String playlistDetailItemsRemoved(int count) {
    return '$count items removed';
  }

  @override
  String playlistDetailAddedToAbsorbing(String title) {
    return 'Added \"$title\" to Absorbing';
  }

  @override
  String get collectionDetailDefaultName => 'Collection';

  @override
  String collectionDetailBookCount(int count) {
    return '$count livres';
  }

  @override
  String get collectionDetailDone => 'Terminé';

  @override
  String collectionDetailAddedToAbsorbing(String title) {
    return 'Added \"$title\" to Absorbing';
  }

  @override
  String get audibleSeriesNoBooksFound => 'No books found on Audible';

  @override
  String get audibleSeriesFailedToLoad => 'Failed to load series from Audible';

  @override
  String audibleSeriesSummary(int total, int missing) {
    return '$total on Audible · $missing missing';
  }

  @override
  String audibleSeriesSummaryWithUpcoming(
    int total,
    int missing,
    int upcoming,
  ) {
    return '$total on Audible · $missing missing · $upcoming upcoming';
  }

  @override
  String audibleSeriesFilterMissing(int count) {
    return 'Missing ($count)';
  }

  @override
  String audibleSeriesFilterUpcoming(int count) {
    return 'Upcoming ($count)';
  }

  @override
  String audibleSeriesFilterAll(int count) {
    return 'Tous ($count)';
  }

  @override
  String get audibleSeriesSearching => 'Searching Audible...';

  @override
  String get audibleSeriesCompleteSeries => 'You have the complete series!';

  @override
  String get audibleSeriesNoUpcoming => 'No upcoming releases found';

  @override
  String get audibleSeriesUpcomingBadge => 'À VENIR';

  @override
  String get audibleSeriesAbridged => 'Abridged';

  @override
  String get audibleSeriesRegionTitle => 'Audible Region';

  @override
  String get audibleSeriesOpenOnAudible => 'Ouvrir sur Audible';

  @override
  String get audibleSeriesAddToCalendar => 'Ajouter au calendrier';

  @override
  String get audibleSeriesAddToUpcoming => 'Add to upcoming releases';

  @override
  String get audibleSeriesAddedToUpcoming => 'Added to upcoming releases';

  @override
  String get audibleSeriesAlreadyInUpcoming => 'Already on the upcoming page';

  @override
  String get audibleSeriesCouldNotOpenAudible => 'Could not open Audible';

  @override
  String get audibleSeriesCouldNotOpenCalendar => 'Could not open calendar';

  @override
  String audibleSeriesCalendarDescription(String seriesName) {
    return 'New audiobook release in the $seriesName series';
  }

  @override
  String get authorBooksGroupBySeries => 'Regrouper par série';

  @override
  String get authorBooksList => 'Liste';

  @override
  String get authorBooksGrid => 'Grille';

  @override
  String authorBooksBookCount(int count) {
    return '$count livres';
  }

  @override
  String get metadataLookupCover => 'Couverture';

  @override
  String get metadataLookupChooseFields => 'Choose Fields to Apply';

  @override
  String metadataLookupApplyFields(int count) {
    return 'Apply $count fields';
  }

  @override
  String metadataLookupFieldsSavedLocally(int count) {
    return '$count fields saved locally';
  }

  @override
  String get metadataLookupOverrideLocalDisplay => 'Override local display';

  @override
  String get equalizerPresetFlat => 'Plat';

  @override
  String get equalizerPresetVoiceBoost => 'Voice Boost';

  @override
  String get equalizerPresetBassBoost => 'Amplification des basses';

  @override
  String get equalizerPresetTrebleBoost => 'Amplification des aigus';

  @override
  String get equalizerPresetPodcast => 'Podcast';

  @override
  String get equalizerPresetAudiobook => 'Livre audio';

  @override
  String get equalizerPresetReduceNoise => 'Réduction du bruit';

  @override
  String get equalizerPresetLoudness => 'Volume';

  @override
  String equalizerEditingSavedNamed(String title) {
    return 'Editing saved EQ for \"$title\"';
  }

  @override
  String get equalizerEditingSavedGeneric => 'Édition de l\'EQ enregistré';

  @override
  String get equalizerPerBookEq => 'Per-book EQ';

  @override
  String get notesDeleteNoteQuestion => 'Supprimer la note ?';

  @override
  String notesDeleteNoteContent(String title) {
    return 'Delete \"$title\"?';
  }

  @override
  String get notesExport => 'Export';

  @override
  String get notesNewNote => 'Nouvelle note';

  @override
  String get librarySortFilterUpcomingReleases => 'Scan Series';

  @override
  String get librarySortFilterUpcomingReleasesSubtitle =>
      'Check Audible for upcoming and missing books in your series';

  @override
  String sleepTimerSheetChaptersLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count chapters left',
      one: '1 chapter left',
    );
    return '$_temp0';
  }

  @override
  String sleepTimerSheetAddMinutesChip(int minutes) {
    return '+${minutes}m';
  }

  @override
  String sleepTimerSheetAddChaptersChip(int count) {
    return '+$count ch';
  }

  @override
  String sleepTimerSheetMinShort(int minutes) {
    return '${minutes}m';
  }

  @override
  String sleepTimerSheetSecondsShort(int seconds) {
    return '${seconds}s';
  }

  @override
  String sleepTimerSheetMinSecShort(int minutes, int seconds) {
    return '${minutes}m ${seconds}s';
  }

  @override
  String sleepTimerSheetChaptersValue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count chapters',
      one: '1 chapter',
    );
    return '$_temp0';
  }

  @override
  String sleepTimerSheetChaptersChip(int count) {
    return '$count ch';
  }

  @override
  String sleepTimerSheetStartChapterSleep(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sleep after $count chapters',
      one: 'Sleep after 1 chapter',
    );
    return '$_temp0';
  }

  @override
  String get sleepTimerSheetRewindOnSleep => 'Retour après endormissement';

  @override
  String get sleepTimerSheetShake => 'Secouer';

  @override
  String sleepTimerSheetAddsMinutes(int minutes) {
    return 'Adds $minutes min';
  }

  @override
  String get sleepTimerSheetAddsOneChapter => 'Adds 1 chapter';

  @override
  String get sleepTimerSheetResetsToFull => 'Resets to full duration';

  @override
  String get sleepTimerSheetTabSpecificChapter => 'Chapitre';

  @override
  String get sleepTimerSheetSpecificNoChapters => 'No chapters available';

  @override
  String sleepTimerSheetSpecificChapterFallback(int number) {
    return 'Chapitre $number';
  }

  @override
  String get sleepTimerSheetSpecificPassedShort => 'passed';

  @override
  String get sleepTimerSheetSpecificStart => 'Début du chapitre';

  @override
  String get sleepTimerSheetSpecificEnd => 'Chapter End';

  @override
  String get sleepTimerSheetSpecificEndsAt => 'Sleep timer will end at';

  @override
  String sleepTimerSheetSpecificCountdown(String countdown) {
    return 'in $countdown';
  }

  @override
  String get sleepTimerSheetSpecificAlreadyPassed =>
      'This point has already passed';

  @override
  String get sleepTimerSheetSpecificStartButton => 'Start timer';

  @override
  String get sleepTimerSheetSpecificStartButtonPassed => 'Already passed';

  @override
  String get timeAm => 'AM';

  @override
  String get timePm => 'PM';

  @override
  String get collectionPickerCollectionFallback => 'Collection';

  @override
  String collectionPickerNameWithCount(String name, int count) {
    return '$name ($count)';
  }

  @override
  String get playlistPickerPlaylistFallback => 'Liste de lecture';

  @override
  String playlistPickerNameWithCount(String name, int count) {
    return '$name ($count)';
  }

  @override
  String get cardChaptersPlayFromChapterTitle => 'Jouer à partir du chapitre ?';

  @override
  String cardChaptersPlayFromChapterContent(String title) {
    return 'Start playing from \"$title\"?';
  }

  @override
  String get cardChaptersPlay => 'Lire';

  @override
  String get absorbingSharedToday => 'Aujourd\'hui';

  @override
  String get absorbingSharedYesterday => 'Hier';

  @override
  String get absorbingSharedMonday => 'Monday';

  @override
  String get absorbingSharedTuesday => 'Mardi';

  @override
  String get absorbingSharedWednesday => 'Mercredi';

  @override
  String get absorbingSharedThursday => 'Jeudi';

  @override
  String get absorbingSharedFriday => 'Friday';

  @override
  String get absorbingSharedSaturday => 'Samedi';

  @override
  String get absorbingSharedSunday => 'Sunday';

  @override
  String get absorbingSharedAm => 'AM';

  @override
  String get absorbingSharedPm => 'PM';

  @override
  String sectionDetailAddedToAbsorbing(String title) {
    return 'Added \"$title\" to Absorbing';
  }

  @override
  String get sectionDetailDoneBadge => 'Terminé';

  @override
  String get homeCustomizeAddGenreTitle => 'Add Genre Section';

  @override
  String get homeCustomizeAddGenreSubtitle =>
      'Pick a genre to show on your home screen';

  @override
  String get homeSectionDoneBadge => 'Terminé';

  @override
  String get tipsSheetQuickBookmarksTitle => 'Signets rapides';

  @override
  String get tipsSheetQuickBookmarksDesc =>
      'Appuyez longuement sur le bouton de signet de n\'importe quelle carte pour déposer instantanément un signet à votre position actuelle sans ouvrir la feuille de signets.';

  @override
  String get tipsSheetCoverPlayPauseTitle => 'Lecture/pause sur la couverture';

  @override
  String get tipsSheetCoverPlayPauseDesc =>
      'Appuyez sur la pochette de n\'importe quelle carte pour jouer ou mettre en pause. Activez ceci dans Réglages sous Cartes d\'Absorption. Une icône de pause pâle apparaît lors de la lecture pour que vous sachiez qu\'elle est tappable.';

  @override
  String get tipsSheetFullScreenPlayerTitle => 'Lecteur plein écran';

  @override
  String get tipsSheetFullScreenPlayerDesc =>
      'Swipe up on any absorbing card to open the full screen player. Swipe down to dismiss it.';

  @override
  String get tipsSheetQuickAddAbsorbingTitle => 'Quick Add to Absorbing';

  @override
  String get tipsSheetQuickAddAbsorbingDesc =>
      'Glissez à droite sur n\'importe quel livre dans une page de liste (séries, auteur, résultats de recherche) pour l\'ajouter instantanément à votre file d\'attente.';

  @override
  String get tipsSheetShakeExtendSleepTitle => 'Shake to Extend Sleep';

  @override
  String get tipsSheetShakeExtendSleepDesc =>
      'Si vous avez un minuteur de sommeil en cours et que vous secouez votre téléphone, cela ajoutera des minutes supplémentaires. Configurez la quantité dans les paramètres sous Minuterie de sommeil.';

  @override
  String get tipsSheetSeriesNavigationTitle => 'Series Navigation';

  @override
  String get tipsSheetSeriesNavigationDesc =>
      'Appuyez sur le nom de la série dans la popup de détails de n\'importe quel livre pour voir tous les livres de la série, trié en ordre de lecture avec des badges séquentiels sur chaque couverture.';

  @override
  String get tipsSheetSwipeBetweenBooksTitle => 'Swipe Between Books';

  @override
  String get tipsSheetSwipeBetweenBooksDesc =>
      'Glissez vers la gauche et la droite sur l\'écran Absorbing pour basculer entre vos livres en cours. Avec le mode file d\'attente manuelle activée, les cartes agissent également comme une file d\'attente, de sorte que la prochaine jouera automatiquement lorsque la carte actuelle se terminera.';

  @override
  String get tipsSheetTapToSeekTitle => 'Tap to Seek';

  @override
  String get tipsSheetTapToSeekDesc =>
      'Tapotez n\'importe où sur la barre de progression du chapitre ou du livre pour passer directement à cette position. Vous pouvez également faire glisser les barres pour un contrôle précis.';

  @override
  String get tipsSheetSpeedAdjustedTimeTitle => 'Speed-Adjusted Time';

  @override
  String get tipsSheetSpeedAdjustedTimeDesc =>
      'Temps restant et temps de chapitre s\'ajustent automatiquement en fonction de votre vitesse de lecture. Vous écoutez à 1,5x ? Le temps affiché reflète combien de temps il vous faudra effectivement.';

  @override
  String get tipsSheetPlaybackHistoryTitle => 'Historique de lecture';

  @override
  String get tipsSheetPlaybackHistoryDesc =>
      'Appuyez sur le bouton Historique de n\'importe quelle carte pour voir une chronologie de chaque lecture, pause, recherche et changement de vitesse. Appuyez sur n\'importe quel événement pour revenir à cette position.';

  @override
  String get tipsSheetAutoRewindTitle => 'Auto-Rewind';

  @override
  String get tipsSheetAutoRewindDesc =>
      'Lorsque vous redémarrez après une pause, Absorb revient en arrière automatiquement de quelques secondes pour ne pas perdre votre place. La durée du retour varie avec le temps d\'absence. Configurez-le dans les paramètres.';

  @override
  String get tipsSheetSeriesQueueModeTitle => 'Series Queue Mode';

  @override
  String get tipsSheetSeriesQueueModeDesc =>
      'Quand vous avez terminé un livre qui fait partie d\'une série, Absorb peut automatiquement lire le livre suivant. Réglez le mode file d\'attente sur \"Séries\" dans les paramètres.';

  @override
  String get tipsSheetOfflineModeTitle => 'Mode hors-ligne';

  @override
  String get tipsSheetOfflineModeDesc =>
      'Appuyez sur le bouton Avion de l\'écran Absorption pour passer en mode hors ligne. Ceci arrête la synchronisation, enregistre les données et affiche uniquement les livres téléchargés. Idéal pour les vols ou les zones de faible signal.';

  @override
  String get tipsSheetUpcomingReleasesTitle => 'Upcoming Releases';

  @override
  String get tipsSheetUpcomingReleasesDesc =>
      'Dans l\'onglet Série, appuyez à nouveau sur l\'onglet pour ouvrir sa page de tri et de filtre, puis choisissez Sorties à venir pour voir les nouveaux livres et ceux à venir de votre série, triés par date de publication.';

  @override
  String get tipsSheetPerBookEqTitle => 'Égaliseur par livre';

  @override
  String get tipsSheetPerBookEqDesc =>
      'Chaque livre se souvient de ses propres paramètres d\'égaliseur. Ajuster l\'EQ une fois pour une épopée de science-fiction et la prochaine fois que vous la jouerez, il sonnera pareil.';

  @override
  String get tipsSheetPerBookSpeedTitle => 'Per-Book Speed';

  @override
  String get tipsSheetPerBookSpeedDesc =>
      'La vitesse de lecture est enregistrée par livre. Écoutez une non-fiction à 1,5x et une fiction dramatique à 1,0x sans le définir à chaque fois.';

  @override
  String get tipsSheetAutoSleepWindowTitle => 'Auto Sleep Window';

  @override
  String get tipsSheetAutoSleepWindowDesc =>
      'Choisissez les heures où vous vous endormez habituellement et le minuteur de sommeil se déclenchera quand vous commencerez à écouter dans cette plage.';

  @override
  String get tipsSheetSleepFadeChimeTitle => 'Sleep Fade and Chime';

  @override
  String get tipsSheetSleepFadeChimeDesc =>
      'Quand le minuteur de sommeil se termine, l\'audio s\'estompe graduellement et une cloche optionnelle joue pour qu\'il ne coupe pas au milieu d\'une phrase.';

  @override
  String get tipsSheetCarModeTitle => 'Mode voiture';

  @override
  String get tipsSheetCarModeDesc =>
      'Tap the car icon to switch to giant-button mode designed for safer use while driving.';

  @override
  String get tipsSheetAudibleSeriesTitle => 'Audible Series Discovery';

  @override
  String get tipsSheetAudibleSeriesDesc =>
      'Ouvrez une série et utilisez le menu de débordement (les trois points) pour récupérer la liste complète des séries d\'Audible, y compris les entrées manquantes et les livres que vous n\'avez pas commencés.';

  @override
  String get bookCardUnknownTitle => 'Titre inconnu';

  @override
  String get bookCardExplicitBadge => 'E';

  @override
  String get bookCardDone => 'Terminé';

  @override
  String get bookCardSaved => 'Enregistré';

  @override
  String get episodeRowEpisode => 'Épisode';

  @override
  String get episodeRowToday => 'Aujourd\'hui';

  @override
  String get episodeRowYesterday => 'Hier';

  @override
  String episodeRowDaysAgo(int count) {
    return 'Il y a $count j';
  }

  @override
  String episodeRowWeeksAgo(int count) {
    return 'Il y a $count sem';
  }

  @override
  String episodeRowDurationHm(int hours, int minutes) {
    return '${hours}h ${minutes}m';
  }

  @override
  String episodeRowDurationM(int minutes) {
    return '${minutes}m';
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
  String get librarySearchResultsDone => 'Terminé';

  @override
  String get librarySearchResultsSaved => 'Enregistré';

  @override
  String librarySearchResultsSequence(String number) {
    return '#$number';
  }

  @override
  String get librarySearchResultsUnknownSeries => 'Unknown Series';

  @override
  String get librarySearchResultsUnknownEpisode => 'Épisode inconnu';

  @override
  String librarySearchResultsBookCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count books',
      one: '1 book',
    );
    return '$_temp0';
  }

  @override
  String get libraryGridTilesExplicitBadge => 'E';

  @override
  String get libraryGridTilesDone => 'Terminé';

  @override
  String get libraryGridTilesSaved => 'Enregistré';

  @override
  String libraryGridTilesSequence(String number) {
    return '#$number';
  }

  @override
  String get libraryGridTilesUnknownSeries => 'Unknown Series';

  @override
  String get seriesCardUnknownSeries => 'Unknown Series';

  @override
  String seriesCardBookCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count books',
      one: '1 book',
    );
    return '$_temp0';
  }

  @override
  String get cardProgressFineScrubbing => 'Fine Scrubbing';

  @override
  String get cardProgressQuarterSpeed => 'Vitesse /4';

  @override
  String get cardProgressHalfSpeed => 'Vitesse /2';

  @override
  String cardProgressChapterPrefix(String number) {
    return 'Chapitre $number';
  }

  @override
  String get cardEdgeProgressFineScrubbing => 'Fine Scrubbing';

  @override
  String get cardEdgeProgressQuarterSpeed => 'Vitesse /4';

  @override
  String get cardEdgeProgressHalfSpeed => 'Vitesse /2';

  @override
  String get authSessionExpired => 'Session expired. Please log in again.';

  @override
  String authCannotReachServer(String url) {
    return 'Cannot reach server at $url';
  }

  @override
  String get authInvalidUsernameOrPassword => 'Invalid username or password';

  @override
  String get authInvalidApiKey => 'Clé API invalide';

  @override
  String get authLoginFailedDetail =>
      'Login failed - check your server address and credentials';

  @override
  String get authUnexpectedServerResponse => 'Unexpected server response';

  @override
  String get authSsoUnexpectedResponse => 'SSO returned an unexpected response';

  @override
  String get authSwitchedToLocalServer => 'Switched to local server';

  @override
  String get authSwitchedToRemoteServer => 'Switched to remote server';

  @override
  String get lpDeletedFinishedDownload => 'Téléchargement achevé supprimé';

  @override
  String lpSubscribedPodcastDownloading(String showTitle, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nouveaux épisodes en cours de téléchargement',
      one: '1 nouvel épisode en cours de téléchargement',
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
  String lpSubscribedEpisodeDownloaded(String showTitle) {
    return 'New $showTitle episode downloaded';
  }

  @override
  String get statsWeekStartsOn => 'Week starts on';

  @override
  String get episodeListNewEpisodePosition => 'New episode position';

  @override
  String get episodeListPositionTop => 'En haut de la file d\'attente';

  @override
  String get episodeListPositionSecond => 'Deuxième dans la file d\'attente';

  @override
  String get episodeListPositionEnd => 'Fin de la file d\'attente';

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
      other: 'Queue: downloading $count items',
      one: 'Queue: downloading 1 item',
    );
    return '$_temp0';
  }

  @override
  String lpDownloadingBooks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Downloading $count books',
      one: 'Downloading 1 book',
    );
    return '$_temp0';
  }

  @override
  String lpDownloadingEpisodes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Downloading $count episodes',
      one: 'Downloading 1 episode',
    );
    return '$_temp0';
  }

  @override
  String get downloadNotifProgressChannelName => 'Download Progress';

  @override
  String get downloadNotifProgressChannelDesc =>
      'Affiche la progression pendant les téléchargements de livres audio';

  @override
  String get downloadNotifAlertChannelName => 'Alertes de téléchargement';

  @override
  String get downloadNotifAlertChannelDesc =>
      'Notifications when downloads finish or fail';

  @override
  String get downloadNotifDownloadingTitle => 'Téléchargement…';

  @override
  String downloadNotifActiveCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count downloads active',
      one: '1 download active',
    );
    return '$_temp0';
  }

  @override
  String downloadNotifSlotTitle(String title) {
    return 'Downloading: $title';
  }

  @override
  String get downloadNotifStartingLabel => 'Démarrage…';

  @override
  String get downloadNotifCompleteTitle => 'Download Complete';

  @override
  String downloadNotifCompleteBody(String title) {
    return '$title is ready to listen offline';
  }

  @override
  String get downloadNotifFailedTitle => 'Téléchargement échoué';

  @override
  String get upcomingNotifChannelName => 'Upcoming Release Scan';

  @override
  String get upcomingNotifChannelDesc =>
      'Shows progress while scanning for upcoming releases';

  @override
  String get upcomingNotifScanTitle => 'Scanning for upcoming releases';

  @override
  String get upcomingNotifStartingScan => 'Starting scan…';

  @override
  String upcomingNotifCheckingSeries(
    String seriesName,
    int current,
    int total,
  ) {
    return 'Checking $seriesName… ($current/$total)';
  }

  @override
  String get upcomingNotifFoundTitle => 'Upcoming releases found!';

  @override
  String upcomingNotifFoundBody(int books, int series) {
    String _temp0 = intl.Intl.pluralLogic(
      series,
      locale: localeName,
      other: '$series series',
      one: '1 series',
    );
    return '$books upcoming across $_temp0';
  }

  @override
  String get androidAutoTabContinue => 'Continuer';

  @override
  String get androidAutoTabLibrary => 'Bibliothèque';

  @override
  String get androidAutoTabDownloads => 'Téléchargements';

  @override
  String get androidAutoCatBooks => 'Livres';

  @override
  String get androidAutoCatSeries => 'Series';

  @override
  String get androidAutoCatAuthors => 'Auteurs';

  @override
  String get showTipsAgain => 'Afficher les conseils à nouveau';

  @override
  String get showTipsAgainSubtitle =>
      'Bring back feature tips you\'ve dismissed';

  @override
  String get tipsRestored => 'Conseils rétablis';

  @override
  String get resetSpeedPresets => 'Reset speed presets';

  @override
  String get resetSpeedPresetsSubtitle =>
      'Restore the default playback speed chips';

  @override
  String get speedPresetsReset => 'Speed presets reset';

  @override
  String get editAuthor => 'Edit author';

  @override
  String get authorName => 'Nom';

  @override
  String get authorImage => 'Image de l\'auteur';

  @override
  String get authorRemoveImage => 'Supprimer l’image';

  @override
  String get authorRemoveImageTitle => 'Remove author image?';

  @override
  String get authorRemoveImageConfirm =>
      'This deletes the image on the server.';

  @override
  String get authorImageRemoved => 'Image supprimée';

  @override
  String get authorImageFailed => 'Couldn\'t update author image';

  @override
  String get authorUpdated => 'Author updated';

  @override
  String get authorUpdateFailed => 'Couldn\'t update author';

  @override
  String get authorMatched => 'Author updated from match';

  @override
  String get authorNoMatchFound => 'No match found';

  @override
  String authorMergedInto(String name) {
    return 'Fusionné dans $name';
  }

  @override
  String get authorQuickMatchHint =>
      'Récupérer le nom, l\'ASIN, la description et l\'image de Audible pour la région choisie.';

  @override
  String get region => 'Region';

  @override
  String get editTabDetails => 'Détails';

  @override
  String get editTabCover => 'Couverture';

  @override
  String get editTabMatch => 'Match';

  @override
  String get editTabEmbed => 'Intégré';

  @override
  String get chapterEditorTitle => 'Modifier les chapitres';

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
  String get chapterEditStartTitle => 'Modifier l\'heure de début';

  @override
  String get chapterTimeHintSeconds => 'Secondes';

  @override
  String get chapterTimeHintFull => 'HH:MM:SS or seconds';

  @override
  String get chapterInvalidTime => 'Heure non valide';

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
  String get add => 'Ajouter';

  @override
  String get chapterCountRange => 'Enter a count between 1 and 150';

  @override
  String get chapterTitlesUpdated => 'Chapter titles updated';

  @override
  String get chaptersApplied => 'Chapitres appliqués';

  @override
  String get chapterDiscardTitle => 'Abandonner les changements ?';

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
  String get chaptersUpdated => 'Chapitres mis à jour';

  @override
  String get ok => 'OK';

  @override
  String get chapterSaveButton => 'Enregistrer les chapitres';

  @override
  String get chapterAddHint => 'Add chapter (e.g. \"Chapter 01\")';

  @override
  String get chapterAddTooltip => 'Add chapter(s)';

  @override
  String get chapterRemoveAll => 'Tout supprimer';

  @override
  String get chapterShiftTimes => 'Shift Times';

  @override
  String get chapterFromTracks => 'From Tracks';

  @override
  String get chapterLookup => 'Lookup';

  @override
  String get chapterShowSeconds => 'Afficher les secondes';

  @override
  String get chapterShiftBySeconds => 'Décaler de (secondes)';

  @override
  String get chapterShiftHint =>
      'Shifts every unlocked chapter. Use a negative value to move them earlier.';

  @override
  String get chapterBack1Second => 'Retour de 1 seconde';

  @override
  String get chapterForward1Second => 'Avancer de 1 seconde';

  @override
  String get chapterTitleHint => 'Titre du chapitre';

  @override
  String get chapterStopPreview => 'Arrêt de l\'aperçu';

  @override
  String get chapterPreviewFromHere => 'Preview from here';

  @override
  String get chapterScrubHint => 'Scrub to the exact spot, then set';

  @override
  String chapterStartAt(String time) {
    return 'Commencer à $time';
  }

  @override
  String get chapterSetStartHere => 'Set start here';

  @override
  String get chapterMore => 'Plus';

  @override
  String get chapterUnlock => 'Déverrouiller';

  @override
  String get chapterLock => 'Verrouiller';

  @override
  String get chapterInsertBelow => 'Insérer en dessous';

  @override
  String get chapterFindTitle => 'Rechercher les chapitres';

  @override
  String get chapterFindSubtitle =>
      'Looks up chapters from Audible/Audnexus by ASIN.';

  @override
  String get chapterEnterAsin => 'Entrez un ASIN';

  @override
  String get chapterLookupFailed => 'Lookup failed - check the ASIN';

  @override
  String get chapterNoChaptersFound => 'No chapters found for that ASIN';

  @override
  String get chapterRemoveBranding => 'Remove Audible branding (intro/outro)';

  @override
  String chapterFoundCount(int count) {
    return '$count chapitres trouvés';
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
      'La version Audible est plus courte que votre fichier - les chapitres peuvent ne pas s\'aligner.';

  @override
  String get chapterTitlesOnly => 'Titles only';

  @override
  String get chapterApplyChapters => 'Apply chapters';

  @override
  String get coverSearchTitle => 'Rechercher une couverture';

  @override
  String get coverSearchRefineHint =>
      'Affinez le titre/auteur pour nettoyer les résultats - cela ne change pas le livre.';

  @override
  String get coverNoneFound => 'Aucune couverture trouvée';

  @override
  String get coverEnterTitleFirst => 'Enter a title first';

  @override
  String get coverUpdated => 'Couverture mise à jour';

  @override
  String get coverCouldNotUpdate => 'Could not update cover';

  @override
  String get coverApply => 'Appliquer la couverture';

  @override
  String get coverUnknownResolution => 'Résolution inconnue';

  @override
  String get embedIntro =>
      'Embed metadata into audio files including cover image and chapters.';

  @override
  String get embedBackupOption => 'Back up audio files first';

  @override
  String get embedNoteInFolder =>
      'Les métadonnées seront intégrées dans les pistes audio dans le dossier de votre livre audio.';

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
  String get embedProgressIndeterminate => 'Intégration...';

  @override
  String taskProgressKeepsRunning(String percent) {
    return '$percent% - keeps running if you leave this page';
  }

  @override
  String get taskStarting => 'Démarrage...';

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
      other: '# fichiers audio',
      one: '# fichier audio',
    );
    return 'Intégrez les métadonnées dans $_temp0? Vos fichiers audio seront réécrits$backup.';
  }

  @override
  String get embedConfirmBackupClause => ' (originals backed up first)';

  @override
  String get embedConfirmAction => 'Intégrer';

  @override
  String get embedCouldNotStart => 'Could not start embed';

  @override
  String get embedStarted => 'Intégration démarrée';

  @override
  String get embedComplete => 'Embed complete';

  @override
  String get embedFailed => 'Échec de l\'intégration';

  @override
  String get encodeComplete => 'Encodage terminé';

  @override
  String get encodeFailedTask => 'L\'encodage a échoué';

  @override
  String encodeProgress(String percent) {
    return 'Encoding $percent%';
  }

  @override
  String get encodeProgressIndeterminate => 'Encodage...';

  @override
  String get adminApiKeys => 'Clés API';

  @override
  String get adminApiKeysSubtitle => 'Programmatic access tokens';

  @override
  String get adminApiKeysNewTitle => 'Nouvelle clé API';

  @override
  String get adminApiKeysName => 'Nom';

  @override
  String get adminApiKeysNameHint => 'e.g. Home Assistant';

  @override
  String get adminApiKeysOwner => 'Utilisateur';

  @override
  String get adminApiKeysExpiration => 'Expiration';

  @override
  String get adminApiKeysActive => 'Active';

  @override
  String get adminApiKeysActiveSub => 'Key works as soon as it\'s created';

  @override
  String get adminApiKeysInactive => 'Inactive';

  @override
  String get adminApiKeysExpired => 'Expirée';

  @override
  String get adminApiKeysCreate => 'Créer une clé';

  @override
  String get adminApiKeysCreated => 'Clé API créée';

  @override
  String get adminApiKeysTokenLabel => 'Votre nouvelle clé API';

  @override
  String get adminApiKeysCopyWarning =>
      'Copiez cette clé maintenant. Par sécurité, elle ne sera pas affichée à nouveau.';

  @override
  String get adminApiKeysCopy => 'Copier';

  @override
  String get adminApiKeysCopied => 'Copiée dans le presse-papiers';

  @override
  String get adminApiKeysDone => 'Terminé';

  @override
  String get adminApiKeysDeleteTitle => 'Révoquer la clé API ?';

  @override
  String get adminApiKeysDeleted => 'Clé API révoquée';

  @override
  String get adminApiKeysRevoke => 'Révoquer';

  @override
  String get adminApiKeysSetActive => 'Activer';

  @override
  String get adminApiKeysSetInactive => 'Désactiver';

  @override
  String get adminApiKeysFailedCreate => 'Couldn\'t create API key';

  @override
  String get adminApiKeysFailedDelete => 'Couldn\'t revoke API key';

  @override
  String get adminApiKeysFailedUpdate => 'Couldn\'t update API key';

  @override
  String get adminApiKeysEmpty => 'Aucune clé API pour le moment';

  @override
  String get adminApiKeysEmptySub =>
      'Create one to let apps and scripts reach your server';

  @override
  String get adminApiKeysNeverUsed => 'Jamais utilisée';

  @override
  String get adminApiKeysNeverExpires => 'Pas d\'expiration';

  @override
  String get adminApiKeysNameRequired => 'Entrez un nom';

  @override
  String get adminApiKeysUserRequired => 'Sélectionner un utilisateur';

  @override
  String get adminApiKeysExpNever => 'Jamais';

  @override
  String get adminApiKeysExp7d => '7 jours';

  @override
  String get adminApiKeysExp30d => '30 jours';

  @override
  String get adminApiKeysExp90d => '90 jours';

  @override
  String get adminApiKeysExp1y => '1 an';

  @override
  String adminApiKeysLastUsed(String time) {
    return 'Dernière utilisation $time';
  }

  @override
  String adminApiKeysExpiresOn(String date) {
    return 'Expire le $date';
  }

  @override
  String adminApiKeysDeleteContent(String name) {
    return 'Révoquer \"$name\" ? Les applications utilisant cette clé perdront accès immédiatement.';
  }

  @override
  String get endOfEpisode => 'End of Episode';

  @override
  String get sleepTimerSheetEpisodeSleepStart => 'Sleep at end of episode';

  @override
  String get bookmarkListen => 'Écouter';

  @override
  String get bookmarkPause => 'Pause';

  @override
  String get bookmarkPreviewFailed => 'Couldn\'t play this spot.';

  @override
  String get clipExport => 'Exporter le clip';

  @override
  String get clipJumpToStart => 'Se déplacer au début';

  @override
  String get clipJumpToEnd => 'Sauter à la fin';

  @override
  String get clipSetStart => 'Définir le début';

  @override
  String get clipSetEnd => 'Set end';

  @override
  String get clipInLabel => 'In';

  @override
  String get clipOutLabel => 'Out';

  @override
  String get clipSave => 'Enregistrer le clip';

  @override
  String clipExportSaved(String filename) {
    return '$filename sauvegardé';
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
  String get fsPickerTitle => 'Sélectionner un dossier';

  @override
  String get fsServerRoot => 'Racine du serveur';

  @override
  String get fsEmptyFolder => 'Aucun sous-dossier ici';

  @override
  String get fsUseThisFolder => 'Utiliser ce dossier';

  @override
  String get adminLibrariesManage => 'Bibliothèques';

  @override
  String get adminLibrariesManageSubtitle => 'Create, edit and reorder';

  @override
  String get adminUploadTitle => 'Téléverser un média';

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
  String get adminUploadDetails => 'Détails de l\'élément';

  @override
  String get adminUploadOptional => 'Facultatif';

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
  String get adminUploadDestinationPreview => 'Serveur destinataire';

  @override
  String get adminUploadFiles => 'Fichiers';

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
  String get adminUploadChooseFiles => 'Choisir les fichiers';

  @override
  String get adminUploadAddFiles => 'Ajouter des fichiers';

  @override
  String get adminUploadBookFilesHint =>
      'Choisissez des fichiers audio ou ebook. Vous pouvez également inclure des fichiers de couvertures et de métadonnées.';

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
  String get adminUploadTitleRequired => 'Entrez un titre';

  @override
  String get adminUploadLibraryRequired => 'Choisir une bibliothèque';

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
  String get adminUploadUploading => 'Envoi...';

  @override
  String adminUploadProgress(int percent) {
    return 'Uploading $percent%';
  }

  @override
  String get adminUploadButton => 'Upload';

  @override
  String adminUploadComplete(String title) {
    return 'Envoyé \"$title\"';
  }

  @override
  String get adminUploadFailed => 'Échec de l’envoi';

  @override
  String adminUploadFailedReason(String error) {
    return 'Upload failed: $error';
  }

  @override
  String get adminUploadReselectFiles =>
      'Choose the files again before retrying.';

  @override
  String get adminServerSettings => 'Paramètres du serveur';

  @override
  String get adminServerSettingsSubtitle => 'Scanner, storage and sorting';

  @override
  String get adminStats => 'Statistiques';

  @override
  String get adminStatsSubtitle => 'Library and listening totals';

  @override
  String get adminAllSessions => 'Toutes les sessions';

  @override
  String get adminAllSessionsSubtitle =>
      'View and manage all listening sessions';

  @override
  String get adminSessionsAllUsers => 'Tous les utilisateurs';

  @override
  String get adminSessionsEmpty => 'Aucune session';

  @override
  String get statsLibraryTotals => 'Library totals';

  @override
  String get statsTotalItems => 'Éléments';

  @override
  String get statsAudioFiles => 'Fichiers audio';

  @override
  String get statsTotalSize => 'Taille totale';

  @override
  String get statsBooks => 'Livres';

  @override
  String get statsPodcasts => 'Podcasts';

  @override
  String get statsBooksSize => 'Taille des livres';

  @override
  String get statsYearReview => 'Year in review';

  @override
  String get statsNoYearData => 'No data for this year';

  @override
  String get statsListeningTime => 'Listening time';

  @override
  String get statsSessions => 'Sessions';

  @override
  String get statsBooksAdded => 'Livres ajoutés';

  @override
  String get statsAuthorsAdded => 'Auteurs ajoutés';

  @override
  String get statsTopAuthors => 'Meilleurs auteurs';

  @override
  String get statsTopNarrators => 'Les meilleurs narrateurs';

  @override
  String get statsTopGenres => 'Genres Principaux';

  @override
  String get srvScannerSection => 'Scanneur';

  @override
  String get srvFindCovers => 'Trouver des couvertures';

  @override
  String get srvCoverProvider => 'Fournisseur de couverture';

  @override
  String get srvParseSubtitles => 'Parse subtitles from filename';

  @override
  String get srvPreferMatched => 'Prefer matched metadata';

  @override
  String get srvDisableWatcher => 'Disable folder watcher';

  @override
  String get srvStorageSection => 'Stockage';

  @override
  String get srvStoreCover => 'Store cover with item';

  @override
  String get srvStoreMetadata => 'Store metadata with item';

  @override
  String get srvMetadataFormat => 'Format de fichier de métadonnées';

  @override
  String get srvFormatSection => 'Affichage et format';

  @override
  String get srvDateFormat => 'Format de date';

  @override
  String get srvTimeFormat => 'Format de l\'heure';

  @override
  String get srvLanguage => 'Langage du serveur';

  @override
  String get srvChromecast => 'Support Chromecast';

  @override
  String get srvAllowIframe => 'Allow iframe embedding';

  @override
  String get srvSortingSection => 'Tri';

  @override
  String get srvIgnorePrefixes => 'Ignore prefixes when sorting';

  @override
  String get srvSortingPrefixes => 'Préfixes de tri';

  @override
  String get srvAddPrefix => 'Ajouter un préfixe';

  @override
  String get srvSave => 'Enregistrer les paramètres';

  @override
  String get srvSavePrefixes => 'Enregistrer les préfixes';

  @override
  String get srvSaved => 'Paramètres sauvegardés';

  @override
  String get srvSaveFailed => 'Couldn\'t save settings';

  @override
  String get srvPrefixesSaved => 'Sorting prefixes updated';

  @override
  String get libNoneYet => 'Pas encore de bibliothèques';

  @override
  String get libReorderFailed => 'Couldn\'t save the new order';

  @override
  String get libDeleteTitle => 'Supprimer la bibliothèque ?';

  @override
  String get libDeleteBody =>
      'Cela supprime définitivement la bibliothèque et tous ses éléments du serveur.';

  @override
  String get libDeleted => 'Bibliothèque supprimée';

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
  String get libNewTitle => 'Nouvelle bibliothèque';

  @override
  String get libEditTitle => 'Modifier la bibliothèque';

  @override
  String get libName => 'Nom de la bibliothèque';

  @override
  String get libMediaType => 'Media type';

  @override
  String get libMediaBook => 'Livres audio';

  @override
  String get libMediaPodcast => 'Podcasts';

  @override
  String get libProvider => 'Fournisseur de métadonnées';

  @override
  String get libIcon => 'Icône';

  @override
  String get libFolders => 'Dossiers';

  @override
  String get libAddFolder => 'Add folder';

  @override
  String get libNoFolders => 'Add at least one folder';

  @override
  String get libAdvanced => 'Advanced settings';

  @override
  String get libCoverShape => 'Forme de couverture';

  @override
  String get libCoverSquare => 'Carré';

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
  String get libAudiobooksOnly => 'Livres audio uniquement';

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
  String get libCreate => 'Créer une bibliothèque';

  @override
  String get libUpdate => 'Enregistrer les modifications';

  @override
  String get libNameRequired => 'Enter a library name';

  @override
  String get libCreated => 'Bibliothèque créée';

  @override
  String get libCreateFailed => 'Couldn\'t create library';

  @override
  String get libUpdated => 'Bibliothèque mise à jour';

  @override
  String get libUpdateFailed => 'Couldn\'t update library';

  @override
  String get libRemoveFoldersTitle => 'Supprimer les dossiers ?';

  @override
  String get libRemoveFoldersBody =>
      'La suppression d\'un dossier supprime ses éléments de la bibliothèque. Cette action est irréversible.';

  @override
  String get readEbook => 'Lu';

  @override
  String get ebookDownload => 'Télécharger';

  @override
  String get ebookDownloaded => 'Downloaded';

  @override
  String get ebookSavedOffline => 'Saved for offline reading';

  @override
  String get ebookRemovedOffline => 'Removed from offline';

  @override
  String get ebookOfflineFailed => 'Couldn\'t download the ebook';

  @override
  String get ebookSaveToDevice => 'Enregistrer sur l’appareil';

  @override
  String get ebookSaveToDeviceTitle => 'Enregistrer sur l\'appareil ?';

  @override
  String get ebookSaveToDeviceBody =>
      'Cela enregistre une copie du fichier ebook quelque part sur votre appareil (vous choisissez où). Il ne rendra pas le livre disponible hors ligne dans le lecteur - utilisez Download pour cela.';

  @override
  String get readerFormatUnsupported =>
      'This ebook format can\'t be opened in the reader yet';

  @override
  String get moreActions => 'Plus';

  @override
  String get readerChapters => 'Chapitres';

  @override
  String get readerSettings => 'Paramètres du lecteur';

  @override
  String get readerFontSize => 'Taille de la police';

  @override
  String get readerLineSpacing => 'Interligne';

  @override
  String get readerSideMargins => 'Marges latérales';

  @override
  String get readerTopBottom => 'Haut et bas';

  @override
  String get readerPageLayout => 'Mise en page';

  @override
  String get readerLayoutAuto => 'Auto';

  @override
  String get readerLayoutSingle => 'Single';

  @override
  String get readerLayoutTwoPage => 'Double page';

  @override
  String get readerTheme => 'Thème';

  @override
  String get readerFont => 'Police';

  @override
  String get readerVolumeNav => 'Les boutons de volume tournent les pages';

  @override
  String get readerVolumeNavOff => 'Désactivé';

  @override
  String get readerVolumeNavNormal => 'Normal';

  @override
  String get readerVolumeNavMirrored => 'Inversé';

  @override
  String get readerVolumeNavWhilePlaying =>
      'Même lorsque l\'audio est en cours de lecture';

  @override
  String get readerMoreFonts => 'Télécharger plus de polices';

  @override
  String get readerFontRemove => 'Retirer le téléchargement';

  @override
  String readerFontDownloadFailed(String font) {
    return 'Échec du téléchargement de $font';
  }

  @override
  String get readerAnnotations => 'Notes';

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
  String get readerNoBookmarks => 'Aucun signet pour l\'instant';

  @override
  String get readerBookmarkDefault => 'Signet';

  @override
  String get readerNoteTitle => 'Note';

  @override
  String get readerNoteHint => 'Ajouter une note...';

  @override
  String get readerCopied => 'Copied to clipboard';

  @override
  String get readerTooltipCopy => 'Copier';

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
  String get readerSearchEmpty =>
      'Entrez un mot ou une phrase puis recherchez.';

  @override
  String readerSearchNoResults(String query) {
    return 'No matches for \"$query\".';
  }
}
