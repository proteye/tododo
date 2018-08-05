import 'dart:async';
import 'dart:convert';

import 'package:tododo/src/models/chat.model.dart';
import 'package:tododo/src/utils/enum.util.dart';
import 'package:tododo/src/utils/rsa.util.dart';
import 'package:tododo/src/utils/websocket.util.dart';
import 'package:tododo/src/utils/db.util.dart';
import 'package:tododo/src/config.dart';

final Websocket websocket = new Websocket();
Db db = new Db();
final Map<String, String> meta = Config.MESSAGE_META;

class ChatService {
  List<ChatModel> chats = [];
  ChatModel currentChat = ChatModel();

  static final ChatService _chatService = new ChatService._internal();

  factory ChatService() {
    return _chatService;
  }

  ChatService._internal();

  Future<void> init() async {
    var jsonChats = await db.getByKey(Enum.DB['chats']) ?? [];
    jsonChats = json.decode(jsonChats);

    for (var jsonChat in jsonChats) {
      ChatModel chat = ChatModel.fromJson(jsonChat);
      chats.add(chat);
    }
  }

  Future<ChatModel> create(ChatModel chat) async {
    try {
      chats.clear(); // TODO: remove after tests
      chats.add(chat);
      var jsonChats = json.encode(chats);
      await db.setByKey(Enum.DB['chats'], jsonChats);
      var test = await db.getByKey(Enum.DB['chats']) ?? [];
      print('chat created: ${json.decode(test).length}');
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

  static void sendCreateChat(String username, String publicKey, ChatModel chat,
      {DateTime encryptTime}) {
    var _encryptTime = encryptTime != null
        ? encryptTime.toUtc().toIso8601String()
        : DateTime.now().toUtc().toIso8601String();
    String encrypted = '';

    try {
      var _chat = chat.toJson();
      var _data = json.encode({
        'id': _chat['id'],
        'owner': _chat['owner'],
        'members': _chat['members'],
        'membersHash': _chat['membersHash'],
        'salt': _chat['salt'],
        'dateSend': _chat['dateSend'],
      });
      var _publicKey = RsaHelper.parsePublicKeyFromPem(publicKey);
      encrypted = RsaHelper.encrypt(_data, _publicKey);
      var data = json.encode({
        'type': 'client_message',
        'action': 'create_chat',
        'data': {'meta': meta, 'files': {}, 'payload': encrypted},
        'to': [username],
        'encrypt_time': _encryptTime,
      });

      websocket.send(data);
    } catch (e) {
      print('ChatService.sendCreateChat error: ${e.toString()}');
    }
  }
}
