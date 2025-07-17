import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kassoua/constants/colors.dart';
import 'package:kassoua/views/screen/homepage/home_page.dart';
import 'package:kassoua/views/screen/shop/my_listings_page.dart';
import 'package:kassoua/views/screen/profile/profile_screen.dart';
import 'package:kassoua/controllers/auth_controller.dart';
import 'package:provider/provider.dart';
import 'package:kassoua/views/screen/auth/auth_screen_selection.dart';
import 'package:kassoua/views/screen/homepage/favorite_products_screen.dart';

class MenuNavigation extends StatefulWidget {
  const MenuNavigation({Key? key}) : super(key: key);

  @override
  _MenuNavigationState createState() => _MenuNavigationState();
}

class _MenuNavigationState extends State<MenuNavigation> {
  int _selectedIndex = 0;

  // Utiliser un getter pour _screens qui dépend de l'Auth Controller
  List<Widget> _screens(BuildContext context, AuthController authController) {
    final String currentUserId = authController.userData?.id ?? '';

    return [
      const HomePage(),
      FavoriteProductsScreen(userId: currentUserId),
      MyListingsPage(
        authController: context.read<AuthController>(),
        userId: currentUserId,
      ),
      const ProfileScreen(),
    ];
  }

  void onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authController = Provider.of<AuthController>(context);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: _screens(context, authController)[_selectedIndex],
      extendBody: true,
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color:
              isDark
                  ? const Color.fromARGB(255, 32, 32, 32)
                  : const Color.fromARGB(255, 255, 255, 255),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 10,
            ),
          ],
        ),
        height: 66,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, Iconsax.home, Iconsax.home, 'Accueil'),
            _buildNavItem(1, Iconsax.heart, Iconsax.heart, 'Mes favoris'),
            _buildNavItem(2, Iconsax.shop, Iconsax.shop, 'Mes annonces'),
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
    final isSelected = _selectedIndex == index;
    final activeColor = AppColors.primary;
    final inactiveColor = Colors.grey;

    return GestureDetector(
      onTap: () {
        if (index == 1) {
          onItemTapped(index);
        } else {
          onItemTapped(index);
        }
      },
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
            ),
          ),
        ],
      ),
    );
  }
}
