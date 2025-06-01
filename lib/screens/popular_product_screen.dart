import 'package:flutter/material.dart';
import 'package:kassoua/constants/colors.dart';
import 'package:kassoua/constants/size.dart';
import 'package:kassoua/themes/customs/text_theme.dart';
import 'package:iconsax/iconsax.dart';
import 'product_screen.dart';

class PopularProductScreen extends StatelessWidget {
  PopularProductScreen({Key? key}) : super(key: key);

  // Ajoutez cette liste de produits dans la classe
  final List<Map<String, dynamic>> _allProducts = List.generate(
    20, // Nombre total de produits
    (index) => {
      'id': '${index + 1}',
      'name': 'Produit ${index + 1}',
      'price': (index + 1) * 100,
      'description': 'Description du produit ${index + 1}...',
    },
  );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? DMColors.black : DMColors.white,
      appBar: AppBar(
        backgroundColor: isDark ? DMColors.black : DMColors.white,
        title: Text(
          'Produits Populaires',
          style:
              isDark
                  ? TTextTheme.darkTextTheme.headlineSmall?.copyWith(
                    color: DMColors.textWhite,
                  )
                  : TTextTheme.lightTextTheme.headlineSmall?.copyWith(
                    color: DMColors.black,
                  ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? DMColors.white : DMColors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(DMSizes.defaultSpace),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: _allProducts.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              final product = Product(
                id: _allProducts[index]['id'],
                name: _allProducts[index]['name'],
                description: _allProducts[index]['description'],
                price: _allProducts[index]['price'].toDouble(),
                quantity: 1,
                imageUrl: 'https://via.placeholder.com/150',
                sellerId: 'seller_123',
                sellerName: 'Vendeur',
              );
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProductDetailPage(product: product),
                ),
              );
            },
            child: Card(
              color: isDark ? DMColors.dark : DMColors.white,
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color:
                            isDark
                                ? DMColors.grey.withOpacity(0.3)
                                : DMColors.grey.withOpacity(0.1),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Iconsax.image,
                          color: DMColors.primary,
                          size: DMSizes.iconLg,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(DMSizes.sm),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Produit ${index + 1}',
                          style:
                              isDark
                                  ? TTextTheme.darkTextTheme.titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: DMColors.textWhite,
                                      )
                                  : TTextTheme.lightTextTheme.titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: DMColors.black,
                                      ),
                        ),
                        const SizedBox(height: DMSizes.xs),
                        Text(
                          '${(index + 1) * 100} FCFA',
                          style:
                              isDark
                                  ? TTextTheme.darkTextTheme.bodyMedium
                                      ?.copyWith(
                                        color: DMColors.primary,
                                        fontWeight: FontWeight.bold,
                                      )
                                  : TTextTheme.lightTextTheme.bodyMedium
                                      ?.copyWith(
                                        color: DMColors.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
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
    );
  }
}
