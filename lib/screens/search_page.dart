import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kassoua/constants/colors.dart';
import 'package:kassoua/constants/size.dart';
import 'package:kassoua/themes/customs/text_theme.dart';
import 'package:kassoua/screens/product_screen.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _isDarkMode(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  // Simuler une liste de produits pour la recherche
  final List<Map<String, dynamic>> _allProducts = [
    {
      'id': '1',
      'name': 'Smartphone Samsung',
      'price': 299000,
      'category': 'Électronique',
    },
    {'id': '2', 'name': 'T-shirt Nike', 'price': 15000, 'category': 'Mode'},
    {
      'id': '3',
      'name': 'Laptop HP',
      'price': 450000,
      'category': 'Informatique',
    },
    // Ajoutez plus de produits ici
  ];

  List<Map<String, dynamic>> _searchResults = [];

  void _performSearch(String query) {
    setState(() {
      if (query.isEmpty) {
        _searchResults = [];
      } else {
        _searchResults =
            _allProducts
                .where(
                  (product) => product['name'].toLowerCase().contains(
                    query.toLowerCase(),
                  ),
                )
                .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _isDarkMode(context);

    return Scaffold(
      backgroundColor: isDark ? DMColors.black : DMColors.white,
      appBar: AppBar(
        backgroundColor: isDark ? DMColors.black : DMColors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? DMColors.textWhite : DMColors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          controller: _searchController,
          onChanged: _performSearch,
          style:
              isDark
                  ? TTextTheme.darkTextTheme.bodyLarge
                  : TTextTheme.lightTextTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: 'Rechercher un produit...',
            hintStyle: TextStyle(
              color:
                  isDark ? DMColors.textWhite.withOpacity(0.5) : DMColors.grey,
            ),
            border: InputBorder.none,
            suffixIcon: IconButton(
              icon: Icon(
                Iconsax.close_circle,
                color: isDark ? DMColors.textWhite : DMColors.black,
              ),
              onPressed: () {
                _searchController.clear();
                _performSearch('');
              },
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child:
                _searchResults.isEmpty
                    ? Center(
                      child: Text(
                        _searchController.text.isEmpty
                            ? 'Commencez à taper pour rechercher'
                            : 'Aucun résultat trouvé',
                        style:
                            isDark
                                ? TTextTheme.darkTextTheme.bodyLarge
                                : TTextTheme.lightTextTheme.bodyLarge,
                      ),
                    )
                    : ListView.builder(
                      itemCount: _searchResults.length,
                      padding: const EdgeInsets.all(DMSizes.defaultSpace),
                      itemBuilder: (context, index) {
                        final product = _searchResults[index];
                        return Card(
                          color: isDark ? DMColors.dark : DMColors.white,
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: DMSizes.sm),
                          child: ListTile(
                            onTap: () {
                              final productDetail = Product(
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
                                  builder:
                                      (context) => ProductDetailPage(
                                        product: productDetail,
                                      ),
                                ),
                              );
                            },
                            leading: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color:
                                    isDark
                                        ? DMColors.grey.withOpacity(0.3)
                                        : DMColors.grey.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Iconsax.image),
                            ),
                            title: Text(
                              product['name'],
                              style:
                                  isDark
                                      ? TTextTheme.darkTextTheme.titleMedium
                                      : TTextTheme.lightTextTheme.titleMedium,
                            ),
                            subtitle: Text(
                              '${product['category']}',
                              style:
                                  isDark
                                      ? TTextTheme.darkTextTheme.bodyMedium
                                      : TTextTheme.lightTextTheme.bodyMedium,
                            ),
                            trailing: Text(
                              '${product['price']} FCFA',
                              style: TextStyle(
                                color: DMColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
