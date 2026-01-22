import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../playlist/playlist_view_model.dart';

class RecentMusicsView extends StatefulWidget {
  const RecentMusicsView({super.key});

  @override
  State<RecentMusicsView> createState() => _RecentMusicsViewState();
}

class _RecentMusicsViewState extends State<RecentMusicsView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PlaylistViewModel>().loadRecentMusics();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PlaylistViewModel>();
    final theme = Theme.of(context);

    final grouped = vm.recentGrouped;
    final hasAnyMusic =
        grouped.values.any((list) => list.isNotEmpty);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tocadas recentemente'),
        actions: [
    IconButton(
      icon: const Icon(Icons.delete_outline),
      tooltip: 'Limpar histórico',
      onPressed: () => _showClearDialog(context),
    ),
  ],
      ),
      body: !hasAnyMusic
          ? const Center(
              child: Text('Nenhuma música tocada ainda'),
            )
          : ListView(
              children: grouped.entries
                  .where((e) => e.value.isNotEmpty)
                  .map((entry) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Text(
                        entry.key,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ...entry.value.map((music) {
                      return ListTile(
                        leading: const Icon(Icons.history),
                        title: Text(music.title),
                        subtitle: Text(music.artist),
                        onTap: () {
                          vm.playMusic(
                            entry.value,
                            entry.value.indexOf(music),
                          );
                        },
                      );
                    }),
                  ],
                );
              }).toList(),
            ),
    );
  }

  void _showClearDialog(BuildContext context) {
  final theme = Theme.of(context);

  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Limpar histórico'),
      content: const Text(
        'Isso removerá todas as músicas tocadas recentemente. '
        'Essa ação não pode ser desfeita.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
            foregroundColor: theme.colorScheme.onError,
          ),
          onPressed: () async {
            Navigator.pop(context);
            await context
                .read<PlaylistViewModel>()
                .clearRecentHistory();
          },
          child: const Text('Limpar'),
        ),
      ],
    ),
  );
}

}
