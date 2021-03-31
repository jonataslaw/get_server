import '../data_model/user_model.dart';
import '../data_provider/user_data.dart';

mixin IUserRepository {
  User fetchUser(String? name);
}

class UserRepository with IUserRepository {
  final IUserProvider dataProvider;
  UserRepository({required this.dataProvider});
  @override
  User fetchUser(String? name) {
    final data = dataProvider.getUser(name);
    return User.fromJson(data);
  }
}
