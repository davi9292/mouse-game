// Autor: Davi de Assis Fabricio
import 'package:supabase_flutter/supabase_flutter.dart';

import 'errors.dart';

/// Resultado de uma tentativa de login ou cadastro.
class AuthResult {
  const AuthResult.success({this.needsEmailConfirmation = false})
      : errorMessage = null;
  const AuthResult.failure(this.errorMessage) : needsEmailConfirmation = false;

  final String? errorMessage;
  final bool needsEmailConfirmation;

  bool get ok => errorMessage == null;
}

class AuthService {
  static SupabaseClient get _client => Supabase.instance.client;

  static Session? get currentSession => _client.auth.currentSession;
  static User? get currentUser => _client.auth.currentUser;

  static Future<AuthResult> signIn(String email, String password) async {
    try {
      await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      return const AuthResult.success();
    } on AuthException catch (e) {
      return AuthResult.failure(authErrorMessage(e));
    } catch (_) {
      return const AuthResult.failure(
        'Sem conexão com o servidor. Tente novamente.',
      );
    }
  }

  static Future<AuthResult> signUp(
    String email,
    String password,
    String nickname,
  ) async {
    try {
      final response = await _client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {'nickname': nickname.trim()},
      );
      // Sem sessão = o projeto exige confirmação de e-mail.
      return AuthResult.success(needsEmailConfirmation: response.session == null);
    } on AuthException catch (e) {
      return AuthResult.failure(authErrorMessage(e));
    } catch (_) {
      return const AuthResult.failure(
        'Sem conexão com o servidor. Tente novamente.',
      );
    }
  }

  static Future<void> signOut() => _client.auth.signOut();
}
