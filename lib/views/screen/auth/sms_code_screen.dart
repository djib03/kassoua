import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kassoua/models/user.dart';
import 'package:kassoua/constants/colors.dart';
import 'package:iconsax/iconsax.dart';

class SmsCodeScreen extends StatefulWidget {
  final String verificationId;
  final String phoneNumber;
  final String nom; // <-- Ajouté
  final String prenom; // <-- Ajouté

  const SmsCodeScreen({
    super.key,
    required this.verificationId,
    required this.phoneNumber,
    required this.nom, // <-- Ajouté
    required this.prenom, // <-- Ajouté
  });

  @override
  State<SmsCodeScreen> createState() => _SmsCodeScreenState();
}

class _SmsCodeScreenState extends State<SmsCodeScreen>
    with TickerProviderStateMixin {
  final int codeLength = 6;
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isLoading = false;
  bool _isCodeComplete = false;
  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();

    // Auto-focus le premier champ
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    _shakeController.dispose();
    super.dispose();
  }

  String get _smsCode => _controllers.map((c) => c.text).join();

  Future<void> _verifyCode() async {
    if (_smsCode.length != codeLength) {
      _shakeFields();
      _showErrorSnackBar("Veuillez saisir le code complet.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: _smsCode,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);

      // Après la connexion réussie
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Récupère les infos nécessaires (nom, prénom, etc.)
        // Tu dois les passer à SmsCodeScreen via le constructeur ou Provider !
        final utilisateur = Utilisateur(
          id: user.uid,
          nom: widget.nom, // <-- à passer en paramètre
          prenom: widget.prenom, // <-- à passer en paramètre
          email: '', // Pas d'email pour inscription par téléphone
          telephone: user.phoneNumber ?? widget.phoneNumber,
          dateInscription: DateTime.now(),
        );
        await FirebaseFirestore.instance
            .collection('users')
            .doc(utilisateur.id)
            .set(utilisateur.toMap());
      }

      // Animation de succès
      _showSuccessSnackBar("Code vérifié avec succès !");
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } on FirebaseAuthException catch (e) {
      _shakeFields();
      _clearFields();
      _showErrorSnackBar(e.message ?? "Code invalide");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _shakeFields() {
    _shakeController.forward().then((_) {
      _shakeController.reverse();
    });
  }

  void _clearFields() {
    for (final controller in _controllers) {
      controller.clear();
    }
    _focusNodes[0].requestFocus();
    setState(() {
      _isCodeComplete = false;
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildOtpFields() {
    return Form(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(codeLength, (index) {
          return SizedBox(
            height: 68,
            width: 48,
            child: TextFormField(
              controller: _controllers[index],
              onChanged: (value) {
                if (value.length == 1 && index < codeLength - 1) {
                  FocusScope.of(context).nextFocus();
                }
                if (value.isEmpty && index > 0) {
                  FocusScope.of(context).previousFocus();
                }
                setState(() {
                  _isCodeComplete = _controllers.every(
                    (c) => c.text.isNotEmpty,
                  );
                });
              },
              style: Theme.of(context).textTheme.headlineLarge,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              inputFormatters: [
                LengthLimitingTextInputFormatter(1),
                FilteringTextInputFormatter.digitsOnly,
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.sms_outlined,
            size: 48,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          "Vérification SMS",
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
            children: [
              const TextSpan(
                text: "Nous avons envoyé un code à 6 chiffres au\n",
              ),
              TextSpan(
                text: widget.phoneNumber,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Center(
      child: SizedBox(
        width: 100, // Largeur réduite
        height: 60, // Hauteur réduite
        child: ElevatedButton(
          onPressed: _isLoading || !_isCodeComplete ? null : _verifyCode,
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: _isCodeComplete ? 2 : 0,
          ),
          child:
              _isLoading
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                  : const Text(
                    "Valider",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(codeLength, (index) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 8,
              height: 4,
              decoration: BoxDecoration(
                color:
                    index < _smsCode.length
                        ? Theme.of(context).primaryColor
                        : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Text(
          "${_smsCode.length}/$codeLength",
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade500),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),
              _buildHeader(),
              const SizedBox(height: 48),
              _buildOtpFields(),
              const SizedBox(height: 16), // Moins d'espace
              _buildActionButtons(), // <-- déplacé ici
              const SizedBox(height: 24),
              _buildProgressIndicator(),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
