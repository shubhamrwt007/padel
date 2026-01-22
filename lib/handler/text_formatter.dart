import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class EmojiFilteringTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final emojiRegex = RegExp(
      r'[\u{1F600}-\u{1F64F}' // Emoticons
      r'\u{1F300}-\u{1F5FF}' // Misc Symbols and Pictographs
      r'\u{1F680}-\u{1F6FF}' // Transport and Map
      r'\u{1F700}-\u{1F77F}' // Alchemical Symbols
      r'\u{1F780}-\u{1F7FF}' // Geometric Shapes Extended
      r'\u{1F800}-\u{1F8FF}' // Supplemental Arrows-C
      r'\u{1F900}-\u{1F9FF}' // Supplemental Symbols and Pictographs
      r'\u{1FA00}-\u{1FA6F}' // Chess Symbols
      r'\u{1FA70}-\u{1FAFF}' // Symbols and Pictographs Extended-A
      r'\u{2600}-\u{26FF}' // Misc symbols
      r'\u{2700}-\u{27BF}]', // Dingbats
      unicode: true,
    );

    // Remove any emoji characters from the new input value
    String newText = newValue.text.replaceAll(emojiRegex, '');

    return TextEditingValue(text: newText, selection: newValue.selection);
  }
}

extension StringExtension on String {
  String capitalizeFirstChar() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  //Check if the string is a valid email address
  bool get isValidEmail {
    final emailRegex = RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$");
    return emailRegex.hasMatch(this);
  }

  /// Checks if the string is a valid password
  bool get isValidPassword {
    final passwordRegex = RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[\W_]).{6,}$',
    );
    return passwordRegex.hasMatch(this);
  }
}
  String formatTimeSlot(String raw) {
    try {
      // Normalize input (e.g., remove extra spaces, lowercase)
      final normalized = raw.trim().toLowerCase();

      // Handle formats like "10:00 pm" or "10 pm"
      final parts = normalized.split(" ");
      if (parts.isEmpty) return raw;
      
      final timePart = parts[0];
      final periodPart = normalized.contains("pm") ? "PM" : "AM";

      // Extract hour from time part (handle both "10" and "10:00" formats)
      int hour;
      if (timePart.contains(":")) {
        hour = int.tryParse(timePart.split(":")[0]) ?? 0;
      } else {
        hour = int.tryParse(timePart) ?? 0;
      }

      if (hour == 0) return raw; // Invalid hour

      // Return formatted time with :00
      return "$hour:00 $periodPart";
    } catch (_) {
      return raw; // fallback if parsing fails
    }
  }

  ///Capitalize name first character---------------------------
   String capitalizeBothFIrstLastWords(String name) {
    if (name.trim().isEmpty) return "";

    return name
        .split(" ")
        .map((word) =>
    word.isEmpty ? "" : "${word[0].toUpperCase()}${word.substring(1).toLowerCase()}")
        .join(" ");
  }

  ///Get First Initials--------------------------------------------------
   String getNameInitials(String firstName, String lastName) {
  if (firstName.trim().isEmpty && lastName.trim().isEmpty) return "?";

  // If lastName is empty but firstName contains space, split firstName
  if (lastName.trim().isEmpty && firstName.trim().contains(' ')) {
    final nameParts = firstName.trim().split(' ');
    String f = nameParts[0].isNotEmpty ? nameParts[0][0].toUpperCase() : "";
    String l = nameParts.length > 1 && nameParts[1].isNotEmpty ? nameParts[1][0].toUpperCase() : "";
    return "$f$l";
  }

  String f = firstName.trim().isNotEmpty ? firstName.trim()[0].toUpperCase() : "";
  String l = lastName.trim().isNotEmpty ? lastName.trim()[0].toUpperCase() : "";

  return "$f$l";
  }

  ///Price Format--------------------------------------------------------
String formatAmount(dynamic amount, {String? currency}) {
  final raw = (amount ?? '').toString();
  final cleaned = raw.replaceAll(RegExp(r'[^\d\.-]'), '');
  final value = num.tryParse(cleaned);
  if (value == null) return raw;

  String formatted;
  if (value >= 100000) {
    // Compact (e.g. 100K, 1M)
    formatted = NumberFormat.compact(locale: 'en_IN').format(value);
  } else {
    // Normal with commas
    formatted = NumberFormat('#,##0', 'en_IN').format(value);
  }

  return currency != null ? '$currency $formatted' : formatted;
}

///Wallet Balance Format---------------------------------------------------------
String formatWalletAmount(dynamic amount, {String? currency}) {
  final raw = (amount ?? '').toString();
  final cleaned = raw.replaceAll(RegExp(r'[^\d\.-]'), '');
  final value = num.tryParse(cleaned);
  if (value == null) return raw;

  String formatted;
  if (value >= 100000) {
    // Compact (e.g. 100K, 1M) - preserves up to 1 decimal
    formatted = NumberFormat.compact(locale: 'en_IN').format(value);
  } else {
    // Normal with commas and up to 2 decimal places
    formatted = NumberFormat('#,##0.##', 'en_IN').format(value);
  }

  return currency != null ? '$currency $formatted' : formatted;
}