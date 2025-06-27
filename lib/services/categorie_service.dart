import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:kassoua/models/categorie.dart';
import 'package:kassoua/constants/colors.dart';

class CategoryService {
  static final CategoryService _instance = CategoryService._internal();
  factory CategoryService() => _instance;
  CategoryService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'categories';

  /// Ajouter une nouvelle catégorie
  Future<String> addCategory(Categorie category) async {
    try {
      DocumentReference docRef = await _firestore
          .collection(_collection)
          .add(category.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Erreur lors de l\'ajout de la catégorie: $e');
    }
  }

  /// Récupérer toutes les catégories sous forme de Stream
  Stream<List<Categorie>> getCategoriesStream() {
    return _firestore.collection(_collection).orderBy('nom').snapshots().map((
      snapshot,
    ) {
      return snapshot.docs.map((doc) {
        return Categorie.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  /// Récupérer toutes les catégories principales
  Stream<List<Categorie>> getParentCategoriesStream() {
    return _firestore
        .collection(_collection)
        .where('parentId', isNull: true)
        .where('isActive', isEqualTo: true)
        .orderBy('ordre')
        .snapshots()
        .map((snapshot) {
          print(
            'Nombre de catégories principales trouvées : ${snapshot.docs.length}',
          );
          snapshot.docs.forEach((doc) {
            print('Document : ${doc.id} - Données : ${doc.data()}');
          });
          return snapshot.docs
              .map((doc) => Categorie.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  /// Récupérer les sous-catégories d'une catégorie
  Stream<List<Categorie>> getSubCategoriesStream(String parentId) {
    return _firestore
        .collection(_collection)
        .where('parentId', isEqualTo: parentId)
        .where('isActive', isEqualTo: true)
        .orderBy('ordre')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => Categorie.fromMap(doc.data(), doc.id))
                  .toList(),
        );
  }

  /// Récupérer la hiérarchie complète
  Future<List<CategoryHierarchy>> getCategoryHierarchy() async {
    try {
      final parents = await getParentCategoriesStream().first;
      final List<CategoryHierarchy> hierarchy = [];

      for (final parent in parents) {
        final subCategories = await getSubCategoriesStream(parent.id).first;
        hierarchy.add(
          CategoryHierarchy(parent: parent, subCategories: subCategories),
        );
      }

      return hierarchy;
    } catch (e) {
      throw Exception('Erreur lors de la récupération de la hiérarchie: $e');
    }
  }

  /// Récupérer toutes les catégories (une seule fois)
  Future<List<Categorie>> getCategories() async {
    try {
      QuerySnapshot snapshot =
          await _firestore.collection(_collection).orderBy('nom').get();

      return snapshot.docs.map((doc) {
        return Categorie.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des catégories: $e');
    }
  }

  /// Initialiser les catégories par défaut (à exécuter une seule fois)
  Future<void> initializeDefaultCategories() async {
    try {
      // Vérifier si des catégories existent déjà
      bool exist = await categoriesExist();
      if (exist) {
        print('Les catégories existent déjà dans Firestore');
        return;
      }

      // Liste des catégories principales
      List<Map<String, dynamic>> defaultCategories = [
        {
          'nom': 'Électronique',
          'icone': 'fa_solid_headphones',
          'ordre': 1,
          'subCategories': [
            {
              'nom': 'téléphone et tablette',
              'icone': 'fa_solid_mobile',
              'ordre': 1,
            },
            {'nom': 'Ordinateurs', 'icone': 'fa_solid_laptop', 'ordre': 2},
            {
              'nom': 'Accessoires et peripherique',
              'icone': 'fa_solid_keyboard',
              'ordre': 3,
            },
            {'nom': 'Télévisions', 'icone': 'fa_solid_tv', 'ordre': 4},
            {'nom': 'Audio', 'icone': 'fa_solid_headphones', 'ordre': 5},
            {'nom': 'Jeux vidéo', 'icone': 'fa_solid_scooter', 'ordre': 6},
            {'nom': 'Tablettes', 'icone': 'fa_solid_tablet', 'ordre': 7},
          ],
        },
        {
          'nom': 'Mode',
          'icone': 'fa_solid_shirt',
          'ordre': 2,
          'subCategories': [
            {'nom': 'Vêtements Homme', 'icone': 'fa_solid_tshirt', 'ordre': 1},
            {'nom': 'Vêtements Femme', 'icone': 'fa_solid_dress', 'ordre': 2},
            {'nom': 'Chaussures', 'icone': 'fa_solid_shoe_prints', 'ordre': 3},
            {'nom': 'Accessoires', 'icone': 'fa_solid_hat_cowboy', 'ordre': 4},
            {'nom': 'Vêtements Enfant', 'icone': 'fa_solid_ring', 'ordre': 5},
          ],
        },
        {
          'nom': 'Maison et Jardin',
          'icone': 'fa_solid_house',
          'ordre': 3,
          'subCategories': [
            {'nom': 'Décoration', 'icone': 'fa_solid_paint_roller', 'ordre': 1},
            {'nom': 'Cuisine', 'icone': 'fa_solid_utensils', 'ordre': 2},
            {'nom': 'Électroménager', 'icone': 'fa_solid_blender', 'ordre': 3},
          ],
        },
        {
          'nom': 'Beauté et Santé',
          'icone': 'fa_solid_spa',
          'ordre': 4,
          'subCategories': [
            {'nom': 'Maquillage', 'icone': 'fa_solid_eye_dropper', 'ordre': 1},
            {
              'nom': 'Soins capillaires',
              'icone': 'fa_solid_scissors',
              'ordre': 2,
            },
            {'nom': 'Parfums', 'icone': 'fa_solid_spray_can', 'ordre': 3},
          ],
        },
        {
          'nom': 'Livres et Papeterie',
          'icone': 'fa_solid_book',
          'ordre': 5,
          'subCategories': [
            {'nom': 'Romans', 'icone': 'fa_solid_book_open', 'ordre': 1},
            {
              'nom': 'Manuels scolaires',
              'icone': 'fa_solid_book_medical',
              'ordre': 2,
            },
            {
              'nom': 'Fournitures de bureau',
              'icone': 'fa_solid_pen',
              'ordre': 3,
            },
          ],
        },
        {
          'nom': 'Sports et Loisirs',
          'icone': 'fa_solid_dumbbell',
          'ordre': 6,
          'subCategories': [
            {
              'nom': 'Équipements de sport',
              'icone': 'fa_solid_football',
              'ordre': 1,
            },
            {'nom': 'Camping', 'icone': 'fa_solid_tent', 'ordre': 2},
            {'nom': 'Vélos', 'icone': 'fa_solid_bicycle', 'ordre': 3},
          ],
        },
        {
          'nom': 'Alimentation et Épicerie',
          'icone': 'fa_solid_shopping_cart',
          'ordre': 7,
          'subCategories': [
            {
              'nom': 'Produits frais',
              'icone': 'fa_solid_apple_alt',
              'ordre': 1,
            },
            {'nom': 'Conserves', 'icone': 'fa_solid_can_food', 'ordre': 2},
            {'nom': 'Boissons', 'icone': 'fa_solid_bottle_water', 'ordre': 3},
          ],
        },

        {
          'nom': 'Bricolage et Quincaillerie',
          'icone': 'fa_solid_hammer',
          'ordre': 9,
          'subCategories': [
            {
              'nom': 'Outils électriques',
              'icone': 'fa_solid_screwdriver_wrench',
              'ordre': 1,
            },
            {'nom': 'Outils manuels', 'icone': 'fa_solid_wrench', 'ordre': 2},
            {'nom': 'Matériaux', 'icone': 'fa_solid_bricks', 'ordre': 3},
          ],
        },
        {
          'nom': 'Ameublement',
          'icone': 'fa_solid_couch',
          'ordre': 10,
          'subCategories': [
            {'nom': 'Salon', 'icone': 'fa_solid_couch', 'ordre': 1},
            {'nom': 'Chambre', 'icone': 'fa_solid_bed', 'ordre': 2},
            {'nom': 'Salle à manger', 'icone': 'fa_solid_chair', 'ordre': 3},
          ],
        },
        {
          'nom': 'Auto et Moto',
          'icone': 'fa_solid_car',
          'ordre': 11,
          'subCategories': [
            {
              'nom': 'Accessoires auto',
              'icone': 'fa_solid_car_battery',
              'ordre': 1,
            },
            {'nom': 'Pièces détachées', 'icone': 'fa_solid_gears', 'ordre': 2},
            {'nom': 'Motos', 'icone': 'fa_solid_motorcycle', 'ordre': 3},
            {'nom': 'Voiture', 'icone': 'fa_solid_scooter', 'ordre': 4},
          ],
        },
      ];

      // Ajouter les catégories principales et leurs sous-catégories
      for (var categoryData in defaultCategories) {
        // Ajouter la catégorie principale
        Categorie parentCategory = Categorie(
          id: '',
          nom: categoryData['nom'],
          icone: categoryData['icone'],
          ordre: categoryData['ordre'],
          isActive: true,
          createdAt: DateTime.now(),
        );

        // Ajouter la catégorie principale à Firestore et récupérer son ID
        String parentId = await addCategory(parentCategory);

        // Ajouter les sous-catégories
        for (var subCategoryData in categoryData['subCategories']) {
          Categorie subCategory = Categorie(
            id: '',
            nom: subCategoryData['nom'],
            icone: subCategoryData['icone'],
            parentId: parentId,
            ordre: subCategoryData['ordre'],
            isActive: true,
            createdAt: DateTime.now(),
          );
          await addCategory(subCategory);
        }
      }

      print(
        'Catégories et sous-catégories par défaut initialisées avec succès',
      );
    } catch (e) {
      throw Exception('Erreur lors de l\'initialisation des catégories: $e');
    }
  }

  /// Mettre à jour une catégorie existante
  Future<void> updateCategory(String id, Categorie category) async {
    try {
      await _firestore.collection(_collection).doc(id).update(category.toMap());
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour de la catégorie: $e');
    }
  }

  /// Vérifier si des catégories existent déjà
  Future<bool> categoriesExist() async {
    try {
      QuerySnapshot snapshot =
          await _firestore.collection(_collection).limit(1).get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}

class IconUtils {
  static final Map<String, IconData> _iconMap = {
    // Electronique
    'fa_solid_headphones': FontAwesomeIcons.headphones,

    // Mode et Habillement
    'fa_solid_shirt': FontAwesomeIcons.shirt,

    // Maison
    'fa_solid_house': FontAwesomeIcons.house,

    // Beauté et Santé
    'fa_solid_spa': FontAwesomeIcons.spa,

    // Livres et Papeterie
    'fa_solid_book': FontAwesomeIcons.book,

    // Sports et Loisirs
    'fa_solid_dumbbell': FontAwesomeIcons.dumbbell,

    // Alimentation et Épicerie
    'fa_solid_shopping_cart': FontAwesomeIcons.cartShopping,

    // Jeux Vidéo
    'fa_solid_gamepad': FontAwesomeIcons.gamepad,

    // Bricolage et Quincaillerie
    'fa_solid_hammer': FontAwesomeIcons.hammer,

    // Ameublement
    'fa_solid_couch': FontAwesomeIcons.couch,

    // Auto et Moto
    'fa_solid_car': FontAwesomeIcons.car,
  };

  /// Obtenir une icône à partir de son nom
  static IconData? getIconFromName(String iconName) {
    return _iconMap[iconName];
  }

  /// Obtenir le nom d'une icône à partir de l'IconData
  static String? getNameFromIcon(IconData icon) {
    for (String key in _iconMap.keys) {
      if (_iconMap[key] == icon) {
        return key;
      }
    }
    return null;
  }

  /// Obtenir toutes les icônes disponibles
  static Map<String, IconData> getAllIcons() {
    return Map.from(_iconMap);
  }

  /// Widget helper pour afficher une icône personnalisée
  static Widget buildCustomIcon(
    String iconName, {
    double size = 24.0,
    Color color = DMColors.primary,
    Color? backgroundColor,
    double? backgroundRadius,
    EdgeInsets? padding,
  }) {
    IconData? iconData = getIconFromName(iconName);

    iconData ??= FontAwesomeIcons.tags;

    Widget iconWidget = FaIcon(iconData, size: size, color: color);

    if (backgroundColor != null || padding != null) {
      iconWidget = Container(
        padding: padding ?? EdgeInsets.all(8.0),
        decoration:
            backgroundColor != null
                ? BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(
                    backgroundRadius ?? size * 0.5,
                  ),
                )
                : null,
        child: iconWidget,
      );
    }

    return iconWidget;
  }
}
