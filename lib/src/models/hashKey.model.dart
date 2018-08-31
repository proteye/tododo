import 'dart:convert';

class HashKeyModel {
  String chatId;
  String messageId;
  String hashKey;
  DateTime dateSend;

  HashKeyModel(
      {String chatId, String messageId, String hashKey, DateTime dateSend}) {
    this.chatId = chatId ?? '';
    this.messageId = messageId ?? '';
    this.hashKey = hashKey ?? '';
    this.dateSend = dateSend;
  }

  factory HashKeyModel.fromJson(Map<String, dynamic> json) {
    return HashKeyModel(
      chatId: json['chatId'] as String,
      messageId: json['messageId'] as String,
      hashKey: json['hashKey'] as String,
      dateSend:
          json['dateSend'] != null ? DateTime.parse(json['dateSend']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'chatId': chatId,
      'messageId': messageId,
      'hashKey': hashKey,
      'dateSend': dateSend != null ? dateSend.toUtc().toIso8601String() : '',
    };
  }

  @override
  String toString() {
    return json.encode(this);
  }
}
