import 'package:flutter/material.dart';
import 'package:dm_shop/constants/colors.dart';
import 'package:dm_shop/constants/size.dart';

import 'package:dm_shop/themes/customs/elevated_button_theme.dart';
import 'package:dm_shop/themes/customs/text_field_theme.dart';
import 'package:dm_shop/themes/customs/text_theme.dart';

class SignUpScreen extends StatelessWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: DMSizes.iconSm),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(DMSizes.defaultSpace),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre
            Text(
              "Créer un compte",
              style: TTextTheme.lightTextTheme.headlineMedium,
            ),
            const SizedBox(height: DMSizes.sm),

            Text(
              "Remplissez vos informations pour continuer",
              style: TTextTheme.lightTextTheme.bodyMedium?.copyWith(
                color: DMColors.textSecondary,
              ),
            ),
            const SizedBox(height: DMSizes.spaceBtwSections),

            // Formulaire
            Form(
              child: Column(
                children: [
                  // Nom Complet
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: "Nom Complet",
                      prefixIcon: const Icon(Icons.person_outline),
                      border:
                          TTextFormFieldTheme.lightInputDecorationTheme.border,
                      enabledBorder:
                          TTextFormFieldTheme
                              .lightInputDecorationTheme
                              .enabledBorder,
                      focusedBorder:
                          TTextFormFieldTheme
                              .lightInputDecorationTheme
                              .focusedBorder,
                      errorBorder:
                          TTextFormFieldTheme
                              .lightInputDecorationTheme
                              .errorBorder,
                      contentPadding:
                          TTextFormFieldTheme
                              .lightInputDecorationTheme
                              .contentPadding,
                    ),
                  ),
                  const SizedBox(height: DMSizes.spaceBtwInputFields),

                  // Email
                  TextFormField(
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: "Email",
                      prefixIcon: const Icon(Icons.email_outlined),
                      border:
                          TTextFormFieldTheme.lightInputDecorationTheme.border,
                      enabledBorder:
                          TTextFormFieldTheme
                              .lightInputDecorationTheme
                              .enabledBorder,
                      focusedBorder:
                          TTextFormFieldTheme
                              .lightInputDecorationTheme
                              .focusedBorder,
                      errorBorder:
                          TTextFormFieldTheme
                              .lightInputDecorationTheme
                              .errorBorder,
                      contentPadding:
                          TTextFormFieldTheme
                              .lightInputDecorationTheme
                              .contentPadding,
                    ),
                  ),
                  const SizedBox(height: DMSizes.spaceBtwInputFields),

                  // Téléphone
                  TextFormField(
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: "Numéro de téléphone",
                      prefixIcon: const Icon(Icons.phone_outlined),
                      border:
                          TTextFormFieldTheme.lightInputDecorationTheme.border,
                      enabledBorder:
                          TTextFormFieldTheme
                              .lightInputDecorationTheme
                              .enabledBorder,
                      focusedBorder:
                          TTextFormFieldTheme
                              .lightInputDecorationTheme
                              .focusedBorder,
                      errorBorder:
                          TTextFormFieldTheme
                              .lightInputDecorationTheme
                              .errorBorder,
                      contentPadding:
                          TTextFormFieldTheme
                              .lightInputDecorationTheme
                              .contentPadding,
                    ),
                  ),
                  const SizedBox(height: DMSizes.spaceBtwInputFields),

                  // Mot de passe
                  TextFormField(
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: "Mot de passe",
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: const Icon(Icons.remove_red_eye_outlined),
                      border:
                          TTextFormFieldTheme.lightInputDecorationTheme.border,
                      enabledBorder:
                          TTextFormFieldTheme
                              .lightInputDecorationTheme
                              .enabledBorder,
                      focusedBorder:
                          TTextFormFieldTheme
                              .lightInputDecorationTheme
                              .focusedBorder,
                      errorBorder:
                          TTextFormFieldTheme
                              .lightInputDecorationTheme
                              .errorBorder,
                      contentPadding:
                          TTextFormFieldTheme
                              .lightInputDecorationTheme
                              .contentPadding,
                    ),
                  ),
                  const SizedBox(height: DMSizes.spaceBtwInputFields),

                  // Confirmation mot de passe
                  TextFormField(
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: "Confirmer le mot de passe",
                      prefixIcon: const Icon(Icons.lock_outline),
                      border:
                          TTextFormFieldTheme.lightInputDecorationTheme.border,
                      enabledBorder:
                          TTextFormFieldTheme
                              .lightInputDecorationTheme
                              .enabledBorder,
                      focusedBorder:
                          TTextFormFieldTheme
                              .lightInputDecorationTheme
                              .focusedBorder,
                      errorBorder:
                          TTextFormFieldTheme
                              .lightInputDecorationTheme
                              .errorBorder,
                      contentPadding:
                          TTextFormFieldTheme
                              .lightInputDecorationTheme
                              .contentPadding,
                    ),
                  ),
                  const SizedBox(height: DMSizes.spaceBtwSections),

                  // Checkbox Conditions
                  Row(
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(value: true, onChanged: (value) {}),
                      ),
                      const SizedBox(width: DMSizes.sm),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: "J'accepte les ",
                                style: TTextTheme.lightTextTheme.bodySmall,
                              ),
                              TextSpan(
                                text: "conditions d'utilisation ",
                                style: TTextTheme.lightTextTheme.bodySmall
                                    ?.copyWith(
                                      color: DMColors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              TextSpan(
                                text: "et la ",
                                style: TTextTheme.lightTextTheme.bodySmall,
                              ),
                              TextSpan(
                                text: "politique de confidentialité",
                                style: TTextTheme.lightTextTheme.bodySmall
                                    ?.copyWith(
                                      color: DMColors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: DMSizes.spaceBtwSections),

                  // Bouton d'inscription
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {},
                      style:
                          DMElevatedButtonTheme.lightElevatedButtonTheme.style,
                      child: const Text("S'inscrire"),
                    ),
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
                              style: TTextTheme.lightTextTheme.bodyMedium,
                            ),
                            TextSpan(
                              text: "Connectez-vous",
                              style: TTextTheme.lightTextTheme.bodyMedium
                                  ?.copyWith(
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
          ],
        ),
      ),
    );
  }
}
