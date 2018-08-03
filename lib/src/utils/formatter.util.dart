import 'package:flutter/services.dart';

class SentenceCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (oldValue.text.length >= newValue.text.length) {
      return newValue;
    }

    return new TextEditingValue(
        text: newValue.text.toLowerCase(), selection: newValue.selection);
  }
}
