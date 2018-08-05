import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../config.dart';

class Websocket {
  WebSocketChannel channel;
  Stream<dynamic> bstream;
  StreamSubscription<dynamic> subscription;

  static final Websocket _websocket = new Websocket._internal();

  factory Websocket() {
    return _websocket;
  }

  Websocket._internal();

  void connect(
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
    bstream = channel.stream.asBroadcastStream();
    subscription = bstream.listen(onData, onError: onError, onDone: onDone);
  }

  void send(String message) {
    if (channel != null && channel.closeCode == null && message.isNotEmpty) {
      print('Websocket send: $message');
      channel.sink.add(message);
    }
  }

  void close() {
    if (channel != null && channel.closeCode == null) {
      channel.sink.close();
    }
  }

  void sendDeliveryReport(data) {
    var jsonData = json.decode(data);
    var _encryptTime = jsonData['encrypt_time'] ?? null;
    var _action = jsonData['action'] ?? null;

    if (_encryptTime == null || _action == null || _action == 'delivery_report') {
      return;
    }

    var reportData = json.encode({
      'type': 'server_message',
      'action': 'delivery_report',
      'data': {'encrypt_time': _encryptTime},
      'to': null,
      // 'encrypt_time': DateTime.now().toUtc().toIso8601String(),
    });

    send(reportData);
  }

  void onData(data) {
    print('Websocket received: ${data.toString()}');
    sendDeliveryReport(data);
  }

  void onError(error) {
    print('Websocket error: ${error.toString()}');
  }

  void onDone() {
    print('Websocket done');
    print('Close code: ${channel.closeCode}');
    print('Close reason: ${channel.closeReason}');
    subscription.cancel();
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
