import 'package:flutter/material.dart';

/// Light and Dark Elevated Button Themes
class DMElevatedButtonTheme {
  // To avoid creating instances
  DMElevatedButtonTheme._();

  /// Light Theme
  static final lightElevatedButtonTheme = ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      elevation: 4,
      foregroundColor: Colors.white,
      backgroundColor: Color(0xFF4F46E5),
      disabledForegroundColor: Colors.grey,
      disabledBackgroundColor: Colors.grey,
      side: const BorderSide(color: Color(0xFF4F46E5)),
      padding: const EdgeInsets.symmetric(vertical: 18),
      textStyle: const TextStyle(
        fontSize: 16,
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );

  /// Dark Theme
  static final darkElevatedButtonTheme = ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      elevation: 0,
      foregroundColor: Colors.white,
      backgroundColor: Color(0xFF4F46E5),
      disabledForegroundColor: Colors.grey,
      disabledBackgroundColor: Colors.grey,
      side: const BorderSide(color: Color(0xFF4F46E5)),
      padding: const EdgeInsets.symmetric(vertical: 18),
      textStyle: const TextStyle(
        fontSize: 16,
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}
