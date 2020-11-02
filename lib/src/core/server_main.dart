import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:meta/meta.dart';
import '../../get_server.dart';
import '../routes/route.dart';
import 'node_mode_mixin.dart';
import 'route_config.dart';
import 'server_config.dart';

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

class GetServer with NodeMode {
  HttpServer _server;

  final List<GetPage> getPages;
  final LogWriterCallback log;
  final String host;
  final int port;
  final String certificateChain;
  final bool shared;
  final String privateKey;
  final String password;
  final bool cors;
  final GetView onNotFound;
  final bool useLog;
  final String jwtKey;
  final Public public;

  GetServer({
    this.host = '127.0.0.1',
    this.port = 8080,
    this.certificateChain,
    this.privateKey,
    this.password,
    this.shared = true,
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

  Future<GetServer> start() async {
    final cpus = Platform.numberOfProcessors;
    Get.log('Starting server on ${host}:${port} using $cpus threads');

    final serverConfig = ServerConfig(
      log,
      host,
      port,
      certificateChain,
      shared,
      privateKey,
      password,
      cors,
      onNotFound,
      useLog,
      jwtKey,
      public,
      _server,
    );
    if (getPages != null) {
      if (jwtKey != null) {
        TokenUtil.saveJwtKey(jwtKey);
      }
      RouteConfig.i.addRoutes(getPages);
    }

    final start = ServerStart.startServer;

    for (var i = 0; i < cpus - 1; i++) {
      // ignore: unawaited_futures
      Isolate.spawn(start, serverConfig);
    }

    // ignore: unawaited_futures
    start(serverConfig);

    await ProcessSignal.sigterm.watch().first;
    return Future.value(this);
  }
}

abstract class GetView<T> {
  final String tag = null;

  T get controller => GetInstance().find<T>(tag: tag);
  FutureOr<Widget> build(BuildContext context);
}

abstract class GetEndpoint<T> {
  final String tag = null;

  T get controller => GetInstance().find<T>(tag: tag);
  FutureOr<Widget> build(BuildContext context);
}

typedef WidgetCallback = FutureOr<Widget> Function(BuildContext context);

abstract class Widget<T> {
  Widget({this.data});
  final T data;
}

class _Wrapper<T> {
  T data;
}

//TODO: Change the name after
abstract class GetWidget<T> extends Widget {
  final _value = _Wrapper<T>();

  final String tag = null;

  T get controller {
    _value.data ??= GetInstance().find<T>(tag: tag);
    return _value.data;
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
