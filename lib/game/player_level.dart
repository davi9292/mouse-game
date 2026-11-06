// Autor: Davi de Assis Fabricio

/// Nível do jogador, calculado a partir da pontuação.
/// O avatar do rato ganha acessórios conforme o nível sobe.
class PlayerLevel {
  const PlayerLevel(this.number, this.name, this.minScore);

  final int number;
  final String name;
  final int minScore;

  static const List<PlayerLevel> all = [
    PlayerLevel(1, 'Filhote de Rato', 0),
    PlayerLevel(2, 'Rato Curioso', 100),
    PlayerLevel(3, 'Rato Esperto', 250),
    PlayerLevel(4, 'Rato Detetive', 500),
    PlayerLevel(5, 'Mestre dos Ratos', 1000),
  ];

  static PlayerLevel forScore(int score) {
    var current = all.first;
    for (final level in all) {
      if (score >= level.minScore) current = level;
    }
    return current;
  }

  PlayerLevel? get next {
    final index = all.indexOf(this);
    return index + 1 < all.length ? all[index + 1] : null;
  }

  /// Progresso (0 a 1) dentro do nível atual.
  double progress(int score) {
    final n = next;
    if (n == null) return 1.0;
    final value = (score - minScore) / (n.minScore - minScore);
    return value.clamp(0.0, 1.0).toDouble();
  }

  int pointsToNext(int score) {
    final n = next;
    if (n == null) return 0;
    final missing = n.minScore - score;
    return missing < 0 ? 0 : missing;
  }
}
