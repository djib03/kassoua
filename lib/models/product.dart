import 'package:cloud_firestore/cloud_firestore.dart';

class Produit {
  final String id;
  final String nom;
  final String description;
  final double prix;
  // final String etat;
  final String statut;
  final DateTime dateAjout;
  final String vendeurId;
  final String categorieId;
  final String adresseId;

  Produit({
    required this.id,
    required this.nom,
    required this.description,
    required this.prix,
    required this.statut,
    required this.dateAjout,
    required this.vendeurId,
    required this.categorieId,
    required this.adresseId,
  });

  factory Produit.fromMap(Map<String, dynamic> map, String id) {
    return Produit(
      id: id,
      nom: map['nom'],
      description: map['description'],
      prix: map['prix'].toDouble(),
      statut: map['statut'],
      dateAjout: (map['dateAjout'] as Timestamp).toDate(),
      vendeurId: map['vendeurId'],
      categorieId: map['categorieId'],
      adresseId: map['adresseId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nom': nom,
      'description': description,
      'prix': prix,
      'statut': statut,
      'dateAjout': dateAjout,
      'vendeurId': vendeurId,
      'categorieId': categorieId,
      'adresseId': adresseId,
    };
  }
}
