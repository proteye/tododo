import 'dart:async';

import 'package:tododo/src/models/chatMessage.model.dart';
import 'package:tododo/src/utils/enum.util.dart';
import 'package:tododo/src/utils/websocket.util.dart';
import 'package:tododo/src/utils/db.util.dart';
import 'package:tododo/src/config.dart';

const TABLE_NAME = 'ChatMessage';
const COLUMN_ID = 'id';

final Db db = new Db();
final Websocket websocket = new Websocket();
final Map<String, String> meta = Config.MESSAGE_META;

class ChatMessageService {
  List<ChatMessageModel> chatMessages = [];
  ChatMessageModel currentMessage;

  static final ChatMessageService _chatMessageService =
      new ChatMessageService._internal();

  factory ChatMessageService() {
    return _chatMessageService;
  }

  ChatMessageService._internal();

  Future<List<ChatMessageModel>> loadByChatId(String chatId) async {
    chatMessages = [];
    var jsonChatMessages = await db
        .getByParams(TABLE_NAME, where: 'chatId = ?', whereArgs: [chatId]);

    for (var jsonChatMessage in jsonChatMessages) {
      ChatMessageModel chatMessage =
          ChatMessageModel.fromSqlite(jsonChatMessage);
      chatMessages.add(chatMessage);
    }

    return chatMessages;
  }

  Future<ChatMessageModel> send(ChatMessageModel chatMessage) async {
    try {
      chatMessages.add(chatMessage);
      var result = await db.insert(TABLE_NAME, chatMessage.toSqlite());
      print('chatMessage created: $result');
    } catch (e) {
      print('ChatMessageService.send error: ${e.toString()}');
      return null;
    }

    return chatMessage;
  }

  Future<ChatMessageModel> sendText(String text,
      {String chatId, String username}) async {
    try {
      ChatMessageModel chatMessage = new ChatMessageModel(
        chatId: chatId,
        type: Enum.MESSAGE_TYPE['text'],
        username: username,
        text: text.trim(),
        status: Enum.MESSAGE_STATUS['sent'],
        isOwn: true,
      );
      return this.send(chatMessage);
    } catch (e) {
      print('ChatMessageService.sendText error: ${e.toString()}');
      return null;
    }
  }

  List<ChatMessageModel> find(String text) {
    return chatMessages.where((item) => item.text.indexOf(text) >= 0).toList();
  }

  Future<ChatMessageModel> receiveMessage(
      String payload, String hashKey) async {
    ChatMessageModel chatMessage;

    try {} catch (e) {
      print('ChatMessageService.receiveMessage error: ${e.toString()}');
      return null;
    }

    return chatMessage;
  }

  static void sendMessage(
      String username, String hashKey, ChatMessageModel chatMessage,
      {DateTime encryptTime}) {
    var _encryptTime = encryptTime != null
        ? encryptTime.toUtc().toIso8601String()
        : DateTime.now().toUtc().toIso8601String();
    var _meta = Map.from(meta);
    _meta['id'] = chatMessage.id;
    _meta['chatId'] = chatMessage.chatId;

    try {} catch (e) {
      print('ChatMessageService.sendMessage error: ${e.toString()}');
    }
  }
}
