import 'package:get_server/get_server.dart';

class UserPage extends GetView {
  @override
  build(Context context) {
    String name = context.param('name');
    if (name == "pedro") {
      // return page not found
      return context.pageNotFound();

      // you can return other status code:
      // context
      // ..statusCode(302)
      // ..close();
    }
    return context.send('Welcome, ${context.param('name')} !');
  }
}
