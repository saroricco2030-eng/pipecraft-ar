/// SharedPreferences에서 사용되는 모든 키의 단일 출처.
///
/// 새 키 추가 시 여기에만 정의하고, 화면에서는 이 클래스의 상수만 참조한다.
/// 이전 키에서 마이그레이션이 필요하면 [legacyMachine]/[legacyOd] 처럼 명시.
class PrefsKeys {
  const PrefsKeys._();

  // ─── 전역 (셸 — 기기/관경/테마) ──────────────────────
  static const themeMode = 'theme_mode';
  static const machine = 'global_machine';
  static const od = 'global_od';

  /// Phase 1 → Phase 2 키 이동 (마이그레이션 1회성)
  static const legacyMachine = 'bending_machine';
  static const legacyOd = 'bending_od';

  // ─── 화면별 ───────────────────────────────────────────
  static const bendingData = 'bending_data';
  static const arMeasurements = 'ar_measurements';
}
