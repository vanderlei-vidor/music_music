// views/home/home_view.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'home_view_model.dart';
import '../playlist/playlist_view.dart';
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
    // Carrega as músicas assim que a tela é iniciada
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = Provider.of<HomeViewModel>(context, listen: false);
      viewModel.loadMusics();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Consumer<HomeViewModel>(
          builder: (context, viewModel, child) {
            // Se as músicas estiverem carregando, mostra o indicador de progresso
            if (viewModel.isLoading) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7B66FF)),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Carregando suas músicas...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                ],
              );
            }

            // Se as músicas já foram carregadas, exibe o botão
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.library_music,
                  size: 80,
                  color: Color(0xFF7B66FF),
                ),
                const SizedBox(height: 30),
                const Text(
                  'Bem-vindo!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  viewModel.musics.isEmpty
                      ? 'Nenhuma música encontrada.'
                      : 'Músicas encontradas: ${viewModel.musics.length}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 40),
                CustomButton(
                  text: 'Ver Minhas Músicas',
                  onPressed: () {
                    // Acessa o ViewModel da Playlist para passar a lista de músicas
                    final playlistViewModel = Provider.of<PlaylistViewModel>(context, listen: false);
                    playlistViewModel.setMusics(viewModel.musics);

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PlaylistView(),
                      ),
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
