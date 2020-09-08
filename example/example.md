```dart
import 'dart:convert';
import 'dart:io';
import 'package:get_server/get_server.dart';

// default method is Method.get
// name is the path of url
void main() {
  runApp(GetServer(getPages: [
    GetPage(name: '/', page: HomePage()),
    GetPage(name: '/user', page: UserPage()),
    GetPage(name: '/fruits', page: JsonPage()),
    GetPage(name: '/landing', page: JsonPage()),
    GetPage(name: '/upload', page: UploadPage(), method: Method.post),
    GetPage(name: '/socket', page: SocketPage(), method: Method.ws),
  ]));
}

class HomePage extends GetView {
  @override
  build(Context context) {
    return context.send('Hello, you are on home');
  }
}

class UserPage extends GetView {
  @override
  build(Context context) {
    return context.send('Welcome, ${context.param('name')} !');
  }
}

class JsonPage extends GetView {
  @override
  build(Context context) {
    return context.sendJson({
      "fruits": ["banana", "apple", "orange"]
    });
  }
}

class SocketPage extends GetView {
  @override
  build(Context context) {
    context.ws.listen((socket) {
      socket.onMessage.listen((data) {
        print('data: $data');
        socket.send(data);
      });

      socket.onOpen.listen((ws) {
        print('new socket opened');
      });

      socket.onClose.listen((ws) {
        print('socket has been closed');
      });
    });
    return null;
  }
}

class HtmlPage extends GetView {
  @override
  build(Context context) {
    final path = '${Directory.current.path}/example/index.html';
    return context.sendHtml(path);
  }
}

class UploadPage extends GetView {
  @override
  build(Context context) async {
    final upload = await context.file('file');
    final data = {
      "nameFile": upload.name,
      "mimeType": upload.mimeType,
      "fileBase64": "${base64Encode(upload.data)}",
    };
    return context.sendJson(data);
  }
}
```