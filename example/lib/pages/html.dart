import 'dart:io';

import 'package:get_server/get_server.dart';

class HtmlPage extends GetView {
  @override
  build(Context context) {
    final path = '${Directory.current.path}/example/web/index.html';
    return context.sendHtml(path);
  }
}
