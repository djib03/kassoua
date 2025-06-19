import 'package:kassoua/screens/menu_navigation.dart';
import 'package:flutter/material.dart';
import 'package:kassoua/constants/size.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kassoua/constants/text_string.dart';
import 'package:email_validator/email_validator.dart';
import 'package:kassoua/themes/customs/spacing_style.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:flutter/services.dart';
import 'package:kassoua/screens/signup_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kassoua/themes/customs/form_divider.dart';
import 'package:kassoua/constants/colors.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Ajouté

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();
  bool _isPhone = false;
  String? _phoneNumber;
  String? _email;
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? DMColors.black : DMColors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        elevation: 0,
        title: Text(
          'Se connecter',
          style: Theme.of(context).textTheme.headlineSmall,
        ),

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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Heureux de vous retrouver sur DM Shop !",
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: DMSizes.sm),
                    Text(
                      "Connecter avec votre numéro de téléphone ou email",
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
                const SizedBox(height: DMSizes.spaceBtwSections),
                if (_isPhone)
                  IntlPhoneField(
                    controller: _controller,
                    decoration: InputDecoration(
                      labelText: 'Numéro de téléphone',
                      prefixIcon: const Icon(Iconsax.call),
                      border: const OutlineInputBorder(),
                      suffixIcon: TextButton(
                        onPressed: () {
                          setState(() {
                            _isPhone = !_isPhone;
                            _controller.clear();
                          });
                        },
                        child: Text(
                          "Utiliser l'email",
                          style: TextStyle(color: DMColors.buttonPrimary),
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
                    controller: _controller,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Iconsax.message),
                      border: const OutlineInputBorder(),
                      suffixIcon: TextButton(
                        onPressed: () {
                          setState(() {
                            _isPhone = !_isPhone;
                            _controller.clear();
                          });
                        },
                        child: Text(
                          "Utiliser le téléphone",
                          style: TextStyle(color: DMColors.buttonPrimary),
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
                TextFormField(
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Mot de passe',
                    prefixIcon: const Icon(Iconsax.password_check),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Iconsax.eye_slash : Iconsax.eye,
                      ),
                      onPressed: () {
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
                          Checkbox(value: true, onChanged: (value) {}),
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
                      onPressed: () {},
                      child: const Text(
                        'Mot de passe oublié ?',
                        style: TextStyle(color: DMColors.buttonPrimary),
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
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            // Simuler une connexion réussie
                            print(
                              _isPhone
                                  ? 'Téléphone: $_phoneNumber'
                                  : 'Email: $_email',
                            );
                            print('Mot de passe: ${_controller.text}');

                            // Enregistrer l'état de connexion
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setBool('isLoggedIn', true);

                            // Naviguer vers MenuNavigation
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
                        child: const Text('Se connecter'),
                      ),
                    ),
                    const SizedBox(height: DMSizes.spaceBtwItems),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SignUpScreen(),
                            ),
                          );
                        },
                        child: const Text('Créer un compte'),
                      ),
                    ),
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
                        onPressed: () {},
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
