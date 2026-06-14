import 'package:flutter/material.dart';
import 'package:tasks_app/utils/app_colors.dart';

class CustomLoading extends StatelessWidget {
  final double size;
  final Color? color;

  const CustomLoading({
    super.key,
    this.size = 40,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          strokeWidth: 3,
          color: color ?? AppColors.primaryColor,
        ),
      ),
    );
  }
}
