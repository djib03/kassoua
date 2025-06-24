import 'package:flutter/material.dart';
import 'package:kassoua/themes/widget/product_card.dart';
import 'package:kassoua/constants/colors.dart';
import 'package:kassoua/data/home_data.dart';
import 'package:kassoua/screens/homepage/popular_product_screen.dart';

class ProductsSection extends StatelessWidget {
  final bool isDark;
  final bool Function(String) isFavorite;
  final void Function(String) onToggleFavorite;

  const ProductsSection({
    Key? key,
    required this.isDark,
    required this.isFavorite,
    required this.onToggleFavorite,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Produits populaires',
                style: TextStyle(
                  color: isDark ? DMColors.textWhite : DMColors.black,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PopularProductScreen(),
                    ),
                  );
                },

                label: const Text(
                  'Voir tout',
                  style: TextStyle(
                    color: DMColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: HomeData.products.length,
            itemBuilder: (context, index) {
              final product = HomeData.products[index];
              return ProductCard(
                product: product,
                isDark: isDark,
                isFavorite: isFavorite(product['id']),
                onToggleFavorite: () => onToggleFavorite(product['id']),
              );
            },
          ),
        ),
      ],
    );
  }
}
