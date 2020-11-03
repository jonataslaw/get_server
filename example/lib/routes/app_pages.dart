import 'package:get_server/get_server.dart';
import '../pages/auth/bindings/auth_binding.dart';
import '../pages/auth/view/auth.dart';
// import '../pages/home/home.dart';
import '../pages/html/html.dart';
import '../pages/json/json.dart';
import '../pages/pageable/pageable.dart';
import '../pages/socket/socket.dart';
import '../pages/upload/upload.dart';
import '../pages/user/bindings/user_binding.dart';
import '../pages/user/view/user_view.dart';
part 'app_routes.dart';

abstract class AppPages {
  static final routes = [
    // GetPage(
    //   name: Routes.HOME,
    //   page: () => HomePage(),
    // ),
    GetPage(
      name: Routes.USER,
      page: () => UserPage(),
      binding: UserBinding(),
    ),
    GetPage(
      name: Routes.LANDING,
      page: () => HtmlPage(),
    ),
    GetPage(
      name: Routes.PAGEABLE,
      page: () => PageablePage(),
    ),
    GetPage(
      name: Routes.UPLOAD,
      page: () => UploadPage(),
      method: Method.post,
    ),
    GetPage(
      name: Routes.SOCKET,
      page: () => SocketPage(),
      method: Method.ws,
    ),
    GetPage(
      name: Routes.FRUITS,
      page: () => JsonPage(),
      needAuth: true,
    ),
    GetPage(
      name: Routes.AUTH,
      page: () => AuthPage(),
      method: Method.post,
      binding: AuthBinding(),
    ),
  ];
}
