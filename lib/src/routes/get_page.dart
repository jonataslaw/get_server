import '../../get_server.dart';

typedef PageBuilder = Widget Function();

class GetPage {
  final Method method;
  final String name;
  final List<String> keys;
  final PageBuilder page;
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
