// Autor: Davi de Assis Fabricio
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum MissionStatus { available, inProgress, completed }

class Mission {
  const Mission({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.difficulty,
    required this.points,
    required this.instructions,
    required this.icon,
    required this.maxQuestions,
    required this.featured,
    required this.sortOrder,
  });

  final String id;
  final String title;
  final String description;
  final String category;
  final String difficulty; // facil | medio | dificil
  final int points;
  final String instructions;
  final String icon;
  final int maxQuestions;
  final bool featured;
  final int sortOrder;

  factory Mission.fromMap(Map<String, dynamic> map) {
    return Mission(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      category: map['category'] as String,
      difficulty: map['difficulty'] as String,
      points: (map['points'] as num).toInt(),
      instructions: (map['instructions'] as String?) ?? '',
      icon: (map['icon'] as String?) ?? '🐭',
      maxQuestions: (map['max_questions'] as num).toInt(),
      featured: (map['featured'] as bool?) ?? false,
      sortOrder: (map['sort_order'] as num?)?.toInt() ?? 0,
    );
  }

  String get difficultyLabel {
    switch (difficulty) {
      case 'facil':
        return 'Fácil';
      case 'medio':
        return 'Médio';
      default:
        return 'Difícil';
    }
  }

  Color get difficultyColor {
    switch (difficulty) {
      case 'facil':
        return AppColors.success;
      case 'medio':
        return AppColors.warning;
      default:
        return AppColors.danger;
    }
  }

  /// Instruções separadas em linhas (uma por passo).
  List<String> get steps => instructions
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList();

  /// Como o rato chama o que o jogador deve imaginar.
  String get thinkOf {
    switch (category) {
      case 'Animais':
        return 'um animal';
      case 'Comidas':
        return 'uma comida';
      case 'Objetos':
        return 'um objeto';
      case 'Profissões':
        return 'uma profissão';
      default:
        return 'algo';
    }
  }
}

/// Registro de uma missão iniciada ou concluída pelo usuário (tabela user_missions).
class UserMission {
  const UserMission({
    required this.missionId,
    required this.status,
    required this.stumped,
    required this.pointsEarned,
    this.completedAt,
  });

  final String missionId;
  final String status; // in_progress | completed
  final bool stumped;
  final int pointsEarned;
  final DateTime? completedAt;

  factory UserMission.fromMap(Map<String, dynamic> map) {
    final completed = map['completed_at'] as String?;
    return UserMission(
      missionId: map['mission_id'] as String,
      status: map['status'] as String,
      stumped: (map['stumped'] as bool?) ?? false,
      pointsEarned: (map['points_earned'] as num?)?.toInt() ?? 0,
      completedAt: completed == null ? null : DateTime.parse(completed),
    );
  }

  MissionStatus get missionStatus => status == 'completed'
      ? MissionStatus.completed
      : MissionStatus.inProgress;
}

class UnlockedAchievement {
  const UnlockedAchievement({
    required this.name,
    required this.icon,
    required this.description,
  });

  final String name;
  final String icon;
  final String description;

  factory UnlockedAchievement.fromMap(Map<String, dynamic> map) {
    return UnlockedAchievement(
      name: map['name'] as String,
      icon: map['icon'] as String,
      description: map['description'] as String,
    );
  }
}

/// Resposta da função complete_mission do banco.
class CompletionResult {
  const CompletionResult({
    required this.points,
    required this.bonus,
    required this.alreadyCompleted,
    required this.newAchievements,
  });

  final int points;
  final int bonus;
  final bool alreadyCompleted;
  final List<UnlockedAchievement> newAchievements;

  factory CompletionResult.fromMap(Map<String, dynamic> map) {
    final list = (map['new_achievements'] as List?) ?? const [];
    return CompletionResult(
      points: (map['points'] as num?)?.toInt() ?? 0,
      bonus: (map['bonus'] as num?)?.toInt() ?? 0,
      alreadyCompleted: (map['already_completed'] as bool?) ?? false,
      newAchievements: list
          .map((e) => UnlockedAchievement.fromMap(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
