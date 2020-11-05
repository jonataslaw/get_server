import 'dart:io';

import 'package:get_server/get_server.dart';

class HtmlPage extends GetView {
  @override
  Widget build(BuildContext context) {
    final path = '${Directory.current.path}/example/web/index.html';
    return Html(path: path);
  }
}
