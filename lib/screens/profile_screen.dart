// Autor: Davi de Assis Fabricio
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../game/player_level.dart';
import '../models/mission.dart';
import '../models/player.dart';
import '../router/app_router.dart';
import '../services/app_events.dart';
import '../services/auth_service.dart';
import '../services/errors.dart';
import '../services/mounator_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/data_view.dart';
import '../widgets/mouse_avatar.dart';
import '../widgets/progress_card.dart';

class _ProfileData {
  const _ProfileData({
    required this.profile,
    required this.completed,
    required this.totalMissions,
    required this.unlocked,
    required this.totalAchievements,
  });

  final PlayerProfile profile;
  final int completed;
  final int totalMissions;
  final int unlocked;
  final int totalAchievements;
}

Future<_ProfileData> _loadProfile() async {
  final results = await (
    MounatorRepository.fetchProfile(),
    MounatorRepository.fetchMissions(),
    MounatorRepository.fetchUserMissions(),
    MounatorRepository.fetchAchievements(),
  ).wait;
  final userMissions = results.$3;
  final achievements = results.$4;
  return _ProfileData(
    profile: results.$1,
    completed: userMissions.values
        .where((u) => u.missionStatus == MissionStatus.completed)
        .length,
    totalMissions: results.$2.length,
    unlocked: achievements.where((a) => a.unlocked).length,
    totalAchievements: achievements.length,
  );
}

/// Perfil do jogador: apelido, e-mail, pontuação, evolução e logout.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _editNickname(BuildContext context, String current) async {
    final controller = TextEditingController(text: current);
    final newName = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Mudar apelido'),
        content: TextField(
          controller: controller,
          maxLength: 24,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Novo apelido'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(100, 44)),
            onPressed: () => Navigator.of(dialogContext).pop(controller.text.trim()),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    if (newName == null || newName.length < 2 || newName == current) return;
    try {
      await MounatorRepository.updateNickname(newName);
      AppEvents.instance.dataChanged();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyError(e))),
      );
    }
  }

  Future<void> _logout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sair da conta?'),
        content: const Text('Seus pontos e conquistas continuam salvos no banco.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(100, 44)),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    await AuthService.signOut();
    if (!context.mounted) return;
    context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final email = AuthService.currentUser?.email ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: SafeArea(
        child: DataView<_ProfileData>(
          loader: _loadProfile,
          builder: (context, data) {
            final level = PlayerLevel.forScore(data.profile.score);
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              children: [
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.cheeseLight,
                    ),
                    child: MouseAvatar(size: 130, level: level.number, mood: MouseMood.happy),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        data.profile.nickname,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Mudar apelido',
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: () => _editNickname(context, data.profile.nickname),
                    ),
                  ],
                ),
                Text(
                  email,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.ink.withValues(alpha: 0.7)),
                ),
                const SizedBox(height: 18),
                ProgressCard(
                  score: data.profile.score,
                  completedMissions: data.completed,
                  totalMissions: data.totalMissions,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _StatBox(
                        emoji: '⭐',
                        value: '${data.profile.score}',
                        label: 'Pontos',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatBox(
                        emoji: '✅',
                        value: '${data.completed}',
                        label: 'Missões',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatBox(
                        emoji: '🏅',
                        value: '${data.unlocked}/${data.totalAchievements}',
                        label: 'Conquistas',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: () => _logout(context),
                  icon: const Icon(Icons.logout),
                  label: const Text('Sair da conta'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({required this.emoji, required this.value, required this.label});

  final String emoji;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: cardDecoration(radius: 18),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.ink,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: AppColors.ink.withValues(alpha: 0.7)),
          ),
        ],
      ),
    );
  }
}
