import 'package:get_server/get_server.dart';

class JsonPage extends GetView {
  @override
  Widget build(BuildContext context) {
    return Json({
      "fruits": ["banana", "apple", "orange"]
    });
  }
}
