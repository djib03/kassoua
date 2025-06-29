import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kassoua/constants/colors.dart';
import 'package:kassoua/constants/size.dart';
import 'package:kassoua/views/product_screen.dart';

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
          color: isDark ? AppColors.dark : Colors.white,
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
            // Image section - taille flexible
            Expanded(
              flex: 3, // Conserver le flex 3 pour l'image
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color:
                          isDark
                              ? AppColors.grey.withOpacity(0.3)
                              : Colors.grey[100],
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Iconsax.image,
                        color: AppColors.primary,
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
            // Text section
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ), // Reduced padding
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment:
                      MainAxisAlignment
                          .spaceEvenly, // Changed from spaceBetween
                  children: [
                    Flexible(
                      child: Text(
                        product['name'],
                        style: TextStyle(
                          color: isDark ? AppColors.textWhite : AppColors.black,
                          fontSize:
                              13, // Slightly increased for better readability
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          Iconsax.location,
                          size: 12,
                          color:
                              isDark
                                  ? AppColors.textSecondary
                                  : Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            product['location'] ?? 'Non spécifié',
                            style: TextStyle(
                              color:
                                  isDark
                                      ? AppColors.textSecondary
                                      : Colors.grey[600],
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${product['price'].toInt()} FCFA',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize:
                            13, // Slightly increased for better readability
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
