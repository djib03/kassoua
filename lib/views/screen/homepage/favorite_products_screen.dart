import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kassoua/models/favori.dart';
import 'package:kassoua/views/widgets/product_card.dart'; // Ajuste le chemin si nécessaire

// =======================================================
// Firestore services
// =======================================================

class FavoriRepository {
  FavoriRepository._();
  static final FavoriRepository _instance = FavoriRepository._();
  factory FavoriRepository() => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Renvoie la liste des favoris (objets Favori) pour un utilisateur.
  Stream<List<Favori>> getFavoris(String userId) {
    return _firestore
        .collection('favoris')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return Favori(
              id: doc.id,
              userId: data['userId'],
              produitId: data['produitId'],
              dateAjout: (data['dateAjout'] as Timestamp).toDate(),
            );
          }).toList();
        });
  }

  /// Ajoute ou retire un favori (toggle).
  Future<void> toggleFavori(String userId, String produitId) async {
    final query =
        await _firestore
            .collection('favoris')
            .where('userId', isEqualTo: userId)
            .where('produitId', isEqualTo: produitId)
            .get();

    if (query.docs.isNotEmpty) {
      // Déjà dans les favoris → on supprime
      for (final doc in query.docs) {
        await doc.reference.delete();
      }
    } else {
      // Pas encore en favori → on ajoute
      await _firestore.collection('favoris').add({
        'userId': userId,
        'produitId': produitId,
        'dateAjout': Timestamp.now(),
      });
    }
  }
}

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Récupère une liste de produits par leurs IDs (avec gestion du whereIn ≤ 10)
  Future<List<Map<String, dynamic>>> fetchProductsByIds(
    List<String> ids,
  ) async {
    if (ids.isEmpty) return [];

    const chunkSize = 10; // Limite Firestore
    final List<Map<String, dynamic>> results = [];

    for (var i = 0; i < ids.length; i += chunkSize) {
      final chunk = ids.sublist(i, min(i + chunkSize, ids.length));
      final querySnap =
          await _firestore
              .collection('produits')
              .where(FieldPath.documentId, whereIn: chunk)
              .get();

      results.addAll(querySnap.docs.map((d) => {...d.data(), 'id': d.id}));
    }
    return results;
  }
}

// =======================================================
// UI
// =======================================================

class FavoriteProductsScreen extends StatelessWidget {
  const FavoriteProductsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Utilisateur non connecté')),
      );
    }

    final productService = ProductService();
    final favorisStream = FavoriRepository().getFavoris(user.uid);

    return Scaffold(
      appBar: AppBar(title: const Text('Mes favoris')),
      body: StreamBuilder<List<Favori>>(
        stream: favorisStream,
        builder: (context, favSnap) {
          if (favSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final favoris = favSnap.data ?? [];

          if (favoris.isEmpty) {
            return const _EmptyFavoriteView();
          }

          final ids = favoris.map((f) => f.produitId).toList();

          return FutureBuilder<List<Map<String, dynamic>>>(
            future: productService.fetchProductsByIds(ids),
            builder: (context, prodSnap) {
              if (!prodSnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final products = prodSnap.data!;

              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount:
                      MediaQuery.of(context).size.width > 600 ? 4 : 2,
                  childAspectRatio: 0.66,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  return ProductCard(
                    product: product,
                    isDark: Theme.of(context).brightness == Brightness.dark,
                    isFavorite: true,
                    isProcessing: false,
                    onToggleFavorite:
                        () => FavoriRepository().toggleFavori(
                          user.uid,
                          product['id'],
                        ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _EmptyFavoriteView extends StatelessWidget {
  const _EmptyFavoriteView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Iconsax.heart,
            size: 72,
            color: isDark ? Colors.white70 : Colors.grey[400],
          ),
          const SizedBox(height: 12),
          Text(
            'Tu n\'as encore ajouté aucun produit en favori.',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
