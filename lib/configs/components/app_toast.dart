import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class AppToast {
  static void show({
    required String message,
    Color backgroundColor = Colors.black,
    Color textColor = Colors.white,
    ToastGravity gravity = ToastGravity.BOTTOM,
    Toast length = Toast.LENGTH_SHORT,
  }) {
    Fluttertoast.cancel(); // Optional: cancels previous toast

    Fluttertoast.showToast(
      msg: message,
      toastLength: length,
      gravity: gravity,
      backgroundColor: backgroundColor,
      textColor: textColor,
      fontSize: 16.0,
      timeInSecForIosWeb: 3,
    );
  }

  /// Predefined Error Toast
  static void error(String message) {
    show(
      message: message,
      backgroundColor: Colors.red,
    );
  }

  /// Predefined Success Toast
  static void success(String message) {
    show(
      message: message,
      backgroundColor: Colors.green,
    );
  }

  /// Predefined Info Toast
  static void info(String message) {
    show(
      message: message,
      backgroundColor: Colors.blue,
    );
  }
}
