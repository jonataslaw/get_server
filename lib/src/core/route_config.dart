import 'dart:io' as io;

import '../../get_server.dart';
import '../routes/get_page.dart';

class RouteConfig {
  final routes = <Route>[];
  static final i = RouteConfig();
  void addRoutes(List<GetPage> getPages) {
    for (final route in getPages) {
      addRoute(
        Route(
          route.method,
          route.name,
          route?.page()?.build,
          binding: route.binding,
          keys: route.keys,
          needAuth: route.needAuth,
        ),
      );
    }
  }

  void addRoute(Route route) {
    routes.add(route);
  }

  Route findRoute(io.HttpRequest req) {
    final route = routes.firstWhere(
      (route) => route.match(req),
      orElse: () => null,
    );
    return route;
  }
}
