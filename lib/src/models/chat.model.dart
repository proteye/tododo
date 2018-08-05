import 'dart:convert';

import 'package:tododo/src/utils/db.util.dart';

class ChatModel {
  String id;
  String name;
  String owner;
  List<String> members;
  String membersHash;
  String type;
  String avatar;
  Map<String, dynamic> lastMessage;
  List<Map<String, dynamic>> contacts;
  int unreadCount;
  int sort;
  int pin;
  bool isMuted;
  bool isDeleted;
  String salt;
  DateTime dateSend;
  DateTime dateCreate;
  DateTime dateUpdate;

  ChatModel(
      {String id,
      String name,
      String owner,
      List<String> members,
      String membersHash,
      String type,
      String avatar,
      Map<String, dynamic> lastMessage,
      List<Map<String, dynamic>> contacts,
      int unreadCount,
      int sort,
      int pin,
      bool isMuted,
      bool isDeleted,
      String salt,
      DateTime dateSend,
      DateTime dateCreate,
      DateTime dateUpdate}) {
    DateTime dateTimeNow = DateTime.now();
    this.id = id ?? Db.generateId();
    this.name = name ?? '';
    this.owner = owner ?? '';
    this.members = members ?? [];
    this.membersHash = membersHash ?? '';
    this.type = type ?? '';
    this.avatar = avatar ?? '';
    this.lastMessage = lastMessage ?? {};
    this.contacts = contacts ?? [];
    this.unreadCount = unreadCount ?? 0;
    this.sort = sort ?? 0;
    this.pin = pin ?? 0;
    this.isMuted = isMuted ?? false;
    this.isDeleted = isDeleted ?? false;
    this.salt = salt ?? Db.generateSalt();
    this.dateSend = dateSend ?? dateTimeNow;
    this.dateCreate = dateCreate ?? dateTimeNow;
    this.dateUpdate = dateUpdate ?? dateTimeNow;
  }

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    return ChatModel(
      id: json['id'] as String,
      name: json['name'] as String,
      owner: json['owner'] as String,
      members: List<String>.from(json['members']),
      membersHash: json['membersHash'] as String,
      type: json['type'] as String,
      avatar: json['avatar'] as String,
      lastMessage: json['lastMessage'] as Map<String, dynamic>,
      contacts: List<Map<String, dynamic>>.from(json['contacts']),
      unreadCount: json['unreadCount'] as int,
      sort: json['sort'] as int,
      pin: json['pin'] as int,
      isMuted: json['isMuted'] as bool,
      isDeleted: json['isDeleted'] as bool,
      salt: json['salt'] as String,
      dateSend: json['dateSend'] != null ? DateTime.parse(json['dateSend']) : null,
      dateCreate:
          json['dateCreate'] != null ? DateTime.parse(json['dateCreate']) : null,
      dateUpdate:
          json['dateUpdate'] != null ? DateTime.parse(json['dateUpdate']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'owner': owner,
      'members': members,
      'membersHash': membersHash,
      'type': type,
      'avatar': avatar,
      'lastMessage': lastMessage,
      'contacts': contacts,
      'unreadCount': unreadCount,
      'sort': sort,
      'pin': pin,
      'isMuted': isMuted,
      'isDeleted': isDeleted,
      'salt': salt,
      'dateSend': dateSend != null ? dateSend.toUtc().toIso8601String() : '',
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
