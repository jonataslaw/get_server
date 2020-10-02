import 'package:get_server/get_server.dart';

class UploadPage extends GetView {
  @override
  Future<Widget> build(BuildContext context) async {
    final upload = await context.file('file');
    print("File received: ${upload.name}");
    return Json(upload);
  }
}
