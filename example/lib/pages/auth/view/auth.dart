import 'package:get_server/get_server.dart';

import '../controller/view_controller.dart';

class AuthPage extends GetView<AuthController> {
  @override
  Widget build(BuildContext context) {
    return Json(controller.getToken());
  }
}
