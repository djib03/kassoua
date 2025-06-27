// Modèle Categorie modifié
import 'package:cloud_firestore/cloud_firestore.dart'; // Import for Timestamp

class Categorie {
  final String id;
  final String nom;
  final String icone;
  final String? parentId; // null = catégorie principale
  final int ordre;
  final bool isActive;
  final DateTime createdAt;

  Categorie({
    required this.id,
    required this.nom,
    required this.icone,
    this.parentId,
    required this.ordre,
    required this.isActive,
    required this.createdAt,
  });

  factory Categorie.fromMap(Map<String, dynamic> map, String id) {
    return Categorie(
      id: id,
      nom: map['nom'] ?? '',
      icone: map['icone'] ?? '',
      parentId: map['parentId'],
      ordre: map['ordre'] ?? 0,
      isActive: map['isActive'] ?? true,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nom': nom,
      'icone': icone,
      'parentId': parentId,
      'ordre': ordre,
      'isActive': isActive,
      'createdAt': createdAt,
    };
  }

  // Propriétés calculées
  bool get isParentCategory => parentId == null;
  bool get isSubCategory => parentId != null;
}

// Nouveau modèle pour la hiérarchie
class CategoryHierarchy {
  final Categorie parent;
  final List<Categorie> subCategories;

  CategoryHierarchy({required this.parent, required this.subCategories});
}
