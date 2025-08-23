import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:path_provider/path_provider.dart';

import '../../models/music_model.dart';

enum RepeatMode { off, all, one }
enum PlayerState { playing, paused, stopped }

class PlaylistViewModel extends ChangeNotifier {
  final _player = AudioPlayer();
  final OnAudioQuery _audioQuery = OnAudioQuery();

  PlayerState _playerState = PlayerState.stopped;
  List<Music> _musics = [];
  Music? _currentMusic;

  bool _isShuffled = false;
  RepeatMode _repeatMode = RepeatMode.off;

  // Getters
  PlayerState get playerState => _playerState;
  List<Music> get musics => _musics;
  Music? get currentMusic => _currentMusic;
  bool get isShuffled => _isShuffled;
  RepeatMode get repeatMode => _repeatMode;
  Stream<Duration> get positionStream => _player.positionStream;

  Stream<PlayerState> get playerStateStream =>
      _player.playerStateStream.map((state) {
        if (state.playing) {
          return PlayerState.playing;
        } else if (state.processingState == ProcessingState.completed) {
          return PlayerState.stopped;
        } else {
          return PlayerState.paused;
        }
      });

  Stream<SequenceState?> get sequenceStateStream =>
      _player.sequenceStateStream;

  PlaylistViewModel() {
    _initAudioSession();
    _listenToPlayerStateAndSequence();
  }

  // 🔹 Helper para salvar artwork em arquivo temporário
  Future<String?> _saveArtworkToFile(Uint8List bytes, int songId) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/artwork_$songId.jpg');
    await file.writeAsBytes(bytes, flush: true);
    return file.uri.toString();
  }

  // 🔹 Carrega músicas com capas reais
  Future<void> loadMusics() async {
    final songs = await _audioQuery.querySongs();

    List<Music> loaded = [];

    for (var song in songs) {
      Uint8List? artwork =
          await _audioQuery.queryArtwork(song.id, ArtworkType.AUDIO);

      String? artPath;
      if (artwork != null) {
        artPath = await _saveArtworkToFile(artwork, song.id);
      }

      loaded.add(
        Music.fromSongModel(song, albumArtUri: artPath)
      );
    }

    setMusics(loaded);
  }

  // Define músicas e cria playlist no player
  void setMusics(List<Music> musics) {
    _musics = musics;
    _setAudioSource();
    notifyListeners();
  }

  // Sessão de áudio
  Future<void> _initAudioSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
  }

  // Define playlist no player
  Future<void> _setAudioSource() async {
    if (_musics.isEmpty) return;

    final playlist = ConcatenatingAudioSource(
      children: _musics.map((music) {
        return AudioSource.uri(
          Uri.parse(music.uri),
          tag: MediaItem(
            id: music.id.toString(),
            album: music.album ?? 'Álbum desconhecido',
            title: music.title,
            artist: music.artist,
            artUri: music.albumId != null
                ? Uri.parse("content://media/external/audio/albumart/${music.albumId}")
                : Uri.parse("asset:///assets/images/notifica.png"), // fallback
        )
        );
      }).toList(),
    );

    await _player.setAudioSource(playlist);
    await _player.setShuffleModeEnabled(isShuffled);
  }

  // Listener de estados
  void _listenToPlayerStateAndSequence() {
    _player.playerStateStream.listen((state) {
      if (state.playing) {
        _playerState = PlayerState.playing;
      } else if (state.processingState == ProcessingState.completed) {
        _playerState = PlayerState.stopped;
      } else {
        _playerState = PlayerState.paused;
      }
      notifyListeners();
    });

    _player.sequenceStateStream.listen((sequenceState) {
      if (sequenceState != null && sequenceState.currentSource != null) {
        final index = sequenceState.currentIndex;
        if (index < _musics.length) {
          _currentMusic = _musics[index];
        }
      } else {
        _currentMusic = null;
      }
      notifyListeners();
    });
  }

  // Controles do player
  Future<void> play() async => await _player.play();
  Future<void> pause() async => await _player.pause();

  void playPause() {
    if (_player.playing) {
      pause();
    } else {
      play();
    }
  }

  Future<void> playMusic(int index) async {
    if (index >= 0 && index < _musics.length) {
      _currentMusic = _musics[index];
      notifyListeners();
      await _player.seek(Duration.zero, index: index);
      play();
    }
  }

  Future<void> nextMusic() async => await _player.seekToNext();
  Future<void> previousMusic() async => await _player.seekToPrevious();
  Future<void> seek(Duration position) async => await _player.seek(position);

  void toggleShuffle() {
    _isShuffled = !_isShuffled;
    _player.setShuffleModeEnabled(_isShuffled);
    if (_isShuffled) {
      _player.shuffle();
    }
    notifyListeners();
  }

  void toggleRepeatMode() {
    if (_repeatMode == RepeatMode.off) {
      _repeatMode = RepeatMode.all;
      _player.setLoopMode(LoopMode.all);
    } else if (_repeatMode == RepeatMode.all) {
      _repeatMode = RepeatMode.one;
      _player.setLoopMode(LoopMode.one);
    } else {
      _repeatMode = RepeatMode.off;
      _player.setLoopMode(LoopMode.off);
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
