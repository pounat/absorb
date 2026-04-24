import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'A B S O R B'**
  String get appTitle;

  /// No description provided for @online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get online;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offline;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @enable.
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get enable;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @off.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get off;

  /// No description provided for @disabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get disabled;

  /// No description provided for @later.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get later;

  /// No description provided for @gotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get gotIt;

  /// No description provided for @preview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get preview;

  /// No description provided for @or.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get or;

  /// No description provided for @file.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get file;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @untitled.
  ///
  /// In en, this message translates to:
  /// **'Untitled'**
  String get untitled;

  /// No description provided for @noThanks.
  ///
  /// In en, this message translates to:
  /// **'No Thanks'**
  String get noThanks;

  /// No description provided for @stay.
  ///
  /// In en, this message translates to:
  /// **'Stay'**
  String get stay;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeTitle;

  /// No description provided for @continueListening.
  ///
  /// In en, this message translates to:
  /// **'Continue Listening'**
  String get continueListening;

  /// No description provided for @continueSeries.
  ///
  /// In en, this message translates to:
  /// **'Continue Series'**
  String get continueSeries;

  /// No description provided for @recentlyAdded.
  ///
  /// In en, this message translates to:
  /// **'Recently Added'**
  String get recentlyAdded;

  /// No description provided for @listenAgain.
  ///
  /// In en, this message translates to:
  /// **'Listen Again'**
  String get listenAgain;

  /// No description provided for @discover.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get discover;

  /// No description provided for @newEpisodes.
  ///
  /// In en, this message translates to:
  /// **'New Episodes'**
  String get newEpisodes;

  /// No description provided for @downloads.
  ///
  /// In en, this message translates to:
  /// **'Downloads'**
  String get downloads;

  /// No description provided for @noDownloadedBooks.
  ///
  /// In en, this message translates to:
  /// **'No downloaded books'**
  String get noDownloadedBooks;

  /// No description provided for @yourLibraryIsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your library is empty'**
  String get yourLibraryIsEmpty;

  /// No description provided for @downloadBooksWhileOnline.
  ///
  /// In en, this message translates to:
  /// **'Download books while online to listen offline'**
  String get downloadBooksWhileOnline;

  /// No description provided for @customizeHome.
  ///
  /// In en, this message translates to:
  /// **'Customize Home'**
  String get customizeHome;

  /// No description provided for @dragToReorderTapEye.
  ///
  /// In en, this message translates to:
  /// **'Drag to reorder, tap eye to show/hide'**
  String get dragToReorderTapEye;

  /// No description provided for @loginTagline.
  ///
  /// In en, this message translates to:
  /// **'Start Absorbing'**
  String get loginTagline;

  /// No description provided for @loginConnectToServer.
  ///
  /// In en, this message translates to:
  /// **'Connect to your server'**
  String get loginConnectToServer;

  /// No description provided for @loginServerAddress.
  ///
  /// In en, this message translates to:
  /// **'Server address'**
  String get loginServerAddress;

  /// No description provided for @loginServerHint.
  ///
  /// In en, this message translates to:
  /// **'my.server.com'**
  String get loginServerHint;

  /// No description provided for @loginServerHelper.
  ///
  /// In en, this message translates to:
  /// **'IP:port works too (e.g. 192.168.1.5:13378)'**
  String get loginServerHelper;

  /// No description provided for @loginCouldNotReachServer.
  ///
  /// In en, this message translates to:
  /// **'Could not reach server'**
  String get loginCouldNotReachServer;

  /// No description provided for @loginAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get loginAdvanced;

  /// No description provided for @loginCustomHttpHeaders.
  ///
  /// In en, this message translates to:
  /// **'Custom HTTP Headers'**
  String get loginCustomHttpHeaders;

  /// No description provided for @loginCustomHeadersDescription.
  ///
  /// In en, this message translates to:
  /// **'For Cloudflare tunnels or reverse proxies that require extra headers. Add headers before entering your server URL.'**
  String get loginCustomHeadersDescription;

  /// No description provided for @loginHeaderName.
  ///
  /// In en, this message translates to:
  /// **'Header name'**
  String get loginHeaderName;

  /// No description provided for @loginHeaderValue.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get loginHeaderValue;

  /// No description provided for @loginAddHeader.
  ///
  /// In en, this message translates to:
  /// **'Add Header'**
  String get loginAddHeader;

  /// No description provided for @loginSelfSignedCertificates.
  ///
  /// In en, this message translates to:
  /// **'Self-signed Certificates'**
  String get loginSelfSignedCertificates;

  /// No description provided for @loginTrustAllCertificates.
  ///
  /// In en, this message translates to:
  /// **'Trust all certificates (for self-signed / custom CA setups)'**
  String get loginTrustAllCertificates;

  /// No description provided for @loginWaitingForSso.
  ///
  /// In en, this message translates to:
  /// **'Waiting for SSO...'**
  String get loginWaitingForSso;

  /// No description provided for @loginRedirectUri.
  ///
  /// In en, this message translates to:
  /// **'Redirect URI: audiobookshelf://oauth'**
  String get loginRedirectUri;

  /// No description provided for @loginOrSignInManually.
  ///
  /// In en, this message translates to:
  /// **'or sign in manually'**
  String get loginOrSignInManually;

  /// No description provided for @loginUsername.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get loginUsername;

  /// No description provided for @loginUsernameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your username'**
  String get loginUsernameRequired;

  /// No description provided for @loginPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get loginPassword;

  /// No description provided for @loginSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get loginSignIn;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed'**
  String get loginFailed;

  /// No description provided for @loginSsoFailed.
  ///
  /// In en, this message translates to:
  /// **'SSO login failed or was cancelled'**
  String get loginSsoFailed;

  /// No description provided for @loginSsoAuthFailed.
  ///
  /// In en, this message translates to:
  /// **'SSO authentication failed. Please try again.'**
  String get loginSsoAuthFailed;

  /// No description provided for @loginRestoreFromBackup.
  ///
  /// In en, this message translates to:
  /// **'Restore from backup'**
  String get loginRestoreFromBackup;

  /// No description provided for @loginInvalidBackupFile.
  ///
  /// In en, this message translates to:
  /// **'Invalid backup file'**
  String get loginInvalidBackupFile;

  /// No description provided for @loginRestoreBackupTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore backup?'**
  String get loginRestoreBackupTitle;

  /// No description provided for @loginRestoreBackupWithAccounts.
  ///
  /// In en, this message translates to:
  /// **'This will restore all settings and {count} saved account(s). You\'ll be signed in automatically.'**
  String loginRestoreBackupWithAccounts(int count);

  /// No description provided for @loginRestoreBackupNoAccounts.
  ///
  /// In en, this message translates to:
  /// **'This will restore all settings. No accounts were included in this backup.'**
  String get loginRestoreBackupNoAccounts;

  /// No description provided for @loginRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get loginRestore;

  /// No description provided for @loginRestoredAndSignedIn.
  ///
  /// In en, this message translates to:
  /// **'Restored settings and signed in as {username}'**
  String loginRestoredAndSignedIn(String username);

  /// No description provided for @loginSessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Settings restored. Session expired - sign in to continue.'**
  String get loginSessionExpired;

  /// No description provided for @loginSettingsRestored.
  ///
  /// In en, this message translates to:
  /// **'Settings restored'**
  String get loginSettingsRestored;

  /// No description provided for @loginRestoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Restore failed: {error}'**
  String loginRestoreFailed(String error);

  /// No description provided for @loginSavedAccounts.
  ///
  /// In en, this message translates to:
  /// **'saved accounts'**
  String get loginSavedAccounts;

  /// No description provided for @libraryTitle.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get libraryTitle;

  /// No description provided for @librarySearchBooksHint.
  ///
  /// In en, this message translates to:
  /// **'Search books, series, and authors...'**
  String get librarySearchBooksHint;

  /// No description provided for @librarySearchShowsHint.
  ///
  /// In en, this message translates to:
  /// **'Search shows and episodes...'**
  String get librarySearchShowsHint;

  /// No description provided for @libraryTabLibrary.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get libraryTabLibrary;

  /// No description provided for @libraryTabSeries.
  ///
  /// In en, this message translates to:
  /// **'Series'**
  String get libraryTabSeries;

  /// No description provided for @libraryTabAuthors.
  ///
  /// In en, this message translates to:
  /// **'Authors'**
  String get libraryTabAuthors;

  /// No description provided for @libraryNoBooks.
  ///
  /// In en, this message translates to:
  /// **'No books found'**
  String get libraryNoBooks;

  /// No description provided for @libraryNoBooksInProgress.
  ///
  /// In en, this message translates to:
  /// **'No books in progress'**
  String get libraryNoBooksInProgress;

  /// No description provided for @libraryNoFinishedBooks.
  ///
  /// In en, this message translates to:
  /// **'No finished books'**
  String get libraryNoFinishedBooks;

  /// No description provided for @libraryAllBooksStarted.
  ///
  /// In en, this message translates to:
  /// **'All books have been started'**
  String get libraryAllBooksStarted;

  /// No description provided for @libraryNoDownloadedBooks.
  ///
  /// In en, this message translates to:
  /// **'No downloaded books'**
  String get libraryNoDownloadedBooks;

  /// No description provided for @libraryNoSeriesFound.
  ///
  /// In en, this message translates to:
  /// **'No series found'**
  String get libraryNoSeriesFound;

  /// No description provided for @libraryNoBooksWithEbooks.
  ///
  /// In en, this message translates to:
  /// **'No books with eBooks'**
  String get libraryNoBooksWithEbooks;

  /// No description provided for @libraryNoBooksInGenre.
  ///
  /// In en, this message translates to:
  /// **'No books in \"{genre}\"'**
  String libraryNoBooksInGenre(String genre);

  /// No description provided for @libraryClearFilter.
  ///
  /// In en, this message translates to:
  /// **'Clear filter'**
  String get libraryClearFilter;

  /// No description provided for @libraryNoAuthorsFound.
  ///
  /// In en, this message translates to:
  /// **'No authors found'**
  String get libraryNoAuthorsFound;

  /// No description provided for @libraryNoResults.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get libraryNoResults;

  /// No description provided for @librarySearchBooks.
  ///
  /// In en, this message translates to:
  /// **'Books'**
  String get librarySearchBooks;

  /// No description provided for @librarySearchShows.
  ///
  /// In en, this message translates to:
  /// **'Shows'**
  String get librarySearchShows;

  /// No description provided for @librarySearchEpisodes.
  ///
  /// In en, this message translates to:
  /// **'Episodes'**
  String get librarySearchEpisodes;

  /// No description provided for @librarySearchSeries.
  ///
  /// In en, this message translates to:
  /// **'Series'**
  String get librarySearchSeries;

  /// No description provided for @librarySearchAuthors.
  ///
  /// In en, this message translates to:
  /// **'Authors'**
  String get librarySearchAuthors;

  /// No description provided for @librarySeriesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} series'**
  String librarySeriesCount(int count);

  /// No description provided for @libraryAuthorsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} authors'**
  String libraryAuthorsCount(int count);

  /// No description provided for @libraryBooksCount.
  ///
  /// In en, this message translates to:
  /// **'{loaded}/{total} books'**
  String libraryBooksCount(int loaded, int total);

  /// No description provided for @sort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get sort;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @filterActive.
  ///
  /// In en, this message translates to:
  /// **'Filter ●'**
  String get filterActive;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @author.
  ///
  /// In en, this message translates to:
  /// **'Author'**
  String get author;

  /// No description provided for @dateAdded.
  ///
  /// In en, this message translates to:
  /// **'Date Added'**
  String get dateAdded;

  /// No description provided for @numberOfBooks.
  ///
  /// In en, this message translates to:
  /// **'Number of Books'**
  String get numberOfBooks;

  /// No description provided for @publishedYear.
  ///
  /// In en, this message translates to:
  /// **'Published Year'**
  String get publishedYear;

  /// No description provided for @duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// No description provided for @random.
  ///
  /// In en, this message translates to:
  /// **'Random'**
  String get random;

  /// No description provided for @collapseSeries.
  ///
  /// In en, this message translates to:
  /// **'Collapse Series'**
  String get collapseSeries;

  /// No description provided for @inProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get inProgress;

  /// No description provided for @filterFinished.
  ///
  /// In en, this message translates to:
  /// **'Finished'**
  String get filterFinished;

  /// No description provided for @notStarted.
  ///
  /// In en, this message translates to:
  /// **'Not Started'**
  String get notStarted;

  /// No description provided for @downloaded.
  ///
  /// In en, this message translates to:
  /// **'Downloaded'**
  String get downloaded;

  /// No description provided for @hasEbook.
  ///
  /// In en, this message translates to:
  /// **'Has eBook'**
  String get hasEbook;

  /// No description provided for @genre.
  ///
  /// In en, this message translates to:
  /// **'Genre'**
  String get genre;

  /// No description provided for @clearFilter.
  ///
  /// In en, this message translates to:
  /// **'Clear Filter'**
  String get clearFilter;

  /// No description provided for @noGenresFound.
  ///
  /// In en, this message translates to:
  /// **'No genres found'**
  String get noGenresFound;

  /// No description provided for @asc.
  ///
  /// In en, this message translates to:
  /// **'ASC'**
  String get asc;

  /// No description provided for @desc.
  ///
  /// In en, this message translates to:
  /// **'DESC'**
  String get desc;

  /// No description provided for @absorbingTitle.
  ///
  /// In en, this message translates to:
  /// **'Absorbing'**
  String get absorbingTitle;

  /// No description provided for @absorbingStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get absorbingStop;

  /// No description provided for @absorbingManageQueue.
  ///
  /// In en, this message translates to:
  /// **'Manage Queue'**
  String get absorbingManageQueue;

  /// No description provided for @absorbingDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get absorbingDone;

  /// No description provided for @absorbingNoDownloadedEpisodes.
  ///
  /// In en, this message translates to:
  /// **'No downloaded episodes'**
  String get absorbingNoDownloadedEpisodes;

  /// No description provided for @absorbingNoDownloadedBooks.
  ///
  /// In en, this message translates to:
  /// **'No downloaded books'**
  String get absorbingNoDownloadedBooks;

  /// No description provided for @absorbingNothingPlayingYet.
  ///
  /// In en, this message translates to:
  /// **'Nothing playing yet'**
  String get absorbingNothingPlayingYet;

  /// No description provided for @absorbingNothingAbsorbingYet.
  ///
  /// In en, this message translates to:
  /// **'Nothing absorbing yet'**
  String get absorbingNothingAbsorbingYet;

  /// No description provided for @absorbingDownloadEpisodesToListen.
  ///
  /// In en, this message translates to:
  /// **'Download episodes to listen offline'**
  String get absorbingDownloadEpisodesToListen;

  /// No description provided for @absorbingDownloadBooksToListen.
  ///
  /// In en, this message translates to:
  /// **'Download books to listen offline'**
  String get absorbingDownloadBooksToListen;

  /// No description provided for @absorbingStartEpisodeFromShows.
  ///
  /// In en, this message translates to:
  /// **'Start an episode from the Shows tab'**
  String get absorbingStartEpisodeFromShows;

  /// No description provided for @absorbingStartBookFromLibrary.
  ///
  /// In en, this message translates to:
  /// **'Start a book from the Library tab'**
  String get absorbingStartBookFromLibrary;

  /// No description provided for @carModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Car Mode'**
  String get carModeTitle;

  /// No description provided for @carModeNoBookLoaded.
  ///
  /// In en, this message translates to:
  /// **'No book loaded'**
  String get carModeNoBookLoaded;

  /// No description provided for @carModeBookLabel.
  ///
  /// In en, this message translates to:
  /// **'Book'**
  String get carModeBookLabel;

  /// No description provided for @carModeChapterLabel.
  ///
  /// In en, this message translates to:
  /// **'Chapter'**
  String get carModeChapterLabel;

  /// No description provided for @carModeBookmarkDefault.
  ///
  /// In en, this message translates to:
  /// **'Bookmark'**
  String get carModeBookmarkDefault;

  /// No description provided for @carModeBookmarkAdded.
  ///
  /// In en, this message translates to:
  /// **'Bookmark added'**
  String get carModeBookmarkAdded;

  /// No description provided for @downloadsTitle.
  ///
  /// In en, this message translates to:
  /// **'Downloads'**
  String get downloadsTitle;

  /// No description provided for @downloadsCancelSelection.
  ///
  /// In en, this message translates to:
  /// **'Cancel selection'**
  String get downloadsCancelSelection;

  /// No description provided for @downloadsSelect.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get downloadsSelect;

  /// No description provided for @downloadsNoDownloads.
  ///
  /// In en, this message translates to:
  /// **'No downloads'**
  String get downloadsNoDownloads;

  /// No description provided for @downloadsDownloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading'**
  String get downloadsDownloading;

  /// No description provided for @downloadsQueued.
  ///
  /// In en, this message translates to:
  /// **'Queued'**
  String get downloadsQueued;

  /// No description provided for @downloadsCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get downloadsCompleted;

  /// No description provided for @downloadsWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting...'**
  String get downloadsWaiting;

  /// No description provided for @downloadsCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get downloadsCancel;

  /// No description provided for @downloadsDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get downloadsDelete;

  /// No description provided for @downloadsDeleteCount.
  ///
  /// In en, this message translates to:
  /// **'Delete {count} download(s)?'**
  String downloadsDeleteCount(int count);

  /// No description provided for @downloadsDeleteContent.
  ///
  /// In en, this message translates to:
  /// **'Downloaded files will be removed from this device.'**
  String get downloadsDeleteContent;

  /// No description provided for @downloadsDeletedCount.
  ///
  /// In en, this message translates to:
  /// **'Deleted {count} download(s)'**
  String downloadsDeletedCount(int count);

  /// No description provided for @downloadsRemoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove download?'**
  String get downloadsRemoveTitle;

  /// No description provided for @downloadsRemoveContent.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{title}\" from this device?'**
  String downloadsRemoveContent(String title);

  /// No description provided for @downloadsRemovedTitle.
  ///
  /// In en, this message translates to:
  /// **'\"{title}\" removed'**
  String downloadsRemovedTitle(String title);

  /// No description provided for @downloadsSelectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String downloadsSelectedCount(int count);

  /// No description provided for @bookmarksTitle.
  ///
  /// In en, this message translates to:
  /// **'All Bookmarks'**
  String get bookmarksTitle;

  /// No description provided for @bookmarksCancelSelection.
  ///
  /// In en, this message translates to:
  /// **'Cancel selection'**
  String get bookmarksCancelSelection;

  /// No description provided for @bookmarksSortedByNewest.
  ///
  /// In en, this message translates to:
  /// **'Sorted by newest'**
  String get bookmarksSortedByNewest;

  /// No description provided for @bookmarksSortedByPosition.
  ///
  /// In en, this message translates to:
  /// **'Sorted by position'**
  String get bookmarksSortedByPosition;

  /// No description provided for @bookmarksSelect.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get bookmarksSelect;

  /// No description provided for @bookmarksNoBookmarks.
  ///
  /// In en, this message translates to:
  /// **'No bookmarks yet'**
  String get bookmarksNoBookmarks;

  /// No description provided for @bookmarksDeleteCount.
  ///
  /// In en, this message translates to:
  /// **'Delete {count} bookmark(s)?'**
  String bookmarksDeleteCount(int count);

  /// No description provided for @bookmarksDeleteContent.
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone.'**
  String get bookmarksDeleteContent;

  /// No description provided for @bookmarksDeletedCount.
  ///
  /// In en, this message translates to:
  /// **'Deleted {count} bookmark(s)'**
  String bookmarksDeletedCount(int count);

  /// No description provided for @bookmarksJumpTitle.
  ///
  /// In en, this message translates to:
  /// **'Jump to bookmark?'**
  String get bookmarksJumpTitle;

  /// No description provided for @bookmarksJumpContent.
  ///
  /// In en, this message translates to:
  /// **'\"{title}\" at {position}\nin {bookTitle}'**
  String bookmarksJumpContent(String title, String position, String bookTitle);

  /// No description provided for @bookmarksJump.
  ///
  /// In en, this message translates to:
  /// **'Jump'**
  String get bookmarksJump;

  /// No description provided for @bookmarksNotConnected.
  ///
  /// In en, this message translates to:
  /// **'Not connected to server'**
  String get bookmarksNotConnected;

  /// No description provided for @bookmarksCouldNotLoad.
  ///
  /// In en, this message translates to:
  /// **'Could not load book'**
  String get bookmarksCouldNotLoad;

  /// No description provided for @bookmarksSelectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String bookmarksSelectedCount(int count);

  /// No description provided for @statsTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Stats'**
  String get statsTitle;

  /// No description provided for @statsCouldNotLoad.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load stats'**
  String get statsCouldNotLoad;

  /// No description provided for @statsTotalListeningTime.
  ///
  /// In en, this message translates to:
  /// **'TOTAL LISTENING TIME'**
  String get statsTotalListeningTime;

  /// No description provided for @statsHoursUnit.
  ///
  /// In en, this message translates to:
  /// **'h'**
  String get statsHoursUnit;

  /// No description provided for @statsMinutesUnit.
  ///
  /// In en, this message translates to:
  /// **'m'**
  String get statsMinutesUnit;

  /// No description provided for @statsDaysOfAudio.
  ///
  /// In en, this message translates to:
  /// **'That\'s {days} days of audio'**
  String statsDaysOfAudio(String days);

  /// No description provided for @statsHoursOfAudio.
  ///
  /// In en, this message translates to:
  /// **'That\'s {hours} hours of audio'**
  String statsHoursOfAudio(String hours);

  /// No description provided for @statsToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get statsToday;

  /// No description provided for @statsThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get statsThisWeek;

  /// No description provided for @statsThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get statsThisMonth;

  /// No description provided for @statsActivity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get statsActivity;

  /// No description provided for @statsCurrentStreak.
  ///
  /// In en, this message translates to:
  /// **'Current Streak'**
  String get statsCurrentStreak;

  /// No description provided for @statsBestStreak.
  ///
  /// In en, this message translates to:
  /// **'Best Streak'**
  String get statsBestStreak;

  /// No description provided for @statsFinished.
  ///
  /// In en, this message translates to:
  /// **'Finished'**
  String get statsFinished;

  /// No description provided for @statsBooksFinished.
  ///
  /// In en, this message translates to:
  /// **'Books'**
  String get statsBooksFinished;

  /// No description provided for @statsEpisodesFinished.
  ///
  /// In en, this message translates to:
  /// **'Episodes'**
  String get statsEpisodesFinished;

  /// No description provided for @statsBooksThisYear.
  ///
  /// In en, this message translates to:
  /// **'Books this year'**
  String get statsBooksThisYear;

  /// No description provided for @statsEpisodesThisYear.
  ///
  /// In en, this message translates to:
  /// **'Episodes this year'**
  String get statsEpisodesThisYear;

  /// No description provided for @statsDaysActive.
  ///
  /// In en, this message translates to:
  /// **'Days Active'**
  String get statsDaysActive;

  /// No description provided for @statsDailyAverage.
  ///
  /// In en, this message translates to:
  /// **'Daily Average'**
  String get statsDailyAverage;

  /// No description provided for @statsLast7Days.
  ///
  /// In en, this message translates to:
  /// **'Last 7 Days'**
  String get statsLast7Days;

  /// No description provided for @statsMostListened.
  ///
  /// In en, this message translates to:
  /// **'Most Listened'**
  String get statsMostListened;

  /// No description provided for @statsRecentSessions.
  ///
  /// In en, this message translates to:
  /// **'Recent Sessions'**
  String get statsRecentSessions;

  /// No description provided for @appShellHomeTab.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get appShellHomeTab;

  /// No description provided for @appShellLibraryTab.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get appShellLibraryTab;

  /// No description provided for @appShellAbsorbingTab.
  ///
  /// In en, this message translates to:
  /// **'Absorbing'**
  String get appShellAbsorbingTab;

  /// No description provided for @appShellStatsTab.
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get appShellStatsTab;

  /// No description provided for @appShellSettingsTab.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get appShellSettingsTab;

  /// No description provided for @appShellPressBackToExit.
  ///
  /// In en, this message translates to:
  /// **'Press back again to exit'**
  String get appShellPressBackToExit;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @sectionAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get sectionAppearance;

  /// No description provided for @themeLabel.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themeLabel;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeOled.
  ///
  /// In en, this message translates to:
  /// **'OLED'**
  String get themeOled;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get themeAuto;

  /// No description provided for @colorSourceLabel.
  ///
  /// In en, this message translates to:
  /// **'Color source'**
  String get colorSourceLabel;

  /// No description provided for @colorSourceCoverDescription.
  ///
  /// In en, this message translates to:
  /// **'App colors follow the currently playing book cover'**
  String get colorSourceCoverDescription;

  /// No description provided for @colorSourceWallpaperDescription.
  ///
  /// In en, this message translates to:
  /// **'App colors follow your system wallpaper'**
  String get colorSourceWallpaperDescription;

  /// No description provided for @colorSourceWallpaper.
  ///
  /// In en, this message translates to:
  /// **'Wallpaper'**
  String get colorSourceWallpaper;

  /// No description provided for @colorSourceNowPlaying.
  ///
  /// In en, this message translates to:
  /// **'Now Playing'**
  String get colorSourceNowPlaying;

  /// No description provided for @startScreenLabel.
  ///
  /// In en, this message translates to:
  /// **'Start screen'**
  String get startScreenLabel;

  /// No description provided for @startScreenSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Which tab to open when the app launches'**
  String get startScreenSubtitle;

  /// No description provided for @startScreenHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get startScreenHome;

  /// No description provided for @startScreenLibrary.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get startScreenLibrary;

  /// No description provided for @startScreenAbsorb.
  ///
  /// In en, this message translates to:
  /// **'Absorb'**
  String get startScreenAbsorb;

  /// No description provided for @startScreenStats.
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get startScreenStats;

  /// No description provided for @disablePageFade.
  ///
  /// In en, this message translates to:
  /// **'Disable page fade'**
  String get disablePageFade;

  /// No description provided for @disablePageFadeOnSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pages switch instantly'**
  String get disablePageFadeOnSubtitle;

  /// No description provided for @disablePageFadeOffSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pages fade when switching tabs'**
  String get disablePageFadeOffSubtitle;

  /// No description provided for @rectangleBookCovers.
  ///
  /// In en, this message translates to:
  /// **'Rectangle book covers'**
  String get rectangleBookCovers;

  /// No description provided for @rectangleBookCoversOnSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Covers display in 2:3 book proportion'**
  String get rectangleBookCoversOnSubtitle;

  /// No description provided for @rectangleBookCoversOffSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Covers are square'**
  String get rectangleBookCoversOffSubtitle;

  /// No description provided for @sectionAbsorbingCards.
  ///
  /// In en, this message translates to:
  /// **'Absorbing Cards'**
  String get sectionAbsorbingCards;

  /// No description provided for @fullScreenPlayer.
  ///
  /// In en, this message translates to:
  /// **'Full screen player'**
  String get fullScreenPlayer;

  /// No description provided for @fullScreenPlayerOnSubtitle.
  ///
  /// In en, this message translates to:
  /// **'On - books open in full screen when played'**
  String get fullScreenPlayerOnSubtitle;

  /// No description provided for @fullScreenPlayerOffSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Off - play within card view'**
  String get fullScreenPlayerOffSubtitle;

  /// No description provided for @fullBookScrubber.
  ///
  /// In en, this message translates to:
  /// **'Full book scrubber'**
  String get fullBookScrubber;

  /// No description provided for @fullBookScrubberOnSubtitle.
  ///
  /// In en, this message translates to:
  /// **'On - seekable slider across entire book'**
  String get fullBookScrubberOnSubtitle;

  /// No description provided for @fullBookScrubberOffSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Off - progress bar only'**
  String get fullBookScrubberOffSubtitle;

  /// No description provided for @speedAdjustedTime.
  ///
  /// In en, this message translates to:
  /// **'Speed-adjusted time'**
  String get speedAdjustedTime;

  /// No description provided for @speedAdjustedTimeOnSubtitle.
  ///
  /// In en, this message translates to:
  /// **'On - remaining time reflects playback speed'**
  String get speedAdjustedTimeOnSubtitle;

  /// No description provided for @speedAdjustedTimeOffSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Off - showing raw audio duration'**
  String get speedAdjustedTimeOffSubtitle;

  /// No description provided for @buttonLayout.
  ///
  /// In en, this message translates to:
  /// **'Button layout'**
  String get buttonLayout;

  /// No description provided for @buttonLayoutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'How action buttons are arranged on the card'**
  String get buttonLayoutSubtitle;

  /// No description provided for @whenAbsorbed.
  ///
  /// In en, this message translates to:
  /// **'When absorbed'**
  String get whenAbsorbed;

  /// No description provided for @whenAbsorbedInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'When Absorbed'**
  String get whenAbsorbedInfoTitle;

  /// No description provided for @whenAbsorbedInfoContent.
  ///
  /// In en, this message translates to:
  /// **'Controls what happens to an absorbing card when you finish a book or episode.\n\nFinished cards are automatically removed from your Absorbing screen.'**
  String get whenAbsorbedInfoContent;

  /// No description provided for @whenAbsorbedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'What happens to the absorbing card when a book or episode finishes'**
  String get whenAbsorbedSubtitle;

  /// No description provided for @whenAbsorbedShowOverlay.
  ///
  /// In en, this message translates to:
  /// **'Show Overlay'**
  String get whenAbsorbedShowOverlay;

  /// No description provided for @whenAbsorbedAutoRelease.
  ///
  /// In en, this message translates to:
  /// **'Auto-release'**
  String get whenAbsorbedAutoRelease;

  /// No description provided for @mergeLibraries.
  ///
  /// In en, this message translates to:
  /// **'Merge libraries'**
  String get mergeLibraries;

  /// No description provided for @mergeLibrariesInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Merge Libraries'**
  String get mergeLibrariesInfoTitle;

  /// No description provided for @mergeLibrariesInfoContent.
  ///
  /// In en, this message translates to:
  /// **'When enabled, the Absorbing screen shows all your in-progress books and podcasts from every library in a single view. When disabled, only items from the library you currently have selected are shown.'**
  String get mergeLibrariesInfoContent;

  /// No description provided for @mergeLibrariesOnSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Absorbing page shows items from all libraries'**
  String get mergeLibrariesOnSubtitle;

  /// No description provided for @mergeLibrariesOffSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Absorbing page shows current library only'**
  String get mergeLibrariesOffSubtitle;

  /// No description provided for @queueMode.
  ///
  /// In en, this message translates to:
  /// **'Queue mode'**
  String get queueMode;

  /// No description provided for @queueModeInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Queue Mode'**
  String get queueModeInfoTitle;

  /// No description provided for @queueModeInfoOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get queueModeInfoOff;

  /// No description provided for @queueModeInfoOffDesc.
  ///
  /// In en, this message translates to:
  /// **'Playback stops when the current book or episode finishes.'**
  String get queueModeInfoOffDesc;

  /// No description provided for @queueModeInfoManual.
  ///
  /// In en, this message translates to:
  /// **'Manual Queue'**
  String get queueModeInfoManual;

  /// No description provided for @queueModeInfoManualDesc.
  ///
  /// In en, this message translates to:
  /// **'Your absorbing cards act as a playlist. When one finishes, the next non-finished card auto-plays. Add items with the \"Add to Absorbing\" button on a book or episode and reorder from the absorbing screen.'**
  String get queueModeInfoManualDesc;

  /// No description provided for @queueModeInfoAutoAbsorb.
  ///
  /// In en, this message translates to:
  /// **'Auto Absorb'**
  String get queueModeInfoAutoAbsorb;

  /// No description provided for @queueModeInfoAutoAbsorbDesc.
  ///
  /// In en, this message translates to:
  /// **'Automatically absorbs the next book in a series or the next episode in a podcast show.'**
  String get queueModeInfoAutoAbsorbDesc;

  /// No description provided for @queueModeOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get queueModeOff;

  /// No description provided for @queueModeManual.
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get queueModeManual;

  /// No description provided for @queueModeAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get queueModeAuto;

  /// No description provided for @queueModeBooks.
  ///
  /// In en, this message translates to:
  /// **'Books'**
  String get queueModeBooks;

  /// No description provided for @queueModePodcasts.
  ///
  /// In en, this message translates to:
  /// **'Podcasts'**
  String get queueModePodcasts;

  /// No description provided for @autoDownloadQueue.
  ///
  /// In en, this message translates to:
  /// **'Auto-download queue'**
  String get autoDownloadQueue;

  /// No description provided for @autoDownloadQueueOnSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Keep next {count} items downloaded'**
  String autoDownloadQueueOnSubtitle(int count);

  /// No description provided for @autoDownloadQueueOffSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Off - manual downloads only'**
  String get autoDownloadQueueOffSubtitle;

  /// No description provided for @sectionPlayback.
  ///
  /// In en, this message translates to:
  /// **'Playback'**
  String get sectionPlayback;

  /// No description provided for @defaultSpeed.
  ///
  /// In en, this message translates to:
  /// **'Default speed'**
  String get defaultSpeed;

  /// No description provided for @defaultSpeedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'New books start at this speed - each book remembers its own'**
  String get defaultSpeedSubtitle;

  /// No description provided for @skipBack.
  ///
  /// In en, this message translates to:
  /// **'Skip back'**
  String get skipBack;

  /// No description provided for @skipForward.
  ///
  /// In en, this message translates to:
  /// **'Skip forward'**
  String get skipForward;

  /// No description provided for @chapterProgressInNotification.
  ///
  /// In en, this message translates to:
  /// **'Chapter progress in notification'**
  String get chapterProgressInNotification;

  /// No description provided for @chapterProgressOnSubtitle.
  ///
  /// In en, this message translates to:
  /// **'On - lockscreen shows chapter progress'**
  String get chapterProgressOnSubtitle;

  /// No description provided for @chapterProgressOffSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Off - lockscreen shows full book progress'**
  String get chapterProgressOffSubtitle;

  /// No description provided for @autoRewindOnResume.
  ///
  /// In en, this message translates to:
  /// **'Auto-rewind on resume'**
  String get autoRewindOnResume;

  /// No description provided for @autoRewindOnSubtitle.
  ///
  /// In en, this message translates to:
  /// **'On - {min}s to {max}s based on pause length'**
  String autoRewindOnSubtitle(String min, String max);

  /// No description provided for @autoRewindOffSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get autoRewindOffSubtitle;

  /// No description provided for @rewindRange.
  ///
  /// In en, this message translates to:
  /// **'Rewind range'**
  String get rewindRange;

  /// No description provided for @rewindAfterPausedFor.
  ///
  /// In en, this message translates to:
  /// **'Rewind after paused for'**
  String get rewindAfterPausedFor;

  /// No description provided for @rewindAnyPause.
  ///
  /// In en, this message translates to:
  /// **'Any pause'**
  String get rewindAnyPause;

  /// No description provided for @rewindAlwaysLabel.
  ///
  /// In en, this message translates to:
  /// **'Always'**
  String get rewindAlwaysLabel;

  /// No description provided for @rewindAlwaysDescription.
  ///
  /// In en, this message translates to:
  /// **'Rewinds every time you resume, even after quick interruptions'**
  String get rewindAlwaysDescription;

  /// No description provided for @rewindAfterDescription.
  ///
  /// In en, this message translates to:
  /// **'Only rewinds if paused for {seconds}+ seconds'**
  String rewindAfterDescription(String seconds);

  /// No description provided for @chapterBarrier.
  ///
  /// In en, this message translates to:
  /// **'Chapter barrier'**
  String get chapterBarrier;

  /// No description provided for @chapterBarrierSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Don\'t rewind past the start of the current chapter'**
  String get chapterBarrierSubtitle;

  /// No description provided for @rewindInstant.
  ///
  /// In en, this message translates to:
  /// **'Instant'**
  String get rewindInstant;

  /// No description provided for @rewindPause.
  ///
  /// In en, this message translates to:
  /// **'{duration} pause'**
  String rewindPause(String duration);

  /// No description provided for @rewindNoRewind.
  ///
  /// In en, this message translates to:
  /// **'no rewind'**
  String get rewindNoRewind;

  /// No description provided for @rewindSeconds.
  ///
  /// In en, this message translates to:
  /// **'{seconds}s rewind'**
  String rewindSeconds(String seconds);

  /// No description provided for @sectionSleepTimer.
  ///
  /// In en, this message translates to:
  /// **'Sleep Timer'**
  String get sectionSleepTimer;

  /// No description provided for @sleep.
  ///
  /// In en, this message translates to:
  /// **'Sleep'**
  String get sleep;

  /// No description provided for @sleepTimer.
  ///
  /// In en, this message translates to:
  /// **'Sleep Timer'**
  String get sleepTimer;

  /// No description provided for @shakeDuringSleepTimer.
  ///
  /// In en, this message translates to:
  /// **'Shake during sleep timer'**
  String get shakeDuringSleepTimer;

  /// No description provided for @shakeOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get shakeOff;

  /// No description provided for @shakeAddTime.
  ///
  /// In en, this message translates to:
  /// **'Add Time'**
  String get shakeAddTime;

  /// No description provided for @shakeReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get shakeReset;

  /// No description provided for @shakeAdds.
  ///
  /// In en, this message translates to:
  /// **'Shake adds'**
  String get shakeAdds;

  /// No description provided for @shakeAddsValue.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String shakeAddsValue(int minutes);

  /// No description provided for @shakeSensitivity.
  ///
  /// In en, this message translates to:
  /// **'Shake sensitivity'**
  String get shakeSensitivity;

  /// No description provided for @shakeSensitivityVeryLow.
  ///
  /// In en, this message translates to:
  /// **'Very low'**
  String get shakeSensitivityVeryLow;

  /// No description provided for @shakeSensitivityLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get shakeSensitivityLow;

  /// No description provided for @shakeSensitivityMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get shakeSensitivityMedium;

  /// No description provided for @shakeSensitivityHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get shakeSensitivityHigh;

  /// No description provided for @shakeSensitivityVeryHigh.
  ///
  /// In en, this message translates to:
  /// **'Very high'**
  String get shakeSensitivityVeryHigh;

  /// No description provided for @resetTimerOnPause.
  ///
  /// In en, this message translates to:
  /// **'Reset timer on pause'**
  String get resetTimerOnPause;

  /// No description provided for @resetTimerOnPauseOnSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Timer restarts from full duration when you resume'**
  String get resetTimerOnPauseOnSubtitle;

  /// No description provided for @resetTimerOnPauseOffSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Timer continues from where it left off'**
  String get resetTimerOnPauseOffSubtitle;

  /// No description provided for @fadeVolumeBeforeSleep.
  ///
  /// In en, this message translates to:
  /// **'Fade volume before sleep'**
  String get fadeVolumeBeforeSleep;

  /// No description provided for @fadeVolumeOnSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Gradually lowers volume during the last 30 seconds'**
  String get fadeVolumeOnSubtitle;

  /// No description provided for @fadeVolumeOffSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Playback stops immediately when timer ends'**
  String get fadeVolumeOffSubtitle;

  /// No description provided for @autoSleepTimer.
  ///
  /// In en, this message translates to:
  /// **'Auto sleep timer'**
  String get autoSleepTimer;

  /// No description provided for @autoSleepTimerOnSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{start} - {end} - {duration} min'**
  String autoSleepTimerOnSubtitle(String start, String end, int duration);

  /// No description provided for @autoSleepTimerOffSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Automatically start a sleep timer during a time window'**
  String get autoSleepTimerOffSubtitle;

  /// No description provided for @windowStart.
  ///
  /// In en, this message translates to:
  /// **'Window start'**
  String get windowStart;

  /// No description provided for @windowEnd.
  ///
  /// In en, this message translates to:
  /// **'Window end'**
  String get windowEnd;

  /// No description provided for @timerDuration.
  ///
  /// In en, this message translates to:
  /// **'Timer duration'**
  String get timerDuration;

  /// No description provided for @timer.
  ///
  /// In en, this message translates to:
  /// **'Timer'**
  String get timer;

  /// No description provided for @endOfChapter.
  ///
  /// In en, this message translates to:
  /// **'End of Chapter'**
  String get endOfChapter;

  /// No description provided for @startMinTimer.
  ///
  /// In en, this message translates to:
  /// **'Start {minutes} min timer'**
  String startMinTimer(int minutes);

  /// No description provided for @sleepAfterChapters.
  ///
  /// In en, this message translates to:
  /// **'Sleep after {count} {label}'**
  String sleepAfterChapters(int count, String label);

  /// No description provided for @addMoreTime.
  ///
  /// In en, this message translates to:
  /// **'Add more time'**
  String get addMoreTime;

  /// No description provided for @cancelTimer.
  ///
  /// In en, this message translates to:
  /// **'Cancel timer'**
  String get cancelTimer;

  /// No description provided for @chaptersLeftCount.
  ///
  /// In en, this message translates to:
  /// **'{count} ch left'**
  String chaptersLeftCount(int count);

  /// No description provided for @sectionDownloadsAndStorage.
  ///
  /// In en, this message translates to:
  /// **'Downloads & Storage'**
  String get sectionDownloadsAndStorage;

  /// No description provided for @downloadOverWifiOnly.
  ///
  /// In en, this message translates to:
  /// **'Download over Wi-Fi only'**
  String get downloadOverWifiOnly;

  /// No description provided for @downloadOverWifiOnSubtitle.
  ///
  /// In en, this message translates to:
  /// **'On - mobile data blocked for downloads'**
  String get downloadOverWifiOnSubtitle;

  /// No description provided for @downloadOverWifiOffSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Off - downloads on any connection'**
  String get downloadOverWifiOffSubtitle;

  /// No description provided for @autoDownloadOnWifi.
  ///
  /// In en, this message translates to:
  /// **'Auto download on Wi-Fi'**
  String get autoDownloadOnWifi;

  /// No description provided for @autoDownloadOnWifiInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Auto Download on Wi-Fi'**
  String get autoDownloadOnWifiInfoTitle;

  /// No description provided for @autoDownloadOnWifiInfoContent.
  ///
  /// In en, this message translates to:
  /// **'When you start streaming a book over Wi-Fi, it will automatically begin downloading the full book in the background. This way you\'ll have it available offline without having to manually start the download.'**
  String get autoDownloadOnWifiInfoContent;

  /// No description provided for @autoDownloadOnWifiOnSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Books download in the background when you start streaming on Wi-Fi'**
  String get autoDownloadOnWifiOnSubtitle;

  /// No description provided for @autoDownloadOnWifiOffSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get autoDownloadOnWifiOffSubtitle;

  /// No description provided for @concurrentDownloads.
  ///
  /// In en, this message translates to:
  /// **'Concurrent downloads'**
  String get concurrentDownloads;

  /// No description provided for @autoDownload.
  ///
  /// In en, this message translates to:
  /// **'Auto-download'**
  String get autoDownload;

  /// No description provided for @autoDownloadSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enable per series or podcast from their detail pages'**
  String get autoDownloadSubtitle;

  /// No description provided for @keepNext.
  ///
  /// In en, this message translates to:
  /// **'Keep next'**
  String get keepNext;

  /// No description provided for @keepNextInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Keep Next'**
  String get keepNextInfoTitle;

  /// No description provided for @keepNextInfoContent.
  ///
  /// In en, this message translates to:
  /// **'The number of items to keep downloaded, including the one you\'re currently listening to. For example, \"Keep next 3\" means the current book plus the next 2 in the series or podcast will stay downloaded.'**
  String get keepNextInfoContent;

  /// No description provided for @deleteAbsorbedDownloads.
  ///
  /// In en, this message translates to:
  /// **'Delete absorbed downloads'**
  String get deleteAbsorbedDownloads;

  /// No description provided for @deleteAbsorbedDownloadsInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Absorbed Downloads'**
  String get deleteAbsorbedDownloadsInfoTitle;

  /// No description provided for @deleteAbsorbedDownloadsInfoContent.
  ///
  /// In en, this message translates to:
  /// **'When enabled, downloaded books or episodes are automatically deleted from your device after you finish listening to them. This helps free up storage space as you work through your library.'**
  String get deleteAbsorbedDownloadsInfoContent;

  /// No description provided for @deleteAbsorbedOnSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Finished items are removed to save space'**
  String get deleteAbsorbedOnSubtitle;

  /// No description provided for @deleteAbsorbedOffSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Off - finished downloads kept'**
  String get deleteAbsorbedOffSubtitle;

  /// No description provided for @downloadLocation.
  ///
  /// In en, this message translates to:
  /// **'Download location'**
  String get downloadLocation;

  /// No description provided for @storageUsed.
  ///
  /// In en, this message translates to:
  /// **'Storage used'**
  String get storageUsed;

  /// No description provided for @storageUsedByDownloads.
  ///
  /// In en, this message translates to:
  /// **'{size} used by downloads'**
  String storageUsedByDownloads(String size);

  /// No description provided for @storageFreeOfTotal.
  ///
  /// In en, this message translates to:
  /// **'{free} free of {total}'**
  String storageFreeOfTotal(String free, String total);

  /// No description provided for @manageDownloads.
  ///
  /// In en, this message translates to:
  /// **'Manage downloads'**
  String get manageDownloads;

  /// No description provided for @streamingCache.
  ///
  /// In en, this message translates to:
  /// **'Streaming cache'**
  String get streamingCache;

  /// No description provided for @streamingCacheInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Streaming Cache'**
  String get streamingCacheInfoTitle;

  /// No description provided for @streamingCacheInfoContent.
  ///
  /// In en, this message translates to:
  /// **'Caches streamed audio to disk so it doesn\'t need to be re-downloaded if you seek back or re-listen to sections. The cache is automatically managed - oldest files are removed when the size limit is reached. This is separate from fully downloaded books.'**
  String get streamingCacheInfoContent;

  /// No description provided for @streamingCacheOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get streamingCacheOff;

  /// No description provided for @streamingCacheOffSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Off - audio is streamed without caching'**
  String get streamingCacheOffSubtitle;

  /// No description provided for @streamingCacheOnSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{size} MB - recently streamed audio is cached to disk'**
  String streamingCacheOnSubtitle(int size);

  /// No description provided for @clearCache.
  ///
  /// In en, this message translates to:
  /// **'Clear cache'**
  String get clearCache;

  /// No description provided for @streamingCacheCleared.
  ///
  /// In en, this message translates to:
  /// **'Streaming cache cleared'**
  String get streamingCacheCleared;

  /// No description provided for @sectionLibrary.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get sectionLibrary;

  /// No description provided for @hideEbookOnlyTitles.
  ///
  /// In en, this message translates to:
  /// **'Hide eBook-only titles'**
  String get hideEbookOnlyTitles;

  /// No description provided for @hideEbookOnlyOnSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Books with no audio files are hidden'**
  String get hideEbookOnlyOnSubtitle;

  /// No description provided for @hideEbookOnlyOffSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Off - all library items shown'**
  String get hideEbookOnlyOffSubtitle;

  /// No description provided for @showGoodreadsButton.
  ///
  /// In en, this message translates to:
  /// **'Show Goodreads button'**
  String get showGoodreadsButton;

  /// No description provided for @showGoodreadsOnSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Book detail sheet shows a link to Goodreads'**
  String get showGoodreadsOnSubtitle;

  /// No description provided for @showGoodreadsOffSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Off - Goodreads button hidden'**
  String get showGoodreadsOffSubtitle;

  /// No description provided for @sectionPermissions.
  ///
  /// In en, this message translates to:
  /// **'Permissions'**
  String get sectionPermissions;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @notificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'For download progress and playback controls'**
  String get notificationsSubtitle;

  /// No description provided for @notificationsAlreadyEnabled.
  ///
  /// In en, this message translates to:
  /// **'Notifications already enabled'**
  String get notificationsAlreadyEnabled;

  /// No description provided for @unrestrictedBattery.
  ///
  /// In en, this message translates to:
  /// **'Unrestricted battery'**
  String get unrestrictedBattery;

  /// No description provided for @unrestrictedBatterySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Prevents Android from killing background playback'**
  String get unrestrictedBatterySubtitle;

  /// No description provided for @batteryAlreadyUnrestricted.
  ///
  /// In en, this message translates to:
  /// **'Battery already unrestricted'**
  String get batteryAlreadyUnrestricted;

  /// No description provided for @sectionIssuesAndSupport.
  ///
  /// In en, this message translates to:
  /// **'Issues & Support'**
  String get sectionIssuesAndSupport;

  /// No description provided for @bugsAndFeatureRequests.
  ///
  /// In en, this message translates to:
  /// **'Bugs & Feature Requests'**
  String get bugsAndFeatureRequests;

  /// No description provided for @bugsAndFeatureRequestsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Open an issue on GitHub'**
  String get bugsAndFeatureRequestsSubtitle;

  /// No description provided for @joinDiscord.
  ///
  /// In en, this message translates to:
  /// **'Join Discord'**
  String get joinDiscord;

  /// No description provided for @joinDiscordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Community, support, and updates'**
  String get joinDiscordSubtitle;

  /// No description provided for @contact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get contact;

  /// No description provided for @contactSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Send device info via email'**
  String get contactSubtitle;

  /// No description provided for @enableLogging.
  ///
  /// In en, this message translates to:
  /// **'Enable logging'**
  String get enableLogging;

  /// No description provided for @enableLoggingOnSubtitle.
  ///
  /// In en, this message translates to:
  /// **'On - logs saved to file (restart to apply)'**
  String get enableLoggingOnSubtitle;

  /// No description provided for @enableLoggingOffSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Off - no logs captured'**
  String get enableLoggingOffSubtitle;

  /// No description provided for @loggingEnabledSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Logging enabled - restart app to start capturing'**
  String get loggingEnabledSnackbar;

  /// No description provided for @loggingDisabledSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Logging disabled - restart app to stop capturing'**
  String get loggingDisabledSnackbar;

  /// No description provided for @sendLogs.
  ///
  /// In en, this message translates to:
  /// **'Send logs'**
  String get sendLogs;

  /// No description provided for @sendLogsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Share log file as attachment'**
  String get sendLogsSubtitle;

  /// No description provided for @failedToShare.
  ///
  /// In en, this message translates to:
  /// **'Failed to share: {error}'**
  String failedToShare(String error);

  /// No description provided for @clearLogs.
  ///
  /// In en, this message translates to:
  /// **'Clear logs'**
  String get clearLogs;

  /// No description provided for @logsCleared.
  ///
  /// In en, this message translates to:
  /// **'Logs cleared'**
  String get logsCleared;

  /// No description provided for @sectionAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get sectionAdvanced;

  /// No description provided for @localServer.
  ///
  /// In en, this message translates to:
  /// **'Local server'**
  String get localServer;

  /// No description provided for @localServerInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Local Server'**
  String get localServerInfoTitle;

  /// No description provided for @localServerInfoContent.
  ///
  /// In en, this message translates to:
  /// **'If you run your Audiobookshelf server at home, you can set a local/LAN URL here. Absorb will automatically switch to the faster local connection when it detects you\'re on your home network, and fall back to your remote URL when you\'re away.'**
  String get localServerInfoContent;

  /// No description provided for @localServerOnConnectedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Connected via local server'**
  String get localServerOnConnectedSubtitle;

  /// No description provided for @localServerOnRemoteSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enabled - using remote server'**
  String get localServerOnRemoteSubtitle;

  /// No description provided for @localServerOffSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Auto-switch to a LAN server on your home WiFi'**
  String get localServerOffSubtitle;

  /// No description provided for @localServerUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'Local server URL'**
  String get localServerUrlLabel;

  /// No description provided for @localServerUrlHint.
  ///
  /// In en, this message translates to:
  /// **'http://192.168.1.100:13378'**
  String get localServerUrlHint;

  /// No description provided for @localServerUrlSetSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Local server URL set - will connect automatically when on your home network'**
  String get localServerUrlSetSnackbar;

  /// No description provided for @disableAudioFocus.
  ///
  /// In en, this message translates to:
  /// **'Disable audio focus'**
  String get disableAudioFocus;

  /// No description provided for @disableAudioFocusInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Audio Focus'**
  String get disableAudioFocusInfoTitle;

  /// No description provided for @disableAudioFocusInfoContent.
  ///
  /// In en, this message translates to:
  /// **'By default, Android gives audio \"focus\" to one app at a time - when Absorb plays, other audio (music, videos) will pause. Disabling audio focus lets Absorb play alongside other apps. Phone calls will still pause playback regardless of this setting.'**
  String get disableAudioFocusInfoContent;

  /// No description provided for @disableAudioFocusOnSubtitle.
  ///
  /// In en, this message translates to:
  /// **'On - plays alongside other audio (still pauses for calls)'**
  String get disableAudioFocusOnSubtitle;

  /// No description provided for @disableAudioFocusOffSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Off - other audio pauses when Absorb plays'**
  String get disableAudioFocusOffSubtitle;

  /// No description provided for @restartRequired.
  ///
  /// In en, this message translates to:
  /// **'Restart Required'**
  String get restartRequired;

  /// No description provided for @restartRequiredContent.
  ///
  /// In en, this message translates to:
  /// **'Audio focus change requires a full restart to take effect. Close the app now?'**
  String get restartRequiredContent;

  /// No description provided for @closeApp.
  ///
  /// In en, this message translates to:
  /// **'Close App'**
  String get closeApp;

  /// No description provided for @trustAllCertificates.
  ///
  /// In en, this message translates to:
  /// **'Trust all certificates'**
  String get trustAllCertificates;

  /// No description provided for @trustAllCertificatesInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Self-signed Certificates'**
  String get trustAllCertificatesInfoTitle;

  /// No description provided for @trustAllCertificatesInfoContent.
  ///
  /// In en, this message translates to:
  /// **'Enable this if your Audiobookshelf server uses a self-signed certificate or a custom root CA. When enabled, Absorb will skip TLS certificate verification for all connections. Only enable this if you trust your network.'**
  String get trustAllCertificatesInfoContent;

  /// No description provided for @trustAllCertificatesOnSubtitle.
  ///
  /// In en, this message translates to:
  /// **'On - accepting all certificates'**
  String get trustAllCertificatesOnSubtitle;

  /// No description provided for @trustAllCertificatesOffSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Off - only trusted certificates accepted'**
  String get trustAllCertificatesOffSubtitle;

  /// No description provided for @supportTheDev.
  ///
  /// In en, this message translates to:
  /// **'Support the Dev'**
  String get supportTheDev;

  /// No description provided for @buyMeACoffee.
  ///
  /// In en, this message translates to:
  /// **'Buy me a coffee'**
  String get buyMeACoffee;

  /// No description provided for @appVersionFormat.
  ///
  /// In en, this message translates to:
  /// **'Absorb v{version}'**
  String appVersionFormat(String version);

  /// No description provided for @appVersionWithServerFormat.
  ///
  /// In en, this message translates to:
  /// **'Absorb v{version}  -  Server {serverVersion}'**
  String appVersionWithServerFormat(String version, String serverVersion);

  /// No description provided for @backupAndRestore.
  ///
  /// In en, this message translates to:
  /// **'Backup & Restore'**
  String get backupAndRestore;

  /// No description provided for @backupAndRestoreSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Save or restore all your settings to a file'**
  String get backupAndRestoreSubtitle;

  /// No description provided for @backUp.
  ///
  /// In en, this message translates to:
  /// **'Back up'**
  String get backUp;

  /// No description provided for @restore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restore;

  /// No description provided for @allBookmarks.
  ///
  /// In en, this message translates to:
  /// **'All Bookmarks'**
  String get allBookmarks;

  /// No description provided for @allBookmarksSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View bookmarks across all books'**
  String get allBookmarksSubtitle;

  /// No description provided for @switchAccount.
  ///
  /// In en, this message translates to:
  /// **'Switch Account'**
  String get switchAccount;

  /// No description provided for @addAccount.
  ///
  /// In en, this message translates to:
  /// **'Add Account'**
  String get addAccount;

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logOut;

  /// No description provided for @includeLoginInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Include login info?'**
  String get includeLoginInfoTitle;

  /// No description provided for @includeLoginInfoContent.
  ///
  /// In en, this message translates to:
  /// **'Would you like to include login credentials for all your saved accounts in the backup?\n\nThis makes it easy to restore on a new device, but the file will contain your auth tokens.'**
  String get includeLoginInfoContent;

  /// No description provided for @noSettingsOnly.
  ///
  /// In en, this message translates to:
  /// **'No, settings only'**
  String get noSettingsOnly;

  /// No description provided for @yesIncludeAccounts.
  ///
  /// In en, this message translates to:
  /// **'Yes, include accounts'**
  String get yesIncludeAccounts;

  /// No description provided for @backupSavedWithAccounts.
  ///
  /// In en, this message translates to:
  /// **'Backup saved (with accounts)'**
  String get backupSavedWithAccounts;

  /// No description provided for @backupSavedSettingsOnly.
  ///
  /// In en, this message translates to:
  /// **'Backup saved (settings only)'**
  String get backupSavedSettingsOnly;

  /// No description provided for @backupFailed.
  ///
  /// In en, this message translates to:
  /// **'Backup failed: {error}'**
  String backupFailed(String error);

  /// No description provided for @restoreBackupTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore backup?'**
  String get restoreBackupTitle;

  /// No description provided for @restoreBackupContent.
  ///
  /// In en, this message translates to:
  /// **'This will replace all your current settings with the backup values.'**
  String get restoreBackupContent;

  /// No description provided for @fromAbsorbVersion.
  ///
  /// In en, this message translates to:
  /// **'From Absorb v{version}'**
  String fromAbsorbVersion(String version);

  /// No description provided for @restoreAccountsChip.
  ///
  /// In en, this message translates to:
  /// **'{count} account(s)'**
  String restoreAccountsChip(int count);

  /// No description provided for @restoreBookmarksChip.
  ///
  /// In en, this message translates to:
  /// **'Bookmarks for {count} book(s)'**
  String restoreBookmarksChip(int count);

  /// No description provided for @restoreCustomHeadersChip.
  ///
  /// In en, this message translates to:
  /// **'Custom headers'**
  String get restoreCustomHeadersChip;

  /// No description provided for @invalidBackupFile.
  ///
  /// In en, this message translates to:
  /// **'Invalid backup file'**
  String get invalidBackupFile;

  /// No description provided for @settingsRestoredSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Settings restored successfully'**
  String get settingsRestoredSuccessfully;

  /// No description provided for @restoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Restore failed: {error}'**
  String restoreFailed(String error);

  /// No description provided for @logOutTitle.
  ///
  /// In en, this message translates to:
  /// **'Log out?'**
  String get logOutTitle;

  /// No description provided for @logOutContent.
  ///
  /// In en, this message translates to:
  /// **'This will sign you out. Your downloads will stay on this device.'**
  String get logOutContent;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @removeAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove Account?'**
  String get removeAccountTitle;

  /// No description provided for @removeAccountContent.
  ///
  /// In en, this message translates to:
  /// **'Remove {username} on {server} from saved accounts?\n\nYou can always add it back later by signing in again.'**
  String removeAccountContent(String username, String server);

  /// No description provided for @switchAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Switch Account?'**
  String get switchAccountTitle;

  /// No description provided for @switchAccountContent.
  ///
  /// In en, this message translates to:
  /// **'Switch to {username} on {server}?\n\nYour current playback will be stopped and the app will reload with the other account\'s data.'**
  String switchAccountContent(String username, String server);

  /// No description provided for @switchButton.
  ///
  /// In en, this message translates to:
  /// **'Switch'**
  String get switchButton;

  /// No description provided for @downloadLocationSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Download Location'**
  String get downloadLocationSheetTitle;

  /// No description provided for @downloadLocationSheetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose where audiobooks are saved'**
  String get downloadLocationSheetSubtitle;

  /// No description provided for @currentLocation.
  ///
  /// In en, this message translates to:
  /// **'Current location'**
  String get currentLocation;

  /// No description provided for @existingDownloadsWarning.
  ///
  /// In en, this message translates to:
  /// **'Existing downloads stay in their current location. Only new downloads use the new path.'**
  String get existingDownloadsWarning;

  /// No description provided for @chooseFolder.
  ///
  /// In en, this message translates to:
  /// **'Choose folder'**
  String get chooseFolder;

  /// No description provided for @chooseDownloadFolder.
  ///
  /// In en, this message translates to:
  /// **'Choose download folder'**
  String get chooseDownloadFolder;

  /// No description provided for @storagePermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Storage permission permanently denied - enable it in app settings'**
  String get storagePermissionDenied;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettings;

  /// No description provided for @storagePermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Storage permission is required for custom download locations'**
  String get storagePermissionRequired;

  /// No description provided for @cannotWriteToFolder.
  ///
  /// In en, this message translates to:
  /// **'Cannot write to that folder - choose another location or grant file access in system settings'**
  String get cannotWriteToFolder;

  /// No description provided for @downloadLocationSetTo.
  ///
  /// In en, this message translates to:
  /// **'Download location set to {label}'**
  String downloadLocationSetTo(String label);

  /// No description provided for @resetToDefault.
  ///
  /// In en, this message translates to:
  /// **'Reset to default'**
  String get resetToDefault;

  /// No description provided for @resetToDefaultStorage.
  ///
  /// In en, this message translates to:
  /// **'Reset to default storage'**
  String get resetToDefaultStorage;

  /// No description provided for @tipsAndHiddenFeatures.
  ///
  /// In en, this message translates to:
  /// **'Tips & Hidden Features'**
  String get tipsAndHiddenFeatures;

  /// No description provided for @tipsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Get the most out of Absorb'**
  String get tipsSubtitle;

  /// No description provided for @adminTitle.
  ///
  /// In en, this message translates to:
  /// **'Server Admin'**
  String get adminTitle;

  /// No description provided for @adminServer.
  ///
  /// In en, this message translates to:
  /// **'Server'**
  String get adminServer;

  /// No description provided for @adminVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get adminVersion;

  /// No description provided for @adminUsers.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get adminUsers;

  /// No description provided for @adminOnline.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get adminOnline;

  /// No description provided for @adminBackup.
  ///
  /// In en, this message translates to:
  /// **'Backup'**
  String get adminBackup;

  /// No description provided for @adminPurgeCache.
  ///
  /// In en, this message translates to:
  /// **'Purge Cache'**
  String get adminPurgeCache;

  /// No description provided for @adminManage.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get adminManage;

  /// No description provided for @adminUsersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{userCount} accounts - {onlineCount} online'**
  String adminUsersSubtitle(int userCount, int onlineCount);

  /// No description provided for @adminPodcasts.
  ///
  /// In en, this message translates to:
  /// **'Podcasts'**
  String get adminPodcasts;

  /// No description provided for @adminPodcastsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Search, add & manage shows'**
  String get adminPodcastsSubtitle;

  /// No description provided for @adminScan.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get adminScan;

  /// No description provided for @adminScanning.
  ///
  /// In en, this message translates to:
  /// **'Scanning...'**
  String get adminScanning;

  /// No description provided for @adminMatchAll.
  ///
  /// In en, this message translates to:
  /// **'Match All'**
  String get adminMatchAll;

  /// No description provided for @adminMatching.
  ///
  /// In en, this message translates to:
  /// **'Matching...'**
  String get adminMatching;

  /// No description provided for @adminMatchAllTitle.
  ///
  /// In en, this message translates to:
  /// **'Match All Items?'**
  String get adminMatchAllTitle;

  /// No description provided for @adminMatchAllContent.
  ///
  /// In en, this message translates to:
  /// **'Match metadata for all items in {name}? This can take a while.'**
  String adminMatchAllContent(String name);

  /// No description provided for @adminScanStarted.
  ///
  /// In en, this message translates to:
  /// **'Scan started for {name}'**
  String adminScanStarted(String name);

  /// No description provided for @adminBackupCreated.
  ///
  /// In en, this message translates to:
  /// **'Backup created'**
  String get adminBackupCreated;

  /// No description provided for @adminBackupFailed.
  ///
  /// In en, this message translates to:
  /// **'Backup failed'**
  String get adminBackupFailed;

  /// No description provided for @adminCachePurged.
  ///
  /// In en, this message translates to:
  /// **'Cache purged'**
  String get adminCachePurged;

  /// No description provided for @narratedBy.
  ///
  /// In en, this message translates to:
  /// **'Narrated by {narrator}'**
  String narratedBy(String narrator);

  /// No description provided for @onAudible.
  ///
  /// In en, this message translates to:
  /// **'on Audible'**
  String get onAudible;

  /// No description provided for @percentComplete.
  ///
  /// In en, this message translates to:
  /// **'{percent}% complete'**
  String percentComplete(String percent);

  /// No description provided for @absorbing.
  ///
  /// In en, this message translates to:
  /// **'Absorbing...'**
  String get absorbing;

  /// No description provided for @absorbAgain.
  ///
  /// In en, this message translates to:
  /// **'Absorb Again'**
  String get absorbAgain;

  /// No description provided for @absorb.
  ///
  /// In en, this message translates to:
  /// **'Absorb'**
  String get absorb;

  /// No description provided for @ebookOnlyNoAudio.
  ///
  /// In en, this message translates to:
  /// **'eBook Only - No Audio'**
  String get ebookOnlyNoAudio;

  /// No description provided for @fullyAbsorbed.
  ///
  /// In en, this message translates to:
  /// **'Fully Absorbed'**
  String get fullyAbsorbed;

  /// No description provided for @fullyAbsorbAction.
  ///
  /// In en, this message translates to:
  /// **'Fully Absorb'**
  String get fullyAbsorbAction;

  /// No description provided for @removeFromAbsorbing.
  ///
  /// In en, this message translates to:
  /// **'Remove from Absorbing'**
  String get removeFromAbsorbing;

  /// No description provided for @addToAbsorbing.
  ///
  /// In en, this message translates to:
  /// **'Add to Absorbing'**
  String get addToAbsorbing;

  /// No description provided for @removedFromAbsorbing.
  ///
  /// In en, this message translates to:
  /// **'Removed from Absorbing'**
  String get removedFromAbsorbing;

  /// No description provided for @addedToAbsorbing.
  ///
  /// In en, this message translates to:
  /// **'Added to Absorbing'**
  String get addedToAbsorbing;

  /// No description provided for @addToPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Add to Playlist'**
  String get addToPlaylist;

  /// No description provided for @addToCollection.
  ///
  /// In en, this message translates to:
  /// **'Add to Collection'**
  String get addToCollection;

  /// No description provided for @downloadEbook.
  ///
  /// In en, this message translates to:
  /// **'Download eBook'**
  String get downloadEbook;

  /// No description provided for @downloadEbookAgain.
  ///
  /// In en, this message translates to:
  /// **'Download eBook Again'**
  String get downloadEbookAgain;

  /// No description provided for @resetProgress.
  ///
  /// In en, this message translates to:
  /// **'Reset Progress'**
  String get resetProgress;

  /// No description provided for @lookupLocalMetadata.
  ///
  /// In en, this message translates to:
  /// **'Lookup Local Metadata'**
  String get lookupLocalMetadata;

  /// No description provided for @reLookupLocalMetadata.
  ///
  /// In en, this message translates to:
  /// **'Re-Lookup Local Metadata'**
  String get reLookupLocalMetadata;

  /// No description provided for @clearLocalMetadata.
  ///
  /// In en, this message translates to:
  /// **'Clear Local Metadata'**
  String get clearLocalMetadata;

  /// No description provided for @searchOnGoodreads.
  ///
  /// In en, this message translates to:
  /// **'Search on Goodreads'**
  String get searchOnGoodreads;

  /// No description provided for @editServerDetails.
  ///
  /// In en, this message translates to:
  /// **'Edit Server Details'**
  String get editServerDetails;

  /// No description provided for @aboutSection.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutSection;

  /// No description provided for @chaptersCount.
  ///
  /// In en, this message translates to:
  /// **'Chapters ({count})'**
  String chaptersCount(int count);

  /// No description provided for @chapters.
  ///
  /// In en, this message translates to:
  /// **'Chapters'**
  String get chapters;

  /// No description provided for @failedToLoad.
  ///
  /// In en, this message translates to:
  /// **'Failed to load'**
  String get failedToLoad;

  /// No description provided for @startedDate.
  ///
  /// In en, this message translates to:
  /// **'Started {date}'**
  String startedDate(String date);

  /// No description provided for @finishedDate.
  ///
  /// In en, this message translates to:
  /// **'Finished {date}'**
  String finishedDate(String date);

  /// No description provided for @andCountMore.
  ///
  /// In en, this message translates to:
  /// **'and {count} more'**
  String andCountMore(int count);

  /// No description provided for @markAsFullyAbsorbedQuestion.
  ///
  /// In en, this message translates to:
  /// **'Mark as Fully Absorbed?'**
  String get markAsFullyAbsorbedQuestion;

  /// No description provided for @markAsFullyAbsorbedContent.
  ///
  /// In en, this message translates to:
  /// **'This will set your progress to 100% and stop playback if this book is playing.'**
  String get markAsFullyAbsorbedContent;

  /// No description provided for @markedAsFinishedNiceWork.
  ///
  /// In en, this message translates to:
  /// **'Marked as finished - nice work!'**
  String get markedAsFinishedNiceWork;

  /// No description provided for @failedToUpdateCheckConnection.
  ///
  /// In en, this message translates to:
  /// **'Failed to update - check your connection'**
  String get failedToUpdateCheckConnection;

  /// No description provided for @markAsNotFinishedQuestion.
  ///
  /// In en, this message translates to:
  /// **'Mark as Not Finished?'**
  String get markAsNotFinishedQuestion;

  /// No description provided for @markAsNotFinishedContent.
  ///
  /// In en, this message translates to:
  /// **'This will clear the finished status but keep your current position.'**
  String get markAsNotFinishedContent;

  /// No description provided for @unmark.
  ///
  /// In en, this message translates to:
  /// **'Unmark'**
  String get unmark;

  /// No description provided for @markedAsNotFinishedBackAtIt.
  ///
  /// In en, this message translates to:
  /// **'Marked as not finished - back at it!'**
  String get markedAsNotFinishedBackAtIt;

  /// No description provided for @resetProgressQuestion.
  ///
  /// In en, this message translates to:
  /// **'Reset Progress?'**
  String get resetProgressQuestion;

  /// No description provided for @resetProgressContent.
  ///
  /// In en, this message translates to:
  /// **'This will erase all progress for this book and set it back to the beginning. This can\'t be undone.'**
  String get resetProgressContent;

  /// No description provided for @progressResetFreshStart.
  ///
  /// In en, this message translates to:
  /// **'Progress reset - fresh start!'**
  String get progressResetFreshStart;

  /// No description provided for @clearLocalMetadataQuestion.
  ///
  /// In en, this message translates to:
  /// **'Clear Local Metadata?'**
  String get clearLocalMetadataQuestion;

  /// No description provided for @clearLocalMetadataContent.
  ///
  /// In en, this message translates to:
  /// **'This will remove the locally stored metadata and revert to whatever the server has.'**
  String get clearLocalMetadataContent;

  /// No description provided for @localMetadataCleared.
  ///
  /// In en, this message translates to:
  /// **'Local metadata cleared'**
  String get localMetadataCleared;

  /// No description provided for @saveEbook.
  ///
  /// In en, this message translates to:
  /// **'Save eBook'**
  String get saveEbook;

  /// No description provided for @noEbookFileFound.
  ///
  /// In en, this message translates to:
  /// **'No ebook file found'**
  String get noEbookFileFound;

  /// No description provided for @bookmark.
  ///
  /// In en, this message translates to:
  /// **'Bookmark'**
  String get bookmark;

  /// No description provided for @bookmarks.
  ///
  /// In en, this message translates to:
  /// **'Bookmarks'**
  String get bookmarks;

  /// No description provided for @bookmarksWithCount.
  ///
  /// In en, this message translates to:
  /// **'Bookmarks ({count})'**
  String bookmarksWithCount(int count);

  /// No description provided for @playbackSpeed.
  ///
  /// In en, this message translates to:
  /// **'Playback Speed'**
  String get playbackSpeed;

  /// No description provided for @noBookmarksYet.
  ///
  /// In en, this message translates to:
  /// **'No bookmarks yet'**
  String get noBookmarksYet;

  /// No description provided for @longPressBookmarkHint.
  ///
  /// In en, this message translates to:
  /// **'Long-press the bookmark button to quick save'**
  String get longPressBookmarkHint;

  /// No description provided for @addBookmark.
  ///
  /// In en, this message translates to:
  /// **'Add Bookmark'**
  String get addBookmark;

  /// No description provided for @editBookmark.
  ///
  /// In en, this message translates to:
  /// **'Edit Bookmark'**
  String get editBookmark;

  /// No description provided for @titleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get titleLabel;

  /// No description provided for @noteOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get noteOptionalLabel;

  /// No description provided for @editLayout.
  ///
  /// In en, this message translates to:
  /// **'Edit Layout'**
  String get editLayout;

  /// No description provided for @inMenu.
  ///
  /// In en, this message translates to:
  /// **'In menu'**
  String get inMenu;

  /// No description provided for @bookmarkAdded.
  ///
  /// In en, this message translates to:
  /// **'Bookmark added'**
  String get bookmarkAdded;

  /// No description provided for @startPlayingSomethingFirst.
  ///
  /// In en, this message translates to:
  /// **'Start playing something first'**
  String get startPlayingSomethingFirst;

  /// No description provided for @playbackHistory.
  ///
  /// In en, this message translates to:
  /// **'Playback History'**
  String get playbackHistory;

  /// No description provided for @clearHistoryTooltip.
  ///
  /// In en, this message translates to:
  /// **'Clear history'**
  String get clearHistoryTooltip;

  /// No description provided for @tapEventToJump.
  ///
  /// In en, this message translates to:
  /// **'Tap an event to jump to that position'**
  String get tapEventToJump;

  /// No description provided for @noHistoryYet.
  ///
  /// In en, this message translates to:
  /// **'No history yet'**
  String get noHistoryYet;

  /// No description provided for @jumpedToPosition.
  ///
  /// In en, this message translates to:
  /// **'Jumped to {position}'**
  String jumpedToPosition(String position);

  /// No description provided for @booksInSeriesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} books in this series'**
  String booksInSeriesCount(int count);

  /// No description provided for @bookNumber.
  ///
  /// In en, this message translates to:
  /// **'Book {number}'**
  String bookNumber(String number);

  /// No description provided for @downloadRemainingCount.
  ///
  /// In en, this message translates to:
  /// **'Download Remaining ({count})'**
  String downloadRemainingCount(int count);

  /// No description provided for @downloadAll.
  ///
  /// In en, this message translates to:
  /// **'Download All'**
  String get downloadAll;

  /// No description provided for @markAllNotFinished.
  ///
  /// In en, this message translates to:
  /// **'Mark All Not Finished'**
  String get markAllNotFinished;

  /// No description provided for @markAllFinished.
  ///
  /// In en, this message translates to:
  /// **'Mark All Finished'**
  String get markAllFinished;

  /// No description provided for @markAllNotFinishedQuestion.
  ///
  /// In en, this message translates to:
  /// **'Mark All Not Finished?'**
  String get markAllNotFinishedQuestion;

  /// No description provided for @fullyAbsorbSeries.
  ///
  /// In en, this message translates to:
  /// **'Fully Absorb Series?'**
  String get fullyAbsorbSeries;

  /// No description provided for @turnAutoDownloadOff.
  ///
  /// In en, this message translates to:
  /// **'Turn Auto-Download Off'**
  String get turnAutoDownloadOff;

  /// No description provided for @turnAutoDownloadOn.
  ///
  /// In en, this message translates to:
  /// **'Turn Auto-Download On'**
  String get turnAutoDownloadOn;

  /// No description provided for @autoDownloadThisSeries.
  ///
  /// In en, this message translates to:
  /// **'Auto-Download This Series?'**
  String get autoDownloadThisSeries;

  /// No description provided for @autoDownloadSeriesContent.
  ///
  /// In en, this message translates to:
  /// **'Automatically download the next books as you listen.'**
  String get autoDownloadSeriesContent;

  /// No description provided for @standalone.
  ///
  /// In en, this message translates to:
  /// **'Standalone'**
  String get standalone;

  /// No description provided for @episodes.
  ///
  /// In en, this message translates to:
  /// **'Episodes'**
  String get episodes;

  /// No description provided for @noEpisodesFound.
  ///
  /// In en, this message translates to:
  /// **'No episodes found'**
  String get noEpisodesFound;

  /// No description provided for @markFinished.
  ///
  /// In en, this message translates to:
  /// **'Mark Finished'**
  String get markFinished;

  /// No description provided for @markUnfinished.
  ///
  /// In en, this message translates to:
  /// **'Mark Unfinished'**
  String get markUnfinished;

  /// No description provided for @allEpisodes.
  ///
  /// In en, this message translates to:
  /// **'All Episodes'**
  String get allEpisodes;

  /// No description provided for @aboutThisEpisode.
  ///
  /// In en, this message translates to:
  /// **'About This Episode'**
  String get aboutThisEpisode;

  /// No description provided for @reversePlayOrder.
  ///
  /// In en, this message translates to:
  /// **'Reverse play order'**
  String get reversePlayOrder;

  /// No description provided for @selectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String selectedCount(int count);

  /// No description provided for @selectAll.
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get selectAll;

  /// No description provided for @autoDownloadThisPodcast.
  ///
  /// In en, this message translates to:
  /// **'Auto-Download This Podcast?'**
  String get autoDownloadThisPodcast;

  /// No description provided for @autoDownloadPodcastContent.
  ///
  /// In en, this message translates to:
  /// **'Automatically download the next episodes as you listen.'**
  String get autoDownloadPodcastContent;

  /// No description provided for @download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// No description provided for @deleteDownload.
  ///
  /// In en, this message translates to:
  /// **'Delete Download'**
  String get deleteDownload;

  /// No description provided for @casting.
  ///
  /// In en, this message translates to:
  /// **'Casting'**
  String get casting;

  /// No description provided for @castingTo.
  ///
  /// In en, this message translates to:
  /// **'Casting to'**
  String get castingTo;

  /// No description provided for @editDetails.
  ///
  /// In en, this message translates to:
  /// **'Edit Details'**
  String get editDetails;

  /// No description provided for @quickMatch.
  ///
  /// In en, this message translates to:
  /// **'Quick Match'**
  String get quickMatch;

  /// No description provided for @custom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get custom;

  /// No description provided for @authorOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Author (optional)'**
  String get authorOptionalLabel;

  /// No description provided for @noResultsFound.
  ///
  /// In en, this message translates to:
  /// **'No results found.\nTry adjusting your search or provider.'**
  String get noResultsFound;

  /// No description provided for @searchForMetadataAbove.
  ///
  /// In en, this message translates to:
  /// **'Search for metadata above'**
  String get searchForMetadataAbove;

  /// No description provided for @applyThisMatch.
  ///
  /// In en, this message translates to:
  /// **'Apply This Match?'**
  String get applyThisMatch;

  /// No description provided for @metadataUpdated.
  ///
  /// In en, this message translates to:
  /// **'Metadata updated'**
  String get metadataUpdated;

  /// No description provided for @failedToUpdateMetadata.
  ///
  /// In en, this message translates to:
  /// **'Failed to update metadata'**
  String get failedToUpdateMetadata;

  /// No description provided for @subtitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Subtitle'**
  String get subtitleLabel;

  /// No description provided for @authorLabel.
  ///
  /// In en, this message translates to:
  /// **'Author'**
  String get authorLabel;

  /// No description provided for @narratorLabel.
  ///
  /// In en, this message translates to:
  /// **'Narrator'**
  String get narratorLabel;

  /// No description provided for @seriesLabel.
  ///
  /// In en, this message translates to:
  /// **'Series'**
  String get seriesLabel;

  /// No description provided for @descriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get descriptionLabel;

  /// No description provided for @publisherLabel.
  ///
  /// In en, this message translates to:
  /// **'Publisher'**
  String get publisherLabel;

  /// No description provided for @yearLabel.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get yearLabel;

  /// No description provided for @languageLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageLabel;

  /// No description provided for @genresLabel.
  ///
  /// In en, this message translates to:
  /// **'Genres'**
  String get genresLabel;

  /// No description provided for @commaSeparated.
  ///
  /// In en, this message translates to:
  /// **'Comma separated'**
  String get commaSeparated;

  /// No description provided for @asinLabel.
  ///
  /// In en, this message translates to:
  /// **'ASIN'**
  String get asinLabel;

  /// No description provided for @isbnLabel.
  ///
  /// In en, this message translates to:
  /// **'ISBN'**
  String get isbnLabel;

  /// No description provided for @coverImage.
  ///
  /// In en, this message translates to:
  /// **'Cover Image'**
  String get coverImage;

  /// No description provided for @coverUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'Cover URL'**
  String get coverUrlLabel;

  /// No description provided for @coverUrlHint.
  ///
  /// In en, this message translates to:
  /// **'https://...'**
  String get coverUrlHint;

  /// No description provided for @localMetadata.
  ///
  /// In en, this message translates to:
  /// **'Local Metadata'**
  String get localMetadata;

  /// No description provided for @overrideLocalDisplay.
  ///
  /// In en, this message translates to:
  /// **'Override local display'**
  String get overrideLocalDisplay;

  /// No description provided for @metadataSavedLocally.
  ///
  /// In en, this message translates to:
  /// **'Metadata saved locally'**
  String get metadataSavedLocally;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @newNote.
  ///
  /// In en, this message translates to:
  /// **'New Note'**
  String get newNote;

  /// No description provided for @editNote.
  ///
  /// In en, this message translates to:
  /// **'Edit Note'**
  String get editNote;

  /// No description provided for @noNotesYet.
  ///
  /// In en, this message translates to:
  /// **'No notes yet'**
  String get noNotesYet;

  /// No description provided for @markdownIsSupported.
  ///
  /// In en, this message translates to:
  /// **'Markdown is supported'**
  String get markdownIsSupported;

  /// No description provided for @markdownMd.
  ///
  /// In en, this message translates to:
  /// **'Markdown (.md)'**
  String get markdownMd;

  /// No description provided for @keepsFormattingIntact.
  ///
  /// In en, this message translates to:
  /// **'Keeps formatting intact'**
  String get keepsFormattingIntact;

  /// No description provided for @plainTextTxt.
  ///
  /// In en, this message translates to:
  /// **'Plain Text (.txt)'**
  String get plainTextTxt;

  /// No description provided for @simpleTextNoFormatting.
  ///
  /// In en, this message translates to:
  /// **'Simple text, no formatting'**
  String get simpleTextNoFormatting;

  /// No description provided for @untitledNote.
  ///
  /// In en, this message translates to:
  /// **'Untitled note'**
  String get untitledNote;

  /// No description provided for @titleHint.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get titleHint;

  /// No description provided for @noteBodyHint.
  ///
  /// In en, this message translates to:
  /// **'Write your note... (supports markdown)'**
  String get noteBodyHint;

  /// No description provided for @nothingToPreview.
  ///
  /// In en, this message translates to:
  /// **'Nothing to preview'**
  String get nothingToPreview;

  /// No description provided for @audioEnhancements.
  ///
  /// In en, this message translates to:
  /// **'Audio Enhancements'**
  String get audioEnhancements;

  /// No description provided for @presets.
  ///
  /// In en, this message translates to:
  /// **'PRESETS'**
  String get presets;

  /// No description provided for @equalizer.
  ///
  /// In en, this message translates to:
  /// **'EQUALIZER'**
  String get equalizer;

  /// No description provided for @effects.
  ///
  /// In en, this message translates to:
  /// **'EFFECTS'**
  String get effects;

  /// No description provided for @bassBoost.
  ///
  /// In en, this message translates to:
  /// **'Bass Boost'**
  String get bassBoost;

  /// No description provided for @surround.
  ///
  /// In en, this message translates to:
  /// **'Surround'**
  String get surround;

  /// No description provided for @loudness.
  ///
  /// In en, this message translates to:
  /// **'Loudness'**
  String get loudness;

  /// No description provided for @monoAudio.
  ///
  /// In en, this message translates to:
  /// **'Mono Audio'**
  String get monoAudio;

  /// No description provided for @resetAll.
  ///
  /// In en, this message translates to:
  /// **'Reset All'**
  String get resetAll;

  /// No description provided for @collectionNotFound.
  ///
  /// In en, this message translates to:
  /// **'Collection not found'**
  String get collectionNotFound;

  /// No description provided for @deleteCollection.
  ///
  /// In en, this message translates to:
  /// **'Delete Collection'**
  String get deleteCollection;

  /// No description provided for @deleteCollectionContent.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this collection?'**
  String get deleteCollectionContent;

  /// No description provided for @playlistNotFound.
  ///
  /// In en, this message translates to:
  /// **'Playlist not found'**
  String get playlistNotFound;

  /// No description provided for @deletePlaylist.
  ///
  /// In en, this message translates to:
  /// **'Delete Playlist'**
  String get deletePlaylist;

  /// No description provided for @deletePlaylistContent.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this playlist?'**
  String get deletePlaylistContent;

  /// No description provided for @newPlaylist.
  ///
  /// In en, this message translates to:
  /// **'New Playlist'**
  String get newPlaylist;

  /// No description provided for @playlistNameHint.
  ///
  /// In en, this message translates to:
  /// **'Playlist name'**
  String get playlistNameHint;

  /// No description provided for @addedToName.
  ///
  /// In en, this message translates to:
  /// **'Added to \"{name}\"'**
  String addedToName(String name);

  /// No description provided for @failedToAdd.
  ///
  /// In en, this message translates to:
  /// **'Failed to add'**
  String get failedToAdd;

  /// No description provided for @newCollection.
  ///
  /// In en, this message translates to:
  /// **'New Collection'**
  String get newCollection;

  /// No description provided for @collectionNameHint.
  ///
  /// In en, this message translates to:
  /// **'Collection name'**
  String get collectionNameHint;

  /// No description provided for @castToDevice.
  ///
  /// In en, this message translates to:
  /// **'Cast to Device'**
  String get castToDevice;

  /// No description provided for @searchingForCastDevices.
  ///
  /// In en, this message translates to:
  /// **'Searching for Cast devices...'**
  String get searchingForCastDevices;

  /// No description provided for @castDevice.
  ///
  /// In en, this message translates to:
  /// **'Cast Device'**
  String get castDevice;

  /// No description provided for @stopCasting.
  ///
  /// In en, this message translates to:
  /// **'Stop Casting'**
  String get stopCasting;

  /// No description provided for @disconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get disconnect;

  /// No description provided for @audioOutput.
  ///
  /// In en, this message translates to:
  /// **'Audio Output'**
  String get audioOutput;

  /// No description provided for @noOutputDevicesFound.
  ///
  /// In en, this message translates to:
  /// **'No output devices found'**
  String get noOutputDevicesFound;

  /// No description provided for @welcomeToAbsorb.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Absorb'**
  String get welcomeToAbsorb;

  /// No description provided for @welcomeOverview.
  ///
  /// In en, this message translates to:
  /// **'Here\'s a quick overview of how things work.'**
  String get welcomeOverview;

  /// No description provided for @welcomeHomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get welcomeHomeTitle;

  /// No description provided for @welcomeHomeBody.
  ///
  /// In en, this message translates to:
  /// **'Your personalized shelves from Audiobookshelf - continue listening, discover new titles, and browse your playlists and collections. Use the edit button in the top right to customize which sections appear and their order.'**
  String get welcomeHomeBody;

  /// No description provided for @welcomeLibraryTitle.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get welcomeLibraryTitle;

  /// No description provided for @welcomeLibraryBody.
  ///
  /// In en, this message translates to:
  /// **'Browse your full library with tabs for books, series, and authors. Tap the active tab to open sort and filter options.'**
  String get welcomeLibraryBody;

  /// No description provided for @welcomeAbsorbingTitle.
  ///
  /// In en, this message translates to:
  /// **'Absorbing'**
  String get welcomeAbsorbingTitle;

  /// No description provided for @welcomeAbsorbingBody.
  ///
  /// In en, this message translates to:
  /// **'Your active listening queue. Books you start playing automatically appear here as swipeable cards with full playback controls.'**
  String get welcomeAbsorbingBody;

  /// No description provided for @welcomeQueueModesTitle.
  ///
  /// In en, this message translates to:
  /// **'Queue modes'**
  String get welcomeQueueModesTitle;

  /// No description provided for @welcomeQueueModeOff.
  ///
  /// In en, this message translates to:
  /// **'Off - playback stops when a book finishes'**
  String get welcomeQueueModeOff;

  /// No description provided for @welcomeQueueModeManual.
  ///
  /// In en, this message translates to:
  /// **'Manual - auto-plays the next card in your queue'**
  String get welcomeQueueModeManual;

  /// No description provided for @welcomeQueueModeAuto.
  ///
  /// In en, this message translates to:
  /// **'Series - automatically finds and plays the next book in a series'**
  String get welcomeQueueModeAuto;

  /// No description provided for @welcomeManagingQueueTitle.
  ///
  /// In en, this message translates to:
  /// **'Managing your queue'**
  String get welcomeManagingQueueTitle;

  /// No description provided for @welcomeManagingCoverTap.
  ///
  /// In en, this message translates to:
  /// **'Tap the cover art to play/pause (toggleable in Settings)'**
  String get welcomeManagingCoverTap;

  /// No description provided for @welcomeManagingSwipeUp.
  ///
  /// In en, this message translates to:
  /// **'Swipe up on a card to open the full screen player, swipe down to dismiss'**
  String get welcomeManagingSwipeUp;

  /// No description provided for @welcomeManagingSwipeRight.
  ///
  /// In en, this message translates to:
  /// **'Swipe right on any book in a list sheet to quickly add it to your queue'**
  String get welcomeManagingSwipeRight;

  /// No description provided for @welcomeManagingReorder.
  ///
  /// In en, this message translates to:
  /// **'Tap the reorder icon to drag cards into your preferred order or swipe to remove'**
  String get welcomeManagingReorder;

  /// No description provided for @welcomeManagingAdd.
  ///
  /// In en, this message translates to:
  /// **'Add books manually from any book\'s detail sheet'**
  String get welcomeManagingAdd;

  /// No description provided for @welcomeManagingRemoveFinished.
  ///
  /// In en, this message translates to:
  /// **'Finished books are automatically removed from your queue'**
  String get welcomeManagingRemoveFinished;

  /// No description provided for @welcomeMergeLibrariesTitle.
  ///
  /// In en, this message translates to:
  /// **'Merge libraries'**
  String get welcomeMergeLibrariesTitle;

  /// No description provided for @welcomeMergeLibrariesBody.
  ///
  /// In en, this message translates to:
  /// **'Enable in Settings to show all your libraries together in one queue'**
  String get welcomeMergeLibrariesBody;

  /// No description provided for @welcomeDownloadsTitle.
  ///
  /// In en, this message translates to:
  /// **'Downloads & Offline'**
  String get welcomeDownloadsTitle;

  /// No description provided for @welcomeDownloadsBody.
  ///
  /// In en, this message translates to:
  /// **'Download books for offline listening. Toggle offline mode with the airplane icon on the Absorbing screen. Your progress syncs back to the server automatically when you reconnect.'**
  String get welcomeDownloadsBody;

  /// No description provided for @welcomeSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get welcomeSettingsTitle;

  /// No description provided for @welcomeSettingsBody.
  ///
  /// In en, this message translates to:
  /// **'Configure queue behavior, sleep timers, playback speed, local server connections, and more.'**
  String get welcomeSettingsBody;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @showMore.
  ///
  /// In en, this message translates to:
  /// **'Show more'**
  String get showMore;

  /// No description provided for @showLess.
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get showLess;

  /// No description provided for @readMore.
  ///
  /// In en, this message translates to:
  /// **'Read more'**
  String get readMore;

  /// No description provided for @removeDownloadQuestion.
  ///
  /// In en, this message translates to:
  /// **'Remove download?'**
  String get removeDownloadQuestion;

  /// No description provided for @removeDownloadContent.
  ///
  /// In en, this message translates to:
  /// **'This will be removed from your device.'**
  String get removeDownloadContent;

  /// No description provided for @downloadRemoved.
  ///
  /// In en, this message translates to:
  /// **'Download removed'**
  String get downloadRemoved;

  /// No description provided for @finished.
  ///
  /// In en, this message translates to:
  /// **'Finished'**
  String get finished;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @selectLibrary.
  ///
  /// In en, this message translates to:
  /// **'Select Library'**
  String get selectLibrary;

  /// No description provided for @switchLibraryTooltip.
  ///
  /// In en, this message translates to:
  /// **'Switch library'**
  String get switchLibraryTooltip;

  /// No description provided for @noBooksFound.
  ///
  /// In en, this message translates to:
  /// **'No books found'**
  String get noBooksFound;

  /// No description provided for @userFallback.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get userFallback;

  /// No description provided for @rootAdmin.
  ///
  /// In en, this message translates to:
  /// **'Root Admin'**
  String get rootAdmin;

  /// No description provided for @admin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get admin;

  /// No description provided for @serverAdmin.
  ///
  /// In en, this message translates to:
  /// **'Server Admin'**
  String get serverAdmin;

  /// No description provided for @serverAdminSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage users, libraries & server settings'**
  String get serverAdminSubtitle;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}m ago'**
  String minutesAgo(int count);

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}h ago'**
  String hoursAgo(int count);

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}d ago'**
  String daysAgo(int count);

  /// No description provided for @audible.
  ///
  /// In en, this message translates to:
  /// **'Audible'**
  String get audible;

  /// No description provided for @iTunes.
  ///
  /// In en, this message translates to:
  /// **'iTunes'**
  String get iTunes;

  /// No description provided for @openLibrary.
  ///
  /// In en, this message translates to:
  /// **'Open Library'**
  String get openLibrary;

  /// No description provided for @root.
  ///
  /// In en, this message translates to:
  /// **'Root'**
  String get root;

  /// No description provided for @coverPlayPause.
  ///
  /// In en, this message translates to:
  /// **'Cover play/pause'**
  String get coverPlayPause;

  /// No description provided for @coverPlayPauseOnSubtitle.
  ///
  /// In en, this message translates to:
  /// **'On - tap cover art to play/pause'**
  String get coverPlayPauseOnSubtitle;

  /// No description provided for @coverPlayPauseOffSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Off - dedicated play/pause button in controls'**
  String get coverPlayPauseOffSubtitle;

  /// No description provided for @queueModeMergedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Playback stops, manual queue, or auto-absorbs next item'**
  String get queueModeMergedSubtitle;

  /// No description provided for @queueModeSeriesLabel.
  ///
  /// In en, this message translates to:
  /// **'Series'**
  String get queueModeSeriesLabel;

  /// No description provided for @queueModeShowLabel.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get queueModeShowLabel;

  /// No description provided for @queueModeInfoSeries.
  ///
  /// In en, this message translates to:
  /// **'Series'**
  String get queueModeInfoSeries;

  /// No description provided for @queueModeInfoSeriesDesc.
  ///
  /// In en, this message translates to:
  /// **'Automatically plays the next book in a series or the next episode in a podcast show.'**
  String get queueModeInfoSeriesDesc;

  /// No description provided for @resetButtonGridQuestion.
  ///
  /// In en, this message translates to:
  /// **'Reset button grid?'**
  String get resetButtonGridQuestion;

  /// No description provided for @resetButtonGridContent.
  ///
  /// In en, this message translates to:
  /// **'This will restore the default button layout, order, and toggle settings.'**
  String get resetButtonGridContent;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @buttonGridReset.
  ///
  /// In en, this message translates to:
  /// **'Button grid reset'**
  String get buttonGridReset;

  /// No description provided for @resetButtonGrid.
  ///
  /// In en, this message translates to:
  /// **'Reset button grid'**
  String get resetButtonGrid;

  /// No description provided for @chapterBarrierOnRewind.
  ///
  /// In en, this message translates to:
  /// **'Chapter barrier on rewind'**
  String get chapterBarrierOnRewind;

  /// No description provided for @chapterBarrierInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Chapter barrier'**
  String get chapterBarrierInfoTitle;

  /// No description provided for @chapterBarrierInfoContent.
  ///
  /// In en, this message translates to:
  /// **'When skipping back, the playback will snap to the start of the current chapter instead of crossing into the previous one.\n\nDouble-tap the skip back button within 2 seconds to break through the barrier.'**
  String get chapterBarrierInfoContent;

  /// No description provided for @chapterBarrierOnRewindOnSubtitle.
  ///
  /// In en, this message translates to:
  /// **'On - rewind snaps to chapter start'**
  String get chapterBarrierOnRewindOnSubtitle;

  /// No description provided for @chapterBarrierOnRewindOffSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Off - rewind crosses chapter boundaries'**
  String get chapterBarrierOnRewindOffSubtitle;

  /// No description provided for @autoRewindOnSubtitleFormat.
  ///
  /// In en, this message translates to:
  /// **'On -{min}s to {max}s based on pause length'**
  String autoRewindOnSubtitleFormat(String min, String max);

  /// No description provided for @rewindOnSessionStart.
  ///
  /// In en, this message translates to:
  /// **'Rewind on session start'**
  String get rewindOnSessionStart;

  /// No description provided for @rewindOnSessionStartInfoContent.
  ///
  /// In en, this message translates to:
  /// **'Normal auto-rewind triggers when you resume from a pause within an active session. This setting adds a rewind when starting a completely new session - for example after the app was closed, playback was stopped, or you open the app fresh.\n\nWhen enabled, playback rewinds by the full max rewind amount at the start of every new session so you can re-hear where you left off.'**
  String get rewindOnSessionStartInfoContent;

  /// No description provided for @rewindOnSessionStartOnSubtitle.
  ///
  /// In en, this message translates to:
  /// **'On - rewinds {seconds}s when starting a new session'**
  String rewindOnSessionStartOnSubtitle(String seconds);

  /// No description provided for @rewindActivationDelayValue.
  ///
  /// In en, this message translates to:
  /// **'{seconds}s+'**
  String rewindActivationDelayValue(String seconds);

  /// No description provided for @rewindRangeValue.
  ///
  /// In en, this message translates to:
  /// **'{min}s – {max}s'**
  String rewindRangeValue(String min, String max);

  /// No description provided for @rewindSecondsPause.
  ///
  /// In en, this message translates to:
  /// **'{seconds}s pause'**
  String rewindSecondsPause(String seconds);

  /// No description provided for @rewindMinPause.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min pause'**
  String rewindMinPause(String minutes);

  /// No description provided for @rewindHrPause.
  ///
  /// In en, this message translates to:
  /// **'{hours} hr pause'**
  String rewindHrPause(String hours);

  /// No description provided for @rewindOneHrPause.
  ///
  /// In en, this message translates to:
  /// **'1 hr pause'**
  String get rewindOneHrPause;

  /// No description provided for @speedValue.
  ///
  /// In en, this message translates to:
  /// **'{speed}x'**
  String speedValue(String speed);

  /// No description provided for @secondsValue.
  ///
  /// In en, this message translates to:
  /// **'{seconds}s'**
  String secondsValue(String seconds);

  /// No description provided for @minutesValue.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String minutesValue(int minutes);

  /// No description provided for @chimeBeforeSleep.
  ///
  /// In en, this message translates to:
  /// **'Chime before sleep'**
  String get chimeBeforeSleep;

  /// No description provided for @chimeBeforeSleepOnSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Plays a gentle bell when the timer is about to end'**
  String get chimeBeforeSleepOnSubtitle;

  /// No description provided for @chimeBeforeSleepOffSubtitle.
  ///
  /// In en, this message translates to:
  /// **'No sound warning before sleep'**
  String get chimeBeforeSleepOffSubtitle;

  /// No description provided for @windDownDuration.
  ///
  /// In en, this message translates to:
  /// **'Wind-down duration'**
  String get windDownDuration;

  /// No description provided for @windDownDurationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Fade and chime start {seconds}s before sleep'**
  String windDownDurationSubtitle(int seconds);

  /// No description provided for @fadeVolumeOnSubtitleDynamic.
  ///
  /// In en, this message translates to:
  /// **'Gradually lowers volume over the last {seconds}s'**
  String fadeVolumeOnSubtitleDynamic(int seconds);

  /// No description provided for @autoSleepTimerEnabledSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{start} – {end} · {duration}'**
  String autoSleepTimerEnabledSubtitle(
      String start, String end, String duration);

  /// No description provided for @endOfChapterShort.
  ///
  /// In en, this message translates to:
  /// **'End of chapter'**
  String get endOfChapterShort;

  /// No description provided for @endOfChapterOnSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Stop at the end of the current chapter'**
  String get endOfChapterOnSubtitle;

  /// No description provided for @endOfChapterOffSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use a timed sleep timer'**
  String get endOfChapterOffSubtitle;

  /// No description provided for @showExplicitBadge.
  ///
  /// In en, this message translates to:
  /// **'Show explicit badge'**
  String get showExplicitBadge;

  /// No description provided for @showExplicitBadgeOnSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Explicit items show an \"E\" badge'**
  String get showExplicitBadgeOnSubtitle;

  /// No description provided for @showExplicitBadgeOffSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Off - explicit badge hidden'**
  String get showExplicitBadgeOffSubtitle;

  /// No description provided for @libraryFallback.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get libraryFallback;

  /// No description provided for @preReleaseUpdatesInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Pre-release Updates'**
  String get preReleaseUpdatesInfoTitle;

  /// No description provided for @preReleaseUpdatesInfoContent.
  ///
  /// In en, this message translates to:
  /// **'When enabled, the update checker will also notify you about alpha and pre-release builds from GitHub. These may be less stable but include the latest features and fixes.'**
  String get preReleaseUpdatesInfoContent;

  /// No description provided for @includePreReleases.
  ///
  /// In en, this message translates to:
  /// **'Include pre-releases'**
  String get includePreReleases;

  /// No description provided for @includePreReleasesOnSubtitle.
  ///
  /// In en, this message translates to:
  /// **'On - checking for alpha & pre-release builds'**
  String get includePreReleasesOnSubtitle;

  /// No description provided for @includePreReleasesOffSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Off - stable releases only'**
  String get includePreReleasesOffSubtitle;

  /// No description provided for @setTooltip.
  ///
  /// In en, this message translates to:
  /// **'Set'**
  String get setTooltip;

  /// No description provided for @saveAbsorbBackup.
  ///
  /// In en, this message translates to:
  /// **'Save Absorb backup'**
  String get saveAbsorbBackup;

  /// No description provided for @checkForUpdate.
  ///
  /// In en, this message translates to:
  /// **'Check for update'**
  String get checkForUpdate;

  /// No description provided for @onLatestVersion.
  ///
  /// In en, this message translates to:
  /// **'You\'re on the latest version'**
  String get onLatestVersion;

  /// No description provided for @updateAvailable.
  ///
  /// In en, this message translates to:
  /// **'Update available'**
  String get updateAvailable;

  /// No description provided for @preReleaseAvailable.
  ///
  /// In en, this message translates to:
  /// **'Pre-release available'**
  String get preReleaseAvailable;

  /// No description provided for @updateDialogContent.
  ///
  /// In en, this message translates to:
  /// **'A new {kind} of Absorb is available: {latest}\n\nYou are on {current}.'**
  String updateDialogContent(String kind, String latest, String current);

  /// No description provided for @updateKindPreRelease.
  ///
  /// In en, this message translates to:
  /// **'pre-release'**
  String get updateKindPreRelease;

  /// No description provided for @updateKindVersion.
  ///
  /// In en, this message translates to:
  /// **'version'**
  String get updateKindVersion;

  /// No description provided for @downloadButton.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get downloadButton;

  /// No description provided for @libraryCountOne.
  ///
  /// In en, this message translates to:
  /// **'{count} library'**
  String libraryCountOne(int count);

  /// No description provided for @libraryCountOther.
  ///
  /// In en, this message translates to:
  /// **'{count} libraries'**
  String libraryCountOther(int count);

  /// No description provided for @serverVersionLabel.
  ///
  /// In en, this message translates to:
  /// **'Server {version}'**
  String serverVersionLabel(String version);

  /// No description provided for @appVersionServerSuffix.
  ///
  /// In en, this message translates to:
  /// **'  ·  Server {version}'**
  String appVersionServerSuffix(String version);

  /// No description provided for @backupDateFormat.
  ///
  /// In en, this message translates to:
  /// **'{month}/{day}/{year}'**
  String backupDateFormat(int month, int day, int year);

  /// No description provided for @backupDetailsSeparator.
  ///
  /// In en, this message translates to:
  /// **' · '**
  String get backupDetailsSeparator;

  /// No description provided for @bookmarksSortedByPositionReversed.
  ///
  /// In en, this message translates to:
  /// **'Sorted by position (reversed)'**
  String get bookmarksSortedByPositionReversed;

  /// No description provided for @bookmarksJumpShortContent.
  ///
  /// In en, this message translates to:
  /// **'\"{title}\" at {position}'**
  String bookmarksJumpShortContent(String title, String position);

  /// No description provided for @deleteBookmarkQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete bookmark?'**
  String get deleteBookmarkQuestion;

  /// No description provided for @bookmarkAtPosition.
  ///
  /// In en, this message translates to:
  /// **'Bookmark at {position}'**
  String bookmarkAtPosition(String position);

  /// No description provided for @cardIconsOnlyChip.
  ///
  /// In en, this message translates to:
  /// **'Icons only'**
  String get cardIconsOnlyChip;

  /// No description provided for @cardMoreInGridChip.
  ///
  /// In en, this message translates to:
  /// **'\"More\" in grid'**
  String get cardMoreInGridChip;

  /// No description provided for @cardLayoutHidden.
  ///
  /// In en, this message translates to:
  /// **'Hidden'**
  String get cardLayoutHidden;

  /// No description provided for @speed.
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get speed;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @episodeDetailsLabel.
  ///
  /// In en, this message translates to:
  /// **'Episode Details'**
  String get episodeDetailsLabel;

  /// No description provided for @bookDetailsLabel.
  ///
  /// In en, this message translates to:
  /// **'Book Details'**
  String get bookDetailsLabel;

  /// No description provided for @equalizerShort.
  ///
  /// In en, this message translates to:
  /// **'EQ'**
  String get equalizerShort;

  /// No description provided for @equalizerLabel.
  ///
  /// In en, this message translates to:
  /// **'Equalizer'**
  String get equalizerLabel;

  /// No description provided for @cast.
  ///
  /// In en, this message translates to:
  /// **'Cast'**
  String get cast;

  /// No description provided for @castingToDevice.
  ///
  /// In en, this message translates to:
  /// **'Casting to {device}'**
  String castingToDevice(String device);

  /// No description provided for @castToDeviceNamed.
  ///
  /// In en, this message translates to:
  /// **'Cast to {device}'**
  String castToDeviceNamed(String device);

  /// No description provided for @historyShort.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get historyShort;

  /// No description provided for @atPosition.
  ///
  /// In en, this message translates to:
  /// **'at {position}'**
  String atPosition(String position);

  /// No description provided for @chaptersChip.
  ///
  /// In en, this message translates to:
  /// **'{count} chapters'**
  String chaptersChip(int count);

  /// No description provided for @chapterNumber.
  ///
  /// In en, this message translates to:
  /// **'Chapter {number}'**
  String chapterNumber(int number);

  /// No description provided for @kbpsValue.
  ///
  /// In en, this message translates to:
  /// **'{value} kbps'**
  String kbpsValue(int value);

  /// No description provided for @resetMayNotHaveSynced.
  ///
  /// In en, this message translates to:
  /// **'Reset may not have synced - check your server'**
  String get resetMayNotHaveSynced;

  /// No description provided for @failedToDownloadEbook.
  ///
  /// In en, this message translates to:
  /// **'Failed to download ebook ({code})'**
  String failedToDownloadEbook(int code);

  /// No description provided for @serverReturnedErrorPage.
  ///
  /// In en, this message translates to:
  /// **'Server returned an error page instead of the ebook file'**
  String get serverReturnedErrorPage;

  /// No description provided for @ebookSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved: {filename}'**
  String ebookSaved(String filename);

  /// No description provided for @errorSavingEbook.
  ///
  /// In en, this message translates to:
  /// **'Error saving ebook: {error}'**
  String errorSavingEbook(String error);

  /// No description provided for @failedToSaveError.
  ///
  /// In en, this message translates to:
  /// **'Failed to save: {error}'**
  String failedToSaveError(String error);

  /// No description provided for @adminBackupsLabel.
  ///
  /// In en, this message translates to:
  /// **'Backups'**
  String get adminBackupsLabel;

  /// No description provided for @adminListeningNow.
  ///
  /// In en, this message translates to:
  /// **'Listening Now'**
  String get adminListeningNow;

  /// No description provided for @adminLibraries.
  ///
  /// In en, this message translates to:
  /// **'Libraries'**
  String get adminLibraries;

  /// No description provided for @adminLibraryShows.
  ///
  /// In en, this message translates to:
  /// **'shows'**
  String get adminLibraryShows;

  /// No description provided for @adminLibraryBooks.
  ///
  /// In en, this message translates to:
  /// **'books'**
  String get adminLibraryBooks;

  /// No description provided for @adminLibraryFolders.
  ///
  /// In en, this message translates to:
  /// **'folders'**
  String get adminLibraryFolders;

  /// No description provided for @adminLibrarySize.
  ///
  /// In en, this message translates to:
  /// **'size'**
  String get adminLibrarySize;

  /// No description provided for @adminLibraryDuration.
  ///
  /// In en, this message translates to:
  /// **'duration'**
  String get adminLibraryDuration;

  /// No description provided for @adminMatchAction.
  ///
  /// In en, this message translates to:
  /// **'Match'**
  String get adminMatchAction;

  /// No description provided for @adminMatchingStarted.
  ///
  /// In en, this message translates to:
  /// **'Matching started for {name}'**
  String adminMatchingStarted(String name);

  /// No description provided for @adminMatchFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get adminMatchFailed;

  /// No description provided for @adminScanFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to scan {name}'**
  String adminScanFailed(String name);

  /// No description provided for @adminPurgeCacheFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get adminPurgeCacheFailed;

  /// No description provided for @adminUsersRootBadge.
  ///
  /// In en, this message translates to:
  /// **'root'**
  String get adminUsersRootBadge;

  /// No description provided for @adminUsersAdminBadge.
  ///
  /// In en, this message translates to:
  /// **'admin'**
  String get adminUsersAdminBadge;

  /// No description provided for @adminUsersDisabledBadge.
  ///
  /// In en, this message translates to:
  /// **'disabled'**
  String get adminUsersDisabledBadge;

  /// No description provided for @adminUsersEditUserTooltip.
  ///
  /// In en, this message translates to:
  /// **'Edit user'**
  String get adminUsersEditUserTooltip;

  /// No description provided for @adminUsersOnlineNow.
  ///
  /// In en, this message translates to:
  /// **'Online now'**
  String get adminUsersOnlineNow;

  /// No description provided for @adminUsersLastSeen.
  ///
  /// In en, this message translates to:
  /// **'Last seen {time}'**
  String adminUsersLastSeen(String time);

  /// No description provided for @adminUsersNever.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get adminUsersNever;

  /// No description provided for @adminUsersTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get adminUsersTotal;

  /// No description provided for @adminUsersNoReadingActivity.
  ///
  /// In en, this message translates to:
  /// **'No reading activity'**
  String get adminUsersNoReadingActivity;

  /// No description provided for @adminUsersLoadingDots.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get adminUsersLoadingDots;

  /// No description provided for @adminUsersLoadMoreSessions.
  ///
  /// In en, this message translates to:
  /// **'Load more sessions'**
  String get adminUsersLoadMoreSessions;

  /// No description provided for @adminUsersNoRecentSessions.
  ///
  /// In en, this message translates to:
  /// **'No recent sessions'**
  String get adminUsersNoRecentSessions;

  /// No description provided for @adminUsersLibraryProgress.
  ///
  /// In en, this message translates to:
  /// **'Library Progress'**
  String get adminUsersLibraryProgress;

  /// No description provided for @adminUsersLoadMoreRemaining.
  ///
  /// In en, this message translates to:
  /// **'Load More ({count} remaining)'**
  String adminUsersLoadMoreRemaining(int count);

  /// No description provided for @adminUsersMonthsAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}mo ago'**
  String adminUsersMonthsAgo(int count);

  /// No description provided for @adminUsersNewUser.
  ///
  /// In en, this message translates to:
  /// **'New User'**
  String get adminUsersNewUser;

  /// No description provided for @adminUsersEditUser.
  ///
  /// In en, this message translates to:
  /// **'Edit User'**
  String get adminUsersEditUser;

  /// No description provided for @adminUsersUsername.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get adminUsersUsername;

  /// No description provided for @adminUsersEnterUsername.
  ///
  /// In en, this message translates to:
  /// **'Enter username'**
  String get adminUsersEnterUsername;

  /// No description provided for @adminUsersPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get adminUsersPassword;

  /// No description provided for @adminUsersNewPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get adminUsersNewPassword;

  /// No description provided for @adminUsersEnterPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter password'**
  String get adminUsersEnterPassword;

  /// No description provided for @adminUsersLeaveBlankToKeep.
  ///
  /// In en, this message translates to:
  /// **'Leave blank to keep current'**
  String get adminUsersLeaveBlankToKeep;

  /// No description provided for @adminUsersAccountType.
  ///
  /// In en, this message translates to:
  /// **'Account Type'**
  String get adminUsersAccountType;

  /// No description provided for @adminUsersTypeGuest.
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get adminUsersTypeGuest;

  /// No description provided for @adminUsersTypeUser.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get adminUsersTypeUser;

  /// No description provided for @adminUsersTypeAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get adminUsersTypeAdmin;

  /// No description provided for @adminUsersStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get adminUsersStatus;

  /// No description provided for @adminUsersAccountActive.
  ///
  /// In en, this message translates to:
  /// **'Account Active'**
  String get adminUsersAccountActive;

  /// No description provided for @adminUsersAccountActiveSub.
  ///
  /// In en, this message translates to:
  /// **'Disabled accounts cannot log in'**
  String get adminUsersAccountActiveSub;

  /// No description provided for @adminUsersLocked.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get adminUsersLocked;

  /// No description provided for @adminUsersLockedSub.
  ///
  /// In en, this message translates to:
  /// **'Prevents password changes'**
  String get adminUsersLockedSub;

  /// No description provided for @adminUsersPermissions.
  ///
  /// In en, this message translates to:
  /// **'Permissions'**
  String get adminUsersPermissions;

  /// No description provided for @adminUsersPermDownload.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get adminUsersPermDownload;

  /// No description provided for @adminUsersPermUpdate.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get adminUsersPermUpdate;

  /// No description provided for @adminUsersPermUpdateSub.
  ///
  /// In en, this message translates to:
  /// **'Edit metadata and library items'**
  String get adminUsersPermUpdateSub;

  /// No description provided for @adminUsersPermDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get adminUsersPermDelete;

  /// No description provided for @adminUsersPermUpload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get adminUsersPermUpload;

  /// No description provided for @adminUsersPermExplicit.
  ///
  /// In en, this message translates to:
  /// **'Explicit Content'**
  String get adminUsersPermExplicit;

  /// No description provided for @adminUsersLibraryAccess.
  ///
  /// In en, this message translates to:
  /// **'Library Access'**
  String get adminUsersLibraryAccess;

  /// No description provided for @adminUsersAccessAllLibraries.
  ///
  /// In en, this message translates to:
  /// **'Access All Libraries'**
  String get adminUsersAccessAllLibraries;

  /// No description provided for @adminUsersCreateUser.
  ///
  /// In en, this message translates to:
  /// **'Create User'**
  String get adminUsersCreateUser;

  /// No description provided for @adminUsersSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get adminUsersSaveChanges;

  /// No description provided for @adminUsersUsernameRequired.
  ///
  /// In en, this message translates to:
  /// **'Username is required'**
  String get adminUsersUsernameRequired;

  /// No description provided for @adminUsersPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get adminUsersPasswordRequired;

  /// No description provided for @adminUsersUserCreated.
  ///
  /// In en, this message translates to:
  /// **'User created'**
  String get adminUsersUserCreated;

  /// No description provided for @adminUsersUserUpdated.
  ///
  /// In en, this message translates to:
  /// **'User updated'**
  String get adminUsersUserUpdated;

  /// No description provided for @adminUsersFailedCreate.
  ///
  /// In en, this message translates to:
  /// **'Failed to create user'**
  String get adminUsersFailedCreate;

  /// No description provided for @adminUsersFailedUpdate.
  ///
  /// In en, this message translates to:
  /// **'Failed to update user'**
  String get adminUsersFailedUpdate;

  /// No description provided for @adminUsersThisUser.
  ///
  /// In en, this message translates to:
  /// **'this user'**
  String get adminUsersThisUser;

  /// No description provided for @adminUsersDeleteUserTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete User?'**
  String get adminUsersDeleteUserTitle;

  /// No description provided for @adminUsersDeleteUserContent.
  ///
  /// In en, this message translates to:
  /// **'Permanently delete {name}?'**
  String adminUsersDeleteUserContent(String name);

  /// No description provided for @adminUsersUserDeleted.
  ///
  /// In en, this message translates to:
  /// **'{name} deleted'**
  String adminUsersUserDeleted(String name);

  /// No description provided for @adminUsersFailedDelete.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete user'**
  String get adminUsersFailedDelete;

  /// No description provided for @adminUsersByAuthor.
  ///
  /// In en, this message translates to:
  /// **'by {author}'**
  String adminUsersByAuthor(String author);

  /// No description provided for @adminUsersListened.
  ///
  /// In en, this message translates to:
  /// **'Listened'**
  String get adminUsersListened;

  /// No description provided for @adminUsersStartedAtPosition.
  ///
  /// In en, this message translates to:
  /// **'Started at position'**
  String get adminUsersStartedAtPosition;

  /// No description provided for @adminUsersEndedAtPosition.
  ///
  /// In en, this message translates to:
  /// **'Ended at position'**
  String get adminUsersEndedAtPosition;

  /// No description provided for @adminUsersTotalDuration.
  ///
  /// In en, this message translates to:
  /// **'Total duration'**
  String get adminUsersTotalDuration;

  /// No description provided for @adminUsersStarted.
  ///
  /// In en, this message translates to:
  /// **'Started'**
  String get adminUsersStarted;

  /// No description provided for @adminUsersUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get adminUsersUpdated;

  /// No description provided for @adminUsersClient.
  ///
  /// In en, this message translates to:
  /// **'Client'**
  String get adminUsersClient;

  /// No description provided for @adminUsersDevice.
  ///
  /// In en, this message translates to:
  /// **'Device'**
  String get adminUsersDevice;

  /// No description provided for @adminUsersOs.
  ///
  /// In en, this message translates to:
  /// **'OS'**
  String get adminUsersOs;

  /// No description provided for @adminUsersPlayMethod.
  ///
  /// In en, this message translates to:
  /// **'Play method'**
  String get adminUsersPlayMethod;

  /// No description provided for @adminUsersPlayDirect.
  ///
  /// In en, this message translates to:
  /// **'Direct play'**
  String get adminUsersPlayDirect;

  /// No description provided for @adminUsersPlayDirectStream.
  ///
  /// In en, this message translates to:
  /// **'Direct stream'**
  String get adminUsersPlayDirectStream;

  /// No description provided for @adminUsersPlayTranscode.
  ///
  /// In en, this message translates to:
  /// **'Transcode'**
  String get adminUsersPlayTranscode;

  /// No description provided for @adminUsersPlayLocal.
  ///
  /// In en, this message translates to:
  /// **'Local'**
  String get adminUsersPlayLocal;

  /// No description provided for @adminPodcastsCheckNewEpisodesTitle.
  ///
  /// In en, this message translates to:
  /// **'Check for New Episodes'**
  String get adminPodcastsCheckNewEpisodesTitle;

  /// No description provided for @adminPodcastsCheckNewEpisodesContent.
  ///
  /// In en, this message translates to:
  /// **'This will check RSS feeds for all podcasts and download any new episodes found (if auto-download is enabled).'**
  String get adminPodcastsCheckNewEpisodesContent;

  /// No description provided for @adminPodcastsCheckNewEpisodesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Scan RSS feed and download new episodes'**
  String get adminPodcastsCheckNewEpisodesSubtitle;

  /// No description provided for @adminPodcastsCheck.
  ///
  /// In en, this message translates to:
  /// **'Check'**
  String get adminPodcastsCheck;

  /// No description provided for @adminPodcastsCheckingForNew.
  ///
  /// In en, this message translates to:
  /// **'Checking for new episodes…'**
  String get adminPodcastsCheckingForNew;

  /// No description provided for @adminPodcastsCheckingForNewDots.
  ///
  /// In en, this message translates to:
  /// **'Checking for new episodes...'**
  String get adminPodcastsCheckingForNewDots;

  /// No description provided for @adminPodcastsFailedCheckEpisodes.
  ///
  /// In en, this message translates to:
  /// **'Failed to check episodes'**
  String get adminPodcastsFailedCheckEpisodes;

  /// No description provided for @adminPodcastsCheckFeedsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Check feeds for new episodes'**
  String get adminPodcastsCheckFeedsTooltip;

  /// No description provided for @adminPodcastsNoPodcastsYet.
  ///
  /// In en, this message translates to:
  /// **'No podcasts yet'**
  String get adminPodcastsNoPodcastsYet;

  /// No description provided for @adminPodcastsTapPlusHint.
  ///
  /// In en, this message translates to:
  /// **'Tap + to search and add shows'**
  String get adminPodcastsTapPlusHint;

  /// No description provided for @adminPodcastsEpisodesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} episodes'**
  String adminPodcastsEpisodesCount(int count);

  /// No description provided for @adminPodcastsAddPodcast.
  ///
  /// In en, this message translates to:
  /// **'Add Podcast'**
  String get adminPodcastsAddPodcast;

  /// No description provided for @adminPodcastsCouldNotFindFeed.
  ///
  /// In en, this message translates to:
  /// **'Could not find podcast feed'**
  String get adminPodcastsCouldNotFindFeed;

  /// No description provided for @adminPodcastsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search for podcasts…'**
  String get adminPodcastsSearchHint;

  /// No description provided for @adminPodcastsSearchItunesHint.
  ///
  /// In en, this message translates to:
  /// **'Search iTunes...'**
  String get adminPodcastsSearchItunesHint;

  /// No description provided for @adminPodcastsNoPodcastsFound.
  ///
  /// In en, this message translates to:
  /// **'No podcasts found'**
  String get adminPodcastsNoPodcastsFound;

  /// No description provided for @adminPodcastsRelToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get adminPodcastsRelToday;

  /// No description provided for @adminPodcastsWeeksAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}w ago'**
  String adminPodcastsWeeksAgo(int count);

  /// No description provided for @adminPodcastsMonthsAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}mo ago'**
  String adminPodcastsMonthsAgo(int count);

  /// No description provided for @adminPodcastsYearsAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}y ago'**
  String adminPodcastsYearsAgo(int count);

  /// No description provided for @adminPodcastsUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated {when}'**
  String adminPodcastsUpdated(String when);

  /// No description provided for @adminPodcastsGenreAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get adminPodcastsGenreAll;

  /// No description provided for @adminPodcastsGenreArts.
  ///
  /// In en, this message translates to:
  /// **'Arts'**
  String get adminPodcastsGenreArts;

  /// No description provided for @adminPodcastsGenreComedy.
  ///
  /// In en, this message translates to:
  /// **'Comedy'**
  String get adminPodcastsGenreComedy;

  /// No description provided for @adminPodcastsGenreEducation.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get adminPodcastsGenreEducation;

  /// No description provided for @adminPodcastsGenreTvFilm.
  ///
  /// In en, this message translates to:
  /// **'TV & Film'**
  String get adminPodcastsGenreTvFilm;

  /// No description provided for @adminPodcastsGenreMusic.
  ///
  /// In en, this message translates to:
  /// **'Music'**
  String get adminPodcastsGenreMusic;

  /// No description provided for @adminPodcastsGenreNews.
  ///
  /// In en, this message translates to:
  /// **'News'**
  String get adminPodcastsGenreNews;

  /// No description provided for @adminPodcastsGenreReligion.
  ///
  /// In en, this message translates to:
  /// **'Religion'**
  String get adminPodcastsGenreReligion;

  /// No description provided for @adminPodcastsGenreScience.
  ///
  /// In en, this message translates to:
  /// **'Science'**
  String get adminPodcastsGenreScience;

  /// No description provided for @adminPodcastsGenreSports.
  ///
  /// In en, this message translates to:
  /// **'Sports'**
  String get adminPodcastsGenreSports;

  /// No description provided for @adminPodcastsGenreTechnology.
  ///
  /// In en, this message translates to:
  /// **'Technology'**
  String get adminPodcastsGenreTechnology;

  /// No description provided for @adminPodcastsGenreBusiness.
  ///
  /// In en, this message translates to:
  /// **'Business'**
  String get adminPodcastsGenreBusiness;

  /// No description provided for @adminPodcastsGenreFiction.
  ///
  /// In en, this message translates to:
  /// **'Fiction'**
  String get adminPodcastsGenreFiction;

  /// No description provided for @adminPodcastsGenreSocietyCulture.
  ///
  /// In en, this message translates to:
  /// **'Society & Culture'**
  String get adminPodcastsGenreSocietyCulture;

  /// No description provided for @adminPodcastsGenreHealthFitness.
  ///
  /// In en, this message translates to:
  /// **'Health & Fitness'**
  String get adminPodcastsGenreHealthFitness;

  /// No description provided for @adminPodcastsGenreTrueCrime.
  ///
  /// In en, this message translates to:
  /// **'True Crime'**
  String get adminPodcastsGenreTrueCrime;

  /// No description provided for @adminPodcastsGenreHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get adminPodcastsGenreHistory;

  /// No description provided for @adminPodcastsGenreKidsFamily.
  ///
  /// In en, this message translates to:
  /// **'Kids & Family'**
  String get adminPodcastsGenreKidsFamily;

  /// No description provided for @adminPodcastsPodcastFallback.
  ///
  /// In en, this message translates to:
  /// **'Podcast'**
  String get adminPodcastsPodcastFallback;

  /// No description provided for @adminPodcastsEpisodeFallback.
  ///
  /// In en, this message translates to:
  /// **'Episode'**
  String get adminPodcastsEpisodeFallback;

  /// No description provided for @adminPodcastsNoFeedFound.
  ///
  /// In en, this message translates to:
  /// **'No feed URL found'**
  String get adminPodcastsNoFeedFound;

  /// No description provided for @adminPodcastsNoFeedAvailable.
  ///
  /// In en, this message translates to:
  /// **'No feed URL available'**
  String get adminPodcastsNoFeedAvailable;

  /// No description provided for @adminPodcastsAddedToLibrary.
  ///
  /// In en, this message translates to:
  /// **'{title} added to library'**
  String adminPodcastsAddedToLibrary(String title);

  /// No description provided for @adminPodcastsFailedToAdd.
  ///
  /// In en, this message translates to:
  /// **'Failed to add {title}'**
  String adminPodcastsFailedToAdd(String title);

  /// No description provided for @adminPodcastsEpisodesInFeed.
  ///
  /// In en, this message translates to:
  /// **'{count} episodes in feed'**
  String adminPodcastsEpisodesInFeed(int count);

  /// No description provided for @adminPodcastsMoreEpisodes.
  ///
  /// In en, this message translates to:
  /// **'+ {count} more episodes'**
  String adminPodcastsMoreEpisodes(int count);

  /// No description provided for @adminPodcastsAdding.
  ///
  /// In en, this message translates to:
  /// **'Adding…'**
  String get adminPodcastsAdding;

  /// No description provided for @adminPodcastsAddToLibrary.
  ///
  /// In en, this message translates to:
  /// **'Add to Library'**
  String get adminPodcastsAddToLibrary;

  /// No description provided for @adminPodcastsRemoveShowTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove Show?'**
  String get adminPodcastsRemoveShowTitle;

  /// No description provided for @adminPodcastsRemoveShowContent.
  ///
  /// In en, this message translates to:
  /// **'Remove \"{title}\" and all its episodes from the server? This cannot be undone.'**
  String adminPodcastsRemoveShowContent(String title);

  /// No description provided for @adminPodcastsRemovedShow.
  ///
  /// In en, this message translates to:
  /// **'Removed \"{title}\"'**
  String adminPodcastsRemovedShow(String title);

  /// No description provided for @adminPodcastsFailedRemoveShow.
  ///
  /// In en, this message translates to:
  /// **'Failed to remove show'**
  String get adminPodcastsFailedRemoveShow;

  /// No description provided for @adminPodcastsRemoveShowTooltip.
  ///
  /// In en, this message translates to:
  /// **'Remove show'**
  String get adminPodcastsRemoveShowTooltip;

  /// No description provided for @adminPodcastsSelectMultipleTooltip.
  ///
  /// In en, this message translates to:
  /// **'Select multiple'**
  String get adminPodcastsSelectMultipleTooltip;

  /// No description provided for @adminPodcastsDownloadedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} downloaded'**
  String adminPodcastsDownloadedCount(int count);

  /// No description provided for @adminPodcastsTabDownloaded.
  ///
  /// In en, this message translates to:
  /// **'Downloaded'**
  String get adminPodcastsTabDownloaded;

  /// No description provided for @adminPodcastsTabFeed.
  ///
  /// In en, this message translates to:
  /// **'Feed'**
  String get adminPodcastsTabFeed;

  /// No description provided for @adminPodcastsTabSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get adminPodcastsTabSettings;

  /// No description provided for @adminPodcastsDownloadingEpisode.
  ///
  /// In en, this message translates to:
  /// **'Downloading \"{title}\"'**
  String adminPodcastsDownloadingEpisode(String title);

  /// No description provided for @adminPodcastsFailedDownload.
  ///
  /// In en, this message translates to:
  /// **'Failed to download'**
  String get adminPodcastsFailedDownload;

  /// No description provided for @adminPodcastsDeleteEpisodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Episode?'**
  String get adminPodcastsDeleteEpisodeTitle;

  /// No description provided for @adminPodcastsDeleteEpisodeContent.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{title}\"?'**
  String adminPodcastsDeleteEpisodeContent(String title);

  /// No description provided for @adminPodcastsDeleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get adminPodcastsDeleted;

  /// No description provided for @adminPodcastsFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get adminPodcastsFailed;

  /// No description provided for @adminPodcastsDeleteEpisodesTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Episodes?'**
  String get adminPodcastsDeleteEpisodesTitle;

  /// No description provided for @adminPodcastsDeleteEpisodesContent.
  ///
  /// In en, this message translates to:
  /// **'Delete {count} episode(s) from the server?'**
  String adminPodcastsDeleteEpisodesContent(int count);

  /// No description provided for @adminPodcastsDeletedEpisodes.
  ///
  /// In en, this message translates to:
  /// **'Deleted {count} episode(s)'**
  String adminPodcastsDeletedEpisodes(int count);

  /// No description provided for @adminPodcastsBrowseFeedToDownload.
  ///
  /// In en, this message translates to:
  /// **'Browse feed to download'**
  String get adminPodcastsBrowseFeedToDownload;

  /// No description provided for @adminPodcastsDownloadingDots.
  ///
  /// In en, this message translates to:
  /// **'Downloading...'**
  String get adminPodcastsDownloadingDots;

  /// No description provided for @adminPodcastsDeleteEpisodesCount.
  ///
  /// In en, this message translates to:
  /// **'Delete {count} episode(s)'**
  String adminPodcastsDeleteEpisodesCount(int count);

  /// No description provided for @adminPodcastsDownloadingCount.
  ///
  /// In en, this message translates to:
  /// **'Downloading {count} episode(s)'**
  String adminPodcastsDownloadingCount(int count);

  /// No description provided for @adminPodcastsDownloadEpisodesCount.
  ///
  /// In en, this message translates to:
  /// **'Download {count} episode(s)'**
  String adminPodcastsDownloadEpisodesCount(int count);

  /// No description provided for @adminPodcastsLookForEpisodesAfter.
  ///
  /// In en, this message translates to:
  /// **'Look for episodes after'**
  String get adminPodcastsLookForEpisodesAfter;

  /// No description provided for @adminPodcastsSelectDate.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get adminPodcastsSelectDate;

  /// No description provided for @adminPodcastsMaxEpisodes.
  ///
  /// In en, this message translates to:
  /// **'Max episodes to download'**
  String get adminPodcastsMaxEpisodes;

  /// No description provided for @adminPodcastsNoNewEpisodesAfter.
  ///
  /// In en, this message translates to:
  /// **'No new episodes found after {date}'**
  String adminPodcastsNoNewEpisodesAfter(String date);

  /// No description provided for @adminPodcastsFoundNewEpisodes.
  ///
  /// In en, this message translates to:
  /// **'Found {count} new episode(s) - downloading'**
  String adminPodcastsFoundNewEpisodes(int count);

  /// No description provided for @adminPodcastsFailedToCheckNew.
  ///
  /// In en, this message translates to:
  /// **'Failed to check for new episodes'**
  String get adminPodcastsFailedToCheckNew;

  /// No description provided for @adminPodcastsCheckAndDownload.
  ///
  /// In en, this message translates to:
  /// **'Check & Download'**
  String get adminPodcastsCheckAndDownload;

  /// No description provided for @adminPodcastsMatchPodcast.
  ///
  /// In en, this message translates to:
  /// **'Match Podcast'**
  String get adminPodcastsMatchPodcast;

  /// No description provided for @adminPodcastsMatchPodcastSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Search iTunes to update cover and metadata'**
  String get adminPodcastsMatchPodcastSubtitle;

  /// No description provided for @adminPodcastsAutoDownloadNewEpisodes.
  ///
  /// In en, this message translates to:
  /// **'Auto-Download New Episodes'**
  String get adminPodcastsAutoDownloadNewEpisodes;

  /// No description provided for @adminPodcastsAutoDownloadOnSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Server downloads new episodes automatically'**
  String get adminPodcastsAutoDownloadOnSubtitle;

  /// No description provided for @adminPodcastsAutoDownloadOffSubtitle.
  ///
  /// In en, this message translates to:
  /// **'New episodes are not auto-downloaded'**
  String get adminPodcastsAutoDownloadOffSubtitle;

  /// No description provided for @adminPodcastsFailedAutoDownloadUpdate.
  ///
  /// In en, this message translates to:
  /// **'Failed to update auto-download setting'**
  String get adminPodcastsFailedAutoDownloadUpdate;

  /// No description provided for @adminPodcastsCheckSchedule.
  ///
  /// In en, this message translates to:
  /// **'Check Schedule'**
  String get adminPodcastsCheckSchedule;

  /// No description provided for @adminPodcastsFrequency.
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get adminPodcastsFrequency;

  /// No description provided for @adminPodcastsFreqHourly.
  ///
  /// In en, this message translates to:
  /// **'Hourly'**
  String get adminPodcastsFreqHourly;

  /// No description provided for @adminPodcastsFreqDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get adminPodcastsFreqDaily;

  /// No description provided for @adminPodcastsFreqWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get adminPodcastsFreqWeekly;

  /// No description provided for @adminPodcastsDay.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get adminPodcastsDay;

  /// No description provided for @adminPodcastsTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get adminPodcastsTime;

  /// No description provided for @adminPodcastsDaySun.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get adminPodcastsDaySun;

  /// No description provided for @adminPodcastsDayMon.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get adminPodcastsDayMon;

  /// No description provided for @adminPodcastsDayTue.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get adminPodcastsDayTue;

  /// No description provided for @adminPodcastsDayWed.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get adminPodcastsDayWed;

  /// No description provided for @adminPodcastsDayThu.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get adminPodcastsDayThu;

  /// No description provided for @adminPodcastsDayFri.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get adminPodcastsDayFri;

  /// No description provided for @adminPodcastsDaySat.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get adminPodcastsDaySat;

  /// No description provided for @adminPodcastsFeedUrl.
  ///
  /// In en, this message translates to:
  /// **'Feed URL'**
  String get adminPodcastsFeedUrl;

  /// No description provided for @adminPodcastsBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get adminPodcastsBack;

  /// No description provided for @adminPodcastsRootOnly.
  ///
  /// In en, this message translates to:
  /// **'Root Only'**
  String get adminPodcastsRootOnly;

  /// No description provided for @adminPodcastsDeleting.
  ///
  /// In en, this message translates to:
  /// **'Deleting...'**
  String get adminPodcastsDeleting;

  /// No description provided for @adminPodcastsDeleteEpisode.
  ///
  /// In en, this message translates to:
  /// **'Delete Episode'**
  String get adminPodcastsDeleteEpisode;

  /// No description provided for @adminPodcastsSeasonChip.
  ///
  /// In en, this message translates to:
  /// **'Season {season}'**
  String adminPodcastsSeasonChip(String season);

  /// No description provided for @adminPodcastsEpChip.
  ///
  /// In en, this message translates to:
  /// **'Ep. {number}'**
  String adminPodcastsEpChip(String number);

  /// No description provided for @adminPodcastsApplyingMatch.
  ///
  /// In en, this message translates to:
  /// **'Applying match...'**
  String get adminPodcastsApplyingMatch;

  /// No description provided for @adminPodcastsNoResults.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get adminPodcastsNoResults;

  /// No description provided for @adminPodcastsPodcastMatched.
  ///
  /// In en, this message translates to:
  /// **'Podcast matched and updated'**
  String get adminPodcastsPodcastMatched;

  /// No description provided for @adminPodcastsFailedMatch.
  ///
  /// In en, this message translates to:
  /// **'Failed to match podcast'**
  String get adminPodcastsFailedMatch;

  /// No description provided for @episodeListEpisodeFallback.
  ///
  /// In en, this message translates to:
  /// **'Episode'**
  String get episodeListEpisodeFallback;

  /// No description provided for @episodeListUnknownPodcast.
  ///
  /// In en, this message translates to:
  /// **'Unknown Podcast'**
  String get episodeListUnknownPodcast;

  /// No description provided for @episodeListMarkedFinished.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 episode marked as finished} other{{count} episodes marked as finished}}'**
  String episodeListMarkedFinished(int count);

  /// No description provided for @episodeListMarkedUnfinished.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 episode marked as unfinished} other{{count} episodes marked as unfinished}}'**
  String episodeListMarkedUnfinished(int count);

  /// No description provided for @episodeListUnsubscribeFromNewEpisodes.
  ///
  /// In en, this message translates to:
  /// **'Unsubscribe from New Episodes'**
  String get episodeListUnsubscribeFromNewEpisodes;

  /// No description provided for @episodeListSubscribeToNewEpisodes.
  ///
  /// In en, this message translates to:
  /// **'Subscribe to New Episodes'**
  String get episodeListSubscribeToNewEpisodes;

  /// No description provided for @episodeListSubscribeTitle.
  ///
  /// In en, this message translates to:
  /// **'Subscribe to this podcast?'**
  String get episodeListSubscribeTitle;

  /// No description provided for @episodeListSubscribeContent.
  ///
  /// In en, this message translates to:
  /// **'New episodes will be automatically downloaded and added to your absorbing queue when they appear on the server.'**
  String get episodeListSubscribeContent;

  /// No description provided for @episodeListSubscribe.
  ///
  /// In en, this message translates to:
  /// **'Subscribe'**
  String get episodeListSubscribe;

  /// No description provided for @episodeListShowFinishedEpisodes.
  ///
  /// In en, this message translates to:
  /// **'Show Finished Episodes'**
  String get episodeListShowFinishedEpisodes;

  /// No description provided for @episodeListHideFinishedEpisodes.
  ///
  /// In en, this message translates to:
  /// **'Hide Finished Episodes'**
  String get episodeListHideFinishedEpisodes;

  /// No description provided for @episodeListPlaysNewerToOlder.
  ///
  /// In en, this message translates to:
  /// **'Plays newer to older episodes'**
  String get episodeListPlaysNewerToOlder;

  /// No description provided for @episodeListPlaysOlderToNewer.
  ///
  /// In en, this message translates to:
  /// **'Plays older to newer episodes'**
  String get episodeListPlaysOlderToNewer;

  /// No description provided for @episodeListEpisodeCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 episode} other{{count} episodes}}'**
  String episodeListEpisodeCount(int count);

  /// No description provided for @episodeListAutoDownloadChip.
  ///
  /// In en, this message translates to:
  /// **'Auto-Download'**
  String get episodeListAutoDownloadChip;

  /// No description provided for @episodeListSubscribedChip.
  ///
  /// In en, this message translates to:
  /// **'Subscribed'**
  String get episodeListSubscribedChip;

  /// No description provided for @episodeListExplicitChip.
  ///
  /// In en, this message translates to:
  /// **'Explicit'**
  String get episodeListExplicitChip;

  /// No description provided for @episodeListSortNewest.
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get episodeListSortNewest;

  /// No description provided for @episodeListSortOldest.
  ///
  /// In en, this message translates to:
  /// **'Oldest'**
  String get episodeListSortOldest;

  /// No description provided for @episodeListAddedToAbsorbing.
  ///
  /// In en, this message translates to:
  /// **'Added \"{title}\" to Absorbing'**
  String episodeListAddedToAbsorbing(String title);

  /// No description provided for @episodeDetailEpisodeFallback.
  ///
  /// In en, this message translates to:
  /// **'Episode'**
  String get episodeDetailEpisodeFallback;

  /// No description provided for @episodeDetailMarkedNotFinished.
  ///
  /// In en, this message translates to:
  /// **'Marked as not finished'**
  String get episodeDetailMarkedNotFinished;

  /// No description provided for @episodeDetailMarkedFinishedNice.
  ///
  /// In en, this message translates to:
  /// **'Marked as finished - nice!'**
  String get episodeDetailMarkedFinishedNice;

  /// No description provided for @episodeDetailMarkAbsorbedContent.
  ///
  /// In en, this message translates to:
  /// **'This will set your progress to 100% for this episode.'**
  String get episodeDetailMarkAbsorbedContent;

  /// No description provided for @episodeDetailResetProgressContent.
  ///
  /// In en, this message translates to:
  /// **'This will erase all progress for this episode and set it back to the beginning. This can\'t be undone.'**
  String get episodeDetailResetProgressContent;

  /// No description provided for @episodeDetailToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get episodeDetailToday;

  /// No description provided for @episodeDetailYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get episodeDetailYesterday;

  /// No description provided for @episodeDetailDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}d ago'**
  String episodeDetailDaysAgo(int count);

  /// No description provided for @episodeDetailWeeksAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}w ago'**
  String episodeDetailWeeksAgo(int count);

  /// No description provided for @episodeDetailDurationHm.
  ///
  /// In en, this message translates to:
  /// **'{hours}h {minutes}m'**
  String episodeDetailDurationHm(int hours, int minutes);

  /// No description provided for @episodeDetailDurationM.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m'**
  String episodeDetailDurationM(int minutes);

  /// No description provided for @episodeDetailResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get episodeDetailResume;

  /// No description provided for @episodeDetailPlayEpisode.
  ///
  /// In en, this message translates to:
  /// **'Play Episode'**
  String get episodeDetailPlayEpisode;

  /// No description provided for @episodeDetailEpisodeNumber.
  ///
  /// In en, this message translates to:
  /// **'Episode {number}'**
  String episodeDetailEpisodeNumber(String number);

  /// No description provided for @episodeDetailSeasonNumber.
  ///
  /// In en, this message translates to:
  /// **'Season {number}'**
  String episodeDetailSeasonNumber(String number);

  /// No description provided for @editMetadataUpdatedFromMatch.
  ///
  /// In en, this message translates to:
  /// **'Metadata updated from match'**
  String get editMetadataUpdatedFromMatch;

  /// No description provided for @editMetadataConfirmMatch.
  ///
  /// In en, this message translates to:
  /// **'This will update the server metadata for this book using:\n\n\"{title}\"\n\nAll fields and the cover will be overwritten on the server.'**
  String editMetadataConfirmMatch(String title);

  /// No description provided for @editMetadataConfirmMatchWithAuthor.
  ///
  /// In en, this message translates to:
  /// **'This will update the server metadata for this book using:\n\n\"{title}\" by {author}\n\nAll fields and the cover will be overwritten on the server.'**
  String editMetadataConfirmMatchWithAuthor(String title, String author);

  /// No description provided for @seriesBooksFindMissingTitle.
  ///
  /// In en, this message translates to:
  /// **'Find Missing Books'**
  String get seriesBooksFindMissingTitle;

  /// No description provided for @seriesBooksFindMissingContent.
  ///
  /// In en, this message translates to:
  /// **'This searches Audible to find books in this series that may be missing from your library.\n\nBooks are matched by ASIN first (depending on whether your server has ASINs for its books), then falls back to title matching. Results may not be perfectly accurate.'**
  String get seriesBooksFindMissingContent;

  /// No description provided for @seriesBooksCouldNotFindOnAudible.
  ///
  /// In en, this message translates to:
  /// **'Could not find this series on Audible'**
  String get seriesBooksCouldNotFindOnAudible;

  /// No description provided for @seriesBooksMarkAllNotFinishedContent.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{This will clear the finished status for the 1 book in this series.} other{This will clear the finished status for all {count} books in this series.}}'**
  String seriesBooksMarkAllNotFinishedContent(int count);

  /// No description provided for @seriesBooksFullyAbsorbContent.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{This will mark the 1 book in this series as finished.} other{This will mark all {count} books in this series as finished.}}'**
  String seriesBooksFullyAbsorbContent(int count);

  /// No description provided for @seriesBooksUnmarkAll.
  ///
  /// In en, this message translates to:
  /// **'Unmark All'**
  String get seriesBooksUnmarkAll;

  /// No description provided for @seriesBooksShowAllBooks.
  ///
  /// In en, this message translates to:
  /// **'Show all books'**
  String get seriesBooksShowAllBooks;

  /// No description provided for @seriesBooksGroupBySubSeries.
  ///
  /// In en, this message translates to:
  /// **'Group by sub-series'**
  String get seriesBooksGroupBySubSeries;

  /// No description provided for @seriesBooksLoadingSubSeries.
  ///
  /// In en, this message translates to:
  /// **'Loading sub-series...'**
  String get seriesBooksLoadingSubSeries;

  /// No description provided for @seriesBooksBookCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 book} other{{count} books}}'**
  String seriesBooksBookCount(int count);

  /// No description provided for @seriesBooksDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get seriesBooksDone;

  /// No description provided for @seriesBooksExplicitBadge.
  ///
  /// In en, this message translates to:
  /// **'E'**
  String get seriesBooksExplicitBadge;

  /// No description provided for @expandedCardStreaming.
  ///
  /// In en, this message translates to:
  /// **'Streaming'**
  String get expandedCardStreaming;

  /// No description provided for @expandedCardDeviceFallback.
  ///
  /// In en, this message translates to:
  /// **'Device'**
  String get expandedCardDeviceFallback;

  /// No description provided for @bookmarksScreenPositionInBook.
  ///
  /// In en, this message translates to:
  /// **'{position} in {bookTitle}'**
  String bookmarksScreenPositionInBook(String position, String bookTitle);

  /// No description provided for @bookmarksScreenClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get bookmarksScreenClose;

  /// No description provided for @bookmarksScreenSortNewest.
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get bookmarksScreenSortNewest;

  /// No description provided for @bookmarksScreenSortPosition.
  ///
  /// In en, this message translates to:
  /// **'Position'**
  String get bookmarksScreenSortPosition;

  /// No description provided for @statsScreenStreakDays.
  ///
  /// In en, this message translates to:
  /// **'{count}d'**
  String statsScreenStreakDays(int count);

  /// No description provided for @statsScreenSessionCountOne.
  ///
  /// In en, this message translates to:
  /// **'{count} session'**
  String statsScreenSessionCountOne(int count);

  /// No description provided for @statsScreenSessionCountOther.
  ///
  /// In en, this message translates to:
  /// **'{count} sessions'**
  String statsScreenSessionCountOther(int count);

  /// No description provided for @statsScreenDayMon.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get statsScreenDayMon;

  /// No description provided for @statsScreenDayTue.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get statsScreenDayTue;

  /// No description provided for @statsScreenDayWed.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get statsScreenDayWed;

  /// No description provided for @statsScreenDayThu.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get statsScreenDayThu;

  /// No description provided for @statsScreenDayFri.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get statsScreenDayFri;

  /// No description provided for @statsScreenDaySat.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get statsScreenDaySat;

  /// No description provided for @statsScreenDaySun.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get statsScreenDaySun;

  /// No description provided for @statsScreenDurationHm.
  ///
  /// In en, this message translates to:
  /// **'{h}h {m}m'**
  String statsScreenDurationHm(int h, int m);

  /// No description provided for @statsScreenDurationM.
  ///
  /// In en, this message translates to:
  /// **'{m}m'**
  String statsScreenDurationM(int m);

  /// No description provided for @statsScreenDurationLessThanMin.
  ///
  /// In en, this message translates to:
  /// **'<1m'**
  String get statsScreenDurationLessThanMin;

  /// No description provided for @statsScreenDurationZero.
  ///
  /// In en, this message translates to:
  /// **'0m'**
  String get statsScreenDurationZero;

  /// No description provided for @statsScreenDurationShortH.
  ///
  /// In en, this message translates to:
  /// **'{h}h'**
  String statsScreenDurationShortH(int h);

  /// No description provided for @statsScreenDurationShortM.
  ///
  /// In en, this message translates to:
  /// **'{m}m'**
  String statsScreenDurationShortM(int m);

  /// No description provided for @statsScreenCouldNotLoadItem.
  ///
  /// In en, this message translates to:
  /// **'Could not load item'**
  String get statsScreenCouldNotLoadItem;

  /// No description provided for @statsScreenCouldNotFindEpisode.
  ///
  /// In en, this message translates to:
  /// **'Could not find episode'**
  String get statsScreenCouldNotFindEpisode;

  /// No description provided for @statsScreenByAuthor.
  ///
  /// In en, this message translates to:
  /// **'by {author}'**
  String statsScreenByAuthor(String author);

  /// No description provided for @statsScreenListened.
  ///
  /// In en, this message translates to:
  /// **'Listened'**
  String get statsScreenListened;

  /// No description provided for @statsScreenStartedAtPosition.
  ///
  /// In en, this message translates to:
  /// **'Started at position'**
  String get statsScreenStartedAtPosition;

  /// No description provided for @statsScreenEndedAtPosition.
  ///
  /// In en, this message translates to:
  /// **'Ended at position'**
  String get statsScreenEndedAtPosition;

  /// No description provided for @statsScreenTotalDuration.
  ///
  /// In en, this message translates to:
  /// **'Total duration'**
  String get statsScreenTotalDuration;

  /// No description provided for @statsScreenStarted.
  ///
  /// In en, this message translates to:
  /// **'Started'**
  String get statsScreenStarted;

  /// No description provided for @statsScreenUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get statsScreenUpdated;

  /// No description provided for @statsScreenClient.
  ///
  /// In en, this message translates to:
  /// **'Client'**
  String get statsScreenClient;

  /// No description provided for @statsScreenDevice.
  ///
  /// In en, this message translates to:
  /// **'Device'**
  String get statsScreenDevice;

  /// No description provided for @statsScreenOs.
  ///
  /// In en, this message translates to:
  /// **'OS'**
  String get statsScreenOs;

  /// No description provided for @statsScreenPlayMethod.
  ///
  /// In en, this message translates to:
  /// **'Play method'**
  String get statsScreenPlayMethod;

  /// No description provided for @statsScreenLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get statsScreenLoading;

  /// No description provided for @statsScreenJumpToSessionStart.
  ///
  /// In en, this message translates to:
  /// **'Jump to session start ({position})'**
  String statsScreenJumpToSessionStart(String position);

  /// No description provided for @statsScreenPlayMethodDirect.
  ///
  /// In en, this message translates to:
  /// **'Direct play'**
  String get statsScreenPlayMethodDirect;

  /// No description provided for @statsScreenPlayMethodDirectStream.
  ///
  /// In en, this message translates to:
  /// **'Direct stream'**
  String get statsScreenPlayMethodDirectStream;

  /// No description provided for @statsScreenPlayMethodTranscode.
  ///
  /// In en, this message translates to:
  /// **'Transcode'**
  String get statsScreenPlayMethodTranscode;

  /// No description provided for @statsScreenPlayMethodLocal.
  ///
  /// In en, this message translates to:
  /// **'Local'**
  String get statsScreenPlayMethodLocal;

  /// No description provided for @statsScreenAmLabel.
  ///
  /// In en, this message translates to:
  /// **'AM'**
  String get statsScreenAmLabel;

  /// No description provided for @statsScreenPmLabel.
  ///
  /// In en, this message translates to:
  /// **'PM'**
  String get statsScreenPmLabel;

  /// No description provided for @statsScreenDateAtTime.
  ///
  /// In en, this message translates to:
  /// **'{month} {day}, {year} at {hour}:{minute} {ampm}'**
  String statsScreenDateAtTime(
      String month, int day, int year, int hour, String minute, String ampm);

  /// No description provided for @statsScreenMonthJan.
  ///
  /// In en, this message translates to:
  /// **'Jan'**
  String get statsScreenMonthJan;

  /// No description provided for @statsScreenMonthFeb.
  ///
  /// In en, this message translates to:
  /// **'Feb'**
  String get statsScreenMonthFeb;

  /// No description provided for @statsScreenMonthMar.
  ///
  /// In en, this message translates to:
  /// **'Mar'**
  String get statsScreenMonthMar;

  /// No description provided for @statsScreenMonthApr.
  ///
  /// In en, this message translates to:
  /// **'Apr'**
  String get statsScreenMonthApr;

  /// No description provided for @statsScreenMonthMay.
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get statsScreenMonthMay;

  /// No description provided for @statsScreenMonthJun.
  ///
  /// In en, this message translates to:
  /// **'Jun'**
  String get statsScreenMonthJun;

  /// No description provided for @statsScreenMonthJul.
  ///
  /// In en, this message translates to:
  /// **'Jul'**
  String get statsScreenMonthJul;

  /// No description provided for @statsScreenMonthAug.
  ///
  /// In en, this message translates to:
  /// **'Aug'**
  String get statsScreenMonthAug;

  /// No description provided for @statsScreenMonthSep.
  ///
  /// In en, this message translates to:
  /// **'Sep'**
  String get statsScreenMonthSep;

  /// No description provided for @statsScreenMonthOct.
  ///
  /// In en, this message translates to:
  /// **'Oct'**
  String get statsScreenMonthOct;

  /// No description provided for @statsScreenMonthNov.
  ///
  /// In en, this message translates to:
  /// **'Nov'**
  String get statsScreenMonthNov;

  /// No description provided for @statsScreenMonthDec.
  ///
  /// In en, this message translates to:
  /// **'Dec'**
  String get statsScreenMonthDec;

  /// No description provided for @upcomingReleasesTitle.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Releases'**
  String get upcomingReleasesTitle;

  /// No description provided for @upcomingReleasesRescanTitle.
  ///
  /// In en, this message translates to:
  /// **'Rescan?'**
  String get upcomingReleasesRescanTitle;

  /// No description provided for @upcomingReleasesRescanContent.
  ///
  /// In en, this message translates to:
  /// **'These results are {days} days old. Release dates may have changed - would you like to rescan?'**
  String upcomingReleasesRescanContent(int days);

  /// No description provided for @upcomingReleasesNotNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get upcomingReleasesNotNow;

  /// No description provided for @upcomingReleasesRescan.
  ///
  /// In en, this message translates to:
  /// **'Rescan'**
  String get upcomingReleasesRescan;

  /// No description provided for @upcomingReleasesRescanReleaseDate.
  ///
  /// In en, this message translates to:
  /// **'Rescan Release Date'**
  String get upcomingReleasesRescanReleaseDate;

  /// No description provided for @upcomingReleasesRescanning.
  ///
  /// In en, this message translates to:
  /// **'Rescanning...'**
  String get upcomingReleasesRescanning;

  /// No description provided for @upcomingReleasesUpdatedWithDate.
  ///
  /// In en, this message translates to:
  /// **'Updated - {date}'**
  String upcomingReleasesUpdatedWithDate(String date);

  /// No description provided for @upcomingReleasesNoReleaseDateFound.
  ///
  /// In en, this message translates to:
  /// **'No release date found'**
  String get upcomingReleasesNoReleaseDateFound;

  /// No description provided for @upcomingReleasesRescanFailed.
  ///
  /// In en, this message translates to:
  /// **'Rescan failed'**
  String get upcomingReleasesRescanFailed;

  /// No description provided for @upcomingReleasesDateChip.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get upcomingReleasesDateChip;

  /// No description provided for @upcomingReleasesCheckingSeries.
  ///
  /// In en, this message translates to:
  /// **'Checking {name}... ({processed}/{total})'**
  String upcomingReleasesCheckingSeries(String name, int processed, int total);

  /// No description provided for @upcomingReleasesLoadingSeries.
  ///
  /// In en, this message translates to:
  /// **'Loading series...'**
  String get upcomingReleasesLoadingSeries;

  /// No description provided for @upcomingReleasesScannedToday.
  ///
  /// In en, this message translates to:
  /// **'(scanned today)'**
  String get upcomingReleasesScannedToday;

  /// No description provided for @upcomingReleasesScannedYesterday.
  ///
  /// In en, this message translates to:
  /// **'(scanned yesterday)'**
  String get upcomingReleasesScannedYesterday;

  /// No description provided for @upcomingReleasesScannedDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'(scanned {days} days ago)'**
  String upcomingReleasesScannedDaysAgo(int days);

  /// No description provided for @upcomingReleasesUpcomingCount.
  ///
  /// In en, this message translates to:
  /// **'{count} upcoming'**
  String upcomingReleasesUpcomingCount(int count);

  /// No description provided for @upcomingReleasesRecentCount.
  ///
  /// In en, this message translates to:
  /// **'{count} recent'**
  String upcomingReleasesRecentCount(int count);

  /// No description provided for @upcomingReleasesNoneFound.
  ///
  /// In en, this message translates to:
  /// **'No upcoming or recent releases found'**
  String get upcomingReleasesNoneFound;

  /// No description provided for @upcomingReleasesAcrossSeries.
  ///
  /// In en, this message translates to:
  /// **'{summary} across {count} series'**
  String upcomingReleasesAcrossSeries(String summary, int count);

  /// No description provided for @upcomingReleasesCheckedSeries.
  ///
  /// In en, this message translates to:
  /// **'Checked {count} series on Audible'**
  String upcomingReleasesCheckedSeries(int count);

  /// No description provided for @upcomingReleasesDateFormat.
  ///
  /// In en, this message translates to:
  /// **'{month} {day}, {year}'**
  String upcomingReleasesDateFormat(String month, int day, int year);

  /// No description provided for @upcomingReleasesSequenceLabel.
  ///
  /// In en, this message translates to:
  /// **'#{sequence}'**
  String upcomingReleasesSequenceLabel(String sequence);

  /// No description provided for @upcomingReleasesBadgeUpcoming.
  ///
  /// In en, this message translates to:
  /// **'UPCOMING'**
  String get upcomingReleasesBadgeUpcoming;

  /// No description provided for @upcomingReleasesBadgeAdded.
  ///
  /// In en, this message translates to:
  /// **'ADDED'**
  String get upcomingReleasesBadgeAdded;

  /// No description provided for @upcomingReleasesBadgeMissing.
  ///
  /// In en, this message translates to:
  /// **'MISSING'**
  String get upcomingReleasesBadgeMissing;

  /// No description provided for @homeScreenEpisodeFallback.
  ///
  /// In en, this message translates to:
  /// **'Episode'**
  String get homeScreenEpisodeFallback;

  /// No description provided for @libraryScreenUnknownTitle.
  ///
  /// In en, this message translates to:
  /// **'Unknown Title'**
  String get libraryScreenUnknownTitle;

  /// No description provided for @playlistDetailDefaultName.
  ///
  /// In en, this message translates to:
  /// **'Playlist'**
  String get playlistDetailDefaultName;

  /// No description provided for @playlistDetailItemCount.
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String playlistDetailItemCount(int count);

  /// No description provided for @playlistDetailUnfinished.
  ///
  /// In en, this message translates to:
  /// **'Unfinished'**
  String get playlistDetailUnfinished;

  /// No description provided for @playlistDetailRemoveFromPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Remove from playlist'**
  String get playlistDetailRemoveFromPlaylist;

  /// No description provided for @playlistDetailDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get playlistDetailDone;

  /// No description provided for @playlistDetailItemsMarkedFinished.
  ///
  /// In en, this message translates to:
  /// **'{count} items marked finished'**
  String playlistDetailItemsMarkedFinished(int count);

  /// No description provided for @playlistDetailItemsMarkedUnfinished.
  ///
  /// In en, this message translates to:
  /// **'{count} items marked unfinished'**
  String playlistDetailItemsMarkedUnfinished(int count);

  /// No description provided for @playlistDetailItemsRemoved.
  ///
  /// In en, this message translates to:
  /// **'{count} items removed'**
  String playlistDetailItemsRemoved(int count);

  /// No description provided for @playlistDetailAddedToAbsorbing.
  ///
  /// In en, this message translates to:
  /// **'Added \"{title}\" to Absorbing'**
  String playlistDetailAddedToAbsorbing(String title);

  /// No description provided for @collectionDetailDefaultName.
  ///
  /// In en, this message translates to:
  /// **'Collection'**
  String get collectionDetailDefaultName;

  /// No description provided for @collectionDetailBookCount.
  ///
  /// In en, this message translates to:
  /// **'{count} books'**
  String collectionDetailBookCount(int count);

  /// No description provided for @collectionDetailDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get collectionDetailDone;

  /// No description provided for @collectionDetailAddedToAbsorbing.
  ///
  /// In en, this message translates to:
  /// **'Added \"{title}\" to Absorbing'**
  String collectionDetailAddedToAbsorbing(String title);

  /// No description provided for @audibleSeriesNoBooksFound.
  ///
  /// In en, this message translates to:
  /// **'No books found on Audible'**
  String get audibleSeriesNoBooksFound;

  /// No description provided for @audibleSeriesFailedToLoad.
  ///
  /// In en, this message translates to:
  /// **'Failed to load series from Audible'**
  String get audibleSeriesFailedToLoad;

  /// No description provided for @audibleSeriesSummary.
  ///
  /// In en, this message translates to:
  /// **'{total} on Audible · {missing} missing'**
  String audibleSeriesSummary(int total, int missing);

  /// No description provided for @audibleSeriesSummaryWithUpcoming.
  ///
  /// In en, this message translates to:
  /// **'{total} on Audible · {missing} missing · {upcoming} upcoming'**
  String audibleSeriesSummaryWithUpcoming(int total, int missing, int upcoming);

  /// No description provided for @audibleSeriesFilterMissing.
  ///
  /// In en, this message translates to:
  /// **'Missing ({count})'**
  String audibleSeriesFilterMissing(int count);

  /// No description provided for @audibleSeriesFilterUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming ({count})'**
  String audibleSeriesFilterUpcoming(int count);

  /// No description provided for @audibleSeriesFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All ({count})'**
  String audibleSeriesFilterAll(int count);

  /// No description provided for @audibleSeriesSearching.
  ///
  /// In en, this message translates to:
  /// **'Searching Audible...'**
  String get audibleSeriesSearching;

  /// No description provided for @audibleSeriesCompleteSeries.
  ///
  /// In en, this message translates to:
  /// **'You have the complete series!'**
  String get audibleSeriesCompleteSeries;

  /// No description provided for @audibleSeriesNoUpcoming.
  ///
  /// In en, this message translates to:
  /// **'No upcoming releases found'**
  String get audibleSeriesNoUpcoming;

  /// No description provided for @audibleSeriesUpcomingBadge.
  ///
  /// In en, this message translates to:
  /// **'UPCOMING'**
  String get audibleSeriesUpcomingBadge;

  /// No description provided for @audibleSeriesAbridged.
  ///
  /// In en, this message translates to:
  /// **'Abridged'**
  String get audibleSeriesAbridged;

  /// No description provided for @audibleSeriesRegionTitle.
  ///
  /// In en, this message translates to:
  /// **'Audible Region'**
  String get audibleSeriesRegionTitle;

  /// No description provided for @audibleSeriesOpenOnAudible.
  ///
  /// In en, this message translates to:
  /// **'Open on Audible'**
  String get audibleSeriesOpenOnAudible;

  /// No description provided for @audibleSeriesAddToCalendar.
  ///
  /// In en, this message translates to:
  /// **'Add to Calendar'**
  String get audibleSeriesAddToCalendar;

  /// No description provided for @audibleSeriesCouldNotOpenAudible.
  ///
  /// In en, this message translates to:
  /// **'Could not open Audible'**
  String get audibleSeriesCouldNotOpenAudible;

  /// No description provided for @audibleSeriesCouldNotOpenCalendar.
  ///
  /// In en, this message translates to:
  /// **'Could not open calendar'**
  String get audibleSeriesCouldNotOpenCalendar;

  /// No description provided for @audibleSeriesCalendarDescription.
  ///
  /// In en, this message translates to:
  /// **'New audiobook release in the {seriesName} series'**
  String audibleSeriesCalendarDescription(String seriesName);

  /// No description provided for @authorBooksGroupBySeries.
  ///
  /// In en, this message translates to:
  /// **'Group by series'**
  String get authorBooksGroupBySeries;

  /// No description provided for @authorBooksList.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get authorBooksList;

  /// No description provided for @authorBooksGrid.
  ///
  /// In en, this message translates to:
  /// **'Grid'**
  String get authorBooksGrid;

  /// No description provided for @authorBooksBookCount.
  ///
  /// In en, this message translates to:
  /// **'{count} books'**
  String authorBooksBookCount(int count);

  /// No description provided for @metadataLookupCover.
  ///
  /// In en, this message translates to:
  /// **'Cover'**
  String get metadataLookupCover;

  /// No description provided for @metadataLookupChooseFields.
  ///
  /// In en, this message translates to:
  /// **'Choose Fields to Apply'**
  String get metadataLookupChooseFields;

  /// No description provided for @metadataLookupApplyFields.
  ///
  /// In en, this message translates to:
  /// **'Apply {count} fields'**
  String metadataLookupApplyFields(int count);

  /// No description provided for @metadataLookupFieldsSavedLocally.
  ///
  /// In en, this message translates to:
  /// **'{count} fields saved locally'**
  String metadataLookupFieldsSavedLocally(int count);

  /// No description provided for @metadataLookupOverrideLocalDisplay.
  ///
  /// In en, this message translates to:
  /// **'Override local display'**
  String get metadataLookupOverrideLocalDisplay;

  /// No description provided for @equalizerPresetFlat.
  ///
  /// In en, this message translates to:
  /// **'Flat'**
  String get equalizerPresetFlat;

  /// No description provided for @equalizerPresetVoiceBoost.
  ///
  /// In en, this message translates to:
  /// **'Voice Boost'**
  String get equalizerPresetVoiceBoost;

  /// No description provided for @equalizerPresetBassBoost.
  ///
  /// In en, this message translates to:
  /// **'Bass Boost'**
  String get equalizerPresetBassBoost;

  /// No description provided for @equalizerPresetTrebleBoost.
  ///
  /// In en, this message translates to:
  /// **'Treble Boost'**
  String get equalizerPresetTrebleBoost;

  /// No description provided for @equalizerPresetPodcast.
  ///
  /// In en, this message translates to:
  /// **'Podcast'**
  String get equalizerPresetPodcast;

  /// No description provided for @equalizerPresetAudiobook.
  ///
  /// In en, this message translates to:
  /// **'Audiobook'**
  String get equalizerPresetAudiobook;

  /// No description provided for @equalizerPresetReduceNoise.
  ///
  /// In en, this message translates to:
  /// **'Reduce Noise'**
  String get equalizerPresetReduceNoise;

  /// No description provided for @equalizerPresetLoudness.
  ///
  /// In en, this message translates to:
  /// **'Loudness'**
  String get equalizerPresetLoudness;

  /// No description provided for @equalizerEditingSavedNamed.
  ///
  /// In en, this message translates to:
  /// **'Editing saved EQ for \"{title}\"'**
  String equalizerEditingSavedNamed(String title);

  /// No description provided for @equalizerEditingSavedGeneric.
  ///
  /// In en, this message translates to:
  /// **'Editing saved EQ'**
  String get equalizerEditingSavedGeneric;

  /// No description provided for @equalizerPerBookEq.
  ///
  /// In en, this message translates to:
  /// **'Per-book EQ'**
  String get equalizerPerBookEq;

  /// No description provided for @notesDeleteNoteQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete note?'**
  String get notesDeleteNoteQuestion;

  /// No description provided for @notesDeleteNoteContent.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{title}\"?'**
  String notesDeleteNoteContent(String title);

  /// No description provided for @notesExport.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get notesExport;

  /// No description provided for @notesNewNote.
  ///
  /// In en, this message translates to:
  /// **'New note'**
  String get notesNewNote;

  /// No description provided for @librarySortFilterUpcomingReleases.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Releases'**
  String get librarySortFilterUpcomingReleases;

  /// No description provided for @librarySortFilterUpcomingReleasesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Scan Audible for new releases in your series'**
  String get librarySortFilterUpcomingReleasesSubtitle;

  /// No description provided for @sleepTimerSheetChaptersLeft.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 chapter left} other{{count} chapters left}}'**
  String sleepTimerSheetChaptersLeft(int count);

  /// No description provided for @sleepTimerSheetAddMinutesChip.
  ///
  /// In en, this message translates to:
  /// **'+{minutes}m'**
  String sleepTimerSheetAddMinutesChip(int minutes);

  /// No description provided for @sleepTimerSheetAddChaptersChip.
  ///
  /// In en, this message translates to:
  /// **'+{count} ch'**
  String sleepTimerSheetAddChaptersChip(int count);

  /// No description provided for @sleepTimerSheetMinShort.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m'**
  String sleepTimerSheetMinShort(int minutes);

  /// No description provided for @sleepTimerSheetSecondsShort.
  ///
  /// In en, this message translates to:
  /// **'{seconds}s'**
  String sleepTimerSheetSecondsShort(int seconds);

  /// No description provided for @sleepTimerSheetMinSecShort.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m {seconds}s'**
  String sleepTimerSheetMinSecShort(int minutes, int seconds);

  /// No description provided for @sleepTimerSheetChaptersValue.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 chapter} other{{count} chapters}}'**
  String sleepTimerSheetChaptersValue(int count);

  /// No description provided for @sleepTimerSheetChaptersChip.
  ///
  /// In en, this message translates to:
  /// **'{count} ch'**
  String sleepTimerSheetChaptersChip(int count);

  /// No description provided for @sleepTimerSheetStartChapterSleep.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Sleep after 1 chapter} other{Sleep after {count} chapters}}'**
  String sleepTimerSheetStartChapterSleep(int count);

  /// No description provided for @sleepTimerSheetRewindOnSleep.
  ///
  /// In en, this message translates to:
  /// **'Rewind on sleep'**
  String get sleepTimerSheetRewindOnSleep;

  /// No description provided for @sleepTimerSheetShake.
  ///
  /// In en, this message translates to:
  /// **'Shake'**
  String get sleepTimerSheetShake;

  /// No description provided for @sleepTimerSheetAddsMinutes.
  ///
  /// In en, this message translates to:
  /// **'Adds {minutes} min'**
  String sleepTimerSheetAddsMinutes(int minutes);

  /// No description provided for @sleepTimerSheetAddsOneChapter.
  ///
  /// In en, this message translates to:
  /// **'Adds 1 chapter'**
  String get sleepTimerSheetAddsOneChapter;

  /// No description provided for @sleepTimerSheetResetsToFull.
  ///
  /// In en, this message translates to:
  /// **'Resets to full duration'**
  String get sleepTimerSheetResetsToFull;

  /// No description provided for @collectionPickerCollectionFallback.
  ///
  /// In en, this message translates to:
  /// **'Collection'**
  String get collectionPickerCollectionFallback;

  /// No description provided for @collectionPickerNameWithCount.
  ///
  /// In en, this message translates to:
  /// **'{name} ({count})'**
  String collectionPickerNameWithCount(String name, int count);

  /// No description provided for @playlistPickerPlaylistFallback.
  ///
  /// In en, this message translates to:
  /// **'Playlist'**
  String get playlistPickerPlaylistFallback;

  /// No description provided for @playlistPickerNameWithCount.
  ///
  /// In en, this message translates to:
  /// **'{name} ({count})'**
  String playlistPickerNameWithCount(String name, int count);

  /// No description provided for @cardChaptersPlayFromChapterTitle.
  ///
  /// In en, this message translates to:
  /// **'Play from chapter?'**
  String get cardChaptersPlayFromChapterTitle;

  /// No description provided for @cardChaptersPlayFromChapterContent.
  ///
  /// In en, this message translates to:
  /// **'Start playing from \"{title}\"?'**
  String cardChaptersPlayFromChapterContent(String title);

  /// No description provided for @cardChaptersPlay.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get cardChaptersPlay;

  /// No description provided for @absorbingSharedToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get absorbingSharedToday;

  /// No description provided for @absorbingSharedYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get absorbingSharedYesterday;

  /// No description provided for @absorbingSharedMonday.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get absorbingSharedMonday;

  /// No description provided for @absorbingSharedTuesday.
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get absorbingSharedTuesday;

  /// No description provided for @absorbingSharedWednesday.
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get absorbingSharedWednesday;

  /// No description provided for @absorbingSharedThursday.
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get absorbingSharedThursday;

  /// No description provided for @absorbingSharedFriday.
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get absorbingSharedFriday;

  /// No description provided for @absorbingSharedSaturday.
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get absorbingSharedSaturday;

  /// No description provided for @absorbingSharedSunday.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get absorbingSharedSunday;

  /// No description provided for @absorbingSharedAm.
  ///
  /// In en, this message translates to:
  /// **'AM'**
  String get absorbingSharedAm;

  /// No description provided for @absorbingSharedPm.
  ///
  /// In en, this message translates to:
  /// **'PM'**
  String get absorbingSharedPm;

  /// No description provided for @sectionDetailAddedToAbsorbing.
  ///
  /// In en, this message translates to:
  /// **'Added \"{title}\" to Absorbing'**
  String sectionDetailAddedToAbsorbing(String title);

  /// No description provided for @sectionDetailDoneBadge.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get sectionDetailDoneBadge;

  /// No description provided for @homeCustomizeAddGenreTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Genre Section'**
  String get homeCustomizeAddGenreTitle;

  /// No description provided for @homeCustomizeAddGenreSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick a genre to show on your home screen'**
  String get homeCustomizeAddGenreSubtitle;

  /// No description provided for @homeSectionDoneBadge.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get homeSectionDoneBadge;

  /// No description provided for @tipsSheetQuickBookmarksTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick Bookmarks'**
  String get tipsSheetQuickBookmarksTitle;

  /// No description provided for @tipsSheetQuickBookmarksDesc.
  ///
  /// In en, this message translates to:
  /// **'Long-press the bookmark button on any card to instantly drop a bookmark at your current position without opening the bookmark sheet.'**
  String get tipsSheetQuickBookmarksDesc;

  /// No description provided for @tipsSheetEditBookmarksTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Bookmarks'**
  String get tipsSheetEditBookmarksTitle;

  /// No description provided for @tipsSheetEditBookmarksDesc.
  ///
  /// In en, this message translates to:
  /// **'Long-press any bookmark in the bookmark sheet to edit its title and add notes.'**
  String get tipsSheetEditBookmarksDesc;

  /// No description provided for @tipsSheetCoverPlayPauseTitle.
  ///
  /// In en, this message translates to:
  /// **'Cover Play/Pause'**
  String get tipsSheetCoverPlayPauseTitle;

  /// No description provided for @tipsSheetCoverPlayPauseDesc.
  ///
  /// In en, this message translates to:
  /// **'Tap the cover art on any card to play or pause. Toggle this in Settings under Absorbing Cards. A faint pause icon shows when playing so you know it\'s tappable.'**
  String get tipsSheetCoverPlayPauseDesc;

  /// No description provided for @tipsSheetFullScreenPlayerTitle.
  ///
  /// In en, this message translates to:
  /// **'Full Screen Player'**
  String get tipsSheetFullScreenPlayerTitle;

  /// No description provided for @tipsSheetFullScreenPlayerDesc.
  ///
  /// In en, this message translates to:
  /// **'Swipe up on any absorbing card to open the full screen player. Swipe down to dismiss it.'**
  String get tipsSheetFullScreenPlayerDesc;

  /// No description provided for @tipsSheetQuickAddAbsorbingTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick Add to Absorbing'**
  String get tipsSheetQuickAddAbsorbingTitle;

  /// No description provided for @tipsSheetQuickAddAbsorbingDesc.
  ///
  /// In en, this message translates to:
  /// **'Swipe right on any book in a list sheet (series, author, search results) to instantly add it to your absorbing queue.'**
  String get tipsSheetQuickAddAbsorbingDesc;

  /// No description provided for @tipsSheetShakeExtendSleepTitle.
  ///
  /// In en, this message translates to:
  /// **'Shake to Extend Sleep'**
  String get tipsSheetShakeExtendSleepTitle;

  /// No description provided for @tipsSheetShakeExtendSleepDesc.
  ///
  /// In en, this message translates to:
  /// **'If you have a sleep timer running and shake your phone, it\'ll add extra minutes. Configure the amount in Settings under Sleep Timer.'**
  String get tipsSheetShakeExtendSleepDesc;

  /// No description provided for @tipsSheetSeriesNavigationTitle.
  ///
  /// In en, this message translates to:
  /// **'Series Navigation'**
  String get tipsSheetSeriesNavigationTitle;

  /// No description provided for @tipsSheetSeriesNavigationDesc.
  ///
  /// In en, this message translates to:
  /// **'Tap the series name in any book\'s detail popup to see all books in the series, sorted in reading order with sequence badges on each cover.'**
  String get tipsSheetSeriesNavigationDesc;

  /// No description provided for @tipsSheetSwipeBetweenBooksTitle.
  ///
  /// In en, this message translates to:
  /// **'Swipe Between Books'**
  String get tipsSheetSwipeBetweenBooksTitle;

  /// No description provided for @tipsSheetSwipeBetweenBooksDesc.
  ///
  /// In en, this message translates to:
  /// **'On the Absorbing screen, swipe left and right to switch between your in-progress books. The dots at the top show which book you\'re viewing.'**
  String get tipsSheetSwipeBetweenBooksDesc;

  /// No description provided for @tipsSheetTapToSeekTitle.
  ///
  /// In en, this message translates to:
  /// **'Tap to Seek'**
  String get tipsSheetTapToSeekTitle;

  /// No description provided for @tipsSheetTapToSeekDesc.
  ///
  /// In en, this message translates to:
  /// **'Tap anywhere on the chapter or book progress bar to jump directly to that position. You can also drag the bars for fine-grained control.'**
  String get tipsSheetTapToSeekDesc;

  /// No description provided for @tipsSheetSpeedAdjustedTimeTitle.
  ///
  /// In en, this message translates to:
  /// **'Speed-Adjusted Time'**
  String get tipsSheetSpeedAdjustedTimeTitle;

  /// No description provided for @tipsSheetSpeedAdjustedTimeDesc.
  ///
  /// In en, this message translates to:
  /// **'Time remaining and chapter times automatically adjust based on your playback speed. Listening at 1.5x? The time shown reflects how long it\'ll actually take you.'**
  String get tipsSheetSpeedAdjustedTimeDesc;

  /// No description provided for @tipsSheetPlaybackHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Playback History'**
  String get tipsSheetPlaybackHistoryTitle;

  /// No description provided for @tipsSheetPlaybackHistoryDesc.
  ///
  /// In en, this message translates to:
  /// **'Tap the History button on any card to see a timeline of every play, pause, seek, and speed change. Tap any event to jump back to that position.'**
  String get tipsSheetPlaybackHistoryDesc;

  /// No description provided for @tipsSheetAutoRewindTitle.
  ///
  /// In en, this message translates to:
  /// **'Auto-Rewind'**
  String get tipsSheetAutoRewindTitle;

  /// No description provided for @tipsSheetAutoRewindDesc.
  ///
  /// In en, this message translates to:
  /// **'When you resume after a pause, Absorb automatically rewinds a few seconds so you don\'t lose your place. The rewind amount scales with how long you were away. Configure it in Settings.'**
  String get tipsSheetAutoRewindDesc;

  /// No description provided for @tipsSheetSeriesQueueModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Series Queue Mode'**
  String get tipsSheetSeriesQueueModeTitle;

  /// No description provided for @tipsSheetSeriesQueueModeDesc.
  ///
  /// In en, this message translates to:
  /// **'When you finish a book that\'s part of a series, Absorb can automatically play the next book. Set queue mode to \"Series\" in Settings.'**
  String get tipsSheetSeriesQueueModeDesc;

  /// No description provided for @tipsSheetOfflineModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Offline Mode'**
  String get tipsSheetOfflineModeTitle;

  /// No description provided for @tipsSheetOfflineModeDesc.
  ///
  /// In en, this message translates to:
  /// **'Tap the airplane button on the Absorbing screen to enter offline mode. This stops syncing, saves data, and only shows your downloaded books. Great for flights or low signal areas.'**
  String get tipsSheetOfflineModeDesc;

  /// No description provided for @tipsSheetStopPlaybackTitle.
  ///
  /// In en, this message translates to:
  /// **'Stop Playback'**
  String get tipsSheetStopPlaybackTitle;

  /// No description provided for @tipsSheetStopPlaybackDesc.
  ///
  /// In en, this message translates to:
  /// **'The Stop button in the Absorbing header ends your listening session and saves your progress. Your progress syncs automatically in the background.'**
  String get tipsSheetStopPlaybackDesc;

  /// No description provided for @tipsSheetDownloadOfflineTitle.
  ///
  /// In en, this message translates to:
  /// **'Download for Offline'**
  String get tipsSheetDownloadOfflineTitle;

  /// No description provided for @tipsSheetDownloadOfflineDesc.
  ///
  /// In en, this message translates to:
  /// **'Tap the download button in any book\'s detail popup to save it for offline listening. Downloaded books are available in offline mode without any internet connection.'**
  String get tipsSheetDownloadOfflineDesc;

  /// No description provided for @tipsSheetCustomizeHomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Customize Home'**
  String get tipsSheetCustomizeHomeTitle;

  /// No description provided for @tipsSheetCustomizeHomeDesc.
  ///
  /// In en, this message translates to:
  /// **'Tap the edit button in the top right of the Home screen to rearrange, hide, or show sections. Drag sections into your preferred order.'**
  String get tipsSheetCustomizeHomeDesc;

  /// No description provided for @tipsSheetPlaylistsTitle.
  ///
  /// In en, this message translates to:
  /// **'Playlists'**
  String get tipsSheetPlaylistsTitle;

  /// No description provided for @tipsSheetPlaylistsDesc.
  ///
  /// In en, this message translates to:
  /// **'Create and manage playlists on your Audiobookshelf server and they\'ll appear as sections on your Home screen. Add books to playlists from any book\'s detail popup.'**
  String get tipsSheetPlaylistsDesc;

  /// No description provided for @tipsSheetCollectionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Collections'**
  String get tipsSheetCollectionsTitle;

  /// No description provided for @tipsSheetCollectionsDesc.
  ///
  /// In en, this message translates to:
  /// **'Collections group related books together and show up as Home sections. Root admins can add books and edit collections from the detail popup.'**
  String get tipsSheetCollectionsDesc;

  /// No description provided for @bookCardUnknownTitle.
  ///
  /// In en, this message translates to:
  /// **'Unknown Title'**
  String get bookCardUnknownTitle;

  /// No description provided for @bookCardExplicitBadge.
  ///
  /// In en, this message translates to:
  /// **'E'**
  String get bookCardExplicitBadge;

  /// No description provided for @bookCardDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get bookCardDone;

  /// No description provided for @bookCardSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get bookCardSaved;

  /// No description provided for @episodeRowEpisode.
  ///
  /// In en, this message translates to:
  /// **'Episode'**
  String get episodeRowEpisode;

  /// No description provided for @episodeRowToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get episodeRowToday;

  /// No description provided for @episodeRowYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get episodeRowYesterday;

  /// No description provided for @episodeRowDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}d ago'**
  String episodeRowDaysAgo(int count);

  /// No description provided for @episodeRowWeeksAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}w ago'**
  String episodeRowWeeksAgo(int count);

  /// No description provided for @episodeRowDurationHm.
  ///
  /// In en, this message translates to:
  /// **'{hours}h {minutes}m'**
  String episodeRowDurationHm(int hours, int minutes);

  /// No description provided for @episodeRowDurationM.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m'**
  String episodeRowDurationM(int minutes);

  /// No description provided for @episodeRowSeasonShort.
  ///
  /// In en, this message translates to:
  /// **'S{number}'**
  String episodeRowSeasonShort(String number);

  /// No description provided for @episodeRowEpisodeShort.
  ///
  /// In en, this message translates to:
  /// **'E{number}'**
  String episodeRowEpisodeShort(String number);

  /// No description provided for @librarySearchResultsExplicitBadge.
  ///
  /// In en, this message translates to:
  /// **'E'**
  String get librarySearchResultsExplicitBadge;

  /// No description provided for @librarySearchResultsDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get librarySearchResultsDone;

  /// No description provided for @librarySearchResultsSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get librarySearchResultsSaved;

  /// No description provided for @librarySearchResultsSequence.
  ///
  /// In en, this message translates to:
  /// **'#{number}'**
  String librarySearchResultsSequence(String number);

  /// No description provided for @librarySearchResultsUnknownSeries.
  ///
  /// In en, this message translates to:
  /// **'Unknown Series'**
  String get librarySearchResultsUnknownSeries;

  /// No description provided for @librarySearchResultsUnknownEpisode.
  ///
  /// In en, this message translates to:
  /// **'Unknown Episode'**
  String get librarySearchResultsUnknownEpisode;

  /// No description provided for @librarySearchResultsBookCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 book} other{{count} books}}'**
  String librarySearchResultsBookCount(int count);

  /// No description provided for @libraryGridTilesExplicitBadge.
  ///
  /// In en, this message translates to:
  /// **'E'**
  String get libraryGridTilesExplicitBadge;

  /// No description provided for @libraryGridTilesDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get libraryGridTilesDone;

  /// No description provided for @libraryGridTilesSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get libraryGridTilesSaved;

  /// No description provided for @libraryGridTilesSequence.
  ///
  /// In en, this message translates to:
  /// **'#{number}'**
  String libraryGridTilesSequence(String number);

  /// No description provided for @libraryGridTilesUnknownSeries.
  ///
  /// In en, this message translates to:
  /// **'Unknown Series'**
  String get libraryGridTilesUnknownSeries;

  /// No description provided for @seriesCardUnknownSeries.
  ///
  /// In en, this message translates to:
  /// **'Unknown Series'**
  String get seriesCardUnknownSeries;

  /// No description provided for @seriesCardBookCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 book} other{{count} books}}'**
  String seriesCardBookCount(int count);

  /// No description provided for @cardProgressFineScrubbing.
  ///
  /// In en, this message translates to:
  /// **'Fine Scrubbing'**
  String get cardProgressFineScrubbing;

  /// No description provided for @cardProgressQuarterSpeed.
  ///
  /// In en, this message translates to:
  /// **'Quarter Speed'**
  String get cardProgressQuarterSpeed;

  /// No description provided for @cardProgressHalfSpeed.
  ///
  /// In en, this message translates to:
  /// **'Half Speed'**
  String get cardProgressHalfSpeed;

  /// No description provided for @cardProgressChapterPrefix.
  ///
  /// In en, this message translates to:
  /// **'Chapter {number}'**
  String cardProgressChapterPrefix(String number);

  /// No description provided for @cardEdgeProgressFineScrubbing.
  ///
  /// In en, this message translates to:
  /// **'Fine Scrubbing'**
  String get cardEdgeProgressFineScrubbing;

  /// No description provided for @cardEdgeProgressQuarterSpeed.
  ///
  /// In en, this message translates to:
  /// **'Quarter Speed'**
  String get cardEdgeProgressQuarterSpeed;

  /// No description provided for @cardEdgeProgressHalfSpeed.
  ///
  /// In en, this message translates to:
  /// **'Half Speed'**
  String get cardEdgeProgressHalfSpeed;

  /// No description provided for @authSessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Session expired. Please log in again.'**
  String get authSessionExpired;

  /// No description provided for @authCannotReachServer.
  ///
  /// In en, this message translates to:
  /// **'Cannot reach server at {url}'**
  String authCannotReachServer(String url);

  /// No description provided for @authInvalidUsernameOrPassword.
  ///
  /// In en, this message translates to:
  /// **'Invalid username or password'**
  String get authInvalidUsernameOrPassword;

  /// No description provided for @authLoginFailedDetail.
  ///
  /// In en, this message translates to:
  /// **'Login failed - check your server address and credentials'**
  String get authLoginFailedDetail;

  /// No description provided for @authUnexpectedServerResponse.
  ///
  /// In en, this message translates to:
  /// **'Unexpected server response'**
  String get authUnexpectedServerResponse;

  /// No description provided for @authSsoUnexpectedResponse.
  ///
  /// In en, this message translates to:
  /// **'SSO returned an unexpected response'**
  String get authSsoUnexpectedResponse;

  /// No description provided for @authSwitchedToLocalServer.
  ///
  /// In en, this message translates to:
  /// **'Switched to local server'**
  String get authSwitchedToLocalServer;

  /// No description provided for @authSwitchedToRemoteServer.
  ///
  /// In en, this message translates to:
  /// **'Switched to remote server'**
  String get authSwitchedToRemoteServer;

  /// No description provided for @lpDeletedFinishedDownload.
  ///
  /// In en, this message translates to:
  /// **'Deleted finished download'**
  String get lpDeletedFinishedDownload;

  /// No description provided for @lpSubscribedPodcastDownloading.
  ///
  /// In en, this message translates to:
  /// **'{showTitle}: {count, plural, =1{1 new episode downloading} other{{count} new episodes downloading}}'**
  String lpSubscribedPodcastDownloading(String showTitle, int count);

  /// No description provided for @lpQueueDownloadingItems.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Queue: downloading 1 item} other{Queue: downloading {count} items}}'**
  String lpQueueDownloadingItems(int count);

  /// No description provided for @lpDownloadingBooks.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Downloading 1 book} other{Downloading {count} books}}'**
  String lpDownloadingBooks(int count);

  /// No description provided for @lpDownloadingEpisodes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Downloading 1 episode} other{Downloading {count} episodes}}'**
  String lpDownloadingEpisodes(int count);

  /// No description provided for @downloadNotifProgressChannelName.
  ///
  /// In en, this message translates to:
  /// **'Download Progress'**
  String get downloadNotifProgressChannelName;

  /// No description provided for @downloadNotifProgressChannelDesc.
  ///
  /// In en, this message translates to:
  /// **'Shows progress during audiobook downloads'**
  String get downloadNotifProgressChannelDesc;

  /// No description provided for @downloadNotifAlertChannelName.
  ///
  /// In en, this message translates to:
  /// **'Download Alerts'**
  String get downloadNotifAlertChannelName;

  /// No description provided for @downloadNotifAlertChannelDesc.
  ///
  /// In en, this message translates to:
  /// **'Notifications when downloads finish or fail'**
  String get downloadNotifAlertChannelDesc;

  /// No description provided for @downloadNotifDownloadingTitle.
  ///
  /// In en, this message translates to:
  /// **'Downloading…'**
  String get downloadNotifDownloadingTitle;

  /// No description provided for @downloadNotifActiveCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 download active} other{{count} downloads active}}'**
  String downloadNotifActiveCount(int count);

  /// No description provided for @downloadNotifSlotTitle.
  ///
  /// In en, this message translates to:
  /// **'Downloading: {title}'**
  String downloadNotifSlotTitle(String title);

  /// No description provided for @downloadNotifStartingLabel.
  ///
  /// In en, this message translates to:
  /// **'Starting…'**
  String get downloadNotifStartingLabel;

  /// No description provided for @downloadNotifCompleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Download Complete'**
  String get downloadNotifCompleteTitle;

  /// No description provided for @downloadNotifCompleteBody.
  ///
  /// In en, this message translates to:
  /// **'{title} is ready to listen offline'**
  String downloadNotifCompleteBody(String title);

  /// No description provided for @downloadNotifFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Download Failed'**
  String get downloadNotifFailedTitle;

  /// No description provided for @upcomingNotifChannelName.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Release Scan'**
  String get upcomingNotifChannelName;

  /// No description provided for @upcomingNotifChannelDesc.
  ///
  /// In en, this message translates to:
  /// **'Shows progress while scanning for upcoming releases'**
  String get upcomingNotifChannelDesc;

  /// No description provided for @upcomingNotifScanTitle.
  ///
  /// In en, this message translates to:
  /// **'Scanning for upcoming releases'**
  String get upcomingNotifScanTitle;

  /// No description provided for @upcomingNotifStartingScan.
  ///
  /// In en, this message translates to:
  /// **'Starting scan…'**
  String get upcomingNotifStartingScan;

  /// No description provided for @upcomingNotifCheckingSeries.
  ///
  /// In en, this message translates to:
  /// **'Checking {seriesName}… ({current}/{total})'**
  String upcomingNotifCheckingSeries(String seriesName, int current, int total);

  /// No description provided for @upcomingNotifFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Upcoming releases found!'**
  String get upcomingNotifFoundTitle;

  /// No description provided for @upcomingNotifFoundBody.
  ///
  /// In en, this message translates to:
  /// **'{books} upcoming across {series, plural, =1{1 series} other{{series} series}}'**
  String upcomingNotifFoundBody(int books, int series);

  /// No description provided for @androidAutoTabContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get androidAutoTabContinue;

  /// No description provided for @androidAutoTabLibrary.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get androidAutoTabLibrary;

  /// No description provided for @androidAutoTabDownloads.
  ///
  /// In en, this message translates to:
  /// **'Downloads'**
  String get androidAutoTabDownloads;

  /// No description provided for @androidAutoCatBooks.
  ///
  /// In en, this message translates to:
  /// **'Books'**
  String get androidAutoCatBooks;

  /// No description provided for @androidAutoCatSeries.
  ///
  /// In en, this message translates to:
  /// **'Series'**
  String get androidAutoCatSeries;

  /// No description provided for @androidAutoCatAuthors.
  ///
  /// In en, this message translates to:
  /// **'Authors'**
  String get androidAutoCatAuthors;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
