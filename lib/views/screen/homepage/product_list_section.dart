import 'package:flutter/material.dart';
import 'package:kassoua/models/product.dart';
import 'package:kassoua/services/firestore_service.dart';
import 'package:kassoua/constants/colors.dart';
import 'package:kassoua/views/widgets/product_card.dart';
import 'package:kassoua/models/image_produit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProductListSection extends StatefulWidget {
  final List<Produit> products;
  final bool isDark;
  final Function(String) onToggleFavorite;
  final ScrollController scrollController;
  final ValueNotifier<Set<String>> favoriteProductIdsNotifier;
  final void Function(Produit)? onProductTap;
  final bool showSkeletonLoader; // ← Nouveau paramètre

  const ProductListSection({
    required this.products,
    required this.isDark,
    required this.onToggleFavorite,
    required this.favoriteProductIdsNotifier,
    required this.scrollController,
    this.onProductTap,
    this.showSkeletonLoader = false, // ← Paramètre par défaut
    super.key,
  });

  @override
  State<ProductListSection> createState() => ProductListSectionState();
}

class ProductListSectionState extends State<ProductListSection> {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final Map<String, int> _imageRetryCount = {};
  final int _maxRetries = 3;

  void _clearImageCache() {
    _productImageCache.clear();
    _imageRetryCount.clear();
  }

  final Map<String, Future<Map<String, dynamic>>> _productDataCache = {};
  final Map<String, String> _productLocationCache = {};
  final Map<String, ImageProduit?> _productImageCache = {};

  @override
  void dispose() {
    _productDataCache.clear();
    _productLocationCache.clear();
    _productImageCache.clear();
    super.dispose();
  }

  // ✅ NOUVEAU: Widget skeleton pour un produit
  Widget _buildSkeletonProductCard() {
    return Container(
      decoration: BoxDecoration(
        color: widget.isDark ? Colors.grey[800] : Colors.grey[300],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Image skeleton
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                color: widget.isDark ? Colors.grey[700] : Colors.grey[400],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
            ),
          ),
          // Contenu skeleton
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nom du produit
                  Container(
                    height: 16,
                    decoration: BoxDecoration(
                      color:
                          widget.isDark ? Colors.grey[700] : Colors.grey[400],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Prix
                  Container(
                    height: 14,
                    width: 80,
                    decoration: BoxDecoration(
                      color:
                          widget.isDark ? Colors.grey[700] : Colors.grey[400],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Location
                  Container(
                    height: 12,
                    width: 100,
                    decoration: BoxDecoration(
                      color:
                          widget.isDark ? Colors.grey[700] : Colors.grey[400],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // En-tête
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child:
              widget.showSkeletonLoader
                  ? Container(
                    height: 24,
                    width: 150,
                    decoration: BoxDecoration(
                      color:
                          widget.isDark ? Colors.grey[700] : Colors.grey[400],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  )
                  : Text(
                    'Annonces',
                    style: TextStyle(
                      color:
                          widget.isDark ? AppColors.textWhite : AppColors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
        ),

        // GridView avec skeleton ou contenu réel
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child:
              widget.showSkeletonLoader
                  ? GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.75,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                    itemCount: 6, // Nombre fixe pour le skeleton
                    itemBuilder: (context, index) {
                      return _buildSkeletonProductCard();
                    },
                  )
                  : ValueListenableBuilder<Set<String>>(
                    valueListenable: widget.favoriteProductIdsNotifier,
                    builder: (context, favoriteIds, child) {
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.75,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                        itemCount: widget.products.length,
                        itemBuilder: (context, index) {
                          final product = widget.products[index];
                          return _buildOptimizedProductCard(
                            product,
                            widget.isDark,
                          );
                        },
                      );
                    },
                  ),
        ),

        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildOptimizedProductCard(Produit product, bool isDark) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getCachedProductData(product),
      builder: (context, snapshot) {
        return ValueListenableBuilder<Set<String>>(
          valueListenable: widget.favoriteProductIdsNotifier,
          builder: (context, favoriteIds, child) {
            // ✅ REMPLACER CircularProgressIndicator par skeleton
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildSkeletonProductCard();
            }

            if (snapshot.hasError) {
              return GestureDetector(
                onTap:
                    widget.onProductTap != null
                        ? () => widget.onProductTap!(product)
                        : null,
                child: ProductCard(
                  product: _convertProductToMap(product),
                  isDark: isDark,
                  isFavorite: favoriteIds.contains(product.id),
                  isProcessing: false,
                  onToggleFavorite: () => widget.onToggleFavorite(product.id),
                ),
              );
            }

            return GestureDetector(
              onTap:
                  widget.onProductTap != null
                      ? () => widget.onProductTap!(product)
                      : null,
              child: ProductCard(
                product: snapshot.data ?? _convertProductToMap(product),
                isDark: isDark,
                isFavorite: favoriteIds.contains(product.id),
                isProcessing: false,
                onToggleFavorite: () => widget.onToggleFavorite(product.id),
              ),
            );
          },
        );
      },
    );
  }

  Future<Map<String, dynamic>> _getCachedProductData(Produit product) {
    if (!_productDataCache.containsKey(product.id)) {
      _productDataCache[product
          .id] = _convertProductToMapWithAddressAndImagesCached(product);
    }
    return _productDataCache[product.id]!;
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

  Future<String> _getProductLocation(String? adresseId) async {
    if (adresseId == null || adresseId.isEmpty) {
      return 'Localisation non spécifiée';
    }

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

      _productLocationCache[adresseId] = location;
      return location;
    } catch (e) {
      print('Erreur lors de la récupération de l\'adresse: $e');
      return 'Localisation non disponible';
    }
  }

  Future<ImageProduit?> getImagePrincipale(String produitId) async {
    if (_productImageCache.containsKey(produitId) &&
        !_imageRetryCount.containsKey(produitId)) {
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

      _productImageCache[produitId] = image;
      _imageRetryCount.remove(produitId);
      return image;
    } catch (e) {
      print('Erreur lors du chargement de l\'image: $e');

      final currentRetries = _imageRetryCount[produitId] ?? 0;
      if (currentRetries < _maxRetries) {
        _imageRetryCount[produitId] = currentRetries + 1;
        await Future.delayed(Duration(seconds: currentRetries + 1));
        return getImagePrincipale(produitId);
      } else {
        _productImageCache[produitId] = null;
        return null;
      }
    }
  }

  void refreshProductData() {
    setState(() {
      _productDataCache.clear();
      _clearImageCache();
    });
  }
}
