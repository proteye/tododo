import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:tododo/src/models/contact.model.dart';
import 'package:tododo/src/services/account.service.dart';
import 'package:tododo/src/services/contact.service.dart';
import 'package:tododo/src/utils/formatter.util.dart';
import 'package:tododo/src/utils/helper.util.dart';
import 'package:tododo/src/utils/websocket.util.dart';
import 'package:tododo/src/utils/db.util.dart';

Db db = new Db();
Websocket websocket = new Websocket();
AccountService accountService = new AccountService();
ContactService contactService = new ContactService();

class ContactAddScreen extends StatefulWidget {
  @override
  createState() => ContactAddState();
}

class ContactAddState extends State<ContactAddScreen> {
  final _searchController = TextEditingController();

  bool _maybePop = true;

  StreamSubscription<dynamic> websocketSubscription;
  List<String> contacts = []; // from server
  List<ContactModel> dbContacts = []; // from db
  String searchText = '';
  DateTime encryptTime;

  void init() async {
    websocketSubscription = websocket.bstream.listen(onWebsocketData);
    _searchController.addListener(onSearchChange);
    dbContacts = await contactService.loadAll();

    setState(() {});
  }

  void search(String text) {
    encryptTime = new DateTime.now();

    if (text.isEmpty) {
      return;
    }

    contactService.search(text, encryptTime: encryptTime);
  }

  void searchResult(Map<String, dynamic> jsonData) {
    var encryptTimeResult = DateTime.parse(jsonData['encrypt_time']);
    if (encryptTime.millisecondsSinceEpoch ==
        encryptTimeResult.millisecondsSinceEpoch) {
      List<String> dataList = List<String>.from(jsonData['data']);
      setState(() {
        contacts = dataList
            .where((item) => item != accountService.account.username)
            .toList();
      });
    }
  }

  void getOpenKey(String username) {
    encryptTime = new DateTime.now();
    contactService.getOpenKey([username], encryptTime: encryptTime);
  }

  Future getOpenKeyResult(Map<String, dynamic> jsonData) async {
    var encryptTimeResult = DateTime.parse(jsonData['encrypt_time']);
    if (encryptTime.millisecondsSinceEpoch ==
        encryptTimeResult.millisecondsSinceEpoch) {
      try {
        Map<String, dynamic> data = jsonData['data'][0];
        var contact = await contactService.updatePublicKey(
          data['name'],
          data['open_key'],
        );

        if (contact == null) {
          throw new ArgumentError('contact not found');
        }

        _maybePop = false;
        Navigator.pop(context, contact.username);
      } catch (e) {
        print('getOpenKeyResult error: ${e.toString()}');
      }
    }
  }

  Future addContact(username) async {
    ContactModel contact = await contactService.loadByUsername(username);

    if (contact == null) {
      contact = new ContactModel(
          username: username, nickname: Helper.getNickname(username));
      await contactService.create(contact);
    }

    getOpenKey(username);

    return contact != null ? contact.username : null;
  }

  void onWebsocketData(data) {
    try {
      var jsonData = json.decode(data);
      switch (jsonData['action']) {
        case 'search':
          searchResult(jsonData);
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
        contacts = [];
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

  void onContactTap(username) async {
    var result = await addContact(username);

    var timeOut = const Duration(seconds: 1);
    new Timer(timeOut, () {
      if (_maybePop) {
        Navigator.pop(context, result);
      }
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
        centerTitle: false,
        title: Text('Add contact',
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
                hintText: 'Search contacts for @nickname',
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
                child: contacts.length != 0 || _searchController.text.isNotEmpty
                    ? ListView.builder(
                        itemCount: contacts.length,
                        itemBuilder: (context, index) {
                          String username = contacts[index];
                          String nickname = Helper.getAtNickname(username);
                          String inContacts = '';

                          var inDbContacts = dbContacts.firstWhere((item) {
                            return item.username == username;
                          }, orElse: () {});
                          if (inDbContacts != null) {
                            inContacts = 'in contacts';
                          }

                          return ListTile(
                            onTap: () {
                              onContactTap(username);
                            },
                            leading: Icon(
                              Icons.account_circle,
                              size: 48.0,
                              color: Colors.blue,
                            ),
                            title: Text(username,
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16.0)),
                            subtitle: Text('$nickname $inContacts',
                                style: TextStyle(
                                    fontWeight: FontWeight.w400,
                                    fontSize: 14.0)),
                          );
                        },
                      )
                    : Icon(Icons.group_add)),
          ],
        ),
      ),
    );
  }
}
