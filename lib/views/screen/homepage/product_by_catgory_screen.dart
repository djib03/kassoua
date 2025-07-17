import 'package:flutter/material.dart';
import 'package:kassoua/constants/colors.dart';
import 'package:kassoua/models/adresse.dart';
import 'package:kassoua/models/categorie.dart';
import 'package:kassoua/models/product.dart';
import 'package:kassoua/models/image_produit.dart';
import 'package:kassoua/services/categorie_service.dart';
import 'package:kassoua/services/firestore_service.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:kassoua/services/favori_service.dart';

class ProductsByCategoryScreen extends StatefulWidget {
  final Categorie category;

  const ProductsByCategoryScreen({super.key, required this.category});

  @override
  State<ProductsByCategoryScreen> createState() =>
      _ProductsByCategoryScreenState();
}

class _ProductsByCategoryScreenState extends State<ProductsByCategoryScreen> {
  final CategoryService _categoryService = CategoryService();
  final FirestoreService _productService = FirestoreService();
  final favoriService _favoriService = favoriService();

  String _selectedSubCategory = 'Tous';
  List<Categorie> _subCategories = [];
  bool _isLoadingSubCategories = true;
  bool _hasSubCategoriesError = false;

  @override
  void initState() {
    super.initState();
    _loadSubCategories();
  }

  void _loadSubCategories() async {
    try {
      setState(() {
        _isLoadingSubCategories = true;
        _hasSubCategoriesError = false;
      });

      final subCategories =
          await _categoryService
              .getSubCategoriesStream(widget.category.id)
              .first;

      setState(() {
        _subCategories = subCategories;
        _isLoadingSubCategories = false;
      });
    } catch (e) {
      setState(() {
        _hasSubCategoriesError = true;
        _isLoadingSubCategories = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.black : AppColors.lightGrey,
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              Icons.menu_book,
              color: isDark ? Colors.white : Colors.black,
              size: 24,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.category.nom,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
        backgroundColor: isDark ? AppColors.black : AppColors.lightGrey,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_hasSubCategoriesError) {
      return _buildErrorState("Erreur lors du chargement des sous-catégories");
    }

    if (_isLoadingSubCategories) {
      return _buildFullLoadingState();
    }

    // Si pas de sous-catégories, afficher directement les produits
    if (_subCategories.isEmpty) {
      return StreamBuilder<List<Produit>>(
        stream: _productService.getProductsByCategoryStream(widget.category.id),
        builder: (context, productSnapshot) {
          if (productSnapshot.hasError) {
            return _buildErrorState(productSnapshot.error.toString());
          }

          if (productSnapshot.connectionState == ConnectionState.waiting) {
            return _buildProductsLoadingState();
          }

          final products = productSnapshot.data ?? [];

          if (products.isEmpty) {
            return _buildEmptyProductsState();
          }

          return _buildProductsList(products);
        },
      );
    }

    // Avec sous-catégories
    return Column(
      children: [
        _buildSubCategoryChips(),
        Expanded(child: _buildFilteredContent()),
      ],
    );
  }

  Widget _buildSubCategoryChips() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chips = ['Tous', ..._subCategories.map((cat) => cat.nom)];

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: chips.length,
        itemBuilder: (context, index) {
          final chip = chips[index];
          final isSelected = _selectedSubCategory == chip;

          return Container(
            margin: const EdgeInsets.only(right: 12),
            child: FilterChip(
              label: Text(
                chip,
                style: TextStyle(
                  color:
                      isSelected
                          ? Colors.white
                          : (isDark ? Colors.white70 : Colors.black87),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedSubCategory = chip;
                  });
                }
              },
              backgroundColor: isDark ? AppColors.dark : Colors.white,
              selectedColor: AppColors.primary,
              checkmarkColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                  color:
                      isSelected
                          ? AppColors.primary
                          : Colors.grey.withOpacity(0.3),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilteredContent() {
    if (_selectedSubCategory == 'Tous') {
      // Afficher tous les produits de la catégorie parent
      return StreamBuilder<List<Produit>>(
        stream: _productService.getProductsByCategoryStream(widget.category.id),
        builder: (context, productSnapshot) {
          if (productSnapshot.hasError) {
            return _buildErrorState(productSnapshot.error.toString());
          }

          if (productSnapshot.connectionState == ConnectionState.waiting) {
            return _buildProductsLoadingState();
          }

          final products = productSnapshot.data ?? [];

          if (products.isEmpty) {
            return _buildEmptyProductsState();
          }

          return _buildProductsList(products);
        },
      );
    } else {
      // Afficher seulement les produits de la sous-catégorie sélectionnée
      final selectedSubCategory = _subCategories.firstWhere(
        (cat) => cat.nom == _selectedSubCategory,
        orElse: () => _subCategories.first,
      );

      return StreamBuilder<List<Produit>>(
        stream: _productService.getProductsByCategoryStream(
          selectedSubCategory.id,
        ),
        builder: (context, productSnapshot) {
          if (productSnapshot.hasError) {
            return _buildErrorState(productSnapshot.error.toString());
          }

          if (productSnapshot.connectionState == ConnectionState.waiting) {
            return _buildProductsLoadingState();
          }

          final products = productSnapshot.data ?? [];

          if (products.isEmpty) {
            return _buildEmptyProductsState();
          }

          return _buildProductsList(products);
        },
      );
    }
  }

  Widget _buildProductsList(List<Produit> products) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Liste des produits (${products.length})',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white70 : Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: products.length,
            itemBuilder: (context, index) {
              return _buildProductCard(products[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProductCard(Produit product) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      color: isDark ? AppColors.dark : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _onProductTap(product),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Image du produit
              _buildProductImage(product.id),
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
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Localisation
                    FutureBuilder<Adresse?>(
                      future: _productService.getAdresseById(product.adresseId),
                      builder: (context, snapshot) {
                        if (snapshot.hasData &&
                            (snapshot.data?.quartier != null ||
                                snapshot.data?.ville != null)) {
                          final adresse = snapshot.data!;
                          return Text(
                            '${adresse.quartier ?? ''} ${adresse.ville ?? ''}'
                                .trim(),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatPrice(product.prix),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (product.estnegociable)
                      Row(
                        children: [
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
                      ),
                  ],
                ),
              ),
              // Bouton favoris
              IconButton(
                onPressed: () => _toggleFavorite(product),
                icon: const Icon(Icons.favorite_border, color: Colors.grey),
                tooltip: 'Ajouter aux favoris',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductImage(String productId) {
    return FutureBuilder<ImageProduit?>(
      future: _favoriService.getImagePrincipale(productId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
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
                  (context, url) => Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
              errorWidget:
                  (context, url, error) => Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.broken_image,
                      size: 30,
                      color: Colors.grey.shade400,
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
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.image, size: 40, color: Colors.grey.shade400),
        );
      },
    );
  }

  String _formatPrice(double price) {
    // Formatage du prix avec espaces comme séparateurs de milliers
    final formatter = price.toStringAsFixed(0);
    final reversed = formatter.split('').reversed.join();
    final withSpaces = reversed.replaceAllMapped(
      RegExp(r'(\d{3})(?=\d)'),
      (match) => '${match.group(1)} ',
    );
    return '${withSpaces.split('').reversed.join()} FCFA';
  }

  Widget _buildProductsLoadingState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Titre avec skeleton
        Padding(
          padding: const EdgeInsets.all(16),
          child: Skeletonizer(
            enabled: true,
            child: Container(height: 20, width: 150, color: Colors.grey[300]),
          ),
        ),
        // Liste des produits avec skeleton
        Expanded(
          child: Skeletonizer(
            enabled: true,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 5,
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.grey[300],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                height: 16,
                                width: double.infinity,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 8),
                              Container(
                                height: 12,
                                width: 150,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 8),
                              Container(
                                height: 14,
                                width: 100,
                                color: Colors.grey[300],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFullLoadingState() {
    return Column(
      children: [
        // Chips skeleton
        Container(
          height: 60,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 4,
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.only(right: 12),
                child: Skeletonizer(
                  enabled: true,
                  child: Chip(
                    label: Container(
                      width: 60,
                      height: 20,
                      color: Colors.grey[300],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        // Products skeleton
        Expanded(child: _buildProductsLoadingState()),
      ],
    );
  }

  Widget _buildEmptyProductsState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Aucun produit disponible',
            style: TextStyle(
              color: isDark ? AppColors.textWhite : Colors.grey[600],
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'pour le moment',
            style: TextStyle(
              color:
                  isDark
                      ? AppColors.textWhite.withAlpha((0.7 * 255).toInt())
                      : Colors.grey[500],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 80, color: Colors.red[400]),
          const SizedBox(height: 16),
          Text(
            'Erreur de chargement',
            style: TextStyle(
              color: isDark ? AppColors.textWhite : Colors.grey[600],
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              color:
                  isDark
                      ? AppColors.textWhite.withOpacity(0.7)
                      : Colors.grey[500],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _onProductTap(Produit product) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Produit sélectionné: ${product.nom}'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _toggleFavorite(Produit product) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.nom} ajouté aux favoris'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
