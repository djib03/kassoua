import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kassoua/constants/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kassoua/models/user.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  // Contrôleurs pour les champs de texte
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();

  String _selectedGender = 'Autre';
  final List<String> _genderOptions = ['Masculin', 'Féminin', 'Autre'];

  bool _isLoading = false;
  bool _isSaving = false;
  bool _hasChanges = false;
  Utilisateur? _currentUser;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _fetchUserData();
    _setupChangeListeners();
  }

  void _setupChangeListeners() {
    _nameController.addListener(_onFieldChanged);
    _firstNameController.addListener(_onFieldChanged);
    _emailController.addListener(_onFieldChanged);
    _phoneController.addListener(_onFieldChanged);
    _birthDateController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
    }
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
      final prefs = await SharedPreferences.getInstance();
      final authType = prefs.getString('authType') ?? 'firebase';

      if (authType == 'firebase') {
        // Utilisateur Firebase
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
            _populateFields();
          }
        }
      } else {
        // Utilisateur téléphone
        final loggedInUserId = prefs.getString('loggedInUserId');
        if (loggedInUserId != null && loggedInUserId.isNotEmpty) {
          final docSnapshot =
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(loggedInUserId)
                  .get();

          if (docSnapshot.exists) {
            _currentUser = Utilisateur.fromMap(
              docSnapshot.data()!,
              docSnapshot.id,
            );
            _populateFields();
          }
        }
      }
    } catch (e) {
      print('Error fetching user data: $e');
      _showErrorSnackBar('Erreur lors du chargement des données utilisateur.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _populateFields() {
    if (_currentUser != null) {
      _nameController.text = _currentUser!.nom;
      _firstNameController.text = _currentUser!.prenom;
      _emailController.text = _currentUser!.email;
      _phoneController.text = _currentUser!.telephone;
      if (_currentUser!.dateNaissance != null) {
        _birthDateController.text =
            "${_currentUser!.dateNaissance!.day} ${_getMonthName(_currentUser!.dateNaissance!.month)} ${_currentUser!.dateNaissance!.year}";
      }
      _selectedGender = _currentUser!.genre ?? 'Autre';
      _animationController.forward();
    }
  }

  Widget _buildSection(
    String title,
    List<Widget> children,
    Brightness brightness, {
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 20, 24, isLast ? 20 : 12),
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
            const SizedBox(height: 16),
            Divider(
              color:
                  brightness == Brightness.dark
                      ? Colors.grey[800]
                      : Colors.grey[200],
              thickness: 1,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEditableInfoRow({
    required IconData icon,
    required String label,
    required Widget child,
    required Brightness brightness,
    bool isRequired = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                brightness == Brightness.dark
                    ? Colors.grey[800]!
                    : Colors.grey[200]!,
            width: 1,
          ),
          color:
              brightness == Brightness.dark
                  ? Colors.grey[900]?.withOpacity(0.3)
                  : Colors.grey[50],
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
                  Row(
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color:
                              brightness == Brightness.dark
                                  ? Colors.white
                                  : Colors.black87,
                          letterSpacing: 0.3,
                        ),
                      ),
                      if (isRequired) ...[
                        const SizedBox(width: 4),
                        Text(
                          '*',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  child,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required Brightness brightness,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    bool readOnly = false,
    VoidCallback? onTap,
    int maxLines = 1,
  }) {
    final Color textColor =
        brightness == Brightness.dark ? Colors.white : Colors.black87;
    final Color hintColor =
        brightness == Brightness.dark ? Colors.grey[400]! : Colors.grey[600]!;

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      onTap: onTap,
      maxLines: maxLines,
      style: TextStyle(
        color: textColor,
        fontSize: 15,
        fontWeight: FontWeight.w500,
        height: 1.4,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: hintColor,
          fontSize: 15,
          fontWeight: FontWeight.w400,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor:
            brightness == Brightness.dark
                ? Colors.grey[800]?.withOpacity(0.3)
                : Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        suffixIcon:
            readOnly
                ? Icon(
                  Iconsax.calendar,
                  color: AppColors.primary.withOpacity(0.7),
                  size: 20,
                )
                : null,
      ),
      validator: validator,
    );
  }

  Widget _buildDropdownField(Brightness brightness) {
    final Color textColor =
        brightness == Brightness.dark ? Colors.white : Colors.black87;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color:
            brightness == Brightness.dark
                ? Colors.grey[800]?.withOpacity(0.3)
                : Colors.white,
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedGender,
        style: TextStyle(
          color: textColor,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          filled: true,
          fillColor: Colors.transparent,
        ),
        dropdownColor:
            brightness == Brightness.dark ? Colors.grey[800] : Colors.white,
        items:
            _genderOptions.map((String gender) {
              return DropdownMenuItem<String>(
                value: gender,
                child: Row(
                  children: [
                    Icon(
                      gender == 'Masculin'
                          ? Iconsax.man
                          : gender == 'Féminin'
                          ? Iconsax.woman
                          : Iconsax.user,
                      size: 16,
                      color: AppColors.primary.withOpacity(0.7),
                    ),
                    const SizedBox(width: 8),
                    Text(gender),
                  ],
                ),
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
    );
  }

  Widget _buildProfileHeader(Brightness brightness) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Hero(
            tag: 'profile_image_edit',
            child: Stack(
              children: [
                Container(
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
                          (_currentUser?.photoProfil == null ||
                                  _currentUser!.photoProfil!.isEmpty)
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
                                child: Icon(
                                  Iconsax.user,
                                  size: 60,
                                  color: AppColors.primary.withOpacity(0.7),
                                ),
                              )
                              : Image.network(
                                _currentUser!.photoProfil!,
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
                                      child: Icon(
                                        Iconsax.user,
                                        size: 60,
                                        color: AppColors.primary.withOpacity(
                                          0.7,
                                        ),
                                      ),
                                    ),
                              ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _isLoading ? null : _pickAndUploadImage,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary,
                            AppColors.primary.withOpacity(0.8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(
                          color:
                              brightness == Brightness.dark
                                  ? AppColors.black
                                  : Colors.white,
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child:
                          _isLoading
                              ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                              : Icon(
                                Iconsax.camera,
                                size: 18,
                                color: Colors.white,
                              ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Modifier votre photo',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
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

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Iconsax.warning_2, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Iconsax.tick_circle, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
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
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface:
                  Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[800]
                      : Colors.white,
            ),
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
        _isSaving = true;
      });

      try {
        final prefs = await SharedPreferences.getInstance();
        final authType = prefs.getString('authType') ?? 'firebase';

        String? userId;

        if (authType == 'firebase') {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            userId = user.uid;
          }
        } else {
          userId = prefs.getString('loggedInUserId');
        }

        if (userId != null) {
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
            id: userId,
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
              .doc(userId)
              .set(updatedUser.toMap(), SetOptions(merge: true));

          _showSuccessSnackBar('Profil mis à jour avec succès');
          Navigator.pop(context, true);
        }
      } catch (e) {
        print('Error updating user data: $e');
        _showErrorSnackBar('Erreur lors de la mise à jour du profil.');
      } finally {
        setState(() {
          _isSaving = false;
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

        final prefs = await SharedPreferences.getInstance();
        final authType = prefs.getString('authType') ?? 'firebase';

        String? userId;

        if (authType == 'firebase') {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            userId = user.uid;
          }
        } else {
          userId = prefs.getString('loggedInUserId');
        }

        if (userId != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .update({'photoProfil': imageUrl});

          setState(() {
            if (_currentUser != null) {
              _currentUser = _currentUser!.copyWith(
                photoProfil: imageUrl,
                nom: _nameController.text,
                prenom: _firstNameController.text,
              );
            }
          });

          _showSuccessSnackBar('Photo mise à jour avec succès !');
        }
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
          'Modifier le profil',
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
                    colors:
                        _hasChanges
                            ? [
                              AppColors.primary.withOpacity(0.2),
                              AppColors.primary.withOpacity(0.1),
                            ]
                            : [
                              Colors.grey.withOpacity(0.1),
                              Colors.grey.withOpacity(0.05),
                            ],
                  ),
                ),
                child:
                    _isSaving
                        ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primary,
                            ),
                          ),
                        )
                        : Icon(
                          Iconsax.tick_circle,
                          color: _hasChanges ? AppColors.primary : Colors.grey,
                          size: 20,
                        ),
              ),
              onPressed: (_isSaving || !_hasChanges) ? null : _saveProfile,
            ),
          ),
        ],
      ),
      body:
          _isLoading && _currentUser == null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: AppColors.primary),
                    const SizedBox(height: 16),
                    Text(
                      'Chargement des informations...',
                      style: TextStyle(
                        color:
                            brightness == Brightness.dark
                                ? Colors.white70
                                : Colors.black54,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              )
              : FadeTransition(
                opacity: _fadeAnimation,
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        _buildProfileHeader(brightness),
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
                                _buildEditableInfoRow(
                                  icon: Iconsax.user_tag,
                                  label: 'Nom',
                                  brightness: brightness,
                                  isRequired: true,
                                  child: _buildTextField(
                                    controller: _nameController,
                                    hint: 'Entrez votre nom',
                                    brightness: brightness,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Veuillez entrer votre nom';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                _buildEditableInfoRow(
                                  icon: Iconsax.user,
                                  label: 'Prénom',
                                  brightness: brightness,
                                  isRequired: true,
                                  child: _buildTextField(
                                    controller: _firstNameController,
                                    hint: 'Entrez votre prénom',
                                    brightness: brightness,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Veuillez entrer votre prénom';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                _buildEditableInfoRow(
                                  icon: Iconsax.calendar,
                                  label: 'Date de naissance',
                                  brightness: brightness,
                                  child: _buildTextField(
                                    controller: _birthDateController,
                                    hint:
                                        'Sélectionnez votre date de naissance',
                                    brightness: brightness,
                                    readOnly: true,
                                    onTap: () => _selectDate(context),
                                  ),
                                ),
                                _buildEditableInfoRow(
                                  icon: Iconsax.user_octagon,
                                  label: 'Genre',
                                  brightness: brightness,
                                  child: _buildDropdownField(brightness),
                                ),
                              ], brightness),

                              _buildSection(
                                'Informations de Contact',
                                [
                                  _buildEditableInfoRow(
                                    icon: Iconsax.sms,
                                    label: 'Email',
                                    brightness: brightness,
                                    child: _buildTextField(
                                      controller: _emailController,
                                      hint: 'Entrez votre email',
                                      brightness: brightness,
                                      keyboardType: TextInputType.emailAddress,
                                      validator: (value) {
                                        if (value != null && value.isNotEmpty) {
                                          final emailRegex = RegExp(
                                            r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                                          );
                                          if (!emailRegex.hasMatch(value)) {
                                            return 'Email invalide';
                                          }
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  _buildEditableInfoRow(
                                    icon: Iconsax.call,
                                    label: 'Téléphone',
                                    brightness: brightness,
                                    isRequired: true,
                                    child: _buildTextField(
                                      controller: _phoneController,
                                      hint: 'Entrez votre numéro de téléphone',
                                      brightness: brightness,
                                      keyboardType: TextInputType.phone,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Veuillez entrer votre numéro de téléphone';
                                        }
                                        // Validation basique du numéro de téléphone
                                        if (value.length < 8) {
                                          return 'Numéro de téléphone trop court';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                                brightness,
                                isLast: true,
                              ),
                            ],
                          ),
                        ),

                        // Bouton de sauvegarde fixe en bas
                        Container(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              // Bouton principal de sauvegarde
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed:
                                      (_isSaving || !_hasChanges)
                                          ? null
                                          : _saveProfile,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        _hasChanges
                                            ? AppColors.primary
                                            : Colors.grey,
                                    foregroundColor: Colors.white,
                                    elevation: _hasChanges ? 8 : 2,
                                    shadowColor:
                                        _hasChanges
                                            ? AppColors.primary.withOpacity(0.3)
                                            : Colors.grey.withOpacity(0.3),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child:
                                      _isSaving
                                          ? Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              SizedBox(
                                                width: 20,
                                                height: 20,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                        Color
                                                      >(Colors.white),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Text(
                                                'Sauvegarde...',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ],
                                          )
                                          : Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                _hasChanges
                                                    ? Iconsax.tick_circle
                                                    : Iconsax.document,
                                                size: 20,
                                              ),
                                              const SizedBox(width: 12),
                                              Text(
                                                _hasChanges
                                                    ? 'Sauvegarder les modifications'
                                                    : 'Aucune modification',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                ),
                              ),

                              // Bouton secondaire pour annuler
                              if (_hasChanges) ...[
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  height: 48,
                                  child: TextButton(
                                    onPressed:
                                        _isSaving
                                            ? null
                                            : () {
                                              // Remettre les valeurs originales
                                              _populateFields();
                                              setState(() {
                                                _hasChanges = false;
                                              });
                                            },
                                    style: TextButton.styleFrom(
                                      foregroundColor:
                                          brightness == Brightness.dark
                                              ? Colors.white70
                                              : Colors.black54,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Iconsax.refresh, size: 18),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Annuler les modifications',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
    );
  }

  // Méthode pour afficher une boîte de dialogue de confirmation avant de quitter
  Future<bool> _showExitConfirmationDialog() async {
    if (!_hasChanges) return true;

    return await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text('Modifications non sauvegardées'),
                content: Text(
                  'Vous avez des modifications non sauvegardées. Voulez-vous vraiment quitter ?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text('Annuler'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text('Quitter'),
                  ),
                ],
              ),
        ) ??
        false;
  }

  // Override pour intercepter le bouton retour du système

  // Méthode séparée pour le contenu principal
  Widget _buildMainContent(BuildContext context) {
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
          'Modifier le profil',
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
        leading: IconButton(
          icon: Icon(Iconsax.arrow_left),
          onPressed: () async {
            if (await _showExitConfirmationDialog()) {
              Navigator.of(context).pop();
            }
          },
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
                    colors:
                        _hasChanges
                            ? [
                              AppColors.primary.withOpacity(0.2),
                              AppColors.primary.withOpacity(0.1),
                            ]
                            : [
                              Colors.grey.withOpacity(0.1),
                              Colors.grey.withOpacity(0.05),
                            ],
                  ),
                ),
                child:
                    _isSaving
                        ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primary,
                            ),
                          ),
                        )
                        : Icon(
                          Iconsax.tick_circle,
                          color: _hasChanges ? AppColors.primary : Colors.grey,
                          size: 20,
                        ),
              ),
              onPressed: (_isSaving || !_hasChanges) ? null : _saveProfile,
            ),
          ),
        ],
      ),
      body:
          _isLoading && _currentUser == null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: AppColors.primary),
                    const SizedBox(height: 16),
                    Text(
                      'Chargement des informations...',
                      style: TextStyle(
                        color:
                            brightness == Brightness.dark
                                ? Colors.white70
                                : Colors.black54,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              )
              : FadeTransition(
                opacity: _fadeAnimation,
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        _buildProfileHeader(brightness),
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
                                _buildEditableInfoRow(
                                  icon: Iconsax.user_tag,
                                  label: 'Nom',
                                  brightness: brightness,
                                  isRequired: true,
                                  child: _buildTextField(
                                    controller: _nameController,
                                    hint: 'Entrez votre nom',
                                    brightness: brightness,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Veuillez entrer votre nom';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                _buildEditableInfoRow(
                                  icon: Iconsax.user,
                                  label: 'Prénom',
                                  brightness: brightness,
                                  isRequired: true,
                                  child: _buildTextField(
                                    controller: _firstNameController,
                                    hint: 'Entrez votre prénom',
                                    brightness: brightness,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Veuillez entrer votre prénom';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                _buildEditableInfoRow(
                                  icon: Iconsax.calendar,
                                  label: 'Date de naissance',
                                  brightness: brightness,
                                  child: _buildTextField(
                                    controller: _birthDateController,
                                    hint:
                                        'Sélectionnez votre date de naissance',
                                    brightness: brightness,
                                    readOnly: true,
                                    onTap: () => _selectDate(context),
                                  ),
                                ),
                                _buildEditableInfoRow(
                                  icon: Iconsax.user_octagon,
                                  label: 'Genre',
                                  brightness: brightness,
                                  child: _buildDropdownField(brightness),
                                ),
                              ], brightness),

                              _buildSection(
                                'Informations de Contact',
                                [
                                  _buildEditableInfoRow(
                                    icon: Iconsax.sms,
                                    label: 'Email',
                                    brightness: brightness,
                                    child: _buildTextField(
                                      controller: _emailController,
                                      hint: 'Entrez votre email',
                                      brightness: brightness,
                                      keyboardType: TextInputType.emailAddress,
                                      validator: (value) {
                                        if (value != null && value.isNotEmpty) {
                                          final emailRegex = RegExp(
                                            r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                                          );
                                          if (!emailRegex.hasMatch(value)) {
                                            return 'Email invalide';
                                          }
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  _buildEditableInfoRow(
                                    icon: Iconsax.call,
                                    label: 'Téléphone',
                                    brightness: brightness,
                                    isRequired: true,
                                    child: _buildTextField(
                                      controller: _phoneController,
                                      hint: 'Entrez votre numéro de téléphone',
                                      brightness: brightness,
                                      keyboardType: TextInputType.phone,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Veuillez entrer votre numéro de téléphone';
                                        }
                                        // Validation basique du numéro de téléphone
                                        if (value.length < 8) {
                                          return 'Numéro de téléphone trop court';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                                brightness,
                                isLast: true,
                              ),
                            ],
                          ),
                        ),

                        // Bouton de sauvegarde fixe en bas
                        Container(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              // Bouton principal de sauvegarde
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed:
                                      (_isSaving || !_hasChanges)
                                          ? null
                                          : _saveProfile,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        _hasChanges
                                            ? AppColors.primary
                                            : Colors.grey,
                                    foregroundColor: Colors.white,
                                    elevation: _hasChanges ? 8 : 2,
                                    shadowColor:
                                        _hasChanges
                                            ? AppColors.primary.withOpacity(0.3)
                                            : Colors.grey.withOpacity(0.3),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child:
                                      _isSaving
                                          ? Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              SizedBox(
                                                width: 20,
                                                height: 20,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                        Color
                                                      >(Colors.white),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Text(
                                                'Sauvegarde...',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ],
                                          )
                                          : Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                _hasChanges
                                                    ? Iconsax.tick_circle
                                                    : Iconsax.document,
                                                size: 20,
                                              ),
                                              const SizedBox(width: 12),
                                              Text(
                                                _hasChanges
                                                    ? 'Sauvegarder les modifications'
                                                    : 'Aucune modification',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                ),
                              ),

                              // Bouton secondaire pour annuler
                              if (_hasChanges) ...[
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  height: 48,
                                  child: TextButton(
                                    onPressed:
                                        _isSaving
                                            ? null
                                            : () {
                                              // Remettre les valeurs originales
                                              _populateFields();
                                              setState(() {
                                                _hasChanges = false;
                                              });
                                            },
                                    style: TextButton.styleFrom(
                                      foregroundColor:
                                          brightness == Brightness.dark
                                              ? Colors.white70
                                              : Colors.black54,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Iconsax.refresh, size: 18),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Annuler les modifications',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
    );
  }
}
