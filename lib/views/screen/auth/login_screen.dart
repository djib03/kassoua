import 'package:kassoua/views/screen/homepage/menu_navigation.dart';
import 'package:flutter/material.dart';
import 'package:kassoua/constants/size.dart';
import 'package:iconsax/iconsax.dart';

import 'package:email_validator/email_validator.dart';

import 'package:flutter/services.dart';
import 'package:kassoua/views/screen/auth/signup_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kassoua/constants/colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kassoua/services/auth_service.dart';
import 'package:kassoua/themes/customs/text_theme.dart';
import 'package:kassoua/controllers/auth_controller.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  final AuthService _authService = AuthService();
  String? _verificationId;

  bool _isDarkMode(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Fonction pour détecter le type d'identifiant
  bool _isPhoneNumber(String identifier) {
    // Vérifier si c'est un format téléphone nigérien (+227 + 8 chiffres)
    final phoneRegex = RegExp(r'^\+227\d{8}$');
    return phoneRegex.hasMatch(identifier);
  }

  bool _isEmail(String identifier) {
    return identifier.contains('@') && EmailValidator.validate(identifier);
  }

  // Fonction pour formater le numéro de téléphone
  String _formatPhoneNumber(String input) {
    // Supprimer tous les espaces et caractères non numériques sauf +
    String cleaned = input.replaceAll(RegExp(r'[^\d+]'), '');

    // Si commence par +227, garder tel quel
    if (cleaned.startsWith('+227')) {
      return cleaned;
    }

    // Si commence par 227, ajouter le +
    if (cleaned.startsWith('227')) {
      return '+$cleaned';
    }

    // Si c'est juste 8 chiffres, ajouter +227
    if (cleaned.length == 8 && !cleaned.startsWith('0')) {
      return '+227$cleaned';
    }

    // Si commence par 0 et fait 9 chiffres, remplacer 0 par +227
    if (cleaned.startsWith('0') && cleaned.length == 9) {
      return '+227${cleaned.substring(1)}';
    }

    return cleaned;
  }

  // Widget pour créer un champ de saisie avec le style harmonisé
  Widget _buildStyledField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required String? Function(String?) validator,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
    Function(String)? onChanged,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              controller: controller,
              enabled: !_isLoading,
              obscureText: obscureText,
              keyboardType: keyboardType,
              onChanged: onChanged,
              inputFormatters: inputFormatters,
              decoration: InputDecoration(
                labelText: label,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                suffixIcon: suffixIcon,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
              validator: validator,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _signIn() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        String identifier = _identifierController.text.trim();
        String password = _passwordController.text;

        if (_isEmail(identifier)) {
          // Connexion par email
          await _authService.signInWithEmail(identifier, password);

          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isLoggedIn', true);

          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const MenuNavigation()),
              (route) => false,
            );
          }
        } else if (_isPhoneNumber(identifier)) {
          // Connexion par téléphone avec mot de passe
          final authController = Provider.of<AuthController>(
            context,
            listen: false,
          );

          final errorMessage = await authController.signInWithPhoneAndPassword(
            telephone: identifier,
            password: password,
          );

          if (errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMessage),
                backgroundColor: AppColors.error,
              ),
            );
          } else {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('isLoggedIn', true);

            if (mounted) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const MenuNavigation()),
                (route) => false,
              );
            }
          }
        } else {
          // Format non reconnu
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Format d\'identifiant non reconnu. Utilisez un email ou un numéro de téléphone (+227XXXXXXXX)',
              ),
            ),
          );
        }
      } on FirebaseAuthException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Erreur de connexion')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Une erreur s\'est produite: $e')),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _isDarkMode(context);
    final appBarTextStyle =
        isDark
            ? TTextTheme.darkTextTheme.headlineSmall
            : TTextTheme.lightTextTheme.headlineSmall;

    return Scaffold(
      backgroundColor: isDark ? AppColors.black : AppColors.white,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.black : AppColors.white,
        automaticallyImplyLeading: false,
        centerTitle: true,
        elevation: 0,
        title: Text('Se connecter', style: appBarTextStyle),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(DMSizes.defaultSpace),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec texte de bienvenue
              Text(
                "Heureux de vous retrouver sur Kassoua !",
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: DMSizes.sm),
              Text(
                "Connectez-vous avec votre email ou numéro de téléphone",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color:
                      isDark
                          ? AppColors.textWhite.withOpacity(0.8)
                          : AppColors.black,
                ),
              ),
              const SizedBox(height: DMSizes.spaceBtwSections),

              // Champ Identifiant unifié
              _buildStyledField(
                label: 'Email ou numéro de téléphone',
                icon: Iconsax.user,
                controller: _identifierController,
                keyboardType: TextInputType.text,
                onChanged: (value) {
                  // Seulement formater si la saisie ressemble à un numéro de téléphone
                  // et ne contient pas de '@' pour l'instant.
                  // Cela permet à l'utilisateur de commencer à taper un email normalement.
                  if (!value.contains('@') &&
                      (value.startsWith('+') ||
                          RegExp(r'^\d+$').hasMatch(value))) {
                    String formatted = _formatPhoneNumber(value);
                    if (formatted != value) {
                      _identifierController.value = TextEditingValue(
                        text: formatted,
                        selection: TextSelection.collapsed(
                          offset: formatted.length,
                        ),
                      );
                    }
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer votre email ou numéro de téléphone';
                  }

                  if (!_isEmail(value) && !_isPhoneNumber(value)) {
                    return 'Format invalide. Utilisez un email ou +227XXXXXXXX';
                  }

                  return null;
                },
              ),
              const SizedBox(height: DMSizes.spaceBtwInputFields),

              // Champ Mot de passe
              _buildStyledField(
                label: 'Mot de passe',
                icon: Iconsax.password_check,
                controller: _passwordController,
                obscureText: _obscurePassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Iconsax.eye_slash : Iconsax.eye,
                  ),
                  onPressed:
                      _isLoading
                          ? null
                          : () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer votre mot de passe';
                  }
                  if (value.length < 6) {
                    return 'Le mot de passe doit contenir au moins 6 caractères';
                  }
                  return null;
                },
              ),

              const SizedBox(height: DMSizes.spaceBtwInputFields),

              // Mot de passe oublié
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed:
                      _isLoading
                          ? null
                          : () {
                            // TODO: Implémenter la récupération de mot de passe
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Fonctionnalité à venir'),
                              ),
                            );
                          },
                  child: Text(
                    'Mot de passe oublié ?',
                    style: TextStyle(
                      color: _isLoading ? Colors.grey : AppColors.primary,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: DMSizes.spaceBtwSections),

              // Bouton de connexion
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _signIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child:
                      _isLoading
                          ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Text("Connexion en cours..."),
                            ],
                          )
                          : Text(
                            'Se connecter',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                ),
              ),

              const SizedBox(height: DMSizes.spaceBtwItems),

              // Pas de compte
              Center(
                child: TextButton(
                  onPressed:
                      _isLoading
                          ? null
                          : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SignUpScreen(),
                              ),
                            );
                          },
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: "Vous n'avez pas de compte? ",
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(
                            color: _isLoading ? Colors.grey : null,
                          ),
                        ),
                        TextSpan(
                          text: "S'inscrire",
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(
                            color: _isLoading ? Colors.grey : AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
