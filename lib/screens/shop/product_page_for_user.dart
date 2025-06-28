import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kassoua/constants/colors.dart';
import 'package:kassoua/constants/size.dart';
import 'package:kassoua/services/firestore_service.dart';
import 'package:kassoua/models/product.dart';
import 'package:kassoua/models/image_produit.dart';
import 'package:kassoua/models/adresse.dart';
import 'package:kassoua/screens/shop/add_edit_product_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:panara_dialogs/panara_dialogs.dart';
import 'package:kassoua/services/categorie_service.dart';
import 'package:url_launcher/url_launcher.dart';

class ProductDetailPage extends StatefulWidget {
  final String productId;

  const ProductDetailPage({Key? key, required this.productId})
    : super(key: key);

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final CategoryService _CategoryService = CategoryService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final PageController _imagePageController = PageController();
  int _currentImageIndex = 0;

  String? get currentUserId => _auth.currentUser?.uid;

  @override
  void dispose() {
    _imagePageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? DMColors.black : DMColors.white,
      body: StreamBuilder<Produit?>(
        stream: Stream.fromFuture(
          _firestoreService.getProduct(widget.productId),
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingState();
          }

          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString());
          }

          final product = snapshot.data;
          if (product == null) {
            return _buildNotFoundState();
          }

          return _buildProductDetail(product);
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: DMColors.primary),
            SizedBox(height: DMSizes.spaceBtwItems),
            Text(
              'Chargement du produit...',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: DMColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: Center(
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
                'Impossible de charger ce produit',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: DMColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotFoundState() {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(DMSizes.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Iconsax.box,
                size: DMSizes.iconLg * 2,
                color: DMColors.textSecondary,
              ),
              SizedBox(height: DMSizes.spaceBtwItems),
              Text(
                'Produit non trouvé',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: DMColors.textPrimary,
                ),
              ),
              SizedBox(height: DMSizes.xs),
              Text(
                'Ce produit n\'existe plus ou a été supprimé',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: DMColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductDetail(Produit product) {
    final bool isOwner = currentUserId == product.vendeurId;
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return CustomScrollView(
      slivers: [
        // App Bar avec image de fond
        SliverAppBar(
          expandedHeight: 300,
          pinned: true,
          backgroundColor: isDark ? DMColors.black : DMColors.white,
          iconTheme: IconThemeData(color: DMColors.white),
          actions: [
            if (isOwner)
              Container(
                margin: EdgeInsets.only(right: DMSizes.sm),
                decoration: BoxDecoration(
                  color: DMColors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(DMSizes.borderRadiusMd),
                ),
                child: IconButton(
                  icon: Icon(Iconsax.edit, color: DMColors.white),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) =>
                                AddEditProductPage(productId: widget.productId),
                      ),
                    );
                  },
                ),
              ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: _buildImageGallery(product),
          ),
        ),

        // Contenu du produit
        SliverToBoxAdapter(
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? DMColors.black : DMColors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(DMSizes.borderRadiusLg),
                topRight: Radius.circular(DMSizes.borderRadiusLg),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(DMSizes.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titre et prix
                  _buildTitleAndPrice(product),
                  SizedBox(height: DMSizes.spaceBtwItems),

                  // État et statut
                  _buildStatusRow(product),
                  SizedBox(height: DMSizes.spaceBtwSections),

                  // Localisation
                  _buildLocationSection(product),
                  SizedBox(height: DMSizes.spaceBtwSections),

                  // Description
                  _buildDescriptionSection(product),
                  SizedBox(height: DMSizes.spaceBtwSections),

                  // Informations supplémentaires
                  _buildAdditionalInfo(product),

                  // Barre d'actions pour le propriétaire
                  if (isOwner) ...[
                    SizedBox(height: DMSizes.spaceBtwSections),
                    _buildOwnerActions(product),
                  ],

                  SizedBox(height: DMSizes.spaceBtwSections),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageGallery(Produit product) {
    return StreamBuilder<List<ImageProduit>>(
      stream: _firestoreService.getImagesProduit(product.id),
      builder: (context, snapshot) {
        List<String> imageUrls = [];

        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          imageUrls = snapshot.data!.map((img) => img.url).toList();
        } else if (product.imageUrl != null && product.imageUrl!.isNotEmpty) {
          imageUrls = [product.imageUrl!];
        }

        if (imageUrls.isEmpty) {
          return Container(
            color: DMColors.grey.withOpacity(0.3),
            child: Center(
              child: Icon(
                Iconsax.gallery_slash,
                size: DMSizes.iconLg * 2,
                color: DMColors.textSecondary,
              ),
            ),
          );
        }

        return Stack(
          children: [
            PageView.builder(
              controller: _imagePageController,
              onPageChanged: (index) {
                setState(() {
                  _currentImageIndex = index;
                });
              },
              itemCount: imageUrls.length,
              itemBuilder: (context, index) {
                return CachedNetworkImage(
                  imageUrl: imageUrls[index],
                  fit: BoxFit.cover,
                  errorWidget:
                      (context, url, error) => Container(
                        color: DMColors.grey.withOpacity(0.3),
                        child: Icon(
                          Iconsax.gallery_slash,
                          size: DMSizes.iconLg,
                          color: DMColors.textSecondary,
                        ),
                      ),
                );
              },
            ),

            // Indicateurs de page
            if (imageUrls.length > 1)
              Positioned(
                bottom: DMSizes.md,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children:
                      imageUrls.asMap().entries.map((entry) {
                        return Container(
                          width: 8,
                          height: 8,
                          margin: EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                _currentImageIndex == entry.key
                                    ? DMColors.white
                                    : DMColors.white.withOpacity(0.5),
                          ),
                        );
                      }).toList(),
                ),
              ),

            // Badge de statut vendu
            if (product.isVendu)
              Positioned(
                top: DMSizes.md,
                right: DMSizes.md,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: DMSizes.sm,
                    vertical: DMSizes.xs,
                  ),
                  decoration: BoxDecoration(
                    color: DMColors.error,
                    borderRadius: BorderRadius.circular(DMSizes.borderRadiusMd),
                  ),
                  child: Text(
                    'VENDU',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: DMColors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildTitleAndPrice(Produit product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          product.nom,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: DMColors.textPrimary,
          ),
        ),
        SizedBox(height: DMSizes.xs),
        Text(
          '${product.prix.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} FCFA',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            color: DMColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusRow(Produit product) {
    return Row(
      children: [
        // Badge d'état
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: DMSizes.sm,
            vertical: DMSizes.xs,
          ),
          decoration: BoxDecoration(
            color: _getEtatColor(product.etat).withOpacity(0.1),
            borderRadius: BorderRadius.circular(DMSizes.borderRadiusMd),
          ),
          child: Text(
            product.etatText,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: _getEtatColor(product.etat),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox(width: DMSizes.sm),

        // Badge de disponibilité
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: DMSizes.sm,
            vertical: DMSizes.xs,
          ),
          decoration: BoxDecoration(
            color:
                product.isVendu
                    ? DMColors.error.withOpacity(0.1)
                    : DMColors.success.withOpacity(0.1),
            borderRadius: BorderRadius.circular(DMSizes.borderRadiusMd),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                product.isVendu ? Iconsax.close_circle : Iconsax.tick_circle,
                size: 16,
                color: product.isVendu ? DMColors.error : DMColors.success,
              ),
              SizedBox(width: DMSizes.xs / 2),
              Text(
                product.isVendu ? 'Vendu' : 'Disponible',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: product.isVendu ? DMColors.error : DMColors.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLocationSection(Produit product) {
    return FutureBuilder<Adresse?>(
      future: _firestoreService.getAdresseById(product.adresseId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Padding(
            padding: EdgeInsets.all(DMSizes.md),
            child: LinearProgressIndicator(),
          );
        }
        final adresse = snapshot.data;
        return Container(
          padding: EdgeInsets.all(DMSizes.md),
          decoration: BoxDecoration(
            color:
                Theme.of(context).brightness == Brightness.dark
                    ? DMColors.dark.withOpacity(0.3)
                    : DMColors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(DMSizes.borderRadiusMd),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Iconsax.location,
                    color: DMColors.primary,
                    size: DMSizes.iconMd,
                  ),
                  SizedBox(width: DMSizes.sm),
                  Text(
                    'Localisation',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: DMColors.textPrimary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: DMSizes.sm),

              if (adresse != null &&
                  (adresse.quartier != null || adresse.ville != null))
                Text(
                  '${adresse.quartier ?? ''} ${adresse.ville ?? ''}'.trim(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: DMColors.textSecondary,
                  ),
                ),

              if (adresse != null &&
                  adresse.ville != null &&
                  adresse.ville!.isNotEmpty)
                Row(
                  children: [
                    Icon(
                      Iconsax.buildings,
                      size: 16,
                      color: DMColors.textSecondary,
                    ),
                    SizedBox(width: DMSizes.xs),
                    Text(
                      adresse.ville!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: DMColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

              if (adresse != null &&
                  adresse.latitude != null &&
                  adresse.longitude != null)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _openInMaps(adresse),
                    icon: Icon(Iconsax.map, size: 16),
                    label: Text('Voir sur la carte'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: DMColors.primary,
                      side: BorderSide(color: DMColors.primary),
                      padding: EdgeInsets.symmetric(vertical: DMSizes.sm),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDescriptionSection(Produit product) {
    if (product.description == null || product.description!.isEmpty) {
      return SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: DMColors.textPrimary,
          ),
        ),
        SizedBox(height: DMSizes.sm),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(DMSizes.md),
          decoration: BoxDecoration(
            color:
                Theme.of(context).brightness == Brightness.dark
                    ? DMColors.dark.withOpacity(0.3)
                    : DMColors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(DMSizes.borderRadiusMd),
          ),
          child: Text(
            product.description!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: DMColors.textSecondary,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAdditionalInfo(Produit product) {
    return FutureBuilder<String?>(
      future: _CategoryService.getCategoryNameById(product.categorieId),
      builder: (context, snapshot) {
        final categoryName = snapshot.data ?? 'Non spécifié';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informations',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: DMColors.textPrimary,
              ),
            ),
            SizedBox(height: DMSizes.sm),
            Container(
              padding: EdgeInsets.all(DMSizes.md),
              decoration: BoxDecoration(
                color:
                    Theme.of(context).brightness == Brightness.dark
                        ? DMColors.dark.withOpacity(0.3)
                        : DMColors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(DMSizes.borderRadiusMd),
              ),
              child: Column(
                children: [
                  _buildInfoRow(
                    icon: Iconsax.category,
                    label: 'Catégorie',
                    value: categoryName,
                  ),
                  _buildInfoRow(
                    icon: Iconsax.calendar,
                    label: 'Publié le',
                    value: _formatDate(product.dateAjout),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: DMSizes.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: DMColors.textSecondary),
          SizedBox(width: DMSizes.sm),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: DMColors.textSecondary),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: DMColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOwnerActions(Produit product) {
    return Container(
      padding: EdgeInsets.all(DMSizes.md),
      decoration: BoxDecoration(
        color:
            Theme.of(context).brightness == Brightness.dark
                ? DMColors.dark.withOpacity(0.3)
                : DMColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(DMSizes.borderRadiusMd),
        border: Border.all(color: DMColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Actions',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: DMColors.textPrimary,
            ),
          ),
          SizedBox(height: DMSizes.sm),
          Row(
            children: [
              // Bouton Marquer vendu/disponible
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (product.isVendu) {
                      _showReactivateConfirmationDialog(product);
                    } else {
                      _showMarkAsSoldConfirmationDialog(product);
                    }
                  },
                  icon: Icon(
                    product.isVendu ? Iconsax.refresh : Iconsax.tick_circle,
                    size: 16,
                  ),
                  label: Text(product.isVendu ? 'Remettre' : 'Vendu'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        product.isVendu ? DMColors.info : DMColors.success,
                    foregroundColor: DMColors.white,
                    padding: EdgeInsets.symmetric(vertical: DMSizes.sm),
                  ),
                ),
              ),
              SizedBox(width: DMSizes.sm),

              // Bouton Supprimer
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showDeleteConfirmationDialog(product),
                  icon: Icon(Iconsax.trash, size: 16),
                  label: Text('Supprimer'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: DMColors.error,
                    side: BorderSide(color: DMColors.error),
                    padding: EdgeInsets.symmetric(vertical: DMSizes.sm),
                  ),
                ),
              ),
            ],
          ),
        ],
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return "Aujourd'hui";
    } else if (difference.inDays == 1) {
      return "Hier";
    } else if (difference.inDays < 7) {
      return "Il y a ${difference.inDays} jours";
    } else {
      return "${date.day}/${date.month}/${date.year}";
    }
  }

  void _openInMaps(Adresse adresse) async {
    String query = '${adresse.latitude},${adresse.longitude}';
    final googleMapsUrl = 'https://maps.google.com/maps?q=$query';
    final appleMapsUrl = 'https://maps.apple.com/?q=$query';

    try {
      if (await canLaunchUrl(Uri.parse(googleMapsUrl))) {
        await launchUrl(
          Uri.parse(googleMapsUrl),
          mode: LaunchMode.externalApplication,
        );
      } else if (await canLaunchUrl(Uri.parse(appleMapsUrl))) {
        await launchUrl(
          Uri.parse(appleMapsUrl),
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Impossible d\'ouvrir la carte'),
            backgroundColor: DMColors.error,
          ),
        );
      }
    }
  }

  void _showDeleteConfirmationDialog(Produit product) {
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
            Navigator.of(context).pop(); // Fermer le dialog
            Navigator.of(context).pop(); // Retourner à la liste
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Annonce "${product.nom}" supprimée avec succès.',
                ),
                backgroundColor: DMColors.success,
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erreur lors de la suppression: $e'),
                backgroundColor: DMColors.error,
              ),
            );
          }
        }
      },
      onTapCancel: () => Navigator.of(context).pop(),
      panaraDialogType: PanaraDialogType.custom,
      color: DMColors.error,
      barrierDismissible: false,
    );
  }

  void _showMarkAsSoldConfirmationDialog(Produit product) {
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
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Annonce "${product.nom}" marquée comme vendue.'),
                backgroundColor: DMColors.success,
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erreur lors de la mise à jour: $e'),
                backgroundColor: DMColors.error,
              ),
            );
          }
        }
      },
      onTapCancel: () => Navigator.of(context).pop(),
      panaraDialogType: PanaraDialogType.custom,
      color: DMColors.success,
      barrierDismissible: false,
    );
  }

  void _showReactivateConfirmationDialog(Produit product) {
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
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Annonce "${product.nom}" remise en vente.'),
                backgroundColor: DMColors.info,
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erreur lors de la mise à jour: $e'),
                backgroundColor: DMColors.error,
              ),
            );
          }
        }
      },
      onTapCancel: () => Navigator.of(context).pop(),
      panaraDialogType: PanaraDialogType.custom,
      color: DMColors.info,
      barrierDismissible: false,
    );
  }

  // Méthode pour partager le produit
  void _shareProduct(Produit product) async {
    try {
      final String shareText =
          '''
🛍️ ${product.nom}
💰 Prix: ${product.prix.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} FCFA
📍 Lieu:  'Non spécifié'}
🏷️ État: ${product.etatText}
${product.isVendu ? '❌ VENDU' : '✅ DISPONIBLE'}

${product.description ?? ''}

Voir plus de détails sur Kassoua
      '''.trim();

      // Copier dans le presse-papiers
      await Clipboard.setData(ClipboardData(text: shareText));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Iconsax.copy, color: DMColors.white, size: 16),
                SizedBox(width: DMSizes.xs),
                Text('Détails copiés dans le presse-papiers'),
              ],
            ),
            backgroundColor: DMColors.success,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du partage'),
            backgroundColor: DMColors.error,
          ),
        );
      }
    }
  }

  // Méthode pour contacter le vendeur
}
