import 'package:flutter/material.dart';

// ─── AppColors ───────────────────────────────────────────
class AppColors {
  final Color background;
  final Color card;
  final Color primary;
  final Color accent;
  final Color accentBg;
  final Color text;
  final Color text2;
  final Color text3;
  final Color border;
  final Color headerBg;
  final Color diagramBg;
  final Color diagramBorder;
  final Color navBar;
  final Color chipSelected;
  final Color chipUnselected;
  final Color stepUnchecked;

  const AppColors({
    required this.background,
    required this.card,
    required this.primary,
    required this.accent,
    required this.accentBg,
    required this.text,
    required this.text2,
    required this.text3,
    required this.border,
    required this.headerBg,
    required this.diagramBg,
    required this.diagramBorder,
    required this.navBar,
    required this.chipSelected,
    required this.chipUnselected,
    required this.stepUnchecked,
  });

  static const light = AppColors(
    background: Color(0xFFF5F3F0),
    card: Color(0xFFFFFFFF),
    primary: Color(0xFFC8102E),
    accent: Color(0xFF1A7A4A),
    accentBg: Color(0xFFEBF7F1),
    text: Color(0xFF18181B),
    text2: Color(0xFF71717A),
    text3: Color(0xFFA1A1AA),
    border: Color(0xFFE4E2DE),
    headerBg: Color(0xFFF8F6F3),
    diagramBg: Color(0xFF1C1C1E),
    diagramBorder: Color(0xFF2A2A2E),
    navBar: Color(0xFFFFFFFF),
    chipSelected: Color(0xFF18181B),
    chipUnselected: Color(0xFFFFFFFF),
    stepUnchecked: Color(0xFFEEEEEE),
  );

  static const dark = AppColors(
    background: Color(0xFF121212),
    card: Color(0xFF1E1E1E),
    primary: Color(0xFFFF4D6A),
    accent: Color(0xFF2ECC71),
    accentBg: Color(0xFF1A3A2A),
    text: Color(0xFFF5F5F5),
    text2: Color(0xFFA0A0A0),
    text3: Color(0xFF666666),
    border: Color(0xFF2A2A2E),
    headerBg: Color(0xFF252528),
    diagramBg: Color(0xFF1C1C1E),
    diagramBorder: Color(0xFF2A2A2E),
    navBar: Color(0xFF1A1A1A),
    chipSelected: Color(0xFFF5F5F5),
    chipUnselected: Color(0xFF1E1E1E),
    stepUnchecked: Color(0xFF2A2A2E),
  );
}

// ─── Theme Extension ────────────────────────────────────
class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  final AppColors colors;

  const AppColorsExtension(this.colors);

  @override
  AppColorsExtension copyWith({AppColors? colors}) =>
      AppColorsExtension(colors ?? this.colors);

  @override
  AppColorsExtension lerp(ThemeExtension<AppColorsExtension>? other, double t) {
    if (other is! AppColorsExtension) return this;
    return this; // no interpolation needed for discrete color sets
  }
}

// ─── ThemeData builders ─────────────────────────────────
class AppTheme {
  static ThemeData light() {
    const c = AppColors.light;
    return ThemeData(
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: c.primary,
        brightness: Brightness.light,
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: c.background,
      extensions: const [AppColorsExtension(c)],
    );
  }

  static ThemeData dark() {
    const c = AppColors.dark;
    return ThemeData(
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: c.primary,
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: c.background,
      extensions: const [AppColorsExtension(c)],
    );
  }
}

// ─── Context Extension ──────────────────────────────────
extension AppColorsContext on BuildContext {
  AppColors get appColors =>
      Theme.of(this).extension<AppColorsExtension>()?.colors ??
      AppColors.light;
}

const cardRadius = 12.0;

BoxDecoration cardDeco(AppColors c) => BoxDecoration(
      color: c.card,
      borderRadius: BorderRadius.circular(cardRadius),
      border: Border.all(color: c.border, width: 1),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
