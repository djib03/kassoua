import 'package:flutter/material.dart';
import 'package:kassoua/constants/colors.dart';
import 'package:kassoua/constants/size.dart';
import 'package:kassoua/views/screen/auth/email_login_screen.dart';
import 'package:kassoua/views/screen/auth/phone_login_screen.dart';
import 'package:kassoua/views/screen/auth/signup_screen.dart';
import 'package:kassoua/views/screen/homepage/menu_navigation.dart';
import 'package:iconsax/iconsax.dart';

class AuthSelectionScreen extends StatelessWidget {
  const AuthSelectionScreen({Key? key}) : super(key: key);

  bool _isDarkMode(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  // Fonction pour afficher le modal bottom sheet
  void _showLoginOptionsModal(BuildContext context) {
    final isDark = _isDarkMode(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.black : AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Poignée du modal

              // Titre
              Text(
                "Choisissez votre méthode de connexion",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                "Sélectionnez comment vous souhaitez vous connecter",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color:
                      isDark
                          ? AppColors.textWhite.withOpacity(0.8)
                          : AppColors.black.withOpacity(0.7),
                ),
              ),

              const SizedBox(height: 24),

              // Option Email
              InkWell(
                onTap: () {
                  Navigator.pop(context); // Fermer le modal
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Iconsax.message,
                          color: AppColors.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Continuer avec Email",
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Utilisez votre email et mot de passe",
                              style: Theme.of(
                                context,
                              ).textTheme.bodySmall?.copyWith(
                                color:
                                    isDark
                                        ? AppColors.textWhite.withOpacity(0.7)
                                        : AppColors.black.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Iconsax.arrow_right_3, color: Colors.grey.shade400),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Option Téléphone
              InkWell(
                onTap: () {
                  Navigator.pop(context); // Fermer le modal
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PhoneLoginScreen(),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Iconsax.call,
                          color: AppColors.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Continuer avec Téléphone",
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Utilisez votre numéro de téléphone et mot de passe",
                              style: Theme.of(
                                context,
                              ).textTheme.bodySmall?.copyWith(
                                color:
                                    isDark
                                        ? AppColors.textWhite.withOpacity(0.7)
                                        : AppColors.black.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Iconsax.arrow_right_3, color: Colors.grey.shade400),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _isDarkMode(context);

    return Scaffold(
      backgroundColor: isDark ? AppColors.black : AppColors.white,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.black : AppColors.white,
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
              style: TextStyle(color: AppColors.primary),
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
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Iconsax.security_user,
                size: 100,
                color: AppColors.primary,
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
              "Achetez et vendez en toute simplicité",
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color:
                    isDark
                        ? AppColors.textWhite.withOpacity(0.8)
                        : AppColors.black.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: DMSizes.spaceBtwSections * 2),

            // Bouton S'inscrire
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SignUpScreen(),
                    ),
                  );
                },
                icon: const Icon(Iconsax.user_add, size: 24),
                label: const Text(
                  'Créer un compte',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
            ),

            const SizedBox(height: DMSizes.spaceBtwItems),

            // Bouton Se connecter
            SizedBox(
              width: double.infinity,
              height: 60,
              child: OutlinedButton.icon(
                onPressed: () {
                  _showLoginOptionsModal(context);
                },
                icon: const Icon(Iconsax.login, size: 24),
                label: const Text(
                  'Se connecter',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            // Texte informatif
          ],
        ),
      ),
    );
  }
}
