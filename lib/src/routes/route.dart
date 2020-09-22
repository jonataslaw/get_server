import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:get_instance/get_instance.dart';
import 'package:get_server/src/core/server_main.dart';

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

//typedef RouteCall<Context> = Widget<T> Function<T>(Context context);
typedef Disposer = Function();

class BuildContext {
  BuildContext(this.request, this.socketStream);
  ContextResponse get response => request.response;
  final ContextRequest request;
  final Stream<GetSocket> socketStream;

  Future pageNotFound() {
    return response.close();
  }

  void statusCode(int code) {
    if (code == null) {
      return;
    }
    response.status(code);
  }

  Future close() {
    return response.close();
  }

  Stream<GetSocket> get ws => socketStream;

  Future send(Object string) {
    return response.send(string);
  }

  Future sendBytes(List<int> data) {
    return response.send(data);
  }

  Future sendJson(Object string) {
    return response
        // this headers are not working
        .header('Content-Type', 'application/json; charset=UTF-8')
        .sendJson(string);
  }

  Future sendHtml(String path) {
    // this headers are not working
    response.header('Content-Type', 'text/html; charset=UTF-8');
    return response.sendFile(path);
  }

  Future<MultipartUpload> file(String name, {Encoding encoder = utf8}) async {
    final payload = await request.payload(encoder: encoder);
    final multiPart = await payload[name];
    return multiPart;
  }

  String param(String name) => request.param(name);

  Future<Map> payload({Encoding encoder = utf8}) =>
      request.payload(encoder: encoder);
}

String enumValueToString(Object o) => o.toString().split('.').last;

class Route {
  final _socketController = StreamController<HttpRequest>();
  // Stream<ContextRequest> requestStream;
  Stream<GetSocket> socketStream;
  final Method _method;
  final Map _path;
  final Bindings binding;
  FutureOr<Widget> Function(BuildContext context) _call;

  Route(
    Method method,
    dynamic path,
    FutureOr<Widget> Function(BuildContext context) call, {
    this.binding,
    List<String> keys,
    Map<String, List<WebSocket>> rooms,
  })  : _method = method,
        _path = _normalize(path, keys: keys) {
    if (_method == Method.ws) {
      socketStream = _socketController.stream
          .transform(WebSocketTransformer())
          .map((ws) => GetSocket(ws, rooms));
      final context = BuildContext(null, socketStream);
      Socket socket = call(context);
      context.ws.listen((event) {
        socket.builder(event);
      });
    } else {
      _call = call;
    }
  }

  bool match(HttpRequest req) {
    return ((enumValueToString(_method) == req.method?.toLowerCase() ||
            _method == Method.ws) &&
        _path['regexp'].hasMatch(req.uri.path));
  }

  Future<void> handle(HttpRequest req, {int status}) async {
    if (_method == Method.ws) {
      _socketController.add(req);
    } else {
      var request = ContextRequest(req);
      request.params = _parseParams(req.uri.path, _path);
      request.response = ContextResponse(req.response);
      if (status != null) request.response.status(status);
      Widget widget;
      final prepareWidget = _call(BuildContext(request, socketStream));

      if (prepareWidget is Future) {
        widget = await prepareWidget;
      } else {
        widget = prepareWidget;
      }
      print(widget.runtimeType.toString());
      if (widget is Text) {
        request.response.send(widget.data);
      } else if (widget is Json) {
        request.response.sendJson(widget.data);
      } else if (widget is Html) {
        request.response.sendFile(widget.data);
      } else if (widget is HtmlText) {
        request.response.sendHtmlText(widget.data);
      } else if (widget is WidgetBuilder) {
        widget.builder?.call(BuildContext(request, socketStream));
      } else if (widget is GetWidget) {
        final wid = await widget.build(BuildContext(request, socketStream));
        request.response.send(wid.data);
      } else {
        request.response.send(widget.data);
      }
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

  Map<String, String> _parseParams(String path, Map routePath) {
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
