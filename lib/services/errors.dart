// Autor: Davi de Assis Fabricio
import 'package:supabase_flutter/supabase_flutter.dart';

/// Traduz a mensagem de erro do Supabase Auth para algo claro em português.
String authErrorMessage(AuthException e) {
  final msg = e.message.toLowerCase();
  if (msg.contains('invalid login credentials')) {
    return 'E-mail ou senha incorretos.';
  }
  if (msg.contains('already registered') || msg.contains('already been registered')) {
    return 'Este e-mail já está cadastrado. Tente entrar.';
  }
  if (msg.contains('email not confirmed')) {
    return 'Confirme seu e-mail pelo link que enviamos antes de entrar.';
  }
  if (msg.contains('password should be') || msg.contains('weak password')) {
    return 'A senha precisa ter pelo menos 6 caracteres.';
  }
  if (msg.contains('valid email') || msg.contains('invalid email')) {
    return 'Digite um e-mail válido.';
  }
  if (msg.contains('rate limit') || msg.contains('too many')) {
    return 'Muitas tentativas. Aguarde um pouco e tente de novo.';
  }
  return 'Não foi possível autenticar: ${e.message}';
}

/// Mensagem amigável para qualquer erro mostrado na interface.
String friendlyError(Object error) {
  if (error is AuthException) return authErrorMessage(error);
  if (error is PostgrestException) {
    final code = error.code ?? '';
    if (code == 'PGRST205' || code == 'PGRST202' || code == '42P01') {
      return 'O banco ainda não foi configurado. Rode o arquivo '
          'supabase/schema.sql no SQL Editor do Supabase.';
    }
    if (error.message.isNotEmpty) return error.message;
  }
  if (error is Exception) {
    final text = error.toString();
    if (text.startsWith('Exception: ')) return text.substring(11);
  }
  return 'Algo deu errado. Verifique sua conexão e tente novamente.';
}
