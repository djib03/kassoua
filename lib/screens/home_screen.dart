import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:dm_shop/constants/colors.dart';
// Assurez-vous que le chemin d'accès est correct.  Si CustomBottomBar est dans un autre dossier, ajustez-le.
import 'package:dm_shop/themes/widget/custom_bottom_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

bool isDarkMode(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark;
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // Placeholder for the different screens/pages.
  final List<Widget> _screens = [
    const Center(child: Text('Écran d\'accueil')), // Placeholder for Home
    const Center(child: Text('Écran de recherche')), // Placeholder for Search
    const Center(child: Text('Écran du panier')), // Placeholder for Cart
    const Center(child: Text('Écran de profil')), // Placeholder for Profile
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = isDarkMode(context);

    return Scaffold(
      body: _screens[_selectedIndex], // Display the selected screen
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add your action for the "+" button here
        },
        backgroundColor: DMColors.primary,
        shape: const CircleBorder(),
        elevation: 4,
        child: const Icon(Iconsax.add, color: Colors.white),
      ),
      bottomNavigationBar: CustomBottomBar(
        // Utilise le CustomBottomBar existant
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
        activeColor: DMColors.primary,
        inactiveColor: isDark ? Colors.white60 : Colors.black54,
        isDark: isDark,
      ),
    );
  }
}
