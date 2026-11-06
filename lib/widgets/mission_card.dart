// Autor: Davi de Assis Fabricio
import 'package:flutter/material.dart';

import '../models/mission.dart';
import '../theme/app_theme.dart';

/// Selo com o status da missão: disponível, em andamento ou concluída.
class MissionStatusBadge extends StatelessWidget {
  const MissionStatusBadge({super.key, required this.status});

  final MissionStatus status;

  @override
  Widget build(BuildContext context) {
    final String label;
    final IconData icon;
    final Color color;
    switch (status) {
      case MissionStatus.completed:
        label = 'Concluída';
        icon = Icons.check_circle;
        color = AppColors.success;
      case MissionStatus.inProgress:
        label = 'Em andamento';
        icon = Icons.timelapse;
        color = AppColors.warning;
      case MissionStatus.available:
        label = 'Disponível';
        icon = Icons.radio_button_unchecked;
        color = AppColors.purple;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// Cartão de apresentação de uma missão (usado na Home).
class MissionCard extends StatelessWidget {
  const MissionCard({
    super.key,
    required this.mission,
    required this.status,
    required this.onTap,
    this.highlighted = false,
  });

  final Mission mission;
  final MissionStatus status;
  final VoidCallback onTap;

  /// Versão grande, em destaque (missão em destaque da Home).
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final fg = highlighted ? Colors.white : AppColors.ink;
    return Material(
      color: highlighted ? AppColors.purple : Colors.white,
      borderRadius: BorderRadius.circular(22),
      elevation: 2,
      shadowColor: Colors.black26,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: highlighted ? 64 : 56,
                height: highlighted ? 64 : 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: highlighted ? AppColors.cheese : AppColors.cheeseLight,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  mission.icon,
                  style: TextStyle(fontSize: highlighted ? 34 : 28),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mission.title,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: fg,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      mission.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: fg.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _Tag(label: mission.category, color: AppColors.purple),
                        _Tag(
                          label: mission.difficultyLabel,
                          color: mission.difficultyColor,
                        ),
                        _Tag(
                          label: '⭐ ${mission.points} pts',
                          color: const Color(0xFFB26A00),
                        ),
                        MissionStatusBadge(status: status),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: color.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}
