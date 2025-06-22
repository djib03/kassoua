import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kassoua/constants/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kassoua/models/user.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Contrôleurs pour les champs de texte
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();

  String _selectedGender = 'Autre';
  final List<String> _genderOptions = ['Masculin', 'Féminin', 'Autre'];

  bool _isLoading = false;
  Utilisateur? _currentUser;

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
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _fetchUserData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _firstNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final docSnapshot =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();

        if (docSnapshot.exists) {
          _currentUser = Utilisateur.fromMap(
            docSnapshot.data()!,
            docSnapshot.id,
          );
          _nameController.text = _currentUser!.nom;
          _firstNameController.text = _currentUser!.prenom;
          _emailController.text = _currentUser!.email;
          _phoneController.text = _currentUser!.telephone;
          if (_currentUser!.dateNaissance != null) {
            _birthDateController.text =
                "${_currentUser!.dateNaissance!.day} ${_getMonthName(_currentUser!.dateNaissance!.month)} ${_currentUser!.dateNaissance!.year}";
          }
          _selectedGender = _currentUser!.genre ?? 'Autre';
        }
      }
      _animationController.forward();
    } catch (e) {
      print('Error fetching user data: $e');
      _showErrorSnackBar('Erreur lors du chargement des données utilisateur.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildAnimatedCard({required Widget child}) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(opacity: _fadeAnimation, child: child),
    );
  }

  Widget _buildProfileHeader(Brightness brightness) {
    final Color cardColor =
        brightness == Brightness.dark ? Colors.grey[850]! : Colors.white;

    return _buildAnimatedCard(
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color:
                  brightness == Brightness.dark
                      ? Colors.black.withOpacity(0.3)
                      : Colors.grey.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Stack(
              children: [
                Hero(
                  tag: 'profile_photo',
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          DMColors.primary.withOpacity(0.8),
                          DMColors.primary,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: DMColors.primary.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(3),
                    child: Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(50),
                        child:
                            _currentUser?.photoProfil != null &&
                                    _currentUser!.photoProfil!.isNotEmpty
                                ? Image.network(
                                  _currentUser!.photoProfil!,
                                  fit: BoxFit.cover,
                                )
                                : Container(
                                  color: Colors.grey[100],
                                  child: Icon(
                                    Iconsax.user,
                                    size: 40,
                                    color: Colors.grey[400],
                                  ),
                                ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: _isLoading ? null : _pickAndUploadImage,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: DMColors.primary,
                          boxShadow: [
                            BoxShadow(
                              color: DMColors.primary.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          Iconsax.camera,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Modifier votre profil',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color:
                    brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Mettez à jour vos informations personnelles',
              style: TextStyle(
                fontSize: 14,
                color:
                    brightness == Brightness.dark
                        ? Colors.grey[400]
                        : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormSection({
    required String title,
    required List<Widget> children,
    required Brightness brightness,
    IconData? icon,
  }) {
    final Color cardColor =
        brightness == Brightness.dark ? Colors.grey[850]! : Colors.white;

    return _buildAnimatedCard(
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color:
                  brightness == Brightness.dark
                      ? Colors.black.withOpacity(0.2)
                      : Colors.grey.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Row(
                children: [
                  if (icon != null) ...[
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: DMColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, size: 20, color: DMColors.primary),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                      color:
                          brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(children: children),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required IconData icon,
    required String label,
    required String hint,
    required Brightness brightness,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    final Color textColor =
        brightness == Brightness.dark ? Colors.white : Colors.black87;
    final Color hintColor =
        brightness == Brightness.dark ? Colors.grey[400]! : Colors.grey[600]!;
    final Color fillColor =
        brightness == Brightness.dark ? Colors.grey[800]! : Colors.grey[50]!;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 4),
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: textColor,
              ),
            ),
          ),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            readOnly: readOnly,
            onTap: onTap,
            style: TextStyle(color: textColor, fontSize: 16),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: hintColor, fontSize: 15),
              prefixIcon: Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: DMColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 20, color: DMColors.primary),
              ),
              filled: true,
              fillColor: fillColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: DMColors.primary, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            validator: validator,
          ),
        ],
      ),
    );
  }

  Widget _buildModernDropdown(Brightness brightness) {
    final Color textColor =
        brightness == Brightness.dark ? Colors.white : Colors.black87;
    final Color fillColor =
        brightness == Brightness.dark ? Colors.grey[800]! : Colors.grey[50]!;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 4),
            child: Text(
              'Genre',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: textColor,
              ),
            ),
          ),
          DropdownButtonFormField<String>(
            value: _selectedGender,
            style: TextStyle(color: textColor, fontSize: 16),
            decoration: InputDecoration(
              prefixIcon: Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: DMColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Iconsax.user, size: 20, color: DMColors.primary),
              ),
              filled: true,
              fillColor: fillColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: DMColors.primary, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            dropdownColor:
                brightness == Brightness.dark ? Colors.grey[800] : Colors.white,
            items:
                _genderOptions.map((String gender) {
                  return DropdownMenuItem<String>(
                    value: gender,
                    child: Text(gender),
                  );
                }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedGender = newValue;
                });
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(Brightness brightness) {
    return _buildAnimatedCard(
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _saveProfile,
          style: ElevatedButton.styleFrom(
            backgroundColor: DMColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shadowColor: DMColors.primary.withOpacity(0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ).copyWith(
            elevation: MaterialStateProperty.resolveWith<double>((
              Set<MaterialState> states,
            ) {
              if (states.contains(MaterialState.pressed)) return 8;
              return 4;
            }),
          ),
          child:
              _isLoading
                  ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                  : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Iconsax.tick_circle, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Sauvegarder les modifications',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _currentUser?.dateNaissance ?? DateTime(1999, 1, 12),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: DMColors.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _birthDateController.text =
            "${picked.day} ${_getMonthName(picked.month)} ${picked.year}";
      });
    }
  }

  String _getMonthName(int month) {
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
    return months[month];
  }

  int? _getMonthNumber(String monthName) {
    const months = {
      'Janvier': 1,
      'Février': 2,
      'Mars': 3,
      'Avril': 4,
      'Mai': 5,
      'Juin': 6,
      'Juillet': 7,
      'Août': 8,
      'Septembre': 9,
      'Octobre': 10,
      'Novembre': 11,
      'Décembre': 12,
    };
    return months[monthName];
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final birthDateParts = _birthDateController.text.split(' ');
          DateTime? birthDate;
          if (birthDateParts.length == 3) {
            final day = int.tryParse(birthDateParts[0]);
            final month = _getMonthNumber(birthDateParts[1]);
            final year = int.tryParse(birthDateParts[2]);
            if (day != null && month != null && year != null) {
              birthDate = DateTime(year, month, day);
            }
          }

          final updatedUser = Utilisateur(
            id: user.uid,
            nom: _nameController.text,
            prenom: _firstNameController.text,
            email: _emailController.text,
            telephone: _phoneController.text,
            photoProfil: _currentUser?.photoProfil,
            dateInscription: _currentUser?.dateInscription ?? DateTime.now(),
            dateNaissance: birthDate,
            genre: _selectedGender,
          );

          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set(updatedUser.toMap());

          _showSuccessSnackBar('Profil mis à jour avec succès');
          Navigator.pop(context);
        }
      } catch (e) {
        print('Error updating user data: $e');
        _showErrorSnackBar('Erreur lors de la mise à jour du profil.');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 50,
        maxWidth: 512,
        maxHeight: 512,
      );

      if (pickedFile == null) return;

      setState(() => _isLoading = true);

      final file = File(pickedFile.path);

      // 🔄 Préparation de la requête vers Cloudinary
      final uri = Uri.parse(
        "https://api.cloudinary.com/v1_1/dzttvgpfs/image/upload",
      );

      final request =
          http.MultipartRequest('POST', uri)
            ..fields['upload_preset'] = 'dkdm_app'
            ..files.add(await http.MultipartFile.fromPath('file', file.path));

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final decoded = json.decode(responseData);
        final imageUrl = decoded['secure_url'];

        print('✅ Image URL Cloudinary: $imageUrl');

        final user = FirebaseAuth.instance.currentUser;
        if (user == null) return;

        // 🔥 Mise à jour Firestore avec l'URL
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'photoProfil': imageUrl});

        setState(() {
          if (_currentUser != null) {
            _currentUser = _currentUser!.copyWith(photoProfil: imageUrl);
          }
        });

        _showSuccessSnackBar('✅ Photo mise à jour !');
      } else {
        print('❌ Erreur Cloudinary: ${response.statusCode}');
        _showErrorSnackBar("Erreur d'envoi (${response.statusCode})");
      }
    } catch (e, stackTrace) {
      print('❌ Exception: $e');
      print('Stack trace: $stackTrace');
      _showErrorSnackBar('Erreur: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Brightness brightness = Theme.of(context).brightness;
    final Color backgroundColor =
        brightness == Brightness.dark ? DMColors.black : DMColors.white;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'Modifier le profil',
          style: TextStyle(
            color:
                brightness == Brightness.dark ? Colors.white : DMColors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(
          color: brightness == Brightness.dark ? Colors.white : Colors.black,
        ),
      ),
      body:
          _isLoading && _currentUser == null
              ? const Center(child: CircularProgressIndicator())
              : Form(
                key: _formKey,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      _buildProfileHeader(brightness),
                      _buildFormSection(
                        title: 'Informations personnelles',
                        icon: Iconsax.user_octagon,
                        brightness: brightness,
                        children: [
                          _buildModernTextField(
                            controller: _nameController,
                            icon: Iconsax.user_tag,
                            label: 'Nom',
                            hint: 'Entrez votre nom',
                            brightness: brightness,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Veuillez entrer votre nom';
                              }
                              return null;
                            },
                          ),
                          _buildModernTextField(
                            controller: _firstNameController,
                            icon: Iconsax.user,
                            label: 'Prénom',
                            hint: 'Entrez votre prénom',
                            brightness: brightness,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Veuillez entrer votre prénom';
                              }
                              return null;
                            },
                          ),
                          _buildModernTextField(
                            controller: _emailController,
                            icon: Iconsax.message,
                            label: 'Email',
                            hint: 'Entrez votre email',
                            brightness: brightness,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Veuillez entrer votre email';
                              }
                              if (!value.contains('@')) {
                                return 'Veuillez entrer un email valide';
                              }
                              return null;
                            },
                          ),
                          _buildModernTextField(
                            controller: _phoneController,
                            icon: Iconsax.call,
                            label: 'Téléphone',
                            hint: 'Entrez votre numéro de téléphone',
                            brightness: brightness,
                            keyboardType: TextInputType.phone,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Veuillez entrer votre numéro de téléphone';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                      _buildFormSection(
                        title: 'Informations complémentaires',
                        icon: Iconsax.info_circle,
                        brightness: brightness,
                        children: [
                          _buildModernTextField(
                            controller: _birthDateController,
                            icon: Iconsax.calendar,
                            label: 'Date de naissance',
                            hint: 'Sélectionnez votre date de naissance',
                            brightness: brightness,
                            readOnly: true,
                            onTap: () => _selectDate(context),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Veuillez sélectionner votre date de naissance';
                              }
                              return null;
                            },
                          ),
                          _buildModernDropdown(brightness),
                        ],
                      ),
                      _buildSaveButton(brightness),
                    ],
                  ),
                ),
              ),
    );
  }
}
