import 'package:flutter/material.dart';

import 'custom_text.dart';

class CustomElevatedButton extends StatelessWidget {
  final VoidCallback onTap;
  final String text;
  final Color color;
  final Color textColor;
  final double fontSize;
  final FontWeight? fontWeight;
  final double height;
  final double width;
  const CustomElevatedButton({
    super.key,
    required this.text,
    required this.color,
    required this.textColor,
    required this.fontSize,
    required this.height,
    required this.width,
    required this.onTap,
    this.fontWeight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 50,
      constraints: BoxConstraints(minWidth: 120),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF8CD6F7), Color(0xFF6BB8E3)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF8CD6F7).withOpacity(0.4),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Center(
            child: CustomText(
              text: text,
              fontSize: fontSize,
              fontWeight: fontWeight ?? FontWeight.bold,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}
