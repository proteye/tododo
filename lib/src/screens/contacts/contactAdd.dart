import 'package:flutter/material.dart';

class ContactAddScreen extends StatefulWidget {
  @override
  createState() => ContactAddState();
}

class ContactAddState extends State<ContactAddScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomPadding: true,
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: Colors.black54,
        ),
        title: Text('Add contact',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
        titleSpacing: 0.0,
        backgroundColor: Colors.white,
      ),
      body: Center(child: Icon(Icons.group_add)),
    );
  }
}
