// Fichier: auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

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

  Future<String?> signInWithPhoneAndPassword({
    required String telephone,
    required String password,
  }) async {
    try {
      final users = FirebaseFirestore.instance.collection('users');

      // Rechercher l'utilisateur avec le téléphone (assurez-vous que le champ est 'phone' ou 'telephone' dans Firestore)
      // Ici, j'utilise 'phone' pour rester cohérent avec votre utilisation précédente dans signUpWithPhoneAndPassword.
      final querySnapshot =
          await users.where('phone', isEqualTo: telephone).get();

      if (querySnapshot.docs.isEmpty) {
        return 'Aucun compte trouvé pour ce numéro.';
      }

      final userData = querySnapshot.docs.first.data();
      final storedHashedPassword = userData['password'];

      // Hasher le mot de passe entré
      final hashedInput = sha256.convert(utf8.encode(password)).toString();

      if (hashedInput != storedHashedPassword) {
        return 'Mot de passe incorrect.';
      }

      // Connexion réussie (pas de connexion Firebase Auth ici, juste validation)
      return null;
    } catch (e) {
      return 'Erreur de connexion : $e';
    }
  }

  // Ancienne méthode signUpWithPhoneAndPassword renommée et modifiée
  // Elle ne fait plus que valider l'unicité du téléphone.
  Future<String?> validatePhoneSignUp({required String telephone}) async {
    try {
      final users = FirebaseFirestore.instance.collection('users');

      // Vérifie si le téléphone est déjà utilisé
      final existingUser =
          await users.where('phone', isEqualTo: telephone).get();
      if (existingUser.docs.isNotEmpty) {
        return 'Numéro déjà utilisé.';
      }

      return null; // Succès: le numéro est unique
    } catch (e) {
      return 'Erreur lors de la validation du numéro : $e';
    }
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
    required String displayName,
  }) async {
    final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    await userCredential.user?.updateDisplayName(displayName);

    return userCredential;
  }

  // Sign Out
  Future<void> signOut() {
    return _firebaseAuth.signOut();
  }

  // Phone Number Authentication (méthodes liées à l'OTP, inchangées)
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
}
