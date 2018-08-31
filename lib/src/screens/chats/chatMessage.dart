import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';

import 'package:tododo/src/models/account.model.dart';
import 'package:tododo/src/models/chat.model.dart';
import 'package:tododo/src/models/chatMessage.model.dart';
// import 'package:tododo/src/models/hashKey.model.dart';
import 'package:tododo/src/services/account.service.dart';
import 'package:tododo/src/services/chat.service.dart';
import 'package:tododo/src/services/chatMessage.service.dart';
import 'package:tododo/src/services/hashKey.service.dart';
import 'package:tododo/src/utils/enum.util.dart';
import 'package:tododo/src/utils/formatter.util.dart';
import 'package:tododo/src/utils/websocket.util.dart';
import 'package:tododo/src/utils/db.util.dart';

Db db = new Db();
Websocket websocket = new Websocket();
AccountService accountService = new AccountService();
ChatService chatService = new ChatService();
ChatMessageService chatMessageService = new ChatMessageService();
HashKeyService hashKeyService = new HashKeyService();

class ChatMessageScreen extends StatefulWidget {
  final String chatId;

  ChatMessageScreen({Key key, @required this.chatId}) : super(key: key);

  @override
  createState() => ChatMessageState();
}

class ChatMessageState extends State<ChatMessageScreen> {
  final _searchController = TextEditingController();
  final _messageController = TextEditingController();
  final _messageFocusNode = FocusNode();
  final _scrollController = ScrollController();
  final AccountModel account = accountService.account;

  StreamSubscription<dynamic> websocketSubscription;
  ChatModel chat;
  List<ChatMessageModel> chatMessages = [];
  String searchText = '';
  String messageText = '';

  void init() async {
    websocketSubscription = websocket.bstream.listen(onWebsocketData);
    _searchController.addListener(onSearchChange);
    _messageController.addListener(onMessageChange);
    _messageFocusNode.addListener(onMessageTextFieldFocus);
    chat = await chatService.loadById(widget.chatId);
    chatMessages = await chatMessageService.loadByChatId(widget.chatId);
    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
    // print('chat: $chat');
    // print('chatMessages: $chatMessages');
    setState(() {});
  }

  void search(String text) async {
    if (text.isEmpty) {
      return;
    }

    setState(() {
      chatMessages = chatMessageService.find(text);
    });
  }

  Future<ChatMessageModel> receiveChatMessage(jsonData) async {}

  Future<ChatMessageModel> receiveMessageStatus(jsonData) async {}

  Future receiveMessageTyping(jsonData) async {}

  void onWebsocketData(data) {
    try {
      var jsonData = json.decode(data);
      switch (jsonData['action']) {
        case 'send_chat_message':
          receiveChatMessage(jsonData);
          break;
        case 'chat_message_received':
          receiveMessageStatus(jsonData);
          break;
        case 'chat_message_read':
          receiveMessageStatus(jsonData);
          break;
        case 'chat_message_typing':
          receiveMessageTyping(jsonData);
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
        chatMessages = chatMessageService.chatMessages;
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

  void onMessageChange() {
    setState(() {
      messageText = _messageController.text;
    });
  }

  void onMessageTextFieldFocus() {
    if (_messageFocusNode.hasFocus) {
      new Timer(Duration(milliseconds: 300), () {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            curve: Curves.easeOut,
            duration: const Duration(milliseconds: 300),
          );
        });
      });
    }
  }

  void onSendMessage() {
    print('send: $messageText');
    setState(() {
      chatMessageService.sendText(messageText,
          chatId: chat.id, username: account.username);
      _messageController.clear();
    });
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        curve: Curves.easeOut,
        duration: const Duration(milliseconds: 300),
      );
    });
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
    _messageController.dispose();
    _messageFocusNode.removeListener(onMessageTextFieldFocus);
    _messageFocusNode.dispose();
    _scrollController.dispose();
    websocketSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomPadding: true,
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: Colors.black54,
        ),
        title: Text('Chat Message',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
        titleSpacing: 0.0,
        backgroundColor: Colors.white,
      ),
      body: Container(
        padding: EdgeInsets.symmetric(horizontal: 0.0),
        child: Column(
          children: <Widget>[
            SizedBox(height: 15.0),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10.0),
              child: TextField(
                key: Key('search'),
                controller: _searchController,
                autocorrect: false,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey[200],
                  prefixIcon: Icon(Icons.search),
                  suffixIcon: IconButton(
                      onPressed: onSearchClear, icon: Icon(Icons.clear)),
                  hintText: 'Search in messages',
                  contentPadding:
                      const EdgeInsets.fromLTRB(10.0, 10.0, 0.0, 10.0),
                  border: OutlineInputBorder(
                      borderRadius:
                          const BorderRadius.all(const Radius.circular(30.0))),
                ),
                inputFormatters: <TextInputFormatter>[
                  SentenceCaseTextFormatter(),
                ],
              ),
            ),
            Expanded(
              child: chatMessageService.chatMessages.length > 0
                  ? ListView.builder(
                      controller: _scrollController,
                      itemCount: chatMessages.length,
                      itemBuilder: (context, index) {
                        var chatMessage = chatMessages[index];

                        var messageStatusIcon =
                            Icon(Icons.done, size: 16.0, color: Colors.grey);
                        if (chatMessage.status ==
                            Enum.MESSAGE_STATUS['received']) {
                          messageStatusIcon = Icon(Icons.done_all,
                              size: 16.0, color: Colors.grey);
                        } else if (chatMessage.status ==
                            Enum.MESSAGE_STATUS['read']) {
                          messageStatusIcon = Icon(Icons.done_all,
                              size: 16.0, color: Colors.blue);
                        }

                        if (chatMessage.isOwn) {
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius:
                                  BorderRadius.all(Radius.circular(15.0)),
                            ),
                            margin: EdgeInsets.fromLTRB(40.0, 5.0, 10.0, 5.0),
                            padding: EdgeInsets.all(10.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  chatMessage.text,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w400,
                                    fontSize: 16.0,
                                  ),
                                ),
                                Container(
                                  alignment: Alignment.centerRight,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(10.0)),
                                    ),
                                    padding:
                                        EdgeInsets.fromLTRB(8.0, 2.0, 8.0, 2.0),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: <Widget>[
                                        messageStatusIcon,
                                        SizedBox(width: 2.0),
                                        Text(
                                          chatMessage.formatDateCreate,
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontWeight: FontWeight.w500,
                                            fontSize: 12.0,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return Container(
                          decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Colors.grey),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(15.0))),
                          margin: EdgeInsets.fromLTRB(10.0, 5.0, 40.0, 5.0),
                          padding: EdgeInsets.all(10.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                chatMessage.text,
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w400,
                                  fontSize: 16.0,
                                ),
                              ),
                              Container(
                                alignment: Alignment.centerRight,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.transparent,
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(10.0)),
                                  ),
                                  padding:
                                      EdgeInsets.fromLTRB(8.0, 2.0, 8.0, 2.0),
                                  child: Text(
                                    chatMessage.formatDateCreate,
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12.0,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    )
                  : Icon(Icons.message),
            ),
            Container(
              color: Colors.grey[100],
              height: 44.0,
              child: Row(
                children: <Widget>[
                  IconButton(
                    icon: Icon(Icons.attachment),
                    onPressed: null,
                  ),
                  Flexible(
                    child: TextField(
                      key: Key('message'),
                      controller: _messageController,
                      focusNode: _messageFocusNode,
                      autocorrect: true,
                      maxLines: 1,
                      textCapitalization: TextCapitalization.sentences,
                      keyboardType: TextInputType.text,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        hintText: 'Message',
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 8.0, horizontal: 20.0),
                        border: OutlineInputBorder(
                            borderRadius: const BorderRadius.all(
                                const Radius.circular(30.0))),
                      ),
                    ),
                  ),
                  messageText.isEmpty
                      ? IconButton(
                          icon: Icon(Icons.mic_none),
                          onPressed: null,
                        )
                      : IconButton(
                          icon: Icon(Icons.send),
                          color: Colors.blue,
                          onPressed: onSendMessage,
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
