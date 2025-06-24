import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  User? get currentUser => _firebaseAuth.currentUser;
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // Email & Password Sign In
  Future<UserCredential> signInWithEmail(String email, String password) {
    return _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // Delete current user account
  Future<void> deleteAccount() async {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      await user.delete();
    }
  }

  // Email & Password Sign Up
  Future<UserCredential> signUpWithEmail(
    String email,
    String password, {
    required String displayName, // Ajout du nom complet
  }) async {
    final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Mettre à jour le nom d'affichage
    await userCredential.user?.updateDisplayName(displayName);

    return userCredential;
  }

  // Sign Out
  Future<void> signOut() {
    return _firebaseAuth.signOut();
  }

  // Phone Number Authentication
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(PhoneAuthCredential) onVerificationCompleted,
    required Function(FirebaseAuthException) onVerificationFailed,
    required Function(String, int?) onCodeSent,
    required Function(String) onCodeAutoRetrievalTimeout,
  }) async {
    await _firebaseAuth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: onVerificationCompleted,
      verificationFailed: onVerificationFailed,
      codeSent: onCodeSent,
      codeAutoRetrievalTimeout: onCodeAutoRetrievalTimeout,
    );
  }

  // Sign in with SMS code
  Future<UserCredential> signInWithSmsCode(
    String verificationId,
    String smsCode,
  ) {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    return _firebaseAuth.signInWithCredential(credential);
  }

  // Démarre le processus d’authentification avec le numéro
  Future<void> loginWithPhoneNumber({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onError,
    required Function() onAutoVerified,
    required Function() onTimeout,
  }) async {
    try {
      await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _firebaseAuth.signInWithCredential(credential);
          onAutoVerified();
        },
        verificationFailed: (FirebaseAuthException e) {
          onError(e.message ?? "Erreur lors de la vérification");
        },
        codeSent: (String verificationId, int? resendToken) {
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          onTimeout();
        },
      );
    } catch (e) {
      onError(e.toString());
    }
  }

  // Vérifie le code OTP manuellement
  Future<void> verifyOtpCode({
    required String verificationId,
    required String smsCode,
    required Function(User user) onSuccess,
    required Function(String error) onError,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      final userCredential = await _firebaseAuth.signInWithCredential(
        credential,
      );

      final user = userCredential.user;
      if (user != null) {
        onSuccess(user);
      } else {
        onError("Utilisateur non trouvé");
      }
    } catch (e) {
      onError(e.toString());
    }
  }
}
