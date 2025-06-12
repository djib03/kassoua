import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kassoua/constants/colors.dart'; // Assure-toi que ce fichier existe et contient tes couleurs personnalisées.

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
    Color? valueColor,
    required Brightness brightness, // Ajout du paramètre brightness
  }) {
    // Détermine la couleur de fond de l'icône et la couleur du texte en fonction du thème
    Color iconBackgroundColor =
        brightness == Brightness.dark ? Colors.grey[800]! : Colors.grey[200]!;
    Color textColor =
        brightness == Brightness.dark ? Colors.white70 : Colors.black;
    Color labelColor =
        brightness == Brightness.dark ? Colors.white : Colors.black;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color:
                  valueColor ??
                  iconBackgroundColor, // Utilise la couleur adaptée au thème
              borderRadius: BorderRadius.circular(8),
            ),
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
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: labelColor, // Couleur du label adaptée au thème
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color:
                        valueColor ??
                        textColor, // Couleur de la valeur adaptée au thème
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
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
              Icons.edit,
              color:
                  brightness == Brightness.dark
                      ? DMColors.white
                      : DMColors.black,
            ),
            onPressed: () {
              // Handle edit action
            },
          ),
        ],
      ),
      body: Padding(
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
                  child: Image.asset('assets/images/user.png'),
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
                      color: shadowColor, // Ombre adaptée au thème
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
                        value: 'DKDM',
                        brightness: brightness,
                      ),
                      _buildInfoRow(
                        icon: Iconsax.message,
                        label: 'Email',
                        value: 'dkdm@example.com',
                        brightness: brightness,
                      ),
                      _buildInfoRow(
                        icon: Iconsax.call,
                        label: 'Téléphone',
                        value: '+227 90 00 00 00',
                        brightness: brightness,
                      ),
                      _buildInfoRow(
                        icon: Iconsax.location,
                        label: 'Adresse',
                        value: 'Niamey, Niger',
                        brightness: brightness,
                      ),
                    ], brightness), // Passage du paramètre brightness
                    _buildSection('Plus d\'information', [
                      _buildInfoRow(
                        icon: Iconsax.calendar,
                        label: 'Date de naissance',
                        value: '12 Janvier 1999',
                        brightness: brightness,
                      ),
                      _buildInfoRow(
                        icon: Iconsax.user4,
                        label: 'Genre',
                        value: 'Masculin',
                        brightness: brightness,
                      ),
                    ], brightness), // Passage du paramètre brightness
                    _buildSection('Informations du Compte', [
                      _buildInfoRow(
                        icon:
                            Iconsax
                                .calendar_1, // Correction : calendar3 n'existe pas, calendar_1 est une alternative courante
                        label: 'Membre depuis',
                        value: '01 Janvier 2023',
                        brightness: brightness,
                      ),
                    ], brightness), // Passage du paramètre brightness
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
