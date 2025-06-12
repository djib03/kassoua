import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart'; // Pour les icônes
import 'package:kassoua/data/home_data.dart';
import 'package:kassoua/constants/colors.dart'; // Pour les couleurs

// Le modèle Product n'est plus strictement nécessaire ici si HomeData.products est bien structuré,
// mais je le laisse au cas où tu en aurais besoin ailleurs pour la clarté des données.
class Product {
  final String id;
  final String name;
  final String imageUrl;
  final double price;
  bool isFavorite;

  Product({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.price,
    this.isFavorite = false,
  });

  Product copyWith({
    String? id,
    String? name,
    String? imageUrl,
    double? price,
    bool? isFavorite,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      price: price ?? this.price,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}

class FavoriteProductsScreen extends StatefulWidget {
  // Nous passons maintenant le Set des IDs des favoris
  final Set<String> favoriteProductIds;
  // Et la fonction pour gérer l'ajout/retrait
  final void Function(String productId) onToggleFavorite;

  const FavoriteProductsScreen({
    Key? key,
    required this.favoriteProductIds,
    required this.onToggleFavorite,
  }) : super(key: key);

  @override
  State<FavoriteProductsScreen> createState() => _FavoriteProductsScreenState();
}

class _FavoriteProductsScreenState extends State<FavoriteProductsScreen> {
  // Nous n'avons plus besoin de _favoriteProducts ici car nous recevons les IDs
  // List<Product> _favoriteProducts = [...]; // Ancien

  // Cette liste sera construite dynamiquement à partir de favoriteProductIds
  List<Map<String, dynamic>> _currentFavoriteProducts = [];

  @override
  void initState() {
    super.initState();
    _loadCurrentFavorites();
  }

  // Si les favoris peuvent changer en arrière-plan, utiliser didUpdateWidget
  @override
  void didUpdateWidget(covariant FavoriteProductsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.favoriteProductIds != oldWidget.favoriteProductIds) {
      _loadCurrentFavorites();
    }
  }

  void _loadCurrentFavorites() {
    // Filtrer HomeData.products pour obtenir les produits qui sont dans favoriteProductIds
    _currentFavoriteProducts =
        HomeData.products
            .where(
              (product) => widget.favoriteProductIds.contains(product['id']),
            )
            .toList();
    // Sortir de setState si _currentFavoriteProducts est déjà à jour
    // (pourrait être optimisé si nécessaire, mais suffisant pour l'instant)
    setState(() {});
  }

  // La fonction de retrait appellera la fonction passée en paramètre
  void _removeFavorite(String productId) {
    widget.onToggleFavorite(productId); // Appelle la fonction de la HomePage
    // Recharger la liste locale après la modification
    _loadCurrentFavorites();
  }

  @override
  Widget build(BuildContext context) {
    final Brightness brightness = Theme.of(context).brightness;
    final Color backgroundColor =
        brightness == Brightness.dark
            ? Theme.of(context).colorScheme.surface
            : Colors.white;
    final Color textColor =
        brightness == Brightness.dark ? Colors.white : Colors.black;
    final Color secondaryTextColor =
        brightness == Brightness.dark ? Colors.white70 : Colors.grey[600]!;
    final Color cardColor =
        brightness == Brightness.dark ? Colors.grey[900]! : Colors.white;
    final Color shadowColor =
        brightness == Brightness.dark
            ? Colors.transparent
            : Colors.grey.withOpacity(0.2);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text('Mes Favoris', style: TextStyle(color: textColor)),
        backgroundColor: backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body:
          _currentFavoriteProducts
                  .isEmpty // Utilise la liste filtrée
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Iconsax.heart_slash, // Icône pour les favoris vides
                      size: 80,
                      color: secondaryTextColor,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Aucun produit favori pour le moment.',
                      style: TextStyle(fontSize: 18, color: secondaryTextColor),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () {
                        // Optionnel: Naviguer vers la page d'accueil ou de recherche
                        Navigator.pop(
                          context,
                        ); // Revenir à la page précédente (HomePage)
                      },
                      icon: const Icon(Iconsax.shop, color: Colors.white),
                      label: const Text(
                        'Découvrir des produits',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DMColors.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              )
              : GridView.builder(
                padding: const EdgeInsets.all(16.0),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // 2 colonnes
                  crossAxisSpacing: 16.0,
                  mainAxisSpacing: 16.0,
                  childAspectRatio:
                      0.7, // Ajuste pour que les cartes aient une bonne proportion
                ),
                itemCount: _currentFavoriteProducts.length,
                itemBuilder: (context, index) {
                  final product = _currentFavoriteProducts[index];
                  return Card(
                    color: cardColor,
                    elevation: 5,
                    shadowColor: shadowColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                            // Assurez-vous que l'URL d'image du produit est valide ou utilisez un placeholder
                            child:
                                product['imageUrl'] != null &&
                                        product['imageUrl'].isNotEmpty
                                    ? Image.asset(
                                      product['imageUrl'],
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      errorBuilder: (
                                        context,
                                        error,
                                        stackTrace,
                                      ) {
                                        return Center(
                                          child: Icon(
                                            Iconsax.image,
                                            color: secondaryTextColor,
                                            size: 40,
                                          ),
                                        );
                                      },
                                    )
                                    : Center(
                                      // Placeholder si pas d'image
                                      child: Icon(
                                        Iconsax.image,
                                        color: secondaryTextColor,
                                        size: 40,
                                      ),
                                    ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product['name'],
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: textColor,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${product['price'].toStringAsFixed(2)} FCFA', // Formatage du prix
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: DMColors.primary, // Couleur du prix
                                ),
                              ),
                            ],
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: IconButton(
                            icon: Icon(
                              Iconsax.heart_slash,
                              color: Colors.red,
                            ), // Icône pour retirer des favoris
                            onPressed: () => _removeFavorite(product['id']),
                            tooltip: 'Retirer des favoris',
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
    );
  }
}
