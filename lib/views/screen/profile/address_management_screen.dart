// address_management_screen.dart
import 'package:flutter/material.dart';
import 'package:kassoua/constants/colors.dart';
import 'package:kassoua/views/screen/profile/add_edit_address_screen.dart';
import 'package:kassoua/models/adresse.dart';
import 'package:kassoua/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddressManagementScreen extends StatefulWidget {
  const AddressManagementScreen({Key? key}) : super(key: key);

  @override
  State<AddressManagementScreen> createState() =>
      _AddressManagementScreenState();
}

class _AddressManagementScreenState extends State<AddressManagementScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  String? currentUserId;
  String? authType;

  @override
  void initState() {
    super.initState();
    _initializeUser();
  }

  Future<void> _initializeUser() async {
    final prefs = await SharedPreferences.getInstance();
    final authTypeFromPrefs = prefs.getString('authType') ?? 'firebase';

    setState(() {
      authType = authTypeFromPrefs;

      if (authTypeFromPrefs == 'firebase') {
        currentUserId = FirebaseAuth.instance.currentUser?.uid;
      } else {
        currentUserId = prefs.getString('loggedInUserId');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (currentUserId == null) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.black : AppColors.white,
        appBar: AppBar(
          backgroundColor: isDark ? AppColors.black : AppColors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness:
                isDark ? Brightness.light : Brightness.dark,
            statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
          ),
          title: Text(
            'Mes Adresses',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ),
        body: const Center(
          child: Text('Veuillez vous connecter pour voir vos adresses'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.black : AppColors.white,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.black : AppColors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
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
            _showSnackBar('Adresse ajoutée avec succès!', AppColors.primary);
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
            return Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red.withOpacity(0.6),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Erreur: ${snapshot.error}',
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black87,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final adresses = snapshot.data;

          if (adresses == null || adresses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.location_off_outlined,
                    size: 80,
                    color: (isDark ? Colors.white : Colors.black).withOpacity(
                      0.3,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Aucune adresse enregistrée',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ajoutez votre première adresse pour commencer',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final result = await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (ctx) => const AddEditAddressScreen(),
                        ),
                      );
                      if (result != null && result is Adresse) {
                        if (result.isDefaut) {
                          await _firestoreService.resetDefaultAddresses(
                            currentUserId!,
                            newDefaultId: result.id,
                          );
                        }
                        await _firestoreService.addAdresse(result);
                        _showSnackBar(
                          'Adresse ajoutée avec succès!',
                          AppColors.primary,
                        );
                      }
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Ajouter une adresse'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(10.0),
            itemCount: adresses.length,
            itemBuilder: (ctx, index) {
              final adresse = adresses[index];
              return _buildAddressCard(adresse, isDark);
            },
          );
        },
      ),
    );
  }

  Widget _buildAddressCard(Adresse adresse, bool isDark) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: isDark ? AppColors.dark : AppColors.white,
      elevation: isDark ? 4 : 2,
      shadowColor: isDark ? Colors.black54 : Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? Colors.white10 : Colors.black12,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    adresse.description,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (adresse.isDefaut)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Par défaut',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 18,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    adresse.quartier != null && adresse.quartier!.isNotEmpty
                        ? '${adresse.quartier}, ${adresse.ville ?? ''}'
                        : 'Lat: ${adresse.latitude.toStringAsFixed(6)}, Lng: ${adresse.longitude.toStringAsFixed(6)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              // mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
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
                        AppColors.primary,
                      );
                    }
                  },
                  icon: const Icon(Icons.edit_outlined, size: 14),
                  label: const Text('Modifier'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                  ),
                ),
                // const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _confirmDeleteAddress(adresse),
                  icon: const Icon(Icons.delete_outline, size: 14),
                  label: const Text('Supprimer'),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                ),
                if (!adresse.isDefaut) ...[
                  // const SizedBox(width: 3),
                  TextButton.icon(
                    onPressed: () => _setAsDefault(adresse),
                    icon: const Icon(Icons.star_outline, size: 14),
                    label: const Text('Par défaut'),
                    style: TextButton.styleFrom(
                      foregroundColor: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteAddress(Adresse adresse) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: isDark ? AppColors.dark : AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Supprimer l\'adresse',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Êtes-vous sûr de vouloir supprimer l\'adresse "${adresse.description}" ?',
            style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                'Annuler',
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await _firestoreService.deleteAdresse(adresse.id);
                  if (mounted) {
                    Navigator.of(ctx).pop();
                    _showSnackBar(
                      'Adresse supprimée avec succès!',
                      AppColors.primary,
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    _showSnackBar('Erreur: $e', Colors.grey);
                  }
                }
              },
              child: const Text(
                'Supprimer',
                style: TextStyle(color: Colors.grey),
              ),
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
        _showSnackBar('Adresse définie par défaut', AppColors.primary);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Erreur: $e', Colors.red);
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }
}
