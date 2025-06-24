import 'package:flutter/material.dart';
import 'package:kassoua/constants/colors.dart';
import 'package:kassoua/constants/size.dart';
import 'package:kassoua/themes/customs/spacing_style.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kassoua/screens/auth/sms_code_screen_login.dart';
import 'package:kassoua/screens/homepage/menu_navigation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({Key? key}) : super(key: key);

  @override
  _PhoneLoginScreenState createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  String? _phoneNumber;
  bool _isLoading = false;

  bool _isDarkMode(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _sendSmsCode() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        await FirebaseAuth.instance.verifyPhoneNumber(
          phoneNumber: _phoneNumber!,
          verificationCompleted: (PhoneAuthCredential credential) async {
            // Connexion automatique
            UserCredential userCredential = await FirebaseAuth.instance
                .signInWithCredential(credential);
            if (userCredential.user != null) {
              // Mettre à jour SharedPreferences
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('isLoggedIn', true);
              await prefs.setString('userId', userCredential.user!.uid);

              // Vérifier et créer un document Firestore si nécessaire
              final userDoc = FirebaseFirestore.instance
                  .collection('users')
                  .doc(userCredential.user!.uid);
              final docSnapshot = await userDoc.get();
              if (!docSnapshot.exists) {
                // Créer un document utilisateur par défaut
                await userDoc.set({
                  'nom': '',
                  'prenom': '',
                  'email': '',
                  'telephone': _phoneNumber,
                  'photoProfil': '',
                  'dateInscription': FieldValue.serverTimestamp(),
                });
              }

              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MenuNavigation(),
                  ),
                );
              }
            }
          },
          verificationFailed: (FirebaseAuthException e) {
            setState(() {
              _isLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  e.message ?? 'Erreur de vérification du téléphone',
                ),
                backgroundColor: DMColors.error,
              ),
            );
          },
          codeSent: (String verificationId, int? resendToken) {
            setState(() {
              _isLoading = false;
            });
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => SmsCodeScreenLogin(
                      verificationId: verificationId,
                      phoneNumber: _phoneNumber!,
                    ),
              ),
            );
          },
          codeAutoRetrievalTimeout: (String verificationId) {},
          timeout: const Duration(seconds: 60),
        );
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Une erreur s\'est produite: $e'),
            backgroundColor: DMColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _isDarkMode(context);

    return Scaffold(
      backgroundColor: isDark ? DMColors.black : DMColors.white,
      appBar: AppBar(
        backgroundColor: isDark ? DMColors.black : DMColors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Iconsax.arrow_left,
            color: isDark ? Colors.white : Colors.black,
          ),
          onPressed: _isLoading ? null : () => Navigator.pop(context),
        ),
        title: Text(
          'Connexion par téléphone',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: DMSpacingStyle.paddingWithAppBarHeight,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête avec icône
                Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: DMColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Iconsax.call,
                          size: 48,
                          color: DMColors.primary,
                        ),
                      ),
                      const SizedBox(height: DMSizes.spaceBtwItems),
                      Text(
                        "Entrez votre numéro",
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: DMSizes.sm),
                      Text(
                        "Nous vous enverrons un code de vérification par SMS",
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color:
                              isDark
                                  ? DMColors.textWhite.withOpacity(0.8)
                                  : DMColors.black.withOpacity(0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: DMSizes.spaceBtwSections * 2),

                // Champ numéro de téléphone
                IntlPhoneField(
                  controller: _phoneController,
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    labelText: 'Numéro de téléphone',
                    hintText: 'Entrez votre numéro',
                    prefixIcon: const Icon(Iconsax.call),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: DMColors.primary,
                        width: 2,
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
                ),

                const SizedBox(height: DMSizes.spaceBtwSections),

                // Bouton Envoyer le code
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _sendSmsCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DMColors.primary,
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
                                      isDark ? DMColors.black : Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Text("Envoi en cours..."),
                              ],
                            )
                            : const Text(
                              'Valider le numéro',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                  ),
                ),

                const SizedBox(height: DMSizes.spaceBtwItems),

                const SizedBox(height: DMSizes.spaceBtwSections),

                // Lien retour vers email
                Center(
                  child: TextButton.icon(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    icon: const Icon(Iconsax.message),
                    label: const Text('Utiliser l\'email à la place'),
                    style: TextButton.styleFrom(
                      foregroundColor: DMColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
