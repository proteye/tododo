import 'package:flutter/material.dart';

class GroupListScreen extends StatefulWidget {
  @override
  createState() => GroupListState();
}

class GroupListState extends State<GroupListScreen> {
  void onGroupAdd() {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomPadding: true,
      appBar: AppBar(
        centerTitle: false,
        title: Text('Groups',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
        titleSpacing: 0.0,
        leading: Icon(Icons.more_vert, color: Colors.black),
        backgroundColor: Colors.white,
        actions: <Widget>[
          FlatButton(
            onPressed: onGroupAdd,
            child: Icon(Icons.add, color: Colors.blue),
          ),
        ],
      ),
      body: Center(child: Icon(Icons.group_work)),
    );
  }
}
