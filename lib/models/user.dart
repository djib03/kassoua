import 'package:cloud_firestore/cloud_firestore.dart';

class Utilisateur {
  final String id;
  final String nom;
  final String prenom;
  final String email;
  final String telephone;
  final String? photoProfil;
  final DateTime dateInscription;
  final DateTime? dateNaissance;
  final String? genre;

  Utilisateur({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.telephone,
    this.photoProfil,
    required this.dateInscription,
    this.dateNaissance,
    this.genre,
  });

  factory Utilisateur.fromMap(Map<String, dynamic> map, String id) {
    return Utilisateur(
      id: id,
      nom: map['nom'],
      prenom: map['prenom'],
      email: map['email'],
      telephone: map['telephone'],
      photoProfil: map['photoProfil'],
      dateInscription: (map['dateInscription'] as Timestamp).toDate(),
      dateNaissance: (map['dateNaissance'] as Timestamp).toDate(),
      genre: map['genre'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'telephone': telephone,
      'photoProfil': photoProfil,
      'dateInscription': dateInscription,
      'dateNaissance': dateNaissance,
      'genre': genre,
    };
  }
}
