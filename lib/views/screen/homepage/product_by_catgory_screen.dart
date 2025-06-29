import 'package:flutter/material.dart';
import 'package:kassoua/constants/colors.dart';
import 'package:kassoua/models/adresse.dart';
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
      backgroundColor: isDark ? AppColors.black : AppColors.lightGrey,
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
        backgroundColor: isDark ? AppColors.black : AppColors.lightGrey,
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
                            ? AppColors.textWhite
                            : AppColors.black,
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
              if (productSnapshot.hasError) {
                return _buildProductErrorState();
              }

              if (productSnapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                );
              }

              final products = productSnapshot.data ?? [];
              if (products.isEmpty) {
                return _buildEmptyProductsState();
              }

              return SizedBox(
                height: 160,

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
      width: 240, // LARGEUR AUGMENTÉE
      height: 140, // HAUTEUR RÉDUITE pour format rectangulaire
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.dark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
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
            child: Row(
              // LAYOUT HORIZONTAL
              children: [
                // IMAGE (à gauche)
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[100],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child:
                        product.imageUrl != null
                            ? Image.network(
                              product.imageUrl!,
                              fit: BoxFit.cover,
                            )
                            : _buildPlaceholderImage(),
                  ),
                ),

                const SizedBox(width: 12),

                // INFOS (à droite)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // NOM
                      Text(
                        product.nom,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),

                        overflow: TextOverflow.ellipsis,
                      ),

                      // LOCALISATION
                      FutureBuilder<Adresse?>(
                        future: _productService.getAdresseById(
                          product.adresseId,
                        ),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const SizedBox(
                              child: LinearProgressIndicator(),
                            );
                          }
                          if (snapshot.hasData &&
                              (snapshot.data?.quartier != null ||
                                  snapshot.data?.ville != null)) {
                            final adresse = snapshot.data!;
                            return Text(
                              '${adresse.quartier ?? ''} ${adresse.ville ?? ''}'
                                  .trim(),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),

                      // PRIX
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      height: 70,
      width: 40,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Icon(Icons.image_outlined, color: AppColors.primary, size: 48),
    );
  }

  Widget _buildLoadingState() {
    return Skeletonizer(
      enabled: true,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 3, // Nombre de sous-catégories fictives
        itemBuilder: (context, index) {
          return _buildSubCategorySection(
            Categorie(
              id: 'skeleton_$index',
              nom: 'Nom de catégorie skeleton', // Texte qui sera skeletonisé
              parentId: '',
              icone: '', // Valeur fictive ou par défaut
              ordre: 0, // Valeur fictive ou par défaut
              isActive: true, // Valeur fictive ou par défaut
              createdAt: DateTime.now(), // Valeur fictive ou par défaut
            ),
          );
        },
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
              color: isDark ? AppColors.textWhite : Colors.grey[600],
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
                      ? AppColors.textWhite.withOpacity(0.7)
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
      height: 130,
      padding: const EdgeInsets.all(27),
      decoration: BoxDecoration(
        color: isDark ? AppColors.dark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.1), width: 1),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            Icon(Icons.inventory_2_outlined, size: 41, color: Colors.grey[400]),
            Text(
              'Aucun produit',
              style: TextStyle(
                color: isDark ? AppColors.textWhite : Colors.grey[600],
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              'disponible pour le moment',
              style: TextStyle(
                color:
                    isDark
                        ? AppColors.textWhite.withAlpha((0.7 * 255).toInt())
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

  Widget _buildProductErrorState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 280,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.dark : Colors.white,
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
                color: isDark ? AppColors.textWhite : Colors.grey[600],
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
                        ? AppColors.textWhite.withOpacity(0.7)
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
