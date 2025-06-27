import 'package:cloud_firestore/cloud_firestore.dart';

class Produit {
  final String id;
  final String nom;
  final String description;
  final double prix;
  final String etat; // Ajout du champ état (neuf, occasion, etc.)
  final String statut;
  // final int quantite; // Removed from here if not directly managed by user
  final DateTime dateAjout;
  final String vendeurId;
  final String categorieId;
  final String adresseId;
  final String? imageUrl; // Image principale (optionnelle pour compatibilité)

  Produit({
    required this.id,
    required this.nom,
    required this.description,
    required this.prix,
    required this.etat,
    required this.statut,
    // required this.quantite, // Removed from constructor
    required this.dateAjout,
    required this.vendeurId,
    required this.categorieId,
    required this.adresseId,
    this.imageUrl,
  });

  factory Produit.fromMap(Map<String, dynamic> map, String id) {
    return Produit(
      id: id,
      nom: map['nom'] ?? '',
      description: map['description'] ?? '',
      prix: (map['prix'] ?? 0).toDouble(),
      etat: map['etat'] ?? 'occasion', // Valeur par défaut
      statut: map['statut'] ?? 'actif',
      // quantite: map['quantite'] ?? 1, // Default to 1 if not explicitly set
      dateAjout:
          map['dateAjout'] != null
              ? (map['dateAjout'] as Timestamp).toDate()
              : DateTime.now(),
      vendeurId: map['vendeurId'] ?? '',
      categorieId: map['categorieId'] ?? '',
      adresseId: map['adresseId'] ?? '',
      imageUrl: map['imageUrl'], // Peut être null
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nom': nom,
      'description': description,
      'prix': prix,
      'etat': etat,
      'statut': statut,
      // 'quantite': 1, // Always set to 1 for marketplace announcement
      'dateAjout': dateAjout,
      'vendeurId': vendeurId,
      'categorieId': categorieId,
      'adresseId': adresseId,
      'imageUrl': imageUrl,
    };
  }

  // If quantite is always 1, then isVendu depends on 'statut'
  bool get isVendu => statut == 'vendu';

  // Méthode pour obtenir le texte de l'état
  String get etatText {
    switch (etat.toLowerCase()) {
      case 'neuf':
        return 'Neuf';
      case 'occasion':
        return 'Occasion';
      case 'tres_bon_etat':
        return 'Très bon état';
      case 'bon_etat':
        return 'Bon état';
      case 'etat_correct':
        return 'État correct';
      default:
        return 'Occasion';
    }
  }

  // Copie avec modifications
  Produit copyWith({
    String? id,
    String? nom,
    String? description,
    double? prix,
    String? etat,
    String? statut,
    // int? quantite, // Removed from copyWith
    DateTime? dateAjout,
    String? vendeurId,
    String? categorieId,
    String? adresseId,
    String? imageUrl,
  }) {
    return Produit(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      description: description ?? this.description,
      prix: prix ?? this.prix,
      etat: etat ?? this.etat,
      statut: statut ?? this.statut,
      // quantite: quantite ?? this.quantite, // Removed from copyWith
      dateAjout: dateAjout ?? this.dateAjout,
      vendeurId: vendeurId ?? this.vendeurId,
      categorieId: categorieId ?? this.categorieId,
      adresseId: adresseId ?? this.adresseId,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}
