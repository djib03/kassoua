import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import 'package:kassoua/services/auth_service.dart';

class AuthController extends ChangeNotifier {
  final AuthService _authService;
  User? _user;
  Utilisateur? _userData; // Ajoutez cette ligne
  bool _isLoading = false;
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedInPref = prefs.getBool('isLoggedIn') ?? false;
    return isLoggedInPref && _authService.currentUser != null;
  }

  bool get isLoading => _isLoading;
  User? get user => _user;
  Utilisateur? get userData => _userData; // Ajoutez cette ligne

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
  /// Inscription avec numéro de téléphone et mot de passe
  /// Retourne un message d'erreur ou null si succès
  Future<String?> signUpWithPhone({
    required String phone,
    required String password,
    required String nom,
    required String prenom,
  }) async {
    return await _authService.signUpWithPhoneAndPassword(
      phone: phone,
      password: password,
      nom: nom,
      prenom: prenom,
    );
  }

  AuthController({AuthService? authService})
    : _authService = authService ?? AuthService() {
    _authService.authStateChanges.listen((User? user) {
      _user = user;
      // Si l'utilisateur se déconnecte, effacer les données
      if (user == null) {
        _userData = null;
      }
      notifyListeners();
    });
    initialize();
  }

  // Initialisation
  Future<void> initialize() async {
    await _checkAuthState();
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

        // Charger les données utilisateur immédiatement après connexion
        _userData = await _fetchUserDataInternal();

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

  Future<void> _checkAuthState() async {
    _isLoading = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      if (isLoggedIn && _authService.currentUser != null) {
        _user = _authService.currentUser;
        // Charger les données utilisateur si connecté
        _userData = await _fetchUserDataInternal();
      } else {
        _user = null;
        _userData = null;
        await _signOutLocally();
      }
    } catch (e) {
      _user = null;
      _userData = null;
      await _signOutLocally();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Vérifie si l'utilisateur est connecté (synchrone)
  bool get isLoggedInSync => _user != null && _authService.currentUser != null;

  Future<void> _signOutLocally() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    await prefs.remove('userId');
    _user = null;
    _userData = null; // Ajoutez cette ligne
  }

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

  Future<Utilisateur?> _fetchUserDataInternal() async {
    if (!await isLoggedIn()) {
      print('Utilisateur non connecté');
      return null;
    }
    try {
      final user = _authService.currentUser;
      if (user == null) {
        print('Aucun utilisateur Firebase connecté');
        return null;
      }
      print('Récupération Firestore pour uid: ${user.uid}');
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      if (!doc.exists) {
        print('Document Firestore inexistant pour uid: ${user.uid}');
        return null;
      }
      final data = doc.data()!;
      print('Données Firestore récupérées: $data');
      return Utilisateur.fromMap({
        'nom': data['nom'] ?? '',
        'prenom': data['prenom'] ?? '',
        'email': data['email'] ?? '',
        'telephone': data['telephone'] ?? '',
        'photoProfil': data['photoProfil'] ?? '',
        'dateInscription': data['dateInscription'],
      }, doc.id);
    } catch (e) {
      print('Erreur lors de la récupération des données utilisateur: $e');
      return null;
    }
  }

  Future<Utilisateur?> fetchUserData() async {
    // Si les données sont déjà en cache, les retourner
    if (_userData != null) {
      return _userData;
    }

    // Sinon, les récupérer et les mettre en cache
    _userData = await _fetchUserDataInternal();
    notifyListeners();
    return _userData;
  }

  // Ajoutez une méthode pour rafraîchir les données si nécessaire
  Future<void> refreshUserData() async {
    _userData = await _fetchUserDataInternal();
    notifyListeners();
  }

  // Récupérer les données utilisateur Firestore
}
