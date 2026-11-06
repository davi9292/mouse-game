// Autor: Davi de Assis Fabricio

/// Algo que o jogador pode estar pensando (o rato tenta adivinhar).
class Character {
  const Character({
    required this.id,
    required this.category,
    required this.name,
    required this.emoji,
    required this.traits,
  });

  final String id;
  final String category;
  final String name;
  final String emoji;

  /// Características verdadeiras deste personagem.
  final Set<String> traits;

  factory Character.fromMap(Map<String, dynamic> map) {
    final raw = (map['traits'] as List?) ?? const [];
    return Character(
      id: map['id'] as String,
      category: map['category'] as String,
      name: map['name'] as String,
      emoji: map['emoji'] as String,
      traits: raw.map((e) => e.toString()).toSet(),
    );
  }
}

/// Pergunta que o rato faz. Cada pergunta testa uma característica ("trait").
class Question {
  const Question({
    required this.id,
    required this.category,
    required this.trait,
    required this.text,
  });

  final String id;
  final String category;
  final String trait;
  final String text;

  factory Question.fromMap(Map<String, dynamic> map) {
    return Question(
      id: map['id'] as String,
      category: map['category'] as String,
      trait: map['trait'] as String,
      text: map['question_text'] as String,
    );
  }
}

class GameData {
  const GameData({required this.characters, required this.questions});

  final List<Character> characters;
  final List<Question> questions;
}
