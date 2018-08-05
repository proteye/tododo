import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tododo/src/models/account.model.dart';
import 'package:tododo/src/utils/db.util.dart';

Db db = new Db();

class AccountService {
  AccountModel account;

  static final AccountService _accountService = new AccountService._internal();

  factory AccountService() {
    return _accountService;
  }

  AccountService._internal();

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    var accountJson = json.decode(prefs.getString('account'));
    account = AccountModel.fromJson(accountJson);
  }
}
