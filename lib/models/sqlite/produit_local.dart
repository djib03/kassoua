class ProduitLocal {
  final String id;
  final String nom;
  final String description;
  final double prix;
  final String statut;
  final String dateAjout;
  final String vendeurId;
  final String categorieId;
  final String adresseId;
  final bool isSynced;
  final String lastUpdated;

  ProduitLocal({
    required this.id,
    required this.nom,
    required this.description,
    required this.prix,
    required this.statut,
    required this.dateAjout,
    required this.vendeurId,
    required this.categorieId,
    required this.adresseId,
    required this.isSynced,
    required this.lastUpdated,
  });

  factory ProduitLocal.fromMap(Map<String, dynamic> map) {
    return ProduitLocal(
      id: map['id'],
      nom: map['nom'],
      description: map['description'],
      prix: map['prix'],
      statut: map['statut'],
      dateAjout: map['dateAjout'],
      vendeurId: map['vendeurId'],
      categorieId: map['categorieId'],
      adresseId: map['adresseId'],
      isSynced: map['isSynced'] == 1,
      lastUpdated: map['lastUpdated'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'description': description,
      'prix': prix,
      'statut': statut,
      'dateAjout': dateAjout,
      'vendeurId': vendeurId,
      'categorieId': categorieId,
      'adresseId': adresseId,
      'isSynced': isSynced ? 1 : 0,
      'lastUpdated': lastUpdated,
    };
  }
}
