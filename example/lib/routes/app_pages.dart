import 'package:get_server/get_server.dart';
import '../pages/home.dart';
import '../pages/html.dart';
import '../pages/json.dart';
import '../pages/socket.dart';
import '../pages/upload.dart';
import '../pages/user.dart';
part 'app_routes.dart';

abstract class AppPages {
  static final routes = [
    GetPage(name: Routes.HOME, page: HomePage()),
    GetPage(name: Routes.USER, page: UserPage()),
    GetPage(name: Routes.FRUITS, page: JsonPage()),
    GetPage(name: Routes.LANDING, page: HtmlPage()),
    GetPage(name: Routes.UPLOAD, page: UploadPage(), method: Method.post),
    GetPage(name: Routes.SOCKET, page: SocketPage(), method: Method.ws),
  ];
}
