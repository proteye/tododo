import 'dart:async';
import 'dart:convert';

import 'package:tododo/src/models/chat.model.dart';
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

  Future<void> sendStatusTyping(String chatId, String toUsername) async {
    _sendMessageStatus(
      Enum.MESSAGE_STATUS['typing'],
      toUsername,
      [],
      chatId,
    );
  }

  Future<void> sendStatusRead(String chatId, String toUsername) async {
    if (chatId.isEmpty || toUsername.isEmpty) {
      return null;
    }

    try {
      var jsonChatMessages = await db.getByParams(
        TABLE_NAME,
        where: 'chatId = ? AND status = ? AND isOwn = 0',
        whereArgs: [chatId, Enum.MESSAGE_STATUS['received']],
      );

      if (jsonChatMessages.length == 0) {
        return null;
      }

      String dateNow = DateTime.now().toUtc().toIso8601String();
      var result = await db.update(
        TABLE_NAME,
        {'status': Enum.MESSAGE_STATUS['read'], 'dateUpdate': dateNow},
        where: 'chatId = ? AND status = ? AND isOwn = 0',
        whereArgs: [chatId, Enum.MESSAGE_STATUS['received']],
      );
      print('chat messages status updated to "read": $result');

      List<String> ids =
          jsonChatMessages.map((item) => item['id'].toString()).toList();
      _sendMessageStatus(
        Enum.MESSAGE_STATUS['read'],
        toUsername,
        ids,
        chatId,
      );
    } catch (e) {
      print('ChatMessageService.sendStatusRead error: ${e.toString()}');
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
      Map<String, dynamic> jsonMessage, ChatModel currentChat) async {
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
      chatMessage.status = Enum.MESSAGE_STATUS['received'];
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

      // send received or read status
      var status = Enum.MESSAGE_STATUS['received'];
      if (currentChat != null && currentChat.id == chatMessage.chatId) {
        status = Enum.MESSAGE_STATUS['read'];
      }
      _sendMessageStatus(
        status,
        chatMessage.username,
        [chatMessage.id],
        chatMessage.chatId,
      );
    } catch (e) {
      print('ChatMessageService.receiveMessage error: ${e.toString()}');
      return null;
    }

    return chatMessage;
  }

  Future<void> receiveMessageStatus(Map<String, dynamic> jsonMessage) async {
    try {
      var action = jsonMessage['action'];
      var meta = jsonMessage['data']['meta'];
      List<String> ids = List<String>.from(meta['ids']);
      String status = '';

      if (ids == null || ids.isEmpty) {
        throw new ArgumentError('meta.ids is empty');
      }

      switch (action) {
        case 'chat_message_received':
          status = Enum.MESSAGE_STATUS['received'];
          break;
        case 'chat_message_read':
          status = Enum.MESSAGE_STATUS['read'];
          break;
      }

      if (status.isEmpty) {
        throw new ArgumentError('message status is empty');
      }

      DateTime dateNow = DateTime.now();
      String dateNowIso = dateNow.toUtc().toIso8601String();
      List<String> whereCond = new List<String>.filled(ids.length, '?');
      String where = 'id IN (${whereCond.join(', ')})';

      chatMessages.forEach((item) {
        if (ids.indexOf(item.id) >= 0) {
          item.status = status;
          item.dateUpdate = dateNow;
        }
      });

      var result = await db.update(
          TABLE_NAME, {'status': status, 'dateUpdate': dateNowIso},
          where: where, whereArgs: ids);
      print('chat messages status received and updated: $result');
    } catch (e) {
      print('ChatMessageService.receiveMessageStatus error: ${e.toString()}');
    }
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

  void _sendMessageStatus(
    String status,
    String username,
    List<String> ids,
    String chatId,
  ) {
    var _encryptTime = DateTime.now().toUtc().toIso8601String();
    var _meta = Map.from(meta);
    _meta['ids'] = ids;
    _meta['chatId'] = chatId;
    var action = '';

    switch (status) {
      case 'received':
        action = 'chat_message_received';
        break;
      case 'read':
        action = 'chat_message_read';
        break;
      case 'typing':
        action = 'chat_message_typing';
        break;
    }

    try {
      if (action.isEmpty) {
        throw new ArgumentError('action is empty');
      }

      var data = json.encode({
        'type': 'client_message',
        'action': action,
        'data': {'meta': _meta},
        'to': [username],
        'encrypt_time': _encryptTime,
      });

      websocket.send(data);
    } catch (e) {
      print('ChatMessageService._sendMessage error: ${e.toString()}');
    }
  }
}
