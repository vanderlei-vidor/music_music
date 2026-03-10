import 'package:music_music/data/models/music_entity.dart';

class PlaybackIssue {
  final DateTime when;
  final String stage;
  final String? audioUrl;
  final String? title;
  final String message;

  const PlaybackIssue({
    required this.when,
    required this.stage,
    required this.audioUrl,
    required this.title,
    required this.message,
  });

  factory PlaybackIssue.fromMusic({
    required String stage,
    required Object error,
    required MusicEntity? music,
  }) {
    return PlaybackIssue(
      when: DateTime.now(),
      stage: stage,
      audioUrl: music?.audioUrl,
      title: music?.title,
      message: error.toString(),
    );
  }
}
