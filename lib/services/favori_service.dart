import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/favori.dart';
import '../models/image_produit.dart'; // Ajout de l'import pour ImageProduit
import 'dart:math';

class favoriService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'products';

  // Cache pour les images
  final Map<String, ImageProduit?> _productImageCache = {};
  final Map<String, int> _imageRetryCount = {};
  final int _maxRetries = 3;

  favoriService() {
    // Activer la persistance hors ligne
    _firestore.settings = const Settings(persistenceEnabled: true);
  }

  // ✅ Méthode pour récupérer l'image principale d'un produit
  Future<ImageProduit?> getImagePrincipale(String produitId) async {
    // Vérifier le cache seulement si pas d'erreur précédente
    if (_productImageCache.containsKey(produitId) &&
        !_imageRetryCount.containsKey(produitId)) {
      return _productImageCache[produitId];
    }

    try {
      final query =
          await _firestore
              .collection('imagesProduits')
              .where('produitId', isEqualTo: produitId)
              .limit(1)
              .get();

      ImageProduit? image;
      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        image = ImageProduit.fromMap(doc.data(), doc.id);
      }

      // ✅ Mettre en cache et réinitialiser le compteur d'erreurs
      _productImageCache[produitId] = image;
      _imageRetryCount.remove(produitId);
      return image;
    } catch (e) {
      print('Erreur lors du chargement de l\'image: $e');

      // ✅ Gestion des retry
      final currentRetries = _imageRetryCount[produitId] ?? 0;
      if (currentRetries < _maxRetries) {
        _imageRetryCount[produitId] = currentRetries + 1;
        // Retry après un délai
        await Future.delayed(Duration(seconds: currentRetries + 1));
        return getImagePrincipale(produitId);
      } else {
        // Échec définitif
        _productImageCache[produitId] = null;
        return null;
      }
    }
  }

  // ✅ Méthode pour récupérer les produits par leurs IDs
  Future<List<Map<String, dynamic>>> fetchProductsByIds(
    List<String> ids,
  ) async {
    if (ids.isEmpty) return [];

    const chunkSize = 10; // Limite Firestore pour whereIn
    final List<Map<String, dynamic>> results = [];

    for (var i = 0; i < ids.length; i += chunkSize) {
      final chunk = ids.sublist(i, min(i + chunkSize, ids.length));

      try {
        final querySnap =
            await _firestore
                .collection(
                  'products',
                ) // Utilisez 'products' ou 'produits' selon votre collection
                .where(FieldPath.documentId, whereIn: chunk)
                .get();

        results.addAll(querySnap.docs.map((d) => {...d.data(), 'id': d.id}));
      } catch (e) {
        print('Erreur lors de la récupération des produits: $e');
      }
    }
    return results;
  }

  // ✅ Méthode pour ajouter un favori
  Future<void> addFavori(Favori favori) async {
    try {
      await _firestore.collection('favoris').doc(favori.id).set(favori.toMap());
    } catch (e) {
      print('Erreur lors de l\'ajout du favori: $e');
      rethrow;
    }
  }

  // ✅ Méthode pour ajouter un favori avec userId et produitId
  Future<void> addFavoriByIds(String userId, String produitId) async {
    // Vérifier si le favori existe déjà
    final existing =
        await _firestore
            .collection('favoris')
            .where('userId', isEqualTo: userId)
            .where('produitId', isEqualTo: produitId)
            .get();

    if (existing.docs.isNotEmpty) {
      return; // Le favori existe déjà
    }

    final favori = Favori(
      id: generateNewFavoriId(),
      userId: userId,
      produitId: produitId,
      dateAjout: DateTime.now(),
    );

    await addFavori(favori);
  }

  // ✅ Générer un nouvel ID pour un favori
  String generateNewFavoriId() {
    return _firestore.collection('favoris').doc().id;
  }

  // ✅ Méthode pour supprimer un favori par ID
  Future<void> removeFavori(String userId, String produitId) async {
    try {
      final favorisRef = _firestore
          .collection('favoris')
          .where('userId', isEqualTo: userId)
          .where('produitId', isEqualTo: produitId);

      final snapshot = await favorisRef.get();
      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      print('Erreur lors de la suppression du favori: $e');
      rethrow;
    }
  }

  // ✅ Méthode pour obtenir les favoris d'un utilisateur
  Stream<List<Favori>> getFavoris(String userId) {
    return _firestore
        .collection('favoris')
        .where('userId', isEqualTo: userId)
        .orderBy('dateAjout', descending: true) // Tri par date d'ajout
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

  // ✅ Méthode pour vérifier si un produit est en favori
  Future<bool> isFavorite(String userId, String produitId) async {
    try {
      final snapshot =
          await _firestore
              .collection('favoris')
              .where('userId', isEqualTo: userId)
              .where('produitId', isEqualTo: produitId)
              .limit(1)
              .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('Erreur lors de la vérification du favori: $e');
      return false;
    }
  }

  // ✅ Méthode pour obtenir le nombre de favoris d'un utilisateur
  Future<int> getFavorisCount(String userId) async {
    try {
      final snapshot =
          await _firestore
              .collection('favoris')
              .where('userId', isEqualTo: userId)
              .get();

      return snapshot.docs.length;
    } catch (e) {
      print('Erreur lors du comptage des favoris: $e');
      return 0;
    }
  }

  // ✅ Méthode pour basculer l'état favori (ajouter/supprimer)
  Future<bool> toggleFavorite(String userId, String produitId) async {
    try {
      final isFav = await isFavorite(userId, produitId);

      if (isFav) {
        await removeFavori(userId, produitId);
        return false; // Plus en favori
      } else {
        await addFavoriByIds(userId, produitId);
        return true; // Ajouté aux favoris
      }
    } catch (e) {
      print('Erreur lors du basculement du favori: $e');
      rethrow;
    }
  }

  // ✅ Méthode pour supprimer tous les favoris d'un utilisateur
  Future<void> clearAllFavoris(String userId) async {
    try {
      final snapshot =
          await _firestore
              .collection('favoris')
              .where('userId', isEqualTo: userId)
              .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      print('Erreur lors de la suppression de tous les favoris: $e');
      rethrow;
    }
  }
}
