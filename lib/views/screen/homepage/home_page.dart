import 'dart:async';

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kassoua/views/screen/homepage/section/app_bar_action.dart';
import 'package:kassoua/views/screen/homepage/section/banner_carousel.dart';
import 'package:kassoua/views/screen/homepage/section/category_section.dart';
import 'package:kassoua/constants/colors.dart';
import 'package:kassoua/views/screen/homepage/search_page.dart';
import 'package:kassoua/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kassoua/models/favori.dart';
import 'package:kassoua/models/product.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kassoua/views/screen/homepage/product_list_section.dart';
import 'package:kassoua/models/image_produit.dart';
import 'package:kassoua/views/screen/shop/product_detail_vendeur.dart';
import 'package:kassoua/views/screen/homepage/product_detail_acheteur.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final GlobalKey<ProductListSectionState> _productListKey = GlobalKey();

  // 🚀 OPTIMISATION: Cache amélioré avec expiration
  final Map<String, Future<Map<String, dynamic>>> _productDataCache = {};
  final Map<String, String> _productLocationCache = {};
  final Map<String, ImageProduit?> _productImageCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheExpiration = Duration(minutes: 5);

  // 🔧 NOUVEAU: Gestion des états de favoris en cours
  final Set<String> _processingFavorites = <String>{};

  // Variables pour les favoris et utilisateur
  final FirestoreService _firestoreService = FirestoreService();
  late final ValueNotifier<Set<String>> _favoriteProductIdsNotifier;
  String? _currentUserId;
  bool _isInitialized = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 🚀 OPTIMISATION: Variables pour la pagination intelligente
  int _displayLimit = 6;
  static const int _loadIncrement = 6;
  bool _isLoadingMore = false;
  bool _hasMoreProducts = true;

  // 🚀 NOUVEAU: Debouncing pour éviter les appels multiples
  Timer? _debounceTimer;

  // 🚀 NOUVEAU: Preloading des images
  final Set<String> _preloadedImages = {};

  bool _isDarkMode(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;
  late final ScrollController _scrollController;

  // 🚀 OPTIMISATION: Garder la page en mémoire
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _favoriteProductIdsNotifier = ValueNotifier<Set<String>>(<String>{});
    _scrollController = ScrollController();
    _initializeAnimations();
    _initializeUser();

    // 🚀 OPTIMISATION: Precharger les données critiques
    _preloadCriticalData();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600), // Réduit de 800ms à 600ms
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _animationController.forward();
  }

  // 🚀 NOUVEAU: Precharger les données critiques
  void _preloadCriticalData() {
    // Precharger les favoris si l'utilisateur est connecté
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_currentUserId != null) {
        _loadFavorites();
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _scrollController.dispose();
    _animationController.dispose();
    _productDataCache.clear();
    _productLocationCache.clear();
    _productImageCache.clear();
    _cacheTimestamps.clear();
    _favoriteProductIdsNotifier.dispose();
    _processingFavorites.clear();
    super.dispose();
  }

  // 🚀 OPTIMISATION: Cache intelligent avec expiration
  bool _isCacheValid(String key) {
    final timestamp = _cacheTimestamps[key];
    if (timestamp == null) return false;
    return DateTime.now().difference(timestamp) < _cacheExpiration;
  }

  void _updateCache(String key, dynamic value) {
    _cacheTimestamps[key] = DateTime.now();
    if (value is ImageProduit?) {
      _productImageCache[key] = value;
    }
  }

  Future<String?> _getCurrentUserId() async {
    try {
      // Vérifier d'abord Firebase Auth
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        return firebaseUser.uid;
      }

      // Si pas Firebase, vérifier l'auth téléphone
      final prefs = await SharedPreferences.getInstance();
      final authType = prefs.getString('authType') ?? 'firebase';
      final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

      if (isLoggedIn && authType == 'phone') {
        return prefs.getString('loggedInUserId');
      }

      return null;
    } catch (e) {
      print('Erreur lors de la récupération de l\'ID utilisateur: $e');
      return null;
    }
  }

  void _initializeUser() async {
    try {
      // Vérifier d'abord l'authentification Firebase
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        _currentUserId = firebaseUser.uid;
        _loadFavorites();
      } else {
        // Si pas d'utilisateur Firebase, vérifier l'auth téléphone
        final prefs = await SharedPreferences.getInstance();
        final authType = prefs.getString('authType') ?? 'firebase';
        final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

        if (isLoggedIn && authType == 'phone') {
          final loggedInUserId = prefs.getString('loggedInUserId');
          if (loggedInUserId != null && loggedInUserId.isNotEmpty) {
            _currentUserId = loggedInUserId;
            _loadFavorites();
          }
        }
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

  void _loadFavorites() async {
    final userId = await _getCurrentUserId();
    if (userId == null) return;

    try {
      _firestoreService
          .getFavoris(userId)
          .listen(
            (favoris) {
              if (mounted) {
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

  // 🚀 OPTIMISATION: Toggle favori avec debouncing
  Future<void> _onToggleFavorite(String productId) async {
    if (_processingFavorites.contains(productId)) {
      return; // Éviter les appels multiples
    }

    _processingFavorites.add(productId);

    try {
      // Utiliser la nouvelle méthode pour obtenir l'ID utilisateur
      final userId = await _getCurrentUserId();

      if (userId == null) {
        _showSnackBar('Veuillez vous connecter pour gérer les favoris');
        return;
      }

      // Récupérer l'état actuel des favoris
      final currentFavorites = Set<String>.from(
        _favoriteProductIdsNotifier.value,
      );
      final wasAlreadyFavorite = currentFavorites.contains(productId);

      // Mise à jour optimiste
      final newFavorites = Set<String>.from(currentFavorites);
      if (wasAlreadyFavorite) {
        newFavorites.remove(productId);
      } else {
        newFavorites.add(productId);
      }
      _favoriteProductIdsNotifier.value = newFavorites;

      try {
        if (wasAlreadyFavorite) {
          await _firestoreService.removeFavori(userId, productId);
          if (mounted) {
            _showSnackBar('Produit retiré des favoris');
          }
        } else {
          final newFavori = Favori(
            id: _firestoreService.generateNewFavoriId(),
            userId: userId,
            produitId: productId,
            dateAjout: DateTime.now(),
          );
          await _firestoreService.addFavori(newFavori);
          if (mounted) {
            _showSnackBar('Produit ajouté aux favoris');
          }
        }
      } catch (e) {
        // Rollback en cas d'erreur
        if (mounted) {
          _favoriteProductIdsNotifier.value = currentFavorites;
          print('Erreur favoris: $e');
          _showSnackBar('Erreur lors de la modification des favoris');
        }
      }
    } finally {
      _processingFavorites.remove(productId);
    }
  }

  // 🚀 OPTIMISATION: Chargement d'image avec cache intelligent
  Future<ImageProduit?> getImagePrincipale(String produitId) async {
    // Vérifier le cache valide
    if (_isCacheValid(produitId) && _productImageCache.containsKey(produitId)) {
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

      // Mettre en cache avec timestamp
      _updateCache(produitId, image);

      // 🚀 NOUVEAU: Preload de l'image
      if (image?.url != null && !_preloadedImages.contains(image!.url)) {
        _preloadImage(image.url);
      }

      return image;
    } catch (e) {
      print('Erreur lors du chargement de l\'image: $e');
      _updateCache(produitId, null);
      return null;
    }
  }

  // 🚀 NOUVEAU: Preload des images pour une meilleure fluidité
  void _preloadImage(String imageUrl) {
    if (_preloadedImages.contains(imageUrl)) return;

    _preloadedImages.add(imageUrl);
    precacheImage(NetworkImage(imageUrl), context).catchError((error) {
      print('Erreur preload image: $error');
    });
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

  // 🚀 OPTIMISATION: Indicateurs de chargement plus fluides
  Widget _buildLoadingIndicator() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.scale(
            scale: value,
            child: const Column(
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
            ),
          ),
        );
      },
    );
  }

  Widget _buildEndOfContentIndicator(bool isDark) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: Column(
              children: [
                const SizedBox(height: 8),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 20,
                  ),
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
            ),
          ),
        );
      },
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
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _displayLimit = 6;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Réessayer'),
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

  // 🚀 OPTIMISATION: Section produits avec gestion intelligente du cache
  Widget _buildProductsSection(bool isDark) {
    return StreamBuilder<List<Produit>>(
      stream: _firestoreService.getAllProductsStream(),
      builder: (context, snapshot) {
        // ✅ Skeleton loader optimisé
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ProductListSection(
            key: _productListKey,
            products: [],
            isDark: isDark,
            favoriteProductIdsNotifier: _favoriteProductIdsNotifier,
            onToggleFavorite: _onToggleFavorite,
            scrollController: _scrollController,
            onProductTap: null,
            showSkeletonLoader: true,
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

        // 🚀 NOUVEAU: Preload des images des produits suivants
        _preloadNextProductImages(products, _displayLimit);

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
              showSkeletonLoader: false,
              onProductTap: (Produit produit) => _handleProductTap(produit),
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

  // 🚀 NOUVEAU: Preload des images des produits suivants
  void _preloadNextProductImages(List<Produit> products, int currentLimit) {
    final nextProducts = products.skip(currentLimit).take(3).toList();
    for (final product in nextProducts) {
      getImagePrincipale(product.id);
    }
  }

  // 🚀 OPTIMISATION: Gestion du tap sur un produit
  Future<void> _handleProductTap(Produit produit) async {
    try {
      // Récupérer les images du produit
      final images = await _firestoreService.getImagesProduit(produit.id).first;
      final imageUrls = images.map((img) => img.url).toList();

      // Vérifier si l'utilisateur connecté est le propriétaire du produit
      final currentUserId = await _getCurrentUserId();
      final isOwner =
          currentUserId != null && currentUserId == produit.vendeurId;

      if (isOwner) {
        // L'utilisateur est le vendeur → Vue vendeur
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) =>
                    ProductDetailVendeur(produit: produit, images: imageUrls),
          ),
        );
      } else {
        // L'utilisateur n'est pas le vendeur → Vue acheteur
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) =>
                    ProductDetailAcheteur(produit: produit, images: imageUrls),
          ),
        );
      }
    } catch (e) {
      print('Erreur lors de la navigation vers les détails du produit: $e');
      _showSnackBar('Erreur lors de l\'ouverture des détails du produit');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    final isDark = _isDarkMode(context);

    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: isDark ? Color(0xFF121212) : Colors.grey[50],
        body: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 600),
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: const CircularProgressIndicator(
                  color: AppColors.primary,
                ),
              );
            },
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? Color(0xFF121212) : Colors.grey[50],
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          color: AppColors.primary,
          backgroundColor: isDark ? AppColors.black : Colors.white,
          child: NotificationListener<ScrollNotification>(
            onNotification: (ScrollNotification scrollInfo) {
              if (scrollInfo.metrics.axisDirection == AxisDirection.down &&
                  scrollInfo.depth == 0) {
                if (_hasMoreProducts &&
                    !_isLoadingMore &&
                    scrollInfo.metrics.pixels >=
                        scrollInfo.metrics.maxScrollExtent * 0.8) {
                  _loadMoreProductsWithDebounce();
                }
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
                          showSkeletonLoader: false,
                        ),
                        const SizedBox(height: 20),
                        _buildProductsSection(isDark),
                        const SizedBox(height: 24),
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

  // 🚀 OPTIMISATION: Refresh avec animation fluide
  Future<void> _onRefresh() async {
    try {
      setState(() {
        _displayLimit = 6;
        _isLoadingMore = false;
        _hasMoreProducts = true;
      });

      // Vider le cache pour forcer le rechargement
      _productImageCache.clear();
      _cacheTimestamps.clear();
      _preloadedImages.clear();

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

  // 🚀 OPTIMISATION: Chargement avec debouncing
  void _loadMoreProductsWithDebounce() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (_hasMoreProducts && !_isLoadingMore) {
        setState(() {
          _isLoadingMore = true;
        });

        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            setState(() {
              _displayLimit += _loadIncrement;
              _isLoadingMore = false;
            });
          }
        });
      }
    });
  }

  Widget _buildSliverAppBar(bool isDark) {
    return SliverAppBar(
      expandedHeight: 0,
      floating: true,
      pinned: true,
      backgroundColor: isDark ? Color(0xFF121212) : Colors.white,
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
