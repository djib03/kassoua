import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kassoua/constants/colors.dart';
import 'package:kassoua/views/widgets/product_card.dart'; // Import du ProductCard

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  bool _showGrid = true;
  String _sortBy = "Populaire";
  RangeValues _pricesRange = const RangeValues(0, 150000);

  final sortOptions = [
    "Populaire",
    "Recent",
    "Prix: décroissant",
    "Prix: croissant",
  ];

  // Données d'exemple pour les produits
  final List<Map<String, dynamic>> products = [
    {
      'id': 1,
      'name': 'T-shirt Premium',
      'price': 15000.0,
      'isLiked': false,
      'location': 'Niamey, Niger',
    },
    {
      'id': 2,
      'name': 'Jeans Slim Fit',
      'price': 45000.0,
      'isLiked': true,
      'location': 'Dosso, Niger',
    },
    {
      'id': 3,
      'name': 'Sneakers Sport',
      'price': 65000.0,
      'isLiked': false,
      'location': 'Maradi, Niger',
    },
    {
      'id': 4,
      'name': 'Veste En Cuir',
      'price': 85000.0,
      'isLiked': false,
      'location': 'Tahoua, Niger',
    },
  ];

  List<Map<String, dynamic>> get filteredProducts {
    List<Map<String, dynamic>> filtered =
        products.where((product) {
          return product['price'] >= _pricesRange.start &&
              product['price'] <= _pricesRange.end;
        }).toList();

    // Tri des produits
    switch (_sortBy) {
      case "Prix: croissant":
        filtered.sort((a, b) => a['price'].compareTo(b['price']));
        break;
      case "Prix: décroissant":
        filtered.sort((a, b) => b['price'].compareTo(a['price']));
        break;
      case "Recent":
        filtered.sort((a, b) => b['id'].compareTo(a['id']));
        break;
      case "Populaire":
      default:
        filtered.sort((a, b) => b['id'].compareTo(a['id']));
        break;
    }

    return filtered;
  }

  void _toggleFavorite(int productId) {
    setState(() {
      final productIndex = products.indexWhere((p) => p['id'] == productId);
      if (productIndex != -1) {
        products[productIndex]['isLiked'] = !products[productIndex]['isLiked'];
      }
    });
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setModalState) => Container(
                  padding: EdgeInsets.all(20),
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Filtres',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(Icons.close),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      Text(
                        'Gamme de prix',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 10),
                      RangeSlider(
                        values: _pricesRange,
                        min: 0,
                        max: 150000,
                        divisions: 20,
                        labels: RangeLabels(
                          '${_pricesRange.start.round()} FCFA',
                          '${_pricesRange.end.round()} FCFA',
                        ),
                        onChanged: (values) {
                          setModalState(() {
                            _pricesRange = values;
                          });
                        },
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${_pricesRange.start.round()} FCFA'),
                          Text('${_pricesRange.end.round()} FCFA'),
                        ],
                      ),
                      Spacer(),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {});
                            Navigator.pop(context);
                          },
                          child: Text('Appliquer les filtres'),
                        ),
                      ),
                    ],
                  ),
                ),
          ),
    );
  }

  void _showSortDialog() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Container(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trier par',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 20),
                ...sortOptions.map(
                  (option) => ListTile(
                    title: Text(option),
                    trailing:
                        _sortBy == option
                            ? Icon(
                              Icons.check,
                              color: Theme.of(context).primaryColor,
                            )
                            : null,
                    onTap: () {
                      setState(() {
                        _sortBy = option;
                      });
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildProductList(Map<String, dynamic> product) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.dark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(12),
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: isDark ? AppColors.grey.withOpacity(0.3) : Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Icon(Iconsax.image, color: AppColors.primary, size: 24),
          ),
        ),
        title: Text(
          product['name'],
          style: TextStyle(
            color: isDark ? AppColors.textWhite : AppColors.black,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Iconsax.location,
                  size: 12,
                  color: isDark ? AppColors.textSecondary : Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    product['location'] ?? 'Non spécifié',
                    style: TextStyle(
                      color:
                          isDark ? AppColors.textSecondary : Colors.grey[600],
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${product['price'].toInt()} FCFA',
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        trailing: GestureDetector(
          onTap: () => _toggleFavorite(product['id']),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color:
                  product['isLiked']
                      ? Colors.red.withOpacity(0.1)
                      : Colors.white.withOpacity(0.9),
              shape: BoxShape.circle,
              border:
                  product['isLiked']
                      ? Border.all(color: Colors.red.withOpacity(0.3))
                      : null,
            ),
            child: Icon(
              product['isLiked'] ? Icons.favorite : Icons.favorite_border,
              color: product['isLiked'] ? Colors.red : Colors.grey,
              size: 18,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    List<Map<String, dynamic>> displayProducts = filteredProducts;

    return Scaffold(
      backgroundColor: isDark ? AppColors.black : AppColors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            iconTheme: IconThemeData(
              color:
                  Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
            ),
            backgroundColor: isDark ? AppColors.black : AppColors.white,
            leading: IconButton(
              icon: Icon(Iconsax.arrow_left),
              onPressed: () => Navigator.of(context).pop(),
            ),
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(60),
              child: Container(
                height: 65,
                margin: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  decoration: InputDecoration(
                    labelText: "Chercher des produits",
                    prefixIcon: Icon(Iconsax.search_normal),
                    suffixIcon: Icon(Iconsax.close_circle),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    '${displayProducts.length} résultats',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Spacer(),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _showGrid = !_showGrid;
                      });
                    },
                    icon: Icon(_showGrid ? Icons.grid_view : Icons.list),
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: _showFilterDialog,
                    icon: Icon(Icons.tune),
                    label: Text('Filtrer'),
                  ),
                  SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: _showSortDialog,
                    icon: Icon(Iconsax.sort),
                    label: Text('Trier'),
                  ),
                ],
              ),
            ),
          ),

          // Grille ou liste des produits
          _showGrid
              ? SliverPadding(
                padding: EdgeInsets.all(16),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio:
                        0.8, // Augmenté de 0.75 à 0.8 pour plus de hauteur
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final product = displayProducts[index];
                    return ProductCard(
                      product: product,
                      isDark: isDark,
                      isFavorite: product['isLiked'] ?? false,
                      onToggleFavorite: () => _toggleFavorite(product['id']),
                    );
                  }, childCount: displayProducts.length),
                ),
              )
              : SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildProductList(displayProducts[index]),
                  childCount: displayProducts.length,
                ),
              ),

          // Espace en bas pour éviter que le contenu soit coupé
          SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }
}
