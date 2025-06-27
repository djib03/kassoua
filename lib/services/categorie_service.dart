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

  /// Initialiser les catégories par défaut (à exécuter une seule fois)
  Future<void> initializeDefaultCategories() async {
    try {
      // Vérifier si des catégories existent déjà
      bool exist = await categoriesExist();
      if (exist) {
        print('Les catégories existent déjà dans Firestore');
        return;
      }

      List<Categorie> defaultCategories = [
        Categorie(id: '', nom: 'Mode et Habillement', icone: 'fa_solid_shirt'),
        Categorie(id: '', nom: 'Maison', icone: 'fa_solid_house'),
        Categorie(id: '', nom: 'Beauté et Santé', icone: 'fa_solid_spa'),
        Categorie(id: '', nom: 'Livres et Papeterie', icone: 'fa_solid_book'),
        Categorie(id: '', nom: 'Sports et Loisirs', icone: 'fa_solid_dumbbell'),
        Categorie(
          id: '',
          nom: 'Alimentation et Épicerie',
          icone: 'fa_solid_shopping_cart',
        ),
        Categorie(id: '', nom: 'Jeux Vidéo', icone: 'fa_solid_gamepad'),
        Categorie(
          id: '',
          nom: 'Bricolage et Quincaillerie',
          icone: 'fa_solid_hammer',
        ),
        Categorie(id: '', nom: 'Ameublement', icone: 'fa_solid_couch'),
        Categorie(id: '', nom: 'Auto et Moto', icone: 'fa_solid_car'),
      ];

      // Ajouter toutes les catégories par défaut
      for (Categorie category in defaultCategories) {
        await addCategory(category);
      }

      print('Catégories par défaut initialisées avec succès');
    } catch (e) {
      throw Exception('Erreur lors de l\'initialisation des catégories: $e');
    }
  }
}

class IconUtils {
  static final Map<String, IconData> _iconMap = {
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
    Color? color,
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

  /// Widget pour sélectionner une icône
  static Widget buildIconPicker({
    required String? selectedIconName,
    required Function(String) onIconSelected,
    double iconSize = 30.0,
    Color? iconColor,
    int crossAxisCount = 4,
  }) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 1,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _iconMap.length,
      itemBuilder: (context, index) {
        String iconName = _iconMap.keys.elementAt(index);
        bool isSelected = selectedIconName == iconName;

        return GestureDetector(
          onTap: () => onIconSelected(iconName),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color:
                    isSelected
                        ? DMColors.primary
                        : Colors.grey.withOpacity(0.3),
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(8),
              color: isSelected ? DMColors.primary.withOpacity(0.1) : null,
            ),
            child: Center(
              child: buildCustomIcon(
                iconName,
                size: iconSize,
                color:
                    iconColor ??
                    (isSelected ? DMColors.primary : Colors.grey[600]),
              ),
            ),
          ),
        );
      },
    );
  }
}
