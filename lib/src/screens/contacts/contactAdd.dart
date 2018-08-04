import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:tododo/src/utils/formatter.util.dart';
import 'package:tododo/src/utils/helper.util.dart';
import 'package:tododo/src/utils/websocket.util.dart';

Websocket websocket = new Websocket();

class ContactAddScreen extends StatefulWidget {
  @override
  createState() => ContactAddState();
}

class ContactAddState extends State<ContactAddScreen> {
  final searchController = TextEditingController();
  StreamSubscription<dynamic> websocketSubscription;
  List<String> contacts = [];
  String searchText = '';
  DateTime encryptTime;

  void search(String text) async {
    encryptTime = new DateTime.now();

    if (text.isEmpty) {
      return;
    }

    var data = json.encode({
      'type': 'server_message',
      'action': 'search',
      'data': text.toLowerCase(),
      'to': null,
      'encrypt_time': encryptTime.toUtc().toIso8601String(),
    });

    websocket.send(data);
  }

  void onSearchResult(data) {
    try {
      var decoded = json.decode(data);
      if (decoded['action'] == 'search') {
        var encryptTimeResult = DateTime.parse(decoded['encrypt_time']);
        if (encryptTime.millisecondsSinceEpoch ==
            encryptTimeResult.millisecondsSinceEpoch) {
          setState(() {
            contacts = List<String>.from(decoded['data']);
          });
        }
      }
    } catch (e) {
      print('onSearchResult error: ${e.toString()}');
    }
  }

  void onSearchChange() {
    var prevSearchText = searchText;

    setState(() {
      if (searchController.text.isEmpty) {
        contacts = [];
      }
      searchText = searchController.text;
    });

    if (prevSearchText != searchController.text) {
      search(searchController.text);
    }
  }

  void onSearchClear() {
    searchController.clear();
  }

  void onContactTap(username) {
    Navigator.pop(context, username);
  }

  @override
  void initState() {
    super.initState();
    websocketSubscription = websocket.bstream.listen(onSearchResult);
    searchController.addListener(onSearchChange);
  }

  @override
  void dispose() {
    searchController.removeListener(onSearchChange);
    searchController.dispose();
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
              controller: searchController,
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
                child: contacts.length != 0 || searchController.text.isNotEmpty
                    ? ListView.builder(
                        itemCount: contacts.length,
                        itemBuilder: (context, index) {
                          String username = contacts[index];
                          String nickname = Helper.getNickname(username);

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
                            subtitle: Text(nickname,
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
