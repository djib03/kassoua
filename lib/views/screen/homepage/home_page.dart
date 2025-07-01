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
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kassoua/models/image_produit.dart';
import 'package:kassoua/views/widgets/optimized_image_widget.dart'; // 🎯 IMPORT AJOUTÉ

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Variables pour les favoris et utilisateur
  final FirestoreService _firestoreService = FirestoreService();
  final Set<String> _favoriteProductIds = <String>{};
  String? _currentUserId;
  bool _isInitialized = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Variables pour la section produits (intégrées)
  int _displayLimit = 6;
  static const int _loadMoreIncrement = 6;
  bool _isLoadingMore = false;
  bool _hasMoreProducts = true;

  // 🎯 CACHE POUR LES IMAGES OPTIMISÉ
  final Map<String, ImageProduit?> _imageCache = {};
  final Map<String, String> _locationCache = {};

  bool _isDarkMode(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  @override
  void initState() {
    super.initState();
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
    _animationController.dispose();
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
                setState(() {
                  _favoriteProductIds.clear();
                  _favoriteProductIds.addAll(favoris.map((f) => f.produitId));
                });
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

  // ===== MÉTHODES OPTIMISÉES POUR LES IMAGES ET LOCALISATION =====

  Future<ImageProduit?> getImagePrincipale(String produitId) async {
    // 🎯 VÉRIFIER LE CACHE D'ABORD
    if (_imageCache.containsKey(produitId)) {
      return _imageCache[produitId];
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

      // 🎯 MISE EN CACHE
      _imageCache[produitId] = image;
      return image;
    } catch (e) {
      print('Erreur lors du chargement de l\'image pour $produitId: $e');
      _imageCache[produitId] = null;
      return null;
    }
  }

  Future<String> _getProductLocation(String? adresseId) async {
    if (adresseId == null || adresseId.isEmpty) {
      return 'Localisation non spécifiée';
    }

    // 🎯 VÉRIFIER LE CACHE D'ABORD
    if (_locationCache.containsKey(adresseId)) {
      return _locationCache[adresseId]!;
    }

    try {
      final adresse = await _firestoreService.getAdresseById(adresseId);
      String location;

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
      } else {
        location = 'Localisation non disponible';
      }

      // 🎯 MISE EN CACHE
      _locationCache[adresseId] = location;
      return location;
    } catch (e) {
      print('Erreur lors de la récupération de l\'adresse: $e');
      const location = 'Localisation non disponible';
      _locationCache[adresseId] = location;
      return location;
    }
  }

  Future<Map<String, dynamic>> _convertProductToMapWithAddressAndImages(
    Produit product,
  ) async {
    // 🎯 CHARGEMENT PARALLÈLE DES DONNÉES
    final futures = await Future.wait([
      _getProductLocation(product.adresseId),
      getImagePrincipale(product.id),
    ]);

    final location = futures[0] as String;
    final productImages = futures[1] as ImageProduit?;

    // ✅ VALIDATION SÉCURISÉE DU PRIX
    double safePrix = 0.0;
    try {
      if (product.prix != null) {
        if (product.prix.isNaN || product.prix.isInfinite) {
          safePrix = 0.0;
        } else {
          safePrix = product.prix;
        }
      }
    } catch (e) {
      print('Erreur prix produit ${product.id}: $e');
      safePrix = 0.0;
    }

    return {
      'id': product.id,
      'name': product.nom,
      'price': product.prix,
      'location': location,
      'images': productImages,
      'description': product.description,
      'etat': product.etat,
      'estnegociable': product.estnegociable,
      'dateAjout': product.dateAjout, // ✅ AJOUT DE LA DATE
    };
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

  bool _isFavorite(String productId) {
    return _favoriteProductIds.contains(productId);
  }

  // ===== FIXED TOGGLE FAVORITE METHOD =====
  Future<void> _onToggleFavorite(String productId) async {
    if (_currentUserId == null) {
      _showSnackBar('Veuillez vous connecter pour gérer les favoris');
      return;
    }

    final wasAlreadyFavorite = _isFavorite(productId);

    // 🎯 MISE À JOUR OPTIMISTE : Mettre à jour l'UI immédiatement
    setState(() {
      if (wasAlreadyFavorite) {
        _favoriteProductIds.remove(productId);
      } else {
        _favoriteProductIds.add(productId);
      }
    });

    try {
      if (wasAlreadyFavorite) {
        // Supprimer le favori
        await _firestoreService.removeFavori(_currentUserId!, productId);
        _showSnackBar('Produit retiré des favoris');
      } else {
        // Ajouter le favori
        final newFavori = Favori(
          id: _firestoreService.generateNewFavoriId(),
          userId: _currentUserId!,
          produitId: productId,
          dateAjout: DateTime.now(),
        );
        await _firestoreService.addFavori(newFavori);
        _showSnackBar('Produit ajouté aux favoris');
      }
    } catch (e) {
      // 🔄 ROLLBACK : En cas d'erreur, remettre l'état précédent
      setState(() {
        if (wasAlreadyFavorite) {
          _favoriteProductIds.add(productId);
        } else {
          _favoriteProductIds.remove(productId);
        }
      });

      print('Erreur favoris: $e');
      _showSnackBar('Erreur lors de la modification des favoris');
    }
  }

  // ===== UNIFIED TOGGLE FAVORITE METHOD =====
  Future<void> _toggleFavorite(String productId) async {
    // Use the same logic as _onToggleFavorite for consistency
    await _onToggleFavorite(productId);
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

  // ===== WIDGET OPTIMISÉ POUR AFFICHER LES PRODUITS =====
  Widget _buildOptimizedProductCard({
    required Produit product,
    required bool isDark,
  }) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _convertProductToMapWithAddressAndImages(product),
      builder: (context, snapshot) {
        // 🎯 AFFICHAGE IMMÉDIAT AVEC DONNÉES PARTIELLES
        final productMap = snapshot.data ?? _convertProductToMap(product);

        return Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[850] : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🎯 IMAGE OPTIMISÉE
              Expanded(
                flex: 3,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                      child: OptimizedImageWidget(
                        image: productMap['images'] as ImageProduit?,
                        productId: product.id,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                      ),
                    ),
                    // Bouton favori optimisé
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () => _onToggleFavorite(product.id),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Icon(
                            _isFavorite(product.id)
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color:
                                _isFavorite(product.id)
                                    ? Colors.red
                                    : Colors.grey[600],
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Informations du produit
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        productMap['name'] ?? 'Produit',
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${productMap['price']} FCFA',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 12,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              productMap['location'] ?? 'Non spécifié',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ===== CONSTRUCTION DE LA SECTION PRODUITS OPTIMISÉE =====
  Widget _buildProductsSection(bool isDark) {
    return StreamBuilder<List<Produit>>(
      stream: _firestoreService.getAllProductsStream(),
      builder: (context, snapshot) {
        final products = snapshot.data ?? [];
        final displayProducts = products.take(_displayLimit).toList();
        final hasMoreProducts = products.length > _displayLimit;

        // ⭐ AJOUTEZ CETTE LIGNE CRITIQUE :
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
                      color:
                          isDark ? AppColors.textSecondary : Colors.grey[600],
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        if (products.isEmpty) {
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
                      color:
                          isDark ? AppColors.textSecondary : Colors.grey[600],
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: [
            // En-tête
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Text(
                'Annonces',
                style: TextStyle(
                  color: isDark ? AppColors.textWhite : AppColors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // 🎯 GridView OPTIMISÉ avec le nouveau widget
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: displayProducts.length,
                itemBuilder: (context, index) {
                  final product = displayProducts[index];

                  return _buildOptimizedProductCard(
                    product: product,
                    isDark: isDark,
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // Indicateur de chargement
            if (_isLoadingMore) ...[
              const SizedBox(height: 8),
              const Center(
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
              const SizedBox(height: 16),
            ],

            // Message de fin
            if (!hasMoreProducts && displayProducts.length > 6) ...[
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

            const SizedBox(height: 20),
          ],
        );
      },
    );
  }

  void _loadMoreProductsAutomatically() {
    if (!_isLoadingMore && _hasMoreProducts) {
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
            // Vérifier s'il y a encore des produits ET si on approche de la fin
            if (_hasMoreProducts &&
                !_isLoadingMore &&
                scrollInfo.metrics.pixels >=
                    scrollInfo.metrics.maxScrollExtent * 0.8) {
              _loadMoreProductsAutomatically();
            }
            return false;
          },
          child: CustomScrollView(
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
                      // Section produits intégrée dans le scroll principal
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
                      (context) => FavoriteProductsScreen(
                        favoriteProductIds: _favoriteProductIds,
                        onToggleFavorite: _toggleFavorite,
                      ),
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
