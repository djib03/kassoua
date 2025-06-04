import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kassoua/constants/colors.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  bool _showGrid = true;
  String _sortBy = "Populaire";
  RangeValues _pricesRange = const RangeValues(0, 1000);

  final sortOptions = [
    "Populaire",
    "Recent",
    "Prix: décroissant",
    "Prix: croissant",
  ];

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? DMColors.black : DMColors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            // Utilisez la couleur du thème pour les icônes
            iconTheme: IconThemeData(
              color:
                  Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
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
                    prefixIcon: Icon(Icons.search),
                    suffixIcon: Icon(Icons.clear),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Text(
                        '20 resultats',
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
                        color: DMColors.textSecondary,
                      ),
                      SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: () {},
                        icon: Icon(Icons.tune),
                        label: Text('Filtrer'),
                      ),
                      SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: () {},
                        icon: Icon(Iconsax.sort),
                        label: Text('Trier'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
