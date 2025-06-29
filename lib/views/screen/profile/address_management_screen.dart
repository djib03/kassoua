// address_management_screen.dart
import 'package:flutter/material.dart';
import 'package:kassoua/constants/colors.dart';
import 'package:kassoua/views/screen/profile/add_edit_address_screen.dart';
import 'package:kassoua/models/adresse.dart';
import 'package:kassoua/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

class AddressManagementScreen extends StatefulWidget {
  const AddressManagementScreen({Key? key}) : super(key: key);

  @override
  State<AddressManagementScreen> createState() =>
      _AddressManagementScreenState();
}

class _AddressManagementScreenState extends State<AddressManagementScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  String?
  currentUserId; // Rendre non final pour pouvoir le définir dans initState

  @override
  void initState() {
    super.initState();
    currentUserId = FirebaseAuth.instance.currentUser?.uid; // Initialiser ici
  }

  @override
  Widget build(BuildContext context) {
    if (currentUserId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mes Adresses')),
        body: const Center(
          child: Text('Veuillez vous connecter pour voir vos adresses'),
        ),
      );
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          Theme.of(context).brightness == Brightness.dark
              ? AppColors.black
              : AppColors.white,
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor:
              Colors.transparent, // Transparente pour un meilleur rendu
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          statusBarBrightness:
              isDark ? Brightness.dark : Brightness.light, // Pour iOS
        ),
        title: Text(
          'Mes Adresses',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(builder: (ctx) => const AddEditAddressScreen()),
          );
          if (result != null && result is Adresse) {
            // Si la nouvelle adresse est par défaut, réinitialiser les autres
            if (result.isDefaut) {
              await _firestoreService.resetDefaultAddresses(
                currentUserId!,
                newDefaultId: result.id,
              );
            }
            await _firestoreService.addAdresse(result);
            _showSnackBar('Adresse ajoutée avec succès!', Colors.green);
          }
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<Adresse>>(
        stream: _firestoreService.getAdressesStream(currentUserId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          }

          final adresses = snapshot.data;

          if (adresses == null || adresses.isEmpty) {
            return const Center(
              child: Text(
                'Aucune adresse enregistrée. Ajoutez-en une nouvelle !',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: adresses.length,
            itemBuilder: (ctx, index) {
              final adresse = adresses[index];
              return _buildAddressCard(adresse);
            },
          );
        },
      ),
    );
  }

  Widget _buildAddressCard(Adresse adresse) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    adresse.description,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (adresse.isDefaut)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Par défaut',
                      style: TextStyle(color: Colors.white, fontSize: 12),
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
                    adresse.quartier != null && adresse.quartier!.isNotEmpty
                        ? '${adresse.quartier}, ${adresse.ville ?? ''}'
                        : 'Lat: ${adresse.latitude.toStringAsFixed(6)}, Lng: ${adresse.longitude.toStringAsFixed(6)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () async {
                    final result = await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder:
                            (ctx) => AddEditAddressScreen(address: adresse),
                      ),
                    );
                    if (result != null && result is Adresse) {
                      // Si l'adresse modifiée est maintenant par défaut, réinitialiser les autres
                      if (result.isDefaut && !adresse.isDefaut) {
                        await _firestoreService.resetDefaultAddresses(
                          currentUserId!,
                          newDefaultId: result.id,
                        );
                      }
                      await _firestoreService.updateAdresse(result);
                      _showSnackBar(
                        'Adresse modifiée avec succès!',
                        Colors.green,
                      );
                    }
                  },
                  child: const Text('Modifier'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => _confirmDeleteAddress(adresse),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Supprimer'),
                ),
                const SizedBox(width: 8),
                if (!adresse.isDefaut)
                  TextButton(
                    onPressed: () => _setAsDefault(adresse),
                    child: const Text('Définir par défaut'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteAddress(Adresse adresse) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Supprimer l\'adresse'),
          content: Text(
            'Êtes-vous sûr de vouloir supprimer l\'adresse "${adresse.description}" ?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
              },
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await _firestoreService.deleteAdresse(adresse.id);
                  if (mounted) {
                    Navigator.of(ctx).pop();
                    _showSnackBar(
                      'Adresse supprimée avec succès!',
                      Colors.green,
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    _showSnackBar('Erreur: $e', Colors.red);
                  }
                }
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );
  }

  void _setAsDefault(Adresse adresse) async {
    try {
      final updatedAdresse = Adresse(
        id: adresse.id,
        description: adresse.description,
        latitude: adresse.latitude,
        longitude: adresse.longitude,
        isDefaut: true,
        idUtilisateur: adresse.idUtilisateur,
        quartier: adresse.quartier,
        ville: adresse.ville,
      );

      await _firestoreService.resetDefaultAddresses(
        adresse.idUtilisateur!,
        newDefaultId: adresse.id,
      );
      await _firestoreService.updateAdresse(updatedAdresse);

      if (mounted) {
        _showSnackBar('Adresse définie par défaut', AppColors.primaryDark);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Erreur: $e', Colors.red);
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
    }
  }
}
