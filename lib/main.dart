import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme/app_theme.dart';
import 'features/bending/bending_screen.dart';
import 'features/offset/offset_screen.dart';
import 'features/ar/ar_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  runApp(const MyApp());
}

// ─── Theme Controller InheritedWidget ───────────────────
class ThemeController extends InheritedWidget {
  final ThemeMode themeMode;
  final VoidCallback onCycleTheme;

  const ThemeController({
    super.key,
    required this.themeMode,
    required this.onCycleTheme,
    required super.child,
  });

  static ThemeController? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ThemeController>();

  @override
  bool updateShouldNotify(ThemeController old) => themeMode != old.themeMode;
}

// ─── App ────────────────────────────────────────────────
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
    final mode = prefs.getString('theme_mode') ?? 'system';
    setState(() {
      _themeMode = switch (mode) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
    });
  }

  void _cycleTheme() {
    final next = switch (_themeMode) {
      ThemeMode.system => ThemeMode.light,
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
    };
    setState(() => _themeMode = next);
    SharedPreferences.getInstance().then((prefs) {
      final key = switch (next) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        _ => 'system',
      };
      prefs.setString('theme_mode', key);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ThemeController(
      themeMode: _themeMode,
      onCycleTheme: _cycleTheme,
      child: MaterialApp(
        title: 'PIPECRAFT AR',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: _themeMode,
        home: const MainShell(),
      ),
    );
  }
}

// ─── Main Shell ─────────────────────────────────────────
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  static const _screens = [
    BendingScreen(),
    OffsetScreen(),
    ArScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        backgroundColor: c.navBar,
        indicatorColor: c.primary.withValues(alpha: 0.1),
        height: 64,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.straighten_outlined),
            selectedIcon: Icon(Icons.straighten, color: c.primary),
            label: '밴딩',
          ),
          NavigationDestination(
            icon: const Icon(Icons.route_outlined),
            selectedIcon: Icon(Icons.route, color: c.primary),
            label: '오프셋',
          ),
          NavigationDestination(
            icon: const Icon(Icons.camera_alt_outlined),
            selectedIcon: Icon(Icons.camera_alt, color: c.primary),
            label: 'AR 측정',
          ),
        ],
      ),
    );
  }
}
