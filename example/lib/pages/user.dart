import 'package:get_server/get_server.dart';

class UserPage extends GetView {
  @override
  build(Context context) {
    String name = context.param('name');
    return Text('Welcome, $name !');
  }
}
