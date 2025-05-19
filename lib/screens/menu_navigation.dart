import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:dm_shop/constants/colors.dart';
import 'package:dm_shop/screens/home/home_page.dart';

class MenuNavigation extends StatefulWidget {
  const MenuNavigation({Key? key}) : super(key: key);

  @override
  State<MenuNavigation> createState() => _MenuNavigationState();
}

class _MenuNavigationState extends State<MenuNavigation> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomePage(),
    const Center(child: Text('Chat')),
    const Center(child: Text('Mes annonces')),
    const Center(child: Text('Profil')),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  bool _isDarkMode(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _isDarkMode(context);

    return Scaffold(
      body: _screens[_selectedIndex],
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: DMColors.primary,
        shape: const CircleBorder(),
        elevation: 4,
      ),
      bottomNavigationBar: CustomBottomBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
        activeColor: DMColors.primary,
        inactiveColor: isDark ? Colors.white60 : Colors.black54,
        isDark: isDark,
      ),
    );
  }
}

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
      notchMargin: 8,
      child: SizedBox(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, Iconsax.home, Iconsax.home, 'Accueil'),
            _buildNavItem(1, Iconsax.message, Iconsax.message, 'Chat'),
            const SizedBox(width: 48),
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
