import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kassoua/models/product.dart';
import 'package:kassoua/views/screen/shop/image_viewer.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:kassoua/constants/colors.dart';
import 'package:kassoua/constants/size.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kassoua/models/adresse.dart';
import 'package:kassoua/models/user.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:kassoua/services/firestore_service.dart';
import 'package:kassoua/services/favori_service.dart';
import 'package:kassoua/models/image_produit.dart';

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
  final favoriService _favoriService = favoriService();
  bool isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  Utilisateur? vendeur;
  Adresse? _adresse;
  bool _isLoadingLocation = false;
  bool _locationLoaded = false;

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
    _loadLocationOnce(); // Charger la localisation une seule fois
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Nouvelle méthode pour charger la localisation une seule fois
  void _loadLocationOnce() async {
    if (_locationLoaded) return; // Si déjà chargé, ne pas recharger

    setState(() {
      _isLoadingLocation = true;
    });

    try {
      final adresse = await _firestoreService.getAdresseById(
        widget.produit.adresseId,
      );
      if (mounted) {
        setState(() {
          _adresse = adresse;
          _isLoadingLocation = false;
          _locationLoaded = true; // Marquer comme chargé
        });
      }
    } catch (e) {
      print('Erreur lors du chargement de l\'adresse: $e');
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
          _locationLoaded =
              true; // Même en cas d'erreur, éviter les rechargements
        });
      }
    }
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
              margin: EdgeInsets.all(6),
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

      // Bottom Navigation Bar pour contact WhatsApp/SMS
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
            // Bouton Appeler
            if (vendeur?.telephone != null)
              Container(
                width: 60,
                height: 60,
                margin: EdgeInsets.only(right: 12),
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

            // Bouton SMS
            if (vendeur?.telephone != null)
              Container(
                width: 60,
                height: 60,
                margin: EdgeInsets.only(right: 12),
                child: Material(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _sendSMS(),
                    child: Icon(Iconsax.message, color: Colors.blue, size: 24),
                  ),
                ),
              ),

            // Bouton principal - WhatsApp
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
                                  Color(0xFF25D366), // Couleur WhatsApp
                                  Color(0xFF25D366).withOpacity(0.8),
                                ]
                                : [Colors.grey, Colors.grey.withOpacity(0.8)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap:
                          produit.statut == 'disponible'
                              ? () => _contactViaWhatsApp()
                              : null,
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.message, color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text(
                              produit.statut == 'disponible'
                                  ? 'Contacter via WhatsApp'
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
      padding: EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge de statut et stats
          Row(
            children: [
              Text(
                produit.nom,
                style: TextStyle(
                  fontSize: 20,
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
              SizedBox(width: 3),
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
                    SizedBox(width: 3),
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
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 3),
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
                        fontSize: 10,
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
              // Boutons de contact rapide
              Row(
                children: [
                  if (vendeur?.telephone != null) ...[
                    IconButton(
                      onPressed: _callVendeur,
                      icon: Icon(Iconsax.call, color: Colors.green),
                      tooltip: 'Appeler',
                    ),
                    IconButton(
                      onPressed: _sendSMS,
                      icon: Icon(Iconsax.message, color: Colors.blue),
                      tooltip: 'SMS',
                    ),
                    IconButton(
                      onPressed: _contactViaWhatsApp,
                      icon: Icon(Icons.message, color: Color(0xFF25D366)),
                      tooltip: 'WhatsApp',
                    ),
                  ],
                ],
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
            color: (isAvailable ? AppColors.primary : Colors.grey).withOpacity(
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
              fontSize: 10,
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

          // Affichage conditionnel basé sur l'état de chargement
          if (_isLoadingLocation)
            Padding(
              padding: EdgeInsets.symmetric(vertical: DMSizes.sm),
              child: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Chargement de la localisation...',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          else if (_adresse != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_adresse!.quartier != null || _adresse!.ville != null)
                  Text(
                    '${_adresse!.quartier ?? ''} - ${_adresse!.ville} '.trim(),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                SizedBox(height: DMSizes.sm),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _openInMaps(_adresse!),
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
            )
          else
            Padding(
              padding: EdgeInsets.symmetric(vertical: DMSizes.sm),
              child: Row(
                children: [
                  Icon(Icons.location_off, color: Colors.grey[400], size: 16),
                  SizedBox(width: 8),
                  Text(
                    'Localisation non disponible',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // Méthode pour forcer le rechargement si nécessaire
  void _refreshLocation() {
    setState(() {
      _locationLoaded = false;
      _adresse = null;
    });
    _loadLocationOnce();
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
                Text(
                  'Signaler ce produit',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Aidez-nous à maintenir la qualité de notre plateforme',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                SizedBox(height: 20),
                _buildReportOption(
                  icon: Icons.description_outlined,
                  title: 'Description inappropriée',
                  subtitle: 'Contenu offensant ou trompeur',
                  onTap: () => _submitReport('description'),
                ),
                _buildReportOption(
                  icon: Icons.image_not_supported_outlined,
                  title: 'Images inappropriées',
                  subtitle: 'Photos non conformes ou trompeuses',
                  onTap: () => _submitReport('images'),
                ),
                _buildReportOption(
                  icon: Icons.attach_money_outlined,
                  title: 'Prix suspect',
                  subtitle: 'Prix anormalement bas ou élevé',
                  onTap: () => _submitReport('prix'),
                ),
                _buildReportOption(
                  icon: Icons.report_outlined,
                  title: 'Contenu frauduleux',
                  subtitle: 'Produit contrefait ou arnaque',
                  onTap: () => _submitReport('fraude'),
                ),
                SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Annuler',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.black : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: Colors.orange),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
        onTap: onTap,
      ),
    );
  }

  void _submitReport(String reason) {
    Navigator.pop(context);
    _showSuccessSnackBar(
      'Signalement envoyé. Merci de nous aider à améliorer la plateforme.',
      Icons.check_circle,
    );
  }

  void _callVendeur() async {
    if (vendeur?.telephone != null) {
      final phoneNumber = vendeur!.telephone!;
      final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);

      try {
        if (await canLaunchUrl(phoneUri)) {
          await launchUrl(phoneUri);
        } else {
          _showErrorSnackBar('Impossible d\'ouvrir l\'application téléphone');
        }
      } catch (e) {
        _showErrorSnackBar('Erreur lors de l\'appel');
      }
    }
  }

  void _sendSMS() async {
    if (vendeur?.telephone != null) {
      final phoneNumber = vendeur!.telephone!;
      final message =
          'Bonjour, je suis intéressé par votre produit "${widget.produit.nom}" sur Kassoua.';
      final Uri smsUri = Uri(
        scheme: 'sms',
        path: phoneNumber,
        queryParameters: {'body': message},
      );

      try {
        if (await canLaunchUrl(smsUri)) {
          await launchUrl(smsUri);
        } else {
          _showErrorSnackBar('Impossible d\'ouvrir l\'application SMS');
        }
      } catch (e) {
        _showErrorSnackBar('Erreur lors de l\'envoi du SMS');
      }
    }
  }

  void _contactViaWhatsApp() async {
    if (vendeur?.telephone != null) {
      final phoneNumber = vendeur!.telephone!.replaceAll(RegExp(r'[^\d+]'), '');
      final message =
          'Bonjour, je suis intéressé par votre produit "${widget.produit.nom}" sur Kassoua. Prix: ${widget.produit.prix.toStringAsFixed(0)} FCFA';
      final encodedMessage = Uri.encodeComponent(message);
      final whatsappUrl = 'https://wa.me/$phoneNumber?text=$encodedMessage';

      try {
        if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
          await launchUrl(
            Uri.parse(whatsappUrl),
            mode: LaunchMode.externalApplication,
          );
        } else {
          _showErrorSnackBar('WhatsApp n\'est pas installé sur votre appareil');
        }
      } catch (e) {
        _showErrorSnackBar('Erreur lors de l\'ouverture de WhatsApp');
      }
    }
  }

  void _showSuccessSnackBar(String message, IconData icon) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: EdgeInsets.all(16),
        ),
      );
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: EdgeInsets.all(16),
        ),
      );
    }
  }
}
