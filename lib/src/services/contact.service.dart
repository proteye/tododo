import 'dart:convert';

import 'package:tododo/src/utils/rsa.util.dart';
import 'package:tododo/src/utils/websocket.util.dart';
import 'package:tododo/src/config.dart';

final Websocket websocket = new Websocket();
final Map<String, String> meta = Config.MESSAGE_META;

class ContactService {
  static void search(String query, {DateTime encryptTime}) {
    var _encryptTime = encryptTime != null
        ? encryptTime.toUtc().toIso8601String()
        : DateTime.now().toUtc().toIso8601String();
    var data = json.encode({
      'type': 'server_message',
      'action': 'search',
      'data': query.toLowerCase(),
      'to': null,
      'encrypt_time': _encryptTime,
    });

    websocket.send(data);
  }

  static void getOpenKey(List<String> usernames, {DateTime encryptTime}) {
    var _encryptTime = encryptTime != null
        ? encryptTime.toUtc().toIso8601String()
        : DateTime.now().toUtc().toIso8601String();
    var data = json.encode({
      'type': 'server_message',
      'action': 'get_open_key',
      'data': usernames,
      'to': null,
      'encrypt_time': _encryptTime,
    });

    websocket.send(data);
  }

  static void requestProfile(List<String> usernames, {DateTime encryptTime}) {
    var _encryptTime = encryptTime != null
        ? encryptTime.toUtc().toIso8601String()
        : DateTime.now().toUtc().toIso8601String();
    var data = json.encode({
      'type': 'client_message',
      'action': 'request_profile',
      'data': {'meta': meta, 'payload': null},
      'to': usernames,
      'encrypt_time': _encryptTime,
    });

    websocket.send(data);
  }

  static void sendProfile(
      String username, String publicKey, Map<String, String> profile,
      {DateTime encryptTime}) {
    var _encryptTime = encryptTime != null
        ? encryptTime.toUtc().toIso8601String()
        : DateTime.now().toUtc().toIso8601String();
    String encrypted = '';

    try {
      var _publicKey = RsaHelper.parsePublicKeyFromPem(publicKey);
      var _profile = json.encode(profile);
      encrypted = RsaHelper.encrypt(_profile, _publicKey);
      var data = json.encode({
        'type': 'client_message',
        'action': 'send_profile',
        'data': {'meta': meta, 'files': {}, 'payload': encrypted},
        'to': [username],
        'encrypt_time': _encryptTime,
      });

      websocket.send(data);
    } catch (e) {
      print('ContactService.sendProfile error: ${e.toString()}');
    }
  }

  static void getOnlineUsers(List<String> usernames, {DateTime encryptTime}) {
    var _encryptTime = encryptTime != null
        ? encryptTime.toUtc().toIso8601String()
        : DateTime.now().toUtc().toIso8601String();
    var data = json.encode({
      'type': 'server_message',
      'action': 'get_online_users',
      'data': usernames,
      'to': null,
      'encrypt_time': _encryptTime,
    });

    websocket.send(data);
  }
}
