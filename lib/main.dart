import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'core/theme/app_colors.dart';
import 'views/splash/splash_view.dart';
import 'views/playlist/playlist_view_model.dart';
import 'views/home/home_view_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.example.music_music.channel.audio',
    androidNotificationChannelName: 'Music Playback',
    androidNotificationOngoing: true,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HomeViewModel(OnAudioQuery())),
        ChangeNotifierProvider(create: (_) => PlaylistViewModel()),
      ],
      child: MaterialApp(
        title: 'Music Music',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: AppColors.background,
        ),
        home: const SplashView(),
      ),
    );
  }
}
