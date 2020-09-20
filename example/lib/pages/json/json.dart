import 'package:get_server/get_server.dart';

class JsonPage extends GetView {
  @override
  build(Context context) {
    return Json({
      "fruits": ["banana", "apple", "orange"]
    });
  }
}
