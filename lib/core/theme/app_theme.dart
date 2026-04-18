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
  final Color onPrimary; // 버튼 전경색 (primary 위)
  final Color chipSelectedText; // 선택된 칩 텍스트
  final Color shadow; // 그림자 색상
  final Color danger; // 파괴적 액션 (삭제 등)
  final Color success; // 성공/완료 상태

  // ─── Diagram Palette (Technical Drawing 스타일) ───────
  // 다이어그램은 다크 배경 고정이므로 light/dark 동일값
  final Color diagramPrimary; // 주 파이프선 (흰색 93%)
  final Color diagramSecondary; // 보조선 (흰색 40%)
  final Color diagramGrid; // 배경 그리드 (흰색 8%)
  final Color diagramAccent; // 현재 꺾기점 / 강조
  final Color diagramDone; // 완료 꺾기점
  final Color diagramDim; // 치수선 (gold 얇은 점선)
  final Color diagramDimText; // 치수 텍스트 (gold)
  final Color diagramObstacleFill; // 장애물 fill
  final Color diagramObstacleStroke; // 장애물 stroke
  final Color splashBg; // 스플래시 화면 배경 (이미지와 톤 통일)

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
    required this.onPrimary,
    required this.chipSelectedText,
    required this.shadow,
    required this.danger,
    required this.success,
    required this.diagramPrimary,
    required this.diagramSecondary,
    required this.diagramGrid,
    required this.diagramAccent,
    required this.diagramDone,
    required this.diagramDim,
    required this.diagramDimText,
    required this.diagramObstacleFill,
    required this.diagramObstacleStroke,
    required this.splashBg,
  });

  // Airbnb Soft Coral 라이트 모드 — CLAUDE.md 디자인 시스템 기준
  static const light = AppColors(
    background: Color(0xFFFFF9F5), // --bg: 크림 배경
    card: Color(0xFFFFFFFF), // --surface
    primary: Color(0xFFE8876B), // --accent: Soft Coral
    accent: Color(0xFFD4725A), // --accent-dark: 텍스트용 어두운 코랄
    accentBg: Color(0xFFFFF0EB), // --accent-dim: 코랄 배경
    text: Color(0xFF2A1F1F), // --text-primary
    text2: Color(0xFF5A4A42), // --text-secondary
    text3: Color(0xFF7A6A5E), // --text-muted (WCAG AA 4.5:1+)
    border: Color(0xFFE8D5C8), // --border: 코랄 틴트
    headerBg: Color(0xFFFFF5F0), // surface-hi: 따뜻한 톤
    diagramBg: Color(0xFF1C1C1E), // 다이어그램은 다크 유지
    diagramBorder: Color(0xFF2A2A2E),
    navBar: Color(0xFFFFFFFF),
    chipSelected: Color(0xFF2A1F1F), // 텍스트 컬러 기반
    chipUnselected: Color(0xFFFFFFFF),
    stepUnchecked: Color(0xFFF0E6DF), // 따뜻한 그레이
    onPrimary: Color(0xFFFFFFFF),
    chipSelectedText: Color(0xFFFFFFFF),
    shadow: Color(0x0D000000), // black 5%
    danger: Color(0xFFDC2626), // --danger (light)
    success: Color(0xFF059669), // --success (light)
    // Technical Drawing 팔레트 (다이어그램은 다크 배경 고정)
    diagramPrimary: Color(0xFFEDEDED), // 주 파이프선 white 93%
    diagramSecondary: Color(0x66FFFFFF), // 보조선 white 40%
    diagramGrid: Color(0x14FFFFFF), // 그리드 white 8%
    diagramAccent: Color(0xFFFF8A73), // coral 강조
    diagramDone: Color(0xFF4ADE80), // 완료 green
    diagramDim: Color(0x99FBBF24), // 치수선 gold 60%
    diagramDimText: Color(0xFFFCD34D), // 치수 텍스트 gold
    diagramObstacleFill: Color(0x1FF87171), // 장애물 fill 12%
    diagramObstacleStroke: Color(0x99F87171), // 장애물 stroke 60%
    splashBg: Color(0xFF0C1216), // 스플래시 다크 배경 (양 모드 공통)
  );

  // 다크 모드 — CLAUDE.md 디자인 시스템 기준
  static const dark = AppColors(
    background: Color(0xFF141210), // --bg: 따뜻한 다크
    card: Color(0xFF1E1C1A), // --surface: 불투명 서피스
    primary: Color(0xFFFF6B5A), // --accent: Coral 다크 변형
    accent: Color(0xFF2ECC71), // --success 계열 유지
    accentBg: Color(0xFF1A3A2A), // --accent-dim
    text: Color(0xFFEBE8E5), // --text-primary: rgba(255,255,255,0.92)
    text2: Color(0xFF8A8280), // --text-secondary
    text3: Color(0xFF7A7674), // --text-muted (WCAG AA 4.5:1+)
    border: Color(0xFF2A2826), // --border
    headerBg: Color(0xFF222018), // --surface-hi
    diagramBg: Color(0xFF1C1C1E),
    diagramBorder: Color(0xFF2A2A2E),
    navBar: Color(0xFF1A1816),
    chipSelected: Color(0xFFEBE8E5),
    chipUnselected: Color(0xFF2A2826), // card와 구분되는 어두운 톤
    stepUnchecked: Color(0xFF2A2826),
    onPrimary: Color(0xFFFFFFFF),
    chipSelectedText: Color(0xFF141210), // 다크 배경 텍스트
    shadow: Color(0x14000000), // black 8%
    danger: Color(0xFFEF5350), // --danger (dark)
    success: Color(0xFF34D399), // --success (dark)
    // Technical Drawing 팔레트 (light/dark 동일 — 다이어그램은 다크 고정)
    diagramPrimary: Color(0xFFEDEDED),
    diagramSecondary: Color(0x66FFFFFF),
    diagramGrid: Color(0x14FFFFFF),
    diagramAccent: Color(0xFFFF8A73),
    diagramDone: Color(0xFF4ADE80),
    diagramDim: Color(0x99FBBF24),
    diagramDimText: Color(0xFFFCD34D),
    diagramObstacleFill: Color(0x1FF87171),
    diagramObstacleStroke: Color(0x99F87171),
    splashBg: Color(0xFF0C1216),
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
      Theme.of(this).extension<AppColorsExtension>()?.colors ?? AppColors.light;
}

const cardRadius = 12.0;

BoxDecoration cardDeco(AppColors c) => BoxDecoration(
  color: c.card,
  borderRadius: BorderRadius.circular(cardRadius),
  border: Border.all(color: c.border, width: 1),
  boxShadow: [
    BoxShadow(color: c.shadow, blurRadius: 8, offset: const Offset(0, 2)),
  ],
);
