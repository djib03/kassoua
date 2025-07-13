import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kassoua/services/favori_service.dart';
import 'package:kassoua/models/image_produit.dart';
import 'package:kassoua/models/product.dart';
import 'package:kassoua/constants/colors.dart';
import 'package:skeletonizer/skeletonizer.dart';

class FavoriteProductsScreen extends StatefulWidget {
  final String? userId;

  const FavoriteProductsScreen({Key? key, this.userId}) : super(key: key);

  @override
  State<FavoriteProductsScreen> createState() => _FavoriteProductsScreenState();
}

class _FavoriteProductsScreenState extends State<FavoriteProductsScreen>
    with TickerProviderStateMixin {
  final favoriService _favoriService = favoriService();
  List<Produit> _favoriteProducts = [];
  bool _isLoading = true;
  bool _isInitialized = false;
  String? _currentUserId;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

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

  void _initializeUser() {
    try {
      // Utiliser l'userId fourni ou celui de l'utilisateur connecté
      _currentUserId = widget.userId ?? FirebaseAuth.instance.currentUser?.uid;

      if (_currentUserId != null) {
        _loadFavoriteProducts();
      }

      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      print('Erreur lors de l\'initialisation de l\'utilisateur: $e');
      setState(() {
        _isInitialized = true;
        _isLoading = false;
      });
    }
  }

  void _loadFavoriteProducts() {
    if (_currentUserId == null) return;

    setState(() {
      _isLoading = true;
    });

    _favoriService.getFavoris(_currentUserId!).listen((favoris) async {
      try {
        if (favoris.isNotEmpty) {
          final productIds = favoris.map((f) => f.produitId).toList();
          final products = await _favoriService.fetchProductsByIds(productIds);

          if (mounted) {
            setState(() {
              _favoriteProducts =
                  products
                      .map(
                        (productData) =>
                            Produit.fromMap(productData, productData['id']),
                      )
                      .toList();
              _isLoading = false;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _favoriteProducts = [];
              _isLoading = false;
            });
          }
        }
      } catch (e) {
        print('Erreur lors du chargement des favoris: $e');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    });
  }

  Future<void> _removeFavorite(String productId) async {
    if (_currentUserId == null) return;

    try {
      await _favoriService.removeFavori(_currentUserId!, productId);
      _showSnackBar('Produit retiré des favoris', Colors.green);
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

  bool _isDarkMode(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  @override
  void dispose() {
    _animationController.dispose();
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
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          color: AppColors.primary,
          backgroundColor: isDark ? AppColors.black : Colors.white,
          child: _buildBody(isDark),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark) {
    return AppBar(
      title: const Text(
        'Mes Favoris',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      foregroundColor: isDark ? Colors.white : Colors.black,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
    );
  }

  Widget _buildBody(bool isDark) {
    // Cas 1: Utilisateur non connecté
    if (_currentUserId == null) {
      return _buildNotLoggedInState(isDark);
    }

    // Cas 2: Chargement en cours
    if (_isLoading) {
      return _buildSkeletonLoader(isDark);
    }

    // Cas 3: Aucun produit favori
    if (_favoriteProducts.isEmpty) {
      return _buildEmptyState(isDark);
    }

    // Cas 4: Affichage des favoris
    return _buildFavoritesList(isDark);
  }

  Widget _buildNotLoggedInState(bool isDark) {
    return Center(
      child: SingleChildScrollView(
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
                  Icons.person_outline,
                  size: 64,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
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
                'Vous devez être connecté pour voir vos produits favoris',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  // Naviguer vers la page de connexion
                  // Navigator.pushNamed(context, '/login');
                },
                icon: const Icon(Icons.login),
                label: const Text('Se connecter'),
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
      ),
    );
  }

  Widget _buildSkeletonLoader(bool isDark) {
    return Skeletonizer(
      enabled: true,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 6,
        itemBuilder: (context, index) {
          return _buildSkeletonProductCard(isDark);
        },
      ),
    );
  }

  Widget _buildSkeletonProductCard(bool isDark) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      color: isDark ? Colors.grey[800] : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Image skeleton
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[700] : Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(width: 16),
            // Contenu skeleton
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 16,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[700] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 14,
                    width: 200,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[700] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 16,
                    width: 120,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[700] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ],
              ),
            ),
            // Bouton skeleton
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[700] : Colors.grey[300],
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: SingleChildScrollView(
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
                onPressed: () {
                  Navigator.pop(context);
                },
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
      ),
    );
  }

  Widget _buildFavoritesList(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _favoriteProducts.length,
      itemBuilder: (context, index) {
        final product = _favoriteProducts[index];
        return _buildProductCard(product, isDark);
      },
    );
  }

  Widget _buildProductCard(Produit product, bool isDark) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
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
          padding: const EdgeInsets.all(16),
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
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(product.etat),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            product.etatText,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
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
                            color: isDark ? Colors.grey[400] : Colors.grey[500],
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
    );
  }

  Widget _buildProductImage(String productId, bool isDark) {
    return FutureBuilder<ImageProduit?>(
      future: _favoriService.getImagePrincipale(productId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Skeletonizer(
            enabled: true,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[700] : Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: snapshot.data!.url,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              placeholder:
                  (context, url) => Skeletonizer(
                    enabled: true,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[700] : Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
              errorWidget:
                  (context, url, error) => Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[700] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.broken_image,
                      size: 30,
                      color: isDark ? Colors.grey[500] : Colors.grey[400],
                    ),
                  ),
            ),
          );
        }

        // Pas d'image ou erreur
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
      },
    );
  }

  Color _getStatusColor(String etat) {
    switch (etat.toLowerCase()) {
      case 'neuf':
        return Colors.green;
      case 'tres_bon_etat':
        return Colors.lightGreen;
      case 'bon_etat':
        return Colors.orange;
      case 'etat_correct':
        return Colors.deepOrange;
      default:
        return Colors.blue;
    }
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

  Future<void> _onRefresh() async {
    try {
      setState(() {
        _isLoading = true;
      });

      _loadFavoriteProducts();

      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        _showSnackBar('Favoris actualisés', Colors.green);
      }
    } catch (e) {
      print('Erreur lors du rafraîchissement: $e');
      if (mounted) {
        _showSnackBar('Erreur lors de l\'actualisation', Colors.red);
      }
    }
  }
}
