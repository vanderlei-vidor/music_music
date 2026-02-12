import 'dart:typed_data';
import 'package:idb_shim/idb_browser.dart';

class WebAudioStore {
  static const _dbName = 'music_music_web';
  static const _storeName = 'audios';

  static Future<Database> _openDb() async {
    final factory = getIdbFactory()!;
    return factory.open(
      _dbName,
      version: 1,
      onUpgradeNeeded: (e) {
        final db = e.database;
        db.createObjectStore(_storeName, autoIncrement: true);
      },
    );
  }

  static Future<void> saveAudio(
    String name,
    Uint8List bytes,
  ) async {
    final db = await _openDb();
    final txn = db.transaction(_storeName, idbModeReadWrite);
    final store = txn.objectStore(_storeName);

    await store.add({
      'name': name,
      'bytes': bytes,
    });

    await txn.completed;
    db.close();
  }

  static Future<List<Map<String, dynamic>>> loadAudios() async {
    final db = await _openDb();
    final txn = db.transaction(_storeName, idbModeReadOnly);
    final store = txn.objectStore(_storeName);

    final result = <Map<String, dynamic>>[];

    await for (final cursor in store.openCursor(autoAdvance: true)) {
      result.add(cursor.value as Map<String, dynamic>);
    }

    await txn.completed;
    db.close();

    return result;
  }
}
