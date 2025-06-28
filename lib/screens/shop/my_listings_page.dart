import 'package:flutter/material.dart';
import 'package:kassoua/constants/colors.dart';
import 'package:kassoua/constants/size.dart';
import 'package:kassoua/screens/shop/add_edit_product_page.dart';
import 'package:kassoua/services/firestore_service.dart';
import 'package:kassoua/models/product.dart';
import 'package:kassoua/models/image_produit.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:iconsax/iconsax.dart';
import 'package:panara_dialogs/panara_dialogs.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MyListingsPage extends StatefulWidget {
  const MyListingsPage({Key? key}) : super(key: key);

  @override
  State<MyListingsPage> createState() => _MyListingsPageState();
}

class _MyListingsPageState extends State<MyListingsPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? get currentUserId => _auth.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? DMColors.black : DMColors.white,
      appBar: AppBar(
        title: Text(
          'Mes annonces',
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
          currentUserId == null
              ? _buildNotLoggedInState(context)
              : StreamBuilder<List<Produit>>(
                stream: _firestoreService.getUserProducts(currentUserId!),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildLoadingState(context);
                  }

                  if (snapshot.hasError) {
                    return _buildErrorState(context, snapshot.error.toString());
                  }

                  final products = snapshot.data ?? [];

                  if (products.isEmpty) {
                    return _buildEmptyState(context);
                  }

                  return _buildProductList(context, products);
                },
              ),
    );
  }

  Widget _buildNotLoggedInState(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(DMSizes.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Iconsax.user,
              size: DMSizes.iconLg * 2,
              color: DMColors.primary,
            ),
            SizedBox(height: DMSizes.spaceBtwItems),
            Text(
              'Veuillez vous connecter',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: DMColors.textPrimary,
              ),
            ),
            SizedBox(height: DMSizes.xs),
            Text(
              'Connectez-vous pour voir vos annonces',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: DMColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: DMColors.primary),
          SizedBox(height: DMSizes.spaceBtwItems),
          Text(
            'Chargement de vos annonces...',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: DMColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(DMSizes.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Iconsax.warning_2,
              size: DMSizes.iconLg * 2,
              color: DMColors.error,
            ),
            SizedBox(height: DMSizes.spaceBtwItems),
            Text(
              'Erreur de chargement',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: DMColors.textPrimary,
              ),
            ),
            SizedBox(height: DMSizes.xs),
            Text(
              'Impossible de charger vos annonces',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: DMColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: DMSizes.spaceBtwSections),
            ElevatedButton(
              onPressed: () => setState(() {}),
              style: ElevatedButton.styleFrom(
                backgroundColor: DMColors.primary,
                padding: EdgeInsets.symmetric(
                  horizontal: DMSizes.xl,
                  vertical: DMSizes.md,
                ),
              ),
              child: Text('Réessayer', style: TextStyle(color: DMColors.white)),
            ),
          ],
        ),
      ),
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

  Widget _buildProductList(BuildContext context, List<Produit> products) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView.builder(
      padding: EdgeInsets.all(DMSizes.md),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return Padding(
          // Ajout d'un Padding pour la marge du bas
          padding: EdgeInsets.only(bottom: DMSizes.md),
          child: Material(
            // Le Material widget gère la couleur de fond et le borderRadius pour InkWell
            color:
                isDark
                    ? DMColors.dark.withOpacity(0.3)
                    : DMColors.white, // La couleur de fond du Material
            borderRadius: BorderRadius.circular(DMSizes.borderRadiusMd),
            shadowColor: DMColors.dark.withOpacity(0.3), // Couleur de l'ombre
            elevation: 8, // L'élévation pour l'ombre
            child: InkWell(
              onTap: () {
                print('Produit ${product.nom} cliqué !');
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => AddEditProductPage(productId: product.id),
                  ),
                );
              },
              // Configurez les couleurs de splash et highlight
              splashColor: DMColors.primary.withOpacity(0.2),
              highlightColor: DMColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(
                DMSizes.borderRadiusMd,
              ), // Doit correspondre au Material borderRadius
              // L'enfant de InkWell est maintenant un Container qui n'a plus de couleur de fond
              child: Container(
                padding: EdgeInsets.all(DMSizes.sm),
                decoration: BoxDecoration(
                  // Maintenez la bordure ici si vous voulez, mais la couleur de fond est gérée par le Material
                  border: Border.all(
                    color: DMColors.primary.withOpacity(0.3),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(
                    DMSizes.borderRadiusMd,
                  ), // Important
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Images du produit
                        ClipRRect(
                          borderRadius: BorderRadius.circular(
                            DMSizes.borderRadiusSm,
                          ),
                          child: StreamBuilder<List<ImageProduit>>(
                            stream: _firestoreService.getImagesProduit(
                              product.id,
                            ),
                            builder: (context, imageSnapshot) {
                              String imageUrl = product.imageUrl ?? '';
                              if (imageSnapshot.hasData &&
                                  imageSnapshot.data!.isNotEmpty) {
                                imageUrl = imageSnapshot.data!.first.url;
                              }
                              return CachedNetworkImage(
                                imageUrl: imageUrl,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                                errorWidget:
                                    (context, url, error) => Container(
                                      width: 100,
                                      height: 100,
                                      color: DMColors.grey.withOpacity(0.3),
                                      child: const Icon(
                                        Iconsax.gallery_slash,
                                        color: DMColors.textSecondary,
                                      ),
                                    ),
                              );
                            },
                          ),
                        ),
                        SizedBox(width: DMSizes.md),
                        // Infos du produit
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.nom,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: DMSizes.xs),
                              Text(
                                '${product.prix.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} FCFA',
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineSmall?.copyWith(
                                  color: DMColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: DMSizes.xs),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: DMSizes.xs,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: _getEtatColor(
                                    product.etat,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(
                                    DMSizes.borderRadiusSm,
                                  ),
                                ),
                                child: Text(
                                  product.etatText,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.labelSmall?.copyWith(
                                    color: _getEtatColor(product.etat),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              SizedBox(height: DMSizes.sm),
                              if (product.isVendu)
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: DMSizes.sm,
                                      vertical: DMSizes.xs,
                                    ),
                                    decoration: BoxDecoration(
                                      color: DMColors.error.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      'Vendu',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.labelLarge?.copyWith(
                                        color: DMColors.error,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    // Ajouter la barre d'actions
                    _buildActionBar(context, product),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProductImage(Produit product, bool isSold) {
    return Stack(
      children: [
        Hero(
          tag: 'product_image_${product.id}',
          child: Container(
            width: DMSizes.imageThumbSize,
            height: DMSizes.imageThumbSize,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(DMSizes.borderRadiusMd),
              color: DMColors.grey.withOpacity(0.1),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(DMSizes.borderRadiusMd),
              child: StreamBuilder<List<ImageProduit>>(
                stream: _firestoreService.getImagesProduit(product.id),
                builder: (context, imageSnapshot) {
                  if (imageSnapshot.hasData && imageSnapshot.data!.isNotEmpty) {
                    // Utiliser la première image trouvée
                    final imageUrl = imageSnapshot.data!.first.url;
                    return Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (context, error, stackTrace) => Icon(
                            Iconsax.image,
                            size: DMSizes.iconMd,
                            color: DMColors.darkGrey,
                          ),
                    );
                  } else if (product.imageUrl != null &&
                      product.imageUrl!.isNotEmpty) {
                    // Fallback vers l'imageUrl du produit si elle existe
                    return Image.network(
                      product.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (context, error, stackTrace) => Icon(
                            Iconsax.image,
                            size: DMSizes.iconMd,
                            color: DMColors.darkGrey,
                          ),
                    );
                  } else {
                    // Pas d'image disponible
                    return Icon(
                      Iconsax.image,
                      size: DMSizes.iconMd,
                      color: DMColors.darkGrey,
                    );
                  }
                },
              ),
            ),
          ),
        ),
        // Badge de statut
        Positioned(
          top: DMSizes.xs,
          right: DMSizes.xs,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: DMSizes.xs, vertical: 2),
            decoration: BoxDecoration(
              color: isSold ? DMColors.error : DMColors.success,
              borderRadius: BorderRadius.circular(DMSizes.borderRadiusSm),
            ),
            child: Text(
              isSold ? 'VENDU' : 'DISPO',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: DMColors.white,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionBar(BuildContext context, Produit product) {
    final bool isSold = product.isVendu; // Correction ici

    return Container(
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
            // Bouton Modifier
            _buildActionButton(
              context: context,
              icon: Icons.edit,
              label: 'Modifier',
              color: DMColors.primary,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => AddEditProductPage(productId: product.id),
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

            // Bouton Status
            _buildActionButton(
              context: context,
              icon: isSold ? Iconsax.refresh : Iconsax.tick_circle,
              label: isSold ? 'Remettre' : 'Vendu',
              color: isSold ? DMColors.info : DMColors.primary,
              onPressed: () {
                if (isSold) {
                  _showReactivateConfirmationDialog(context, product);
                } else {
                  _showMarkAsSoldConfirmationDialog(context, product);
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

            // Bouton Supprimer
            _buildActionButton(
              context: context,
              icon: Icons.delete,
              label: 'Supprimer',
              color: DMColors.primary,
              onPressed: () {
                _showDeleteConfirmationDialog(context, product);
              },
            ),
          ],
        ),
      ),
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

  Color _getEtatColor(String etat) {
    switch (etat.toLowerCase()) {
      case 'neuf':
        return DMColors.success;
      case 'tres_bon_etat':
        return DMColors.info;
      case 'bon_etat':
        return DMColors.primary;
      case 'etat_correct':
        return DMColors.warning;
      case 'occasion':
      default:
        return DMColors.textSecondary;
    }
  }

  void _showDeleteConfirmationDialog(BuildContext context, Produit product) {
    PanaraConfirmDialog.show(
      context,
      title: 'Supprimer l\'annonce',
      message:
          'Êtes-vous sûr de vouloir supprimer l\'annonce "${product.nom}" ?',
      confirmButtonText: 'Supprimer',
      cancelButtonText: 'Annuler',
      onTapConfirm: () async {
        try {
          await _firestoreService.deleteProduct(product.id);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Annonce "${product.nom}" supprimée avec succès.',
                ),
                backgroundColor: DMColors.success,
              ),
            );
            Navigator.of(context).pop();
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erreur lors de la suppression: $e'),
                backgroundColor: DMColors.error,
              ),
            );
            Navigator.of(context).pop();
          }
        }
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

  void _showMarkAsSoldConfirmationDialog(
    BuildContext context,
    Produit product,
  ) {
    PanaraConfirmDialog.show(
      context,
      title: 'Marquer comme vendu',
      message:
          'Êtes-vous sûr de vouloir marquer l\'annonce "${product.nom}" comme vendue ?',
      confirmButtonText: 'Marquer comme vendu',
      cancelButtonText: 'Annuler',
      onTapConfirm: () async {
        try {
          await _firestoreService.markProductAsSold(product.id);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Annonce "${product.nom}" marquée comme vendue.'),
                backgroundColor: DMColors.success,
              ),
            );
            Navigator.of(context).pop();
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erreur lors de la mise à jour: $e'),
                backgroundColor: DMColors.error,
              ),
            );
            Navigator.of(context).pop();
          }
        }
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

  void _showReactivateConfirmationDialog(
    BuildContext context,
    Produit product,
  ) {
    PanaraConfirmDialog.show(
      context,
      title: 'Remettre en vente',
      message: 'Voulez-vous remettre l\'annonce "${product.nom}" en vente ?',
      confirmButtonText: 'Confirmer',
      cancelButtonText: 'Annuler',
      onTapConfirm: () async {
        try {
          await _firestoreService.reactivateProduct(product.id);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Annonce "${product.nom}" remise en vente.'),
                backgroundColor: DMColors.info,
              ),
            );
            Navigator.of(context).pop();
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erreur lors de la mise à jour: $e'),
                backgroundColor: DMColors.error,
              ),
            );
            Navigator.of(context).pop();
          }
        }
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
