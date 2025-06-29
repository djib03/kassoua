import 'package:flutter/material.dart';
import 'package:kassoua/models/product.dart';
import 'package:kassoua/views/screen/shop/image_viewer.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:kassoua/constants/colors.dart';
import 'package:kassoua/services/firestore_service.dart';
import 'package:kassoua/constants/size.dart';
import 'package:iconsax/iconsax.dart';
import 'add_edit_product_page.dart';
import 'package:kassoua/models/adresse.dart';
import 'package:url_launcher/url_launcher.dart';

class ProductDetailVendeur extends StatefulWidget {
  final Produit produit;
  final List<String> images;

  const ProductDetailVendeur({
    super.key,
    required this.produit,
    required this.images,
  });

  @override
  // ignore: library_private_types_in_public_api
  _ProductDetailVendeurState createState() => _ProductDetailVendeurState();
}

class _ProductDetailVendeurState extends State<ProductDetailVendeur>
    with SingleTickerProviderStateMixin {
  PageController productImageSlider = PageController();
  final FirestoreService _firestoreService = FirestoreService();
  bool isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Produit produit = widget.produit;
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.black : Colors.grey[50],
      body: CustomScrollView(
        physics: BouncingScrollPhysics(),
        slivers: [
          // AppBar avec effet de transparence
          SliverAppBar(
            expandedHeight: 320,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: isDark ? AppColors.black : Colors.white,
            leading: Container(
              margin: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            actions: [
              Container(
                margin: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: Colors.white),
                  color: isDark ? AppColors.dark : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        // Navigation vers la page d'édition
                        break;
                      case 'delete':
                        _showDeleteConfirmation();
                        break;
                    }
                  },
                  itemBuilder:
                      (context) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined, size: 20),
                              SizedBox(width: 12),
                              Text('Modifier'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline,
                                size: 20,
                                color: Colors.red,
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Supprimer',
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ],
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'product_${produit.id}',
                child: _buildImageCarousel(),
              ),
            ),
          ),

          // Contenu principal
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: _buildProductContent(produit, isDark),
            ),
          ),
        ],
      ),

      // Bottom Navigation Bar améliorée
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 15),
        decoration: BoxDecoration(
          color: isDark ? AppColors.dark : Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          children: [
            // Bouton Modifier avec animation
            Container(
              width: 60,
              height: 60,
              margin: EdgeInsets.only(right: 16),
              child: Material(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    // Navigation vers la page d'édition
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => AddEditProductPage(
                              productId: widget.produit.id,
                            ),
                      ),
                    );
                  },
                  child: Icon(Iconsax.edit, color: AppColors.primary, size: 24),
                ),
              ),
            ),

            // Bouton principal avec gradient
            Expanded(
              child: SizedBox(
                height: 60,
                child: Material(
                  borderRadius: BorderRadius.circular(16),
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors:
                            produit.statut == 'disponible'
                                ? [
                                  AppColors.primary,
                                  AppColors.primary.withOpacity(0.8),
                                ]
                                : [AppColors.primary, AppColors.primary],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap:
                          isLoading
                              ? null
                              : () {
                                if (widget.produit.statut == 'disponible') {
                                  _showMarkAsSoldConfirmationDialog(
                                    widget.produit,
                                  );
                                } else {
                                  _toggleProductStatus();
                                }
                              },
                      child: Center(
                        child:
                            isLoading
                                ? SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                                : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      produit.statut == 'disponible'
                                          ? Icons.check_circle_outline
                                          : Icons.refresh,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      produit.statut == 'disponible'
                                          ? 'Marquer comme vendu'
                                          : 'Remettre en vente',
                                      style: TextStyle(
                                        fontFamily: 'poppins',
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCarousel() {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ImageViewer(imageUrl: widget.images),
          ),
        );
      },
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Container(
            width: double.infinity,
            height: 320,
            child:
                widget.images.isNotEmpty
                    ? PageView.builder(
                      physics: BouncingScrollPhysics(),
                      controller: productImageSlider,
                      itemCount: widget.images.length,
                      itemBuilder:
                          (context, index) => Container(
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: NetworkImage(widget.images[index]),
                                fit: BoxFit.cover,
                                onError: (error, stackTrace) {},
                              ),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.3),
                                  ],
                                ),
                              ),
                            ),
                          ),
                    )
                    : Container(
                      color: Colors.grey[300],
                      child: Icon(
                        Icons.image_not_supported,
                        size: 60,
                        color: Colors.grey[600],
                      ),
                    ),
          ),

          // Indicateur de pages amélioré
          if (widget.images.length > 1)
            Positioned(
              bottom: 20,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: SmoothPageIndicator(
                  controller: productImageSlider,
                  count: widget.images.length,
                  effect: ExpandingDotsEffect(
                    dotColor: Colors.white.withOpacity(0.5),
                    activeDotColor: Colors.white,
                    dotHeight: 8,
                    dotWidth: 8,
                    expansionFactor: 2,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProductContent(Produit produit, bool isDark) {
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge de statut amélioré
          Row(
            children: [
              _buildStatusBadge(produit),
              Spacer(),
              _buildStatsChip(Icons.visibility, '${produit.vues ?? 0} vues'),
            ],
          ),

          SizedBox(height: 20),

          // Nom du produit avec animation
          Text(
            produit.nom,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              fontFamily: 'poppins',
              color: isDark ? Colors.white : AppColors.primary,
              height: 1.2,
            ),
          ),

          SizedBox(height: 12),

          // Prix avec effet visuel
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.1),
                  AppColors.primary.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Text(
              '${produit.prix.toStringAsFixed(0)} FCFA',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                fontFamily: 'poppins',
                color: AppColors.primary,
              ),
            ),
          ),

          SizedBox(height: 24),
          _buildLocationSection(produit),

          // Card d'informations avec design moderne
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.dark : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildInfoRow(
                  Icons.calendar_today_outlined,
                  'Ajouté le',
                  _formatDate(produit.dateAjout),
                  isDark,
                ),
                SizedBox(height: 16),
                _buildInfoRow(
                  Icons.info_outline,
                  'État',
                  produit.etatText,
                  isDark,
                ),
              ],
            ),
          ),

          SizedBox(height: 24),

          // Section Description
          Text(
            'Description',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              fontFamily: 'poppins',
              color: isDark ? Colors.white : AppColors.primary,
            ),
          ),

          SizedBox(height: 12),

          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.dark : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Text(
              produit.description.isNotEmpty
                  ? produit.description
                  : 'Aucune description disponible.',
              style: TextStyle(
                height: 1.6,
                fontSize: 16,
                color: isDark ? Colors.grey[300] : Colors.grey[700],
              ),
            ),
          ),

          SizedBox(height: 20), // Espace pour le bottom bar
        ],
      ),
    );
  }

  Widget _buildStatusBadge(Produit produit) {
    bool isAvailable = produit.statut == 'disponible';
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors:
              isAvailable
                  ? [Colors.green, Colors.green.withOpacity(0.8)]
                  : [Colors.orange, Colors.orange.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isAvailable ? Colors.green : Colors.orange).withOpacity(
              0.3,
            ),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isAvailable ? Icons.check_circle : Icons.sell,
            size: 16,
            color: Colors.white,
          ),
          SizedBox(width: 6),
          Text(
            isAvailable ? 'Disponible' : 'Vendu',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsChip(IconData icon, String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, bool isDark) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: AppColors.primary),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }

  void _showDeleteConfirmation() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          margin: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color:
                Theme.of(context).brightness == Brightness.dark
                    ? AppColors.dark
                    : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: Offset(0, -5),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  margin: EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Icône
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.delete_forever_outlined,
                    color: Colors.red,
                    size: 40,
                  ),
                ),

                SizedBox(height: 24),

                // Titre
                Text(
                  'Supprimer l\'annonce',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'poppins',
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 12),

                // Description
                Text(
                  'Êtes-vous sûr de vouloir supprimer cette annonce ?\n\nCette action est définitive et ne peut pas être annulée.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 32),

                // Boutons
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.grey[100],
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Annuler',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _deleteProduct();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
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

                // Espace pour éviter le clavier
                SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
              ],
            ),
          ),
        );
      },
    );
  }

  void _deleteProduct() async {
    try {
      await _firestoreService.deleteProduct(widget.produit.id);
      _showSuccessSnackBar('Produit supprimé avec succès', Icons.check_circle);
      Navigator.of(context).pop();
    } catch (e) {
      _showErrorSnackBar('Erreur lors de la suppression du produit');
    }
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
                    ? AppColors.dark.withOpacity(0.3)
                    : AppColors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(DMSizes.borderRadiusMd),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Iconsax.location,
                    color: AppColors.primary,
                    size: DMSizes.iconMd,
                  ),
                  SizedBox(width: DMSizes.sm),
                  Text(
                    'Localisation',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color:
                          Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black,
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
                    color: AppColors.textSecondary,
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
                      color: AppColors.textSecondary,
                    ),
                    SizedBox(width: DMSizes.xs),
                    Text(
                      adresse.ville!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

              if (adresse != null)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _openInMaps(adresse),
                    icon: Icon(Iconsax.map, size: 16),
                    label: Text('Voir sur la carte'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(color: AppColors.primary),
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
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showSuccessSnackBar(String message, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(16),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(16),
      ),
    );
  }

  void _showMarkAsSoldConfirmationDialog(Produit product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          margin: EdgeInsets.all(DMSizes.lg),
          decoration: BoxDecoration(
            color:
                Theme.of(context).brightness == Brightness.dark
                    ? AppColors.dark
                    : AppColors.white,
            borderRadius: BorderRadius.circular(DMSizes.borderRadiusLg),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: EdgeInsets.only(top: DMSizes.sm),
                decoration: BoxDecoration(
                  color: AppColors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              Padding(
                padding: EdgeInsets.all(DMSizes.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icône et titre
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(DMSizes.sm),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(
                              DMSizes.borderRadiusSm,
                            ),
                          ),
                          child: Icon(
                            Iconsax.tick_circle,
                            color: AppColors.success,
                            size: 24,
                          ),
                        ),
                        SizedBox(width: DMSizes.md),
                        Expanded(
                          child: Text(
                            'Marquer comme vendu',
                            style: Theme.of(
                              context,
                            ).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: DMSizes.md),

                    // Message
                    Text(
                      'Êtes-vous sûr de vouloir marquer l\'annonce "${product.nom}" comme vendue ?',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),

                    SizedBox(height: DMSizes.lg),

                    // Boutons d'action
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                vertical: DMSizes.md,
                              ),
                              side: BorderSide(color: AppColors.grey),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  DMSizes.borderRadiusMd,
                                ),
                              ),
                            ),
                            child: Text(
                              'Annuler',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: DMSizes.md),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _confirmMarkAsSold(product),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                vertical: DMSizes.md,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  DMSizes.borderRadiusMd,
                                ),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              'Marquer comme vendu',
                              style: TextStyle(fontWeight: FontWeight.w600),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Espace pour éviter le clavier
                    SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Méthode pour confirmer et marquer comme vendu
  Future<void> _confirmMarkAsSold(Produit product) async {
    // Ferme le bottom sheet
    Navigator.of(context).pop();

    // Met à jour l'état local
    setState(() {
      isLoading = true;
    });

    try {
      await _firestoreService.markProductAsSold(product.id);

      if (mounted) {
        // Ferme le loading dialog
        Navigator.of(context).pop();

        // Affiche la confirmation de succès
        _showSuccessSnackBar(
          'Annonce "${product.nom}" marquée comme vendue',
          Iconsax.tick_circle,
        );

        // Retourne à la page précédente après un délai
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            Navigator.of(context).pop();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        // Ferme le loading dialog
        Navigator.of(context).pop();
        _showErrorSnackBar('Erreur lors de la mise à jour: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // Version simplifiée et unifiée de _toggleProductStatus
  void _toggleProductStatus() async {
    if (widget.produit.statut == 'disponible') {
      // Pour les produits disponibles, affiche le dialog de confirmation
      _showMarkAsSoldConfirmationDialog(widget.produit);
    } else {
      // Pour les produits vendus, reactive directement
      await _reactivateProduct();
    }
  }

  // Méthode pour réactiver un produit
  Future<void> _reactivateProduct() async {
    setState(() {
      isLoading = true;
    });

    try {
      await _firestoreService.reactivateProduct(widget.produit.id);
      _showSuccessSnackBar('Produit remis en vente', Icons.refresh);

      // Retourne à la page précédente
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          Navigator.of(context).pop();
        }
      });
    } catch (e) {
      _showErrorSnackBar('Erreur lors de la réactivation');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }
}
