import 'package:flutter/material.dart';

import '../../core/painting/diagram_helpers.dart';
import '../../core/theme/app_theme.dart';
import 'bend_entry.dart';

/// 밴딩 꺾기 경로 Technical Drawing 프리뷰.
///
/// 수평 기준선 위에 꺾기점을 균등 배치하고, 상단에 총 길이 치수선,
/// 하단에 각도·방향 라벨을 배치하는 도면 스타일.
class RoutePainter extends CustomPainter {
  final List<BendEntry> bends;
  final AppColors colors;

  RoutePainter({required this.bends, required this.colors});

  @override
  bool shouldRepaint(covariant RoutePainter old) {
    if (!identical(old.colors, colors)) return true;
    if (old.bends.length != bends.length) return true;
    for (int i = 0; i < bends.length; i++) {
      final a = old.bends[i];
      final b = bends[i];
      if (a.done != b.done ||
          a.angle != b.angle ||
          a.direction != b.direction ||
          a.insertLen != b.insertLen ||
          a.result.consumedLength != b.result.consumedLength) {
        return true;
      }
    }
    return false;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (bends.isEmpty) return;

    drawDiagramGrid(canvas, size, colors.diagramGrid);

    const padX = 36.0;
    final topY = size.height * 0.28; // 치수선
    final lineY = size.height * 0.55; // 메인 파이프
    final labelBaseY = size.height * 0.78; // 각도/방향 라벨

    final n = bends.length;
    final segCount = n + 1;
    final segLen = (size.width - padX * 2) / segCount;
    final markX = List<double>.generate(n + 2, (i) => padX + i * segLen);

    _drawDimension(canvas, markX.first, markX.last, topY);
    _drawMainLine(canvas, markX.first, markX.last, lineY);
    _drawInsertMarks(canvas, markX, lineY, segLen);
    _drawBendPoints(canvas, markX, lineY, labelBaseY);
    _drawEndpoints(canvas, markX, lineY);
  }

  // ─── 상단 총 길이 치수선 ────────────────────────────
  void _drawDimension(Canvas canvas, double x1, double x2, double y) {
    final total = bends.fold<double>(0, (s, b) => s + b.result.consumedLength);
    final paint = Paint()
      ..color = colors.diagramDim
      ..strokeWidth = 1;

    canvas.drawLine(Offset(x1, y - 4), Offset(x1, y + 8), paint);
    canvas.drawLine(Offset(x2, y - 4), Offset(x2, y + 8), paint);
    canvas.drawLine(Offset(x1, y), Offset(x2, y), paint);
    drawDiagramArrowhead(canvas, Offset(x1, y), const Offset(-1, 0), paint);
    drawDiagramArrowhead(canvas, Offset(x2, y), const Offset(1, 0), paint);

    drawDiagramText(
      canvas,
      '${total.round()} mm',
      Offset((x1 + x2) / 2, y - 9),
      colors.diagramDimText,
      11,
      mono: true,
      bold: true,
      centered: true,
    );
  }

  void _drawMainLine(Canvas canvas, double x1, double x2, double y) {
    final paint = Paint()
      ..color = colors.diagramPrimary
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(x1, y), Offset(x2, y), paint);
  }

  void _drawInsertMarks(
    Canvas canvas,
    List<double> markX,
    double lineY,
    double segLen,
  ) {
    final paint = Paint()
      ..color = colors.diagramAccent
      ..strokeWidth = 1.5;

    for (int i = 0; i < bends.length; i++) {
      final b = bends[i];
      final total = b.insertLen + b.result.arcLength;
      if (total <= 0) continue;
      final ratio = (b.insertLen / total).clamp(0.0, 1.0);
      final x = markX[i] + segLen * ratio * 0.85;
      canvas.drawLine(Offset(x, lineY - 6), Offset(x, lineY + 6), paint);
    }
  }

  void _drawBendPoints(
    Canvas canvas,
    List<double> markX,
    double lineY,
    double labelBaseY,
  ) {
    for (int i = 0; i < bends.length; i++) {
      final b = bends[i];
      final x = markX[i + 1];
      final color = b.done ? colors.diagramDone : colors.diagramAccent;

      canvas.drawCircle(Offset(x, lineY), 5, Paint()..color = color);
      canvas.drawCircle(
        Offset(x, lineY),
        9,
        Paint()
          ..color = color.withValues(alpha: 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );

      drawDiagramText(
        canvas,
        '${b.angle.round()}°',
        Offset(x, labelBaseY - 8),
        color,
        12,
        mono: true,
        bold: true,
        centered: true,
      );

      _drawDirectionIndicator(
        canvas,
        b.direction,
        Offset(x, labelBaseY + 10),
        colors.diagramSecondary,
      );
    }
  }

  void _drawDirectionIndicator(
    Canvas canvas,
    BendDirection dir,
    Offset center,
    Color color,
  ) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    const len = 6.0;
    final (dx, dy) = switch (dir) {
      BendDirection.up => (0.0, -len),
      BendDirection.down => (0.0, len),
      BendDirection.left => (-len, 0.0),
      BendDirection.right => (len, 0.0),
    };

    final tip = Offset(center.dx + dx, center.dy + dy);
    canvas.drawLine(center, tip, paint);

    const head = 2.5;
    final (hx1, hy1, hx2, hy2) = switch (dir) {
      BendDirection.up => (-head, head, head, head),
      BendDirection.down => (-head, -head, head, -head),
      BendDirection.left => (head, -head, head, head),
      BendDirection.right => (-head, -head, -head, head),
    };
    canvas.drawLine(tip, Offset(tip.dx + hx1, tip.dy + hy1), paint);
    canvas.drawLine(tip, Offset(tip.dx + hx2, tip.dy + hy2), paint);
  }

  void _drawEndpoints(Canvas canvas, List<double> markX, double lineY) {
    final ring = Paint()
      ..color = colors.diagramSecondary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawCircle(Offset(markX.first, lineY), 4, ring);
    canvas.drawCircle(Offset(markX.last, lineY), 4, ring);

    drawDiagramText(
      canvas,
      'S',
      Offset(markX.first, lineY + 18),
      colors.diagramSecondary,
      10,
      mono: true,
      bold: true,
      centered: true,
    );
    drawDiagramText(
      canvas,
      'E',
      Offset(markX.last, lineY + 18),
      colors.diagramSecondary,
      10,
      mono: true,
      bold: true,
      centered: true,
    );
  }
}
