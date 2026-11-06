// Autor: Davi de Assis Fabricio
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'config/supabase_config.dart';
import 'theme/app_theme.dart';
import 'widgets/mouse_avatar.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!SupabaseConfig.isConfigured) {
    runApp(const _MissingConfigApp());
    return;
  }

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );
  runApp(const MounatorApp());
}

/// Aviso amigável quando a URL/chave do Supabase ainda não foram preenchidas.
class _MissingConfigApp extends StatelessWidget {
  const _MissingConfigApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const Scaffold(
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                MouseAvatar(size: 120, mood: MouseMood.sad),
                SizedBox(height: 20),
                Text(
                  'Falta configurar o Supabase',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 10),
                Text(
                  'Abra lib/config/supabase_config.dart e cole a URL e a anon key '
                  'do seu projeto (ou use --dart-define). Os passos completos '
                  'estão no README.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
