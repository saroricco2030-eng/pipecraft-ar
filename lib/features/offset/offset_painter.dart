import 'dart:math' show cos, pi;

import 'package:flutter/material.dart';

import '../../core/painting/diagram_helpers.dart';
import '../../core/theme/app_theme.dart';
import '../bending/bending_calculator.dart';

/// 오프셋 배관 경로 Technical Drawing 도면.
///
/// 좌측 시작점(S) → 상승 구간 → 장애물 통과 → 하강 구간 → 우측 끝점(E).
/// 상단: 총 길이 치수선. 좌측: 높이 H 치수선. 각 꺾기점에 B1/B2 라벨.
class OffsetPainter extends CustomPainter {
  final OffsetResult result;
  final double angle;
  final double obsHeight;
  final double obsWidth;
  final String obstacleLabel;
  final AppColors colors;

  OffsetPainter({
    required this.result,
    required this.angle,
    required this.obsHeight,
    required this.obsWidth,
    required this.obstacleLabel,
    required this.colors,
  });

  @override
  bool shouldRepaint(covariant OffsetPainter old) =>
      old.result.totalLength != result.totalLength ||
      old.result.b1Insert != result.b1Insert ||
      old.result.b2Insert != result.b2Insert ||
      old.result.offsetLength != result.offsetLength ||
      old.angle != angle ||
      old.obsHeight != obsHeight ||
      old.obsWidth != obsWidth ||
      old.obstacleLabel != obstacleLabel ||
      !identical(old.colors, colors);

  @override
  void paint(Canvas canvas, Size size) {
    drawDiagramGrid(canvas, size, colors.diagramGrid);

    final w = size.width;
    final h = size.height;
    const padX = 40.0;
    const padTop = 34.0;
    const padBottom = 28.0;

    final total = result.totalLength;
    if (total <= 0) return;

    final scale = (w - padX * 2) / total;
    final baseY = h - padBottom;

    final liftMax = (h - padTop - padBottom - 20).clamp(24.0, 100.0);
    final liftH = (obsHeight * scale * 1.6).clamp(24.0, liftMax);
    final topY = baseY - liftH;

    final pre = result.b1Insert;
    final offLen = result.offsetLength;
    final overW = obsWidth * scale;

    final angleRad = angle * pi / 180;
    final horizPart = (offLen * scale * cos(angleRad).abs()).clamp(18.0, 80.0);

    final startX = padX;
    final b1X = startX + pre * scale;
    final riseEndX = b1X + horizPart;
    final descentStartX = riseEndX + overW;
    final b2X = descentStartX + horizPart;
    final endX = w - padX;

    _drawHorizontalDim(
        canvas, startX, endX, padTop - 16, '${total.round()} mm');

    _drawObstacle(
      canvas,
      Rect.fromLTWH(riseEndX, topY - 2, overW, liftH + 2),
      obstacleLabel,
    );

    if (obsHeight > 0) {
      _drawVerticalDim(
        canvas,
        Offset(b1X - 12, baseY),
        Offset(b1X - 12, topY),
        'H ${obsHeight.round()}',
      );
    }

    _drawRoute(
      canvas, startX, b1X, riseEndX, descentStartX, b2X, endX, topY, baseY,
    );

    _drawBendPoint(canvas, Offset(b1X, baseY), 'B1');
    _drawBendPoint(canvas, Offset(b2X, baseY), 'B2');

    final angleStr = '${angle.round()}°';
    _drawAngleLabel(
      canvas,
      Offset((b1X + riseEndX) / 2, (baseY + topY) / 2 - 4),
      angleStr,
    );
    _drawAngleLabel(
      canvas,
      Offset((descentStartX + b2X) / 2, (baseY + topY) / 2 - 4),
      angleStr,
    );

    _drawEndpoint(canvas, Offset(startX, baseY), 'S');
    _drawEndpoint(canvas, Offset(endX, baseY), 'E');
  }

  // ─── 장애물 (도면 스타일 얇은 dashed 박스) ───────────
  void _drawObstacle(Canvas canvas, Rect rect, String label) {
    final fill = Paint()..color = colors.diagramObstacleFill;
    canvas.drawRect(rect, fill);

    final stroke = Paint()
      ..color = colors.diagramObstacleStroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    drawDiagramDashedLine(canvas, rect.topLeft, rect.topRight, stroke);
    drawDiagramDashedLine(canvas, rect.topRight, rect.bottomRight, stroke);
    drawDiagramDashedLine(canvas, rect.bottomRight, rect.bottomLeft, stroke);
    drawDiagramDashedLine(canvas, rect.bottomLeft, rect.topLeft, stroke);

    _drawHatching(canvas, rect, colors.diagramObstacleStroke);

    drawDiagramText(
      canvas,
      label,
      Offset(rect.center.dx, rect.top - 8),
      colors.diagramObstacleStroke,
      9,
      mono: true,
      bold: true,
      centered: true,
    );
  }

  void _drawHatching(Canvas canvas, Rect rect, Color color) {
    final p = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..strokeWidth = 0.5;
    canvas.save();
    canvas.clipRect(rect);
    const step = 8.0;
    for (double x = rect.left - rect.height; x < rect.right; x += step) {
      canvas.drawLine(
        Offset(x, rect.bottom),
        Offset(x + rect.height, rect.top),
        p,
      );
    }
    canvas.restore();
  }

  // ─── 파이프 경로 ─────────────────────────────────────
  void _drawRoute(
    Canvas canvas,
    double startX,
    double b1X,
    double riseEndX,
    double descentStartX,
    double b2X,
    double endX,
    double topY,
    double baseY,
  ) {
    final paint = Paint()
      ..color = colors.diagramPrimary
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(startX, baseY)
      ..lineTo(b1X, baseY)
      ..lineTo(riseEndX, topY)
      ..lineTo(descentStartX, topY)
      ..lineTo(b2X, baseY)
      ..lineTo(endX, baseY);

    canvas.drawPath(path, paint);
  }

  // ─── 꺾기점 마커 ─────────────────────────────────────
  void _drawBendPoint(Canvas canvas, Offset pos, String label) {
    final dot = Paint()..color = colors.diagramAccent;
    canvas.drawCircle(pos, 4.5, dot);

    final ring = Paint()
      ..color = colors.diagramAccent.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(pos, 8, ring);

    drawDiagramText(canvas, label, Offset(pos.dx, pos.dy + 16),
        colors.diagramAccent, 10,
        mono: true, bold: true, centered: true);
  }

  void _drawAngleLabel(Canvas canvas, Offset pos, String text) {
    drawDiagramText(canvas, text, pos, colors.diagramPrimary, 10,
        mono: true, bold: true, centered: true);
  }

  void _drawEndpoint(Canvas canvas, Offset pos, String label) {
    final ring = Paint()
      ..color = colors.diagramSecondary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(pos, 4, ring);

    drawDiagramText(canvas, label, Offset(pos.dx, pos.dy + 16),
        colors.diagramSecondary, 10,
        mono: true, bold: true, centered: true);
  }

  // ─── 수평/수직 치수선 ───────────────────────────────
  void _drawHorizontalDim(
      Canvas canvas, double x1, double x2, double y, String label) {
    final paint = Paint()
      ..color = colors.diagramDim
      ..strokeWidth = 1;

    canvas.drawLine(Offset(x1, y - 4), Offset(x1, y + 4), paint);
    canvas.drawLine(Offset(x2, y - 4), Offset(x2, y + 4), paint);
    canvas.drawLine(Offset(x1, y), Offset(x2, y), paint);
    drawDiagramArrowhead(canvas, Offset(x1, y), const Offset(-1, 0), paint);
    drawDiagramArrowhead(canvas, Offset(x2, y), const Offset(1, 0), paint);

    drawDiagramText(canvas, label, Offset((x1 + x2) / 2, y - 8),
        colors.diagramDimText, 10,
        mono: true, bold: true, centered: true);
  }

  void _drawVerticalDim(
      Canvas canvas, Offset bottom, Offset top, String label) {
    final paint = Paint()
      ..color = colors.diagramDim
      ..strokeWidth = 1;

    canvas.drawLine(Offset(bottom.dx - 3, bottom.dy),
        Offset(bottom.dx + 3, bottom.dy), paint);
    canvas.drawLine(Offset(top.dx - 3, top.dy),
        Offset(top.dx + 3, top.dy), paint);
    canvas.drawLine(bottom, top, paint);
    drawDiagramArrowhead(canvas, bottom, const Offset(0, 1), paint);
    drawDiagramArrowhead(canvas, top, const Offset(0, -1), paint);

    drawDiagramText(
      canvas,
      label,
      Offset(bottom.dx - 4, (bottom.dy + top.dy) / 2),
      colors.diagramDimText,
      9,
      mono: true,
      bold: true,
    );
  }
}
