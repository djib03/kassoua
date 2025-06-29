import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kassoua/views/screen/homepage/section/app_bar_action.dart';
import 'package:kassoua/views/screen/homepage/section/banner_carousel.dart';
import 'package:kassoua/views/screen/homepage/section/category_section.dart';

import 'package:kassoua/views/screen/homepage/section/products_section.dart';
import 'package:kassoua/constants/colors.dart';

import 'package:kassoua/views/search_page.dart';
import 'package:kassoua/views/screen/homepage/favorite_products_screen.dart'; // Importe la page des favoris

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  Set<String> _favoriteProducts = {}; // Ton état actuel des favoris

  bool _isDarkMode(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
    _loadFavorites();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _loadFavorites() {
    setState(() {
      _favoriteProducts = {};
      // Ici, tu chargerais les favoris depuis le stockage local (SharedPreferences)
      // ou une API si tu en as une.
      // Par exemple :
      // SharedPreferences.getInstance().then((prefs) {
      //   setState(() {
      //     _favoriteProducts = prefs.getStringList('favoriteProductIds')?.toSet() ?? {};
      //   });
      // });
    });
  }

  void _toggleFavorite(String productId) {
    setState(() {
      if (_favoriteProducts.contains(productId)) {
        _favoriteProducts.remove(productId);
        _showSnackBar(
          'Produit retiré des favoris',
          Icons.heart_broken,
          Colors.grey,
        );
      } else {
        _favoriteProducts.add(productId);
        _showSnackBar('Produit ajouté aux favoris', Icons.favorite, Colors.red);
      }
    });
    _saveFavorites();
  }

  void _saveFavorites() {
    // Implémentation de la sauvegarde des favoris
    // Par exemple, en utilisant SharedPreferences:
    // SharedPreferences.getInstance().then((prefs) {
    //   prefs.setStringList('favoriteProductIds', _favoriteProducts.toList());
    // });
  }

  void _showSnackBar(String message, IconData icon, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  bool _isFavorite(String productId) {
    return _favoriteProducts.contains(productId);
  }

  // Cette méthode est maintenant remplacée par la navigation vers la page
  // void _showFavoritesDialog() { ... } // Supprime ou commente cette méthode

  @override
  Widget build(BuildContext context) {
    final isDark = _isDarkMode(context);

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
                  BannerCarousel(isDark: isDark),
                  const SizedBox(height: 19),
                  CategorySection(isDark: isDark),
                  const SizedBox(height: 20),
                  ProductsSection(
                    isDark: isDark,
                    isFavorite: _isFavorite,
                    onToggleFavorite: _toggleFavorite,
                  ),
                  const SizedBox(height: 24),
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
          icon: Iconsax.heart, // L'icône de cœur
          onPressed: () {
            // Naviguer vers la nouvelle page des favoris
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => FavoriteProductsScreen(
                      favoriteProductIds:
                          _favoriteProducts, // Passe les IDs des favoris
                      onToggleFavorite:
                          _toggleFavorite, // Passe la fonction de basculement
                    ),
              ),
            ).then((_) {
              // Optionnel: Recharger les favoris quand on revient de la page
              // Si tu as un système de sauvegarde des favoris (SharedPreferences, etc.),
              // c'est un bon endroit pour les recharger pour t'assurer que la HomePage est à jour.
              _loadFavorites();
            });
          },
          isDark: isDark,
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}
