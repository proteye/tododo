import 'dart:async';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';
import 'package:uuid/uuid.dart';

import 'package:tododo/src/utils/file.util.dart';
import 'package:tododo/src/config.dart';

class Db {
  DatabaseFactory dbFactory;
  Database db;

  static final Db _db = new Db._internal();

  factory Db() {
    return _db;
  }

  Db._internal();

  static String generateSalt() {
    var uuid = new Uuid();
    var id = uuid.v4();

    return id.replaceAll(new RegExp(r'-'), '');
  }

  static String generateId() {
    return generateSalt();
  }

  Future<dynamic> open({String dbName}) async {
    try {
      String _dbName = dbName ?? Config.DEFAULT_DBNAME;
      _dbName += '.db';
      String dbPath = await FileHelper.filePath(_dbName);

      dbFactory = databaseFactoryIo;
      db = await dbFactory.openDatabase(dbPath);
      print('Db opened: ${db.toString()}');

      return db;
    } catch (e) {
      print('DB opening error: ${e.toString()}');
      return null;
    }
  }

  Future<dynamic> getByKey(String key) {
    return db.get(key);
  }

  Future<dynamic> setByKey(String key, dynamic value) {
    return db.put(value, key);
  }

  Future<dynamic> delete(String key) {
    return db.delete(key);
  }

  Future<dynamic> close() {
    return db.close();
  }
}
