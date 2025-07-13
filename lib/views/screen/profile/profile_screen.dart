import 'package:firebase_auth/firebase_auth.dart';
import 'package:kassoua/views/screen/profile/address_management_screen.dart';
import 'package:kassoua/views/screen/profile/user_detail.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kassoua/constants/colors.dart';
import 'package:kassoua/views/screen/profile/notification_screen.dart';
import 'package:provider/provider.dart';
import 'package:kassoua/controllers/auth_controller.dart';
import 'package:kassoua/models/user.dart';
import 'package:kassoua/views/screen/auth/auth_screen_selection.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:skeletonizer/skeletonizer.dart';

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
                color: AppColors.textSecondary,
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
        if (title.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 12),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color:
                    Theme.of(context).brightness == Brightness.dark
                        ? AppColors.textWhite
                        : AppColors.textPrimary,
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
                          ? AppColors.error.withOpacity(0.1)
                          : color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isDestructive ? AppColors.error : color,
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
                        color: isDestructive ? AppColors.error : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color:
                            isDestructive
                                ? AppColors.error.withOpacity(0.7)
                                : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method for anonymous profile with login button
  Widget _buildAnonymousProfile(BuildContext context, bool isDark) {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.dark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color:
                isDark
                    ? Colors.black26.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Profile info section
          Row(
            children: [
              // Image de profil à gauche
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primaryDark, AppColors.accent],
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
                    borderRadius: BorderRadius.circular(35),
                    child: SizedBox(
                      width: 70,
                      height: 70,
                      child: Container(
                        color: AppColors.primary.withOpacity(0.1),
                        child: Icon(
                          Icons.account_circle_outlined,
                          size: 35,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              // Informations à droite
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Invité',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        color:
                            isDark
                                ? AppColors.textWhite
                                : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Connectez-vous pour accéder à toutes les fonctionnalités',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Login button
          Container(
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AuthSelectionScreen(),
                    ),
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Iconsax.login, color: Colors.white, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      'Se connecter',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getDisplayIdentifier(Utilisateur userData) {
    // Si l'utilisateur a un téléphone mais pas d'email, c'est une connexion par téléphone
    if (userData.telephone.isNotEmpty && userData.email.isEmpty) {
      return userData.telephone;
    }
    // Si l'utilisateur a un email mais pas de téléphone, c'est une connexion par email
    else if (userData.email.isNotEmpty && userData.telephone.isEmpty) {
      return userData.email;
    }
    // Si les deux existent, vous pouvez choisir votre préférence
    else if (userData.telephone.isNotEmpty && userData.email.isNotEmpty) {
      // Ici vous pouvez choisir : prioriser le téléphone ou l'email
      return userData.telephone; // ou userData.email selon votre préférence
    } else {
      return 'Contact non disponible';
    }
  }

  // Helper method for logged-in user profile
  Widget _buildUserProfile(
    BuildContext context,
    Utilisateur? userData,
    bool isLoggedIn,
    bool isDark,
  ) {
    // Si l'utilisateur n'est PAS connecté ou userData est null, affichez le message simple
    if (!isLoggedIn || userData == null) {
      return Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: AppColors.primary.withOpacity(0.2),
            child: const Icon(Iconsax.user, size: 40, color: AppColors.primary),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Non connecté',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              Text(
                'Veuillez vous connecter',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ],
      );
    }

    // Si l'utilisateur est connecté, affichez le design plus riche de _buildUserProfile
    final String displayName = '${userData.nom} ${userData.prenom}'.trim();
    final String displayIdentifier = _getDisplayIdentifier(userData);

    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.dark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color:
                isDark
                    ? Colors.black.withOpacity(0.2)
                    : Colors.grey.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Image de profil avec bordure dégradée
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primaryDark, AppColors.accent],
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
                borderRadius: BorderRadius.circular(35),
                child: SizedBox(
                  width: 70,
                  height: 70,
                  child:
                      (userData.photoProfil == null ||
                              userData.photoProfil!.isEmpty)
                          ? Icon(Iconsax.user)
                          : CachedNetworkImage(
                            imageUrl: userData.photoProfil!,
                            fit: BoxFit.cover,
                            placeholder:
                                (context, url) => const Center(
                                  child: CircularProgressIndicator(
                                    color: AppColors.primary,
                                    strokeWidth: 2,
                                  ),
                                ),
                            errorWidget:
                                (context, url, error) => const Icon(
                                  Iconsax.profile, // Ou Icons.error_outline
                                  color: AppColors.error,
                                  size: 30,
                                ),
                          ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          // Informations utilisateur
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  displayName.isEmpty ? 'Utilisateur' : displayName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    color: isDark ? AppColors.textWhite : AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  displayIdentifier,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                // Badge "Connecté"
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified, color: AppColors.primary, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'Connecté',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Écoutez l'Auth Controller pour les changements d'état
    final authController = Provider.of<AuthController>(context);

    // Utilisez isLoading pour afficher un état de chargement
    if (authController.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Récupérez les données de l'utilisateur
    final Utilisateur? userData = authController.userData;

    // CORRECTION : Utilisez isLoggedInSync au lieu de isLoggedIn()
    final bool isLoggedIn = authController.isLoggedInSync;

    return Scaffold(
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          'Profil',
          style: TextStyle(
            color: isDark ? AppColors.textWhite : Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: () {},
            icon: Icon(
              Icons.more_vert,
              color: isDark ? AppColors.textWhite : Colors.black,
            ),
          ),
        ],
      ),
      backgroundColor: isDark ? Color(0xFF121212) : Colors.grey[50],
      body: SingleChildScrollView(
        child: Column(
          children: [
            Consumer<AuthController>(
              builder: (context, authController, child) {
                // Vérifier d'abord si on est en cours de chargement
                if (authController.isLoading) {
                  return Container(
                    margin: const EdgeInsets.all(24),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.dark : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color:
                              isDark
                                  ? Colors.black.withOpacity(0.2)
                                  : Colors.grey.withOpacity(0.08),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Skeletonizer(
                      enabled: true,
                      child: Row(
                        children: [
                          // Profile picture skeleton
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              shape: BoxShape.circle,
                            ),
                            child: Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          // User info skeleton
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Name skeleton
                                Container(
                                  width: double.infinity,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                // Email skeleton
                                Container(
                                  width: 150,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // Status badge skeleton
                                Container(
                                  width: 80,
                                  height: 26,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Vérifier si l'utilisateur n'est pas connecté
                if (!authController.isLoggedInSync &&
                    authController.userData == null) {
                  return _buildAnonymousProfile(context, isDark);
                }

                // Utilisateur connecté - afficher le profil
                return _buildUserProfile(
                  context,
                  authController.userData,
                  authController
                      .isLoggedInSync, // CORRECTION : Utiliser isLoggedInSync
                  isDark,
                );
              },
            ),

            // Section paramètres
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  // Section Compte
                  _buildSection(
                    context,
                    title: '',
                    items: [
                      _buildMenuItem(
                        icon: Iconsax.setting,
                        title: 'Détails du compte',
                        subtitle: 'Modifier vos informations personnelles',
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
                        color: AppColors.primary,
                      ),
                      _buildMenuItem(
                        icon: Iconsax.location,
                        title: 'Mes adresses',
                        subtitle: 'Gérer vos adresses de livraison',
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
                        color: AppColors.primary,
                      ),

                      _buildMenuItem(
                        icon: Iconsax.logout,
                        title: 'Déconnexion',
                        subtitle: 'Se déconnecter de votre compte',
                        onTap: () {
                          _showLogoutConfirmationDialog(context);
                        },
                        color: AppColors.secondary,
                      ),
                      _buildMenuItem(
                        icon: Iconsax.trash,
                        title: 'Supprimer le compte',
                        subtitle: 'Supprimer définitivement votre compte',
                        onTap: () {
                          _showDeleteAccountConfirmationDialog(context);
                        },
                        color: AppColors.error,
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

  // Dialog pour la déconnexion
  void _showLogoutConfirmationDialog(BuildContext context) {
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

                // Icône de déconnexion
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Iconsax.logout,
                    color: AppColors.secondary,
                    size: 40,
                  ),
                ),

                const SizedBox(height: 24),

                // Titre
                const Text(
                  'Déconnexion',
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
                  'Êtes-vous sûr de vouloir vous déconnecter ?',
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
                        onPressed: () async {
                          await Provider.of<AuthController>(
                            context,
                            listen: false,
                          ).signOut();
                          Navigator.of(ctx).pop();
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AuthSelectionScreen(),
                            ),
                            (route) => false,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
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
                            Icon(Iconsax.logout, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Se déconnecter',
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

  // Dialog pour la suppression du compte
  void _showDeleteAccountConfirmationDialog(BuildContext context) {
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

                // Icône d'avertissement
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Iconsax.trash, color: AppColors.error, size: 40),
                ),

                const SizedBox(height: 24),

                // Titre
                const Text(
                  'Supprimer le compte',
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
                  'Êtes-vous sûr de vouloir supprimer définitivement votre compte ? Cette action est irréversible.',
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
                        onPressed: () async {
                          await Provider.of<AuthController>(
                            context,
                            listen: false,
                          ).deleteAccount();
                          Navigator.of(ctx).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
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
                            Icon(Iconsax.trash, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Supprimer',
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

  // Remplacer l'appel _showLoginRequiredSnackBar(context) par :
  // _showLoginRequiredDialog(context)}
}
