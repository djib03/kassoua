import 'package:flutter/material.dart';
import 'package:kassoua/constants/colors.dart';
import 'package:kassoua/constants/size.dart';
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
import 'package:provider/provider.dart';
import 'package:kassoua/views/screen/auth/login_screen.dart';

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
  String? _whatsappNumber; // Pour stocker le numéro WhatsApp

  final AuthService _authService = AuthService();

  bool _isDarkMode(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  // Modal Bottom Sheet pour demander le numéro WhatsApp
  void _showWhatsAppNumberModal() {
    final TextEditingController whatsappController = TextEditingController();
    String? tempWhatsappNumber;

    showModalBottomSheet(
      showDragHandle: false,
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isDark = _isDarkMode(context);

            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.black : AppColors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Titre
                    Text(
                      'Numéro WhatsApp',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),

                    // Description
                    Text(
                      'Ajoutez votre numéro WhatsApp pour permettre aux acheteurs de vous contacter facilement.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color:
                            isDark
                                ? AppColors.textWhite.withOpacity(0.8)
                                : AppColors.black.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Champ téléphone
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
                            child: Icon(
                              Iconsax.call,
                              color: AppColors.primary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: IntlPhoneField(
                              showCountryFlag: false,
                              showDropdownIcon: false,
                              controller: whatsappController,
                              decoration: const InputDecoration(
                                labelText: 'Numéro WhatsApp',
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                errorBorder: InputBorder.none,
                                focusedErrorBorder: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                              ),
                              initialCountryCode: 'NE',
                              onChanged: (phone) {
                                setModalState(() {
                                  tempWhatsappNumber = phone.completeNumber;
                                });
                              },
                              validator: (value) => null,
                              keyboardType: TextInputType.phone,
                              disableLengthCheck: true,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Message d'erreur
                    if (tempWhatsappNumber != null &&
                        tempWhatsappNumber!.isNotEmpty &&
                        tempWhatsappNumber!.length < 12)
                      Padding(
                        padding: const EdgeInsets.only(top: 5, left: 12),
                        child: Text(
                          'Numéro de téléphone invalide',
                          style: TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ),

                    const SizedBox(height: 20),

                    // Boutons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: AppColors.primary),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text(
                              'Passer',
                              style: TextStyle(color: AppColors.primary),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed:
                                (tempWhatsappNumber != null &&
                                        tempWhatsappNumber!.isNotEmpty &&
                                        tempWhatsappNumber!.length >= 8)
                                    ? () {
                                      setState(() {
                                        _whatsappNumber = tempWhatsappNumber;
                                      });
                                      Navigator.pop(context);
                                    }
                                    : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text('Confirmer'),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

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
                  controller: _phoneNoController,
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
                  validator: (value) => null,
                  keyboardType: TextInputType.phone,
                  disableLengthCheck: true,
                ),
              ),
            ],
          ),
        ),
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

    return Column(
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
                child: Icon(
                  Iconsax.message,
                  color: AppColors.primary,
                  size: 24,
                ),
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
        ),

        // Bouton pour ajouter le numéro WhatsApp
        if (!_isPhone &&
            _emailController.text.isNotEmpty &&
            EmailValidator.validate(_emailController.text))
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Icon(Iconsax.info_circle, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _whatsappNumber != null
                        ? 'WhatsApp: $_whatsappNumber'
                        : 'Ajoutez votre numéro WhatsApp',
                    style: TextStyle(color: AppColors.primary, fontSize: 12),
                  ),
                ),
                TextButton(
                  onPressed: _isLoading ? null : _showWhatsAppNumberModal,
                  child: Text(
                    _whatsappNumber != null ? 'Modifier' : 'Ajouter',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
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

                                  // Création de l'objet Utilisateur avec numéro WhatsApp
                                  final utilisateur = Utilisateur(
                                    id: userCredential.user!.uid,
                                    nom: nom,
                                    prenom: prenom,
                                    email: email,
                                    telephone:
                                        _whatsappNumber ??
                                        '', // Utilise le numéro WhatsApp
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
                                        telephone: telephone,
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
                          ? Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
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
