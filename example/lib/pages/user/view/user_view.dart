import 'package:get_server/get_server.dart';
import '../controller/user_controller.dart';

class UserPage extends GetView<UserController> {
  @override
  build(Context context) {
    final user = controller.getUser(context.request).toJson();
    return Json(user);
  }
}
