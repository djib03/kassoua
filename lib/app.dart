import 'package:kassoua/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/splash_screen.dart';
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
      home: const SplashScreen(),
      builder: (context, child) {
        final Brightness brightness = MediaQuery.of(context).platformBrightness;

        SystemChrome.setSystemUIOverlayStyle(
          const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent, // Barre de notif transparente
            statusBarIconBrightness: Brightness.dark,
          ),
        );

        return child!;
      },
    );
  }
}
