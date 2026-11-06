// Autor: Davi de Assis Fabricio
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../game/mounator_engine.dart';
import '../models/game_data.dart';
import '../models/mission.dart';
import '../router/app_router.dart';
import '../services/app_events.dart';
import '../services/errors.dart';
import '../services/mounator_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/achievement_badge.dart';
import '../widgets/mouse_avatar.dart';
import '../widgets/speech_bubble.dart';
import '../widgets/state_views.dart';

enum _Phase { loading, error, intro, asking, guessing, finishing, result }

/// A rodada: o rato faz perguntas, dá palpites e, no fim, a missão é registrada.
class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.missionId, this.initialMission});

  final String missionId;
  final Mission? initialMission;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  _Phase _phase = _Phase.loading;
  String? _error;

  Mission? _mission;
  GameData? _data;
  MounatorEngine? _engine;

  Question? _question;
  Character? _guess;

  bool _ratWon = false;
  CompletionResult? _result;
  String? _resultError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _phase = _Phase.loading;
      _error = null;
    });
    try {
      final mission = widget.initialMission ??
          await MounatorRepository.fetchMission(widget.missionId);
      final data = await MounatorRepository.fetchGameData(mission.category);
      if (!mounted) return;
      if (data.characters.isEmpty || data.questions.isEmpty) {
        throw Exception(
          'O rato ainda não conhece nada de ${mission.category}. '
          'Rode o supabase/schema.sql no Supabase.',
        );
      }
      setState(() {
        _mission = mission;
        _data = data;
        _phase = _Phase.intro;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = friendlyError(e);
        _phase = _Phase.error;
      });
    }
  }

  void _start() {
    final mission = _mission!;
    final data = _data!;
    _engine = MounatorEngine(
      characters: data.characters,
      questions: data.questions,
      maxQuestions: mission.maxQuestions,
    );
    _result = null;
    _resultError = null;
    _advance();
  }

  void _advance() {
    final step = _engine!.next();
    switch (step) {
      case AskStep(:final question):
        setState(() {
          _question = question;
          _phase = _Phase.asking;
        });
      case GuessStep(:final character):
        setState(() {
          _guess = character;
          _phase = _Phase.guessing;
        });
      case SurrenderStep():
        _finish(ratWon: false);
    }
  }

  void _answer(AnswerValue value) {
    _engine!.answer(_question!, value);
    _advance();
  }

  void _guessResult({required bool correct}) {
    if (correct) {
      _finish(ratWon: true);
    } else {
      _engine!.rejectGuess(_guess!);
      _advance();
    }
  }

  /// Registra o fim da rodada no banco (função complete_mission).
  Future<void> _finish({required bool ratWon}) async {
    setState(() {
      _ratWon = ratWon;
      _phase = _Phase.finishing;
      _resultError = null;
    });
    CompletionResult? result;
    try {
      await MounatorRepository.startMission(widget.missionId);
      result = await MounatorRepository.completeMission(
        widget.missionId,
        stumped: !ratWon,
      );
      AppEvents.instance.dataChanged();
    } catch (e) {
      _resultError = friendlyError(e);
    }
    if (!mounted) return;
    setState(() {
      _result = result;
      _phase = _Phase.result;
    });
    if (result != null && result.newAchievements.isNotEmpty) {
      await showAchievementDialog(context, result.newAchievements);
    }
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
        title: Text(_mission?.title ?? 'Mounator'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _back,
        ),
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    switch (_phase) {
      case _Phase.loading:
        return const LoadingView(message: 'O rato está afiando os dentes...');
      case _Phase.error:
        return ErrorView(message: _error ?? 'Erro inesperado.', onRetry: _load);
      case _Phase.intro:
        return _buildIntro();
      case _Phase.asking:
        return _buildAsking();
      case _Phase.guessing:
        return _buildGuessing();
      case _Phase.finishing:
        return const LoadingView(message: 'Registrando o resultado...');
      case _Phase.result:
        return _buildResult();
    }
  }

  Widget _page({required List<Widget> children}) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    );
  }

  Widget _buildIntro() {
    final mission = _mission!;
    return _page(
      children: [
        const Center(child: MouseAvatar(size: 170, mood: MouseMood.thinking, level: 3)),
        SpeechBubble(text: 'Pense em ${mission.thinkOf}...\nEu vou tentar descobrir!'),
        const SizedBox(height: 16),
        Text(
          'Até ${mission.maxQuestions} perguntas · 3 palpites\n'
          'Responda com sinceridade e sem contar para ninguém 🤫',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.ink.withValues(alpha: 0.75)),
        ),
        const SizedBox(height: 24),
        FilledButton(onPressed: _start, child: const Text('Já pensei! Pode perguntar')),
      ],
    );
  }

  Widget _buildAsking() {
    final engine = _engine!;
    final mission = _mission!;
    final number = engine.questionsAsked + 1;
    return _page(
      children: [
        Text(
          'Pergunta $number de ${mission.maxQuestions}',
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.purple),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: engine.questionsAsked / mission.maxQuestions,
            minHeight: 8,
            backgroundColor: AppColors.cheeseLight,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.cheese),
          ),
        ),
        const SizedBox(height: 14),
        const Center(child: MouseAvatar(size: 130, mood: MouseMood.thinking, level: 3)),
        SpeechBubble(text: _question!.text),
        const SizedBox(height: 18),
        for (final option in AnswerValue.values) ...[
          _AnswerButton(
            label: option.label,
            highlight: option == AnswerValue.yes || option == AnswerValue.no,
            onPressed: () => _answer(option),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _buildGuessing() {
    final guess = _guess!;
    return _page(
      children: [
        const Center(child: MouseAvatar(size: 130, mood: MouseMood.surprised, level: 3)),
        const SpeechBubble(text: 'Já sei! Você está pensando em...'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 22),
          decoration: cardDecoration(color: AppColors.cheeseLight),
          child: Column(
            children: [
              Text(guess.emoji, style: const TextStyle(fontSize: 64)),
              const SizedBox(height: 6),
              Text(
                guess.name,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: () => _guessResult(correct: true),
          child: const Text('Acertou, rato! 🧀'),
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          onPressed: () => _guessResult(correct: false),
          child: const Text('Errou! 🙈'),
        ),
      ],
    );
  }

  Widget _buildResult() {
    final result = _result;
    final won = _ratWon;
    final guess = _guess;

    final String title;
    final String subtitle;
    if (won) {
      title = 'O rato acertou!';
      subtitle = guess == null
          ? 'Ele é esperto mesmo.'
          : 'Era ${guess.emoji} ${guess.name}. Ele é esperto mesmo!';
    } else {
      title = 'Você enganou o rato!';
      subtitle = 'Ele não faz ideia do que você pensou. Bigode torcido de raiva!';
    }

    return _page(
      children: [
        Center(
          child: MouseAvatar(
            size: 160,
            mood: won ? MouseMood.happy : MouseMood.sad,
            level: 3,
          ),
        ),
        SpeechBubble(text: title, fontSize: 24),
        const SizedBox(height: 10),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.ink.withValues(alpha: 0.8), fontSize: 15),
        ),
        const SizedBox(height: 18),
        if (_resultError != null) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: cardDecoration(),
            child: Column(
              children: [
                Text(
                  'Não consegui registrar sua pontuação: $_resultError',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.danger),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () => _finish(ratWon: _ratWon),
                  child: const Text('Tentar registrar de novo'),
                ),
              ],
            ),
          ),
        ] else if (result != null)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: cardDecoration(color: AppColors.purple),
            child: Column(
              children: [
                Text(
                  result.alreadyCompleted ? 'Sem pontos desta vez' : '+${result.points} pontos',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  result.alreadyCompleted
                      ? 'Você já tinha concluído esta missão antes.'
                      : result.bonus > 0
                          ? 'Inclui ${result.bonus} pts de bônus por enganar o rato 🎭'
                          : 'Missão concluída! Tente enganar o rato na próxima.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.cheeseLight),
                ),
              ],
            ),
          ),
        const SizedBox(height: 22),
        FilledButton(
          onPressed: () => context.go(AppRoutes.home),
          child: const Text('Ver missões'),
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          onPressed: () => context.go(AppRoutes.ranking),
          child: const Text('Ver ranking'),
        ),
        const SizedBox(height: 10),
        TextButton(onPressed: _start, child: const Text('Jogar de novo (sem pontos)')),
      ],
    );
  }
}

class _AnswerButton extends StatelessWidget {
  const _AnswerButton({
    required this.label,
    required this.onPressed,
    this.highlight = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    if (highlight) {
      return FilledButton(onPressed: onPressed, child: Text(label));
    }
    return FilledButton.tonal(
      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(46)),
      onPressed: onPressed,
      child: Text(label),
    );
  }
}
