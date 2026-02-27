import 'dart:math';

import '../../core/constants/pipe_specs.dart';
import '../../core/models/bend_result.dart';

class BendingCalculator {
  static BendResult calculate({
    required double insertLength,
    required double targetAngle,
    required int pipeOd,
    required Machine machine,
  }) {
    final spec = pipeSpecs[pipeOd];
    if (spec == null) {
      throw ArgumentError('지원하지 않는 관경: $pipeOd mm');
    }

    final sb = springBack[machine]?[pipeOd];
    if (sb == null) {
      throw ArgumentError('스프링백 데이터 없음: ${machine.label} / $pipeOd mm');
    }

    final setAngle = targetAngle + sb;
    final arcLength = spec.minRadius * (targetAngle * pi / 180);
    final shortenLength = arcLength;
    final consumedLength = insertLength + arcLength;

    return BendResult(
      insertLength: insertLength,
      targetAngle: targetAngle,
      setAngle: setAngle,
      arcLength: arcLength,
      shortenLength: shortenLength,
      consumedLength: consumedLength,
    );
  }
}

class OffsetResult {
  final double offsetLength;
  final double horizMove;
  final double b1Insert;
  final double b2Insert;
  final double totalLength;

  const OffsetResult({
    required this.offsetLength,
    required this.horizMove,
    required this.b1Insert,
    required this.b2Insert,
    required this.totalLength,
  });
}

class OffsetCalculator {
  static OffsetResult calculate({
    required double obsHeight,
    required double obsWidth,
    required double preDist,
    required double postDist,
    required double angle,
  }) {
    final rad = angle * pi / 180;
    final sinVal = sin(rad);
    if (sinVal.abs() < 1e-10) {
      throw ArgumentError('오프셋 각도가 0°이면 계산할 수 없습니다');
    }
    final cosVal = cos(rad);
    if (cosVal.abs() < 1e-10) {
      throw ArgumentError('오프셋 각도가 90°이면 수평이동을 계산할 수 없습니다');
    }
    final offsetLength = obsHeight / sinVal;
    final horizMove = obsHeight * cosVal / sinVal; // tan 대신 cos/sin 사용
    final b1Insert = preDist;
    final b2Insert = preDist + offsetLength;
    final totalLength = preDist + offsetLength * 2 + obsWidth + postDist;

    return OffsetResult(
      offsetLength: offsetLength,
      horizMove: horizMove,
      b1Insert: b1Insert,
      b2Insert: b2Insert,
      totalLength: totalLength,
    );
  }
}
