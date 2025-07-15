import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'views/splash_screen.dart';
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
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: _getSystemUIOverlayStyle(context),
          child: child!,
        );
      },
    );
  }

  SystemUiOverlayStyle _getSystemUIOverlayStyle(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return SystemUiOverlayStyle(
      // Barre de statut transparente
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,

      // Barre de navigation système
      systemNavigationBarColor:
          isDark
              ? const Color.fromARGB(255, 32, 32, 32)
              : const Color.fromARGB(255, 255, 255, 255),
      systemNavigationBarIconBrightness:
          isDark ? Brightness.light : Brightness.dark,

      // Amélioration pour les appareils avec navigation gestuelle
      systemNavigationBarContrastEnforced: false,
      systemNavigationBarDividerColor: Colors.transparent,
    );
  }
}
