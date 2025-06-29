import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kassoua/views/screen/homepage/section/app_bar_action.dart';
import 'package:kassoua/views/screen/homepage/section/banner_carousel.dart';
import 'package:kassoua/views/screen/homepage/section/category_section.dart';
import 'package:kassoua/views/screen/homepage/section/products_section.dart';
import 'package:kassoua/constants/colors.dart';
import 'package:kassoua/views/search_page.dart';
import 'package:kassoua/views/screen/homepage/favorite_products_screen.dart';
import 'package:kassoua/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kassoua/models/favori.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // ✅ Vérifications null ajoutées
  final FirestoreService _firestoreService = FirestoreService();
  final Set<String> _favoriteProductIds = <String>{};
  String? _currentUserId;
  bool _isInitialized = false; // ✅ Ajouté pour éviter les erreurs de chargement

  bool _isDarkMode(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeUser();
  }

  // ✅ Séparation de l'initialisation des animations
  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // ✅ Initialisation avec gestion d'erreurs
  void _initializeUser() {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _currentUserId = user.uid;
        _loadFavorites();
      }
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      print('Erreur lors de l\'initialisation de l\'utilisateur: $e');
      setState(() {
        _isInitialized = true; // Permettre l'affichage même en cas d'erreur
      });
    }
  }

  // ✅ Chargement des favoris avec gestion d'erreurs
  void _loadFavorites() {
    if (_currentUserId == null) return;

    try {
      _firestoreService
          .getFavoris(_currentUserId!)
          .listen(
            (favoris) {
              if (mounted) {
                setState(() {
                  _favoriteProductIds.clear();
                  _favoriteProductIds.addAll(favoris.map((f) => f.produitId));
                });
              }
            },
            onError: (error) {
              print('Erreur lors du chargement des favoris: $error');
              // Ne pas bloquer l'interface même en cas d'erreur
            },
          );
    } catch (e) {
      print('Erreur lors de l\'écoute des favoris: $e');
    }
  }

  // ✅ Toggle des favoris avec vérifications null
  Future<void> _toggleFavorite(String productId) async {
    if (_currentUserId == null) {
      _showSnackBar(
        'Veuillez vous connecter pour gérer les favoris',
        Icons.error,
        Colors.orange,
      );
      return;
    }

    try {
      if (_favoriteProductIds.contains(productId)) {
        // Retirer des favoris
        final favorisStream = _firestoreService.getFavoris(_currentUserId!);
        final favoris = await favorisStream.first;
        final favorisToRemove = favoris.where((f) => f.produitId == productId);

        for (var favori in favorisToRemove) {
          await _firestoreService.removeFavori(favori.id, favori.produitId);
        }

        _showSnackBar(
          'Produit retiré des favoris',
          Icons.heart_broken,
          Colors.grey,
        );
      } else {
        // Ajouter aux favoris
        final newFavori = Favori(
          id: _firestoreService.generateNewFavoriId(),
          userId: _currentUserId!,
          produitId: productId,
          dateAjout: DateTime.now(),
        );
        await _firestoreService.addFavori(newFavori);

        _showSnackBar('Produit ajouté aux favoris', Icons.favorite, Colors.red);
      }
    } catch (e) {
      print('Erreur lors de la modification des favoris: $e');
      _showSnackBar(
        'Erreur lors de la modification des favoris',
        Icons.error,
        Colors.red,
      );
    }
  }

  void _showSnackBar(String message, IconData icon, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _isDarkMode(context);

    // ✅ Écran de chargement pendant l'initialisation
    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.black : Colors.grey[50],
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.black : Colors.grey[50],
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          slivers: [
            _buildSliverAppBar(isDark),
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  // ✅ Vérification avant d'afficher les composants
                  if (_isInitialized) ...[
                    BannerCarousel(isDark: isDark),
                    const SizedBox(height: 19),
                    CategorySection(isDark: isDark),
                    const SizedBox(height: 20),
                    // ✅ Container avec hauteur fixe pour éviter les problèmes de layout
                    Container(
                      height: MediaQuery.of(context).size.height * 0.6,
                      child: ProductsSection(isDark: isDark),
                    ),
                    const SizedBox(height: 24),
                  ] else ...[
                    // ✅ Placeholder si pas encore initialisé
                    const SizedBox(
                      height: 200,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(bool isDark) {
    return SliverAppBar(
      expandedHeight: 0,
      floating: true,
      pinned: true,
      backgroundColor: isDark ? AppColors.black : Colors.white,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Iconsax.shop, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 12),
          Text(
            'Kassoua',
            style: TextStyle(
              color: isDark ? AppColors.textWhite : AppColors.black,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      actions: [
        AppBarAction(
          icon: Iconsax.search_normal,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SearchScreen()),
            );
          },
          isDark: isDark,
        ),
        AppBarAction(
          icon: Iconsax.heart,
          onPressed: () {
            // ✅ Vérification avant navigation
            if (_currentUserId != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => FavoriteProductsScreen(
                        favoriteProductIds: _favoriteProductIds,
                        onToggleFavorite: _toggleFavorite,
                      ),
                ),
              ).then((_) {
                // Recharger les favoris au retour
                _loadFavorites();
              });
            } else {
              _showSnackBar(
                'Veuillez vous connecter pour voir vos favoris',
                Icons.error,
                Colors.orange,
              );
            }
          },
          isDark: isDark,
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}
