import 'dart:async';
import 'dart:convert';

import 'package:tododo/src/models/chat.model.dart';
import 'package:tododo/src/utils/enum.util.dart';
import 'package:tododo/src/utils/helper.util.dart';
import 'package:tododo/src/utils/rsa.util.dart';
import 'package:tododo/src/utils/websocket.util.dart';
import 'package:tododo/src/utils/db.util.dart';
import 'package:tododo/src/config.dart';

final Websocket websocket = new Websocket();
Db db = new Db();
final Map<String, String> meta = Config.MESSAGE_META;

class ChatService {
  List<ChatModel> chats = [];
  ChatModel currentChat;

  static final ChatService _chatService = new ChatService._internal();

  factory ChatService() {
    return _chatService;
  }

  ChatService._internal();

  Future<void> init() async {
    var jsonChats = await db.getByKey(Enum.DB['chats']) ?? '[]';
    jsonChats = json.decode(jsonChats);

    for (var jsonChat in jsonChats) {
      ChatModel chat = ChatModel.fromJson(jsonChat);
      chats.add(chat);
    }
  }

  Future<ChatModel> loadById(String id) async {
    try {
      var jsonChats = await db.getByKey(Enum.DB['chats']) ?? '[]';
      jsonChats = json.decode(jsonChats);
      var jsonCurrentChat = jsonChats.singleWhere((item) => id == item['id']);
      currentChat = ChatModel.fromJson(jsonCurrentChat);
    } catch (e) {
      print('ChatService.loadById error: ${e.toString()}');
      return null;
    }

    return currentChat;
  }

  Future<ChatModel> create(ChatModel chat) async {
    try {
      chats.clear(); // TODO: remove after tests
      chats.add(chat);
      var jsonChats = json.encode(chats);
      await db.setByKey(Enum.DB['chats'], jsonChats);
      // var test = await db.getByKey(Enum.DB['chats']) ?? '[]';
      // print('chat created: ${json.decode(test).length}');
      sendCreateChat(
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
      chats[index] = chat;
      await db.setByKey(Enum.DB['chats'], chats);
    } catch (e) {
      print('ChatService.update error: ${e.toString()}');
      return null;
    }

    return chat;
  }

  Future<bool> deleteById(String id) async {
    try {
      int index = chats.indexWhere((item) => item.id == id);
      chats.removeAt(index);
      await db.setByKey(Enum.DB['chats'], chats);
    } catch (e) {
      print('ChatService.deleteById error: ${e.toString()}');
      return null;
    }

    return true;
  }

  List<ChatModel> find(text) {
    return chats.where((item) => item.name.indexOf(text) >= 0).toList();
  }

  Future<ChatModel> receiveCreate(String payload, String privateKey) async {
    ChatModel chat;

    try {
      var _privateKey = RsaHelper.parsePrivateKeyFromPem(privateKey);
      var _decrypted = RsaHelper.decrypt(payload, _privateKey);
      chat = ChatModel.fromJson(json.decode(_decrypted));
      chat.name = Helper.getAtNickname(chat.owner);
      chat.contacts = []; // TODO - add contact
      chats.add(chat);
      var jsonChats = json.encode(chats);
      await db.setByKey(Enum.DB['chats'], jsonChats);
      // var test = await db.getByKey(Enum.DB['chats']) ?? '[]';
      // print('chat created: ${json.decode(test).length}');
    } catch (e) {
      print('ChatService.receiveCreate error: ${e.toString()}');
      return null;
    }

    return chat;
  }

  static void sendCreateChat(String username, String publicKey, ChatModel chat,
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
