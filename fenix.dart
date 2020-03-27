import "dart:async";
import "dart:convert";

import "package:meta/meta.dart";
import "package:web_socket_channel/web_socket_channel.dart";

class _Listener {
  final StreamController stream;
  final bool Function(Map) check;

  _Listener(this.stream, this.check);
}

class Fenix {
  static int _lastID = 0;
  static final Map<String, Fenix> _cache = {};

  final WebSocketChannel _websocket = WebSocketChannel.connect(
      Uri(host: "bloblet.com", port: 3300, scheme: "ws"));
  final List<_Listener> _listeners = [];

  factory Fenix({debug = true}) {
    return _cache.putIfAbsent("cachedAPI", () => Fenix._internal(debug));
  }

  Fenix._internal(bool debug) {
    this._websocket.stream.listen((raw) {
      if (debug) {
        print(raw);
      }
      Map message = JsonDecoder().convert(raw);
      this._notifyAll(message);
    });
  }

  StreamController _send(Map msg) {
    _lastID++;
    int id = _lastID;
    msg["id"] = id;
    this._websocket.sink.add(jsonEncode(msg));
    return this._listen((Map message) => message["id"] == id);
  }

  StreamController _listen(bool Function(Map) check) {
    StreamController stream = StreamController();
    this._listeners.add(_Listener(stream, check));
    return stream;
  }

  void _notifyAll(Map message) {
    for (_Listener listener in this._listeners) {
      if (listener.check(message)) {
        listener.stream.add(message);
      }
    }
  }

  StreamController<Map> register({
    @required String username, 
    @required String email, 
    @required String password
  }) {

    return this._send({
      "type": "REGISTER",
      "username": username,
      "email": email,
      "password": password
    });
  }

  StreamController<Map> login({
    @required String email, 
    @required String password
  }) {

    return this._send({"type": "LOGIN", "email": email, "password": password});
  }

  StreamController<Map> channel({
    @required String msgID
  }) {

    return this._send({
      "type": "CHANNEL",
      "msg_id": msgID
    });
  }

  StreamController<Map> loginBot({
    @required String token
  }) {

    return this._send({
      "type": "LOGIN_BOT",
      "token": token
    });
  }

  StreamController<Map> message({
    @required String channel, 
    @required String message
  }) {

    return this._send({
      "type": "MESSAGE",
      "channel": channel,
      "message": message
    });
  }

  StreamController<Map> registerBot({
    @required botName, 
    @required parentEmail, 
    @required parentPassword
  }) {

    return this._send({
      "type": "REGISTER_BOT",
      "name": botName,
      "parentEmail": parentEmail,
      "parentPassword": parentPassword
    });
  }

  StreamController<Map> verify({
    @required String code
  }) {

    return this._send({
      "type": "REGISTER_BOT",
      "code": code,
    });
  }

  StreamController<Map> version() {

    return this._send({
      "type": "VERSION",
    });
  }
}
