part of server;

class NodeWidgetWrapper extends StatelessWidget {
  const NodeWidgetWrapper({Key? key, required this.builder}) : super(key: key);
  final Widget Function(BuildContext context) builder;

  @override
  Widget build(BuildContext context) {
    return builder(context);
  }
}

mixin NodeMode {
  void get(String name, NodeWidgetCallback build, {List<String?>? keys}) {
    final path = RouteParser.normalize(name, keys: keys);
    RouteConfig.i.addRoute(Route(
      Method.get,
      path,
      NodeWidgetWrapper(
        builder: (context) => build(context),
      ),
    ));
  }

  void post(String name, NodeWidgetCallback build, {List<String?>? keys}) {
    final path = RouteParser.normalize(name, keys: keys);
    RouteConfig.i.addRoute(Route(
      Method.post,
      path,
      NodeWidgetWrapper(
        builder: (context) => build(context),
      ),
    ));
  }

  void delete(String name, NodeWidgetCallback build, {List<String?>? keys}) {
    final path = RouteParser.normalize(name, keys: keys);
    RouteConfig.i.addRoute(Route(
      Method.delete,
      path,
      NodeWidgetWrapper(
        builder: (context) => build(context),
      ),
    ));
  }

  void put(String name, NodeWidgetCallback build, {List<String?>? keys}) {
    final path = RouteParser.normalize(name, keys: keys);
    RouteConfig.i.addRoute(Route(
      Method.put,
      path,
      NodeWidgetWrapper(
        builder: (context) => build(context),
      ),
    ));
  }

  void ws(String name, SocketBuilder build, {List<String?>? keys}) {
    final path = RouteParser.normalize(name, keys: keys);
    RouteConfig.i.addRoute(Route(
      Method.ws,
      path,
      NodeWidgetWrapper(
        builder: (context) => Socket(builder: build),
      ),
    ));
  }
}
