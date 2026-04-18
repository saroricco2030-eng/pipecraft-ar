import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/extensions/build_context_ext.dart';
import 'core/storage/prefs_keys.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'features/splash/splash_screen.dart';
import 'l10n/app_localizations.dart';

/// Sentry DSN — 빌드 시 주입 (`--dart-define=SENTRY_DSN=https://...`).
/// 비어있으면 Sentry는 자동으로 비활성화됨.
const _kSentryDsn = String.fromEnvironment('SENTRY_DSN');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  await SentryFlutter.init(
    (options) {
      options.dsn = _kSentryDsn;
      options.debug = kDebugMode;
      options.tracesSampleRate = kReleaseMode ? 0.1 : 0.0;
      // PII 전송 금지 — CLAUDE.md 10번 (개인정보 보호)
      options.sendDefaultPii = false;
    },
    appRunner: () => runApp(const MyApp()),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(PrefsKeys.themeMode);
    if (!mounted) return;
    setState(() => _themeMode = _parseThemeMode(stored));
  }

  void _cycleTheme() {
    final next = switch (_themeMode) {
      ThemeMode.system => ThemeMode.light,
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
    };
    setState(() => _themeMode = next);
    SharedPreferences.getInstance().then(
      (prefs) => prefs.setString(PrefsKeys.themeMode, next.name),
    );
  }

  static ThemeMode _parseThemeMode(String? name) {
    if (name == null) return ThemeMode.system;
    return ThemeMode.values.firstWhere(
      (m) => m.name == name,
      orElse: () => ThemeMode.system,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ThemeController(
      themeMode: _themeMode,
      onCycleTheme: _cycleTheme,
      child: MaterialApp(
        onGenerateTitle: (context) => context.l10n.appTitle,
        debugShowCheckedModeBanner: false,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: _themeMode,
        home: const SplashScreen(),
      ),
    );
  }
}
