import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kassoua/services/favori_service.dart';
import 'package:kassoua/models/image_produit.dart';
import 'package:kassoua/models/product.dart';
import 'package:kassoua/constants/colors.dart';
import 'dart:async';
import 'package:kassoua/controllers/auth_controller.dart';
import 'package:provider/provider.dart';
import 'package:kassoua/views/screen/auth/auth_screen_selection.dart';

class FavoriteProductsScreen extends StatefulWidget {
  final String? userId;

  const FavoriteProductsScreen({Key? key, this.userId}) : super(key: key);

  @override
  State<FavoriteProductsScreen> createState() => _FavoriteProductsScreenState();
}

class _FavoriteProductsScreenState extends State<FavoriteProductsScreen>
    with TickerProviderStateMixin {
  final favoriService _favoriService = favoriService();

  // États de données
  List<Produit> _favoriteProducts = [];
  Map<String, ImageProduit?> _productImages = {}; // Cache des images
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _currentUserId;
  String? _error;

  // Contrôleurs d'animation
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Stream subscription pour écouter les changements
  StreamSubscription? _favoriteSubscription;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeUser();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  void _initializeUser() {
    try {
      _currentUserId = widget.userId ?? FirebaseAuth.instance.currentUser?.uid;

      setState(() {
        _isInitialized = true;
      });

      if (_currentUserId != null) {
        _loadFavoriteProducts();
      } else {
        // Démarrer l'animation même si pas connecté
        _animationController.forward();
      }
    } catch (e) {
      print('Erreur lors de l\'initialisation de l\'utilisateur: $e');
      setState(() {
        _isInitialized = true;
        _error = 'Erreur d\'initialisation';
      });
    }
  }

  Future<void> _loadFavoriteProducts() async {
    if (_currentUserId == null) return;

    // Ne pas afficher le loading si on a déjà des données
    if (_favoriteProducts.isEmpty) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      // Annuler l'ancienne subscription
      _favoriteSubscription?.cancel();

      // Écouter les changements de favoris
      _favoriteSubscription = _favoriService
          .getFavoris(_currentUserId!)
          .listen(
            (favoris) async {
              try {
                if (favoris.isNotEmpty) {
                  final productIds = favoris.map((f) => f.produitId).toList();
                  final products = await _favoriService.fetchProductsByIds(
                    productIds,
                  );

                  // Convertir les données en objets Produit
                  final favoriteProducts =
                      products
                          .map(
                            (productData) =>
                                Produit.fromMap(productData, productData['id']),
                          )
                          .toList();

                  if (mounted) {
                    setState(() {
                      _favoriteProducts = favoriteProducts;
                      _isLoading = false;
                      _error = null;
                    });

                    // Commencer l'animation une fois les données chargées
                    _animationController.forward();

                    // Précharger les images en arrière-plan
                    _preloadImages();
                  }
                } else {
                  if (mounted) {
                    setState(() {
                      _favoriteProducts = [];
                      _isLoading = false;
                      _error = null;
                    });
                    _animationController.forward();
                  }
                }
              } catch (e) {
                print('Erreur lors du chargement des favoris: $e');
                if (mounted) {
                  setState(() {
                    _isLoading = false;
                    _error = 'Erreur lors du chargement';
                  });
                }
              }
            },
            onError: (error) {
              print('Erreur stream favoris: $error');
              if (mounted) {
                setState(() {
                  _isLoading = false;
                  _error = 'Erreur de connexion';
                });
              }
            },
          );
    } catch (e) {
      print('Erreur lors de l\'initialisation du stream: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Erreur de connexion';
        });
      }
    }
  }

  // Précharger les images pour améliorer les performances
  void _preloadImages() {
    for (final product in _favoriteProducts) {
      if (!_productImages.containsKey(product.id)) {
        _loadProductImage(product.id);
      }
    }
  }

  Future<void> _loadProductImage(String productId) async {
    try {
      final image = await _favoriService.getImagePrincipale(productId);
      if (mounted) {
        setState(() {
          _productImages[productId] = image;
        });
      }
    } catch (e) {
      print('Erreur lors du chargement de l\'image pour $productId: $e');
      // Stocker null pour éviter de refaire la requête
      if (mounted) {
        setState(() {
          _productImages[productId] = null;
        });
      }
    }
  }

  Future<void> _removeFavorite(String productId) async {
    if (_currentUserId == null) return;

    try {
      await _favoriService.removeFavori(_currentUserId!, productId);

      // Supprimer l'image du cache
      _productImages.remove(productId);

      _showSnackBar('Produit retiré des favoris', AppColors.primary);
    } catch (e) {
      print('Erreur lors de la suppression du favori: $e');
      _showSnackBar('Erreur lors de la suppression', Colors.red);
    }
  }

  void _showSnackBar(String message, Color backgroundColor) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: backgroundColor,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  Future<void> _onRefresh() async {
    if (_currentUserId == null) {
      _showSnackBar('Veuillez vous connecter pour actualiser', Colors.orange);
      return;
    }

    try {
      // Vider le cache d'images pour forcer le rechargement
      _productImages.clear();

      // Recharger les données
      await _loadFavoriteProducts();

      if (mounted) {
        _showSnackBar('Favoris actualisés', AppColors.primary);
      }
    } catch (e) {
      print('Erreur lors du rafraîchissement: $e');
      if (mounted) {
        _showSnackBar('Erreur lors de l\'actualisation', Colors.red);
      }
    }
  }

  void _handleLogin() {
    // Naviguer vers la page de connexion
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const AuthSelectionScreen()),
    );
  }

  bool _isDarkMode(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  @override
  void dispose() {
    _animationController.dispose();
    _favoriteSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _isDarkMode(context);

    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[50],
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[50],
      appBar: _buildAppBar(isDark),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: AppColors.primary,
        backgroundColor: isDark ? AppColors.black : Colors.white,
        child: _buildBody(isDark),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark) {
    return AppBar(
      title: Text(
        'Mes Favoris',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : Colors.black,
          fontSize: 24,
        ),
      ),
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      foregroundColor: isDark ? Colors.white : Colors.black,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      actions: [
        if (_currentUserId != null && _favoriteProducts.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_favoriteProducts.length}',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBody(bool isDark) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          // Bannière d'avertissement si pas connecté
          if (_currentUserId == null) _buildNotLoggedInBanner(isDark),

          // Contenu principal
          SizedBox(
            height:
                _currentUserId == null
                    ? MediaQuery.of(context).size.height -
                        200 // Ajuster selon la hauteur de la bannière
                    : MediaQuery.of(context).size.height - 140,
            child: _buildMainContent(isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildNotLoggedInBanner(bool isDark) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
              isDark
                  ? Colors.orange.shade900.withOpacity(0.2)
                  : Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.orange.shade700 : Colors.orange.shade200,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.orange.shade600, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Connexion requise',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color:
                          isDark
                              ? Colors.orange.shade300
                              : Colors.orange.shade800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Connectez-vous pour voir vos produits favoris',
                    style: TextStyle(
                      color:
                          isDark
                              ? Colors.orange.shade400
                              : Colors.orange.shade700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _handleLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              child: const Text('Se connecter', style: TextStyle(fontSize: 14)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(bool isDark) {
    // CORRECTION: Utiliser Provider.of avec context pour obtenir l'instance
    final authController = Provider.of<AuthController>(context);

    // CORRECTION: Inverser la logique - si PAS connecté, afficher l'état guest
    if (!authController.isLoggedInSync) {
      return FadeTransition(
        opacity: _fadeAnimation,
        child: _buildEmptyStateForGuest(isDark),
      );
    }

    // Cas 2: Erreur
    if (_error != null) {
      return _buildErrorState(isDark);
    }

    // Cas 3: Chargement initial
    if (_isLoading && _favoriteProducts.isEmpty) {
      return _buildLoadingState(isDark);
    }

    // Cas 4: Aucun produit favori (utilisateur connecté)
    if (_favoriteProducts.isEmpty) {
      return FadeTransition(
        opacity: _fadeAnimation,
        child: _buildEmptyStateForUser(isDark),
      );
    }

    // Cas 5: Affichage des favoris
    return FadeTransition(
      opacity: _fadeAnimation,
      child: _buildFavoritesList(isDark),
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppColors.primary),
          const SizedBox(height: 16),
          Text(
            'Chargement de vos favoris...',
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red[400],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Erreur de chargement',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _error ?? 'Une erreur inattendue s\'est produite',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _loadFavoriteProducts,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyStateForGuest(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Iconsax.user,
                size: 64,
                color: isDark ? Colors.grey[500] : Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Connexion requise',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Connectez-vous pour voir vos produits préférés',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _handleLogin,
                  icon: const Icon(Icons.login),
                  label: const Text('Se connecter'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyStateForUser(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.favorite_border,
                size: 64,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Aucun produit favori',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Ajoutez des produits à vos favoris\npour les retrouver facilement ici',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.explore),
              label: const Text('Découvrir des produits'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoritesList(bool isDark) {
    return Column(
      children: [
        // Indicateur de chargement en cours si refresh
        if (_isLoading)
          Container(
            padding: const EdgeInsets.all(8),
            child: const LinearProgressIndicator(
              color: AppColors.primary,
              backgroundColor: Colors.transparent,
            ),
          ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _favoriteProducts.length,
            itemBuilder: (context, index) {
              final product = _favoriteProducts[index];
              return _buildProductCard(product, isDark, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProductCard(Produit product, bool isDark, int index) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300 + (index * 100)),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 2,
        color: isDark ? Colors.grey[800] : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: () {
            // Navigation vers les détails du produit
            // Navigator.push(context, MaterialPageRoute(
            //   builder: (context) => ProductDetailScreen(product: product),
            // ));
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                // Image du produit
                _buildProductImage(product.id, isDark),
                const SizedBox(width: 16),
                // Informations du produit
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.nom,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            '${product.prix.toStringAsFixed(0)} FCFA',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.visibility,
                            size: 14,
                            color: isDark ? Colors.grey[400] : Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${product.vues} vues',
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  isDark ? Colors.grey[400] : Colors.grey[500],
                            ),
                          ),
                          if (product.estnegociable) ...[
                            const SizedBox(width: 8),
                            Icon(
                              Icons.handshake,
                              size: 14,
                              color: Colors.orange.shade600,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              'Négociable',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // Bouton supprimer des favoris
                IconButton(
                  onPressed: () => _showRemoveDialog(product, isDark),
                  icon: const Icon(Icons.favorite, color: Colors.red),
                  tooltip: 'Retirer des favoris',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductImage(String productId, bool isDark) {
    // Utiliser le cache d'abord
    if (_productImages.containsKey(productId)) {
      final cachedImage = _productImages[productId];
      if (cachedImage != null) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(
            imageUrl: cachedImage.url,
            width: 80,
            height: 80,
            fit: BoxFit.cover,
            placeholder: (context, url) => _buildImagePlaceholder(isDark),
            errorWidget: (context, url, error) => _buildImageError(isDark),
          ),
        );
      } else {
        // null dans le cache = pas d'image
        return _buildImageError(isDark);
      }
    }

    // Charger l'image si pas en cache
    _loadProductImage(productId);
    return _buildImagePlaceholder(isDark);
  }

  Widget _buildImagePlaceholder(bool isDark) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[700] : Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildImageError(bool isDark) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[700] : Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.image,
        size: 40,
        color: isDark ? Colors.grey[500] : Colors.grey[400],
      ),
    );
  }

  void _showRemoveDialog(Produit product, bool isDark) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isDark ? Colors.grey[800] : Colors.white,
          title: Text(
            'Retirer des favoris',
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
          ),
          content: Text(
            'Voulez-vous vraiment retirer "${product.nom}" de vos favoris ?',
            style: TextStyle(
              color: isDark ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Annuler',
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _removeFavorite(product.id);
              },
              child: const Text('Retirer', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
