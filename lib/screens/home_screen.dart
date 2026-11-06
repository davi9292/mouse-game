// Autor: Davi de Assis Fabricio
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../game/player_level.dart';
import '../models/mission.dart';
import '../models/player.dart';
import '../router/app_router.dart';
import '../services/mounator_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/data_view.dart';
import '../widgets/mission_card.dart';
import '../widgets/mouse_avatar.dart';
import '../widgets/progress_card.dart';
import '../widgets/state_views.dart';

class _HomeData {
  const _HomeData({
    required this.profile,
    required this.missions,
    required this.userMissions,
  });

  final PlayerProfile profile;
  final List<Mission> missions;
  final Map<String, UserMission> userMissions;

  MissionStatus statusOf(Mission mission) {
    final um = userMissions[mission.id];
    return um == null ? MissionStatus.available : um.missionStatus;
  }

  int get completed =>
      missions.where((m) => statusOf(m) == MissionStatus.completed).length;
}

Future<_HomeData> _loadHome() async {
  final results = await (
    MounatorRepository.fetchProfile(),
    MounatorRepository.fetchMissions(),
    MounatorRepository.fetchUserMissions(),
  ).wait;
  return _HomeData(
    profile: results.$1,
    missions: results.$2,
    userMissions: results.$3,
  );
}

/// Central de missões: saudação, progresso, missão em destaque e lista com filtros.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _category; // null = todas
  MissionStatus? _status; // null = todos

  void _open(Mission mission) {
    context.push(AppRoutes.missionDetail(mission.id), extra: mission);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mounator')),
      body: SafeArea(
        child: DataView<_HomeData>(
          loader: _loadHome,
          builder: (context, data) => _buildContent(data),
        ),
      ),
    );
  }

  Widget _buildContent(_HomeData data) {
    final level = PlayerLevel.forScore(data.profile.score);
    final categories = data.missions.map((m) => m.category).toSet().toList();

    final featured = _pickFeatured(data);

    final filtered = data.missions.where((m) {
      if (_category != null && m.category != _category) return false;
      if (_status != null && data.statusOf(m) != _status) return false;
      return true;
    }).toList();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        Row(
          children: [
            MouseAvatar(size: 64, level: level.number, mood: MouseMood.happy),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Olá, ${data.profile.nickname}!',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppColors.ink,
                    ),
                  ),
                  Text(
                    'Pronto para enganar o rato hoje?',
                    style: TextStyle(color: AppColors.ink.withValues(alpha: 0.7)),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ProgressCard(
          score: data.profile.score,
          completedMissions: data.completed,
          totalMissions: data.missions.length,
        ),
        const SizedBox(height: 22),
        const _SectionTitle('Missão em destaque'),
        if (featured == null)
          const EmptyView(
            emoji: '🏆',
            title: 'Você concluiu todas as missões!',
            message: 'O rato está impressionado. Confira o ranking!',
          )
        else
          MissionCard(
            mission: featured,
            status: data.statusOf(featured),
            highlighted: true,
            onTap: () => _open(featured),
          ),
        const SizedBox(height: 22),
        const _SectionTitle('Todas as missões'),
        _FilterRow<String>(
          options: categories,
          selected: _category,
          labelOf: (c) => c,
          onSelected: (value) => setState(() => _category = value),
        ),
        const SizedBox(height: 8),
        _FilterRow<MissionStatus>(
          options: MissionStatus.values,
          selected: _status,
          labelOf: (s) {
            switch (s) {
              case MissionStatus.available:
                return 'Disponíveis';
              case MissionStatus.inProgress:
                return 'Em andamento';
              case MissionStatus.completed:
                return 'Concluídas';
            }
          },
          onSelected: (value) => setState(() => _status = value),
        ),
        const SizedBox(height: 12),
        if (data.missions.isEmpty)
          const EmptyView(
            title: 'Nenhuma missão cadastrada',
            message: 'Rode o arquivo supabase/schema.sql para criar as missões.',
          )
        else if (filtered.isEmpty)
          const EmptyView(
            emoji: '🔍',
            title: 'Nada por aqui',
            message: 'Nenhuma missão combina com esses filtros.',
          )
        else
          for (final mission in filtered) ...[
            MissionCard(
              mission: mission,
              status: data.statusOf(mission),
              onTap: () => _open(mission),
            ),
            const SizedBox(height: 12),
          ],
      ],
    );
  }

  Mission? _pickFeatured(_HomeData data) {
    final pending = data.missions
        .where((m) => data.statusOf(m) != MissionStatus.completed)
        .toList();
    if (pending.isEmpty) return null;
    for (final m in pending) {
      if (m.featured) return m;
    }
    return pending.first;
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w900,
          color: AppColors.ink,
        ),
      ),
    );
  }
}

/// Linha de chips para filtrar. Tocar de novo no chip selecionado remove o filtro.
class _FilterRow<T> extends StatelessWidget {
  const _FilterRow({
    required this.options,
    required this.selected,
    required this.labelOf,
    required this.onSelected,
  });

  final List<T> options;
  final T? selected;
  final String Function(T) labelOf;
  final void Function(T?) onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ChoiceChip(
            label: const Text('Todas'),
            selected: selected == null,
            onSelected: (_) => onSelected(null),
          ),
          for (final option in options) ...[
            const SizedBox(width: 8),
            ChoiceChip(
              label: Text(labelOf(option)),
              selected: selected == option,
              onSelected: (_) => onSelected(selected == option ? null : option),
            ),
          ],
        ],
      ),
    );
  }
}
