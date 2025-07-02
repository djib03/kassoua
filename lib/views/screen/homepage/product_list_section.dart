import 'package:flutter/material.dart';
import 'package:kassoua/models/product.dart';
import 'package:kassoua/services/firestore_service.dart';
import 'package:kassoua/constants/colors.dart';
import 'package:kassoua/views/widgets/product_card.dart';
import 'package:kassoua/models/image_produit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kassoua/views/screen/product_detail.acheteur.dart';

class ProductListSection extends StatefulWidget {
  final List<Produit> products;
  final bool isDark;
  // final Set<String> favoriteProductIds;
  final Function(String) onToggleFavorite;
  final ScrollController scrollController;
  final Function(Produit)? onProductTap;
  final ValueNotifier<Set<String>> favoriteProductIdsNotifier;
  const ProductListSection({
    required this.products,
    required this.isDark,
    required this.favoriteProductIdsNotifier, // Changé
    this.onProductTap, // ✅ NOUVEAU paramètre
    required this.onToggleFavorite,
    required this.scrollController,
    super.key,
  });

  @override
  State<ProductListSection> createState() => _ProductListSectionState();
}

class _ProductListSectionState extends State<ProductListSection> {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

        // GridView optimisé
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
            itemCount: widget.products.length,
            itemBuilder: (context, index) {
              final product = widget.products[index];
              final productMap = {
                'id': product.id,
                'name': product.nom,
                'price': product.prix,
                'images': ImageProduit,
                // ✅ Ajouter d'autres champs nécessaires
              };

              return ProductCard(
                product: productMap,
                isDark: widget.isDark,
                isFavorite: widget.favoriteProductIdsNotifier.value.contains(
                  product.id,
                ),
                onToggleFavorite: () => widget.onToggleFavorite(product.id),
                // ✅ AJOUTER : Callback de navigation
                onProductTap:
                    widget.onProductTap != null
                        ? (_) => widget.onProductTap!(product)
                        : null,
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
            // Pendant le chargement, afficher une version basique
            if (snapshot.connectionState == ConnectionState.waiting) {
              return ProductCard(
                product: _convertProductToMap(product),
                isDark: isDark,
                isFavorite: favoriteIds.contains(product.id),
                isProcessing: false,
                onToggleFavorite: () => widget.onToggleFavorite(product.id),
              );
            }

            // En cas d'erreur, utiliser les données de base
            if (snapshot.hasError) {
              return ProductCard(
                product: _convertProductToMap(product),
                isDark: isDark,
                isFavorite: favoriteIds.contains(product.id),
                isProcessing: false,
                onToggleFavorite: () => widget.onToggleFavorite(product.id),
              );
            }

            // Données complètes disponibles
            return ProductCard(
              product: snapshot.data ?? _convertProductToMap(product),
              isDark: isDark,
              isFavorite: favoriteIds.contains(product.id),
              isProcessing: false,
              onToggleFavorite: () => widget.onToggleFavorite(product.id),
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
}
