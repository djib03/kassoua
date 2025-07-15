import 'package:kassoua/views/screen/homepage/menu_navigation.dart';
import 'package:flutter/material.dart';
import 'package:kassoua/constants/size.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
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
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isPhone = true; // Téléphone en premier par défaut
  String? _phoneNumber;
  String? _email;

  final AuthService _authService = AuthService();

  bool _isDarkMode(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
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

  // Widget pour le champ téléphone avec style similaire
  Widget _buildPhoneField() {
    final isDark = _isDarkMode(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
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
                child: Icon(Iconsax.call, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: IntlPhoneField(
                  showCountryFlag: false,
                  showDropdownIcon: false,
                  controller: _phoneController,
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    labelText: 'Numéro de téléphone',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    suffixIcon: TextButton(
                      onPressed:
                          _isLoading
                              ? null
                              : () {
                                setState(() {
                                  _isPhone = !_isPhone;
                                  _phoneController.clear();
                                });
                              },
                      child: Text(
                        "Utiliser l'email",
                        style: TextStyle(
                          color: _isLoading ? Colors.grey : AppColors.primary,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                  initialCountryCode: 'NE',
                  onChanged: (phone) {
                    setState(() {
                      _phoneNumber = phone.completeNumber;
                    });
                  },
                  validator: (value) {
                    return null;
                  },
                  keyboardType: TextInputType.phone,
                  disableLengthCheck: true,
                ),
              ),
            ],
          ),
        ),
        // Message d'erreur à l'extérieur du champ
        if (_phoneNumber != null &&
            _phoneNumber!.isNotEmpty &&
            _phoneNumber!.length < 12)
          Padding(
            padding: const EdgeInsets.only(top: 5, left: 12),
            child: Text(
              'Numéro de téléphone invalide',
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }

  // Widget pour le champ email avec style similaire
  Widget _buildEmailField() {
    final isDark = _isDarkMode(context);

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
            child: Icon(Iconsax.message, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              controller: _emailController,
              enabled: !_isLoading,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                suffixIcon: TextButton(
                  onPressed:
                      _isLoading
                          ? null
                          : () {
                            setState(() {
                              _isPhone = !_isPhone;
                              _emailController.clear();
                            });
                          },
                  child: Text(
                    "Utiliser le téléphone",
                    style: TextStyle(
                      color: _isLoading ? Colors.grey : AppColors.primary,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer votre email';
                }
                if (!EmailValidator.validate(value)) {
                  return 'Veuillez entrer un email valide';
                }
                return null;
              },
              onChanged: (value) {
                setState(() {
                  _email = value;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _signIn() async {
    if (_formKey.currentState!.validate()) {
      // Validation manuelle du téléphone si c'est le mode téléphone
      if (_isPhone &&
          (_phoneNumber == null ||
              _phoneNumber!.isEmpty ||
              _phoneNumber!.length < 8)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez entrer un numéro de téléphone valide'),
          ),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        String password = _passwordController.text;

        if (!_isPhone && _email != null && _email!.isNotEmpty) {
          // Connexion par email
          await _authService.signInWithEmail(_email!, password);

          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isLoggedIn', true);

          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const MenuNavigation()),
              (route) => false,
            );
          }
        } else if (_isPhone &&
            _phoneNumber != null &&
            _phoneNumber!.isNotEmpty) {
          // Connexion par téléphone avec mot de passe
          final authController = Provider.of<AuthController>(
            context,
            listen: false,
          );

          final errorMessage = await authController.signInWithPhoneAndPassword(
            telephone: _phoneNumber!,
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
          // Aucune méthode de connexion valide
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Veuillez entrer un identifiant valide'),
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
        leading: IconButton(
          icon: Icon(
            Iconsax.arrow_left,
            color: isDark ? Colors.white : Colors.black,
          ),
          onPressed: _isLoading ? null : () => Navigator.pop(context),
        ),
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
                "Connectez-vous avec votre téléphone ou email",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color:
                      isDark
                          ? AppColors.textWhite.withOpacity(0.8)
                          : AppColors.black,
                ),
              ),
              const SizedBox(height: DMSizes.spaceBtwSections),

              // Champ téléphone/email unifié
              if (_isPhone) _buildPhoneField() else _buildEmailField(),
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

              const SizedBox(height: 10),

              // Mot de passe oublié
              Align(
                alignment: Alignment.center,
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

              const SizedBox(height: 10),

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
