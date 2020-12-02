import 'package:get_server/get_server.dart';

class UploadPage extends GetView {
  @override
  Widget build(BuildContext context) {
    return MultiPartWidget(
      builder: (context, file) {
        return Json({
          'file': file.data.toString(),
          'mime': file.mimeType,
        });
      },
    );
  }
}
