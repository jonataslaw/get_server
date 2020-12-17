part of server;

mixin NodeMode {
  void get(String path, Widget build, {List<String> keys}) {
    _addRoute(Route(Method.get, path, build, keys: keys));
  }

  void post(String path, Widget build, {List<String> keys}) {
    _addRoute(Route(Method.post, path, build, keys: keys));
  }

  void delete(String path, Widget build, {List<String> keys}) {
    _addRoute(Route(Method.delete, path, build, keys: keys));
  }

  void put(String path, Widget build, {List<String> keys}) {
    _addRoute(Route(Method.put, path, build, keys: keys));
  }

  void ws(String path, Widget build, {List<String> keys}) {
    _addRoute(Route(Method.ws, path, build, keys: keys));
  }
}
