// lib/views/home/home_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'home_view_model.dart';
import '../playlist/playlist_view.dart';
import '../playlist/playlists_screen.dart'; // 👈 IMPORTANTE!
import '../../widgets/custom_button.dart';
import '../playlist/playlist_view_model.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = Provider.of<HomeViewModel>(context, listen: false);
      viewModel.loadMusics();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: Consumer<HomeViewModel>(
          builder: (context, viewModel, child) {
            if (viewModel.isLoading) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
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
                // Botão 1: Ver todas as músicas
                CustomButton(
                  text: 'Ver Minhas Músicas',
                  onPressed: () {
                    final playlistViewModel = Provider.of<PlaylistViewModel>(context, listen: false);
                    playlistViewModel.setMusics(viewModel.musics);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const PlaylistView()),
                    );
                  },
                ),
                const SizedBox(height: 16),
                // Botão 2: Ir direto para playlists
                CustomButton(
                  text: 'Minhas Playlists',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const PlaylistsScreen()),
                    );
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