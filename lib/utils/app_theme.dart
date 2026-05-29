// // ignore_for_file: deprecated_member_use
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:tasks_app/utils/app_colors.dart';

class AppTheme {
  // Light theme
  static ThemeData lightTheme = ThemeData(
    fontFamily: 'Cairo',
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.light(
      primary: AppColors.primaryColor,
      primaryContainer: AppColors.primaryLight,
      secondary: AppColors.secondaryColor,
      secondaryContainer: AppColors.secondaryLight,
      surface: AppColors.surfaceLight,
      background: AppColors.backgroundLight,
      error: AppColors.errorColor,
      onPrimary: AppColors.whiteColor,
      onPrimaryContainer: AppColors.primaryDark,
      onSecondary: AppColors.blackColor87,
      onSecondaryContainer: AppColors.secondaryDark,
      onSurface: AppColors.textPrimaryLight,
      onBackground: AppColors.textPrimaryLight,
      onError: AppColors.whiteColor,
      outline: AppColors.borderLight,
      shadow: AppColors.shadowLight,
      surfaceVariant: AppColors.lightGrayColor,
      onSurfaceVariant: AppColors.textSecondaryLight,
    ),
    scaffoldBackgroundColor: AppColors.backgroundLight,

    // AppBar Theme
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.primaryColor,
      foregroundColor: AppColors.whiteColor,
      elevation: 0,
      scrolledUnderElevation: 4,
      centerTitle: true,
      shadowColor: Colors.black26,
      surfaceTintColor: AppColors.transparent,
      iconTheme: const IconThemeData(color: AppColors.whiteColor, size: 24),
      actionsIconTheme:
          const IconThemeData(color: AppColors.whiteColor, size: 24),
      titleTextStyle: const TextStyle(
        color: AppColors.whiteColor,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        fontFamily: 'Cairo',
        letterSpacing: 0.3,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(16),
        ),
      ),
    ),

    // Card Theme
    cardTheme: CardThemeData(
      color: AppColors.cardLight,
      elevation: 2,
      shadowColor: AppColors.shadowLight,
      surfaceTintColor: AppColors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),

    // Elevated Button Theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryColor,
        foregroundColor: AppColors.whiteColor,
        elevation: 2,
        shadowColor: AppColors.shadowLight,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          fontFamily: 'Cairo',
        ),
      ),
    ),

    // Text Button Theme
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          fontFamily: 'Cairo',
        ),
      ),
    ),

    // Outlined Button Theme
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryColor,
        side: const BorderSide(color: AppColors.primaryColor, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          fontFamily: 'Cairo',
        ),
      ),
    ),

    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceLight,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.borderLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.borderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.errorColor),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.errorColor, width: 2),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.borderLight.withOpacity(0.5)),
      ),
      hintStyle: const TextStyle(color: AppColors.hintColor),
      labelStyle: const TextStyle(color: AppColors.textSecondaryLight),
    ),

    // Icon Theme
    iconTheme: const IconThemeData(color: AppColors.primaryColor, size: 24),

    // Divider Theme
    dividerTheme: const DividerThemeData(
      color: AppColors.dividerLight,
      thickness: 1,
      space: 1,
    ),

    // Floating Action Button Theme
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.primaryColor,
      foregroundColor: AppColors.whiteColor,
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),

    // Bottom Navigation Bar Theme
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surfaceLight,
      selectedItemColor: AppColors.primaryColor,
      unselectedItemColor: AppColors.textSecondaryLight,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),

    // Chip Theme
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.lightGrayColor,
      deleteIconColor: AppColors.textSecondaryLight,
      disabledColor: AppColors.lightGrayColor.withOpacity(0.5),
      selectedColor: AppColors.primaryLight,
      secondarySelectedColor: AppColors.secondaryLight,
      labelPadding: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      labelStyle: const TextStyle(color: AppColors.textPrimaryLight),
      secondaryLabelStyle: const TextStyle(color: AppColors.textPrimaryLight),
      brightness: Brightness.light,
    ),

    // Dialog Theme
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surfaceLight,
      elevation: 24,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titleTextStyle: const TextStyle(
        color: AppColors.textPrimaryLight,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        fontFamily: 'Cairo',
      ),
      contentTextStyle: const TextStyle(
        color: AppColors.textSecondaryLight,
        fontSize: 14,
        fontFamily: 'Cairo',
      ),
    ),

    // Snackbar Theme
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.darkGrayColor,
      contentTextStyle: const TextStyle(color: AppColors.whiteColor),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      behavior: SnackBarBehavior.floating,
    ),

    // Progress Indicator Theme
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.primaryColor,
      linearTrackColor: AppColors.lightGrayColor,
      circularTrackColor: AppColors.lightGrayColor,
    ),
  );

  // Dark theme
  static ThemeData darkTheme = ThemeData(
    fontFamily: 'Cairo',
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: AppColors.secondaryColor,
      primaryContainer: AppColors.secondaryDark,
      secondary: AppColors.primaryColor,
      secondaryContainer: AppColors.primaryDark,
      surface: AppColors.surfaceDark,
      background: AppColors.backgroundDark,
      error: AppColors.errorColor,
      onPrimary: AppColors.blackColor87,
      onPrimaryContainer: AppColors.secondaryLight,
      onSecondary: AppColors.whiteColor,
      onSecondaryContainer: AppColors.primaryLight,
      onSurface: AppColors.textPrimaryDark,
      onBackground: AppColors.textPrimaryDark,
      onError: AppColors.blackColor,
      outline: AppColors.borderDark,
      shadow: AppColors.shadowDark,
      surfaceVariant: AppColors.darkGrayColor,
      onSurfaceVariant: AppColors.textSecondaryDark,
    ),
    scaffoldBackgroundColor: AppColors.backgroundDark,

    // AppBar Theme
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.surfaceDark,
      foregroundColor: AppColors.secondaryColor,
      elevation: 0,
      scrolledUnderElevation: 4,
      centerTitle: true,
      shadowColor: Colors.black38,
      surfaceTintColor: AppColors.transparent,
      iconTheme: const IconThemeData(color: AppColors.secondaryColor, size: 24),
      actionsIconTheme:
          const IconThemeData(color: AppColors.secondaryColor, size: 24),
      titleTextStyle: const TextStyle(
        color: AppColors.secondaryColor,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        fontFamily: 'Cairo',
        letterSpacing: 0.3,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(16),
        ),
      ),
    ),

    // Card Theme
    cardTheme: CardThemeData(
      color: AppColors.cardDark,
      elevation: 2,
      shadowColor: AppColors.shadowDark,
      surfaceTintColor: AppColors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),

    // Elevated Button Theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.secondaryColor,
        foregroundColor: AppColors.blackColor87,
        elevation: 2,
        shadowColor: AppColors.shadowDark,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          fontFamily: 'Cairo',
        ),
      ),
    ),

    // Text Button Theme
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.secondaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          fontFamily: 'Cairo',
        ),
      ),
    ),

    // Outlined Button Theme
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.secondaryColor,
        side: const BorderSide(color: AppColors.secondaryColor, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          fontFamily: 'Cairo',
        ),
      ),
    ),

    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF2C2C2C),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.borderDark),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.borderDark),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.secondaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.errorColor),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.errorColor, width: 2),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.borderDark.withOpacity(0.5)),
      ),
      hintStyle: const TextStyle(color: AppColors.hintColor),
      labelStyle: const TextStyle(color: AppColors.textSecondaryDark),
    ),

    // Icon Theme
    iconTheme: const IconThemeData(color: AppColors.secondaryColor, size: 24),

    // Divider Theme
    dividerTheme: const DividerThemeData(
      color: AppColors.dividerDark,
      thickness: 1,
      space: 1,
    ),

    // Floating Action Button Theme
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.secondaryColor,
      foregroundColor: AppColors.blackColor87,
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),

    // Bottom Navigation Bar Theme
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surfaceDark,
      selectedItemColor: AppColors.secondaryColor,
      unselectedItemColor: AppColors.textSecondaryDark,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),

    // Chip Theme
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.darkGrayColor,
      deleteIconColor: AppColors.textSecondaryDark,
      disabledColor: AppColors.darkGrayColor.withOpacity(0.5),
      selectedColor: AppColors.secondaryDark,
      secondarySelectedColor: AppColors.primaryDark,
      labelPadding: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      labelStyle: const TextStyle(color: AppColors.textPrimaryDark),
      secondaryLabelStyle: const TextStyle(color: AppColors.textPrimaryDark),
      brightness: Brightness.dark,
    ),

    // Dialog Theme
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surfaceDark,
      elevation: 24,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titleTextStyle: const TextStyle(
        color: AppColors.textPrimaryDark,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        fontFamily: 'Cairo',
      ),
      contentTextStyle: const TextStyle(
        color: AppColors.textSecondaryDark,
        fontSize: 14,
        fontFamily: 'Cairo',
      ),
    ),

    // Snackbar Theme
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.mediumGrayColor,
      contentTextStyle: const TextStyle(color: AppColors.blackColor87),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      behavior: SnackBarBehavior.floating,
    ),

    // Progress Indicator Theme
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.secondaryColor,
      linearTrackColor: AppColors.darkGrayColor,
      circularTrackColor: AppColors.darkGrayColor,
    ),
  );
}
