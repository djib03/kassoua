import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kassoua/constants/colors.dart';
import 'package:kassoua/views/widgets/product_card.dart';
import 'package:kassoua/services/firestore_service.dart';
import 'package:kassoua/models/product.dart';
import 'package:kassoua/models/favori.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:intl/intl.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();

  String _sortBy = "Recent";
  String _searchQuery = '';
  bool _isLoading = false;

  List<Produit> _allProducts = [];
  List<Produit> _filteredProducts = [];
  List<String> _favoriteProductIds = [];
  final Map<String, String> _productImages = {};
  final Map<String, String> _productLocations = {};

  // Formateur de prix pour la lisibilité
  final NumberFormat _priceFormatter = NumberFormat('#,###', 'fr_FR');

  final sortOptions = [
    "Recent",
    "Prix: décroissant",
    "Prix: croissant",
    "Plus vus",
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _loadFavorites();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Utilisation de getAllProductsStream() au lieu de getAllProductsStream1()
      // pour récupérer TOUS les produits sans limitation
      _firestoreService.getAllProductsStream().listen((products) async {
        _allProducts = products;
        await _loadProductImages();
        await _loadProductLocations();
        _applyFilters();
        setState(() {
          _isLoading = false;
        });
      });
    } catch (e) {
      print('Erreur lors du chargement des produits: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadProductImages() async {
    for (var product in _allProducts) {
      try {
        final images =
            await _firestoreService.getImagesProduit(product.id).first;
        if (images.isNotEmpty) {
          _productImages[product.id] = images.first.url;
        }
      } catch (e) {
        print('Erreur lors du chargement de l\'image pour ${product.id}: $e');
      }
    }
  }

  Future<void> _loadProductLocations() async {
    for (var product in _allProducts) {
      try {
        final adresse = await _firestoreService.getAdresseById(
          product.adresseId,
        );
        if (adresse != null) {
          String location = '';
          if (adresse.quartier != null && adresse.quartier!.isNotEmpty) {
            location = adresse.quartier!;
          }
          if (adresse.ville != null && adresse.ville!.isNotEmpty) {
            location +=
                location.isEmpty ? adresse.ville! : ', ${adresse.ville!}';
          }
          if (location.isEmpty) {
            location = adresse.description;
          }
          _productLocations[product.id] = location;
        }
      } catch (e) {
        print('Erreur lors du chargement de l\'adresse pour ${product.id}: $e');
      }
    }
  }

  Future<void> _loadFavorites() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      _firestoreService.getFavoris(currentUser.uid).listen((favoris) {
        setState(() {
          _favoriteProductIds = favoris.map((f) => f.produitId).toList();
        });
      });
    }
  }

  void _performSearch(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      _applyFilters();
    });
  }

  void _applyFilters() {
    List<Produit> filtered = _allProducts;

    // Filtrer par recherche uniquement
    if (_searchQuery.isNotEmpty) {
      filtered =
          filtered.where((product) {
            return product.nom.toLowerCase().contains(_searchQuery) ||
                product.description.toLowerCase().contains(_searchQuery);
          }).toList();
    }

    // Trier les produits
    switch (_sortBy) {
      case "Prix: croissant":
        filtered.sort((a, b) => a.prix.compareTo(b.prix));
        break;
      case "Prix: décroissant":
        filtered.sort((a, b) => b.prix.compareTo(a.prix));
        break;
      case "Recent":
        filtered.sort((a, b) => b.dateAjout.compareTo(a.dateAjout));
        break;
      case "Plus vus":
        filtered.sort((a, b) => b.vues.compareTo(a.vues));
        break;
      default:
        filtered.sort((a, b) => b.dateAjout.compareTo(a.dateAjout));
        break;
    }

    setState(() {
      _filteredProducts = filtered;
    });
  }

  Future<void> _toggleFavorite(String productId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      if (_favoriteProductIds.contains(productId)) {
        await _firestoreService.removeFavori(currentUser.uid, productId);
      } else {
        final favori = Favori(
          id: _firestoreService.generateNewFavoriId(),
          userId: currentUser.uid,
          produitId: productId,
          dateAjout: DateTime.now(),
        );
        await _firestoreService.addFavori(favori);
      }
    } catch (e) {
      print('Erreur lors de la gestion des favoris: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la gestion des favoris')),
      );
    }
  }

  void _showSortDialog() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Container(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trier par',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 20),
                ...sortOptions.map(
                  (option) => ListTile(
                    title: Text(option),
                    trailing:
                        _sortBy == option
                            ? Icon(
                              Icons.check,
                              color: Theme.of(context).primaryColor,
                            )
                            : null,
                    onTap: () {
                      setState(() {
                        _sortBy = option;
                      });
                      _applyFilters();
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildProductList(Produit product) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    bool isFavorite = _favoriteProductIds.contains(product.id);
    String imageUrl = _productImages[product.id] ?? '';
    String location = _productLocations[product.id] ?? 'Non spécifié';

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.dark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(12),
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: isDark ? AppColors.grey.withOpacity(0.3) : Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child:
              imageUrl.isNotEmpty
                  ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Icon(
                            Iconsax.image,
                            color: AppColors.primary,
                            size: 24,
                          ),
                        );
                      },
                    ),
                  )
                  : Center(
                    child: Icon(
                      Iconsax.image,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
        ),
        title: Text(
          product.nom,
          style: TextStyle(
            color: isDark ? AppColors.textWhite : AppColors.black,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Iconsax.location,
                  size: 12,
                  color: isDark ? AppColors.textSecondary : Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    location,
                    style: TextStyle(
                      color:
                          isDark ? AppColors.textSecondary : Colors.grey[600],
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${_priceFormatter.format(product.prix.toInt())} FCFA',
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        trailing: GestureDetector(
          onTap: () => _toggleFavorite(product.id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color:
                  isFavorite
                      ? Colors.red.withOpacity(0.1)
                      : Colors.white.withOpacity(0.9),
              shape: BoxShape.circle,
              border:
                  isFavorite
                      ? Border.all(color: Colors.red.withOpacity(0.3))
                      : null,
            ),
            child: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? Colors.red : Colors.grey,
              size: 18,
            ),
          ),
        ),
      ),
    );
  }

  // Widget pour créer un skeleton de produit
  Widget _buildSkeletonProduct() {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.dark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(12),
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: isDark ? AppColors.grey.withOpacity(0.3) : Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        title: Container(
          height: 16,
          width: double.infinity,
          color: Colors.grey[300],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 8),
            Container(height: 12, width: 120, color: Colors.grey[300]),
            SizedBox(height: 4),
            Container(height: 14, width: 80, color: Colors.grey[300]),
          ],
        ),
        trailing: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.black : AppColors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            iconTheme: IconThemeData(
              color:
                  Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
            ),
            backgroundColor: isDark ? AppColors.black : AppColors.white,
            leading: IconButton(
              icon: Icon(Iconsax.arrow_left),
              onPressed: () => Navigator.of(context).pop(),
            ),
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(60),
              child: Container(
                height: 65,
                margin: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _performSearch,
                  decoration: InputDecoration(
                    labelText: "Chercher des produits",
                    prefixIcon: Icon(Iconsax.search_normal),
                    suffixIcon:
                        _searchQuery.isNotEmpty
                            ? IconButton(
                              icon: Icon(Iconsax.close_circle),
                              onPressed: () {
                                _searchController.clear();
                                _performSearch('');
                              },
                            )
                            : null,
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    '${_filteredProducts.length} résultats',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Spacer(),
                  TextButton.icon(
                    onPressed: _showSortDialog,
                    icon: Icon(Iconsax.sort, color: AppColors.primary),
                    label: Text(
                      'Trier',
                      style: TextStyle(color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Skeleton loader au lieu du CircularProgressIndicator
          if (_isLoading)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) =>
                    Skeletonizer(enabled: true, child: _buildSkeletonProduct()),
                childCount: 5, // Afficher 5 éléments skeleton
              ),
            ),

          // Message si aucun résultat
          if (!_isLoading && _filteredProducts.isEmpty)
            SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(Iconsax.search_normal, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Aucun produit trouvé',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Essayez de modifier vos critères de recherche',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Liste des produits
          if (!_isLoading && _filteredProducts.isNotEmpty)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildProductList(_filteredProducts[index]),
                childCount: _filteredProducts.length,
              ),
            ),

          // Espace en bas pour éviter que le contenu soit coupé
          SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }
}
