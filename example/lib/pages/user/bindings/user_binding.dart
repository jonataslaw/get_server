import 'package:get_server/get_server.dart';
import '../controller/user_controller.dart';
import '../data/data_provider/user_data.dart';
import '../data/data_repository/user_repository.dart';

class UserBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<IUserProvider>(() => UserProvider());
    Get.lazyPut<IUserRepository>(
        () => UserRepository(dataProvider: Get.find()));
    Get.lazyPut(() => UserController(repository: Get.find()));
  }
}
