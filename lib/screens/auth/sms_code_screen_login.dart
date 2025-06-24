import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kassoua/constants/colors.dart';
import 'package:kassoua/screens/homepage/menu_navigation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:iconsax/iconsax.dart';

class SmsCodeScreenLogin extends StatefulWidget {
  final String verificationId;
  final String phoneNumber;

  const SmsCodeScreenLogin({
    super.key,
    required this.verificationId,
    required this.phoneNumber,
  });

  @override
  State<SmsCodeScreenLogin> createState() => _SmsCodeScreenLoginState();
}

class _SmsCodeScreenLoginState extends State<SmsCodeScreenLogin>
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
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize shake animation
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Initialize scale animation for button
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );

    // Auto-focus first field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });

    // Listen to text changes
    for (int i = 0; i < _controllers.length; i++) {
      _controllers[i].addListener(_updateCodeCompleteStatus);
    }
  }

  void _updateCodeCompleteStatus() {
    final isComplete = _smsCode.length == codeLength;
    if (isComplete != _isCodeComplete) {
      setState(() {
        _isCodeComplete = isComplete;
      });
      if (isComplete) {
        _scaleController.forward().then((_) => _scaleController.reverse());
      }
    }
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
    _scaleController.dispose();
    super.dispose();
  }

  String get _smsCode => _controllers.map((c) => c.text).join();

  Future<void> _verifyCode(String smsCode, String verificationId) async {
    try {
      setState(() => _isLoading = true);
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential);
      if (userCredential.user != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('userId', userCredential.user!.uid);

        final userDoc = FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid);
        final docSnapshot = await userDoc.get();
        if (!docSnapshot.exists) {
          await userDoc.set({
            'nom': '',
            'prenom': '',
            'email': '',
            'telephone': widget.phoneNumber,
            'photoProfil': '',
            'dateInscription': FieldValue.serverTimestamp(),
          });
        }

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MenuNavigation()),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _shakeController.forward().then((_) => _shakeController.reverse());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: DMColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  Future<void> _resendCode() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: widget.phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await FirebaseAuth.instance.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          _showErrorSnackBar(e.message ?? "Erreur lors du renvoi du code.");
        },
        codeSent: (String verificationId, int? resendToken) {
          _showSuccessSnackBar("Nouveau code envoyé !");
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      _showErrorSnackBar("Impossible de renvoyer le code.");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
        backgroundColor: DMColors.error,
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
    return AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) {
        final shake = _shakeController.value;
        return Transform.translate(
          offset: Offset(shake * 10 * (shake > 0.5 ? (1 - shake) : shake), 0),
          child: Form(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(codeLength, (index) {
                return SizedBox(
                  height: 56,
                  width: 48,
                  child: TextFormField(
                    controller: _controllers[index],
                    focusNode: _focusNodes[index],
                    onChanged: (value) {
                      if (value.length == 1 && index < codeLength - 1) {
                        FocusScope.of(context).nextFocus();
                      }
                      if (value.isEmpty && index > 0) {
                        FocusScope.of(context).previousFocus();
                      }
                      _updateCodeCompleteStatus();
                    },
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(1),
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Theme.of(context).primaryColor,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.sms_outlined,
            size: 40,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          "Vérification SMS",
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        const SizedBox(height: 8),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade600,
              height: 1.5,
            ),
            children: [
              const TextSpan(text: "Entrez le code à 6 chiffres envoyé à\n"),
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
    return Column(
      children: [
        ScaleTransition(
          scale: _scaleAnimation,
          child: SizedBox(
            width: 200, // Reduced width
            height: 48,
            child: ElevatedButton(
              onPressed:
                  _isLoading || !_isCodeComplete
                      ? null
                      : () => _verifyCode(_smsCode, widget.verificationId),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: _isCodeComplete ? 3 : 0,
                backgroundColor:
                    _isCodeComplete
                        ? Theme.of(context).primaryColor
                        : Colors.grey.shade300,
                foregroundColor:
                    _isCodeComplete ? Colors.white : Colors.grey.shade600,
              ),
              child:
                  _isLoading
                      ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                      : const Text(
                        "Valider",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: _isLoading ? null : _resendCode,
          child: Text(
            "Renvoyer le code",
            style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(codeLength, (index) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color:
                index < _smsCode.length
                    ? Theme.of(context).primaryColor
                    : Colors.grey.shade300,
            shape: BoxShape.circle,
          ),
        );
      }),
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
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 32),
              _buildOtpFields(),
              const SizedBox(height: 16),
              _buildProgressIndicator(),
              const SizedBox(height: 24),
              _buildActionButtons(),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
