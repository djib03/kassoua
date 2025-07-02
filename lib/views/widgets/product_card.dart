// =============================================
// WIDGET PRODUCTCARD OPTIMISÉ
// =============================================

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:kassoua/constants/colors.dart';
import 'package:kassoua/models/image_produit.dart';

class ProductCard extends StatefulWidget {
  final Map<String, dynamic> product;
  final bool isDark;
  final bool isFavorite;
  final bool isProcessing; // 🔧 NOUVEAU: État de traitement
  final VoidCallback onToggleFavorite;

  const ProductCard({
    Key? key,
    required this.product,
    required this.isDark,
    required this.isFavorite,
    required this.onToggleFavorite,
    this.isProcessing = false, // 🔧 NOUVEAU: Par défaut false
  }) : super(key: key);

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard>
    with TickerProviderStateMixin {
  // 🔧 NOUVEAU: Contrôleurs d'animation
  late AnimationController _favoriteController;
  late AnimationController _pulseController;
  late Animation<double> _favoriteScaleAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<Color?> _favoriteColorAnimation;

  // 🔧 NOUVEAU: Cache local de l'image
  String? _cachedImageUrl;
  bool _imageLoaded = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadImage();
  }

  void _initializeAnimations() {
    // Animation du bouton favori
    _favoriteController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Animation de pulsation
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _favoriteScaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _favoriteController, curve: Curves.elasticOut),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _favoriteColorAnimation = ColorTween(
      begin: Colors.grey[400],
      end: Colors.red,
    ).animate(_favoriteController);
  }

  void _loadImage() {
    final images = widget.product['images'] as ImageProduit?;
    if (images?.url != null && images!.url.isNotEmpty) {
      _cachedImageUrl = images.url;
      setState(() {
        _imageLoaded = true;
      });
    }
  }

  @override
  void didUpdateWidget(ProductCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 🔧 Mettre à jour les animations selon l'état
    if (widget.isFavorite != oldWidget.isFavorite) {
      if (widget.isFavorite) {
        _favoriteController.forward();
      } else {
        _favoriteController.reverse();
      }
    }

    // 🔧 Animation de pulsation pendant le traitement
    if (widget.isProcessing != oldWidget.isProcessing) {
      if (widget.isProcessing) {
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController.stop();
        _pulseController.reset();
      }
    }

    // Recharger l'image si nécessaire
    if (widget.product['images'] != oldWidget.product['images']) {
      _loadImage();
    }
  }

  @override
  void dispose() {
    _favoriteController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // 🔧 OPTIMISÉ: Gestionnaire de tap avec animation
  Future<void> _handleFavoriteToggle() async {
    if (widget.isProcessing) return;

    // Animation immédiate
    _favoriteController.forward().then((_) {
      if (mounted) {
        _favoriteController.reverse();
      }
    });

    // Déclencher l'action
    widget.onToggleFavorite();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _pulseAnimation,
      child: Container(
        decoration: BoxDecoration(
          color: widget.isDark ? Colors.grey[850] : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color:
                  widget.isDark
                      ? Colors.black.withOpacity(0.3)
                      : Colors.grey.withOpacity(0.1),
              spreadRadius: 0,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔧 OPTIMISÉ: Section image avec cache
            _buildImageSection(),

            // 🔧 Section informations
            _buildInfoSection(),
          ],
        ),
      ),
    );
  }

  // 🔧 NOUVEAU: Section image optimisée
  Widget _buildImageSection() {
    return Expanded(
      flex: 3,
      child: Stack(
        children: [
          // Image principale
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              color: widget.isDark ? Colors.grey[800] : Colors.grey[100],
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: _buildImage(),
            ),
          ),

          // 🔧 OPTIMISÉ: Bouton favori avec animation
          Positioned(top: 8, right: 8, child: _buildAnimatedFavoriteButton()),

          // 🔧 NOUVEAU: Indicateur de traitement
          if (widget.isProcessing)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 2,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // 🔧 OPTIMISÉ: Image avec cache amélioré
  Widget _buildImage() {
    if (!_imageLoaded || _cachedImageUrl == null) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: widget.isDark ? Colors.grey[800] : Colors.grey[200],
        child: Icon(
          Icons.image_outlined,
          color: widget.isDark ? Colors.grey[600] : Colors.grey[400],
          size: 32,
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: _cachedImageUrl!,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      placeholder:
          (context, url) => Container(
            color: widget.isDark ? Colors.grey[800] : Colors.grey[200],
            child: Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 2,
              ),
            ),
          ),
      errorWidget:
          (context, url, error) => Container(
            color: widget.isDark ? Colors.grey[800] : Colors.grey[200],
            child: Icon(
              Icons.image_not_supported_outlined,
              color: widget.isDark ? Colors.grey[600] : Colors.grey[400],
              size: 32,
            ),
          ),
      // 🔧 Cache optimisé
      memCacheWidth: 300,
      memCacheHeight: 300,
      maxWidthDiskCache: 600,
      maxHeightDiskCache: 600,
    );
  }

  // 🔧 NOUVEAU: Bouton favori animé
  Widget _buildAnimatedFavoriteButton() {
    return ScaleTransition(
      scale: _favoriteScaleAnimation,
      child: GestureDetector(
        onTap: _handleFavoriteToggle,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            // ignore: deprecated_member_use
            color: Colors.white.withOpacity(0.9),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                // ignore: deprecated_member_use
                color: Colors.black.withOpacity(0.1),
                spreadRadius: 0,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: AnimatedBuilder(
            animation: _favoriteColorAnimation,
            builder: (context, child) {
              return Icon(
                widget.isFavorite ? Icons.favorite : Icons.favorite_border,
                color:
                    widget.isFavorite
                        ? Colors.red
                        : _favoriteColorAnimation.value ?? Colors.grey[400],
                size: 18,
              );
            },
          ),
        ),
      ),
    );
  }

  // 🔧 Section informations du produit
  Widget _buildInfoSection() {
    return Expanded(
      flex: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Nom du produit
            Text(
              widget.product['name'] ?? 'Produit sans nom',
              style: TextStyle(
                color: widget.isDark ? AppColors.textWhite : AppColors.black,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            // Prix
            Text(
              '${widget.product['price']} FCFA',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 4),

            // Localisation
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  color: widget.isDark ? Colors.grey[400] : Colors.grey[600],
                  size: 12,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    widget.product['location'] ?? 'Non spécifié',
                    style: TextStyle(
                      color:
                          widget.isDark ? Colors.grey[400] : Colors.grey[600],
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            // const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
