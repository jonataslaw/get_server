import 'package:get_server/get_server.dart';

class JsonPage extends GetView {
  @override
  build(Context context) {
    return context.sendJson({
      "fruits": ["banana", "apple", "orange"]
    });
  }
}
