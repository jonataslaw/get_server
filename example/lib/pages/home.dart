import 'package:get_server/get_server.dart';

class HomePage extends GetView {
  @override
  build(Context context) {
    return context.send('Hello, you are on home');
  }
}
