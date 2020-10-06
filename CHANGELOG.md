# [0.7.0] 
* Added jwt auth
* 
# [0.6.5] 
* Improve Widget three

# [0.6.4] 
* Fix pageable

## [0.6.3] 
* Fix examples

## [0.6.2] 
* Unification of GetPages from GetServer with GetX.
Now GetPage receives a function that returns a widget, both in get_server and Getx.

## [0.6.1] 
* Fix typo on build method. 
Possible breakchanges:
For a typo, `build(BuildContext context)` was used as `build(Context context)`. This bug was fixed in this version, so you should probably change the "Context" type to "BuildContext" if your build was typed.

## [0.6.0] 
* Added fully compatibility with GetX
* Added Bindings and Controllers

## [0.5.0] 
* Added PageNotFound on GetServer

## [0.4.0] 
* Added Widgets "Text", "Json" and "Html"
* Breaking changes: now you need return a widget.
The syntax that used to be similar to that of Flutter, is now identical to that of Flutter:

To show clear text:
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
  Widget build(Context context) {
    return Text("Welcome to GetX");
  }
}
```

To create Websocket page:
```dart
class SocketPage extends GetView {
  @override
  build(Context context) {
    return Socket(context, builder: (socket) {
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
  }
}
```
Great performance Improvement. 
Now Get_Server is 2.3X faster than Node.js to http requests.

## [0.3.0] 
* Added join, leave and sendToRoom to websocket

## [0.2.0] 
* Added "pageNotFound" to context, and "close"

## [0.1.0] 
* Added optional "Functional way" of create server

## [0.0.1] 
* Initial Release
