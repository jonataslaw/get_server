import 'dart:async';
import 'dart:io';

abstract class WebSocketBase {
  void send(String msg);

  void emit(String event, Object data);

  void close([int status, String reason]);
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

class GetSocket implements WebSocketBase {
  final WebSocket _ws;
  final _messageController = StreamController(),
      _openController = StreamController(),
      _closeController = StreamController();

  Stream _messages;

  GetSocket(this._ws) {
    _messages = _messageController.stream.asBroadcastStream();

    _openController.add(_ws);

    _ws.listen(_messageController.add, onError: (err) {
      _closeController.add(err);
    }, onDone: () {
      _closeController.add('Connection closed');
    });
  }

  @override
  void send(Object message) {
    _ws.add(message);
  }

  @override
  void emit(String event, Object data) {
    _ws.add({event: data});
  }

  ///Listen messages to socket
  Stream get onMessage => _messages;

  ///Listen socket open
  Stream get onOpen => _openController.stream;

  ///Listen socket close
  Stream get onClose => _closeController.stream;

  @override
  void close([int status, String reason]) {
    _ws.close(status, reason);
  }
}
