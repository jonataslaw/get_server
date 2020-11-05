import '../../get_server.dart';

class GetPage {
  final Method method;
  final String name;
  final List<String> keys;
  final Widget Function() page;
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
