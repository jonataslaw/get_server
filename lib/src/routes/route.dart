import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:get_instance/get_instance.dart';
import 'package:get_server/get_server.dart';
import 'package:jaguar_jwt/jaguar_jwt.dart';
import 'package:meta/meta.dart';

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

abstract class BuildContext {
  ContextResponse get response;
  ContextRequest get request;

  Future pageNotFound();

  void statusCode(int code);

  Future close();

  Stream<GetSocket> get ws;

  Stream<GetSocket> get socketStream;

  Future send(Object string);

  Future sendBytes(List<int> data);

  Future sendJson(Object string);

  Future sendHtml(String path);

  Future<MultipartUpload> file(String name, {Encoding encoder = utf8});

  String param(String name) => request.param(name);

  Future<Map> payload({Encoding encoder = utf8});
}

String enumValueToString(Object o) => o.toString().split('.').last;

class Route {
  final _socketController = StreamController<HttpRequest>.broadcast();
  Stream<GetSocket> socketStream;
  final Method _method;
  final Map _path;
  final Bindings binding;
  final bool _needAuth;
  final Map<String, HashSet<GetSocket>> _rooms;
  final HashSet<GetSocket> _sockets;
  final Widget widget;

  Route(
    Method method,
    dynamic path,
    this.widget, {
    this.binding,
    List<String> keys,
    bool needAuth = false,
  })  : _method = method,
        _needAuth = needAuth,
        _rooms = (method == Method.ws ? <String, HashSet<GetSocket>>{} : null),
        _sockets = (method == Method.ws ? HashSet<GetSocket>() : null),
        _path = _normalize(path, keys: keys) {
    if (_method == Method.ws) {
      _setupWs();
    }
  }

  void _setupWs() {
    socketStream =
        _socketController.stream.transform(WebSocketTransformer()).map((ws) {
      return GetSocket(ws, _rooms, _sockets);
    });
  }

  bool match(HttpRequest req) {
    return ((enumValueToString(_method) == req.method?.toLowerCase() ||
            _method == Method.ws) &&
        _path['regexp'].hasMatch(req.uri.path));
  }

  Future<void> handle(HttpRequest req, {int status}) async {
    if (_method == Method.ws) {
      var request = ContextRequest(req);
      request.params = _parseParams(req.uri.path, _path);
      request.response = ContextResponse(req.response);

      _verifyAuth(
        req: request,
        successCallback: () {
          _sendResponse(request);
          _socketController.add(req);
        },
      );
    } else {
      var request = ContextRequest(req);
      request.params = _parseParams(req.uri.path, _path);
      request.response = ContextResponse(req.response);
      if (status != null) request.response.status(status);

      _verifyAuth(
        req: request,
        successCallback: () => _sendResponse(request),
      );
    }
  }

  void _sendResponse(ContextRequest request, [Widget failure]) async {
    if (failure != null) {
      // ignore: invalid_use_of_protected_member
      failure.createElement(request, socketStream);
    } else {
      // ignore: invalid_use_of_protected_member
      widget.createElement(request, socketStream);
    }
  }

  static Map _normalize(
    dynamic path, {
    List<String> keys,
    bool strict = false,
  }) {
    String stringPath = path;
    keys ??= [];
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

  String _authHandler(ContextRequest req) {
    dynamic token = req.header('Authorization');
    try {
      if (token != null) {
        token = token.first;
        if (token.contains('Bearer')) {
          token = token.replaceAll('Bearer ', '');

          var key = TokenUtil.getJwtKey();
          var decClaimSet = verifyJwtHS256Signature(token, key);
          if (decClaimSet.expiry.isBefore(DateTime.now())) {
            return JwtException.tokenExpired.message;
          }
        } else {
          return JwtException.invalidToken.message;
        }
      } else {
        return JwtException.invalidToken.message;
      }
      return null;
    } on JwtException catch (err) {
      return err.message;
    } catch (err) {
      return JwtException.invalidToken.message;
    }
  }

  void _verifyAuth({
    @required ContextRequest req,
    @required void Function() successCallback,
  }) {
    if (_needAuth) {
      var message = _authHandler(req);
      if (message == null) {
        successCallback();
      } else {
        req.response?.status(401);
        _sendResponse(
          req,
          Json({'success': false, 'data': null, 'error': message}),
        );
      }
    } else {
      successCallback();
    }
  }
}
