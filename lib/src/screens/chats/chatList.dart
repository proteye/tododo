import 'package:flutter/material.dart';

class ChatListScreen extends StatefulWidget {
  @override
  createState() => ChatListState();
}

class ChatListState extends State<ChatListScreen> {
  void onChatCreate() {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomPadding: true,
      appBar: AppBar(
        title: Text('Messages',
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
      body: Center(child: Icon(Icons.message)),
    );
  }
}
