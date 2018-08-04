import 'dart:core';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:tododo/src/utils/enum.util.dart';
import 'package:tododo/src/utils/formatter.util.dart';
import 'package:tododo/src/utils/helper.util.dart';
import 'package:tododo/src/utils/db.util.dart';

Db db = new Db();

class ContactListScreen extends StatefulWidget {
  @override
  createState() => ContactListState();
}

class ContactListState extends State<ContactListScreen> {
  final searchController = TextEditingController();
  List<Map<String, dynamic>> contacts = [];
  List<Map<String, dynamic>> filteredContacts = [];
  String searchText = '';

  void init() async {
    searchController.addListener(onSearchChange);
    var _contacts = await db.getByKey(Enum.DB['contacts']) ?? [];

    setState(() {
      contacts = List<Map<String, dynamic>>.from(_contacts);
      filteredContacts = contacts;
    });
  }

  void search(String text) async {
    if (text.isEmpty) {
      return;
    }

    setState(() {
      filteredContacts = contacts.where((item) => item['username'].indexOf(text) >= 0).toList();
    });
  }

  void onSearchChange() {
    var prevSearchText = searchText;

    setState(() {
      if (searchController.text.isEmpty) {
        filteredContacts = contacts;
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

  void onContactAdd() async {
    var result = await Navigator.pushNamed(context, '/contactAdd');

    if (result != null) {
      var _contacts = await db.getByKey(Enum.DB['contacts']) ?? [];
      setState(() {
        contacts = List<Map<String, dynamic>>.from(_contacts);
        filteredContacts = contacts;
      });
    }
  }

  void onContactTap(username) {}

  @override
  void initState() {
    super.initState();
    init();
  }

  @override
  void dispose() {
    searchController.removeListener(onSearchChange);
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomPadding: false,
      appBar: AppBar(
        title: Text('Contacts',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
        titleSpacing: 0.0,
        leading: Icon(Icons.more_vert, color: Colors.black),
        backgroundColor: Colors.white,
        actions: <Widget>[
          FlatButton(
            onPressed: onContactAdd,
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
              controller: searchController,
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
                            title: Text(contact['username'],
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16.0)),
                            subtitle: Text('@${contact['nickname']}',
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
