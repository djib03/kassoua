import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthController extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;
  bool _isLoading = false;
  String? _verificationId;

  // Getters
  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  String? get verificationId => _verificationId;

  AuthController() {
    // Écouter les changements d'état d'authentification
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      notifyListeners();
    });

    // Vérifier si l'utilisateur est déjà connecté
    _checkAuthState();
  }

  // Vérifier l'état d'authentification au démarrage
  Future<void> _checkAuthState() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

      if (isLoggedIn && _auth.currentUser != null) {
        _user = _auth.currentUser;
      }
    } catch (e) {
      print(
        'Erreur lors de la vérification de l\'état d\'authentification: $e',
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Connexion avec email et mot de passe
  Future<bool> signInWithEmail(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        _user = credential.user;
        await _saveLoginState(true);
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      notifyListeners();
      throw _handleAuthException(e);
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw 'Une erreur inattendue s\'est produite';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // Inscription avec email et mot de passe
  Future<bool> signUpWithEmail(
    String email,
    String password, {
    String? displayName,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Mettre à jour le nom d'affichage si fourni
        if (displayName != null) {
          await credential.user!.updateDisplayName(displayName);
        }

        _user = credential.user;
        await _saveLoginState(true);
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      notifyListeners();
      throw _handleAuthException(e);
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw 'Une erreur inattendue s\'est produite';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // Vérification du numéro de téléphone
  Future<void> verifyPhoneNumber(String phoneNumber) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-vérification (sur Android uniquement)
          await _signInWithPhoneCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          _isLoading = false;
          notifyListeners();
          throw _handleAuthException(e);
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          _isLoading = false;
          notifyListeners();
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw 'Erreur lors de la vérification du numéro de téléphone';
    }
  }

  // Connexion avec le code SMS
  Future<bool> signInWithSmsCode(String smsCode) async {
    if (_verificationId == null) {
      throw 'ID de vérification manquant';
    }

    _isLoading = true;
    notifyListeners();

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: smsCode,
      );

      return await _signInWithPhoneCredential(credential);
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      notifyListeners();
      throw _handleAuthException(e);
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw 'Code SMS invalide';
    }
  }

  // Connexion avec les identifiants de téléphone
  Future<bool> _signInWithPhoneCredential(
    PhoneAuthCredential credential,
  ) async {
    try {
      final userCredential = await _auth.signInWithCredential(credential);

      if (userCredential.user != null) {
        _user = userCredential.user;
        await _saveLoginState(true);
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // Réinitialisation du mot de passe
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Erreur lors de l\'envoi de l\'email de réinitialisation';
    }
  }

  // Déconnexion
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _user = null;
      await _saveLoginState(false);
      _verificationId = null;
      notifyListeners();
    } catch (e) {
      throw 'Erreur lors de la déconnexion';
    }
  }

  // Sauvegarder l'état de connexion
  Future<void> _saveLoginState(bool isLoggedIn) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', isLoggedIn);
  }

  // Gestion des exceptions Firebase Auth
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Aucun utilisateur trouvé avec cet email';
      case 'wrong-password':
        return 'Mot de passe incorrect';
      case 'email-already-in-use':
        return 'Cet email est déjà utilisé';
      case 'weak-password':
        return 'Le mot de passe est trop faible';
      case 'invalid-email':
        return 'Format d\'email invalide';
      case 'user-disabled':
        return 'Ce compte a été désactivé';
      case 'too-many-requests':
        return 'Trop de tentatives. Réessayez plus tard';
      case 'invalid-phone-number':
        return 'Numéro de téléphone invalide';
      case 'quota-exceeded':
        return 'Quota de SMS dépassé';
      case 'invalid-verification-code':
        return 'Code de vérification invalide';
      case 'invalid-verification-id':
        return 'ID de vérification invalide';
      default:
        return e.message ?? 'Une erreur s\'est produite';
    }
  }

  // Réenvoyer le code SMS
  Future<void> resendSmsCode(String phoneNumber) async {
    await verifyPhoneNumber(phoneNumber);
  }

  // Mettre à jour le profil utilisateur
  Future<void> updateUserProfile({
    String? displayName,
    String? photoURL,
  }) async {
    if (_user != null) {
      try {
        await _user!.updateDisplayName(displayName);
        if (photoURL != null) {
          await _user!.updatePhotoURL(photoURL);
        }
        await _user!.reload();
        _user = _auth.currentUser;
        notifyListeners();
      } catch (e) {
        throw 'Erreur lors de la mise à jour du profil';
      }
    }
  }

  // Vérifier si l'email est vérifié
  bool get isEmailVerified => _user?.emailVerified ?? false;

  // Envoyer un email de vérification
  Future<void> sendEmailVerification() async {
    if (_user != null && !_user!.emailVerified) {
      try {
        await _user!.sendEmailVerification();
      } catch (e) {
        throw 'Erreur lors de l\'envoi de l\'email de vérification';
      }
    }
  }
}
