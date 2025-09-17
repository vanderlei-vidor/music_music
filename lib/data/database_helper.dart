import 'dart:io';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../models/music_model.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseHelper {
  static Database? _database;
  

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
  // Use sqflite_common_ffi para desktop
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  
  // O restante do seu código pode permanecer o mesmo, pois o 'getDatabasesPath()' e o 'join()' já são compatíveis.
  final dbPath = await getDatabasesPath();
  final path = join(dbPath, 'music_music.db');
  
  return await openDatabase(
    path,
    version: 2,
    onCreate: _onCreate,
    onUpgrade: _onUpgrade,
  );
}

// Added onUpgrade to migrate the database
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE musics ADD COLUMN data TEXT');
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE musics(
        id INTEGER PRIMARY KEY,
        title TEXT,
        artist TEXT,
        uri TEXT,
        data TEXT,
        duration INTEGER,
        albumId INTEGER,
        album TEXT,
        albumArtUri TEXT
      )
    ''');
    
    await db.execute('''
      CREATE TABLE playlists(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT
      )
    ''');
    
    // Tabela corrigida para "playlist_musics"
    await db.execute('''
      CREATE TABLE playlist_musics(
        playlistId INTEGER,
        musicId INTEGER,
        FOREIGN KEY(playlistId) REFERENCES playlists(id) ON DELETE CASCADE,
        FOREIGN KEY(musicId) REFERENCES musics(id) ON DELETE CASCADE,
        PRIMARY KEY (playlistId, musicId)
      )
    ''');
  }

  // ✅ CORRIGIDO: Este método agora só lê do banco de dados.
  // A lógica de popular o banco foi movida para o MusicService.
  Future<List<Music>> getAllMusics() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('musics');

    return List.generate(maps.length, (i) {
      return Music.fromMap(maps[i]);
    });
  }

  // ✅ NOVO: Método para inserir uma música no banco de dados
  Future<void> insertMusic(Music music) async {
    final db = await database;
    await db.insert(
      'musics',
      music.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace, // Substitui se o ID já existir
    );
  }
  Future<bool> musicExists(int id) async {
  final db = await database;
  final result = await db.query(
    'musics',
    where: 'id = ?',
    whereArgs: [id],
    limit: 1,
  );
  return result.isNotEmpty;
}

  // Método para criar uma nova playlist
  Future<void> createPlaylist(String playlistName) async {
    final db = await database;
    try {
      await db.insert(
        'playlists',
        {'name': playlistName},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      print('Erro ao criar a playlist: $e');
    }
  }

  // Método para obter todas as playlists
  Future<List<Map<String, dynamic>>> getPlaylists() async {
    final db = await database;
    return await db.query('playlists');
  }

  // Método para adicionar uma música a uma playlist
  Future<void> addMusicToPlaylist(int playlistId, Music music) async {
    final db = await database;
    await db.insert(
      'playlist_musics',
      {'playlistId': playlistId, 'musicId': music.id},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  // Método para obter as músicas de uma playlist
  Future<List<Music>> getMusicsFromPlaylist(int playlistId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT T1.* FROM musics T1
      INNER JOIN playlist_musics T2 ON T1.id = T2.musicId
      WHERE T2.playlistId = ?
    ''', [playlistId]);
    
    return List.generate(maps.length, (i) {
      return Music.fromMap(maps[i]);
    });
  }
  
  // NOVO MÉTODO: Remove uma música de uma playlist no banco de dados
  Future<void> removeMusicFromPlaylist(int playlistId, int musicId) async {
    final db = await database;
    await db.delete(
      'playlist_musics',
      where: 'playlistId = ? AND musicId = ?',
      whereArgs: [playlistId, musicId],
    );
  }
  Future<void> deletePlaylist(int playlistId) async {
    final db = await database;
    await db.delete(
      'playlists',
      where: 'id = ?',
      whereArgs: [playlistId],
    );
  }
  // Adicione este método na classe DatabaseHelper
  Future<int> getMusicCountForPlaylist(int playlistId) async {  
    final db = await database;
    final count = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM playlist_musics WHERE playlistId = ?',
    [playlistId],
    ));
    return count ?? 0;
  }
}
