import 'package:flutter/material.dart';
import 'package:kassoua/constants/colors.dart';
import 'package:kassoua/constants/size.dart';
import 'package:kassoua/screens/add_edit_product_page.dart';
import 'package:iconsax/iconsax.dart';

// --- Page "Mes Annonces" Améliorée ---
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
      'status': 'disponible',
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
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? DMColors.black : DMColors.white,
      appBar: AppBar(
        title: Text(
          'Ma Boutique',
          style: TextStyle(
            color:
                Theme.of(context).brightness == Brightness.dark
                    ? DMColors.textWhite
                    : Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 0,
        backgroundColor: isDark ? DMColors.black : DMColors.white,
        actions: [
          Container(
            margin: EdgeInsets.only(right: DMSizes.md),
            decoration: BoxDecoration(
              color: DMColors.primary,
              borderRadius: BorderRadius.circular(DMSizes.borderRadiusMd),
            ),
            child: IconButton(
              icon: const Icon(Iconsax.add, color: DMColors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddEditProductPage(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body:
          mockProducts.isEmpty
              ? _buildEmptyState(context)
              : _buildProductList(context),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(DMSizes.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(DMSizes.xl),
              decoration: BoxDecoration(
                color: DMColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Iconsax.shop,
                size: DMSizes.iconLg * 2,
                color: DMColors.primary,
              ),
            ),
            SizedBox(height: DMSizes.spaceBtwItems),
            Text(
              'Votre boutique est vide',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: DMColors.textPrimary,
              ),
            ),
            SizedBox(height: DMSizes.xs),
            Text(
              'Commencez à vendre en ajoutant votre première annonce',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: DMColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: DMSizes.spaceBtwSections),
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
                  horizontal: DMSizes.xl,
                  vertical: DMSizes.md,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(DMSizes.buttonRadius),
                ),
                elevation: 2,
              ),
              icon: const Icon(Iconsax.add, color: DMColors.white),
              label: Text(
                'Créer ma première annonce',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: DMColors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductList(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.all(DMSizes.md),
      itemCount: mockProducts.length,
      itemBuilder: (context, index) {
        final product = mockProducts[index];
        final bool isSold = product['status'] == 'vendu';

        return Container(
          margin: EdgeInsets.only(bottom: DMSizes.md),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(DMSizes.borderRadiusLg),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Contenu principal de la carte
              Padding(
                padding: EdgeInsets.all(DMSizes.md),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image du produit avec badge de statut
                    Stack(
                      children: [
                        Container(
                          width: DMSizes.imageThumbSize,
                          height: DMSizes.imageThumbSize,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              DMSizes.borderRadiusMd,
                            ),
                            color: DMColors.grey.withOpacity(0.1),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(
                              DMSizes.borderRadiusMd,
                            ),
                            child: Image.network(
                              product['imageUrl']!,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (context, error, stackTrace) => Icon(
                                    Iconsax.image,
                                    size: DMSizes.iconMd,
                                    color: DMColors.darkGrey,
                                  ),
                            ),
                          ),
                        ),
                        // Badge de statut
                        Positioned(
                          top: DMSizes.xs,
                          right: DMSizes.xs,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: DMSizes.xs,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isSold ? DMColors.error : DMColors.success,
                              borderRadius: BorderRadius.circular(
                                DMSizes.borderRadiusSm,
                              ),
                            ),
                            child: Text(
                              isSold ? 'VENDU' : 'DISPO',
                              style: Theme.of(
                                context,
                              ).textTheme.labelSmall?.copyWith(
                                color: DMColors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(width: DMSizes.md),

                    // Détails du produit
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product['name']!,
                            style: Theme.of(
                              context,
                            ).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color:
                                  Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? DMColors.white
                                      : Colors.black,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: DMSizes.xs),
                          Text(
                            '${product['price']?.toStringAsFixed(0)} FCFA',
                            style: Theme.of(
                              context,
                            ).textTheme.titleLarge?.copyWith(
                              color: DMColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: DMSizes.xs),
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: DMSizes.sm,
                                  vertical: DMSizes.xs,
                                ),
                                decoration: BoxDecoration(
                                  color: DMColors.grey.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(
                                    DMSizes.borderRadiusSm,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Iconsax.box,
                                      size: DMSizes.iconSm,
                                      color: DMColors.textSecondary,
                                    ),
                                    SizedBox(width: DMSizes.xs),
                                    Text(
                                      'Qté: ${product['quantity']}',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall?.copyWith(
                                        color: DMColors.textSecondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Barre d'actions en bas - VERSION UNIFORME
              Container(
                decoration: BoxDecoration(
                  color:
                      Theme.of(context).brightness == Brightness.dark
                          ? DMColors.dark.withOpacity(0.3)
                          : DMColors.grey.withOpacity(0.05),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(DMSizes.borderRadiusLg),
                    bottomRight: Radius.circular(DMSizes.borderRadiusLg),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.all(DMSizes.sm),
                  child: Row(
                    children: [
                      // Bouton Modifier - toujours présent
                      _buildActionButton(
                        context: context,
                        icon: Iconsax.edit,
                        label: 'Modifier',
                        color: DMColors.primary,
                        onPressed: () {
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

                      // Séparateur vertical
                      Container(
                        height: 30,
                        width: 1,
                        color: DMColors.grey.withOpacity(0.3),
                        margin: EdgeInsets.symmetric(horizontal: DMSizes.xs),
                      ),

                      // Bouton Status - adapté selon l'état
                      _buildActionButton(
                        context: context,
                        icon: isSold ? Iconsax.refresh : Iconsax.tick_circle,
                        label: isSold ? 'Remettre' : 'Vendu',
                        color: isSold ? DMColors.info : DMColors.success,
                        onPressed: () {
                          if (isSold) {
                            _showReactivateConfirmationDialog(
                              context,
                              product['name']!,
                            );
                          } else {
                            _showMarkAsSoldConfirmationDialog(
                              context,
                              product['name']!,
                            );
                          }
                        },
                      ),

                      // Séparateur vertical
                      Container(
                        height: 30,
                        width: 1,
                        color: DMColors.grey.withOpacity(0.3),
                        margin: EdgeInsets.symmetric(horizontal: DMSizes.xs),
                      ),

                      // Bouton Supprimer - toujours présent
                      _buildActionButton(
                        context: context,
                        icon: Iconsax.trash,
                        label: 'Supprimer',
                        color: DMColors.error,
                        onPressed: () {
                          _showDeleteConfirmationDialog(
                            context,
                            product['name']!,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(DMSizes.borderRadiusSm),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: DMSizes.sm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: DMSizes.iconMd),
              SizedBox(height: DMSizes.xs / 2),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Fonction pour afficher la boîte de dialogue de confirmation de suppression
  void _showDeleteConfirmationDialog(BuildContext context, String productName) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DMSizes.borderRadiusLg),
          ),
          title: Row(
            children: [
              Container(
                padding: EdgeInsets.all(DMSizes.sm),
                decoration: BoxDecoration(
                  color: DMColors.error.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Iconsax.warning_2,
                  color: DMColors.error,
                  size: DMSizes.iconMd,
                ),
              ),
              SizedBox(width: DMSizes.md),
              const Text('Confirmer la suppression'),
            ],
          ),
          content: Text(
            'Voulez-vous vraiment supprimer l\'annonce "$productName" ?\n\nCette action est irréversible.',
            style: Theme.of(context).textTheme.bodyMedium,
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
                backgroundColor: DMColors.error,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(DMSizes.borderRadiusSm),
                ),
              ),
              child: const Text(
                'Supprimer',
                style: TextStyle(color: DMColors.white),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Annonce "$productName" supprimée (simulation).',
                    ),
                    backgroundColor: DMColors.error,
                  ),
                );
                Navigator.of(dialogContext).pop();
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DMSizes.borderRadiusLg),
          ),
          title: Row(
            children: [
              Container(
                padding: EdgeInsets.all(DMSizes.sm),
                decoration: BoxDecoration(
                  color: DMColors.success.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Iconsax.tick_circle,
                  color: DMColors.success,
                  size: DMSizes.iconMd,
                ),
              ),
              SizedBox(width: DMSizes.md),
              const Text('Marquer comme vendu'),
            ],
          ),
          content: Text(
            'Voulez-vous marquer l\'annonce "$productName" comme "Vendu" ?',
            style: Theme.of(context).textTheme.bodyMedium,
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(DMSizes.borderRadiusSm),
                ),
              ),
              child: const Text(
                'Confirmer',
                style: TextStyle(color: DMColors.white),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Annonce "$productName" marquée comme vendue (simulation).',
                    ),
                    backgroundColor: DMColors.success,
                  ),
                );
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Nouvelle fonction pour remettre en vente un produit vendu
  void _showReactivateConfirmationDialog(
    BuildContext context,
    String productName,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DMSizes.borderRadiusLg),
          ),
          title: Row(
            children: [
              Container(
                padding: EdgeInsets.all(DMSizes.sm),
                decoration: BoxDecoration(
                  color: DMColors.info.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Iconsax.refresh,
                  color: DMColors.info,
                  size: DMSizes.iconMd,
                ),
              ),
              SizedBox(width: DMSizes.md),
              const Text('Remettre en vente'),
            ],
          ),
          content: Text(
            'Voulez-vous remettre l\'annonce "$productName" en vente ?',
            style: Theme.of(context).textTheme.bodyMedium,
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
                backgroundColor: DMColors.info,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(DMSizes.borderRadiusSm),
                ),
              ),
              child: const Text(
                'Confirmer',
                style: TextStyle(color: DMColors.white),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Annonce "$productName" remise en vente (simulation).',
                    ),
                    backgroundColor: DMColors.info,
                  ),
                );
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
