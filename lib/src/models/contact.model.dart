import 'dart:convert';

class ContactModel {
  String username = '';
  String nickname = '';
  String deviceId = '';
  List<String> groups = [];
  List<String> phones = [];
  String firstName = '';
  String secondName = '';
  String bio = '';
  String avatar = '';
  String sound = '';
  bool notification = true;
  bool isBlocked = false;
  String settings = '';
  String publicKey = '';
  DateTime dateCreate = DateTime.now();
  DateTime dateUpdate = DateTime.now();

  ContactModel(
      {String username,
      String nickname,
      String deviceId,
      List<String> groups,
      List<String> phones,
      String firstName,
      String secondName,
      String bio,
      String avatar,
      String sound,
      bool notification,
      bool isBlocked,
      String settings,
      String publicKey,
      DateTime dateCreate,
      DateTime dateUpdate}) {
    DateTime dateTimeNow = DateTime.now();
    this.username = username ?? '';
    this.nickname = nickname ?? '';
    this.deviceId = deviceId ?? '';
    this.groups = groups ?? [];
    this.phones = phones ?? [];
    this.firstName = firstName ?? '';
    this.secondName = secondName ?? '';
    this.bio = bio ?? '';
    this.avatar = avatar ?? '';
    this.sound = sound ?? '';
    this.notification = notification ?? true;
    this.isBlocked = isBlocked ?? false;
    this.settings = settings ?? '';
    this.publicKey = publicKey ?? '';
    this.dateCreate = dateCreate ?? dateTimeNow;
    this.dateUpdate = dateUpdate ?? dateTimeNow;
  }

  factory ContactModel.fromJson(Map<String, dynamic> json) {
    return ContactModel(
      username: json['username'] as String,
      nickname: json['nickname'] as String,
      deviceId: json['deviceId'] as String,
      groups: json['groups'] as List<String>,
      phones: json['phones'] as List<String>,
      firstName: json['firstName'] as String,
      secondName: json['secondName'] as String,
      bio: json['bio'] as String,
      avatar: json['avatar'] as String,
      sound: json['sound'] as String,
      notification: json['notification'] as bool,
      isBlocked: json['isBlocked'] as bool,
      settings: json['settings'] as String,
      publicKey: json['publicKey'] as String,
      dateCreate:
          json['dateCreate'] ? DateTime.parse(json['dateCreate']) : null,
      dateUpdate:
          json['dateUpdate'] ? DateTime.parse(json['dateUpdate']) : null,
    );
  }

  Map<String, String> toJson() {
    return {
      'username': username,
      'nickname': nickname,
      'deviceId': deviceId,
      'groups': json.encode(groups),
      'phones': json.encode(phones),
      'firstName': firstName,
      'secondName': secondName,
      'bio': bio,
      'avatar': avatar,
      'sound': sound,
      'notification': notification.toString(),
      'isBlocked': isBlocked.toString(),
      'settings': settings,
      'publicKey': publicKey,
      'dateCreate':
          dateCreate != null ? dateCreate.toUtc().toIso8601String() : '',
      'dateUpdate':
          dateUpdate != null ? dateUpdate.toUtc().toIso8601String() : '',
    };
  }

  @override
  String toString() {
    return json.encode(this);
  }
}
