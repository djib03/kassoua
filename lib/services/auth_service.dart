import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  User? get currentUser => _firebaseAuth.currentUser;
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // Email & Password Sign In
  Future<UserCredential> signInWithEmail(String email, String password) {
    return _firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
  }

  // Email & Password Sign Up
  Future<UserCredential> signUpWithEmail(String email, String password) {
    return _firebaseAuth.createUserWithEmailAndPassword(email: email, password: password);
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
  Future<UserCredential> signInWithSmsCode(String verificationId, String smsCode) {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    return _firebaseAuth.signInWithCredential(credential);
  }
}