// lib/views/playlist/music_selection_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:music_music/data/local/database_helper.dart';
import 'package:music_music/data/models/music_entity.dart';
import 'package:music_music/features/playlists/view_model/playlist_view_model.dart';

class MusicSelectionScreen extends StatefulWidget {
  final int playlistId;
  final String playlistName;

  const MusicSelectionScreen({
    super.key,
    required this.playlistId,
    required this.playlistName,
  });

  @override
  State<MusicSelectionScreen> createState() => _MusicSelectionScreenState();
}

class _MusicSelectionScreenState extends State<MusicSelectionScreen> {
  late final PlaylistViewModel _viewModel;

  bool _isLoading = true;
  List<MusicEntity> _allMusics = [];
  List<MusicEntity> _filteredMusics = [];

  final Set<int> _selectedMusicIds = <int>{};
  final Set<int> _existingMusicIds = <int>{};

  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _viewModel = context.read<PlaylistViewModel>();
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
      final db = DatabaseHelper.instance;

      final allMusics = await db.getAllMusicsV2();
      final playlistMusics = await _viewModel.getMusicsFromPlaylistV2(
        widget.playlistId,
      );

      _existingMusicIds
        ..clear()
        ..addAll(playlistMusics.where((m) => m.id != null).map((m) => m.id!));

      _selectedMusicIds
        ..clear()
        ..addAll(_existingMusicIds);

      setState(() {
        _allMusics = allMusics;
        _filteredMusics = allMusics;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Erro ao carregar músicas: $e');
      setState(() => _isLoading = false);
    }
  }

  void _confirmSelection() async {
    for (final musicId in _selectedMusicIds) {
      if (!_existingMusicIds.contains(musicId)) {
        await _viewModel.addMusicToPlaylistV2(widget.playlistId, musicId);
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
              music.artist.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Buscar músicas...',
                  border: InputBorder.none,
                ),
              )
            : Text('Adicionar à ${widget.playlistName}'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
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
              style: TextStyle(color: theme.colorScheme.primary),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            )
          : ListView.builder(
              itemCount: _filteredMusics.length,
              itemBuilder: (context, index) {
                final music = _filteredMusics[index];
                final musicId = music.id;

                if (musicId == null) {
                  return const SizedBox.shrink();
                }

                final isExisting = _existingMusicIds.contains(musicId);
                final isSelected = _selectedMusicIds.contains(musicId);

                return ListTile(
                  leading: const Icon(Icons.music_note),
                  title: Text(music.title),
                  subtitle: Text(music.artist),
                  trailing: Checkbox(
                    value: isSelected,
                    onChanged: isExisting
                        ? null
                        : (value) {
                            setState(() {
                              if (value == true) {
                                _selectedMusicIds.add(musicId);
                              } else {
                                _selectedMusicIds.remove(musicId);
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


