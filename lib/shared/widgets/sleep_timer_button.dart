// lib/widgets/sleep_timer_button.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:music_music/features/playlists/view_model/playlist_view_model.dart';

/// Um botÃ£o para definir ou cancelar um temporizador de desligamento.
class SleepTimerButton extends StatelessWidget {
  const SleepTimerButton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewModel = Provider.of<PlaylistViewModel>(context);
    final hasTimer = viewModel.hasSleepTimer;

    return IconButton(
      icon: Icon(
        Icons.timer,
        color: hasTimer 
            ? theme.colorScheme.primary // âœ… Cor primÃ¡ria quando ativo
            : theme.colorScheme.onSurface.withValues(alpha: 0.7), // âœ… Cor secundÃ¡ria quando inativo
        size: 30,
      ),
      onPressed: () {
        _showSleepTimerDialog(context, viewModel);
      },
      tooltip: 'Temporizador de Desligamento',
    );
  }

  /// Mostra um diÃ¡logo com opÃ§Ãµes para o temporizador de desligamento.
  void _showSleepTimerDialog(BuildContext context, PlaylistViewModel viewModel) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          backgroundColor:
              theme.dialogTheme.backgroundColor ?? theme.colorScheme.surface,
          title: Text(
            "Temporizador de Desligamento",
            style: TextStyle(
              color: theme.colorScheme.onSurface, // âœ… Cor do tÃ­tulo
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (viewModel.hasSleepTimer)
                ListTile(
                  leading: Icon(Icons.timer_off, color: theme.colorScheme.primary),
                  title: Text(
                    "Cancelar Temporizador",
                    style: TextStyle(color: theme.colorScheme.onSurface),
                  ),
                  onTap: () {
                    viewModel.cancelSleepTimer();
                    Navigator.of(context).pop();
                  },
                ),
              ListTile(
                title: Text("15 minutos", style: TextStyle(color: theme.colorScheme.onSurface)),
                onTap: () {
                  viewModel.setSleepTimer(const Duration(minutes: 15));
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                title: Text("30 minutos", style: TextStyle(color: theme.colorScheme.onSurface)),
                onTap: () {
                  viewModel.setSleepTimer(const Duration(minutes: 30));
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                title: Text("1 hora", style: TextStyle(color: theme.colorScheme.onSurface)),
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


