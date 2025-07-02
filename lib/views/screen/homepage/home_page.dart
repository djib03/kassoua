import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kassoua/views/screen/homepage/section/app_bar_action.dart';
import 'package:kassoua/views/screen/homepage/section/banner_carousel.dart';
import 'package:kassoua/views/screen/homepage/section/category_section.dart';
import 'package:kassoua/constants/colors.dart';
import 'package:kassoua/views/search_page.dart';
import 'package:kassoua/views/screen/homepage/favorite_products_screen.dart';
import 'package:kassoua/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kassoua/models/favori.dart';
import 'package:kassoua/models/product.dart';
import 'package:kassoua/views/widgets/product_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kassoua/views/screen/homepage/product_list_section.dart';
import 'package:kassoua/models/image_produit.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

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

  final bool _isLoadingMore = false;
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

  bool _isFavorite(String productId) {
    return _favoriteProductIdsNotifier.value.contains(productId);
  }

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

  Future<String> _getProductLocation(String? adresseId) async {
    if (adresseId == null || adresseId.isEmpty) {
      return 'Localisation non spécifiée';
    }

    // Vérifier le cache
    if (_productLocationCache.containsKey(adresseId)) {
      return _productLocationCache[adresseId]!;
    }

    try {
      final adresse = await _firestoreService.getAdresseById(adresseId);
      String location = 'Localisation non disponible';

      if (adresse != null) {
        if (adresse.ville != null && adresse.ville!.isNotEmpty) {
          location = adresse.ville!;
        } else if (adresse.quartier != null && adresse.quartier!.isNotEmpty) {
          location = adresse.quartier!;
        } else {
          String description = adresse.description;
          if (description.length > 20) {
            description = '${description.substring(0, 20)}...';
          }
          location = description;
        }
      }

      // Mettre en cache
      _productLocationCache[adresseId] = location;
      return location;
    } catch (e) {
      print('Erreur lors de la récupération de l\'adresse: $e');
      return 'Localisation non disponible';
    }
  }

  Map<String, dynamic> _convertProductToMap(Produit product) {
    return {
      'id': product.id,
      'name': product.nom,
      'price': product.prix,
      'location': 'Non spécifié',
      'description': product.description,
      'etat': product.etat,
      'estnegociable': product.estnegociable,
    };
  }

  Future<Map<String, dynamic>> _getCachedProductData(Produit product) {
    if (!_productDataCache.containsKey(product.id)) {
      _productDataCache[product
          .id] = _convertProductToMapWithAddressAndImagesCached(product);
    }
    return _productDataCache[product.id]!;
  }

  Future<Map<String, dynamic>> _convertProductToMapWithAddressAndImagesCached(
    Produit product,
  ) async {
    final locationFuture = _getProductLocation(product.adresseId);
    final imageFuture = getImagePrincipale(product.id);

    final results = await Future.wait([locationFuture, imageFuture]);
    final location = results[0] as String;
    final productImages = results[1] as ImageProduit?;

    return {
      'id': product.id,
      'name': product.nom,
      'price': product.prix,
      'location': location,
      'images': productImages,
      'description': product.description,
      'etat': product.etat,
      'estnegociable': product.estnegociable,
    };
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
            // 🔧 CHANGEMENT 8: Passer le ValueNotifier au lieu du Set
            ProductListSection(
              products: displayProducts,
              isDark: isDark,
              favoriteProductIds:
                  _favoriteProductIdsNotifier.value, // Correction ici
              onToggleFavorite: _onToggleFavorite,
              scrollController: _scrollController,
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

  bool _isFavoriteProcessing(String productId) {
    return _processingFavorites.contains(productId);
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
        AppBarAction(
          icon: Iconsax.heart,
          onPressed: () {
            if (_currentUserId != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FavoriteProductsScreen(),
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
