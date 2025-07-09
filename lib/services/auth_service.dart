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
    required String phone,
    required String password,
  }) async {
    try {
      final users = FirebaseFirestore.instance.collection('users');

      // Rechercher l'utilisateur avec le téléphone
      final querySnapshot = await users.where('phone', isEqualTo: phone).get();

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

  //methode pour creer un compte avec numero
  Future<String?> signUpWithPhoneAndPassword({
    required String phone,
    required String password,
    required String prenom,
    required String nom,
  }) async {
    try {
      final users = FirebaseFirestore.instance.collection('users');

      // Vérifie si le téléphone est déjà utilisé
      final existingUser = await users.where('phone', isEqualTo: phone).get();
      if (existingUser.docs.isNotEmpty) {
        return 'Numéro déjà utilisé.';
      }

      // Hashage du mot de passe
      final hashedPassword = sha256.convert(utf8.encode(password)).toString();

      // Création du compte dans Firestore
      await users.add({
        'phone': phone,
        'password': hashedPassword,
        'prenom': prenom,
        'nom': nom,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return null; // success
    } catch (e) {
      return 'Erreur lors de l\'inscription : $e';
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
