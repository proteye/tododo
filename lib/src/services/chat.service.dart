import 'dart:async';
import 'dart:convert';

import 'package:tododo/src/models/chat.model.dart';
import 'package:tododo/src/utils/helper.util.dart';
import 'package:tododo/src/utils/rsa.util.dart';
import 'package:tododo/src/utils/websocket.util.dart';
import 'package:tododo/src/utils/db.util.dart';
import 'package:tododo/src/config.dart';

const TABLE_NAME = 'Chat';
const COLUMN_ID = 'id';

final Db db = new Db();
final Websocket websocket = new Websocket();
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

  Future<ChatModel> create(ChatModel chat) async {
    try {
      int index =
          chats.indexWhere((item) => item.membersHash == chat.membersHash);
      if (index >= 0) {
        return null;
      }

      chats.add(chat);
      var result = await db.insert(TABLE_NAME, chat.toSqlite());
      print('chat created: $result');
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
      chat = chats[index];
      int result = await db.updateById(TABLE_NAME, COLUMN_ID, chat.toSqlite());
      print('chat.lastMessage updated: $result');
    } catch (e) {
      print('ChatService.update error: ${e.toString()}');
      return null;
    }

    return chat;
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

  List<ChatModel> find(String text) {
    return chats.where((item) => item.name.indexOf(text) >= 0).toList();
  }

  Future<ChatModel> receiveCreate(String payload, String privateKey) async {
    ChatModel chat;

    try {
      var _privateKey = RsaHelper.parsePrivateKeyFromPem(privateKey);
      var _decrypted = RsaHelper.decrypt(payload, _privateKey);
      chat = ChatModel.fromSqlite(json.decode(_decrypted));
      chat.name = Helper.getAtNickname(chat.owner);
      chat.contacts = []; // TODO - add contact
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
      var _encrypted = RsaHelper.encrypt(chat.sendData, _publicKey);
      var data = json.encode({
        'type': 'client_message',
        'action': 'create_chat',
        'data': {'meta': _meta, 'files': {}, 'payload': _encrypted},
        'to': [username],
        'encrypt_time': _encryptTime,
      });

      websocket.send(data);
    } catch (e) {
      print('ChatService.sendCreateChat error: ${e.toString()}');
    }
  }
}
