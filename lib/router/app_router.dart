// Autor: Davi de Assis Fabricio
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/mission.dart';
import '../screens/achievements_screen.dart';
import '../screens/game_screen.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../screens/mission_detail_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/ranking_screen.dart';
import '../screens/register_screen.dart';
import '../screens/shell_screen.dart';
import '../screens/splash_screen.dart';

/// Nomes de rota em um só lugar (evita texto solto espalhado pelo app).
class AppRoutes {
  static const splash = '/splash';
  static const login = '/login';
  static const register = '/register';
  static const home = '/home';
  static const achievements = '/achievements';
  static const ranking = '/ranking';
  static const profile = '/profile';

  static String missionDetail(String id) => '/mission/$id';
  static String missionPlay(String id) => '/play/$id';
}

/// Faz o GoRouter reavaliar o redirect sempre que o login/logout acontece.
class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh() {
    _subscription = Supabase.instance.client.auth.onAuthStateChange.listen(
      (_) => notifyListeners(),
    );
  }

  late final StreamSubscription<AuthState> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  refreshListenable: _AuthRefresh(),
  redirect: (context, state) {
    final loggedIn = Supabase.instance.client.auth.currentSession != null;
    final location = state.matchedLocation;
    final isAuthPage =
        location == AppRoutes.login || location == AppRoutes.register;

    if (location == AppRoutes.splash) return null; // a splash decide sozinha
    if (!loggedIn && !isAuthPage) return AppRoutes.login; // rotas internas protegidas
    if (loggedIn && isAuthPage) return AppRoutes.home;
    return null;
  },
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🧀', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 12),
            const Text('Essa toca não existe.', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 16),
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(200, 48)),
              onPressed: () => context.go(AppRoutes.home),
              child: const Text('Voltar ao início'),
            ),
          ],
        ),
      ),
    ),
  ),
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: AppRoutes.register,
      builder: (context, state) => const RegisterScreen(),
    ),

    // Telas com a barra de navegação inferior.
    ShellRoute(
      builder: (context, state, child) =>
          ShellScreen(location: state.matchedLocation, child: child),
      routes: [
        GoRoute(
          path: AppRoutes.home,
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: AppRoutes.achievements,
          builder: (context, state) => const AchievementsScreen(),
        ),
        GoRoute(
          path: AppRoutes.ranking,
          builder: (context, state) => const RankingScreen(),
        ),
        GoRoute(
          path: AppRoutes.profile,
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    ),

    // Detalhes da missão: recebe a missão escolhida por parâmetro (extra)
    // e o id pela URL (se o extra não vier, a tela busca no banco).
    GoRoute(
      path: '/mission/:id',
      builder: (context, state) => MissionDetailScreen(
        missionId: state.pathParameters['id']!,
        initialMission: state.extra as Mission?,
      ),
    ),

    // Rodada do jogo (o rato fazendo as perguntas) de uma missão.
    GoRoute(
      path: '/play/:id',
      builder: (context, state) => GameScreen(
        missionId: state.pathParameters['id']!,
        initialMission: state.extra as Mission?,
      ),
    ),
  ],
);
