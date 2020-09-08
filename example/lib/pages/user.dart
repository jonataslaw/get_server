import 'package:get_server/get_server.dart';

class UserPage extends GetView {
  @override
  build(Context context) {
    return context.send('Welcome, ${context.param('name')} !');
  }
}
