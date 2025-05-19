import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'package:dm_shop/constants/colors.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 48,
                ), // Adjust 48 for padding
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      children: [
                        // Image en haut
                        Image.asset(
                          'assets/images/onboarding-image1.png',
                          height:
                              constraints.maxWidth *
                              0.6, // Adjust factor as needed
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 20),
                        // Texte du nom de l'app
                        Text(
                          'DM Shop',
                          style: Theme.of(
                            context,
                          ).textTheme.displayLarge?.copyWith(
                            fontSize:
                                constraints.maxWidth > 600
                                    ? 48
                                    : 32, // Responsive font size
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Achetez et vendez facilement vos produits en ligne',
                          style: Theme.of(
                            context,
                          ).textTheme.bodyLarge?.copyWith(
                            fontSize:
                                constraints.maxWidth > 600
                                    ? 20
                                    : 16, // Responsive font size
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                    // Bouton en bas
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          textStyle: const TextStyle(fontSize: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          backgroundColor: DMColors.buttonPrimary,
                        ),
                        child: const Text(
                          'Commencer',
                          style: TextStyle(color: DMColors.textWhite),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
