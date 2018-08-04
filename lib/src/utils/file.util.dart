import 'dart:async';
import "package:path/path.dart" show dirname, join;
import 'package:path_provider/path_provider.dart';

class FileHelper {
  static Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  static Future<String> filePath(path) async {
    final directory = await _localPath;
    return join(dirname(directory), path);
  }
}
