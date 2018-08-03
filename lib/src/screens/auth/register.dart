import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import "package:pointycastle/export.dart";
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tododo/src/models/account.model.dart';
import 'package:tododo/src/models/registerForm.model.dart';
import 'package:tododo/src/services/auth.service.dart';
import 'package:tododo/src/utils/rsa.util.dart';
import 'package:tododo/src/utils/convert.util.dart';
import 'package:tododo/src/utils/formatter.util.dart';
import 'package:tododo/src/utils/device.util.dart';
import 'package:tododo/src/config.dart';

// First step
class RegisterScreen extends StatefulWidget {
  @override
  createState() => RegisterFormState();
}

class RegisterFormState extends State<RegisterScreen> {
  final _scaffoldKey = new GlobalKey<ScaffoldState>();
  final _formKey = new GlobalKey<FormState>();

  bool _autovalidate = false;

  RegisterFormModel form = new RegisterFormModel();

  void showInSnackBar(String value) {
    _scaffoldKey.currentState.showSnackBar(new SnackBar(
      content: new Text(value),
    ));
  }

  void onContinue() {
    if (_formKey.currentState.validate()) {
      // print('login: ${form.login}, password: ${form.password}');
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => RegisterEmailScreen(form: form)));
    } else {
      showInSnackBar('Please enter the correct values');
      setState(() {
        _autovalidate = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      resizeToAvoidBottomPadding: true,
      body: Form(
        key: _formKey,
        autovalidate: _autovalidate,
        onChanged: () {
          _formKey.currentState.save();
        },
        child: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: new AssetImage('images/backgrounds/bg_register.png'),
              fit: BoxFit.fitWidth,
              alignment: Alignment.topCenter,
            ),
          ),
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            reverse: false,
            padding: EdgeInsets.symmetric(horizontal: 40.0),
            child: Column(
              children: <Widget>[
                SizedBox(height: 100.0),
                Text(
                  'Registration',
                  style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 15.0),
                Text(
                  'During registration, the application will create security key for recovery',
                  style: TextStyle(fontSize: 15.0, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 30.0),
                TextFormField(
                  key: Key('login'),
                  autocorrect: false,
                  decoration: InputDecoration(
                    hintText: 'Create login',
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 10.0, horizontal: 20.0),
                    border: OutlineInputBorder(
                        borderRadius: const BorderRadius.all(
                            const Radius.circular(30.0))),
                  ),
                  inputFormatters: <TextInputFormatter>[
                    SentenceCaseTextFormatter(),
                  ],
                  validator: (value) {
                    if (value.isEmpty) {
                      return 'Please enter login';
                    }
                  },
                  onSaved: (text) {
                    form.login = text.toLowerCase();
                  },
                ),
                SizedBox(height: 15.0),
                TextFormField(
                  key: Key('password'),
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'Password',
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 10.0, horizontal: 20.0),
                    border: OutlineInputBorder(
                        borderRadius: const BorderRadius.all(
                            const Radius.circular(30.0))),
                  ),
                  validator: (value) {
                    if (value.isEmpty) {
                      return 'Please enter password';
                    }
                  },
                  onSaved: (text) {
                    form.password = text;
                  },
                ),
                SizedBox(height: 15.0),
                TextFormField(
                  key: Key('repeatPassword'),
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'Repeat password',
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 10.0, horizontal: 20.0),
                    border: OutlineInputBorder(
                        borderRadius: const BorderRadius.all(
                            const Radius.circular(30.0))),
                  ),
                  validator: (value) {
                    if (value.isEmpty) {
                      return 'Please repeat password';
                    }
                    if (value != form.password) {
                      return 'Passwords do not match';
                    }
                  },
                ),
                SizedBox(height: 45.0),
                FlatButton(
                  color: Colors.transparent,
                  textColor: Colors.black,
                  shape: new RoundedRectangleBorder(
                      borderRadius: new BorderRadius.circular(30.0),
                      side: BorderSide(width: 3.0, color: Colors.black)),
                  padding:
                      EdgeInsets.symmetric(vertical: 10.0, horizontal: 70.0),
                  onPressed: onContinue,
                  child: Text('Continue', style: TextStyle(fontSize: 16.0)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Second step
class RegisterEmailScreen extends StatefulWidget {
  final RegisterFormModel form;

  RegisterEmailScreen({Key key, @required this.form}) : super(key: key);

  @override
  createState() => RegisterEmailFormState();
}

class RegisterEmailFormState extends State<RegisterEmailScreen> {
  final _scaffoldKey = new GlobalKey<ScaffoldState>();
  final _formKey = new GlobalKey<FormState>();

  bool _autovalidate = false;
  bool _disabled = false;

  RegExp phoneExp = new RegExp(r'^[0-9]{10}$');
  RegExp emailExp = new RegExp(r'^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}$',
      caseSensitive: false);

  void showInSnackBar(String value, {Duration duration, bool error: false}) {
    var _duration = duration != null ? duration : Duration(milliseconds: 1500);
    _scaffoldKey.currentState.showSnackBar(new SnackBar(
      content: new Text(value),
      duration: _duration,
      backgroundColor: error ? Colors.red : null,
    ));
  }

  void register() async {
    var keyPair = RsaHelper.generateKeyPair();

    widget.form.privateKey =
        RsaHelper.encodePrivateKeyToPem(keyPair.privateKey);
    // print(widget.form.privateKey);

    widget.form.publicKey = RsaHelper.encodePublicKeyToPem(keyPair.publicKey);
    // print(widget.form.publicKey);

    Digest sha256 = new SHA256Digest();
    var hashPrivateKey =
        sha256.process(createUint8ListFromString(widget.form.privateKey));
    widget.form.hashKey = formatBytesAsHexString(hashPrivateKey);
    // print(widget.form.hashKey);

    widget.form.platform = DeviceHelper.getPlatform(context);
    // print(widget.form.platform);

    var device = await DeviceHelper.getDeviceDetails(widget.form.platform);
    widget.form.deviceId = device['deviceId'];
    widget.form.deviceName = device['deviceName'];
    print(device);

    var registerParams = widget.form.toMap();
    var result = await AuthService.register(null, params: registerParams);

    if (!result['success']) {
      showInSnackBar("Server error: ${result['errorMessage']}",
          duration: Duration(seconds: 5), error: true);
      setState(() {
        _disabled = false;
      });

      return;
    }

    final prefs = await SharedPreferences.getInstance();
    var hostname = Config.HOSTNAME;
    var account = new AccountModel(
        username: "${registerParams['login']}@$hostname",
        nickname: registerParams['login'],
        password: registerParams['password'],
        email: registerParams['email'],
        phone: registerParams['phone'],
        publicKey: registerParams['publicKey'],
        privateKey: registerParams['privateKey'],
        hashKey: registerParams['hashKey'],
        deviceId: registerParams['deviceId'],
        deviceName: registerParams['deviceName'],
        platform: registerParams['platform'],
        settings: registerParams['settings'],
        hostname: hostname);
    prefs.setString('account', account.toString());

    showInSnackBar('Congratulations! Registration successful',
        duration: Duration(seconds: 3));

    const timeOut = const Duration(seconds: 3);
    new Timer(timeOut, () {
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      setState(() {
        _disabled = false;
      });
    });
  }

  void onDone() {
    if (_formKey.currentState.validate()) {
      const timeOut = const Duration(seconds: 1);
      setState(() {
        _disabled = true;
      });
      showInSnackBar('Signing up...');
      new Timer(timeOut, () {
        // print('email: ${widget.form.email}, phone: ${widget.form.phone}');
        register();
      });
    } else {
      showInSnackBar('Please enter the correct values');
      setState(() {
        _autovalidate = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      resizeToAvoidBottomPadding: true,
      body: Form(
        key: _formKey,
        autovalidate: _autovalidate,
        onChanged: () {
          _formKey.currentState.save();
        },
        child: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: new AssetImage('images/backgrounds/bg_register.png'),
              fit: BoxFit.fitWidth,
              alignment: Alignment.topCenter,
            ),
          ),
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            reverse: false,
            padding: EdgeInsets.symmetric(horizontal: 40.0),
            child: Column(
              children: <Widget>[
                SizedBox(height: 100.0),
                Text(
                  'Registration',
                  style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 15.0),
                Text(
                  'Email is required to restore access to your account',
                  style: TextStyle(fontSize: 15.0, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 30.0),
                TextFormField(
                  key: Key('email'),
                  autocorrect: false,
                  decoration: InputDecoration(
                    hintText: 'Email',
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 10.0, horizontal: 20.0),
                    border: OutlineInputBorder(
                        borderRadius: const BorderRadius.all(
                            const Radius.circular(30.0))),
                  ),
                  inputFormatters: <TextInputFormatter>[
                    SentenceCaseTextFormatter(),
                  ],
                  validator: (value) {
                    if (value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (value.isNotEmpty && !emailExp.hasMatch(value)) {
                      return 'Please enter the correct email';
                    }
                  },
                  onSaved: (text) {
                    widget.form.email = text.toLowerCase();
                  },
                ),
                SizedBox(height: 15.0),
                TextFormField(
                  key: Key('phone'),
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    hintText: 'Phone',
                    prefixText: 'RUS +7',
                    prefixStyle: TextStyle(
                        color: Colors.black,
                        fontSize: 16.0,
                        fontWeight: FontWeight.w600),
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 10.0, horizontal: 20.0),
                    border: OutlineInputBorder(
                        borderRadius: const BorderRadius.all(
                            const Radius.circular(30.0))),
                  ),
                  validator: (value) {
                    if (value.isNotEmpty && !phoneExp.hasMatch(value)) {
                      return 'Please enter the correct phone';
                    }
                  },
                  onSaved: (text) {
                    widget.form.phone = text;
                  },
                ),
                SizedBox(height: 45.0),
                FlatButton(
                  color: Colors.transparent,
                  textColor: Colors.black,
                  shape: new RoundedRectangleBorder(
                      borderRadius: new BorderRadius.circular(30.0),
                      side: BorderSide(
                          width: 3.0,
                          color: !_disabled ? Colors.black : Colors.grey)),
                  padding:
                      EdgeInsets.symmetric(vertical: 10.0, horizontal: 70.0),
                  onPressed: !_disabled ? onDone : null,
                  child: Text('Done', style: TextStyle(fontSize: 16.0)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
