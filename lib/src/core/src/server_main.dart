part of server;

void runIsolate(void Function(dynamic) isol) {
  isol(null);
  final list = List.generate(Platform.numberOfProcessors - 1, (index) => null);
  for (var item in list) {
    Isolate.spawn(isol, item);
  }
}

void runApp(Widget widget) {
  if (widget is GetServer) {
    widget.build(null);
  } else {
    GetServer(
      port: 8080,
      cors: true,
      home: widget,
    ).build(null);
  }
}

class FolderWidget extends StatelessWidget {
  final String folder;
  // final String path;
  final bool allowDirectoryListing;
  final bool followLinks;
  final bool jailRoot;

  FolderWidget(
    this.folder, {

    /// awaiting dart lang solution
    /// https://github.com/dart-lang/http_server/issues/81
    // this.path = '/',
    this.allowDirectoryListing = true,
    this.followLinks = false,
    this.jailRoot = true,
  });
  @override
  Widget build(BuildContext context) {
    return WidgetEmpty();
  }
}

class Public {
  final String folder;
  // final String path;
  final bool allowDirectoryListing;
  final bool followLinks;
  final bool jailRoot;

  const Public(
    this.folder, {

    /// awaiting dart lang solution
    /// https://github.com/dart-lang/http_server/issues/81
    // this.path = '/',
    this.allowDirectoryListing = true,
    this.followLinks = false,
    this.jailRoot = true,
  });
}

class GetServer extends StatelessWidget with NodeMode {
  HttpServer _server;
  VirtualDirectory _virtualDirectory;
  final List<GetPage> _getPages;
  final String host;
  final int port;
  final String certificateChain;
  final bool shared;
  final String privateKey;
  final String password;
  final bool cors;
  final String corsUrl;
  final Widget onNotFound;
  final bool useLog;
  final String jwtKey;
  Public _public;
  final Widget home;

  GetServer({
    this.host = '0.0.0.0',
    this.port = 8080,
    this.certificateChain,
    this.privateKey,
    this.password,
    this.shared = true,
    List<GetPage> getPages,
    this.cors = false,
    this.corsUrl = '*',
    this.onNotFound,
    this.initialBinding,
    this.useLog = true,
    this.jwtKey,
    this.home,
  }) : _getPages = getPages ?? List.from([]) {
    _homeParser();
    initialBinding?.dependencies();
  }

  final Bindings initialBinding;

  void stop() => _server.close();

  Future<GetServer> start() async {
    if (_getPages != null) {
      if (jwtKey != null) {
        TokenUtil.saveJwtKey(jwtKey);
      }

      RouteConfig.i.addRoutes(_getPages);
    }

    await startServer();

    return Future.value(this);
  }

  Future<void> startServer() async {
    Get.log('Server started on ${host}:${port}');

    _server = await _getHttpServer();

    _server.listen(
      (req) {
        if (useLog) Get.log('Method ${req.method} on ${req.uri}');
        final route = RouteConfig.i.findRoute(req);

        route?.binding?.dependencies();
        if (cors) {
          addCorsHeaders(req.response, corsUrl);
          if (req.method.toLowerCase() == 'options') {
            // #var msg = {'status': 'ok'};
            // req.response.write(json.encode(msg));
            req.response.statusCode = 204;
            req.response.close();
          }
        }
        if (route != null) {
          route.handle(req);
        } else {
          if (req.method.toLowerCase() != 'options') {
            if (_public != null) {
              _virtualDirectory ??= VirtualDirectory(
                _public.folder,
                // pathPrefix: public.path,
              )
                ..allowDirectoryListing = _public.allowDirectoryListing
                ..jailRoot = _public.jailRoot
                ..followLinks = _public.followLinks
                ..errorPageHandler = (callback) {
                  _onNotFound(
                    callback,
                    onNotFound,
                  );
                }
                ..directoryHandler = (dir, req) {
                  var indexUri = Uri.file(dir.path).resolve('index.html');
                  _virtualDirectory.serveFile(File(indexUri.toFilePath()), req);
                };

              _virtualDirectory.serveRequest(req);
            } else {
              _onNotFound(
                req,
                onNotFound,
              );
            }
          }
        }
      },
    );
  }

  void _homeParser() {
    if (home == null) return;
    if (home is FolderWidget) {
      var _home = home as FolderWidget;
      _public = Public(
        _home.folder,
        allowDirectoryListing: _home.allowDirectoryListing,
        followLinks: _home.followLinks,
        jailRoot: _home.jailRoot,
      );
    } else {
      _getPages.add(GetPage(name: '/', page: () => home));
    }
  }

  Future<HttpServer> _getHttpServer() {
    if (privateKey != null) {
      var context = SecurityContext();
      if (certificateChain != null) {
        context.useCertificateChain(File(certificateChain).path);
      }
      context.usePrivateKey(File(privateKey).path, password: password);
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
        'access-control-allow-origin,content-type,x-access-token,authorization');
  }

  void _onNotFound(HttpRequest req, Widget onNotFound) {
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

  @override
  Widget build(BuildContext context) {
    start();
    return WidgetEmpty();
  }
}
