import 'package:dm_shop/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/splash_screen.dart';
import 'themes/theme.dart';
import 'package:get/get.dart';

class EShopApp extends StatelessWidget {
  const EShopApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DM Shop',
      theme: DMappTheme.dmShopLightTheme,
      darkTheme: DMappTheme.dmShopDarkTheme,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
      builder: (context, child) {
        final Brightness brightness = MediaQuery.of(context).platformBrightness;

        SystemChrome.setSystemUIOverlayStyle(
          SystemUiOverlayStyle(
            statusBarColor:
                DMColors
                    .buttonPrimary, // Fond transparent (prend la couleur de l'appBar ou fond d'écran)
            statusBarIconBrightness:
                brightness == Brightness.dark
                    ? Brightness
                        .light // En mode sombre : icônes claires
                    : Brightness.light, // En mode clair : icônes foncées
          ),
        );

        return child!;
      },
    );
  }
}
