import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tododo/src/models/account.model.dart';
import 'package:tododo/src/utils/formatter.util.dart';
import 'package:tododo/src/utils/websocket.util.dart';
import 'package:tododo/src/utils/db.util.dart';

Websocket websocket = new Websocket();
Db db = new Db();

class LoginScreen extends StatefulWidget {
  @override
  createState() => LoginFormState();
}

class LoginFormState extends State<LoginScreen> {
  final _scaffoldKey = new GlobalKey<ScaffoldState>();
  final _formKey = new GlobalKey<FormState>();

  bool _autovalidate = false;
  bool _disabled = false;

  String login = '';
  String password = '';
  bool createNewKey = false;

  void showInSnackBar(String value, {Duration duration, bool error: false}) {
    var _duration = duration != null ? duration : Duration(milliseconds: 1500);
    _scaffoldKey.currentState.showSnackBar(new SnackBar(
      content: new Text(value),
      duration: _duration,
      backgroundColor: error ? Colors.red : null,
    ));
  }

  void init() async {
    final prefs = await SharedPreferences.getInstance();
    bool authorized = prefs.getBool('authorized') ?? false;
    if (authorized) {
      var accountJson = json.decode(prefs.getString('account'));
      setState(() {
        _disabled = true;
        login = accountJson['nickname'];
        password = accountJson['password'];
      });
      signin();
    }
  }

  void signin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      var accountString = prefs.getString('account') ?? '{}';
      var accountJson = json.decode(accountString);
      AccountModel account = AccountModel.fromJson(accountJson);
      // print('account: ${account}');

      if (login != account.nickname) {
        showInSnackBar('Failure! Wrong login or password',
            duration: Duration(seconds: 3), error: true);
        setState(() {
          _disabled = false;
        });
        return;
      }

      showInSnackBar('Signing in...', duration: Duration(seconds: 3));

      websocket.connect(
          username: account.username,
          password: password,
          deviceId: account.deviceId,
          hashKey: account.hashKey);

      var timeOut = const Duration(seconds: 3);
      new Timer(timeOut, () async {
        // login failed
        if (websocket.channel.closeCode != null) {
          showInSnackBar('Failure! Wrong login or password',
              duration: Duration(seconds: 3), error: true);
          setState(() {
            _disabled = false;
          });
          return;
        }

        // login success
        var dbResult = await db.open(dbName: account.nickname);
        if (dbResult == null) {
          showInSnackBar('Failure! Database connection error',
              duration: Duration(seconds: 3), error: true);
          return;
        }

        prefs.setBool('authorized', true);
        Navigator.pushNamedAndRemoveUntil(context, '/main', (route) => false);
        setState(() {
          _disabled = false;
        });
      });
    } catch (e) {
      print('LoginFormState.signin error: ${e.toString()}');
      showInSnackBar('Failure! Wrong login or password',
          duration: Duration(seconds: 3), error: true);
      setState(() {
        _disabled = false;
      });
    }
  }

  void onLogin() async {
    _formKey.currentState.save();
    if (_formKey.currentState.validate()) {
      const timeOut = const Duration(seconds: 1);
      setState(() {
        _disabled = true;
      });
      new Timer(timeOut, () {
        // print('login: $login, password: $password, createNewKey: $createNewKey');
        signin();
      });
    } else {
      setState(() {
        _autovalidate = true;
      });
      showInSnackBar('Login or password is empty');
    }
  }

  void onRegistration() {
    Navigator.pushNamed(context, '/register');
  }

  void onForgot() {}

  @override
  void initState() {
    super.initState();
    init();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      resizeToAvoidBottomPadding: true,
      body: Theme(
        data: Theme.of(context).copyWith(
            hintColor: Colors.white, unselectedWidgetColor: Colors.white),
        child: Form(
          key: _formKey,
          autovalidate: _autovalidate,
          child: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: new AssetImage('images/backgrounds/bg_login.png'),
                fit: BoxFit.cover,
              ),
            ),
            alignment: Alignment.topCenter,
            child: SingleChildScrollView(
              reverse: false,
              child: Column(
                children: <Widget>[
                  SizedBox(height: 60.0),
                  Image.asset('images/icons/logo.png'),
                  SizedBox(height: 20.0),
                  Text(
                    'Please enter your login and pass',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w500),
                  ),
                  SizedBox(height: 30.0),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 50.0),
                    child: Column(
                      children: <Widget>[
                        TextFormField(
                          key: Key('login'),
                          autocorrect: false,
                          decoration: InputDecoration(
                            hintText: 'Login',
                            hintStyle: TextStyle(color: Colors.white70),
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 10.0, horizontal: 20.0),
                            border: OutlineInputBorder(
                                borderRadius: const BorderRadius.all(
                                    const Radius.circular(30.0))),
                          ),
                          inputFormatters: <TextInputFormatter>[
                            SentenceCaseTextFormatter(),
                          ],
                          style: TextStyle(color: Colors.white),
                          validator: (value) {
                            if (value.isEmpty) {
                              return 'Please enter login';
                            }
                          },
                          onSaved: (text) {
                            login = text.toLowerCase();
                          },
                        ),
                        SizedBox(height: 15.0),
                        TextFormField(
                          key: Key('password'),
                          obscureText: true,
                          decoration: InputDecoration(
                            hintText: 'Password',
                            hintStyle: TextStyle(color: Colors.white70),
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 10.0, horizontal: 20.0),
                            border: OutlineInputBorder(
                                borderRadius: const BorderRadius.all(
                                    const Radius.circular(30.0))),
                          ),
                          style: TextStyle(color: Colors.white),
                          validator: (value) {
                            if (value.isEmpty) {
                              return 'Please enter password';
                            }
                          },
                          onSaved: (text) {
                            password = text;
                          },
                        ),
                        SizedBox(height: 15.0),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Text('For best security',
                                style: TextStyle(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13.0)),
                            Text('Create a new key',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13.0)),
                            Checkbox(
                              value: createNewKey,
                              activeColor: Colors.blue,
                              onChanged: (val) {
                                setState(() {
                                  createNewKey = !createNewKey;
                                });
                              },
                            ),
                          ],
                        ),
                        SizedBox(height: 20.0),
                        FlatButton(
                          color: Colors.transparent,
                          textColor: Colors.white,
                          shape: new RoundedRectangleBorder(
                              borderRadius: new BorderRadius.circular(30.0),
                              side: BorderSide(
                                  width: 2.0,
                                  color: !_disabled
                                      ? Colors.white
                                      : Colors.black26)),
                          padding: EdgeInsets.symmetric(
                              vertical: 10.0, horizontal: 70.0),
                          onPressed: !_disabled ? onLogin : null,
                          child: Text('Enter'),
                        ),
                        SizedBox(height: 5.0),
                        FlatButton(
                          color: Colors.transparent,
                          textColor: Colors.white,
                          onPressed: onForgot,
                          child: Text('Forgot password'),
                        ),
                        SizedBox(height: 15.0),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Text('First time in app?',
                                    style: TextStyle(color: Colors.grey)),
                                FlatButton(
                                  color: Colors.transparent,
                                  textColor: Colors.blue,
                                  onPressed: onRegistration,
                                  child: Text('Registration'),
                                ),
                              ],
                            ),
                            SizedBox(height: 5.0),
                            FlatButton(
                              color: Colors.grey[200],
                              textColor: Colors.grey,
                              shape: new RoundedRectangleBorder(
                                  borderRadius: new BorderRadius.circular(30.0),
                                  side: BorderSide(
                                      width: 2.0, color: Colors.grey[200])),
                              padding: EdgeInsets.symmetric(
                                  vertical: 10.0, horizontal: 30.0),
                              onPressed: null,
                              child: Text('Keys import'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
