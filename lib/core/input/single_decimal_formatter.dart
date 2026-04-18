import 'package:flutter/services.dart';

/// 입력 필드에서 소수점(`.`) 하나만 허용한다.
/// 이미 `.`이 포함된 상태에서 추가 `.` 입력은 거부.
class SingleDecimalFormatter extends TextInputFormatter {
  const SingleDecimalFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if ('.'.allMatches(text).length <= 1) return newValue;
    return oldValue;
  }
}

/// 입력값 상한 검증 — 10000mm 초과 값 입력 시 이전 값 유지.
/// 현장에서 자릿수 실수 방지용.
class MaxValueFormatter extends TextInputFormatter {
  final double max;
  const MaxValueFormatter({this.max = 9999});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;
    final v = double.tryParse(newValue.text);
    if (v == null) return newValue; // 숫자 아니면 다른 formatter가 처리
    if (!v.isFinite || v > max) return oldValue;
    return newValue;
  }
}
