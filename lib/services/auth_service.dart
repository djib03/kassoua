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

      // Rechercher l'utilisateur avec le téléphone (utiliser 'telephone' pour être cohérent)
      final querySnapshot =
          await users.where('telephone', isEqualTo: telephone).get();

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

      // Connexion réussie
      return null;
    } catch (e) {
      return 'Erreur de connexion : $e';
    }
  }

  // Changer le mot de passe pour les utilisateurs avec authentification téléphone
  Future<String?> changePhonePassword({
    required String telephone,
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final users = FirebaseFirestore.instance.collection('users');

      // Rechercher l'utilisateur avec le téléphone
      final querySnapshot =
          await users.where('telephone', isEqualTo: telephone).get();

      if (querySnapshot.docs.isEmpty) {
        return 'Aucun compte trouvé pour ce numéro.';
      }

      final userDoc = querySnapshot.docs.first;
      final userData = userDoc.data();
      final storedHashedPassword = userData['password'];

      // Vérifier l'ancien mot de passe
      final hashedCurrentPassword =
          sha256.convert(utf8.encode(currentPassword)).toString();

      if (hashedCurrentPassword != storedHashedPassword) {
        return 'Mot de passe actuel incorrect.';
      }

      // Hasher le nouveau mot de passe
      final hashedNewPassword =
          sha256.convert(utf8.encode(newPassword)).toString();

      // Mettre à jour le mot de passe dans Firestore
      await userDoc.reference.update({
        'password': hashedNewPassword,
        'dateModificationMotDePasse': FieldValue.serverTimestamp(),
      });

      return null; // Succès
    } catch (e) {
      return 'Erreur lors du changement de mot de passe : $e';
    }
  }

  // Changer le mot de passe pour les utilisateurs Firebase Auth
  Future<String?> changeFirebasePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        return 'Aucun utilisateur connecté.';
      }

      // Ré-authentifier l'utilisateur avec son mot de passe actuel
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);

      // Changer le mot de passe
      await user.updatePassword(newPassword);

      return null; // Succès
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'wrong-password':
          return 'Mot de passe actuel incorrect.';
        case 'weak-password':
          return 'Le nouveau mot de passe est trop faible.';
        case 'requires-recent-login':
          return 'Veuillez vous reconnecter pour effectuer cette action.';
        default:
          return 'Erreur lors du changement de mot de passe : ${e.message}';
      }
    } catch (e) {
      return 'Erreur lors du changement de mot de passe : $e';
    }
  }

  // Valider l'unicité du numéro de téléphone pour l'inscription
  Future<String?> validatePhoneSignUp({required String telephone}) async {
    try {
      final users = FirebaseFirestore.instance.collection('users');

      // Vérifier si le téléphone est déjà utilisé (utiliser 'telephone' pour être cohérent)
      final existingUser =
          await users.where('telephone', isEqualTo: telephone).get();

      if (existingUser.docs.isNotEmpty) {
        return 'Ce numéro de téléphone est déjà utilisé.';
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

  // Phone Number Authentication (méthodes liées à l'OTP)
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
