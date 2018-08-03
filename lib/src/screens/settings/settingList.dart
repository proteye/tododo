import 'package:flutter/material.dart';

import 'package:tododo/src/utils/websocket.util.dart';

Websocket websocket = new Websocket();

class SettingListScreen extends StatefulWidget {
  @override
  createState() => SettingListState();
}

class SettingListState extends State<SettingListScreen> {
  void onLogout() {
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomPadding: true,
      appBar: AppBar(
        title: Text('Settings',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
        titleSpacing: 0.0,
        leading: Icon(Icons.more_vert, color: Colors.black),
        backgroundColor: Colors.white,
        actions: <Widget>[
          FlatButton(
            onPressed: onLogout,
            child: Icon(Icons.exit_to_app, color: Colors.deepOrangeAccent),
          ),
        ],
      ),
      body: Center(child: Icon(Icons.settings)),
    );
  }

  @override
  void dispose() {
    websocket.close();
    super.dispose();
  }
}
