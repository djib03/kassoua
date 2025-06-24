import 'package:flutter/material.dart';
import 'package:kassoua/constants/colors.dart';
import 'package:kassoua/constants/size.dart';
import 'package:kassoua/themes/customs/form_divider.dart';
import 'package:kassoua/screens/login_screen.dart';
import 'package:kassoua/screens/phone_login_screen.dart';
import 'package:kassoua/screens/signup_screen.dart';
import 'package:kassoua/screens/menu_navigation.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter/services.dart';

class AuthSelectionScreen extends StatelessWidget {
  const AuthSelectionScreen({Key? key}) : super(key: key);

  bool _isDarkMode(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  @override
  Widget build(BuildContext context) {
    final isDark = _isDarkMode(context);

    return Scaffold(
      backgroundColor: isDark ? DMColors.black : DMColors.white,
      appBar: AppBar(
        backgroundColor: isDark ? DMColors.black : DMColors.white,
        automaticallyImplyLeading: false,
        centerTitle: true,
        elevation: 0,

        actions: [
          TextButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => MenuNavigation()),
              );
            },
            child: const Text(
              'Passer',
              style: TextStyle(color: DMColors.buttonPrimary),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(DMSizes.defaultSpace),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Logo ou icône principale
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: DMColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Iconsax.security_user,
                size: 80,
                color: DMColors.primary,
              ),
            ),

            const SizedBox(height: DMSizes.spaceBtwSections),

            // Titre de bienvenue
            Text(
              "Bienvenue sur Kassoua !",
              style: Theme.of(
                context,
              ).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: DMSizes.sm),

            Text(
              "Choisissez votre méthode de connexion préférée",
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color:
                    isDark
                        ? DMColors.textWhite.withOpacity(0.8)
                        : DMColors.black.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: DMSizes.spaceBtwSections),

            // Bouton Email
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                },
                icon: const Icon(Iconsax.message, size: 24),
                label: const Text(
                  'Continuer avec Email',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: DMColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
            ),

            const SizedBox(height: DMSizes.spaceBtwItems),

            // Bouton Téléphone
            SizedBox(
              width: double.infinity,
              height: 60,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PhoneLoginScreen(),
                    ),
                  );
                },
                icon: const Icon(Iconsax.call, size: 24),
                label: const Text(
                  'Continuer avec Téléphone',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: DMColors.primary,
                  side: const BorderSide(color: DMColors.primary, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: DMSizes.spaceBtwSections),

            // Divider
            const TFormDivider(dividerText: 'Ou continuer avec'),

            const SizedBox(height: DMSizes.spaceBtwItems),

            // Bouton Google
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: InkWell(
                onTap: () {
                  // Logique de connexion Google
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/icons/icons-google.png',
                        width: 24,
                        height: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Continuer avec Google',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 4),

            // Lien vers inscription
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Vous n'avez pas de compte ? ",
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SignUpScreen(),
                      ),
                    );
                  },
                  child: Text(
                    'Créer un compte',
                    style: TextStyle(
                      color: DMColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
