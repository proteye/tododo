import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:tododo/src/models/contact.model.dart';
import 'package:tododo/src/services/contact.service.dart';
import 'package:tododo/src/utils/formatter.util.dart';
import 'package:tododo/src/utils/db.util.dart';

Db db = new Db();
ContactService contactService = new ContactService();

class ContactListScreen extends StatefulWidget {
  @override
  createState() => ContactListState();
}

class ContactListState extends State<ContactListScreen> {
  final _searchController = TextEditingController();

  List<ContactModel> contacts = [];
  List<ContactModel> filteredContacts = [];
  String searchText = '';

  void init() async {
    _searchController.addListener(onSearchChange);
    contacts = await contactService.loadAll();

    setState(() {
      filteredContacts = contacts;
    });
  }

  void deleteChat() {
    contactService.deleteAll();
    setState(() {
      contacts = contactService.contacts;
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
          content: new Text('Are you sure to delete ALL contacts?'),
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

  void onContactAdd() async {
    var result = await Navigator.pushNamed(context, '/contactAdd');

    if (result != null) {
      contacts = await contactService.loadAll();
      setState(() {
        filteredContacts = contacts;
      });
    }
  }

  void onContactTap(contact) {}

  void onContactLongPress(contact) {
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomPadding: false,
      appBar: AppBar(
        centerTitle: false,
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
                            onLongPress: () {
                              onContactLongPress(contact);
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
