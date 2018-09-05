import 'dart:async';
import 'dart:convert';

import 'package:tododo/src/models/chatMessage.model.dart';
import 'package:tododo/src/models/hashKey.model.dart';
import 'package:tododo/src/services/hashKey.service.dart';
import 'package:tododo/src/services/contact.service.dart';
import 'package:tododo/src/utils/enum.util.dart';
import 'package:tododo/src/utils/aes.util.dart';
import 'package:tododo/src/utils/websocket.util.dart';
import 'package:tododo/src/utils/db.util.dart';
import 'package:tododo/src/config.dart';

const TABLE_NAME = 'ChatMessage';
const COLUMN_ID = 'id';

final Db db = new Db();
final Websocket websocket = new Websocket();
final HashKeyService hashKeyService = new HashKeyService();
final ContactService contactService = new ContactService();
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

  Future<ChatMessageModel> send(
      ChatMessageModel chatMessage, String toUsername) async {
    try {
      // add message to cache and db
      chatMessages.add(chatMessage);
      var result = await db.insert(TABLE_NAME, chatMessage.toSqlite());
      print('chatMessage created: $result');

      // find last hashKey to encrypt current message
      List<Map<String, dynamic>> jsonHashKeys =
          await hashKeyService.getByChatId(chatMessage.chatId, inJson: true);
      if (jsonHashKeys == null || jsonHashKeys.length == 0) {
        throw new ArgumentError('hashKey is not found');
      }
      HashKeyModel hashKey = HashKeyModel.fromJson(jsonHashKeys[0]);

      // generate hashKey from current message
      String hashString = HashKeyService.generateHash(
          chatMessage.dateSend, chatMessage.sendData, chatMessage.salt);
      HashKeyModel nextHashKey = HashKeyModel(
          chatId: chatMessage.chatId,
          messageId: chatMessage.id,
          hashKey: hashString,
          dateSend: chatMessage.dateSend);
      hashKeyService.add(nextHashKey);

      // encrypt and send message to opponent via websocket
      _sendMessage(
        toUsername,
        hashKey,
        chatMessage,
      );
    } catch (e) {
      print('ChatMessageService.send error: ${e.toString()}');
      return null;
    }

    return chatMessage;
  }

  Future<ChatMessageModel> sendText(String text,
      {String chatId, String fromUsername, String toUsername}) async {
    try {
      ChatMessageModel chatMessage = new ChatMessageModel(
        chatId: chatId,
        type: Enum.MESSAGE_TYPE['text'],
        username: fromUsername,
        text: text.trim(),
        status: Enum.MESSAGE_STATUS['sent'],
        isOwn: true,
      );
      return this.send(chatMessage, toUsername);
    } catch (e) {
      print('ChatMessageService.sendText error: ${e.toString()}');
      return null;
    }
  }

  Future<bool> deleteAll() async {
    try {
      chatMessages = [];
      int result = await db.deleteAll(TABLE_NAME);
      print('all chatMessages deleted: $result');
    } catch (e) {
      print('ChatMessageService.deleteAll error: ${e.toString()}');
      return null;
    }

    return true;
  }

  List<ChatMessageModel> find(String text) {
    return chatMessages
        .where((item) => item.text.toLowerCase().indexOf(text) >= 0)
        .toList();
  }

  Future<ChatMessageModel> receiveMessage(
      Map<String, dynamic> jsonMessage) async {
    ChatMessageModel chatMessage;

    try {
      var encryptTime = jsonMessage['encrypt_time'];
      var payload = jsonMessage['data']['payload'];

      HashKeyModel hashKey = await hashKeyService.getByDate(encryptTime);
      if (hashKey == null) {
        throw new ArgumentError('hashKey is not found');
      }

      var decrypted = AesHelper.decrypt(hashKey.hashKey, payload);
      chatMessage = ChatMessageModel.fromJson(json.decode(decrypted));
      chatMessage.isOwn = false;
      chatMessage.isFavorite = false;
      chatMessage.dateCreate = DateTime.now();
      chatMessage.dateUpdate = chatMessage.dateCreate;
      var contact = await contactService.loadByUsername(chatMessage.username);
      chatMessage.contact = contact != null ? contact.toJson() : {};
      chatMessages.add(chatMessage);
      var result = await db.insert(TABLE_NAME, chatMessage.toSqlite());
      print('chatMessage received and created: $result');

      // generate hashKey from current message
      String hashString = HashKeyService.generateHash(
          chatMessage.dateSend, decrypted, chatMessage.salt);
      HashKeyModel nextHashKey = HashKeyModel(
          chatId: chatMessage.chatId,
          messageId: chatMessage.id,
          hashKey: hashString,
          dateSend: chatMessage.dateSend);
      hashKeyService.add(nextHashKey);
    } catch (e) {
      print('ChatMessageService.receiveMessage error: ${e.toString()}');
      return null;
    }

    return chatMessage;
  }

  void _sendMessage(
    String username,
    HashKeyModel hashKey,
    ChatMessageModel chatMessage,
  ) {
    var _encryptTime = hashKey.dateSend.toUtc().toIso8601String();
    var _meta = Map.from(meta);
    _meta['id'] = chatMessage.id;
    _meta['chatId'] = chatMessage.chatId;

    try {
      var _encrypted = AesHelper.encrypt(hashKey.hashKey, chatMessage.sendData);
      var data = json.encode({
        'type': 'client_message',
        'action': 'send_chat_message',
        'data': {'meta': _meta, 'payload': _encrypted},
        'to': [username],
        'encrypt_time': _encryptTime,
      });
      websocket.send(data);
    } catch (e) {
      print('ChatMessageService._sendMessage error: ${e.toString()}');
    }
  }
}
