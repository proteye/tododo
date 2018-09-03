import 'dart:convert';

import 'package:tododo/src/utils/hash.util.dart';
import 'package:tododo/src/utils/db.util.dart';

class ChatModel {
  String id;
  String name;
  String owner;
  List<String> members;
  String membersHash; // for fast search
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
    if (members != null && members.isNotEmpty) {
      members.sort();
    }
    this.id = id ?? Db.generateId();
    this.name = name ?? '';
    this.owner = owner ?? '';
    this.members = members ?? [];
    this.membersHash =
        membersHash ?? HashHelper.hexSha256(this.members.toString());
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

  factory ChatModel.fromJson(Map<String, dynamic> data) {
    return ChatModel(
      id: data['id'] as String,
      name: data['name'] as String,
      owner: data['owner'] as String,
      members:
          data['members'] != null ? List<String>.from(data['members']) : [],
      membersHash: data['membersHash'] as String,
      type: data['type'] as String,
      avatar: data['avatar'] as String,
      lastMessage: data['lastMessage'] as Map<String, dynamic> ?? {},
      contacts: data['contacts'] != null
          ? List<Map<String, dynamic>>.from(data['contacts'])
          : [],
      unreadCount: data['unreadCount'] as int,
      sort: data['sort'] as int,
      pin: data['pin'] as int,
      isMuted: data['isMuted'] as bool,
      isDeleted: data['isDeleted'] as bool,
      salt: data['salt'] as String,
      dateSend:
          data['dateSend'] != null ? DateTime.parse(data['dateSend']) : null,
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

  factory ChatModel.fromSqlite(Map<String, dynamic> data) {
    return ChatModel(
      id: data['id'] as String,
      name: data['name'] as String,
      owner: data['owner'] as String,
      members: data['members'] != null && data['members'].isNotEmpty
          ? List<String>.from(json.decode(data['members']))
          : [],
      membersHash: data['membersHash'] as String,
      type: data['type'] as String,
      avatar: data['avatar'] as String,
      lastMessage: data['lastMessage'] != null && data['lastMessage'].isNotEmpty
          ? json.decode(data['lastMessage']) as Map<String, dynamic>
          : {},
      contacts: data['contacts'] != null && data['contacts'].isNotEmpty
          ? List<Map<String, dynamic>>.from(json.decode(data['contacts']))
          : [],
      unreadCount: data['unreadCount'] as int,
      sort: data['sort'] as int,
      pin: data['pin'] as int,
      isMuted: (data['isMuted'] as int) == 1 ? true : false,
      isDeleted: (data['isDeleted'] as int) == 1 ? true : false,
      salt: data['salt'] as String,
      dateSend:
          data['dateSend'] != null ? DateTime.parse(data['dateSend']) : null,
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
      'id': id,
      'name': name,
      'owner': owner,
      'members': json.encode(members),
      'membersHash': membersHash,
      'type': type,
      'avatar': avatar,
      'lastMessage': json.encode(lastMessage),
      'contacts': json.encode(contacts),
      'unreadCount': unreadCount,
      'sort': sort,
      'pin': pin,
      'isMuted': isMuted == true ? 1 : 0,
      'isDeleted': isDeleted == true ? 1 : 0,
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

  String get sendData {
    Map<String, dynamic> _sendData = {
      'id': this.id,
      'owner': this.owner,
      'members': this.members,
      'membersHash': this.membersHash,
      'salt': this.salt,
      'dateSend':
          this.dateSend != null ? this.dateSend.toUtc().toIso8601String() : '',
    };

    return json.encode(_sendData);
  }
}
