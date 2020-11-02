import 'dart:async';

import '../../get_server.dart';
import 'route_config.dart';

mixin NodeMode {
  void get(String path, WidgetCallback build, {List<String> keys}) {
    RouteConfig.i.addRoute(Route(Method.get, path, build, keys: keys));
  }

  void post(String path, FutureOr Function(BuildContext context) build,
      {List<String> keys}) {
    RouteConfig.i.addRoute(Route(Method.post, path, build, keys: keys));
  }

  void delete(String path, FutureOr Function(BuildContext context) build,
      {List<String> keys}) {
    RouteConfig.i.addRoute(Route(Method.delete, path, build, keys: keys));
  }

  void put(String path, FutureOr Function(BuildContext context) build,
      {List<String> keys}) {
    RouteConfig.i.addRoute(Route(Method.put, path, build, keys: keys));
  }

  void ws(String path, FutureOr Function(BuildContext context) build,
      {List<String> keys}) {
    RouteConfig.i.addRoute(Route(Method.ws, path, build, keys: keys));
  }
}
