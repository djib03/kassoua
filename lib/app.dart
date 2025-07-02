import 'package:flutter/material.dart';
import 'views/screen/splash_screen.dart';
import 'themes/theme.dart';

class KassouaApp extends StatelessWidget {
  const KassouaApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kassoua',
      theme: DMappTheme.dmShopLightTheme,
      darkTheme: DMappTheme.dmShopDarkTheme,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
    );
  }
}
