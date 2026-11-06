// Autor: Davi de Assis Fabricio
import 'package:flutter/foundation.dart';

/// Avisa as telas quando os dados do jogador mudaram (ex.: missão concluída),
/// para Home, Conquistas, Ranking e Perfil recarregarem do banco.
class AppEvents extends ChangeNotifier {
  AppEvents._();

  static final AppEvents instance = AppEvents._();

  void dataChanged() => notifyListeners();
}
