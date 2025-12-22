
import 'package:flutter/material.dart';
import 'package:music_music/views/playlist/playlist_view_model.dart';

void showCreatePlaylistDialog(BuildContext context, PlaylistViewModel viewModel) {
  final theme = Theme.of(context);
  final TextEditingController controller = TextEditingController();
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: theme.cardColor,
      title: Text('Criar Nova Playlist', style: TextStyle(color: theme.colorScheme.onSurface)),
      content: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: 'Nome da Playlist',
          labelStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7)),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: theme.colorScheme.primary),
          ),
        ),
        style: TextStyle(color: theme.colorScheme.onSurface),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancelar', style: TextStyle(color: theme.colorScheme.onSurface)),
        ),
        TextButton(
          onPressed: () {
            if (controller.text.isNotEmpty) {
              viewModel.createPlaylist(controller.text);
              Navigator.pop(context);
            }
          },
          child: Text('Criar', style: TextStyle(color: theme.colorScheme.primary)),
        ),
      ],
    ),
  );
}
