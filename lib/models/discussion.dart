import 'package:cloud_firestore/cloud_firestore.dart';

class Discussion {
  final String id;
  final String produitId;
  final String vendeurId;
  final String acheteurId;
  final List<String> participants;
  final DateTime dateCreation;

  // Champs optionnels pour une meilleure gestion
  final String? dernierMessage;
  final DateTime? dateDernierMessage;
  final List<String>? nonLuPar;
  final bool? isActive;

  Discussion({
    required this.id,
    required this.produitId,
    required this.vendeurId,
    required this.acheteurId,
    required this.participants,
    required this.dateCreation,
    this.dernierMessage,
    this.dateDernierMessage,
    this.nonLuPar,
    this.isActive = true,
  });

  factory Discussion.fromMap(Map<String, dynamic> map, String id) {
    return Discussion(
      id: id,
      produitId: map['produitId'] ?? '',
      vendeurId: map['vendeurId'] ?? '',
      acheteurId: map['acheteurId'] ?? '',
      participants: List<String>.from(map['participants'] ?? []),
      dateCreation:
          (map['dateCreation'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dernierMessage: map['dernierMessage'],
      dateDernierMessage: (map['dateDernierMessage'] as Timestamp?)?.toDate(),
      nonLuPar:
          map['nonLuPar'] != null ? List<String>.from(map['nonLuPar']) : null,
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    final Map<String, dynamic> data = {
      'produitId': produitId,
      'vendeurId': vendeurId,
      'acheteurId': acheteurId,
      'participants': participants,
      'dateCreation': Timestamp.fromDate(dateCreation),
      'isActive': isActive,
    };

    // Ajouter les champs optionnels seulement s'ils ne sont pas null
    if (dernierMessage != null) {
      data['dernierMessage'] = dernierMessage;
    }
    if (dateDernierMessage != null) {
      data['dateDernierMessage'] = Timestamp.fromDate(dateDernierMessage!);
    }
    if (nonLuPar != null) {
      data['nonLuPar'] = nonLuPar;
    }

    return data;
  }

  // Méthodes utilitaires
  Discussion copyWith({
    String? id,
    String? produitId,
    String? vendeurId,
    String? acheteurId,
    List<String>? participants,
    DateTime? dateCreation,
    String? dernierMessage,
    DateTime? dateDernierMessage,
    List<String>? nonLuPar,
    bool? isActive,
  }) {
    return Discussion(
      id: id ?? this.id,
      produitId: produitId ?? this.produitId,
      vendeurId: vendeurId ?? this.vendeurId,
      acheteurId: acheteurId ?? this.acheteurId,
      participants: participants ?? this.participants,
      dateCreation: dateCreation ?? this.dateCreation,
      dernierMessage: dernierMessage ?? this.dernierMessage,
      dateDernierMessage: dateDernierMessage ?? this.dateDernierMessage,
      nonLuPar: nonLuPar ?? this.nonLuPar,
      isActive: isActive ?? this.isActive,
    );
  }

  // Vérifier si un utilisateur a des messages non lus
  bool hasUnreadMessages(String userId) {
    return nonLuPar?.contains(userId) ?? false;
  }

  // Obtenir l'autre participant (pas l'utilisateur actuel)
  String getOtherParticipant(String currentUserId) {
    return participants.firstWhere(
      (participant) => participant != currentUserId,
      orElse: () => '',
    );
  }
}
