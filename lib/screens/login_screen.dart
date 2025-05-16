import 'package:flutter/material.dart';
import 'package:dm_shop/constants/size.dart';
import 'package:dm_shop/constants/text_string.dart';
import 'package:iconsax/iconsax.dart';
import 'package:email_validator/email_validator.dart';
import 'package:dm_shop/themes/customs/spacing_style.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:flutter/services.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        elevation: 0,
        title: Text(
          'Se connecter',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: Icon(Iconsax.arrow_left, color: Colors.white),
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: Stack(
        children: [
          Padding(
            padding: DMSpacingStyle.paddingWithAppBarHeight,
            child: Column(
              children: [
                // Logo, Title & Sub-Title
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DMTexts.loginTitle,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: DMSizes.sm),
                    Text(
                      DMTexts.loginSubTitle,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),

                // Form
                Form(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: DMSizes.spaceBtwSections,
                    ),
                    child: Column(
                      children: [
                        // Email or Phone
                        const LoginField(),

                        const SizedBox(height: DMSizes.spaceBtwInputFields),

                        // Password
                        TextFormField(
                          obscureText: true,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Iconsax.password_check),
                            labelText: DMTexts.password,
                            suffixIcon: Icon(Iconsax.eye_slash),
                          ),
                        ),
                        const SizedBox(height: DMSizes.spaceBtwItems / 2),

                        // Remember Me & Forget Password
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Remember Me
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

                            // Forget Password
                            TextButton(
                              onPressed: () {},
                              child: const Text(DMTexts.forgetPassword),
                            ),
                          ],
                        ),
                        const SizedBox(height: DMSizes.spaceBtwSections / 2),

                        // Sign In Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {},
                            child: const Text(DMTexts.signIn),
                          ),
                        ),
                        const SizedBox(height: DMSizes.spaceBtwSections / 2),

                        // Create Account Button
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () {},
                            child: const Text(DMTexts.createAccount),
                          ),
                        ),

                        const SizedBox(height: DMSizes.spaceBtwSections),

                        // Divider
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          child: Row(
                            children: [
                              Expanded(child: Divider()),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8.0),
                                child: Text('se connecter avec'),
                              ),
                              Expanded(child: Divider()),
                            ],
                          ),
                        ),

                        // Social Login Buttons
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class LoginField extends StatefulWidget {
  const LoginField({super.key});

  @override
  State<LoginField> createState() => _LoginFieldState();
}

class _LoginFieldState extends State<LoginField> {
  final TextEditingController _controller = TextEditingController();
  bool _isPhone = false;
  String? _phoneNumber;
  String? _email;

  // Fonction pour détecter si c'est un numéro ou un email
  void _detectInputType(String value) {
    if (value.isEmpty) return;

    // Si la première saisie est un chiffre, il s'agit probablement d'un numéro
    if (RegExp(r'^[0-9]').hasMatch(value)) {
      setState(() {
        _isPhone = true; // Change vers téléphone
      });
    }
    // Si l'entrée contient un '@', c'est probablement un email
    else if (value.contains('@')) {
      setState(() {
        _isPhone = false; // Change vers email
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      _detectInputType(_controller.text);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Champ dynamique (email ou téléphone)
        _isPhone
            ? IntlPhoneField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Numéro de téléphone',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Iconsax.call),
              ),
              initialCountryCode: 'NE', // Niger par défaut
              onChanged: (phone) {
                setState(() {
                  _phoneNumber = phone.completeNumber;
                });
              },
            )
            : TextFormField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Iconsax.message),
                border: OutlineInputBorder(),
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
      ],
    );
  }
}
