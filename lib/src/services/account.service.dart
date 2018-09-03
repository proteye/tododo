import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tododo/src/models/account.model.dart';
import 'package:tododo/src/utils/db.util.dart';

const TABLE_NAME = 'Account';
const COLUMN_ID = 'username';

Db db = new Db();

class AccountService {
  AccountModel account;

  static final AccountService _accountService = new AccountService._internal();

  factory AccountService() {
    return _accountService;
  }

  AccountService._internal();

  Future<AccountModel> init() async {
    final prefs = await SharedPreferences.getInstance();
    var prefsAccountJson = json.decode(prefs.getString('account'));
    account = await getByUsername(prefsAccountJson['username']);

    return account;
  }

  Future<AccountModel> getByUsername(String username) async {
    if (username == null || username.isEmpty) {
      return null;
    }

    var accountJson = await db.getById(TABLE_NAME, 'username', username);

    if (accountJson == null) {
      return null;
    }

    return AccountModel.fromJson(accountJson);
  }

  Future<dynamic> insert(AccountModel account) {
    return db.insert(TABLE_NAME, account.toJson());
  }

  Future<int> update(AccountModel account) {
    return db.updateById(TABLE_NAME, 'username', account.toJson());
  }

  Future<dynamic> deleteByUsername(String username) {
    return db.deleteById(TABLE_NAME, 'username', username);
  }
}
