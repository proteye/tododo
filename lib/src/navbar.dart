import 'package:flutter/material.dart';
import 'package:tododo/src/screens/contacts/contactList.dart';
import 'package:tododo/src/screens/chats/chatList.dart';
import 'package:tododo/src/screens/groups/groupList.dart';
import 'package:tododo/src/screens/settings/settingList.dart';

class BottomNavbarScreen extends StatefulWidget {
  @override
  createState() => BottomNavbarState();
}

class BottomNavbarState extends State<BottomNavbarScreen> {
  int _currentIndex = 1;

  Color getNavbarColor(index) {
    return _currentIndex == index ? Colors.blue : Colors.grey;
  }

  void onNavbarTap(index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomPadding: true,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: onNavbarTap,
        items: [
          BottomNavigationBarItem(
              backgroundColor: Colors.white,
              icon: Icon(Icons.people, color: getNavbarColor(0)),
              title:
                  Text('Contacts', style: TextStyle(color: getNavbarColor(0)))),
          BottomNavigationBarItem(
              backgroundColor: Colors.white,
              icon: Icon(Icons.message, color: getNavbarColor(1)),
              title:
                  Text('Messages', style: TextStyle(color: getNavbarColor(1)))),
          BottomNavigationBarItem(
              backgroundColor: Colors.white,
              icon: Icon(Icons.group_work, color: getNavbarColor(2)),
              title:
                  Text('Groups', style: TextStyle(color: getNavbarColor(2)))),
          BottomNavigationBarItem(
              backgroundColor: Colors.white,
              icon: Icon(Icons.settings, color: getNavbarColor(3)),
              title:
                  Text('Settings', style: TextStyle(color: getNavbarColor(3)))),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: <Widget>[
          ContactListScreen(),
          ChatListScreen(),
          GroupListScreen(),
          SettingListScreen(),
        ],
      ),
    );
  }
}
