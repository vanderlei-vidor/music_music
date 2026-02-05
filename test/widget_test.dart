// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_music/app/app.dart';
import 'package:music_music/app/routes.dart';
import 'test_route_observer.dart';


void main() {
  test('AppRoutes builds album route with args', () {
    final route = AppRoutes.onGenerateRoute(
      const RouteSettings(
        name: AppRoutes.albumDetail,
        arguments: AlbumDetailArgs(albumName: 'Test Album'),
      ),
    );

    expect(route, isA<PageRoute<dynamic>>());
    expect(route.settings.name, AppRoutes.albumDetail);
  });

  test('AppRoutes builds artist route with args', () {
    final route = AppRoutes.onGenerateRoute(
      const RouteSettings(
        name: AppRoutes.artistDetail,
        arguments: ArtistDetailArgs(artistName: 'Test Artist'),
      ),
    );

    expect(route, isA<PageRoute<dynamic>>());
    expect(route.settings.name, AppRoutes.artistDetail);
  });

  test('RouteObserver records push/pop events', () {
    final observer = TestRouteObserver();
    final route = PageRouteBuilder<void>(
      settings: const RouteSettings(name: AppRoutes.home),
      pageBuilder: (_, __, ___) => const SizedBox(),
    );

    observer.didPush(route, null);
    observer.didPop(route, null);

    expect(observer.events.length, 2);
    expect(observer.events.first, contains('push'));
    expect(observer.events.last, contains('pop'));
  });

  test('MusicApp accepts custom navigatorObservers', () {
    final observer = TestRouteObserver();
    final app = MusicApp(navigatorObservers: [observer]);
    expect(app, isA<MusicApp>());
  });
}
