import 'package:flutter/material.dart';
import 'package:dm_shop/constants/colors.dart';
import 'package:dm_shop/constants/size.dart';
import 'package:dm_shop/themes/customs/elevated_button_theme.dart';
import 'package:dm_shop/themes/customs/text_field_theme.dart';
import 'package:dm_shop/themes/customs/text_theme.dart';
import 'package:dm_shop/constants/text_string.dart';
import 'package:iconsax/iconsax.dart';
import 'package:dm_shop/themes/customs/form_divider.dart';
import 'package:flutter/services.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:email_validator/email_validator.dart';
import 'package:dm_shop/screens/menu_navigation.dart'; // Ajouté
import 'package:shared_preferences/shared_preferences.dart'; // Ajouté

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
  bool _obscurePassword = true; // Ajouté pour la visibilité du mot de passe

  bool _isPhone = false;
  String? _phoneNumber;
  String? _email;

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
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        elevation: 0,
        title: Text(DMTexts.createAccount, style: appBarTextStyle),
        leading: IconButton(
          icon: Icon(
            Iconsax.arrow_left,
            color: isDark ? Colors.white : Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(DMSizes.defaultSpace),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Bienvenue sur DM Shop !",
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: DMSizes.sm),
              Text(
                "Rejoignez notre communauté et commencez à vendre ou acheter en toute simplicité !",
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
                decoration: InputDecoration(
                  labelText: DMTexts.firstName,
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
                decoration: InputDecoration(
                  labelText: DMTexts.lastName,
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
                  decoration: InputDecoration(
                    labelText: 'Numéro de téléphone',
                    prefixIcon: const Icon(Iconsax.call),
                    border: const OutlineInputBorder(),
                    suffixIcon: TextButton(
                      onPressed: () {
                        setState(() {
                          _isPhone = !_isPhone;
                          _phoneNoController.clear();
                        });
                      },
                      child: Text(
                        "Utiliser l'email",
                        style: TextStyle(color: DMColors.primary),
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
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Iconsax.message),
                    border: const OutlineInputBorder(),
                    suffixIcon: TextButton(
                      onPressed: () {
                        setState(() {
                          _isPhone = !_isPhone;
                          _emailController.clear();
                        });
                      },
                      child: Text(
                        "Utiliser le téléphone",
                        style: TextStyle(color: DMColors.primary),
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
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: DMTexts.password,
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
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      // Simuler l'inscription
                      String firstName = _firstNameController.text;
                      String lastName = _lastNameController.text;
                      String emailOrPhone =
                          _isPhone
                              ? _phoneNoController.text
                              : _emailController.text;
                      String password = _passwordController.text;

                      print('Prénom: $firstName');
                      print('Nom: $lastName');
                      print(
                        _isPhone
                            ? 'Téléphone: $emailOrPhone'
                            : 'Email: $emailOrPhone',
                      );
                      print('Mot de passe: $password');

                      // Simuler une connexion réussie en enregistrant l'état
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('isLoggedIn', true);

                      // Naviguer directement vers MenuNavigation
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
                  style: DMElevatedButtonTheme.lightElevatedButtonTheme.style,
                  child: Text(DMTexts.createAccount),
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
              const SizedBox(height: DMSizes.spaceBtwItems),
              // Déjà un compte
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: "Vous avez déjà un compte? ",
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        TextSpan(
                          text: DMTexts.signIn,
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(
                            color: DMColors.primary,
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
