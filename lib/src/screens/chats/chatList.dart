import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:tododo/src/models/chat.model.dart';
import 'package:tododo/src/models/contact.model.dart';
import 'package:tododo/src/models/hashKey.model.dart';
import 'package:tododo/src/services/account.service.dart';
import 'package:tododo/src/services/chat.service.dart';
import 'package:tododo/src/services/hashKey.service.dart';
import 'package:tododo/src/utils/formatter.util.dart';
import 'package:tododo/src/utils/helper.util.dart';
import 'package:tododo/src/utils/websocket.util.dart';
import 'package:tododo/src/utils/db.util.dart';

Db db = new Db();
Websocket websocket = new Websocket();
AccountService accountService = new AccountService();
ChatService chatService = new ChatService();
HashKeyService hashKeyService = new HashKeyService();

class ChatListScreen extends StatefulWidget {
  @override
  createState() => ChatListState();
}

class ChatListState extends State<ChatListScreen> {
  final _searchController = TextEditingController();

  StreamSubscription<dynamic> websocketSubscription;
  List<ChatModel> chats = [];
  String searchText = '';

  void init() async {
    websocketSubscription = websocket.bstream.listen(onWebsocketData);
    _searchController.addListener(onSearchChange);
    chats = await chatService.loadAll();

    setState(() {});
  }

  void deleteChat() async {
    await chatService.deleteAll();
    setState(() {
      chats = chatService.chats;
    });
    Navigator.of(context).pop();
  }

  void showDeleteChatDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          title: new Text('Confirmation'),
          content: new Text(
              'Are you sure to delete ALL chats, messages and hashKeys?'),
          actions: <Widget>[
            new FlatButton(
              child: new Text(
                'Delete',
                style: TextStyle(color: Colors.red, fontSize: 16.0),
              ),
              onPressed: deleteChat,
            ),
            new FlatButton(
              child: new Text(
                'Cancel',
                style: TextStyle(fontSize: 16.0),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void search(String text) async {
    if (text.isEmpty) {
      return;
    }

    setState(() {
      chats = chatService.find(text);
    });
  }

  Future<ChatModel> receiveCreateChat(jsonData) async {
    ChatModel chat;

    try {
      Map<String, dynamic> data = jsonData['data'];
      String payload = data['payload'];
      chat = await chatService.receiveChat(
          payload, accountService.account.privateKey);
      getOpenKey(chat.owner);
      setState(() {
        chats = chatService.chats;
      });

      // calculate and add the hashKey
      if (chat != null) {
        String hashString = HashKeyService.generateHash(
            chat.dateSend, chat.sendData, chat.salt);
        HashKeyModel hashKey = HashKeyModel(
            chatId: chat.id, hashKey: hashString, dateSend: chat.dateSend);
        hashKeyService.add(hashKey);
      }
    } catch (e) {
      print('ChatListState.createChatReceive error: ${e.toString()}');
      return null;
    }

    return chat;
  }

  Future<void> receiveChatMessage(jsonData) async {
    var chatMessage = await chatMessageService.receiveMessage(
        jsonData, chatService.currentChat);
    if (chatMessage == null) {
      return null;
    }

    chatService.updateLastMessage(chatMessage.chatId, chatMessage.toJson());

    setState(() {
      chats = chatService.chats;
    });
  }

  Future<void> receiveMessageStatus(jsonData) async {
    await chatMessageService.receiveMessageStatus(jsonData);
  }

  void getOpenKey(String username) {
    contactService.getOpenKey([username], encryptTime: new DateTime.now());
  }

  // add new contact if not exists
  Future getOpenKeyResult(Map<String, dynamic> jsonData) async {
    Map<String, dynamic> data = jsonData['data'][0];
    String username = data['name'].toString();
    String publicKey = data['open_key'].toString();
    ContactModel contact = new ContactModel(
        username: username,
        nickname: Helper.getNickname(username),
        publicKey: publicKey);
    await contactService.create(contact);
    await chatService
        .updateContactsByOwner(contact.username, [contact.toJson()]);
  }

  void onWebsocketData(data) {
    try {
      var jsonData = json.decode(data);
      switch (jsonData['action']) {
        case 'create_chat':
          receiveCreateChat(jsonData);
          break;
        case 'send_chat_message':
          receiveChatMessage(jsonData);
          break;
        case 'chat_message_received':
          receiveMessageStatus(jsonData);
          break;
        case 'chat_message_read':
          receiveMessageStatus(jsonData);
          break;
        case 'get_open_key':
          getOpenKeyResult(jsonData);
          break;
      }
    } catch (e) {
      print('onWebsocketData error: ${e.toString()}');
    }
  }

  void onSearchChange() {
    var prevSearchText = searchText;

    setState(() {
      if (_searchController.text.isEmpty) {
        chats = chatService.chats;
      }
      searchText = _searchController.text;
    });

    if (prevSearchText != _searchController.text) {
      search(_searchController.text);
    }
  }

  void onSearchClear() {
    _searchController.clear();
  }

  void onChatCreate() async {
    var result = await Navigator.pushNamed(context, '/chatCreate');

    if (result != null) {
      setState(() {
        chats = chatService.chats;
      });
    }
  }

  void onChatTap(chat) {
    Navigator.pushNamed(context, '/chatMessage/${chat.id}');
  }

  void onChatLongPress(chat) {
    showDeleteChatDialog();
  }

  @override
  void initState() {
    super.initState();
    init();
  }

  @override
  void dispose() {
    _searchController.removeListener(onSearchChange);
    _searchController.dispose();
    websocketSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomPadding: false,
      appBar: AppBar(
        centerTitle: false,
        title: Text('Chats',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
        titleSpacing: 0.0,
        leading: Icon(Icons.more_vert, color: Colors.black),
        backgroundColor: Colors.white,
        actions: <Widget>[
          FlatButton(
            onPressed: onChatCreate,
            child: Icon(Icons.add, color: Colors.blue),
          ),
        ],
      ),
      body: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.0),
        child: Column(
          children: <Widget>[
            SizedBox(height: 15.0),
            TextField(
              key: Key('search'),
              controller: _searchController,
              autocorrect: false,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey[200],
                prefixIcon: Icon(Icons.search),
                suffixIcon: IconButton(
                    onPressed: onSearchClear, icon: Icon(Icons.clear)),
                hintText: 'Search in chats',
                contentPadding:
                    const EdgeInsets.fromLTRB(10.0, 10.0, 0.0, 10.0),
                border: OutlineInputBorder(
                    borderSide: BorderSide(width: 0.0, color: Colors.red),
                    borderRadius:
                        const BorderRadius.all(const Radius.circular(30.0))),
              ),
              inputFormatters: <TextInputFormatter>[
                SentenceCaseTextFormatter(),
              ],
            ),
            Expanded(
                child: chatService.chats.length > 0
                    ? ListView.builder(
                        itemCount: chats.length,
                        itemBuilder: (context, index) {
                          var chat = chats[index];
                          var subTitle = 'You have no messages yet';
                          var unreadCount = chats[index].unreadCount > 0
                              ? chats[index].unreadCount.toString()
                              : '';
                          if (chat.lastMessage != null &&
                              chat.lastMessage.isNotEmpty) {
                            String nickname = accountService.account != null &&
                                    accountService.account.username ==
                                        chat.lastMessage['username']
                                ? ''
                                : Helper.getAtNickname(
                                        chat.lastMessage['username']) +
                                    ': ';
                            subTitle = '${nickname}${chat.lastMessage['text']}';
                          }

                          return ListTile(
                            onTap: () {
                              onChatTap(chat);
                            },
                            onLongPress: () {
                              onChatLongPress(chat);
                            },
                            leading: Icon(
                              Icons.account_circle,
                              size: 48.0,
                              color: Colors.blue,
                            ),
                            title: Text(chat.name,
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16.0)),
                            subtitle: Text(subTitle,
                                style: TextStyle(
                                    fontWeight: FontWeight.w400,
                                    fontSize: 14.0)),
                            trailing: Text(unreadCount,
                                style: TextStyle(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.w400,
                                    fontSize: 14.0)),
                          );
                        },
                      )
                    : Icon(Icons.message)),
          ],
        ),
      ),
    );
  }
}
