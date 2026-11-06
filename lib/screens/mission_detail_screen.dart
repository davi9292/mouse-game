// Autor: Davi de Assis Fabricio
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/mission.dart';
import '../router/app_router.dart';
import '../services/app_events.dart';
import '../services/errors.dart';
import '../services/mounator_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/data_view.dart';
import '../widgets/mission_card.dart';

class _DetailData {
  const _DetailData({required this.mission, this.userMission});

  final Mission mission;
  final UserMission? userMission;

  MissionStatus get status =>
      userMission == null ? MissionStatus.available : userMission!.missionStatus;
}

/// Detalhes de uma missão: descrição, orientações, pontuação, status e botão de jogar.
class MissionDetailScreen extends StatefulWidget {
  const MissionDetailScreen({
    super.key,
    required this.missionId,
    this.initialMission,
  });

  final String missionId;
  final Mission? initialMission;

  @override
  State<MissionDetailScreen> createState() => _MissionDetailScreenState();
}

class _MissionDetailScreenState extends State<MissionDetailScreen> {
  bool _busy = false;

  Future<_DetailData> _load() async {
    final mission = widget.initialMission ??
        await MounatorRepository.fetchMission(widget.missionId);
    final userMissions = await MounatorRepository.fetchUserMissions();
    return _DetailData(mission: mission, userMission: userMissions[mission.id]);
  }

  Future<void> _play(Mission mission) async {
    setState(() => _busy = true);
    try {
      await MounatorRepository.startMission(mission.id);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyError(e))),
      );
      return;
    }
    if (!mounted) return;
    setState(() => _busy = false);
    await context.push(AppRoutes.missionPlay(mission.id), extra: mission);
    // Ao voltar do jogo, atualiza o status mostrado nas telas.
    AppEvents.instance.dataChanged();
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes da missão'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _back,
        ),
      ),
      body: SafeArea(
        child: DataView<_DetailData>(
          loader: _load,
          builder: (context, data) => _buildContent(data),
        ),
      ),
    );
  }

  Widget _buildContent(_DetailData data) {
    final mission = data.mission;
    final status = data.status;
    final um = data.userMission;

    final String buttonLabel;
    switch (status) {
      case MissionStatus.available:
        buttonLabel = 'Iniciar desafio';
      case MissionStatus.inProgress:
        buttonLabel = 'Continuar desafio';
      case MissionStatus.completed:
        buttonLabel = 'Jogar de novo (sem pontos)';
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: cardDecoration(),
          child: Column(
            children: [
              Container(
                width: 84,
                height: 84,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.cheeseLight,
                ),
                child: Text(mission.icon, style: const TextStyle(fontSize: 44)),
              ),
              const SizedBox(height: 14),
              Text(
                mission.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  _InfoChip(label: mission.category, color: AppColors.purple),
                  _InfoChip(
                    label: mission.difficultyLabel,
                    color: mission.difficultyColor,
                  ),
                  _InfoChip(
                    label: '⭐ ${mission.points} pts',
                    color: const Color(0xFFB26A00),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              MissionStatusBadge(status: status),
              if (status == MissionStatus.completed && um != null) ...[
                const SizedBox(height: 10),
                Text(
                  um.stumped
                      ? 'Você enganou o rato e ganhou ${um.pointsEarned} pontos! 🎭'
                      : 'O rato acertou, mas você ganhou ${um.pointsEarned} pontos.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.success,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 18),
        _Section(
          title: 'Sobre o desafio',
          child: Text(
            mission.description,
            style: const TextStyle(fontSize: 15, height: 1.4, color: AppColors.ink),
          ),
        ),
        const SizedBox(height: 14),
        _Section(
          title: 'Orientações',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < mission.steps.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: AppColors.purple,
                        child: Text(
                          '${i + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          mission.steps[i],
                          style: const TextStyle(fontSize: 15, height: 1.35),
                        ),
                      ),
                    ],
                  ),
                ),
              Text(
                'O rato faz até ${mission.maxQuestions} perguntas e pode dar até 3 palpites. '
                'Se ele errar tudo, você ganha 50% de bônus!',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.ink.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        FilledButton.icon(
          onPressed: _busy ? null : () => _play(mission),
          icon: _busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                )
              : Icon(status == MissionStatus.completed ? Icons.replay : Icons.play_arrow),
          label: Text(buttonLabel),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 13),
      ),
    );
  }
}
