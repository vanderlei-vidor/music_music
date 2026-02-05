import 'package:flutter/widgets.dart';

class TestRouteObserver extends RouteObserver<PageRoute<dynamic>> {
  final List<String> events = [];

  @override
  void didPush(Route route, Route? previousRoute) {
    super.didPush(route, previousRoute);
    events.add('push:${route.settings.name ?? route.runtimeType}');
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    super.didPop(route, previousRoute);
    events.add('pop:${route.settings.name ?? route.runtimeType}');
  }
}
