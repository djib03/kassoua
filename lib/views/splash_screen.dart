import 'dart:async';
import 'package:flutter/material.dart';
import 'package:kassoua/constants/colors.dart';
import 'package:kassoua/controllers/auth_controller.dart';
import 'package:kassoua/views/screen/homepage/menu_navigation.dart';
import 'package:kassoua/views/screen/auth/auth_screen_selection.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kassoua/services/firestore_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return SplashState();
  }
}

class SplashState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  bool _canNavigate = true;

  final FirestoreService _firestoreService = FirestoreService();
  final AuthController _authController = AuthController();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startSplashSequence();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
  }

  Future<void> _startSplashSequence() async {
    try {
      // Démarrer l'animation de fade
      _fadeController.forward();

      // Attendre un minimum pour l'animation
      await Future.delayed(const Duration(milliseconds: 500));

      // Initialiser l'application
      await _initializeApp();

      // Vérifier l'authentification
      await _checkAuthenticationStatus();

      // Attendre la fin de l'animation
      await Future.delayed(const Duration(milliseconds: 1000));

      if (mounted && _canNavigate) {
        _navigateToNextScreen();
      }
    } catch (error) {
      debugPrint("Erreur splash: $error");
      if (mounted) {
        _handleError(error);
      }
    }
  }

  Future<void> _initializeApp() async {
    try {
      await _authController.initialize();
      await Future.delayed(const Duration(milliseconds: 300));
    } catch (e) {
      debugPrint("Erreur initialisation app: $e");
    }
  }

  Future<void> _checkAuthenticationStatus() async {
    try {
      bool isLoggedIn = await _authController.isLoggedIn();

      if (isLoggedIn) {
        // Récupérer les données utilisateur
        await _authController.fetchUserData();

        // Créer l'adresse par défaut si nécessaire
        final prefs = await SharedPreferences.getInstance();
        final authType = prefs.getString('authType') ?? 'firebase';

        if (authType == 'firebase') {
          User? currentUser = FirebaseAuth.instance.currentUser;
          if (currentUser != null) {
            await _firestoreService.createDefaultAddressFromCurrentLocation(
              currentUser.uid,
            );
          }
        } else {
          if (_authController.userData != null) {
            await _firestoreService.createDefaultAddressFromCurrentLocation(
              _authController.userData!.id,
            );
          }
        }
      }
    } catch (e) {
      debugPrint("Erreur vérification auth: $e");
    }
  }

  void _navigateToNextScreen() async {
    if (!mounted) return;

    _canNavigate = false;

    try {
      bool isLoggedIn = await _authController.isLoggedIn();

      if (isLoggedIn) {
        // Vérifier que les données utilisateur sont bien chargées
        if (_authController.userData != null || _authController.user != null) {
          _navigateToHome();
        } else {
          // Essayer de recharger les données
          await _authController.fetchUserData();
          if (_authController.userData != null ||
              _authController.user != null) {
            _navigateToHome();
          } else {
            _navigateToAuth();
          }
        }
      } else {
        _navigateToAuth();
      }
    } catch (error) {
      debugPrint("Erreur navigation: $error");
      _navigateToAuth();
    }
  }

  void _navigateToHome() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder:
            (context, animation, secondaryAnimation) => const MenuNavigation(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  void _navigateToAuth() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder:
            (context, animation, secondaryAnimation) =>
                const AuthSelectionScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  void _handleError(dynamic error) {
    debugPrint("Erreur splash: $error");

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        _navigateToAuth();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _buildSplashBody(),
    );
  }

  Widget _buildSplashBody() {
    return SafeArea(
      child: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value,
            child: _buildMainContent(),
          );
        },
      ),
    );
  }

  Widget _buildMainContent() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          // Logo simplifié
          Image.asset(
            height: 300,
            width: 300,
            "assets/images/logos/app_logo.png",
            alignment: Alignment.center,
            semanticLabel: "Logo de l'application Kassoua",
          ),
          // Nom de l'application
          Text(
            "Kassoua",
            style: TextStyle(
              fontFamily: 'poppins',
              fontSize: 32.0,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Color.fromARGB(255, 6, 5, 82),
              letterSpacing: 1.5,
            ),
            semanticsLabel: "Kassoua - Nom de l'application",
          ),

          const SizedBox(height: 12),

          // Slogan
          Text(
            "Vendre et Acheter en toute simplicité",
            style: TextStyle(
              fontFamily: 'poppins',
              fontSize: 16.0,
              color: isDark ? Colors.white70 : Colors.black54,
              fontStyle: FontStyle.italic,
            ),
            semanticsLabel: "Slogan de l'application Kassoua",
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 30),

          // Indicateur de chargement moderne
          _buildModernLoader(),
        ],
      ),
    );
  }

  Widget _buildModernLoader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: 40,
      height: 40,
      child: CircularProgressIndicator(
        strokeWidth: 3,
        backgroundColor:
            isDark
                ? Colors.grey[800]?.withOpacity(0.3)
                : Colors.grey[300]?.withOpacity(0.5),
        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        strokeCap: StrokeCap.round,
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }
}
