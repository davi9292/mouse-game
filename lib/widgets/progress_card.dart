// Autor: Davi de Assis Fabricio
import 'package:flutter/material.dart';

import '../game/player_level.dart';
import '../theme/app_theme.dart';

/// Cartão de pontuação e progresso do jogador (Home e Perfil).
class ProgressCard extends StatelessWidget {
  const ProgressCard({
    super.key,
    required this.score,
    required this.completedMissions,
    required this.totalMissions,
  });

  final int score;
  final int completedMissions;
  final int totalMissions;

  @override
  Widget build(BuildContext context) {
    final level = PlayerLevel.forScore(score);
    final next = level.next;
    final missionsProgress =
        totalMissions == 0 ? 0.0 : completedMissions / totalMissions;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.purple, AppColors.purpleDark],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '⭐ $score pontos',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Nível ${level.number} · ${level.name}',
                      style: const TextStyle(
                        color: AppColors.cheeseLight,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _Bar(value: level.progress(score), color: AppColors.cheese),
          const SizedBox(height: 6),
          Text(
            next == null
                ? 'Nível máximo alcançado! 👑'
                : 'Faltam ${level.pointsToNext(score)} pts para ${next.name}',
            style: const TextStyle(color: Colors.white70, fontSize: 12.5),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Missões concluídas',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              ),
              Text(
                '$completedMissions / $totalMissions',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _Bar(value: missionsProgress, color: const Color(0xFF6EE7A8)),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.value, required this.color});

  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: LinearProgressIndicator(
        value: value,
        minHeight: 10,
        backgroundColor: Colors.white24,
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }
}
