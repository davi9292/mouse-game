// Autor: Davi de Assis Fabricio
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum MouseMood { neutral, thinking, happy, sad, surprised }

/// O rato do Mounator, desenhado com CustomPaint.
/// [level] controla os acessórios: 2 = óculos, 3 = chapéu de detetive, 4+ = coroa.
class MouseAvatar extends StatelessWidget {
  const MouseAvatar({
    super.key,
    this.size = 120,
    this.mood = MouseMood.neutral,
    this.level = 1,
  });

  final double size;
  final MouseMood mood;
  final int level;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _MousePainter(mood: mood, level: level)),
    );
  }
}

class _MousePainter extends CustomPainter {
  _MousePainter({required this.mood, required this.level});

  final MouseMood mood;
  final int level;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    Offset p(double x, double y) => Offset(x * s, y * s);

    final grey = Paint()..color = AppColors.mouse;
    final pink = Paint()..color = const Color(0xFFFF9EB5);
    final dark = Paint()..color = AppColors.ink;
    final white = Paint()..color = Colors.white;
    final stroke = Paint()
      ..color = AppColors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.018
      ..strokeCap = StrokeCap.round;

    // orelhas
    canvas.drawCircle(p(0.22, 0.28), s * 0.19, grey);
    canvas.drawCircle(p(0.22, 0.28), s * 0.11, pink);
    canvas.drawCircle(p(0.78, 0.28), s * 0.19, grey);
    canvas.drawCircle(p(0.78, 0.28), s * 0.11, pink);

    // cabeça
    canvas.drawOval(
      Rect.fromCenter(center: p(0.5, 0.58), width: s * 0.74, height: s * 0.66),
      grey,
    );

    // olhos
    final leftEye = p(0.37, 0.52);
    final rightEye = p(0.63, 0.52);
    switch (mood) {
      case MouseMood.happy:
        for (final eye in [leftEye, rightEye]) {
          canvas.drawArc(
            Rect.fromCenter(center: eye, width: s * 0.1, height: s * 0.08),
            math.pi,
            math.pi,
            false,
            stroke,
          );
        }
      case MouseMood.surprised:
        for (final eye in [leftEye, rightEye]) {
          canvas.drawCircle(eye, s * 0.06, white);
          canvas.drawCircle(eye, s * 0.06, stroke);
          canvas.drawCircle(eye, s * 0.03, dark);
        }
      case MouseMood.sad:
        canvas.drawCircle(leftEye, s * 0.045, dark);
        canvas.drawCircle(rightEye, s * 0.045, dark);
        canvas.drawLine(p(0.30, 0.43), p(0.43, 0.47), stroke);
        canvas.drawLine(p(0.70, 0.43), p(0.57, 0.47), stroke);
      case MouseMood.thinking:
        canvas.drawCircle(leftEye, s * 0.045, dark);
        canvas.drawCircle(rightEye, s * 0.045, dark);
        canvas.drawLine(p(0.58, 0.43), p(0.69, 0.40), stroke);
      case MouseMood.neutral:
        canvas.drawCircle(leftEye, s * 0.045, dark);
        canvas.drawCircle(rightEye, s * 0.045, dark);
    }
    if (mood != MouseMood.happy && mood != MouseMood.surprised) {
      canvas.drawCircle(p(0.385, 0.505), s * 0.013, white);
      canvas.drawCircle(p(0.645, 0.505), s * 0.013, white);
    }

    // focinho
    canvas.drawCircle(p(0.5, 0.64), s * 0.04, pink);

    // boca
    switch (mood) {
      case MouseMood.happy:
        canvas.drawArc(
          Rect.fromCenter(center: p(0.5, 0.71), width: s * 0.2, height: s * 0.14),
          0,
          math.pi,
          false,
          stroke,
        );
      case MouseMood.sad:
        canvas.drawArc(
          Rect.fromCenter(center: p(0.5, 0.79), width: s * 0.16, height: s * 0.1),
          math.pi,
          math.pi,
          false,
          stroke,
        );
      case MouseMood.surprised:
        canvas.drawOval(
          Rect.fromCenter(center: p(0.5, 0.76), width: s * 0.07, height: s * 0.09),
          dark,
        );
      case MouseMood.thinking:
        canvas.drawLine(p(0.46, 0.74), p(0.56, 0.72), stroke);
      case MouseMood.neutral:
        canvas.drawLine(p(0.45, 0.73), p(0.55, 0.73), stroke);
    }

    // bigodes
    for (final side in [1.0, -1.0]) {
      double x(double v) => side > 0 ? v : 1 - v;
      canvas.drawLine(p(x(0.36), 0.67), p(x(0.10), 0.62), stroke);
      canvas.drawLine(p(x(0.36), 0.70), p(x(0.08), 0.70), stroke);
      canvas.drawLine(p(x(0.36), 0.73), p(x(0.12), 0.79), stroke);
    }

    // acessórios por nível
    if (level >= 2) {
      final glasses = Paint()
        ..color = AppColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.016;
      canvas.drawCircle(leftEye, s * 0.085, glasses);
      canvas.drawCircle(rightEye, s * 0.085, glasses);
      canvas.drawLine(p(0.455, 0.52), p(0.545, 0.52), glasses);
    }
    if (level == 3) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(s * 0.32, s * 0.06, s * 0.68, s * 0.27),
          Radius.circular(s * 0.05),
        ),
        Paint()..color = const Color(0xFF6B4F3A),
      );
      canvas.drawRect(
        Rect.fromLTRB(s * 0.32, s * 0.19, s * 0.68, s * 0.22),
        Paint()..color = AppColors.cheese,
      );
      canvas.drawOval(
        Rect.fromCenter(center: p(0.5, 0.27), width: s * 0.62, height: s * 0.07),
        Paint()..color = const Color(0xFF4E3828),
      );
    } else if (level >= 4) {
      final crown = Path()
        ..moveTo(s * 0.30, s * 0.29)
        ..lineTo(s * 0.30, s * 0.12)
        ..lineTo(s * 0.40, s * 0.21)
        ..lineTo(s * 0.50, s * 0.08)
        ..lineTo(s * 0.60, s * 0.21)
        ..lineTo(s * 0.70, s * 0.12)
        ..lineTo(s * 0.70, s * 0.29)
        ..close();
      canvas.drawPath(crown, Paint()..color = AppColors.cheese);
      canvas.drawPath(
        crown,
        Paint()
          ..color = const Color(0xFFC98A00)
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.012,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MousePainter old) =>
      old.mood != mood || old.level != level;
}

/// Logotipo do app: o rato dentro de uma rodela de queijo.
class MounatorLogo extends StatelessWidget {
  const MounatorLogo({super.key, this.size = 160});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFD35C), AppColors.cheese],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          _hole(size * 0.14, size * 0.12, size * 0.08),
          _hole(size * 0.74, size * 0.20, size * 0.06),
          _hole(size * 0.80, size * 0.62, size * 0.09),
          _hole(size * 0.10, size * 0.66, size * 0.06),
          MouseAvatar(size: size * 0.78, mood: MouseMood.happy, level: 3),
        ],
      ),
    );
  }

  Widget _hole(double left, double top, double diameter) {
    return Positioned(
      left: left,
      top: top,
      child: Container(
        width: diameter,
        height: diameter,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0x33B26A00),
        ),
      ),
    );
  }
}
