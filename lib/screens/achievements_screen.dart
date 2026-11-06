// Autor: Davi de Assis Fabricio
import 'package:flutter/material.dart';

import '../models/achievement.dart';
import '../services/mounator_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/achievement_badge.dart';
import '../widgets/data_view.dart';
import '../widgets/state_views.dart';

/// Lista de conquistas: as desbloqueadas em destaque e as demais bloqueadas.
class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Conquistas')),
      body: SafeArea(
        child: DataView<List<Achievement>>(
          loader: MounatorRepository.fetchAchievements,
          builder: (context, items) {
            if (items.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 80),
                  EmptyView(
                    emoji: '🏅',
                    title: 'Nenhuma conquista cadastrada',
                    message: 'Rode o arquivo supabase/schema.sql para criá-las.',
                  ),
                ],
              );
            }
            final unlocked = items.where((a) => a.unlocked).length;
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: cardDecoration(color: AppColors.cheeseLight),
                  child: Row(
                    children: [
                      const Text('🏆', style: TextStyle(fontSize: 36)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$unlocked de ${items.length} desbloqueadas',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: AppColors.ink,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: unlocked / items.length,
                                minHeight: 8,
                                backgroundColor: Colors.white,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  AppColors.purple,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                for (final item in items) ...[
                  AchievementBadge(achievement: item),
                  const SizedBox(height: 12),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
