import 'package:flutter/material.dart';
import 'package:kassoua/constants/colors.dart';
import 'package:kassoua/services/categorie_service.dart';
import 'package:kassoua/models/categorie.dart';
import 'package:kassoua/views/screen/homepage/category_screen.dart';
import 'package:kassoua/views/screen/homepage/product_by_catgory_screen.dart';

class CategorySection extends StatelessWidget {
  final bool isDark;
  final bool showSkeletonLoader; // ← Nouveau paramètre

  const CategorySection({
    Key? key,
    required this.isDark,
    this.showSkeletonLoader = false, // ← Paramètre par défaut
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(padding: const EdgeInsets.symmetric(horizontal: 17)),
        SizedBox(
          height: 120,
          child:
              showSkeletonLoader
                  ? _buildSkeletonCategories()
                  : StreamBuilder<List<Categorie>>(
                    stream: CategoryService().getParentCategoriesStream(),
                    builder: (context, snapshot) {
                      // ✅ REMPLACER CircularProgressIndicator par skeleton
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return _buildSkeletonCategories();
                      }

                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(child: Text('Aucune catégorie'));
                      }

                      final categories = snapshot.data!;
                      final showSeeAll = categories.length > 5;
                      final displayCount = showSeeAll ? 5 : categories.length;

                      return ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: displayCount + (showSeeAll ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (showSeeAll && index == displayCount) {
                            return _buildSeeAllCard(context);
                          }

                          final category = categories[index];
                          return _buildCategoryCard(context, category);
                        },
                      );
                    },
                  ),
        ),
      ],
    );
  }

  // ✅ NOUVEAU: Widget skeleton pour les catégories
  Widget _buildSkeletonCategories() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 6, // Nombre fixe pour le skeleton
      itemBuilder: (context, index) {
        return Container(
          width: 90,
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[800] : Colors.grey[300],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icône skeleton
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[700] : Colors.grey[400],
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(height: 8),
              // Nom skeleton
              Container(
                height: 12,
                width: 60,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[700] : Colors.grey[400],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryCard(BuildContext context, Categorie category) {
    return Container(
      width: 90,
      margin: const EdgeInsets.only(right: 16),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.dark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black26 : Colors.grey.withOpacity(0.1),
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
            onTap: () => _onCategoryTap(context, category),
            child: Container(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(12),
                    child: IconUtils.buildCustomIcon(
                      category.icone,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    category.nom,
                    style: TextStyle(
                      color: isDark ? AppColors.textWhite : AppColors.black,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSeeAllCard(BuildContext context) {
    return Container(
      width: 90,
      margin: const EdgeInsets.only(right: 16),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.dark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary, width: 2),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black26 : Colors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CategoryScreen()),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(12),
                    child: const Icon(
                      Icons.more_horiz,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Voir tout",
                    style: TextStyle(
                      color: isDark ? AppColors.textWhite : AppColors.black,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onCategoryTap(BuildContext context, Categorie category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductsByCategoryScreen(category: category),
      ),
    );
  }
}
