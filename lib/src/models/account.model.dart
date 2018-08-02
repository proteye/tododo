import 'dart:convert';

class AccountModel {
  String username = '';
  String nickname = '';
  String password = '';
  String email = '';
  String phone = '';
  String publicKey = '';
  String privateKey = '';
  String hashKey = '';
  String deviceId = '';
  String deviceName = '';
  String platform = '';
  String settings = '';
  String hostname = '';

  AccountModel(
      {this.username,
      this.nickname,
      this.password,
      this.email,
      this.phone,
      this.publicKey,
      this.privateKey,
      this.hashKey,
      this.deviceId,
      this.deviceName,
      this.platform,
      this.settings,
      this.hostname});

  factory AccountModel.fromJson(Map<String, dynamic> json) {
    return AccountModel(
        username: json['username'] as String,
        nickname: json['nickname'] as String,
        password: json['password'] as String,
        email: json['email'] as String,
        phone: json['phone'] as String,
        publicKey: json['publicKey'] as String,
        privateKey: json['privateKey'] as String,
        hashKey: json['hashKey'] as String,
        deviceId: json['deviceId'] as String,
        deviceName: json['deviceName'] as String,
        platform: json['platform'] as String,
        settings: json['settings'] as String,
        hostname: json['hostname'] as String);
  }

  Map<String, String> toMap() {
    return {
      'username': username,
      'nickname': nickname,
      'password': password,
      'email': email,
      'phone': phone,
      'publicKey': publicKey,
      'privateKey': privateKey,
      'hashKey': hashKey,
      'deviceId': deviceId,
      'deviceName': deviceName,
      'platform': platform,
      'settings': settings,
      'hostname': hostname,
    };
  }

  @override
  String toString() {
    return json.encode(this.toMap());
  }
}
