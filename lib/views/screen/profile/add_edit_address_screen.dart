import 'package:flutter/material.dart';
import 'package:kassoua/constants/colors.dart';
import 'package:kassoua/models/adresse.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddEditAddressScreen extends StatefulWidget {
  final Adresse? address;

  const AddEditAddressScreen({Key? key, this.address}) : super(key: key);

  @override
  State<AddEditAddressScreen> createState() => _AddEditAddressScreenState();
}

class _AddEditAddressScreenState extends State<AddEditAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final TextEditingController _quartierController = TextEditingController();
  final TextEditingController _villeController = TextEditingController();

  bool _isDefault = false;
  bool _isLoadingLocation = false;
  double? _latitude;
  double? _longitude;
  String? _currentUserId;
  String? _authType;

  bool get isEditing => widget.address != null;

  @override
  void initState() {
    super.initState();
    _initializeUser();
    if (isEditing) {
      // Mode modification : pré-remplir avec les données existantes
      _descriptionController.text = widget.address!.description;
      _latitude = widget.address!.latitude;
      _longitude = widget.address!.longitude;
      _isDefault = widget.address!.isDefaut;
      _quartierController.text = widget.address!.quartier ?? '';
      _villeController.text = widget.address!.ville ?? '';
    }
  }

  Future<void> _initializeUser() async {
    final prefs = await SharedPreferences.getInstance();
    final authTypeFromPrefs = prefs.getString('authType') ?? 'firebase';

    setState(() {
      _authType = authTypeFromPrefs;

      if (authTypeFromPrefs == 'firebase') {
        _currentUserId = FirebaseAuth.instance.currentUser?.uid;
      } else {
        _currentUserId = prefs.getString('loggedInUserId');
      }
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _quartierController.dispose();
    _villeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Si l'utilisateur n'est pas connecté, afficher un message
    if (_currentUserId == null) {
      return Scaffold(
        backgroundColor:
            Theme.of(context).brightness == Brightness.dark
                ? AppColors.black
                : Colors.white,
        appBar: AppBar(
          iconTheme: IconThemeData(
            color:
                Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
          ),
          title: Text(
            'Adresse',
            style: TextStyle(
              color:
                  Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
            ),
          ),
          elevation: 0,
        ),
        body: const Center(
          child: Text('Veuillez vous connecter pour gérer vos adresses'),
        ),
      );
    }

    return Scaffold(
      backgroundColor:
          Theme.of(context).brightness == Brightness.dark
              ? AppColors.black
              : Colors.white,
      appBar: AppBar(
        iconTheme: IconThemeData(
          color:
              Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black,
        ),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor:
              Colors.transparent, // Transparente pour un meilleur rendu
          statusBarIconBrightness:
              Theme.of(context).brightness == Brightness.dark
                  ? Brightness.light
                  : Brightness.dark,
          statusBarBrightness:
              Theme.of(context).brightness == Brightness.dark
                  ? Brightness.dark
                  : Brightness.light, // Pour iOS
        ),
        title: Text(
          isEditing ? 'Modifier l\'adresse' : 'Ajouter une adresse',
          style: TextStyle(
            color:
                Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
          ),
        ),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Informations de l\'adresse',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Description de l'adresse
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Description de l\'adresse*',
                          hintText:
                              'Ex: Plateau, près de la pharmacie centrale, immeuble bleu au 3ème étage...',
                          prefixIcon: const Icon(Icons.description_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: AppColors.primary!),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Veuillez saisir une description pour cette adresse';
                          }
                          if (value.trim().length < 10) {
                            return 'La description doit contenir au moins 10 caractères';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Champ pour le Quartier (auto-rempli)
                      TextFormField(
                        controller: _quartierController,
                        decoration: InputDecoration(
                          labelText: 'Quartier (auto-rempli)',
                          prefixIcon: const Icon(Icons.location_city),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: AppColors.primary),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Champ pour la Ville (auto-rempli)
                      TextFormField(
                        controller: _villeController,
                        decoration: InputDecoration(
                          labelText: 'Ville (auto-remplie)',
                          prefixIcon: const Icon(Icons.map),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: AppColors.primary!),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Case à cocher pour adresse par défaut
                      Row(
                        children: [
                          Checkbox(
                            value: _isDefault,
                            onChanged: (value) {
                              setState(() {
                                _isDefault = value ?? false;
                              });
                            },
                            activeColor: AppColors.primary,
                          ),
                          const Expanded(
                            child: Text(
                              'Définir comme adresse par défaut',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                      if (_isDefault)
                        Padding(
                          padding: const EdgeInsets.only(left: 48.0),
                          child: Text(
                            'Cette adresse sera utilisée par défaut pour vos livraisons',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Bouton pour géolocalisation
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading:
                      _isLoadingLocation
                          ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : Icon(Icons.my_location, color: AppColors.primary),
                  title: Text(
                    _latitude != null && _longitude != null
                        ? 'Position enregistrée ✓'
                        : 'Utiliser ma position actuelle',
                    style: TextStyle(
                      color:
                          _isLoadingLocation
                              ? Colors.grey[500]
                              : (_latitude != null && _longitude != null)
                              ? AppColors.primary
                              : AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    _isLoadingLocation
                        ? 'Récupération de la position...'
                        : _latitude != null && _longitude != null
                        ? 'Lat: ${_latitude!.toStringAsFixed(6)}, Lng: ${_longitude!.toStringAsFixed(6)}'
                        : 'Obtenir automatiquement mes coordonnées GPS',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  onTap: _isLoadingLocation ? null : _getCurrentLocation,
                ),
              ),
              const SizedBox(height: 24),

              // Boutons d'action
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Annuler'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveAddress,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(isEditing ? 'Modifier' : 'Ajouter'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _getCurrentLocation() async {
    if (_currentUserId == null) {
      _showSnackBar(
        'Veuillez vous connecter pour utiliser cette fonctionnalité',
        Colors.red,
      );
      return;
    }

    setState(() {
      _isLoadingLocation = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnackBar(
          'Les services de localisation sont désactivés',
          Colors.orange,
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSnackBar('Permission de localisation refusée', Colors.red);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showSnackBar(
          'Permission de localisation refusée définitivement',
          Colors.red,
        );
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });

      // Géocodage inversée pour obtenir l'adresse
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          Placemark place = placemarks.first;
          setState(() {
            _quartierController.text =
                place.subLocality ?? place.locality ?? '';
            _villeController.text =
                place.administrativeArea ?? place.country ?? '';
            if (_descriptionController.text.isEmpty) {
              _descriptionController.text =
                  "${place.street ?? ''}, ${place.subLocality ?? ''}, ${place.locality ?? ''}";
              _descriptionController.text = _descriptionController.text
                  .trim()
                  .replaceAll(RegExp(r',\s*$'), '');
            }
          });
          _showSnackBar(
            'Position et adresse approximative obtenues avec succès',
            AppColors.primary,
          );
        } else {
          _showSnackBar(
            'Position obtenue, mais impossible de trouver l\'adresse approximative',
            Colors.grey,
          );
        }
      } catch (e) {
        _showSnackBar(
          'Position obtenue, erreur lors du géocodage: $e',
          Colors.grey,
        );
      }
    } catch (e) {
      _showSnackBar(
        'Erreur lors de la récupération de la position: $e',
        Colors.grey,
      );
    } finally {
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  void _showSnackBar(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
    }
  }

  void _saveAddress() {
    if (_currentUserId == null) {
      _showSnackBar(
        'Veuillez vous connecter pour sauvegarder une adresse',
        Colors.grey,
      );
      return;
    }

    if (_latitude == null || _longitude == null) {
      _showSnackBar(
        'Veuillez d\'abord obtenir votre position GPS',
        Colors.grey,
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      final address = Adresse(
        id:
            isEditing
                ? widget.address!.id
                : DateTime.now().millisecondsSinceEpoch.toString(),
        description: _descriptionController.text.trim(),
        latitude: _latitude!,
        longitude: _longitude!,
        isDefaut: _isDefault,
        idUtilisateur: _currentUserId!,
        quartier:
            _quartierController.text.trim().isNotEmpty
                ? _quartierController.text.trim()
                : null,
        ville:
            _villeController.text.trim().isNotEmpty
                ? _villeController.text.trim()
                : null,
      );

      Navigator.of(context).pop(address);
    }
  }
}
