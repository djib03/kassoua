import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kassoua/constants/colors.dart';
import 'package:kassoua/views/screen/homepage/home_page.dart'; // Importez votre HomePage
import 'package:kassoua/views/screen/Chat/conversations_list_page.dart';
import 'package:kassoua/views/screen/shop/my_listings_page.dart';
import 'package:kassoua/views/screen/profile/profile_screen.dart';
import 'package:flutter/services.dart';
import 'package:kassoua/controllers/auth_controller.dart';
import 'package:provider/provider.dart';
import 'package:kassoua/views/screen/auth/auth_screen_selection.dart';

class MenuNavigation extends StatefulWidget {
  const MenuNavigation({Key? key}) : super(key: key);

  @override
  _MenuNavigationState createState() => _MenuNavigationState();
}

class _MenuNavigationState extends State<MenuNavigation> {
  int _selectedIndex = 0;

  // Les écrans à afficher. HomePage est maintenant utilisé ici.
  final List<Widget> _screens = [
    HomePage(),
    ConversationsListPage(),
    MyListingsPage(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    final isLoggedIn =
        Provider.of<AuthController>(context, listen: false).user != null;
    // Indices : 1 = Discussions, 2 = Ma boutique
    if ((index == 1 || index == 2) && !isLoggedIn) {
      _showLoginRequiredSnackBar(context);
      return;
    }
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
        activeColor: AppColors.primary,
        inactiveColor: isDark ? Colors.white60 : Colors.black54,
        isDark: isDark,
      ),
    );
  }

  void _showLoginRequiredSnackBar(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (ctx) {
        return Container(
          margin: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color:
                Theme.of(ctx).brightness == Brightness.dark
                    ? AppColors.dark
                    : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Icône d'information
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.account_circle_outlined,
                    color: AppColors.primary,
                    size: 40,
                  ),
                ),

                const SizedBox(height: 24),

                // Titre
                const Text(
                  'Connexion requise',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'poppins',
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 12),

                // Message
                Text(
                  'Vous devez être connecté pour accéder à cette fonctionnalité.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 32),

                // Boutons
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.grey[100],
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Annuler',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AuthSelectionScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Iconsax.login, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Se connecter',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // Espace pour éviter le clavier
                SizedBox(height: MediaQuery.of(ctx).viewInsets.bottom),
              ],
            ),
          ),
        );
      },
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
