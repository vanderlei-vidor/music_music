import 'dart:isolate';
import 'package:music_music/data/models/music_entity.dart';

Future<List<MusicEntity>> scanInIsolate(
  Future<List<MusicEntity>> Function() task,
) async {
  final receivePort = ReceivePort();

  await Isolate.spawn(_entry, [receivePort.sendPort, task]);

  return await receivePort.first as List<MusicEntity>;
}

void _entry(List args) async {
  final SendPort sendPort = args[0];
  final Future<List<MusicEntity>> Function() task = args[1];

  final result = await task();
  sendPort.send(result);
}

