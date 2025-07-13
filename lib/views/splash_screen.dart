import 'dart:async';
import 'package:flutter/material.dart';
import 'package:kassoua/constants/colors.dart';
import 'package:kassoua/controllers/auth_controller.dart';
import 'package:kassoua/views/screen/homepage/menu_navigation.dart';
import 'package:kassoua/views/screen/auth/auth_screen_selection.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kassoua/services/firestore_service.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return SplashState();
  }
}

class SplashState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _progressController;
  late Animation<double> _logoAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _progressAnimation;

  bool _canSkip = true;
  String _loadingText = "Initialisation...";

  final FirestoreService _firestoreService = FirestoreService();
  final AuthController _authController = AuthController();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startSplashSequence();
  }

  void _initializeAnimations() {
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _progressController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );
    _logoAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );
  }

  void _updateLoadingText(String text) {
    if (mounted && _loadingText != text) {
      setState(() {
        _loadingText = text;
      });
    }
  }

  Future<void> _startSplashSequence() async {
    try {
      // Étape 1: Préchargement des images
      _updateLoadingText("Chargement des ressources...");
      await _preloadImages();

      // Étape 2: Démarrage des animations
      _logoController.forward();
      await Future.delayed(const Duration(milliseconds: 500));
      _progressController.forward();

      // Étape 3: Initialisation de l'application
      _updateLoadingText("Initialisation de l'application...");
      await _initializeApp();

      // Étape 4: Vérification de l'authentification
      _updateLoadingText("Vérification de votre session...");
      await _checkAuthenticationStatus();

      // Attendre la fin des animations ou un temps minimum
      await Future.delayed(const Duration(seconds: 1));

      if (mounted && _canSkip) {
        _navigateToNextScreen();
      }
    } catch (error) {
      if (mounted) {
        _handleError(error);
      }
    }
  }

  Future<void> _preloadImages() async {
    try {
      await precacheImage(
        const AssetImage("assets/images/logos/app_logo.png"),
        context,
      );
    } catch (e) {
      debugPrint("Error preloading images: $e");
    }
  }

  Future<void> _initializeApp() async {
    try {
      // Initialiser le contrôleur d'authentification
      await _authController.initialize();

      // Attendre un peu pour que l'initialisation soit complète
      await Future.delayed(const Duration(milliseconds: 500));
    } catch (e) {
      debugPrint("Error initializing app: $e");
    }
  }

  Future<void> _checkAuthenticationStatus() async {
    try {
      // Utiliser la méthode corrigée du contrôleur
      bool isLoggedIn = await _authController.isLoggedIn();

      if (isLoggedIn) {
        _updateLoadingText("Connexion détectée...");

        // Vérifier le type d'authentification
        final prefs = await SharedPreferences.getInstance();
        final authType = prefs.getString('authType') ?? 'firebase';

        if (authType == 'firebase') {
          // Pour Firebase Auth, vérifier si l'utilisateur Firebase existe toujours
          User? currentUser = FirebaseAuth.instance.currentUser;
          if (currentUser != null) {
            _updateLoadingText("Vérification de votre adresse...");
            await _firestoreService.createDefaultAddressFromCurrentLocation(
              currentUser.uid,
            );
          }
        } else {
          // Pour l'auth téléphone, récupérer l'utilisateur depuis les données stockées
          await _authController.fetchUserData();
          if (_authController.userData != null) {
            _updateLoadingText("Vérification de votre adresse...");
            await _firestoreService.createDefaultAddressFromCurrentLocation(
              _authController.userData!.id,
            );
          }
        }

        _updateLoadingText("Prêt !");
      } else {
        _updateLoadingText("Redirection vers la connexion...");
      }
    } catch (e) {
      debugPrint("Error checking authentication: $e");
      // En cas d'erreur, rediriger vers l'écran de connexion
      _updateLoadingText("Redirection vers la connexion...");
    }
  }

  void _navigateToNextScreen() async {
    if (!mounted) return;

    _canSkip = false;

    try {
      bool isLoggedIn = await _authController.isLoggedIn();

      if (isLoggedIn) {
        // Vérifier que les données utilisateur sont disponibles
        if (_authController.userData != null || _authController.user != null) {
          // Naviguer vers l'écran principal
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder:
                  (context, animation, secondaryAnimation) =>
                      const MenuNavigation(),
              transitionsBuilder: (
                context,
                animation,
                secondaryAnimation,
                child,
              ) {
                return FadeTransition(opacity: animation, child: child);
              },
              transitionDuration: const Duration(milliseconds: 800),
            ),
          );
        } else {
          // Données utilisateur manquantes, rediriger vers la connexion
          _navigateToAuth();
        }
      } else {
        // Utilisateur non connecté
        _navigateToAuth();
      }
    } catch (error) {
      _handleError(error);
    }
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
    debugPrint("Splash screen error: $error");
    _updateLoadingText("Erreur de chargement...");

    // Attendre un peu puis rediriger vers l'écran de connexion
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        _navigateToAuth();
      }
    });
  }

  SystemUiOverlayStyle get systemOverlayStyle => SystemUiOverlayStyle(
    statusBarColor: AppColors.primary,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.light,
    systemNavigationBarColor: AppColors.primary,
    systemNavigationBarIconBrightness: Brightness.light,
  );

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: systemOverlayStyle,
      child: Scaffold(body: _buildSplashBody(context)),
    );
  }

  Widget _buildSplashBody(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: AppColors.primary),
      child: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            _buildMainContent(),
            Semantics(
              label: "Écran de chargement de l'application Kassoua",
              child: const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        AnimatedBuilder(
          animation: _logoController,
          builder: (context, child) {
            return Transform.scale(
              scale: _logoAnimation.value,
              child: Opacity(
                opacity: _fadeAnimation.value,
                child: _buildLogo(),
              ),
            );
          },
        ),
        const SizedBox(height: 30),
        Column(
          children: [
            AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: const Text(
                    "Kassoua",
                    style: TextStyle(
                      fontFamily: 'poppins',
                      fontSize: 28.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                    semanticsLabel: "Kassoua - Nom de l'application",
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: const Text(
                    "Vendre et Acheter en toute simplicité",
                    style: TextStyle(
                      fontFamily: 'poppins',
                      fontSize: 16.0,
                      color: Colors.white70,
                      fontStyle: FontStyle.italic,
                    ),
                    semanticsLabel: "Slogan de l'application Kassoua",
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 40),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            _loadingText,
            key: ValueKey(_loadingText),
            style: const TextStyle(
              fontSize: 16.0,
              color: Colors.white70,
              fontFamily: 'poppins',
            ),
            semanticsLabel: _loadingText,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 20),
        _buildProgressIndicator(),
      ],
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 5,
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Image.asset(
        "assets/images/logos/app_logo.png",
        width: 200,
        height: 200,
        alignment: Alignment.center,
        semanticLabel: "Logo de l'application Kassoua",
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return SizedBox(
      width: 250,
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return LinearProgressIndicator(
                value: _progressAnimation.value,
                backgroundColor: Colors.white.withOpacity(0.3),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                minHeight: 4,
              );
            },
          ),
          const SizedBox(height: 10),
          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return Text(
                "${(_progressAnimation.value * 100).toInt()}%",
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontFamily: 'poppins',
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    _progressController.dispose();
    super.dispose();
  }
}
