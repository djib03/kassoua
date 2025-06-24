import 'package:kassoua/screens/address_management_screen.dart';
import 'package:kassoua/screens/user_detail.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kassoua/constants/colors.dart';
import 'package:kassoua/screens/change_password_screen.dart';
import 'package:kassoua/screens/notification_screen.dart';
import 'package:provider/provider.dart';
import 'package:kassoua/controllers/auth_controller.dart';
import 'package:kassoua/models/user.dart';
import 'package:panara_dialogs/panara_dialogs.dart';
import 'package:kassoua/screens/auth_screen_selection.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: const Color.fromARGB(31, 93, 93, 93),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: DMColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 12),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color:
                  Theme.of(context).brightness == Brightness.dark
                      ? DMColors.textWhite
                      : DMColors.textPrimary,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color:
                Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[900]
                    : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children:
                items.asMap().entries.map((entry) {
                  int index = entry.key;
                  Widget item = entry.value;

                  return Column(
                    children: [
                      item,
                      if (index < items.length - 1)
                        Divider(
                          height: 1,
                          color:
                              Theme.of(context).brightness == Brightness.dark
                                  ? Colors.grey[800]
                                  : Colors.grey[200],
                          indent: 16,
                          endIndent: 16,
                        ),
                    ],
                  );
                }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color color,
    bool isDestructive = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:
                      isDestructive
                          ? DMColors.error.withOpacity(0.1)
                          : color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isDestructive ? DMColors.error : color,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDestructive ? DMColors.error : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle, // Correction: utiliser subtitle au lieu de title
                      style: TextStyle(
                        fontSize: 13,
                        color:
                            isDestructive
                                ? DMColors.error.withOpacity(0.7)
                                : DMColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: DMColors.textSecondary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method for anonymous profile
  Widget _buildAnonymousProfile(BuildContext context, bool isDark) {
    return Container(
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 10, top: 24),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [DMColors.primaryDark, DMColors.accent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[900] : Colors.white,
                shape: BoxShape.circle,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child: SizedBox(
                  width: 100,
                  height: 100,
                  child: Image.asset(
                    'assets/images/user.png', // Default image for anonymous
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 15),
          Text(
            'Anonyme', // Display "Anonymous User"
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: isDark ? DMColors.textWhite : DMColors.textPrimary,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Connectez-vous pour voir vos informations', // Indication pour se connecter
            textAlign: TextAlign.center,
            style: const TextStyle(color: DMColors.textSecondary, fontSize: 16),
          ),
        ],
      ),
    );
  }

  // Helper method for logged-in user profile
  Widget _buildUserProfile(
    BuildContext context,
    bool isDark,
    Utilisateur user,
  ) {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar avec effet de bordure
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [DMColors.primaryDark, DMColors.accent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[900] : Colors.white,
                shape: BoxShape.circle,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child: SizedBox(
                  width: 100,
                  height: 100,
                  child:
                      (user.photoProfil == null || user.photoProfil!.isEmpty)
                          ? Image.asset(
                            'assets/images/user.png',
                            fit: BoxFit.cover,
                          )
                          : Image.network(
                            user.photoProfil!,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (context, error, stackTrace) => Image.asset(
                                  'assets/images/user.png',
                                  fit: BoxFit.cover,
                                ),
                          ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 15),
          Text(
            '${user.nom} ${user.prenom}',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: isDark ? DMColors.textWhite : DMColors.textPrimary,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            user.email.isNotEmpty ? user.email : user.telephone,
            style: const TextStyle(color: DMColors.textSecondary, fontSize: 16),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLoggedIn = Provider.of<AuthController>(context).user != null;
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          'Profile',
          style: TextStyle(
            color: isDark ? DMColors.textWhite : Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: Icon(
              Icons.more_vert,
              color: isDark ? DMColors.textWhite : Colors.black,
            ),
          ),
        ],
      ),
      backgroundColor: isDark ? DMColors.black : Colors.grey[50],
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Section profil utilisateur
            FutureBuilder<Utilisateur?>(
              future:
                  Provider.of<AuthController>(
                    context,
                    listen: false,
                  ).fetchUserData(),
              builder: (context, snapshot) {
                Utilisateur? user = snapshot.data;
                if (user == null) {
                  // Affiche le profil anonyme si pas de données utilisateur
                  return _buildAnonymousProfile(context, isDark);
                }
                // Affiche le profil utilisateur réel
                return _buildUserProfile(context, isDark, user);
              },
            ),

            // Cartes statistiques
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  _buildActionCard(
                    icon: Iconsax.shopping_bag,
                    title: 'Mes achats',
                    value: '3',
                    color: DMColors.accent,
                  ),
                  const SizedBox(width: 16),
                  _buildActionCard(
                    icon: Iconsax.heart,
                    title: 'Mes favoris', // Correction: "favories" -> "favoris"
                    value: '6',
                    color: DMColors.secondary,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Section paramètres
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  _buildSection(
                    context,
                    title: 'Paramètres',
                    items: [
                      _buildMenuItem(
                        icon: Iconsax.setting,
                        title: 'Détails du compte',
                        subtitle: 'Voir les paramètres du compte',
                        onTap: () {
                          if (!isLoggedIn) {
                            _showLoginRequiredSnackBar(context);
                            return;
                          }
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const UserDetailScreen(),
                            ),
                          );
                        },
                        color: DMColors.primary,
                      ),
                      _buildMenuItem(
                        icon: Iconsax.lock,
                        title: 'Changer le mot de passe',
                        subtitle: 'Mettre à jour votre mot de passe',
                        onTap: () {
                          if (!isLoggedIn) {
                            _showLoginRequiredSnackBar(context);
                            return;
                          }
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => const ChangePasswordScreen(),
                            ),
                          );
                        },
                        color: DMColors.primary,
                      ),
                      _buildMenuItem(
                        icon: Iconsax.notification,
                        title: 'Notifications',
                        subtitle: 'Gérer les notifications',
                        onTap: () {
                          if (!isLoggedIn) {
                            _showLoginRequiredSnackBar(context);
                            return;
                          }
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const NotificationScreen(),
                            ),
                          );
                        },
                        color: DMColors.primary,
                      ),
                      _buildMenuItem(
                        icon: Iconsax.location,
                        title: 'Mes adresses',
                        subtitle:
                            'Ajouter et gérer vos adresses', // Amélioration du texte
                        onTap: () {
                          if (!isLoggedIn) {
                            _showLoginRequiredSnackBar(context);
                            return;
                          }
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => const AddressManagementScreen(),
                            ),
                          );
                        },
                        color: DMColors.primary,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Section actions dangereuses
                  _buildSection(
                    context,
                    title: 'Actions',
                    items: [
                      _buildMenuItem(
                        icon: Iconsax.login,
                        title: 'Se connecter',
                        subtitle: 'Connecter vous à votre compte compte',
                        onTap: () {
                          if (isLoggedIn) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Vous êtes déjà connecté',
                                  style: TextStyle(
                                    color:
                                        isDark
                                            ? DMColors.textWhite
                                            : Colors.black,
                                  ),
                                ),
                                backgroundColor: DMColors.primary,
                              ),
                            );
                            return;
                          }
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AuthSelectionScreen(),
                            ),
                          );
                        },
                        color: DMColors.primary,
                      ),
                      _buildMenuItem(
                        icon: Iconsax.logout,
                        title: 'Déconnexion',
                        subtitle:
                            'Se déconnecter de votre compte en toute sécurité',
                        onTap: () {
                          PanaraConfirmDialog.show(
                            context,
                            message:
                                'Êtes vous sur de vouloir vous deconnecter',
                            confirmButtonText: 'Oui ',
                            cancelButtonText: 'Non',
                            onTapConfirm: () async {
                              await Provider.of<AuthController>(
                                context,
                                listen: false,
                              ).signOut();
                              Navigator.of(context).pop(); // Ferme le dialog
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AuthSelectionScreen(),
                                ),
                                (route) => false,
                              );
                            },
                            onTapCancel: () {
                              Navigator.of(context).pop();
                            },
                            panaraDialogType: PanaraDialogType.custom,
                            color: DMColors.error,
                          );
                        },
                        color: DMColors.secondary,
                      ),
                      _buildMenuItem(
                        icon: Iconsax.trash,
                        title: 'Supprimer le compte',
                        subtitle:
                            'Supprimez définitivement votre compte et vos données',
                        onTap: () {
                          PanaraConfirmDialog.show(
                            context,
                            message:
                                'Êtes vous sur de vouloir supprimer votre compte',
                            confirmButtonText: 'Oui',
                            cancelButtonText: 'Non',
                            onTapConfirm: () async {
                              // Call delete account logic here
                              await Provider.of<AuthController>(
                                context,
                                listen: false,
                              ).deleteAccount();
                            },
                            onTapCancel: () {
                              Navigator.of(context).pop();
                            },
                            panaraDialogType: PanaraDialogType.custom,
                            color: DMColors.error,
                          );
                        },
                        color: DMColors.error,
                        isDestructive: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _showLoginRequiredSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.3),
                      Colors.white.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.account_circle_outlined,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Connexion requise',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Connectez-vous pour continuer',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        action: SnackBarAction(
          label: 'Se connecter',
          textColor: Colors.white,
          backgroundColor: Colors.white.withOpacity(0.25),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => AuthSelectionScreen()),
            );
          },
        ),
        backgroundColor: DMColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
        elevation: 4,
        dismissDirection: DismissDirection.horizontal,
      ),
    );
  }
}
