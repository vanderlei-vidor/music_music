import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/database_helper.dart';
import '../../models/music_model.dart';
import 'playlist_view_model.dart';

class MusicSelectionScreen extends StatefulWidget {
  final int playlistId;
  final String playlistName;

  const MusicSelectionScreen({
    Key? key,
    required this.playlistId,
    required this.playlistName,
  }) : super(key: key);

  @override
  State<MusicSelectionScreen> createState() => _MusicSelectionScreenState();
}

class _MusicSelectionScreenState extends State<MusicSelectionScreen> {
  late final PlaylistViewModel _viewModel;
  bool _isLoading = true;
  List<Music> _allMusics = [];
  Set<int> _selectedMusicIds = {};
  Set<int> _existingMusicIds = {};

  @override
  void initState() {
    super.initState();
    _viewModel = Provider.of<PlaylistViewModel>(context, listen: false);
    _loadAllMusics();
  }

  Future<void> _loadAllMusics() async {
    try {
      // Pega todas as músicas do dispositivo
      final allMusics = await DatabaseHelper().getAllMusics();
      // Pega as músicas que já estão na playlist atual
      final existingMusics = await _viewModel.getMusicsFromPlaylist(widget.playlistId);

      // Mapeia as músicas existentes para um conjunto de IDs para busca rápida
      _existingMusicIds = existingMusics.map((m) => m.id).toSet();
      // Inicializa o conjunto de músicas selecionadas com as músicas existentes
      _selectedMusicIds = Set<int>.from(_existingMusicIds);

      setState(() {
        _allMusics = allMusics;
        _isLoading = false;
      });
    } catch (e) {
      print('Erro ao carregar músicas: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Lógica do botão de confirmação
  void _confirmSelection() {
    // Itera sobre todas as músicas do dispositivo
    for (final music in _allMusics) {
      // Se a música foi selecionada e ainda não está na playlist
      if (_selectedMusicIds.contains(music.id) && !_existingMusicIds.contains(music.id)) {
        _viewModel.addMusicToPlaylist(widget.playlistId, music);
      }
    }
    // Retorna para a tela anterior
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Adicionar à ${widget.playlistName}'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _selectedMusicIds.isNotEmpty ? _confirmSelection : null,
            child: const Text('Confirmar', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _allMusics.length,
              itemBuilder: (context, index) {
                final music = _allMusics[index];
                // Verifica se a música já existe na playlist
                final bool isExisting = _existingMusicIds.contains(music.id);
                // Verifica se a música está selecionada para adicionar
                final bool isSelected = _selectedMusicIds.contains(music.id);

                return ListTile(
                  leading: const Icon(Icons.music_note),
                  title: Text(music.title,
                      style: TextStyle(
                          color: isExisting ? Colors.grey : Colors.black)),
                  subtitle: Text(music.artist ?? 'Artista Desconhecido',
                      style: TextStyle(
                          color: isExisting ? Colors.grey : Colors.black54)),
                  trailing: Checkbox(
                    value: isSelected,
                    onChanged: isExisting
                        ? null // Desabilita o checkbox se a música já existe
                        : (bool? value) {
                            setState(() {
                              if (value == true) {
                                _selectedMusicIds.add(music.id);
                              } else {
                                _selectedMusicIds.remove(music.id);
                              }
                            });
                          },
                  ),
                );
              },
            ),
    );
  }
}
