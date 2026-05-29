import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';

class ReusableDialog {
  static AwesomeDialog showAwesomeDialog(
    BuildContext context, {
    required String title,
    required String description,
    required DialogType dialogType,
    void Function()? onCancel,
    void Function()? onConfirm,
  }) {
    return AwesomeDialog(
      context: context,
      dialogType: dialogType,
      animType: AnimType.rightSlide,
      title: title,
      desc: description,
      btnCancelOnPress: onCancel,
      btnOkOnPress: onConfirm,
    )..show();
  }
}
