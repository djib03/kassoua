import 'package:kassoua/views/screen/homepage/menu_navigation.dart';
import 'package:flutter/material.dart';
import 'package:kassoua/constants/size.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kassoua/constants/text_string.dart';
import 'package:email_validator/email_validator.dart';
import 'package:kassoua/themes/customs/spacing_style.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:flutter/services.dart';
import 'package:kassoua/views/screen/auth/signup_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kassoua/themes/customs/form_divider.dart';
import 'package:kassoua/constants/colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kassoua/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController(); // Email ou téléphone
  final _passwordController =
      TextEditingController(); // AJOUTÉ: Contrôleur pour le mot de passe

  bool _isPhone = false;
  String? _phoneNumber;
  String? _email;
  bool _obscurePassword = true;
  bool _isLoading = false; // AJOUTÉ: État de chargement
  final AuthService _authService = AuthService();
  String? _verificationId;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose(); // AJOUTÉ: Dispose du contrôleur
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.black : AppColors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        elevation: 0,
        title: Text(
          'Se connecter',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: DMSpacingStyle.paddingWithAppBarHeight,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Heureux de vous retrouver sur Kassoua !",
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: DMSizes.sm),
                    Text(
                      "Connectez-vous avec votre numéro de téléphone ou email",
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
                const SizedBox(height: DMSizes.spaceBtwSections),

                // Champ Email ou Téléphone
                if (_isPhone)
                  IntlPhoneField(
                    controller: _identifierController,
                    enabled:
                        !_isLoading, // MODIFIÉ: Désactiver si en cours de chargement
                    decoration: InputDecoration(
                      labelText: 'Numéro de téléphone',
                      prefixIcon: const Icon(Iconsax.call),
                      border: const OutlineInputBorder(),
                      suffixIcon: TextButton(
                        onPressed:
                            _isLoading
                                ? null
                                : () {
                                  // MODIFIÉ: Désactiver si en cours de chargement
                                  setState(() {
                                    _isPhone = !_isPhone;
                                    _identifierController.clear();
                                    _phoneNumber = null;
                                    _email = null;
                                  });
                                },
                        child: Text(
                          "Utiliser l'email",
                          style: TextStyle(color: AppColors.buttonPrimary),
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
                    controller: _identifierController,
                    enabled:
                        !_isLoading, // MODIFIÉ: Désactiver si en cours de chargement
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Iconsax.message),
                      border: const OutlineInputBorder(),
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

                // Champ Mot de passe - CORRIGÉ avec le bon contrôleur
                TextFormField(
                  controller:
                      _passwordController, // CORRIGÉ: Utilise le bon contrôleur
                  enabled:
                      !_isLoading, // MODIFIÉ: Désactiver si en cours de chargement
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Mot de passe',
                    prefixIcon: const Icon(Iconsax.password_check),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Iconsax.eye_slash : Iconsax.eye,
                      ),
                      onPressed:
                          _isLoading
                              ? null
                              : () {
                                // MODIFIÉ: Désactiver si en cours de chargement
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                    ),
                    border: const OutlineInputBorder(),
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

                const SizedBox(height: DMSizes.spaceBtwInputFields / 2),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Checkbox(
                            fillColor: WidgetStateProperty.all<Color>(
                              AppColors.primary,
                            ),
                            value: true,
                            onChanged:
                                _isLoading
                                    ? null
                                    : (
                                      value,
                                    ) {}, // MODIFIÉ: Désactiver si en cours de chargement
                          ),
                          Flexible(
                            child: Text(
                              DMTexts.rememberMe,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed:
                          _isLoading
                              ? null
                              : () {}, // MODIFIÉ: Désactiver si en cours de chargement
                      child: const Text(
                        'Mot de passe oublié ?',
                        style: TextStyle(color: AppColors.buttonPrimary),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: DMSizes.spaceBtwSections / 2),

                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed:
                            _isLoading
                                ? null
                                : () async {
                                  // MODIFIÉ: Désactiver si en cours de chargement
                                  if (_formKey.currentState!.validate()) {
                                    setState(() {
                                      _isLoading =
                                          true; // AJOUTÉ: Activer le chargement
                                    });

                                    try {
                                      if (_isPhone) {
                                        // AMÉLIORATION: Validation des données
                                        if (_phoneNumber == null ||
                                            _phoneNumber!.isEmpty) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Numéro de téléphone manquant',
                                              ),
                                            ),
                                          );
                                          return;
                                        }

                                        // Connexion par téléphone (logique SMS existante)
                                        if (_verificationId == null) {
                                          await _authService.verifyPhoneNumber(
                                            phoneNumber: _phoneNumber!,
                                            onVerificationCompleted: (
                                              credential,
                                            ) async {
                                              await FirebaseAuth.instance
                                                  .signInWithCredential(
                                                    credential,
                                                  );
                                              if (mounted) {
                                                Navigator.pushReplacement(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder:
                                                        (context) =>
                                                            const MenuNavigation(),
                                                  ),
                                                );
                                              }
                                            },
                                            onVerificationFailed: (e) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    e.message ?? 'Erreur SMS',
                                                  ),
                                                ),
                                              );
                                            },
                                            onCodeSent: (
                                              verificationId,
                                              resendToken,
                                            ) async {
                                              setState(() {
                                                _verificationId =
                                                    verificationId;
                                              });

                                              String?
                                              smsCode = await showDialog<
                                                String
                                              >(
                                                context: context,
                                                builder: (context) {
                                                  String code = '';
                                                  return AlertDialog(
                                                    title: const Text(
                                                      'Code SMS',
                                                    ),
                                                    content: TextField(
                                                      onChanged:
                                                          (value) =>
                                                              code = value,
                                                      decoration:
                                                          const InputDecoration(
                                                            labelText:
                                                                'Code reçu par SMS',
                                                          ),
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed:
                                                            () => Navigator.pop(
                                                              context,
                                                              code,
                                                            ),
                                                        child: const Text(
                                                          'Valider',
                                                        ),
                                                      ),
                                                    ],
                                                  );
                                                },
                                              );

                                              if (smsCode != null &&
                                                  smsCode.isNotEmpty) {
                                                await _authService
                                                    .signInWithSmsCode(
                                                      _verificationId!,
                                                      smsCode,
                                                    );
                                                if (mounted) {
                                                  Navigator.pushReplacement(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder:
                                                          (context) =>
                                                              const MenuNavigation(),
                                                    ),
                                                  );
                                                }
                                              }
                                            },
                                            onCodeAutoRetrievalTimeout: (
                                              verificationId,
                                            ) {
                                              setState(() {
                                                _verificationId =
                                                    verificationId;
                                              });
                                            },
                                          );
                                        }
                                      } else {
                                        // CORRIGÉ: Connexion par email avec le bon mot de passe
                                        if (_email == null || _email!.isEmpty) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text('Email manquant'),
                                            ),
                                          );
                                          return;
                                        }

                                        await _authService.signInWithEmail(
                                          _email!,
                                          _passwordController
                                              .text, // CORRIGÉ: Utilise le bon contrôleur
                                        );

                                        final prefs =
                                            await SharedPreferences.getInstance();
                                        await prefs.setBool('isLoggedIn', true);

                                        if (mounted) {
                                          Navigator.pushAndRemoveUntil(
                                            context,
                                            MaterialPageRoute(
                                              builder:
                                                  (context) =>
                                                      const MenuNavigation(),
                                            ),
                                            (route) => false,
                                          );
                                        }
                                      }
                                    } on FirebaseAuthException catch (e) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            e.message ?? 'Erreur de connexion',
                                          ),
                                        ),
                                      );
                                    } finally {
                                      if (mounted) {
                                        setState(() {
                                          _isLoading =
                                              false; // AJOUTÉ: Désactiver le chargement
                                        });
                                      }
                                    }
                                  }
                                },
                        child:
                            _isLoading // MODIFIÉ: Afficher l'indicateur de chargement
                                ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Color.fromARGB(255, 147, 143, 224),
                                    ),
                                  ),
                                )
                                : const Text('Se connecter'),
                      ),
                    ),

                    const SizedBox(height: DMSizes.spaceBtwItems),
                  ],
                ),

                const SizedBox(height: DMSizes.spaceBtwSections),
                const TFormDivider(dividerText: 'Se connecter avec'),
                const SizedBox(height: DMSizes.spaceBtwItems),

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
                                : () {}, // MODIFIÉ: Désactiver si en cours de chargement
                        icon: Image.asset(
                          'assets/images/icons/icons-google.png',
                          width: DMSizes.iconMd,
                          height: DMSizes.iconMd,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
