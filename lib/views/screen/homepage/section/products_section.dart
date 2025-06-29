import 'package:flutter/material.dart';
import 'package:kassoua/constants/colors.dart';
import 'package:kassoua/services/firestore_service.dart';
import 'package:kassoua/models/product.dart';
import 'package:kassoua/models/favori.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kassoua/views/widgets/product_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../models/image_produit.dart';

class ProductsSection extends StatefulWidget {
  final bool isDark;

  const ProductsSection({Key? key, required this.isDark}) : super(key: key);

  @override
  State<ProductsSection> createState() => _ProductsSectionState();
}

class _ProductsSectionState extends State<ProductsSection> {
  final FirestoreService _firestoreService = FirestoreService();
  final Set<String> _favoriteProductIds = <String>{};
  String? _currentUserId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  int _displayLimit = 6;
  static const int _loadMoreIncrement = 6;
  bool _isLoadingMore = false;
  final ScrollController _scrollController = ScrollController();

  // ✅ NOUVELLE MÉTHODE : Récupérer les images d'un produit

  // void _loadMoreProducts() {
  //   setState(() {
  //     _displayLimit += _loadMoreIncrement;
  //   });
  // }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      // Vérifier si on est proche du bas (80% de la hauteur scrollée)
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent * 0.8) {
        _loadMoreProductsAutomatically();
      }
    });
  }

  void _loadMoreProductsAutomatically() {
    if (!_isLoadingMore) {
      setState(() {
        _isLoadingMore = true;
        _displayLimit += _loadMoreIncrement;
      });

      // Petit délai pour l'animation de chargement
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _isLoadingMore = false;
          });
        }
      });
    }
  }

  Future<ImageProduit?> getImagePrincipale(String produitId) async {
    final query =
        await _firestore
            .collection('imagesProduits')
            .where('produitId', isEqualTo: produitId)
            .limit(1)
            .get();

    if (query.docs.isNotEmpty) {
      final doc = query.docs.first;
      return ImageProduit.fromMap(doc.data(), doc.id);
    }
    return null;
  }

  Future<String> _getProductLocation(String? adresseId) async {
    if (adresseId == null || adresseId.isEmpty) {
      return 'Localisation non spécifiée';
    }

    try {
      final adresse = await _firestoreService.getAdresseById(adresseId);
      if (adresse != null) {
        if (adresse.ville != null && adresse.ville!.isNotEmpty) {
          return adresse.ville!;
        } else if (adresse.quartier != null && adresse.quartier!.isNotEmpty) {
          return adresse.quartier!;
        } else {
          String description = adresse.description;
          if (description.length > 20) {
            description = '${description.substring(0, 20)}...';
          }
          return description;
        }
      }
    } catch (e) {
      print('Erreur lors de la récupération de l\'adresse: $e');
    }

    return 'Localisation non disponible';
  }

  // ✅ MÉTHODE AMÉLIORÉE : Convertir un produit avec adresse et images complètes
  Future<Map<String, dynamic>> _convertProductToMapWithAddressAndImages(
    Produit product,
  ) async {
    String location = await _getProductLocation(product.adresseId);
    ImageProduit? productImages = await getImagePrincipale(product.id);

    return {
      'id': product.id,
      'name': product.nom,
      'price': product.prix,
      'location': location,
      'images': productImages, // Toutes les images
      'description': product.description,
      'etat': product.etat,
      'estnegociable': product.estnegociable,
    };
  }

  @override
  void initState() {
    super.initState();
    _initializeUser();
    _setupScrollListener();
  }

  @override
  void dispose() {
    _scrollController.dispose(); // ✅ IMPORTANT : Nettoyer le contrôleur
    super.dispose();
  }

  void _initializeUser() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _currentUserId = user.uid;
      _loadFavorites();
    }
  }

  void _loadFavorites() {
    if (_currentUserId != null) {
      _firestoreService.getFavoris(_currentUserId!).listen((favoris) {
        setState(() {
          _favoriteProductIds.clear();
          _favoriteProductIds.addAll(favoris.map((f) => f.produitId));
        });
      });
    }
  }

  bool _isFavorite(String productId) {
    return _favoriteProductIds.contains(productId);
  }

  Future<void> _onToggleFavorite(String productId) async {
    if (_currentUserId == null) {
      _showSnackBar('Veuillez vous connecter pour gérer les favoris');
      return;
    }

    try {
      if (_isFavorite(productId)) {
        await _firestoreService.removeFavori(_currentUserId!, productId);
        _showSnackBar('Produit retiré des favoris');
      } else {
        final newFavori = Favori(
          id: '',
          userId: _currentUserId!,
          produitId: productId,
          dateAjout: DateTime.now(),
        );
        await _firestoreService.addFavori(newFavori);
        _showSnackBar('Produit ajouté aux favoris');
      }
    } catch (e) {
      print('Erreur favoris: $e');
      _showSnackBar('Erreur lors de la modification des favoris');
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ✅ En-tête avec padding amélioré
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(
            16,
            16,
            16,
            12,
          ), // Padding optimisé
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Annonces',
                style: TextStyle(
                  color: widget.isDark ? AppColors.textWhite : AppColors.black,
                  fontSize: 20, // Taille légèrement augmentée
                  fontWeight: FontWeight.bold,
                ),
              ),
              // Optionnel : bouton pour remonter en haut
              IconButton(
                onPressed: () {
                  _scrollController.animateTo(
                    0,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                  );
                },
                icon: Icon(
                  Icons.keyboard_arrow_up,
                  color:
                      widget.isDark
                          ? AppColors.textSecondary
                          : Colors.grey[600],
                ),
                tooltip: 'Remonter en haut',
              ),
            ],
          ),
        ),

        // ✅ STRUCTURE AMÉLIORÉE avec gestion complète du scroll
        Expanded(
          child: StreamBuilder<List<Produit>>(
            stream: _firestoreService.getAllProductsStream(),
            builder: (context, snapshot) {
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
                          color:
                              widget.isDark
                                  ? AppColors.textSecondary
                                  : Colors.grey[600],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Erreur de chargement',
                          style: TextStyle(
                            color:
                                widget.isDark
                                    ? AppColors.textWhite
                                    : AppColors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Impossible de charger les produits',
                          style: TextStyle(
                            color:
                                widget.isDark
                                    ? AppColors.textSecondary
                                    : Colors.grey[600],
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              final products = snapshot.data ?? [];

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
                          color:
                              widget.isDark
                                  ? AppColors.textSecondary
                                  : Colors.grey[600],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aucun produit disponible',
                          style: TextStyle(
                            color:
                                widget.isDark
                                    ? AppColors.textWhite
                                    : AppColors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Les produits apparaîtront ici une fois ajoutés',
                          style: TextStyle(
                            color:
                                widget.isDark
                                    ? AppColors.textSecondary
                                    : Colors.grey[600],
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              final displayProducts = products.take(_displayLimit).toList();
              final hasMoreProducts = products.length > _displayLimit;

              return SingleChildScrollView(
                controller: _scrollController,
                physics:
                    const AlwaysScrollableScrollPhysics(), // ✅ Scroll toujours activé
                padding: const EdgeInsets.only(
                  left: 16,
                  right: 16,
                  bottom:
                      24, // ✅ IMPORTANT : Padding bottom pour éviter la coupure
                ),
                child: Column(
                  children: [
                    // ✅ GridView avec gestion améliorée
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.75,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                      itemCount: displayProducts.length,
                      itemBuilder: (context, index) {
                        final product = displayProducts[index];

                        return FutureBuilder<Map<String, dynamic>>(
                          future: _convertProductToMapWithAddressAndImages(
                            product,
                          ), // ✅ Méthode avec images
                          builder: (context, addressSnapshot) {
                            if (addressSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              // Affichage temporaire pendant le chargement
                              final tempProductMap = _convertProductToMap(
                                product,
                              );
                              return ProductCard(
                                product: tempProductMap,
                                isDark: widget.isDark,
                                isFavorite: _isFavorite(product.id),
                                onToggleFavorite:
                                    () => _onToggleFavorite(product.id),
                              );
                            }

                            if (addressSnapshot.hasError) {
                              print(
                                'Erreur lors du chargement du produit ${product.id}: ${addressSnapshot.error}',
                              );
                              final fallbackProductMap = _convertProductToMap(
                                product,
                              );
                              return ProductCard(
                                product: fallbackProductMap,
                                isDark: widget.isDark,
                                isFavorite: _isFavorite(product.id),
                                onToggleFavorite:
                                    () => _onToggleFavorite(product.id),
                              );
                            }

                            final productMapWithAddressAndImages =
                                addressSnapshot.data ??
                                _convertProductToMap(product);

                            return ProductCard(
                              product: productMapWithAddressAndImages,
                              isDark: widget.isDark,
                              isFavorite: _isFavorite(product.id),
                              onToggleFavorite:
                                  () => _onToggleFavorite(product.id),
                            );
                          },
                        );
                      },
                    ),

                    // ✅ Espacement entre la grille et les éléments suivants
                    const SizedBox(height: 16),

                    // ✅ Indicateur de chargement automatique
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

                    // ✅ Message de fin si plus de produits
                    if (!hasMoreProducts && displayProducts.length > 6) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 20,
                        ),
                        decoration: BoxDecoration(
                          color:
                              widget.isDark
                                  ? Colors.grey[800]
                                  : Colors.grey[100],
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
                                color:
                                    widget.isDark
                                        ? AppColors.textWhite
                                        : AppColors.black,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // ✅ IMPORTANT : Espacement final pour éviter la coupure
                    const SizedBox(height: 20),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
