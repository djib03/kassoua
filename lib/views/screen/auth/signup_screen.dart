import 'package:flutter/material.dart';
import 'package:kassoua/constants/colors.dart';
import 'package:kassoua/constants/size.dart';
import 'package:kassoua/themes/customs/elevated_button_theme.dart';
import 'package:kassoua/themes/customs/text_theme.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:email_validator/email_validator.dart';
import 'package:kassoua/constants/text_string.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kassoua/models/user.dart';
import 'package:kassoua/services/auth_service.dart';
import 'package:kassoua/controllers/auth_controller.dart';
import 'package:kassoua/views/screen/auth/email_login_screen.dart';
import 'package:provider/provider.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneNoController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  bool _isPhone = false;
  String? _phoneNumber;
  String? _email;

  final AuthService _authService = AuthService();

  bool _isDarkMode(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  // Widget pour créer un champ de saisie avec le style d'AuthScreenSelection
  Widget _buildStyledField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required String? Function(String?) validator,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
    Function(String)? onChanged,
  }) {
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
                  showDropdownIcon:
                      false, // Enlève l'icône dropdown si vous voulez
                  controller: _phoneNoController,
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    labelText: 'Numéro de téléphone',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none, // Enlève la bordure d'erreur
                    focusedErrorBorder:
                        InputBorder.none, // Enlève la bordure d'erreur focusée
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    suffixIcon: TextButton(
                      onPressed:
                          _isLoading
                              ? null
                              : () {
                                setState(() {
                                  _isPhone = !_isPhone;
                                  _phoneNoController.clear();
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
                    // Retourne null ici car on va gérer l'erreur à l'extérieur
                    return null;
                  },
                  keyboardType: TextInputType.phone,
                  disableLengthCheck:
                      true, // Désactive la vérification de longueur automatique
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
        title: Text(DMTexts.createAccount, style: appBarTextStyle),
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
              Text(
                "Bienvenue sur Kassoua !",
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: DMSizes.sm),
              Text(
                "Acheter et vendre en toute simplicité !",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color:
                      isDark
                          ? AppColors.textWhite.withOpacity(0.8)
                          : AppColors.black,
                ),
              ),
              const SizedBox(height: DMSizes.spaceBtwSections),

              // Nom
              _buildStyledField(
                label: 'Nom',
                icon: Iconsax.user,
                controller: _firstNameController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer votre nom';
                  }
                  return null;
                },
              ),
              const SizedBox(height: DMSizes.spaceBtwInputFields),

              // Prénom
              _buildStyledField(
                label: 'Prénom',
                icon: Iconsax.user,
                controller: _lastNameController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer votre prénom';
                  }
                  return null;
                },
              ),
              const SizedBox(height: DMSizes.spaceBtwInputFields),

              // E-mail ou Numéro de téléphone
              if (_isPhone) _buildPhoneField() else _buildEmailField(),
              const SizedBox(height: DMSizes.spaceBtwInputFields),

              // Mot de passe
              _buildStyledField(
                label: DMTexts.password,
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
              const SizedBox(height: DMSizes.spaceBtwSections),

              // Bouton S'inscrire
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed:
                      _isLoading
                          ? null
                          : () async {
                            if (_formKey.currentState!.validate()) {
                              // Validation manuelle du téléphone si c'est le mode téléphone
                              if (_isPhone &&
                                  (_phoneNumber == null ||
                                      _phoneNumber!.isEmpty ||
                                      _phoneNumber!.length < 8)) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Veuillez entrer un numéro de téléphone valide',
                                    ),
                                  ),
                                );
                                return;
                              }

                              setState(() {
                                _isLoading = true;
                              });

                              String nom = _firstNameController.text.trim();
                              String prenom = _lastNameController.text.trim();
                              String email = _emailController.text.trim();
                              String telephone = _phoneNumber ?? '';
                              String password = _passwordController.text;

                              try {
                                if (email.isNotEmpty) {
                                  // Inscription avec email via AuthService
                                  UserCredential userCredential =
                                      await _authService.signUpWithEmail(
                                        email,
                                        password,
                                        displayName: '$nom $prenom',
                                      );

                                  // Création de l'objet Utilisateur
                                  final utilisateur = Utilisateur(
                                    id: userCredential.user!.uid,
                                    nom: nom,
                                    prenom: prenom,
                                    email: email,
                                    telephone: '',
                                    dateInscription: DateTime.now(),
                                  );

                                  // Enregistrement dans Firestore
                                  await FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(utilisateur.id)
                                      .set(utilisateur.toMap());

                                  setState(() {
                                    _isLoading = false;
                                  });

                                  if (mounted) {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => const LoginScreen(),
                                      ),
                                    );
                                  }
                                } else {
                                  // Inscription avec téléphone via AuthController
                                  final authController =
                                      Provider.of<AuthController>(
                                        context,
                                        listen: false,
                                      );

                                  String? errorMessage = await authController
                                      .signUpWithPhone(
                                        phone: telephone,
                                        password: password,
                                        nom: nom,
                                        prenom: prenom,
                                      );

                                  setState(() {
                                    _isLoading = false;
                                  });

                                  if (errorMessage != null) {
                                    // Afficher l'erreur
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(errorMessage)),
                                    );
                                  } else {
                                    // Succès - rediriger vers login
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Compte créé avec succès !',
                                        ),
                                        backgroundColor: AppColors.primary,
                                      ),
                                    );

                                    if (mounted) {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) => const LoginScreen(),
                                        ),
                                      );
                                    }
                                  }
                                }
                              } on FirebaseAuthException catch (e) {
                                setState(() {
                                  _isLoading = false;
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      e.message ?? 'Erreur d\'inscription',
                                    ),
                                  ),
                                );
                              } catch (e) {
                                setState(() {
                                  _isLoading = false;
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Une erreur s\'est produite: $e',
                                    ),
                                  ),
                                );
                              }
                            }
                          },
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
                              const Text("Inscription en cours..."),
                            ],
                          )
                          : Text(
                            DMTexts.createAccount,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                ),
              ),
              const SizedBox(height: DMSizes.spaceBtwItems),

              // Déjà un compte
              Center(
                child: TextButton(
                  onPressed: _isLoading ? null : () => Navigator.pop(context),
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: "Vous avez déjà un compte? ",
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(
                            color: _isLoading ? Colors.grey : null,
                          ),
                        ),
                        TextSpan(
                          text: DMTexts.signIn,
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
