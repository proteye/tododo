import 'dart:async';

import '../utils/http.util.dart';

class AuthService {
  static Future register(Function callback,
      {Map<String, String> params, Function errorCallback}) async {
    Map<String, String> _params = {
      'name': params['login'],
      'password': params['password'],
      'email': params['email'],
      'open_key': params['publicKey'],
      'hash_key': params['hashKey'],
      'device_id': params['deviceId'],
      'device_name': params['deviceName'],
      'platform': params['platform'],
      'settings': params['settings']
    };

    return Http.post('/registration/', callback,
        params: _params, errorCallback: errorCallback);
  }
}
