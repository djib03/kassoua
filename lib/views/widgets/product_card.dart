import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kassoua/constants/colors.dart';
import 'package:kassoua/constants/size.dart';
import 'package:kassoua/views/product_screen.dart';
import 'package:kassoua/models/image_produit.dart';

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

  // ✅ FONCTION SÉCURISÉE POUR CONVERTIR LE PRIX
  String _formatPrice(dynamic price) {
    if (price == null) return '0';

    try {
      if (price is String) {
        final parsedPrice = double.tryParse(price);
        if (parsedPrice == null ||
            parsedPrice.isNaN ||
            parsedPrice.isInfinite) {
          return '0';
        }
        return parsedPrice.toInt().toString();
      } else if (price is num) {
        if (price.isNaN || price.isInfinite) {
          return '0';
        }
        return price.toInt().toString();
      }
      return '0';
    } catch (e) {
      print('Erreur lors du formatage du prix: $e');
      return '0';
    }
  }

  // ✅ FONCTION POUR FORMATER LA DATE D'AJOUT
  String _formatDateAjout(dynamic dateAjout) {
    if (dateAjout == null) return '';

    try {
      DateTime date;
      if (dateAjout is DateTime) {
        date = dateAjout;
      } else if (dateAjout is String) {
        date = DateTime.parse(dateAjout);
      } else {
        return '';
      }

      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        if (difference.inHours == 0) {
          if (difference.inMinutes == 0) {
            return 'À l\'instant';
          }
          return 'Il y a ${difference.inMinutes}min';
        }
        return 'Il y a ${difference.inHours}h';
      } else if (difference.inDays == 1) {
        return 'Hier';
      } else if (difference.inDays < 7) {
        return 'Il y a ${difference.inDays}j';
      } else if (difference.inDays < 30) {
        final weeks = (difference.inDays / 7).floor();
        return 'Il y a ${weeks}sem';
      } else if (difference.inDays < 365) {
        final months = (difference.inDays / 30).floor();
        return 'Il y a ${months}mois';
      } else {
        final years = (difference.inDays / 365).floor();
        return 'Il y a ${years}an${years > 1 ? 's' : ''}';
      }
    } catch (e) {
      print('Erreur lors du formatage de la date: $e');
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ RÉCUPÉRATION SÉCURISÉE DES DONNÉES
    final ImageProduit? productImage = product['images'] as ImageProduit?;
    final String? imageUrl = productImage?.url;
    final String formattedPrice = _formatPrice(product['price']);
    final String dateText = _formatDateAjout(product['dateAjout']);

    return GestureDetector(
      onTap: () {
        // ✅ CRÉATION SÉCURISÉE DU PRODUIT
        try {
          final productObj = Product(
            id: product['id'] ?? '',
            name: product['name'] ?? 'Produit sans nom',
            description: product['description'] ?? 'Description du produit...',
            price: double.tryParse(formattedPrice) ?? 0.0,
            imageUrl: imageUrl ?? 'https://via.placeholder.com/150',
            sellerId: product['sellerId'] ?? 'seller_unknown',
            sellerName: product['sellerName'] ?? 'Vendeur',
          );

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailPage(product: productObj),
            ),
          );
        } catch (e) {
          print('Erreur lors de la navigation: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erreur lors de l\'ouverture du produit'),
              duration: Duration(seconds: 2),
            ),
          );
        }
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
            // ✅ SECTION IMAGE AVEC DATE D'AJOUT
            Expanded(
              flex: 3,
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
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      child:
                          imageUrl != null && imageUrl.isNotEmpty
                              ? Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                                errorBuilder: (context, error, stackTrace) {
                                  print('Erreur chargement image: $error');
                                  return _buildImagePlaceholder();
                                },
                                loadingBuilder: (
                                  context,
                                  child,
                                  loadingProgress,
                                ) {
                                  if (loadingProgress == null) return child;
                                  return Center(
                                    child: CircularProgressIndicator(
                                      color: AppColors.primary,
                                      strokeWidth: 2,
                                      value:
                                          loadingProgress.expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  loadingProgress
                                                      .expectedTotalBytes!
                                              : null,
                                    ),
                                  );
                                },
                              )
                              : _buildImagePlaceholder(),
                    ),
                  ),

                  // ✅ BADGE DATE D'AJOUT (en haut à gauche)
                  if (dateText.isNotEmpty)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          dateText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),

                  // ✅ BADGE ÉTAT (au milieu à gauche si pas de date)
                  if (product['etat'] != null && dateText.isEmpty)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getEtatColor(product['etat']),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          product['etat'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                  // ✅ BADGE ÉTAT (décalé si il y a une date)
                  if (product['etat'] != null && dateText.isNotEmpty)
                    Positioned(
                      top: 35,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _getEtatColor(product['etat']),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          product['etat'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                  // ✅ BOUTON FAVORI (en haut à droite)
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
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
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

            // ✅ SECTION TEXTE AMÉLIORÉE
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Nom du produit
                    Flexible(
                      child: Text(
                        product['name'] ?? 'Produit sans nom',
                        style: TextStyle(
                          color: isDark ? AppColors.textWhite : AppColors.black,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    // Localisation
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

                    // Prix avec négociable
                    Row(
                      children: [
                        Text(
                          '$formattedPrice FCFA',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (product['estnegociable'] == true) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Nég.',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 9,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
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

  // ✅ WIDGET PLACEHOLDER POUR IMAGE
  Widget _buildImagePlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Iconsax.image,
            color: AppColors.primary.withOpacity(0.5),
            size: DMSizes.iconLg,
          ),
          const SizedBox(height: 4),
          Text(
            'Pas d\'image',
            style: TextStyle(
              color: AppColors.primary.withOpacity(0.7),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  // ✅ COULEUR SELON L'ÉTAT
  Color _getEtatColor(String etat) {
    switch (etat.toLowerCase()) {
      case 'neuf':
        return Colors.green;
      case 'très bon état':
        return Colors.blue;
      case 'bon état':
        return Colors.orange;
      case 'état moyen':
        return Colors.amber;
      case 'mauvais état':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
