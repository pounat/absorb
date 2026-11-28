// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'A B S O R B';

  @override
  String get online => 'Подключен';

  @override
  String get offline => 'Не в сети';

  @override
  String get stillOffline =>
      'Не удается подключиться. Нажмите, чтобы попробовать еще раз.';

  @override
  String get retry => 'Повторить';

  @override
  String get listsNone => 'Нет коллекций или плейлистов';

  @override
  String get listsNoneHint =>
      'Коллекции и плейлисты создаются на вашем сервере Audiobookshelf и появляются здесь.';

  @override
  String get listsLoadFailed => 'Не удалось загрузить ваши списки';

  @override
  String get listsLoadFailedHint =>
      'Absorb не смог достичь вашего сервера для коллекций и плейлистов.';

  @override
  String get listsNoneBookOrbit => 'Нет коллекций или Smart Scopes';

  @override
  String get listsNoneHintBookOrbit =>
      'Коллекции и Smart Scopes сделаны на вашем сервере BookOrbit и отображаются здесь.';

  @override
  String get listsLoadFailedHintBookOrbit =>
      'Absorb не смог связаться с вашим сервером для коллекций и Smart Scope.';

  @override
  String get cancel => 'Отменить';

  @override
  String get delete => 'Удалить';

  @override
  String get remove => 'Убрать';

  @override
  String get save => 'Сохранить';

  @override
  String get done => 'Выполнено';

  @override
  String get edit => 'Править';

  @override
  String get search => 'Поиск';

  @override
  String get apply => 'Применить';

  @override
  String get enable => 'Включить';

  @override
  String get clear => 'Очистить';

  @override
  String get off => 'Выкл';

  @override
  String get disabled => 'Отключено';

  @override
  String get later => 'Позже';

  @override
  String get whatsNewTitle => 'Absorb было обновлено';

  @override
  String whatsNewContent(String version) {
    return 'Теперь ты на $version.';
  }

  @override
  String get whatsNewButton => 'Узнать, что нового';

  @override
  String get whatsNewKeepShowing => 'Show this after every update';

  @override
  String get whatsNewKeepShowingHint => 'You can turn it back on in Settings';

  @override
  String get settingsWhatsNew => 'Show what\'s new after updates';

  @override
  String get settingsWhatsNewSubtitle =>
      'After Absorb updates, a popup links to the release notes';

  @override
  String get gotIt => 'Понятно';

  @override
  String get betaLoggingTitle => 'Logs are on';

  @override
  String get betaLoggingContent =>
      'Since this is a beta, Absorb now keeps logs to help track down problems. They stay on this device unless you share them.\n\nYou can send them or turn them off in Settings, under Issues & Support. If you turn them off, later betas leave them off.';

  @override
  String get preview => 'Предпросмотр';

  @override
  String get or => 'или';

  @override
  String get file => 'Файл';

  @override
  String get more => 'Больше';

  @override
  String get unknown => 'Неизвестно';

  @override
  String get untitled => 'Без названия';

  @override
  String get noThanks => 'Нет, спасибо';

  @override
  String get stay => 'Остаться';

  @override
  String get homeTitle => 'Главная';

  @override
  String get continueListening => 'Продолжить Слушать';

  @override
  String get continueReading => 'Продолжить чтение';

  @override
  String get continueSeries => 'Продолжить Серию';

  @override
  String get recentlyAdded => 'Недавно Добавлено';

  @override
  String get listenAgain => 'Послушать Ещё Раз';

  @override
  String get discover => 'Подборка';

  @override
  String get newEpisodes => 'Новые Выпуски';

  @override
  String get downloads => 'Сохраненные';

  @override
  String get noDownloadedBooks => 'Нет загруженных книг';

  @override
  String get yourLibraryIsEmpty => 'Ваша библиотека пуста';

  @override
  String get downloadBooksWhileOnline =>
      'Скачивать книги пока в сети, чтобы слушать офлайн';

  @override
  String get customizeHome => 'Настроить Главную';

  @override
  String get dragToReorderTapEye =>
      'Перетащи для сортировки, нажми на глаза, чтобы показать/скрыть';

  @override
  String get loginTagline => 'Начать Поглощение';

  @override
  String get loginConnectToServer => 'Подключиться к вашему серверу';

  @override
  String get loginServerAddress => 'Адрес сервера';

  @override
  String get loginServerHint => 'my.server.com';

  @override
  String get loginServerHelper =>
      'IP:port тоже работает (например 192.168.1.5:13378)';

  @override
  String get loginCouldNotReachServer => 'Не удалось подключиться к серверу';

  @override
  String get loginAdvanced => 'Расширенные';

  @override
  String get loginCustomHttpHeaders => 'Пользовательские HTTP-заголовки';

  @override
  String get loginCustomHeadersDescription =>
      'Для Cloudflare туннелей или обратных прокси для которых требуются дополнительные заголовки. Добавьте заголовки перед введением URL вашего сервера.';

  @override
  String get loginHeaderName => 'Имя заголовка';

  @override
  String get loginHeaderValue => 'Значение';

  @override
  String get loginAddHeader => 'Добавить заголовок';

  @override
  String get loginSelfSignedCertificates => 'Самоподписанные сертификаты';

  @override
  String get loginTrustAllCertificates =>
      'Доверять всем сертификатам (для самоподписанных / пользовательских настроек ЦС)';

  @override
  String get loginApiKey => 'Ключ API';

  @override
  String get loginApiKeyDescription =>
      'Использовать созданный администратором API ключ вместо имени пользователя/пароля. Полезно при сбое обновления токена для вашей учетной записи.';

  @override
  String get loginWaitingForSso => 'Ожидаем SSO...';

  @override
  String get loginRedirectUri => 'Редирект URI: absorb://oauth';

  @override
  String get loginOrSignInManually => 'или войти вручную';

  @override
  String get loginUsername => 'Логин';

  @override
  String get loginUsernameRequired => 'Пожалуйста, введите логин';

  @override
  String get loginPassword => 'Пароль';

  @override
  String get loginSignIn => 'Войти';

  @override
  String loginSignInAs(String username) {
    return 'Войти как $username?';
  }

  @override
  String get loginSignInToServer => 'Войти на этот сервер?';

  @override
  String loginSignedInAs(String username) {
    return 'Вы вошли как $username.';
  }

  @override
  String get adminCreateSetupFile => 'Поделиться входом';

  @override
  String adminSetupFileDescription(String username) {
    return 'Создает приватную ссылку для $username, которая работает только в приложении Absorb.';
  }

  @override
  String get adminSetupFileServerUrl =>
      'URL сервера, который будет использовать новый пользователь';

  @override
  String get adminSetupFileNoteWithHeaders =>
      'Выделенный ключ API и пользовательские заголовки будут включены, чтобы они могли получить доступ к серверу. Считайте ссылку, как пароль.';

  @override
  String get adminSetupFileNote =>
      'Выделенный ключ API будет включен. Считать ссылку, как пароль.';

  @override
  String get adminSetupFileCreate => 'Создать ссылку';

  @override
  String get adminSetupFileSaveTitle => 'Сохранить конфигурационный файл';

  @override
  String get adminSetupFileKeyError =>
      'Не удалось создать ключ API для этого пользователя';

  @override
  String adminSetupFileSaved(String username) {
    return 'Файл настройки для $username сохранен';
  }

  @override
  String adminSetupFileFailed(String error) {
    return 'Не удалось войти: $error';
  }

  @override
  String get setupLinkShareTitle => 'Поделиться входом';

  @override
  String setupLinkShareDescription(String username) {
    return 'Отправьте эту приватную ссылку или отсканируйте QR-код, чтобы войти как $username.';
  }

  @override
  String setupLinkPrivateWarning(String username) {
    return 'Любой пользователь по этой ссылке может войти как $username. Считайте это как пароль.';
  }

  @override
  String get setupLinkShare => 'Поделиться ссылкой';

  @override
  String get setupLinkCopy => 'Копировать ссылку';

  @override
  String get setupLinkCopied => 'Ссылка для входа скопирована';

  @override
  String get setupLinkSaveFile => 'Сохранить файл настроек';

  @override
  String get setupLinkQrError =>
      'Эта ссылка слишком большая для QR-кода. Поделитесь ссылкой.';

  @override
  String setupLinkShareSubject(String username) {
    return 'Absorb вход для $username';
  }

  @override
  String get setupLinkConfirmTitle => 'Войти с этой ссылкой?';

  @override
  String setupLinkConfirmBody(String server, String username) {
    return 'Войдите в $server как $username? Продолжайте только если вы доверяете этой ссылке.';
  }

  @override
  String get setupLinkInvalid =>
      'Эта ссылка на вход недействительна или неполная';

  @override
  String get setupLinkSigningIn => 'Проверка ссылки для входа...';

  @override
  String get loginPlayDownloads => 'Воспроизвести загрузки';

  @override
  String signedOutDownloadsNote(String username) {
    return 'Вы вышли. Всё, что вы слушаете здесь, синхронизируется с $username , когда вы снова войдете.';
  }

  @override
  String get loginPasteLink => 'Вставить ссылку для входа';

  @override
  String get loginPasteLinkHelp =>
      'Вставьте полученную вами ссылку для входа. Считайте ее паролем.';

  @override
  String get loginFailed => 'Не удалось войти';

  @override
  String get loginSsoFailed => 'Вход по SSO не удался или был отменен';

  @override
  String get loginSsoAuthFailed =>
      'Ошибка аутентификации SSO. Пожалуйста, попробуй еще раз.';

  @override
  String get loginRestoreFromBackup => 'Импорт';

  @override
  String get loginInvalidBackupFile => 'Недопустимый файл резервной копии';

  @override
  String get loginRestoreBackupTitle => 'Восстановить бэкап?';

  @override
  String loginRestoreBackupWithAccounts(int count) {
    return 'Это восстановит все настройки и $count сохраненный(х) аккаунт(а/ов). Вы будете автоматически авторизованы.';
  }

  @override
  String get loginRestoreBackupNoAccounts =>
      'Будут восстановлены все настройки. Учетные записи не были включены в эту резервную копию.';

  @override
  String get loginRestore => 'Восстановить';

  @override
  String loginRestoredAndSignedIn(String username) {
    return 'Восстановлены настройки и авторизованы как $username';
  }

  @override
  String get loginSessionExpired =>
      'Настройки восстановлены. Сессия истекла - войдите, чтобы продолжить.';

  @override
  String get loginSettingsRestored => 'Настройки восстановлены';

  @override
  String loginRestoreFailed(String error) {
    return 'Ошибка восстановления: $error';
  }

  @override
  String get loginSavedAccounts => 'сохранённые аккаунты';

  @override
  String get libraryTitle => 'Библиотека';

  @override
  String get librarySearchBooksHint => 'Поиск книг, серий, авторов, чтецов...';

  @override
  String get librarySearchShowsHint => 'Поиск Шоу и Выпусков...';

  @override
  String get libraryTabLibrary => 'Библиотека';

  @override
  String get libraryTabSeries => 'Серии';

  @override
  String get libraryTabAuthors => 'Авторы';

  @override
  String get libraryTabNarrators => 'Чтецы';

  @override
  String get libraryNoBooks => 'Книги не найдены';

  @override
  String get libraryNoUnfinishedBooks => 'Нет не прослушанных книг';

  @override
  String get libraryNoBooksInProgress => 'Нет начатых книг';

  @override
  String get libraryNoFinishedBooks => 'Нет прослушанных книг';

  @override
  String get libraryAllBooksStarted => 'Все книги начаты';

  @override
  String get libraryNoDownloadedBooks => 'Нет скачанных книг';

  @override
  String get libraryNoSeriesFound => 'Серии не найдены';

  @override
  String get libraryNoBooksWithEbooks => 'Нет книг с eBook';

  @override
  String get libraryNoBooksMissingMetadata => 'Нет книг без этих метаданных';

  @override
  String get libraryNoItemsMatchingFilter =>
      'Нет элементов, соответствующих этому фильтру';

  @override
  String libraryNoBooksInGenre(String genre) {
    return 'Нет книг с жанром \"$genre\"';
  }

  @override
  String libraryNoBooksWithTag(String tag) {
    return 'Нет книг с тегом \"$tag\"';
  }

  @override
  String get libraryClearFilter => 'Сбросить фильтр';

  @override
  String get libraryNoAuthorsFound => 'Авторы не найдены';

  @override
  String get libraryNoNarratorsFound => 'Чтецы не найдены';

  @override
  String get libraryNoResults => 'Результаты не найдены';

  @override
  String get librarySearchBooks => 'Книги';

  @override
  String get librarySearchShows => 'Шоу';

  @override
  String get librarySearchEpisodes => 'Выпуски';

  @override
  String get librarySearchSeries => 'Серии';

  @override
  String get librarySearchAuthors => 'Авторы';

  @override
  String get librarySearchTags => 'Теги';

  @override
  String get librarySearchGenres => 'Жанры';

  @override
  String librarySeriesCount(int count) {
    return '$count серии';
  }

  @override
  String libraryAuthorsCount(int count) {
    return '$count авторы';
  }

  @override
  String libraryNarratorsCount(int count) {
    return '$count чтецы';
  }

  @override
  String libraryBooksCount(int loaded, int total) {
    return '$loaded/$total книги';
  }

  @override
  String get sort => 'Сортировка';

  @override
  String get filter => 'Фильтр';

  @override
  String get filterActive => 'Фильтр ●';

  @override
  String get name => 'Название';

  @override
  String get title => 'Название';

  @override
  String get author => 'Автор';

  @override
  String get dateAdded => 'Дата добавления';

  @override
  String get numberOfBooks => 'Количество книг';

  @override
  String get sortTotalDuration => 'Общее время';

  @override
  String get sortLastBookAdded => 'Последняя добавленная книга';

  @override
  String get sortLastBookUpdated => 'Последняя обновленная книга';

  @override
  String get publishedYear => 'Год публикации';

  @override
  String get duration => 'Длительность';

  @override
  String get random => 'Случайно';

  @override
  String get collapseSeries => 'Свернуть серии';

  @override
  String get notFinished => 'Не Прослушано';

  @override
  String get inProgress => 'В процессе';

  @override
  String get filterFinished => 'Прослушано';

  @override
  String get notStarted => 'Не начато';

  @override
  String get downloaded => 'Скачано';

  @override
  String get hasEbook => 'Имеет eBook';

  @override
  String get noEbook => 'Без eBook';

  @override
  String get hasSupplementaryEbook => 'С дополнительным eBook';

  @override
  String get noSupplementaryEbook => 'Без дополнительным eBook';

  @override
  String get noSeries => 'Без серии';

  @override
  String get publishedDecade => 'Десятилетие';

  @override
  String get tracks => 'Треки';

  @override
  String get noTracks => 'Нет треков';

  @override
  String get singleTrack => 'Один трек';

  @override
  String get multipleTracks => 'Несколько треков';

  @override
  String get abridged => 'Сокращено';

  @override
  String get issues => 'Вопросы';

  @override
  String get rssFeedOpen => 'Открытый RSS канал';

  @override
  String get explicitContent => 'Ненорм. лексика';

  @override
  String get missingMetadata => 'Отсутствуют метаданные';

  @override
  String get genre => 'Жанр';

  @override
  String get tag => 'Тег';

  @override
  String get clearFilter => 'Очистить фильтр';

  @override
  String get noGenresFound => 'Жанры не найдены';

  @override
  String get noTagsFound => 'Теги не найдены';

  @override
  String get asc => 'ВОЗР';

  @override
  String get desc => 'УБЫВ';

  @override
  String get fileSize => 'Размер файла';

  @override
  String get lastUpdated => 'Последнее обновление';

  @override
  String get fileCreated => 'Файл создан';

  @override
  String get lastModified => 'Последнее изменение';

  @override
  String get authorFirstLast => 'Автор (Имя Фамилия)';

  @override
  String get authorLastFirst => 'Автор (Фамилия, Имя)';

  @override
  String get progressSort => 'Прогресс';

  @override
  String get dateStarted => 'Дата начала';

  @override
  String get dateFinished => 'Дата завершения прослушивание';

  @override
  String get episodeCount => 'Число выпусков';

  @override
  String get sequence => 'Последовательность серии';

  @override
  String get absorbingTitle => 'Поглощение';

  @override
  String get absorbingStop => 'Стоп';

  @override
  String get absorbingManageQueue => 'Управление очередью';

  @override
  String get desktopAbsorbingQueueHint =>
      'Use Add to Absorbing on a book or episode to put it here. Items play in this order.';

  @override
  String get absorbingDone => 'Готово';

  @override
  String get absorbingNoDownloadedEpisodes => 'Нет скачанных выпусков';

  @override
  String get absorbingNoDownloadedBooks => 'Нет скачанных книг';

  @override
  String get absorbingNothingPlayingYet => 'Пока ничего не играет';

  @override
  String get absorbingNothingAbsorbingYet => 'Пока ничего не поглощается';

  @override
  String get absorbingDownloadEpisodesToListen =>
      'Скачать выпуски для прослушивания офлайн';

  @override
  String get absorbingDownloadBooksToListen =>
      'Скачать книги для прослушивания офлайн';

  @override
  String get absorbingStartEpisodeFromShows => 'Начать эпизод на вкладке «Шоу»';

  @override
  String get absorbingStartBookFromLibrary =>
      'Начать книгу на вкладке «Библиотека»';

  @override
  String get carModeTitle => 'Режим \"Авто\"';

  @override
  String get carModeNoBookLoaded => 'Нет загруженных книг';

  @override
  String get carModeBookLabel => 'Книга';

  @override
  String get carModeChapterLabel => 'Глава';

  @override
  String get carModeBookmarkDefault => 'Закладка';

  @override
  String get carModeBookmarkAdded => 'Закладка добавлена';

  @override
  String get downloadsTitle => 'Сохраненные';

  @override
  String get downloadsCancelSelection => 'Отменить загрузку';

  @override
  String get downloadsSelect => 'Выберите';

  @override
  String get downloadsNoDownloads => 'Нет загрузок';

  @override
  String get downloadsDownloading => 'Идёт загрузка';

  @override
  String get downloadsQueued => 'Очередь';

  @override
  String get downloadsCompleted => 'Завершено';

  @override
  String get downloadsEbooks => 'Ebooks';

  @override
  String get downloadsWaiting => 'Подождите...';

  @override
  String get downloadsCancel => 'Отменить';

  @override
  String get downloadsDelete => 'Удалить';

  @override
  String downloadsDeleteCount(int count) {
    return 'Удалить $count загрузку(ок)?';
  }

  @override
  String get downloadsDeleteContent => 'Загруженные файлы будут удалены.';

  @override
  String downloadsDeletedCount(int count) {
    return 'Удалено $count загрузка(ок)';
  }

  @override
  String get downloadsRemoveTitle => 'Удалить из загруженных?';

  @override
  String downloadsRemoveContent(String title) {
    return 'Удалить \"$title\" из памяти?';
  }

  @override
  String downloadsRemovedTitle(String title) {
    return '\"$title\" удалено';
  }

  @override
  String downloadFailedMissingFile(String title) {
    return 'Не удалось скачать \"$title\" - один из файлов не на сервере. Попробуйте пересканировать библиотеку.';
  }

  @override
  String downloadFailedNoSpace(String title) {
    return 'Не удалось скачать \"$title\" - Не хватает памяти';
  }

  @override
  String downloadFailedPermission(String title) {
    return '';
  }

  @override
  String downloadFailedGeneric(String title) {
    return 'Не удалось скачать \"$title\"';
  }

  @override
  String downloadsSelectedCount(int count) {
    return '$count выбрано';
  }

  @override
  String get bookmarksTitle => 'Все закладки';

  @override
  String get bookmarksTabBookmarks => 'Закладки';

  @override
  String get bookmarksTabHighlights => 'Выделение';

  @override
  String get highlightOpenInBook => 'Открыть в книге';

  @override
  String get highlightDeleteAction => 'Удалить выделение';

  @override
  String get highlightDeleted => 'Выделение удалено';

  @override
  String highlightsDeleteCount(int count) {
    return 'Удалить $count выделение(ий)?';
  }

  @override
  String highlightsDeletedCount(int count) {
    return 'Удалено $count выделение(я)';
  }

  @override
  String get quoteShareTitle => 'Поделиться цитатой';

  @override
  String get quoteShareAction => 'Поделиться';

  @override
  String get quoteShareFailed => 'Не удалось создать изображение цитаты';

  @override
  String get quoteShapePortrait => 'Вертикально';

  @override
  String get quoteShapeSquare => 'Квадрат';

  @override
  String get quoteShapeStory => 'История';

  @override
  String get quoteStyleBlur => 'Размытие';

  @override
  String get quoteStyleDim => 'Затемнение';

  @override
  String get quoteStyleNone => 'Обложка';

  @override
  String get quoteTextLight => 'Светлый текст';

  @override
  String get quoteTextDark => 'Темный текст';

  @override
  String get quoteFieldTitle => 'Заголовок';

  @override
  String get quoteFieldDetail => 'Подробности';

  @override
  String get quoteFieldDetailHint =>
      'Автор главы, страницы, который сказал это';

  @override
  String highlightsMeta(String chapter, String date) {
    return '$chapter · $date';
  }

  @override
  String get bookmarksCancelSelection => 'Отменить выбранное';

  @override
  String get bookmarksSortedByNewest => 'Сортировка по последним';

  @override
  String get bookmarksSortedByPosition => 'Сортировка по позиции';

  @override
  String get bookmarksSelect => 'Выберите закладку';

  @override
  String get bookmarksNoBookmarks => 'Закладок пока нет';

  @override
  String get bookmarksSearchHint => 'Поиск закладок';

  @override
  String get bookmarksNoMatches => 'По вашему запросу закладок не найдено';

  @override
  String batchDownloadQueued(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Скачиваются $count книги',
      one: 'Скачивается $count книга',
      many: 'Скачиваются $count книг',
      few: 'Скачиваются $count книги',
    );
    return '$_temp0';
  }

  @override
  String get batchDownloadNothingNew => 'Уже загружено';

  @override
  String bookmarksDeleteCount(int count) {
    return 'Удалить $count закладку(ок)?';
  }

  @override
  String get bookmarksDeleteContent => 'Это невозможно отменить.';

  @override
  String bookmarksDeletedCount(int count) {
    return 'Удалено $count закладка(ок)';
  }

  @override
  String get bookmarksJumpTitle => 'Перейти к закладкам?';

  @override
  String bookmarksJumpContent(String title, String position, String bookTitle) {
    return '\"$title\" на $position\nв $bookTitle';
  }

  @override
  String get bookmarksJump => 'Перейти';

  @override
  String get bookmarksNotConnected => 'Нет подключения к серверу';

  @override
  String get bookmarksCouldNotLoad => 'Не удается загрузить книгу';

  @override
  String bookmarksSelectedCount(int count) {
    return '$count выбрано';
  }

  @override
  String get statsTitle => 'Ваша Статистика';

  @override
  String get statsCouldNotLoad => 'Не удается загрузить статистику';

  @override
  String get statsTotalListeningTime => 'ОБЩЕЕ ВРЕМЯ ПРОСЛУШИВАНИЯ';

  @override
  String get statsHoursUnit => 'ч';

  @override
  String get statsMinutesUnit => 'м';

  @override
  String get statsSecondsUnit => 'с';

  @override
  String statsDaysOfAudio(String days) {
    return 'Это $days дней звучания';
  }

  @override
  String statsHoursOfAudio(String hours) {
    return 'Это $hours часов звучания';
  }

  @override
  String get statsToday => 'Сегодня';

  @override
  String get statsThisWeek => 'За эту неделю';

  @override
  String get statsThisMonth => 'За этот месяц';

  @override
  String get statsActivity => 'Действия';

  @override
  String get statsCurrentStreak => 'Текущая Серия';

  @override
  String get statsBestStreak => 'Лучшая Серия';

  @override
  String get statsFinished => 'Прослушано';

  @override
  String get statsBooksFinished => 'Книги';

  @override
  String get statsEpisodesFinished => 'Серии';

  @override
  String get statsBooksThisYear => 'Книги в этом году';

  @override
  String get statsEpisodesThisYear => 'Серии в этом году';

  @override
  String get statsRemoveFromYearTitle => 'Удалить за этот год';

  @override
  String statsRemoveFromYearWithDate(String date, String title) {
    return 'Завершенная дата $date останется на сервере. Это только удаляет \"$title\" из вашего Absorb списка книг за этот год.';
  }

  @override
  String statsRemoveFromYearNoDate(String title) {
    return 'Дата завершения останется на сервере. Это только удаляет \"$title\" из твоего Absorb списка \"Книги за этот год\".';
  }

  @override
  String get statsRemovedFromYear => 'Удалено за этот год';

  @override
  String get statsAddBackToYearTitle => 'Добавить к этому году';

  @override
  String statsAddBackToYearBody(String title) {
    return 'Добавить \"$title\" обратно в список Absorb \"Книги за этот год\"?';
  }

  @override
  String get statsAddBack => 'Добавить';

  @override
  String get statsAddedBackToYear => 'Добавлено в этот год';

  @override
  String get statsHiddenFromYear => 'Скрыто за этот год';

  @override
  String get statsNothingHidden => 'Ничего не скрыто';

  @override
  String get settingsCustomizeStats => 'Изменить статистику';

  @override
  String get statsGoalTitle => 'Цель прослушивания';

  @override
  String get statsGoalOff => 'Выкл';

  @override
  String get statsGoalDaily => 'Ежедневно';

  @override
  String get statsGoalWeekly => 'Еженедельно';

  @override
  String get statsGoalMonthly => 'Ежемесячно';

  @override
  String get statsGoalTarget => 'Цель';

  @override
  String get statsGoalEnterTitle => 'Задать цель';

  @override
  String get statsGoalEnterTimeHint => 'Минут или ч:мм';

  @override
  String statsBooksShort(int count) {
    return '$count книг';
  }

  @override
  String get statsBookChallengeTitle => 'Челлендж по чтению';

  @override
  String get statsBookChallengeDesc => 'Книги для завершения в этом году';

  @override
  String get statsDailyGoal => 'Ежедневная цель';

  @override
  String get statsWeeklyGoal => 'Еженедельная цель';

  @override
  String get statsMonthlyGoal => 'Ежемесячная цель';

  @override
  String statsGoalProgress(String done, String target) {
    return '$done / $target';
  }

  @override
  String statsBookChallengeProgress(int done, int target) {
    return '$done из $target книг';
  }

  @override
  String get statsGoalReached => 'Цель достигнута';

  @override
  String get statsChartTitle => 'График прослушивания';

  @override
  String get statsChartBar => 'Столб';

  @override
  String get statsChartLine => 'Линия';

  @override
  String get statsChartHeatmap => 'Тепловая карта';

  @override
  String get statsChartDays7 => '7 дней';

  @override
  String get statsChartDays30 => '30 дней';

  @override
  String get statsLast30Days => 'Последние 30 дней';

  @override
  String get statsThisYearTitle => 'Текущий год';

  @override
  String get statsSectionsTitle => 'Разделы';

  @override
  String get statsSectionTimePeriods => 'Временные периоды';

  @override
  String get statsHeatmapLess => 'Меньше';

  @override
  String get statsHeatmapMore => 'Больше';

  @override
  String get statsDayOfWeek => 'В среднем по дням недели';

  @override
  String get statsTimeSavedLabel => 'Сэкономлено по скорости';

  @override
  String statsTimeSavedSince(String date) {
    return 'начиная с $date';
  }

  @override
  String get statsTimeSavedReset => 'Сброс времени сохранён';

  @override
  String get statsTimeSavedResetConfirm =>
      'Сохраненное время начнет подсчет с сегодняшнего дня';

  @override
  String get statsTimeSavedResetDone => 'Время сброшено';

  @override
  String statsOnPaceFor(int count) {
    return 'В соответствии с планом, $count книг';
  }

  @override
  String get statsDaysActive => 'Дней Активности';

  @override
  String get statsDailyAverage => 'В среднем за день';

  @override
  String get statsLast7Days => 'Последние 7 дней';

  @override
  String get statsMostListened => 'Самые слушаемые';

  @override
  String get statsRecentSessions => 'Недавние сессии';

  @override
  String get appShellHomeTab => 'Главная';

  @override
  String get appShellLibraryTab => 'Библиотека';

  @override
  String get appShellAbsorbingTab => 'Поглощение';

  @override
  String get appShellStatsTab => 'Статистика';

  @override
  String get appShellSettingsTab => 'Настройки';

  @override
  String get appShellDiscoverTab => 'Подборка';

  @override
  String get appShellShowsTab => 'Шоу';

  @override
  String get appShellPodcastsTab => 'Подкасты';

  @override
  String get libraryTabEpisodes => 'Выпуски';

  @override
  String get filterAllEpisodes => 'Все';

  @override
  String get filterUnplayed => 'Непрослушано';

  @override
  String get episodeFeedEmpty => 'Нет эпизодов, соответствующих этому фильтру';

  @override
  String get podcastFilterUpNext => 'Следующий';

  @override
  String get podcastFilterNew => 'Новый ';

  @override
  String get settingsPodcastTab => 'Подкасты';

  @override
  String get settingsPodcastTabDesc =>
      'Дать одной библиотеке подкастов свою собственную вкладку в нижней панели';

  @override
  String get settingsPodcastTabLibrary => 'Библиотека вкладок подкастов';

  @override
  String get settingsStatsTab => 'Stats tab';

  @override
  String get settingsStatsTabDesc =>
      'Keep Stats in the bottom bar. Turn it off for more room on a small screen';

  @override
  String get settingsOpenStats => 'Open Stats';

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
      'Всегда включено, пока включена вкладка Подкастов';

  @override
  String get settingsEpisodeNotifs => 'Настройки уведомлений';

  @override
  String get settingsEpisodeNotifsDesc =>
      'New podcast episodes, upcoming book releases and BookOrbit notifications, checked in the background';

  @override
  String get notifIntervalOff => 'Выключить';

  @override
  String notifIntervalMinutes(int n) {
    return 'Каждые $n минут';
  }

  @override
  String get notifIntervalHour => 'Каждый час';

  @override
  String notifIntervalHours(int n) {
    return 'Каждые $n часов';
  }

  @override
  String get settingsBatteryUnrestricted =>
      'Разрешить неограниченное использование заряда батареи';

  @override
  String get settingsBatteryUnrestrictedDesc =>
      'Защищает систему от паузы в фоновом режиме на некоторых телефонах';

  @override
  String get appShellPressBackToExit => 'Нажмите «Назад» ещё раз, чтобы выйти';

  @override
  String get settingsTitle => 'Настройки';

  @override
  String get sectionAppearance => 'Внешний вид';

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
  String get languageLabel => 'Язык';

  @override
  String get languageSystemDefault => 'По умолчанию системы';

  @override
  String get languageHelpTranslateInvite =>
      'Хотите помочь перевести Absorb на ваш язык?';

  @override
  String get themeLabel => 'Тема';

  @override
  String get themeDark => 'Тёмная';

  @override
  String get themeOled => 'OLED';

  @override
  String get themeLight => 'Светлая';

  @override
  String get themeAuto => 'Авто';

  @override
  String get colorSourceLabel => 'Источник цвета';

  @override
  String get colorSourceCoverDescription =>
      'Цвета приложения следуют за обложкой текущей книги';

  @override
  String get colorSourceWallpaperDescription =>
      'Цвета приложения следуют вашим системным обоям';

  @override
  String get colorSourceWallpaper => 'Обои';

  @override
  String get colorSourceNowPlaying => 'Сейчас Играет';

  @override
  String get colorSourceDynamic => 'Динамичный';

  @override
  String get colorSourceManual => 'Вручную';

  @override
  String get colorSourceManualDescription =>
      'Использовать фиксированный цвет приложения';

  @override
  String get colorSourceCustom => 'По выбору';

  @override
  String get useColorEverywhereLabel => 'Использовать этот цвет везде';

  @override
  String get useColorEverywhereSubtitle =>
      'Также раскрасьте страницы с описанием книг и карточку игрока в выбранный вами цвет вместо обложки каждой книги';

  @override
  String get flatBackgroundLabel => 'Плоский фон';

  @override
  String get flatBackgroundSubtitle =>
      'Удалите фоновый градиент. Чистый чёрный в темном режиме для OLED экранов.';

  @override
  String get einkModeLabel => 'E-ink режим';

  @override
  String get einkModeSubtitle =>
      'Высококонтрастный черно-белый без анимации, сделанный для экранов с электронным чернилами';

  @override
  String get einkModeIntroBody =>
      'Сделано для экранов e-link. Приложение переключается на плоский черно-белый вид с высокой контрастностью, анимация выключена, проигрываемая карта теряет свой фон, а соединение с сервером остается выключенным, чтобы сэкономить заряд батареи. Воспроизведение и прогресс все еще синхронизируются нормально. Ваши настройки внешнего вида сохраняются и возвращаются, когда вы выключите это.';

  @override
  String get einkModeIntroConfirm => 'Включить';

  @override
  String get backgroundIntensityLabel => 'Интенсивность фона';

  @override
  String get startScreenLabel => 'Начальный экран';

  @override
  String get startScreenSubtitle =>
      'Какая вкладка открывается при запуске приложения';

  @override
  String get startScreenHome => 'Главная';

  @override
  String get startScreenLibrary => 'Библиотека';

  @override
  String get startScreenAbsorb => 'Absorb';

  @override
  String get startScreenStats => 'Статистика';

  @override
  String get disablePageFade => 'Отключить затухание страницы';

  @override
  String get disablePageFadeOnSubtitle => 'Страницы переключаются мгновенно';

  @override
  String get disablePageFadeOffSubtitle =>
      'Страницы затухают при смене вкладок';

  @override
  String get rectangleBookCovers => 'Прямоугольные обложки для книг';

  @override
  String get progressTextSize => 'Размер текста прогресса';

  @override
  String get rectangleBookCoversOnSubtitle =>
      'Обложки отображаются в книжной пропорции 2:3';

  @override
  String get rectangleBookCoversOffSubtitle => 'Обложки в виде квадрата';

  @override
  String get coverSize => 'Размер обложек';

  @override
  String get coverSizeSubtitle =>
      'Сколько обложек помещаются на сетке библиотеки';

  @override
  String get coverSizeSmall => 'Маленький';

  @override
  String get coverSizeMedium => 'Средний';

  @override
  String get coverSizeLarge => 'Большой';

  @override
  String get sectionAbsorbingCards => 'Карты Поглощение';

  @override
  String get fullScreenPlayer => 'Полно экранный плеер';

  @override
  String get fullScreenPlayerOnSubtitle =>
      'Вкл - книги открываются в полноэкранном режиме при воспроизведении';

  @override
  String get fullScreenPlayerOffSubtitle => 'Выкл. - играть в режиме карт';

  @override
  String get fullBookScrubber => 'Полосы прокрутки';

  @override
  String get fullBookScrubberOnSubtitle =>
      'Вкл - видимый слайдер по всей книге';

  @override
  String get fullBookScrubberOffSubtitle =>
      'Выкл. - только индикатор прогресса';

  @override
  String get cardScrubbers => 'Progress bars';

  @override
  String get cardScrubbersBoth => 'Оба';

  @override
  String get cardScrubbersChapter => 'Глава';

  @override
  String get cardScrubbersLocked => 'Заблокировано';

  @override
  String get cardScrubbersBothSubtitle =>
      'Полосы прокрутки всей книги и отдельных глав поддерживают перемотку';

  @override
  String get cardScrubbersChapterSubtitle => 'Полоса прокрутки только для глав';

  @override
  String get cardScrubbersLockedSubtitle =>
      'Отображать прогресс без полосы прокрутки';

  @override
  String get speedAdjustedTime => 'Время с поправкой на скорость';

  @override
  String get speedAdjustedTimeOnSubtitle =>
      'Вкл - все время отражает скорость воспроизведения';

  @override
  String get speedAdjustedTimeOffSubtitle =>
      'Выкл - показывать исходную длительность аудио';

  @override
  String get buttonLayout => 'Раскладка кнопок';

  @override
  String get buttonLayoutSubtitle =>
      'Как распределяются кнопки действий на карте';

  @override
  String get whenAbsorbed => 'При поглощении';

  @override
  String get whenAbsorbedInfoTitle => 'При поглощении';

  @override
  String get whenAbsorbedInfoContent =>
      'Управляет что случается с Картой Поглощение когда книга или выпуск прослушан.\n\nПрослушанные карты автоматически удаляются с экрана Поглощение.';

  @override
  String get whenAbsorbedSubtitle =>
      'Что происходит с поглощающей картой после завершения книги или эпизода';

  @override
  String get whenAbsorbedShowOverlay => 'Показать оверлей';

  @override
  String get whenAbsorbedAutoRelease => 'Авторелиз';

  @override
  String get mergeLibraries => 'Единая страница Поглощения';

  @override
  String get mergeLibrariesInfoTitle => 'Главная Поглощающая Страница';

  @override
  String get mergeLibrariesInfoContent =>
      'Если включено, в одном окне отображаются все ваши текущие книги и подкасты из каждой библиотеки. Когда отключено, отображаются только элементы из выбранной вами библиотеки.';

  @override
  String get mergeLibrariesOnSubtitle =>
      'Показывать элементы из всех библиотек';

  @override
  String get mergeLibrariesOffSubtitle =>
      'Показывать элементы из текущей библиотеки';

  @override
  String get queueMode => 'Режим очереди';

  @override
  String get queueModeInfoTitle => 'Режим Очереди';

  @override
  String get queueModeInfoOff => 'Выкл';

  @override
  String get queueModeInfoOffDesc =>
      'Плеер остановится после текущей книги или серии.';

  @override
  String get queueModeInfoManual => 'Очередь Вручную';

  @override
  String get queueModeInfoManualDesc =>
      'Ваши поглощающие карты действуют в качестве плейлиста. По завершении одной следующая незавершённая карта запуститься автоматически. Добавьте элементы нажав на кнопку «Добавить в абсорбцию» на книге или серии и измените порядок с экрана поглощения.';

  @override
  String get queueModeOff => 'Выкл';

  @override
  String get queueModeManual => 'Вручную';

  @override
  String get queueModeAuto => 'Авто';

  @override
  String get queueModePlaylist => 'Плейлист';

  @override
  String get queueModeCollection => 'Коллекция';

  @override
  String get queueModeInfoPlaylist => 'Плейлист очереди';

  @override
  String get queueModeInfoPlaylistDesc =>
      'Воспроизведение элементов плейлиста, кроме прослушанных книг или серий. Остановка в конце списка.';

  @override
  String get queuePlaylistPickerTitle => 'Выберите плейлист';

  @override
  String get queuePlaylistNone => 'Не выбран плейлист';

  @override
  String queuePlaylistActiveLabel(String name) {
    return 'Плейлист: $name';
  }

  @override
  String get queueModePlaylistHint =>
      'Запустите плейлист очереди, открыв плейлист на главной странице.';

  @override
  String get exit => 'Выход';

  @override
  String upNext(String label) {
    return 'Далее: $label';
  }

  @override
  String get nothingUpNext => 'Далее ничего нет';

  @override
  String get showUpNextLabel => 'Показывать следующую на странице поглощения';

  @override
  String get openSeries => 'Открыть серию';

  @override
  String get openPlaylist => 'Открыть плейлист';

  @override
  String get openCollection => 'Открыть коллекцию';

  @override
  String get playlistPlayAction => 'Играть плейлист';

  @override
  String get playlistAllFinished => 'Все завершено';

  @override
  String get queueModeBooks => 'Книги';

  @override
  String get queueModePodcasts => 'Подкасты';

  @override
  String get autoDownloadQueue => 'Автозагрузка очереди';

  @override
  String get autoDownloadThisSeriesLabel => 'Автозагрузка этой серии';

  @override
  String get autoDownloadThisShowLabel => 'Автозагрузка этого подкаста';

  @override
  String get autoDownloadThisPlaylistLabel => 'Автозагрузка этого плейлиста';

  @override
  String get autoDownloadThisCollectionLabel => 'Автозагрузка этой коллекции';

  @override
  String autoDownloadQueueOnSubtitle(int count) {
    return 'Оставить следующие $count загруженных элементов';
  }

  @override
  String get autoDownloadQueueOffSubtitle => 'Выкл. - загрузки вручную';

  @override
  String get sectionPlayback => 'Воспроизведение';

  @override
  String get sectionMediaControls => 'Управление медиа';

  @override
  String get defaultSpeed => 'Стандартная скорость';

  @override
  String get defaultSpeedSubtitle =>
      'Новые книги начинаются с этой скоростью - каждая книга сохранит эту настройку';

  @override
  String get skipBack => 'Перейти назад';

  @override
  String get skipForward => 'Перейти вперед';

  @override
  String get iosLockScreenSkipHint =>
      'Блокирующий экран рисует только числа iOS иконок для (5, 10, 15, 30, 45, 60, 75, 90). Остальные суммы показывают + на кнопке, но при этом все равно пропускать по вашим настройкам.';

  @override
  String get longSkipButtons => 'Длинные кнопки пропуска';

  @override
  String get longSkipButtonsOnSubtitle =>
      'Вкл - проигрыватель показывает секунды, большую пару пропуска ';

  @override
  String get longSkipButtonsOffSubtitle => 'Выкл - обычные кнопки пропуска';

  @override
  String get longSkipBack => 'Длинный пропуск назад';

  @override
  String get longSkipForward => 'Длинный пропуск вперёд';

  @override
  String get coverShapeDefault => 'Стандартная';

  @override
  String get coverShapeSquare => 'Квадратная';

  @override
  String get coverShapeRectangle => 'Прямоугольная';

  @override
  String get coverShapeLabel => 'Форма обложек';

  @override
  String get showSubtitles => 'Показывать субтитры';

  @override
  String get showSubtitlesOnSubtitle =>
      'Субтитры показываются под названиями книг в библиотеке и на главной';

  @override
  String get showSubtitlesOffSubtitle =>
      'Выкл. - субтитры только в таблице с подробностями книги';

  @override
  String get subtitleVisibilityLabel => 'Субтитры';

  @override
  String get subtitleVisibilityDefault => 'По умолчанию';

  @override
  String get subtitleVisibilityShow => 'Показать';

  @override
  String get subtitleVisibilityHide => 'Скрыть';

  @override
  String currentLibrarySettingsTitle(String name) {
    return 'Текущая библиотека: $name';
  }

  @override
  String get currentLibrarySkipOverride => 'Пользовательские суммы пропуска';

  @override
  String get currentLibrarySkipOverrideOnSubtitle =>
      'Вкл - эта библиотека использует свои собственные пропускаемые суммы';

  @override
  String get currentLibrarySkipOverrideOffSubtitle =>
      'Выкл. - эта библиотека использует общие пропущенные суммы';

  @override
  String get currentLibrarySpeedOverride => 'Custom default speed';

  @override
  String get currentLibrarySpeedOverrideOnSubtitle =>
      'On - new items in this library start at their own speed';

  @override
  String get currentLibrarySpeedOverrideOffSubtitle =>
      'Off - new items in this library start at the global default speed';

  @override
  String get currentLibrarySpeed => 'Default speed';

  @override
  String get currentLibrarySkipBack => 'Перейти назад';

  @override
  String get currentLibrarySkipForward => 'Перейти вперед';

  @override
  String get chapterProgressInNotification =>
      'Прогресс главы в уведомлении и в Android Auto';

  @override
  String get chapterProgressOnSubtitle =>
      'Вкл. - уведомление и Android Auto покажут прогресс главы';

  @override
  String get chapterProgressOffSubtitle =>
      'Выкл. - они покажут прогресс всей книги';

  @override
  String get chapterProgressInNotificationIos =>
      'Прогресс главы на экране блокировки и CarPlay';

  @override
  String get chapterProgressOnSubtitleIos =>
      'Вкл. - блокировка экрана и CarPlay покажут прогресс главы';

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
  String get nowPlayingText => 'Сейчас проигрывается текст';

  @override
  String get nowPlayingTextSubtitle =>
      'Выберите какие элементы управления мультимедиа отображаются в каждой строке';

  @override
  String get nowPlayingTopLine => 'Верхняя линия';

  @override
  String get nowPlayingSecondLine => 'Вторая линия';

  @override
  String get nowPlayingNotShown => 'Не отображать';

  @override
  String get nowPlayingTopLineRequired =>
      'Верхняя строка должна иметь хотя бы одну позицию';

  @override
  String get nowPlayingPieceChapter => 'Глава';

  @override
  String get nowPlayingPieceTitle => 'Название книги';

  @override
  String get nowPlayingPieceNarrator => 'Чтец';

  @override
  String get nowPlayingPieceSeries => 'Серии';

  @override
  String get nowPlayingPiecePercent => 'Процент книги';

  @override
  String get nowPlayingPieceChapterNumber => 'Номер главы';

  @override
  String get nowPlayingPieceTimeLeft => 'Оставшееся время';

  @override
  String nowPlayingChapterNumber(int number, int total) {
    return 'Гл. $number/$total';
  }

  @override
  String nowPlayingTimeLeft(String time) {
    return 'Осталось $time';
  }

  @override
  String get bookDockBadgePending => 'Ожидание';

  @override
  String get bookDockBadgeExtracting => 'Чтение файла';

  @override
  String get bookDockBadgeFetching => 'Искать';

  @override
  String get bookDockBadgeError => 'Ошибка';

  @override
  String get bookDockNeedsReview => 'Требуется проверка';

  @override
  String get bookDockNoMatch => 'Нет совпадений';

  @override
  String get bookDockApplied => 'Применено';

  @override
  String get bookDockNotApplied => 'Обнаруженные детали не используются';

  @override
  String get bookDockNoDestination => 'Назначение не установлено';

  @override
  String get bookDockNoAuthor => 'Пока нет автора';

  @override
  String get bookDockLookUpAgain => 'Искать снова';

  @override
  String get bookDockLookingUp => 'Поиск деталей еще раз';

  @override
  String get bookDockLookUpFailed => 'Не удалось найти детали';

  @override
  String get bookDockProposedChanges => 'Предлагаемые изменения';

  @override
  String get bookDockNoChanges => 'Детали не найдены онлайн';

  @override
  String get bookDockStillReading => 'Сервер все еще читает этот файл';

  @override
  String get bookDockRoleBook => 'Книга';

  @override
  String get bookDockRoleCover => 'Обложка';

  @override
  String get bookDockRoleMetadata => 'Метаданные';

  @override
  String get bookDockRoleExtra => 'Дополнительно';

  @override
  String get bookDockFieldTitle => 'Заголовок';

  @override
  String get bookDockFieldSubtitle => 'Субтитры';

  @override
  String get bookDockFieldAuthors => 'Авторы';

  @override
  String get bookDockFieldSeries => 'Серии';

  @override
  String get bookDockFieldPublisher => 'Издатель';

  @override
  String get bookDockFieldYear => 'Год';

  @override
  String get bookDockFieldLanguage => 'Язык';

  @override
  String get bookDockFieldIsbn => 'ISBN';

  @override
  String bookDockMatch(int percent) {
    return '$percent% совпадения';
  }

  @override
  String bookDockFileCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files',
      one: '1 file',
    );
    return '$_temp0';
  }

  @override
  String bookDockGoesTo(String library) {
    return 'Перейти к $library';
  }

  @override
  String bookDockChangedFields(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fields',
      one: '1 field',
    );
    return '$_temp0';
  }

  @override
  String bookDockFilesInEntry(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files in this entry',
      one: 'File in this entry',
    );
    return '$_temp0';
  }

  @override
  String bookDockAdded(String date) {
    return 'Добавлено $date';
  }

  @override
  String get bookDockAddToLibrary => 'Добавить в библиотеку';

  @override
  String get bookDockUseFound => 'Использовать найденные подробности';

  @override
  String get bookDockRemoveTitle => 'Remove from Book Dock?';

  @override
  String get bookDockRemoveFailed => 'Невозможно удалить этот файл';

  @override
  String get bookDockPickLibrary => 'Добавить в какую библиотеку?';

  @override
  String get bookDockNoLibraries =>
      'Ваш аккаунт не может добавить книги в библиотеку';

  @override
  String get bookDockFileFailed => 'Невозможно добавить этот файл в библиотеку';

  @override
  String get bookDockDuplicateBody =>
      'Файл с таким именем уже есть в этой библиотеке. Удалить его из Book Dock?';

  @override
  String get bookDockDetailsUpdated => 'Подробности обновлены';

  @override
  String get bookDockUseFoundFailed =>
      'Не найдено подробностей для использования';

  @override
  String bookDockRemoveBody(String title) {
    return 'Это удалит $title с сервера.';
  }

  @override
  String bookDockRemoved(String title) {
    return '$title удален из Book Dock';
  }

  @override
  String bookDockFiled(String title, String library) {
    return 'Добавлено $title в $library';
  }

  @override
  String bookDockFileFailedReason(String reason) {
    return 'Не удалось добавить этот файл: $reason';
  }

  @override
  String bookDockDuplicateTitle(String library) {
    return 'Уже в $library';
  }

  @override
  String get bomatchSearchAll => 'Поиск по всем источникам';

  @override
  String get bomatchSearching => 'Поиск...';

  @override
  String get bomatchSearchFailed =>
      'Не удалось найти совпадения. Проверьте подключение и повторите попытку.';

  @override
  String get bomatchNoResults => 'Совпадений не найдено';

  @override
  String get bomatchStrong => 'Точные совпадения';

  @override
  String get bomatchPossible => 'Возможные совпадения';

  @override
  String get bomatchSourceTimeout => 'истекло время ожидания';

  @override
  String get bomatchSourceBusy => 'занято';

  @override
  String get bomatchSourceFailed => 'ошибка';

  @override
  String get bomatchLinked => 'Связан';

  @override
  String get bomatchSameIsbn => 'Такой же ISBN';

  @override
  String get bomatchFewDetails => 'Больше подробностей';

  @override
  String get bomatchBack => 'Все результаты';

  @override
  String get bomatchFillEmpty => 'Заполнить пустым';

  @override
  String get bomatchTakeAll => 'Взять всё';

  @override
  String get bomatchOnlyDifferences => 'Только различия';

  @override
  String get bomatchNow => 'Сейчас';

  @override
  String get bomatchEmpty => 'Пустой';

  @override
  String get bomatchKindNew => 'Новый ';

  @override
  String get bomatchKindChange => 'Изменить';

  @override
  String get bomatchKindSmall => 'Небольшое изменение';

  @override
  String get bomatchKindSame => 'То же';

  @override
  String get bomatchKindNone => 'Не в результате';

  @override
  String get bomatchKeep => 'Оставить';

  @override
  String get bomatchUse => 'Использовать';

  @override
  String get bomatchMerge => 'Объединение';

  @override
  String get bomatchReplace => 'Заменить';

  @override
  String get bomatchUseThis => 'Использовать это';

  @override
  String get bomatchChosen => 'Выбран';

  @override
  String bomatchOther(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count other books',
      one: '1 other book',
    );
    return '$_temp0';
  }

  @override
  String bomatchChanged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count changes',
      one: '1 change',
    );
    return '$_temp0';
  }

  @override
  String bomatchNew(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count new',
      one: '1 new',
    );
    return '$_temp0';
  }

  @override
  String bomatchApply(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Apply $count changes',
      one: 'Apply 1 change',
      zero: 'Apply',
    );
    return '$_temp0';
  }

  @override
  String bomatchOtherSources(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count other sources',
      one: '1 other source',
    );
    return '$_temp0';
  }

  @override
  String bomatchFrom(String source) {
    return 'Из $source';
  }

  @override
  String get breqTitle => 'Запросы на книги';

  @override
  String get breqTabRequest => 'Запросить книгу';

  @override
  String get breqTabMine => 'Mои запросы';

  @override
  String get breqTabAll => 'Все запросы';

  @override
  String get breqNoAccess =>
      'Ваша учетная запись не может запрашивать книги на этом сервере.';

  @override
  String get breqTitleHint => 'Заголовок книги';

  @override
  String get breqAuthorHint => 'Автор';

  @override
  String get breqKindAudiobook => 'Аудиокнига';

  @override
  String get breqKindEbook => 'E-book';

  @override
  String get breqKindComic => 'Комикс';

  @override
  String get breqSearch => 'Поиск';

  @override
  String get breqSearching => 'Поиск...';

  @override
  String get breqSearchFailed =>
      'Не удалось найти. Проверьте подключение и повторите попытку.';

  @override
  String get breqSearchPrompt =>
      'Найдите книгу, которой еще нет в библиотеке, и запросите ее.';

  @override
  String get breqNoResults => 'Подходящих книг не найдено';

  @override
  String get breqInLibrary => 'В вашей библиотеке';

  @override
  String get breqYouAsked => 'Вы запрашивали это';

  @override
  String get breqSomeoneAsked => 'Уже запрошен кем-то другим';

  @override
  String get breqView => 'Просмотр';

  @override
  String get breqRequest => 'Запрос';

  @override
  String get breqRequested => 'Запрошено';

  @override
  String get breqAddMeToo => 'Добавить меня тоже';

  @override
  String get breqLibrary => 'Библиотека';

  @override
  String get breqLibraryApprover => 'По решению утверждающего';

  @override
  String get breqLibraryChoose => 'Выбрать библиотеку';

  @override
  String get breqNote => 'Примечание для утверждающего';

  @override
  String get breqNoteHint => 'Всё, что стоит знать об этом запросе';

  @override
  String get breqAutoApproved => 'Ваши запросы одобрены прямо сейчас.';

  @override
  String get breqSubmitted => 'Запрос отправлен';

  @override
  String get breqJoined => 'Вы добавлены в существующий запрос';

  @override
  String get breqFailed => 'Не удалось отправить запрос';

  @override
  String get breqStatusPending => 'В обработке';

  @override
  String get breqStatusApproved => 'Одобрено';

  @override
  String get breqStatusRejected => 'Отклонено';

  @override
  String get breqStatusCancelled => 'Отменено';

  @override
  String get breqStatusSearching => 'Поиск';

  @override
  String get breqStatusGrabbed => 'Найден релиз';

  @override
  String get breqStatusDownloading => 'Скачивание';

  @override
  String get breqStatusImporting => 'Импортирование';

  @override
  String get breqStatusNeedsReview => 'Требуется ревью';

  @override
  String get breqStatusAvailable => 'Доступен';

  @override
  String get breqStatusFailed => 'Ошибка';

  @override
  String get breqWaitingApproval => 'В ожидании одобрения';

  @override
  String get breqWaitingRelease => 'Ожидание выбора релиза';

  @override
  String get breqLookingForRelease => 'Поиск релиза';

  @override
  String get breqStartingDownload => 'Запуск скачивания';

  @override
  String get breqAddingToLibrary => 'Добавление в библиотеку';

  @override
  String get breqWaitingCheck => 'Ожидание проверки вручную';

  @override
  String get breqReady => 'Готово в вашей библиотеке';

  @override
  String get breqSomethingWrong => 'Что-то пошло не так';

  @override
  String get breqShowHidden => 'Показывать скрытые';

  @override
  String get breqHidden => 'Скрыто';

  @override
  String get breqMineEmpty => 'Вы еще не запросили ни одной книги.';

  @override
  String get breqAllEmpty => 'Пока что нет запросов.';

  @override
  String get breqLoadFailed => 'Не удалось загрузить запросы.';

  @override
  String get breqLoadMore => 'Загрузить ещё';

  @override
  String get breqApprove => 'Одобрить';

  @override
  String get breqReject => 'Отклонить';

  @override
  String get breqCancel => 'Отменить запрос';

  @override
  String get breqHide => 'Скрыть из списка';

  @override
  String get breqUnhide => 'Показать в списке';

  @override
  String get breqLeave => 'Запрос на выход';

  @override
  String get breqDelete => 'Удалить запрос';

  @override
  String get breqOpenBook => 'Открыть книгу';

  @override
  String get breqCancelConfirm =>
      'Отменить этот запрос? Загрузка в процессе работы также прекращается.';

  @override
  String get breqDeleteConfirm =>
      'Удалить данный запрос? Это действие не может быть отменено.';

  @override
  String get breqRejectTitle => 'Отклонить запрос';

  @override
  String get breqRejectReason => 'Причина (опционально)';

  @override
  String get breqApproveTitle => 'Одобрить запрос';

  @override
  String get breqApproveLibraryNeeded => 'Выберите библиотеку для этой книги.';

  @override
  String get breqApprovedToast => 'Запрос одобрен';

  @override
  String get breqRejectedToast => 'Запрос отклонен';

  @override
  String get breqCancelledToast => 'Запрос отменён';

  @override
  String get breqHiddenToast => 'Скрыть из списка';

  @override
  String get breqRestoredToast => 'Назад в список';

  @override
  String get breqDeletedToast => 'Запрос отклонен';

  @override
  String get breqLeftToast => 'Вы покинули этот запрос';

  @override
  String get breqActionFailed => 'Не удалось обновить запрос';

  @override
  String get breqFactRequestedBy => 'По запросу';

  @override
  String get breqFactRequestedOn => 'Запрошено';

  @override
  String get breqFactLibrary => 'Библиотека';

  @override
  String get breqFactDecidedBy => 'Утверждено';

  @override
  String get breqFactNote => 'Заметка инициатора';

  @override
  String get breqFactDecisionNote => 'Decision note';

  @override
  String get breqFactAlsoWanted => 'Also wanted by';

  @override
  String get breqLibraryCta => 'Запросить книгу';

  @override
  String get breqSettingsSubtitle =>
      'Ask for books the library does not have yet';

  @override
  String get navHoldBookRequests => 'Book requests';

  @override
  String breqLibraryDefault(String library) {
    return 'По умолчанию ($library)';
  }

  @override
  String breqFailedReason(String reason) {
    return 'Не удалось отправить запрос: $reason';
  }

  @override
  String breqBookCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count books',
      one: '1 book',
    );
    return '$_temp0';
  }

  @override
  String breqDownloadingPercent(int percent) {
    return 'Загружено: $percent%';
  }

  @override
  String breqAddedTo(String library) {
    return 'Добавлено в \"$library';
  }

  @override
  String breqRejectedWithNote(String note) {
    return 'Отклонено: $note';
  }

  @override
  String breqFailedWithReason(String reason) {
    return 'Ошибка: $reason';
  }

  @override
  String breqRequestedBy(String name) {
    return 'Запрошено: $name';
  }

  @override
  String breqActionFailedReason(String reason) {
    return 'Не удалось обновить запрос: $reason';
  }

  @override
  String breqFooterCta(String query) {
    return 'Запрос \"$query\"';
  }

  @override
  String breqCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count requests',
      one: '1 request',
      zero: 'No requests',
    );
    return '$_temp0';
  }

  @override
  String get breqFindRelease => 'Поиск релиза';

  @override
  String get breqTryAnotherRelease => 'Попробуйте другой релиз';

  @override
  String get breqApproveAndFind => 'Одобрить и найти релиз';

  @override
  String get breqReviewButton => 'Обзор скачанных';

  @override
  String get breqStopDownload => 'Остановить загрузку';

  @override
  String get breqStopDownloadConfirm =>
      'Остановить эту загрузку? Запрос возвращается к утвержденному релизу, чтобы можно было выбрать другой.';

  @override
  String get breqDiscardImport => 'Отменить загрузку';

  @override
  String get breqDiscardConfirm =>
      'Отменить эту загрузку? Запрос помечен как не удавшийся и может быть повторен в другой версии.';

  @override
  String get breqFileAnyway => 'Добавить в библиотеку';

  @override
  String get breqFiledToast => 'Добавлено в библиотеку';

  @override
  String get breqDiscardedToast => 'Скачивание отменено';

  @override
  String get breqStoppedToast => 'Загрузка остановлена';

  @override
  String get breqGrabTitle => 'Скачать этот релиз?';

  @override
  String get breqGrab => 'Скачать';

  @override
  String get breqGrabbed => 'Скачивание началось';

  @override
  String get breqGrabFailed => 'Не удалось запустить эту загрузку';

  @override
  String get breqReleaseVipWarning =>
      'Этот трекер позволяет скачивать только VIP-аккаунтам.';

  @override
  String get breqReleaseNoBookFile =>
      'В этом выпуске нет книжного файла BookOrbit который можно добавить в библиотеку.';

  @override
  String get breqReleaseCheckFailed =>
      'Не удалось проверить, что находится в этом выпуске. Попробуйте еще раз или выберите другой.';

  @override
  String get breqCheckingRelease => 'Проверка файлов...';

  @override
  String get breqSearchAgain => 'Повторный поиск';

  @override
  String get breqSearchTerms => 'Условия поиска';

  @override
  String get breqIsbnHint => 'Оставьте пустым для поиска по названию и автору';

  @override
  String get breqSearchingIndexers =>
      'Поиск по индексаторам. Это может занять до минуты.';

  @override
  String get breqReleasesFailed => 'Не удалось найти релизы.';

  @override
  String get breqNoSourcesSetUp => 'No search sources are set up in BookOrbit.';

  @override
  String get breqNoSourcesOn =>
      'Every search source is switched off in BookOrbit.';

  @override
  String get breqNoSourceCarries =>
      'Ни один из ваших поисковых источников не содержит такой книги.';

  @override
  String get breqNoReleases =>
      'Релизы не найдены. Попробуйте другие условия поиска.';

  @override
  String get breqFromCache => 'из недавнего поиска';

  @override
  String get breqIndexerUnauthorized => 'ошибка входа';

  @override
  String get breqIndexerThrottled => 'занято';

  @override
  String get breqIndexerTimeout => 'время ожидания истекло';

  @override
  String get breqIndexerUnreachable => 'недоступно';

  @override
  String get breqIndexerNoMedium => 'does not carry this';

  @override
  String get breqIndexerError => 'ошибка';

  @override
  String get breqSortBest => 'Лучшее совпадение';

  @override
  String get breqSortSeeders => 'Сидеры';

  @override
  String get breqSortSize => 'Размер';

  @override
  String get breqSortNewest => 'Сначала новые';

  @override
  String get breqFreeleech => 'Freeleech';

  @override
  String get breqVipOnly => 'Только VIP';

  @override
  String get breqAlreadyGrabbed => 'Загружено до';

  @override
  String get breqReasonIsbn => 'ISBN';

  @override
  String get breqReasonTitle => 'Заголовок';

  @override
  String get breqReasonAuthor => 'Автор';

  @override
  String get breqReasonUnknownFormat => 'Неизвестный формат';

  @override
  String get breqReasonExpectedSize => 'Размер';

  @override
  String get breqReasonSuspiciousSize => 'Нестандартный размер';

  @override
  String get breqReasonFreeleech => 'Freeleech';

  @override
  String get breqReasonSeveralBooks => 'Ряд книг';

  @override
  String get breqReviewTitle => 'Загрузка ожидает проверки';

  @override
  String get breqReviewFailed => 'Не удалось загрузить подробности.';

  @override
  String get breqReviewDockGone =>
      'Загруженные файлы больше не отображаются в Book Dock.';

  @override
  String get breqReviewNoLibrary =>
      'Этот запрос не содержит библиотеки для добавления книги.';

  @override
  String breqGrabFailedReason(String reason) {
    return 'Не удалось запустить эту загрузку: $reason';
  }

  @override
  String breqReleaseCheckFailedReason(String reason) {
    return 'Не удалось проверить, что находится в этом выпуске: $reason';
  }

  @override
  String breqReleasesFailedReason(String reason) {
    return 'Не удалось найти релизы: $reason';
  }

  @override
  String breqReviewFailedReason(String reason) {
    return 'Не удалось загрузить данные загрузки: $reason';
  }

  @override
  String breqReleaseCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count releases',
      one: '1 release',
      zero: 'No releases',
    );
    return '$_temp0';
  }

  @override
  String breqFileCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files',
      one: '1 file',
    );
    return '$_temp0';
  }

  @override
  String breqReviewFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files',
      one: '1 file',
    );
    return '$_temp0';
  }

  @override
  String breqSeeders(int seeders, int leechers) {
    return '$seeders seeders, $leechers leechers';
  }

  @override
  String breqScore(int score) {
    return 'Оценка $score';
  }

  @override
  String breqReasonPreferredFormat(String format) {
    return 'Предпочитаемый $format';
  }

  @override
  String breqReasonFormat(String format) {
    return '$format';
  }

  @override
  String breqReasonSeeders(String count) {
    return '$count сидеров';
  }

  @override
  String breqReviewScore(int score, int threshold) {
    return 'Match score $score. Downloads scoring $threshold or more are added on their own.';
  }

  @override
  String breqReviewRequested(String value) {
    return 'Запрошено: $value';
  }

  @override
  String breqReviewImported(String value) {
    return 'Загружено: $value';
  }

  @override
  String get breqKindBoth => 'Оба';

  @override
  String get breqEbookLibrary => 'Библиотека e-book';

  @override
  String get breqAudiobookLibrary => 'Библиотека аудиокниг';

  @override
  String get breqRequestBoth => 'Запросить оба';

  @override
  String get breqAddMeToBoth => 'Добавить меня в оба';

  @override
  String get breqRequestEbook => 'Запрос e-book';

  @override
  String get breqRequestAudiobook => 'Запросить аудиокнигу';

  @override
  String get breqAddMeEbook => 'Добавить меня в запрос на e-book';

  @override
  String get breqAddMeAudiobook => 'Добавить меня в запрос на аудиокнигу';

  @override
  String get breqPairSubmitted => 'Запрос e-book и аудиокниги';

  @override
  String get breqPairOneJoined =>
      'Запрошено оба. Один из них уже на пути, поэтому вы были добавлены к этому запросу';

  @override
  String get breqJoinedBoth => 'Вы добавлены к обоим запросам';

  @override
  String get breqJoinsOwned =>
      'Запрошено. Оно присоединится к копии уже в вашей библиотеке';

  @override
  String get speedBookmarkInControls =>
      'Скорость и закладки в панели управления медиа';

  @override
  String get speedBookmarkOnSubtitle =>
      'Вкл. - уведомление покажет скорость и закладку; в Android Auto переключатели глав';

  @override
  String get speedBookmarkOffSubtitle =>
      'Выкл. - в уведомлении переключатели глав; в Android Auto скорость и закладка';

  @override
  String get lockSeekBar => 'Заблокировать ползунок на панели';

  @override
  String get lockSeekBarOnSubtitle =>
      'Вкл. - уведомление покажет прогресс, на экране блокировки и Android Auto, но ползунок переместить невозможно';

  @override
  String get lockSeekBarOffSubtitle =>
      'Выкл. - ползунок прогресса перемещается в уведомлении, на экране блокировки и Android Auto';

  @override
  String get autoRewindOnResume => 'Автоперемотка после возобновления';

  @override
  String autoRewindOnSubtitle(String min, String max) {
    return 'Вкл - $minс до $maxв зависимости от длины паузы';
  }

  @override
  String get autoRewindOffSubtitle => 'Выкл';

  @override
  String get rewindRange => 'Диапазон перемотки';

  @override
  String get rewindAfterPausedFor => 'Перемотка после паузы на';

  @override
  String get rewindAnyPause => 'Любая пауза';

  @override
  String get rewindAlwaysLabel => 'Всегда';

  @override
  String get rewindAlwaysDescription =>
      'Rewinds every time you resume, even after quick interruptions';

  @override
  String rewindAfterDescription(String seconds) {
    return 'Only rewinds if paused for $seconds+ seconds';
  }

  @override
  String get chapterBarrier => 'Chapter barrier';

  @override
  String get chapterBarrierSubtitle =>
      'Don\'t auto-rewind past the start of the current chapter';

  @override
  String get rewindInstant => 'Немедленно';

  @override
  String rewindPause(String duration) {
    return 'Пауза $duration';
  }

  @override
  String get rewindNoRewind => 'без перемотки';

  @override
  String rewindSeconds(String seconds) {
    return '${seconds}s перемотки';
  }

  @override
  String get sectionSleepTimer => 'Таймер сна';

  @override
  String get sleep => 'Спящий режим';

  @override
  String get sleepTimer => 'Таймер сна';

  @override
  String get shakeDuringSleepTimer => 'Встряхнуть во время таймера сна';

  @override
  String get shakeOff => 'Выключить';

  @override
  String get shakeAddTime => 'Добавить время';

  @override
  String get shakeReset => 'Сброс';

  @override
  String get shakeAdds => 'Добавляет встряхивание';

  @override
  String get sleepAddAmount => 'Добавить время';

  @override
  String shakeAddsValue(int minutes) {
    return '$minutes мин';
  }

  @override
  String get shakeSensitivity => 'Чувствительность встряхивания';

  @override
  String get shakeSensitivityVeryLow => 'Очень низкая';

  @override
  String get shakeSensitivityLow => 'Низкая';

  @override
  String get shakeSensitivityMedium => 'Средняя';

  @override
  String get shakeSensitivityHigh => 'Высокая';

  @override
  String get shakeSensitivityVeryHigh => 'Очень высокая';

  @override
  String get buttonDuringSleepTimer =>
      'Кнопка наушников во время завершения работы';

  @override
  String get buttonDuringSleepTimerHint =>
      'В заключительных моментах завершения работы одно нажатие сбрасывает таймер вместо паузы. Двойное нажатие по-прежнему пропускает.';

  @override
  String get resetTimerOnPause => 'Сброс таймера при паузе';

  @override
  String get resetTimerOnPauseOnSubtitle =>
      'Таймер перезапустится с полной продолжительностью при возобновлении';

  @override
  String get resetTimerOnPauseOffSubtitle =>
      'Таймер продолжится с предыдущего места';

  @override
  String get fadeVolumeBeforeSleep => 'Затухание громкости перед сном';

  @override
  String get fadeVolumeOnSubtitle =>
      'Постепенно снижать громкость в течение последних 30 секунд';

  @override
  String get fadeVolumeOffSubtitle =>
      'Воспроизведение прекращается сразу после окончания таймера';

  @override
  String get autoSleepTimer => 'Автоматический таймер сна';

  @override
  String autoSleepTimerOnSubtitle(String start, String end, int duration) {
    return '$start – $end · $duration';
  }

  @override
  String get autoSleepTimerOffSubtitle =>
      'Автоматически запускать таймер сна в заданном временном интервале';

  @override
  String get windowStart => 'Начало окна';

  @override
  String get windowEnd => 'Конец окна';

  @override
  String get timerDuration => 'Продолжительность таймера';

  @override
  String get timer => 'Таймер';

  @override
  String get endOfChapter => 'Конец главы';

  @override
  String startMinTimer(int minutes) {
    return 'Запустить таймер $minutes минут';
  }

  @override
  String sleepAfterChapters(int count, String label) {
    return 'Сон после $count $label';
  }

  @override
  String get addMoreTime => 'Добавить время';

  @override
  String get cancelTimer => 'Сбросить таймер';

  @override
  String chaptersLeftCount(int count) {
    return '$count Гл. осталось';
  }

  @override
  String get sectionDownloadsAndStorage => 'Загрузки и хранилище';

  @override
  String get downloadOverWifiOnly => 'Сеть для скачивания';

  @override
  String get downloadOverWifiOnSubtitle => 'Только Wi-Fi';

  @override
  String get downloadOverWifiOffSubtitle => 'Любая связь';

  @override
  String get autoDownloadOnWifi => 'Автозагрузка начатых книг';

  @override
  String get autoDownloadOnWifiInfoTitle => 'Автозагрузка начатых книг';

  @override
  String get autoDownloadOnWifiInfoContent =>
      'Когда вы начинаете стримить книгу, полная книга скачивается в фоновом режиме, так что вы будете иметь к ней доступ автономном режиме без ручной загрузки. Эти загрузки следуют вашим настройкам сети загрузок, так что установите в \"Любые подключения\", если вы хотите, чтобы они запускались на мобильной сети.';

  @override
  String get autoDownloadOnWifiOnSubtitle =>
      'Загрузка потоковых книг в фоне автоматически';

  @override
  String get autoDownloadOnWifiOffSubtitle => 'Выключить';

  @override
  String get concurrentDownloads => 'Одновременные загрузки';

  @override
  String get autoDownload => 'Авто-скачивание';

  @override
  String get autoDownloadSubtitle =>
      'Включить для каждой серии, подкаста, плейлиста или коллекции с их страниц деталей';

  @override
  String get autoDownloadEnabledFor => 'Включено для';

  @override
  String get autoDownloadEnabledForNone => 'Пока ничего';

  @override
  String get autoDownloadSourceUnnamed => 'Ещё не загружено';

  @override
  String get keepNext => 'Продолжить далее';

  @override
  String get keepNextInfoTitle => 'Продолжить Далее';

  @override
  String get keepNextInfoContent =>
      'Количество загружаемых элементов, включая тот, который вы сейчас слушаете. Например, «Сохранить следующие 3» означает текущую книгу плюс следующие 2 в этой серии, подкаст, плейлист или коллекция останутся загруженными. Это применимо к каждой автоматической загрузке, которую вы включаете.';

  @override
  String get deleteAbsorbedDownloads => 'Удалить поглощенные загрузки';

  @override
  String get deleteAbsorbedDownloadsInfoTitle => 'Удалить поглощенные загрузки';

  @override
  String get deleteAbsorbedDownloadsInfoContent =>
      'Когда включено, загруженные книги или эпизоды автоматически удаляются с этого устройства после их завершения в Absorb. Завершение установки в Интернете или на другом устройстве не приведет к удалению загрузки здесь.';

  @override
  String get deleteAbsorbedOnSubtitle =>
      'Скачанное удаляется после прослушивание';

  @override
  String get deleteAbsorbedOffSubtitle =>
      'Выкл. - скачанное после прослушивание не удаляется';

  @override
  String get downloadLocation => 'Папка скачивания';

  @override
  String get storageUsed => 'Использовано памяти';

  @override
  String storageUsedByDownloads(String size) {
    return '$size используется для скачивания';
  }

  @override
  String storageFreeOfTotal(String free, String total) {
    return '$free из $total';
  }

  @override
  String get manageDownloads => 'Управление загрузками';

  @override
  String get streamingCache => 'Потоковый кэш';

  @override
  String get streamingCacheInfoTitle => 'Потоковый Кэш';

  @override
  String get streamingCacheInfoContent =>
      'Кэширует потоковый аудио на диск, чтобы он скачивался снова, если вы прокручиваете назад или повторно прослушиваете разделы. Кэш автоматически управляется - старые файлы удаляются по достижении лимита размера. Это отделяется от полностью загруженных книг.';

  @override
  String get streamingCacheOff => 'Выключить';

  @override
  String get streamingCacheOffSubtitle =>
      'Выкл - звук транслируется без кэширования';

  @override
  String streamingCacheOnSubtitle(int size) {
    return '$size MB - недавно кэшированный потоковый аудио на диск';
  }

  @override
  String get clearCache => 'Очистить кэш';

  @override
  String get streamingCacheCleared => 'Кэш вещания очищен';

  @override
  String get sectionLibrary => 'Библиотека';

  @override
  String get hideEbookOnlyTitles => 'Скрыть заголовки только для eBooks';

  @override
  String get hideEbookOnlyOnSubtitle => 'Книги без аудио файлов скрыты';

  @override
  String get hideEbookOnlyOffSubtitle =>
      'Выкл - все элементы библиотеки показаны';

  @override
  String get audibleRatings => 'Audible ratings';

  @override
  String get audibleRatingsOnSubtitle =>
      'On - book details show the Audible rating';

  @override
  String get audibleRatingsOffSubtitle => 'Off - no Audible lookup or stars';

  @override
  String get homeCardsOpenDetails => 'Открыть детали из Главной';

  @override
  String get homeCardsOpenDetailsOnSubtitle =>
      'Нажатие кнопки Продолжить Слушать или Продолжить Чтение раскрывает детали';

  @override
  String get homeCardsOpenDetailsOffSubtitle =>
      'Нажатие кнопки Продолжить Слушать или Продолжить Чтение раскрывает детали';

  @override
  String get showGoodreadsButton => 'Показать кнопку \'Goodreads\'';

  @override
  String get showGoodreadsOnSubtitle =>
      'Подробная информация о книге показывает ссылку на Goodreads';

  @override
  String get showGoodreadsOffSubtitle => 'Выкл. - кнопка с Goodreads скрыта';

  @override
  String get sectionPermissions => 'Разрешения';

  @override
  String get notifications => 'Уведомления';

  @override
  String get notificationsSubtitle =>
      'Для загрузки прогресса и управления воспроизведением';

  @override
  String get notificationsAlreadyEnabled => 'Уведомления уже включены';

  @override
  String get unrestrictedBattery => 'Не ограничивать заряд батареи';

  @override
  String get unrestrictedBatterySubtitle =>
      'Запрещает Android закрывать фоновое воспроизведение';

  @override
  String get batteryAlreadyUnrestricted => 'Батарея уже не ограничена';

  @override
  String get sectionIssuesAndSupport => 'Проблемы и поддержка';

  @override
  String get bugsAndFeatureRequests => 'Ошибки и пожелания функций';

  @override
  String get bugsAndFeatureRequestsSubtitle => 'Открыть issue на GitHub';

  @override
  String get joinDiscord => 'Присоединиться в Discord';

  @override
  String get joinDiscordSubtitle => 'Сообщество, поддержка и обновления';

  @override
  String get contact => 'Контакт';

  @override
  String get contactSubtitle => 'Отправить информацию об устройстве на email';

  @override
  String get enableLogging => 'Включить логи';

  @override
  String get enableLoggingOnSubtitle =>
      'On - logs are being captured (restart to apply)';

  @override
  String get enableLoggingOffSubtitle => 'Вкл - логи не сохраняются';

  @override
  String get loggingEnabledSnackbar =>
      'Логирование включено - перезапустите приложение, чтобы начать захват';

  @override
  String get loggingDisabledSnackbar =>
      'Логирование выключено - перезапустите приложение, чтобы остановить захват';

  @override
  String get sendLogs => 'Export logs';

  @override
  String get sendLogsSubtitle => 'Download or share the .txt log file';

  @override
  String failedToShare(String error) {
    return 'Failed to export: $error';
  }

  @override
  String get clearLogs => 'Очистить логи';

  @override
  String get logsCleared => 'Логи очищены';

  @override
  String get clearLogsQuestion => 'Очистить логи?';

  @override
  String get clearLogsContent =>
      'Это нельзя отменить. Отправьте их первыми, если они вам могут понадобиться.';

  @override
  String get sectionAdvanced => 'Расширенные';

  @override
  String get localServer => 'Локальный сервер';

  @override
  String get localServerInfoTitle => 'Локальный Сервер';

  @override
  String get localServerInfoContent =>
      'Если вы используете сервер Audiobookshelf дома, здесь можно указать локальный URL-адрес или адрес в локальной сети. Absorb автоматически переключится на более быстрое локальное соединение, когда определит, что вы находитесь в домашней сети, и вернется к удаленному URL-адресу, когда вы окажетесь вне зоны доступа.';

  @override
  String get localServerOnConnectedSubtitle =>
      'Подключено через локальный сервер';

  @override
  String get localServerOnRemoteSubtitle =>
      'Включено - используется удаленный сервер';

  @override
  String get localServerOffSubtitle =>
      'Автопереключение на сервер LAN на домашнем WiFi';

  @override
  String get localServerUrlLabel => 'URL локального сервера';

  @override
  String get localServerUrlHint => 'http://192.168.1.100:13378';

  @override
  String get localServerUrlSetSnackbar =>
      'Указан URL локального сервера — подключение будет происходить автоматически при входе в домашнюю сеть';

  @override
  String get disableAudioFocus => 'Отключить аудиофокус';

  @override
  String get disableAudioFocusInfoTitle => 'Аудиофокус';

  @override
  String get disableAudioFocusInfoContent =>
      'По умолчанию Android предоставляет аудио \"фокус\" одному приложению одновременно - когда Absorb проигрывается, другие аудио (музыка, видео) будут приостанавливаться. Отключение аудиофокуса позволяет Absorb проигрывать вместе с другими приложениями. Телефонные звонки будут приостановлены независимо от этой настройки.';

  @override
  String get disableAudioFocusOnSubtitle =>
      'Вкл - воспроизводится вместе с другим аудио (по-прежнему приостанавливается во время звонков)';

  @override
  String get disableAudioFocusOffSubtitle =>
      'Выкл - остальные проигрыватели ставятся на паузу при воспроизведении Absorb';

  @override
  String get restartRequired => 'Требуется перезапуск';

  @override
  String get restartRequiredContent =>
      'Для изменения аудиофокуса требуется перезапустить приложение. Закрыть приложение сейчас?';

  @override
  String get closeApp => 'Закрыть приложение';

  @override
  String get trustAllCertificates => 'Доверять всем сертификатам';

  @override
  String get trustAllCertificatesInfoTitle => 'Самоподписанные сертификаты';

  @override
  String get mp3IndexSeeking => 'Поиск по индексу MP3';

  @override
  String get mp3IndexSeekingInfoTitle => 'Поиск по индексу MP3';

  @override
  String get mp3IndexSeekingInfoContent =>
      'Включите эту опцию, только если у вас есть MP3-файлы, которые не стремятся к правильной позиции. Неточный поиск обычно происходит от переменного битрейта (VBR) MP3. Индексировать для построения точной временной карты по мере чтения файла, так что прыгая рядом с концом большого MP3 может занять минуту - особенно при стриминге, так как файл должен быть прочитан до этой точки. Вступает в силу следующего запуска эпизода книги или подкаста.';

  @override
  String get mp3IndexSeekingOnSubtitle =>
      'Включен - точный поиск VBR MP3 файлов';

  @override
  String get mp3IndexSeekingOffSubtitle => 'Выкл - обычный поиск';

  @override
  String get trustAllCertificatesInfoContent =>
      'Включите, если ваш сервер Audiobookshelf использует самоподписанный сертификат или кастомный корневой. Если включено, Absorb пропустит проверку сертификата TLS для всех подключений. Включите это только если вы доверяете сети.';

  @override
  String get trustAllCertificatesOnSubtitle =>
      'Вкл - принимать все сертификаты';

  @override
  String get trustAllCertificatesOffSubtitle =>
      'Выкл - только доверенные сертификаты';

  @override
  String get supportTheDev => 'Поддержать разработчика';

  @override
  String get buyMeACoffee => 'Поддержать проект';

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
    return 'Absorb v$version  - Сервер $serverVersion';
  }

  @override
  String get backupAndRestore => 'Бэкап и Восстановление';

  @override
  String get backupAndRestoreSubtitle =>
      'Сохранить или восстановить все ваши настройки из файла';

  @override
  String get backUp => 'Бэкап';

  @override
  String get restore => 'Восстановить';

  @override
  String get allBookmarks => 'Все закладки';

  @override
  String get allBookmarksSubtitle => 'Показать закладки во всех книгах';

  @override
  String get switchAccount => 'Сменить аккаунт';

  @override
  String get addAccount => 'Добавить аккаунт';

  @override
  String get logOut => 'Выйти';

  @override
  String get includeLoginInfoTitle => 'Включить данные для входа?';

  @override
  String get includeLoginInfoContent =>
      'Вы хотите включить учетные данные для всех сохраненных учетных записей в резервную копию?\n\nЭто упрощает восстановление на новом устройстве, но файл будет содержать ваши токены авторизации.';

  @override
  String get noSettingsOnly => 'Нет, только настройки';

  @override
  String get yesIncludeAccounts => 'Да, включить аккаунты';

  @override
  String get backupSavedWithAccounts =>
      'Резервная копия сохранена (с учетными записями)';

  @override
  String get backupSavedSettingsOnly =>
      'Резервная копия сохранена (только настройки)';

  @override
  String backupFailed(String error) {
    return 'Не удалось создать резервную копию: $error';
  }

  @override
  String get restoreBackupTitle => 'Восстановить резервную копию?';

  @override
  String get restoreBackupContent =>
      'Это заменит все ваши текущие настройки на значения из резервной копии.';

  @override
  String fromAbsorbVersion(String version) {
    return 'Absorb v$version';
  }

  @override
  String restoreAccountsChip(int count) {
    return 'Аккаунт(ы) $count';
  }

  @override
  String restoreBookmarksChip(int count) {
    return 'Закладки для книг(и) $count';
  }

  @override
  String get restoreCustomHeadersChip => 'Пользовательские заголовки';

  @override
  String get invalidBackupFile => 'Недопустимый файл резервной копии';

  @override
  String get settingsRestoredSuccessfully => 'Настройки успешно восстановлены';

  @override
  String restoreFailed(String error) {
    return 'Ошибка восстановления: $error';
  }

  @override
  String get logOutTitle => 'Выйти?';

  @override
  String get logOutContent =>
      'Вы выйдете из системы. Ваши загрузки будут сохранены на этом устройстве.';

  @override
  String get signOut => 'Выйти';

  @override
  String get changePasswordTitle => 'Сменить пароль';

  @override
  String get changePasswordSubtitle =>
      'Безопасно обновить пароль Audiobookshelf';

  @override
  String get currentPassword => 'Текущий пароль';

  @override
  String get newPassword => 'Новый пароль';

  @override
  String get confirmNewPassword => 'Подтверди новый пароль';

  @override
  String get passwordChangeEffect =>
      'Смена пароля завершает все текущие сеансы Audiobookshelf. Данное устройство останется в состоянии авторизации.';

  @override
  String get passwordFieldsRequired => 'Заполни все поля пароля';

  @override
  String get passwordsDoNotMatch => 'Новые пароли не совпадают';

  @override
  String get passwordChanged =>
      'Пароль изменен. Все другие устройства, на которых был авторизован пользователь, были отключены.';

  @override
  String get passwordInvalid => 'Текущий пароль неверный';

  @override
  String get passwordChangeUnsupported =>
      'Эта версия сервера не поддерживает безопасное изменение пароля в Absorb';

  @override
  String get passwordChangeFailed => 'Не удалось сменить пароль';

  @override
  String get otherUserPasswordResetWarning =>
      'Смена этого пароля приведет к выходу из учетной записи на всех устройствах.';

  @override
  String get manageSessionsTitle => 'Подключенные устройства';

  @override
  String get manageSessionsSubtitle =>
      'Просмотр и удаление сеансов Audiobookshelf';

  @override
  String get sessionsCurrent => 'Это устройство';

  @override
  String get sessionsUnknownDevice => 'Неизвестное устройство';

  @override
  String sessionsLastActive(String date) {
    return 'Последняя активность: $date';
  }

  @override
  String get sessionsNone => 'Нет активных сеансов';

  @override
  String get sessionsLoadMore => 'Загрузить ещё';

  @override
  String get sessionsUnsupported =>
      'Управление сессиями требует Audiobookshelf 2.36 или новее.';

  @override
  String get sessionsLoadFailed => 'Could not load signed-in devices';

  @override
  String get sessionsLegacyNotice =>
      'This login does not have a refresh session, so Absorb cannot identify this device in the list.';

  @override
  String get sessionsRemove => 'Выход из устройства';

  @override
  String get sessionsRemoveTitle => 'Выйти из устройства?';

  @override
  String get sessionsRemoveContent =>
      'Это удаляет сеанс обновления. Текущий доступ может продолжать работать, пока этот короткий токен не истечет.';

  @override
  String get sessionsRemoved => 'Вы вышли на этом устройстве';

  @override
  String get sessionsRemoveFailed => 'Не удалось выйти из устройства';

  @override
  String get sessionsSignOutAll => 'Выйти из всех устройств';

  @override
  String get sessionsSignOutAllTitle => 'Выйти из системы везде?';

  @override
  String get sessionsSignOutAllContent =>
      'Это удаляет каждую сессию обновления, включая это устройство. Существующие токены доступа могут работать, пока они не закончится.';

  @override
  String podcastScheduleServerTime(String timeZone) {
    return 'Планировщик использует время сервера ($timeZone)';
  }

  @override
  String get podcastScheduleServerTimeUnknown =>
      'Планировщик использует время сервера';

  @override
  String get editServerAddressTitle => 'Редактировать адрес сервера';

  @override
  String editServerAddressSubtitle(String username) {
    return 'Обновите адрес для $username. Используйте это, если ваш сервер изменил адрес - это все равно тот же сервер, просто новый URL. Ваша статистика и загрузки сохраняются.';
  }

  @override
  String get editServerAddressField => 'Адрес сервера';

  @override
  String get editServerAddressUpdated => 'Адрес сервера обновлён';

  @override
  String get editServerAddressFailed => 'Не удалось обновить адрес сервера';

  @override
  String get editServerAddressAction => 'Редактировать адрес сервера';

  @override
  String get editServerConnectionTitle => 'Редактировать подключение к серверу';

  @override
  String editServerConnectionSubtitle(String username) {
    return 'Обновите адрес сервера и пользовательские заголовки для $username. Ваша статистика и загрузки сохраняются.';
  }

  @override
  String get editServerConnectionAction =>
      'Редактировать подключение к серверу';

  @override
  String get editServerConnectionUpdated => 'Подключение к серверу обновлено';

  @override
  String get editServerConnectionFailed =>
      'Не удалось обновить соединение с сервером';

  @override
  String get editCustomHeadersDescription =>
      'Используется для Cloudflare туннелей или обратных прокси. Эти заголовки применяются только к этой сохраненной учетной записи.';

  @override
  String get removeAccountAction => 'Удаление учётной записи';

  @override
  String get removeAccountTitle => 'Удалить аккаунт?';

  @override
  String removeAccountContent(String username, String server) {
    return 'Удалить $username на $server из сохраненных аккаунтов?\n\nВы всегда можете добавить его обратно позже, войдя в систему снова.';
  }

  @override
  String get switchAccountTitle => 'Сменить аккаунт?';

  @override
  String switchAccountContent(String username, String server) {
    return 'Переключиться на $username на $server?\n\nВаше воспроизведение будет остановлено и приложение перезагрузится с другими данными учетной записи.';
  }

  @override
  String get switchButton => 'Переключить';

  @override
  String get downloadLocationSheetTitle => 'Загрузить местоположение';

  @override
  String get downloadLocationSheetSubtitle =>
      'Выберите, где сохраняются аудиокниги';

  @override
  String get currentLocation => 'Текущее местоположение';

  @override
  String get existingDownloadsWarning =>
      'Существующие загрузки сохраняются в их текущем местоположении. Новый путь используется только для новых загрузок.';

  @override
  String get chooseFolder => 'Выбрать папку';

  @override
  String get chooseDownloadFolder => 'Выбрать папку для скачивания';

  @override
  String get storagePermissionDenied =>
      'Разрешение на доступ к памяти отклонено - включите его в настройках приложения';

  @override
  String get openSettings => 'Открыть настройки';

  @override
  String get storagePermissionRequired =>
      'Storage permission is required for custom download locations';

  @override
  String get cannotWriteToFolder =>
      'Запись в эту папку невозможна - выберите другое место или предоставьте доступ к файлам в настройках системы';

  @override
  String downloadLocationSetTo(String label) {
    return 'Download location set to $label';
  }

  @override
  String get resetToDefault => 'Сбросить по умолчанию';

  @override
  String get resetToDefaultStorage => 'Сбросить к хранилищу по умолчанию';

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
  String get redownload => 'Скачать снова';

  @override
  String get redownloadStarted => 'Скачать снова';

  @override
  String get dismiss => 'Отменить';

  @override
  String get tipsAndHiddenFeatures => 'Советы и скрытые возможности';

  @override
  String get tipsSubtitle => 'Получите максимум от Absorb';

  @override
  String get adminTitle => 'Админ сервера';

  @override
  String get adminTasksTitle => 'Активность сервера';

  @override
  String adminTasksRunning(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count задачи выполняются',
      many: '$count задач выполняются',
      few: '$count задачи выполняются',
      one: '$count задача выполняется',
    );
    return '$_temp0';
  }

  @override
  String get adminTasksRecent => 'Недавняя активность сервера';

  @override
  String get adminTasksEmpty => 'Нет запущенных задач сервера';

  @override
  String adminTaskScanSummary(int added, int updated, int missing) {
    return '$added добавлено - $updated обновлено - $missing отсутствует';
  }

  @override
  String get adminServer => 'Сервер';

  @override
  String get adminVersion => 'Версия';

  @override
  String get adminUsers => 'Пользователи';

  @override
  String get adminOnline => 'Онлайн';

  @override
  String get adminBackup => 'Бэкап';

  @override
  String get adminPurgeCache => 'Очистить кеш';

  @override
  String get adminManage => 'Управление';

  @override
  String adminUsersSubtitle(int userCount, int onlineCount) {
    return '$userCount аккаунты - $onlineCount онлайн';
  }

  @override
  String get adminPodcasts => 'Подкасты';

  @override
  String get adminPodcastsSubtitle => 'Поиск, добавление и управление шоу';

  @override
  String get adminScan => 'Сканировать';

  @override
  String get adminScanning => 'Сканирование...';

  @override
  String get adminMatchAll => 'Полное совпадение';

  @override
  String get adminMatching => 'Поиск совпадений...';

  @override
  String get adminMatchAllTitle => 'Совпадение со всеми элементами?';

  @override
  String adminMatchAllContent(String name) {
    return 'Match metadata for all items in $name? This can take a while.';
  }

  @override
  String adminScanStarted(String name) {
    return 'Сканирование началось для $name';
  }

  @override
  String get adminBackupCreated => 'Резервная копия создана';

  @override
  String get adminBackupFailed => 'Не удалось создать резервную копию';

  @override
  String get adminCachePurged => 'Кэш очищен';

  @override
  String get adminRmab => 'ReadMeABook';

  @override
  String get adminRmabSubtitle => 'Открыть в приложении';

  @override
  String get adminRmabAdd => 'Добавить интеграцию с ReadMeABook';

  @override
  String get adminRmabUrlTitle => 'ReadMeABook URL';

  @override
  String get adminRmabUrlHelp =>
      'Вставьте URL токена входа. Создайте его в RMAB, Admin, Users.';

  @override
  String get adminRmabUrlHint => 'https://rmab.example.com/?token=...';

  @override
  String get adminRmabInvalidUrl => 'Введите корректный URL с http(s)';

  @override
  String get adminRmabSaved => 'ReadMeABook сохранён';

  @override
  String get adminRmabRemoved => 'ReadMeABook удалён';

  @override
  String get adminRmabReload => 'Обновить';

  @override
  String get adminRmabLoadFailed =>
      'Не удалось загрузить ReadMeABook. Проверьте свой URL.';

  @override
  String get adminRmabConnected => 'Подключено';

  @override
  String get adminRmabAskAdmin =>
      'Получите URL входа от администратора сервера';

  @override
  String get adminRmabUrlHelpUser =>
      'Получите URL входа от администратора сервера. Он генерируется в RMAB > Администратор > Пользователи.';

  @override
  String get adminRmabSettingsInfo =>
      'ReadMeABook - это сервис для запроса и скачивания аудиокниг. Он должен быть установлен и настроен администратором вашего сервера.';

  @override
  String get rmabConfigTitle => 'Подключение ReadMeABook';

  @override
  String get rmabConfigExplainerAdmin =>
      'ReadMeABook - это самохостинг для запроса аудиокниг. Генерируйте ключ API в RMAB под Admin Dashboard > Settings > API, затем вставьте ниже URL сервера и токен. Absorb не поддерживает или не загружает какой-либо контент, он просто посылает запросы на ваш сервер.';

  @override
  String get rmabConfigExplainerUser =>
      'ReadMeABook — это самохостинг для запроса аудиокниг. Запросите администратора вашего сервера для RMAB URL и API токен. Absorb не размещает или не загружает какие-либо материалы, он просто отправляет запросы на ваш сервер.';

  @override
  String get rmabConfigLearnMore => 'Подробнее о ReadMeABook';

  @override
  String get rmabConfigBaseUrlLabel => 'URL-адрес RMAB сервера';

  @override
  String get rmabConfigBaseUrlHint => 'https://rmab.example.com';

  @override
  String get rmabConfigTokenLabel => 'API токен';

  @override
  String get rmabConfigTokenHint => 'rmab_...';

  @override
  String get rmabConfigLegacyUrlLabel =>
      'URL входа в веб-интерфейс (необязательно)';

  @override
  String get rmabConfigLegacyUrlHint => 'https://rmab.example.com/?token=...';

  @override
  String get rmabConfigLegacyUrlHelp =>
      'Вставьте ваш URL автовхода, так что «Открыть в просмотре браузера» вы вошли в систему. Оставьте пустым, чтобы использовать обычный вход.';

  @override
  String get rmabConfigHeadersHelp =>
      'Дополнительные заголовки, посылаемые с каждым запросом ReadMeABook, для обратных прокси типа доступа Cloudflare Access.';

  @override
  String get rmabConfigConnect => 'Подключиться';

  @override
  String get rmabConfigDisconnect => 'Отключиться';

  @override
  String get rmabConfigOpenWebView => 'Открыть в просмотре браузера';

  @override
  String rmabConfigConnectedAs(String name) {
    return 'Подключено как $name';
  }

  @override
  String get rmabConfigErrorInvalidUrl => 'Введите корректный URL с http(s)';

  @override
  String get rmabConfigErrorMissingToken => 'Введите свой API-токен';

  @override
  String get rmabConfigErrorUnauthorized => 'Токен отклонён сервером';

  @override
  String get rmabConfigErrorForbidden =>
      'Этот токен не допускается для этого действия';

  @override
  String get rmabConfigErrorNetwork =>
      'Не удалось подключиться к RMAB. Проверьте URL-адрес.';

  @override
  String get rmabConfigErrorGeneric => 'Невозможно подключиться';

  @override
  String get rmabConfigSavedSnackbar => 'ReadMeABook подключён';

  @override
  String get rmabConfigDisconnectedSnackbar => 'ReadMeABook отключён';

  @override
  String get rmabRequestCta => 'Запрос через ReadMeABook';

  @override
  String get rmabSearchHeader => 'Запрос через ReadMeABook';

  @override
  String get rmabSearchHint => 'Поиск по названию или автору';

  @override
  String get rmabSearchEmpty => 'Нет совпадений на вашем сервере ReadMeABook';

  @override
  String get rmabSearchError => 'Не удалось найти ReadMeABook';

  @override
  String get rmabSearchPrompt => 'Введите название или автора для поиска';

  @override
  String get rmabSearchFooterPrompt => 'Ищете что-то еще?';

  @override
  String rmabSearchFooterCta(String query) {
    return 'Поиск в ReadMeABook для \"$query\"';
  }

  @override
  String get rmabBookDetailExplainer =>
      'Этот запрос будет отправлен через ваш сервер ReadMeABook. Администратор будет проверять и обрабатывать его. Вы можете отслеживать его под My Requests на плитке ReadMeABook.';

  @override
  String get rmabBookAlreadyAvailable => 'Уже в вашей библиотеке';

  @override
  String get rmabBookAlreadyRequested => 'Уже запрошено';

  @override
  String get rmabRequestSubmitting => 'Отправляем…';

  @override
  String get rmabRequestSent => 'Запрос отправлен';

  @override
  String get rmabRequestErrorAlreadyAvailable => 'Уже в вашей библиотеке';

  @override
  String get rmabRequestErrorBeingProcessed => 'Уже в обработке';

  @override
  String get rmabRequestErrorDuplicate => 'Вы уже запрашивали это';

  @override
  String get rmabRequestErrorValidation => 'Не удалось отправить запрос';

  @override
  String get rmabRequestErrorUserNotFound =>
      'Токен пользователя больше не существует. Переподключение ReadMeABook.';

  @override
  String get rmabRequestErrorIgnored =>
      'Эта книга находится в вашем списке игнор';

  @override
  String get rmabRequestErrorGeneric => 'Не удалось отправить запрос';

  @override
  String get rmabRequestErrorTokenRejected =>
      'Токен отклонен сервером. Переподключение ReadMeABook.';

  @override
  String get rmabMyRequestsTab => 'Мои Запросы';

  @override
  String get rmabSetupTab => 'Настройки';

  @override
  String get rmabMyRequestsEmpty => 'Вы еще не запросили ни одной книги';

  @override
  String get rmabMyRequestsError => 'Не удалось загрузить запросы';

  @override
  String get rmabMyRequestsRefresh => 'Обновить';

  @override
  String get rmabRequestDetailTitle => 'Детали запроса';

  @override
  String get rmabRequestDetailStatus => 'Статус';

  @override
  String get rmabRequestDetailRequestedOn => 'Запрошено';

  @override
  String get rmabRequestDetailCompletedOn => 'Выполнено';

  @override
  String get rmabRequestDetailProgress => 'Прогресс';

  @override
  String get rmabStatusActive => 'В процессе';

  @override
  String get rmabStatusWaiting => 'Ожидание';

  @override
  String get rmabStatusAvailable => 'Доступно';

  @override
  String get rmabStatusDownloaded => 'Загружено';

  @override
  String get rmabStatusFailed => 'Ошибка';

  @override
  String get rmabStatusCancelled => 'Отменено';

  @override
  String get rmabStatusDenied => 'Отказано';

  @override
  String get rmabStatusUnknown => 'Неизвестно';

  @override
  String narratedBy(String narrator) {
    return 'Распространяется $narrator';
  }

  @override
  String get onAudible => 'on Audible';

  @override
  String percentComplete(String percent) {
    return '$percent% выполнено';
  }

  @override
  String get absorbing => 'Поглощение...';

  @override
  String get absorbAgain => 'Поглощение снова';

  @override
  String get absorb => 'Поглощение';

  @override
  String get ebookOnlyNoAudio => 'только eBook - без аудио';

  @override
  String get absorbAudioNotDownloaded => 'Аудио не загружено';

  @override
  String get absorbAudioNotDownloadedEbookOnly =>
      'Аудио не загружено, только ebook';

  @override
  String get fullyAbsorbed => 'Полностью Поглощено';

  @override
  String get fullyAbsorbAction => 'Полное Поглощение';

  @override
  String get removeFromAbsorbing => 'Удалить из Поглощения';

  @override
  String get addToAbsorbing => 'Добавить в Поглощение';

  @override
  String get absorbNext => 'Поглощение след';

  @override
  String get absorbNextAdded => 'Следующий в Поглощении';

  @override
  String get absorbLast => 'Поглощение последнего';

  @override
  String get absorbNextHint => 'Сразу после того, что сейчас играет';

  @override
  String get absorbLastHint => 'В конец списка';

  @override
  String get removedFromAbsorbing => 'Удалено из Поглощения';

  @override
  String get addedToAbsorbing => 'Добавлено в Поглощение';

  @override
  String get removeFromContinueListening => 'Удалить из Продолжить слушать';

  @override
  String get removedFromContinueListening => 'Удалить из Продолжить слушать';

  @override
  String get removeFromContinueReading => 'Remove from Continue Reading';

  @override
  String get removedFromContinueReading => 'Removed from Continue Reading';

  @override
  String get sessionAdd => 'Add session';

  @override
  String get sessionStartLabel => 'Started at';

  @override
  String get sessionAdded => 'Session added';

  @override
  String get sessionAddFailed => 'Could not add the session';

  @override
  String get removeSeriesFromContinueSeries => 'Удалить из Продолжить серию';

  @override
  String get removedSeriesFromContinueSeries => 'Removed from Continue Series';

  @override
  String get couldNotUpdate => 'Could not update, try again';

  @override
  String get addToPlaylist => 'Добавить в плейлист';

  @override
  String get addToCollection => 'Добавить в коллекцию';

  @override
  String get downloadEbook => 'Скачать eBook';

  @override
  String get downloadEbookAgain => 'Скачать eBook снова';

  @override
  String get resetProgress => 'Сбросить прогресс';

  @override
  String get lookupLocalMetadata => 'Lookup Local Metadata';

  @override
  String get reLookupLocalMetadata => 'Re-Lookup Local Metadata';

  @override
  String get clearLocalMetadata => 'Очистить локальные метаданные';

  @override
  String get searchOnGoodreads => 'Search on Goodreads';

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
  String get mono => 'Моно';

  @override
  String get stereo => 'Стерео';

  @override
  String get startM4bEncode => 'Запустить кодирование M4B';

  @override
  String get encodeStarted => 'M4B кодирование запущено';

  @override
  String get encodeFailed => 'Failed to start encode';

  @override
  String get encodeFinished => 'Завершено кодирование M4B';

  @override
  String get currentlyLabel => 'Currently:';

  @override
  String encodeOutputPathNote(String path) {
    return 'Готовый файл M4B будет помещен в папку аудиокниг: $path/';
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
  String get aboutSection => 'About';

  @override
  String chaptersCount(int count) {
    return 'Главы ($count)';
  }

  @override
  String audioTracksCount(int count) {
    return 'Аудио треки ($count)';
  }

  @override
  String libraryFilesCount(int count) {
    return 'Файлы библиотеки ($count)';
  }

  @override
  String get chapters => 'Главы';

  @override
  String get noChaptersBook => 'В этой книге нет глав';

  @override
  String get noChaptersPodcast => 'В этом подкасте нет глав';

  @override
  String get failedToLoad => 'Не удалось загрузить';

  @override
  String startedDate(String date) {
    return 'Начато $date';
  }

  @override
  String finishedDate(String date) {
    return 'Прослушано $date';
  }

  @override
  String andCountMore(int count) {
    return 'и ещё $count';
  }

  @override
  String get markAsFullyAbsorbedQuestion => 'Mark as Fully Absorbed?';

  @override
  String get markAsFullyAbsorbedContent =>
      'Это установит ваш прогресс на 100% и прекратит воспроизведение, если эта книга проигрывается.';

  @override
  String get markedAsFinishedNiceWork =>
      'Помечено как прослушано - красивая работа!';

  @override
  String get failedToUpdateCheckConnection =>
      'Не удалось обновить - проверьте ваше соединение';

  @override
  String get markedFinishedWillSync =>
      'Marked as finished - will sync when you\'re back online';

  @override
  String get markAsNotFinishedQuestion => 'Пометить как не прослушано?';

  @override
  String get markAsNotFinishedContent =>
      'Это очистит статус прослушано и вернет вашу позицию на начало.';

  @override
  String get unmark => 'Снять метку';

  @override
  String get markedAsNotFinishedBackAtIt =>
      'Помечено как не прослушано - Ещё разок!';

  @override
  String get resetProgressQuestion => 'Сбросить прогресс?';

  @override
  String get resetProgressListeningAndReading =>
      'Your listening and reading progress will both go back to 0%.';

  @override
  String get resetProgressListening =>
      'Your listening progress will go back to 0%.';

  @override
  String get resetProgressReading =>
      'Your reading progress will go back to 0%.';

  @override
  String get resetProgressMarksUnread =>
      'The book will also be marked as unread.';

  @override
  String get resetProgressCantUndo => 'This can\'t be undone.';

  @override
  String get progressResetFreshStart => 'Прогресс сброшен - свежий старт!';

  @override
  String get clearLocalMetadataQuestion => 'Очистить локальные метаданные?';

  @override
  String get clearLocalMetadataContent =>
      'Это удалит локально сохраненные метаданные и вернется к данным от сервера.';

  @override
  String get localMetadataCleared => 'Локальные метаданные удалены';

  @override
  String get saveEbook => 'Сохранить eBook';

  @override
  String get noEbookFileFound => 'Не найден файл ebook';

  @override
  String get bookmark => 'Закладка';

  @override
  String get bookmarks => 'Закладки';

  @override
  String bookmarksWithCount(int count) {
    return 'Закладки ($count)';
  }

  @override
  String get playbackSpeed => 'Скорость воспроизведения';

  @override
  String get noBookmarksYet => 'Пока нет закладок';

  @override
  String get longPressBookmarkHint =>
      'Долгое нажатие на кнопку закладки для быстрого сохранения';

  @override
  String get addBookmark => 'Добавить закладку';

  @override
  String get editBookmark => 'Изменить закладку';

  @override
  String get titleLabel => 'Название';

  @override
  String get noteOptionalLabel => 'Заметка (необязательно)';

  @override
  String get editLayout => 'Редактировать макет';

  @override
  String get inMenu => 'В меню';

  @override
  String get bookmarkAdded => 'Закладка добавлена';

  @override
  String get startPlayingSomethingFirst => 'Начните играть что-то вначале';

  @override
  String get playbackHistory => 'История воспроизведения';

  @override
  String get historyLocalTab => 'История';

  @override
  String get historyServerTab => 'Сессии';

  @override
  String get historyNoServerSessions =>
      'Сессий сервера для этого элемента пока нет';

  @override
  String get historyServerLoadFailed => 'Не удалось загрузить сессии сервера';

  @override
  String get clearHistoryTooltip => 'Очистить историю';

  @override
  String get tapEventToJump =>
      'Коснитесь события, чтобы перейти к этой позиции';

  @override
  String get noHistoryYet => 'Истории пока нет';

  @override
  String jumpedToPosition(String position) {
    return 'Переход к $position';
  }

  @override
  String booksInSeriesCount(int count) {
    return '$count книг в этой серии';
  }

  @override
  String bookNumber(String number) {
    return 'Книга $number';
  }

  @override
  String downloadRemainingCount(int count) {
    return 'Осталось загрузок ($count)';
  }

  @override
  String get downloadAll => 'Скачать все';

  @override
  String get markAllNotFinished => 'Отметить всё как не прослушано';

  @override
  String get markAllFinished => 'Отметить всё как прослушано';

  @override
  String get markAllNotFinishedQuestion => 'Отметить всё как не прослушано?';

  @override
  String get fullyAbsorbSeries => 'Полностью Absorb серии?';

  @override
  String get turnAutoDownloadOff => 'Выключить автозагрузку';

  @override
  String get turnAutoDownloadOn => 'Включить автозагрузку';

  @override
  String get autoDownloadThisSeries => 'Автозагрузка этой серии?';

  @override
  String get autoDownloadSeriesContent =>
      'Автоматически загружать следующие книги по мере прослушивания.';

  @override
  String get standalone => 'Автономно';

  @override
  String get episodes => 'Выпуски';

  @override
  String get noEpisodesFound => 'Эпизоды не найдены';

  @override
  String get markFinished => 'Отметить как прослушано';

  @override
  String get markUnfinished => 'Отметить как не прослушано';

  @override
  String get allEpisodes => 'Все эпизоды';

  @override
  String get aboutThisEpisode => 'Об этом эпизоде';

  @override
  String get reversePlayOrder => 'Обратный порядок воспроизведения';

  @override
  String selectedCount(int count) {
    return '$count выбрано';
  }

  @override
  String get selectAll => 'Выбрать все';

  @override
  String get deselectAll => 'Отменить всё';

  @override
  String get autoDownloadThisPodcast => 'Автозагрузка этого подкаста?';

  @override
  String get autoDownloadPodcastContent =>
      'Автоматически загружать следующие эпизоды по мере прослушивания.';

  @override
  String get download => 'Скачать';

  @override
  String get deleteDownload => 'Удалить загруженные';

  @override
  String get casting => 'Трансляция';

  @override
  String get castingTo => 'Транслировать на';

  @override
  String get editDetails => 'Редактировать сведения';

  @override
  String get quickMatch => 'Быстрое совпадение';

  @override
  String get quickMatchNoUpdates => 'Обновления не требуется';

  @override
  String get custom => 'Кастомный';

  @override
  String get authorOptionalLabel => 'Автор (необязательно)';

  @override
  String get noResultsFound =>
      'Нет результатов.\nПопробуйте изменить запрос или поставщика.';

  @override
  String get searchForMetadataAbove => 'Искать метаданные выше';

  @override
  String get applyThisMatch => 'Применить это совпадение?';

  @override
  String get metadataUpdated => 'Метаданные обновлены';

  @override
  String get failedToUpdateMetadata => 'Не удалось обновить метаданные';

  @override
  String get subtitleLabel => 'Субтитры';

  @override
  String get authorLabel => 'Автор';

  @override
  String get narratorLabel => 'Чтец';

  @override
  String get seriesLabel => 'Серия';

  @override
  String get addSeries => 'Добавить серию';

  @override
  String get removeSeries => 'Удалить серию';

  @override
  String get descriptionLabel => 'Описание';

  @override
  String get publisherLabel => 'Издатель';

  @override
  String get yearLabel => 'Год';

  @override
  String get genresLabel => 'Жанры';

  @override
  String get tagsLabel => 'Теги';

  @override
  String get commaSeparated => 'Разделенные запятой';

  @override
  String get asinLabel => 'ASIN';

  @override
  String get isbnLabel => 'ISBN';

  @override
  String get coverImage => 'Обложка';

  @override
  String get coverRemove => 'Удалить обложку';

  @override
  String get coverRemoveConfirm =>
      'Удалить обложку этой книги? Вместо нее будет показана сгенерированная карта.';

  @override
  String get coverRemoved => 'Обложка удалена';

  @override
  String get coverRemoveFailed => 'Не удалось удалить обложку';

  @override
  String get coverUrlLabel => 'URL обложки';

  @override
  String get coverUrlHint => 'https://...';

  @override
  String get localMetadata => 'Локальные метаданные';

  @override
  String get overrideLocalDisplay => 'Переопределить локальное отображение';

  @override
  String get metadataSavedLocally => 'Метаданные сохранены локально';

  @override
  String get notes => 'Заметки';

  @override
  String get newNote => 'Новая заметка';

  @override
  String get editNote => 'Редактировать заметку';

  @override
  String get noNotesYet => 'Заметок пока нет';

  @override
  String get markdownIsSupported => 'Поддерживается Markdown';

  @override
  String get markdownMd => 'Markdown (.md)';

  @override
  String get keepsFormattingIntact => 'Сохраняет форматирование нетронутым';

  @override
  String get plainTextTxt => 'Простой текст (.txt)';

  @override
  String get simpleTextNoFormatting => 'Простой текст, без форматирования';

  @override
  String get untitledNote => 'Заметка без названия';

  @override
  String get titleHint => 'Название';

  @override
  String get noteBodyHint => 'Напиши заметку... (поддерживает markdown)';

  @override
  String get nothingToPreview => 'Нет ничего для предосмотра';

  @override
  String get audioEnhancements => 'Улучшение звука';

  @override
  String get presets => 'ПРЕСЕТЫ';

  @override
  String get equalizer => 'ЭКВАЛАЙЗЕР';

  @override
  String get effects => 'ЭФФЕКТЫ';

  @override
  String get bassBoost => 'Усиление Басов';

  @override
  String get surround => 'Объёмный';

  @override
  String get loudness => 'Громкость';

  @override
  String get pitch => 'Pitch';

  @override
  String get monoAudio => 'Монозвук';

  @override
  String get skipSilence => 'Пропускать тишину';

  @override
  String get resetAll => 'Сбросить все';

  @override
  String get collectionNotFound => 'Коллекция не найдена';

  @override
  String get deleteCollection => 'Удалить коллекцию';

  @override
  String get deleteCollectionContent =>
      'Ты действительно хочешь удалить эту коллекцию?';

  @override
  String get deleteCollectionFailed => 'Не удалось удалить коллекцию';

  @override
  String get deletePermissionRequired =>
      'Требуется разрешение на удаление. Попросите root администратора предоставить вам разрешение на удаление.';

  @override
  String get deleteFilesCheckbox => 'Также удалить файлы на сервере';

  @override
  String get deleteFilesCheckedHint => 'Файлы удалены с сервера безвозвратно.';

  @override
  String get deleteFilesUncheckedHint =>
      'Файлы остаются на сервере, поэтому при следующем сканировании библиотеки их можно будет вернуть.';

  @override
  String get deleteFromServerAction => 'Удалить с сервера';

  @override
  String get deleteFromServerTitle => 'Удалить с сервера';

  @override
  String deleteFromServerContent(String title) {
    return 'Удалить \"$title\" из Audiobookshelf?';
  }

  @override
  String deletedFromServer(String title) {
    return 'Удалено \"$title\"';
  }

  @override
  String get deleteFromServerFailed =>
      'Не удалось удалить это. Проверьте логи сервера.';

  @override
  String get playlistNotFound => 'Плейлист не найден';

  @override
  String get deletePlaylist => 'Удалить плейлист';

  @override
  String get deletePlaylistContent =>
      'Вы уверены, что хотите удалить этот плейлист?';

  @override
  String get newPlaylist => 'Новый плейлист';

  @override
  String get playlistNameHint => 'Название плейлиста';

  @override
  String addedToName(String name) {
    return 'Добавлено в \"$name\"';
  }

  @override
  String get failedToAdd => 'Ошибка добавления';

  @override
  String get newCollection => 'Новая коллекция';

  @override
  String get collectionNameHint => 'Название коллекции';

  @override
  String get listsNewCollectionSubtitle =>
      'Группируйте книги в хранящийся список';

  @override
  String get listsNewCollectionNeedsBookSubtitle =>
      'Начать с хотя бы одной книгой';

  @override
  String get listsNewPlaylistSubtitle => 'Построeние книг для прослушивания';

  @override
  String get listsAddBooksNow => 'Добавить книги сейчас';

  @override
  String get listsPickBooksNext =>
      'Далее вы выберете книги. Коллекция на этом сервере должна иметь хотя бы одну книгу.';

  @override
  String get listsCreate => 'Создать';

  @override
  String get listsCollectionNeedsBook =>
      'Коллекция должна иметь хотя бы одну книгу, так что ничего не было создано.';

  @override
  String get listsCreateFailed => 'Не удалось создать';

  @override
  String get castToDevice => 'Передача на устройство';

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
  String get searchingForCastDevices => 'Поиск Cast устройств...';

  @override
  String get castDevice => 'Устройство для трансляции';

  @override
  String get stopCasting => 'Остановить трансляцию';

  @override
  String get disconnect => 'Отключиться';

  @override
  String get audioOutput => 'Аудиовыход';

  @override
  String get noOutputDevicesFound => 'No output devices found';

  @override
  String get welcomeToAbsorb => 'Добро пожаловать в Absorb';

  @override
  String get welcomeTagline => 'Клиент Audiobookshelf.';

  @override
  String get welcomeAbsorbingTitle => 'Поглощение';

  @override
  String get welcomeAbsorbingIntro =>
      'We use \"absorb\" in place of \"play\" and \"listen\". Prefer the classic wording? Switch it in Settings.';

  @override
  String get welcomeAbsorbingTabBullet =>
      'Absorbing tab - what you\'re currently listening to';

  @override
  String get welcomeAbsorbButtonBullet => 'Absorb button - start playback';

  @override
  String get welcomeFullyAbsorbBullet =>
      'Полное Поглощение - отметить как прослушано';

  @override
  String get welcomeGettingAroundTitle => 'Getting around';

  @override
  String get welcomeGettingAroundBody =>
      'Tap any cover to open its details. Continue Listening cards are different - tap to play right away, press and hold to open details.';

  @override
  String get welcomeMakeItYoursTitle => 'Make it yours';

  @override
  String get welcomeMakeItYoursBody =>
      'Mess around in Settings to tune Absorb to your taste. The Tips & Hidden Features section in there is worth a look.';

  @override
  String get getStarted => 'Приступить к работе';

  @override
  String get showMore => 'Показать еще';

  @override
  String get showLess => 'Показать меньше';

  @override
  String get readMore => 'Подробнее';

  @override
  String get removeDownloadQuestion => 'Удалить загрузки?';

  @override
  String get removeDownloadContent => 'Это будет удалено с вашего устройства.';

  @override
  String get removeWhichDownload =>
      'The audiobook and the ebook are both on this device. Choose what to remove.';

  @override
  String get downloadRemoved => 'Загрузка удалена';

  @override
  String get finished => 'Прослушано';

  @override
  String get saved => 'Скачано';

  @override
  String get selectLibrary => 'Выбери библиотеку';

  @override
  String get switchLibraryTooltip => 'Переключить библиотеку';

  @override
  String get refreshTooltip => 'Обновить';

  @override
  String get openNowPlayingTooltip => 'Open Now Playing';

  @override
  String get previousChapterTooltip => 'Previous chapter';

  @override
  String get nextChapterTooltip => 'Next chapter';

  @override
  String get noBooksFound => 'Книги не найдены';

  @override
  String get userFallback => 'Пользователь';

  @override
  String get rootAdmin => 'Корневой админ';

  @override
  String get admin => 'Админ';

  @override
  String get serverAdmin => 'Админ сервера';

  @override
  String get serverAdminSubtitle =>
      'Управление пользователями, библиотеками и настройками сервера';

  @override
  String serverUpdateAvailable(String version) {
    return 'Доступно обновление сервера $version';
  }

  @override
  String get justNow => 'Только что';

  @override
  String minutesAgo(int count) {
    return '$countм назад';
  }

  @override
  String hoursAgo(int count) {
    return '$count ч назад';
  }

  @override
  String daysAgo(int count) {
    return '$countд назад';
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
  String get coverPlayPause => 'Обложка воспроизведение/пауза';

  @override
  String get coverPlayPauseOnSubtitle =>
      'Вкл - нажмите на обложку для воспроизведения/паузы';

  @override
  String get coverPlayPauseOffSubtitle =>
      'Выкл - выделенная кнопка воспроизведения/паузы в панели управления';

  @override
  String get cardBackground => 'Фон карточки';

  @override
  String get cardBackgroundBlurred => 'Размытый';

  @override
  String get cardBackgroundGradient => 'Градиент';

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
      'Воспроизведение останавливается, очередь вручную или автоматическое воспроизведение следующего элемента';

  @override
  String get queueModeSeriesLabel => 'Серии';

  @override
  String get queueModeShowLabel => 'Показать';

  @override
  String get queueModeInfoSeries => 'Серии';

  @override
  String get queueModeInfoSeriesDesc =>
      'Автоматически проигрывает следующую книгу в серии или в следующем эпизоде в подкасте.';

  @override
  String get resetButtonGridQuestion => 'Сбросить сетку кнопок?';

  @override
  String get resetButtonGridContent =>
      'Это восстановит стандартную раскладку кнопок, порядок и настройки переключателей.';

  @override
  String get reset => 'Сбросить';

  @override
  String get buttonGridReset => 'Сброс сетки кнопок';

  @override
  String get resetButtonGrid => 'Сбросить сетку кнопок';

  @override
  String get chapterBarrierOnRewind => 'Барьер на перемотке';

  @override
  String get chapterBarrierInfoTitle => 'Барьер глав';

  @override
  String get chapterBarrierInfoContent =>
      'При переходе назад, воспроизведение будет переходить к началу текущей главы, а не к предыдущей.\n\nЧтобы обойти барьер, нажмите на кнопку \"назад\" дважды в течение 2 секунд.';

  @override
  String get chapterBarrierOnRewindOnSubtitle =>
      'Вкл - перемотать назад в начало главы';

  @override
  String get chapterBarrierOnRewindOffSubtitle =>
      'Выкл - перемотка пересекает границы глав';

  @override
  String autoRewindOnSubtitleFormat(String min, String max) {
    return 'Вкл - $minс до $maxв зависимости от длины паузы';
  }

  @override
  String get rewindOnSessionStart => 'Перемотка при запуске сессии';

  @override
  String get rewindOnSessionStartInfoContent =>
      'Обычная автоматическая перемотка назад запускается при возобновлении воспроизведения после паузы в рамках активного сеанса. Этот параметр добавляет перемотку назад при запуске совершенно нового сеанса — например, после закрытия приложения, остановки воспроизведения или повторного открытия приложения. \n\n Если эта функция включена, при каждом новом сеансе воспроизведения происходит полная перемотка назад на максимальное количество секунд, чтобы вы могли продолжить с того места, на котором остановились.';

  @override
  String rewindOnSessionStartOnSubtitle(String seconds) {
    return 'Включен - перемотка $secondsс при запуске новой сессии';
  }

  @override
  String rewindActivationDelayValue(String seconds) {
    return '${seconds}s+';
  }

  @override
  String rewindRangeValue(String min, String max) {
    return '$minс – $maxс';
  }

  @override
  String rewindSecondsPause(String seconds) {
    return 'Приостановить $seconds';
  }

  @override
  String rewindMinPause(String minutes) {
    return '$minutes мин. пауза';
  }

  @override
  String rewindHrPause(String hours) {
    return 'Приостановить $hours';
  }

  @override
  String get rewindOneHrPause => '1 час паузы';

  @override
  String speedValue(String speed) {
    return '${speed}x';
  }

  @override
  String secondsValue(String seconds) {
    return '${seconds}s';
  }

  @override
  String minutesValue(int minutes) {
    return '$minutes мин';
  }

  @override
  String get chimeBeforeSleep => 'Колокольчик перед сном';

  @override
  String get chimeBeforeSleepOnSubtitle =>
      'Проигрывает мягкое оповещение перед окончанием таймера';

  @override
  String get chimeBeforeSleepOffSubtitle =>
      'Без звукового оповещения перед сном';

  @override
  String get windDownDuration => 'Длительность затухания';

  @override
  String windDownDurationSubtitle(int seconds) {
    return 'Нарастание и звон начинаются за $seconds до сна';
  }

  @override
  String fadeVolumeOnSubtitleDynamic(int seconds) {
    return 'Постепенно снижать громкость последние $secondsс';
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
  String get endOfChapterShort => 'Конец главы';

  @override
  String get endOfChapterOnSubtitle => 'Остановка в конце текущей главы';

  @override
  String get endOfChapterOffSubtitle => 'Использовать таймер сна';

  @override
  String get showExplicitBadge => 'Показать явный значок';

  @override
  String get showExplicitBadgeOnSubtitle =>
      'Чрезмерные элементы показывают значок \"E\"';

  @override
  String get showExplicitBadgeOffSubtitle => 'Выкл - явный значок скрыт';

  @override
  String get showEbookBadge => 'Показать значок ebook';

  @override
  String get showEbookBadgeOnSubtitle =>
      'Книги с ebook отображают значок книги на обложке';

  @override
  String get showEbookBadgeOffSubtitle => 'Выкл - значок скрыт';

  @override
  String get libraryFallback => 'Библиотека';

  @override
  String get preReleaseUpdatesInfoTitle => 'Пред-релизные обновления';

  @override
  String get preReleaseUpdatesInfoContent =>
      'Когда включено, проверка обновлений также уведомит вас о альфа-релизных сборках с GitHub. Они могут быть менее стабильными, но включают в себя последние функции и исправления.';

  @override
  String get includePreReleases => 'Включить предрелизы';

  @override
  String get includePreReleasesOnSubtitle =>
      'Вкл - проверка на альфа и предварительные релизы';

  @override
  String get includePreReleasesOffSubtitle => 'Выкл - только стабильные версии';

  @override
  String get setTooltip => 'Задать';

  @override
  String get saveAbsorbBackup => 'Сохранить резервную копию Absorb';

  @override
  String get checkForUpdate => 'Проверить наличие обновлений';

  @override
  String get onLatestVersion => 'Установлена последняя версия';

  @override
  String get updateAvailable => 'Доступно обновление';

  @override
  String get preReleaseAvailable => 'Доступен предварительный релиз';

  @override
  String updateDialogContent(String kind, String latest, String current) {
    return 'Доступен новый $kind от Absorb: $latest\n\nВы используете $current.';
  }

  @override
  String get updateKindPreRelease => 'предварительный релиз';

  @override
  String get updateKindVersion => 'версия';

  @override
  String get downloadButton => 'Скачать';

  @override
  String get updateDownloading => 'Загрузка обновления...';

  @override
  String get updateInstallPermissionDenied =>
      'Доступ запрещен. Включите \"Установить из неизвестных источников\" для Absorb в настройках системы.';

  @override
  String get updateOpeningInBrowser =>
      'Не удалось обновить приложение, открытие браузера';

  @override
  String get sendToEreader => 'Отправить в E-Reader';

  @override
  String sendingToEreader(String device) {
    return 'Отправка на $device...';
  }

  @override
  String sendToEreaderSuccess(String device) {
    return 'Отправлено на $device';
  }

  @override
  String get sendToEreaderFailed => 'Не удалось отправить на eBook';

  @override
  String get pickEreaderDevice => 'Выбрать устройство';

  @override
  String get adminEmail => 'Почта';

  @override
  String get adminEmailSubtitle => 'Устройства SMTP и e-reader';

  @override
  String get smtpSection => 'SMTP';

  @override
  String get smtpSetupGuide => 'Инструкция по настройке';

  @override
  String get smtpHost => 'Хост';

  @override
  String get smtpPort => 'Порт';

  @override
  String get smtpSecure => 'Безопасность';

  @override
  String get smtpRejectUnauthorized => 'Отклонить несанкционированный TLS';

  @override
  String get smtpUser => 'Логин';

  @override
  String get smtpPass => 'Пароль';

  @override
  String get smtpFromAddress => 'С адреса';

  @override
  String get smtpTestAddress => 'Адрес теста';

  @override
  String get smtpSendTest => 'Отправить тест';

  @override
  String get smtpSaveSettings => 'Сохранить';

  @override
  String get smtpSaved => 'Настройки Email сохранены';

  @override
  String get smtpSaveFailed => 'Не удалось сохранить настройки email';

  @override
  String get smtpTestSent => 'Тестовый email отправлен';

  @override
  String get smtpTestFailed => 'Тестовый email не удался';

  @override
  String get ereaderDevicesTitle => 'Устройства E-Reader';

  @override
  String get ereaderDevicesEmpty => 'Нет устройств. Добавьте ниже.';

  @override
  String get addEreaderDevice => 'Добавить устройство';

  @override
  String get editEreaderDevice => 'Редактировать устройство';

  @override
  String get deleteEreaderDevice => 'Удалить';

  @override
  String get ereaderDeviceName => 'Название';

  @override
  String get ereaderDeviceEmail => 'Адрес электронной почты';

  @override
  String get ereaderAvailability => 'Кто может использовать данное устройство';

  @override
  String get ereaderAvailAdminOrUp => 'Только администраторы';

  @override
  String get ereaderAvailUserOrUp => 'Все пользователи';

  @override
  String get ereaderAvailGuestOrUp => 'Кто угодно';

  @override
  String get ereaderAvailSpecificUsers => 'Определенные пользователи';

  @override
  String ereaderSpecificUsersN(int count) {
    return 'Определенных пользователей ($count)';
  }

  @override
  String get ereaderDevicesSaved => 'Устройства сохранены';

  @override
  String get ereaderDevicesSaveFailed => 'Не удалось сохранить устройства';

  @override
  String libraryCountOne(int count) {
    return 'Библиотеки $count';
  }

  @override
  String libraryCountOther(int count) {
    return 'Библиотеки $count';
  }

  @override
  String serverVersionLabel(String version) {
    return 'Сервер $version';
  }

  @override
  String appVersionServerSuffix(String version) {
    return '  ·  Сервер $version';
  }

  @override
  String backupDateFormat(int month, int day, int year) {
    return '$day/$month/$year';
  }

  @override
  String get backupDetailsSeparator => ' · ';

  @override
  String get bookmarksSortedByPositionReversed =>
      'Сортировка по позиции (обратный)';

  @override
  String bookmarksJumpShortContent(String title, String position) {
    return '\"$title\" на $position';
  }

  @override
  String get deleteBookmarkQuestion => 'Удалить закладку?';

  @override
  String get cardIconsOnlyChip => 'Только иконки';

  @override
  String get cardMoreInGridChip => '\"Еще\" в сетке';

  @override
  String get cardLayoutHidden => 'Скрыто';

  @override
  String get speed => 'Скорость';

  @override
  String get details => 'Подробности';

  @override
  String get episodeDetailsLabel => 'Подробности эпизода';

  @override
  String get bookDetailsLabel => 'Детали книги';

  @override
  String get equalizerShort => 'EQ';

  @override
  String get equalizerLabel => 'Эквалайзер';

  @override
  String get cast => 'Актеры';

  @override
  String castingToDevice(String device) {
    return 'Занесение в $device';
  }

  @override
  String castToDeviceNamed(String device) {
    return 'Отправлено на $device';
  }

  @override
  String get historyShort => 'История';

  @override
  String atPosition(String position) {
    return 'на $position';
  }

  @override
  String chaptersChip(int count) {
    return 'Главы $count';
  }

  @override
  String chapterNumber(int number) {
    return 'Глава $number';
  }

  @override
  String kbpsValue(int value) {
    return '$value кбит/с';
  }

  @override
  String get fileInfoTitle => 'File info';

  @override
  String fileInfoFileCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files',
      one: '1 file',
    );
    return '$_temp0';
  }

  @override
  String get fileInfoNone => 'This book has no file details.';

  @override
  String get fileInfoAudio => 'Audio';

  @override
  String get fileInfoEbook => 'Ebook';

  @override
  String get fileInfoOther => 'Other files';

  @override
  String get fileInfoBookOrbitNote =>
      'BookOrbit doesn\'t report codec or bitrate.';

  @override
  String fileInfoChannels(int count) {
    return '$count channels';
  }

  @override
  String get fileInfoCover => 'Cover';

  @override
  String get fileInfoMetadata => 'Metadata';

  @override
  String get fileInfoSupplement => 'Extra';

  @override
  String get fileInfoPathCopied => 'Path copied';

  @override
  String get resetMayNotHaveSynced =>
      'Возможно не синхронизировано - проверьте ваш сервер';

  @override
  String failedToDownloadEbook(int code) {
    return 'Не удалось загрузить ebook ($code)';
  }

  @override
  String get serverReturnedErrorPage =>
      'Сервер вернул страницу ошибки вместо файла ebook';

  @override
  String ebookSaved(String filename) {
    return 'Сохранено: $filename';
  }

  @override
  String errorSavingEbook(String error) {
    return 'Ошибка при сохранении ebook: $error';
  }

  @override
  String failedToSaveError(String error) {
    return 'Ошибка сохранения: $error';
  }

  @override
  String get adminBackupsLabel => 'Резервные копии';

  @override
  String get adminListeningNow => 'Сейчас играет';

  @override
  String get adminLibraries => 'Библиотеки';

  @override
  String get adminLibraryShows => 'shows';

  @override
  String get adminLibraryBooks => 'книги';

  @override
  String get adminLibraryFolders => 'папки';

  @override
  String get adminLibrarySize => 'размер';

  @override
  String get adminLibraryDuration => 'длительность';

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
  String get adminLibraryReview => 'Обзор';

  @override
  String get adminMissingTitle => 'Отсутствующие элементы';

  @override
  String adminMissingSubtitle(String library) {
    return 'Записи в $library, чьи файлы отсутствуют или не читаются';
  }

  @override
  String get adminMissingNone => 'Нет отсутствующих или недопустимых элементов';

  @override
  String get adminMissingBadge => 'Отсутствует';

  @override
  String get adminInvalidBadge => 'Недопустимый';

  @override
  String get adminMissingDeleteTitle => 'Удалить запись';

  @override
  String adminMissingDeleteOneContent(String title) {
    return 'Удалить \"$title\" из Audiobookshelf?';
  }

  @override
  String adminMissingDeleteManyContent(int count) {
    return 'Удалить \"$count\" из Audiobookshelf?';
  }

  @override
  String adminMissingDeleteCount(int count) {
    return 'Удалено \"$count';
  }

  @override
  String adminMissingRemovedOne(String title) {
    return 'Удалено $title';
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
  String get adminMissingDeleteFailed => 'Не удалось удалить запись';

  @override
  String get adminMatchAction => 'Совпадение';

  @override
  String adminMatchingStarted(String name) {
    return 'Начато сопоставление для $name';
  }

  @override
  String get adminMatchFailed => 'Ошибка';

  @override
  String adminScanFailed(String name) {
    return 'Ошибка сканирования $name';
  }

  @override
  String get adminPurgeCacheFailed => 'Ошибка';

  @override
  String get adminUsersRootBadge => 'root';

  @override
  String get adminUsersAdminBadge => 'admin';

  @override
  String get adminUsersDisabledBadge => 'отключено';

  @override
  String get adminUsersEditUserTooltip => 'Редактировать пользователя';

  @override
  String get adminUsersOnlineNow => 'Сейчас онлайн';

  @override
  String adminUsersLastSeen(String time) {
    return 'Последний онлайн $time';
  }

  @override
  String get adminUsersNever => 'Никогда';

  @override
  String get adminUsersTotal => 'Всего';

  @override
  String get adminUsersNoReadingActivity => 'Нет активности чтения';

  @override
  String get adminUsersLoadingDots => 'Загрузка...';

  @override
  String get adminUsersLoadMoreSessions => 'Загрузить больше сессий';

  @override
  String get adminUsersNoRecentSessions => 'Недавние сессии';

  @override
  String get adminUsersLibraryProgress => 'Прогресс библиотеки';

  @override
  String adminUsersLoadMoreRemaining(int count) {
    return 'Загрузить больше ($count осталось)';
  }

  @override
  String adminUsersMonthsAgo(int count) {
    return '${count}mo назад';
  }

  @override
  String get adminUsersNewUser => 'Новый пользователь';

  @override
  String get adminUsersEditUser => 'Редактировать пользователя';

  @override
  String get adminUsersUsername => 'Логин';

  @override
  String get adminUsersEnterUsername => 'Введите логин';

  @override
  String get adminUsersPassword => 'Пароль';

  @override
  String get adminUsersNewPassword => 'Новый пароль';

  @override
  String get adminUsersEnterPassword => 'Введи пароль';

  @override
  String get adminUsersLeaveBlankToKeep =>
      'Оставьте пустым, чтобы сохранить текущий';

  @override
  String get adminUsersAccountType => 'Тип Аккаунта';

  @override
  String get adminUsersTypeGuest => 'Гость';

  @override
  String get adminUsersTypeUser => 'Пользователь';

  @override
  String get adminUsersTypeAdmin => 'Админ';

  @override
  String get adminUsersStatus => 'Статус';

  @override
  String get adminUsersAccountActive => 'Аккаунт активен';

  @override
  String get adminUsersAccountActiveSub =>
      'Отключенные аккаунты не могут войти';

  @override
  String get adminUsersLocked => 'Заблокировано';

  @override
  String get adminUsersLockedSub => 'Запрещает изменение пароля';

  @override
  String get adminUsersPermissions => 'Разрешения';

  @override
  String get adminUsersPermDownload => 'Скачать';

  @override
  String get adminUsersPermUpdate => 'Обновить';

  @override
  String get adminUsersPermUpdateSub =>
      'Редактировать метаданные и элементы библиотеки';

  @override
  String get adminUsersPermDelete => 'Удалить';

  @override
  String get adminUsersPermUpload => 'Загрузить';

  @override
  String get adminUsersPermExplicit => 'Явное содержимое';

  @override
  String get adminUsersLibraryAccess => 'Доступ к библиотеке';

  @override
  String get adminUsersAccessAllLibraries => 'Доступ ко всем библиотекам';

  @override
  String get adminUsersCreateUser => 'Создать пользователя';

  @override
  String get adminUsersSaveChanges => 'Сохранить изменения';

  @override
  String get adminUsersUsernameRequired => 'Требуется имя пользователя';

  @override
  String get adminUsersPickLibrary =>
      'Pick at least one library, or turn on access to all libraries';

  @override
  String get adminUsersPasswordRequired => 'Требуется пароль';

  @override
  String get adminUsersUserCreated => 'Пользователь создан';

  @override
  String get adminUsersUserUpdated => 'Пользователь обновлён';

  @override
  String get adminUsersFailedCreate => 'Не удалось создать пользователя';

  @override
  String get adminUsersFailedUpdate => 'Не удалось обновить пользователя';

  @override
  String get adminUsersThisUser => 'этот пользователь';

  @override
  String get adminUsersDeleteUserTitle => 'Удалить пользователя?';

  @override
  String adminUsersDeleteUserContent(String name) {
    return 'Окончательно удалить $name?';
  }

  @override
  String adminUsersUserDeleted(String name) {
    return '$name удален';
  }

  @override
  String get adminUsersFailedDelete => 'Не удалось удалить пользователя';

  @override
  String get adminUsersUnlinkOpenId => 'Отвязать OpenID';

  @override
  String get adminUsersUnlinkOpenIdTitle => 'Отвязать OpenID?';

  @override
  String adminUsersUnlinkOpenIdContent(String name) {
    return 'Удалить OpenID соединение для $name? Они должны войти с OpenID снова для повторной ссылки.';
  }

  @override
  String get adminUsersOpenIdUnlinked => 'OpenID отвязан';

  @override
  String get adminUsersFailedUnlinkOpenId => 'Не удалось отвязать OpenID';

  @override
  String adminUsersByAuthor(String author) {
    return 'автор: $author';
  }

  @override
  String get adminUsersListened => 'Listened';

  @override
  String get adminUsersStartedAtPosition => 'Started at position';

  @override
  String get adminUsersEndedAtPosition => 'Ended at position';

  @override
  String get adminUsersTotalDuration => 'Total duration';

  @override
  String get adminUsersStarted => 'Started';

  @override
  String get adminUsersUpdated => 'Updated';

  @override
  String get adminUsersClient => 'Клиент';

  @override
  String get adminUsersDevice => 'Устройство';

  @override
  String get adminUsersOs => 'ОС';

  @override
  String get adminUsersPlayMethod => 'Способ воспроизведения';

  @override
  String get adminUsersPlayDirect => 'Прямое воспроизведение';

  @override
  String get adminUsersPlayDirectStream => 'Direct stream';

  @override
  String get adminUsersPlayTranscode => 'Перекодирование';

  @override
  String get adminUsersPlayLocal => 'Локально';

  @override
  String get adminPodcastsCheckNewEpisodesTitle => 'Check for New Episodes';

  @override
  String get adminPodcastsCheckNewEpisodesContent =>
      'This will check RSS feeds for all podcasts and download any new episodes found (if auto-download is enabled).';

  @override
  String get adminPodcastsCheckNewEpisodesSubtitle =>
      'Scan RSS feed and download new episodes';

  @override
  String get adminPodcastsCheck => 'Check';

  @override
  String get adminPodcastsCheckingForNew => 'Checking for new episodes…';

  @override
  String get adminPodcastsCheckingForNewDots => 'Checking for new episodes...';

  @override
  String get adminPodcastsFailedCheckEpisodes => 'Failed to check episodes';

  @override
  String get adminPodcastsCheckFeedsTooltip => 'Check feeds for new episodes';

  @override
  String get adminPodcastsNoPodcastsYet => 'No podcasts yet';

  @override
  String get adminPodcastsTapPlusHint => 'Tap + to search and add shows';

  @override
  String adminPodcastsEpisodesCount(int count) {
    return '$count episodes';
  }

  @override
  String get adminPodcastsAddPodcast => 'Add Podcast';

  @override
  String get adminPodcastsCouldNotFindFeed => 'Could not find podcast feed';

  @override
  String get adminPodcastsSearchHint => 'Search for podcasts…';

  @override
  String get adminPodcastsSearchItunesHint => 'Search iTunes...';

  @override
  String adminPodcastsSearchItunesFor(String query) {
    return 'Search iTunes for \"$query\"';
  }

  @override
  String get adminPodcastsNoPodcastsFound => 'No podcasts found';

  @override
  String get adminPodcastsRelToday => 'Сегодня';

  @override
  String adminPodcastsWeeksAgo(int count) {
    return '${count}w ago';
  }

  @override
  String adminPodcastsMonthsAgo(int count) {
    return '${count}mo ago';
  }

  @override
  String adminPodcastsYearsAgo(int count) {
    return '${count}y ago';
  }

  @override
  String adminPodcastsUpdated(String when) {
    return 'Updated $when';
  }

  @override
  String get adminPodcastsGenreAll => 'All';

  @override
  String get adminPodcastsGenreArts => 'Искусство';

  @override
  String get adminPodcastsGenreComedy => 'Комедия';

  @override
  String get adminPodcastsGenreEducation => 'Образование';

  @override
  String get adminPodcastsGenreTvFilm => 'ТВ и Кино';

  @override
  String get adminPodcastsGenreMusic => 'Музыка';

  @override
  String get adminPodcastsGenreNews => 'Новости';

  @override
  String get adminPodcastsGenreReligion => 'Религия';

  @override
  String get adminPodcastsGenreScience => 'Наука';

  @override
  String get adminPodcastsGenreSports => 'Спорт';

  @override
  String get adminPodcastsGenreTechnology => 'Технология';

  @override
  String get adminPodcastsGenreBusiness => 'Бизнес';

  @override
  String get adminPodcastsGenreFiction => 'Художественная литература';

  @override
  String get adminPodcastsGenreSocietyCulture => 'Общество и Культура';

  @override
  String get adminPodcastsGenreHealthFitness => 'Здоровье и Фитнес';

  @override
  String get adminPodcastsGenreTrueCrime => 'True Crime';

  @override
  String get adminPodcastsGenreHistory => 'История';

  @override
  String get adminPodcastsGenreKidsFamily => 'Дети & Семья';

  @override
  String get adminPodcastsPodcastFallback => 'Подкаст';

  @override
  String get adminPodcastsEpisodeFallback => 'Эпизод';

  @override
  String get adminPodcastsNoFeedFound => 'No feed URL found';

  @override
  String get adminPodcastsNoFeedAvailable => 'No feed URL available';

  @override
  String adminPodcastsAddedToLibrary(String title) {
    return '$title added to library';
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
  String get adminPodcastsAdding => 'Добавляем…';

  @override
  String get adminPodcastsAddToLibrary => 'Add to Library';

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
  String get adminPodcastsSelectMultipleTooltip => 'Select multiple';

  @override
  String adminPodcastsDownloadedCount(int count) {
    return '$count downloaded';
  }

  @override
  String get adminPodcastsTabDownloaded => 'Загружено';

  @override
  String get adminPodcastsTabFeed => 'Feed';

  @override
  String get adminPodcastsTabSettings => 'Settings';

  @override
  String adminPodcastsDownloadingEpisode(String title) {
    return 'Downloading \"$title\"';
  }

  @override
  String get adminPodcastsFailedDownload => 'Не удалось загрузить';

  @override
  String get adminPodcastsDeleteEpisodeTitle => 'Удалить эпизод?';

  @override
  String adminPodcastsDeleteEpisodeContent(String title) {
    return 'Удалить \"$title\"?';
  }

  @override
  String get adminPodcastsDeleted => 'Удалено';

  @override
  String get adminPodcastsFailed => 'Ошибка';

  @override
  String get adminPodcastsDeleteEpisodesTitle => 'Удалить эпизоды?';

  @override
  String adminPodcastsDeleteEpisodesContent(int count) {
    return 'Удалить $count эпизод(ов) с сервера?';
  }

  @override
  String adminPodcastsDeletedEpisodes(int count) {
    return 'Удалено $count эпизод(ов)';
  }

  @override
  String get adminPodcastsBrowseFeedToDownload => 'Browse feed to download';

  @override
  String get adminPodcastsDownloadingDots => 'Скачивание...';

  @override
  String adminPodcastsDeleteEpisodesCount(int count) {
    return 'Удалить $count эпизод(ов)';
  }

  @override
  String adminPodcastsDownloadingCount(int count) {
    return 'Загружается $count эпизода(ов)';
  }

  @override
  String adminPodcastsDownloadEpisodesCount(int count) {
    return 'Загрузка $count эпизода(ов)';
  }

  @override
  String get adminPodcastsLookForEpisodesAfter => 'Искать эпизоды после';

  @override
  String get adminPodcastsSelectDate => 'Выберите дату';

  @override
  String get adminPodcastsMaxEpisodes => 'Максимум эпизодов для загрузки';

  @override
  String adminPodcastsNoNewEpisodesAfter(String date) {
    return 'Не найдено новых эпизодов после $date';
  }

  @override
  String adminPodcastsFoundNewEpisodes(int count) {
    return 'Найдено $count новых эпизодов(ов) - загрузка';
  }

  @override
  String get adminPodcastsFailedToCheckNew =>
      'Не удалось проверить наличие новых эпизодов';

  @override
  String get adminPodcastsCheckAndDownload => 'Проверить и загрузить';

  @override
  String get adminPodcastsMatchPodcast => 'Match Podcast';

  @override
  String get adminPodcastsMatchPodcastSubtitle =>
      'Поиск в iTunes для обновления обложки и метаданных';

  @override
  String get adminPodcastsAutoDownloadNewEpisodes =>
      'Автозагрузка новых эпизодов';

  @override
  String get adminPodcastsAutoDownloadOnSubtitle =>
      'Сервер автоматически загружает новые эпизоды';

  @override
  String get adminPodcastsAutoDownloadOffSubtitle =>
      'Новые эпизоды не загружаюся автоматически';

  @override
  String get adminPodcastsFailedAutoDownloadUpdate =>
      'Не удалось обновить настройки автозагрузки';

  @override
  String get adminPodcastsMaxEpisodesToKeep =>
      'Максимальное количество эпизодов для сохранения';

  @override
  String get adminPodcastsMaxEpisodesToKeepHelp =>
      '0 сохраняет каждый эпизод. После автозагрузки нового эпизода, Audiobookshelf удаляет самый старый эпизод, когда шоу превысит этот лимит.';

  @override
  String get adminPodcastsNoEpisodeLimit => 'No limit';

  @override
  String get adminPodcastsEpisodeLimitInvalid => 'Enter 0 or a whole number';

  @override
  String get adminPodcastsCheckSchedule => 'Check Schedule';

  @override
  String get adminPodcastsFrequency => 'Частота';

  @override
  String get adminPodcastsFreqHourly => 'Ежечасно';

  @override
  String get adminPodcastsFreqDaily => 'Ежедневно';

  @override
  String get adminPodcastsFreqWeekly => 'Еженедельно';

  @override
  String get adminPodcastsDay => 'День';

  @override
  String get adminPodcastsTime => 'Время';

  @override
  String get adminPodcastsDaySun => 'Вск';

  @override
  String get adminPodcastsDayMon => 'Пон';

  @override
  String get adminPodcastsDayTue => 'Втр';

  @override
  String get adminPodcastsDayWed => 'Срд';

  @override
  String get adminPodcastsDayThu => 'Чтв';

  @override
  String get adminPodcastsDayFri => 'Птн';

  @override
  String get adminPodcastsDaySat => 'Сбт';

  @override
  String get adminPodcastsFeedUrl => 'Feed URL';

  @override
  String get adminPodcastsBack => 'Назад ';

  @override
  String get adminPodcastsRootOnly => 'Root Only';

  @override
  String get adminPodcastsDeleting => 'Удаляется...';

  @override
  String get adminPodcastsDeleteEpisode => 'Delete Episode';

  @override
  String adminPodcastsSeasonChip(String season) {
    return 'Season $season';
  }

  @override
  String adminPodcastsEpChip(String number) {
    return 'Ep. $number';
  }

  @override
  String get adminPodcastsApplyingMatch => 'Applying match...';

  @override
  String get adminPodcastsNoResults => 'No results';

  @override
  String get adminPodcastsPodcastMatched => 'Podcast matched and updated';

  @override
  String get adminPodcastsFailedMatch => 'Failed to match podcast';

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
  String get episodeListUnknownPodcast => 'Unknown Podcast';

  @override
  String episodeListMarkedFinished(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count выпусков помечены как прослушанные',
      many: '$count выпусков помечены как прослушанные',
      few: '$count выпуска помечены как прослушанные',
      one: '$count выпуск помечен как прослушанный',
    );
    return '$_temp0';
  }

  @override
  String episodeListMarkedUnfinished(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count выпусков помечены как не прослушанные',
      many: '$count выпусков помечены как не прослушанные',
      few: '$count выпуска помечены как не прослушанные',
      one: '$count выпуск помечен как не прослушанный',
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
      'New episodes will be automatically downloaded and added to your absorbing queue when they appear on the server.';

  @override
  String get episodeListSubscribe => 'Subscribe';

  @override
  String get episodeListShowFinishedEpisodes => 'Показать завершенные эпизоды';

  @override
  String get episodeListHideFinishedEpisodes => 'Скрыть завершенные эпизоды';

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
      other: '$count выпуска',
      many: '$count выпусков',
      few: '$count выпуска',
      one: '$count выпуск',
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
  String get episodeListSubscribedChip => 'Subscribed';

  @override
  String get episodeListExplicitChip => 'Explicit';

  @override
  String get episodeListSortNewest => 'Newest';

  @override
  String get episodeListSortOldest => 'Oldest';

  @override
  String get episodeListSortBy => 'Sort episodes';

  @override
  String get episodeListSortPubDate => 'Publish date';

  @override
  String get episodeListSortTitle => 'Title';

  @override
  String get episodeListSortSeason => 'Сезон';

  @override
  String get episodeListSortEpisode => 'Episode number';

  @override
  String get episodeListSortFileName => 'Название файла';

  @override
  String get episodeListSortReverseHint => 'Tap again to reverse the order';

  @override
  String episodeListAddedToAbsorbing(String title) {
    return 'Added \"$title\" to Absorbing';
  }

  @override
  String get episodeDetailEpisodeFallback => 'Episode';

  @override
  String get episodeDetailMarkedNotFinished => 'Marked as not finished';

  @override
  String get episodeDetailMarkedFinishedNice =>
      'Отметить как прослушано - круто!';

  @override
  String get episodeDetailMarkAbsorbedContent =>
      'This will set your progress to 100% for this episode.';

  @override
  String get episodeDetailResetProgressContent =>
      'This will erase all progress for this episode and set it back to the beginning. This can\'t be undone.';

  @override
  String get episodeDetailToday => 'Сегодня';

  @override
  String get episodeDetailYesterday => 'Вчера';

  @override
  String episodeDetailDaysAgo(int count) {
    return '$countд назад';
  }

  @override
  String episodeDetailWeeksAgo(int count) {
    return '${count}w ago';
  }

  @override
  String episodeDetailDurationHm(int hours, int minutes) {
    return '$hoursч $minutesм';
  }

  @override
  String episodeDetailDurationM(int minutes) {
    return '$minutesм';
  }

  @override
  String get episodeDetailResume => 'Продолжить';

  @override
  String get episodeDetailPlayEpisode => 'Play Episode';

  @override
  String episodeDetailEpisodeNumber(String number) {
    return 'Episode $number';
  }

  @override
  String episodeDetailSeasonNumber(String number) {
    return 'Сезон $number';
  }

  @override
  String get editMetadataUpdatedFromMatch => 'Metadata updated from match';

  @override
  String editMetadataConfirmMatch(String title) {
    return 'This will update the server metadata for this book using:\n\n\"$title\"\n\nAll fields and the cover will be overwritten on the server.';
  }

  @override
  String editMetadataConfirmMatchWithAuthor(String title, String author) {
    return 'This will update the server metadata for this book using:\n\n\"$title\" by $author\n\nAll fields and the cover will be overwritten on the server.';
  }

  @override
  String get seriesBooksFindMissingTitle => 'Find Missing Books';

  @override
  String get seriesBooksFindMissingContent =>
      'This searches Audible to find books in this series that may be missing from your library.\n\nBooks are matched by ASIN first (depending on whether your server has ASINs for its books), then falls back to title matching. Results may not be perfectly accurate.';

  @override
  String get seriesBooksCouldNotFindOnAudible =>
      'Could not find this series on Audible';

  @override
  String seriesBooksMarkAllNotFinishedContent(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'This will clear the finished status for all $count books in this series.',
      one: 'This will clear the finished status for the 1 book in this series.',
    );
    return '$_temp0';
  }

  @override
  String seriesBooksFullyAbsorbContent(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'This will mark all $count books in this series as finished.',
      one: 'This will mark the 1 book in this series as finished.',
    );
    return '$_temp0';
  }

  @override
  String get seriesBooksUnmarkAll => 'Unmark All';

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
      other: '$count книги',
      many: '$count книг',
      few: '$count книги',
      one: '$count книга',
    );
    return '$_temp0';
  }

  @override
  String get seriesBooksDone => 'Готово';

  @override
  String get seriesBooksExplicitBadge => 'E';

  @override
  String get expandedCardStreaming => 'Трансляция';

  @override
  String get expandedCardDeviceFallback => 'Устройство';

  @override
  String bookmarksScreenPositionInBook(String position, String bookTitle) {
    return '$position in $bookTitle';
  }

  @override
  String get bookmarksScreenClose => 'Закрыть';

  @override
  String get bookmarksScreenSortNewest => 'Newest';

  @override
  String get bookmarksScreenSortPosition => 'Position';

  @override
  String statsScreenStreakDays(int count) {
    return '$countд';
  }

  @override
  String statsScreenSessionCountOne(int count) {
    return '$count сессия';
  }

  @override
  String statsScreenSessionCountOther(int count) {
    return '$count сессий';
  }

  @override
  String get statsScreenDayMon => 'Пон';

  @override
  String get statsScreenDayTue => 'Втр';

  @override
  String get statsScreenDayWed => 'Срд';

  @override
  String get statsScreenDayThu => 'Чтв';

  @override
  String get statsScreenDayFri => 'Птн';

  @override
  String get statsScreenDaySat => 'Сбт';

  @override
  String get statsScreenDaySun => 'Вск';

  @override
  String statsScreenDurationHm(int h, int m) {
    return '$hч $mм';
  }

  @override
  String statsScreenDurationM(int m) {
    return '$mм';
  }

  @override
  String get statsScreenDurationLessThanMin => '<1м';

  @override
  String get statsScreenDurationZero => '0м';

  @override
  String statsScreenDurationShortH(int h) {
    return '$hч';
  }

  @override
  String statsScreenDurationShortM(int m) {
    return '$mм';
  }

  @override
  String get statsScreenCouldNotLoadItem => 'Не удалось загрузить элемент';

  @override
  String get statsScreenCouldNotFindEpisode => 'Не удалось найти эпизод';

  @override
  String statsScreenByAuthor(String author) {
    return 'от $author';
  }

  @override
  String get statsScreenListened => 'Listened';

  @override
  String get sessionEditTitle => 'Edit session';

  @override
  String get sessionDayLabel => 'День';

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
  String get statsScreenStartedAtPosition => 'Started at position';

  @override
  String get statsScreenEndedAtPosition => 'Ended at position';

  @override
  String get statsScreenTotalDuration => 'Total duration';

  @override
  String get statsScreenStarted => 'Started';

  @override
  String get statsScreenUpdated => 'Updated';

  @override
  String get statsScreenClient => 'Client';

  @override
  String get statsScreenDevice => 'Устройство';

  @override
  String get statsScreenOs => 'ОС';

  @override
  String get statsScreenPlayMethod => 'Способ воспроизведения';

  @override
  String get statsScreenLoading => 'Загрузка...';

  @override
  String get statsScreenJumpToStart => 'Jump to start';

  @override
  String get statsScreenJumpToEnd => 'Jump to end';

  @override
  String get statsScreenPlayMethodDirect => 'Direct play';

  @override
  String get statsScreenPlayMethodDirectStream => 'Direct stream';

  @override
  String get statsScreenPlayMethodTranscode => 'Transcode';

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
  String get statsScreenMonthJan => 'Янв';

  @override
  String get statsScreenMonthFeb => 'Фев';

  @override
  String get statsScreenMonthMar => 'Мар';

  @override
  String get statsScreenMonthApr => 'Апр';

  @override
  String get statsScreenMonthMay => 'Май';

  @override
  String get statsScreenMonthJun => 'Июн';

  @override
  String get statsScreenMonthJul => 'Июл';

  @override
  String get statsScreenMonthAug => 'Авг';

  @override
  String get statsScreenMonthSep => 'Сен';

  @override
  String get statsScreenMonthOct => 'Окт';

  @override
  String get statsScreenMonthNov => 'Ноя';

  @override
  String get statsScreenMonthDec => 'Дек';

  @override
  String get upcomingReleasesTitle => 'Upcoming Releases';

  @override
  String get upcomingReleasesRescanTitle => 'Rescan?';

  @override
  String upcomingReleasesRescanContent(int days) {
    return 'These results are $days days old. Release dates may have changed - would you like to rescan?';
  }

  @override
  String get upcomingReleasesNotNow => 'Не сейчас';

  @override
  String get upcomingReleasesRescan => 'Пересканировать';

  @override
  String get upcomingReleasesRescanReleaseDate => 'Rescan Release Date';

  @override
  String get upcomingReleasesRescanning => 'Пересканирование...';

  @override
  String upcomingReleasesUpdatedWithDate(String date) {
    return 'Updated - $date';
  }

  @override
  String get upcomingReleasesNoReleaseDateFound => 'No release date found';

  @override
  String get upcomingReleasesRescanFailed => 'Rescan failed';

  @override
  String get upcomingReleasesRemoveFromList => 'Remove from list';

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
  String get upcomingReleasesScannedToday => '(scanned today)';

  @override
  String get upcomingReleasesScannedYesterday => '(scanned yesterday)';

  @override
  String upcomingReleasesScannedDaysAgo(int days) {
    return '(scanned $days days ago)';
  }

  @override
  String upcomingReleasesUpcomingCount(int count) {
    return '$count upcoming';
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
  String get upcomingReleasesBadgeUpcoming => 'UPCOMING';

  @override
  String get upcomingReleasesBadgeAdded => 'ADDED';

  @override
  String get upcomingReleasesBadgeMissing => 'MISSING';

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
      other: '$count годов',
      many: '$count лет',
      few: '$count года',
      one: '$count год',
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
      other: '$count книги',
      many: '$count книг',
      few: '$count книги',
      one: '$count книга',
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
  String get libraryScreenUnknownTitle => 'Unknown Title';

  @override
  String get playlistDetailDefaultName => 'Playlist';

  @override
  String playlistDetailItemCount(int count) {
    return '$count items';
  }

  @override
  String get playlistDetailUnfinished => 'Unfinished';

  @override
  String get playlistDetailRemoveFromPlaylist => 'Remove from playlist';

  @override
  String get playlistDetailDone => 'Done';

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
  String smartScopeBookCount(int count) {
    return 'Smart Scope · $count books';
  }

  @override
  String get smartScopeNew => 'New Smart Scope';

  @override
  String get smartScopeNewSubtitle =>
      'Save a set of filters as a list that keeps itself up to date';

  @override
  String get smartScopeEditTitle => 'Edit Smart Scope';

  @override
  String get smartScopeIcon => 'Icon';

  @override
  String get smartScopePublic => 'Visible to all users';

  @override
  String get smartScopeKobo => 'Sync to Kobo';

  @override
  String get smartScopeRules => 'Rules';

  @override
  String get smartScopeMatchAll => 'Match all';

  @override
  String get smartScopeMatchAny => 'Match any';

  @override
  String get smartScopeAddRule => 'Add rule';

  @override
  String get smartScopeAddGroup => 'Add group';

  @override
  String get smartScopeGroup => 'Group';

  @override
  String get smartScopeStartFrom => 'Start from';

  @override
  String get smartScopeFromScratch => 'Build from scratch';

  @override
  String get smartScopeTplHasSeries => 'Has a series';

  @override
  String get smartScopeTplRecent => 'Added recently';

  @override
  String get smartScopeTplPdf => 'PDF only';

  @override
  String get smartScopeTplNoGenres => 'No genres';

  @override
  String get smartScopeTplEpub => 'EPUB only';

  @override
  String get smartScopeCounting => 'Counting...';

  @override
  String get smartScopeSort => 'Default sort';

  @override
  String get smartScopeAddSort => 'Add sort level';

  @override
  String get smartScopeSortNone => 'No sort set, so books sort by title.';

  @override
  String get smartScopeAscending => 'Ascending';

  @override
  String get smartScopeDescending => 'Descending';

  @override
  String get smartScopeDelete => 'Delete Smart Scope';

  @override
  String get smartScopeSaveFailed => 'Couldn\'t save the Smart Scope';

  @override
  String get smartScopeDeleteFailed => 'Couldn\'t delete the Smart Scope';

  @override
  String get smartScopeLoadFailed => 'Couldn\'t load the Smart Scope';

  @override
  String get smartScopeUnsupportedRule =>
      'This rule can only be changed on the BookOrbit web. It\'s kept as it is.';

  @override
  String get smartScopeAnd => 'and';

  @override
  String get smartScopeDays => 'days';

  @override
  String get smartScopeWeeks => 'weeks';

  @override
  String get smartScopeMonths => 'months';

  @override
  String get smartScopePickDate => 'Pick a date';

  @override
  String get smartScopeAddValue => 'Add a value';

  @override
  String get smartScopeValue => 'Value';

  @override
  String get smartScopeCustomFields => 'Custom fields';

  @override
  String get smartScopeAnyProvider => 'Any provider';

  @override
  String get smartScopeScoreOutstanding => 'Outstanding';

  @override
  String get smartScopeScoreGood => 'Good';

  @override
  String get smartScopeScoreFair => 'Fair';

  @override
  String get smartScopeScorePoor => 'Poor';

  @override
  String get smartScopeMb => 'MB';

  @override
  String get smartScopeMaxValues => 'Up to 20 values';

  @override
  String get scopeFieldTitle => 'Title';

  @override
  String get scopeFieldAuthor => 'Author';

  @override
  String get scopeFieldSeries => 'Series';

  @override
  String get scopeFieldSeriesIndex => 'Series number';

  @override
  String get scopeFieldGenre => 'Genre';

  @override
  String get scopeFieldTag => 'Tag';

  @override
  String get scopeFieldReadStatus => 'Read status';

  @override
  String get scopeFieldReadProgress => 'Reading progress';

  @override
  String get scopeFieldRating => 'Your rating';

  @override
  String get scopeFieldFormat => 'Format';

  @override
  String get scopeFieldLibrary => 'Library';

  @override
  String get scopeFieldCollection => 'Collection';

  @override
  String get scopeFieldPublisher => 'Publisher';

  @override
  String get scopeFieldLanguage => 'Language';

  @override
  String get scopeFieldPublishedDate => 'Published date';

  @override
  String get scopeFieldPublishedYear => 'Published year';

  @override
  String get scopeFieldAddedAt => 'Date added';

  @override
  String get scopeFieldStartedAt => 'Date started';

  @override
  String get scopeFieldFinishedAt => 'Date finished';

  @override
  String get scopeFieldPageCount => 'Page count';

  @override
  String get scopeFieldFileSize => 'File size';

  @override
  String get scopeFieldCommunityRating => 'Community rating';

  @override
  String get scopeFieldCommunityRatingCount => 'Community review count';

  @override
  String get scopeFieldMetadataScore => 'Metadata score';

  @override
  String get scopeFieldIsbn => 'ISBN';

  @override
  String get scopeFieldDescription => 'Description';

  @override
  String get scopeFieldCover => 'Cover';

  @override
  String get scopeFieldAudioCover => 'Audiobook cover';

  @override
  String get scopeFieldFileAvailability => 'File availability';

  @override
  String get scopeFieldLockStatus => 'Lock status';

  @override
  String get scopeFieldSeriesStatus => 'Series status';

  @override
  String get scopeSortUpdatedAt => 'Date updated';

  @override
  String get scopeSortLastReadAt => 'Last read';

  @override
  String get scopeSortRandom => 'Random';

  @override
  String get scopeOpContains => 'contains';

  @override
  String get scopeOpNotContains => 'does not contain';

  @override
  String get scopeOpStartsWith => 'starts with';

  @override
  String get scopeOpEndsWith => 'ends with';

  @override
  String get scopeOpEq => 'is';

  @override
  String get scopeOpNotEq => 'is not';

  @override
  String get scopeOpIsEmpty => 'is empty';

  @override
  String get scopeOpIsNotEmpty => 'is not empty';

  @override
  String get scopeOpGt => 'greater than';

  @override
  String get scopeOpGte => 'at least';

  @override
  String get scopeOpLt => 'less than';

  @override
  String get scopeOpLte => 'at most';

  @override
  String get scopeOpBetween => 'between';

  @override
  String get scopeOpIncludesAny => 'includes any of';

  @override
  String get scopeOpIncludesAll => 'includes all of';

  @override
  String get scopeOpExcludesAll => 'excludes all of';

  @override
  String get scopeOpBefore => 'before';

  @override
  String get scopeOpAfter => 'after';

  @override
  String get scopeOpWithinLast => 'within the last';

  @override
  String get scopeOpIsMissing => 'is missing';

  @override
  String get scopeOpIsPresent => 'is present';

  @override
  String get scopeOpIsUnread => 'is unread';

  @override
  String get scopeOpIsInProgress => 'is in progress';

  @override
  String get scopeOpIsFinished => 'is finished';

  @override
  String get scopeOpIsLocked => 'is locked';

  @override
  String get scopeOpIsUnlocked => 'is unlocked';

  @override
  String get scopeOpIsUpNext => 'is up next';

  @override
  String get scopeOpIsTrue => 'is yes';

  @override
  String get scopeOpIsFalse => 'is no';

  @override
  String smartScopeMatchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count books match',
      one: '1 book matches',
      zero: 'No books match',
    );
    return '$_temp0';
  }

  @override
  String smartScopeDeleteConfirm(String name) {
    return 'Delete \"$name\"? This can\'t be undone.';
  }

  @override
  String collectionDetailBookCount(int count) {
    return '$count books';
  }

  @override
  String get collectionDetailDone => 'Готово';

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
    return 'All ($count)';
  }

  @override
  String get audibleSeriesSearching => 'Searching Audible...';

  @override
  String get audibleSeriesCompleteSeries => 'You have the complete series!';

  @override
  String get audibleSeriesNoUpcoming => 'No upcoming releases found';

  @override
  String get audibleSeriesUpcomingBadge => 'UPCOMING';

  @override
  String get audibleSeriesAbridged => 'Abridged';

  @override
  String get audibleSeriesRegionTitle => 'Audible Region';

  @override
  String get audibleSeriesOpenOnAudible => 'Open on Audible';

  @override
  String get audibleSeriesAddToCalendar => 'Add to Calendar';

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
  String get authorBooksGroupBySeries => 'Group by series';

  @override
  String get authorBooksList => 'Список';

  @override
  String get authorBooksGrid => 'Сетка';

  @override
  String authorBooksBookCount(int count) {
    return '$count books';
  }

  @override
  String get metadataLookupCover => 'Обложка';

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
  String get equalizerPresetFlat => 'Flat';

  @override
  String get equalizerPresetVoiceBoost => 'Голосовое Усиление';

  @override
  String get equalizerPresetBassBoost => 'Усиление Басов';

  @override
  String get equalizerPresetTrebleBoost => 'Усиление Высоких Частот';

  @override
  String get equalizerPresetPodcast => 'Подкаст';

  @override
  String get equalizerPresetAudiobook => 'Аудиокнига';

  @override
  String get equalizerPresetReduceNoise => 'Снижение шума';

  @override
  String get equalizerPresetLoudness => 'Громкость';

  @override
  String equalizerEditingSavedNamed(String title) {
    return 'Editing saved EQ for \"$title\"';
  }

  @override
  String get equalizerEditingSavedGeneric => 'Editing saved EQ';

  @override
  String get equalizerPerBookEq => 'Per-book EQ';

  @override
  String get notesDeleteNoteQuestion => 'Delete note?';

  @override
  String notesDeleteNoteContent(String title) {
    return 'Delete \"$title\"?';
  }

  @override
  String get notesExport => 'Export';

  @override
  String get notesNewNote => 'New note';

  @override
  String get librarySortFilterUpcomingReleases => 'Scan Series';

  @override
  String get librarySortFilterMatchAllAuthorsSubtitle =>
      'Fetch a photo and bio for every author from the metadata provider';

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
  String get sleepTimerSheetRewindOnSleep => 'Rewind on sleep';

  @override
  String get sleepTimerSheetShake => 'Shake';

  @override
  String sleepTimerSheetAddsMinutes(int minutes) {
    return 'Adds $minutes min';
  }

  @override
  String get sleepTimerSheetAddsOneChapter => 'Adds 1 chapter';

  @override
  String get sleepTimerSheetResetsToFull => 'Resets to full duration';

  @override
  String get sleepTimerSheetTabSpecificChapter => 'Chapter';

  @override
  String get sleepTimerSheetSpecificNoChapters => 'No chapters available';

  @override
  String sleepTimerSheetSpecificChapterFallback(int number) {
    return 'Chapter $number';
  }

  @override
  String get sleepTimerSheetSpecificPassedShort => 'passed';

  @override
  String get sleepTimerSheetSpecificStart => 'Chapter Start';

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
  String get playlistPickerPlaylistFallback => 'Playlist';

  @override
  String playlistPickerNameWithCount(String name, int count) {
    return '$name ($count)';
  }

  @override
  String get cardChaptersPlayFromChapterTitle => 'Play from chapter?';

  @override
  String cardChaptersPlayFromChapterContent(String title) {
    return 'Start playing from \"$title\"?';
  }

  @override
  String get cardChaptersPlay => 'Play';

  @override
  String get absorbingSharedToday => 'Сегодня';

  @override
  String get absorbingSharedYesterday => 'Вчера';

  @override
  String get absorbingSharedMonday => 'Понедельник';

  @override
  String get absorbingSharedTuesday => 'Вторник';

  @override
  String get absorbingSharedWednesday => 'Среда';

  @override
  String get absorbingSharedThursday => 'Четверг';

  @override
  String get absorbingSharedFriday => 'Пятница';

  @override
  String get absorbingSharedSaturday => 'Суббота';

  @override
  String get absorbingSharedSunday => 'Воскресенье';

  @override
  String get absorbingSharedAm => 'AM';

  @override
  String get absorbingSharedPm => 'PM';

  @override
  String sectionDetailAddedToAbsorbing(String title) {
    return 'Added \"$title\" to Absorbing';
  }

  @override
  String get sectionDetailDoneBadge => 'Done';

  @override
  String get homeCustomizeAddGenreTitle => 'Add Genre Section';

  @override
  String get homeCustomizeAddGenreSubtitle =>
      'Pick a genre to show on your home screen';

  @override
  String get homeSectionDoneBadge => 'Готово';

  @override
  String get tipsSheetQuickBookmarksTitle => 'Quick Bookmarks';

  @override
  String get tipsSheetQuickBookmarksDesc =>
      'Long-press the bookmark button on any card to instantly drop a bookmark at your current position without opening the bookmark sheet.';

  @override
  String get tipsSheetCoverPlayPauseTitle => 'Cover Play/Pause';

  @override
  String get tipsSheetCoverPlayPauseDesc =>
      'Коснись обложки на любой карте для игры или паузы. Включи это в Настройках в разделе Карты Поглощение. Тусклый значок паузы отображается при воспроизведении, чтобы ты знал, что обложка кнопка.';

  @override
  String get tipsSheetFullScreenPlayerTitle => 'Full Screen Player';

  @override
  String get tipsSheetFullScreenPlayerDesc =>
      'Swipe up on any absorbing card to open the full screen player. Swipe down to dismiss it.';

  @override
  String get tipsSheetQuickAddAbsorbingTitle => 'Quick Add to Absorbing';

  @override
  String get tipsSheetQuickAddAbsorbingDesc =>
      'Swipe right on any book in a list sheet (series, author, search results) to instantly add it to your absorbing queue.';

  @override
  String get tipsSheetShakeExtendSleepTitle => 'Shake to Extend Sleep';

  @override
  String get tipsSheetShakeExtendSleepDesc =>
      'If you have a sleep timer running and shake your phone, it\'ll add extra minutes. Configure the amount in Settings under Sleep Timer.';

  @override
  String get tipsSheetSeriesNavigationTitle => 'Series Navigation';

  @override
  String get tipsSheetSeriesNavigationDesc =>
      'Tap the series name in any book\'s detail popup to see all books in the series, sorted in reading order with sequence badges on each cover.';

  @override
  String get tipsSheetSwipeBetweenBooksTitle => 'Swipe Between Books';

  @override
  String get tipsSheetSwipeBetweenBooksDesc =>
      'Проведи пальцем влево и вправо на экране Поглощение для переключения между текущих книг. В режиме ручной очереди карты действуют как очередь, так что следующая автоматически играет, когда текущая карта закончится.';

  @override
  String get tipsSheetTapToSeekTitle => 'Tap to Seek';

  @override
  String get tipsSheetTapToSeekDesc =>
      'Tap anywhere on the chapter or book progress bar to jump directly to that position. You can also drag the bars for fine-grained control.';

  @override
  String get tipsSheetSpeedAdjustedTimeTitle => 'Speed-Adjusted Time';

  @override
  String get tipsSheetSpeedAdjustedTimeDesc =>
      'Every time shown - position, remaining, chapters, bookmarks - adjusts to your playback speed. Listening at 1.5x? The times shown reflect how long they\'ll actually take you.';

  @override
  String get tipsSheetPlaybackHistoryTitle => 'Playback History';

  @override
  String get tipsSheetPlaybackHistoryDesc =>
      'Tap the History button on any card to see a timeline of every play, pause, seek, and speed change. Tap any event to jump back to that position.';

  @override
  String get tipsSheetAutoRewindTitle => 'Авто-перемотка';

  @override
  String get tipsSheetAutoRewindDesc =>
      'When you resume after a pause, Absorb automatically rewinds a few seconds so you don\'t lose your place. The rewind amount scales with how long you were away. Configure it in Settings.';

  @override
  String get tipsSheetSeriesQueueModeTitle => 'Series Queue Mode';

  @override
  String get tipsSheetSeriesQueueModeDesc =>
      'When you finish a book that\'s part of a series, Absorb can automatically play the next book. Set queue mode to \"Series\" in Settings.';

  @override
  String get tipsSheetOfflineModeTitle => 'Офлайн Режим';

  @override
  String get tipsSheetOfflineModeDesc =>
      'Tap the green cloud at the top of the Absorbing screen to go offline. Syncing stops, nothing uses data and only your downloads show. The cloud goes orange while you\'re offline, and tapping it again reconnects. A red cloud means you\'ve been signed out: your downloads still play, and what you listen to syncs once you sign back in. Holding a tab can switch offline mode too, under Tab hold shortcuts in Settings.';

  @override
  String get tipsSheetUpcomingReleasesTitle => 'Предстоящие Релизы';

  @override
  String get tipsSheetUpcomingReleasesDesc =>
      'On the Series tab, tap the tab again to open its sort and filter sheet, then choose Upcoming Releases to see new and upcoming books across your series, sorted by release date.';

  @override
  String get tipsSheetPerBookEqTitle => 'Per-Book Equalizer';

  @override
  String get tipsSheetPerBookEqDesc =>
      'Each book remembers its own equalizer settings. Tweak EQ once for a sci-fi epic and the next time you play it, it sounds the same.';

  @override
  String get tipsSheetPerBookSpeedTitle => 'Per-Book Speed';

  @override
  String get tipsSheetPerBookSpeedDesc =>
      'Playback speed is saved per book. Run nonfiction at 1.5x and dramatic fiction at 1.0x without setting it every time.';

  @override
  String get tipsSheetAutoSleepWindowTitle => 'Auto Sleep Window';

  @override
  String get tipsSheetAutoSleepWindowDesc =>
      'Pick the hours you usually fall asleep and the sleep timer will start itself when you begin listening in that window.';

  @override
  String get tipsSheetSleepFadeChimeTitle => 'Sleep Fade and Chime';

  @override
  String get tipsSheetSleepFadeChimeDesc =>
      'When the sleep timer ends, audio gradually fades out and an optional chime plays so it doesn\'t cut off mid-sentence.';

  @override
  String get tipsSheetCarModeTitle => 'Режим \"В автомобиле\"';

  @override
  String get tipsSheetCarModeDesc =>
      'Tap the car icon to switch to giant-button mode designed for safer use while driving.';

  @override
  String get tipsSheetAudibleSeriesTitle => 'Audible Series Discovery';

  @override
  String get tipsSheetAudibleSeriesDesc =>
      'Open a series and use the overflow menu (the three dots) to pull the full series list from Audible, including missing entries and books you haven\'t started.';

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
      'Keep your settings, per-book speeds and Absorbing order in step across devices through your own WebDAV server. Set it up in Settings under Backup and sync.';

  @override
  String get tipsSheetNavLongPressTitle => 'Long-Press the Bottom Tabs';

  @override
  String get tipsSheetNavLongPressDesc =>
      'Hold the Home tab to switch libraries from any page. Hold the Library tab to jump straight into search.';

  @override
  String get bookCardUnknownTitle => 'Unknown Title';

  @override
  String get bookCardExplicitBadge => 'E';

  @override
  String get bookCardDone => 'Готово';

  @override
  String get bookCardSaved => 'Saved';

  @override
  String get episodeRowEpisode => 'Episode';

  @override
  String get episodeRowToday => 'Сегодня';

  @override
  String get episodeRowYesterday => 'Yesterday';

  @override
  String episodeRowDaysAgo(int count) {
    return '${count}d ago';
  }

  @override
  String episodeRowWeeksAgo(int count) {
    return '${count}w ago';
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
  String get librarySearchResultsDone => 'Готово';

  @override
  String get librarySearchResultsSaved => 'Saved';

  @override
  String librarySearchResultsSequence(String number) {
    return '#$number';
  }

  @override
  String get librarySearchResultsUnknownSeries => 'Unknown Series';

  @override
  String get librarySearchResultsUnknownEpisode => 'Unknown Episode';

  @override
  String librarySearchResultsBookCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count книги',
      many: '$count книг',
      few: '$count книги',
      one: '$count книга',
    );
    return '$_temp0';
  }

  @override
  String get libraryGridTilesExplicitBadge => 'E';

  @override
  String get libraryGridTilesDone => 'Готово';

  @override
  String get libraryGridTilesSaved => 'Saved';

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
      other: '$count книги',
      many: '$count книг',
      few: '$count книги',
      one: '$count книга',
    );
    return '$_temp0';
  }

  @override
  String get cardProgressFineScrubbing => 'Fine Scrubbing';

  @override
  String get cardProgressQuarterSpeed => 'Quarter Speed';

  @override
  String get cardProgressHalfSpeed => 'Half Speed';

  @override
  String cardProgressChapterPrefix(String number) {
    return 'Глава $number';
  }

  @override
  String get cardEdgeProgressFineScrubbing => 'Fine Scrubbing';

  @override
  String get cardEdgeProgressQuarterSpeed => 'Quarter Speed';

  @override
  String get cardEdgeProgressHalfSpeed => 'Half Speed';

  @override
  String get authSessionExpired => 'Session expired. Please log in again.';

  @override
  String authCannotReachServer(String url) {
    return 'Не удается подключиться к серверу $url';
  }

  @override
  String get authInvalidUsernameOrPassword => 'Неверный логин или пароль';

  @override
  String get authInvalidApiKey => 'Invalid API key';

  @override
  String get authLoginFailedDetail =>
      'Login failed - check your server address and credentials';

  @override
  String get authUnexpectedServerResponse => 'Unexpected server response';

  @override
  String get authSsoUnexpectedResponse => 'SSO вернул неожиданный ответ';

  @override
  String get authSwitchedToLocalServer => 'Переключено на локальный сервер';

  @override
  String get authSwitchedToRemoteServer => 'Переключено на удаленный сервер';

  @override
  String get lpDeletedFinishedDownload => 'Deleted finished download';

  @override
  String lpSubscribedPodcastDownloading(String showTitle, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count new episodes downloading',
      one: '1 new episode downloading',
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
  String get statsWeekStartsOn => 'Начало недели в';

  @override
  String get episodeListNewEpisodePosition => 'New episode position';

  @override
  String get episodeListPositionTop => 'Top of queue';

  @override
  String get episodeListPositionSecond => 'Second in queue';

  @override
  String get episodeListPositionEnd => 'End of queue';

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
  String get downloadNotifProgressChannelName => 'Прогресс загрузки';

  @override
  String get downloadNotifProgressChannelDesc =>
      'Показывает прогресс во время скачивания аудиокниги';

  @override
  String get downloadNotifAlertChannelName => 'Download Alerts';

  @override
  String get downloadNotifAlertChannelDesc =>
      'Notifications when downloads finish or fail';

  @override
  String get downloadNotifDownloadingTitle => 'Downloading…';

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
  String get downloadNotifStartingLabel => 'Starting…';

  @override
  String get downloadNotifCompleteTitle => 'Download Complete';

  @override
  String downloadNotifCompleteBody(String title) {
    return '$title is ready to listen offline';
  }

  @override
  String get downloadNotifFailedTitle => 'Download Failed';

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
  String get androidAutoTabContinue => 'Продолжить';

  @override
  String get androidAutoTabLibrary => 'Библиотека';

  @override
  String get androidAutoTabDownloads => 'Downloads';

  @override
  String get settingsSearchHint => 'Search settings...';

  @override
  String get settingsSearchNoResults => 'No matching settings';

  @override
  String get carConnectAutoplay => 'Start playback when Android Auto connects';

  @override
  String get carConnectAutoplayIos => 'Start playback when CarPlay connects';

  @override
  String get carConnectAutoplayOnSubtitle =>
      'The last book you were listening to starts by itself when the car connects';

  @override
  String get carConnectAutoplayOffSubtitle =>
      'Playback waits for you to press play';

  @override
  String get sectionCar => 'Android Auto';

  @override
  String get sectionCarIos => 'CarPlay';

  @override
  String get sectionSiri => 'Siri';

  @override
  String get siriUseWithSiri => 'Use with Siri';

  @override
  String get siriStatusOn =>
      'On. Siri can find and play your books and podcasts by name.';

  @override
  String get siriStatusAsk =>
      'Let Siri find and play your books and podcasts by name.';

  @override
  String get siriStatusOff =>
      'Siri is turned off for Absorb. Turn it on in iOS Settings.';

  @override
  String get siriAllow => 'Allow';

  @override
  String get siriOpenSettings => 'Open Settings';

  @override
  String get siriThingsToSay => 'Things to say';

  @override
  String get siriExamples =>
      '\"Play [book title] on Absorb\"\n\"Play [series name] on Absorb\"\n\"Play something by [author] on Absorb\"\n\"Play the latest episode of [podcast] on Absorb\"\n\"Resume Absorb\"\n\"Skip back in Absorb\"\n\"Next chapter in Absorb\"\n\"Set a sleep timer in Absorb\"\n\"Add a bookmark in Absorb\"\n\"What am I listening to in Absorb\"';

  @override
  String get siriShortcutsNote =>
      'Resume, pause, skips, chapters, the sleep timer, bookmarks and what\'s playing work even without this permission. They are also in the Shortcuts app for automations and the Action button.';

  @override
  String get carBookOrder => 'Book order in the car';

  @override
  String get carBookOrderReverse => 'Reverse book order';

  @override
  String get carBookOrderReverseSubtitle => 'Z to A, or oldest added first';

  @override
  String get carPodcastOrder => 'Podcast order in the car';

  @override
  String get carEpisodesOldestFirst => 'Oldest episodes first';

  @override
  String get carEpisodesOldestFirstSubtitle =>
      'For shows you listen to from the start';

  @override
  String get androidAutoCatBooks => 'Книги';

  @override
  String get androidAutoCatSeries => 'Серии';

  @override
  String get androidAutoCatAuthors => 'Авторы';

  @override
  String get androidAutoCatCollections => 'Collections';

  @override
  String get androidAutoCatPlaylists => 'Playlists';

  @override
  String get showTipsAgain => 'Показать подсказки снова';

  @override
  String get showTipsAgainSubtitle =>
      'Bring back feature tips you\'ve dismissed';

  @override
  String get tipsRestored => 'Подсказки восстановлены';

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
  String get authorName => 'Имя';

  @override
  String get authorImage => 'Изображение автора';

  @override
  String get authorRemoveImage => 'Удалить изображение';

  @override
  String get authorRemoveImageTitle => 'Удалить изображение автора?';

  @override
  String get authorRemoveImageConfirm => 'Это удаляет изображение на сервере.';

  @override
  String get authorImageRemoved => 'Изображение удалено';

  @override
  String get authorImageFailed => 'Не удалось обновить изображение автора';

  @override
  String get authorUpdated => 'Автор обновлён';

  @override
  String get authorUpdateFailed => 'Не удалось обновить автора';

  @override
  String get authorMatched => 'Author updated from match';

  @override
  String get authorNoMatchFound => 'No match found';

  @override
  String authorMergedInto(String name) {
    return 'Merged into $name';
  }

  @override
  String get authorQuickMatchHint =>
      'Pull name, ASIN, description and image from Audible for the chosen region.';

  @override
  String get region => 'Region';

  @override
  String get editTabDetails => 'Подробности';

  @override
  String get editTabCover => 'Обложка';

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
  String get chapterTimeHintFull => 'ЧЧ:ММ:СС или секунд';

  @override
  String get chapterInvalidTime => 'Неверное время';

  @override
  String get chapterLocked => 'Глава заблокирована';

  @override
  String get chapterAllLocked => 'Все главы заблокированы';

  @override
  String chapterTrackTitle(int number) {
    return 'Трек $number';
  }

  @override
  String get chapterNoAudioForPosition => 'Для этой позиции нет аудио';

  @override
  String get chapterCouldNotPlayPreview => 'Предпросмотр не удался';

  @override
  String chapterStartSetTo(String time) {
    return 'Начало установлено на $time';
  }

  @override
  String get chapterAddNumberedTitle => 'Добавить нумерацию глав';

  @override
  String chapterNextPreview(String first, String second) {
    return 'Next: \"$first\", \"$second\", ...';
  }

  @override
  String get chapterHowMany => 'How many chapters';

  @override
  String get add => 'Добавить';

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
  String get chapterReadAlongOnly =>
      'This book\'s chapters come from its read along ebook and can\'t be edited';

  @override
  String get ok => 'ОК';

  @override
  String get chapterSaveButton => 'Save chapters';

  @override
  String get chapterAddHint => 'Add chapter (e.g. \"Chapter 01\")';

  @override
  String get chapterAddTooltip => 'Add chapter(s)';

  @override
  String get chapterRemoveAll => 'Remove All';

  @override
  String get chapterShiftTimes => 'Shift Times';

  @override
  String get chapterFromTracks => 'Из треков';

  @override
  String get chapterLookup => 'Lookup';

  @override
  String get chapterShowSeconds => 'Показывать секунды';

  @override
  String chapterWindowMinutes(int minutes) {
    return '$minutes мин';
  }

  @override
  String get chapterLoopCut => 'Loop the cut';

  @override
  String get chapterFindStart => 'Найти начало';

  @override
  String get chapterFindStartListening => 'Listening around the marker';

  @override
  String get chapterFindStartNone => 'Nothing here sounds like a chapter start';

  @override
  String get chapterFindStartWider => 'Search wider';

  @override
  String get chapterFindStartCeiling =>
      'Searched half an hour around the marker. The start is further off than that, or there\'s no chapter announcement to hear.';

  @override
  String get chapterFindStartStrong => 'Sounds like this chapter';

  @override
  String get chapterFindStartMaybe => 'Chapter-like words';

  @override
  String chapterFindStartGap(String seconds) {
    return '${seconds}s gap';
  }

  @override
  String chapterFindStartRange(String from, String to) {
    return 'Searched $from to $to';
  }

  @override
  String get chapterFindStartNeedsModel =>
      'Turn on transcription in Settings and download a model first';

  @override
  String get chapterFindStartUseThis => 'Use this';

  @override
  String chapterFindStartTitle(String title) {
    return 'Title: $title';
  }

  @override
  String get chapterShiftBySeconds => 'Shift by (seconds)';

  @override
  String get chapterShiftHint =>
      'Shifts every unlocked chapter. Use a negative value to move them earlier.';

  @override
  String get chapterTitleHint => 'Название главы';

  @override
  String get chapterStopPreview => 'Stop preview';

  @override
  String get chapterPreviewFromHere => 'Preview from here';

  @override
  String get chapterScrubHint => 'Drag or nudge to move the start';

  @override
  String chapterStartAt(String time) {
    return 'Start at $time';
  }

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
  String get chapterRemoveBranding =>
      'Удалить брендинг Audible (вступление/заключение)';

  @override
  String chapterFoundCount(int count) {
    return '$count Глав найдено';
  }

  @override
  String chapterAudibleVsBook(String audible, String book) {
    return 'Audible $audible  -  Книга $book';
  }

  @override
  String get chapterAudibleLonger =>
      'Версия Audible длиннее вашего файла - более поздние главы могут не совпадать.';

  @override
  String get chapterAudibleShorter =>
      'Версия Audible короче, чем ваш файл - главы могут не совпадать.';

  @override
  String get chapterTitlesOnly => 'Только заголовки';

  @override
  String get chapterApplyChapters => 'Применить главы';

  @override
  String get coverSearchTitle => 'Поиск обложек';

  @override
  String get coverSearchRefineHint =>
      'Уточните название/автор для очистки результата - это не меняет книгу.';

  @override
  String get coverNoneFound => 'Обложки не найдены';

  @override
  String get coverEnterTitleFirst => 'Введите сначала название';

  @override
  String get coverUpdated => 'Обложка обновлена';

  @override
  String get coverCouldNotUpdate => 'Не удается обновить обложку';

  @override
  String get coverApply => 'Применить обложку';

  @override
  String get coverUnknownResolution => 'Неизвестное разрешение';

  @override
  String get embedIntro =>
      'Вставить метаданные в аудио файлы, включая обложку и главы.';

  @override
  String get embedBackupOption =>
      'Сначала сделайте резервную копию аудио файлов';

  @override
  String get embedNoteInFolder =>
      'Метаданные будут встроены в аудиофайлы в папку аудиокниг.';

  @override
  String get embedNoteMultiTrack =>
      'Главы не встроить в мульти-трековые аудиокниги.';

  @override
  String get embedNoteNavigateAway =>
      'После запуска задачи вы можете уйти с этой страницы.';

  @override
  String get embedStartButton => 'Запустить вставку метаданных';

  @override
  String embedProgress(String percent) {
    return 'Встраивание $percent%';
  }

  @override
  String get embedProgressIndeterminate => 'Встраивание...';

  @override
  String taskProgressKeepsRunning(String percent) {
    return '$percent% - продолжит запуск, если вы покинете эту страницу';
  }

  @override
  String get taskStarting => 'Запуск...';

  @override
  String get embedBackupNoteIntro =>
      'Резервная копия ваших оригинальных аудиофайлов будет сохранена на сервере в ';

  @override
  String embedBackupNotePath(String itemId) {
    return '/metadata/cache/items/$itemId/';
  }

  @override
  String get embedBackupNoteOutro => '. Периодически очищайте кэш элементов.';

  @override
  String get embedDialogTitle => 'Встроенные метаданные';

  @override
  String embedConfirmMessage(int count, String backup) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# audio files',
      one: '# audio file',
    );
    return 'Встроить метаданные в $_temp0? Аудиофайлы будут перезаписаны$backup.';
  }

  @override
  String get embedConfirmBackupClause => ' (оригиналы резервных копий сначала)';

  @override
  String get embedConfirmAction => 'Встроить';

  @override
  String get embedCouldNotStart => 'Невозможно начать вставку';

  @override
  String get embedStarted => 'Встраивание начато';

  @override
  String get embedComplete => 'Встраивание завершено';

  @override
  String get embedFailed => 'Не удалось встроить';

  @override
  String get encodeComplete => 'Кодирование завершено';

  @override
  String get encodeFailedTask => 'Ошибка кодирования';

  @override
  String encodeProgress(String percent) {
    return 'Кодирование $percent%';
  }

  @override
  String get encodeProgressIndeterminate => 'Кодирование...';

  @override
  String get adminApiKeys => 'API-ключи';

  @override
  String get adminApiKeysSubtitle => 'Программные токены доступа';

  @override
  String get adminApiKeysNewTitle => 'Новый API-ключ';

  @override
  String get adminApiKeysName => 'Название';

  @override
  String get adminApiKeysNameHint => 'например Home Assistant';

  @override
  String get adminApiKeysOwner => 'Пользователь';

  @override
  String get adminApiKeysExpiration => 'Срок действия';

  @override
  String get adminApiKeysActive => 'Активный';

  @override
  String get adminApiKeysActiveSub => 'Ключ работает сразу же после создания';

  @override
  String get adminApiKeysInactive => 'Неактивен';

  @override
  String get adminApiKeysExpired => 'Истек срок';

  @override
  String get adminApiKeysCreate => 'Создать ключ';

  @override
  String get adminApiKeysCreated => 'API-ключ создан';

  @override
  String get adminApiKeysTokenLabel => 'Ваш новый API-ключ';

  @override
  String get adminApiKeysCopyWarning =>
      'Скопируйте этот ключ сейчас. Для безопасности он не будет показан снова.';

  @override
  String get adminApiKeysCopy => 'Копировать';

  @override
  String get adminApiKeysCopied => 'Скопирован в буфер обмена';

  @override
  String get adminApiKeysDone => 'Готово';

  @override
  String get adminApiKeysDeleteTitle => 'Отозвать API-ключ?';

  @override
  String get adminApiKeysDeleted => 'API-ключ отозван';

  @override
  String get adminApiKeysRevoke => 'Отозвать';

  @override
  String get adminApiKeysSetActive => 'Активировать';

  @override
  String get adminApiKeysSetInactive => 'Деактивировать';

  @override
  String get adminApiKeysFailedCreate => 'Не удалось создать API-ключ';

  @override
  String get adminApiKeysFailedDelete => 'Не удалось отозвать API ключ';

  @override
  String get adminApiKeysFailedUpdate => 'Не удалось обновить API-ключ';

  @override
  String get adminApiKeysEmpty => 'API-ключей еще нет';

  @override
  String get adminApiKeysEmptySub =>
      'Создайте, чтобы приложения и скрипты дошли до вашего сервера';

  @override
  String get adminApiKeysNeverUsed => 'Не использовался';

  @override
  String get adminApiKeysNeverExpires => 'Без срока действия';

  @override
  String get adminApiKeysNameRequired => 'Введите имя';

  @override
  String get adminApiKeysUserRequired => 'Выберите пользователя';

  @override
  String get adminApiKeysExpNever => 'Не ограничен';

  @override
  String get adminApiKeysExp7d => '7 дней';

  @override
  String get adminApiKeysExp30d => '30 дней';

  @override
  String get adminApiKeysExp90d => '90 дней';

  @override
  String get adminApiKeysExp1y => '1 год';

  @override
  String adminApiKeysLastUsed(String time) {
    return 'Последнее использование $time';
  }

  @override
  String adminApiKeysExpiresOn(String date) {
    return 'Истекает $date';
  }

  @override
  String adminApiKeysDeleteContent(String name) {
    return 'Отозвать \"$name\"? Приложения с этим ключом немедленно потеряют доступ.';
  }

  @override
  String get endOfEpisode => 'Окончание серии';

  @override
  String get sleepTimerSheetEpisodeSleepStart => 'Сон в конце серии';

  @override
  String get bookmarkListen => 'Прослушать';

  @override
  String get bookmarkPause => 'Пауза';

  @override
  String get bookmarkPreviewFailed => 'Не удалось воспроизвести это место.';

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
  String get adminLibrariesManage => 'Библиотеки';

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
  String get adminUploadFiles => 'Файлы';

  @override
  String adminUploadSelectedFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count файла',
      many: '$count файлов',
      few: '$count файла',
      one: '$count файл',
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
  String get adminUploadAddToExistingTitle => 'Folder already exists';

  @override
  String adminUploadAddToExisting(String title) {
    return 'That folder belongs to \"$title\". Add the files to it? The server picks them up on its next scan.';
  }

  @override
  String get adminUploadAddToExistingNoItem =>
      'That folder already exists on the server. Add the files to it?';

  @override
  String get adminUploadAddToBook => 'Add to an existing book';

  @override
  String get adminUploadAddToBookHint => 'Search this library';

  @override
  String get adminUploadNoBooksFound => 'No books found';

  @override
  String adminUploadAddingTo(String title) {
    return 'Adding files to \"$title\"';
  }

  @override
  String adminUploadAddedTo(String title) {
    return 'Added files to \"$title\"';
  }

  @override
  String get adminUploadTargetNoFolder =>
      'Couldn\'t find that book\'s folder on the server.';

  @override
  String adminUploadTargetFolderMismatch(String preview, String folder) {
    return 'The server would put these files in \"$preview\", not in that book\'s folder \"$folder\". Nothing was uploaded.';
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
  String get adminAuthentication => 'Authentication';

  @override
  String get adminAuthenticationSubtitle =>
      'Password and OpenID Connect sign-in';

  @override
  String get adminStats => 'Статистика';

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
  String get statsTotalItems => 'Элементы';

  @override
  String get statsAudioFiles => 'Аудио файлы';

  @override
  String get statsTotalSize => 'Общий размер';

  @override
  String get statsBooks => 'Книги';

  @override
  String get statsPodcasts => 'Подкасты';

  @override
  String get statsBooksSize => 'Размер книг';

  @override
  String get statsYearReview => 'Обзор года';

  @override
  String get statsNoYearData => 'No data for this year';

  @override
  String get statsListeningTime => 'Время прослушивания';

  @override
  String get statsSessions => 'Сеансы';

  @override
  String get statsBooksAdded => 'Добавлено книг';

  @override
  String get statsAuthorsAdded => 'Добавлено авторов';

  @override
  String get statsTopAuthors => 'Топ авторы';

  @override
  String get statsTopNarrators => 'Топ чтецы';

  @override
  String get statsTopGenres => 'Топ жанры';

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
  String get authSetLoadFailed => 'Couldn\'t load authentication settings';

  @override
  String get authSetCustomMessage => 'Custom message on login';

  @override
  String get authSetMessage => 'Message';

  @override
  String get authSetPasswordAuth => 'Password authentication';

  @override
  String get authSetOpenId => 'OpenID Connect authentication';

  @override
  String get authSetGuide => 'Setup guide';

  @override
  String get authSetIssuerUrl => 'Issuer URL';

  @override
  String get authSetAutoPopulate => 'Auto-populate';

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
  String get authSetSigningAlgorithm => 'Signing algorithm';

  @override
  String get authSetRedirectUris => 'Allowed mobile redirect URIs';

  @override
  String get authSetRedirectUrisInfo =>
      'Apps can only return to these addresses after sign-in. Absorb uses absorb://oauth. An asterisk (*) as the only entry allows any address.';

  @override
  String get authSetAddRedirectUri => 'Add URI';

  @override
  String get authSetAddAbsorbRedirect => 'Add absorb://oauth';

  @override
  String get authSetSubfolder => 'Subfolder for redirect URLs';

  @override
  String get authSetSubfolderNone => 'None';

  @override
  String get authSetWebRedirectInfo =>
      'Allow these URLs in your OAuth provider so sign-in can return to the web app:';

  @override
  String get authSetButtonText => 'Button text';

  @override
  String get authSetMatchExisting => 'Match existing users by';

  @override
  String get authSetMatchNone => 'Do not match';

  @override
  String get authSetMatchEmail => 'Email';

  @override
  String get authSetMatchUsername => 'Username';

  @override
  String get authSetMatchExistingInfo =>
      'Used to link existing users. Once linked, users are matched by their unique ID from the provider.';

  @override
  String get authSetAutoLaunch => 'Auto launch';

  @override
  String get authSetAutoLaunchInfo =>
      'Open the provider automatically from the web login page. /login?autoLaunch=0 skips it.';

  @override
  String get authSetAutoRegister => 'Auto register';

  @override
  String get authSetAutoRegisterInfo =>
      'Create new users automatically after they sign in';

  @override
  String get authSetClaimsInfo =>
      'Leave these empty to turn off group and permission assignment. New users then get the User role.';

  @override
  String get authSetGroupClaim => 'Group claim';

  @override
  String get authSetGroupClaimInfo =>
      'Claim that lists the user\'s groups, usually groups. Groups named admin, user or guest set the role, and the highest one wins. If no group matches, sign-in is refused.';

  @override
  String get authSetPermsClaim => 'Advanced permission claim';

  @override
  String get authSetPermsClaimInfo =>
      'Claim with permissions for non-admin users. If the claim is missing, sign-in is refused, and a missing option counts as off. Expected format:';

  @override
  String get authSetRestartNote =>
      'Restart the server after saving to apply OpenID Connect changes.';

  @override
  String get authSetNoChanges => 'No changes to save';

  @override
  String get authSetNeedOneMethod => 'Turn on at least one sign-in method';

  @override
  String authSetFieldRequired(String field) {
    return '$field is required';
  }

  @override
  String authSetInvalidRedirectUri(String uri) {
    return 'Invalid redirect URI: $uri';
  }

  @override
  String get authSetAsteriskAlone =>
      'An asterisk (*) must be the only redirect URI';

  @override
  String authSetInvalidClaim(String field) {
    return '$field is not a valid claim name';
  }

  @override
  String authSetIssuerFailed(String error) {
    return 'Couldn\'t read the issuer: $error';
  }

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
      other: '$count папки',
      many: '$count папок',
      few: '$count папки',
      one: '$count папка',
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
  String get libIcon => 'Значок';

  @override
  String get libFolders => 'Папки';

  @override
  String get libAddFolder => 'Добавить папку';

  @override
  String get libNoFolders => 'Добавь хотя бы одну папку';

  @override
  String get libAdvanced => 'Расширенные настройки';

  @override
  String get libCoverShape => 'Форма обложек';

  @override
  String get libCoverSquare => 'Квадрат';

  @override
  String get libCoverStandard => 'Стандарт';

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
  String get libMarkPercent => 'Прослушано когда готово на %';

  @override
  String get libMarkTime => 'Прослушано когда останется секунд';

  @override
  String get libAutoScan => 'Auto-scan schedule (cron)';

  @override
  String get libCreate => 'Создать библиотеку';

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
  String get ebookDownload => 'Скачать';

  @override
  String get ebookDownloaded => 'Скачано';

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
  String get ebookSaveNarratedBody =>
      'This EPUB has its narration built in, so the full file is large. Text only saves just the book\'s text and pictures, which is much smaller.';

  @override
  String get ebookSaveTextOnly => 'Text only';

  @override
  String get ebookSaveWithNarration => 'With narration';

  @override
  String get readerFormatUnsupported =>
      'This ebook format can\'t be opened in the reader yet';

  @override
  String get readerCouldNotOpen =>
      'This ebook couldn\'t be opened. The file may be damaged.';

  @override
  String get moreActions => 'Больше';

  @override
  String get readerChapters => 'Главы';

  @override
  String get readerSettings => 'Reader Settings';

  @override
  String get readerFontSize => 'Font Size';

  @override
  String get readerLineSpacing => 'Line Spacing';

  @override
  String get readerTextAlignment => 'Alignment';

  @override
  String get readerAlignJustified => 'Justified';

  @override
  String get readerAlignLeft => 'Left';

  @override
  String get readerSideMargins => 'Side margins';

  @override
  String get readerTopBottom => 'Top & bottom';

  @override
  String get readerPageLayout => 'Page layout';

  @override
  String get readerPinTopBar => 'Keep the title and progress bar on screen';

  @override
  String get readerPinTopBarHint =>
      'Pins them above the page instead of showing them on tap. The page gets a little shorter so no text is covered.';

  @override
  String get readerTopBarProgress => 'Top bar progress';

  @override
  String get readerTopBarProgressBook => 'Book';

  @override
  String get readerTopBarProgressChapter => 'Chapter';

  @override
  String get readerTopBarProgressBoth => 'Both';

  @override
  String get readerSectionText => 'Text';

  @override
  String get readerSectionPage => 'Page';

  @override
  String get readerSectionTopBar => 'Top bar and screen';

  @override
  String get readerSectionControls => 'Controls';

  @override
  String get readerSectionStats => 'Stats';

  @override
  String get readerSectionReading => 'Reading';

  @override
  String get readerSectionScreen => 'Screen';

  @override
  String get readerParagraphSpacing => 'Paragraph spacing';

  @override
  String get readerParagraphSpacingBook => 'Book\'s own';

  @override
  String get readerTapZones => 'Tap zones';

  @override
  String get readerTapZonesHint =>
      'Drag the lines to resize the squares. Tap a square to change what it does, or start from a layout.';

  @override
  String get readerTapZonesCardTop => 'Move to the top';

  @override
  String get readerTapZonesCardBottom => 'Move to the bottom';

  @override
  String get readerTapZonesCardHide => 'Shrink the card';

  @override
  String get readerTapZonesCardShow => 'Show the card';

  @override
  String get readerTapPrev => 'Previous page';

  @override
  String get readerTapNext => 'Next page';

  @override
  String get readerTapMenu => 'Show controls';

  @override
  String get readerTapNothing => 'Nothing';

  @override
  String get readerTapKeepMenu => 'One square has to show the controls';

  @override
  String get readerHideControls => 'Hide controls after';

  @override
  String get readerHideControlsNever => 'Never';

  @override
  String get readerBarNotes => 'Notes and highlights';

  @override
  String readerHideControlsAfter(int seconds) {
    return '${seconds}s';
  }

  @override
  String get playerDownloadStreamingInstead =>
      'This download couldn\'t be played, so it\'s streaming from the server. Downloading it again may fix it.';

  @override
  String get readerPageTurn => 'Page turn';

  @override
  String get readerPageTurnNone => 'None';

  @override
  String get readerPageTurnSlide => 'Slide';

  @override
  String get readerPageTurnCurl => 'Curl';

  @override
  String get readerPageTurnRipple => 'Ripple';

  @override
  String get readerScrollMode => 'Scroll mode';

  @override
  String get readerSentenceMode => 'Sentence mode';

  @override
  String get readerSentenceModeHint =>
      'One sentence at a time, tap or swipe to move on. Applies to every book.';

  @override
  String get readerSentencesAtATime => 'Sentences at a time';

  @override
  String get readerSentenceTransition => 'Transition';

  @override
  String get readerSentenceTransitionFade => 'Fade';

  @override
  String get readerSentenceTransitionBurst => 'Burst';

  @override
  String get readerSentenceSpeed => 'Speed';

  @override
  String get readerSentenceAutoAdvance => 'Auto advance';

  @override
  String readerSentenceWpmValue(int wpm) {
    return '$wpm words per minute';
  }

  @override
  String get readerSentencePreparing => 'Preparing sentences';

  @override
  String get readerSentenceEnd => 'That\'s the end of the book';

  @override
  String get readerScrollModeHint =>
      'Scroll down through the book instead of turning pages. Applies to every book.';

  @override
  String get readerKeepAwake => 'Keep the screen on';

  @override
  String get readerKeepAwakeHint =>
      'Stops the screen timing out while you read at your own pace. Auto scroll and read along always keep it on.';

  @override
  String get readerLayoutAuto => 'Авто';

  @override
  String get readerLayoutSingle => 'Single';

  @override
  String get readerLayoutTwoPage => 'Two-page';

  @override
  String get readerTheme => 'Тема';

  @override
  String get readerFont => 'Шрифт';

  @override
  String get readerVolumeNav => 'Переключение страниц кнопками громкости';

  @override
  String get readerVolumeNavOff => 'Выкл';

  @override
  String get readerVolumeNavNormal => 'Нормально';

  @override
  String get readerVolumeNavMirrored => 'Зеркально';

  @override
  String get readerAutoScroll => 'Автопрокрутка';

  @override
  String get readerAutoScrollSubtitle =>
      'The next page paints over this one from the top down - drag the middle of the screen to change speed, tap to stop';

  @override
  String get readerAutoScrollStarted => 'Автопрокрутка началась';

  @override
  String get readerAutoScrollPaused => 'Paused - press and hold to stop';

  @override
  String get readerAutoScrollResumed => 'Auto scroll resumed';

  @override
  String get readerAutoScrollStopped => 'Автопрокрутка выкл';

  @override
  String get readerAutoScrollEndOfBook => 'End of book - auto scroll off';

  @override
  String get readerMoreControls => 'More controls';

  @override
  String get readerAutoScrollSleep => 'Auto scroll sleep timer';

  @override
  String get readerAutoScrollSleepHint =>
      'Stops the scrolling after a while and lets the screen go dark.';

  @override
  String readerAutoScrollSleepMinutes(int minutes) {
    return '$minutes мин';
  }

  @override
  String readerAutoScrollSleepLeft(int minutes) {
    return '$minutes мин осталось';
  }

  @override
  String readerAutoScrollSleepIn(int minutes) {
    return 'Auto scroll stops in $minutes min';
  }

  @override
  String get readerAutoScrollSleepOff => 'Auto scroll sleep timer off';

  @override
  String get readerAutoScrollSleepEnded => 'Sleep timer - auto scroll off';

  @override
  String get readerDownloadStarted => 'Скачивание началось';

  @override
  String get detailChaptersJumpTitle => 'Перейти к этой главе?';

  @override
  String detailChaptersJumpContent(String title) {
    return 'Playback moves to \"$title\".';
  }

  @override
  String get detailChaptersJump => 'Перейти';

  @override
  String detailChaptersFinished(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count главы прослушаны',
      many: '$count глав прослушанные',
      few: '$count главы прослушанные',
      one: '$count глава прослушана',
    );
    return '$_temp0';
  }

  @override
  String detailOtherListeners(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count other listeners',
      one: '1 other listener',
      zero: 'No other listeners',
    );
    return '$_temp0';
  }

  @override
  String get seriesUpNext => 'Up next';

  @override
  String get seriesJumpToUpNext => 'Jump to up next';

  @override
  String get seriesStatsFinished => 'Прослушано';

  @override
  String get seriesStatsListened => 'Прослушано';

  @override
  String get seriesStatsLeft => 'Left';

  @override
  String seriesFinishedOf(int done, int total) {
    return '$done из $total';
  }

  @override
  String get detailSessionsNone => 'No listening sessions yet';

  @override
  String detailSessionsAll(int count) {
    return 'All $count sessions';
  }

  @override
  String get readerVolumeNavWhilePlaying => 'Even while audio is playing';

  @override
  String get readerTranslateWith => 'Translate with';

  @override
  String get readerTranslateApp => 'App on this device';

  @override
  String get readerTranslateApple => 'Built into iOS';

  @override
  String get readerTranslateWeb => 'Opens in your browser';

  @override
  String get readerTranslateHint =>
      'Selected text is sent to the translator you pick.';

  @override
  String get readerMoreFonts => 'Скачать больше шрифтов';

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
  String get readerHistory => 'History';

  @override
  String get sessionReading => 'Reading';

  @override
  String get readerHistoryEmpty =>
      'Pages you leave are listed here, so you can always get back to them.';

  @override
  String get readerHistoryClosed => 'Closed the book';

  @override
  String get readerHistoryBeforeJump => 'Before a jump';

  @override
  String get readerHistoryBeforeSync => 'Before matching the audio';

  @override
  String get readerLogReading => 'Count reading time in stats';

  @override
  String get readerLogReadingHint =>
      'Logs your time in the reader as a session so it shows in your stats. On Audiobookshelf it counts as listening time.';

  @override
  String get readerNoBookmarks => 'No bookmarks yet';

  @override
  String get readerBookmarkDefault => 'Закладка';

  @override
  String get readerNoteTitle => 'Заметка';

  @override
  String get readerNoteHint => 'Добавить заметку...';

  @override
  String get backupAndSync => 'Backup and sync';

  @override
  String get backupAndSyncSubtitle =>
      'Save a backup file, or keep settings in step across devices';

  @override
  String get syncSettingsExperimental => 'Экспериментально';

  @override
  String get syncSettingsExperimentalBody =>
      'Sync is new and still being worked on. If two devices change things while they are apart, one side can lose its changes. Keep a backup file as your safe copy.';

  @override
  String get syncSettingsNeedServer => 'Need a server?';

  @override
  String get syncSettingsNeedServerSub =>
      'Any WebDAV server works. Nextcloud is a free self-hosted one.';

  @override
  String get syncSettingsConnection => 'Подключение';

  @override
  String get syncSettingsConnectionNotSet => 'Ещё не настроено';

  @override
  String get syncSettingsBackupFile => 'Backup file';

  @override
  String get syncSettingsBackupFilePlain =>
      'Save everything to a file you keep.';

  @override
  String get syncSettingsBackupFileWithSync =>
      'Save everything to a file you keep. Include login info and restoring it on another phone turns sync on there too.';

  @override
  String get syncSettingsStatusOff => 'Не синхронизируется';

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
  String get syncSettingsUsername => 'Логин';

  @override
  String get syncSettingsPassword => 'Пароль';

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
  String get syncSettingsUploadNow => 'Загрузить сейчас';

  @override
  String get syncSettingsDownloadNow => 'Скачать сейчас';

  @override
  String get syncSettingsOk => 'Подключено';

  @override
  String get syncSettingsNoRemote =>
      'Подключено - пока ничего не синхронизировано';

  @override
  String get syncSettingsAuthFailed => 'Неверный логин или пароль';

  @override
  String get syncSettingsNetworkError => 'Не удалось достичь этого адреса';

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
  String get navHoldOfflineMode => 'Оафлайн режим';

  @override
  String get navHoldOfflineOn => 'Автономный режим вкл';

  @override
  String get navHoldOfflineOff => 'Оффлайн режим выкл';

  @override
  String get navHoldMenu => 'Всегда показывать меню';

  @override
  String get navHoldStop => 'Остановить воспроизведение';

  @override
  String get navHoldRmabSearch => 'ReadMeABook search';

  @override
  String get navHoldRmabRequests => 'My book requests';

  @override
  String get navHoldRmabWeb => 'ReadMeABook site';

  @override
  String get navHoldAdd => 'Добавить';

  @override
  String get navHoldMoveLeft => 'Сдвинуть влево';

  @override
  String get navHoldMoveRight => 'Сдвинуть вправо';

  @override
  String get navHoldRemoveFromMenu => 'Удалить из меню';

  @override
  String get navHoldEditHint =>
      'Удерживайте элемент для перемещения или удаления';

  @override
  String get navHoldResetMenu => 'Reset the hold menu items';

  @override
  String get navHoldMenuReset => 'Menu items reset';

  @override
  String get bookStatsAction => 'Статистика прослушивания';

  @override
  String get bookStatsYou => 'Ты';

  @override
  String get bookStatsEveryone => 'Все';

  @override
  String get bookStatsListened => 'Время прослушано';

  @override
  String get bookStatsSessions => 'Сеансы';

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
  String get activityYourReading => 'Your reading';

  @override
  String get activityYourListening => 'Your listening';

  @override
  String activityLastRead(String when) {
    return 'Last read $when';
  }

  @override
  String activityLastListened(String when) {
    return 'Last listened $when';
  }

  @override
  String get activityNotStarted => 'Not started';

  @override
  String get activityNoReading => 'No reading sessions yet';

  @override
  String get activityTime => 'Time';

  @override
  String get activityAverage => 'Avg';

  @override
  String get activityProgress => 'Progress';

  @override
  String activityReached(String percent) {
    return '$percent reached';
  }

  @override
  String get readingLogTitle => 'Reading log';

  @override
  String get readingLogTotalTime => 'Total time';

  @override
  String get readingLogAverageSession => 'Average session';

  @override
  String get readingLogActiveDays => 'Active days';

  @override
  String readingLogActiveDaysOf(int active, int total) {
    return '$active of $total';
  }

  @override
  String get readingLogPace => 'Pace';

  @override
  String readingLogPacePerHour(String percent) {
    return '$percent%/h';
  }

  @override
  String get readingLogLastRead => 'Last read';

  @override
  String get readingLogStarted => 'Started';

  @override
  String get readingLogFinished => 'Finished';

  @override
  String get readingLogNotSet => 'Not set';

  @override
  String readingLogLeftMinutes(int m) {
    return 'About ${m}m to finish';
  }

  @override
  String readingLogLeftHours(int h) {
    return 'About ${h}h to finish';
  }

  @override
  String readingLogLeftHoursMinutes(int h, int m) {
    return 'About ${h}h ${m}m to finish';
  }

  @override
  String get readingLogLeftMax => 'Over 99h to finish';

  @override
  String readingLogUpOnLastWeek(int percent) {
    return 'Up $percent% on the week before';
  }

  @override
  String readingLogDownOnLastWeek(int percent) {
    return 'Down $percent% on the week before';
  }

  @override
  String get readingLogNewThisWeek => 'New this week';

  @override
  String get readingLogSameAsLastWeek => 'Same as the week before';

  @override
  String get readingLogQuietTwoWeeks => 'Nothing in the last two weeks';

  @override
  String get readingLogWhereYouRead => 'Where you read it';

  @override
  String get readingLogSourceIos => 'iOS app';

  @override
  String get readingLogSourceAndroid => 'Android app';

  @override
  String get readingLogChartTitle => 'Progress over time';

  @override
  String get readingLogChartPosition => 'Position reached';

  @override
  String get readingLogChartMinutes => 'Minutes';

  @override
  String get readingLogRecords => 'Records';

  @override
  String get readingLogLongestSession => 'Longest session';

  @override
  String get readingLogBestDay => 'Best day';

  @override
  String get readingLogLongestStreak => 'Longest streak';

  @override
  String readingLogStreakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String get readingLogJumpedBack => 'Jumped back';

  @override
  String readingLogJumpedBackTimes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count times',
      one: '1 time',
    );
    return '$_temp0';
  }

  @override
  String get readingLogFirstOpened => 'First opened';

  @override
  String get readingLogAttempts => 'Attempts';

  @override
  String readingLogAttempt(int index) {
    return 'Attempt $index';
  }

  @override
  String readingLogAttemptBegan(int index) {
    return 'Attempt $index began';
  }

  @override
  String get readingLogOutcomeCompleted => 'Completed';

  @override
  String get readingLogOutcomeSkimmed => 'Skimmed';

  @override
  String get readingLogOutcomeAbandoned => 'Abandoned';

  @override
  String get readingLogOutcomeInProgress => 'In progress';

  @override
  String readingLogSpanRange(String from, String to) {
    return '$from to $to';
  }

  @override
  String readingLogSpanSince(String from) {
    return 'Since $from';
  }

  @override
  String readingLogSpanEnded(String to) {
    return 'Ended $to';
  }

  @override
  String get readingLogSpanUnknown => 'No dates recorded';

  @override
  String readingLogSessionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sessions',
      one: '1 session',
    );
    return '$_temp0';
  }

  @override
  String readingLogShowing(int shown, int total) {
    return '$shown of $total';
  }

  @override
  String readingLogGapDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days without reading',
      one: '1 day without reading',
    );
    return '$_temp0';
  }

  @override
  String get readingLogEmpty => 'No sessions recorded yet';

  @override
  String get readingLogEmptyHint =>
      'Sessions show up here as you read or listen, from any app or device that syncs with BookOrbit.';

  @override
  String get readingLogNoMatches => 'No sessions in this range';

  @override
  String get readingLogAllTime => 'All time';

  @override
  String get readingLogLast30 => 'Last 30 days';

  @override
  String get readingLogLast90 => 'Last 90 days';

  @override
  String get readingLogThisYear => 'This year';

  @override
  String get readingLogAllFormats => 'All formats';

  @override
  String get readingLogSortBy => 'Sort by';

  @override
  String get readingLogSortDay => 'Day';

  @override
  String get readingLogSortLength => 'Length';

  @override
  String get readingLogSortChange => 'Change';

  @override
  String get readingLogSortReached => 'Reached';

  @override
  String get readingLogNewestFirst => 'Newest first';

  @override
  String get readingLogOldestFirst => 'Oldest first';

  @override
  String get readingLogMostFirst => 'Most first';

  @override
  String get readingLogLeastFirst => 'Least first';

  @override
  String get readingLogDeleteTitle => 'Delete this session?';

  @override
  String get readingLogDeleteBody =>
      'It comes off the book\'s reading log and your stats on BookOrbit.';

  @override
  String get readingLogDeleteFailed => 'Couldn\'t delete the session';

  @override
  String get readingLogLoadFailed => 'Couldn\'t load the reading log';

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
      'Your preferences, per-book speeds, home layout, Absorbing order, notes and ebook highlights travel. Logins, download folders, auto-download switches, reader looks and anything not yet sent to your server stay on this device.';

  @override
  String get syncSettingsDownloadWarnTitle =>
      'Replace this device\'s settings?';

  @override
  String get syncSettingsDownloadWarnBody =>
      'The synced copy will overwrite the settings on this device.';

  @override
  String get syncSettingsDownloadWarnConfirm => 'Replace';

  @override
  String get readerCopied => 'Copied to clipboard';

  @override
  String get dictionaryNotFound => 'No definition found for this word.';

  @override
  String get dictionaryError =>
      'Couldn\'t reach the dictionary. Check your connection.';

  @override
  String get dictionaryRetry => 'Retry';

  @override
  String get dictionarySearchWeb => 'Search the web';

  @override
  String get readerTooltipCopy => 'Копировать';

  @override
  String get readerTooltipSearch => 'Искать';

  @override
  String get readerTooltipDefine => 'Define';

  @override
  String get readerTooltipTranslate => 'Translate';

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

  @override
  String get transcriptionTitle => 'Транскрипция';

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
      'With more than one downloaded, each job picks between them. Books with an ebook get the quickest one, since the exact words come from the ebook anyway. Books without one get the most accurate - except read along, which stays below Small so it can keep up with the narration.';

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
      'Download this book or connect to your server to transcribe it.';

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
  String get findInAudiobookStillSearching =>
      'Still searching the audio for this spot...';

  @override
  String get findInAudiobookSearchingLong =>
      'Long chapter, still searching. This can take a minute or two...';

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
  String get keepScreenOnPlayer => 'Keep the screen on in the player';

  @override
  String get keepScreenOnPlayerSubtitle =>
      'The screen stays on while the player is open';

  @override
  String get keepScreenOnCarMode => 'Keep the screen on in car mode';

  @override
  String get keepScreenOnCarModeSubtitle =>
      'The screen stays on while car mode is open';

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
  String get boNotificationsClearAll => 'Clear all';

  @override
  String get boNotificationsClearTitle => 'Clear all notifications?';

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
    return 'Happened $count times';
  }

  @override
  String get boNotificationsSettings => 'Notification settings';

  @override
  String get boNotificationsSettingsIntro =>
      'Choose which notifications BookOrbit keeps for you.';

  @override
  String get boNotificationsProblemsHint =>
      'Problems only notifies you when something fails or needs attention.';

  @override
  String get boNotificationLevelOff => 'Off';

  @override
  String get boNotificationLevelProblems => 'Problems';

  @override
  String get boNotificationLevelAll => 'All';

  @override
  String get boNotificationsSaved => 'Notification settings saved';

  @override
  String get boNotificationsSaveFailed =>
      'Couldn\'t save notification settings';

  @override
  String get boNotificationGroupLibrary => 'Library';

  @override
  String get boNotificationGroupFiles => 'Files';

  @override
  String get boNotificationGroupIntegrations => 'Integrations';

  @override
  String get boNotificationGroupPersonal => 'Personal';

  @override
  String get boNotifyScanning => 'Library scanning';

  @override
  String get boNotifyScanningDesc =>
      'When a library scan finishes, fails, or finds missing books.';

  @override
  String get boNotifyMetadata => 'Metadata fetching';

  @override
  String get boNotifyMetadataDesc =>
      'When metadata lookups for your books finish or fail.';

  @override
  String get boNotifyAuthorEnrichment => 'Author details';

  @override
  String get boNotifyAuthorEnrichmentDesc =>
      'When author biographies and photos finish downloading.';

  @override
  String get boNotifyFileWriteBack => 'Saving to files';

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
  String get achievementsCategoryLibrary => 'Library';

  @override
  String get achievementsCategoryExploration => 'Exploration';

  @override
  String get achievementsCategoryDedication => 'Dedication';

  @override
  String get achievementsCategoryDevices => 'Devices';

  @override
  String get achievementsRarityCommon => 'Common';

  @override
  String get achievementsRarityRare => 'Rare';

  @override
  String get achievementsRarityEpic => 'Epic';

  @override
  String get achievementsRarityLegendary => 'Legendary';

  @override
  String get achievementsLoadFailed => 'Couldn\'t load achievements';

  @override
  String get achievementsNoneMatch => 'No achievements match this filter';

  @override
  String get achievementsSecretName => 'Secret achievement';

  @override
  String get achievementsSecretHint => 'Keep reading to reveal this one.';

  @override
  String achievementsEarnedOn(String date) {
    return 'Earned $date';
  }

  @override
  String achievementsWhileReading(String title) {
    return 'While reading $title';
  }

  @override
  String achievementsTierOf(int earned, int total) {
    return 'Tier $earned of $total';
  }

  @override
  String get achievementsTiers => 'Tiers';

  @override
  String get achievementsAllTiers => 'Every tier earned';

  @override
  String achievementsProgress(String current, String threshold) {
    return '$current / $threshold';
  }

  @override
  String achievementsProgressBooks(String current, String threshold) {
    return '$current / $threshold books';
  }

  @override
  String achievementsProgressPages(String current, String threshold) {
    return '$current / $threshold pages';
  }

  @override
  String achievementsProgressHours(String current, String threshold) {
    return '$current / $threshold hours';
  }

  @override
  String achievementsProgressAnnotations(String current, String threshold) {
    return '$current / $threshold highlights and notes';
  }

  @override
  String achievementsProgressRatings(String current, String threshold) {
    return '$current / $threshold ratings';
  }

  @override
  String achievementsProgressGenres(String current, String threshold) {
    return '$current / $threshold genres';
  }

  @override
  String achievementsProgressLanguages(String current, String threshold) {
    return '$current / $threshold languages';
  }

  @override
  String achievementsProgressDays(String current, String threshold) {
    return '$current / $threshold days';
  }

  @override
  String get achievementsHowToGetIt => 'How to get it';

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
  String get achievementsHintUntitledBook => 'A book in progress';

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
  String get achievementsSwitch => 'Achievements';

  @override
  String get achievementsSwitchSubtitle =>
      'Track achievements on BookOrbit. Turning this off hides them here and on the web.';

  @override
  String get achievementsTurnedOn => 'Achievements turned on';

  @override
  String get achievementsTurnedOff => 'Achievements turned off';

  @override
  String get achievementsSwitchFailed =>
      'Couldn\'t change achievements on BookOrbit';

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
