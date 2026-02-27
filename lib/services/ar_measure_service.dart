import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class ArMeasureService {
  static const _channel = MethodChannel('pipecraft/ar_measure');

  /// 카메라 권한을 확인/요청한 뒤 AR 측정 Activity를 실행하고 거리(mm)를 반환한다.
  /// 사용자가 취소하면 null을 반환한다.
  /// 권한 거부 시 [CameraPermissionDeniedException]을 던진다.
  static Future<double?> getDistance() async {
    final granted = await _ensureCameraPermission();
    if (!granted) {
      throw CameraPermissionDeniedException();
    }
    // 타입 파라미터 없이 호출 — native가 int/double 어느 쪽으로 보내도 안전
    final result = await _channel.invokeMethod('getDistance');
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
  final String message = '카메라 권한이 필요합니다';
}
