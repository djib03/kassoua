import 'package:cloud_firestore/cloud_firestore.dart';

class Favori {
  final String id;
  final String userId;
  final String produitId;
  final DateTime dateAjout;

  Favori({
    required this.id,
    required this.userId,
    required this.produitId,
    required this.dateAjout,
  });

  factory Favori.fromMap(Map<String, dynamic> map, String id) {
    return Favori(
      id: id,
      userId: map['userId'],
      produitId: map['produitId'],
      dateAjout: (map['dateAjout'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {'userId': userId, 'produitId': produitId, 'dateAjout': dateAjout};
  }
}
