import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_music/app/routes.dart';

void main() {
  test('Base routes expose critical flow pages', () {
    expect(AppRoutes.baseRoutes.containsKey(AppRoutes.splash), isTrue);
    expect(AppRoutes.baseRoutes.containsKey(AppRoutes.home), isTrue);
    expect(AppRoutes.baseRoutes.containsKey(AppRoutes.player), isTrue);
    expect(AppRoutes.baseRoutes.containsKey(AppRoutes.playlists), isTrue);
    expect(AppRoutes.baseRoutes.containsKey(AppRoutes.favorites), isTrue);
    expect(AppRoutes.baseRoutes.containsKey(AppRoutes.trash), isTrue);
    expect(AppRoutes.baseRoutes.containsKey(AppRoutes.about), isTrue);
  });

  test('onGenerateRoute builds core routes', () {
    final homeRoute = AppRoutes.onGenerateRoute(
      const RouteSettings(name: AppRoutes.home),
    );
    final playerRoute = AppRoutes.onGenerateRoute(
      const RouteSettings(name: AppRoutes.player),
    );
    final favoritesRoute = AppRoutes.onGenerateRoute(
      const RouteSettings(name: AppRoutes.favorites),
    );

    expect(homeRoute, isA<PageRoute<dynamic>>());
    expect(playerRoute, isA<PageRoute<dynamic>>());
    expect(favoritesRoute, isA<PageRoute<dynamic>>());
  });

  test('onGenerateRoute falls back to unknown route safely', () {
    final route = AppRoutes.onGenerateRoute(
      const RouteSettings(name: '/not-registered'),
    );
    expect(route, isA<PageRoute<dynamic>>());
    expect(route.settings.name, '/not-registered');
  });
}
