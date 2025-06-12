import 'package:flutter/material.dart';
import 'package:kassoua/constants/colors.dart';
import 'package:kassoua/data/home_data.dart';
import 'package:kassoua/screens/category_screen.dart';

class CategorySection extends StatelessWidget {
  final bool isDark;
  const CategorySection({Key? key, required this.isDark}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Catégories',
                style: TextStyle(
                  color: isDark ? DMColors.textWhite : DMColors.black,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => CategoryScreen()),
                  );
                },

                label: const Text(
                  'Voir tout',
                  style: TextStyle(
                    color: DMColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: HomeData.categories.take(8).length,
            itemBuilder: (context, index) {
              final category = HomeData.categories[index];
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
                      child: Icon(
                        category['icon'],
                        color: DMColors.primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      category['name'],
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
          ),
        ),
      ],
    );
  }
}
