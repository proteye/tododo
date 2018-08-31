import 'dart:async';
import 'dart:convert';

import 'package:tododo/src/models/chatMessage.model.dart';
import 'package:tododo/src/utils/enum.util.dart';
// import 'package:tododo/src/utils/helper.util.dart';
import 'package:tododo/src/utils/websocket.util.dart';
import 'package:tododo/src/utils/db.util.dart';
import 'package:tododo/src/config.dart';

final Websocket websocket = new Websocket();
Db db = new Db();
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
    try {
      chatMessages = [];

      var jsonChatMessages = await db.getByKey(Enum.DB['chatMessages']) ?? '{}';
      jsonChatMessages = json.decode(jsonChatMessages);

      if (jsonChatMessages is Map && jsonChatMessages[chatId] != null) {
        jsonChatMessages = jsonChatMessages[chatId];
      }

      for (var jsonChatMessage in jsonChatMessages) {
        ChatMessageModel chatMessage =
            ChatMessageModel.fromJson(jsonChatMessage);
        chatMessages.add(chatMessage);
      }
      print('chat messages loaded: ${chatMessages.length}');
    } catch (e) {
      print('ChatMessageService.loadByChatId error: ${e.toString()}');
      return [];
    }

    return chatMessages;
  }

  Future<ChatMessageModel> send(ChatMessageModel chatMessage) async {
    try {
      chatMessages.add(chatMessage);
      var jsonChatMessages = json.encode(chatMessages);
      await db.setByKey(Enum.DB['chatMessages'], jsonChatMessages);
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
        text: text,
        status: Enum.MESSAGE_STATUS['sent'],
        isOwn: true,
      );
      return this.send(chatMessage);
    } catch (e) {
      print('ChatMessageService.sendText error: ${e.toString()}');
      return null;
    }
  }

  List<ChatMessageModel> find(text) {
    return chatMessages.where((item) => item.text.indexOf(text) >= 0).toList();
  }

  Future<ChatMessageModel> receiveMessage(
      String payload, String hashKey) async {
    ChatMessageModel chatMessage;

    try {
    } catch (e) {
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

    try {
    } catch (e) {
      print('ChatMessageService.sendMessage error: ${e.toString()}');
    }
  }
}
