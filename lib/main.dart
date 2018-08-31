import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:tododo/src/routing.dart';

void main() {
  runApp(MaterialApp(
    title: '2dodo',
    theme: ThemeData(
      brightness: Brightness.light,
      fontFamily: 'Exo2',
      scaffoldBackgroundColor: Colors.white,
    ),
    initialRoute: '/',
    routes: Routing.routes(),
    onGenerateRoute: (routeSettings) {
      return Routing.onGenerateRoute(routeSettings);
    },
  ));
}
