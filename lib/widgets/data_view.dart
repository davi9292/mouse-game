// Autor: Davi de Assis Fabricio
import 'package:flutter/material.dart';

import '../services/app_events.dart';
import '../services/errors.dart';
import 'state_views.dart';

/// Carrega dados do banco e mostra carregamento, erro ou o conteúdo.
/// Recarrega sozinho quando [AppEvents] avisa que algo mudou (ex.: missão concluída)
/// e também com "puxar para atualizar". O [builder] deve devolver um widget rolável.
class DataView<T> extends StatefulWidget {
  const DataView({super.key, required this.loader, required this.builder});

  final Future<T> Function() loader;
  final Widget Function(BuildContext context, T data) builder;

  @override
  State<DataView<T>> createState() => _DataViewState<T>();
}

class _DataViewState<T> extends State<DataView<T>> {
  late Future<T> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.loader();
    AppEvents.instance.addListener(_reload);
  }

  @override
  void dispose() {
    AppEvents.instance.removeListener(_reload);
    super.dispose();
  }

  void _reload() {
    if (!mounted) return;
    setState(() => _future = widget.loader());
  }

  Future<void> _refresh() async {
    _reload();
    try {
      await _future;
    } catch (_) {
      // o erro aparece na própria tela
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return ErrorView(
            message: friendlyError(snapshot.error!),
            onRetry: _reload,
          );
        }
        if (snapshot.connectionState != ConnectionState.done || !snapshot.hasData) {
          return const LoadingView(message: 'Farejando os dados...');
        }
        return RefreshIndicator(
          onRefresh: _refresh,
          child: widget.builder(context, snapshot.data as T),
        );
      },
    );
  }
}
