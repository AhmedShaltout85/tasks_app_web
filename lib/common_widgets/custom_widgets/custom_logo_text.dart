import 'package:flutter/material.dart';

class CustomLogoText extends StatelessWidget {
  const CustomLogoText({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      'LOGO',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 80,
        fontWeight: FontWeight.w300,
        fontFamily: 'Prime',
        color: Color(0xFF8CD6F7),
        letterSpacing: 4,
      ),
    );
  }
}
