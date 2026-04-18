import 'package:flutter/material.dart';

import '../../core/constants/pipe_specs.dart';
import '../../core/models/bend_result.dart';
import 'bending_calculator.dart';

// ─── BendDirection ──────────────────────────────────────

enum BendDirection { up, down, left, right }

extension BendDirectionX on BendDirection {
  /// Lucide 스타일 방향 아이콘 (이모지·화살표 문자 대신 공식 아이콘).
  IconData get icon => switch (this) {
        BendDirection.up => Icons.arrow_upward_rounded,
        BendDirection.down => Icons.arrow_downward_rounded,
        BendDirection.left => Icons.arrow_back_rounded,
        BendDirection.right => Icons.arrow_forward_rounded,
      };
}

// ─── BendEntry ──────────────────────────────────────────

/// 한 번의 꺾기 작업 항목.
/// SharedPreferences 직렬화를 지원하며, 복원 시 스프링백 테이블이
/// 변경됐을 수 있으므로 result는 저장값이 아니라 **재계산**한다.
class BendEntry {
  final int pipeOd;
  final Machine machine;
  final double insertLen;
  final double angle;
  final BendDirection direction;
  final BendResult result;
  final List<bool> stepsDone;

  bool get done => stepsDone.every((s) => s);

  BendEntry({
    required this.pipeOd,
    required this.machine,
    required this.insertLen,
    required this.angle,
    required this.direction,
    required this.result,
    List<bool>? stepsDone,
  }) : stepsDone = stepsDone ?? [false, false, false, false];

  Map<String, dynamic> toJson() => {
        'pipeOd': pipeOd,
        'machine': machine.index,
        'insertLen': insertLen,
        'angle': angle,
        'direction': direction.name,
        'stepsDone': stepsDone,
      };

  /// 단일 엔트리 복원. 손상된 데이터에 대해선 [FormatException]을 던진다.
  /// 호출 측에서 try-catch로 감싸 **엔트리 단위 실패**를 처리할 것.
  factory BendEntry.fromJson(Map<String, dynamic> json) {
    final machineIdx = json['machine'];
    final pipeOdRaw = json['pipeOd'];
    final insertLenRaw = json['insertLen'];
    final angleRaw = json['angle'];
    final directionRaw = json['direction'];

    if (machineIdx is! int ||
        machineIdx < 0 ||
        machineIdx >= Machine.values.length) {
      throw const FormatException('invalid machine');
    }
    if (pipeOdRaw is! int || !pipeSpecs.containsKey(pipeOdRaw)) {
      throw const FormatException('invalid pipeOd');
    }
    if (insertLenRaw is! num ||
        !insertLenRaw.toDouble().isFinite ||
        insertLenRaw <= 0) {
      throw const FormatException('invalid insertLen');
    }
    if (angleRaw is! num || !angleRaw.toDouble().isFinite) {
      throw const FormatException('invalid angle');
    }
    if (directionRaw is! String) {
      throw const FormatException('invalid direction');
    }

    final machine = Machine.values[machineIdx];
    final pipeOd = pipeOdRaw;
    final insertLen = insertLenRaw.toDouble();
    final angle = angleRaw.toDouble();
    late final BendDirection direction;
    try {
      direction = BendDirection.values.byName(directionRaw);
    } catch (_) {
      throw const FormatException('invalid direction name');
    }

    final steps = (json['stepsDone'] as List?)?.whereType<bool>().toList();

    final result = BendingCalculator.calculate(
      insertLength: insertLen,
      targetAngle: angle,
      pipeOd: pipeOd,
      machine: machine,
    );

    return BendEntry(
      pipeOd: pipeOd,
      machine: machine,
      insertLen: insertLen,
      angle: angle,
      direction: direction,
      result: result,
      stepsDone: steps,
    );
  }
}
