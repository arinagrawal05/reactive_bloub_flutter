import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:path_drawing/path_drawing.dart';
import '../engine/mascot_engine.dart';
import 'dart:typed_data';

class MascotPainter extends CustomPainter {
  final BotFrame frame;
  final Color baseColor;

  MascotPainter({
    required this.frame,
    required this.baseColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Engine coordinates are based on a 200x200 bounding box
    final scale = size.width / 200.0;
    
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(scale, scale);
    
    // Draw back dots (if behind body)
    if (frame.dotsBehind) {
      _drawDots(canvas, baseColor);
    }

    // Draw body
    if (frame.bodyAlpha > 0) {
      final bodyPath = parseSvgPathData(frame.bodyPath);
      final bodyPaint = Paint()
        ..color = baseColor.withValues(alpha: frame.bodyAlpha)
        ..style = PaintingStyle.fill;
      canvas.drawPath(bodyPath, bodyPaint);
    }

    // Draw front dots
    if (!frame.dotsBehind) {
      _drawDots(canvas, baseColor);
    }

    // Draw eyes
    for (final eye in frame.eyes) {
      if (eye.alpha <= 0) continue;
      
      canvas.save();
      final matrix = _parseMatrix(eye.matrix);
      canvas.transform(matrix);
      
      final eyePath = parseSvgPathData(eye.d);
      final eyePaint = Paint()
        ..color = Colors.white.withValues(alpha: eye.alpha)
        ..style = PaintingStyle.fill;
      canvas.drawPath(eyePath, eyePaint);
      
      canvas.restore();
    }

    // Draw arcs
    for (final arc in frame.arcs) {
      if (arc.opacity <= 0) continue;
      final arcPath = parseSvgPathData(arc.front);
      
      final colors = arc.grad.stops.map((hexStr) {
        final hexNum = hexStr.replaceAll('#', '');
        return Color(int.parse(hexNum.length == 6 ? 'FF$hexNum' : hexNum, radix: 16)).withValues(alpha: arc.opacity);
      }).toList();

      final shader = ui.Gradient.linear(
        Offset(arc.grad.x1, arc.grad.y1),
        Offset(arc.grad.x2, arc.grad.y2),
        colors,
        [0.0, 0.5, 1.0],
      );

      final arcPaint = Paint()
        ..shader = shader
        ..style = PaintingStyle.stroke
        ..strokeWidth = arc.width
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(arcPath, arcPaint);
    }

    // Draw notif
    if (frame.notif != null) {
      final notifPaint = Paint()
        ..color = const Color(0xFF41D1FF) // Vite blue
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(frame.notif!.x, frame.notif!.y), frame.notif!.r, notifPaint);
    }
    
    if (frame.notch != null && frame.notch!.r > 0) {
      final notchPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(frame.notch!.x, frame.notch!.y), frame.notch!.r, notchPaint);
    }

    canvas.restore();
  }

  void _drawDots(Canvas canvas, Color baseColor) {
    for (final dot in frame.dots) {
      if (dot.opacity <= 0) continue;
      
      Color dotColor = baseColor;
      if (dot.color == 'var(--bot-notif)') {
        dotColor = const Color(0xFF41D1FF); // Vite blue
      }
      
      final paint = Paint()
        ..color = dotColor.withValues(alpha: dot.opacity)
        ..style = PaintingStyle.fill;
        
      if (dot.d != null) {
        canvas.save();
        canvas.translate(dot.x, dot.y);
        canvas.rotate(dot.rot ?? 0);
        final p = parseSvgPathData(dot.d!);
        canvas.drawPath(p, paint);
        canvas.restore();
      } else {
        canvas.drawCircle(Offset(dot.x, dot.y), dot.r, paint);
      }
    }
  }

  // Parse SVG matrix string "matrix(a,b,c,d,e,f)" to Float64List for Canvas.transform
  // Float64List format for 4x4 matrix:
  // [ a, b, 0, 0,
  //   c, d, 0, 0,
  //   0, 0, 1, 0,
  //   e, f, 0, 1 ]
  Float64List _parseMatrix(String matrixStr) {
    final values = matrixStr
        .replaceAll('matrix(', '')
        .replaceAll(')', '')
        .split(',')
        .map((s) => double.tryParse(s.trim()) ?? 0.0)
        .toList();
        
    if (values.length == 6) {
      return Float64List.fromList([
        values[0], values[1], 0, 0,
        values[2], values[3], 0, 0,
        0, 0, 1, 0,
        values[4], values[5], 0, 1,
      ]);
    }
    
    // Identity matrix fallback
    return Float64List.fromList([
      1, 0, 0, 0,
      0, 1, 0, 0,
      0, 0, 1, 0,
      0, 0, 0, 1,
    ]);
  }

  @override
  bool shouldRepaint(covariant MascotPainter oldDelegate) {
    return true; // We animate every frame
  }
}
