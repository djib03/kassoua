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
  Utilisateur? _userData;
  bool _isLoading = false;

  // Méthode pour changer le mot de passe
  Future<String?> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final authType = prefs.getString('authType') ?? 'firebase';

      if (authType == 'firebase') {
        // Changer le mot de passe pour Firebase Auth
        return await _authService.changeFirebasePassword(
          currentPassword: currentPassword,
          newPassword: newPassword,
        );
      } else {
        // Changer le mot de passe pour l'auth téléphone
        if (_userData?.telephone == null) {
          return 'Erreur: Données utilisateur manquantes.';
        }

        return await _authService.changePhonePassword(
          telephone: _userData!.telephone,
          currentPassword: currentPassword,
          newPassword: newPassword,
        );
      }
    } catch (e) {
      return 'Une erreur inattendue s\'est produite : $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Méthode corrigée pour vérifier l'état de connexion
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedInPref = prefs.getBool('isLoggedIn') ?? false;

    if (!isLoggedInPref) {
      return false;
    }

    // Vérifier le type d'authentification
    final authType = prefs.getString('authType') ?? 'firebase';

    if (authType == 'firebase') {
      // Pour Firebase Auth, vérifier currentUser
      final firebaseUser = FirebaseAuth.instance.currentUser;
      final userId = prefs.getString('userId');
      return firebaseUser != null && userId != null && userId.isNotEmpty;
    } else {
      // Pour l'auth téléphone, vérifier l'ID du document
      final loggedInUserId = prefs.getString('loggedInUserId');
      return loggedInUserId != null && loggedInUserId.isNotEmpty;
    }
  }

  bool get isLoading => _isLoading;
  User? get user => _user;
  Utilisateur? get userData => _userData;

  Future<String?> signInWithPhoneAndPassword({
    required String telephone,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      // 1. Valider avec le service d'authentification
      final String? authError = await _authService.signInWithPhoneAndPassword(
        telephone: telephone,
        password: password,
      );

      if (authError != null) {
        return authError;
      }

      // 2. Récupérer les données utilisateur depuis Firestore
      final usersCollection = FirebaseFirestore.instance.collection('users');
      final querySnapshot =
          await usersCollection.where('telephone', isEqualTo: telephone).get();

      if (querySnapshot.docs.isEmpty) {
        return 'Erreur interne: Utilisateur non trouvé après authentification.';
      }

      final userDataDoc = querySnapshot.docs.first;
      _userData = Utilisateur.fromMap(userDataDoc.data(), userDataDoc.id);

      // 3. Mettre à jour les préférences pour l'auth téléphone
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('authType', 'phone');
      await prefs.setString('loggedInUserId', _userData!.id);

      // Nettoyer les anciennes préférences Firebase si elles existent
      await prefs.remove('userId');

      return null; // Succès
    } catch (e) {
      return 'Une erreur inattendue s\'est produite lors de la connexion : $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> signUpWithPhone({
    required String telephone,
    required String password,
    required String nom,
    required String prenom,
  }) async {
    try {
      // 1. Valider l'unicité du numéro
      String? validationError = await _authService.validatePhoneSignUp(
        telephone: telephone,
      );

      if (validationError != null) {
        return validationError;
      }

      // 2. Hasher le mot de passe
      final hashedPassword = sha256.convert(utf8.encode(password)).toString();

      // 3. Créer le document utilisateur
      final docRef = await FirebaseFirestore.instance.collection('users').add({
        'telephone': telephone, // Utiliser 'telephone' de manière cohérente
        'password': hashedPassword,
        'prenom': prenom,
        'nom': nom,
        'email': '',
        'dateInscription': FieldValue.serverTimestamp(),
        'photoProfil': null,
        'dateNaissance': null,
        'genre': null,
      });

      // 4. Mettre à jour les données locales
      final Utilisateur newUser = Utilisateur(
        id: docRef.id,
        nom: nom,
        prenom: prenom,
        email: '',
        telephone: telephone,
        dateInscription: DateTime.now(),
        photoProfil: null,
        dateNaissance: null,
        genre: null,
      );

      _userData = newUser;
      notifyListeners();

      return null; // Succès
    } catch (e) {
      return 'Une erreur inattendue s\'est produite lors de l\'inscription : $e';
    }
  }

  AuthController({AuthService? authService})
    : _authService = authService ?? AuthService() {
    _authService.authStateChanges.listen((User? user) {
      _user = user;
      if (user == null) {
        _userData = null;
      }
      notifyListeners();
    });
    initialize();
  }

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

  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      final credential = await _authService.signInWithEmail(email, password);
      if (credential.user != null) {
        _user = credential.user;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('authType', 'firebase');
        await prefs.setString('userId', _user!.uid);

        // Nettoyer les anciennes préférences téléphone
        await prefs.remove('loggedInUserId');

        // Charger les données utilisateur
        _userData = await _fetchUserDataInternal();

        // Si pas de données utilisateur trouvées, créer un document
        if (_userData == null) {
          print('Création du document utilisateur pour ${_user!.email}');
          await _createFirebaseUserDocument(_user!);
          _userData = await _fetchUserDataInternal();
        }

        return true;
      }
      return false;
    } catch (e) {
      print('Erreur lors de la connexion: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _createFirebaseUserDocument(User firebaseUser) async {
    try {
      final String displayName = firebaseUser.displayName ?? '';
      final List<String> nameParts = displayName.split(' ');
      final String prenom = nameParts.isNotEmpty ? nameParts.first : '';
      final String nom =
          nameParts.length > 1 ? nameParts.skip(1).join(' ') : '';

      await FirebaseFirestore.instance
          .collection('users')
          .doc(firebaseUser.uid)
          .set({
            'email': firebaseUser.email ?? '',
            'telephone': '',
            'prenom': prenom,
            'nom': nom,
            'dateInscription': FieldValue.serverTimestamp(),
            'photoProfil': firebaseUser.photoURL,
            'dateNaissance': null,
            'genre': null,
          });

      print('Document utilisateur créé pour: ${firebaseUser.email}');
    } catch (e) {
      print('Erreur lors de la création du document utilisateur: $e');
    }
  }

  Future<void> _checkAuthState() async {
    _isLoading = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      final authType = prefs.getString('authType') ?? 'firebase';

      if (!isLoggedIn) {
        _user = null;
        _userData = null;
        await _signOutLocally();
        return;
      }

      if (authType == 'firebase') {
        // Vérification pour Firebase Auth
        if (_authService.currentUser != null) {
          _user = _authService.currentUser;
          _userData = await _fetchUserDataInternal();

          // Si pas de données utilisateur trouvées, créer un document
          if (_userData == null && _user != null) {
            await _createFirebaseUserDocument(_user!);
            _userData = await _fetchUserDataInternal();
          }
        } else {
          await _signOutLocally();
        }
      } else {
        // Vérification pour l'auth téléphone
        final loggedInUserId = prefs.getString('loggedInUserId');
        if (loggedInUserId != null && loggedInUserId.isNotEmpty) {
          _userData = await _fetchPhoneUserData(loggedInUserId);
          if (_userData == null) {
            await _signOutLocally();
          }
        } else {
          await _signOutLocally();
        }
      }
    } catch (e) {
      print(
        'Erreur lors de la vérification de l\'état d\'authentification: $e',
      );
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
      return Utilisateur.fromMap(data, doc.id);
    } catch (e) {
      print(
        'Erreur lors de la récupération des données utilisateur téléphone: $e',
      );
      return null;
    }
  }

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
    await prefs.remove('authType');
    _user = null;
    _userData = null;
  }

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
      final authType = prefs.getString('authType') ?? 'firebase';

      if (authType == 'firebase') {
        // Utilisateur Firebase
        if (_authService.currentUser == null) {
          print('Aucun utilisateur Firebase connecté');
          return null;
        }

        final String firebaseUid = _authService.currentUser!.uid;
        print('Récupération des données pour Firebase UID: $firebaseUid');

        // Chercher par UID Firebase d'abord
        DocumentSnapshot doc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(firebaseUid)
                .get();

        if (doc.exists) {
          print('Document trouvé par UID Firebase');
          return Utilisateur.fromMap(
            doc.data() as Map<String, dynamic>,
            doc.id,
          );
        }

        // Si pas trouvé par UID, chercher par email
        final String? userEmail = _authService.currentUser!.email;
        if (userEmail != null) {
          print('Recherche par email: $userEmail');
          final QuerySnapshot querySnapshot =
              await FirebaseFirestore.instance
                  .collection('users')
                  .where('email', isEqualTo: userEmail)
                  .limit(1)
                  .get();

          if (querySnapshot.docs.isNotEmpty) {
            print('Document trouvé par email');
            final DocumentSnapshot userDoc = querySnapshot.docs.first;
            return Utilisateur.fromMap(
              userDoc.data() as Map<String, dynamic>,
              userDoc.id,
            );
          }
        }

        print(
          'Aucun document utilisateur trouvé pour cet utilisateur Firebase',
        );
        return null;
      } else {
        // Utilisateur téléphone
        final loggedInUserId = prefs.getString('loggedInUserId');
        if (loggedInUserId == null) {
          print('Aucun ID utilisateur téléphone trouvé');
          return null;
        }
        print(
          'Récupération des données pour utilisateur téléphone ID: $loggedInUserId',
        );
        return await _fetchPhoneUserData(loggedInUserId);
      }
    } catch (e) {
      print('Erreur lors de la récupération des données utilisateur: $e');
      return null;
    }
  }

  Future<Utilisateur?> fetchUserData() async {
    if (_userData != null) {
      return _userData;
    }
    _userData = await _fetchUserDataInternal();
    notifyListeners();
    return _userData;
  }

  Future<void> refreshUserData() async {
    _userData = await _fetchUserDataInternal();
    notifyListeners();
  }
}
