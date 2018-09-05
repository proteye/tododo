import 'dart:convert';

import 'package:tododo/src/utils/db.util.dart';
import 'package:tododo/src/utils/date.util.dart';

class ChatMessageModel {
  String id;
  String chatId;
  String type;
  String username;
  String deviceId;
  String text;
  String filename;
  String fileUrl;
  Map<String, dynamic> contact;
  Map<String, dynamic> quote;
  String status;
  bool isOwn;
  bool isFavorite;
  String salt;
  DateTime dateSend;
  DateTime dateCreate;
  DateTime dateUpdate;

  static DateTime now = new DateTime.now();
  static DateTime today = new DateTime(now.year, now.month, now.day);
  static DateTime yesterday = new DateTime(now.year, now.month, now.day - 1);
  static DateTime sevenDaysAgo = new DateTime(now.year, now.month, now.day - 7);

  String get formatDateCreate {
    if (this.dateCreate.isBefore(sevenDaysAgo)) {
      return '${monthOfYear(this.dateCreate.month)}, ${dayOfWeek(this.dateCreate.weekday)} ${this.dateCreate.hour}:${this.dateCreate.minute}';
    }

    if (this.dateCreate.isBefore(today)) {
      return '${dayOfWeek(this.dateCreate.weekday)}, ${this.dateCreate.hour}:${this.dateCreate.minute}';
    }

    return '${this.dateCreate.hour}:${this.dateCreate.minute}';
  }

  ChatMessageModel(
      {String id,
      String chatId,
      String type,
      String username,
      String deviceId,
      String text,
      String filename,
      String fileUrl,
      Map<String, dynamic> contact,
      Map<String, dynamic> quote,
      String status,
      bool isOwn,
      bool isFavorite,
      String salt,
      DateTime dateSend,
      DateTime dateCreate,
      DateTime dateUpdate}) {
    DateTime dateTimeNow = DateTime.now();
    this.id = id ?? Db.generateId();
    this.chatId = chatId ?? '';
    this.type = type ?? '';
    this.username = username ?? '';
    this.deviceId = deviceId ?? '';
    this.text = text ?? '';
    this.filename = filename ?? '';
    this.fileUrl = fileUrl ?? '';
    this.contact = contact;
    this.quote = quote;
    this.status = status ?? '';
    this.isOwn = isOwn ?? false;
    this.isFavorite = isFavorite ?? false;
    this.salt = salt ?? Db.generateSalt();
    this.dateSend = dateSend ?? dateTimeNow;
    this.dateCreate = dateCreate ?? dateTimeNow;
    this.dateUpdate = dateUpdate ?? dateTimeNow;
  }

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'] as String,
      chatId: json['chatId'] as String,
      type: json['type'] as String,
      username: json['username'] as String,
      deviceId: json['deviceId'] as String,
      text: json['text'] as String,
      filename: json['filename'] as String,
      fileUrl: json['fileUrl'] as String,
      contact: json['contact'] as Map<String, dynamic>,
      quote: json['quote'] as Map<String, dynamic>,
      status: json['status'] as String,
      isOwn: json['isOwn'] as bool,
      isFavorite: json['isFavorite'] as bool,
      salt: json['salt'] as String,
      dateSend:
          json['dateSend'] != null ? DateTime.parse(json['dateSend']) : null,
      dateCreate: json['dateCreate'] != null
          ? DateTime.parse(json['dateCreate'])
          : null,
      dateUpdate: json['dateUpdate'] != null
          ? DateTime.parse(json['dateUpdate'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chatId': chatId,
      'type': type,
      'username': username,
      'deviceId': deviceId,
      'text': text,
      'filename': filename,
      'fileUrl': fileUrl,
      'contact': contact,
      'quote': quote,
      'status': status,
      'isOwn': isOwn,
      'isFavorite': isFavorite,
      'salt': salt,
      'dateSend': dateSend != null ? dateSend.toUtc().toIso8601String() : '',
      'dateCreate':
          dateCreate != null ? dateCreate.toUtc().toIso8601String() : '',
      'dateUpdate':
          dateUpdate != null ? dateUpdate.toUtc().toIso8601String() : '',
    };
  }

  factory ChatMessageModel.fromSqlite(Map<String, dynamic> data) {
    return ChatMessageModel(
      id: data['id'] as String,
      chatId: data['chatId'] as String,
      type: data['type'] as String,
      username: data['username'] as String,
      deviceId: data['deviceId'] as String,
      text: data['text'] as String,
      filename: data['filename'] as String,
      fileUrl: data['fileUrl'] as String,
      contact: data['contact'] != null && data['contact'].isNotEmpty
          ? json.decode(data['contact']) as Map<String, dynamic>
          : {},
      quote: data['quote'] != null && data['quote'].isNotEmpty
          ? json.decode(data['quote']) as Map<String, dynamic>
          : {},
      status: data['status'] as String,
      isOwn: (data['isOwn'] as int) == 1 ? true : false,
      isFavorite: (data['isFavorite'] as int) == 1 ? true : false,
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
      'chatId': chatId,
      'type': type,
      'username': username,
      'deviceId': deviceId,
      'text': text,
      'filename': filename,
      'fileUrl': fileUrl,
      'contact': json.encode(contact),
      'quote': json.encode(quote),
      'status': status,
      'isOwn': isOwn == true ? 1 : 0,
      'isFavorite': isFavorite == true ? 1 : 0,
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
      'chatId': this.chatId,
      'type': this.type,
      'username': this.username,
      'text': this.text,
      'filename': filename,
      'fileUrl': fileUrl,
      'quote': this.quote,
      'salt': this.salt,
      'dateSend':
          this.dateSend != null ? this.dateSend.toUtc().toIso8601String() : '',
    };

    return json.encode(_sendData);
  }
}
