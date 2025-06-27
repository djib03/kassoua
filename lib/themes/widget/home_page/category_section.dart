import 'package:flutter/material.dart';
import 'package:kassoua/constants/colors.dart';
import 'package:kassoua/services/categorie_service.dart';
import 'package:kassoua/models/categorie.dart';
import 'package:kassoua/screens/category_screen.dart';

class CategorySection extends StatelessWidget {
  final bool isDark;
  const CategorySection({Key? key, required this.isDark}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(padding: const EdgeInsets.symmetric(horizontal: 17)),
        SizedBox(
          height: 100,
          child: StreamBuilder<List<Categorie>>(
            stream: CategoryService().getCategoriesStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('Aucune catégorie'));
              }
              final categories = snapshot.data!;
              final showSeeAll = categories.length > 8;
              final displayCount = showSeeAll ? 8 : categories.length;

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount:
                    displayCount +
                    (showSeeAll ? 1 : 0), // +1 pour le bouton "voir tout"
                itemBuilder: (context, index) {
                  if (showSeeAll && index == displayCount) {
                    // Bouton "Voir tout"
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CategoryScreen(),
                          ),
                        );
                      },
                      child: Container(
                        width: 80,
                        margin: const EdgeInsets.only(right: 16),
                        child: Column(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: isDark ? DMColors.dark : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: DMColors.primary,
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        isDark
                                            ? Colors.black26
                                            : Colors.grey.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.more_horiz, // Icône "points"
                                  color: DMColors.primary,
                                  size: 28,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Voir tout",
                              style: TextStyle(
                                color:
                                    isDark
                                        ? DMColors.textWhite
                                        : DMColors.black,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  // Catégorie classique
                  final category = categories[index];
                  return Container(
                    width: 80,
                    margin: const EdgeInsets.only(right: 16),
                    child: Column(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: isDark ? DMColors.dark : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    isDark
                                        ? Colors.black26
                                        : Colors.grey.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: IconUtils.buildCustomIcon(
                              category.icone,
                              color: DMColors.primary,
                              size: 28,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          category.nom,
                          style: TextStyle(
                            color: isDark ? DMColors.textWhite : DMColors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
