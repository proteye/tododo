import 'dart:async';
import 'dart:convert';

import 'package:tododo/src/models/hashKey.model.dart';
import 'package:tododo/src/utils/enum.util.dart';
import 'package:tododo/src/utils/hash.util.dart';
import 'package:tododo/src/utils/db.util.dart';

Db db = new Db();

class HashKeyService {
  List<HashKeyModel> hashKeys = [];
  HashKeyModel currentHashKey;

  static final HashKeyService _hashKeyService = new HashKeyService._internal();

  factory HashKeyService() {
    return _hashKeyService;
  }

  HashKeyService._internal();

  Future<void> init() async {
    var jsonHashKeys = await db.getByKey(Enum.DB['hashKeys']) ?? '[]';
    jsonHashKeys = json.decode(jsonHashKeys);

    for (var jsonHashKey in jsonHashKeys) {
      HashKeyModel hashKey = HashKeyModel.fromJson(jsonHashKey);
      hashKeys.add(hashKey);
    }
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
      hashKeys.clear(); // TODO: remove after tests
      hashKeys.add(hashKey);
      var jsonHashKeys = json.encode(hashKeys);
      await db.setByKey(Enum.DB['hashKeys'], jsonHashKeys);
      // var test = await db.getByKey(Enum.DB['hashKeys']) ?? '[]';
      // print('hashKey added: ${json.decode(test).length}');
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
