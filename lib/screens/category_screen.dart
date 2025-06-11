import 'package:flutter/material.dart';
import 'package:kassoua/constants/colors.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final List<Map<String, dynamic>> _categories = [
    {'name': 'Mode', 'icon': Icons.checkroom_outlined},
    {'name': 'Électronique', 'icon': Icons.devices_other_outlined},
    {'name': 'Maison', 'icon': Icons.home_outlined},
    {'name': 'Beauté & Santé', 'icon': Icons.spa_outlined},
    {'name': 'Alimentation', 'icon': Icons.restaurant_outlined},
    {'name': 'Informatique', 'icon': Icons.computer_outlined},
    {'name': 'Sports & Loisirs', 'icon': Icons.sports_soccer_outlined},
    {'name': 'Auto & Moto', 'icon': Icons.directions_car_outlined},
    {'name': 'Livres & Papeterie', 'icon': Icons.menu_book_outlined},
    {'name': 'Téléphonie & Internet', 'icon': Icons.smartphone_outlined},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          Theme.of(context).brightness == Brightness.dark
              ? DMColors.black
              : DMColors.white,
      appBar: AppBar(
        title: Text(
          'Catégories',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        ),

        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(
          color:
              Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black,
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Découvrez nos catégories',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Trouvez exactement ce que vous cherchez',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.builder(
                physics: const BouncingScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.1,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  return _buildCategoryCard(category, context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(
    Map<String, dynamic> category,
    BuildContext context,
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.1), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _onCategoryTap(category['name']),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: DMColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    category['icon'],
                    color: DMColors.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  category['name'],
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onCategoryTap(String categoryName) {
    // Afficher un feedback visuel
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Catégorie sélectionnée: $categoryName'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );

    // Ici vous pouvez ajouter la navigation vers l'écran de la catégorie
    // Navigator.push(context, MaterialPageRoute(builder: (context) => CategoryDetailScreen(categoryName: categoryName)));
  }
}
