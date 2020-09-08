import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import '../context/context_request.dart';
import '../context/context_response.dart';
import '../socket/socket.dart';

enum Method {
  post,
  get,
  put,
  delete,
  ws,
  options,
}

typedef RouteCall<Context> = Function(Context context);
typedef Disposer = Function();

class Context {
  Context(this.request, this.socketStream);
  ContextResponse get response => request.response;
  final ContextRequest request;
  final Stream<GetSocket> socketStream;

  Stream<GetSocket> get ws => socketStream;

  Future send(string) {
    return response.send(string);
  }

  Future<MultipartUpload> file(String name, {Encoding encoder = utf8}) async {
    final payload = await request.payload(encoder: encoder);
    final multiPart = await payload[name];
    return multiPart;
  }

  Future sendJson(Object string) {
    return response
        .header('Content-Type', 'application/json; charset=UTF-8')
        .sendJson(string);
  }

  Future sendHtml(String path) {
    response.header('Content-Type', 'text/html; charset=UTF-8');
    return response.sendFile(path);
  }

  String param(String name) => request.param(name);

  Future<Map> payload({Encoding encoder = utf8}) =>
      request.payload(encoder: encoder);
}

class RouteValue<Context> {
  RouteValue([Context initial]) {
    _value = initial;
  }
  final _updaters = HashSet<RouteCall<Context>>();

  Context _value;

  Context get value => _value;

  set value(Context v) {
    _value = v;
    update();
  }

  Disposer addListener(RouteCall<Context> listener) {
    _updaters.add(listener);
    return () => _updaters.remove(listener);
  }

  update() {
    _updaters.forEach((element) {
      element(_value);
    });
  }
}

String enumValueToString(Object o) => o.toString().split('.').last;

class Route {
  final requestController = RouteValue<Context>();
  final _socketController = StreamController<HttpRequest>();
  // Stream<ContextRequest> requestStream;
  Stream<GetSocket> socketStream;
  final Method _method;
  final Map _path;

  Route(Method method, dynamic path, RouteCall<Context> call,
      {List<String> keys})
      : _method = method,
        _path = _normalize(path, keys: keys) {
    if (_method == Method.ws) {
      socketStream = _socketController.stream
          .transform(WebSocketTransformer())
          .map((ws) => GetSocket(ws));
      call(Context(null, socketStream));
    } else {
      requestController.addListener(call);
    }
  }

  bool match(HttpRequest req) {
    return ((enumValueToString(_method) == req.method?.toLowerCase() ||
            _method == Method.ws) &&
        _path['regexp'].hasMatch(req.uri.path));
  }

  void handle(HttpRequest req) {
    if (_method == Method.ws) {
      _socketController.add(req);
    } else {
      var request = ContextRequest(req);
      request.params = _parseParams(req.uri.path, _path);
      request.response = ContextResponse(req.response);
      requestController.value = Context(request, socketStream);
    }
  }

  static Map _normalize(dynamic path,
      {List<String> keys, bool strict = false}) {
    String stringPath = path;
    if (keys == null) {
      keys = [];
    }
    if (path is RegExp) {
      return {'regexp': path, 'keys': keys};
    } else if (path is List) {
      stringPath = '(${path.join('|')})';
    }

    if (!strict) {
      stringPath += '/?';
    }

    stringPath =
        stringPath.replaceAllMapped(RegExp(r'(\.)?:(\w+)(\?)?'), (placeholder) {
      var replace = StringBuffer('(?:');

      if (placeholder[1] != null) {
        replace.write('\.');
      }

      replace.write('([\\w%+-._~!\$&\'()*,;=:@]+))');

      if (placeholder[3] != null) {
        replace.write('?');
      }

      keys.add(placeholder[2]);

      return replace.toString();
    }).replaceAll('//', '/');

    return {'regexp': RegExp('^$stringPath\$'), 'keys': keys};
  }

  Map<String, String> _parseParams(
      String path, Map<String, dynamic> routePath) {
    final params = <String, String>{};
    Match paramsMatch = routePath['regexp'].firstMatch(path);
    for (var i = 0; i < routePath['keys'].length; i++) {
      String param;
      try {
        param = Uri.decodeQueryComponent(paramsMatch[i + 1]);
      } catch (e) {
        param = paramsMatch[i + 1];
      }

      params[routePath['keys'][i]] = param;
    }
    return params;
  }
}
