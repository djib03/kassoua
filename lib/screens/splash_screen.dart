import 'dart:async';
import 'package:flutter/material.dart';
import 'package:kassoua/constants/colors.dart';
import 'package:kassoua/screens/auth/login_screen.dart';
import 'package:kassoua/controllers/auth_controller.dart';
import 'package:kassoua/screens/homepage/menu_navigation.dart';
import 'package:kassoua/screens/auth/auth_screen_selection.dart';

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

  // Services
  // final AuthService _authService = AuthService(); // Uncomment if you have this service

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startSplashSequence();
  }

  void _initializeAnimations() {
    // Logo animation controller
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Progress animation controller
    _progressController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    // Logo scale animation
    _logoAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    // Fade animation
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    // Progress animation
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );

    // Add listeners for text updates
    _progressController.addListener(() {
      if (_progressController.value < 0.3) {
        _updateLoadingText("Chargement des ressources...");
      } else if (_progressController.value < 0.6) {
        _updateLoadingText("Préparation de l'interface...");
      } else if (_progressController.value < 0.9) {
        _updateLoadingText("Finalisation...");
      } else {
        _updateLoadingText("Prêt !");
      }
    });
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
      // Preload images
      await _preloadImages();

      // Start logo animation
      _logoController.forward();

      // Start progress animation
      await Future.delayed(const Duration(milliseconds: 500));
      _progressController.forward();

      // Initialize services and check authentication
      await _initializeApp();

      // Wait for animations to complete or minimum time
      await Future.delayed(const Duration(seconds: 4));

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
    // Simulate app initialization
    await Future.delayed(const Duration(milliseconds: 1000));

    // Here you would typically:
    // - Initialize Firebase
    // - Setup analytics
    // - Load user preferences
    // - Check for app updates
    // - Initialize other services
  }

  void _navigateToNextScreen() async {
    if (!mounted) return;

    _canSkip = false;

    try {
      // Check authentication status
      AuthController authController = AuthController();
      bool isLoggedIn = await authController.isLoggedIn();

      Widget nextScreen =
          isLoggedIn ? const MenuNavigation() : const AuthSelectionScreen();

      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => nextScreen,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    } catch (error) {
      _handleError(error);
    }
  }

  void _handleError(dynamic error) {
    debugPrint("Splash screen error: $error");
    // Fallback navigation
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const AuthSelectionScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: _buildSplashBody(context));
  }

  Widget _buildSplashBody(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: DMColors.primary),
      child: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            // Main content
            _buildMainContent(),

            // Accessibility announcements
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
        // Animated logo
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

        // App name with animation
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
                    "Vender et Acheter en toute simplicité",
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

        // Loading text
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            _loadingText,
            key: ValueKey(_loadingText),
            style: const TextStyle(fontSize: 16.0, color: Colors.white70),
            semanticsLabel: _loadingText,
          ),
        ),

        const SizedBox(height: 20),

        // Custom progress indicator
        _buildProgressIndicator(),
      ],
    );
  }

  Widget _buildLogo() {
    return Image.asset(
      "assets/images/logos/app_logo.png",
      width: 200,
      height: 200,
      alignment: Alignment.center,
      semanticLabel: "Logo de l'application Kassoua",
    );
  }

  Widget _buildProgressIndicator() {
    return SizedBox(
      width: 200,
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return CircularProgressIndicator(
                value: _progressAnimation.value,
                backgroundColor: Colors.white.withOpacity(0.3),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              );
            },
          ),
          const SizedBox(height: 10),
          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return Text(
                "${(_progressAnimation.value * 100).toInt()}%",
                style: const TextStyle(color: Colors.white70, fontSize: 12),
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
