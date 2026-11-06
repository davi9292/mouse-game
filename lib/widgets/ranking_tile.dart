// Autor: Davi de Assis Fabricio
import 'package:flutter/material.dart';

import '../models/player.dart';
import '../theme/app_theme.dart';

/// Linha do ranking. Os três primeiros recebem destaque; o usuário logado é marcado.
class RankingTile extends StatelessWidget {
  const RankingTile({super.key, required this.entry, required this.isMe});

  final RankingEntry entry;
  final bool isMe;

  static const _medals = ['🥇', '🥈', '🥉'];
  static const _podiumColors = [
    Color(0xFFFFE08A),
    Color(0xFFE3E6EC),
    Color(0xFFF2C9A0),
  ];

  @override
  Widget build(BuildContext context) {
    final podium = entry.position >= 1 && entry.position <= 3;
    final background = podium ? _podiumColors[entry.position - 1] : Colors.white;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: podium ? 18 : 12),
      decoration: cardDecoration(color: background, radius: 18).copyWith(
        border: isMe ? Border.all(color: AppColors.purple, width: 2.5) : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            child: podium
                ? Text(_medals[entry.position - 1], style: const TextStyle(fontSize: 30))
                : Text(
                    '#${entry.position}',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
          ),
          Expanded(
            child: Text(
              isMe ? '${entry.nickname} (você)' : entry.nickname,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: podium ? 18 : 16,
                fontWeight: podium || isMe ? FontWeight.w900 : FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${entry.score} pts',
            style: TextStyle(
              fontSize: podium ? 18 : 15,
              fontWeight: FontWeight.w900,
              color: AppColors.purple,
            ),
          ),
        ],
      ),
    );
  }
}
