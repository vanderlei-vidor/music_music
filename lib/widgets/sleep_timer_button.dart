import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../views/playlist/playlist_view_model.dart';

/// Um botão para definir ou cancelar um temporizador de desligamento.
class SleepTimerButton extends StatelessWidget {
  const SleepTimerButton({super.key});

  @override
  Widget build(BuildContext context) {
    // Escuta as mudanças no PlaylistViewModel para atualizar a cor do ícone
    final viewModel = Provider.of<PlaylistViewModel>(context);
    final hasTimer = viewModel.hasSleepTimer;

    return IconButton(
      icon: Icon(
        Icons.timer,
        color: hasTimer ? Colors.blueAccent : Colors.white70,
        size: 30,
      ),
      onPressed: () {
        _showSleepTimerDialog(context, viewModel);
      },
      tooltip: 'Temporizador de Desligamento',
    );
  }

  /// Mostra um diálogo com opções para o temporizador de desligamento.
  void _showSleepTimerDialog(BuildContext context, PlaylistViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          backgroundColor: Colors.grey[850],
          title: const Text(
            "Temporizador de Desligamento",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (viewModel.hasSleepTimer)
                ListTile(
                  leading: const Icon(Icons.timer_off, color: Colors.white),
                  title: const Text(
                    "Cancelar Temporizador",
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    viewModel.cancelSleepTimer();
                    Navigator.of(context).pop();
                  },
                ),
              ListTile(
                title: const Text("15 minutos", style: TextStyle(color: Colors.white)),
                onTap: () {
                  viewModel.setSleepTimer(const Duration(minutes: 15));
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                title: const Text("30 minutos", style: TextStyle(color: Colors.white)),
                onTap: () {
                  viewModel.setSleepTimer(const Duration(minutes: 30));
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                title: const Text("1 hora", style: TextStyle(color: Colors.white)),
                onTap: () {
                  viewModel.setSleepTimer(const Duration(hours: 1));
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
