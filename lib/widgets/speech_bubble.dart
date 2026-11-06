// Autor: Davi de Assis Fabricio
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Balão de fala do rato (a "ponta" aponta para cima, para o avatar).
class SpeechBubble extends StatelessWidget {
  const SpeechBubble({super.key, required this.text, this.fontSize = 20});

  final String text;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Transform.translate(
          offset: const Offset(0, 9),
          child: Transform.rotate(
            angle: math.pi / 4,
            child: Container(width: 18, height: 18, color: Colors.white),
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: cardDecoration(),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
              height: 1.25,
            ),
          ),
        ),
      ],
    );
  }
}
