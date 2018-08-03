import 'package:flutter/material.dart';

class ContactListScreen extends StatefulWidget {
  @override
  createState() => ContactListState();
}

class ContactListState extends State<ContactListScreen> {
  void onContactAdd() {
    Navigator.pushNamed(context, '/contactAdd');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomPadding: true,
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
      body: Center(child: Icon(Icons.people)),
    );
  }
}
