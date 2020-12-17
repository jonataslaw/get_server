part of server;

mixin NodeMode {
  void get(String name, WidgetCallback build, {List<String> keys}) {
    final path = RouteParser.normalize(name, keys: keys);
    RouteConfig.i.addRoute(Route(Method.get, path, build()));
  }

  void post(String name, WidgetCallback build, {List<String> keys}) {
    final path = RouteParser.normalize(name, keys: keys);
    RouteConfig.i.addRoute(Route(Method.post, path, build()));
  }

  void delete(String name, WidgetCallback build, {List<String> keys}) {
    final path = RouteParser.normalize(name, keys: keys);
    RouteConfig.i.addRoute(Route(Method.delete, path, build()));
  }

  void put(String name, WidgetCallback build, {List<String> keys}) {
    final path = RouteParser.normalize(name, keys: keys);
    RouteConfig.i.addRoute(Route(Method.put, path, build()));
  }

  void ws(String name, WidgetCallback build, {List<String> keys}) {
    final path = RouteParser.normalize(name, keys: keys);
    RouteConfig.i.addRoute(Route(Method.ws, path, build()));
  }
}
