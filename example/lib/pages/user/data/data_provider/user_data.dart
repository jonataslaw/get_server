abstract class IUserProvider {
  Map<String, dynamic> getUser(String name);
}

class UserProvider extends IUserProvider {
  Map<String, dynamic> getUser(String name) {
    if (name.toLowerCase() == 'pedro') {
      return {
        'name': 'Pedro',
        'age': '30 years old',
        'Country': 'Brazil',
        'Error': ''
      };
    } else {
      return {'Error': 'User Not found'};
    }
  }
}
