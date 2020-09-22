import 'dart:convert';

import 'package:get_server/get_server.dart';

class UploadPage extends GetView {
  @override
  Future<Widget> build(BuildContext context) async {
    final upload = await context.file('file');
    final data = {
      "nameFile": upload.name,
      "mimeType": upload.mimeType,
      "fileBase64": "${base64Encode(upload.data)}",
    };
    return Json(data);
  }
}
