import '../data_model/user_model.dart';
import '../data_provider/user_data.dart';

abstract class IUserRepository {
  User fetchUser(String name);
}

class UserRepository extends IUserRepository {
  final IUserProvider dataProvider;
  UserRepository({this.dataProvider});
  @override
  User fetchUser(String name) {
    final data = dataProvider.getUser(name);
    return User.fromJson(data);
  }
}
