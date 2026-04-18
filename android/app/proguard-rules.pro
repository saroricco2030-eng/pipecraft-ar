# PipeCraft AR — R8/ProGuard 규칙
# CLAUDE.md 12번 "코드 보호" 적용.

# ─── Flutter ──────────────────────────────────────────
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# ─── ARCore (Google AR) ───────────────────────────────
# 네이티브 인터페이스를 리플렉션으로 호출하는 경우가 있어 유지.
-keep class com.google.ar.core.** { *; }
-dontwarn com.google.ar.core.**

# ─── Sentry ───────────────────────────────────────────
# 심볼리케이션에 필요한 스택트레이스 정보 유지.
-keep class io.sentry.** { *; }
-dontwarn io.sentry.**

# ─── kotlin metadata ─────────────────────────────────
-keep class kotlin.Metadata { *; }
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod
-keepattributes SourceFile, LineNumberTable

# ─── 앱 자체 ──────────────────────────────────────────
# MethodChannel 인터페이스는 리플렉션 없이 문자열 매칭 — ProGuard 안전.
# BendEntry.toJson/fromJson의 필드명은 SharedPreferences에 저장되므로
# 필드명 난독화되면 기존 저장본 로드 실패.
-keepclassmembers class com.athvacr.pipecraft_ar.** { *; }
