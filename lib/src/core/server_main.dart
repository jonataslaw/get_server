import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:get_server/src/socket/socket.dart';
import 'package:http_server/http_server.dart';
import 'package:meta/meta.dart';
import '../../get_server.dart';
import '../routes/route.dart';

class GetPage {
  final Method method;
  final String name;
  final List<String> keys;
  final GetView Function() page;
  final Bindings binding;

  const GetPage({
    this.method = Method.get,
    this.name = '/',
    this.page,
    this.binding,
    this.keys,
  });
}

Future<GetServer> runApp(GetServer server) {
  return server.start();
}

class GetServer {
  final LogWriterCallback log;
  final List<GetPage> getPages;
  final String host;
  final int port;
  final String certificateChain;
  final bool shared;
  final String privateKey;
  final String password;
  final bool cors;
  final List<Route> _routes = <Route>[];
  final GetView onNotFound;
  final bool useLog;
  HttpServer _server;
  VirtualDirectory _staticServer;

  GetServer({
    this.host = '127.0.0.1',
    this.port = 8080,
    this.certificateChain,
    this.privateKey,
    this.password,
    this.shared = false,
    this.getPages,
    this.cors = false,
    this.log,
    this.onNotFound,
    this.initialBinding,
    this.useLog = true,
  }) {
    if (log != null) {
      Get.log = log;
    }
    initialBinding?.dependencies();
  }

  final Bindings initialBinding;

  void stop() => _server.close();

  final Map<String, List<WebSocket>> rooms = <String, List<WebSocket>>{};

  Future<GetServer> start() {
    if (getPages != null) {
      getPages.forEach((route) {
        _routes.add(Route(route.method, route.name, route?.page()?.build,
            binding: route.binding, keys: route.keys));
      });
    }

    if (privateKey != null) {
      var context = SecurityContext();
      if (certificateChain != null) {
        context.useCertificateChain(File(certificateChain).path);
      }
      context.usePrivateKey(File(privateKey).path, password: password);
      return HttpServer.bindSecure(host, port, context, shared: shared)
          .then(_configure);
    }
    return HttpServer.bind(host, port, shared: shared).then(_configure);
  }

  void addCorsHeaders(HttpResponse response) {
    response.headers.add('Access-Control-Allow-Origin', '*');
    response.headers
        .add('Access-Control-Allow-Methods', 'GET,HEAD,PUT,PATCH,POST,DELETE');
    response.headers.add('Access-Control-Allow-Headers',
        'access-control-allow-origin,content-type,x-access-token');
  }

  FutureOr<GetServer> _configure(HttpServer httpServer) {
    _server = httpServer;
    httpServer.listen((req) {
      if (useLog) Get.log('Method ${req.method} on ${req.uri}');
      var route =
          _routes.firstWhere((route) => route.match(req), orElse: () => null);

      route?.binding?.dependencies();
      if (cors) {
        addCorsHeaders(req.response);
        if (req.method.toLowerCase() == 'options') {
          var msg = {"status": "ok"};
          req.response.write(json.encode(msg));
          req.response.close();
        }
      }

      if (route != null) {
        route.handle(req);
      } else if (_staticServer != null) {
        _staticServer.serveRequest(req);
      } else {
        if (onNotFound != null) {
          route = Route(
            Method.get,
            req.uri.toString(),
            onNotFound.build,
          );
          route.handle(req, status: HttpStatus.notFound);
        } else {
          pageNotFound(req);
        }
      }
    });

    Get.log('Server started on $host:$port');

    return this;
  }

  void get(String path, FutureOr build(BuildContext context),
      {List<String> keys}) {
    _routes.add(Route(Method.get, path, build, keys: keys));
  }

  void post(String path, FutureOr build(BuildContext context),
      {List<String> keys}) {
    _routes.add(Route(Method.post, path, build, keys: keys));
  }

  void delete(String path, FutureOr build(BuildContext context),
      {List<String> keys}) {
    _routes.add(Route(Method.delete, path, build, keys: keys));
  }

  void put(String path, FutureOr build(BuildContext context),
      {List<String> keys}) {
    _routes.add(Route(Method.put, path, build, keys: keys));
  }

  void ws(String path, FutureOr build(BuildContext context),
      {List<String> keys}) {
    _routes.add(Route(Method.ws, path, build, keys: keys));
  }

  void pageNotFound(HttpRequest req) {
    req.response
      ..statusCode = HttpStatus.notFound
      ..close();
  }
}

// Suggestion, change that name to GetEndpoint
abstract class GetView<T> {
  final String tag = null;

  T get controller => GetInstance().find<T>(tag: tag);
  FutureOr<Widget> build(BuildContext context);
}

abstract class Widget<T> {
  Widget({this.data});
  final T data;
}

//TODO: Change the name after
abstract class GetWidget<T> extends Widget {
  final Set<T> _value = <T>{};

  final String tag = null;

  T get controller {
    if (_value.isEmpty) _value.add(GetInstance().find<T>(tag: tag));
    return _value.first;
  }

  FutureOr build(BuildContext context);
}

class Text extends Widget<String> {
  Text(String text) : super(data: text);
}

class Html extends Widget<String> {
  Html(String path) : super(data: path);
}

class HtmlText extends Widget<String> {
  HtmlText(String htmlText) : super(data: htmlText);
}

class Json extends Widget<dynamic> {
  Json(dynamic jsonRaw) : super(data: jsonRaw);
}

class WidgetBuilder extends Widget {
  final BuildContext context;
  final Future Function(BuildContext) builder;
  WidgetBuilder(this.context, {@required this.builder});
}

class Socket extends Widget<void> {
  Socket(this.context, {@required this.builder});
  final BuildContext context;
  final Function(GetSocket) builder;
}
