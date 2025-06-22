import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kassoua/constants/colors.dart';
import 'package:kassoua/screens/edit_user_details.dart';
import 'package:provider/provider.dart';
import 'package:kassoua/controllers/auth_controller.dart';
import 'package:kassoua/models/user.dart';

class UserDetailScreen extends StatelessWidget {
  const UserDetailScreen({Key? key}) : super(key: key);

  Widget _buildSection(
    String title,
    List<Widget> children,
    Brightness brightness,
  ) {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color:
                  brightness == Brightness.dark
                      ? DMColors.white
                      : DMColors.black, // Couleur du texte adaptée au thème
            ),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Brightness brightness, // Ajout du paramètre brightness
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
            child: Icon(
              icon,
              size: 20,
              color: DMColors.primary,
            ), // La couleur de l'icône reste bleue
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
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
    final Brightness brightness =
        Theme.of(context).brightness; // Récupère le thème actuel
    final Color backgroundColor =
        brightness == Brightness.dark
            ? Theme.of(context).colorScheme.surface
            : DMColors.white;
    final Color cardColor =
        brightness == Brightness.dark
            ? Colors.grey[900]!
            : DMColors.white; // Couleur de la carte
    final Color shadowColor =
        brightness == Brightness.dark
            ? Colors.transparent
            : Colors.grey.withOpacity(0.2); // Ombre adaptée

    return Scaffold(
      backgroundColor: backgroundColor, // Fond de l'écran adapté au thème
      appBar: AppBar(
        title: Text(
          'Informations du compte',
          style: TextStyle(
            color:
                brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black, // Couleur du titre de l'AppBar
          ),
        ),
        backgroundColor: backgroundColor, // Fond de l'AppBar adapté au thème
        elevation:
            0, // Enlève l'ombre par défaut de l'AppBar pour un look plus propre
        iconTheme: IconThemeData(
          color:
              brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black, // Couleur des icônes de l'AppBar
        ),
        actions: [
          IconButton(
            icon: Icon(
              Iconsax.edit,
              color:
                  brightness == Brightness.dark
                      ? DMColors.white
                      : DMColors.black,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => EditProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<Utilisateur?>(
        future:
            Provider.of<AuthController>(context, listen: false).fetchUserData(),
        builder: (context, snapshot) {
          final brightness = Theme.of(context).brightness;
          final cardColor =
              brightness == Brightness.dark
                  ? Colors.grey[900]!
                  : DMColors.white;
          final shadowColor =
              brightness == Brightness.dark
                  ? Colors.transparent
                  : Colors.grey.withOpacity(0.2);

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('Aucune information utilisateur'));
          }
          final user = snapshot.data!;

          return Padding(
            padding: EdgeInsets.only(),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey, width: 4),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(60),
                      child:
                          (user.photoProfil == null ||
                                  user.photoProfil!.isEmpty)
                              ? Image.asset('assets/images/user.png')
                              : Image.network(
                                user.photoProfil!,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (context, error, stackTrace) =>
                                        Image.asset('assets/images/user.png'),
                              ),
                    ),
                  ),
                  SizedBox(height: 24),
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color:
                          cardColor, // Couleur de fond de la carte adaptée au thème
                      boxShadow: [
                        BoxShadow(
                          color: shadowColor,
                          blurRadius: 20,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSection('Information Personnelle', [
                          _buildInfoRow(
                            icon: Iconsax.profile_2user,
                            label: 'Nom Complet',
                            value: '${user.nom} ${user.prenom}',
                            brightness: brightness,
                          ),
                          _buildInfoRow(
                            icon: Iconsax.message,
                            label: 'Email',
                            value:
                                user.email.isNotEmpty
                                    ? user.email
                                    : 'Non renseigné',
                            brightness: brightness,
                          ),
                          _buildInfoRow(
                            icon: Iconsax.call,
                            label: 'Téléphone',
                            value:
                                user.telephone.isNotEmpty
                                    ? user.telephone
                                    : 'Non renseigné',
                            brightness: brightness,
                          ),
                          _buildInfoRow(
                            icon: Iconsax.location,
                            label: 'Adresse',
                            value: 'Non renseignée',
                            brightness: brightness,
                          ),
                        ], brightness),
                        _buildSection('Plus d\'information', [
                          _buildInfoRow(
                            icon: Iconsax.calendar,
                            label: 'Date de naissance',
                            value:
                                user.dateNaissance != null
                                    ? '${user.dateNaissance!.day}/${user.dateNaissance!.month}/${user.dateNaissance!.year}'
                                    : 'Non renseignée',
                            brightness: brightness,
                          ),
                          _buildInfoRow(
                            icon: Iconsax.user4,
                            label: 'Genre',
                            value: user.genre ?? 'Non renseigné',
                            brightness: brightness,
                          ),
                        ], brightness), // Passage du paramètre brightness
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
