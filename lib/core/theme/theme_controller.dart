import 'package:flutter/material.dart';

/// 테마 전환을 트리 전역에 공유하는 InheritedWidget.
///
/// 테마 순환 순서: system → light → dark → system.
/// 실제 ThemeMode 저장·복원은 상위에서 담당 (`main.dart`의 `_MyAppState`).
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
