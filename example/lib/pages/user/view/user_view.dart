import 'package:get_server/get_server.dart';
import '../controller/user_controller.dart';

class UserPage extends GetView<UserController> {
  @override
  Widget build(BuildContext context) {
    return Json(controller.getUser(context.request));
  }
}
