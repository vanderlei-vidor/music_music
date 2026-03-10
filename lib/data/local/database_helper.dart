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
      version: 27,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );

    return _database!;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
    CREATE TABLE musics_v2(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      sourceId INTEGER,
      title TEXT NOT NULL,
      artist TEXT NOT NULL,
      audioUrl TEXT NOT NULL UNIQUE,
      artworkUrl TEXT,
      duration INTEGER,
      album TEXT,
      genre TEXT,
      mediaType TEXT,
      folderPath TEXT,
      isDeleted INTEGER NOT NULL DEFAULT 0,
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

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_musics_favorite ON musics_v2(isFavorite)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_musics_lastPlayedAt ON musics_v2(lastPlayedAt)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_musics_playCount ON musics_v2(playCount)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_playlist_musics_playlistId ON playlist_musics_v2(playlistId)',
    );
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

    if (oldVersion < 24) {
      await db
          .execute(
            'CREATE INDEX IF NOT EXISTS idx_musics_favorite ON musics_v2(isFavorite)',
          )
          .catchError((_) {});
      await db
          .execute(
            'CREATE INDEX IF NOT EXISTS idx_musics_lastPlayedAt ON musics_v2(lastPlayedAt)',
          )
          .catchError((_) {});
      await db
          .execute(
            'CREATE INDEX IF NOT EXISTS idx_musics_playCount ON musics_v2(playCount)',
          )
          .catchError((_) {});
      await db
          .execute(
            'CREATE INDEX IF NOT EXISTS idx_playlist_musics_playlistId ON playlist_musics_v2(playlistId)',
          )
          .catchError((_) {});
    }

    if (oldVersion < 25) {
      await db
          .execute('ALTER TABLE musics_v2 ADD COLUMN sourceId INTEGER')
          .catchError((_) {});
    }

    if (oldVersion < 26) {
      await db
          .execute('ALTER TABLE musics_v2 ADD COLUMN mediaType TEXT')
          .catchError((_) {});
    }

    if (oldVersion < 27) {
      await db
          .execute(
            'ALTER TABLE musics_v2 ADD COLUMN isDeleted INTEGER NOT NULL DEFAULT 0',
          )
          .catchError((_) {});
    }
  }

  // =======================
  // MUSICS
  // =======================
  Future<List<MusicEntity>> getAllMusicsV2() async {
    final db = await database;
    final result = await db.query(
      'musics_v2',
      where: 'isDeleted IS NULL OR isDeleted = 0',
    );
    return result.map((e) => MusicEntity.fromMap(e)).toList();
  }

  Future<List<MusicEntity>> getDeletedMusicsV2() async {
    final db = await database;
    final result = await db.query(
      'musics_v2',
      where: 'isDeleted = 1',
    );
    return result.map((e) => MusicEntity.fromMap(e)).toList();
  }

  Future<MusicEntity?> getMusicByAudioUrl(String audioUrl) async {
    final db = await database;
    final result = await db.query(
      'musics_v2',
      where: 'audioUrl = ?',
      whereArgs: [audioUrl],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return MusicEntity.fromMap(result.first);
  }

  Future<int> insertMusicV2(MusicEntity music) async {
    final db = await database;

    return db.insert('musics_v2', {
      'title': music.title,
      'sourceId': music.sourceId,
      'artist': music.artist,
      'audioUrl': music.audioUrl,
      'artworkUrl': music.artworkUrl,
      'duration': music.duration,
      'album': music.album,
      'genre': music.genre,
      'mediaType': music.mediaType,
      'folderPath': music.folderPath,
      'isDeleted': 0,
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

  Future<List<Map<String, dynamic>>> getPlaylistsWithMusicCount() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT
        p.id AS id,
        p.name AS name,
        COUNT(pm.musicId) AS musicCount
      FROM playlists p
      LEFT JOIN playlist_musics_v2 pm
        ON pm.playlistId = p.id
      GROUP BY p.id, p.name
      ORDER BY LOWER(p.name) ASC
    ''');
    return result
        .map(
          (row) => {
            'id': row['id'] as int,
            'name': row['name'] as String,
            'musicCount': (row['musicCount'] as int?) ?? 0,
          },
        )
        .toList();
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
      where: 'isFavorite = ? AND (isDeleted IS NULL OR isDeleted = 0)',
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
      where: 'lastPlayedAt IS NOT NULL AND (isDeleted IS NULL OR isDeleted = 0)',
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
      where: 'isDeleted IS NULL OR isDeleted = 0',
      orderBy: 'playCount DESC',
      limit: limit,
    );

    return result.map((e) => MusicEntity.fromMap(e)).toList();
  }

  Future<int> reprocessGenresBatch() async {
    final db = await database;
    return db.transaction((txn) async {
      final rows = await txn.query(
        'musics_v2',
        columns: ['audioUrl', 'title', 'artist', 'album', 'folderPath', 'genre'],
        where: '(isDeleted IS NULL OR isDeleted = 0) AND (genre IS NULL OR TRIM(genre) = \'\')',
      );

      var updated = 0;
      for (final row in rows) {
        final inferred = _inferGenreForRow(row);
        if (inferred == null || inferred.isEmpty) continue;
        await txn.update(
          'musics_v2',
          {'genre': inferred},
          where: 'audioUrl = ?',
          whereArgs: [row['audioUrl']],
        );
        updated += 1;
      }
      return updated;
    });
  }

  Future<void> insertMusicIfNotExists(MusicEntity music) async {
    final db = await database;
    await _upsertMusicIfNeeded(db, music);
  }

  Future<void> insertMusicsIfNotExistsBatch(List<MusicEntity> musics) async {
    if (musics.isEmpty) return;
    final db = await database;
    await db.transaction((txn) async {
      for (final music in musics) {
        await _upsertMusicIfNeeded(txn, music);
      }
    });
  }

  Future<void> _upsertMusicIfNeeded(
    DatabaseExecutor executor,
    MusicEntity music,
  ) async {
    final existing = await executor.query(
      'musics_v2',
      where: 'audioUrl = ?',
      whereArgs: [music.audioUrl],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      final updates = <String, Object?>{};
      final currentFolder = existing.first['folderPath'];
      if (currentFolder == null || (currentFolder as String).isEmpty) {
        updates['folderPath'] = music.folderPath;
      }
      final currentSourceId = existing.first['sourceId'] as int?;
      if (currentSourceId == null && music.sourceId != null) {
        updates['sourceId'] = music.sourceId;
      }
      final currentMediaType = existing.first['mediaType'] as String?;
      if ((currentMediaType == null || currentMediaType.isEmpty) &&
          music.mediaType != null &&
          music.mediaType!.isNotEmpty) {
        updates['mediaType'] = music.mediaType;
      }
      final currentGenre = (existing.first['genre'] as String?)?.trim();
      if ((currentGenre == null || currentGenre.isEmpty) &&
          music.genre != null &&
          music.genre!.trim().isNotEmpty) {
        updates['genre'] = music.genre;
      }
      final isDeleted = existing.first['isDeleted'] as int?;
      if (isDeleted == 1) {
        return;
      }
      if (updates.isNotEmpty) {
        await executor.update(
          'musics_v2',
          updates,
          where: 'audioUrl = ?',
          whereArgs: [music.audioUrl],
        );
      }
      return;
    }

    await executor.insert('musics_v2', {
      'title': music.title,
      'sourceId': music.sourceId,
      'artist': music.artist,
      'album': music.album,
      'genre': music.genre,
      'mediaType': music.mediaType,
      'folderPath': music.folderPath,
      'isDeleted': 0,
      'audioUrl': music.audioUrl,
      'artworkUrl': music.artworkUrl,
      'duration': music.duration,
      'isFavorite': music.isFavorite ? 1 : 0,
      'lastPlayedAt': null,
      'playCount': 0,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<LibrarySyncResult> syncMusicsFromScan(List<MusicEntity> scanned) async {
    final db = await database;
    if (scanned.isEmpty) {
      return const LibrarySyncResult();
    }

    return db.transaction((txn) async {
      final existingRows = await txn.query(
        'musics_v2',
        columns: [
          'id',
          'audioUrl',
          'sourceId',
          'title',
          'artist',
          'album',
          'duration',
          'genre',
          'mediaType',
          'folderPath',
          'isDeleted',
        ],
      );

      final existingByUrl = <String, Map<String, Object?>>{
        for (final row in existingRows) (row['audioUrl'] as String): row,
      };

      final scannedByUrl = <String, MusicEntity>{
        for (final music in scanned) music.audioUrl: music,
      };

      var added = 0;
      var restored = 0;
      var updated = 0;
      var removed = 0;

      for (final music in scannedByUrl.values) {
        final row = existingByUrl[music.audioUrl];
        if (row == null) {
          await txn.insert('musics_v2', {
            'title': music.title,
            'sourceId': music.sourceId,
            'artist': music.artist,
            'album': music.album,
            'genre': music.genre,
            'mediaType': music.mediaType,
            'folderPath': music.folderPath,
            'isDeleted': 0,
            'audioUrl': music.audioUrl,
            'artworkUrl': music.artworkUrl,
            'duration': music.duration,
            'isFavorite': music.isFavorite ? 1 : 0,
            'lastPlayedAt': null,
            'playCount': 0,
          }, conflictAlgorithm: ConflictAlgorithm.ignore);
          added += 1;
          continue;
        }

        final changes = <String, Object?>{};
        final isDeleted = (row['isDeleted'] as int?) ?? 0;
        if (isDeleted == 1) {
          changes['isDeleted'] = 0;
          restored += 1;
        }

        if (_asInt(row['sourceId']) != music.sourceId && music.sourceId != null) {
          changes['sourceId'] = music.sourceId;
        }
        if (_asString(row['title']) != music.title) {
          changes['title'] = music.title;
        }
        if (_asString(row['artist']) != music.artist) {
          changes['artist'] = music.artist;
        }
        if (_asNullableString(row['album']) != music.album) {
          changes['album'] = music.album;
        }
        if (_asInt(row['duration']) != music.duration) {
          changes['duration'] = music.duration;
        }
        if (_asNullableString(row['folderPath']) != music.folderPath &&
            (music.folderPath?.isNotEmpty ?? false)) {
          changes['folderPath'] = music.folderPath;
        }
        final existingGenre = _asNullableString(row['genre']);
        final incomingGenre = music.genre?.trim();
        if ((existingGenre == null || existingGenre.isEmpty) &&
            incomingGenre != null &&
            incomingGenre.isNotEmpty) {
          changes['genre'] = incomingGenre;
        }
        final existingMediaType = _asNullableString(row['mediaType']);
        if ((existingMediaType == null || existingMediaType.isEmpty) &&
            (music.mediaType?.isNotEmpty ?? false)) {
          changes['mediaType'] = music.mediaType;
        }

        if (changes.isNotEmpty) {
          await txn.update(
            'musics_v2',
            changes,
            where: 'audioUrl = ?',
            whereArgs: [music.audioUrl],
          );
          updated += 1;
        }
      }

      final activeRows = existingRows.where(
        (row) => ((row['isDeleted'] as int?) ?? 0) == 0,
      );
      for (final row in activeRows) {
        final audioUrl = row['audioUrl'] as String;
        if (scannedByUrl.containsKey(audioUrl)) continue;

        await txn.update(
          'musics_v2',
          {'isDeleted': 1, 'isFavorite': 0},
          where: 'audioUrl = ?',
          whereArgs: [audioUrl],
        );
        await txn.delete(
          'playback_queue_items',
          where: 'audioUrl = ?',
          whereArgs: [audioUrl],
        );
        removed += 1;
      }

      final unchanged = scannedByUrl.length - added - restored - updated;
      return LibrarySyncResult(
        added: added,
        restored: restored,
        updated: updated,
        removed: removed,
        unchanged: unchanged < 0 ? 0 : unchanged,
      );
    });
  }

  Future<void> updateMediaType(String audioUrl, String? mediaType) async {
    final db = await database;
    await db.update(
      'musics_v2',
      {'mediaType': mediaType},
      where: 'audioUrl = ?',
      whereArgs: [audioUrl],
    );
  }

  Future<void> deleteMusicByAudioUrl(String audioUrl) async {
    final db = await database;
    await db.transaction((txn) async {
      final found = await txn.query(
        'musics_v2',
        columns: ['id'],
        where: 'audioUrl = ?',
        whereArgs: [audioUrl],
        limit: 1,
      );

      final musicId = found.isNotEmpty ? found.first['id'] as int? : null;
      if (musicId != null) {
        await txn.delete(
          'playlist_musics_v2',
          where: 'musicId = ?',
          whereArgs: [musicId],
        );
      }

      await txn.delete(
        'playback_queue_items',
        where: 'audioUrl = ?',
        whereArgs: [audioUrl],
      );

      await txn.update(
        'musics_v2',
        {'isDeleted': 1, 'isFavorite': 0},
        where: 'audioUrl = ?',
        whereArgs: [audioUrl],
      );
    });
  }

  Future<void> restoreMusicByAudioUrl(String audioUrl) async {
    final db = await database;
    await db.update(
      'musics_v2',
      {'isDeleted': 0},
      where: 'audioUrl = ?',
      whereArgs: [audioUrl],
    );
  }

  Future<void> permanentlyDeleteMusicByAudioUrl(String audioUrl) async {
    final db = await database;
    await db.transaction((txn) async {
      final found = await txn.query(
        'musics_v2',
        columns: ['id'],
        where: 'audioUrl = ?',
        whereArgs: [audioUrl],
        limit: 1,
      );

      final musicId = found.isNotEmpty ? found.first['id'] as int? : null;
      if (musicId != null) {
        await txn.delete(
          'playlist_musics_v2',
          where: 'musicId = ?',
          whereArgs: [musicId],
        );
      }

      await txn.delete(
        'playback_queue_items',
        where: 'audioUrl = ?',
        whereArgs: [audioUrl],
      );

      await txn.delete(
        'musics_v2',
        where: 'audioUrl = ? AND isDeleted = 1',
        whereArgs: [audioUrl],
      );
    });
  }

  Future<int> permanentlyDeleteAllDeletedMusics() async {
    final db = await database;
    return db.transaction((txn) async {
      final removedRows = await txn.query(
        'musics_v2',
        columns: ['id', 'audioUrl'],
        where: 'isDeleted = 1',
      );
      if (removedRows.isEmpty) return 0;

      for (final row in removedRows) {
        final musicId = row['id'] as int?;
        final audioUrl = row['audioUrl'] as String?;
        if (musicId != null) {
          await txn.delete(
            'playlist_musics_v2',
            where: 'musicId = ?',
            whereArgs: [musicId],
          );
        }
        if (audioUrl != null && audioUrl.isNotEmpty) {
          await txn.delete(
            'playback_queue_items',
            where: 'audioUrl = ?',
            whereArgs: [audioUrl],
          );
        }
      }

      final deletedCount = await txn.delete(
        'musics_v2',
        where: 'isDeleted = 1',
      );
      return deletedCount;
    });
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

  String? _inferGenreForRow(Map<String, Object?> row) {
    final folder = row['folderPath']?.toString().trim();
    if (folder != null && folder.isNotEmpty) {
      final normalized = folder.replaceAll('\\', '/');
      final segments = normalized
          .split('/')
          .where((segment) => segment.trim().isNotEmpty)
          .toList();
      if (segments.isNotEmpty) return segments.last.trim();
    }

    final text = _normalizeText(
      '${row['title'] ?? ''} ${row['artist'] ?? ''} ${row['album'] ?? ''}',
    );

    if (_containsAnyToken(text, const ['mozart', 'bach', 'beethoven', 'chopin'])) {
      return 'Classica';
    }
    if (_containsAnyToken(text, const ['samba', 'pagode', 'axe'])) {
      return 'Samba/Pagode';
    }
    if (_containsAnyToken(text, const ['forro', 'piseiro', 'sertanejo', 'arrocha'])) {
      return 'Sertanejo/Forro';
    }
    if (_containsAnyToken(text, const ['gospel', 'worship', 'louvor'])) {
      return 'Gospel';
    }
    if (_containsAnyToken(text, const ['rock', 'metal', 'punk'])) {
      return 'Rock';
    }
    if (_containsAnyToken(text, const ['funk', 'trap', 'hip hop', 'rap'])) {
      return 'Hip Hop/Funk';
    }
    if (_containsAnyToken(text, const ['jazz', 'blues', 'bossa'])) {
      return 'Jazz/Blues';
    }
    return null;
  }

  String _normalizeText(String value) {
    final lowercase = value.toLowerCase();
    final sb = StringBuffer();
    const map = {
      'á': 'a',
      'à': 'a',
      'â': 'a',
      'ã': 'a',
      'ä': 'a',
      'é': 'e',
      'è': 'e',
      'ê': 'e',
      'ë': 'e',
      'í': 'i',
      'ì': 'i',
      'î': 'i',
      'ï': 'i',
      'ó': 'o',
      'ò': 'o',
      'ô': 'o',
      'õ': 'o',
      'ö': 'o',
      'ú': 'u',
      'ù': 'u',
      'û': 'u',
      'ü': 'u',
      'ç': 'c',
    };
    for (final rune in lowercase.runes) {
      final ch = String.fromCharCode(rune);
      sb.write(map[ch] ?? ch);
    }
    return sb.toString();
  }

  bool _containsAnyToken(String value, List<String> tokens) {
    for (final token in tokens) {
      if (value.contains(token)) return true;
    }
    return false;
  }

  static String _asString(Object? value) => value?.toString() ?? '';
  static String? _asNullableString(Object? value) => value?.toString();
  static int? _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }
}

class LibrarySyncResult {
  final int added;
  final int restored;
  final int updated;
  final int removed;
  final int unchanged;

  const LibrarySyncResult({
    this.added = 0,
    this.restored = 0,
    this.updated = 0,
    this.removed = 0,
    this.unchanged = 0,
  });

  int get changed => added + restored + updated + removed;
}
