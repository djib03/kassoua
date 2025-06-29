import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kassoua/constants/colors.dart';
import 'package:kassoua/models/adresse.dart';
import 'package:kassoua/views/screen/profile/edit_user_details.dart';
import 'package:provider/provider.dart';
import 'package:kassoua/controllers/auth_controller.dart';
import 'package:kassoua/models/user.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:kassoua/views/screen/profile/add_edit_address_screen.dart';
import 'package:kassoua/services/firestore_service.dart';

class UserDetailScreen extends StatefulWidget {
  const UserDetailScreen({Key? key}) : super(key: key);

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Widget _buildSection(
    String title,
    List<Widget> children,
    Brightness brightness, {
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 20, 24, isLast ? 20 : 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withOpacity(0.6),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color:
                      brightness == Brightness.dark
                          ? AppColors.white
                          : AppColors.black,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
          if (!isLast) ...[
            const SizedBox(height: 12),
            Divider(
              color:
                  brightness == Brightness.dark
                      ? Colors.grey[800]
                      : Colors.grey[200],
              thickness: 1,
              indent: 0,
              endIndent: 0,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Brightness brightness,
    bool isClickable = false,
    VoidCallback? onTap,
  }) {
    final Color valueColor =
        brightness == Brightness.dark ? Colors.white70 : Colors.black87;
    final Color labelColor =
        brightness == Brightness.dark ? Colors.white : Colors.black87;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color:
                isClickable
                    ? (brightness == Brightness.dark
                        ? Colors.grey[800]?.withOpacity(0.3)
                        : Colors.grey[50])
                    : Colors.transparent,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.1),
                      AppColors.primary.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Icon(icon, size: 20, color: AppColors.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: labelColor,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: valueColor,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              if (isClickable)
                Icon(
                  Iconsax.arrow_right_3,
                  size: 16,
                  color: AppColors.primary.withOpacity(0.7),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatBirthDate(DateTime? date) {
    if (date == null) return 'Non renseignée';
    const months = [
      '',
      'Janvier',
      'Février',
      'Mars',
      'Avril',
      'Mai',
      'Juin',
      'Juillet',
      'Août',
      'Septembre',
      'Octobre',
      'Novembre',
      'Décembre',
    ];
    return '${date.day} ${months[date.month]} ${date.year}';
  }

  Widget _buildProfileHeader(
    Utilisateur? user,
    Brightness brightness, {
    bool isLoading = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      child: Column(
        children: [
          Hero(
            tag: 'profile_image',
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.3),
                    width: 3,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(65),
                  child:
                      isLoading || user == null
                          ? Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primary.withOpacity(0.1),
                                  AppColors.primary.withOpacity(0.05),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Image.asset(
                              'assets/images/user.png',
                              fit: BoxFit.cover,
                            ),
                          )
                          : (user.photoProfil == null ||
                              user.photoProfil!.isEmpty)
                          ? Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primary.withOpacity(0.1),
                                  AppColors.primary.withOpacity(0.05),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Image.asset(
                              'assets/images/user.png',
                              fit: BoxFit.cover,
                            ),
                          )
                          : Image.network(
                            user.photoProfil!,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (context, error, stackTrace) => Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.primary.withOpacity(0.1),
                                        AppColors.primary.withOpacity(0.05),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                  child: Image.asset(
                                    'assets/images/user.png',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                          ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            textAlign: TextAlign.center,
            isLoading || user == null
                ? 'Nom Prénom'
                : '${user.nom} ${user.prenom}',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color:
                  brightness == Brightness.dark ? Colors.white : Colors.black,
              letterSpacing: 0.5,
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.1),
                  AppColors.primary.withOpacity(0.05),
                ],
              ),
            ),
            child: Text(
              isLoading || user == null
                  ? 'email@exemple.com'
                  : (user.email.isNotEmpty
                      ? user.email
                      : 'Email non renseigné'),
              style: TextStyle(
                fontSize: 14,
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final FirestoreService _firestoreService = FirestoreService();

    // Force la couleur de la status bar à chaque affichage de l'écran
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: isDark ? AppColors.black : Colors.white,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
    );

    final Brightness brightness = Theme.of(context).brightness;
    final Color backgroundColor =
        brightness == Brightness.dark ? AppColors.black : AppColors.white;
    final Color cardColor =
        brightness == Brightness.dark ? Colors.grey[900]! : AppColors.white;
    final Color shadowColor =
        brightness == Brightness.dark
            ? Colors.black.withOpacity(0.3)
            : Colors.grey.withOpacity(0.15);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'Mon Profil',
          style: TextStyle(
            color: brightness == Brightness.dark ? Colors.white : Colors.black,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(
          color: brightness == Brightness.dark ? Colors.white : Colors.black,
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.1),
                      AppColors.primary.withOpacity(0.05),
                    ],
                  ),
                ),
                child: Icon(Iconsax.edit, color: AppColors.primary, size: 20),
              ),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder:
                        (context, animation, secondaryAnimation) =>
                            const EditProfileScreen(),
                    transitionsBuilder: (
                      context,
                      animation,
                      secondaryAnimation,
                      child,
                    ) {
                      const begin = Offset(1.0, 0.0);
                      const end = Offset.zero;
                      const curve = Curves.easeInOut;
                      final tween = Tween(
                        begin: begin,
                        end: end,
                      ).chain(CurveTween(curve: curve));
                      return SlideTransition(
                        position: animation.drive(tween),
                        child: child,
                      );
                    },
                    transitionDuration: const Duration(milliseconds: 300),
                  ),
                );
                if (result == true) {
                  setState(() {});
                }
              },
            ),
          ),
        ],
      ),
      body: FutureBuilder<Utilisateur?>(
        future:
            Provider.of<AuthController>(context, listen: false).fetchUserData(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Iconsax.warning_2,
                    size: 64,
                    color: Colors.red.withOpacity(0.7),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Erreur de chargement',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color:
                          brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Impossible de charger vos informations',
                    style: TextStyle(
                      color:
                          brightness == Brightness.dark
                              ? Colors.white70
                              : Colors.black54,
                    ),
                  ),
                ],
              ),
            );
          }

          // Détermine si on doit afficher le skeleton
          final bool isLoading =
              snapshot.connectionState == ConnectionState.waiting;
          final Utilisateur? user = snapshot.data;

          return Skeletonizer(
            enabled: isLoading,
            child: SlideTransition(
              position: _slideAnimation,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    _buildProfileHeader(
                      isLoading ? null : user,
                      brightness,
                      isLoading: isLoading,
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: cardColor,
                        boxShadow: [
                          BoxShadow(
                            color: shadowColor,
                            blurRadius: 25,
                            offset: const Offset(0, 8),
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSection('Informations Personnelles', [
                            _buildInfoRow(
                              icon: Iconsax.user_tag,
                              label: 'Nom',
                              value:
                                  user != null && user.nom.isNotEmpty
                                      ? user.nom
                                      : 'Non renseigné',
                              brightness: brightness,
                            ),
                            _buildInfoRow(
                              icon: Iconsax.user,
                              label: 'Prénom',
                              value:
                                  user != null && user.prenom.isNotEmpty
                                      ? user.prenom
                                      : 'Non renseigné',
                              brightness: brightness,
                            ),
                            _buildInfoRow(
                              icon: Iconsax.call,
                              label: 'Téléphone',
                              value:
                                  user != null && user.telephone.isNotEmpty
                                      ? user.telephone
                                      : 'Non renseigné',
                              brightness: brightness,
                              isClickable:
                                  !isLoading &&
                                  user != null &&
                                  user.telephone.isNotEmpty,
                              onTap:
                                  !isLoading &&
                                          user != null &&
                                          user.telephone.isNotEmpty
                                      ? () {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Appel de ${user.telephone}',
                                            ),
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                        );
                                      }
                                      : null,
                            ),
                            FutureBuilder<List<Adresse>>(
                              future:
                                  user != null
                                      ? _firestoreService
                                          .getDefaultAdresses(user.id)
                                          .first
                                      : Future.value([]),
                              builder: (context, addressSnapshot) {
                                String addressValue = 'Non renseignée';
                                if (addressSnapshot.hasData &&
                                    addressSnapshot.data!.isNotEmpty) {
                                  final Adresse adresse =
                                      addressSnapshot.data!.first;
                                  addressValue = adresse.description;
                                }
                                return _buildInfoRow(
                                  icon: Iconsax.location,
                                  label: 'Adresse',
                                  value: addressValue,
                                  brightness: brightness,
                                  isClickable: true,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => AddEditAddressScreen(),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ], brightness),
                          _buildSection(
                            'Informations Supplémentaires',
                            [
                              _buildInfoRow(
                                icon: Iconsax.calendar,
                                label: 'Date de naissance',
                                value:
                                    user != null
                                        ? _formatBirthDate(user.dateNaissance)
                                        : 'Non renseignée',
                                brightness: brightness,
                              ),
                              _buildInfoRow(
                                icon: Iconsax.user4,
                                label: 'Genre',
                                value:
                                    user != null && user.genre != null
                                        ? user.genre!
                                        : 'Non renseigné',
                                brightness: brightness,
                              ),
                            ],
                            brightness,
                            isLast: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
