part of server;

class RouteConfig {
  final _pages = <Route>[];

  static final i = RouteConfig();
  void addRoutes(List<GetPage> getPages) {
    for (final route in getPages) {
      addRoute(
        Route(
          route.method,
          route.path,
          route.page!(),
          binding: route.binding,
          needAuth: route.needAuth,
        ),
      );
    }
  }

  void addRoute(Route route) {
    _pages.add(route);
  }

  Route? findRoute(HttpRequest req) {
    final route = _pages.firstWhereOrNull(
      (route) => RouteParser.match(
        req.uri.path,
        req.method,
        route.method,
        route.path,
      ),
    );

    return route;
  }
}
