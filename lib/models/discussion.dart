import 'package:cloud_firestore/cloud_firestore.dart';

class Discussion {
  final String id;
  final String produitId;
  final String vendeurId;
  final String acheteurId;
  final DateTime dateCreation;

  Discussion({
    required this.id,
    required this.produitId,
    required this.vendeurId,
    required this.acheteurId,
    required this.dateCreation,
  });

  factory Discussion.fromMap(Map<String, dynamic> map, String id) {
    return Discussion(
      id: id,
      produitId: map['produitId'],
      vendeurId: map['vendeurId'],
      acheteurId: map['acheteurId'],
      dateCreation: (map['dateCreation'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'produitId': produitId,
      'vendeurId': vendeurId,
      'acheteurId': acheteurId,
      'dateCreation': dateCreation,
    };
  }
}
