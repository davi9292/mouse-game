// Autor: Davi de Assis Fabricio
import 'dart:math';

import '../models/game_data.dart';

/// Respostas possíveis do jogador, cada uma com um valor entre 0 e 1.
enum AnswerValue {
  yes('Sim', 1.0),
  probablyYes('Provavelmente', 0.75),
  unknown('Não sei', 0.5),
  probablyNo('Provavelmente não', 0.25),
  no('Não', 0.0);

  const AnswerValue(this.label, this.value);

  final String label;
  final double value;
}

/// Próximo passo do rato: perguntar, dar um palpite ou desistir.
sealed class GameStep {
  const GameStep();
}

class AskStep extends GameStep {
  const AskStep(this.question);
  final Question question;
}

class GuessStep extends GameStep {
  const GuessStep(this.character);
  final Character character;
}

class SurrenderStep extends GameStep {
  const SurrenderStep();
}

/// Motor do rato adivinhador.
///
/// Cada personagem começa com peso 1. A cada resposta, o peso de quem
/// "combina" com a resposta se mantém e o de quem "não combina" despenca
/// (mas nunca vai a zero, para tolerar uma resposta errada do jogador).
/// A próxima pergunta é a que mais divide os candidatos ao meio, e o rato
/// só chuta quando está confiante ou quando as perguntas acabam.
class MounatorEngine {
  MounatorEngine({
    required List<Character> characters,
    required List<Question> questions,
    required this.maxQuestions,
    this.maxGuesses = 3,
    Random? random,
  })  : _characters = List<Character>.of(characters),
        _questions = List<Question>.of(questions),
        _weights = {for (final c in characters) c.id: 1.0},
        _random = random ?? Random();

  static const double _confidence = 0.8;
  static const int _minQuestionsBeforeGuess = 3;
  static const double _mismatchFloor = 0.05;

  final List<Character> _characters;
  final List<Question> _questions;
  final Map<String, double> _weights;
  final Random _random;
  final Set<String> _askedTraits = <String>{};

  final int maxQuestions;
  final int maxGuesses;

  int questionsAsked = 0;
  int guessesMade = 0;

  List<Character> get _alive =>
      _characters.where((c) => (_weights[c.id] ?? 0) > 0).toList();

  GameStep next() {
    final alive = _alive;
    if (alive.isEmpty || guessesMade >= maxGuesses) {
      return const SurrenderStep();
    }

    var total = 0.0;
    var top = alive.first;
    for (final c in alive) {
      final w = _weights[c.id] ?? 0;
      total += w;
      if (w > (_weights[top.id] ?? 0)) top = c;
    }
    final share = (_weights[top.id] ?? 0) / total;

    final outOfQuestions = questionsAsked >= maxQuestions;
    final confident =
        questionsAsked >= _minQuestionsBeforeGuess && share >= _confidence;

    if (!outOfQuestions && !confident) {
      final question = _bestQuestion(alive, total);
      if (question != null) return AskStep(question);
    }
    return GuessStep(top);
  }

  void answer(Question question, AnswerValue answer) {
    _askedTraits.add(question.trait);
    questionsAsked++;
    for (final c in _characters) {
      final w = _weights[c.id] ?? 0;
      if (w <= 0) continue;
      final truth = c.traits.contains(question.trait) ? 1.0 : 0.0;
      final likelihood = max(_mismatchFloor, 1 - (truth - answer.value).abs());
      _weights[c.id] = w * likelihood;
    }
  }

  void rejectGuess(Character character) {
    _weights[character.id] = 0;
    guessesMade++;
  }

  Question? _bestQuestion(List<Character> alive, double total) {
    final scored = <MapEntry<Question, double>>[];
    for (final q in _questions) {
      if (_askedTraits.contains(q.trait)) continue;
      var yesMass = 0.0;
      for (final c in alive) {
        if (c.traits.contains(q.trait)) yesMass += _weights[c.id] ?? 0;
      }
      final p = yesMass / total;
      if (p < 0.02 || p > 0.98) continue; // não ajuda a separar ninguém
      scored.add(MapEntry(q, (p - 0.5).abs()));
    }
    if (scored.isEmpty) return null;

    scored.sort((a, b) => a.value.compareTo(b.value));
    final best = scored.first.value;
    // Sorteia entre as melhores para o jogo não ser sempre igual.
    final nearBest = scored.where((e) => e.value <= best + 0.05).toList();
    return nearBest[_random.nextInt(nearBest.length)].key;
  }
}
