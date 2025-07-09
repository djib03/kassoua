import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kassoua/constants/colors.dart';
import 'package:kassoua/views/screen/homepage/home_page.dart';
import 'package:kassoua/views/screen/shop/my_listings_page.dart';
import 'package:kassoua/views/screen/profile/profile_screen.dart';
import 'package:flutter/services.dart';
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
  // String? _currentUserId; // Plus besoin de maintenir localement

  // Utiliser un getter pour _screens qui dépend de l'Auth Controller
  List<Widget> _screens(BuildContext context, AuthController authController) {
    // Si l'utilisateur est connecté, utilisez son ID. Sinon, utilisez une chaîne vide ou gérez l'état "non connecté".
    // La FavoriteProductsScreen devrait gérer le cas où l'userId est vide.
    final String currentUserId =
        authController.userData?.id ?? ''; // Récupérer l'ID du userData

    return [
      const HomePage(),
      FavoriteProductsScreen(
        userId: currentUserId,
      ), // Passer l'ID de l'utilisateur
      const MyListingsPage(),
      const ProfileScreen(),
    ];
  }

  @override
  void initState() {
    super.initState();
    // Plus besoin de charger _currentUserId ici, il sera géré par le Provider
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
      body:
          _screens(
            context,
            authController,
          )[_selectedIndex], // Passer le contexte et le contrôleur
      extendBody:
          true, // Permet au body de s'étendre derrière la barre de navigation
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

        // Removed CircularNotchedRectangle as it's typically used with a FloatingActionButton
        // If you still want the FAB behavior, ensure it's properly implemented with shape.
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, Iconsax.home, Iconsax.home, 'Accueil'),
            _buildNavItem(1, Iconsax.heart, Iconsax.heart, 'Mes favoris'),
            _buildNavItem(2, Iconsax.shop, Iconsax.shop, 'Ma boutique'),
            _buildNavItem(3, Iconsax.user, Iconsax.user, 'Profil'),
          ],
        ),
      ),
    );
  }

  // Dans menu_navigation.dart, modifiez la méthode _buildNavItem comme suit :

  Widget _buildNavItem(
    int index,
    IconData outlineIcon,
    IconData filledIcon,
    String label,
  ) {
    final isSelected = _selectedIndex == index;
    final activeColor = AppColors.primary; // Votre couleur active
    final inactiveColor = Colors.grey; // Votre couleur inactive

    return GestureDetector(
      onTap: () {
        // Pour "Mes favoris", vérifier la connexion avant de naviguer
        if (index == 1) {
          // Index de "Mes favoris"
          final authController = Provider.of<AuthController>(
            context,
            listen: false,
          );

          // CORRECTION : Utiliser isLoggedInSync au lieu de isLoggedIn()
          if (authController.isLoggedInSync) {
            onItemTapped(index);
          } else {
            _showLoginRequiredDialog(context);
          }
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

  // J'ai inclus la fonction _showLoginRequiredDialog ici car elle était appelée
  // depuis MenuNavigation pour "Mes favoris". Vous pouvez la centraliser si vous voulez,
  // mais pour l'instant, la dupliquer ou la passer en paramètre.
  // Pour éviter la duplication, je vais la copier directement depuis ProfileScreen.
  void _showLoginRequiredDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Action Requise',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Vous devez être connecté pour accéder à cette fonctionnalité.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop(); // Ferme le dialogue
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const AuthSelectionScreen(),
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
        );
      },
    );
  }
}
