import 'package:get_server/get_server.dart';

class SocketPage extends GetView {
  @override
  Widget build(BuildContext context) {
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
