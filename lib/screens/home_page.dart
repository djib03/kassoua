import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kassoua/themes/widget/home_page/app_bar_action.dart';
import 'package:kassoua/themes/widget/home_page/banner_carousel.dart';
import 'package:kassoua/themes/widget/home_page/category_section.dart';
import 'package:kassoua/themes/widget/product_card.dart';
import 'package:kassoua/themes/widget/home_page/products_section.dart';
import 'package:kassoua/constants/colors.dart';
import 'package:kassoua/data/home_data.dart';
import 'package:kassoua/screens/search_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  Set<String> _favoriteProducts = {};

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

  void _showFavoritesDialog() {
    final favoriteProductsList =
        HomeData.products
            .where((product) => _favoriteProducts.contains(product['id']))
            .toList();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Mes Favoris'),
            content:
                favoriteProductsList.isEmpty
                    ? const Text('Aucun produit en favori')
                    : SizedBox(
                      width: double.maxFinite,
                      height: 300,
                      child: ListView.builder(
                        itemCount: favoriteProductsList.length,
                        itemBuilder: (context, index) {
                          final product = favoriteProductsList[index];
                          return ListTile(
                            leading: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Iconsax.image,
                                color: DMColors.primary,
                              ),
                            ),
                            title: Text(product['name']),
                            subtitle: Text('${product['price']} FCFA'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                _toggleFavorite(product['id']);
                                Navigator.of(context).pop();
                                _showFavoritesDialog();
                              },
                            ),
                          );
                        },
                      ),
                    ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Fermer'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _isDarkMode(context);

    return Scaffold(
      backgroundColor: isDark ? DMColors.black : Colors.grey[50],
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
                  const SizedBox(height: 32),
                  CategorySection(isDark: isDark),
                  const SizedBox(height: 32),
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
      backgroundColor: isDark ? DMColors.black : Colors.white,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: DMColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Iconsax.shop, color: DMColors.primary, size: 24),
          ),
          const SizedBox(width: 12),
          Text(
            'Kassoua',
            style: TextStyle(
              color: isDark ? DMColors.textWhite : DMColors.black,
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
          onPressed: _showFavoritesDialog,
          isDark: isDark,
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}
