import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kassoua/models/favori.dart';
import 'package:kassoua/models/product.dart';
import 'package:kassoua/services/favori_service.dart';

class FavoriteProductsScreen extends StatefulWidget {
  final String userId;

  const FavoriteProductsScreen({Key? key, required this.userId})
    : super(key: key);

  @override
  State<FavoriteProductsScreen> createState() => _FavoriteProductsScreenState();
}

class _FavoriteProductsScreenState extends State<FavoriteProductsScreen> {
  final favoriService _favoriService = favoriService();
  List<Produit> _favoriteProducts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavoriteProducts();
  }

  void _loadFavoriteProducts() {
    _favoriService.getFavoris(widget.userId).listen((favoris) async {
      if (favoris.isNotEmpty) {
        final productIds = favoris.map((f) => f.produitId).toList();
        final products = await _favoriService.fetchProductsByIds(productIds);

        setState(() {
          _favoriteProducts =
              products
                  .map(
                    (productData) =>
                        Produit.fromMap(productData, productData['id']),
                  )
                  .toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _favoriteProducts = [];
          _isLoading = false;
        });
      }
    });
  }

  Future<void> _removeFavorite(String productId) async {
    try {
      await _favoriService.removeFavori(widget.userId, productId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Produit retiré des favoris'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mes Favoris',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.blue.shade600,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _favoriteProducts.isEmpty
              ? _buildEmptyState()
              : _buildFavoritesList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Aucun produit favori',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ajoutez des produits à vos favoris\npour les retrouver ici',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesList() {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {
          _isLoading = true;
        });
        _loadFavoriteProducts();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _favoriteProducts.length,
        itemBuilder: (context, index) {
          final product = _favoriteProducts[index];
          return _buildProductCard(product);
        },
      ),
    );
  }

  Widget _buildProductCard(Produit product) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          // Navigation vers les détails du produit
          // Navigator.push(context, MaterialPageRoute(
          //   builder: (context) => ProductDetailScreen(product: product),
          // ));
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Image du produit (placeholder)
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.image, size: 40, color: Colors.grey.shade400),
              ),
              const SizedBox(width: 16),
              // Informations du produit
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.nom,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '${product.prix.toStringAsFixed(0)} FCFA',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(product.etat),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            product.etatText,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.visibility,
                          size: 14,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${product.vues} vues',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        if (product.estnegociable) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.handshake,
                            size: 14,
                            color: Colors.orange.shade600,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            'Négociable',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Bouton supprimer des favoris
              IconButton(
                onPressed: () => _showRemoveDialog(product),
                icon: const Icon(Icons.favorite, color: Colors.red),
                tooltip: 'Retirer des favoris',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String etat) {
    switch (etat.toLowerCase()) {
      case 'neuf':
        return Colors.green;
      case 'tres_bon_etat':
        return Colors.lightGreen;
      case 'bon_etat':
        return Colors.orange;
      case 'etat_correct':
        return Colors.deepOrange;
      default:
        return Colors.blue;
    }
  }

  void _showRemoveDialog(Produit product) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Retirer des favoris'),
          content: Text(
            'Voulez-vous vraiment retirer "${product.nom}" de vos favoris ?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Annuler',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _removeFavorite(product.id);
              },
              child: const Text('Retirer', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
