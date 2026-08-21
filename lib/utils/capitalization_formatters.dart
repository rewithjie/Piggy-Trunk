import 'package:flutter/services.dart';

/// Formats text in real-time so that each word starts with a capital letter.
/// Works across Web, Desktop, and Mobile (hardware and software keyboards).
class CapitalizeWordsInputFormatter extends TextInputFormatter {
  const CapitalizeWordsInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    final text = newValue.text;
    final buffer = StringBuffer();
    bool capitalizeNext = true;

    for (int i = 0; i < text.length; i++) {
      final char = text[i];
      if (capitalizeNext && RegExp(r'[a-zA-Z]').hasMatch(char)) {
        buffer.write(char.toUpperCase());
        capitalizeNext = false;
      } else {
        buffer.write(char);
        if (char == ' ' || char == '-' || char == '_' || char == '/' || char == '(' || char == ',' || char == '.') {
          capitalizeNext = true;
        }
      }
    }

    return newValue.copyWith(
      text: buffer.toString(),
      selection: newValue.selection,
    );
  }
}

/// Formats text in real-time so that the first letter of each sentence is capitalized.
class CapitalizeSentencesInputFormatter extends TextInputFormatter {
  const CapitalizeSentencesInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    final text = newValue.text;
    final buffer = StringBuffer();
    bool capitalizeNext = true;

    for (int i = 0; i < text.length; i++) {
      final char = text[i];
      if (capitalizeNext && RegExp(r'[a-zA-Z]').hasMatch(char)) {
        buffer.write(char.toUpperCase());
        capitalizeNext = false;
      } else {
        buffer.write(char);
        if (char == '.' || char == '!' || char == '?' || char == '\n') {
          capitalizeNext = true;
        }
      }
    }

    return newValue.copyWith(
      text: buffer.toString(),
      selection: newValue.selection,
    );
  }
}
