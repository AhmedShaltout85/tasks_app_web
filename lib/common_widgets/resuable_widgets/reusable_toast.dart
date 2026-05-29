import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ReusableToast {
  static Future<bool?> showToast({
    required String message,
    required Color bgColor,
    required Color textColor,
    required double fontSize,
  }) {
    return Fluttertoast.showToast(
      msg: message,
      webPosition: 'center',
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: bgColor,
      textColor: Colors.white,
      fontSize: fontSize,
    );
  }
}
