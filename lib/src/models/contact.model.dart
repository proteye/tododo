import 'dart:convert';

class ContactModel {
  String username;
  String nickname;
  String deviceId;
  List<String> groups;
  List<String> phones;
  String firstName;
  String secondName;
  String bio;
  String avatar;
  String sound;
  bool isNotify;
  bool isBlocked;
  String settings;
  String publicKey;
  DateTime dateCreate;
  DateTime dateUpdate;

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
      bool isNotify,
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
    this.isNotify = isNotify ?? true;
    this.isBlocked = isBlocked ?? false;
    this.settings = settings ?? '';
    this.publicKey = publicKey ?? '';
    this.dateCreate = dateCreate ?? dateTimeNow;
    this.dateUpdate = dateUpdate ?? dateTimeNow;
  }

  factory ContactModel.fromJson(Map<String, dynamic> data) {
    return ContactModel(
      username: data['username'] as String,
      nickname: data['nickname'] as String,
      deviceId: data['deviceId'] as String,
      groups: List<String>.from(data['groups']),
      phones: List<String>.from(data['phones']),
      firstName: data['firstName'] as String,
      secondName: data['secondName'] as String,
      bio: data['bio'] as String,
      avatar: data['avatar'] as String,
      sound: data['sound'] as String,
      isNotify: data['isNotify'] as bool,
      isBlocked: data['isBlocked'] as bool,
      settings: data['settings'] as String,
      publicKey: data['publicKey'] as String,
      dateCreate: data['dateCreate'] != null
          ? DateTime.parse(data['dateCreate'])
          : null,
      dateUpdate: data['dateUpdate'] != null
          ? DateTime.parse(data['dateUpdate'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'nickname': nickname,
      'deviceId': deviceId,
      'groups': groups,
      'phones': phones,
      'firstName': firstName,
      'secondName': secondName,
      'bio': bio,
      'avatar': avatar,
      'sound': sound,
      'isNotify': isNotify,
      'isBlocked': isBlocked,
      'settings': settings,
      'publicKey': publicKey,
      'dateCreate':
          dateCreate != null ? dateCreate.toUtc().toIso8601String() : '',
      'dateUpdate':
          dateUpdate != null ? dateUpdate.toUtc().toIso8601String() : '',
    };
  }

  factory ContactModel.fromSqlite(Map<String, dynamic> data) {
    return ContactModel(
      username: data['username'] as String,
      nickname: data['nickname'] as String,
      deviceId: data['deviceId'] as String,
      groups: List<String>.from(json.decode(data['groups'])),
      phones: List<String>.from(json.decode(data['phones'])),
      firstName: data['firstName'] as String,
      secondName: data['secondName'] as String,
      bio: data['bio'] as String,
      avatar: data['avatar'] as String,
      sound: data['sound'] as String,
      isNotify: (data['isNotify'] as int) == 1 ? true : false,
      isBlocked: (data['isBlocked'] as int) == 1 ? true : false,
      settings: data['settings'] as String,
      publicKey: data['publicKey'] as String,
      dateCreate: data['dateCreate'] != null
          ? DateTime.parse(data['dateCreate'])
          : null,
      dateUpdate: data['dateUpdate'] != null
          ? DateTime.parse(data['dateUpdate'])
          : null,
    );
  }

  Map<String, dynamic> toSqlite() {
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
      'isNotify': isNotify == true ? 1 : 0,
      'isBlocked': isBlocked == true ? 1 : 0,
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
