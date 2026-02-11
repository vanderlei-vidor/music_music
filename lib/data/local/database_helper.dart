import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import 'package:music_music/data/models/music_entity.dart';

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'music_music.db');

    _database = await openDatabase(
      path,
      version: 23,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );

    return _database!;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
    CREATE TABLE musics_v2(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      artist TEXT NOT NULL,
      audioUrl TEXT NOT NULL UNIQUE,
      artworkUrl TEXT,
      duration INTEGER,
      album TEXT,
      genre TEXT,
      folderPath TEXT,
      isFavorite INTEGER NOT NULL DEFAULT 0,
      favoritedAt INTEGER,
      lastPlayedAt INTEGER,
      playCount INTEGER NOT NULL DEFAULT 0
    )
    ''');

    await db.execute('''
    CREATE TABLE playlists(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL
    )
    ''');

    await db.execute('''
    CREATE TABLE playlist_musics_v2(
      playlistId INTEGER,
      musicId INTEGER,
      PRIMARY KEY (playlistId, musicId)
    )
    ''');

    await db.execute('''
    CREATE TABLE playback_queue_state(
      id INTEGER PRIMARY KEY CHECK (id = 1),
      currentIndex INTEGER NOT NULL DEFAULT 0,
      positionMs INTEGER NOT NULL DEFAULT 0,
      updatedAt INTEGER
    )
    ''');

    await db.execute('''
    CREATE TABLE playback_queue_items(
      position INTEGER PRIMARY KEY,
      audioUrl TEXT NOT NULL
    )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 22) {
      await db
          .execute('ALTER TABLE musics_v2 ADD COLUMN folderPath TEXT')
          .catchError((_) {});

      await db
          .execute('ALTER TABLE musics_v2 ADD COLUMN genre TEXT')
          .catchError((_) {});

      await db
          .execute('ALTER TABLE musics_v2 ADD COLUMN lastPlayedAt INTEGER')
          .catchError((_) {});

      await db
          .execute(
            'ALTER TABLE musics_v2 ADD COLUMN playCount INTEGER NOT NULL DEFAULT 0',
          )
          .catchError((_) {});
    }

    if (oldVersion < 23) {
      await db
          .execute('''
        CREATE TABLE IF NOT EXISTS playback_queue_state(
          id INTEGER PRIMARY KEY CHECK (id = 1),
          currentIndex INTEGER NOT NULL DEFAULT 0,
          positionMs INTEGER NOT NULL DEFAULT 0,
          updatedAt INTEGER
        )
      ''')
          .catchError((_) {});

      await db
          .execute('''
        CREATE TABLE IF NOT EXISTS playback_queue_items(
          position INTEGER PRIMARY KEY,
          audioUrl TEXT NOT NULL
        )
      ''')
          .catchError((_) {});
    }
  }

  // =======================
  // MUSICS
  // =======================
  Future<List<MusicEntity>> getAllMusicsV2() async {
    final db = await database;
    final result = await db.query('musics_v2');
    return result.map((e) => MusicEntity.fromMap(e)).toList();
  }

  Future<int> insertMusicV2(MusicEntity music) async {
    final db = await database;

    return db.insert('musics_v2', {
      'title': music.title,
      'artist': music.artist,
      'audioUrl': music.audioUrl,
      'artworkUrl': music.artworkUrl,
      'duration': music.duration,
      'album': music.album,
      'genre': music.genre,
      'folderPath': music.folderPath,
      'isFavorite': music.isFavorite ? 1 : 0,
      'lastPlayedAt': music.lastPlayedAt,
      'playCount': music.playCount,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  // =======================
  // PLAYLISTS
  // =======================
  Future<void> createPlaylist(String name) async {
    final db = await database;
    await db.insert('playlists', {'name': name});
  }

  Future<List<Map<String, dynamic>>> getPlaylists() async {
    final db = await database;
    return db.query('playlists');
  }

  Future<void> deletePlaylist(int playlistId) async {
    final db = await database;
    await db.delete('playlists', where: 'id = ?', whereArgs: [playlistId]);
  }

  // =======================
  // PLAYLIST ↔ MUSICS
  // =======================
  Future<void> addMusicToPlaylistV2(int playlistId, int musicId) async {
    final db = await database;
    await db.insert('playlist_musics_v2', {
      'playlistId': playlistId,
      'musicId': musicId,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<void> removeMusicFromPlaylistV2(int playlistId, int musicId) async {
    final db = await database;
    await db.delete(
      'playlist_musics_v2',
      where: 'playlistId = ? AND musicId = ?',
      whereArgs: [playlistId, musicId],
    );
  }

  Future<List<MusicEntity>> getMusicsFromPlaylistV2(int playlistId) async {
    final db = await database;

    final result = await db.rawQuery(
      '''
      SELECT m.* FROM musics_v2 m
      INNER JOIN playlist_musics_v2 pm
        ON m.id = pm.musicId
      WHERE pm.playlistId = ?
    ''',
      [playlistId],
    );

    return result.map((e) => MusicEntity.fromMap(e)).toList();
  }

  Future<int> getMusicCountForPlaylist(int playlistId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) FROM playlist_musics_v2 WHERE playlistId = ?',
      [playlistId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> toggleFavorite(String audioUrl, bool isFavorite) async {
    final db = await database;
    await db.update(
      'musics_v2',
      {'isFavorite': isFavorite ? 1 : 0},
      where: 'audioUrl = ?',
      whereArgs: [audioUrl],
    );
  }

  Future<List<MusicEntity>> getFavoriteMusics() async {
    final db = await database;

    final result = await db.query(
      'musics_v2',
      where: 'isFavorite = ?',
      whereArgs: [1],
    );

    return result.map((e) => MusicEntity.fromMap(e)).toList();
  }

  // =======================
  // HISTÓRICO MUSICAS
  // =======================

  Future<List<MusicEntity>> getRecentMusics() async {
    final db = await database;

    final result = await db.query(
      'musics_v2',
      where: 'lastPlayedAt IS NOT NULL',
      orderBy: 'lastPlayedAt DESC',
      limit: 100,
    );

    return result.map((e) => MusicEntity.fromMap(e)).toList();
  }

  Future<void> registerRecentPlay(int musicId) async {
    final db = await database;

    await db.update(
      'musics_v2',
      {'lastPlayedAt': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [musicId],
    );
  }

  Future<void> clearRecentHistory() async {
    final db = await database;

    await db.update('musics_v2', {'lastPlayedAt': null});
  }

  Future<void> updateLastPlayed(int id) async {
    final db = await database;
    await db.update(
      'musics_v2',
      {'lastPlayedAt': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> incrementPlayCount(int musicId) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE musics_v2 SET playCount = playCount + 1 WHERE id = ?',
      [musicId],
    );
  }

  Future<List<MusicEntity>> getMostPlayed({int limit = 20}) async {
    final db = await database;

    final result = await db.query(
      'musics_v2',
      orderBy: 'playCount DESC',
      limit: limit,
    );

    return result.map((e) => MusicEntity.fromMap(e)).toList();
  }

  Future<void> insertMusicIfNotExists(MusicEntity music) async {
  final db = await database;

  final existing = await db.query(
    'musics_v2',
    where: 'audioUrl = ?',
    whereArgs: [music.audioUrl],
    limit: 1,
  );

  if (existing.isNotEmpty) {
    final currentFolder = existing.first['folderPath'];

    // 🔥 atualiza APENAS se estiver null ou vazio
    if (currentFolder == null || (currentFolder as String).isEmpty) {
      await db.update(
        'musics_v2',
        {'folderPath': music.folderPath},
        where: 'audioUrl = ?',
        whereArgs: [music.audioUrl],
      );
    }

    return;
  }

  // ➕ INSERE SE NÃO EXISTIR
  await db.insert(
    'musics_v2',
    {
      'title': music.title,
      'artist': music.artist,
      'album': music.album,
      'genre': music.genre,
      'folderPath': music.folderPath,
      'audioUrl': music.audioUrl,
      'artworkUrl': music.artworkUrl,
      'duration': music.duration,
      'isFavorite': music.isFavorite ? 1 : 0,
      'lastPlayedAt': null,
      'playCount': 0,
    },
    conflictAlgorithm: ConflictAlgorithm.ignore,
  );
}

  // =======================
  // PLAYBACK QUEUE STATE
  // =======================
  Future<void> savePlaybackQueue({
    required List<String> audioUrls,
    required int currentIndex,
    required int positionMs,
  }) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('playback_queue_items');
      for (var i = 0; i < audioUrls.length; i++) {
        await txn.insert('playback_queue_items', {
          'position': i,
          'audioUrl': audioUrls[i],
        });
      }

      await txn.insert('playback_queue_state', {
        'id': 1,
        'currentIndex': currentIndex,
        'positionMs': positionMs,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    });
  }

  Future<Map<String, dynamic>?> loadPlaybackQueue() async {
    final db = await database;
    final state = await db.query(
      'playback_queue_state',
      where: 'id = ?',
      whereArgs: [1],
      limit: 1,
    );
    if (state.isEmpty) return null;

    final items = await db.query(
      'playback_queue_items',
      orderBy: 'position ASC',
    );

    return {
      'currentIndex': state.first['currentIndex'] as int? ?? 0,
      'positionMs': state.first['positionMs'] as int? ?? 0,
      'audioUrls': items.map((e) => e['audioUrl'] as String).toList(),
    };
  }

  Future<void> clearPlaybackQueue() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('playback_queue_items');
      await txn.delete('playback_queue_state', where: 'id = ?', whereArgs: [1]);
    });
  }

}

