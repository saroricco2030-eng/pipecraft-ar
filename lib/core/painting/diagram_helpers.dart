import 'dart:math' show sqrt;

import 'package:flutter/material.dart';

/// CustomPaint 다이어그램(Bending RoutePainter, Offset OffsetPainter)이
/// 공유하는 그리기 유틸리티. Technical Drawing 톤 일관성을 위해 한 곳에 모음.

/// 캔버스 전체에 균일한 그리드 라인을 한 번의 [drawPath]로 그린다.
/// 개별 [drawLine] 대비 draw call 수가 1로 줄어 저성능 기기에서 jank 감소.
void drawDiagramGrid(
  Canvas canvas,
  Size size,
  Color color, {
  double step = 16,
  double strokeWidth = 0.5,
}) {
  final paint = Paint()
    ..color = color
    ..strokeWidth = strokeWidth;

  final path = Path();
  for (double x = step; x < size.width; x += step) {
    path
      ..moveTo(x, 0)
      ..lineTo(x, size.height);
  }
  for (double y = step; y < size.height; y += step) {
    path
      ..moveTo(0, y)
      ..lineTo(size.width, y);
  }
  canvas.drawPath(path, paint);
}

/// 화살촉을 [pos]에 그린다. [dir]은 정규화된 방향 벡터(끝나는 방향).
/// `Offset(-1, 0)` = 왼쪽, `Offset(1, 0)` = 오른쪽, `Offset(0, -1)` = 위.
void drawDiagramArrowhead(
  Canvas canvas,
  Offset pos,
  Offset dir,
  Paint paint, {
  double size = 4,
}) {
  // dir의 수직 벡터로 화살촉 V 모양 두 변을 그린다.
  final perp = Offset(-dir.dy, dir.dx);
  final back = Offset(pos.dx - dir.dx * size, pos.dy - dir.dy * size);
  canvas.drawLine(
    pos,
    Offset(back.dx + perp.dx * size * 0.5, back.dy + perp.dy * size * 0.5),
    paint,
  );
  canvas.drawLine(
    pos,
    Offset(back.dx - perp.dx * size * 0.5, back.dy - perp.dy * size * 0.5),
    paint,
  );
}

/// 점선을 그린다. 치수선·보조선용.
void drawDiagramDashedLine(
  Canvas canvas,
  Offset from,
  Offset to,
  Paint paint, {
  double dash = 3,
  double gap = 2.5,
}) {
  final dx = to.dx - from.dx;
  final dy = to.dy - from.dy;
  final len = sqrt(dx * dx + dy * dy);
  if (len < 0.1) return;
  final ux = dx / len;
  final uy = dy / len;
  double d = 0;
  bool drawing = true;
  while (d < len) {
    final seg = drawing ? dash : gap;
    final end = (d + seg).clamp(0.0, len);
    if (drawing) {
      canvas.drawLine(
        Offset(from.dx + ux * d, from.dy + uy * d),
        Offset(from.dx + ux * end, from.dy + uy * end),
        paint,
      );
    }
    d += seg;
    drawing = !drawing;
  }
}

/// Technical Drawing 스타일 텍스트(`DM Sans`/`DM Mono` 토글, centered 옵션).
void drawDiagramText(
  Canvas canvas,
  String text,
  Offset anchor,
  Color color,
  double size, {
  bool bold = false,
  bool mono = false,
  bool centered = false,
}) {
  final tp = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        color: color,
        fontSize: size,
        fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
        fontFamily: mono ? 'DM Mono' : 'DM Sans',
        letterSpacing: 0.3,
        height: 1.0,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  final off = centered ? anchor - Offset(tp.width / 2, tp.height / 2) : anchor;
  tp.paint(canvas, off);
}
