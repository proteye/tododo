import 'dart:async';
import 'dart:convert';

import 'package:tododo/src/models/contact.model.dart';
import 'package:tododo/src/utils/rsa.util.dart';
import 'package:tododo/src/utils/websocket.util.dart';
import 'package:tododo/src/utils/db.util.dart';
import 'package:tododo/src/config.dart';

const TABLE_NAME = 'Contact';
const COLUMN_ID = 'username';

final Db db = new Db();
final Websocket websocket = new Websocket();
final Map<String, String> meta = Config.MESSAGE_META;

class ContactService {
  List<ContactModel> contacts = [];
  ContactModel currentContact;

  static final ContactService _contactService = new ContactService._internal();

  factory ContactService() {
    return _contactService;
  }

  ContactService._internal();

  Future<List<ContactModel>> loadAll({bool force = false}) async {
    if (force != true && contacts.length > 0) {
      return contacts;
    }

    contacts = [];
    var jsonContacts = await db.getByQuery(TABLE_NAME, '');
    // print('contacts loaded: $jsonContacts');

    for (var jsonContact in jsonContacts) {
      ContactModel contact = ContactModel.fromSqlite(jsonContact);
      contacts.add(contact);
    }

    return contacts;
  }

  Future<ContactModel> loadByUsername(String username) async {
    try {
      var jsonContact = await db.getById(TABLE_NAME, COLUMN_ID, username);
      if (jsonContact == null) {
        throw new ArgumentError('contact not found');
      }
      currentContact = ContactModel.fromSqlite(jsonContact);
    } catch (e) {
      print('ContactService.loadByUsername error: ${e.toString()}');
      return null;
    }

    return currentContact;
  }

  Future<ContactModel> create(ContactModel contact) async {
    try {
      contacts.add(contact);
      var _contact = await loadByUsername(contact.username);
      if (_contact != null) {
        return null;
      }
      var result = await db.insert(TABLE_NAME, contact.toSqlite());
      print('contact created: $result');
    } catch (e) {
      print('ContactService.create error: ${e.toString()}');
      return null;
    }

    return contact;
  }

  Future<ContactModel> update(String username, ContactModel contact) async {
    try {
      int index = contacts.indexWhere((item) => item.username == username);
      if (index >= 0) {
        contacts[index] = contact;
      }
      int result =
          await db.updateById(TABLE_NAME, COLUMN_ID, contact.toSqlite());
      print('contact updated: $result');
    } catch (e) {
      print('ContactService.update error: ${e.toString()}');
      return null;
    }

    return contact;
  }

  Future<ContactModel> updatePublicKey(
      String username, String publicKey) async {
    ContactModel contact;

    try {
      int index = contacts.indexWhere((item) => item.username == username);
      if (index >= 0) {
        contacts[index].publicKey = publicKey;
        contact = contacts[index];
      }

      if (contact != null) {
        int result =
            await db.updateById(TABLE_NAME, COLUMN_ID, contact.toSqlite());
        print('contact.publicKey updated: $result');
        return contact;
      }

      contact = await loadByUsername(username);
      contact.publicKey = publicKey;
      int result =
          await db.updateById(TABLE_NAME, COLUMN_ID, contact.toSqlite());
      print('contact.publicKey updated: $result');
    } catch (e) {
      print('ContactService.updatePublicKey error: ${e.toString()}');
      return null;
    }

    return contact;
  }

  Future<bool> deleteByUsername(String username) async {
    try {
      int index = contacts.indexWhere((item) => item.username == username);
      if (index >= 0) {
        contacts.removeAt(index);
      }
      int result = await db.deleteById(TABLE_NAME, COLUMN_ID, username);
      print('contact deleted: $result');
    } catch (e) {
      print('ContactService.deleteByUsername error: ${e.toString()}');
      return null;
    }

    return true;
  }

  Future<bool> deleteAll() async {
    try {
      contacts = [];
      int result = await db.deleteAll(TABLE_NAME);
      print('all contacts deleted: $result');
    } catch (e) {
      print('ChatService.deleteAll error: ${e.toString()}');
      return null;
    }

    return true;
  }

  List<ContactModel> find(String text) {
    return contacts
        .where((item) =>
            item.username.indexOf(text) >= 0 ||
            item.firstName.indexOf(text) >= 0 ||
            item.secondName.indexOf(text) >= 0)
        .toList();
  }

  // search on the server
  void search(String query, {DateTime encryptTime}) {
    var _encryptTime = encryptTime != null
        ? encryptTime.toUtc().toIso8601String()
        : DateTime.now().toUtc().toIso8601String();
    var data = json.encode({
      'type': 'server_message',
      'action': 'search',
      'data': query.toLowerCase(),
      'to': null,
      'encrypt_time': _encryptTime,
    });

    websocket.send(data);
  }

  void getOpenKey(List<String> usernames, {DateTime encryptTime}) {
    var _encryptTime = encryptTime != null
        ? encryptTime.toUtc().toIso8601String()
        : DateTime.now().toUtc().toIso8601String();
    var data = json.encode({
      'type': 'server_message',
      'action': 'get_open_key',
      'data': usernames,
      'to': null,
      'encrypt_time': _encryptTime,
    });

    websocket.send(data);
  }

  void requestProfile(List<String> usernames, {DateTime encryptTime}) {
    var _encryptTime = encryptTime != null
        ? encryptTime.toUtc().toIso8601String()
        : DateTime.now().toUtc().toIso8601String();
    var data = json.encode({
      'type': 'client_message',
      'action': 'request_profile',
      'data': {'meta': meta, 'payload': null},
      'to': usernames,
      'encrypt_time': _encryptTime,
    });

    websocket.send(data);
  }

  void sendProfile(
      String username, String publicKey, Map<String, String> profile,
      {DateTime encryptTime}) {
    var _encryptTime = encryptTime != null
        ? encryptTime.toUtc().toIso8601String()
        : DateTime.now().toUtc().toIso8601String();
    String encrypted = '';

    try {
      var _publicKey = RsaHelper.parsePublicKeyFromPem(publicKey);
      var _profile = json.encode(profile);
      encrypted = RsaHelper.encrypt(_profile, _publicKey);
      var data = json.encode({
        'type': 'client_message',
        'action': 'send_profile',
        'data': {'meta': meta, 'files': {}, 'payload': encrypted},
        'to': [username],
        'encrypt_time': _encryptTime,
      });

      websocket.send(data);
    } catch (e) {
      print('ContactService.sendProfile error: ${e.toString()}');
    }
  }

  void getOnlineUsers(List<String> usernames, {DateTime encryptTime}) {
    var _encryptTime = encryptTime != null
        ? encryptTime.toUtc().toIso8601String()
        : DateTime.now().toUtc().toIso8601String();
    var data = json.encode({
      'type': 'server_message',
      'action': 'get_online_users',
      'data': usernames,
      'to': null,
      'encrypt_time': _encryptTime,
    });

    websocket.send(data);
  }
}
