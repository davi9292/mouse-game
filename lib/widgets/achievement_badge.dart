// Autor: Davi de Assis Fabricio
import 'package:flutter/material.dart';

import '../models/achievement.dart';
import '../models/mission.dart';
import '../theme/app_theme.dart';

String _formatDate(DateTime date) {
  final d = date.toLocal();
  final day = d.day.toString().padLeft(2, '0');
  final month = d.month.toString().padLeft(2, '0');
  return '$day/$month/${d.year}';
}

/// Cartão de uma conquista. Conquistas ainda não alcançadas aparecem bloqueadas.
class AchievementBadge extends StatelessWidget {
  const AchievementBadge({super.key, required this.achievement});

  final Achievement achievement;

  @override
  Widget build(BuildContext context) {
    final unlocked = achievement.unlocked;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: cardDecoration(
        color: unlocked ? Colors.white : const Color(0xFFEFEBE0),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: unlocked ? AppColors.cheeseLight : AppColors.mouse.withValues(alpha: 0.4),
              border: Border.all(
                color: unlocked ? AppColors.cheese : AppColors.mouse,
                width: 3,
              ),
            ),
            child: unlocked
                ? Text(achievement.icon, style: const TextStyle(fontSize: 30))
                : const Icon(Icons.lock, color: AppColors.ink, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: unlocked ? AppColors.ink : AppColors.ink.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  achievement.description,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.ink.withValues(alpha: unlocked ? 0.75 : 0.55),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  unlocked && achievement.unlockedAt != null
                      ? '✅ Desbloqueada em ${_formatDate(achievement.unlockedAt!)}'
                      : '🔒 Bloqueada',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: unlocked ? AppColors.success : AppColors.ink.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Diálogo animado mostrado quando uma conquista é desbloqueada.
Future<void> showAchievementDialog(
  BuildContext context,
  List<UnlockedAchievement> items,
) {
  return showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          '🎉 Conquista desbloqueada!',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final item in items)
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.elasticOut,
                  builder: (context, value, child) =>
                      Transform.scale(scale: value, child: child),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      children: [
                        Text(item.icon, style: const TextStyle(fontSize: 56)),
                        Text(
                          item.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(item.description, textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Uhul!'),
          ),
        ],
      );
    },
  );
}
