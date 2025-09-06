import 'dart:io';
import 'dart:typed_data';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:just_waveform/just_waveform.dart';
import 'package:music_music/data/database_helper.dart';
import 'package:music_music/models/music_model.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

enum PlayerState { playing, paused, stopped }

class PlaylistViewModel extends ChangeNotifier {
  final _player = AudioPlayer();
  final OnAudioQuery _audioQuery = OnAudioQuery();
  // Corrigido: Agora cria uma nova instância da classe
  final DatabaseHelper _dbHelper = DatabaseHelper();

  PlayerState _playerState = PlayerState.stopped;
  List<Music> _musics = [];
  Music? _currentMusic;

  bool _isShuffled = false;
  LoopMode _repeatMode = LoopMode.off;
  double _currentSpeed = 1.0;

  Timer? _sleepTimer;
  Duration? _sleepDuration;

  // Getters
  PlayerState get playerState => _playerState;
  List<Music> get musics => _musics;
  Music? get currentMusic => _currentMusic;
  bool get isShuffled => _isShuffled;
  LoopMode get repeatMode => _repeatMode;
  double get currentSpeed => _currentSpeed;
  Stream<Duration> get positionStream => _player.positionStream;

  Waveform? _currentWaveform;
  Waveform? get currentWaveform => _currentWaveform;

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

  Stream<SequenceState?> get sequenceStateStream => _player.sequenceStateStream;

  Duration? get sleepDuration => _sleepDuration;
  bool get hasSleepTimer => _sleepTimer != null && _sleepTimer!.isActive;

  PlaylistViewModel() {
    _initAudioSession();
    _listenToPlayerStateAndSequence();
  }
  
 

  // 🎵 Métodos de playlist (ajustados)
  Future<void> createPlaylist(String name) async {
    await _dbHelper.createPlaylist(name);
    notifyListeners();
  }

  Future<void> addMusicToPlaylist(int playlistId, Music music) async {
    await _dbHelper.addMusicToPlaylist(playlistId, music);
    notifyListeners();
  }

  Future<List<Map<String, dynamic>>> getPlaylists() async {
    return await _dbHelper.getPlaylists();
  }

  Future<List<Music>> getMusicsFromPlaylist(int playlistId) async {
    return await _dbHelper.getMusicsFromPlaylist(playlistId);
  }

  // NOVO MÉTODO: Remove uma música da playlist
  Future<void> removeMusicFromPlaylist(int playlistId, int musicId) async {
    await _dbHelper.removeMusicFromPlaylist(playlistId, musicId);
    notifyListeners();
  }

  Future<void> deletePlaylist(int playlistId) async {
    await _dbHelper.deletePlaylist(playlistId);
    notifyListeners(); // Notifica a UI sobre a mudança
  }

  // 🎵 Métodos de player e áudio (originais)
  // Carrega todas as músicas do banco de dados (ajustado para usar o DB)
  Future<void> loadAllMusics() async {
    _musics = await _dbHelper.getAllMusics();
    _setAudioSource();
    notifyListeners();
  }

  // Define músicas e cria playlist no player
  void setMusics(List<Music> musics, {int startIndex = 0}) {
    _musics = musics;
    _setAudioSource(initialIndex: startIndex);
    notifyListeners();
  }

  // Sessão de áudio
  Future<void> _initAudioSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
  }

  // Define playlist no player
  Future<void> _setAudioSource({int initialIndex = 0}) async {
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
                ? Uri.parse(
                    "content://media/external/audio/albumart/${music.albumId}",
                  )
                : Uri.parse("asset:///assets/images/notifica.png"),
          ),
        );
      }).toList(),
    );
    await _player.setAudioSource(
      playlist,
      initialIndex: initialIndex, // 👉 começa exatamente da música clicada
    );

    //await _player.setAudioSource(playlist);
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
          final newMusic = _musics[index];
          if (_currentMusic?.id != newMusic.id) {
            _currentMusic = newMusic;
            _generateWaveform(newMusic);
          }
          
        }
      } else {
        _currentMusic = null;
        _currentWaveform = null;
      }
      notifyListeners();
    });
  }

  StreamSubscription<WaveformProgress>? _waveformSub;

  Future<void> _generateWaveform(Music music) async {
  _currentWaveform = null;
  notifyListeners();

  try {
    if (music.data == null) {
      print("Music data path is null");
      return;
    }

    final audioFile = File(music.data!);
    if (!await audioFile.exists()) {
      print("Arquivo de áudio não existe: ${music.data}");
      return;
    }

    final waveFile = File(
      p.join((await getTemporaryDirectory()).path, '${p.basename(music.data!)}.wave'),
    );

    // Cancela assinatura anterior
    _waveformSub?.cancel();

    final stream = JustWaveform.extract(
      audioInFile: audioFile,
      waveOutFile: waveFile,
    );

    _waveformSub = stream.listen(
      (progress) {
        if (progress.waveform != null) {
          _currentWaveform = progress.waveform;
          notifyListeners();
        } else {
          print("Progresso: ${(progress.progress * 100).toStringAsFixed(0)}%");
        }
      },
      onError: (e) {
        print("Erro ao gerar waveform: $e");
        _currentWaveform = null;
        notifyListeners();
      },
    );
  } catch (e) {
    print("Error generating waveform: $e");
    _currentWaveform = null;
  }
  }





  // 🎵 Controles do player
  Future<void> play() async => await _player.play();
  Future<void> pause() async => await _player.pause();

  void playPause() {
    if (_player.playing) {
      pause();
    } else {
      play();
    }
  }

  Future<void> playMusic(List<Music> musics, int index) async {
  if (index < 0 || index >= musics.length) return;

  // Se a lista atual é diferente da nova, recria o AudioSource
  if (_musics.isEmpty || _musics.length != musics.length) {
    _musics = musics;
    await _setAudioSource(initialIndex: index);
    _currentMusic = _musics[index];
    notifyListeners();
    await play();
    return;
  }

  // Se a lista já é a mesma, apenas troca de índice
  _currentMusic = musics[index];
  notifyListeners();
  await _player.seek(Duration.zero, index: index);
  await play();
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
    if (_repeatMode == LoopMode.off) {
      _repeatMode = LoopMode.all;
      _player.setLoopMode(LoopMode.all);
    } else if (_repeatMode == LoopMode.all) {
      _repeatMode = LoopMode.one;
      _player.setLoopMode(LoopMode.one);
    } else {
      _repeatMode = LoopMode.off;
      _player.setLoopMode(LoopMode.off);
    }
    notifyListeners();
  }

  Future<void> setPlaybackSpeed(double speed) async {
    if (speed > 0.1 && speed <= 2.0) {
      _currentSpeed = speed;
      await _player.setSpeed(speed);
      notifyListeners();
    }
  }

  Future<List<Map<String, dynamic>>> getPlaylistsWithMusicCount() async {
    final playlists = await _dbHelper.getPlaylists();
    final playlistsWithCount = <Map<String, dynamic>>[];

    for (var playlist in playlists) {
      final playlistId = playlist['id'] as int;
      final musicCount = await _dbHelper.getMusicCountForPlaylist(playlistId);
      playlistsWithCount.add({
        'id': playlistId,
        'name': playlist['name'],
        'musicCount': musicCount,
      });
    }

    return playlistsWithCount;
  }

  // 😴 Métodos para o temporizador de desligamento
  void setSleepTimer(Duration duration) {
    _sleepTimer?.cancel();
    _sleepDuration = duration;
    notifyListeners();
    _sleepTimer = Timer(duration, () {
      pause();
      _sleepTimer = null;
      _sleepDuration = null;
      notifyListeners();
    });
  }

  void cancelSleepTimer() {
    if (_sleepTimer != null) {
      _sleepTimer!.cancel();
      _sleepTimer = null;
      _sleepDuration = null;
      notifyListeners();
    }
  }

  @override
  void dispose() {
     _waveformSub?.cancel();
    _sleepTimer?.cancel();
    _player.dispose();
    super.dispose();
  }
}
