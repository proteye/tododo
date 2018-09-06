import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:tododo/src/models/account.model.dart';
import 'package:tododo/src/models/chat.model.dart';
import 'package:tododo/src/models/contact.model.dart';
import 'package:tododo/src/services/account.service.dart';
import 'package:tododo/src/services/chat.service.dart';
import 'package:tododo/src/services/contact.service.dart';
import 'package:tododo/src/utils/formatter.util.dart';
import 'package:tododo/src/utils/db.util.dart';

Db db = new Db();
AccountService accountService = new AccountService();
ChatService chatService = new ChatService();
ContactService contactService = new ContactService();

class ChatCreateScreen extends StatefulWidget {
  @override
  createState() => ChatCreateState();
}

class ChatCreateState extends State<ChatCreateScreen> {
  final _searchController = TextEditingController();
  final AccountModel account = accountService.account;

  List<ContactModel> contacts = [];
  List<ContactModel> filteredContacts = [];
  List<ChatModel> chats = [];
  ChatModel chat;
  String searchText = '';

  void init() async {
    // chatService.deleteAll();
    _searchController.addListener(onSearchChange);
    contacts = await contactService.loadAll();

    setState(() {
      filteredContacts = contacts;
    });
  }

  Future<ChatModel> createChat(ContactModel contact) async {
    ChatModel chat;

    try {
      chat = ChatModel(
        name: '@${contact.nickname}',
        owner: account.username,
        members: [account.username, contact.username],
        type: 'private',
        avatar: '',
        contacts: [contact.toJson()],
      );
      await chatService.create(chat);
    } catch (e) {
      print('ChatCreateState.createChat error: ${e.toString()}');
      return null;
    }

    return chat;
  }

  void search(String text) async {
    if (text.isEmpty) {
      return;
    }

    setState(() {
      filteredContacts = contactService.find(text);
    });
  }

  void onSearchChange() {
    var prevSearchText = searchText;

    setState(() {
      if (_searchController.text.isEmpty) {
        filteredContacts = contacts;
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

  void onContactTap(contact) async {
    ChatModel chat = await createChat(contact);
    Navigator.pop(context, chat);
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomPadding: false,
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: Colors.black54,
        ),
        centerTitle: false,
        title: Text('Create chat',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
        titleSpacing: 0.0,
        backgroundColor: Colors.white,
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
                hintText: 'Search in contacts',
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
                child: contacts.length > 0
                    ? ListView.builder(
                        itemCount: filteredContacts.length,
                        itemBuilder: (context, index) {
                          var contact = filteredContacts[index];

                          return ListTile(
                            onTap: () {
                              onContactTap(contact);
                            },
                            leading: Icon(
                              Icons.account_circle,
                              size: 48.0,
                              color: Colors.blue,
                            ),
                            title: Text(contact.username,
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16.0)),
                            subtitle: Text('@${contact.nickname}',
                                style: TextStyle(
                                    fontWeight: FontWeight.w400,
                                    fontSize: 14.0)),
                          );
                        },
                      )
                    : Icon(Icons.people)),
          ],
        ),
      ),
    );
  }
}
