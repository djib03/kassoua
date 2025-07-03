import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kassoua/models/product.dart';
import 'package:kassoua/views/screen/shop/image_viewer.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:kassoua/constants/colors.dart';
import 'package:kassoua/services/firestore_service.dart';
import 'package:kassoua/constants/size.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kassoua/models/adresse.dart';
import 'package:kassoua/models/user.dart';
import 'package:url_launcher/url_launcher.dart';

class ProductDetailAcheteur extends StatefulWidget {
  final Produit produit;
  final List<String> images;

  const ProductDetailAcheteur({
    super.key,
    required this.produit,
    required this.images,
  });

  @override
  _ProductDetailAcheteurState createState() => _ProductDetailAcheteurState();
}

class _ProductDetailAcheteurState extends State<ProductDetailAcheteur>
    with SingleTickerProviderStateMixin {
  PageController productImageSlider = PageController();
  final FirestoreService _firestoreService = FirestoreService();
  bool isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  Utilisateur? vendeur;

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
    _loadVendeurInfo();
    _incrementProductViews();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _loadVendeurInfo() async {
    try {
      final vendeurData = await _firestoreService.getUtilisateur(
        widget.produit.vendeurId,
      );
      if (mounted) {
        setState(() {
          vendeur = vendeurData;
        });
      }
    } catch (e) {
      print('Erreur lors du chargement des infos vendeur: $e');
    }
  }

  void _incrementProductViews() async {
    try {
      await _firestoreService.incrementProductViews(widget.produit.id);
    } catch (e) {
      print('Erreur lors de l\'incrémentation des vues: $e');
    }
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
                      case 'share':
                        _shareProduct();
                        break;
                      case 'report':
                        _reportProduct();
                        break;
                    }
                  },
                  itemBuilder:
                      (context) => [
                        PopupMenuItem(
                          value: 'share',
                          child: Row(
                            children: [
                              Icon(Icons.share_outlined, size: 20),
                              SizedBox(width: 12),
                              Text('Partager'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'report',
                          child: Row(
                            children: [
                              Icon(
                                Icons.flag_outlined,
                                size: 20,
                                color: Colors.orange,
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Signaler',
                                style: TextStyle(color: Colors.orange),
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

      // Bottom Navigation Bar pour acheteur
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
            // Bouton Appeler (si numéro disponible)
            if (vendeur?.telephone != null)
              Container(
                width: 60,
                height: 60,
                margin: EdgeInsets.only(right: 16),
                child: Material(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _callVendeur(),
                    child: Icon(Iconsax.call, color: Colors.green, size: 24),
                  ),
                ),
              ),

            // Bouton principal - Contacter le vendeur
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
                                : [Colors.grey, Colors.grey.withOpacity(0.8)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap:
                          produit.statut == 'disponible'
                              ? () => _contactVendeur()
                              : null,
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Iconsax.message,
                              color: Colors.white,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              produit.statut == 'disponible'
                                  ? 'Contacter le vendeur'
                                  : 'Produit vendu',
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
          // Badge de statut et stats
          Row(
            children: [
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
              Spacer(),
              _buildStatsChip(Icons.visibility, '${produit.vues ?? 0} vues'),
            ],
          ),

          SizedBox(height: 10),

          // Prix
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
                fontSize: 20,
                fontWeight: FontWeight.w700,
                fontFamily: 'poppins',
                color: AppColors.primary,
              ),
            ),
          ),
          SizedBox(height: 15),
          // Badge disponibilité
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatusBadge(produit),
              SizedBox(width: 4),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color:
                      produit.statut == 'Négociable'
                          ? AppColors.primary.withOpacity(0.15)
                          : Colors.grey.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      produit.estnegociable == true ? Iconsax.tag : Iconsax.tag,
                      color:
                          produit.estnegociable == true
                              ? AppColors.primary
                              : AppColors.darkGrey,
                      size: 16,
                    ),
                    SizedBox(width: 4),
                    Text(
                      produit.estnegociable == true
                          ? 'Négociable'
                          : 'Non Négociable',
                      style: TextStyle(
                        color:
                            produit.estnegociable == true
                                ? AppColors.primary
                                : AppColors.darkGrey,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 4),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color:
                      produit.isLivrable == true
                          ? AppColors.primary.withOpacity(0.15)
                          : Colors.grey.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Iconsax.truck,
                      color:
                          produit.isLivrable == true
                              ? AppColors.primary
                              : Colors.grey,
                      size: 16,
                    ),
                    SizedBox(width: 4),
                    Text(
                      produit.isLivrable == true
                          ? 'Livraison'
                          : 'Pas de livraison',
                      style: TextStyle(
                        color:
                            produit.isLivrable == true
                                ? AppColors.primary
                                : Colors.grey,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 24),

          _buildLocationSection(produit),

          SizedBox(height: 24),

          // Informations vendeur
          _buildVendeurSection(isDark),

          SizedBox(height: 24),

          // Card d'informations
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
          SizedBox(height: 15),
          Divider(
            height: 5,
            color:
                Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[800]
                    : Colors.grey[200],
            indent: 16,
            endIndent: 16,
          ),

          SizedBox(height: 10),

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

          SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildVendeurSection(bool isDark) {
    return Container(
      padding: EdgeInsets.only(top: 10, right: 20, bottom: 20, left: 20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vendeur',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              fontFamily: 'poppins',
              color: isDark ? Colors.white : AppColors.primary,
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                backgroundImage:
                    vendeur?.photoProfil != null
                        ? NetworkImage(vendeur!.photoProfil!)
                        : null,
                child:
                    vendeur?.photoProfil == null
                        ? Icon(Icons.person, color: AppColors.primary, size: 25)
                        : null,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${vendeur?.nom} ${vendeur?.prenom} ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    if (vendeur?.email != null)
                      Text(
                        vendeur!.email!,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                  ],
                ),
              ),
              if (vendeur?.telephone != null)
                IconButton(
                  onPressed: _callVendeur,
                  icon: Icon(Iconsax.call, color: Colors.green),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(Produit produit) {
    bool isAvailable = produit.statut == 'disponible';
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors:
              isAvailable
                  ? [AppColors.primary, AppColors.primary.withOpacity(0.8)]
                  : [Colors.grey, Colors.grey.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: (isAvailable ? Colors.green : Colors.red).withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isAvailable ? Icons.check : Icons.close,
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
                    textAlign: TextAlign.center,
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
                  '${adresse.quartier ?? ''} - ${adresse.ville} '.trim(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
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
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _shareProduct() {
    // Logique pour partager le produit
    _showSuccessSnackBar(
      'Fonctionnalité de partage bientôt disponible',
      Icons.share,
    );
  }

  void _reportProduct() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildReportBottomSheet(),
    );
  }

  Widget _buildReportBottomSheet() {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.dark : Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.flag_outlined,
                        color: Colors.orange,
                        size: 24,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Signaler cette annonce',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 20),

                Text(
                  'Pourquoi signalez-vous cette annonce ?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),

                SizedBox(height: 16),

                ..._buildReportOptions(),

                SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: Colors.grey),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Annuler',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _submitReport(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Signaler',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildReportOptions() {
    final options = [
      {'title': 'Contenu inapproprié', 'icon': Icons.warning_outlined},
      {'title': 'Arnaque ou fraude', 'icon': Icons.security_outlined},
      {'title': 'Produit contrefait', 'icon': Icons.verified_outlined},
      {'title': 'Prix abusif', 'icon': Icons.attach_money_outlined},
      {'title': 'Informations fausses', 'icon': Icons.info_outlined},
      {'title': 'Autre raison', 'icon': Icons.more_horiz_outlined},
    ];

    return options
        .map(
          (option) => Container(
            margin: EdgeInsets.only(bottom: 8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _selectReportReason(option['title'] as String),
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.withOpacity(0.2)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        option['icon'] as IconData,
                        color: Colors.orange,
                        size: 20,
                      ),
                      SizedBox(width: 12),
                      Text(
                        option['title'] as String,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color:
                              Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white
                                  : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        )
        .toList();
  }

  void _selectReportReason(String reason) {
    // Logique pour sélectionner la raison du signalement
    print('Raison sélectionnée: $reason');
  }

  void _submitReport() {
    Navigator.pop(context);
    _showSuccessSnackBar('Signalement envoyé avec succès', Icons.check_circle);
  }

  void _contactVendeur() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildContactBottomSheet(),
    );
  }

  Widget _buildContactBottomSheet() {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.dark : Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Iconsax.message,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Contacter le vendeur',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          Text(
                            'Choisissez votre moyen de contact',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 24),

                // Option WhatsApp
                if (vendeur?.telephone != null)
                  _buildContactOption(
                    'WhatsApp',
                    'Envoyer un message via WhatsApp',
                    Iconsax.message,
                    Colors.green,
                    () => _contactViaWhatsApp(),
                  ),

                SizedBox(height: 12),

                // Option Appel
                if (vendeur?.telephone != null)
                  _buildContactOption(
                    'Appeler',
                    'Appeler directement le vendeur',
                    Iconsax.call,
                    Colors.blue,
                    () => _callVendeur(),
                  ),

                SizedBox(height: 12),

                // Option Email
                if (vendeur?.email != null)
                  _buildContactOption(
                    'Email',
                    'Envoyer un email au vendeur',
                    Iconsax.sms,
                    Colors.orange,
                    () => _contactViaEmail(),
                  ),

                SizedBox(height: 20),

                Container(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: Colors.grey),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Annuler',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactOption(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color:
                            Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black87,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  void _contactViaWhatsApp() async {
    Navigator.pop(context);
    if (vendeur?.telephone != null) {
      final message = Uri.encodeComponent(
        'Bonjour, je suis intéressé(e) par votre produit "${widget.produit.nom}" sur Kassoua.',
      );
      final whatsappUrl = 'https://wa.me/${vendeur!.telephone}?text=$message';

      try {
        if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
          await launchUrl(
            Uri.parse(whatsappUrl),
            mode: LaunchMode.externalApplication,
          );
        } else {
          _showErrorSnackBar('WhatsApp n\'est pas installé');
        }
      } catch (e) {
        _showErrorSnackBar('Erreur lors de l\'ouverture de WhatsApp');
      }
    }
  }

  void _callVendeur() async {
    Navigator.pop(context);
    if (vendeur?.telephone != null) {
      final phoneUrl = 'tel:${vendeur!.telephone}';
      try {
        if (await canLaunchUrl(Uri.parse(phoneUrl))) {
          await launchUrl(
            Uri.parse(phoneUrl),
            mode: LaunchMode.externalApplication,
          );
        } else {
          _showErrorSnackBar('Impossible d\'effectuer l\'appel');
        }
      } catch (e) {
        _showErrorSnackBar('Erreur lors de l\'appel');
      }
    }
  }

  void _contactViaEmail() async {
    Navigator.pop(context);
    if (vendeur?.email != null) {
      final subject = Uri.encodeComponent(
        'Intérêt pour "${widget.produit.nom}"',
      );
      final body = Uri.encodeComponent(
        'Bonjour,\n\nJe suis intéressé(e) par votre produit "${widget.produit.nom}" publié sur Kassoua.\n\nCordialement.',
      );
      final emailUrl = 'mailto:${vendeur!.email}?subject=$subject&body=$body';

      try {
        if (await canLaunchUrl(Uri.parse(emailUrl))) {
          await launchUrl(
            Uri.parse(emailUrl),
            mode: LaunchMode.externalApplication,
          );
        } else {
          _showErrorSnackBar('Aucune application email trouvée');
        }
      } catch (e) {
        _showErrorSnackBar('Erreur lors de l\'ouverture de l\'email');
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
}
