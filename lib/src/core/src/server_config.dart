part of server;

class ServerConfig {
  HttpServer _server;
  VirtualDirectory _virtualDirectory;
  // final LogWriterCallback log;
  final String host;
  final int port;
  final String certificateChain;
  final bool shared;
  final String privateKey;
  final String password;
  final bool cors;
  final Widget onNotFound;
  final bool useLog;
  final String jwtKey;
  final Public public;

  ServerConfig(
    //  this.log,
    this.host,
    this.port,
    this.certificateChain,
    this.shared,
    this.privateKey,
    this.password,
    this.cors,
    this.onNotFound,
    this.useLog,
    this.jwtKey,
    this.public,
    this._server,
  );
}

class ServerStart {
  static Future<void> startServer(ServerConfig server) async {
    // Get.log('Server started on ${server.host}:${server.port}');

    final http = await _getHttpServer(server);
    server._server = http;
    http.listen((req) {
      if (server.useLog) Get.log('Method ${req.method} on ${req.uri}');
      var route = _findRoute(req);

      route?.binding?.dependencies();
      if (server.cors) {
        addCorsHeaders(req.response);
        if (req.method.toLowerCase() == 'options') {
          var msg = {'status': 'ok'};
          req.response.write(json.encode(msg));
          // ignore: unawaited_futures
          req.response.close();
        }
      }
      if (route != null) {
        route.handle(req);
      } else {
        final public = server.public;

        /// TODO: Check if issue from VirtualDirectory with custom path was resolved
        if (public != null) {
          server._virtualDirectory ??= VirtualDirectory(
            public.folder,
            // pathPrefix: public.path,
          )
            ..allowDirectoryListing = public.allowDirectoryListing
            ..jailRoot = public.jailRoot
            ..followLinks = public.followLinks
            ..errorPageHandler = (callback) {
              _onNotFound(callback, server.onNotFound);
            }
            ..directoryHandler = (Directory dir, HttpRequest req) {
              var indexUri = Uri.file(dir.path).resolve('index.html');
              server._virtualDirectory
                  .serveFile(File(indexUri.toFilePath()), req);
            };

          server._virtualDirectory.serveRequest(req);
        } else {
          _onNotFound(req, server.onNotFound);
        }
      }
    });
  }

  static Future<HttpServer> _getHttpServer(ServerConfig server) {
    if (server.privateKey != null) {
      var context = SecurityContext();
      if (server.certificateChain != null) {
        context.useCertificateChain(File(server.certificateChain).path);
      }
      context.usePrivateKey(File(server.privateKey).path,
          password: server.password);
      return HttpServer.bindSecure(server.host, server.port, context,
          shared: server.shared);
    } else {
      return HttpServer.bind(server.host, server.port, shared: server.shared);
    }
  }

  static void addCorsHeaders(HttpResponse response) {
    response.headers.add('Access-Control-Allow-Origin', '*');
    response.headers
        .add('Access-Control-Allow-Methods', 'GET,HEAD,PUT,PATCH,POST,DELETE');
    response.headers.add('Access-Control-Allow-Headers',
        'access-control-allow-origin,content-type,x-access-token');
  }

  static void _onNotFound(HttpRequest req, GetView onNotFound) {
    if (onNotFound != null) {
      Route(
        Method.get,
        req.uri.toString(),
        onNotFound,
      ).handle(req, status: HttpStatus.notFound);
    } else {
      pageNotFound(req);
    }
  }

  static void pageNotFound(HttpRequest req) {
    req.response
      ..statusCode = HttpStatus.notFound
      ..close();
  }
}
