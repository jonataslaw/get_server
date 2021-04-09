part of socket;

abstract class GetSocket {
  factory GetSocket.fromRaw(
    WebSocket ws,
    Map<String, HashSet<GetSocket>> rooms,
    HashSet<GetSocket> sockets,
  ) {
    return _GetSocketImpl(ws, rooms, sockets);
  }
  Map<String?, HashSet<GetSocket>> get rooms;
  HashSet<GetSocket> get sockets;
  void send(dynamic message);

  void emit(String event, Object data);

  void close([int? status, String? reason]);

  bool join(String? room);

  bool leave(String room);

  dynamic operator [](String key);

  void operator []=(String key, dynamic value);

  WebSocket get rawSocket;

  int get id;

  int get length;

  GetSocket? getSocketById(int id);

  void broadcast(Object message);

  void broadcastEvent(String event, Object data);

  void sendToAll(Object message);

  void emitToAll(String event, Object data);

  void sendToRoom(String? room, Object message);

  void emitToRoom(String event, String? room, Object message);

  void broadcastToRoom(String room, Object message);

  void onOpen(OpenSocket fn);

  void onClose(CloseSocket fn);

  void onError(CloseSocket fn);

  void onMessage(MessageSocket fn);

  void on(String event, MessageSocket message);
}
