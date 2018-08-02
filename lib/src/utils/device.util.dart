import 'dart:async';
import 'package:flutter/material.dart';
import 'package:device_info/device_info.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeviceHelper {
  static String getPlatform(context) {
    if (Theme.of(context).platform == TargetPlatform.iOS) {
      return 'ios';
    } else if (Theme.of(context).platform == TargetPlatform.android) {
      return 'android';
    } else if (Theme.of(context).platform == TargetPlatform.fuchsia) {
      return 'fuchsia';
    } else {
      return 'not recognised';
    }
  }

  static Future<Map<String, String>> getDeviceDetails(platform) async {
    final prefs = await SharedPreferences.getInstance();

    String deviceId = 'unknown';
    String deviceName = 'unknown';
    String deviceVersion = 'unknown';

    final DeviceInfoPlugin deviceInfoPlugin = new DeviceInfoPlugin();

    if (platform == 'android') {
      var build = await deviceInfoPlugin.androidInfo;
      deviceId = prefs.getString('deviceId') ?? '';
      if (deviceId == '') {
        var uuid = new Uuid();
        deviceId = uuid.v4();
        prefs.setString('deviceId', deviceId);
      }
      deviceName = build.model;
      deviceVersion = build.device;
    } else if (platform == 'ios') {
      var data = await deviceInfoPlugin.iosInfo;
      deviceId = data.identifierForVendor;
      deviceName = data.name;
      deviceVersion = data.systemVersion;
    }

    return {
      'deviceId': deviceId,
      'deviceName': deviceName,
      'deviceVersion': deviceVersion
    };
  }
}
