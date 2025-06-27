// adresse.dart
class Adresse {
  final String id;
  final String description;
  final double latitude;
  final double longitude;
  final bool isDefaut;
  final String idUtilisateur;
  final String? quartier; // Nouveau champ
  final String? ville; // Nouveau champ

  Adresse({
    required this.id,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.isDefaut,
    required this.idUtilisateur,
    this.quartier, // Rendre facultatif si pas toujours disponible
    this.ville, // Rendre facultatif
  });

  factory Adresse.fromMap(Map<String, dynamic> map, String id) {
    return Adresse(
      id: id,
      description: map['description'],
      latitude: map['latitude'].toDouble(),
      longitude: map['longitude'].toDouble(),
      isDefaut: map['isDefaut'],
      idUtilisateur: map['idUtilisateur'],
      quartier: map['quartier'], // Lire depuis la carte
      ville: map['ville'], // Lire depuis la carte
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'isDefaut': isDefaut,
      'idUtilisateur': idUtilisateur,
      'quartier': quartier, // Ajouter à la carte
      'ville': ville, // Ajouter à la carte
    };
  }
}
