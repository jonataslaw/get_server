import 'package:get_server/get_server.dart';

class UserPage extends GetView {
  @override
  build(Context context) {
    String name = context.param('name');
    if (name == "pedro") {
     return context.pageNotFound();
    }
    return context.send('Welcome, ${context.param('name')} !');
  }
}
