import 'package:flutter/material.dart';
import 'package:kassoua/constants/colors.dart';
import 'package:kassoua/constants/size.dart';
import 'package:kassoua/views/screen/shop/add_edit_product_page.dart';
import 'package:kassoua/services/firestore_service.dart';
import 'package:kassoua/models/product.dart';
import 'package:kassoua/models/image_produit.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:iconsax/iconsax.dart';
import 'package:panara_dialogs/panara_dialogs.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:kassoua/views/screen/shop/product_detail_vendeur.dart';

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
      backgroundColor: isDark ? AppColors.black : AppColors.white,
      appBar: AppBar(
        title: Text(
          'Mes annonces',
          style: TextStyle(
            color:
                Theme.of(context).brightness == Brightness.dark
                    ? AppColors.textWhite
                    : Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 0,
        backgroundColor: isDark ? AppColors.black : Colors.white,
        actions: [
          Container(
            margin: EdgeInsets.only(right: DMSizes.md),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(DMSizes.borderRadiusMd),
            ),
            child: IconButton(
              icon: const Icon(Iconsax.add, color: AppColors.white),
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
              color: AppColors.primary,
            ),
            SizedBox(height: DMSizes.spaceBtwItems),
            Text(
              'Veuillez vous connecter',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: DMSizes.xs),
            Text(
              'Connectez-vous pour voir vos annonces',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
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
          CircularProgressIndicator(color: AppColors.primary),
          SizedBox(height: DMSizes.spaceBtwItems),
          Text(
            'Chargement de vos annonces...',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
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
              color: AppColors.error,
            ),
            SizedBox(height: DMSizes.spaceBtwItems),
            Text(
              'Erreur de chargement',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: DMSizes.xs),
            Text(
              'Impossible de charger vos annonces',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: DMSizes.spaceBtwSections),
            ElevatedButton(
              onPressed: () => setState(() {}),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: EdgeInsets.symmetric(
                  horizontal: DMSizes.xl,
                  vertical: DMSizes.md,
                ),
              ),
              child: Text(
                'Réessayer',
                style: TextStyle(color: AppColors.white),
              ),
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
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Iconsax.shop,
                size: DMSizes.iconLg * 2,
                color: AppColors.primary,
              ),
            ),
            SizedBox(height: DMSizes.spaceBtwItems),
            Text(
              'Votre boutique est vide',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: DMSizes.xs),
            Text(
              'Commencez à vendre en ajoutant votre première annonce',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
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
                backgroundColor: AppColors.primary,
                padding: EdgeInsets.symmetric(
                  horizontal: DMSizes.xl,
                  vertical: DMSizes.md,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(DMSizes.buttonRadius),
                ),
                elevation: 2,
              ),
              icon: const Icon(Iconsax.add, color: AppColors.white),
              label: Text(
                'Créer ma première annonce',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.white,
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
                    ? AppColors.dark.withOpacity(0.3)
                    : AppColors.white, // La couleur de fond du Material
            borderRadius: BorderRadius.circular(DMSizes.borderRadiusMd),
            shadowColor: AppColors.dark.withOpacity(0.3), // Couleur de l'ombre
            elevation: 8, // L'élévation pour l'ombre
            child: InkWell(
              onTap: () async {
                // Affiche un loader si tu veux
                final images =
                    await _firestoreService.getImagesProduit(product.id).first;
                final imageUrls = images.map((img) => img.url).toList();

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => ProductDetailVendeur(
                          produit: product,
                          images: imageUrls,
                        ),
                  ),
                );
              },
              // Configurez les couleurs de splash et highlight
              splashColor: AppColors.primary.withOpacity(0.2),
              highlightColor: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(
                DMSizes.borderRadiusMd,
              ), // Doit correspondre au Material borderRadius
              // L'enfant de InkWell est maintenant un Container qui n'a plus de couleur de fond
              child: Container(
                padding: EdgeInsets.all(DMSizes.sm),
                decoration: BoxDecoration(
                  // Maintenez la bordure ici si vous voulez, mais la couleur de fond est gérée par le Material
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.3),
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
                            builder: (
                              BuildContext context,
                              AsyncSnapshot<List<ImageProduit>> snapshot,
                            ) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return Container(
                                  width: DMSizes.imageThumbSize,
                                  height: DMSizes.imageThumbSize,
                                  color: AppColors.grey.withOpacity(0.1),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                );
                              }
                              if (snapshot.hasData &&
                                  snapshot.data!.isNotEmpty) {
                                final imageUrl = snapshot.data!.first.url;
                                return CachedNetworkImage(
                                  imageUrl: imageUrl,
                                  width: DMSizes.imageThumbSize,
                                  height: DMSizes.imageThumbSize,
                                  fit: BoxFit.cover,
                                  placeholder:
                                      (context, url) => Container(
                                        color: AppColors.grey.withOpacity(0.1),
                                      ),
                                  errorWidget:
                                      (context, url, error) => Icon(
                                        Iconsax.image,
                                        size: DMSizes.iconMd,
                                        color: AppColors.darkGrey,
                                      ),
                                );
                              }
                              return Container(
                                width: DMSizes.imageThumbSize,
                                height: DMSizes.imageThumbSize,
                                color: AppColors.grey.withOpacity(0.1),
                                child: Icon(
                                  Iconsax.image,
                                  size: DMSizes.iconMd,
                                  color: AppColors.darkGrey,
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
                                  color: AppColors.primary,
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
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: DMSizes.sm,
                                      vertical: DMSizes.xs,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.error.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      'Vendu',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.labelLarge?.copyWith(
                                        color: AppColors.error,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
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
              color: AppColors.grey.withOpacity(0.1),
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
                            color: AppColors.darkGrey,
                          ),
                    );
                  } else {
                    // Pas d'image disponible
                    return Icon(
                      Iconsax.image,
                      size: DMSizes.iconMd,
                      color: AppColors.darkGrey,
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
              color: isSold ? AppColors.error : AppColors.success,
              borderRadius: BorderRadius.circular(DMSizes.borderRadiusSm),
            ),
            child: Text(
              isSold ? 'VENDU' : 'DISPO',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.white,
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
                ? AppColors.dark.withOpacity(0.3)
                : AppColors.grey.withOpacity(0.05),
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
              color: AppColors.primary,
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
              color: AppColors.grey.withOpacity(0.3),
              margin: EdgeInsets.symmetric(horizontal: DMSizes.xs),
            ),

            // Bouton Status
            _buildActionButton(
              context: context,
              icon: isSold ? Iconsax.refresh : Iconsax.tick_circle,
              label: isSold ? 'Remettre' : 'Vendu',
              color: isSold ? AppColors.info : AppColors.primary,
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
              color: AppColors.grey.withOpacity(0.3),
              margin: EdgeInsets.symmetric(horizontal: DMSizes.xs),
            ),

            // Bouton Supprimer
            _buildActionButton(
              context: context,
              icon: Icons.delete,
              label: 'Supprimer',
              color: AppColors.primary,
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
        return AppColors.success;
      case 'tres_bon_etat':
        return AppColors.info;
      case 'bon_etat':
        return AppColors.primary;
      case 'etat_correct':
        return AppColors.warning;
      case 'occasion':
      default:
        return AppColors.textSecondary;
    }
  }

  void _showDeleteConfirmationDialog(BuildContext context, Produit product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      isDismissible: false, // Empêche la fermeture en tapant hors de la feuille
      enableDrag: false, // Empêche la fermeture par glissement
      builder: (ctx) {
        return Container(
          margin: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color:
                Theme.of(ctx).brightness == Brightness.dark
                    ? AppColors.dark
                    : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Icône d’avertissement (image ou icône)
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Image.asset(
                    'assets/images/icons/warning.png',
                    fit: BoxFit.contain,
                  ),
                ),

                const SizedBox(height: 24),

                // Titre
                const Text(
                  'Supprimer l\'annonce',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'poppins',
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 12),

                // Message
                Text(
                  'Êtes-vous sûr de vouloir supprimer l\'annonce "${product.nom}" ?',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 32),

                // Boutons
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.grey[100],
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Annuler',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          try {
                            await _firestoreService.deleteProduct(product.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Annonce "${product.nom}" supprimée avec succès.',
                                  ),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Erreur lors de la suppression: $e',
                                  ),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                          } finally {
                            if (ctx.mounted) Navigator.of(ctx).pop();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.delete_outline, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Supprimer',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // Espace pour éviter le clavier, au cas où
                SizedBox(height: MediaQuery.of(ctx).viewInsets.bottom),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showMarkAsSoldConfirmationDialog(
    BuildContext context,
    Produit product,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (ctx) {
        return Container(
          margin: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color:
                Theme.of(ctx).brightness == Brightness.dark
                    ? AppColors.dark
                    : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Icône de validation
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Image.asset(
                    'assets/images/icons/tick-circle.png',
                    fit: BoxFit.contain,
                  ),
                ),

                const SizedBox(height: 24),

                // Titre
                const Text(
                  'Marquer comme vendu',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'poppins',
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 12),

                // Message
                Text(
                  'Êtes-vous sûr de vouloir marquer l\'annonce "${product.nom}" comme vendue ?',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 32),

                // Boutons
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.grey[100],
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Annuler',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          try {
                            await _firestoreService.markProductAsSold(
                              product.id,
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Annonce "${product.nom}" marquée comme vendue.',
                                  ),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Erreur lors de la mise à jour: $e',
                                  ),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                          } finally {
                            if (ctx.mounted) Navigator.of(ctx).pop();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Marquer comme vendu',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // Espace pour éviter le clavier
                SizedBox(height: MediaQuery.of(ctx).viewInsets.bottom),
              ],
            ),
          ),
        );
      },
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
                backgroundColor: AppColors.info,
              ),
            );
            Navigator.of(context).pop();
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erreur lors de la mise à jour: $e'),
                backgroundColor: AppColors.error,
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
      color: AppColors.info,
      barrierDismissible: false,
      imagePath: 'assets/images/icons/refresh-arrow-02.png',
    );
  }
}
