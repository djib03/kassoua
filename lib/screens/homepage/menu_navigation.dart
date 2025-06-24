import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kassoua/constants/colors.dart';
import 'package:kassoua/screens/homepage/home_page.dart'; // Importez votre HomePage
import 'package:kassoua/screens/Chat/conversations_list_page.dart';
import 'package:kassoua/screens/shop/my_listings_page.dart';
import 'package:kassoua/screens/profile/profile_screen.dart';
import 'package:flutter/services.dart';

class MenuNavigation extends StatefulWidget {
  const MenuNavigation({Key? key}) : super(key: key);

  @override
  _MenuNavigationState createState() => _MenuNavigationState();
}

class _MenuNavigationState extends State<MenuNavigation> {
  int _selectedIndex = 0;

  // Les écrans à afficher. HomePage est maintenant utilisé ici.
  final List<Widget> _screens = [
    HomePage(), // Utilise la HomePage que nous avons définie plus haut
    ConversationsListPage(),
    MyListingsPage(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;

      HapticFeedback.lightImpact();
    });
  }

  bool _isDarkMode(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _isDarkMode(context);

    return Scaffold(
      body: _screens[_selectedIndex], // Affiche l'écran sélectionné.
      bottomNavigationBar: CustomBottomBar(
        // Utilise la CustomBottomBar
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
        activeColor: DMColors.primary,
        inactiveColor: isDark ? Colors.white60 : Colors.black54,
        isDark: isDark,
      ),
    );
  }
}

// Barre de navigation personnalisée
class CustomBottomBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;
  final Color activeColor;
  final Color inactiveColor;
  final bool isDark;

  const CustomBottomBar({
    Key? key,
    required this.selectedIndex,
    required this.onItemTapped,
    required this.activeColor,
    required this.inactiveColor,
    required this.isDark,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color:
          isDark
              ? const Color.fromARGB(255, 32, 32, 32)
              : const Color.fromARGB(255, 255, 255, 255),
      height: 66,
      shape: const CircularNotchedRectangle(),

      child: SizedBox(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, Iconsax.home, Iconsax.home, 'Accueil'),
            _buildNavItem(
              1,
              Iconsax.message,
              Iconsax.message,
              'Mes discussions',
            ),
            _buildNavItem(2, Iconsax.shop, Iconsax.shop, 'Ma boutique'),
            _buildNavItem(3, Iconsax.user, Iconsax.user, 'Profil'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData outlineIcon,
    IconData filledIcon,
    String label,
  ) {
    final isSelected = selectedIndex == index;
    return GestureDetector(
      onTap: () => onItemTapped(index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSelected ? filledIcon : outlineIcon,
            color: isSelected ? activeColor : inactiveColor,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isSelected ? activeColor : inactiveColor,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
