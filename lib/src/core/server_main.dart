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
  final bool needAuth;

  const GetPage({
    this.method = Method.get,
    this.name = '/',
    this.page,
    this.binding,
    this.keys,
    this.needAuth = false,
  });
}

Future<GetServer> runApp(GetServer server) {
  return server.start();
}

class Public {
  final String folder;
  // final String path;
  final bool allowDirectoryListing;
  final bool followLinks;
  final bool jailRoot;

  Public(
    this.folder, {

    /// awaiting dart lang solution
    /// https://github.com/dart-lang/http_server/issues/81
    // this.path = '/',
    this.allowDirectoryListing = true,
    this.followLinks = false,
    this.jailRoot = true,
  });
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
  final String jwtKey;
  HttpServer _server;
  VirtualDirectory _staticServer;
  final Public public;

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
    this.jwtKey,
    this.public,
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
      if (jwtKey != null) TokenUtil.saveJwtKey(jwtKey);

      getPages.forEach((route) {
        _routes.add(
          Route(
            route.method,
            route.name,
            route?.page()?.build,
            binding: route.binding,
            keys: route.keys,
            needAuth: route.needAuth,
          ),
        );
      });
    }

    if (privateKey != null) {
      var context = SecurityContext();
      if (certificateChain != null) {
        context.useCertificateChain(File(certificateChain).path);
      }
      context.usePrivateKey(File(privateKey).path, password: password);
      return HttpServer.bindSecure(host, port, context, shared: shared)
          .then(_configure)
          .catchError((err) {
        Get.log(err?.toString(), isError: true);
      });
    }
    return HttpServer.bind(host, port, shared: shared)
        .then(_configure)
        .catchError((err) {
      Get.log(err?.toString(), isError: true);
    });
  }

  void addCorsHeaders(HttpResponse response) {
    response.headers.add('Access-Control-Allow-Origin', '*');
    response.headers
        .add('Access-Control-Allow-Methods', 'GET,HEAD,PUT,PATCH,POST,DELETE');
    response.headers.add('Access-Control-Allow-Headers',
        'access-control-allow-origin,content-type,x-access-token');
  }

  FutureOr<GetServer> _configure(HttpServer httpServer) {
    httpServer.listen((req) {
      if (useLog) Get.log('Method ${req.method} on ${req.uri}');
      var route =
          _routes.firstWhere((route) => route.match(req), orElse: () => null);

      route?.binding?.dependencies();
      if (cors) {
        addCorsHeaders(req.response);
        if (req.method.toLowerCase() == 'options') {
          var msg = {'status': 'ok'};
          req.response.write(json.encode(msg));
          req.response.close();
        }
      }
      if (route != null) {
        route.handle(req);
      } else {
        /// TODO: IMPROVE IT, The public folder is being called every
        /// time a route is not found.If this is removed from here,
        /// it will not load files that depend on the folder.
        if (public != null) {
          _staticServer ??= VirtualDirectory(
            public.folder,
            // pathPrefix: public.path,
          )
            ..allowDirectoryListing = public.allowDirectoryListing
            ..jailRoot = public.jailRoot
            ..followLinks = public.followLinks
            ..errorPageHandler = _onNotFound
            ..directoryHandler = (Directory dir, HttpRequest req) {
              var indexUri = Uri.file(dir.path).resolve('index.html');
              _staticServer.serveFile(File(indexUri.toFilePath()), req);
            };

          _staticServer.serveRequest(req);
        } else {
          _onNotFound(req);
        }
      }
    });

    Get.log('Server started on $host:$port');

    return this;
  }

  void _onNotFound(HttpRequest req) {
    if (onNotFound != null) {
      Route(
        Method.get,
        req.uri.toString(),
        onNotFound.build,
      ).handle(req, status: HttpStatus.notFound);
    } else {
      pageNotFound(req);
    }
  }

  void get(String path, FutureOr Function(BuildContext context) build,
      {List<String> keys}) {
    _routes.add(Route(Method.get, path, build, keys: keys));
  }

  void post(String path, FutureOr Function(BuildContext context) build,
      {List<String> keys}) {
    _routes.add(Route(Method.post, path, build, keys: keys));
  }

  void delete(String path, FutureOr Function(BuildContext context) build,
      {List<String> keys}) {
    _routes.add(Route(Method.delete, path, build, keys: keys));
  }

  void put(String path, FutureOr Function(BuildContext context) build,
      {List<String> keys}) {
    _routes.add(Route(Method.put, path, build, keys: keys));
  }

  void ws(String path, FutureOr Function(BuildContext context) build,
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

  FutureOr<Widget> build(BuildContext context);
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
  final FutureOr Function(BuildContext) builder;
  WidgetBuilder(this.context, {@required this.builder});
}

class Socket extends Widget<void> {
  Socket(this.context, {@required this.builder});
  final BuildContext context;
  final Function(GetSocket) builder;
}
