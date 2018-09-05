import 'dart:convert';

import 'package:tododo/src/utils/date.util.dart';

class HashKeyModel {
  String chatId;
  String messageId;
  String hashKey;
  DateTime dateSend; // with microseconds
  String dateSendMs; // only milliseconds

  HashKeyModel(
      {String chatId,
      String messageId,
      String hashKey,
      DateTime dateSend,
      String dateSendMs}) {
    this.chatId = chatId ?? '';
    this.messageId = messageId ?? '';
    this.hashKey = hashKey ?? '';
    this.dateSend = dateSend;
    this.dateSendMs = dateSendMs ?? dateToIso8601String(dateSend);
  }

  factory HashKeyModel.fromJson(Map<String, dynamic> json) {
    return HashKeyModel(
      chatId: json['chatId'] as String,
      messageId: json['messageId'] as String,
      hashKey: json['hashKey'] as String,
      dateSend:
          json['dateSend'] != null ? DateTime.parse(json['dateSend']) : null,
      dateSendMs: json['dateSendMs'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'chatId': chatId,
      'messageId': messageId,
      'hashKey': hashKey,
      'dateSend': dateSend != null ? dateSend.toUtc().toIso8601String() : '',
      'dateSendMs': dateSendMs,
    };
  }

  @override
  String toString() {
    return json.encode(this);
  }
}
