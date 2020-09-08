# Get Server

The first backend/frontend/mobile framework written in one syntax for Android, iOS, Web, Linux, Mac, Windows, Fuchsia, and backend.

GetX is the most popular framework for Flutter, and has gained great engagement in the community for facilitating development to the extreme, making the most complex things of Flutter simple.
However, many developers start at Flutter/GetX without any basis in the backend, and are forced to learn another stack, another language, to build their APIs.
GetX fulfilling its mission of transforming development into something simple and productive, created its own server with almost 100% use of the frontEnd code. If you have a local database written in dart (like Hive and Sembast), you can turn it into a backend and build your api to provide them with a simple copy and paste.
All of your Model classes are reused.
All its route syntax is reused.
All of your business logic is reused, and your visualization can be easily exchanged for your API, with a few lines of code.

## Getting Started

This project is still in beta, your contribution will be very welcome for the stable launch.

 Installing

Add Get to your pubspec.yaml file:

```yaml
dependencies:
  get_server:
```

Import get in files that it will be used:

```dart
import 'package:get_server/get_server.dart';
```

To create a server, and send a message:

```dart
void main() {
  runApp(GetServer(
    getPages: [
      GetPage(name: '/', page: Home()),
    ],
  ));
}

class Home extends GetView {
  @override
  build(Context context) {
    return context.send("Welcome to GetX");
  }
}
```
This is stupidly simple, you just define the path of your URL, and the page you want to deliver!

What if you want to return a json page?

```dart
class Home extends GetView {
  @override
  build(Context context) {
    return context.sendJson({
      "fruits": ["banana", "apple", "orange"]
    });
  }
}
```

Ok, you created your project with Flutter web, and you have no idea how to host it on a VPS, would it be possible to create the API for your application, and use the same GetX to display the HTML page?

You just need to copy your Flutter web page and place it in your web project:

```dart
class Home extends GetView {
  @override
  build(Context context) {
    final path = '${Directory.current.path}/web/index.html';
    return context.sendHtml(path);
  }
}
```

Ok, but what if I want to do a POST method to send a photo to my server, for example, how do I do this?

Okay, that sounds crazy, but you upload the file to your server, and retrieve it with an "upload.data".
For the example not to be small, I will return a json response with the name of the file, his mimeType, and the same file back decoded in base64 so the example doesn't have just 5 lines.

```dart
class Home extends GetView {
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

I'm still not convinced, this is just an http server, but what if I want to create a chat that has real-time communication, how would I do that?

Okay, today is your lucky day. This is not just an http server, but also a websocket server.

```dart
class SocketPage extends GetView {
  @override
  build(Context context) {
    context.ws.listen((socket) {
      socket.onMessage.listen((data) {
        print('data: $data');   
      });

      socket.onOpen.listen((ws) {
        print('new socket opened');
        socket.send('You are connected to server');
      });

      socket.onClose.listen((ws) {
        print('socket has been closed');
      });
    });
  }
}
```

Dart is not popular for servers, however, attracting people who already program in Flutter to the backend is now also a mission of GetX. Transforming one-dimensional programmers into full stack developers with 0% learning curve, and reusing code is also one of GetX's goals, and I hope you will help us on this journey.

How can you help?
- Creating Pull requests, adding resources, improving documentation, creating sample applications, producing articles, videos about Getx, suggesting improvements, and helping to disseminate this framework in development communities.
- Supporting this project.

TODO:
- Add Auth options.
- Remove requirements dart:mirrors to allow people to compile the server and use only the binary, protecting its source code.
- Add some ORM
- Create a dart SDK script installation to make it easier to install get_server on servers.
- Creation of Bindings and Controllers (as in the main GetX) to adapt the project 100% with Getx for frontend.

### Accessing GetX:

GetX starts by default on port 8080.
This was done to, if you want to install a reverse proxy like nginx, do it without much effort.

You could, for example, access the home page created in this example, using:

`http://localhost:8080/`
or 
`http://127.0.0.1:8080/`

However, if you want to start it on another port, such as 80, for example, you can simply do:

```dart
void main() {
  runApp(GetServer(
    port: 80,
    getPages: [
      GetPage(name: '/', page: Home()),
    ],
  ));
}
```

To SSL you have too the `certificateChain`, `privateKey`, and `password`, configurations on GetServer