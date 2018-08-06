import "dart:typed_data";
import "package:pointycastle/export.dart";

import 'package:tododo/src/utils/convert.util.dart';

class HashHelper {
  static Uint8List sha256(String plaintext) {
    Digest sha256 = new SHA256Digest();
    var hash = sha256.process(createUint8ListFromString(plaintext));

    return hash;
  }

  static String hexSha256(String plaintext) {
    var hash = sha256(plaintext);

    return formatBytesAsHexString(hash);
  }
}
