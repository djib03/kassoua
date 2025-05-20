import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:iconsax/iconsax.dart';
import 'package:dm_shop/constants/colors.dart';
import 'package:dm_shop/constants/size.dart';
import 'package:dm_shop/themes/customs/text_theme.dart';
import 'package:dm_shop/screens/product_screen.dart';

class HomePage extends StatelessWidget {
  HomePage({Key? key}) : super(key: key);

  bool _isDarkMode(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  // Données simulées pour les catégories (locales, hors ligne)
  final List<Map<String, dynamic>> _categories = [
    {'name': 'Électronique', 'icon': Iconsax.mobile},
    {
      'name': 'Mode',
      'icon': Iconsax.activity1,
    }, // Corrigé l'icône pour plus de cohérence
    {'name': 'Maison', 'icon': Iconsax.home},
    {'name': 'Sports', 'icon': Iconsax.activity},
    {'name': 'Jouets', 'icon': Iconsax.game},
  ];

  // Données simulées pour les produits
  final List<Map<String, dynamic>> _products = [
    {
      'id': '1',
      'name': 'Smartphone',
      'price': 299,
      // 'image': 'assets/images/products/product1.png',
    },
    {
      'id': '2',
      'name': 'T-shirt',
      'price': 19,
      // 'image': 'assets/images/products/product2.png',
    },
    {
      'id': '3',
      'name': 'Lampe',
      'price': 49,
      // 'image': 'assets/images/products/product3.png',
    },
    {
      'id': '4',
      'name': 'Ballon',
      'price': 15,
      // 'image': 'assets/images/products/product4.png',
    },
  ];

  // Données simulées pour les bannières (3 images)
  final List<Map<String, String>> _banners = [
    {
      // 'image': 'assets/images/banners/banner1.png',
      'text': 'Offre spéciale : -20% sur l’électronique !',
    },
    {
      // 'image': 'assets/images/banners/banner2.png',
      'text': 'Nouveautés mode automne 2025 !',
    },
    {
      // 'image': 'assets/images/banners/banner3.png',
      'text': 'Décorez votre maison avec style !',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = _isDarkMode(context);

    return Scaffold(
      backgroundColor: isDark ? DMColors.black : DMColors.white,
      appBar: AppBar(
        backgroundColor: isDark ? DMColors.black : DMColors.white,
        elevation: 0,
        title: Text(
          'DM Shop',
          style:
              isDark
                  ? TTextTheme.darkTextTheme.headlineSmall?.copyWith(
                    color: DMColors.textWhite,
                  )
                  : TTextTheme.lightTextTheme.headlineSmall?.copyWith(
                    color: DMColors.black,
                  ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Iconsax.search_normal,
              color: isDark ? DMColors.textWhite : DMColors.black,
            ),
            onPressed: () {
              // TODO: Implémenter la recherche
            },
          ),
          IconButton(
            icon: Icon(
              Iconsax.heart,
              color: isDark ? DMColors.textWhite : DMColors.black,
            ),
            onPressed: () {
              // TODO: Implémenter les notifications
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner Carousel
            CarouselSlider(
              options: CarouselOptions(
                height: 200,
                autoPlay: true,
                enlargeCenterPage: true,
                viewportFraction: 0.9,
                autoPlayInterval: const Duration(seconds: 3),
              ),
              items:
                  _banners.map((banner) {
                    return Builder(
                      builder: (BuildContext context) {
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: LinearGradient(
                              colors:
                                  isDark
                                      ? [
                                        DMColors.primary.withOpacity(0.8),
                                        DMColors.primary,
                                      ]
                                      : [
                                        DMColors.primary.withOpacity(0.6),
                                        DMColors.primary,
                                      ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    isDark
                                        ? Colors.black26
                                        : Colors.grey.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  color:
                                      isDark
                                          ? DMColors.grey.withOpacity(0.3)
                                          : DMColors.grey.withOpacity(0.1),
                                  width: double.infinity,
                                  child: const Center(
                                    child: Icon(
                                      Iconsax.image,
                                      color: DMColors.primary,
                                      size: DMSizes.iconLg * 1.5,
                                    ),
                                  ),
                                ),
                              ),
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(DMSizes.sm),
                                  child: Text(
                                    banner['text']!,
                                    style:
                                        isDark
                                            ? TTextTheme
                                                .darkTextTheme
                                                .headlineSmall
                                                ?.copyWith(
                                                  color: DMColors.textWhite,
                                                  fontWeight: FontWeight.bold,
                                                )
                                            : TTextTheme
                                                .lightTextTheme
                                                .headlineSmall
                                                ?.copyWith(
                                                  color: DMColors.textWhite,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  }).toList(),
            ),
            const SizedBox(height: DMSizes.spaceBtwSections),

            // Categories Section
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: DMSizes.defaultSpace,
              ),
              child: Text(
                'Catégories',
                style:
                    isDark
                        ? TTextTheme.darkTextTheme.titleLarge?.copyWith(
                          color: DMColors.textWhite,
                        )
                        : TTextTheme.lightTextTheme.titleLarge?.copyWith(
                          color: DMColors.black,
                        ),
              ),
            ),
            const SizedBox(height: DMSizes.sm),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: DMSizes.defaultSpace,
                ),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  return Container(
                    width: 80,
                    margin: const EdgeInsets.only(right: DMSizes.sm),
                    padding: const EdgeInsets.all(DMSizes.xs),
                    decoration: BoxDecoration(
                      color: isDark ? DMColors.dark : DMColors.light,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            isDark
                                ? DMColors.textWhite.withOpacity(0.2)
                                : DMColors.grey,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                              isDark
                                  ? Colors.black26
                                  : Colors.grey.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _categories[index]['icon'],
                          size: DMSizes.iconMd,
                          color: isDark ? DMColors.textWhite : DMColors.black,
                        ),
                        const SizedBox(height: DMSizes.xs),
                        Text(
                          _categories[index]['name'],
                          style:
                              isDark
                                  ? TTextTheme.darkTextTheme.bodySmall
                                      ?.copyWith(color: DMColors.textWhite)
                                  : TTextTheme.lightTextTheme.bodySmall
                                      ?.copyWith(color: DMColors.black),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: DMSizes.spaceBtwSections),

            // Products Grid
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: DMSizes.defaultSpace,
              ),
              child: Text(
                'Produits populaires',
                style:
                    isDark
                        ? TTextTheme.darkTextTheme.titleLarge?.copyWith(
                          color: DMColors.textWhite,
                        )
                        : TTextTheme.lightTextTheme.titleLarge?.copyWith(
                          color: DMColors.black,
                        ),
              ),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(DMSizes.defaultSpace),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: _products.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    // Navigator.push(
                    //   context,
                    //   MaterialPageRoute(
                    //     builder:
                    //         (context) =>
                    //             ProductScreen(id: _products[index]['id']),
                    //   ),
                    // );
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
                                _products[index]['name'],
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
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: DMSizes.xs),
                              Text(
                                '\$${_products[index]['price']}',
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
            const SizedBox(height: DMSizes.spaceBtwSections),
          ],
        ),
      ),
    );
  }
}
