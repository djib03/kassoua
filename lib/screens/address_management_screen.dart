// address_management_screen.dart
import 'package:flutter/material.dart';
import 'package:kassoua/constants/colors.dart';
import 'package:kassoua/screens/add_edit_address_screen.dart';
// Importez votre fichier add_edit_address_screen.dart
// import 'add_edit_address_screen.dart';

// Modèle Address (à placer dans un fichier séparé models/address.dart)
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

class AddressManagementScreen extends StatefulWidget {
  const AddressManagementScreen({Key? key}) : super(key: key);

  @override
  State<AddressManagementScreen> createState() =>
      _AddressManagementScreenState();
}

class _AddressManagementScreenState extends State<AddressManagementScreen> {
  List<Address> addresses = [
    Address(
      id: '1',
      name: 'Ma maison',
      city: 'Plateau, Abidjan',
      phoneNumber: '+225 07 12 34 56 78',
      isDefault: true,
    ),
    Address(
      id: '2',
      name: 'Bureau',
      city: 'Cocody, Abidjan',
      phoneNumber: '+225 01 23 45 67 89',
      isDefault: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          Theme.of(context).brightness == Brightness.dark
              ? DMColors.black
              : Colors.white,
      appBar: AppBar(
        title: Text(
          'Mes Adresses',
          style: TextStyle(
            color:
                Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
          ),
        ),
        elevation: 0,
      ),
      body:
          addresses.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: addresses.length,
                itemBuilder: (context, index) {
                  return _buildAddressCard(addresses[index]);
                },
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewAddress,
        backgroundColor: DMColors.buttonPrimary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_off, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Aucune adresse enregistrée',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ajoutez votre première adresse de livraison',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard(Address address) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    address.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (address.isDefault)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Par défaut',
                      style: TextStyle(
                        fontSize: 12,
                        color: DMColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    address.city,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  address.phoneNumber,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!address.isDefault)
                  TextButton.icon(
                    onPressed: () => _setAsDefault(address.id),
                    icon: const Icon(Icons.star_border, size: 14),
                    label: const Text(
                      'Par défaut',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                TextButton.icon(
                  onPressed: () => _editAddress(address),
                  icon: const Icon(Icons.edit, size: 14),
                  label: const Text('Modifier', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    foregroundColor: DMColors.accent,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _deleteAddress(address.id),
                  icon: const Icon(Icons.delete, size: 14),
                  label: const Text(
                    'Suppr.', // Shortened text
                    style: TextStyle(fontSize: 12),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red[600],
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _addNewAddress() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddEditAddressScreen()),
    );

    if (result != null && result is Address) {
      setState(() {
        if (result.isDefault) {
          // Désactiver toutes les autres adresses par défaut
          addresses =
              addresses.map((addr) => addr.copyWith(isDefault: false)).toList();
        }
        addresses.add(result);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Adresse ajoutée avec succès'),
          backgroundColor: DMColors.primary,
        ),
      );
    }
  }

  void _editAddress(Address address) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddEditAddressScreen()),
    );

    if (result != null && result is Address) {
      setState(() {
        if (result.isDefault) {
          // Désactiver toutes les autres adresses par défaut
          addresses =
              addresses
                  .map(
                    (addr) =>
                        addr.id == result.id
                            ? result
                            : addr.copyWith(isDefault: false),
                  )
                  .toList();
        } else {
          addresses =
              addresses
                  .map((addr) => addr.id == result.id ? result : addr)
                  .toList();
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Adresse modifiée avec succès'),
          backgroundColor: DMColors.primary,
        ),
      );
    }
  }

  void _deleteAddress(String addressId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Supprimer l\'adresse'),
          content: const Text(
            'Êtes-vous sûr de vouloir supprimer cette adresse ?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  addresses.removeWhere((addr) => addr.id == addressId);
                });
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Adresse supprimée'),
                    backgroundColor: Colors.red,
                  ),
                );
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );
  }

  void _setAsDefault(String addressId) {
    setState(() {
      addresses =
          addresses.map((addr) {
            if (addr.id == addressId) {
              return addr.copyWith(isDefault: true);
            } else {
              return addr.copyWith(isDefault: false);
            }
          }).toList();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Adresse définie par défaut'),
        backgroundColor: DMColors.primaryDark,
      ),
    );
  }
}
