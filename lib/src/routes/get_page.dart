import '../../get_server.dart';

class GetPage {
  final Method method;
  final String name;
  final List<String?>? keys;
  final Widget? Function()? page;
  final Bindings? binding;
  final bool needAuth;
  final Map path;

  GetPage({
    this.method = Method.dynamic,
    this.name = '/',
    this.page,
    this.binding,
    this.keys,
    this.needAuth = false,
  }) : path = RouteParser.normalize(name, keys: keys);
}

// class GetPageForIsolate {
//   final Method method;
//   final String name;
//   final List<String> keys;
//   final Widget page;
//   final Bindings binding;
//   final bool needAuth;
//   final Map path;

//   GetPageForIsolate({
//     this.method,
//     this.name,
//     this.page,
//     this.binding,
//     this.keys,
//     this.needAuth,
//   }) : path = _normalize(name, keys: keys);

//   bool match(String uriPath, String methodRoute) {
//     return ((enumValueToString(method) == methodRoute?.toLowerCase() ||
//             method == Method.ws) &&
//         path['regexp'].hasMatch(uriPath));
//   }

//   static Map _normalize(
//     dynamic path, {
//     List<String> keys,
//     bool strict = false,
//   }) {
//     String stringPath = path;
//     keys ??= [];
//     if (path is RegExp) {
//       return {'regexp': path, 'keys': keys};
//     } else if (path is List) {
//       stringPath = '(${path.join('|')})';
//     }

//     if (!strict) {
//       stringPath += '/?';
//     }

//     stringPath =
//         stringPath.replaceAllMapped(RegExp(r'(\.)?:(\w+)(\?)?'), (placeholder) {
//       var replace = StringBuffer('(?:');

//       if (placeholder[1] != null) {
//         replace.write('\.');
//       }

//       replace.write('([\\w%+-._~!\$&\'()*,;=:@]+))');

//       if (placeholder[3] != null) {
//         replace.write('?');
//       }

//       keys.add(placeholder[2]);

//       return replace.toString();
//     }).replaceAll('//', '/');

//     return {'regexp': RegExp('^$stringPath\$'), 'keys': keys};
//   }
// }
