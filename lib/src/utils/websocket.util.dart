import 'dart:convert';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../config.dart';

class Websocket {
  WebSocketChannel channel;

  WebSocketChannel connect(
      {String deviceId,
      String username,
      String password,
      String hashKey,
      String url}) {
    Map<String, String> _headers = _getHeaders(
        deviceId: deviceId,
        username: username,
        password: password,
        hashKey: hashKey);

    if (url == null || url.isEmpty) {
      url = Config.WS_HOST;
    }

    channel = IOWebSocketChannel.connect(url, headers: _headers);

    channel.stream.listen((message) {
      print('Websocket received: ${message.toString()}');
    });

    return channel;
  }

  void sendMessage(text) {
    if (channel != null && text.isNotEmpty) {
      channel.sink.add(text);
    }
  }

  void close() {
    if (channel != null) {
      channel.sink.close();
    }
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
