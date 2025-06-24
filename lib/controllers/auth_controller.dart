import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import 'package:kassoua/services/auth_service.dart';

class AuthController extends ChangeNotifier {
  final AuthService _authService;
  User? _user;
  bool _isLoading = false;

  bool get isLoading => _isLoading;
  User? get user => _user;

  AuthController({AuthService? authService})
    : _authService = authService ?? AuthService() {
    _authService.authStateChanges.listen((User? user) {
      _user = user;
      notifyListeners();
    });
    initialize();
  }

  // Initialisation
  Future<void> initialize() async {
    await _checkAuthState();
  }

  // Vérifier l'état d'authentification au démarrage
  Future<void> _checkAuthState() async {
    _isLoading = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      if (isLoggedIn && _authService.currentUser != null) {
        _user = _authService.currentUser;
      } else {
        _user = null;
        await _signOutLocally();
      }
    } catch (e) {
      _user = null;
      await _signOutLocally();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteAccount() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _authService.deleteAccount();
      await _signOutLocally();
    } catch (e) {
      // Gérer l'erreur si nécessaire
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Vérifie si l'utilisateur est connecté (asynchrone)
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedInPref = prefs.getBool('isLoggedIn') ?? false;
    return isLoggedInPref && _authService.currentUser != null;
  }

  // Vérifie si l'utilisateur est connecté (synchrone)
  bool get isLoggedInSync => _user != null && _authService.currentUser != null;

  // Déconnexion locale
  Future<void> _signOutLocally() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    await prefs.remove('userId');
    _user = null;
  }

  // Connexion
  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      final credential = await _authService.signInWithEmail(email, password);
      if (credential.user != null) {
        _user = credential.user;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('userId', _user!.uid);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Removed Flutter widget-specific code (initState, context, Provider, controllers) as it does not belong in AuthController.

  // Déconnexion
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _authService.signOut();
      await _signOutLocally();
    } catch (e) {
      // ignore
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Récupérer les données utilisateur Firestore
  Future<Utilisateur?> fetchUserData() async {
    if (!await isLoggedIn()) return null;
    try {
      final user = _authService.currentUser;
      if (user == null) return null;
      print('Fetch Firestore for uid: ${user.uid}');
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      if (!doc.exists) return null;
      return Utilisateur.fromMap(doc.data()!, doc.id);
    } catch (e) {
      return null;
    }
  }
}
