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
  // final Set<String> favoriteProductIds;
  final Function(String) onToggleFavorite;
  final ScrollController scrollController;
  final ValueNotifier<Set<String>> favoriteProductIdsNotifier; // ← Ajouté
  final void Function(Produit)? onProductTap; // ← Ajouté

  const ProductListSection({
    required this.products,
    required this.isDark,
    // required this.favoriteProductIds,
    required this.onToggleFavorite,
    required this.favoriteProductIdsNotifier, // Supprimé car non utilisé
    required this.scrollController,
    this.onProductTap, // ← Ajouté
    super.key,
  });

  @override
  State<ProductListSection> createState() => ProductListSectionState();
}

class ProductListSectionState extends State<ProductListSection> {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ✅ NOUVEAU: Cache avec retry pour les images
  final Map<String, int> _imageRetryCount = {};
  final int _maxRetries = 3;

  // ✅ NOUVEAU: Méthode pour nettoyer le cache des images
  void _clearImageCache() {
    _productImageCache.clear();
    _imageRetryCount.clear();
  }

  // Cache pour optimiser les requêtes
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // En-tête
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Text(
            'Annonces',
            style: TextStyle(
              color: widget.isDark ? AppColors.textWhite : AppColors.black,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // GridView optimisé avec ValueListenableBuilder
        ValueListenableBuilder<Set<String>>(
          valueListenable: widget.favoriteProductIdsNotifier,
          builder: (context, favoriteIds, child) {
            return Padding(
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
                itemCount: widget.products.length,
                itemBuilder: (context, index) {
                  final product = widget.products[index];

                  // ✅ UTILISER _buildOptimizedProductCard au lieu de ProductCard directement
                  return _buildOptimizedProductCard(product, widget.isDark);
                },
              ),
            );
          },
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
            // Pendant le chargement, afficher une version basique
            if (snapshot.connectionState == ConnectionState.waiting) {
              return GestureDetector(
                // ✅ AJOUTER GestureDetector
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

            // En cas d'erreur, utiliser les données de base
            if (snapshot.hasError) {
              return GestureDetector(
                // ✅ AJOUTER GestureDetector
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

            // Données complètes disponibles
            return GestureDetector(
              // ✅ AJOUTER GestureDetector
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

  Future<ImageProduit?> getImagePrincipale(String produitId) async {
    // Vérifier le cache seulement si pas d'erreur précédente
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

      // ✅ Mettre en cache et réinitialiser le compteur d'erreurs
      _productImageCache[produitId] = image;
      _imageRetryCount.remove(produitId);
      return image;
    } catch (e) {
      print('Erreur lors du chargement de l\'image: $e');

      // ✅ Gestion des retry
      final currentRetries = _imageRetryCount[produitId] ?? 0;
      if (currentRetries < _maxRetries) {
        _imageRetryCount[produitId] = currentRetries + 1;
        // Retry après un délai
        await Future.delayed(Duration(seconds: currentRetries + 1));
        return getImagePrincipale(produitId);
      } else {
        // Échec définitif
        _productImageCache[produitId] = null;
        return null;
      }
    }
  }

  // ✅ NOUVEAU: Méthode pour forcer le rechargement des données
  void refreshProductData() {
    setState(() {
      _productDataCache.clear();
      _clearImageCache();
    });
  }
}
