// Autor: Davi de Assis Fabricio

/// Credenciais do projeto Supabase.
///
/// Opção 1: troque os valores padrão abaixo pelos do seu projeto
/// (Supabase > Project Settings > API).
/// Opção 2: passe na execução:
/// flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
///
/// Use somente a chave "anon" (pública). Nunca coloque a "service_role" no app.
class SupabaseConfig {
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://bkktcwfciebkjdatsrqd.supabase.co/rest/v1/',
  );

  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJra3Rjd2ZjaWVia2pkYXRzcnFkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTM5NDgxNDEsImV4cCI6MjEwOTUyNDE0MX0.XAdtZYggcKfloZ4Hwiko-_d9i2jaINqdUsQM4fS9ZBI',
  );

  static bool get isConfigured =>
      url.startsWith('http') && !anonKey.startsWith('eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJra3Rjd2ZjaWVia2pkYXRzcnFkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTM5NDgxNDEsImV4cCI6MjEwOTUyNDE0MX0.XAdtZYggcKfloZ4Hwiko-_d9i2jaINqdUsQM4fS9ZBI');
}
