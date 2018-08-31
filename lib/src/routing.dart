import 'package:flutter/material.dart';

import 'package:tododo/src/navbar.dart';
import 'package:tododo/src/screens/auth/login.dart';
import 'package:tododo/src/screens/auth/register.dart';
import 'package:tododo/src/screens/contacts/contactAdd.dart';
import 'package:tododo/src/screens/chats/chatCreate.dart';
import 'package:tododo/src/screens/chats/chatMessage.dart';

class Routing {
  static routes() {
    return {
      '/': (context) => new LoginScreen(),
      '/register': (context) => new RegisterScreen(),
      '/main': (context) => new BottomNavbarScreen(),
      '/contactAdd': (context) => new ContactAddScreen(),
      '/chatCreate': (context) => new ChatCreateScreen(),
      // '/chatMessage/${chatId}': // look in onGenerateRoute
    };
  }

  static onGenerateRoute(routeSettings) {
    var path = routeSettings.name.split('/');

    if (path.length < 3 || path[2] == null || path[2].isEmpty) {
      return null;
    }

    // '/chatMessage/${chatId}'
    if (path[1] == 'chatMessage') {
      final chatId = path[2];
      return new MaterialPageRoute(
        builder: (context) => new ChatMessageScreen(chatId: chatId),
        settings: routeSettings,
      );
    }
  }
}
