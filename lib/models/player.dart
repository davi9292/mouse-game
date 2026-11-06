// Autor: Davi de Assis Fabricio

class PlayerProfile {
  const PlayerProfile({
    required this.id,
    required this.nickname,
    required this.score,
  });

  final String id;
  final String nickname;
  final int score;

  factory PlayerProfile.fromMap(Map<String, dynamic> map) {
    return PlayerProfile(
      id: map['id'] as String,
      nickname: map['nickname'] as String,
      score: (map['score'] as num).toInt(),
    );
  }
}

class RankingEntry {
  const RankingEntry({
    required this.position,
    required this.userId,
    required this.nickname,
    required this.score,
  });

  final int position;
  final String userId;
  final String nickname;
  final int score;

  factory RankingEntry.fromMap(Map<String, dynamic> map) {
    return RankingEntry(
      position: (map['rank_position'] as num).toInt(),
      userId: map['user_id'] as String,
      nickname: map['nickname'] as String,
      score: (map['score'] as num).toInt(),
    );
  }
}
