import 'package:flutter/material.dart';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Startup Name Generator',
      theme: ThemeData(
        brightness: Brightness.light,
        fontFamily: 'Exo2',
        hintColor: Colors.white,
        unselectedWidgetColor: Colors.white,
      ),
      home: LoginForm(),
    );
  }
}

class LoginForm extends StatefulWidget {
  @override
  createState() => LoginFormState();
}

class LoginFormState extends State<LoginForm> {
  final _scaffoldKey = new GlobalKey<ScaffoldState>();
  final _formKey = new GlobalKey<FormState>();

  bool _autovalidate = false;

  String login = '';
  String password = '';
  bool createNewKey = false;

  void showInSnackBar(String value) {
    _scaffoldKey.currentState.showSnackBar(new SnackBar(
      content: new Text(value),
    ));
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold (
      key: _scaffoldKey,
      resizeToAvoidBottomPadding: true,
      body: Form(
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
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 30.0),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 50.0),
                  child: Column(
                    children: <Widget>[
                      TextFormField(
                        key: Key('login'),
                        decoration: InputDecoration(
                          hintText: 'Login',
                          hintStyle: TextStyle(color: Colors.white70),
                          contentPadding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
                          border: OutlineInputBorder(borderRadius: const BorderRadius.all(const Radius.circular(30.0))),
                          ),
                        style: TextStyle(color: Colors.white),
                        validator: (value) {
                          if (value.isEmpty) {
                            return 'Please enter login';
                          }
                        },
                        onSaved: (text) {
                          login = text;
                        },
                      ),
                      SizedBox(height: 15.0),
                      TextFormField(
                        key: Key('password'),
                        obscureText: true,
                        decoration: InputDecoration(
                          hintText: 'Password',
                          hintStyle: TextStyle(color: Colors.white70),
                          contentPadding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
                          border: OutlineInputBorder(borderRadius: const BorderRadius.all(const Radius.circular(30.0))),
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
                          Text('For best security', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w500, fontSize: 13.0)),
                          Text('Create a new key', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 13.0)),
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
                        shape: new RoundedRectangleBorder(borderRadius: new BorderRadius.circular(30.0), side: BorderSide(width: 2.0, color: Colors.white)),
                        padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 70.0),
                        onPressed: () {
                          if (_formKey.currentState.validate()) {
                            _formKey.currentState.save();
                            print('login: $login, password: $password, createNewKey: $createNewKey');
                            showInSnackBar('Logging in...');
                          } else {
                            setState(() {
                              _autovalidate = true;
                            });
                            showInSnackBar('Login or password is empty');
                          }
                        },
                        child: Text('Enter'),
                      ),
                      SizedBox(height: 5.0),
                      FlatButton(
                        color: Colors.transparent,
                        textColor: Colors.white,
                        onPressed: () {
                        },
                        child: Text('Forgot password'),
                      ),
                      SizedBox(height: 15.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text('First time in app?', style: TextStyle(color: Colors.grey)),
                          FlatButton(
                            color: Colors.transparent,
                            textColor: Colors.blue,
                            onPressed: () {
                            },
                            child: Text('Registration'),
                          ),
                        ],
                      ),
                      SizedBox(height: 5.0),
                      FlatButton(
                        color: Colors.grey[200],
                        textColor: Colors.grey,
                        shape: new RoundedRectangleBorder(borderRadius: new BorderRadius.circular(30.0), side: BorderSide(width: 2.0, color: Colors.grey[200])),
                        padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 30.0),
                        onPressed: () {
                        },
                        child: Text('Keys import'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
