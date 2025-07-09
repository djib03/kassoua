import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kassoua/views/screen/homepage/section/app_bar_action.dart';
import 'package:kassoua/views/screen/homepage/section/banner_carousel.dart';
import 'package:kassoua/views/screen/homepage/section/category_section.dart';
import 'package:kassoua/constants/colors.dart';
import 'package:kassoua/views/screen/homepage/search_page.dart';
import 'package:kassoua/views/screen/homepage/favorite_products_screen.dart';
import 'package:kassoua/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kassoua/models/favori.dart';
import 'package:kassoua/models/product.dart';
import 'package:kassoua/views/widgets/product_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kassoua/views/screen/homepage/product_list_section.dart';
import 'package:kassoua/models/image_produit.dart';
import 'package:kassoua/views/screen/shop/product_detail_vendeur.dart'; // ou le nom de votre écran vendeur
import 'package:kassoua/views/screen/homepage/product_detail_acheteur.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final GlobalKey<ProductListSectionState> _productListKey = GlobalKey();

  final Map<String, Future<Map<String, dynamic>>> _productDataCache = {};
  final Map<String, String> _productLocationCache = {};
  final Map<String, ImageProduit?> _productImageCache = {};

  // 🔧 NOUVEAU: Gestion des états de favoris en cours
  final Set<String> _processingFavorites = <String>{};
  // Variables pour les favoris et utilisateur
  final FirestoreService _firestoreService = FirestoreService();
  late final ValueNotifier<Set<String>> _favoriteProductIdsNotifier;
  String? _currentUserId;
  bool _isInitialized = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Variables pour la section produits (intégrées)
  int _displayLimit = 6;

  bool _isLoadingMore = false;
  bool _hasMoreProducts = true;

  bool _isDarkMode(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _favoriteProductIdsNotifier = ValueNotifier<Set<String>>(<String>{});
    _scrollController = ScrollController();
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
    _productDataCache.clear();
    _productLocationCache.clear();
    _productImageCache.clear();
    _favoriteProductIdsNotifier.dispose();
    _processingFavorites.clear();
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

  // bool _isFavorite(String productId) {
  //   return _favoriteProductIdsNotifier.value.contains(productId);
  // }

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

  // ===== MÉTHODES POUR LA SECTION PRODUITS (Intégrées) =====

  Future<ImageProduit?> getImagePrincipale(String produitId) async {
    // Vérifier le cache
    if (_productImageCache.containsKey(produitId)) {
      return _productImageCache[produitId];
    }

    try {
      final query =
          await _firestore
              .collection('imagesProduits')
              .where('produitId', isEqualTo: produitId)
              .limit(1)
              .get();

      ImageProduit? image;
      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        image = ImageProduit.fromMap(doc.data(), doc.id);
      }

      // Mettre en cache
      _productImageCache[produitId] = image;
      return image;
    } catch (e) {
      print('Erreur lors du chargement de l\'image: $e');
      _productImageCache[produitId] = null;
      return null;
    }
  }

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
        // ✅ MONTRER le skeleton loader pendant le chargement
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ProductListSection(
            key: _productListKey,
            products: [], // Liste vide
            isDark: isDark,
            favoriteProductIdsNotifier: _favoriteProductIdsNotifier,
            onToggleFavorite: _onToggleFavorite,
            scrollController: _scrollController,
            onProductTap: null,
            showSkeletonLoader: true, // ← Activer le skeleton
          );
        }

        if (snapshot.hasError) {
          return _buildErrorState(isDark);
        }

        if (snapshot.data?.isEmpty ?? true) {
          return _buildEmptyState(isDark);
        }

        final products = snapshot.data ?? [];
        final displayProducts = products.take(_displayLimit).toList();
        final hasMoreProducts = products.length > _displayLimit;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _hasMoreProducts != hasMoreProducts) {
            setState(() {
              _hasMoreProducts = hasMoreProducts;
            });
          }
        });

        return Column(
          children: [
            ProductListSection(
              key: _productListKey,
              products: displayProducts,
              isDark: isDark,
              favoriteProductIdsNotifier: _favoriteProductIdsNotifier,
              onToggleFavorite: _onToggleFavorite,
              scrollController: _scrollController,
              showSkeletonLoader: false, // ← Désactiver le skeleton
              onProductTap: (Produit produit) async {
                try {
                  // Récupérer les images du produit
                  final images =
                      await _firestoreService
                          .getImagesProduit(produit.id)
                          .first;
                  final imageUrls = images.map((img) => img.url).toList();

                  // Vérifier si l'utilisateur connecté est le propriétaire du produit
                  final isOwner =
                      _currentUserId != null &&
                      _currentUserId == produit.vendeurId;

                  if (isOwner) {
                    // L'utilisateur est le vendeur → Vue vendeur
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => ProductDetailVendeur(
                              // Remplacez par le nom de votre écran vendeur
                              produit: produit,
                              images: imageUrls,
                            ),
                      ),
                    );
                  } else {
                    // L'utilisateur n'est pas le vendeur → Vue acheteur
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => ProductDetailAcheteur(
                              produit: produit,
                              images: imageUrls,
                            ),
                      ),
                    );
                  }
                } catch (e) {
                  print(
                    'Erreur lors de la navigation vers les détails du produit: $e',
                  );
                  _showSnackBar(
                    'Erreur lors de l\'ouverture des détails du produit',
                  );
                }
              },
            ),

            if (_isLoadingMore) _buildLoadingIndicator(),
            if (!hasMoreProducts && displayProducts.length > 6)
              _buildEndOfContentIndicator(isDark),

            const SizedBox(height: 4),
          ],
        );
      },
    );
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
        child: RefreshIndicator(
          // ✅ NOUVEAU: Ajout du RefreshIndicator
          onRefresh: _onRefresh,
          color: AppColors.primary,
          backgroundColor: isDark ? AppColors.black : Colors.white,
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
                        CategorySection(
                          isDark: isDark,
                          showSkeletonLoader:
                              !_isInitialized, // ← Contrôler le skeleton
                        ),
                        const SizedBox(height: 20),
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
      ),
    );
  }

  // ✅ NOUVEAU: Méthode pour gérer le pull-to-refresh
  Future<void> _onRefresh() async {
    try {
      setState(() {
        _displayLimit = 6;
        _isLoadingMore = false;
        _hasMoreProducts = true;
      });

      // ✅ NOUVEAU: Forcer le rechargement des images dans ProductListSection
      _productListKey.currentState?.refreshProductData();

      if (_currentUserId != null) {
        _loadFavorites();
      }

      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        _showSnackBar('Page actualisée');
      }
    } catch (e) {
      print('Erreur lors du rafraîchissement: $e');
      if (mounted) {
        _showSnackBar('Erreur lors de l\'actualisation');
      }
    }
  }

  void _loadMoreProductsAutomatically() {
    if (_hasMoreProducts) {
      setState(() {
        _displayLimit += 6;
      });
    }
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

        const SizedBox(width: 8),
      ],
    );
  }
}
