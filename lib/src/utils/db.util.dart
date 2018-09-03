import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import "package:path/path.dart" show join;

import 'package:tododo/src/config.dart';

const TABLES_CREATE_QUERIES = [
  'CREATE TABLE Account (username TEXT PRIMARY KEY, nickname TEXT, password TEXT, email TEXT, phone TEXT, publicKey TEXT, privateKey TEXT, hashKey TEXT, deviceId TEXT, deviceName TEXT, platform TEXT, settings TEXT, hostname TEXT);',
  'CREATE TABLE Chat (id TEXT PRIMARY KEY, name TEXT, owner TEXT, members TEXT, membersHash TEXT, type TEXT, avatar TEXT, lastMessage TEXT, contacts TEXT, unreadCount INTEGER, sort INTEGER, pin INTEGER, isMuted INTEGER, isDeleted INTEGER, salt TEXT, dateSend TEXT, dateCreate TEXT, dateUpdate TEXT);',
  'CREATE TABLE ChatMessage (id TEXT PRIMARY KEY, chatId TEXT, type TEXT, username TEXT, deviceId TEXT, text TEXT, filename TEXT, fileUrl TEXT, contact TEXT, quote TEXT, status TEXT, isOwn INTEGER, isFavorite INTEGER, salt TEXT, dateSend TEXT, dateCreate TEXT, dateUpdate TEXT);',
  'CREATE TABLE Contact (username TEXT PRIMARY KEY, nickname TEXT, deviceId TEXT, groups TEXT, phones TEXT, firstName TEXT, secondName TEXT, bio TEXT, avatar TEXT, sound TEXT, isNotify INTEGER, isBlocked INTEGER, settings TEXT, publicKey TEXT, dateCreate TEXT, dateUpdate TEXT);',
  'CREATE TABLE HashKey (id INTEGER PRIMARY KEY AUTOINCREMENT, chatId TEXT, messageId TEXT, hashKey TEXT, dateSend TEXT);',
];

const DEFAULT_LIMIT = 1000;
const DEFAULT_OFFSET = 0;

class Db {
  Database database;
  String dbPath;

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
      String dirPath = await getDatabasesPath();
      dbPath = join(dirPath, _dbName);

      database = await openDatabase(dbPath, version: 1,
          onCreate: (Database db, int version) async {
        for (var query in TABLES_CREATE_QUERIES) {
          await db.execute(query);
        }
      });
      print('Db opened: ${database.toString()}');

      return database;
    } catch (e) {
      print('DB opening error: ${e.toString()}');
      return null;
    }
  }

  Future<dynamic> insert(String tableName, Map<String, dynamic> object) {
    return database.insert(tableName, object);
  }

  Future<int> updateById(
      String tableName, String columnId, Map<String, dynamic> object) {
    return database.update(tableName, object,
        where: "$columnId = ?", whereArgs: [object[columnId]]);
  }

  Future<Map<String, dynamic>> getById(
      String tableName, String columnId, dynamic id,
      {List<String> columns}) async {
    List<Map> maps = await database.query(tableName,
        columns: columns ?? null, where: "$columnId = ?", whereArgs: [id]);

    if (maps.length > 0) {
      return maps.first;
    }

    return null;
  }

  Future<List<Map<String, dynamic>>> getByParams(
    String tableName, {
    List<String> columns,
    String where,
    List whereArgs,
    String groupBy,
    String having,
    String orderBy,
    int limit,
    int offset,
  }) {
    limit = limit ?? DEFAULT_LIMIT;
    offset = offset ?? DEFAULT_OFFSET;

    return database.query(
      tableName,
      columns: columns,
      where: where,
      whereArgs: whereArgs,
      groupBy: groupBy,
      having: having,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
  }

  Future<List<Map<String, dynamic>>> getByQuery(String tableName, String query,
      {List<String> columns}) {
    String _query = query != null && query.isNotEmpty ? query : '';
    String _columns =
        columns != null && columns.isNotEmpty ? columns.join(', ') : '*';

    return database.rawQuery('SELECT $_columns FROM "$tableName" $_query');
  }

  Future<int> deleteAll(String tableName) {
    return database.delete(tableName);
  }

  Future<int> deleteById(String tableName, String columnId, dynamic id) {
    return database.delete(tableName, where: "$columnId = ?", whereArgs: [id]);
  }

  Future<dynamic> close() {
    return database.close();
  }

  Future<bool> deleteDb() async {
    try {
      await database.close();
      await deleteDatabase(dbPath);
    } catch (e) {
      print('Db.dbDelete error: $e');
      return false;
    }

    return true;
  }
}
