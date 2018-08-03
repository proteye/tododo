import 'dart:convert';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../config.dart';

class Websocket {
  WebSocketChannel channel;

  static final Websocket _websocket = new Websocket._internal();

  factory Websocket() {
    return _websocket;
  }

  Websocket._internal();

  WebSocketChannel connect(
      {String deviceId,
      String username,
      String password,
      String hashKey,
      String url}) {
    if (url == null || url.isEmpty) {
      url = Config.WS_HOST;
    }

    Map<String, String> _headers = _getHeaders(
        deviceId: deviceId,
        username: username,
        password: password,
        hashKey: hashKey);

    channel = IOWebSocketChannel.connect(url, headers: _headers);

    channel.stream.listen(onData, onError: onError, onDone: onDone);

    return channel;
  }

  void sendMessage(String text) {
    if (channel != null && channel.closeCode == null && text.isNotEmpty) {
      print('Websocket send: $text');
      channel.sink.add(text);
    }
  }

  void close() {
    if (channel != null && channel.closeCode == null) {
      channel.sink.close();
    }
  }

  void onData(data) {
    print('Websocket received: ${data.toString()}');
  }

  void onError(error) {
    print('Websocket error: ${error.toString()}');
  }

  void onDone() {
    print('Websocket done');
    print('Close code: ${channel.closeCode}');
    print('Close reason: ${channel.closeReason}');
  }

  Map<String, String> _getHeaders(
      {String deviceId, String username, String password, String hashKey}) {
    String usernameDevice = '$username@$deviceId';
    String usernameBase64 = base64.encode(usernameDevice.codeUnits);
    String passwordBase64 = base64.encode(password.codeUnits);
    String authStr = '$usernameBase64:$passwordBase64:$hashKey';
    String basicAuth = 'Basic ' + base64.encode(authStr.codeUnits);

    return {'Authorization': basicAuth};
  }
}
