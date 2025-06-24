class Adresse {
  final String id;
  final String description;
  final double latitude;
  final double longitude;
  final bool parDefaut;

  Adresse({
    required this.id,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.parDefaut,
  });

  factory Adresse.fromMap(Map<String, dynamic> map, String id) {
    return Adresse(
      id: id,
      description: map['description'],
      latitude: map['latitude'].toDouble(),
      longitude: map['longitude'].toDouble(),
      parDefaut: map['parDefaut'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'parDefaut': parDefaut,
    };
  }
}
