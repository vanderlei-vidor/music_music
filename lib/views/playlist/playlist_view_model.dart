import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import '../../models/music_model.dart';
import 'package:just_audio_background/just_audio_background.dart';

enum PlayerState {
  playing,
  paused,
  stopped,
}

class PlaylistViewModel extends ChangeNotifier {
  final _player = AudioPlayer();
  PlayerState _playerState = PlayerState.stopped;
  List<Music> _musics = [];
  Music? _currentMusic;

  PlayerState get playerState => _playerState;
  List<Music> get musics => _musics;
  Music? get currentMusic => _currentMusic;

  // Novos getters para expor o estado do player
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream.map((state) {
    if (state.playing) {
      return PlayerState.playing;
    } else if (state.processingState == ProcessingState.completed) {
      return PlayerState.stopped;
    } else {
      return PlayerState.paused;
    }
  });
  Stream<SequenceState?> get sequenceStateStream => _player.sequenceStateStream;

  // Construtor que configura a sessão de áudio
  PlaylistViewModel() {
    _initAudioSession();
    _listenToPlayerStateAndSequence();
  }

  // Define a lista de músicas
  void setMusics(List<Music> musics) {
    _musics = musics;
    _setAudioSource();
    notifyListeners();
  }

  // Configura a sessão de áudio e as notificações
  Future<void> _initAudioSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
  }

  // Define a lista de reprodução para o player
  Future<void> _setAudioSource() async {
    if (_musics.isEmpty) {
      return;
    }
    final playlist = ConcatenatingAudioSource(
      children: _musics.map((music) {
        return AudioSource.uri(
          Uri.parse(music.uri),
          tag: MediaItem(
            id: music.id.toString(),
            album: music.albumId.toString(),
            title: music.title,
            artist: music.artist,
            artUri: Uri.parse('https://placehold.co/100x100/png?text=Album'),
          ),
        );
      }).toList(),
    );
    await _player.setAudioSource(playlist);
  }

  // Ouve as mudanças de estado do player e da sequência
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

  // Inicia a reprodução
  Future<void> play() async {
    await _player.play();
  }

  // Pausa a reprodução
  Future<void> pause() async {
    await _player.pause();
  }

  // Alterna entre play e pause
  void playPause() {
    if (_player.playing) {
      pause();
    } else {
      play();
    }
  }

  // Toca uma música específica pelo índice
  Future<void> playMusic(int index) async {
    if (index >= 0 && index < _musics.length) {
      // Atualiza a música atual imediatamente para que a UI reaja rápido
      _currentMusic = _musics[index];
      notifyListeners();
      await _player.seek(Duration.zero, index: index);
      play();
    }
  }

  // Avança para a próxima música
  Future<void> nextMusic() async {
    await _player.seekToNext();
  }

  // Volta para a música anterior
  Future<void> previousMusic() async {
    await _player.seekToPrevious();
  }

  // Busca uma posição específica na música
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }
}
