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
    final loggedInUserId = prefs.getString('loggedInUserId');

    // Pour l'auth téléphone, on vérifie juste les préférences et l'ID utilisateur
    // Pour l'auth Firebase, on vérifie aussi currentUser
    return isLoggedInPref &&
        loggedInUserId != null &&
        loggedInUserId.isNotEmpty;
  }

  bool get isLoading => _isLoading;
  User? get user => _user;
  Utilisateur? get userData => _userData; // Ajoutez cette ligne

  Future<String?> signInWithPhoneAndPassword({
    required String telephone,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      // 1. Appelle le service d'authentification personnalisé pour valider le téléphone et le mot de passe
      final String? authError = await _authService.signInWithPhoneAndPassword(
        telephone: telephone,
        password: password,
      );

      if (authError != null) {
        return authError; // Erreur d'authentification (ex: mauvais mot de passe)
      }

      // 2. Si l'authentification est réussie, récupère les données de l'utilisateur depuis Firestore
      // en utilisant le numéro de téléphone comme critère de recherche.
      final usersCollection = FirebaseFirestore.instance.collection('users');
      final querySnapshot =
          await usersCollection.where('telephone', isEqualTo: telephone).get();

      if (querySnapshot.docs.isEmpty) {
        // Ce cas ne devrait pas arriver si _authService.signInWithPhoneAndPassword a réussi,
        // mais c'est une sécurité.
        return 'Erreur interne: Utilisateur non trouvé après authentification.';
      }

      final userDataDoc = querySnapshot.docs.first;
      _userData = Utilisateur.fromMap(userDataDoc.data(), userDataDoc.id);

      // 3. Mettre à jour les préférences partagées pour maintenir l'état de connexion.
      // Puisqu'il n'y a pas d'UID Firebase Auth, nous stockons l'ID du document Firestore.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString(
        'loggedInUserId',
        _userData!.id,
      ); // Stocke l'ID du document Firestore

      // Ici, _user (l'objet Firebase Auth User) restera null.
      // Si d'autres parties de votre application s'appuient strictement sur _user non-null,
      // vous devrez peut-être revoir leur logique ou simuler un objet User minimal.

      return null; // Connexion réussie
    } catch (e) {
      return 'Une erreur inattendue s\'est produite lors de la connexion : $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  //methode pour creer un compte avec numero
  /// Inscription avec numéro de téléphone et mot de passe
  /// Retourne un message d'erreur ou null si succès
  Future<String?> signUpWithPhone({
    required String telephone,
    required String password,
    required String nom,
    required String prenom,
  }) async {
    try {
      // 1. Valider l'unicité du numéro de téléphone via AuthService
      String? validationError = await _authService.validatePhoneSignUp(
        telephone: telephone,
      );

      if (validationError != null) {
        return validationError; // Le numéro de téléphone est déjà utilisé ou autre erreur de validation
      }

      // 2. Hasher le mot de passe
      final hashedPassword = sha256.convert(utf8.encode(password)).toString();

      // 3. Créer un nouveau document utilisateur dans Firestore
      final docRef = await FirebaseFirestore.instance.collection('users').add({
        'telephone':
            telephone, // Utilisez 'telephone' pour être cohérent avec votre Firestore
        'password': hashedPassword,
        'prenom': prenom,
        'nom': nom,
        'email':
            '', // L'email est explicitement vide pour une inscription par téléphone
        'dateInscription':
            FieldValue.serverTimestamp(), // Utilisez un timestamp serveur
        // Ajoutez d'autres champs par défaut si nécessaire (photoProfil, dateNaissance, genre)
        'photoProfil': null,
        'dateNaissance': null,
        'genre': null,
      });

      // 4. Mettre à jour les données utilisateur locales dans AuthController
      // Note: Puisqu'il n'y a pas d'utilisateur Firebase Auth créé directement ici,
      // _user restera null pour ce type d'authentification.
      // C'est pourquoi nous devons gérer _userData directement avec l'ID du document Firestore.
      final Utilisateur newUser = Utilisateur(
        id: docRef.id, // L'ID du document Firestore est l'ID de l'utilisateur
        nom: nom,
        prenom: prenom,
        email: '',
        telephone: telephone,
        dateInscription:
            DateTime.now(), // Ou utilisez le temps du serveur si vous le récupérez
        photoProfil: null,
        dateNaissance: null,
        genre: null,
      );

      _userData = newUser; // Définir les données utilisateur actuelles
      notifyListeners();

      return null; // Succès de l'inscription
    } on FirebaseAuthException catch (e) {
      // Cette partie peut être moins pertinente ici si Firebase Auth n'est pas directement utilisé pour l'inscription téléphone
      return e.message ?? "Une erreur d'authentification s'est produite.";
    } catch (e) {
      return 'Une erreur inattendue s\'est produite lors de l\'inscription : $e';
    }
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
      final loggedInUserId = prefs.getString('loggedInUserId');

      if (isLoggedIn && loggedInUserId != null && loggedInUserId.isNotEmpty) {
        // Vérifier si c'est un utilisateur Firebase ou téléphone
        if (_authService.currentUser != null) {
          // Utilisateur Firebase
          _user = _authService.currentUser;
          _userData = await _fetchUserDataInternal();
        } else {
          // Utilisateur téléphone - récupérer depuis Firestore avec l'ID
          _userData = await _fetchPhoneUserData(loggedInUserId);
          if (_userData == null) {
            // Les données n'existent plus, déconnecter
            await _signOutLocally();
          }
        }
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

  Future<Utilisateur?> _fetchPhoneUserData(String documentId) async {
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(documentId)
              .get();

      if (!doc.exists) {
        print('Document Firestore inexistant pour ID: $documentId');
        return null;
      }

      final data = doc.data()!;
      print('Données utilisateur téléphone récupérées: $data');

      return Utilisateur.fromMap(data, doc.id);
    } catch (e) {
      print(
        'Erreur lors de la récupération des données utilisateur téléphone: $e',
      );
      return null;
    }
  }

  // Vérifie si l'utilisateur est connecté (synchrone)
  bool get isLoggedInSync {
    // Pour l'auth Firebase
    if (_user != null && _authService.currentUser != null) {
      return true;
    }

    // Pour l'auth téléphone
    if (_userData != null) {
      return true;
    }

    return false;
  }

  Future<void> _signOutLocally() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    await prefs.remove('userId');
    await prefs.remove('loggedInUserId');
    _user = null;
    _userData = null;
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
    try {
      final prefs = await SharedPreferences.getInstance();
      final loggedInUserId = prefs.getString('loggedInUserId');

      if (loggedInUserId == null || loggedInUserId.isEmpty) {
        print('Aucun ID utilisateur stocké');
        return null;
      }

      // Vérifier si c'est un utilisateur Firebase ou téléphone
      if (_authService.currentUser != null) {
        // Utilisateur Firebase - utiliser l'UID comme ID de document
        final doc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(_authService.currentUser!.uid)
                .get();

        if (!doc.exists) {
          print(
            'Document Firestore inexistant pour UID Firebase: ${_authService.currentUser!.uid}',
          );
          return null;
        }

        final data = doc.data()!;
        return Utilisateur.fromMap(data, doc.id);
      } else {
        // Utilisateur téléphone - utiliser l'ID du document stocké
        return await _fetchPhoneUserData(loggedInUserId);
      }
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
