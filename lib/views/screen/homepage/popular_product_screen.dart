import 'package:flutter/material.dart';
import 'package:kassoua/constants/colors.dart';
import 'package:kassoua/constants/size.dart';
import 'package:kassoua/themes/customs/text_theme.dart';
import 'package:kassoua/themes/widget/product_card.dart';

class PopularProductScreen extends StatefulWidget {
  PopularProductScreen({Key? key}) : super(key: key);

  @override
  State<PopularProductScreen> createState() => _PopularProductScreenState();
}

class _PopularProductScreenState extends State<PopularProductScreen> {
  // Liste des produits avec des données plus réalistes
  final List<Map<String, dynamic>> _allProducts = [
    {
      'id': 1,
      'name': 'T-shirt Premium Coton',
      'price': 15000,
      'description': 'T-shirt en coton premium, confortable et durable',
      'location': 'Niamey, Niger',
      'isLiked': false,
    },
    {
      'id': 2,
      'name': 'Jeans Slim Fit Homme',
      'price': 45000,
      'description': 'Jeans slim fit de qualité supérieure',
      'location': 'Dosso, Niger',
      'isLiked': false,
    },
    {
      'id': 3,
      'name': 'Sneakers Sport Confort',
      'price': 65000,
      'description': 'Sneakers confortables pour le sport et la marche',
      'location': 'Maradi, Niger',
      'isLiked': true,
    },
    {
      'id': 4,
      'name': 'Veste En Cuir Vintage',
      'price': 85000,
      'description': 'Veste en cuir véritable, style vintage',
      'location': 'Tahoua, Niger',
      'isLiked': false,
    },
    {
      'id': 5,
      'name': 'Robe Élégante Soirée',
      'price': 35000,
      'description': 'Robe élégante pour occasions spéciales',
      'location': 'Zinder, Niger',
      'isLiked': false,
    },
    {
      'id': 6,
      'name': 'Chemise Business Homme',
      'price': 25000,
      'description': 'Chemise professionnelle pour le bureau',
      'location': 'Agadez, Niger',
      'isLiked': false,
    },
    {
      'id': 7,
      'name': 'Sac à Main Cuir',
      'price': 55000,
      'description': 'Sac à main en cuir véritable',
      'location': 'Tillabéri, Niger',
      'isLiked': false,
    },
    {
      'id': 8,
      'name': 'Montre Connectée',
      'price': 120000,
      'description': 'Montre intelligente avec nombreuses fonctionnalités',
      'location': 'Niamey, Niger',
      'isLiked': false,
    },
    {
      'id': 9,
      'name': 'Casquette Sport',
      'price': 8000,
      'description': 'Casquette sportive ajustable',
      'location': 'Diffa, Niger',
      'isLiked': false,
    },
    {
      'id': 10,
      'name': 'Pantalon Chino Slim',
      'price': 32000,
      'description': 'Pantalon chino moderne et confortable',
      'location': 'Dosso, Niger',
      'isLiked': false,
    },
    {
      'id': 11,
      'name': 'Polo Classique',
      'price': 18000,
      'description': 'Polo classique en coton piqué',
      'location': 'Maradi, Niger',
      'isLiked': false,
    },
    {
      'id': 12,
      'name': 'Sandales Cuir Homme',
      'price': 28000,
      'description': 'Sandales en cuir confortables',
      'location': 'Tahoua, Niger',
      'isLiked': false,
    },
    {
      'id': 13,
      'name': 'Blouse Femme Élégante',
      'price': 22000,
      'description': 'Blouse élégante pour femme',
      'location': 'Zinder, Niger',
      'isLiked': false,
    },
    {
      'id': 14,
      'name': 'Chaussures Bureau',
      'price': 48000,
      'description': 'Chaussures de bureau en cuir',
      'location': 'Agadez, Niger',
      'isLiked': false,
    },
    {
      'id': 15,
      'name': 'Sweat-shirt Hoodie',
      'price': 28000,
      'description': 'Sweat-shirt à capuche confortable',
      'location': 'Tillabéri, Niger',
      'isLiked': false,
    },
    {
      'id': 16,
      'name': 'Jupe Midi Femme',
      'price': 20000,
      'description': 'Jupe midi moderne et stylée',
      'location': 'Niamey, Niger',
      'isLiked': false,
    },
    {
      'id': 17,
      'name': 'Ceinture Cuir Premium',
      'price': 15000,
      'description': 'Ceinture en cuir de qualité supérieure',
      'location': 'Diffa, Niger',
      'isLiked': false,
    },
    {
      'id': 18,
      'name': 'Portefeuille Homme',
      'price': 12000,
      'description': 'Portefeuille en cuir avec plusieurs compartiments',
      'location': 'Dosso, Niger',
      'isLiked': false,
    },
    {
      'id': 19,
      'name': 'Écharpe Laine',
      'price': 18000,
      'description': 'Écharpe en laine douce et chaude',
      'location': 'Maradi, Niger',
      'isLiked': false,
    },
    {
      'id': 20,
      'name': 'Lunettes de Soleil',
      'price': 25000,
      'description': 'Lunettes de soleil avec protection UV',
      'location': 'Tahoua, Niger',
      'isLiked': false,
    },
  ];

  void _toggleFavorite(int productId) {
    setState(() {
      final productIndex = _allProducts.indexWhere((p) => p['id'] == productId);
      if (productIndex != -1) {
        _allProducts[productIndex]['isLiked'] =
            !_allProducts[productIndex]['isLiked'];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.black : AppColors.white,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.black : AppColors.white,
        elevation: 0,
        title: Text(
          'Produits Populaires',
          style:
              isDark
                  ? TTextTheme.darkTextTheme.headlineSmall?.copyWith(
                    color: AppColors.textWhite,
                  )
                  : TTextTheme.lightTextTheme.headlineSmall?.copyWith(
                    color: AppColors.black,
                  ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? AppColors.white : AppColors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(DMSizes.defaultSpace),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.8, // Ajusté pour une meilleure proportion
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: _allProducts.length,
        itemBuilder: (context, index) {
          final product = _allProducts[index];
          return ProductCard(
            product: product,
            isDark: isDark,
            isFavorite: product['isLiked'] ?? false,
            onToggleFavorite: () => _toggleFavorite(product['id']),
          );
        },
      ),
    );
  }
}
