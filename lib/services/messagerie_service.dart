import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:kassoua/models/message.dart';
import 'package:kassoua/models/discussion.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter/widgets.dart';

class MessagerieService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Obtenir l'utilisateur actuel
  User? get currentUser => _auth.currentUser;

  // --- Discussions ---

  // Créer une discussion
  Future<String> createDiscussion(Discussion discussion) async {
    try {
      // Vérifier si une discussion existe déjà pour ce produit et ces utilisateurs
      final existingDiscussion =
          await _firestore
              .collection('discussions')
              .where('produitId', isEqualTo: discussion.produitId)
              .where('vendeurId', isEqualTo: discussion.vendeurId)
              .where('acheteurId', isEqualTo: discussion.acheteurId)
              .get();

      if (existingDiscussion.docs.isNotEmpty) {
        return existingDiscussion.docs.first.id;
      }

      // Créer une nouvelle discussion
      final docRef = await _firestore
          .collection('discussions')
          .add(discussion.toMap());

      return docRef.id;
    } catch (e) {
      throw Exception('Erreur lors de la création de la discussion: $e');
    }
  }

  // Récupérer les discussions d'un utilisateur avec métadonnées
  Stream<List<Map<String, dynamic>>> getDiscussionsWithMetadata(String userId) {
    return _firestore
        .collection('discussions')
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          List<Map<String, dynamic>> discussionsWithMetadata = [];

          for (var doc in snapshot.docs) {
            final discussion = Discussion.fromMap(doc.data(), doc.id);

            // Obtenir les métadonnées de la dernière conversation
            final unreadCount = await getUnreadCount(doc.id, userId);
            final lastMessage = await getLastMessage(doc.id);

            discussionsWithMetadata.add({
              'discussion': discussion,
              'unreadCount': unreadCount,
              'lastMessage': lastMessage,
            });
          }

          return discussionsWithMetadata;
        });
  }

  // Obtenir le nombre de messages non lus
  Future<int> getUnreadCount(String discussionId, String userId) async {
    try {
      final unreadMessages =
          await _firestore
              .collection('discussions')
              .doc(discussionId)
              .collection('messages')
              .where('receiverId', isEqualTo: userId)
              .where('read', isEqualTo: false)
              .get();

      return unreadMessages.docs.length;
    } catch (e) {
      return 0;
    }
  }

  // Obtenir le dernier message d'une discussion
  Future<Message?> getLastMessage(String discussionId) async {
    try {
      final lastMessageQuery =
          await _firestore
              .collection('discussions')
              .doc(discussionId)
              .collection('messages')
              .orderBy('timestamp', descending: true)
              .limit(1)
              .get();

      if (lastMessageQuery.docs.isNotEmpty) {
        final doc = lastMessageQuery.docs.first;
        return Message.fromMap(doc.data(), doc.id);
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  // --- Messages ---

  // Envoyer un message texte
  Future<void> sendMessage({
    required String discussionId,
    required String senderId,
    required String receiverId,
    required String content,
    MessageType type = MessageType.text,
    String? imageUrl,
    String? audioUrl,
  }) async {
    try {
      final message = Message(
        id: '',
        senderId: senderId,
        receiverId: receiverId,
        content: content,
        timestamp: DateTime.now(),
        read: false,
        type: type,
        imageUrl: imageUrl,
        audioUrl: audioUrl,
      );

      // Ajouter le message à la sous-collection
      await _firestore
          .collection('discussions')
          .doc(discussionId)
          .collection('messages')
          .add(message.toMap());

      // Mettre à jour les métadonnées de la discussion
      await _firestore.collection('discussions').doc(discussionId).update({
        'lastMessage': content,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastSenderId': senderId,
      });
    } catch (e) {
      throw Exception('Erreur lors de l\'envoi du message: $e');
    }
  }

  // Stream pour les messages d'une discussion
  Stream<List<Message>> getMessages(String discussionId) {
    return _firestore
        .collection('discussions')
        .doc(discussionId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => Message.fromMap(doc.data(), doc.id))
                  .toList(),
        );
  }

  // Marquer les messages comme lus
  Future<void> markMessagesAsRead(String discussionId, String userId) async {
    try {
      final unreadMessages =
          await _firestore
              .collection('discussions')
              .doc(discussionId)
              .collection('messages')
              .where('receiverId', isEqualTo: userId)
              .where('read', isEqualTo: false)
              .get();

      final batch = _firestore.batch();

      for (var doc in unreadMessages.docs) {
        batch.update(doc.reference, {'read': true});
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Erreur lors du marquage des messages comme lus: $e');
    }
  }

  // --- Gestion des fichiers ---

  // Envoyer une image
  Future<void> sendImageMessage({
    required String discussionId,
    required String senderId,
    required String receiverId,
    required File imageFile,
    String? caption,
  }) async {
    try {
      // Upload de l'image sur Cloudinary
      final cloudinary = CloudinaryPublic(
        'TON_CLOUD_NAME', // Remplace par ton cloud name Cloudinary
        'TON_UPLOAD_PRESET', // Remplace par ton upload preset Cloudinary
        cache: false,
      );
      final uploadResult = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          imageFile.path,
          resourceType: CloudinaryResourceType.Image,
        ),
      );
      final String imageUrl = uploadResult.secureUrl;

      // Envoyer le message avec l'URL de l'image Cloudinary
      await sendMessage(
        discussionId: discussionId,
        senderId: senderId,
        receiverId: receiverId,
        content: caption ?? 'Image',
        type: MessageType.image,
        imageUrl: imageUrl,
      );
    } catch (e) {
      throw Exception('Erreur lors de l\'envoi de l\'image: $e');
    }
  }

  // Sélectionner et envoyer une image
  Future<void> pickAndSendImage({
    required String discussionId,
    required String senderId,
    required String receiverId,
    required ImageSource source,
  }) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: source);

      if (image != null) {
        final File imageFile = File(image.path);
        await sendImageMessage(
          discussionId: discussionId,
          senderId: senderId,
          receiverId: receiverId,
          imageFile: imageFile,
        );
      }
    } catch (e) {
      throw Exception('Erreur lors de la sélection de l\'image: $e');
    }
  }

  // Supprimer un message
  Future<void> deleteMessage(String discussionId, String messageId) async {
    try {
      await _firestore
          .collection('discussions')
          .doc(discussionId)
          .collection('messages')
          .doc(messageId)
          .delete();
    } catch (e) {
      throw Exception('Erreur lors de la suppression du message: $e');
    }
  }

  // Obtenir les statuts en ligne (à implémenter avec presence)
  Stream<bool> getUserOnlineStatus(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) => doc.data()?['isOnline'] ?? false);
  }

  // Mettre à jour le statut en ligne
  Future<void> updateOnlineStatus(bool isOnline) async {
    if (currentUser != null) {
      await _firestore.collection('users').doc(currentUser!.uid).update({
        'isOnline': isOnline,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    }
  }

  // Écouter les changements de statut de l'application
  void handleAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        updateOnlineStatus(true);
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        updateOnlineStatus(false);
        break;
      default:
        break;
    }
  }
}
