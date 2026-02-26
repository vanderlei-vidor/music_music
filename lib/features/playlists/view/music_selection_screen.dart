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
  bool _isSaving = false;
  bool _isSearching = false;
  List<MusicEntity> _allMusics = [];
  List<MusicEntity> _filteredMusics = [];

  final Set<int> _existingMusicIds = <int>{};
  final ValueNotifier<Set<int>> _selectedMusicIds = ValueNotifier<Set<int>>(<int>{});
  final TextEditingController _searchController = TextEditingController();

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
      final playlistMusics = await _viewModel.getMusicsFromPlaylistV2(widget.playlistId);

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
      debugPrint('Erro ao carregar musicas: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmSelection() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    final selected = _selectedMusicIds.value;
    final newlyAddedIds = selected.difference(_existingMusicIds);

    for (final musicId in selected) {
      if (!_existingMusicIds.contains(musicId)) {
        await _viewModel.addMusicToPlaylistV2(widget.playlistId, musicId);
      }
    }
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    Navigator.pop(context, newlyAddedIds.length);
  }

  void _filterMusics() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredMusics = query.isEmpty
          ? _allMusics
          : _allMusics.where((music) {
              return music.title.toLowerCase().contains(query) ||
                  music.artist.toLowerCase().contains(query);
            }).toList();
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
                decoration: const InputDecoration(
                  hintText: 'Buscar musicas...',
                  border: InputBorder.none,
                ),
              )
            : Text('Adicionar a ${widget.playlistName}'),
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
          ValueListenableBuilder<Set<int>>(
            valueListenable: _selectedMusicIds,
            builder: (_, selected, __) {
              final addedNow = selected.difference(_existingMusicIds).length;
              return TextButton(
                onPressed: selected.isEmpty || _isSaving
                    ? null
                    : () {
                        HapticFeedback.selectionClick();
                        _confirmSelection();
                      },
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: _isSaving
                      ? SizedBox(
                          key: const ValueKey('saving'),
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: theme.colorScheme.primary,
                          ),
                        )
                      : Text(
                          addedNow > 0 ? 'Confirmar ($addedNow)' : 'Confirmar',
                          key: const ValueKey('confirm'),
                          style: TextStyle(color: theme.colorScheme.primary),
                        ),
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: theme.colorScheme.primary))
          : ListView.builder(
              itemCount: _filteredMusics.length,
              itemBuilder: (context, index) {
                final music = _filteredMusics[index];
                final musicId = music.id;
                if (musicId == null) return const SizedBox.shrink();

                final isExisting = _existingMusicIds.contains(musicId);
                ArtworkCache.preload(context, music.artworkUrl);

                return ValueListenableBuilder<Set<int>>(
                  valueListenable: _selectedMusicIds,
                  builder: (_, selectedSet, __) {
                    final isSelected = selectedSet.contains(musicId);
                    final highlight = isSelected
                        ? theme.colorScheme.primary.withValues(alpha: 0.12)
                        : theme.cardColor;

                    return TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: Duration(milliseconds: 180 + (index % 8) * 18),
                      curve: Curves.easeOutCubic,
                      builder: (_, t, child) {
                        return Opacity(
                          opacity: t,
                          child: Transform.translate(
                            offset: Offset(0, (1 - t) * 8),
                            child: child,
                          ),
                        );
                      },
                      child: _PressableTile(
                        onTap: isExisting
                            ? null
                            : _isSaving
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
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOutCubic,
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: highlight,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? theme.colorScheme.primary.withValues(alpha: 0.6)
                                  : Colors.transparent,
                            ),
                          ),
                          child: ListTile(
                            leading: ArtworkThumb(
                              artworkUrl: music.artworkUrl,
                              audioId: music.sourceId ?? music.id,
                            ),
                            title: Text(music.title),
                            subtitle: Text(
                              isExisting ? '${music.artist} • ja esta na playlist' : music.artist,
                            ),
                            trailing: IgnorePointer(
                              ignoring: _isSaving,
                              child: AnimatedScale(
                                scale: isSelected ? 1.0 : 0.92,
                                duration: const Duration(milliseconds: 140),
                                child: Checkbox(
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
                            ),
                          ),
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

  const _PressableTile({required this.child, required this.onTap});

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
