import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import '../core/extensions/build_context_ext.dart';
import '../core/theme/app_theme.dart';
import '../l10n/app_localizations.dart';

/// AR 측정 Activity에 넘길 UI 문자열 팩.
/// Flutter l10n 값을 그대로 복사해 Intent extras로 전달한다.
class ArMeasureStrings {
  final String scanHint;
  final String trackingLost;
  final String planeNotDetected;
  final String tapFirstPoint;
  final String tapSecondPoint;
  final String multiPointTemplate; // {count} 치환 전
  final String noSurface;
  final String btnUndo;
  final String btnReset;
  final String btnConfirm;
  final String totalPrefix;
  final String segmentTemplate; // {index}, {distance} 치환 전
  final String errorDeviceUnsupported;
  final String errorApkTooOld;
  final String errorSdkTooOld;
  final String errorSessionInit;
  final String errorCameraUnavailable;

  const ArMeasureStrings({
    required this.scanHint,
    required this.trackingLost,
    required this.planeNotDetected,
    required this.tapFirstPoint,
    required this.tapSecondPoint,
    required this.multiPointTemplate,
    required this.noSurface,
    required this.btnUndo,
    required this.btnReset,
    required this.btnConfirm,
    required this.totalPrefix,
    required this.segmentTemplate,
    required this.errorDeviceUnsupported,
    required this.errorApkTooOld,
    required this.errorSdkTooOld,
    required this.errorSessionInit,
    required this.errorCameraUnavailable,
  });

  factory ArMeasureStrings.fromL10n(AppLocalizations l) => ArMeasureStrings(
    scanHint: l.arNativeScanHint,
    trackingLost: l.arNativeTrackingLost,
    planeNotDetected: l.arNativePlaneNotDetected,
    tapFirstPoint: l.arNativeTapFirstPoint,
    tapSecondPoint: l.arNativeTapSecondPoint,
    multiPointTemplate: l.arNativeMultiPoint(0), // {count} placeholder
    noSurface: l.arNativeNoSurface,
    btnUndo: l.arNativeBtnUndo,
    btnReset: l.arNativeBtnReset,
    btnConfirm: l.arNativeBtnConfirm,
    totalPrefix: l.arNativeTotalPrefix,
    segmentTemplate: l.arNativeSegmentFormat(0, ''),
    errorDeviceUnsupported: l.arNativeErrorDeviceUnsupported,
    errorApkTooOld: l.arNativeErrorApkTooOld,
    errorSdkTooOld: l.arNativeErrorSdkTooOld,
    errorSessionInit: l.arNativeErrorSessionInit,
    errorCameraUnavailable: l.arNativeErrorCameraUnavailable,
  );

  Map<String, String> toMap() => {
    'scanHint': scanHint,
    'trackingLost': trackingLost,
    'planeNotDetected': planeNotDetected,
    'tapFirstPoint': tapFirstPoint,
    'tapSecondPoint': tapSecondPoint,
    'multiPointTemplate': multiPointTemplate,
    'noSurface': noSurface,
    'btnUndo': btnUndo,
    'btnReset': btnReset,
    'btnConfirm': btnConfirm,
    'totalPrefix': totalPrefix,
    'segmentTemplate': segmentTemplate,
    'errorDeviceUnsupported': errorDeviceUnsupported,
    'errorApkTooOld': errorApkTooOld,
    'errorSdkTooOld': errorSdkTooOld,
    'errorSessionInit': errorSessionInit,
    'errorCameraUnavailable': errorCameraUnavailable,
  };
}

/// 네이티브 AR Activity 브랜드 컬러.
class ArMeasureColors {
  final String primary; // 확인 버튼
  final String secondary; // 되돌리기/초기화 버튼
  final String onPrimary; // 버튼 전경색

  const ArMeasureColors({
    required this.primary,
    required this.secondary,
    required this.onPrimary,
  });

  factory ArMeasureColors.fromAppColors(AppColors c) => ArMeasureColors(
    primary: _toHex(c.primary),
    secondary: _toHex(c.chipUnselected),
    onPrimary: _toHex(c.onPrimary),
  );

  Map<String, String> toMap() => {
    'primary': primary,
    'secondary': secondary,
    'onPrimary': onPrimary,
  };

  static String _toHex(Color c) {
    final a = (c.a * 255).round() & 0xFF;
    final r = (c.r * 255).round() & 0xFF;
    final g = (c.g * 255).round() & 0xFF;
    final b = (c.b * 255).round() & 0xFF;
    return '#${a.toRadixString(16).padLeft(2, '0')}'
            '${r.toRadixString(16).padLeft(2, '0')}'
            '${g.toRadixString(16).padLeft(2, '0')}'
            '${b.toRadixString(16).padLeft(2, '0')}'
        .toUpperCase();
  }
}

class ArMeasureService {
  static const _channel = MethodChannel('pipecraft/ar_measure');

  /// 카메라 권한을 확인/요청한 뒤 AR 측정 Activity를 실행하고 거리(mm)를 반환한다.
  /// 사용자가 취소하면 null을 반환한다.
  /// 권한 거부 시 [CameraPermissionDeniedException]을 던진다.
  ///
  /// [strings]와 [colors]는 네이티브 UI에 표시될 i18n 문자열·브랜드 색상.
  /// 호출 시점의 context에서 빌드하여 넘긴다.
  static Future<double?> getDistance({
    required ArMeasureStrings strings,
    required ArMeasureColors colors,
  }) async {
    final granted = await _ensureCameraPermission();
    if (!granted) {
      throw CameraPermissionDeniedException();
    }
    final result = await _channel.invokeMethod('getDistance', {
      'strings': strings.toMap(),
      'colors': colors.toMap(),
    });
    if (result == null) return null;
    if (result is double) return result;
    if (result is num) return result.toDouble();
    return null;
  }

  static Future<bool> _ensureCameraPermission() async {
    var status = await Permission.camera.status;
    if (status.isGranted) return true;
    status = await Permission.camera.request();
    return status.isGranted;
  }

  static Future<bool> isPermanentlyDenied() async {
    return await Permission.camera.isPermanentlyDenied;
  }
}

class CameraPermissionDeniedException implements Exception {
  const CameraPermissionDeniedException();
}

/// 화면에서 호출하기 좋게 권한·에러·다이얼로그까지 통합한 고수준 헬퍼.
///
/// - 권한 거부 시 다이얼로그 표시 후 null 반환
/// - 측정 에러 시 SnackBar 표시 후 null 반환
/// - 사용자 취소 시 null 반환
/// - 측정 성공 시 거리(mm) 반환
class ArMeasure {
  const ArMeasure._();

  static Future<double?> measureWithUi(BuildContext context) async {
    final l = context.l10n;
    final strings = ArMeasureStrings.fromL10n(l);
    final colors = ArMeasureColors.fromAppColors(context.appColors);

    try {
      return await ArMeasureService.getDistance(
        strings: strings,
        colors: colors,
      );
    } on CameraPermissionDeniedException {
      if (context.mounted) await _showPermissionDeniedDialog(context);
    } on PlatformException {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.arMeasurementError)));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.arGeneralError)));
      }
    }
    return null;
  }

  static Future<void> _showPermissionDeniedDialog(BuildContext context) async {
    final permanentlyDenied = await ArMeasureService.isPermanentlyDenied();
    if (!context.mounted) return;
    final l = context.l10n;
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.permissionCameraTitle),
        content: Text(
          permanentlyDenied
              ? l.permissionCameraMessageDenied
              : l.permissionCameraMessage,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.commonCancel),
          ),
          if (permanentlyDenied)
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                openAppSettings();
              },
              child: Text(l.commonOpenSettings),
            ),
        ],
      ),
    );
  }
}
