import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:music_music/features/home/view_model/home_view_model.dart';

import 'package:music_music/app/routes.dart';
import 'package:music_music/shared/widgets/custom_button.dart';
import 'package:music_music/features/playlists/view_model/playlist_view_model.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
    final vm = context.read<HomeViewModel>();

    // 1️⃣ Faz scan automático no Android (se permitido)
    

    // 2️⃣ Depois carrega do banco
    await vm.loadMusics();
  });

  }

  // 🔥 BottomSheet profissional
  void _showAddMusicSheet(BuildContext context) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Icon(Icons.folder, color: theme.colorScheme.primary),
                title: const Text('Importar arquivos'),
                subtitle: const Text('Adicionar músicas do dispositivo'),
                onTap: () async {
                  Navigator.pop(context);
              //    await MusicService().importMusics();
                  context.read<HomeViewModel>().loadMusics();
                },
              ),
              ListTile(
                leading: Icon(Icons.link, color: theme.colorScheme.primary),
                title: const Text('Adicionar por URL'),
                subtitle: const Text('Streaming, MP3 online, rádio'),
                onTap: () {
                  Navigator.pop(context);
                  // 👉 aqui você pode chamar o dialog de URL depois
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: theme.colorScheme.primary,
        child: const Icon(Icons.add),
        onPressed: () => _showAddMusicSheet(context),
      ),
      body: Center(
        child: Consumer<HomeViewModel>(
          builder: (context, viewModel, child) {
            if (viewModel.isLoading) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Carregando suas músicas...',
                    style: TextStyle(
                      fontSize: 16,
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              );
            }

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.library_music,
                  size: 80,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 30),
                Text(
                  'Bem-vindo!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  viewModel.musics.isEmpty
                      ? 'Nenhuma música encontrada.'
                      : 'Músicas encontradas: ${viewModel.musics.length}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 40),

                // 🔹 Ver músicas
                CustomButton(
                  text: 'Ver Minhas Músicas',
                  onPressed: () {
                    final playlistVM =
                        context.read<PlaylistViewModel>();
                    playlistVM.setMusics(
                      viewModel.musics
                    );
                    Navigator.pushNamed(context, AppRoutes.playlistView);
                  },
                ),
                const SizedBox(height: 16),

                // 🔹 Playlists
                CustomButton(
                  text: 'Minhas Playlists',
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.playlists);
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}



