import 'package:flutter/material.dart';
import 'package:kassoua/constants/colors.dart';
import 'package:kassoua/constants/size.dart';
import 'package:kassoua/screens/shop/add_edit_product_page.dart';
import 'package:iconsax/iconsax.dart';
import 'package:panara_dialogs/panara_dialogs.dart';

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
        backgroundColor: isDark ? DMColors.black : Colors.white,
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
            color:
                Theme.of(context).brightness == Brightness.dark
                    ? DMColors.dark.withOpacity(0.3)
                    : DMColors.white,
            borderRadius: BorderRadius.circular(DMSizes.borderRadiusLg),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
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
                              fontSize: 19,
                            ),
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
    PanaraConfirmDialog.show(
      context,
      title: 'Supprimer l\'annonce',
      message: 'Êtes-vous sûr de vouloir supprimer l\'annonce "$productName" ?',
      confirmButtonText: 'Supprimer',
      cancelButtonText: 'Annuler',

      onTapConfirm: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Annonce "$productName" supprimée (simulation).'),
            backgroundColor: DMColors.error,
          ),
        );
        Navigator.of(context).pop();
      },
      onTapCancel: () {
        Navigator.of(context).pop();
      },
      panaraDialogType: PanaraDialogType.custom,
      color: DMColors.error,
      barrierDismissible: false,
      imagePath: 'assets/images/icons/warning.png',
    );
  }

  // Fonction pour afficher la boîte de dialogue de confirmation "Marquer comme vendu"
  void _showMarkAsSoldConfirmationDialog(
    BuildContext context,
    String productName,
  ) {
    PanaraConfirmDialog.show(
      context,
      title: 'Marquer comme vendu',
      message:
          'Êtes-vous sûr de vouloir marquer l\'annonce "$productName" comme vendue ?',
      confirmButtonText: 'Marquer comme vendu',
      cancelButtonText: 'Annuler',
      onTapConfirm: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Annonce "$productName" marquée comme vendue (simulation).',
            ),
            backgroundColor: DMColors.success,
          ),
        );
        Navigator.of(context).pop();
      },
      onTapCancel: () {
        Navigator.of(context).pop();
      },
      panaraDialogType: PanaraDialogType.custom,
      color: DMColors.success,
      barrierDismissible: false,
      imagePath: 'assets/images/icons/tick-circle.png',
    );
  }

  // Nouvelle fonction pour remettre en vente un produit vendu
  void _showReactivateConfirmationDialog(
    BuildContext context,
    String productName,
  ) {
    PanaraConfirmDialog.show(
      context,
      title: 'Remettre en vente',
      message: 'Voulez-vous remettre l\'annonce "$productName" en vente ?',
      confirmButtonText: 'Confirmer',
      cancelButtonText: 'Annuler',
      onTapConfirm: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Annonce "$productName" remise en vente (simulation).',
            ),
            backgroundColor: DMColors.info,
          ),
        );
        Navigator.of(context).pop();
      },
      onTapCancel: () {
        Navigator.of(context).pop();
      },
      panaraDialogType: PanaraDialogType.custom,
      color: DMColors.info,
      barrierDismissible: false,
      imagePath: 'assets/images/icons/refresh-arrow-02.png',
    );
  }
}
