import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kassoua/constants/colors.dart';
import 'package:kassoua/constants/size.dart';
import 'package:kassoua/screens/product_screen.dart';

class ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final bool isDark;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;

  const ProductCard({
    Key? key,
    required this.product,
    required this.isDark,
    required this.isFavorite,
    required this.onToggleFavorite,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final productObj = Product(
          id: product['id'],
          name: product['name'],
          description: 'Description du produit...',
          price: product['price'].toDouble(),
          quantity: 1,
          imageUrl: 'https://via.placeholder.com/150',
          sellerId: 'seller_123',
          sellerName: 'Vendeur',
        );
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailPage(product: productObj),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? DMColors.dark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black26 : Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color:
                          isDark
                              ? DMColors.grey.withOpacity(0.3)
                              : Colors.grey[100],
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
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
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: onToggleFavorite,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color:
                              isFavorite
                                  ? Colors.red.withOpacity(0.1)
                                  : Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                          border:
                              isFavorite
                                  ? Border.all(
                                    color: Colors.red.withOpacity(0.3),
                                  )
                                  : null,
                        ),
                        child: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? Colors.red : Colors.grey,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              // flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product['name'],
                      style: TextStyle(
                        color: isDark ? DMColors.textWhite : DMColors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Text(
                      '${product['price'].toInt()} FCFA',
                      style: const TextStyle(
                        color: DMColors.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
