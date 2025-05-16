import 'package:flutter/material.dart';
import 'package:dm_shop/themes/customs/app_bar_theme.dart';
import 'package:dm_shop/themes/customs/text_field_theme.dart';
import 'package:dm_shop/themes/customs/elevated_button_theme.dart';
import 'package:dm_shop/themes/customs/checkbox_theme.dart';
import 'package:dm_shop/themes/customs/chip_theme.dart';
import 'package:dm_shop/themes/customs/text_theme.dart';
import 'package:dm_shop/themes/customs/bottom_sheet_theme.dart';
import 'package:dm_shop/themes/customs/outlined_button_theme.dart';

// Couleur principale E-Shop
class DMappTheme {
  DMappTheme._();

  static ThemeData dmShopLightTheme = ThemeData(
    useMaterial3: true,
    fontFamily: 'Poppins',
    brightness: Brightness.light,
    primaryColor: Color(0xFF4b68ff),
    scaffoldBackgroundColor: Color(0xFFF5F5F5),
    chipTheme: TChipTheme.lightChipTheme,
    textTheme: TTextTheme.lightTextTheme,
    checkboxTheme: TCheckboxTheme.lightCheckboxTheme,
    elevatedButtonTheme: DMElevatedButtonTheme.lightElevatedButtonTheme,
    appBarTheme: TAppBarTheme.lightAppBarTheme,
    outlinedButtonTheme: TOutlinedButtonTheme.lightOutlinedButtonTheme,
    bottomSheetTheme: TBottomSheetTheme.lightBottomSheetTheme,
    inputDecorationTheme: TTextFormFieldTheme.lightInputDecorationTheme,
  );

  static ThemeData dmShopDarkTheme = ThemeData(
    useMaterial3: true,
    fontFamily: 'Poppins',
    brightness: Brightness.dark,
    primaryColor: Color(0xFF4b68ff),
    scaffoldBackgroundColor: Color(0xFF121212),
    textTheme: TTextTheme.darkTextTheme,
    elevatedButtonTheme: DMElevatedButtonTheme.darkElevatedButtonTheme,
    chipTheme: TChipTheme.darkChipTheme,
    checkboxTheme: TCheckboxTheme.darkCheckboxTheme,
    appBarTheme: TAppBarTheme.lightAppBarTheme,
    outlinedButtonTheme: TOutlinedButtonTheme.darkOutlinedButtonTheme,
    bottomSheetTheme: TBottomSheetTheme.darkBottomSheetTheme,
    inputDecorationTheme: TTextFormFieldTheme.darkInputDecorationTheme,
  );
}
