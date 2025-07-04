import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';
import '../models/discussion.dart';
import '../models/notification.dart';
import '../models/categorie.dart';
import '../models/favori.dart';
import '../models/adresse.dart';
import '../models/image_produit.dart';
import '../models/user.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'products';
  FirestoreService() {
    // Activer la persistance hors ligne
    _firestore.settings = const Settings(persistenceEnabled: true);
  }

  // --- Produits ---

  // nombre de vue d un produit
  Future<void> incrementProductViews(String productId) async {
    await _firestore.collection('products').doc(productId).update({
      'vues': FieldValue.increment(1),
    });
  }

  //recuperer produit par categorie
  Stream<List<Produit>> getProductsByCategoryStream(String categorieId) {
    return _firestore
        .collection(_collection)
        .where('categorieId', isEqualTo: categorieId)
        .where(
          'statut',
          isEqualTo: 'disponible',
        ) // Seulement les produits disponibles
        .orderBy('dateAjout', descending: true)
        .limit(20) // Limiter à 20 produits par catégorie pour les performances
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return Produit.fromMap(doc.data() as Map<String, dynamic>, doc.id);
          }).toList();
        });
  }

  /// Récupérer un produit spécifique
  Future<Produit?> getProduct(String productId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(productId).get();
      if (doc.exists) {
        return Produit.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Erreur lors de la récupération du produit: $e');
    }
  }

  /// Récupérer tous les produits disponibles
  Stream<List<Produit>> getAllProductsStream() {
    return _firestore
        .collection(_collection)
        .where('statut', isEqualTo: 'disponible')
        .orderBy('dateAjout', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return Produit.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }

  Stream<List<Produit>> getAllProductsStream1() {
    return _firestore
        .collection(_collection)
        .where('statut', isEqualTo: 'disponible')
        .orderBy('dateAjout', descending: true)
        .snapshots()
        .map((snapshot) {
          print(
            'Nombre de produits récupérés: ${snapshot.docs.length}',
          ); // Debug
          return snapshot.docs.map((doc) {
            return Produit.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }

  /// Rechercher des produits par nom
  Stream<List<Produit>> searchProductsStream(String query) {
    return _firestore
        .collection(_collection)
        .where('statut', isEqualTo: 'disponible')
        .orderBy('dateAjout', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Produit.fromMap(doc.data(), doc.id))
              .where(
                (product) =>
                    product.nom.toLowerCase().contains(query.toLowerCase()) ||
                    product.description.toLowerCase().contains(
                      query.toLowerCase(),
                    ),
              )
              .toList();
        });
  }

  Stream<List<Produit>> getUserProducts(String userId) {
    return _firestore
        .collection('products')
        .where('vendeurId', isEqualTo: userId)
        .orderBy('dateAjout', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => Produit.fromMap(doc.data(), doc.id))
                  .toList(),
        );
  }

  // Mettre à jour un produit
  Future<void> updateProduct(Produit produit) async {
    await _firestore
        .collection('products')
        .doc(produit.id)
        .update(produit.toMap());
  }

  // Supprimer un produit
  Future<void> deleteProduct(String productId) async {
    try {
      // Supprimer d'abord les images associées au produit
      final imagesQuery =
          await _firestore
              .collection('imagesProduits')
              .where('produitId', isEqualTo: productId)
              .get();

      // Supprimer toutes les images du produit
      for (var doc in imagesQuery.docs) {
        await doc.reference.delete();
      }

      // Supprimer les favoris associés au produit
      final favorisQuery =
          await _firestore
              .collection('favoris')
              .where('produitId', isEqualTo: productId)
              .get();

      for (var doc in favorisQuery.docs) {
        await doc.reference.delete();
      }

      // Enfin, supprimer le produit lui-même
      await _firestore.collection('products').doc(productId).delete();
    } catch (e) {
      print('Erreur lors de la suppression du produit: $e');
      rethrow;
    }
  }

  // Marquer un produit comme vendu
  Future<void> markProductAsSold(String productId) async {
    await _firestore.collection('products').doc(productId).update({
      'statut': 'vendu',
    });
  }

  // Remettre un produit en vente
  Future<void> reactivateProduct(String productId) async {
    await _firestore.collection('products').doc(productId).update({
      'statut': 'disponible',
    });
  }

  // Ajouter un produit
  Future<void> addProduit(Produit produit) async {
    await _firestore
        .collection('products')
        .doc(produit.id)
        .set(produit.toMap());
  }

  // Récupérer un produit
  Future<Produit?> getProduct1(String produitId) async {
    // Renamed from getProduit for consistency
    final doc = await _firestore.collection('products').doc(produitId).get();
    if (doc.exists) {
      return Produit.fromMap(doc.data()!, doc.id);
    }
    return null;
  }

  // Stream pour la liste des produits
  Stream<List<Produit>> getProduits({String? categorieId}) {
    Query query = _firestore.collection('products');
    if (categorieId != null) {
      query = query.where('categorieId', isEqualTo: categorieId);
    }
    return query.snapshots().map(
      (snapshot) =>
          snapshot.docs
              .map(
                (doc) =>
                    Produit.fromMap(doc.data() as Map<String, dynamic>, doc.id),
              )
              .toList(),
    );
  }

  // --- Discussions ---
  // Créer une discussion
  Future<String> createDiscussion(Discussion discussion) async {
    final docRef = await _firestore
        .collection('discussions')
        .add(discussion.toMap());
    return docRef.id;
  }

  // Récupérer les discussions d'un utilisateur (acheteur ou vendeur)
  Stream<List<Discussion>> getDiscussions(String userId) {
    return _firestore
        .collection('discussions')
        .where('acheteurId', isEqualTo: userId)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => Discussion.fromMap(doc.data(), doc.id))
                  .toList(),
        )
        .asyncMap((discussions) async {
          // Ajouter les discussions où l'utilisateur est vendeur
          final vendeurDiscussions =
              await _firestore
                  .collection('discussions')
                  .where('vendeurId', isEqualTo: userId)
                  .get();
          return discussions..addAll(
            vendeurDiscussions.docs.map(
              (doc) => Discussion.fromMap(doc.data(), doc.id),
            ),
          );
        });
  }

  // --- Messages ---
  // Envoyer un message
  Future<void> sendMessage({
    required String discussionId,
    required String senderId,
    required String receiverId,
    required String content,
  }) async {
    final message = {
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'timestamp': FieldValue.serverTimestamp(),
      'read': false,
    };
    await _firestore
        .collection('discussions')
        .doc(discussionId)
        .collection('messages')
        .add(message);

    // Mettre à jour la discussion
    await _firestore.collection('discussions').doc(discussionId).update({
      'lastMessage': content,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Stream pour les messages d'une discussion
  Stream<List<Map<String, dynamic>>> getMessages(String discussionId) {
    return _firestore
        .collection('discussions')
        .doc(discussionId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => {'id': doc.id, ...doc.data()})
                  .toList(),
        );
  }

  // Marquer un message comme lu
  Future<void> markMessageAsRead(String discussionId, String messageId) async {
    await _firestore
        .collection('discussions')
        .doc(discussionId)
        .collection('messages')
        .doc(messageId)
        .update({'read': true});
  }

  // --- Catégories ---
  Stream<List<Categorie>> getCategories() {
    return _firestore
        .collection('categories')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => Categorie.fromMap(doc.data(), doc.id))
                  .toList(),
        );
  }

  // --- Favoris ---
  Future<void> addFavori(Favori favori) async {
    await _firestore.collection('favoris').doc(favori.id).set(favori.toMap());
  }

  String generateNewFavoriId() {
    return _firestore.collection('favoris').doc().id;
  }

  // ✅ Méthode pour supprimer un favori par ID
  Future<void> removeFavori(String userId, String produitId) async {
    final favorisRef = FirebaseFirestore.instance
        .collection('favoris')
        .where('userId', isEqualTo: userId)
        .where('produitId', isEqualTo: produitId);

    final snapshot = await favorisRef.get();
    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  // ✅ Méthode pour ajouter un favori

  // ✅ Méthode pour obtenir les favoris d'un utilisateur
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

  // --- Notifications ---
  Stream<List<NotificationApp>> getNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('dateEnvoi', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => NotificationApp.fromMap(doc.data(), doc.id))
                  .toList(),
        );
  }

  // --- Adresses ---

  Future<Adresse?> getAdresseById(String adresseId) async {
    final doc = await _firestore.collection('adresses').doc(adresseId).get();
    if (doc.exists) {
      return Adresse.fromMap(doc.data()!, doc.id);
    }
    return null;
  }

  // Récupère toutes les adresses d'un utilisateur
  Stream<List<Adresse>> getAdressesStream(String userId) {
    return _firestore
        .collection('adresses')
        .where('idUtilisateur', isEqualTo: userId)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => Adresse.fromMap(doc.data(), doc.id))
                  .toList(),
        );
  }

  // Récupère l'adresse par défaut d'un utilisateur
  Stream<List<Adresse>> getDefaultAdresses(String userId) {
    return _firestore
        .collection('adresses')
        .where('idUtilisateur', isEqualTo: userId)
        .where('isDefaut', isEqualTo: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => Adresse.fromMap(doc.data(), doc.id))
                  .toList(),
        );
  }

  // Récupère toutes les adresses d'un utilisateur (Future)
  Future<List<Adresse>> getAdresses(String userId) async {
    final querySnapshot =
        await _firestore
            .collection('adresses')
            .where('idUtilisateur', isEqualTo: userId)
            .get();
    return querySnapshot.docs
        .map((doc) => Adresse.fromMap(doc.data(), doc.id))
        .toList();
  }

  // Ajoute ou met à jour une adresse
  Future<void> addAdresse(Adresse adresse) async {
    await _firestore
        .collection('adresses')
        .doc(adresse.id)
        .set(adresse.toMap());
  }

  // Met à jour une adresse existante
  Future<void> updateAdresse(Adresse adresse) async {
    await _firestore
        .collection('adresses')
        .doc(adresse.id)
        .update(adresse.toMap());
  }

  // Supprime une adresse
  Future<void> deleteAdresse(String id) async {
    await _firestore.collection('adresses').doc(id).delete();
  }

  // Réinitialise le statut "isDefaut" de toutes les adresses d'un utilisateur
  // sauf celle spécifiée (si newDefaultId n'est pas null)
  Future<void> resetDefaultAddresses(
    String userId, {
    String? newDefaultId,
  }) async {
    final querySnapshot =
        await _firestore
            .collection('adresses')
            .where('idUtilisateur', isEqualTo: userId)
            .where('isDefaut', isEqualTo: true)
            .get();

    for (var doc in querySnapshot.docs) {
      if (doc.id != newDefaultId) {
        // Ne pas réinitialiser si c'est la nouvelle adresse par défaut
        await doc.reference.update({'isDefaut': false});
      }
    }
  }

  // Nouvelle méthode pour créer une adresse par défaut à partir de la position actuelle
  // Elle renvoie true si une adresse a été créée/mise à jour, false sinon.
  Future<bool> createDefaultAddressFromCurrentLocation(String userId) async {
    try {
      // 1. Vérifier si l'utilisateur a déjà une adresse par défaut
      final List<Adresse> existingAddresses = await getAdresses(userId);
      final bool hasDefaultAddress = existingAddresses.any(
        (addr) => addr.isDefaut,
      );

      if (hasDefaultAddress) {
        // L'utilisateur a déjà une adresse par défaut, ne rien faire automatiquement
        return false;
      }

      // 2. Vérifier les services de localisation
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Les services de localisation sont désactivés.');
        return false;
      }

      // 3. Vérifier et demander les permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('Permission de localisation refusée.');
          return false;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        print('Permission de localisation refusée définitivement.');
        return false;
      }

      // 4. Obtenir la position actuelle
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // 5. Effectuer la géocodage inversée
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      String description = 'Position actuelle';
      String? quartier;
      String? ville;

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        quartier = place.subLocality ?? place.locality;
        ville = place.administrativeArea ?? place.country;
        description =
            "${place.street ?? ''}, ${place.subLocality ?? ''}, ${place.locality ?? ''}, ${place.administrativeArea ?? ''}, ${place.country ?? ''}";
        description = description.trim().replaceAll(RegExp(r',\s*$'), '');
        if (description.isEmpty) {
          description = 'Adresse générée automatiquement';
        }
      } else {
        description =
            'Position actuelle (Lat: ${position.latitude.toStringAsFixed(4)}, Lng: ${position.longitude.toStringAsFixed(4)})';
      }

      // 6. Créer la nouvelle adresse par défaut
      final newAddress = Adresse(
        id:
            _firestore
                .collection('adresses')
                .doc()
                .id, // Générer un nouvel ID Firestore
        description: description,
        latitude: position.latitude,
        longitude: position.longitude,
        isDefaut: true, // Marquer comme par défaut
        idUtilisateur: userId,
        quartier: quartier,
        ville: ville,
      );

      // 7. Réinitialiser les autres adresses par défaut et ajouter la nouvelle
      await resetDefaultAddresses(userId, newDefaultId: newAddress.id);
      await addAdresse(newAddress);

      print(
        'Adresse par défaut créée automatiquement pour l\'utilisateur $userId.',
      );
      return true;
    } catch (e) {
      print(
        'Erreur lors de la création automatique de l\'adresse par défaut: $e',
      );
      return false;
    }
  }

  // --- Images de produits ---
  Future<void> addImageProduit(ImageProduit image) async {
    await _firestore
        .collection('imagesProduits')
        .doc(image.id)
        .set(image.toMap());
  }

  //methode pour recuperer une seul image

  Stream<List<ImageProduit>> getImagesProduit(String produitId) {
    return _firestore
        .collection('imagesProduits')
        .where('produitId', isEqualTo: produitId)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => ImageProduit.fromMap(doc.data(), doc.id))
                  .toList(),
        );
  }

  // New method to delete all images for a specific product
  Future<void> deleteImagesForProduct(String productId) async {
    try {
      final imagesQuery =
          await _firestore
              .collection('imagesProduits')
              .where('produitId', isEqualTo: productId)
              .get();

      for (var doc in imagesQuery.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      print('Error deleting images for product $productId: $e');
      rethrow;
    }
  }

  // --- Utilisateurs ---
  Future<Utilisateur?> getUtilisateur(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (doc.exists) {
      return Utilisateur.fromMap(doc.data()!, doc.id);
    }
    return null;
  }
}
