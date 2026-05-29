import 'package:flutter/material.dart';
import 'package:tasks_app/utils/app_colors.dart';

Widget buildInputField({
  required TextEditingController controller,
  required String hintText,
  required Image icon,
  bool obscureText = false,
}) {
  return Container(
    decoration: BoxDecoration(
      color: AppColors.lightGrayColor,
      borderRadius: BorderRadius.circular(10),
    ),
    child: TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(fontFamily: 'Cairo', color: AppColors.grayColor, fontSize: 15),
        prefixIcon: icon,
        border: InputBorder.none,
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      ),
    ),
  );
}
