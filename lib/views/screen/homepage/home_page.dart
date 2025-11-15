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

  // 🚀 NOUVEAU: Cache persistant des produits avec état local
  static List<Produit> _cachedProducts = [];
  static DateTime? _lastProductsUpdate;
  static const Duration _productsCacheExpiration = Duration(minutes: 10);
  static double _savedScrollPosition = 0.0;
  static int _savedDisplayLimit = 6;
  static bool _hasBeenInitialized = false;

  // Variables pour l'état des produits
  List<Produit> _displayedProducts = [];
  bool _isLoadingProducts = false;
  bool _hasProductsError = false;
  StreamSubscription<List<Produit>>? _productsSubscription;

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

    // Save scroll position on every scroll
    _scrollController.addListener(() {
      if (_scrollController.hasClients) {
        _savedScrollPosition = _scrollController.offset;
      }
    });

    _initializeAnimations();
    _initializeUser();
    _initializeProductsWithStateRestoration();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _animationController.forward();
  }

  // 🚀 NOUVEAU: Initialisation des produits avec cache persistant
  void _initializeProductsWithStateRestoration() {
    // Restaurer la limite d'affichage précédente si elle existe
    if (_hasBeenInitialized && _savedDisplayLimit > _displayLimit) {
      _displayLimit = _savedDisplayLimit;
    }

    // Si on a des produits en cache et qu'ils sont encore valides
    if (_cachedProducts.isNotEmpty && _isProductsCacheValid()) {
      setState(() {
        _displayedProducts = _cachedProducts.take(_displayLimit).toList();
        _hasMoreProducts = _cachedProducts.length > _displayLimit;
        _isLoadingProducts = false;
        _hasProductsError = false;
      });

      // MODIFIÉ: Restaurer la position de scroll avec un délai plus court
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Délai supplémentaire pour s'assurer que le rendu est terminé
        Future.delayed(const Duration(milliseconds: 50), () {
          if (mounted) {
            _restoreScrollPosition();
          }
        });
      });

      // Precharger les images des produits affichés
      _preloadDisplayedProductImages();
    } else {
      // Charger les produits depuis Firestore
      _loadProductsFromFirestore();
    }
  }

  void _restoreScrollPosition() {
    if (_savedScrollPosition > 0 && _scrollController.hasClients) {
      // Utiliser jumpTo au lieu d'animateTo pour éviter les problèmes de timing
      _scrollController.jumpTo(_savedScrollPosition);

      // Alternative si vous voulez garder l'animation :
      /* 
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients && mounted) {
        _scrollController.animateTo(
          _savedScrollPosition,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
    */
    }
  }

  // 🚀 NOUVEAU: Vérifier si le cache des produits est valide
  bool _isProductsCacheValid() {
    if (_lastProductsUpdate == null) return false;
    return DateTime.now().difference(_lastProductsUpdate!) <
        _productsCacheExpiration;
  }

  void _loadProductsFromFirestore() {
    setState(() {
      _isLoadingProducts = true;
      _hasProductsError = false;
    });

    _productsSubscription?.cancel();
    _productsSubscription = _firestoreService.getAllProductsStream().listen(
      (products) {
        if (mounted) {
          // Mettre à jour le cache global
          _cachedProducts = products;
          _lastProductsUpdate = DateTime.now();

          setState(() {
            _displayedProducts = products.take(_displayLimit).toList();
            _hasMoreProducts = products.length > _displayLimit;
            _isLoadingProducts = false;
            _hasProductsError = false;
          });

          // MODIFIÉ: Restaurer la position de scroll après le chargement
          if (_hasBeenInitialized && _savedScrollPosition > 0) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              // Double délai pour s'assurer que tout est rendu
              Future.delayed(const Duration(milliseconds: 100), () {
                if (mounted) {
                  _restoreScrollPosition();
                }
              });
            });
          }

          // Precharger les images
          _preloadDisplayedProductImages();
          _preloadNextProductImages(products, _displayLimit);
        }
      },
      onError: (error) {
        print('Erreur lors du chargement des produits: $error');
        if (mounted) {
          setState(() {
            _isLoadingProducts = false;
            _hasProductsError = true;
          });
        }
      },
    );
  }

  void _saveScrollPosition() {
    if (_scrollController.hasClients) {
      _savedScrollPosition = _scrollController.offset;
      _savedDisplayLimit = _displayLimit;
      _hasBeenInitialized = true;
    }
  }

  // 🚀 NOUVEAU: Precharger les images des produits affichés
  void _preloadDisplayedProductImages() {
    for (final product in _displayedProducts.take(3)) {
      getImagePrincipale(product.id);
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _productsSubscription?.cancel();
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Sauvegarder la position de scroll quand on quitte la page
    if (_scrollController.hasClients) {
      _savedScrollPosition = _scrollController.offset;
    }

    // Sauvegarder la limite d'affichage actuelle
    _savedDisplayLimit = _displayLimit;

    // Marquer comme initialisé
    _hasBeenInitialized = true;
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
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        return firebaseUser.uid;
      }

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
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        _currentUserId = firebaseUser.uid;
        _loadFavorites();
      } else {
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
      return;
    }

    _processingFavorites.add(productId);

    try {
      final userId = await _getCurrentUserId();

      if (userId == null) {
        _showSnackBar('Veuillez vous connecter pour gérer les favoris');
        return;
      }

      final currentFavorites = Set<String>.from(
        _favoriteProductIdsNotifier.value,
      );
      final wasAlreadyFavorite = currentFavorites.contains(productId);

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

      _updateCache(produitId, image);

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
                _loadProductsFromFirestore();
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

  // 🚀 NOUVEAU: Section produits optimisée avec cache persistant
  Widget _buildProductsSection(bool isDark) {
    // Si on a une erreur
    if (_hasProductsError) {
      return _buildErrorState(isDark);
    }

    // Si on charge pour la première fois et qu'on n'a pas de produits en cache
    if (_isLoadingProducts && _displayedProducts.isEmpty) {
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

    // Si on n'a aucun produit
    if (_displayedProducts.isEmpty && !_isLoadingProducts) {
      return _buildEmptyState(isDark);
    }

    return Column(
      children: [
        ProductListSection(
          key: _productListKey,
          products: _displayedProducts,
          isDark: isDark,
          favoriteProductIdsNotifier: _favoriteProductIdsNotifier,
          onToggleFavorite: _onToggleFavorite,
          scrollController: _scrollController,
          showSkeletonLoader: false,
          onProductTap: (Produit produit) => _handleProductTap(produit),
        ),

        if (_isLoadingMore) _buildLoadingIndicator(),
        if (!_hasMoreProducts && _displayedProducts.length > 6)
          _buildEndOfContentIndicator(isDark),

        const SizedBox(height: 4),
      ],
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
    // Sauvegarder la position avant de naviguer
    _saveScrollPosition();

    try {
      final images = await _firestoreService.getImagesProduit(produit.id).first;
      final imageUrls = images.map((img) => img.url).toList();

      final currentUserId = await _getCurrentUserId();
      final isOwner =
          currentUserId != null && currentUserId == produit.vendeurId;

      if (isOwner) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) =>
                    ProductDetailVendeur(produit: produit, images: imageUrls),
          ),
        );
      } else {
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
    super.build(context);
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
                // 🚀 NOUVEAU: Sauvegarder la position en temps réel
                if (_scrollController.hasClients) {
                  _savedScrollPosition = scrollInfo.metrics.pixels;
                }

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
              // 🚀 NOUVEAU: Conserver la position de scroll
              physics: const AlwaysScrollableScrollPhysics(),
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

  // 🚀 OPTIMISATION: Refresh avec cache intelligent
  Future<void> _onRefresh() async {
    try {
      // 🚀 NOUVEAU: Ne pas réinitialiser la limite si on a déjà chargé plus de produits
      final shouldPreserveLimit = _displayLimit > 6;

      if (!shouldPreserveLimit) {
        setState(() {
          _displayLimit = 6;
          _isLoadingMore = false;
          _hasMoreProducts = true;
        });
      }

      // Vider les caches pour forcer le rechargement
      _productImageCache.clear();
      _cacheTimestamps.clear();
      _preloadedImages.clear();

      // Invalider le cache des produits
      _cachedProducts.clear();
      _lastProductsUpdate = null;

      _productListKey.currentState?.refreshProductData();

      if (_currentUserId != null) {
        _loadFavorites();
      }

      // Recharger les produits depuis Firestore
      _loadProductsFromFirestore();

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

  // 🚀 OPTIMISATION: Chargement de plus de produits depuis le cache
  void _loadMoreProductsWithDebounce() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (_hasMoreProducts && !_isLoadingMore) {
        setState(() {
          _isLoadingMore = true;
        });

        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            final newLimit = _displayLimit + _loadIncrement;
            final newDisplayedProducts =
                _cachedProducts.take(newLimit).toList();
            final hasMore = _cachedProducts.length > newLimit;

            setState(() {
              _displayLimit = newLimit;
              _displayedProducts = newDisplayedProducts;
              _hasMoreProducts = hasMore;
              _isLoadingMore = false;
            });

            // Precharger les images des nouveaux produits
            _preloadNextProductImages(_cachedProducts, newLimit);
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
