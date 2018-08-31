import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:tododo/src/models/account.model.dart';
import 'package:tododo/src/models/chat.model.dart';
import 'package:tododo/src/models/hashKey.model.dart';
import 'package:tododo/src/services/account.service.dart';
import 'package:tododo/src/services/chat.service.dart';
import 'package:tododo/src/services/hashKey.service.dart';
import 'package:tododo/src/utils/formatter.util.dart';
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
  final AccountModel account = accountService.account;

  StreamSubscription<dynamic> websocketSubscription;
  List<ChatModel> chats = [];
  String searchText = '';

  void init() async {
    websocketSubscription = websocket.bstream.listen(onWebsocketData);
    _searchController.addListener(onSearchChange);
    await chatService.init();

    setState(() {
      chats = chatService.chats;
    });
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
      chat = await chatService.receiveCreate(payload, account.privateKey);
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

  void onWebsocketData(data) {
    try {
      var jsonData = json.decode(data);
      switch (jsonData['action']) {
        case 'create_chat':
          receiveCreateChat(jsonData);
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

    if (result != null) {}
  }

  void onChatTap(chat) {
    Navigator.pushNamed(context, '/chatMessage/${chat.id}');
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
                          var subTitle = chat.lastMessage != null &&
                                  chat.lastMessage.isNotEmpty
                              ? '${chat.lastMessage['username']}: ${chat.lastMessage['text']}'
                              : 'You have no messages yet';

                          return ListTile(
                            onTap: () {
                              onChatTap(chat);
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
