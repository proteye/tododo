class RegisterFormModel {
  String login = '';
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

  Map<String, String> toMap() {
    return {
      'login': login,
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
    };
  }
}