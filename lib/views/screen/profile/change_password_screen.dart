import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart'; // Pour les icônes
import 'package:provider/provider.dart';
import 'package:kassoua/constants/colors.dart';
import 'package:kassoua/controllers/auth_controller.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({Key? key}) : super(key: key);

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isOldPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _changePassword() async {
    if (_formKey.currentState!.validate()) {
      final authController = Provider.of<AuthController>(
        context,
        listen: false,
      );

      String oldPassword = _oldPasswordController.text;
      String newPassword = _newPasswordController.text;

      try {
        // Utiliser le service d'authentification pour changer le mot de passe
        final String? error = await authController.changePassword(
          currentPassword: oldPassword,
          newPassword: newPassword,
        );

        if (error != null) {
          // Afficher l'erreur
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error), backgroundColor: AppColors.grey),
          );
        } else {
          // Succès
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Mot de passe changé avec succès !'),
              backgroundColor: AppColors.primary,
            ),
          );

          // Effacer les champs après succès
          _oldPasswordController.clear();
          _newPasswordController.clear();
          _confirmPasswordController.clear();

          // Revenir à la page précédente après succès
          Navigator.pop(context);
        }
      } catch (e) {
        // Gérer les erreurs inattendues
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Une erreur inattendue s\'est produite : $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    required bool isVisible,
    required VoidCallback toggleVisibility,
  }) {
    final Brightness brightness = Theme.of(context).brightness;
    final Color fillColor =
        brightness == Brightness.dark ? Colors.grey[800]! : Colors.grey[100]!;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        obscureText: !isVisible,
        decoration: InputDecoration(
          labelText: labelText,
          prefixIcon: Icon(icon),
          suffixIcon: IconButton(
            icon: Icon(isVisible ? Iconsax.eye : Iconsax.eye_slash),
            onPressed: toggleVisibility,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: fillColor,
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Veuillez entrer votre $labelText';
          }
          if (labelText == 'Nouveau mot de passe' && value.length < 6) {
            return 'Le mot de passe doit contenir au moins 6 caractères';
          }
          if (labelText == 'Confirmer le nouveau mot de passe' &&
              value != _newPasswordController.text) {
            return 'Les mots de passe ne correspondent pas';
          }
          return null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Brightness brightness = Theme.of(context).brightness;
    final Color backgroundColor =
        brightness == Brightness.dark
            ? Theme.of(context).colorScheme.surface
            : Colors.white;
    final Color textColor =
        brightness == Brightness.dark ? Colors.white : Colors.black;
    final Color cardColor =
        brightness == Brightness.dark ? Colors.grey[900]! : Colors.white;
    final Color shadowColor =
        brightness == Brightness.dark
            ? Colors.transparent
            : Colors.grey.withOpacity(0.2);

    return Consumer<AuthController>(
      builder: (context, authController, child) {
        return Scaffold(
          backgroundColor: backgroundColor,
          appBar: AppBar(
            title: Text(
              'Changer le mot de passe',
              style: TextStyle(color: textColor),
            ),
            backgroundColor: backgroundColor,
            elevation: 0,
            iconTheme: IconThemeData(color: textColor),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: cardColor,
                      boxShadow: [
                        BoxShadow(
                          color: shadowColor,
                          blurRadius: 20,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mettez à jour votre mot de passe',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildPasswordField(
                          controller: _oldPasswordController,
                          labelText: 'Ancien mot de passe',
                          icon: Iconsax.key,
                          isVisible: _isOldPasswordVisible,
                          toggleVisibility: () {
                            setState(() {
                              _isOldPasswordVisible = !_isOldPasswordVisible;
                            });
                          },
                        ),
                        _buildPasswordField(
                          controller: _newPasswordController,
                          labelText: 'Nouveau mot de passe',
                          icon: Iconsax.lock,
                          isVisible: _isNewPasswordVisible,
                          toggleVisibility: () {
                            setState(() {
                              _isNewPasswordVisible = !_isNewPasswordVisible;
                            });
                          },
                        ),
                        _buildPasswordField(
                          controller: _confirmPasswordController,
                          labelText: 'Confirmer le nouveau mot de passe',
                          icon: Iconsax.lock,
                          isVisible: _isConfirmPasswordVisible,
                          toggleVisibility: () {
                            setState(() {
                              _isConfirmPasswordVisible =
                                  !_isConfirmPasswordVisible;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          authController.isLoading ? null : _changePassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child:
                          authController.isLoading
                              ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                              : const Text(
                                'Changer le mot de passe',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                ),
                              ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
