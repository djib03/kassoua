import 'package:flutter/material.dart';
import 'package:dm_shop/constants/size.dart';
import 'package:iconsax/iconsax.dart';
import 'package:dm_shop/constants/text_string.dart';
import 'package:email_validator/email_validator.dart';
import 'package:dm_shop/themes/customs/spacing_style.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:flutter/services.dart';
import 'package:dm_shop/screens/signup_screen.dart';
import 'package:dm_shop/themes/customs/form_divider.dart';
import 'package:dm_shop/screens/home_screen.dart';
import 'package:dm_shop/constants/colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();
  bool _isPhone = false;
  String? _phoneNumber;
  String? _email;
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        elevation: 0,
        title: Text(
          'Se connecter',
          style:
              Theme.of(
                context,
              ).textTheme.headlineSmall, // Corrected theme usage
        ),
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: Icon(
            Iconsax.arrow_left,
            color:
                Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
          ),
        ),
        actions: [
          // Add this
          TextButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => HomeScreen(),
                ), // Replace HomeScreen with your actual home screen widget
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
                // Logo, Title & Sub-Title
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

                // Champ dynamique (email ou téléphone)
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
                    initialCountryCode: 'NE', // Default country
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

                // Mot de passe
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
                      child: const Text(
                        'Mot de passe oublié ?',
                        style: TextStyle(color: DMColors.buttonPrimary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: DMSizes.spaceBtwSections / 2),

                // Boutons
                Column(
                  children: [
                    // Se connecter
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            // Authentifier l'utilisateur
                            print(
                              _isPhone
                                  ? 'Téléphone: $_phoneNumber'
                                  : 'Email: $_email',
                            );
                            print('Mot de passe: ${_controller.text}');
                          }
                        },
                        child: const Text('Se connecter'),
                      ),
                    ),
                    const SizedBox(height: DMSizes.spaceBtwItems),

                    // Créer un compte
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

                // Social Login
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
