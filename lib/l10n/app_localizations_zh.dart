// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'A B S O R B';

  @override
  String get online => '在线';

  @override
  String get offline => '离线';

  @override
  String get stillOffline => '仍处于离线状态。点击重试。';

  @override
  String get retry => '重试';

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
  String get cancel => '取消';

  @override
  String get delete => '删除';

  @override
  String get remove => '移除';

  @override
  String get save => '保存';

  @override
  String get done => '完成';

  @override
  String get edit => '编辑';

  @override
  String get search => '搜索';

  @override
  String get apply => '应用';

  @override
  String get enable => '启用';

  @override
  String get clear => '清除';

  @override
  String get off => '关闭';

  @override
  String get disabled => '已禁用';

  @override
  String get later => '稍后';

  @override
  String get gotIt => '知道了';

  @override
  String get preview => '预览';

  @override
  String get or => '或';

  @override
  String get file => '文件';

  @override
  String get more => '更多';

  @override
  String get unknown => '未知';

  @override
  String get untitled => '无标题';

  @override
  String get noThanks => '不了，谢谢';

  @override
  String get stay => '保留';

  @override
  String get homeTitle => '首页';

  @override
  String get continueListening => '继续收听';

  @override
  String get continueSeries => '继续收听系列';

  @override
  String get recentlyAdded => '最近添加';

  @override
  String get listenAgain => '重新收听';

  @override
  String get discover => '发现';

  @override
  String get newEpisodes => '最新单集';

  @override
  String get downloads => '下载';

  @override
  String get noDownloadedBooks => '暂无已下载书籍';

  @override
  String get yourLibraryIsEmpty => '您的媒体库空空如也';

  @override
  String get downloadBooksWhileOnline => '在线时下载书籍以离线收听';

  @override
  String get customizeHome => '自定义首页';

  @override
  String get dragToReorderTapEye => '拖动排序，点击眼睛图标显示/隐藏';

  @override
  String get loginTagline => '开始收听之旅';

  @override
  String get loginConnectToServer => '连接到您的服务器';

  @override
  String get loginServerAddress => '服务器地址';

  @override
  String get loginServerHint => 'my.server.com';

  @override
  String get loginServerHelper => '也支持 IP:端口 格式（例如 192.168.1.5:13378）';

  @override
  String get loginCouldNotReachServer => '无法连接到服务器';

  @override
  String get loginAdvanced => '高级';

  @override
  String get loginCustomHttpHeaders => '自定义 HTTP 请求头';

  @override
  String get loginCustomHeadersDescription =>
      '用于需要额外请求头的 Cloudflare 隧道或反向代理。请在输入服务器 URL 之前添加请求头。';

  @override
  String get loginHeaderName => '请求头名称';

  @override
  String get loginHeaderValue => '值';

  @override
  String get loginAddHeader => '添加请求头';

  @override
  String get loginSelfSignedCertificates => '自签名证书';

  @override
  String get loginTrustAllCertificates => '信任所有证书（用于自签名/自定义 CA 配置）';

  @override
  String get loginApiKey => 'API 密钥';

  @override
  String get loginApiKeyDescription =>
      '使用管理员生成的 API 密钥代替用户名/密码。当账号的令牌刷新失败时很有用。';

  @override
  String get loginWaitingForSso => '正在等待单点登录(SSO)...';

  @override
  String get loginRedirectUri => '重定向 URI: audiobookshelf://oauth';

  @override
  String get loginOrSignInManually => '或手动登录';

  @override
  String get loginUsername => '用户名';

  @override
  String get loginUsernameRequired => '请输入用户名';

  @override
  String get loginPassword => '密码';

  @override
  String get loginSignIn => '登录';

  @override
  String loginSignInAs(String username) {
    return '以 $username 登录？';
  }

  @override
  String get loginSignInToServer => '登录到此服务器？';

  @override
  String loginSignedInAs(String username) {
    return '已登录为 $username';
  }

  @override
  String get adminCreateSetupFile => '共享登录';

  @override
  String adminSetupFileDescription(String username) {
    return '为 $username 创建私密登录链接，只能用于 Absorb。';
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
  String get loginFailed => '登录失败';

  @override
  String get loginSsoFailed => '单点登录失败或已取消';

  @override
  String get loginSsoAuthFailed => '单点登录认证失败，请重试。';

  @override
  String get loginRestoreFromBackup => '从备份恢复';

  @override
  String get loginInvalidBackupFile => '无效的备份文件';

  @override
  String get loginRestoreBackupTitle => '恢复备份？';

  @override
  String loginRestoreBackupWithAccounts(int count) {
    return '这将恢复所有设置和 $count 个已保存的账户。你将自动登录。';
  }

  @override
  String get loginRestoreBackupNoAccounts => '这将恢复所有设置。此备份中不包含任何账户。';

  @override
  String get loginRestore => '恢复';

  @override
  String loginRestoredAndSignedIn(String username) {
    return '已恢复设置并以 $username 身份登录';
  }

  @override
  String get loginSessionExpired => '设置已恢复。会话已过期 - 请登录以继续。';

  @override
  String get loginSettingsRestored => '设置已恢复';

  @override
  String loginRestoreFailed(String error) {
    return '恢复失败: $error';
  }

  @override
  String get loginSavedAccounts => '已保存账户';

  @override
  String get libraryTitle => '媒体库';

  @override
  String get librarySearchBooksHint => '搜索书籍、系列、作者、旁白...';

  @override
  String get librarySearchShowsHint => '搜索播客和单集...';

  @override
  String get libraryTabLibrary => '媒体库';

  @override
  String get libraryTabSeries => '系列';

  @override
  String get libraryTabAuthors => '作者';

  @override
  String get libraryTabNarrators => '旁白';

  @override
  String get libraryNoBooks => '未找到书籍';

  @override
  String get libraryNoUnfinishedBooks => 'No unfinished books';

  @override
  String get libraryNoBooksInProgress => '暂无进行中的书籍';

  @override
  String get libraryNoFinishedBooks => '暂无已完成书籍';

  @override
  String get libraryAllBooksStarted => '所有书籍均已开始';

  @override
  String get libraryNoDownloadedBooks => '暂无已下载书籍';

  @override
  String get libraryNoSeriesFound => '未找到系列';

  @override
  String get libraryNoBooksWithEbooks => '暂无包含电子书的书籍';

  @override
  String get libraryNoBooksMissingMetadata =>
      'No books are missing this metadata';

  @override
  String get libraryNoItemsMatchingFilter => 'No items match this filter';

  @override
  String libraryNoBooksInGenre(String genre) {
    return '\"$genre\" 中没有找到书籍';
  }

  @override
  String libraryNoBooksWithTag(String tag) {
    return 'No books tagged \"$tag\"';
  }

  @override
  String get libraryClearFilter => '清除筛选';

  @override
  String get libraryNoAuthorsFound => '未找到作者';

  @override
  String get libraryNoNarratorsFound => '未找到旁白';

  @override
  String get libraryNoResults => '未找到结果';

  @override
  String get librarySearchBooks => '书籍';

  @override
  String get librarySearchShows => '播客';

  @override
  String get librarySearchEpisodes => '单集';

  @override
  String get librarySearchSeries => '系列';

  @override
  String get librarySearchAuthors => '作者';

  @override
  String get librarySearchTags => 'Tags';

  @override
  String get librarySearchGenres => 'Genres';

  @override
  String librarySeriesCount(int count) {
    return '$count 个系列';
  }

  @override
  String libraryAuthorsCount(int count) {
    return '$count 位作者';
  }

  @override
  String libraryNarratorsCount(int count) {
    return '$count 位旁白';
  }

  @override
  String libraryBooksCount(int loaded, int total) {
    return '已加载 $loaded/$total 本书';
  }

  @override
  String get sort => '排序';

  @override
  String get filter => '筛选';

  @override
  String get filterActive => '筛选 ●';

  @override
  String get name => '名称';

  @override
  String get title => '标题';

  @override
  String get author => '作者';

  @override
  String get dateAdded => '添加日期';

  @override
  String get numberOfBooks => '书籍数量';

  @override
  String get publishedYear => '出版年份';

  @override
  String get duration => '时长';

  @override
  String get random => '随机';

  @override
  String get collapseSeries => '折叠系列';

  @override
  String get notFinished => 'Not Finished';

  @override
  String get inProgress => '正在收听';

  @override
  String get filterFinished => '已听完';

  @override
  String get notStarted => '未开始';

  @override
  String get downloaded => '已下载';

  @override
  String get hasEbook => '含电子书';

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
  String get missingMetadata => '缺失元数据';

  @override
  String get genre => '分类';

  @override
  String get tag => 'Tag';

  @override
  String get clearFilter => '清除筛选';

  @override
  String get noGenresFound => '未找到分类';

  @override
  String get noTagsFound => 'No tags found';

  @override
  String get asc => '升序';

  @override
  String get desc => '降序';

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
  String get progressSort => '进度';

  @override
  String get dateStarted => '开始日期';

  @override
  String get dateFinished => '完成日期';

  @override
  String get episodeCount => '集数';

  @override
  String get sequence => '系列序号';

  @override
  String get absorbingTitle => '正在收听';

  @override
  String get absorbingStop => '停止';

  @override
  String get absorbingManageQueue => '管理队列';

  @override
  String get absorbingDone => '完成';

  @override
  String get absorbingNoDownloadedEpisodes => '暂无已下载剧集';

  @override
  String get absorbingNoDownloadedBooks => '暂无已下载书籍';

  @override
  String get absorbingNothingPlayingYet => '暂无正在播放的内容';

  @override
  String get absorbingNothingAbsorbingYet => '暂无收听中的内容';

  @override
  String get absorbingDownloadEpisodesToListen => '下载单集以离线收听';

  @override
  String get absorbingDownloadBooksToListen => '下载书籍以离线收听';

  @override
  String get absorbingStartEpisodeFromShows => '从播客标签页开始播放剧集';

  @override
  String get absorbingStartBookFromLibrary => '从媒体库标签页开始播放书籍';

  @override
  String get carModeTitle => '车载模式';

  @override
  String get carModeNoBookLoaded => '未加载书籍';

  @override
  String get carModeBookLabel => '书籍';

  @override
  String get carModeChapterLabel => '章节';

  @override
  String get carModeBookmarkDefault => '书签';

  @override
  String get carModeBookmarkAdded => '已添加书签';

  @override
  String get downloadsTitle => '下载';

  @override
  String get downloadsCancelSelection => '取消选择';

  @override
  String get downloadsSelect => '选择';

  @override
  String get downloadsNoDownloads => '暂无下载';

  @override
  String get downloadsDownloading => '下载中';

  @override
  String get downloadsQueued => '排队中';

  @override
  String get downloadsCompleted => '已完成';

  @override
  String get downloadsWaiting => '等待中...';

  @override
  String get downloadsCancel => '取消';

  @override
  String get downloadsDelete => '删除';

  @override
  String downloadsDeleteCount(int count) {
    return '删除 $count 个下载项？';
  }

  @override
  String get downloadsDeleteContent => '已下载的文件将从本设备中移除。';

  @override
  String downloadsDeletedCount(int count) {
    return '已删除 $count 个下载项';
  }

  @override
  String get downloadsRemoveTitle => '移除下载？';

  @override
  String downloadsRemoveContent(String title) {
    return '从本设备中删除 \"$title\"？';
  }

  @override
  String downloadsRemovedTitle(String title) {
    return '\"$title\" 已移除';
  }

  @override
  String downloadsSelectedCount(int count) {
    return '已选择 $count 项';
  }

  @override
  String get bookmarksTitle => '全部书签';

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
  String get bookmarksCancelSelection => '取消选择';

  @override
  String get bookmarksSortedByNewest => '按最新排序';

  @override
  String get bookmarksSortedByPosition => '按位置排序';

  @override
  String get bookmarksSelect => '选择';

  @override
  String get bookmarksNoBookmarks => '暂无书签';

  @override
  String bookmarksDeleteCount(int count) {
    return '删除 $count 个书签？';
  }

  @override
  String get bookmarksDeleteContent => '此操作无法撤销。';

  @override
  String bookmarksDeletedCount(int count) {
    return '已删除 $count 个书签';
  }

  @override
  String get bookmarksJumpTitle => '跳转到书签？';

  @override
  String bookmarksJumpContent(String title, String position, String bookTitle) {
    return '\"$title\" 位于 $position\n在《$bookTitle》中';
  }

  @override
  String get bookmarksJump => '跳转';

  @override
  String get bookmarksNotConnected => '未连接到服务器';

  @override
  String get bookmarksCouldNotLoad => '无法加载书籍';

  @override
  String bookmarksSelectedCount(int count) {
    return '已选择 $count 项';
  }

  @override
  String get statsTitle => '你的统计';

  @override
  String get statsCouldNotLoad => '无法加载统计数据';

  @override
  String get statsTotalListeningTime => '总收听时长';

  @override
  String get statsHoursUnit => '小时';

  @override
  String get statsMinutesUnit => '分钟';

  @override
  String get statsSecondsUnit => 's';

  @override
  String statsDaysOfAudio(String days) {
    return '相当于 $days 天的音频';
  }

  @override
  String statsHoursOfAudio(String hours) {
    return '相当于 $hours 小时的音频';
  }

  @override
  String get statsToday => '今日';

  @override
  String get statsThisWeek => '本周';

  @override
  String get statsThisMonth => '本月';

  @override
  String get statsActivity => '活动';

  @override
  String get statsCurrentStreak => '当前连续天数';

  @override
  String get statsBestStreak => '最佳连续天数';

  @override
  String get statsFinished => '已完成';

  @override
  String get statsBooksFinished => '书籍';

  @override
  String get statsEpisodesFinished => '单集';

  @override
  String get statsBooksThisYear => '今年书籍';

  @override
  String get statsEpisodesThisYear => '今年单集';

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
  String get statsChartDays7 => '7 天';

  @override
  String get statsChartDays30 => '30天';

  @override
  String get statsLast30Days => '过去 30 天';

  @override
  String get statsThisYearTitle => '今年';

  @override
  String get statsSectionsTitle => 'Sections';

  @override
  String get statsSectionTimePeriods => 'Time periods';

  @override
  String get statsHeatmapLess => '更少';

  @override
  String get statsHeatmapMore => '更多';

  @override
  String get statsDayOfWeek => '每周日均';

  @override
  String get statsTimeSavedLabel => 'Saved by speed';

  @override
  String statsTimeSavedSince(String date) {
    return '自 $date 起';
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
  String get statsDaysActive => '活跃天数';

  @override
  String get statsDailyAverage => '日均时长';

  @override
  String get statsLast7Days => '过去7天';

  @override
  String get statsMostListened => '收听最多';

  @override
  String get statsRecentSessions => '最近会话';

  @override
  String get appShellHomeTab => '首页';

  @override
  String get appShellLibraryTab => '媒体库';

  @override
  String get appShellAbsorbingTab => '正在收听';

  @override
  String get appShellStatsTab => '统计';

  @override
  String get appShellSettingsTab => '设置';

  @override
  String get appShellDiscoverTab => '发现';

  @override
  String get appShellShowsTab => '节目';

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
  String get podcastFilterUpNext => 'Up Next';

  @override
  String get podcastFilterNew => 'New';

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
  String get settingsEpisodeNotifs => 'Notification settings';

  @override
  String get settingsEpisodeNotifsDesc =>
      'New podcast episodes and upcoming book releases, checked in the background';

  @override
  String get notifIntervalOff => '关闭';

  @override
  String notifIntervalMinutes(int n) {
    return '每 $n 分钟';
  }

  @override
  String get notifIntervalHour => '每小时';

  @override
  String notifIntervalHours(int n) {
    return '每 $n 小时';
  }

  @override
  String get settingsBatteryUnrestricted => '允许不受限制地使用电池';

  @override
  String get settingsBatteryUnrestrictedDesc =>
      'Keeps the system from pausing background checks on some phones';

  @override
  String get appShellPressBackToExit => '再按一次返回键退出';

  @override
  String get settingsTitle => '设置';

  @override
  String get sectionAppearance => '外观';

  @override
  String get languageLabel => '语言';

  @override
  String get languageSystemDefault => '跟随系统';

  @override
  String get languageHelpTranslateInvite => '想帮 Absorb 翻译成你的语言吗？';

  @override
  String get themeLabel => '主题';

  @override
  String get themeDark => '深色';

  @override
  String get themeOled => 'OLED';

  @override
  String get themeLight => '浅色';

  @override
  String get themeAuto => '自动';

  @override
  String get colorSourceLabel => '颜色来源';

  @override
  String get colorSourceCoverDescription => '应用颜色跟随当前播放书籍的封面';

  @override
  String get colorSourceWallpaperDescription => '应用颜色跟随系统壁纸';

  @override
  String get colorSourceWallpaper => '壁纸';

  @override
  String get colorSourceNowPlaying => '正在播放';

  @override
  String get colorSourceDynamic => '动态';

  @override
  String get colorSourceManual => '手动';

  @override
  String get colorSourceManualDescription =>
      'Use a fixed app color you choose below';

  @override
  String get colorSourceCustom => '自定义';

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
  String get backgroundIntensityLabel => 'Background intensity';

  @override
  String get startScreenLabel => '启动画面';

  @override
  String get startScreenSubtitle => '应用启动时打开的标签页';

  @override
  String get startScreenHome => '首页';

  @override
  String get startScreenLibrary => '媒体库';

  @override
  String get startScreenAbsorb => '正在收听';

  @override
  String get startScreenStats => '统计';

  @override
  String get disablePageFade => '禁用页面淡入淡出';

  @override
  String get disablePageFadeOnSubtitle => '页面立即切换';

  @override
  String get disablePageFadeOffSubtitle => '切换标签页时页面淡入淡出';

  @override
  String get rectangleBookCovers => '矩形书籍封面';

  @override
  String get progressTextSize => 'Progress text size';

  @override
  String get rectangleBookCoversOnSubtitle => '封面以 2:3 的书籍比例显示';

  @override
  String get rectangleBookCoversOffSubtitle => '封面为正方形';

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
  String get sectionAbsorbingCards => '收听卡片';

  @override
  String get fullScreenPlayer => '全屏播放器';

  @override
  String get fullScreenPlayerOnSubtitle => '开启 - 播放时以全屏方式打开书籍';

  @override
  String get fullScreenPlayerOffSubtitle => '关闭 - 在卡片视图内播放';

  @override
  String get fullBookScrubber => '全书进度条';

  @override
  String get fullBookScrubberOnSubtitle => '开启 - 可拖动滑块跳转至全书任意位置';

  @override
  String get fullBookScrubberOffSubtitle => '关闭 - 仅显示进度条';

  @override
  String get cardScrubbers => 'Card scrubbers';

  @override
  String get cardScrubbersBoth => 'Both';

  @override
  String get cardScrubbersChapter => '章节';

  @override
  String get cardScrubbersLocked => '已锁定';

  @override
  String get cardScrubbersBothSubtitle => 'Full book and chapter bars can seek';

  @override
  String get cardScrubbersChapterSubtitle => 'Only the chapter bar can seek';

  @override
  String get cardScrubbersLockedSubtitle => 'Progress is shown without seeking';

  @override
  String get speedAdjustedTime => '变速后时间';

  @override
  String get speedAdjustedTimeOnSubtitle => '开启 - 剩余时间会根据播放速度变化';

  @override
  String get speedAdjustedTimeOffSubtitle => '关闭 - 显示原始音频时长';

  @override
  String get buttonLayout => '按钮布局';

  @override
  String get buttonLayoutSubtitle => '卡片上操作按钮的排列方式';

  @override
  String get whenAbsorbed => '当收听完成时';

  @override
  String get whenAbsorbedInfoTitle => '当收听完成时';

  @override
  String get whenAbsorbedInfoContent =>
      '控制当您完成一本书或一集后收听卡片的行为。\n\n已完成的卡片会自动从从您的“正在收听”屏幕中移除。';

  @override
  String get whenAbsorbedSubtitle => '听完一本书或或一集后收听卡片的处理方式';

  @override
  String get whenAbsorbedShowOverlay => '显示覆盖层';

  @override
  String get whenAbsorbedAutoRelease => '自动释放';

  @override
  String get mergeLibraries => '合并媒体库';

  @override
  String get mergeLibrariesInfoTitle => '合并媒体库';

  @override
  String get mergeLibrariesInfoContent =>
      '启用后，“正在收听”界面会将您所有媒体库中正在进行的书籍和播客集中显示在一个视图中。禁用时，仅显示您当前所选媒体库中的项目。';

  @override
  String get mergeLibrariesOnSubtitle => '正在收听页面显示来自所有媒体库的项目';

  @override
  String get mergeLibrariesOffSubtitle => '正在收听页面仅显示当前媒体库';

  @override
  String get queueMode => '队列模式';

  @override
  String get queueModeInfoTitle => '队列模式';

  @override
  String get queueModeInfoOff => '关闭';

  @override
  String get queueModeInfoOffDesc => '当前书籍或单集播放完成后停止播放。';

  @override
  String get queueModeInfoManual => '手动队列';

  @override
  String get queueModeInfoManualDesc =>
      '你的收听卡片将作为播放列表使用。当一个播放完成时，会自动播放下一个未完成的卡片。通过书籍或单集详情页的\"添加至正在收听\"按钮添加项目，并在收听界面重新排序。';

  @override
  String get queueModeOff => '关闭';

  @override
  String get queueModeManual => '手动';

  @override
  String get queueModeAuto => '自动';

  @override
  String get queueModePlaylist => '播放列表';

  @override
  String get queueModeCollection => 'Collection';

  @override
  String get queueModeInfoPlaylist => '播放队列';

  @override
  String get queueModeInfoPlaylistDesc => '按所选播放列表的顺序播放，跳过已完成的项目，并在列表结束时停止。';

  @override
  String get queuePlaylistPickerTitle => '选择一个播放列表';

  @override
  String get queuePlaylistNone => '没有选择播放列表';

  @override
  String queuePlaylistActiveLabel(String name) {
    return '播放列表：$name';
  }

  @override
  String get queueModePlaylistHint =>
      'Start a playlist queue by opening a playlist on the home page.';

  @override
  String get exit => '退出';

  @override
  String upNext(String label) {
    return 'Up next: $label';
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
  String get playlistPlayAction => '播放列表';

  @override
  String get playlistAllFinished => 'All finished';

  @override
  String get queueModeBooks => '书籍';

  @override
  String get queueModePodcasts => '播客';

  @override
  String get autoDownloadQueue => '自动下载队列';

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
    return '保留接下来 $count 个项目的下载';
  }

  @override
  String get autoDownloadQueueOffSubtitle => '关闭 - 仅手动下载';

  @override
  String get sectionPlayback => '播放';

  @override
  String get sectionMediaControls => 'Media Controls';

  @override
  String get defaultSpeed => '默认速度';

  @override
  String get defaultSpeedSubtitle => '新书以此速度开始播放 - 每本书会记住自己的速度';

  @override
  String get skipBack => '快退';

  @override
  String get skipForward => '快进';

  @override
  String get iosLockScreenSkipHint =>
      'The lock screen only draws the numbers iOS has icons for (5, 10, 15, 30, 45, 60, 75, 90). Other amounts show + on the button but still skip by your setting.';

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
  String get showSubtitles => 'Show subtitles';

  @override
  String get showSubtitlesOnSubtitle =>
      'Subtitles show under book titles in the library and on home';

  @override
  String get showSubtitlesOffSubtitle =>
      'Off - subtitles only on the book details sheet';

  @override
  String get subtitleVisibilityLabel => 'Subtitles';

  @override
  String get subtitleVisibilityDefault => 'Default';

  @override
  String get subtitleVisibilityShow => 'Show';

  @override
  String get subtitleVisibilityHide => 'Hide';

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
  String get chapterProgressInNotification => '通知中显示章节进度';

  @override
  String get chapterProgressOnSubtitle => '开启 - 锁屏显示章节进度';

  @override
  String get chapterProgressOffSubtitle => '关闭 - 锁屏显示全书进度';

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
  String get lockSeekBar => '锁定搜索栏';

  @override
  String get lockSeekBarOnSubtitle =>
      'On - the scrubber in the notification, lockscreen and car shows progress but can\'t be dragged';

  @override
  String get lockSeekBarOffSubtitle =>
      'Off - drag the scrubber in the notification, lockscreen and car to jump around';

  @override
  String get autoRewindOnResume => '恢复播放时自动倒退';

  @override
  String autoRewindOnSubtitle(String min, String max) {
    return '开启 - 根据暂停时长倒回 $min 秒至 $max 秒';
  }

  @override
  String get autoRewindOffSubtitle => '关闭';

  @override
  String get rewindRange => '倒回范围';

  @override
  String get rewindAfterPausedFor => '暂停后倒回';

  @override
  String get rewindAnyPause => '任何暂停';

  @override
  String get rewindAlwaysLabel => '始终';

  @override
  String get rewindAlwaysDescription => '每次恢复播放都倒回，即使是短暂中断';

  @override
  String rewindAfterDescription(String seconds) {
    return '仅在暂停 $seconds 秒以上时倒回';
  }

  @override
  String get chapterBarrier => '章节边界';

  @override
  String get chapterBarrierSubtitle => '不回退到当前章节开头之前';

  @override
  String get rewindInstant => '立即';

  @override
  String rewindPause(String duration) {
    return '暂停 $duration';
  }

  @override
  String get rewindNoRewind => '不倒回';

  @override
  String rewindSeconds(String seconds) {
    return '倒回 $seconds 秒';
  }

  @override
  String get sectionSleepTimer => '睡眠定时器';

  @override
  String get sleep => '睡眠';

  @override
  String get sleepTimer => '睡眠定时器';

  @override
  String get shakeDuringSleepTimer => '睡眠定时器期间摇一摇';

  @override
  String get shakeOff => '关闭';

  @override
  String get shakeAddTime => '添加时间';

  @override
  String get shakeReset => '重置';

  @override
  String get shakeAdds => '摇一摇添加';

  @override
  String get sleepAddAmount => 'Add time amount';

  @override
  String shakeAddsValue(int minutes) {
    return '$minutes 分钟';
  }

  @override
  String get shakeSensitivity => '摇一摇灵敏度';

  @override
  String get shakeSensitivityVeryLow => '非常低';

  @override
  String get shakeSensitivityLow => '低';

  @override
  String get shakeSensitivityMedium => '中';

  @override
  String get shakeSensitivityHigh => '高';

  @override
  String get shakeSensitivityVeryHigh => '非常高';

  @override
  String get buttonDuringSleepTimer => 'Headphone button during wind-down';

  @override
  String get buttonDuringSleepTimerHint =>
      'In the final wind-down moments, one press resets the timer instead of pausing. Double press still skips.';

  @override
  String get resetTimerOnPause => '暂停时重置定时器';

  @override
  String get resetTimerOnPauseOnSubtitle => '恢复播放时，定时器从完整时长重新开始';

  @override
  String get resetTimerOnPauseOffSubtitle => '定时器从上次停止的位置继续';

  @override
  String get fadeVolumeBeforeSleep => '睡前渐弱音量';

  @override
  String get fadeVolumeOnSubtitle => '在最后30秒逐渐降低音量';

  @override
  String get fadeVolumeOffSubtitle => '定时器结束时立即停止播放';

  @override
  String get autoSleepTimer => '自动睡眠定时器';

  @override
  String autoSleepTimerOnSubtitle(String start, String end, int duration) {
    return '$start - $end - $duration 分钟';
  }

  @override
  String get autoSleepTimerOffSubtitle => '在指定时间段内自动启动睡眠定时器';

  @override
  String get windowStart => '开始时间';

  @override
  String get windowEnd => '结束时间';

  @override
  String get timerDuration => '定时器时长';

  @override
  String get timer => '定时器';

  @override
  String get endOfChapter => '章节结束';

  @override
  String startMinTimer(int minutes) {
    return '启动 $minutes 分钟定时器';
  }

  @override
  String sleepAfterChapters(int count, String label) {
    return '在 $count $label后睡眠';
  }

  @override
  String get addMoreTime => '添加时间';

  @override
  String get cancelTimer => '取消定时器';

  @override
  String chaptersLeftCount(int count) {
    return '剩余 $count 章';
  }

  @override
  String get sectionDownloadsAndStorage => '下载与存储';

  @override
  String get downloadOverWifiOnly => '仅在 Wi-Fi 下下载';

  @override
  String get downloadOverWifiOnSubtitle => '开启 - 禁止使用移动数据下载';

  @override
  String get downloadOverWifiOffSubtitle => '关闭 - 任何网络均可下载';

  @override
  String get autoDownloadOnWifi => 'Wi-Fi 下自动下载';

  @override
  String get autoDownloadOnWifiInfoTitle => 'Wi-Fi 下自动下载';

  @override
  String get autoDownloadOnWifiInfoContent =>
      '当您开始在线播放书籍时，系统会在后台同步下载完整内容，无需手动操作即可实现离线收听。后台下载将严格遵循上方的“下载网络设置”，若您希望在移动网络下也能自动下载，请将其设置为“任意网络”。';

  @override
  String get autoDownloadOnWifiOnSubtitle => '在 Wi-Fi 下开始流式播放时，书籍将在后台下载';

  @override
  String get autoDownloadOnWifiOffSubtitle => '关闭';

  @override
  String get concurrentDownloads => '同时下载数';

  @override
  String get autoDownload => '自动下载';

  @override
  String get autoDownloadSubtitle => '在系列或播客详情页单独启用';

  @override
  String get autoDownloadEnabledFor => 'Turned on for';

  @override
  String get autoDownloadEnabledForNone => 'Nothing yet';

  @override
  String get autoDownloadSourceUnnamed => 'Not loaded yet';

  @override
  String get keepNext => '保留接下来';

  @override
  String get keepNextInfoTitle => '保留接下来';

  @override
  String get keepNextInfoContent =>
      '要保留下载的项目数量，包括你当前正在收听的项目。例如，\"保留接下来3个\"意味着当前书籍加上系列或播客中的下2本将保持下载状态。';

  @override
  String get deleteAbsorbedDownloads => '删除已完成的下载';

  @override
  String get deleteAbsorbedDownloadsInfoTitle => '删除已完成的下载';

  @override
  String get deleteAbsorbedDownloadsInfoContent =>
      '启用后，在 Absorb 中听完的已下载书籍或剧集会自动从此设备删除。如果你在网页端或其他设备上听完，保存在此设备上的下载不会被删除。';

  @override
  String get deleteAbsorbedOnSubtitle => '已完成项目将被移除以节省空间';

  @override
  String get deleteAbsorbedOffSubtitle => '关闭 - 保留已完成的下载';

  @override
  String get downloadLocation => '下载位置';

  @override
  String get storageUsed => '已用存储';

  @override
  String storageUsedByDownloads(String size) {
    return '下载已使用 $size';
  }

  @override
  String storageFreeOfTotal(String free, String total) {
    return '总计 $total，可用 $free';
  }

  @override
  String get manageDownloads => '管理下载';

  @override
  String get streamingCache => '流式缓存';

  @override
  String get streamingCacheInfoTitle => '流式缓存';

  @override
  String get streamingCacheInfoContent =>
      '将流式播放的音频缓存到磁盘，以便在快退或重复收听时无需重新下载。缓存会自动管理 - 达到大小限制时，最旧的文件会被移除。这与完全下载的书籍是分开的';

  @override
  String get streamingCacheOff => '关闭';

  @override
  String get streamingCacheOffSubtitle => '关闭 - 音频直接流式播放，不缓存';

  @override
  String streamingCacheOnSubtitle(int size) {
    return '$size MB - 最近流式播放的音频将缓存到磁盘';
  }

  @override
  String get clearCache => '清除缓存';

  @override
  String get streamingCacheCleared => '流式缓存已清除';

  @override
  String get sectionLibrary => '媒体库';

  @override
  String get hideEbookOnlyTitles => '隐藏仅含电子书的标题';

  @override
  String get hideEbookOnlyOnSubtitle => '隐藏没有音频文件的书籍';

  @override
  String get hideEbookOnlyOffSubtitle => '关 - 显示所有媒体库项目';

  @override
  String get showGoodreadsButton => '显示 Goodreads 按钮';

  @override
  String get showGoodreadsOnSubtitle => '书籍详情页显示 Goodreads 的链接';

  @override
  String get showGoodreadsOffSubtitle => '关 - 隐藏 Goodreads 按钮';

  @override
  String get sectionPermissions => '权限';

  @override
  String get notifications => '通知';

  @override
  String get notificationsSubtitle => '用于下载进度和播放控制';

  @override
  String get notificationsAlreadyEnabled => '通知权限已启用';

  @override
  String get unrestrictedBattery => '无限制电池权限';

  @override
  String get unrestrictedBatterySubtitle => '防止 Android 终止后台播放';

  @override
  String get batteryAlreadyUnrestricted => '电池优化已关闭';

  @override
  String get sectionIssuesAndSupport => '问题与支持';

  @override
  String get bugsAndFeatureRequests => '错误报告与功能请求';

  @override
  String get bugsAndFeatureRequestsSubtitle => '在 GitHub 上提交问题';

  @override
  String get joinDiscord => '加入 Discord';

  @override
  String get joinDiscordSubtitle => '社区、支持与更新';

  @override
  String get contact => '联系我们';

  @override
  String get contactSubtitle => '通过邮件发送设备信息';

  @override
  String get enableLogging => '启用日志记录';

  @override
  String get enableLoggingOnSubtitle => '开启 - 日志保存到文件（重启生效）';

  @override
  String get enableLoggingOffSubtitle => '关闭 - 不捕获日志';

  @override
  String get loggingEnabledSnackbar => '日志记录已启用 - 重启应用以开始捕获';

  @override
  String get loggingDisabledSnackbar => '日志记录已禁用 - 重启应用以停止捕获';

  @override
  String get sendLogs => '发送日志';

  @override
  String get sendLogsSubtitle => '以附件形式分享日志文件';

  @override
  String failedToShare(String error) {
    return '分享失败: $error';
  }

  @override
  String get clearLogs => '清除日志';

  @override
  String get logsCleared => '日志已清除';

  @override
  String get clearLogsQuestion => 'Clear logs?';

  @override
  String get clearLogsContent =>
      'This can\'t be undone. Send them first if you might want them.';

  @override
  String get sectionAdvanced => '高级';

  @override
  String get localServer => '本地服务器';

  @override
  String get localServerInfoTitle => '本地服务器';

  @override
  String get localServerInfoContent =>
      '如果你在家运行 Audiobookshelf 服务器，可以在此设置本地/局域网 URL。Absorb 在检测到您处于家庭网络时会自动切换到更快的本地连接，而在外出时则回退到远程 URL。';

  @override
  String get localServerOnConnectedSubtitle => '已通过本地服务器连接';

  @override
  String get localServerOnRemoteSubtitle => '已启用 - 正在使用远程服务器';

  @override
  String get localServerOffSubtitle => '在家庭 Wi-Fi 下自动切换到局域网服务器';

  @override
  String get localServerUrlLabel => '本地服务器 URL';

  @override
  String get localServerUrlHint => 'http://192.168.1.100:13378';

  @override
  String get localServerUrlSetSnackbar => '本地服务器 URL 已设置 - 当处于家庭网络时将自动连接';

  @override
  String get disableAudioFocus => '禁用音频焦点';

  @override
  String get disableAudioFocusInfoTitle => '音频焦点';

  @override
  String get disableAudioFocusInfoContent =>
      '默认情况下，Android 一次只给一个应用音频“焦点” - 当 Absorb 播放时，其他音频（音乐、视频）会暂停。禁用音频焦点可让 Absorb 与其他应用同时播放。无论此设置如何，来电时始终会暂停播放。';

  @override
  String get disableAudioFocusOnSubtitle => '开启 - 与其他音频同时播放（来电时仍会暂停）';

  @override
  String get disableAudioFocusOffSubtitle => '关闭 - Absorb 播放时其他音频暂停';

  @override
  String get restartRequired => '需要重启';

  @override
  String get restartRequiredContent => '音频焦点更改需要完全重启应用才能生效。立即关闭应用？';

  @override
  String get closeApp => '关闭应用';

  @override
  String get trustAllCertificates => '信任所有证书';

  @override
  String get trustAllCertificatesInfoTitle => '自签名证书';

  @override
  String get mp3IndexSeeking => 'MP3 index seeking';

  @override
  String get mp3IndexSeekingInfoTitle => 'MP3 Index Seeking';

  @override
  String get mp3IndexSeekingInfoContent =>
      'Only enable this if you have MP3 files that don\'t seek to the right position. Inaccurate seeking usually comes from variable bitrate (VBR) MP3s. Index seeking builds an exact time map as the file is read, so jumping near the end of a large MP3 can take a moment - especially when streaming, since the file has to be read up to that point. Takes effect the next time a book or podcast episode starts.';

  @override
  String get mp3IndexSeekingOnSubtitle =>
      'On - exact seeking for VBR MP3 files';

  @override
  String get mp3IndexSeekingOffSubtitle => 'Off - normal seeking';

  @override
  String get trustAllCertificatesInfoContent =>
      '如果你的 Audiobookshelf 服务器使用自签名证书或自定义根 CA，请启用此选项。启用后，Absorb 将跳过所有连接的 TLS 证书验证。仅在您信任当前网络环境时启用。';

  @override
  String get trustAllCertificatesOnSubtitle => '开启 - 接受所有证书';

  @override
  String get trustAllCertificatesOffSubtitle => '关闭 - 仅接受受信任的证书';

  @override
  String get supportTheDev => '支持开发者';

  @override
  String get buyMeACoffee => '请我喝杯咖啡';

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
    return 'Absorb v$version  -  服务器 $serverVersion';
  }

  @override
  String get backupAndRestore => '备份与恢复';

  @override
  String get backupAndRestoreSubtitle => '将所有设置保存到文件或从文件恢复';

  @override
  String get backUp => '备份';

  @override
  String get restore => '恢复';

  @override
  String get allBookmarks => '所有书签';

  @override
  String get allBookmarksSubtitle => '查看所有书籍的书签';

  @override
  String get switchAccount => '切换账户';

  @override
  String get addAccount => '添加账户';

  @override
  String get logOut => '退出登录';

  @override
  String get includeLoginInfoTitle => '包含登录信息？';

  @override
  String get includeLoginInfoContent =>
      '你是否希望在备份中包含所有已保存账号的登录凭据？\n\n这会让在新设备上恢复变得容易，但文件中将包含您的身份验证令牌。';

  @override
  String get noSettingsOnly => '否，仅设置';

  @override
  String get yesIncludeAccounts => '是，包含账户';

  @override
  String get backupSavedWithAccounts => '备份已保存（包含账户）';

  @override
  String get backupSavedSettingsOnly => '备份已保存（仅设置）';

  @override
  String backupFailed(String error) {
    return '备份失败: $error';
  }

  @override
  String get restoreBackupTitle => '恢复备份？';

  @override
  String get restoreBackupContent => '这将用备份中的值替换您当前的所有设置。';

  @override
  String fromAbsorbVersion(String version) {
    return '来自 Absorb v$version';
  }

  @override
  String restoreAccountsChip(int count) {
    return '$count 个账户';
  }

  @override
  String restoreBookmarksChip(int count) {
    return '$count 本书的书签';
  }

  @override
  String get restoreCustomHeadersChip => '自定义请求头';

  @override
  String get invalidBackupFile => '无效的备份文件';

  @override
  String get settingsRestoredSuccessfully => '设置恢复成功';

  @override
  String restoreFailed(String error) {
    return '恢复失败: $error';
  }

  @override
  String get logOutTitle => '退出登录？';

  @override
  String get logOutContent => '这将使你退出登录。你的下载内容将保留在本设备上。';

  @override
  String get signOut => '退出登录';

  @override
  String get changePasswordTitle => 'Change Password';

  @override
  String get changePasswordSubtitle =>
      'Update your Audiobookshelf password safely';

  @override
  String get currentPassword => 'Current password';

  @override
  String get newPassword => 'New password';

  @override
  String get confirmNewPassword => 'Confirm new password';

  @override
  String get passwordChangeEffect =>
      'Changing your password signs out your other Audiobookshelf sessions. This device stays signed in.';

  @override
  String get passwordFieldsRequired => 'Fill in all password fields';

  @override
  String get passwordsDoNotMatch => 'New passwords do not match';

  @override
  String get passwordChanged =>
      'Password changed. Other signed-in devices were disconnected.';

  @override
  String get passwordInvalid => 'The current password is incorrect';

  @override
  String get passwordChangeUnsupported =>
      'This server version does not support safe password changes in Absorb';

  @override
  String get passwordChangeFailed => 'Could not change your password';

  @override
  String get otherUserPasswordResetWarning =>
      'Changing this password signs the user out on every device.';

  @override
  String get manageSessionsTitle => 'Signed-in Devices';

  @override
  String get manageSessionsSubtitle =>
      'Review and remove Audiobookshelf sessions';

  @override
  String get sessionsCurrent => 'Current device';

  @override
  String get sessionsUnknownDevice => 'Unknown device';

  @override
  String sessionsLastActive(String date) {
    return 'Last active $date';
  }

  @override
  String get sessionsNone => 'No active sessions';

  @override
  String get sessionsLoadMore => 'Load more';

  @override
  String get sessionsUnsupported =>
      'Session management requires Audiobookshelf 2.36 or newer.';

  @override
  String get sessionsLoadFailed => 'Could not load signed-in devices';

  @override
  String get sessionsLegacyNotice =>
      'This login does not have a refresh session, so Absorb cannot identify this device in the list.';

  @override
  String get sessionsRemove => 'Sign out device';

  @override
  String get sessionsRemoveTitle => 'Sign out this device?';

  @override
  String get sessionsRemoveContent =>
      'This removes its refresh session. Its current access may keep working until that short-lived token expires.';

  @override
  String get sessionsRemoved => 'Device signed out';

  @override
  String get sessionsRemoveFailed => 'Could not sign out that device';

  @override
  String get sessionsSignOutAll => 'Sign out all devices';

  @override
  String get sessionsSignOutAllTitle => 'Sign out everywhere?';

  @override
  String get sessionsSignOutAllContent =>
      'This removes every refresh session, including this device. Existing access tokens may work until they expire.';

  @override
  String podcastScheduleServerTime(String timeZone) {
    return 'Schedule uses server time ($timeZone)';
  }

  @override
  String get podcastScheduleServerTimeUnknown => 'Schedule uses server time';

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
  String get removeAccountAction => 'Remove account';

  @override
  String get removeAccountTitle => '移除账户？';

  @override
  String removeAccountContent(String username, String server) {
    return '从已保存账户中移除 $server 上的 $username？\n\n您可以稍后通过重新登录来再次添加。';
  }

  @override
  String get switchAccountTitle => '切换账户？';

  @override
  String switchAccountContent(String username, String server) {
    return '切换到 $server 上的 $username？\n\n你当前的播放将停止，应用将重新加载另一个账户的数据。';
  }

  @override
  String get switchButton => '切换';

  @override
  String get downloadLocationSheetTitle => '下载位置';

  @override
  String get downloadLocationSheetSubtitle => '选择有声读物的保存位置';

  @override
  String get currentLocation => '当前位置';

  @override
  String get existingDownloadsWarning => '现有的下载内容会保留在其当前位置。只有新的下载内容才会使用新路径。';

  @override
  String get chooseFolder => '选择文件夹';

  @override
  String get chooseDownloadFolder => '选择下载文件夹';

  @override
  String get storagePermissionDenied => '存储权限已被永久拒绝 - 请在应用设置中启用';

  @override
  String get openSettings => '打开设置';

  @override
  String get storagePermissionRequired => '自定义下载位置需要存储权限';

  @override
  String get cannotWriteToFolder => '无法写入该文件夹 - 请选择其他位置或在系统设置中授予文件访问权限';

  @override
  String downloadLocationSetTo(String label) {
    return '下载位置已设置为 $label';
  }

  @override
  String get resetToDefault => '重置为默认';

  @override
  String get resetToDefaultStorage => '重置为默认存储';

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
  String get tipsAndHiddenFeatures => '技巧与隐藏功能';

  @override
  String get tipsSubtitle => '充分利用 Absorb';

  @override
  String get adminTitle => '服务器管理';

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
  String get adminServer => '服务器';

  @override
  String get adminVersion => '版本';

  @override
  String get adminUsers => '用户';

  @override
  String get adminOnline => '在线';

  @override
  String get adminBackup => '备份';

  @override
  String get adminPurgeCache => '清除缓存';

  @override
  String get adminManage => '管理';

  @override
  String adminUsersSubtitle(int userCount, int onlineCount) {
    return '$userCount 个账户 - $onlineCount 人在线';
  }

  @override
  String get adminPodcasts => '播客';

  @override
  String get adminPodcastsSubtitle => '搜索、添加和管理节目';

  @override
  String get adminScan => '扫描';

  @override
  String get adminScanning => '正在扫描...';

  @override
  String get adminMatchAll => '匹配全部';

  @override
  String get adminMatching => '正在匹配...';

  @override
  String get adminMatchAllTitle => '匹配所有项目？';

  @override
  String adminMatchAllContent(String name) {
    return '为 $name 中的所有项目匹配元数据？这可能需要一些时间。';
  }

  @override
  String adminScanStarted(String name) {
    return '已开始扫描 $name';
  }

  @override
  String get adminBackupCreated => '备份已创建';

  @override
  String get adminBackupFailed => '备份失败';

  @override
  String get adminCachePurged => '缓存已清除';

  @override
  String get adminRmab => 'ReadMeABook';

  @override
  String get adminRmabSubtitle => '在应用中打开';

  @override
  String get adminRmabAdd => '添加 ReadMeABook 集成';

  @override
  String get adminRmabUrlTitle => 'ReadMeABook URL';

  @override
  String get adminRmabUrlHelp => '粘贴包含登录令牌的 URL。在 RMAB 的管理 -> 用户中生成。';

  @override
  String get adminRmabUrlHint => 'https://rmab.example.com/?token=...';

  @override
  String get adminRmabInvalidUrl => '请输入有效的 http(s) URL';

  @override
  String get adminRmabSaved => '已保存 ReadMeABook';

  @override
  String get adminRmabRemoved => '已移除 ReadMeABook';

  @override
  String get adminRmabReload => '重新加载';

  @override
  String get adminRmabLoadFailed => '无法加载 ReadMeABook，请检查 URL。';

  @override
  String get adminRmabConnected => '已连接';

  @override
  String get adminRmabAskAdmin => '请向您的服务器管理员获取登录 URL';

  @override
  String get adminRmabUrlHelpUser =>
      '请向您的服务器管理员获取登录 URL，管理员可在 RMAB 的管理 -> 用户中生成。';

  @override
  String get adminRmabSettingsInfo =>
      'ReadMeABook 是一个用于请求和下载有声书的自托管服务，需要由您的服务器管理员安装和设置。';

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
  String get rmabConfigTokenLabel => 'API token';

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
  String get rmabConfigHeadersHelp =>
      'Extra headers sent with every ReadMeABook request, for reverse proxies like Cloudflare Access.';

  @override
  String get rmabConfigConnect => 'Connect';

  @override
  String get rmabConfigDisconnect => 'Disconnect';

  @override
  String get rmabConfigOpenWebView => 'Open in browser view';

  @override
  String rmabConfigConnectedAs(String name) {
    return 'Connected as $name';
  }

  @override
  String get rmabConfigErrorInvalidUrl => 'Enter a valid http(s) URL';

  @override
  String get rmabConfigErrorMissingToken => 'Enter your API token';

  @override
  String get rmabConfigErrorUnauthorized => 'Token rejected by server';

  @override
  String get rmabConfigErrorForbidden =>
      'This token isn\'t allowed for that action';

  @override
  String get rmabConfigErrorNetwork => 'Couldn\'t reach RMAB. Check the URL.';

  @override
  String get rmabConfigErrorGeneric => 'Couldn\'t connect';

  @override
  String get rmabConfigSavedSnackbar => 'ReadMeABook connected';

  @override
  String get rmabConfigDisconnectedSnackbar => 'ReadMeABook disconnected';

  @override
  String get rmabRequestCta => 'Request via ReadMeABook';

  @override
  String get rmabSearchHeader => 'Request via ReadMeABook';

  @override
  String get rmabSearchHint => 'Search by title or author';

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
  String get rmabBookAlreadyAvailable => 'Already in your library';

  @override
  String get rmabBookAlreadyRequested => 'Already requested';

  @override
  String get rmabRequestSubmitting => 'Submitting…';

  @override
  String get rmabRequestSent => 'Request sent';

  @override
  String get rmabRequestErrorAlreadyAvailable => 'Already in your library';

  @override
  String get rmabRequestErrorBeingProcessed => 'Already being processed';

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
  String get rmabMyRequestsTab => 'My Requests';

  @override
  String get rmabSetupTab => 'Setup';

  @override
  String get rmabMyRequestsEmpty => 'You haven\'t requested any books yet';

  @override
  String get rmabMyRequestsError => 'Couldn\'t load requests';

  @override
  String get rmabMyRequestsRefresh => 'Refresh';

  @override
  String get rmabRequestDetailTitle => 'Request details';

  @override
  String get rmabRequestDetailStatus => 'Status';

  @override
  String get rmabRequestDetailRequestedOn => 'Requested on';

  @override
  String get rmabRequestDetailCompletedOn => 'Completed on';

  @override
  String get rmabRequestDetailProgress => 'Progress';

  @override
  String get rmabStatusActive => 'In progress';

  @override
  String get rmabStatusWaiting => 'Waiting';

  @override
  String get rmabStatusAvailable => 'Available';

  @override
  String get rmabStatusDownloaded => 'Downloaded';

  @override
  String get rmabStatusFailed => 'Failed';

  @override
  String get rmabStatusCancelled => 'Cancelled';

  @override
  String get rmabStatusDenied => 'Denied';

  @override
  String get rmabStatusUnknown => 'Unknown';

  @override
  String narratedBy(String narrator) {
    return '朗读者: $narrator';
  }

  @override
  String get onAudible => '在 Audible 上';

  @override
  String percentComplete(String percent) {
    return '已完成 $percent%';
  }

  @override
  String get absorbing => '收听中...';

  @override
  String get absorbAgain => '重新收听';

  @override
  String get absorb => '收听';

  @override
  String get ebookOnlyNoAudio => '仅电子书 - 无音频';

  @override
  String get fullyAbsorbed => '已完成';

  @override
  String get fullyAbsorbAction => '标记为已完成';

  @override
  String get removeFromAbsorbing => '从收听中移除';

  @override
  String get addToAbsorbing => '添加到收听中';

  @override
  String get removedFromAbsorbing => '已从收听中移除';

  @override
  String get addedToAbsorbing => '已添加到收听中';

  @override
  String get removeFromContinueListening => '移出继续收听';

  @override
  String get removedFromContinueListening => '已从“继续收听”中移出';

  @override
  String get removeSeriesFromContinueSeries => 'Remove from Continue Series';

  @override
  String get removedSeriesFromContinueSeries => 'Removed from Continue Series';

  @override
  String get couldNotUpdate => 'Could not update, try again';

  @override
  String get addToPlaylist => '添加到播放列表';

  @override
  String get addToCollection => '添加到收藏集';

  @override
  String get downloadEbook => '下载电子书';

  @override
  String get downloadEbookAgain => '重新下载电子书';

  @override
  String get resetProgress => '重置进度';

  @override
  String get lookupLocalMetadata => '查找本地元数据';

  @override
  String get reLookupLocalMetadata => '重新查找本地元数据';

  @override
  String get clearLocalMetadata => '清除本地元数据';

  @override
  String get searchOnGoodreads => '在 Goodreads 上搜索';

  @override
  String get editServerDetails => '编辑服务器详情';

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
  String get stereo => 'Stereo';

  @override
  String get startM4bEncode => 'Start M4B Encode';

  @override
  String get encodeStarted => 'M4B encode started';

  @override
  String get encodeFailed => 'Failed to start encode';

  @override
  String get encodeFinished => 'M4B encode finished';

  @override
  String get currentlyLabel => 'Currently:';

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
  String get aboutSection => '关于';

  @override
  String chaptersCount(int count) {
    return '章节 ($count)';
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
  String get chapters => '章节';

  @override
  String get noChaptersBook => 'This book has no chapters';

  @override
  String get noChaptersPodcast => 'This podcast has no chapters';

  @override
  String get failedToLoad => '加载失败';

  @override
  String startedDate(String date) {
    return '开始于 $date';
  }

  @override
  String finishedDate(String date) {
    return '完成于 $date';
  }

  @override
  String andCountMore(int count) {
    return '还有 $count 个';
  }

  @override
  String get markAsFullyAbsorbedQuestion => '标记为已完成？';

  @override
  String get markAsFullyAbsorbedContent => '这将把你的进度设置为100%，如果这本书正在播放则停止播放。';

  @override
  String get markedAsFinishedNiceWork => '已标记为完成 - 干得漂亮！';

  @override
  String get failedToUpdateCheckConnection => '更新失败 - 请检查您的网络连接';

  @override
  String get markAsNotFinishedQuestion => '标记为未完成？';

  @override
  String get markAsNotFinishedContent => '这将清除完成状态，但保留你当前的位置。';

  @override
  String get unmark => '取消标记';

  @override
  String get markedAsNotFinishedBackAtIt => '已标记为未完成 - 继续加油！';

  @override
  String get resetProgressQuestion => '重置进度？';

  @override
  String get resetProgressContent => '这将清除这本书的所有进度并将其重置到开头。此操作无法撤销。';

  @override
  String get progressResetFreshStart => '进度已重置 - 全新开始！';

  @override
  String get clearLocalMetadataQuestion => '清除本地元数据？';

  @override
  String get clearLocalMetadataContent => '这将删除本地存储的元数据并恢复为服务器上的内容。';

  @override
  String get localMetadataCleared => '本地元数据已清除';

  @override
  String get saveEbook => '保存电子书';

  @override
  String get noEbookFileFound => '未找到电子书文件';

  @override
  String get bookmark => '书签';

  @override
  String get bookmarks => '书签';

  @override
  String bookmarksWithCount(int count) {
    return '书签 ($count)';
  }

  @override
  String get playbackSpeed => '播放速度';

  @override
  String get noBookmarksYet => '暂无书签';

  @override
  String get longPressBookmarkHint => '长按书签按钮快速保存';

  @override
  String get addBookmark => '添加书签';

  @override
  String get editBookmark => '编辑书签';

  @override
  String get titleLabel => '标题';

  @override
  String get noteOptionalLabel => '备注（可选）';

  @override
  String get editLayout => '编辑布局';

  @override
  String get inMenu => '在菜单中';

  @override
  String get bookmarkAdded => '已添加书签';

  @override
  String get startPlayingSomethingFirst => '请先开始播放内容';

  @override
  String get playbackHistory => '播放历史';

  @override
  String get historyLocalTab => 'History';

  @override
  String get historyServerTab => 'Sessions';

  @override
  String get historyNoServerSessions => 'No server sessions for this item yet';

  @override
  String get historyServerLoadFailed => 'Could not load server sessions';

  @override
  String get clearHistoryTooltip => '清除历史';

  @override
  String get tapEventToJump => '点击事件跳转到对应位置';

  @override
  String get noHistoryYet => '暂无历史';

  @override
  String jumpedToPosition(String position) {
    return '已跳转到 $position';
  }

  @override
  String booksInSeriesCount(int count) {
    return '本系列共 $count 本书';
  }

  @override
  String bookNumber(String number) {
    return '第 $number 本';
  }

  @override
  String downloadRemainingCount(int count) {
    return '剩余下载 ($count)';
  }

  @override
  String get downloadAll => '全部下载';

  @override
  String get markAllNotFinished => '全部标记为未完成';

  @override
  String get markAllFinished => '全部标记为已完成';

  @override
  String get markAllNotFinishedQuestion => '全部标记为未完成？';

  @override
  String get fullyAbsorbSeries => '将系列全部标记为已完成？';

  @override
  String get turnAutoDownloadOff => '关闭自动下载';

  @override
  String get turnAutoDownloadOn => '开启自动下载';

  @override
  String get autoDownloadThisSeries => '自动下载此系列？';

  @override
  String get autoDownloadSeriesContent => '边听边自动下载后续书籍。';

  @override
  String get standalone => '独立';

  @override
  String get episodes => '剧集';

  @override
  String get noEpisodesFound => '未找到剧集';

  @override
  String get markFinished => '标记为完成';

  @override
  String get markUnfinished => '标记为未完成';

  @override
  String get allEpisodes => '全部剧集';

  @override
  String get aboutThisEpisode => '关于本集';

  @override
  String get reversePlayOrder => '倒序播放';

  @override
  String selectedCount(int count) {
    return '已选择 $count 项';
  }

  @override
  String get selectAll => '全选';

  @override
  String get deselectAll => 'Deselect All';

  @override
  String get autoDownloadThisPodcast => '自动下载此播客？';

  @override
  String get autoDownloadPodcastContent => '边听边自动下载后续剧集。';

  @override
  String get download => '下载';

  @override
  String get deleteDownload => '删除下载';

  @override
  String get casting => '投屏';

  @override
  String get castingTo => '正在投屏到';

  @override
  String get editDetails => '编辑详情';

  @override
  String get quickMatch => '快速匹配';

  @override
  String get quickMatchNoUpdates => 'No updates necessary';

  @override
  String get custom => '自定义';

  @override
  String get authorOptionalLabel => '作者（可选）';

  @override
  String get noResultsFound => '未找到结果。\n请调整搜索条件或提供商。';

  @override
  String get searchForMetadataAbove => '搜索上方的元数据';

  @override
  String get applyThisMatch => '应用此匹配？';

  @override
  String get metadataUpdated => '元数据已更新';

  @override
  String get failedToUpdateMetadata => '元数据更新失败';

  @override
  String get subtitleLabel => '副标题';

  @override
  String get authorLabel => '作者';

  @override
  String get narratorLabel => '朗读者';

  @override
  String get seriesLabel => '系列';

  @override
  String get addSeries => 'Add series';

  @override
  String get removeSeries => 'Remove series';

  @override
  String get descriptionLabel => '描述';

  @override
  String get publisherLabel => '出版商';

  @override
  String get yearLabel => '年份';

  @override
  String get genresLabel => '分类';

  @override
  String get tagsLabel => 'Tags';

  @override
  String get commaSeparated => '逗号分隔';

  @override
  String get asinLabel => 'ASIN';

  @override
  String get isbnLabel => 'ISBN';

  @override
  String get coverImage => '封面图片';

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
  String get coverUrlLabel => '封面 URL';

  @override
  String get coverUrlHint => 'https://...';

  @override
  String get localMetadata => '本地元数据';

  @override
  String get overrideLocalDisplay => '覆盖本地显示';

  @override
  String get metadataSavedLocally => '元数据已本地保存';

  @override
  String get notes => '笔记';

  @override
  String get newNote => '新建笔记';

  @override
  String get editNote => '编辑笔记';

  @override
  String get noNotesYet => '暂无笔记';

  @override
  String get markdownIsSupported => '支持 Markdown';

  @override
  String get markdownMd => 'Markdown (.md)';

  @override
  String get keepsFormattingIntact => '保留完整格式';

  @override
  String get plainTextTxt => '纯文本 (.txt)';

  @override
  String get simpleTextNoFormatting => '简单文本，无格式';

  @override
  String get untitledNote => '无标题笔记';

  @override
  String get titleHint => '标题';

  @override
  String get noteBodyHint => '写下你的笔记...（支持 Markdown）';

  @override
  String get nothingToPreview => '暂无预览内容';

  @override
  String get audioEnhancements => '音频增强';

  @override
  String get presets => '预设';

  @override
  String get equalizer => '均衡器';

  @override
  String get effects => '效果';

  @override
  String get bassBoost => '低音增强';

  @override
  String get surround => '环绕声';

  @override
  String get loudness => '响度';

  @override
  String get monoAudio => '单声道音频';

  @override
  String get skipSilence => 'Skip Silence';

  @override
  String get resetAll => '全部重置';

  @override
  String get collectionNotFound => '未找到收藏集';

  @override
  String get deleteCollection => '删除收藏集';

  @override
  String get deleteCollectionContent => '你确定要删除此收藏集吗？';

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
  String get playlistNotFound => '未找到播放列表';

  @override
  String get deletePlaylist => '删除播放列表';

  @override
  String get deletePlaylistContent => '你确定要删除此播放列表吗？';

  @override
  String get newPlaylist => '新建播放列表';

  @override
  String get playlistNameHint => '播放列表名称';

  @override
  String addedToName(String name) {
    return '已添加到 \"$name\"';
  }

  @override
  String get failedToAdd => '添加失败';

  @override
  String get newCollection => '新建收藏集';

  @override
  String get collectionNameHint => '收藏集名称';

  @override
  String get castToDevice => '投屏到设备';

  @override
  String get searchingForCastDevices => '正在搜索投屏设备...';

  @override
  String get castDevice => '投屏设备';

  @override
  String get stopCasting => '停止投屏';

  @override
  String get disconnect => '断开连接';

  @override
  String get audioOutput => '音频输出';

  @override
  String get noOutputDevicesFound => '未找到输出设备';

  @override
  String get welcomeToAbsorb => '欢迎使用 Absorb';

  @override
  String get welcomeTagline => '一个 Audiobookshelf 客户端。';

  @override
  String get welcomeAbsorbingTitle => '正在收听';

  @override
  String get welcomeAbsorbingIntro => '我们用 \"absorb\" 代替 \"播放\" 和 \"收听\"。';

  @override
  String get welcomeAbsorbingTabBullet => '正在收听标签页 - 你当前正在收听的内容';

  @override
  String get welcomeAbsorbButtonBullet => 'Absorb 按钮 - 开始播放';

  @override
  String get welcomeFullyAbsorbBullet => 'Fully Absorb - 标记为已完成';

  @override
  String get welcomeGettingAroundTitle => '界面操作';

  @override
  String get welcomeGettingAroundBody =>
      '点击任意封面打开详情。继续收听卡片不一样 - 点击立即播放，长按打开详情。';

  @override
  String get welcomeMakeItYoursTitle => '个性化设置';

  @override
  String get welcomeMakeItYoursBody =>
      '在设置中自定义 Absorb 以符合你的喜好。其中的「技巧与隐藏功能」区块值得一看。';

  @override
  String get getStarted => '开始使用';

  @override
  String get showMore => '显示更多';

  @override
  String get showLess => '显示更少';

  @override
  String get readMore => '阅读更多';

  @override
  String get removeDownloadQuestion => '移除下载？';

  @override
  String get removeDownloadContent => '这将从你的设备中移除。';

  @override
  String get downloadRemoved => '下载已移除';

  @override
  String get finished => '已完成';

  @override
  String get saved => '已保存';

  @override
  String get selectLibrary => '选择媒体库';

  @override
  String get switchLibraryTooltip => '切换媒体库';

  @override
  String get refreshTooltip => 'Refresh';

  @override
  String get noBooksFound => '未找到书籍';

  @override
  String get userFallback => '用户';

  @override
  String get rootAdmin => '超级管理员';

  @override
  String get admin => '管理员';

  @override
  String get serverAdmin => '服务器管理员';

  @override
  String get serverAdminSubtitle => '管理用户、媒体库和服务器设置';

  @override
  String serverUpdateAvailable(String version) {
    return 'Server update $version available';
  }

  @override
  String get justNow => '刚刚';

  @override
  String minutesAgo(int count) {
    return '$count 分钟前';
  }

  @override
  String hoursAgo(int count) {
    return '$count 小时前';
  }

  @override
  String daysAgo(int count) {
    return '$count 天前';
  }

  @override
  String get audible => 'Audible';

  @override
  String get iTunes => 'iTunes';

  @override
  String get openLibrary => '打开媒体库';

  @override
  String get root => 'Root';

  @override
  String get coverPlayPause => '点击封面播放/暂停';

  @override
  String get coverPlayPauseOnSubtitle => '开启 - 点击封面播放/暂停';

  @override
  String get coverPlayPauseOffSubtitle => '关闭 - 使用控制栏中的播放/暂停按钮';

  @override
  String get cardBackground => 'Card background';

  @override
  String get cardBackgroundBlurred => 'Blurred';

  @override
  String get cardBackgroundGradient => 'Gradient';

  @override
  String get queueModeMergedSubtitle => '可选择停止播放、手动队列，或自动播放下一项';

  @override
  String get queueModeSeriesLabel => '系列';

  @override
  String get queueModeShowLabel => 'Show';

  @override
  String get queueModeInfoSeries => '系列';

  @override
  String get queueModeInfoSeriesDesc => '自动播放同系列的下一本书，或播客节目的下一集。';

  @override
  String get resetButtonGridQuestion => '确认重置按钮布局？';

  @override
  String get resetButtonGridContent => '这将恢复默认的按钮布局、顺序和开关设置。';

  @override
  String get reset => '重置';

  @override
  String get buttonGridReset => 'Button grid reset';

  @override
  String get resetButtonGrid => '重置按钮布局';

  @override
  String get chapterBarrierOnRewind => 'Chapter barrier on rewind';

  @override
  String get chapterBarrierInfoTitle => 'Chapter barrier';

  @override
  String get chapterBarrierInfoContent =>
      'When skipping back, the playback will snap to the start of the current chapter instead of crossing into the previous one.\n\nDouble-tap the skip back button within 2 seconds to break through the barrier.';

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
      'Normal auto-rewind triggers when you resume from a pause within an active session. This setting adds a rewind when starting a completely new session - for example after the app was closed, playback was stopped, or you open the app fresh.\n\nWhen enabled, playback rewinds by the full max rewind amount at the start of every new session so you can re-hear where you left off.';

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
    return '${seconds}s pause';
  }

  @override
  String rewindMinPause(String minutes) {
    return '$minutes min pause';
  }

  @override
  String rewindHrPause(String hours) {
    return '$hours hr pause';
  }

  @override
  String get rewindOneHrPause => '1 hr pause';

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
    return '$minutes min';
  }

  @override
  String get chimeBeforeSleep => '睡前提示音';

  @override
  String get chimeBeforeSleepOnSubtitle => '在定时器即将结束时播放轻柔的提示铃声';

  @override
  String get chimeBeforeSleepOffSubtitle => '睡前无提示音';

  @override
  String get windDownDuration => 'Wind-down duration';

  @override
  String windDownDurationSubtitle(int seconds) {
    return '定时结束$seconds 秒前开始淡出并提示';
  }

  @override
  String fadeVolumeOnSubtitleDynamic(int seconds) {
    return '在最后 $seconds 秒内逐渐降低音量';
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
  String get endOfChapterShort => '章节结束';

  @override
  String get endOfChapterOnSubtitle => '在当前章节结束时停止播放';

  @override
  String get endOfChapterOffSubtitle => '使用睡眠定时器';

  @override
  String get showExplicitBadge => '显示敏感内容标记';

  @override
  String get showExplicitBadgeOnSubtitle => '敏感内容会显示 “E” 标记';

  @override
  String get showExplicitBadgeOffSubtitle => '关闭 - 隐藏敏感内容标记';

  @override
  String get libraryFallback => 'Library';

  @override
  String get preReleaseUpdatesInfoTitle => 'Pre-release Updates';

  @override
  String get preReleaseUpdatesInfoContent =>
      'When enabled, the update checker will also notify you about alpha and pre-release builds from GitHub. These may be less stable but include the latest features and fixes.';

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
  String get checkForUpdate => 'Check for update';

  @override
  String get onLatestVersion => 'You\'re on the latest version';

  @override
  String get updateAvailable => 'Update available';

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
  String get downloadButton => 'Download';

  @override
  String get updateDownloading => 'Downloading update...';

  @override
  String get updateInstallPermissionDenied =>
      'Install permission denied. Enable \"Install unknown apps\" for Absorb in system settings.';

  @override
  String get updateOpeningInBrowser => 'In-app update failed, opening browser';

  @override
  String get sendToEreader => 'Send to E-Reader';

  @override
  String sendingToEreader(String device) {
    return 'Sending to $device...';
  }

  @override
  String sendToEreaderSuccess(String device) {
    return 'Sent to $device';
  }

  @override
  String get sendToEreaderFailed => 'Couldn\'t send the ebook';

  @override
  String get pickEreaderDevice => 'Pick a device';

  @override
  String get adminEmail => 'Email';

  @override
  String get adminEmailSubtitle => 'SMTP and e-reader devices';

  @override
  String get smtpSection => 'SMTP';

  @override
  String get smtpSetupGuide => 'Setup guide';

  @override
  String get smtpHost => 'Host';

  @override
  String get smtpPort => 'Port';

  @override
  String get smtpSecure => 'Secure';

  @override
  String get smtpRejectUnauthorized => 'Reject unauthorized TLS';

  @override
  String get smtpUser => 'Username';

  @override
  String get smtpPass => 'Password';

  @override
  String get smtpFromAddress => 'From address';

  @override
  String get smtpTestAddress => 'Test address';

  @override
  String get smtpSendTest => 'Send test';

  @override
  String get smtpSaveSettings => 'Save';

  @override
  String get smtpSaved => 'Email settings saved';

  @override
  String get smtpSaveFailed => 'Couldn\'t save email settings';

  @override
  String get smtpTestSent => 'Test email sent';

  @override
  String get smtpTestFailed => 'Test email failed';

  @override
  String get ereaderDevicesTitle => 'E-Reader devices';

  @override
  String get ereaderDevicesEmpty => 'No devices yet. Add one below.';

  @override
  String get addEreaderDevice => 'Add device';

  @override
  String get editEreaderDevice => 'Edit device';

  @override
  String get deleteEreaderDevice => 'Delete';

  @override
  String get ereaderDeviceName => 'Name';

  @override
  String get ereaderDeviceEmail => 'Email';

  @override
  String get ereaderAvailability => 'Who can use this device';

  @override
  String get ereaderAvailAdminOrUp => 'Admins only';

  @override
  String get ereaderAvailUserOrUp => 'All users';

  @override
  String get ereaderAvailGuestOrUp => 'Everyone';

  @override
  String get ereaderAvailSpecificUsers => 'Specific users';

  @override
  String ereaderSpecificUsersN(int count) {
    return 'Specific users ($count)';
  }

  @override
  String get ereaderDevicesSaved => 'Devices saved';

  @override
  String get ereaderDevicesSaveFailed => 'Couldn\'t save devices';

  @override
  String libraryCountOne(int count) {
    return '$count library';
  }

  @override
  String libraryCountOther(int count) {
    return '$count libraries';
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
  String get deleteBookmarkQuestion => 'Delete bookmark?';

  @override
  String get cardIconsOnlyChip => '仅图标';

  @override
  String get cardMoreInGridChip => '更多';

  @override
  String get cardLayoutHidden => 'Hidden';

  @override
  String get speed => '速度';

  @override
  String get details => 'Details';

  @override
  String get episodeDetailsLabel => 'Episode Details';

  @override
  String get bookDetailsLabel => '书籍详情';

  @override
  String get equalizerShort => 'EQ';

  @override
  String get equalizerLabel => '音频增强';

  @override
  String get cast => 'Cast';

  @override
  String castingToDevice(String device) {
    return 'Casting to $device';
  }

  @override
  String castToDeviceNamed(String device) {
    return 'Cast to $device';
  }

  @override
  String get historyShort => 'History';

  @override
  String atPosition(String position) {
    return 'at $position';
  }

  @override
  String chaptersChip(int count) {
    return '$count chapters';
  }

  @override
  String chapterNumber(int number) {
    return 'Chapter $number';
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
    return 'Saved: $filename';
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
  String get adminListeningNow => 'Listening Now';

  @override
  String get adminLibraries => 'Libraries';

  @override
  String get adminLibraryShows => 'shows';

  @override
  String get adminLibraryBooks => 'books';

  @override
  String get adminLibraryFolders => 'folders';

  @override
  String get adminLibrarySize => 'size';

  @override
  String get adminLibraryDuration => 'duration';

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
  String get adminMatchAction => 'Match';

  @override
  String adminMatchingStarted(String name) {
    return 'Matching started for $name';
  }

  @override
  String get adminMatchFailed => 'Failed';

  @override
  String adminScanFailed(String name) {
    return 'Failed to scan $name';
  }

  @override
  String get adminPurgeCacheFailed => 'Failed';

  @override
  String get adminUsersRootBadge => 'root';

  @override
  String get adminUsersAdminBadge => 'admin';

  @override
  String get adminUsersDisabledBadge => 'disabled';

  @override
  String get adminUsersEditUserTooltip => 'Edit user';

  @override
  String get adminUsersOnlineNow => 'Online now';

  @override
  String adminUsersLastSeen(String time) {
    return 'Last seen $time';
  }

  @override
  String get adminUsersNever => 'Never';

  @override
  String get adminUsersTotal => 'Total';

  @override
  String get adminUsersNoReadingActivity => 'No reading activity';

  @override
  String get adminUsersLoadingDots => 'Loading...';

  @override
  String get adminUsersLoadMoreSessions => 'Load more sessions';

  @override
  String get adminUsersNoRecentSessions => 'No recent sessions';

  @override
  String get adminUsersLibraryProgress => 'Library Progress';

  @override
  String adminUsersLoadMoreRemaining(int count) {
    return 'Load More ($count remaining)';
  }

  @override
  String adminUsersMonthsAgo(int count) {
    return '${count}mo ago';
  }

  @override
  String get adminUsersNewUser => 'New User';

  @override
  String get adminUsersEditUser => 'Edit User';

  @override
  String get adminUsersUsername => 'Username';

  @override
  String get adminUsersEnterUsername => 'Enter username';

  @override
  String get adminUsersPassword => 'Password';

  @override
  String get adminUsersNewPassword => 'New Password';

  @override
  String get adminUsersEnterPassword => 'Enter password';

  @override
  String get adminUsersLeaveBlankToKeep => 'Leave blank to keep current';

  @override
  String get adminUsersAccountType => 'Account Type';

  @override
  String get adminUsersTypeGuest => 'Guest';

  @override
  String get adminUsersTypeUser => 'User';

  @override
  String get adminUsersTypeAdmin => 'Admin';

  @override
  String get adminUsersStatus => 'Status';

  @override
  String get adminUsersAccountActive => 'Account Active';

  @override
  String get adminUsersAccountActiveSub => 'Disabled accounts cannot log in';

  @override
  String get adminUsersLocked => 'Locked';

  @override
  String get adminUsersLockedSub => 'Prevents password changes';

  @override
  String get adminUsersPermissions => 'Permissions';

  @override
  String get adminUsersPermDownload => 'Download';

  @override
  String get adminUsersPermUpdate => 'Update';

  @override
  String get adminUsersPermUpdateSub => 'Edit metadata and library items';

  @override
  String get adminUsersPermDelete => 'Delete';

  @override
  String get adminUsersPermUpload => 'Upload';

  @override
  String get adminUsersPermExplicit => 'Explicit Content';

  @override
  String get adminUsersLibraryAccess => 'Library Access';

  @override
  String get adminUsersAccessAllLibraries => 'Access All Libraries';

  @override
  String get adminUsersCreateUser => 'Create User';

  @override
  String get adminUsersSaveChanges => 'Save Changes';

  @override
  String get adminUsersUsernameRequired => 'Username is required';

  @override
  String get adminUsersPasswordRequired => 'Password is required';

  @override
  String get adminUsersUserCreated => 'User created';

  @override
  String get adminUsersUserUpdated => 'User updated';

  @override
  String get adminUsersFailedCreate => 'Failed to create user';

  @override
  String get adminUsersFailedUpdate => 'Failed to update user';

  @override
  String get adminUsersThisUser => 'this user';

  @override
  String get adminUsersDeleteUserTitle => 'Delete User?';

  @override
  String adminUsersDeleteUserContent(String name) {
    return 'Permanently delete $name?';
  }

  @override
  String adminUsersUserDeleted(String name) {
    return '$name deleted';
  }

  @override
  String get adminUsersFailedDelete => 'Failed to delete user';

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
    return 'by $author';
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
  String get adminUsersClient => 'Client';

  @override
  String get adminUsersDevice => 'Device';

  @override
  String get adminUsersOs => 'OS';

  @override
  String get adminUsersPlayMethod => 'Play method';

  @override
  String get adminUsersPlayDirect => 'Direct play';

  @override
  String get adminUsersPlayDirectStream => 'Direct stream';

  @override
  String get adminUsersPlayTranscode => 'Transcode';

  @override
  String get adminUsersPlayLocal => 'Local';

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
  String get adminPodcastsRelToday => 'Today';

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
  String get adminPodcastsGenreArts => 'Arts';

  @override
  String get adminPodcastsGenreComedy => 'Comedy';

  @override
  String get adminPodcastsGenreEducation => 'Education';

  @override
  String get adminPodcastsGenreTvFilm => 'TV & Film';

  @override
  String get adminPodcastsGenreMusic => 'Music';

  @override
  String get adminPodcastsGenreNews => 'News';

  @override
  String get adminPodcastsGenreReligion => 'Religion';

  @override
  String get adminPodcastsGenreScience => 'Science';

  @override
  String get adminPodcastsGenreSports => 'Sports';

  @override
  String get adminPodcastsGenreTechnology => 'Technology';

  @override
  String get adminPodcastsGenreBusiness => 'Business';

  @override
  String get adminPodcastsGenreFiction => 'Fiction';

  @override
  String get adminPodcastsGenreSocietyCulture => 'Society & Culture';

  @override
  String get adminPodcastsGenreHealthFitness => 'Health & Fitness';

  @override
  String get adminPodcastsGenreTrueCrime => 'True Crime';

  @override
  String get adminPodcastsGenreHistory => 'History';

  @override
  String get adminPodcastsGenreKidsFamily => 'Kids & Family';

  @override
  String get adminPodcastsPodcastFallback => 'Podcast';

  @override
  String get adminPodcastsEpisodeFallback => 'Episode';

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
  String get adminPodcastsAdding => 'Adding…';

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
  String get adminPodcastsTabDownloaded => 'Downloaded';

  @override
  String get adminPodcastsTabFeed => 'Feed';

  @override
  String get adminPodcastsTabSettings => 'Settings';

  @override
  String adminPodcastsDownloadingEpisode(String title) {
    return 'Downloading \"$title\"';
  }

  @override
  String get adminPodcastsFailedDownload => 'Failed to download';

  @override
  String get adminPodcastsDeleteEpisodeTitle => 'Delete Episode?';

  @override
  String adminPodcastsDeleteEpisodeContent(String title) {
    return 'Delete \"$title\"?';
  }

  @override
  String get adminPodcastsDeleted => 'Deleted';

  @override
  String get adminPodcastsFailed => 'Failed';

  @override
  String get adminPodcastsDeleteEpisodesTitle => 'Delete Episodes?';

  @override
  String adminPodcastsDeleteEpisodesContent(int count) {
    return 'Delete $count episode(s) from the server?';
  }

  @override
  String adminPodcastsDeletedEpisodes(int count) {
    return 'Deleted $count episode(s)';
  }

  @override
  String get adminPodcastsBrowseFeedToDownload => 'Browse feed to download';

  @override
  String get adminPodcastsDownloadingDots => 'Downloading...';

  @override
  String adminPodcastsDeleteEpisodesCount(int count) {
    return 'Delete $count episode(s)';
  }

  @override
  String adminPodcastsDownloadingCount(int count) {
    return 'Downloading $count episode(s)';
  }

  @override
  String adminPodcastsDownloadEpisodesCount(int count) {
    return 'Download $count episode(s)';
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
  String get adminPodcastsCheckAndDownload => 'Check & Download';

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
  String get adminPodcastsFrequency => 'Frequency';

  @override
  String get adminPodcastsFreqHourly => 'Hourly';

  @override
  String get adminPodcastsFreqDaily => 'Daily';

  @override
  String get adminPodcastsFreqWeekly => 'Weekly';

  @override
  String get adminPodcastsDay => 'Day';

  @override
  String get adminPodcastsTime => 'Time';

  @override
  String get adminPodcastsDaySun => 'Sun';

  @override
  String get adminPodcastsDayMon => 'Mon';

  @override
  String get adminPodcastsDayTue => 'Tue';

  @override
  String get adminPodcastsDayWed => 'Wed';

  @override
  String get adminPodcastsDayThu => 'Thu';

  @override
  String get adminPodcastsDayFri => 'Fri';

  @override
  String get adminPodcastsDaySat => 'Sat';

  @override
  String get adminPodcastsFeedUrl => 'Feed URL';

  @override
  String get adminPodcastsBack => 'Back';

  @override
  String get adminPodcastsRootOnly => 'Root Only';

  @override
  String get adminPodcastsDeleting => 'Deleting...';

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
      other: '$count episodes marked as unfinished',
      one: '1 episode marked as unfinished',
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
  String get episodeListShowFinishedEpisodes => 'Show Finished Episodes';

  @override
  String get episodeListHideFinishedEpisodes => 'Hide Finished Episodes';

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
  String get episodeListAutoDownloadChip => 'Auto-Download';

  @override
  String get episodeListSubscribedChip => 'Subscribed';

  @override
  String get episodeListExplicitChip => 'Explicit';

  @override
  String get episodeListSortNewest => '最新';

  @override
  String get episodeListSortOldest => 'Oldest';

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
    return 'Added \"$title\" to Absorbing';
  }

  @override
  String get episodeDetailEpisodeFallback => 'Episode';

  @override
  String get episodeDetailMarkedNotFinished => 'Marked as not finished';

  @override
  String get episodeDetailMarkedFinishedNice => 'Marked as finished - nice!';

  @override
  String get episodeDetailMarkAbsorbedContent =>
      'This will set your progress to 100% for this episode.';

  @override
  String get episodeDetailResetProgressContent =>
      'This will erase all progress for this episode and set it back to the beginning. This can\'t be undone.';

  @override
  String get episodeDetailToday => 'Today';

  @override
  String get episodeDetailYesterday => 'Yesterday';

  @override
  String episodeDetailDaysAgo(int count) {
    return '${count}d ago';
  }

  @override
  String episodeDetailWeeksAgo(int count) {
    return '${count}w ago';
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
  String get episodeDetailResume => 'Resume';

  @override
  String get episodeDetailPlayEpisode => 'Play Episode';

  @override
  String episodeDetailEpisodeNumber(String number) {
    return 'Episode $number';
  }

  @override
  String episodeDetailSeasonNumber(String number) {
    return 'Season $number';
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
  String get seriesBooksFindMissingTitle => '扫描缺失书籍';

  @override
  String get seriesBooksFindMissingContent =>
      '此功能将检索 Audible以查找该系列中你的媒体库可能缺失的书籍。\n\n系统会优先通过 ASIN 进行匹配（取决于你的服务器中书籍是否包含 ASIN），若无则通过书名进行匹配。搜索结果可能不会完全准确。';

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
      other: '$count books',
      one: '1 book',
    );
    return '$_temp0';
  }

  @override
  String get seriesBooksDone => 'Done';

  @override
  String get seriesBooksExplicitBadge => 'E';

  @override
  String get expandedCardStreaming => '串流播放';

  @override
  String get expandedCardDeviceFallback => 'Device';

  @override
  String bookmarksScreenPositionInBook(String position, String bookTitle) {
    return '$position in $bookTitle';
  }

  @override
  String get bookmarksScreenClose => 'Close';

  @override
  String get bookmarksScreenSortNewest => 'Newest';

  @override
  String get bookmarksScreenSortPosition => '位置';

  @override
  String statsScreenStreakDays(int count) {
    return '${count}d';
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
  String get statsScreenDayMon => 'Mon';

  @override
  String get statsScreenDayTue => 'Tue';

  @override
  String get statsScreenDayWed => 'Wed';

  @override
  String get statsScreenDayThu => 'Thu';

  @override
  String get statsScreenDayFri => 'Fri';

  @override
  String get statsScreenDaySat => 'Sat';

  @override
  String get statsScreenDaySun => 'Sun';

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
  String get statsScreenListened => 'Listened';

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
  String get statsScreenDevice => 'Device';

  @override
  String get statsScreenOs => 'OS';

  @override
  String get statsScreenPlayMethod => 'Play method';

  @override
  String get statsScreenLoading => 'Loading...';

  @override
  String statsScreenJumpToSessionStart(String position) {
    return 'Jump to session start ($position)';
  }

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
  String get statsScreenMonthJan => 'Jan';

  @override
  String get statsScreenMonthFeb => 'Feb';

  @override
  String get statsScreenMonthMar => 'Mar';

  @override
  String get statsScreenMonthApr => 'Apr';

  @override
  String get statsScreenMonthMay => 'May';

  @override
  String get statsScreenMonthJun => 'Jun';

  @override
  String get statsScreenMonthJul => 'Jul';

  @override
  String get statsScreenMonthAug => 'Aug';

  @override
  String get statsScreenMonthSep => 'Sep';

  @override
  String get statsScreenMonthOct => 'Oct';

  @override
  String get statsScreenMonthNov => 'Nov';

  @override
  String get statsScreenMonthDec => 'Dec';

  @override
  String get upcomingReleasesTitle => '即将上架';

  @override
  String get upcomingReleasesRescanTitle => '重新扫描？';

  @override
  String upcomingReleasesRescanContent(int days) {
    return '这些结果是 $days 天前获取的。发布日期可能已发生变更——是否需要重新扫描？';
  }

  @override
  String get upcomingReleasesNotNow => '稍后再说';

  @override
  String get upcomingReleasesRescan => '重新扫描';

  @override
  String get upcomingReleasesRescanReleaseDate => '重新扫描发布日期';

  @override
  String get upcomingReleasesRescanning => '正在重新扫描...';

  @override
  String upcomingReleasesUpdatedWithDate(String date) {
    return '更新于 $date';
  }

  @override
  String get upcomingReleasesNoReleaseDateFound => '未找到发布日期';

  @override
  String get upcomingReleasesRescanFailed => '重新扫描失败';

  @override
  String get upcomingReleasesRemoveFromList => 'Remove from list';

  @override
  String get upcomingReleasesRemovedFromList => 'Removed from list';

  @override
  String get upcomingReleasesDateChip => '发布日期';

  @override
  String upcomingReleasesCheckingSeries(String name, int processed, int total) {
    return '正在获取 $name... ($processed/$total)';
  }

  @override
  String get upcomingReleasesLoadingSeries => '系列加载中...';

  @override
  String get upcomingReleasesScannedToday => '(今天已扫描)';

  @override
  String get upcomingReleasesScannedYesterday => '(昨天已扫描)';

  @override
  String upcomingReleasesScannedDaysAgo(int days) {
    return '(扫描于 $days 天前)';
  }

  @override
  String upcomingReleasesUpcomingCount(int count) {
    return '$count 个即将发布';
  }

  @override
  String upcomingReleasesRecentCount(int count) {
    return '$count 个最近更新';
  }

  @override
  String get upcomingReleasesNoneFound => '未找到即将推出或最近更新的内容';

  @override
  String upcomingReleasesAcrossSeries(String summary, int count) {
    return '$summary共 $count 个系列';
  }

  @override
  String upcomingReleasesCheckedSeries(int count) {
    return '已扫描 Audible 上的 $count 个系列';
  }

  @override
  String upcomingReleasesDateFormat(String month, int day, int year) {
    return '$year-$month-$day';
  }

  @override
  String upcomingReleasesSequenceLabel(String sequence) {
    return '#$sequence';
  }

  @override
  String get upcomingReleasesBadgeUpcoming => '即将发布';

  @override
  String get upcomingReleasesBadgeAdded => '已添加';

  @override
  String get upcomingReleasesBadgeMissing => '缺失';

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
  String get libraryScreenUnknownTitle => 'Unknown Title';

  @override
  String get playlistDetailDefaultName => 'Playlist';

  @override
  String playlistDetailItemCount(int count) {
    return '$count 个项目';
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
  String collectionDetailBookCount(int count) {
    return '$count本书';
  }

  @override
  String get collectionDetailDone => 'Done';

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
  String get audibleSeriesNoUpcoming => '未找到即将上架的内容';

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
  String get authorBooksList => 'List';

  @override
  String get authorBooksGrid => 'Grid';

  @override
  String authorBooksBookCount(int count) {
    return '$count books';
  }

  @override
  String get metadataLookupCover => 'Cover';

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
  String get equalizerPresetFlat => '原声';

  @override
  String get equalizerPresetVoiceBoost => '人声增强';

  @override
  String get equalizerPresetBassBoost => '低音增强';

  @override
  String get equalizerPresetTrebleBoost => '高音增强';

  @override
  String get equalizerPresetPodcast => '播客模式';

  @override
  String get equalizerPresetAudiobook => '有声书';

  @override
  String get equalizerPresetReduceNoise => '降噪模式';

  @override
  String get equalizerPresetLoudness => 'Loudness';

  @override
  String equalizerEditingSavedNamed(String title) {
    return '正在编辑\"$title\"';
  }

  @override
  String get equalizerEditingSavedGeneric => 'Editing saved EQ';

  @override
  String get equalizerPerBookEq => '每本书单独配置';

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
  String get librarySortFilterUpcomingReleases => '即将发布';

  @override
  String get librarySortFilterUpcomingReleasesSubtitle => 'Audible 中检查系列新书';

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
      other: '听完 $count 章结束',
      one: '听完 1 章结束',
    );
    return '$_temp0';
  }

  @override
  String get sleepTimerSheetRewindOnSleep => '定时结束自动倒回';

  @override
  String get sleepTimerSheetShake => '摇一摇';

  @override
  String sleepTimerSheetAddsMinutes(int minutes) {
    return 'Adds $minutes min';
  }

  @override
  String get sleepTimerSheetAddsOneChapter => 'Adds 1 chapter';

  @override
  String get sleepTimerSheetResetsToFull => 'Resets to full duration';

  @override
  String get sleepTimerSheetTabSpecificChapter => '章节';

  @override
  String get sleepTimerSheetSpecificNoChapters => '没有可用的章节';

  @override
  String sleepTimerSheetSpecificChapterFallback(int number) {
    return '第 $number 章';
  }

  @override
  String get sleepTimerSheetSpecificPassedShort => '已过';

  @override
  String get sleepTimerSheetSpecificStart => '章节开始';

  @override
  String get sleepTimerSheetSpecificEnd => '章节结束';

  @override
  String get sleepTimerSheetSpecificEndsAt => '睡眠定时器将于';

  @override
  String sleepTimerSheetSpecificCountdown(String countdown) {
    return '$countdown 后';
  }

  @override
  String get sleepTimerSheetSpecificAlreadyPassed => '此时间点已过';

  @override
  String get sleepTimerSheetSpecificStartButton => '启动定时器';

  @override
  String get sleepTimerSheetSpecificStartButtonPassed => '已过';

  @override
  String get timeAm => '上午';

  @override
  String get timePm => '下午';

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
  String get absorbingSharedToday => 'Today';

  @override
  String get absorbingSharedYesterday => 'Yesterday';

  @override
  String get absorbingSharedMonday => 'Monday';

  @override
  String get absorbingSharedTuesday => 'Tuesday';

  @override
  String get absorbingSharedWednesday => 'Wednesday';

  @override
  String get absorbingSharedThursday => 'Thursday';

  @override
  String get absorbingSharedFriday => 'Friday';

  @override
  String get absorbingSharedSaturday => 'Saturday';

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
  String get sectionDetailDoneBadge => 'Done';

  @override
  String get homeCustomizeAddGenreTitle => '新增类型分区';

  @override
  String get homeCustomizeAddGenreSubtitle => '选择一个类型显示在你的首页';

  @override
  String get homeSectionDoneBadge => 'Done';

  @override
  String get tipsSheetQuickBookmarksTitle => '快速书签';

  @override
  String get tipsSheetQuickBookmarksDesc => '长按任意卡片上的书签按钮即可立即添加书签，无需打开书签页面。';

  @override
  String get tipsSheetCoverPlayPauseTitle => '点击封面播放/暂停';

  @override
  String get tipsSheetCoverPlayPauseDesc =>
      '点击任意卡片的封面即可播放或暂停。可在设置的“收听卡片”中切换此功能。播放时会显示淡淡的暂停图标，提示封面可点击。';

  @override
  String get tipsSheetFullScreenPlayerTitle => '全屏播放器';

  @override
  String get tipsSheetFullScreenPlayerDesc => '在任意沉浸卡片上向上滑动即可打开全屏播放器，向下滑动即可关闭。';

  @override
  String get tipsSheetQuickAddAbsorbingTitle => '快速加入收听卡片';

  @override
  String get tipsSheetQuickAddAbsorbingDesc =>
      '在列表页（系列、作者、搜索结果）中向右滑动任意书籍，即可将其立即加入收听队列。';

  @override
  String get tipsSheetShakeExtendSleepTitle => '摇一摇延长睡眠定时';

  @override
  String get tipsSheetShakeExtendSleepDesc =>
      '如果睡眠定时器正在运行，摇动手机即可延长时间。可在设置中的“睡眠定时器”调整延长的分钟数。';

  @override
  String get tipsSheetSeriesNavigationTitle => '系列导航';

  @override
  String get tipsSheetSeriesNavigationDesc =>
      '在任意书籍的详情弹窗中点击系列名称，即可查看该系列的所有书籍，并按阅读顺序排序，每本书的封面都会显示序号徽章。';

  @override
  String get tipsSheetSwipeBetweenBooksTitle => '滑动切换书籍';

  @override
  String get tipsSheetSwipeBetweenBooksDesc =>
      '在收听界面左右滑动即可切换你正在收听的书籍。开启手动队列模式后，卡片也会作为你的队列使用，因此当前书籍播放结束时会自动播放下一本。';

  @override
  String get tipsSheetTapToSeekTitle => '点击跳转';

  @override
  String get tipsSheetTapToSeekDesc =>
      '点击章节或书籍进度条的任意位置即可直接跳转到对应进度。你也可以拖动进度条以进行更精细的控制。';

  @override
  String get tipsSheetSpeedAdjustedTimeTitle => '实际播放时长';

  @override
  String get tipsSheetSpeedAdjustedTimeDesc =>
      '剩余时间和章节时长会根据你的播放速度自动调整。用 1.5×倍播放？界面显示的时间就是你实际需要的时长。';

  @override
  String get tipsSheetPlaybackHistoryTitle => '播放历史';

  @override
  String get tipsSheetPlaybackHistoryDesc =>
      '点击任意卡片上的历史按钮即可查看所有播放、暂停、跳转和倍速调整的时间线。点击任意事件即可跳回对应位置。';

  @override
  String get tipsSheetAutoRewindTitle => '自动回退';

  @override
  String get tipsSheetAutoRewindDesc =>
      '暂停后恢复播放时，Absorb 会自动回退几秒，确保你不会错过内容。回退时长会根据你离开的时间自动调整。你可以在设置中进行修改。';

  @override
  String get tipsSheetSeriesQueueModeTitle => '系列连播模式';

  @override
  String get tipsSheetSeriesQueueModeDesc =>
      '当你听完某个系列中的一本书时，Absorb 可以自动播放下一本书。请在“设置”中将队列模式更改为“系列”。';

  @override
  String get tipsSheetOfflineModeTitle => '离线模式';

  @override
  String get tipsSheetOfflineModeDesc =>
      '点击“正在收听”界面上的同步图标即可进入离线模式。这将暂停同步并节省流量，且仅显示你已下载的书籍。非常适合在飞机上或信号较弱的区域使用。';

  @override
  String get tipsSheetUpcomingReleasesTitle => '即将上架';

  @override
  String get tipsSheetUpcomingReleasesDesc =>
      '在“系列”标签页中，再次点击该标签即可打开其排序与筛选面板，然后选择“即将上架”，即可按出版日期查看当前系列中已推出和即将推出的新书。';

  @override
  String get tipsSheetPerBookEqTitle => '为每本书单独配置均衡器';

  @override
  String get tipsSheetPerBookEqDesc =>
      'Each book remembers its own equalizer settings. Tweak EQ once for a sci-fi epic and the next time you play it, it sounds the same.';

  @override
  String get tipsSheetPerBookSpeedTitle => '针对单本有声书的语速设置';

  @override
  String get tipsSheetPerBookSpeedDesc =>
      '播放速度支持书籍单独配置。非虚构内容 1.5x 效率拉满，有声剧 1.0x 原汁原味，省去频繁调整的麻烦。';

  @override
  String get tipsSheetAutoSleepWindowTitle => '自动睡眠时间段';

  @override
  String get tipsSheetAutoSleepWindowDesc => '设定您常睡的时间段，在此时间段内听书，睡眠定时器将自动启用。';

  @override
  String get tipsSheetSleepFadeChimeTitle => '睡眠淡出与提示音';

  @override
  String get tipsSheetSleepFadeChimeDesc =>
      '睡眠定时结束时，音频将逐渐淡出并伴有可选提示音，避免在听书时突然中断。';

  @override
  String get tipsSheetCarModeTitle => '车载模式';

  @override
  String get tipsSheetCarModeDesc => '轻点汽车图标，开启车载模式，让行车操作更安全舒适。';

  @override
  String get tipsSheetAudibleSeriesTitle => '获取 Audible 系列信息';

  @override
  String get tipsSheetAudibleSeriesDesc =>
      '打开任意系列，点击右上角的“更多”图标（三个点），即可从 Audible 获取完整的系列清单，包含缺失以及您尚未开始阅读的书籍。';

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
  String get bookCardDone => 'Done';

  @override
  String get bookCardSaved => 'Saved';

  @override
  String get episodeRowEpisode => 'Episode';

  @override
  String get episodeRowToday => 'Today';

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
  String get librarySearchResultsDone => 'Done';

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
      other: '$count books',
      one: '1 book',
    );
    return '$_temp0';
  }

  @override
  String get libraryGridTilesExplicitBadge => 'E';

  @override
  String get libraryGridTilesDone => 'Done';

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
      other: '$count books',
      one: '1 book',
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
    return 'Chapter $number';
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
    return 'Cannot reach server at $url';
  }

  @override
  String get authInvalidUsernameOrPassword => 'Invalid username or password';

  @override
  String get authInvalidApiKey => 'Invalid API key';

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
  String get statsWeekStartsOn => 'Week starts on';

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
  String get downloadNotifProgressChannelName => 'Download Progress';

  @override
  String get downloadNotifProgressChannelDesc =>
      'Shows progress during audiobook downloads';

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
    return '《$title》已经下载好，随时随地开始听吧';
  }

  @override
  String get downloadNotifFailedTitle => 'Download Failed';

  @override
  String get upcomingNotifChannelName => '扫描即将发布内容';

  @override
  String get upcomingNotifChannelDesc => '显示即将发布扫描的进度';

  @override
  String get upcomingNotifScanTitle => '即将发布内容扫描中';

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
  String get upcomingNotifFoundTitle => '查找到即将发布内容！';

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
  String get androidAutoTabContinue => 'Continue';

  @override
  String get androidAutoTabLibrary => 'Library';

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
  String get androidAutoCatBooks => 'Books';

  @override
  String get androidAutoCatSeries => 'Series';

  @override
  String get androidAutoCatAuthors => 'Authors';

  @override
  String get showTipsAgain => '再次显示提示';

  @override
  String get showTipsAgainSubtitle => '恢复你已关闭的功能提示';

  @override
  String get tipsRestored => '已恢复提示';

  @override
  String get resetSpeedPresets => '重置速度预设';

  @override
  String get resetSpeedPresetsSubtitle => '恢复默认的播放速度选项';

  @override
  String get speedPresetsReset => '速度预设已重置';

  @override
  String get editAuthor => 'Edit author';

  @override
  String get authorName => 'Name';

  @override
  String get authorImage => 'Author image';

  @override
  String get authorRemoveImage => 'Remove image';

  @override
  String get authorRemoveImageTitle => 'Remove author image?';

  @override
  String get authorRemoveImageConfirm =>
      'This deletes the image on the server.';

  @override
  String get authorImageRemoved => 'Image removed';

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
    return 'Merged into $name';
  }

  @override
  String get authorQuickMatchHint =>
      'Pull name, ASIN, description and image from Audible for the chosen region.';

  @override
  String get region => 'Region';

  @override
  String get editTabDetails => '详情';

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
  String get chapterAddHint => 'Add chapter (e.g. \"Chapter 01\")';

  @override
  String get chapterAddTooltip => 'Add chapter(s)';

  @override
  String get chapterRemoveAll => 'Remove All';

  @override
  String get chapterShiftTimes => 'Shift Times';

  @override
  String get chapterFromTracks => 'From Tracks';

  @override
  String get chapterLookup => 'Lookup';

  @override
  String get chapterShowSeconds => 'Show seconds';

  @override
  String get chapterShiftBySeconds => 'Shift by (seconds)';

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
  String get coverSearchTitle => 'Search for a cover';

  @override
  String get coverSearchRefineHint =>
      'Refine the title/author to clean up results - this does not change the book.';

  @override
  String get coverNoneFound => 'No covers found';

  @override
  String get coverEnterTitleFirst => 'Enter a title first';

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
