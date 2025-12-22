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
  List<Music> _filteredMusics = [];
  Set<int> _selectedMusicIds = {};
  Set<int> _existingMusicIds = {};

  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _viewModel = Provider.of<PlaylistViewModel>(context, listen: false);
    _loadAllMusics();
    _searchController.addListener(_filterMusics);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAllMusics() async {
    try {
      final allMusics = await DatabaseHelper().getAllMusics();
      final existingMusics = await _viewModel.getMusicsFromPlaylist(widget.playlistId);

      _existingMusicIds = existingMusics.map((m) => m.id).toSet();
      _selectedMusicIds = Set<int>.from(_existingMusicIds);

      setState(() {
        _allMusics = allMusics;
        _filteredMusics = allMusics;
        _isLoading = false;
      });
    } catch (e) {
      print('Erro ao carregar músicas: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _confirmSelection() {
    for (final music in _allMusics) {
      if (_selectedMusicIds.contains(music.id) && !_existingMusicIds.contains(music.id)) {
        _viewModel.addMusicToPlaylist(widget.playlistId, music);
      }
    }
    Navigator.pop(context);
  }

  void _filterMusics() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredMusics = _allMusics;
      } else {
        _filteredMusics = _allMusics.where((music) {
          return music.title.toLowerCase().contains(query) ||
                 (music.artist?.toLowerCase().contains(query) ?? false);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // 👈 Pega o tema atual

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Buscar músicas...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: theme.hintColor), // ✅ Cor do tema
                ),
                style: TextStyle(
                  color: theme.colorScheme.onSurface, // ✅ Cor do tema
                  fontSize: 18,
                ),
              )
            : Text('Adicionar à ${widget.playlistName}'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close : Icons.search,
              color: theme.colorScheme.onSurface, // ✅ Cor do tema
            ),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _filteredMusics = _allMusics;
                }
              });
            },
          ),
          TextButton(
            onPressed: _selectedMusicIds.isNotEmpty ? _confirmSelection : null,
            child: Text(
              'Confirmar',
              style: TextStyle(color: theme.colorScheme.primary), // ✅ Cor primária do tema
            ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: theme.colorScheme.primary))
          : ListView.builder(
              itemCount: _filteredMusics.length,
              itemBuilder: (context, index) {
                final music = _filteredMusics[index];
                final bool isExisting = _existingMusicIds.contains(music.id);
                final bool isSelected = _selectedMusicIds.contains(music.id);

                // Cores baseadas no tema
                final titleColor = isExisting 
                    ? theme.colorScheme.onSurface.withOpacity(0.5) // Cinza no modo claro/escuro
                    : theme.colorScheme.onSurface;
                final subtitleColor = isExisting
                    ? theme.colorScheme.onSurface.withOpacity(0.4)
                    : theme.colorScheme.onSurface.withOpacity(0.7);

                return ListTile(
                  leading: Icon(
                    Icons.music_note,
                    color: theme.colorScheme.onSurface.withOpacity(0.7), // ✅ Ícone adaptável
                  ),
                  title: Text(
                    music.title,
                    style: TextStyle(color: titleColor),
                  ),
                  subtitle: Text(
                    music.artist ?? 'Artista Desconhecido',
                    style: TextStyle(color: subtitleColor),
                  ),
                  trailing: Checkbox(
                    value: isSelected,
                    activeColor: theme.colorScheme.primary, // ✅ Cor do checkbox
                    checkColor: theme.colorScheme.onPrimary, // ✅ Cor do ✅
                    onChanged: isExisting
                        ? null
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