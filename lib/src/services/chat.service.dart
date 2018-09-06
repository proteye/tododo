import 'dart:async';
import 'dart:convert';

import 'package:tododo/src/models/chat.model.dart';
import 'package:tododo/src/models/hashKey.model.dart';
import 'package:tododo/src/services/hashKey.service.dart';
import 'package:tododo/src/services/contact.service.dart';
import 'package:tododo/src/services/chatMessage.service.dart';
import 'package:tododo/src/utils/helper.util.dart';
import 'package:tododo/src/utils/rsa.util.dart';
import 'package:tododo/src/utils/websocket.util.dart';
import 'package:tododo/src/utils/db.util.dart';
import 'package:tododo/src/config.dart';

const TABLE_NAME = 'Chat';
const COLUMN_ID = 'id';

final Db db = new Db();
final Websocket websocket = new Websocket();
final HashKeyService hashKeyService = new HashKeyService();
final ContactService contactService = new ContactService();
final ChatMessageService chatMessageService = new ChatMessageService();
final Map<String, String> meta = Config.MESSAGE_META;

class ChatService {
  List<ChatModel> chats = [];
  ChatModel currentChat;

  static final ChatService _chatService = new ChatService._internal();

  factory ChatService() {
    return _chatService;
  }

  ChatService._internal();

  Future<List<ChatModel>> loadAll({bool force = false}) async {
    if (force != true && chats.length > 0) {
      return chats;
    }

    chats = [];
    var jsonChats = await db.getByQuery(TABLE_NAME, '');

    for (var jsonChat in jsonChats) {
      ChatModel chat = ChatModel.fromSqlite(jsonChat);
      chats.add(chat);
    }

    return chats;
  }

  // load and set currentChat
  Future<ChatModel> loadById(String id) async {
    try {
      var jsonChat = await db.getById(TABLE_NAME, COLUMN_ID, id);
      if (jsonChat == null) {
        throw new ArgumentError('chat not found');
      }
      currentChat = ChatModel.fromSqlite(jsonChat);
    } catch (e) {
      print('ChatService.loadById error: ${e.toString()}');
      return null;
    }

    return currentChat;
  }

  // set currentChat and clear unreadCount
  Future<ChatModel> loadAndClearById(String id) async {
    try {
      currentChat = await loadById(id);
      if (currentChat != null && currentChat.unreadCount > 0) {
        currentChat.unreadCount = 0;
        await db.updateById(TABLE_NAME, COLUMN_ID, currentChat.toSqlite());
        int index = chats.indexWhere((item) => item.id == id);
        if (index >= 0) {
          chats[index].unreadCount = 0;
        }
      }
    } catch (e) {
      print('ChatService.loadById error: ${e.toString()}');
      return null;
    }

    return currentChat;
  }

  Future<ChatModel> create(ChatModel chat) async {
    try {
      // don't create new chat when exists
      int index =
          chats.indexWhere((item) => item.membersHash == chat.membersHash);
      if (index >= 0) {
        return null;
      }

      // add chat to cache and db
      chats.add(chat);
      var result = await db.insert(TABLE_NAME, chat.toSqlite());
      print('chat created: $result');

      // generate hashKey from current chat
      String hashString =
          HashKeyService.generateHash(chat.dateSend, chat.sendData, chat.salt);
      HashKeyModel nextHashKey = HashKeyModel(
          chatId: chat.id, hashKey: hashString, dateSend: chat.dateSend);
      hashKeyService.add(nextHashKey);

      // encrypt and send chat to opponent via websocket
      _sendCreatedChat(
        chat.contacts[0]['username'],
        chat.contacts[0]['publicKey'],
        chat,
      );
    } catch (e) {
      print('ChatService.create error: ${e.toString()}');
      return null;
    }

    return chat;
  }

  Future<ChatModel> update(String id, ChatModel chat) async {
    try {
      int index = chats.indexWhere((item) => item.id == id);
      if (index == -1) {
        throw new ArgumentError('chat is not found');
      }

      chats[index] = chat;
      int result = await db.updateById(TABLE_NAME, COLUMN_ID, chat.toSqlite());
      print('chat updated: $result');
    } catch (e) {
      print('ChatService.update error: ${e.toString()}');
      return null;
    }

    return chat;
  }

  Future<ChatModel> updateLastMessage(
      String id, Map<String, dynamic> lastMessage) async {
    ChatModel chat;
    try {
      int index = chats.indexWhere((item) => item.id == id);
      if (index == -1) {
        throw new ArgumentError('chat is not found');
      }

      chats[index].lastMessage = lastMessage;
      if (!(currentChat != null && currentChat.id == id)) {
        chats[index].unreadCount += 1;
      }
      chat = chats[index];
      int result = await db.updateById(TABLE_NAME, COLUMN_ID, chat.toSqlite());
      print('chat.lastMessage updated: $result');
    } catch (e) {
      print('ChatService.update error: ${e.toString()}');
      return null;
    }

    return chat;
  }

  Future<void> updateContactsByOwner(
      String owner, List<Map<String, dynamic>> contacts) async {
    try {
      var _contacts = json.encode(contacts);
      int result = await db.update(TABLE_NAME, {'contacts': _contacts},
          where: 'owner = ?', whereArgs: [owner]);
      print('chat.contacts updated: $result');
    } catch (e) {
      print('ChatService.update error: ${e.toString()}');
      return null;
    }
  }

  Future<bool> deleteById(String id) async {
    try {
      int index = chats.indexWhere((item) => item.id == id);
      if (index == -1) {
        throw new ArgumentError('chat is not found');
      }

      chats.removeAt(index);
      int result = await db.deleteById(TABLE_NAME, COLUMN_ID, id);
      print('chat deleted: $result');
    } catch (e) {
      print('ChatService.deleteById error: ${e.toString()}');
      return null;
    }

    return true;
  }

  Future<bool> deleteAll() async {
    try {
      chats = [];
      int result = await db.deleteAll(TABLE_NAME);

      // TODO - remove after tests
      await chatMessageService.deleteAll();
      await hashKeyService.deleteAll();

      print('all chats deleted: $result');
    } catch (e) {
      print('ChatService.deleteAll error: ${e.toString()}');
      return null;
    }

    return true;
  }

  void clearCurrentChat() {
    currentChat = null;
  }

  List<ChatModel> find(String text) {
    return chats.where((item) => item.name.indexOf(text) >= 0).toList();
  }

  Future<ChatModel> receiveChat(String payload, String privateKey) async {
    ChatModel chat;

    try {
      var _privateKey = RsaHelper.parsePrivateKeyFromPem(privateKey);
      var _decrypted = RsaHelper.hybridDecrypt(payload, _privateKey);
      chat = ChatModel.fromJson(json.decode(_decrypted));
      chat.name = Helper.getAtNickname(chat.owner);
      var contact = await contactService.loadByUsername(chat.owner);
      chat.contacts = contact != null ? [contact.toJson()] : [];
      chats.add(chat);
      var result = await db.insert(TABLE_NAME, chat.toSqlite());
      print('chat received and created: $result');
    } catch (e) {
      print('ChatService.receiveCreate error: ${e.toString()}');
      return null;
    }

    return chat;
  }

  void _sendCreatedChat(String username, String publicKey, ChatModel chat,
      {DateTime encryptTime}) {
    var _encryptTime = encryptTime != null
        ? encryptTime.toUtc().toIso8601String()
        : DateTime.now().toUtc().toIso8601String();
    var _meta = Map.from(meta);
    _meta['id'] = chat.id;

    try {
      var _publicKey = RsaHelper.parsePublicKeyFromPem(publicKey);
      var _encrypted = RsaHelper.hybridEncrypt(chat.sendData, _publicKey);
      var data = json.encode({
        'type': 'client_message',
        'action': 'create_chat',
        'data': {'meta': _meta, 'payload': _encrypted},
        'to': [username],
        'encrypt_time': _encryptTime,
      });

      websocket.send(data);
    } catch (e) {
      print('ChatService.sendCreateChat error: ${e.toString()}');
    }
  }
}
