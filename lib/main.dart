import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:tododo/src/routing.dart';
import 'package:tododo/src/utils/websocket.util.dart';

Websocket websocket = new Websocket();

void main() {
  runApp(MaterialApp(
    title: '2dodo',
    theme: ThemeData(
      brightness: Brightness.light,
      fontFamily: 'Exo2',
    ),
    initialRoute: '/',
    routes: Routing.routes(websocket),
  ));
}
