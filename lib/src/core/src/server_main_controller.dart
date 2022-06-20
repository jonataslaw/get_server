part of server;

class GetServerController extends GetxController {
  GetServerController({
    required this.host,
    required this.port,
    required this.certificateChain,
    required this.shared,
    required this.privateKey,
    required this.password,
    required this.cors,
    required this.corsUrl,
    required this.onNotFound,
    required this.useLog,
    required this.jwtKey,
    required this.home,
    required this.initialBinding,
    required this.getPages,
  });
  final String host;
  final int port;
  final String? certificateChain;
  final bool shared;
  final String? privateKey;
  final String? password;
  final bool cors;
  final String corsUrl;
  final Widget? onNotFound;
  final bool useLog;
  final String? jwtKey;
  final Widget? home;
  final Bindings? initialBinding;
  final List<GetPage>? getPages;

  List<GetPage>? _getPages;
  HttpServer? _server;
  VirtualDirectory? _virtualDirectory;
  Public? _public;

  @override
  void onInit() {
    start();
    super.onInit();
  }

  Future<void> stop() async {
    await Future.delayed(Duration.zero);
    await _server?.close();
  }

  Future<GetServerController> restart() async {
    await stop();
    await start();
    return this;
  }

  Future<GetServerController> start() async {
    _getPages = getPages ?? List.from([]);
    _homeParser();
    initialBinding?.dependencies();

    if (_getPages != null) {
      if (jwtKey != null) {
        TokenUtil.saveJwtKey(jwtKey!);
      }

      RouteConfig.i.addRoutes(_getPages!);
    }

    await startServer();

    return Future.value(this);
  }

  Future<void> startServer() async {
    Get.log('Server started on: $host:$port');

    _server = await _getHttpServer();

    _server?.listen(
      (req) {
        if (useLog) Get.log('Method ${req.method} on ${req.uri}');
        final route = RouteConfig.i.findRoute(req);

        route?.binding?.dependencies();
        if (cors) {
          addCorsHeaders(req.response, corsUrl);
          if (req.method.toLowerCase() == 'options') {
            var msg = {'status': 'ok'};
            req.response.write(json.encode(msg));
            req.response.close();
          }
        }
        if (route != null) {
          route.handle(req);
        } else {
          if (_public != null) {
            _virtualDirectory ??= VirtualDirectory(
              _public!.folder,
              // pathPrefix: public.path,
            )
              ..allowDirectoryListing = _public!.allowDirectoryListing
              ..jailRoot = _public!.jailRoot
              ..followLinks = _public!.followLinks
              ..errorPageHandler = (callback) {
                _onNotFound(
                  callback,
                  onNotFound,
                );
              }
              ..directoryHandler = (dir, req) {
                var indexUri = Uri.file(dir.path).resolve('index.html');
                _virtualDirectory!.serveFile(File(indexUri.toFilePath()), req);
              };

            _virtualDirectory!.serveRequest(req);
          } else {
            _onNotFound(
              req,
              onNotFound,
            );
          }
        }
      },
    );
  }

  void _homeParser() {
    if (home == null) return;
    if (home is FolderWidget) {
      var newHome = home as FolderWidget;
      _public = Public(
        newHome.folder,
        allowDirectoryListing: newHome.allowDirectoryListing,
        followLinks: newHome.followLinks,
        jailRoot: newHome.jailRoot,
      );
    } else {
      _getPages?.add(GetPage(name: '/', page: () => home));
    }
  }

  Future<HttpServer> _getHttpServer() {
    if (privateKey != null) {
      var context = SecurityContext();
      if (certificateChain != null) {
        context.useCertificateChain(File(certificateChain!).path);
      }
      if (privateKey != null) {
        context.usePrivateKey(File(privateKey!).path, password: password);
      }

      return HttpServer.bindSecure(host, port, context, shared: shared);
    } else {
      return HttpServer.bind(host, port, shared: shared);
    }
  }

  void addCorsHeaders(HttpResponse response, String corsUrl) {
    response.headers.add('Access-Control-Allow-Origin', corsUrl);
    response.headers
        .add('Access-Control-Allow-Methods', 'GET,HEAD,PUT,PATCH,POST,DELETE');
    response.headers.add('Access-Control-Allow-Headers',
        'access-control-allow-origin,content-type,x-access-token');
  }

  void _onNotFound(HttpRequest req, Widget? onNotFound) {
    if (onNotFound != null) {
      Route(
        Method.get,
        RouteParser.normalize(req.uri.toString()),
        onNotFound,
      ).handle(req, status: HttpStatus.notFound);
    } else {
      pageNotFound(req);
    }
  }

  void pageNotFound(HttpRequest req) {
    req.response
      ..statusCode = HttpStatus.notFound
      ..close();
  }
}
