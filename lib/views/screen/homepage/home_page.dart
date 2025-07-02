import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kassoua/views/screen/homepage/section/app_bar_action.dart';
import 'package:kassoua/views/screen/homepage/section/banner_carousel.dart';
import 'package:kassoua/views/screen/homepage/section/category_section.dart';
import 'package:kassoua/constants/colors.dart';
import 'package:kassoua/views/screen/search_page.dart';
import 'package:kassoua/views/screen/homepage/favorite_products_screen.dart';
import 'package:kassoua/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kassoua/models/favori.dart';
import 'package:kassoua/models/product.dart';
import 'package:kassoua/views/screen/homepage/product_list_section.dart';
import 'package:kassoua/views/screen/product_detail.acheteur.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // 🔧 NOUVEAU: Gestion des états de favoris en cours
  final Set<String> _processingFavorites = <String>{};
  // Variables pour les favoris et utilisateur
  final FirestoreService _firestoreService = FirestoreService();
  String? _currentUserId;
  bool _isInitialized = false;
  late final ValueNotifier<Set<String>> _favoriteProductIdsNotifier;

  // Variables pour la section produits (intégrées)
  int _displayLimit = 6;
  static const int _loadMoreIncrement = 6;
  bool _isLoadingMore = false;
  bool _hasMoreProducts = true;

  bool _isDarkMode(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;
  late final ScrollController _scrollController;

  Future<void> _navigateToVendorDetail(
    BuildContext context,
    Produit product,
  ) async {
    try {
      // Récupérer les images du produit
      final images = await _firestoreService.getImagesProduit(product.id).first;
      final imageUrls = images.map((img) => img.url).toList();

      // Navigation vers ProductDetailAcheteur
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) =>
                  ProductDetailAcheteur(produit: product, images: imageUrls),
        ),
      );
    } catch (e) {
      print('Erreur lors de la navigation vers le détail: $e');
      _showSnackBar('Erreur lors de l\'ouverture du produit');
    }
  }

  Future<void> _navigateToVendorDetailWithAnimation(
    BuildContext context,
    Produit product,
  ) async {
    final images = await _firestoreService.getImagesProduit(product.id).first;
    final imageUrls = images.map((img) => img.url).toList();

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder:
            (context, animation, secondaryAnimation) =>
                ProductDetailAcheteur(produit: product, images: imageUrls),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;

          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _favoriteProductIdsNotifier = ValueNotifier<Set<String>>(<String>{});
    _initializeAnimations();
    _initializeUser();
  }

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
    _scrollController.dispose();
    _animationController.dispose();
    _processingFavorites.clear();
    _favoriteProductIdsNotifier.dispose();

    super.dispose();
  }

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
        _isInitialized = true;
      });
    }
  }

  void _loadFavorites() {
    if (_currentUserId == null) return;

    try {
      _firestoreService
          .getFavoris(_currentUserId!)
          .listen(
            (favoris) {
              if (mounted) {
                // Mettre à jour le ValueNotifier au lieu de setState
                _favoriteProductIdsNotifier.value =
                    favoris.map((f) => f.produitId).toSet();
              }
            },
            onError: (error) {
              print('Erreur lors du chargement des favoris: $error');
            },
          );
    } catch (e) {
      print('Erreur lors de l\'écoute des favoris: $e');
    }
  }

  // 🔧 CHANGEMENT 5: Modifier _isFavorite pour utiliser ValueNotifier
  bool _isFavorite(String productId) {
    return _favoriteProductIdsNotifier.value.contains(productId);
  }

  // 🔧 CHANGEMENT 6: Nouvelle méthode _onToggleFavorite optimisée
  Future<void> _onToggleFavorite(String productId) async {
    if (_currentUserId == null) {
      _showSnackBar('Veuillez vous connecter pour gérer les favoris');
      return;
    }

    // Récupérer l'état actuel des favoris
    final currentFavorites = Set<String>.from(
      _favoriteProductIdsNotifier.value,
    );
    final wasAlreadyFavorite = currentFavorites.contains(productId);

    // 🎯 MISE À JOUR OPTIMISTE : Mettre à jour le ValueNotifier (pas de setState!)
    final newFavorites = Set<String>.from(currentFavorites);
    if (wasAlreadyFavorite) {
      newFavorites.remove(productId);
    } else {
      newFavorites.add(productId);
    }
    _favoriteProductIdsNotifier.value = newFavorites;

    try {
      if (wasAlreadyFavorite) {
        await _firestoreService.removeFavori(_currentUserId!, productId);
        if (mounted) {
          _showSnackBar('Produit retiré des favoris');
        }
      } else {
        final newFavori = Favori(
          id: _firestoreService.generateNewFavoriId(),
          userId: _currentUserId!,
          produitId: productId,
          dateAjout: DateTime.now(),
        );
        await _firestoreService.addFavori(newFavori);
        if (mounted) {
          _showSnackBar('Produit ajouté aux favoris');
        }
      }
    } catch (e) {
      // 🔄 ROLLBACK : En cas d'erreur, remettre l'état précédent
      if (mounted) {
        _favoriteProductIdsNotifier.value = currentFavorites;
        print('Erreur favoris: $e');
        _showSnackBar('Erreur lors de la modification des favoris');
      }
    }
  }

  // ===== UNIFIED TOGGLE FAVORITE METHOD =====

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  // =============================================
  // 5. WIDGETS HELPER POUR L'UI
  // =============================================

  Widget _buildLoadingIndicator() {
    return const Column(
      children: [
        SizedBox(height: 8),
        Center(
          child: Column(
            children: [
              CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 2,
              ),
              SizedBox(height: 8),
              Text(
                'Chargement...',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16),
      ],
    );
  }

  Widget _buildEndOfContentIndicator(bool isDark) {
    return Column(
      children: [
        const SizedBox(height: 8),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[800] : Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle_outline,
                color: AppColors.primary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Tous les produits ont été chargés',
                style: TextStyle(
                  color: isDark ? AppColors.textWhite : AppColors.black,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(bool isDark) {
    return Container(
      height: 200,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: isDark ? AppColors.textSecondary : Colors.grey[600],
            ),
            const SizedBox(height: 16),
            Text(
              'Erreur de chargement',
              style: TextStyle(
                color: isDark ? AppColors.textWhite : AppColors.black,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Impossible de charger les produits',
              style: TextStyle(
                color: isDark ? AppColors.textSecondary : Colors.grey[600],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Container(
      height: 200,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              size: 48,
              color: isDark ? AppColors.textSecondary : Colors.grey[600],
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun produit disponible',
              style: TextStyle(
                color: isDark ? AppColors.textWhite : AppColors.black,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Les produits apparaîtront ici une fois ajoutés',
              style: TextStyle(
                color: isDark ? AppColors.textSecondary : Colors.grey[600],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ===== CONSTRUCTION DE LA SECTION PRODUITS =====
  Widget _buildProductsSection(bool isDark) {
    return StreamBuilder<List<Produit>>(
      stream: _firestoreService.getAllProductsStream(),
      builder: (context, snapshot) {
        final products = snapshot.data ?? [];
        final displayProducts = products.take(_displayLimit).toList();
        final hasMoreProducts = products.length > _displayLimit;

        // Mise à jour de l'état hasMoreProducts
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _hasMoreProducts != hasMoreProducts) {
            setState(() {
              _hasMoreProducts = hasMoreProducts;
            });
          }
        });

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 200,
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        if (snapshot.hasError) {
          return _buildErrorState(isDark);
        }

        if (products.isEmpty) {
          return _buildEmptyState(isDark);
        }

        return Column(
          children: [
            // 🔧 MODIFICATION: Ajouter le callback de navigation
            ProductListSection(
              products: displayProducts,
              isDark: isDark,
              favoriteProductIdsNotifier: _favoriteProductIdsNotifier,
              onToggleFavorite: _onToggleFavorite,
              scrollController: _scrollController,
              // 🔧 NOUVEAU: Ajouter le callback de navigation
              onProductTap:
                  (product) => _navigateToVendorDetail(context, product),
              // Ou avec animation: (product) => _navigateToVendorDetailWithAnimation(context, product),
            ),

            // Indicateurs de chargement et fin
            if (_isLoadingMore) _buildLoadingIndicator(),
            if (!hasMoreProducts && displayProducts.length > 6)
              _buildEndOfContentIndicator(isDark),

            const SizedBox(height: 4),
          ],
        );
      },
    );
  }

  void _loadMoreProductsAutomatically() {
    bool hasMoreProducts = true;
    if (!_isLoadingMore && hasMoreProducts) {
      setState(() {
        _isLoadingMore = true;
        _displayLimit += _loadMoreIncrement;
      });

      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _isLoadingMore = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _isDarkMode(context);

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
        child: NotificationListener<ScrollNotification>(
          onNotification: (ScrollNotification scrollInfo) {
            if (_hasMoreProducts &&
                !_isLoadingMore &&
                scrollInfo.metrics.pixels >=
                    scrollInfo.metrics.maxScrollExtent * 0.8) {
              _loadMoreProductsAutomatically();
            }
            return false;
          },
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              _buildSliverAppBar(isDark),
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    if (_isInitialized) ...[
                      BannerCarousel(isDark: isDark),
                      const SizedBox(height: 19),
                      CategorySection(isDark: isDark),
                      const SizedBox(height: 20),
                      // 🔧 REMPLACER: Utiliser la version optimisée
                      _buildProductsSection(isDark),
                      const SizedBox(height: 24),
                    ] else ...[
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
            if (_currentUserId != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) =>
                          FavoriteProductsScreen(userId: _currentUserId!),
                ),
              ).then((_) {
                _loadFavorites();
              });
            } else {
              _showSnackBar('Veuillez vous connecter pour voir vos favoris');
            }
          },
          isDark: isDark,
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}
