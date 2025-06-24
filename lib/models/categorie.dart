class Categorie {
  final String id;
  final String nom;
  final String icone;

  Categorie({required this.id, required this.nom, required this.icone});

  factory Categorie.fromMap(Map<String, dynamic> map, String id) {
    return Categorie(id: id, nom: map['nom'], icone: map['icone']);
  }

  Map<String, dynamic> toMap() {
    return {'nom': nom, 'icone': icone};
  }
}
