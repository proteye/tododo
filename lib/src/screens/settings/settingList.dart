import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tododo/src/services/account.service.dart';
import 'package:tododo/src/services/hashKey.service.dart';
import 'package:tododo/src/utils/websocket.util.dart';
import 'package:tododo/src/utils/db.util.dart';

Websocket websocket = new Websocket();
Db db = new Db();
AccountService accountService = new AccountService();
HashKeyService hashKeyService = new HashKeyService();

class SettingListScreen extends StatefulWidget {
  @override
  createState() => SettingListState();
}

class SettingListState extends State<SettingListScreen> {
  void init() async {
    await accountService.init();
    await hashKeyService.init();
  }

  void onLogout() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('authorized', false);
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }

  @override
  void initState() {
    super.initState();
    init();
  }

  @override
  void dispose() {
    websocket.close();
    db.close();
    super.dispose();
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
}
