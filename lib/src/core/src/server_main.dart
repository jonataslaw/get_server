part of server;

void runIsolate(void Function(dynamic _) isol) {
  isol(null);
  final list = List.generate(Platform.numberOfProcessors - 1, (index) => null);
  for (var item in list) {
    Isolate.spawn(isol, item);
  }
}

void runApp(Widget widget) {
  if (widget is GetServerApp) {
    widget._createServer();
  } else {
    GetServerApp(
      port: 8080,
      cors: true,
      home: widget,
    )._createServer();
  }
}

class GetServer extends GetServerApp {
  GetServer({
    Key? key,
    String host = '0.0.0.0',
    int port = 8080,
    String? certificateChain,
    bool shared = true,
    String? privateKey,
    String? password,
    bool cors = false,
    String corsUrl = '*',
    Widget? onNotFound,
    bool useLog = true,
    String? jwtKey,
    Widget? home,
    Bindings? initialBinding,
    List<GetPage>? getPages,
  }) : super(
          key: key,
          host: host,
          port: port,
          certificateChain: certificateChain,
          shared: shared,
          privateKey: privateKey,
          password: password,
          cors: cors,
          corsUrl: corsUrl,
          onNotFound: onNotFound,
          useLog: useLog,
          jwtKey: jwtKey,
          home: home,
          initialBinding: initialBinding,
          getPages: getPages,
        );
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

class GetServerApp extends StatelessWidget with NodeMode {
  GetServerApp({
    Key? key,
    this.host = '0.0.0.0',
    this.port = 8080,
    this.certificateChain,
    this.privateKey,
    this.password,
    this.shared = true,
    this.getPages,
    this.cors = false,
    this.corsUrl = '*',
    this.onNotFound,
    this.initialBinding,
    this.useLog = true,
    this.jwtKey,
    this.home,
  })  : controller = Get.put(GetServerController(
          host: host,
          port: port,
          certificateChain: certificateChain,
          shared: shared,
          privateKey: privateKey,
          password: password,
          cors: cors,
          corsUrl: corsUrl,
          onNotFound: onNotFound,
          useLog: useLog,
          jwtKey: jwtKey,
          home: home,
          initialBinding: initialBinding,
          getPages: getPages,
        )),
        super(key: key);

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

  final GetServerController controller;

  void _createServer() => build(null);

  @override
  Widget build(BuildContext? context) {
    return WidgetEmpty();
  }
}
