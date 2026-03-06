import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:music_music/data/models/music_entity.dart';
import 'package:music_music/features/home/view_model/home_view_model.dart';
import 'package:music_music/shared/widgets/artwork_image.dart';

class TrashLibraryView extends StatefulWidget {
  const TrashLibraryView({super.key});

  @override
  State<TrashLibraryView> createState() => _TrashLibraryViewState();
}

class _TrashLibraryViewState extends State<TrashLibraryView> {
  late Future<List<MusicEntity>> _future;
  bool _restoringAll = false;
  bool _deletingAll = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<MusicEntity>> _load() {
    return context.read<HomeViewModel>().getRemovedMusics();
  }

  Future<void> _reload() async {
    setState(() {
      _future = _load();
    });
  }

  Future<void> _restoreMusic(MusicEntity music) async {
    await context.read<HomeViewModel>().restoreMusicToLibrary(music);
    if (!mounted) return;
    await _reload();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('"${music.title}" restaurada para a biblioteca.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _restoreAll(List<MusicEntity> musics) async {
    if (musics.isEmpty || _restoringAll) return;
    setState(() => _restoringAll = true);
    try {
      final vm = context.read<HomeViewModel>();
      for (final music in musics) {
        await vm.restoreMusicToLibrary(music);
      }
      if (!mounted) return;
      await _reload();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${musics.length} musicas restauradas.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _restoringAll = false);
    }
  }

  Future<void> _deleteForever(MusicEntity music) async {
    final vm = context.read<HomeViewModel>();
    final confirmed = await _confirmDelete(
      title: 'Excluir permanentemente?',
      message:
          'A musica "${music.title}" sera removida da lixeira e nao podera ser recuperada.',
      confirmLabel: 'Excluir',
    );
    if (!confirmed) return;

    await vm.permanentlyDeleteFromTrash(music);
    if (!mounted) return;
    await _reload();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('"${music.title}" foi excluida permanentemente.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _deleteAllForever(List<MusicEntity> musics) async {
    if (musics.isEmpty || _deletingAll) return;
    final vm = context.read<HomeViewModel>();
    final confirmed = await _confirmDelete(
      title: 'Limpar lixeira?',
      message:
          'Todos os ${musics.length} itens serao excluidos permanentemente e nao poderao ser recuperados.',
      confirmLabel: 'Limpar',
    );
    if (!confirmed) return;

    setState(() => _deletingAll = true);
    try {
      final deleted = await vm.permanentlyDeleteAllFromTrash();
      if (!mounted) return;
      await _reload();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$deleted itens excluidos permanentemente.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _deletingAll = false);
    }
  }

  Future<bool> _confirmDelete({
    required String title,
    required String message,
    required String confirmLabel,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lixeira'),
      ),
      body: FutureBuilder<List<MusicEntity>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final musics = snapshot.data ?? const <MusicEntity>[];
          if (musics.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.delete_outline_rounded,
                      size: 72,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Sua lixeira esta vazia',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Musicas removidas da biblioteca aparecem aqui para restauracao.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                child: Row(
                  children: [
                    Text(
                      '${musics.length} itens',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                      ),
                    ),
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: _restoringAll ? null : () => _restoreAll(musics),
                      icon: _restoringAll
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.restore_rounded),
                      label: const Text('Restaurar tudo'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: _deletingAll ? null : () => _deleteAllForever(musics),
                      icon: _deletingAll
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.delete_forever_rounded),
                      label: const Text('Limpar'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 8),
              Expanded(
                child: ListView.separated(
                  itemCount: musics.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final music = musics[index];
                    return ListTile(
                      leading: ArtworkThumb(
                        artworkUrl: music.artworkUrl,
                        audioId: music.sourceId ?? music.id,
                      ),
                      title: Text(
                        music.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        music.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: PopupMenuButton<String>(
                        tooltip: 'Acoes',
                        onSelected: (value) {
                          if (value == 'restore') {
                            _restoreMusic(music);
                            return;
                          }
                          if (value == 'delete') {
                            _deleteForever(music);
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem<String>(
                            value: 'restore',
                            child: Text('Restaurar'),
                          ),
                          PopupMenuItem<String>(
                            value: 'delete',
                            child: Text('Excluir permanentemente'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
