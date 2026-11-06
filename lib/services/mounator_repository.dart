// Autor: Davi de Assis Fabricio
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/achievement.dart';
import '../models/game_data.dart';
import '../models/mission.dart';
import '../models/player.dart';

/// Todas as consultas ao Supabase ficam aqui, fora das telas.
///
/// Leitura: tabelas protegidas por RLS (cada jogador só enxerga o que é seu).
/// Escrita de pontuação: somente pelas funções start_mission / complete_mission,
/// que rodam no servidor. O app nunca altera o score diretamente.
class MounatorRepository {
  static SupabaseClient get _db => Supabase.instance.client;

  static String get _uid {
    final user = _db.auth.currentUser;
    if (user == null) throw Exception('Você precisa estar logado.');
    return user.id;
  }

  // ---------- perfil ----------

  static Future<PlayerProfile> fetchProfile() async {
    final row = await _db.from('profiles').select().eq('id', _uid).single();
    return PlayerProfile.fromMap(row);
  }

  static Future<void> updateNickname(String nickname) async {
    await _db.from('profiles').update({'nickname': nickname}).eq('id', _uid);
  }

  // ---------- missões ----------

  static Future<List<Mission>> fetchMissions() async {
    final rows = await _db.from('missions').select().order('sort_order');
    return rows.map<Mission>((r) => Mission.fromMap(r)).toList();
  }

  static Future<Mission> fetchMission(String id) async {
    final row = await _db.from('missions').select().eq('id', id).single();
    return Mission.fromMap(row);
  }

  /// Missões iniciadas/concluídas pelo usuário logado, indexadas pelo id da missão.
  static Future<Map<String, UserMission>> fetchUserMissions() async {
    final rows = await _db.from('user_missions').select().eq('user_id', _uid);
    return {
      for (final r in rows)
        r['mission_id'] as String: UserMission.fromMap(r),
    };
  }

  static Future<void> startMission(String missionId) async {
    await _db.rpc('start_mission', params: {'p_mission_id': missionId});
  }

  static Future<CompletionResult> completeMission(
    String missionId, {
    required bool stumped,
  }) async {
    final result = await _db.rpc(
      'complete_mission',
      params: {'p_mission_id': missionId, 'p_stumped': stumped},
    );
    return CompletionResult.fromMap(Map<String, dynamic>.from(result as Map));
  }

  // ---------- conquistas ----------

  static Future<List<Achievement>> fetchAchievements() async {
    final all = await _db.from('achievements').select().order('condition_value');
    final mine = await _db
        .from('user_achievements')
        .select('achievement_id, unlocked_at')
        .eq('user_id', _uid);

    final unlockedAt = <String, DateTime>{
      for (final r in mine)
        r['achievement_id'] as String: DateTime.parse(r['unlocked_at'] as String),
    };

    final list = all
        .map<Achievement>(
          (r) => Achievement.fromMap(r, unlockedAt: unlockedAt[r['id'] as String]),
        )
        .toList();

    // Desbloqueadas primeiro.
    list.sort((a, b) {
      if (a.unlocked == b.unlocked) return 0;
      return a.unlocked ? -1 : 1;
    });
    return list;
  }

  // ---------- ranking ----------

  /// Top 20 + a linha do usuário logado (calculado no banco pela função get_ranking).
  static Future<List<RankingEntry>> fetchRanking() async {
    final result = await _db.rpc('get_ranking', params: {'p_limit': 20});
    return (result as List)
        .map((r) => RankingEntry.fromMap(Map<String, dynamic>.from(r as Map)))
        .toList();
  }

  // ---------- dados do jogo ----------

  static Future<GameData> fetchGameData(String category) async {
    final characters = await _db.from('characters').select().eq('category', category);
    final questions = await _db.from('questions').select().eq('category', category);
    return GameData(
      characters: characters.map<Character>((r) => Character.fromMap(r)).toList(),
      questions: questions.map<Question>((r) => Question.fromMap(r)).toList(),
    );
  }
}
