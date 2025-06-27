import 'package:flutter/material.dart';
import 'package:kassoua/constants/colors.dart';
import 'package:kassoua/models/categorie.dart';
import 'package:kassoua/models/product.dart';
import 'package:kassoua/services/categorie_service.dart';
import 'package:kassoua/services/firestore_service.dart';
import 'package:skeletonizer/skeletonizer.dart';

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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? DMColors.black : DMColors.lightGrey,
      appBar: AppBar(
        title: Text(
          widget.category.nom,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
        backgroundColor: isDark ? DMColors.black : DMColors.lightGrey,
      ),
      body: StreamBuilder<List<Categorie>>(
        stream: _categoryService.getSubCategoriesStream(widget.category.id),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString());
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingState();
          }

          final subCategories = snapshot.data ?? [];

          if (subCategories.isEmpty) {
            return _buildEmptySubCategoriesState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: subCategories.length,
            itemBuilder: (context, index) {
              final subCategory = subCategories[index];
              return _buildSubCategorySection(subCategory);
            },
          );
        },
      ),
    );
  }

  Widget _buildSubCategorySection(Categorie subCategory) {
    return Container(
      margin: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header avec titre et "View all"
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  subCategory.nom,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color:
                        Theme.of(context).brightness == Brightness.dark
                            ? DMColors.textWhite
                            : DMColors.black,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Navigation vers tous les produits de cette catégorie
                  },
                  child: Text(
                    'View all',
                    style: TextStyle(
                      color: DMColors.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Grille horizontale des produits (reste identique)
          StreamBuilder<List<Produit>>(
            stream: _productService.getProductsByCategoryStream(subCategory.id),
            builder: (context, productSnapshot) {
              // ... reste du code identique

              if (productSnapshot.hasError) {
                return _buildProductErrorState();
              }

              if (productSnapshot.connectionState == ConnectionState.waiting) {
                return _buildProductLoadingState();
              }

              final products = productSnapshot.data ?? [];

              if (products.isEmpty) {
                return _buildEmptyProductsState();
              }

              return SizedBox(
                height: 280,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return _buildProductCard(product);
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Produit product) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 180, // Réduire la largeur
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: isDark ? DMColors.dark : Colors.white,
        borderRadius: BorderRadius.circular(20), // Plus arrondi
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _onProductTap(product),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Container image avec badge et cœur
                Stack(
                  children: [
                    Container(
                      height: 120,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: DMColors.primary.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child:
                          product.imageUrl != null
                              ? ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.network(
                                  product.imageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return _buildPlaceholderImage();
                                  },
                                ),
                              )
                              : _buildPlaceholderImage(),
                    ),

                    // Icône cœur pour favoris
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.favorite_border,
                          color: isDark ? DMColors.textWhite : DMColors.black,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Nom et marque du produit
                Text(
                  product.nom,
                  style: TextStyle(
                    color: isDark ? DMColors.textWhite : DMColors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const Spacer(),

                // Prix avec ancien prix barré si applicable
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      height: 140,
      width: double.infinity,
      decoration: BoxDecoration(
        color: DMColors.primary.withOpacity(0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Icon(Icons.image_outlined, color: DMColors.primary, size: 48),
    );
  }

  Color _getEtatColor(String etat) {
    switch (etat.toLowerCase()) {
      case 'neuf':
        return Colors.green;
      case 'tres_bon_etat':
        return Colors.blue;
      case 'bon_etat':
        return Colors.orange;
      case 'etat_correct':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildLoadingState() {
    return Skeletonizer(
      enabled: true,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 3,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Nom de sous-catégorie'),
                const SizedBox(height: 12),
                SizedBox(
                  height: 280,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: 3,
                    itemBuilder: (context, index) {
                      return Container(
                        width: 200,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Container(
                              height: 140,
                              width: double.infinity,
                              color: Colors.grey,
                            ),
                            Padding(
                              padding: EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Nom du produit'),
                                  SizedBox(height: 8),
                                  Text('État'),
                                  SizedBox(height: 8),
                                  Text('Prix'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductLoadingState() {
    return Skeletonizer(
      enabled: true,
      child: SizedBox(
        height: 280,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: 3,
          itemBuilder: (context, index) {
            return Container(
              width: 200,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Container(
                    height: 140,
                    width: double.infinity,
                    color: Colors.grey,
                  ),
                  Padding(
                    padding: EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Nom du produit'),
                        SizedBox(height: 8),
                        Text('État'),
                        SizedBox(height: 8),
                        Text('Prix'),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptySubCategoriesState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.category_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Aucune sous-catégorie',
            style: TextStyle(
              color: isDark ? DMColors.textWhite : Colors.grey[600],
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'disponible pour cette catégorie',
            style: TextStyle(
              color:
                  isDark
                      ? DMColors.textWhite.withOpacity(0.7)
                      : Colors.grey[500],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyProductsState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 280,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? DMColors.dark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.1), width: 1),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              'Aucun produit',
              style: TextStyle(
                color: isDark ? DMColors.textWhite : Colors.grey[600],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'disponible pour le moment',
              style: TextStyle(
                color:
                    isDark
                        ? DMColors.textWhite.withOpacity(0.7)
                        : Colors.grey[500],
                fontSize: 12,
              ),
            ),
          ],
        ),
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
              color: isDark ? DMColors.textWhite : Colors.grey[600],
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
                      ? DMColors.textWhite.withOpacity(0.7)
                      : Colors.grey[500],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProductErrorState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 280,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? DMColors.dark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withOpacity(0.2), width: 1),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
            const SizedBox(height: 12),
            Text(
              'Erreur de chargement',
              style: TextStyle(
                color: isDark ? DMColors.textWhite : Colors.grey[600],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'des produits',
              style: TextStyle(
                color:
                    isDark
                        ? DMColors.textWhite.withOpacity(0.7)
                        : Colors.grey[500],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onProductTap(Produit product) {
    // Navigation vers la page de détail du produit
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => ProductDetailScreen(product: product),
    //   ),
    // );

    // Temporaire : afficher un snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Produit sélectionné: ${product.nom}'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
