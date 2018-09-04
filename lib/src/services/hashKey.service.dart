import 'dart:async';

import 'package:tododo/src/models/hashKey.model.dart';
import 'package:tododo/src/utils/hash.util.dart';
import 'package:tododo/src/utils/db.util.dart';

const TABLE_NAME = 'HashKey';
const COLUMN_ID = 'id';

final Db db = new Db();

class HashKeyService {
  List<HashKeyModel> hashKeys = [];
  HashKeyModel currentHashKey;

  static final HashKeyService _hashKeyService = new HashKeyService._internal();

  factory HashKeyService() {
    return _hashKeyService;
  }

  HashKeyService._internal();

  Future<List<HashKeyModel>> loadAll({bool force = false}) async {
    if (force != true && hashKeys.length > 0) {
      return hashKeys;
    }

    hashKeys = [];
    var jsonHashKeys = await db.getByQuery(TABLE_NAME, '');

    for (var jsonHashKey in jsonHashKeys) {
      HashKeyModel hashKey = HashKeyModel.fromJson(jsonHashKey);
      hashKeys.add(hashKey);
    }

    return hashKeys;
  }

  static String generateHash(DateTime encryptTime, String data, String salt) {
    String hash;

    try {
      String hashData =
          encryptTime.millisecondsSinceEpoch.toString() + data + salt;
      hash = HashHelper.hexSha256(hashData);
    } catch (e) {
      print('HashKeysService.generateHash error: ${e.toString()}');
      return null;
    }

    return hash;
  }

  Future<HashKeyModel> add(HashKeyModel hashKey) async {
    try {
      hashKeys.add(hashKey);
      var result = await db.insert(TABLE_NAME, hashKey.toJson());
      print('hashKey created: $result');
    } catch (e) {
      print('HashKeysService.add error: ${e.toString()}');
      return null;
    }

    return hashKey;
  }

  Future<HashKeyModel> getByDate(String dateSend) async {
    HashKeyModel hashKey;

    try {
      if (dateSend == null || dateSend.isEmpty) {
        return null;
      }
      DateTime _dateSend = DateTime.parse(dateSend);
      hashKey = hashKeys.singleWhere((item) =>
          item.dateSend.millisecondsSinceEpoch ==
          _dateSend.millisecondsSinceEpoch);
    } catch (e) {
      print('HashKeysService.getByDate error: ${e.toString()}');
      return null;
    }

    return hashKey;
  }
}