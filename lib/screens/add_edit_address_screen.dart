// add_edit_address_screen.dart
import 'package:flutter/material.dart';
// Importez votre modèle Address
// import 'models/address.dart';

// Si vous n'avez pas encore créé le fichier models/address.dart,
// copiez cette classe depuis address_management_screen.dart
class Address {
  final String id;
  final String name;
  final String city;
  final String phoneNumber;
  final bool isDefault;

  Address({
    required this.id,
    required this.name,
    required this.city,
    required this.phoneNumber,
    this.isDefault = false,
  });

  Address copyWith({
    String? id,
    String? name,
    String? city,
    String? phoneNumber,
    bool? isDefault,
  }) {
    return Address(
      id: id ?? this.id,
      name: name ?? this.name,
      city: city ?? this.city,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}

class AddEditAddressScreen extends StatefulWidget {
  final Address? address;

  const AddEditAddressScreen({Key? key, this.address}) : super(key: key);

  @override
  State<AddEditAddressScreen> createState() => _AddEditAddressScreenState();
}

class _AddEditAddressScreenState extends State<AddEditAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _cityController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isDefault = false;

  bool get isEditing => widget.address != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _nameController.text = widget.address!.name;
      _cityController.text = widget.address!.city;
      _phoneController.text = widget.address!.phoneNumber;
      _isDefault = widget.address!.isDefault;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Modifier l\'adresse' : 'Ajouter une adresse'),
        backgroundColor: Colors.green[600],

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

                      // Nom de l'adresse
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Nom de l\'adresse*',
                          hintText: 'Ex: Ma maison, Bureau, Chez maman...',
                          prefixIcon: const Icon(Icons.label_outline),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.green[600]!),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Veuillez saisir un nom pour cette adresse';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Ville/Quartier
                      TextFormField(
                        controller: _cityController,
                        decoration: InputDecoration(
                          labelText: 'Ville/Quartier*',
                          hintText: 'Ex: Plateau, Cocody, Yopougon...',
                          prefixIcon: const Icon(Icons.location_city),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.green[600]!),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Veuillez saisir la ville ou le quartier';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Numéro de téléphone
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'Numéro de téléphone*',
                          hintText: 'Ex: +225 07 12 34 56 78',
                          prefixIcon: const Icon(Icons.phone),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.green[600]!),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Veuillez saisir un numéro de téléphone';
                          }
                          if (value.trim().length < 8) {
                            return 'Numéro de téléphone trop court';
                          }
                          return null;
                        },
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
                            activeColor: Colors.green[600],
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

              // Bouton futur pour géolocalisation
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: Icon(Icons.my_location, color: Colors.grey[400]),
                  title: Text(
                    'Utiliser ma position actuelle',
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                  subtitle: Text(
                    'Fonctionnalité bientôt disponible',
                    style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                  ),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Fonctionnalité de géolocalisation bientôt disponible',
                        ),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  },
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
                        backgroundColor: Colors.green[600],
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

  void _saveAddress() {
    if (_formKey.currentState!.validate()) {
      final address = Address(
        id:
            isEditing
                ? widget.address!.id
                : DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        city: _cityController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        isDefault: _isDefault,
      );

      Navigator.of(context).pop(address);
    }
  }
}
