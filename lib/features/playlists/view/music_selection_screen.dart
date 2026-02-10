// lib/views/playlist/music_selection_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:music_music/data/local/database_helper.dart';
import 'package:music_music/data/models/music_entity.dart';
import 'package:music_music/features/playlists/view_model/playlist_view_model.dart';
import 'package:music_music/shared/widgets/artwork_image.dart';

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

  final Set<int> _existingMusicIds = <int>{};
  final ValueNotifier<Set<int>> _selectedMusicIds =
      ValueNotifier<Set<int>>(<int>{});

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
    _selectedMusicIds.dispose();
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

      _selectedMusicIds.value = Set<int>.from(_existingMusicIds);

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
    for (final musicId in _selectedMusicIds.value) {
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
              HapticFeedback.selectionClick();
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
            onPressed: () {
              if (_selectedMusicIds.value.isEmpty) return;
              HapticFeedback.selectionClick();
              _confirmSelection();
            },
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

                ArtworkCache.preload(context, music.artworkUrl);

                return ValueListenableBuilder<Set<int>>(
                  valueListenable: _selectedMusicIds,
                  builder: (_, selectedSet, __) {
                    final isSelected = selectedSet.contains(musicId);

                    return _PressableTile(
                      onTap: isExisting
                          ? null
                          : () {
                              HapticFeedback.selectionClick();
                              final next = Set<int>.from(selectedSet);
                              if (isSelected) {
                                next.remove(musicId);
                              } else {
                                next.add(musicId);
                              }
                              _selectedMusicIds.value = next;
                            },
                      child: ListTile(
                        leading: ArtworkThumb(artworkUrl: music.artworkUrl),
                        title: Text(music.title),
                        subtitle: Text(music.artist),
                        trailing: Checkbox(
                          value: isSelected,
                          onChanged: isExisting
                              ? null
                              : (value) {
                                  HapticFeedback.selectionClick();
                                  final next = Set<int>.from(selectedSet);
                                  if (value == true) {
                                    next.add(musicId);
                                  } else {
                                    next.remove(musicId);
                                  }
                                  _selectedMusicIds.value = next;
                                },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

class _PressableTile extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _PressableTile({
    required this.child,
    required this.onTap,
  });

  @override
  State<_PressableTile> createState() => _PressableTileState();
}

class _PressableTileState extends State<_PressableTile> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.985 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: AnimatedOpacity(
          opacity: _pressed ? 0.92 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          child: widget.child,
        ),
      ),
    );
  }
}


