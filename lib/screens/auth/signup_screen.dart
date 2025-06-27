import 'package:flutter/material.dart';
import 'package:kassoua/constants/colors.dart';
import 'package:kassoua/constants/size.dart';
import 'package:kassoua/themes/customs/elevated_button_theme.dart';
import 'package:kassoua/themes/customs/text_field_theme.dart';
import 'package:kassoua/themes/customs/text_theme.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kassoua/themes/customs/form_divider.dart';
import 'package:flutter/services.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:email_validator/email_validator.dart';
import 'package:kassoua/constants/text_string.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kassoua/models/user.dart';
import 'package:kassoua/services/auth_service.dart';
import 'package:kassoua/screens/auth/login_screen.dart';
import 'package:kassoua/screens/auth/sms_code_screen.dart';

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
  bool _isLoading = false; // Ajouté pour gérer l'état de chargement

  bool _isPhone = false;
  String? _phoneNumber;
  String? _email;

  final AuthService _authService = AuthService();

  bool _isDarkMode(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  @override
  Widget build(BuildContext context) {
    final isDark = _isDarkMode(context);
    final appBarTextStyle =
        isDark
            ? TTextTheme.darkTextTheme.headlineSmall
            : TTextTheme.lightTextTheme.headlineSmall;
    return Scaffold(
      backgroundColor: isDark ? DMColors.black : DMColors.white,
      appBar: AppBar(
        backgroundColor: isDark ? DMColors.black : DMColors.white,
        automaticallyImplyLeading: false,
        centerTitle: true,
        elevation: 0,
        title: Text(DMTexts.createAccount, style: appBarTextStyle),
        leading: IconButton(
          icon: Icon(
            Iconsax.arrow_left,
            color: isDark ? Colors.white : Colors.black,
          ),
          onPressed:
              _isLoading
                  ? null
                  : () =>
                      Navigator.pop(context), // Désactivé pendant le chargement
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
                "Acheter et vender en toute simplicité !",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color:
                      isDark
                          ? DMColors.textWhite.withOpacity(0.8)
                          : DMColors.black,
                ),
              ),
              const SizedBox(height: DMSizes.spaceBtwSections),
              // Nom
              TextFormField(
                controller: _firstNameController,
                enabled: !_isLoading, // Désactivé pendant le chargement
                decoration: InputDecoration(
                  labelText: 'nom',
                  prefixIcon: const Icon(Iconsax.user),
                  border: TTextFormFieldTheme.lightInputDecorationTheme.border,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer votre nom';
                  }
                  return null;
                },
              ),
              const SizedBox(height: DMSizes.spaceBtwInputFields),
              // Prénom
              TextFormField(
                controller: _lastNameController,
                enabled: !_isLoading, // Désactivé pendant le chargement
                decoration: InputDecoration(
                  labelText: 'prénom',
                  prefixIcon: const Icon(Iconsax.user),
                  border: TTextFormFieldTheme.lightInputDecorationTheme.border,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer votre prénom';
                  }
                  return null;
                },
              ),
              const SizedBox(height: DMSizes.spaceBtwInputFields),
              // E-mail ou Numéro de téléphone
              if (_isPhone)
                IntlPhoneField(
                  controller: _phoneNoController,
                  enabled: !_isLoading, // Désactivé pendant le chargement
                  decoration: InputDecoration(
                    labelText: 'Numéro de téléphone',
                    prefixIcon: const Icon(Iconsax.call),
                    border: const OutlineInputBorder(),
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
                          color: _isLoading ? Colors.grey : DMColors.primary,
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
                    if (value == null || value.completeNumber.isEmpty) {
                      return 'Veuillez entrer votre numéro de téléphone';
                    }
                    return null;
                  },
                  keyboardType: TextInputType.phone,
                )
              else
                TextFormField(
                  controller: _emailController,
                  enabled: !_isLoading, // Désactivé pendant le chargement
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Iconsax.message),
                    border: const OutlineInputBorder(),
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
                          color: _isLoading ? Colors.grey : DMColors.primary,
                        ),
                      ),
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
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
              const SizedBox(height: DMSizes.spaceBtwInputFields),
              // Mot de passe
              TextFormField(
                controller: _passwordController,
                enabled: !_isLoading, // Désactivé pendant le chargement
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: DMTexts.password,
                  prefixIcon: const Icon(Iconsax.password_check),
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
                  border: TTextFormFieldTheme.lightInputDecorationTheme.border,
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
                child: ElevatedButton(
                  onPressed:
                      _isLoading
                          ? null
                          : () async {
                            if (_formKey.currentState!.validate()) {
                              setState(() {
                                _isLoading = true; // Commencer le chargement
                              });

                              String nom = _firstNameController.text.trim();
                              String prenom = _lastNameController.text.trim();
                              String email = _emailController.text.trim();
                              String telephone = _phoneNumber ?? '';
                              String password = _passwordController.text;

                              if ((email.isEmpty && telephone.isEmpty) ||
                                  (email.isNotEmpty && telephone.isNotEmpty)) {
                                setState(() {
                                  _isLoading = false; // Arrêter le chargement
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "Veuillez remplir soit l'email, soit le téléphone, mais pas les deux.",
                                    ),
                                  ),
                                );
                                return;
                              }

                              try {
                                UserCredential userCredential;

                                if (email.isNotEmpty) {
                                  // Inscription avec email via AuthService
                                  userCredential = await _authService
                                      .signUpWithEmail(
                                        email,
                                        password,
                                        displayName: '$nom $prenom',
                                      );
                                } else {
                                  // Inscription avec téléphone via AuthService
                                  setState(() {
                                    _isLoading =
                                        true; // Commencer le chargement
                                  });
                                  // Ceci doit être fait avant d'appeler verifyPhoneNumber pour les tests
                                  FirebaseAuth.instance.setSettings(
                                    appVerificationDisabledForTesting: true,
                                  );

                                  await FirebaseAuth.instance.verifyPhoneNumber(
                                    phoneNumber: telephone,
                                    verificationCompleted: (
                                      PhoneAuthCredential credential,
                                    ) async {
                                      // Optionally sign in the user automatically here
                                      setState(() {
                                        _isLoading = false;
                                      });
                                    },
                                    verificationFailed: (
                                      FirebaseAuthException e,
                                    ) {
                                      setState(() {
                                        _isLoading = false;
                                      });
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            e.message ??
                                                'Erreur de vérification du téléphone',
                                          ),
                                        ),
                                      );
                                    },
                                    codeSent: (
                                      String verificationId,
                                      int? resendToken,
                                    ) {
                                      setState(() {
                                        _isLoading = false;
                                      });
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            "Code de vérification envoyé. Veuillez vérifier votre téléphone.",
                                          ),
                                        ),
                                      );
                                      // Naviguer vers l'écran de saisie du code
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) => SmsCodeScreen(
                                                verificationId: verificationId,
                                                phoneNumber: telephone,
                                                nom: nom,
                                                prenom: prenom,
                                              ),
                                        ),
                                      );
                                    },
                                    codeAutoRetrievalTimeout: (
                                      String verificationId,
                                    ) {
                                      // Optionally handle timeout
                                    },
                                  );

                                  return;
                                }

                                // Création de l'objet Utilisateur
                                final utilisateur = Utilisateur(
                                  id: userCredential.user!.uid,
                                  nom: nom,
                                  prenom: prenom,
                                  email: email.isNotEmpty ? email : '',
                                  telephone:
                                      telephone.isNotEmpty ? telephone : '',
                                  dateInscription: DateTime.now(),
                                );

                                // Enregistrement dans Firestore
                                await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(utilisateur.id)
                                    .set(utilisateur.toMap());

                                setState(() {
                                  _isLoading = false; // Arrêter le chargement
                                });

                                // Navigation ou message de succès
                                if (mounted) {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const LoginScreen(),
                                    ),
                                  );
                                }
                              } on FirebaseAuthException catch (e) {
                                setState(() {
                                  _isLoading =
                                      false; // Arrêter le chargement en cas d'erreur
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
                                  _isLoading =
                                      false; // Arrêter le chargement en cas d'erreur
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
                  style: DMElevatedButtonTheme.lightElevatedButtonTheme.style,
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
                                    isDark ? Colors.black : Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text("Inscription en cours..."),
                            ],
                          )
                          : Text(DMTexts.createAccount),
                ),
              ),
              const SizedBox(height: DMSizes.spaceBtwItems),
              // Ou s'inscrire avec
              const TFormDivider(dividerText: 'Ou s\'inscrire avec'),
              const SizedBox(height: DMSizes.spaceBtwItems),
              // Bouton Google
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: IconButton(
                      onPressed:
                          _isLoading
                              ? null
                              : () {}, // Désactivé pendant le chargement
                      icon: Image.asset(
                        'assets/images/icons/icons-google.png',
                        width: DMSizes.iconMd,
                        height: DMSizes.iconMd,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: DMSizes.spaceBtwItems),
              // Déjà un compte
              Center(
                child: TextButton(
                  onPressed:
                      _isLoading
                          ? null
                          : () => Navigator.pop(
                            context,
                          ), // Désactivé pendant le chargement
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
                            color: _isLoading ? Colors.grey : DMColors.primary,
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
