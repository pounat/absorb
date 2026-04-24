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
  String get retry => '重试';

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
  String get librarySearchBooksHint => '搜索书籍、系列和作者...';

  @override
  String get librarySearchShowsHint => '搜索播客和单集...';

  @override
  String get libraryTabLibrary => '媒体库';

  @override
  String get libraryTabSeries => '系列';

  @override
  String get libraryTabAuthors => '作者';

  @override
  String get libraryNoBooks => '未找到书籍';

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
  String libraryNoBooksInGenre(String genre) {
    return '\"$genre\" 中没有找到书籍';
  }

  @override
  String get libraryClearFilter => '清除筛选';

  @override
  String get libraryNoAuthorsFound => '未找到作者';

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
  String librarySeriesCount(int count) {
    return '$count 个系列';
  }

  @override
  String libraryAuthorsCount(int count) {
    return '$count 位作者';
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
  String get genre => '分类';

  @override
  String get clearFilter => '清除筛选';

  @override
  String get noGenresFound => '未找到分类';

  @override
  String get asc => '升序';

  @override
  String get desc => '降序';

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
  String get appShellPressBackToExit => '再按一次返回键退出';

  @override
  String get settingsTitle => '设置';

  @override
  String get sectionAppearance => '外观';

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
  String get rectangleBookCoversOnSubtitle => '封面以 2:3 的书籍比例显示';

  @override
  String get rectangleBookCoversOffSubtitle => '封面为正方形';

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
  String get queueModeInfoAutoAbsorb => '自动续听';

  @override
  String get queueModeInfoAutoAbsorbDesc => '自动收听系列中的下一本书或播客中的下一集。';

  @override
  String get queueModeOff => '关闭';

  @override
  String get queueModeManual => '手动';

  @override
  String get queueModeAuto => '自动';

  @override
  String get queueModeBooks => '书籍';

  @override
  String get queueModePodcasts => '播客';

  @override
  String get autoDownloadQueue => '自动下载队列';

  @override
  String autoDownloadQueueOnSubtitle(int count) {
    return '保留接下来 $count 个项目的下载';
  }

  @override
  String get autoDownloadQueueOffSubtitle => '关闭 - 仅手动下载';

  @override
  String get sectionPlayback => '播放';

  @override
  String get defaultSpeed => '默认速度';

  @override
  String get defaultSpeedSubtitle => '新书以此速度开始播放 - 每本书会记住自己的速度';

  @override
  String get skipBack => '快退';

  @override
  String get skipForward => '快进';

  @override
  String get chapterProgressInNotification => '通知中显示章节进度';

  @override
  String get chapterProgressOnSubtitle => '开启 - 锁屏显示章节进度';

  @override
  String get chapterProgressOffSubtitle => '关闭 - 锁屏显示全书进度';

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
      '当你在 Wi-Fi 下开始流式播放一本书时，它将自动在后台下载整本书。这样你无需手动开始下载即可离线收听。';

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
      '启用后，听完的书籍或剧集将自动从设备中删除。这有助于在你浏览媒体库时释放存储空间。';

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
  String get tipsAndHiddenFeatures => '技巧与隐藏功能';

  @override
  String get tipsSubtitle => '充分利用 Absorb';

  @override
  String get adminTitle => '服务器管理';

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
  String get aboutSection => '关于';

  @override
  String chaptersCount(int count) {
    return '章节 ($count)';
  }

  @override
  String get chapters => '章节';

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
  String get descriptionLabel => '描述';

  @override
  String get publisherLabel => '出版商';

  @override
  String get yearLabel => '年份';

  @override
  String get languageLabel => '语言';

  @override
  String get genresLabel => '分类';

  @override
  String get commaSeparated => '逗号分隔';

  @override
  String get asinLabel => 'ASIN';

  @override
  String get isbnLabel => 'ISBN';

  @override
  String get coverImage => '封面图片';

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
  String get resetAll => '全部重置';

  @override
  String get collectionNotFound => '未找到收藏集';

  @override
  String get deleteCollection => '删除收藏集';

  @override
  String get deleteCollectionContent => '你确定要删除此收藏集吗？';

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
  String get welcomeOverview => '以下是功能快速介绍。';

  @override
  String get welcomeHomeTitle => '首页';

  @override
  String get welcomeHomeBody =>
      '来自 Audiobookshelf 的个性化书架 - 继续收听、发现新书目，并浏览您的播放列表和合集。使用右上角的编辑按钮自定义显示的版块及其顺序。';

  @override
  String get welcomeLibraryTitle => '媒体库';

  @override
  String get welcomeLibraryBody =>
      '通过书籍、系列和作者等标签页浏览您的完整媒体库。点击当前激活的标签页可以打开排序和筛选选项。';

  @override
  String get welcomeAbsorbingTitle => '正在收听';

  @override
  String get welcomeAbsorbingBody =>
      '你的活跃收听队列。你开始播放的书籍会自动以可滑动卡片的形式显示在这里，并带有完整的播放控制。';

  @override
  String get welcomeQueueModesTitle => '队列模式';

  @override
  String get welcomeQueueModeOff => '关闭 - 书籍播放完成后停止';

  @override
  String get welcomeQueueModeManual => '手动 - 自动播放队列中的下一张卡片';

  @override
  String get welcomeQueueModeAuto => '系列 - 自动查找并播放系列中的下一本书';

  @override
  String get welcomeManagingQueueTitle => '管理你的队列';

  @override
  String get welcomeManagingCoverTap => '点击封面以播放/暂停（可在设置中切换）';

  @override
  String get welcomeManagingSwipeUp => '向上滑动卡片打开全屏播放器，向下滑动关闭';

  @override
  String get welcomeManagingSwipeRight => '在列表中向右滑动任意书籍，即可快速加入队列';

  @override
  String get welcomeManagingReorder => '点击排序图标拖动卡片到你喜欢的顺序，或滑动移除';

  @override
  String get welcomeManagingAdd => '从任何书籍的详情页手动添加书籍';

  @override
  String get welcomeManagingRemoveFinished => '播放完成的书籍会自动从队列中移除';

  @override
  String get welcomeMergeLibrariesTitle => '合并媒体库';

  @override
  String get welcomeMergeLibrariesBody => '在设置中启用，在一个队列中显示所有媒体库的内容';

  @override
  String get welcomeDownloadsTitle => '下载与离线';

  @override
  String get welcomeDownloadsBody =>
      '下载书籍以离线收听。通过“正在收听”屏幕上的飞机图标切换离线模式。您的进度会在重新连接后自动同步回服务器。';

  @override
  String get welcomeSettingsTitle => '设置';

  @override
  String get welcomeSettingsBody => '配置队列行为、睡眠定时器、播放速度、本地服务器连接等更多选项。';

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
  String get coverPlayPause => 'Cover play/pause';

  @override
  String get coverPlayPauseOnSubtitle => 'On - tap cover art to play/pause';

  @override
  String get coverPlayPauseOffSubtitle =>
      'Off - dedicated play/pause button in controls';

  @override
  String get queueModeMergedSubtitle =>
      'Playback stops, manual queue, or auto-absorbs next item';

  @override
  String get queueModeSeriesLabel => 'Series';

  @override
  String get queueModeShowLabel => 'Show';

  @override
  String get queueModeInfoSeries => 'Series';

  @override
  String get queueModeInfoSeriesDesc =>
      'Automatically plays the next book in a series or the next episode in a podcast show.';

  @override
  String get resetButtonGridQuestion => 'Reset button grid?';

  @override
  String get resetButtonGridContent =>
      'This will restore the default button layout, order, and toggle settings.';

  @override
  String get reset => 'Reset';

  @override
  String get buttonGridReset => 'Button grid reset';

  @override
  String get resetButtonGrid => 'Reset button grid';

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
      String start, String end, String duration) {
    return '$start – $end · $duration';
  }

  @override
  String get endOfChapterShort => 'End of chapter';

  @override
  String get endOfChapterOnSubtitle => 'Stop at the end of the current chapter';

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
  String bookmarkAtPosition(String position) {
    return 'Bookmark at $position';
  }

  @override
  String get cardIconsOnlyChip => 'Icons only';

  @override
  String get cardMoreInGridChip => '\"More\" in grid';

  @override
  String get cardLayoutHidden => 'Hidden';

  @override
  String get speed => 'Speed';

  @override
  String get details => 'Details';

  @override
  String get episodeDetailsLabel => 'Episode Details';

  @override
  String get bookDetailsLabel => 'Book Details';

  @override
  String get equalizerShort => 'EQ';

  @override
  String get equalizerLabel => 'Equalizer';

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
  String get expandedCardStreaming => 'Streaming';

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
  String get bookmarksScreenSortPosition => 'Position';

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
      String month, int day, int year, int hour, String minute, String ampm) {
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
  String get upcomingReleasesTitle => 'Upcoming Releases';

  @override
  String get upcomingReleasesRescanTitle => 'Rescan?';

  @override
  String upcomingReleasesRescanContent(int days) {
    return 'These results are $days days old. Release dates may have changed - would you like to rescan?';
  }

  @override
  String get upcomingReleasesNotNow => 'Not now';

  @override
  String get upcomingReleasesRescan => 'Rescan';

  @override
  String get upcomingReleasesRescanReleaseDate => 'Rescan Release Date';

  @override
  String get upcomingReleasesRescanning => 'Rescanning...';

  @override
  String upcomingReleasesUpdatedWithDate(String date) {
    return 'Updated - $date';
  }

  @override
  String get upcomingReleasesNoReleaseDateFound => 'No release date found';

  @override
  String get upcomingReleasesRescanFailed => 'Rescan failed';

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
  String collectionDetailBookCount(int count) {
    return '$count books';
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
      int total, int missing, int upcoming) {
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
  String get equalizerPresetFlat => 'Flat';

  @override
  String get equalizerPresetVoiceBoost => 'Voice Boost';

  @override
  String get equalizerPresetBassBoost => 'Bass Boost';

  @override
  String get equalizerPresetTrebleBoost => 'Treble Boost';

  @override
  String get equalizerPresetPodcast => 'Podcast';

  @override
  String get equalizerPresetAudiobook => 'Audiobook';

  @override
  String get equalizerPresetReduceNoise => 'Reduce Noise';

  @override
  String get equalizerPresetLoudness => 'Loudness';

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
  String get librarySortFilterUpcomingReleases => 'Upcoming Releases';

  @override
  String get librarySortFilterUpcomingReleasesSubtitle =>
      'Scan Audible for new releases in your series';

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
  String get homeCustomizeAddGenreTitle => 'Add Genre Section';

  @override
  String get homeCustomizeAddGenreSubtitle =>
      'Pick a genre to show on your home screen';

  @override
  String get homeSectionDoneBadge => 'Done';

  @override
  String get tipsSheetQuickBookmarksTitle => 'Quick Bookmarks';

  @override
  String get tipsSheetQuickBookmarksDesc =>
      'Long-press the bookmark button on any card to instantly drop a bookmark at your current position without opening the bookmark sheet.';

  @override
  String get tipsSheetEditBookmarksTitle => 'Edit Bookmarks';

  @override
  String get tipsSheetEditBookmarksDesc =>
      'Long-press any bookmark in the bookmark sheet to edit its title and add notes.';

  @override
  String get tipsSheetCoverPlayPauseTitle => 'Cover Play/Pause';

  @override
  String get tipsSheetCoverPlayPauseDesc =>
      'Tap the cover art on any card to play or pause. Toggle this in Settings under Absorbing Cards. A faint pause icon shows when playing so you know it\'s tappable.';

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
      'On the Absorbing screen, swipe left and right to switch between your in-progress books. The dots at the top show which book you\'re viewing.';

  @override
  String get tipsSheetTapToSeekTitle => 'Tap to Seek';

  @override
  String get tipsSheetTapToSeekDesc =>
      'Tap anywhere on the chapter or book progress bar to jump directly to that position. You can also drag the bars for fine-grained control.';

  @override
  String get tipsSheetSpeedAdjustedTimeTitle => 'Speed-Adjusted Time';

  @override
  String get tipsSheetSpeedAdjustedTimeDesc =>
      'Time remaining and chapter times automatically adjust based on your playback speed. Listening at 1.5x? The time shown reflects how long it\'ll actually take you.';

  @override
  String get tipsSheetPlaybackHistoryTitle => 'Playback History';

  @override
  String get tipsSheetPlaybackHistoryDesc =>
      'Tap the History button on any card to see a timeline of every play, pause, seek, and speed change. Tap any event to jump back to that position.';

  @override
  String get tipsSheetAutoRewindTitle => 'Auto-Rewind';

  @override
  String get tipsSheetAutoRewindDesc =>
      'When you resume after a pause, Absorb automatically rewinds a few seconds so you don\'t lose your place. The rewind amount scales with how long you were away. Configure it in Settings.';

  @override
  String get tipsSheetSeriesQueueModeTitle => 'Series Queue Mode';

  @override
  String get tipsSheetSeriesQueueModeDesc =>
      'When you finish a book that\'s part of a series, Absorb can automatically play the next book. Set queue mode to \"Series\" in Settings.';

  @override
  String get tipsSheetOfflineModeTitle => 'Offline Mode';

  @override
  String get tipsSheetOfflineModeDesc =>
      'Tap the airplane button on the Absorbing screen to enter offline mode. This stops syncing, saves data, and only shows your downloaded books. Great for flights or low signal areas.';

  @override
  String get tipsSheetStopPlaybackTitle => 'Stop Playback';

  @override
  String get tipsSheetStopPlaybackDesc =>
      'The Stop button in the Absorbing header ends your listening session and saves your progress. Your progress syncs automatically in the background.';

  @override
  String get tipsSheetDownloadOfflineTitle => 'Download for Offline';

  @override
  String get tipsSheetDownloadOfflineDesc =>
      'Tap the download button in any book\'s detail popup to save it for offline listening. Downloaded books are available in offline mode without any internet connection.';

  @override
  String get tipsSheetCustomizeHomeTitle => 'Customize Home';

  @override
  String get tipsSheetCustomizeHomeDesc =>
      'Tap the edit button in the top right of the Home screen to rearrange, hide, or show sections. Drag sections into your preferred order.';

  @override
  String get tipsSheetPlaylistsTitle => 'Playlists';

  @override
  String get tipsSheetPlaylistsDesc =>
      'Create and manage playlists on your Audiobookshelf server and they\'ll appear as sections on your Home screen. Add books to playlists from any book\'s detail popup.';

  @override
  String get tipsSheetCollectionsTitle => 'Collections';

  @override
  String get tipsSheetCollectionsDesc =>
      'Collections group related books together and show up as Home sections. Root admins can add books and edit collections from the detail popup.';

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
      String seriesName, int current, int total) {
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
  String get androidAutoTabContinue => 'Continue';

  @override
  String get androidAutoTabLibrary => 'Library';

  @override
  String get androidAutoTabDownloads => 'Downloads';

  @override
  String get androidAutoCatBooks => 'Books';

  @override
  String get androidAutoCatSeries => 'Series';

  @override
  String get androidAutoCatAuthors => 'Authors';
}
