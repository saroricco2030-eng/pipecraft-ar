import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:pipe_craft_ar/core/constants/pipe_specs.dart';
import 'package:pipe_craft_ar/features/bending/bending_calculator.dart';

void main() {
  group('BendingCalculator', () {
    test('15mm ROBEND 90° 계산 — setAngle = 92°', () {
      final r = BendingCalculator.calculate(
        insertLength: 150,
        targetAngle: 90,
        pipeOd: 15,
        machine: Machine.robend4000,
      );
      // springBack = 2° → setAngle = 92
      expect(r.setAngle, 92);
      // arcLength = 45 × (90 × π / 180) = 45 × π/2 ≈ 70.69
      expect(r.arcLength, closeTo(45 * pi / 2, 0.01));
      expect(r.shortenLength, r.arcLength);
      expect(r.consumedLength, 150 + r.arcLength);
    });

    test('22mm REMS Curvo 45° 계산 — setAngle = 47°', () {
      final r = BendingCalculator.calculate(
        insertLength: 200,
        targetAngle: 45,
        pipeOd: 22,
        machine: Machine.remsCurvo,
      );
      // springBack = 2° → setAngle = 47
      expect(r.setAngle, 47);
      // arcLength = 66 × (45 × π / 180)
      expect(r.arcLength, closeTo(66 * 45 * pi / 180, 0.01));
    });

    test('35mm ROBEND 30° 계산 — setAngle = 34°', () {
      final r = BendingCalculator.calculate(
        insertLength: 100,
        targetAngle: 30,
        pipeOd: 35,
        machine: Machine.robend4000,
      );
      // springBack = 4° → setAngle = 34
      expect(r.setAngle, 34);
    });

    test('지원하지 않는 관경 — ArgumentError', () {
      expect(
        () => BendingCalculator.calculate(
          insertLength: 100,
          targetAngle: 90,
          pipeOd: 99,
          machine: Machine.robend4000,
        ),
        throwsArgumentError,
      );
    });

    test('모든 관경/기기 조합이 유효한 스프링백을 가짐', () {
      for (final machine in Machine.values) {
        for (final od in pipeSpecs.keys) {
          expect(springBack[machine]?[od], isNotNull,
              reason: '${machine.label} / $od mm 스프링백 누락');
        }
      }
    });
  });

  group('OffsetCalculator', () {
    test('45° 기본 오프셋 계산', () {
      final r = OffsetCalculator.calculate(
        obsHeight: 100,
        obsWidth: 50,
        preDist: 150,
        postDist: 150,
        angle: 45,
      );
      // offsetLength = 100 / sin(45°) = 100 / 0.7071 ≈ 141.42
      expect(r.offsetLength, closeTo(100 / sin(45 * pi / 180), 0.1));
      // horizMove = 100 / tan(45°) = 100
      expect(r.horizMove, closeTo(100, 0.1));
      expect(r.b1Insert, 150);
      expect(r.b2Insert, closeTo(150 + r.offsetLength, 0.1));
      // total = 150 + 141.42×2 + 50 + 150
      expect(r.totalLength,
          closeTo(150 + r.offsetLength * 2 + 50 + 150, 0.1));
    });

    test('30° 오프셋 — offsetLength = h/sin(30°) = 2h', () {
      final r = OffsetCalculator.calculate(
        obsHeight: 80,
        obsWidth: 30,
        preDist: 100,
        postDist: 100,
        angle: 30,
      );
      // sin(30°) = 0.5 → offsetLength = 160
      expect(r.offsetLength, closeTo(160, 0.1));
    });

    test('각도 0° — ArgumentError', () {
      expect(
        () => OffsetCalculator.calculate(
          obsHeight: 100,
          obsWidth: 50,
          preDist: 150,
          postDist: 150,
          angle: 0,
        ),
        throwsArgumentError,
      );
    });

    test('각도 90° — ArgumentError (tan 정의 불가)', () {
      expect(
        () => OffsetCalculator.calculate(
          obsHeight: 100,
          obsWidth: 50,
          preDist: 150,
          postDist: 150,
          angle: 90,
        ),
        throwsArgumentError,
      );
    });
  });
}
