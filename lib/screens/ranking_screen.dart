// Autor: Davi de Assis Fabricio
import 'package:flutter/material.dart';

import '../models/player.dart';
import '../services/auth_service.dart';
import '../services/mounator_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/data_view.dart';
import '../widgets/ranking_tile.dart';
import '../widgets/state_views.dart';

/// Ranking calculado no banco (função get_ranking), com destaque para o pódio
/// e para a posição do usuário logado.
class RankingScreen extends StatelessWidget {
  const RankingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final myId = AuthService.currentUser?.id;

    return Scaffold(
      appBar: AppBar(title: const Text('Ranking')),
      body: SafeArea(
        child: DataView<List<RankingEntry>>(
          loader: MounatorRepository.fetchRanking,
          builder: (context, entries) {
            if (entries.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 80),
                  EmptyView(
                    emoji: '🐭',
                    title: 'Ranking vazio',
                    message: 'Conclua uma missão para entrar na disputa.',
                  ),
                ],
              );
            }

            RankingEntry? me;
            for (final e in entries) {
              if (e.userId == myId) me = e;
            }

            final children = <Widget>[];
            if (me != null) {
              children.add(
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: cardDecoration(color: AppColors.purple),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Sua posição: #${me.position}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        '${me.score} pts',
                        style: const TextStyle(
                          color: AppColors.cheese,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              );
              children.add(const SizedBox(height: 16));
            }

            int? previous;
            for (final entry in entries) {
              // Se o usuário está fora do top 20, mostra reticências antes dele.
              if (previous != null && entry.position > previous + 1) {
                children.add(
                  const Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child: Text(
                      '⋮',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 22, color: AppColors.ink),
                    ),
                  ),
                );
              }
              children.add(RankingTile(entry: entry, isMe: entry.userId == myId));
              children.add(const SizedBox(height: 10));
              previous = entry.position;
            }

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              children: children,
            );
          },
        ),
      ),
    );
  }
}
