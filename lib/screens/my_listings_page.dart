import 'package:flutter/material.dart';
import 'package:kassoua/constants/colors.dart'; // Assurez-vous du bon chemin
import 'package:kassoua/constants/size.dart';
import 'package:kassoua/screens/add_edit_product_page.dart'; // Assurez-vous du bon chemin

// --- Page "Mes Annonces" ---
class MyListingsPage extends StatelessWidget {
  const MyListingsPage({Key? key}) : super(key: key);

  // Données factices pour simuler les produits d'un vendeur
  final List<Map<String, dynamic>> mockProducts = const [
    {
      'id': 'prod_001',
      'name': 'Smartphone Android X20',
      'imageUrl': '',
      'price': 75000.0,
      'quantity': 1,
      'status': 'disponible', // ou 'vendu'
      'description': 'Smartphone en excellent état, 128GB, caméra 48MP.',
    },
    {
      'id': 'prod_002',
      'name': 'Vélo VTT Sportif',
      'imageUrl': '',
      'price': 120000.0,
      'quantity': 1,
      'status': 'vendu',
      'description': 'Vélo tout-terrain, peu utilisé, freins à disque.',
    },
    {
      'id': 'prod_003',
      'name': 'Kit de Couteaux de Cuisine',
      'imageUrl': '',
      'price': 15000.0,
      'quantity': 3,
      'status': 'disponible',
      'description': 'Ensemble de 5 couteaux de cuisine en acier inoxydable.',
    },
    {
      'id': 'prod_004',
      'name': 'Table Basse Design',
      'imageUrl': '',
      'price': 45000.0,
      'quantity': 1,
      'status': 'disponible',
      'description':
          'Table basse moderne en bois et métal, idéale pour votre salon.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    // Note: Pour une vraie application, vous vérifieriez ici le rôle de l'utilisateur
    // (s'il est bien un vendeur) avant d'afficher cette page.

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ma Boutique'),
        backgroundColor:
            DMColors.primary, // Utilisation de votre couleur primaire
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: DMColors.white),
            onPressed: () {
              // Naviguer vers la page d'ajout de produit
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddEditProductPage(),
                ),
              );
            },
          ),
        ],
      ),
      body:
          mockProducts.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.inbox,
                      size: DMSizes.iconLg * 2,
                      color: DMColors.darkGrey,
                    ),
                    SizedBox(height: DMSizes.spaceBtwItems),
                    Text(
                      'Vous n\'avez pas encore d\'annonces.',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(color: DMColors.darkGrey),
                    ),
                    SizedBox(height: DMSizes.spaceBtwItems),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AddEditProductPage(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DMColors.primary,
                        padding: EdgeInsets.symmetric(
                          horizontal: DMSizes.lg,
                          vertical: DMSizes.md,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            DMSizes.buttonRadius,
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.add, color: DMColors.white),
                      label: Text(
                        'Publier une nouvelle annonce',
                        style: Theme.of(
                          context,
                        ).textTheme.titleSmall?.copyWith(color: DMColors.white),
                      ),
                    ),
                  ],
                ),
              )
              : ListView.builder(
                padding: EdgeInsets.all(DMSizes.sm),
                itemCount: mockProducts.length,
                itemBuilder: (context, index) {
                  final product = mockProducts[index];
                  final bool isSold = product['status'] == 'vendu';

                  return Card(
                    elevation: DMSizes.cardElevation,
                    margin: EdgeInsets.symmetric(vertical: DMSizes.sm),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        DMSizes.borderRadiusMd,
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(DMSizes.sm),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Image du produit
                          SizedBox(
                            width: DMSizes.imageThumbSize,
                            height: DMSizes.imageThumbSize,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(
                                DMSizes.productImageRadius,
                              ),
                              child: Image.network(
                                product['imageUrl']!,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (context, error, stackTrace) => const Icon(
                                      Icons.broken_image,
                                      color: DMColors.darkGrey,
                                    ),
                              ),
                            ),
                          ),
                          SizedBox(width: DMSizes.spaceBtwItems),

                          // Détails du produit
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product['name']!,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: DMColors.textPrimary,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: DMSizes.xs),
                                Text(
                                  '${product['price']?.toStringAsFixed(0)} FCFA', // Format du prix
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(color: DMColors.textPrimary),
                                ),
                                SizedBox(height: DMSizes.xs),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.inventory_2_outlined,
                                      size: DMSizes.iconSm,
                                      color: DMColors.darkGrey,
                                    ),
                                    SizedBox(width: DMSizes.xs),
                                    Text(
                                      'Quantité: ${product['quantity']}',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall?.copyWith(
                                        color: DMColors.textSecondary,
                                      ),
                                    ),
                                    SizedBox(width: DMSizes.sm),
                                    Icon(
                                      Icons.circle,
                                      size: DMSizes.iconXs,
                                      color:
                                          isSold
                                              ? DMColors.error
                                              : DMColors.success,
                                    ),
                                    SizedBox(width: DMSizes.xs),
                                    Text(
                                      isSold ? 'Vendu' : 'Disponible',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall?.copyWith(
                                        color:
                                            isSold
                                                ? DMColors.error
                                                : DMColors.success,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Boutons d'action (Modifier, Supprimer, Marquer comme vendu)
                          Column(
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: DMColors.buttonPrimary,
                                ),
                                onPressed: () {
                                  // Naviguer vers la page de modification de produit
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => AddEditProductPage(
                                            productId: product['id'],
                                          ),
                                    ),
                                  );
                                },
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.delete_outline,
                                  color: DMColors.error,
                                ),
                                onPressed: () {
                                  // Afficher une boîte de dialogue de confirmation avant de supprimer
                                  _showDeleteConfirmationDialog(
                                    context,
                                    product['name']!,
                                  );
                                },
                              ),
                              if (!isSold) // Afficher seulement si le produit n'est pas déjà vendu
                                IconButton(
                                  icon: const Icon(
                                    Icons.check_circle_outline,
                                    color: DMColors.success,
                                  ),
                                  onPressed: () {
                                    // Marquer le produit comme vendu
                                    _showMarkAsSoldConfirmationDialog(
                                      context,
                                      product['name']!,
                                    );
                                  },
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
    );
  }

  // Fonction pour afficher la boîte de dialogue de confirmation de suppression
  void _showDeleteConfirmationDialog(BuildContext context, String productName) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirmer la suppression'),
          content: Text(
            'Voulez-vous vraiment supprimer l\'annonce "$productName" ?',
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Annuler',
                style: TextStyle(color: DMColors.textSecondary),
              ),
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(); // Fermer la boîte de dialogue
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: DMColors.error),
              child: const Text(
                'Supprimer',
                style: TextStyle(color: DMColors.white),
              ),
              onPressed: () {
                // Logique de suppression ici (sera connecté à Firebase)
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Annonce "$productName" supprimée (simulation).',
                    ),
                  ),
                );
                Navigator.of(
                  dialogContext,
                ).pop(); // Fermer la boîte de dialogue
                // Vous devrez potentiellement rafraîchir l'interface ici après la suppression réelle.
              },
            ),
          ],
        );
      },
    );
  }

  // Fonction pour afficher la boîte de dialogue de confirmation "Marquer comme vendu"
  void _showMarkAsSoldConfirmationDialog(
    BuildContext context,
    String productName,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Marquer comme vendu'),
          content: Text(
            'Voulez-vous marquer l\'annonce "$productName" comme "Vendu" ?',
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Annuler',
                style: TextStyle(color: DMColors.textSecondary),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: DMColors.success,
              ),
              child: const Text(
                'Marquer comme vendu',
                style: TextStyle(color: DMColors.white),
              ),
              onPressed: () {
                // Logique pour marquer comme vendu ici (sera connecté à Firebase)
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Annonce "$productName" marquée comme vendue (simulation).',
                    ),
                  ),
                );
                Navigator.of(dialogContext).pop();
                // Vous devrez potentiellement rafraîchir l'interface ici après la mise à jour réelle.
              },
            ),
          ],
        );
      },
    );
  }
}
