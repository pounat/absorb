import 'dart:async';
import 'dart:io';
import 'dart:ui';
// Flutter 3.44 moved CupertinoPageTransitionsBuilder from material.dart to
// cupertino.dart. Older SDKs (incl. local) still re-export it from material,
// so the lint flags this as unnecessary, but Codemagic's stable channel
// needs the explicit cupertino import to compile.
// ignore: unnecessary_import
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:app_links/app_links.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'l10n/app_localizations.dart';

import 'package:device_info_plus/device_info_plus.dart';

import 'providers/auth_provider.dart';
import 'providers/library_provider.dart';
import 'services/audio_player_service.dart';
import 'services/api_service.dart';
import 'services/download_service.dart';
import 'services/progress_sync_service.dart';
import 'services/local_session_service.dart';
import 'services/equalizer_service.dart';
import 'services/sleep_timer_service.dart';
import 'services/scoped_prefs.dart';
import 'services/user_account_service.dart';
import 'services/android_auto_service.dart';
import 'services/carplay_service.dart';
import 'services/chromecast_service.dart';
import 'services/episode_notification_service.dart';
import 'services/home_widget_service.dart';
import 'services/log_service.dart';
import 'services/quick_actions_service.dart';
import 'services/setup_link_service.dart';
import 'services/wording.dart';
import 'screens/login_screen.dart';
import 'screens/app_shell.dart';
import 'widgets/absorb_wave_icon.dart';
import 'widgets/setup_link_login.dart';

/// Global notifier so any widget (e.g. settings) can change the theme instantly.
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);

/// Whether the flat (no-gradient) background is active. In dark mode this also
/// switches surfaces to pure black (OLED); in light mode to clean flat white.
final ValueNotifier<bool> flatNotifier = ValueNotifier(false);

/// App color source: 'dynamic' tints the app to the playing book cover,
/// 'manual' pins it to [manualSeedNotifier].
final ValueNotifier<String> colorSourceNotifier = ValueNotifier('dynamic');

/// Fixed seed color used when [colorSourceNotifier] is 'manual'.
final ValueNotifier<Color> manualSeedNotifier = ValueNotifier(const Color(0xFF7C6FBF));

/// Top alpha of the primary-tinted background gradient (0 = flat). Read by
/// screens that paint the gradient so the intensity slider applies everywhere.
final ValueNotifier<double> gradientIntensityNotifier = ValueNotifier(0.06);

/// When true (and color source is manual), the fixed app color is also used on
/// per-book surfaces (detail sheets, the absorbing card background) instead of
/// each book's own cover color.
final ValueNotifier<bool> useColorEverywhereNotifier = ValueNotifier(false);

/// Builds a ColorScheme whose primary accent is exactly [seed] rather than the
/// lighter, desaturated tone Material's seed mapping would pick (which turns a
/// chosen red into pink). Used for the manual app color so swatches read true.
ColorScheme manualColorScheme(Color seed, Brightness brightness) {
  final base = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: brightness,
    dynamicSchemeVariant: DynamicSchemeVariant.vibrant,
  );
  final onSeed = ThemeData.estimateBrightnessForColor(seed) == Brightness.dark
      ? Colors.white
      : Colors.black;
  return base.copyWith(primary: seed, onPrimary: onSeed);
}
/// Whether to disable the fade animation when switching bottom nav tabs.
final ValueNotifier<bool> snappyTransitionsNotifier = ValueNotifier(false);

/// User-selected language override. null means follow the system language.
final ValueNotifier<Locale?> localeNotifier = ValueNotifier(null);


/// Cover-art-derived ColorScheme for the currently playing item.
/// null when nothing is playing or cover hasn't loaded yet.
final ValueNotifier<ColorScheme?> coverSchemeNotifier = ValueNotifier(null);

/// Whether to trust all certificates (for self-signed / custom CA setups).
/// Checked dynamically by [_CertOverrides] when any HttpClient is created.
bool trustAllCerts = false;

/// Allows Dart's HTTP stack to trust user-installed / self-signed certificates.
/// Android's network_security_config.xml only covers the native layer; Dart's
/// BoringSSL ignores it, so we override badCertificateCallback globally.
/// Installed once at startup; checks [trustAllCerts] at HttpClient creation time
/// so that CachedNetworkImage / flutter_cache_manager pick up the setting.
class _CertOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    // Always install the callback so it works even for HttpClient instances
    // created before trustAllCerts is loaded from SharedPreferences.
    // flutter_cache_manager (CachedNetworkImage) caches its HttpClient, so
    // checking the flag at validation time (not creation time) is essential.
    client.badCertificateCallback = (_, __, ___) => trustAllCerts;
    return client;
  }
}

/// Enable or disable the global trust-all-certs override.
void applyTrustAllCerts(bool enabled) {
  trustAllCerts = enabled;
}

/// Global navigator key so non-widget code (e.g. app-icon shortcut handlers)
/// can push routes without needing a BuildContext.
final GlobalKey<NavigatorState> rootNavigatorKey =
    GlobalKey<NavigatorState>();

ThemeMode parseThemeMode(String value) {
  switch (value) {
    case 'light': return ThemeMode.light;
    case 'system': return ThemeMode.system;
    case 'oled': return ThemeMode.dark;
    default: return ThemeMode.dark;
  }
}

void applyThemeMode(String value) {
  themeNotifier.value = parseThemeMode(value);
  // Legacy 'oled' is now expressed as dark + flat background.
  if (value == 'oled') flatNotifier.value = true;
}

void applyFlatBackground(bool value) => flatNotifier.value = value;
void applyColorSource(String value) => colorSourceNotifier.value = value;
void applyManualSeed(int argb) => manualSeedNotifier.value = Color(argb);
void applyGradientIntensity(double value) => gradientIntensityNotifier.value = value;
void applyUseColorEverywhere(bool value) => useColorEverywhereNotifier.value = value;

/// Apply the saved rotation preference. When "lock portrait" is on the app is
/// pinned to portrait; otherwise all orientations are allowed (the default).
/// Safe to call any time the setting changes.
Future<void> applyOrientationLock() async {
  final lock = await PlayerSettings.getLockPortrait();
  await SystemChrome.setPreferredOrientations(lock
      ? const [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]
      : const [
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
}

void main() async {
  HttpOverrides.global = _CertOverrides();
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  final appLinks = AppLinks();

  // These calls use platform channels that require an Activity. When Android
  // Auto cold-starts the app for the MediaBrowserService, no Activity exists
  // and these calls can hang forever - blocking runApp() and freezing on the
  // splash screen. Wrap in try-catch with a timeout so we always reach runApp().
  try {
    FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  } catch (_) {}

  try {
    await applyOrientationLock().timeout(const Duration(seconds: 2));
  } catch (_) {}

  // Load saved theme preference so we render the correct theme immediately
  try {
    var savedTheme = await PlayerSettings.getThemeMode();
    // Migrate legacy OLED mode to dark + flat background.
    if (savedTheme == 'oled') {
      await PlayerSettings.setThemeMode('dark');
      await PlayerSettings.setFlatBackground(true);
      savedTheme = 'dark';
    }
    applyThemeMode(savedTheme);
    flatNotifier.value = await PlayerSettings.getFlatBackground();
    colorSourceNotifier.value = await PlayerSettings.getColorSource();
    manualSeedNotifier.value = Color(await PlayerSettings.getManualSeedColor());
    gradientIntensityNotifier.value = await PlayerSettings.getGradientIntensity();
    useColorEverywhereNotifier.value = await PlayerSettings.getUseColorEverywhere();
    final savedLang = await PlayerSettings.getLanguage();
    if (savedLang.isNotEmpty) localeNotifier.value = Locale(savedLang);
    snappyTransitionsNotifier.value = await PlayerSettings.getSnappyTransitions();
    classicWordingNotifier.value = await PlayerSettings.getClassicWording();
    PlayerSettings.showExplicitBadge = await PlayerSettings.getShowExplicitBadge();
    PlayerSettings.mp3IndexSeeking = await PlayerSettings.getMp3IndexSeeking();
    // Restore last cover seed color so the theme doesn't flash on startup
    {
      final seedInt = await PlayerSettings.getCoverSeedColor();
      if (seedInt != null) {
        final seedColor = Color(seedInt);
        coverSchemeNotifier.value = ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: parseThemeMode(await PlayerSettings.getThemeMode()) == ThemeMode.light
              ? Brightness.light : Brightness.dark,
        );
      }
    }
  } catch (_) {}

  // Trust user-installed / self-signed certificates if the user opted in
  try {
    trustAllCerts = await PlayerSettings.getTrustAllCerts();
  } catch (_) {}

  // Capture Flutter framework errors (widget build failures, etc.)
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    LogService().log('[CRASH] FlutterError: ${details.exceptionAsString()}\n${details.stack}');
  };

  // Capture unhandled Dart exceptions (async errors, null dereferences, etc.)
  PlatformDispatcher.instance.onError = (error, stack) {
    LogService().log('[CRASH] Unhandled: $error\n$stack');
    return true;
  };

  // Remove native splash — Flutter will render the AuthGate splash immediately
  try {
    FlutterNativeSplash.remove();
  } catch (_) {}

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, LibraryProvider>(
          create: (_) => LibraryProvider(),
          update: (_, auth, lib) => lib!..updateAuth(auth),
        ),
      ],
      child: AbsorbApp(setupLinkStream: appLinks.uriLinkStream),
    ),
  );
}

class AbsorbApp extends StatelessWidget {
  final Stream<Uri>? setupLinkStream;

  const AbsorbApp({super.key, this.setupLinkStream});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        themeNotifier,
        flatNotifier,
        localeNotifier,
        coverSchemeNotifier,
        classicWordingNotifier,
        colorSourceNotifier,
        manualSeedNotifier,
        gradientIntensityNotifier,
        useColorEverywhereNotifier,
      ]),
      builder: (context, _) {
        final currentMode = themeNotifier.value;
        final isFlat = flatNotifier.value;
        final overrideLocale = localeNotifier.value;
        // Japanese shares many codepoints with Chinese (Han unification) but
        // draws some kanji differently. Flutter on Android doesn't hint the
        // text engine per locale, so it falls back to Chinese glyph shapes.
        // When the app is running in Japanese, prepend a bundled Japanese font
        // so kanji render with the right shapes. Other languages are untouched.
        final isJapanese =
            (overrideLocale ?? WidgetsBinding.instance.platformDispatcher.locale)
                .languageCode == 'ja';
        final cjkFallback = isJapanese ? const ['NotoSansJP'] : null;
        final coverScheme = coverSchemeNotifier.value;
        final isManual = colorSourceNotifier.value == 'manual';

        // Set system chrome to match active theme
        final isDark = currentMode == ThemeMode.dark ||
            (currentMode == ThemeMode.system &&
                WidgetsBinding.instance.platformDispatcher.platformBrightness ==
                    Brightness.dark);
        SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          systemNavigationBarColor: isDark
              ? Colors.black
              : (isFlat ? Colors.white : const Color(0xFFF5F5F5)),
          systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        ));

        const defaultSeed = Color(0xFF7C6FBF); // deep muted purple
        final seedColor = isManual
            ? manualSeedNotifier.value
            : (coverScheme?.primary ?? defaultSeed);

        // Manual presets use the vibrant variant so the app color closely
        // matches the chosen swatch. Flat mode also goes vibrant: with the
        // gradient glow gone, the accent color is the only place color shows,
        // so it needs to pop. Dynamic + non-flat keeps the softer default.
        final variant = (isManual || isFlat)
            ? DynamicSchemeVariant.vibrant
            : DynamicSchemeVariant.tonalSpot;

        ColorScheme darkScheme = isManual
            ? manualColorScheme(seedColor, Brightness.dark)
            : ColorScheme.fromSeed(
                seedColor: seedColor,
                brightness: Brightness.dark,
                dynamicSchemeVariant: variant,
              );

        // Keep dark surfaces neutral so cards/sheets match the scaffold and
        // app bars; the seed color shows through the gradient glow and accents,
        // not tinted surfaces (tinted dark surfaces read as muddy/mismatched).
        // Flat goes pure black so OLED pixels turn fully off.
        darkScheme = darkScheme.copyWith(
          surface: isFlat ? Colors.black : const Color(0xFF0E0E0E),
          surfaceContainerLowest: isFlat ? Colors.black : const Color(0xFF0A0A0A),
          surfaceContainerLow: isFlat ? Colors.black : const Color(0xFF141414),
          surfaceContainer: isFlat ? const Color(0xFF050505) : const Color(0xFF181818),
          surfaceContainerHigh: isFlat ? const Color(0xFF0A0A0A) : const Color(0xFF1E1E1E),
          surfaceContainerHighest: isFlat ? const Color(0xFF0F0F0F) : const Color(0xFF242424),
        );

        ColorScheme lightScheme = isManual
            ? manualColorScheme(seedColor, Brightness.light)
            : ColorScheme.fromSeed(
                seedColor: seedColor,
                brightness: Brightness.light,
                dynamicSchemeVariant: variant,
              );

        // Same idea in light: neutral surfaces, color from the glow + accents.
        // Flat goes clean white.
        lightScheme = lightScheme.copyWith(
          surface: isFlat ? Colors.white : const Color(0xFFF6F6F6),
          surfaceContainerLowest: Colors.white,
          surfaceContainerLow: isFlat ? Colors.white : const Color(0xFFF1F1F1),
          surfaceContainer: isFlat ? const Color(0xFFF7F7F7) : const Color(0xFFECECEC),
          surfaceContainerHigh: isFlat ? const Color(0xFFF2F2F2) : const Color(0xFFE6E6E6),
          surfaceContainerHighest: isFlat ? const Color(0xFFEDEDED) : const Color(0xFFE0E0E0),
        );

            const pageTransition = PageTransitionsTheme(
              builders: {
                TargetPlatform.android: CupertinoPageTransitionsBuilder(),
                TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
              },
            );

            return MaterialApp(
              navigatorKey: rootNavigatorKey,
              title: 'Absorb',
              debugShowCheckedModeBanner: false,
              locale: overrideLocale,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              localeResolutionCallback: (locale, supportedLocales) {
                if (locale != null) {
                  for (final supported in supportedLocales) {
                    if (supported.languageCode == locale.languageCode) {
                      return supported;
                    }
                  }
                }
                return const Locale('en');
              },
              themeMode: currentMode,
              theme: ThemeData(
                useMaterial3: true,
                colorScheme: lightScheme,
                fontFamilyFallback: cjkFallback,
                scaffoldBackgroundColor: lightScheme.surface,
                cardTheme: CardThemeData(
                  color: lightScheme.surfaceContainerHigh,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                navigationBarTheme: NavigationBarThemeData(
                  backgroundColor: lightScheme.surface,
                  indicatorColor: lightScheme.primary.withValues(alpha: 0.15),
                  labelTextStyle: WidgetStatePropertyAll(
                    TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: lightScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                appBarTheme: AppBarTheme(
                  backgroundColor: lightScheme.surface,
                  surfaceTintColor: Colors.transparent,
                  scrolledUnderElevation: 0,
                ),
                searchBarTheme: SearchBarThemeData(
                  backgroundColor: WidgetStatePropertyAll(
                    lightScheme.surfaceContainerHigh,
                  ),
                  elevation: const WidgetStatePropertyAll(0),
                  shape: WidgetStatePropertyAll(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                bottomSheetTheme: BottomSheetThemeData(
                  backgroundColor: lightScheme.surfaceContainerLow,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                ),
                snackBarTheme: SnackBarThemeData(
                  backgroundColor: lightScheme.inverseSurface,
                  contentTextStyle: TextStyle(color: lightScheme.onInverseSurface),
                  actionTextColor: lightScheme.inversePrimary,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                pageTransitionsTheme: pageTransition,
              ),
              darkTheme: ThemeData(
                useMaterial3: true,
                colorScheme: darkScheme,
                fontFamilyFallback: cjkFallback,
                scaffoldBackgroundColor: isFlat ? Colors.black : const Color(0xFF0E0E0E),
                cardTheme: CardThemeData(
                  color: darkScheme.surfaceContainerHigh,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                navigationBarTheme: NavigationBarThemeData(
                  backgroundColor: isFlat ? Colors.black : const Color(0xFF0E0E0E),
                  indicatorColor: darkScheme.primary.withValues(alpha: 0.15),
                  labelTextStyle: WidgetStatePropertyAll(
                    TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: darkScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                appBarTheme: AppBarTheme(
                  backgroundColor: isFlat ? Colors.black : const Color(0xFF0E0E0E),
                  surfaceTintColor: Colors.transparent,
                  scrolledUnderElevation: 0,
                ),
                searchBarTheme: SearchBarThemeData(
                  backgroundColor: WidgetStatePropertyAll(
                    darkScheme.surfaceContainerHigh,
                  ),
                  elevation: const WidgetStatePropertyAll(0),
                  shape: WidgetStatePropertyAll(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                bottomSheetTheme: BottomSheetThemeData(
                  backgroundColor: isFlat ? Colors.black : const Color(0xFF1A1A1A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                ),
                snackBarTheme: SnackBarThemeData(
                  backgroundColor: darkScheme.surfaceContainerHighest,
                  contentTextStyle: TextStyle(color: darkScheme.onSurface),
                  actionTextColor: darkScheme.primary,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                pageTransitionsTheme: pageTransition,
              ),
              home: AuthGate(setupLinkStream: setupLinkStream),
            );
      },
    );
  }
}

class AuthGate extends StatefulWidget {
  final Stream<Uri>? setupLinkStream;

  const AuthGate({super.key, this.setupLinkStream});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  StreamSubscription<Uri>? _setupLinkSubscription;
  Uri? _pendingSetupLink;
  Uri? _activeSetupLink;
  bool _servicesReady = false;
  bool _handlingSetupLink = false;

  @override
  void initState() {
    super.initState();
    _setupLinkSubscription = widget.setupLinkStream?.listen(
      _queueSetupLink,
      onError: (_) {},
    );
    _initServices();
  }

  @override
  void dispose() {
    _setupLinkSubscription?.cancel();
    super.dispose();
  }

  void _queueSetupLink(Uri uri) {
    if (!SetupLinkService.isSetupLink(uri)) return;
    if (_pendingSetupLink == uri || _activeSetupLink == uri) return;
    _pendingSetupLink = uri;
    _tryHandleSetupLink();
  }

  void _tryHandleSetupLink() {
    final link = _pendingSetupLink;
    if (!_servicesReady ||
        _handlingSetupLink ||
        link == null ||
        !mounted ||
        context.read<AuthProvider>().isLoading) {
      return;
    }

    _pendingSetupLink = null;
    _activeSetupLink = link;
    _handlingSetupLink = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await _handleSetupLink(link);
      _activeSetupLink = null;
      _handlingSetupLink = false;
      _tryHandleSetupLink();
    });
  }

  Future<void> _handleSetupLink(Uri link) async {
    await handleSetupLinkLogin(context, link);
  }

  Future<void> _initServices() async {
    // Load device info before log service so the log header has the real
    // app version and device model instead of fallback values.
    await ApiService.initVersion();
    try {
      if (Platform.isAndroid) {
        final info = await DeviceInfoPlugin().androidInfo;
        ApiService.deviceManufacturer = info.manufacturer;
        ApiService.deviceModel = info.model;
        ApiService.deviceSdkInt = info.version.sdkInt;
      } else if (Platform.isIOS) {
        final info = await DeviceInfoPlugin().iosInfo;
        ApiService.deviceManufacturer = 'Apple';
        ApiService.deviceModel = info.utsname.machine;
      }
    } catch (_) {}

    // Initialize log service early so all debugPrint calls are captured in the
    // log file. This is critical for diagnosing startup freezes in production.
    try {
      final loggingEnabled = await PlayerSettings.getLoggingEnabled();
      await LogService().init(loggingEnabled);
    } catch (_) {}

    final sw = Stopwatch()..start();
    debugPrint('[Init] _initServices started');

    // Initialize user account scope FIRST so all ScopedPrefs reads use the
    // correct scoped keys. Without this, settings read before init() would
    // fall back to un-scoped keys and appear as defaults.
    await UserAccountService().init();

    // One-time migration: copy any settings that were written under unscoped
    // keys (before scope was active) to the current user's scoped keys.
    await ScopedPrefs.migrateToScope();

    // Reload settings that were read in main() before scope was active
    var scopedTheme = await PlayerSettings.getThemeMode();
    if (scopedTheme == 'oled') {
      await PlayerSettings.setThemeMode('dark');
      await PlayerSettings.setFlatBackground(true);
      scopedTheme = 'dark';
    }
    applyThemeMode(scopedTheme);
    flatNotifier.value = await PlayerSettings.getFlatBackground();
    colorSourceNotifier.value = await PlayerSettings.getColorSource();
    manualSeedNotifier.value = Color(await PlayerSettings.getManualSeedColor());
    gradientIntensityNotifier.value = await PlayerSettings.getGradientIntensity();
    useColorEverywhereNotifier.value = await PlayerSettings.getUseColorEverywhere();
    snappyTransitionsNotifier.value = await PlayerSettings.getSnappyTransitions();
    classicWordingNotifier.value = await PlayerSettings.getClassicWording();
    PlayerSettings.showExplicitBadge = await PlayerSettings.getShowExplicitBadge();
    PlayerSettings.mp3IndexSeeking = await PlayerSettings.getMp3IndexSeeking();
    // Rotation lock: main() applied it before scope was active, so that pass
    // read the never-written unscoped key and always came up unlocked. The
    // timeout matters: on a headless boot (Android Auto bind) there is no
    // activity, the orientation channel never answers, and a bare await here
    // wedges the entire init - the browse tree never builds.
    try {
      await applyOrientationLock().timeout(const Duration(seconds: 2));
    } catch (_) {}
    // Background new-episode notifications: re-register the periodic job
    // (self-healing after OEM kills) and wire up notification taps.
    EpisodeNotificationService.syncRegistration();
    EpisodeNotificationService.initTapHandling();
    // Restore cover seed color
    {
      final seedInt = await PlayerSettings.getCoverSeedColor();
      if (seedInt != null) {
        coverSchemeNotifier.value = ColorScheme.fromSeed(
          seedColor: Color(seedInt),
          brightness: parseThemeMode(scopedTheme) == ThemeMode.light
              ? Brightness.light : Brightness.dark,
        );
      }
    }

    // Start auth restoration immediately — it doesn't depend on audio/cast/
    // download services and must not be blocked by a hanging service init.
    if (mounted) {
      context.read<AuthProvider>().tryRestoreSession();
    }

    // Migrate old auto-play booleans → unified queueMode (one-time, no-op after first run)
    debugPrint('[Init] migrateQueueMode... (${sw.elapsedMilliseconds}ms)');
    await PlayerSettings.migrateQueueMode();
    // Migrate unified queueMode → per-type book/podcast modes (one-time)
    await PlayerSettings.migrateBookPodcastQueueMode();

    // Generate persistent device ID for server identification
    debugPrint('[Init] device ID... (${sw.elapsedMilliseconds}ms)');
    await ApiService.initDeviceId();

    // Downloads must be loaded before the audio handler so getChildren()
    // can serve the Android Auto browse tree immediately.
    debugPrint('[Init] DownloadService... (${sw.elapsedMilliseconds}ms)');
    try {
      await DownloadService().init().timeout(const Duration(seconds: 8));
    } catch (e) {
      debugPrint('[Init] DownloadService.init timed out or failed: $e');
    }
    debugPrint('[Init] DownloadService done (${sw.elapsedMilliseconds}ms)');

    // Timeout guards against AudioService.init() hanging when Android killed
    // the app process but kept the MediaBrowserService alive.
    debugPrint('[Init] AudioPlayerService... (${sw.elapsedMilliseconds}ms)');
    try {
      await AudioPlayerService.init().timeout(const Duration(seconds: 8));
    } catch (e) {
      debugPrint('[Init] AudioPlayerService.init timed out or failed: $e');
    }
    // Route cold-start play() calls (headphones / lock screen tap before
    // the UI has bootstrapped the current item) through the existing
    // home-widget restore path. Registered as a static callback to avoid a
    // circular import between AudioPlayerService and HomeWidgetService.
    AudioPlayerService.onColdStartPlayRequested =
        HomeWidgetService().resumeLastPlayedIfAvailable;
    debugPrint('[Init] AudioPlayerService done (${sw.elapsedMilliseconds}ms)');

    try {
      await Permission.notification.request();
    } catch (e) {
      debugPrint('[Init] Permission request failed: $e');
    }

    // Initialize Chromecast (Android only)
    if (Platform.isAndroid) {
      try {
        await ChromecastService().init();
      } catch (e) {
        debugPrint('[Init] Chromecast init failed: $e');
      }
    }

    // Initialize download tracker and progress sync
    debugPrint('[Init] remaining services... (${sw.elapsedMilliseconds}ms)');
    try {
      await ProgressSyncService().init();
      // A killed stream can leave unsynced listening in the streaming buffer;
      // fold it into the offline ledger so the normal flush ships it.
      await ProgressSyncService().migrateOrphanStreamingTime();
      await LocalSessionService().init();
      await EqualizerService().init();
      await SleepTimerService().loadAutoSleepSettings();
      if (Platform.isAndroid) {
        // Pre-populate Android Auto browse tree in background.
        Future.microtask(() => AndroidAutoService().refresh());
      }
      if (Platform.isIOS) {
        // Initialize CarPlay browse tree.
        CarPlayService().init();
      }
      if (Platform.isAndroid || Platform.isIOS) {
        // Initialize homescreen widget
        await HomeWidgetService().init();
      }
      // App-icon long-press shortcuts. On Android the service registers
      // dynamic shortcuts + handler; on iOS it only wires the handler since
      // shortcut items themselves are declared statically in Info.plist
      // (so we get real UIKit system icon types like `.play`, `.search`).
      // Depends on AudioPlayerService + HomeWidgetService so they're ready
      // when the shortcut handler fires.
      await QuickActionsService().init();
    } catch (e) {
      debugPrint('[Init] Service init failed: $e');
    }
    debugPrint('[Init] _initServices complete (${sw.elapsedMilliseconds}ms)');
    _servicesReady = true;
    _tryHandleSetupLink();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isLoading && _pendingSetupLink != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _tryHandleSetupLink());
    }

    if (auth.isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AbsorbWaveIcon(
                size: 48,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 20),
              Text(
                'A B S O R B',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      letterSpacing: 6,
                      fontWeight: FontWeight.w300,
                    ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color:
                      Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (auth.isAuthenticated) {
      return const AppShell();
    }

    return const LoginScreen();
  }
}
