import 'dart:async';
import 'dart:io';

import 'package:get_instance/get_instance.dart';

abstract class WebSocketBase {
  void send(String msg);

  void emit(String event, Object data);

  void close([int status, String reason]);

  void join(String room);

  void leave(String room);
}

enum SocketType {
  message,
  error,
  done,
}

class SocketMessage {
  final dynamic message;
  final SocketType type;

  SocketMessage(this.message, this.type);
}

class Close {
  final WebSocket socket;
  final String message;
  final int reason;

  Close(this.socket, this.message, this.reason);
}

class GetSocket implements WebSocketBase {
  final WebSocket _ws;
  final _messageController = StreamController(),
      _openController = StreamController<WebSocket>(),
      _closeController = StreamController<Close>();

  final Map<String, List<WebSocket>> rooms;

  Stream _messages;

  GetSocket(this._ws, this.rooms) {
    _messages = _messageController.stream.asBroadcastStream();

    _openController.add(_ws);

    _ws.listen(_messageController.add, onError: (err) {
      _closeController.add(Close(_ws, err.toString(), 0));
    }, onDone: () {
      _closeController.add(Close(_ws, 'Connection closed', 1));
    });
  }

  @override
  void send(Object message) {
    _ws.add(message);
  }

  // TODO: Improve it
  void sendToRoom(String room, Object message) {
    if (rooms.containsKey(room)) {
      rooms[room].forEach((element) {
        element.add(message);
      });
    }
  }

  // TODO: Improve it
  void broadcastToRoom(String room, Object message) {
    if (rooms.containsKey(room)) {
      rooms[room].forEach((element) {
        if (element != _ws) {
          element.add(message);
        }
      });
    }
  }

  @override
  void emit(String event, Object data) {
    _ws.add({event: data});
  }

  @override
  void join(String room) {
    if (rooms.containsKey(room)) {
      rooms[room].add(_ws);
    } else {
      Get.log("Room $room don't exists");
    }
  }

  @override
  void leave(String room) {
    if (room.contains(room)) {
      rooms[room].remove(_ws);
    } else {
      Get.log("Room $room don't exists");
    }
  }

  ///Listen messages to socket
  Stream get onMessage => _messages;

  ///Listen socket open
  Stream<WebSocket> get onOpen => _openController.stream;

  ///Listen socket close
  Stream<Close> get onClose => _closeController.stream;

  @override
  void close([int status, String reason]) {
    rooms.removeWhere((key, value) => value.contains(_ws));
    _ws.close(status, reason);
  }
}
