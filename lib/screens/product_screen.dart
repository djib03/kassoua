import 'package:flutter/material.dart';
import 'package:kassoua/constants/colors.dart';
import 'package:kassoua/constants/size.dart';

// Modèle de données simple pour le produit
class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final int quantity;
  final String imageUrl;
  final String sellerId;
  final String sellerName;
  final String? sellerProfileImageUrl;
  final double? rating; // Nouvelle propriété pour la note
  final int? reviewCount; // Nouvelle propriété pour le nombre d'avis

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.quantity,
    required this.imageUrl,
    required this.sellerId,
    required this.sellerName,
    this.sellerProfileImageUrl,
    this.rating,
    this.reviewCount,
  });
}

class ProductDetailPage extends StatefulWidget {
  final Product product;

  const ProductDetailPage({Key? key, required this.product}) : super(key: key);

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool isFavorite = false;
  int selectedQuantity = 1;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
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
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar avec image en arrière-plan
          SliverAppBar(
            expandedHeight: 350,
            pinned: true,
            backgroundColor: DMColors.primary,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: DMColors.primary),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? Colors.red : DMColors.primary,
                  ),
                  onPressed: () {
                    setState(() {
                      isFavorite = !isFavorite;
                    });
                  },
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'product_image_${widget.product.id}',
                child: Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(widget.product.imageUrl),
                      fit: BoxFit.cover,
                      onError: (exception, stackTrace) {
                        print('Error loading image: $exception');
                      },
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
              ),
            ),
          ),

          // Contenu principal
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section principale du produit
                    _buildProductHeader(),

                    // Divider avec style
                    Container(
                      margin: EdgeInsets.symmetric(
                        horizontal: DMSizes.defaultSpace,
                        vertical: DMSizes.md,
                      ),
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            DMColors.grey.withOpacity(0.3),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),

                    // Sélecteur de quantité
                    _buildQuantitySelector(),

                    SizedBox(height: DMSizes.spaceBtwSections),

                    // Description
                    _buildDescription(),

                    SizedBox(height: DMSizes.spaceBtwSections),

                    // Informations vendeur
                    _buildSellerInfo(),

                    // Espace pour le bouton flottant
                    SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),

      // Actions flottantes
      floatingActionButton: _buildFloatingActions(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildProductHeader() {
    return Padding(
      padding: EdgeInsets.all(DMSizes.defaultSpace),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nom du produit
          Text(
            widget.product.name,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: DMColors.textPrimary,
              height: 1.2,
            ),
          ),

          SizedBox(height: DMSizes.sm),

          // Rating et reviews (si disponibles)
          if (widget.product.rating != null)
            Row(
              children: [
                ...List.generate(
                  5,
                  (index) => Icon(
                    index < (widget.product.rating ?? 0).round()
                        ? Icons.star
                        : Icons.star_border,
                    color: Colors.amber,
                    size: 20,
                  ),
                ),
                SizedBox(width: DMSizes.sm),
                Text(
                  '${widget.product.rating?.toStringAsFixed(1)} (${widget.product.reviewCount ?? 0} avis)',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: DMColors.textSecondary,
                  ),
                ),
              ],
            ),

          SizedBox(height: DMSizes.md),

          // Prix avec design amélioré
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: DMSizes.md,
              vertical: DMSizes.sm,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  DMColors.primary.withOpacity(0.1),
                  DMColors.primary.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: DMColors.primary.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.local_offer,
                  color: DMColors.primary,
                  size: DMSizes.iconMd,
                ),
                SizedBox(width: DMSizes.sm),
                Text(
                  '${widget.product.price.toStringAsFixed(0)} FCFA',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: DMColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: DMSizes.md),

          // Statut de disponibilité
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: DMSizes.sm,
              vertical: DMSizes.xs,
            ),
            decoration: BoxDecoration(
              color:
                  widget.product.quantity > 0
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.product.quantity > 0
                      ? Icons.check_circle
                      : Icons.error,
                  color:
                      widget.product.quantity > 0 ? Colors.green : Colors.red,
                  size: 16,
                ),
                SizedBox(width: DMSizes.xs),
                Text(
                  widget.product.quantity > 0
                      ? 'En stock (${widget.product.quantity} disponibles)'
                      : 'Rupture de stock',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color:
                        widget.product.quantity > 0
                            ? Colors.green[700]
                            : Colors.red[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantitySelector() {
    if (widget.product.quantity <= 0) return const SizedBox();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: DMSizes.defaultSpace),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quantité',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: DMColors.textPrimary,
            ),
          ),
          SizedBox(height: DMSizes.sm),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: DMColors.grey.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed:
                      selectedQuantity > 1
                          ? () => setState(() => selectedQuantity--)
                          : null,
                  icon: const Icon(Icons.remove),
                  color: DMColors.primary,
                ),
                Container(
                  width: 50,
                  alignment: Alignment.center,
                  child: Text(
                    '$selectedQuantity',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed:
                      selectedQuantity < widget.product.quantity
                          ? () => setState(() => selectedQuantity++)
                          : null,
                  icon: const Icon(Icons.add),
                  color: DMColors.primary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescription() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: DMSizes.defaultSpace),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Description',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: DMColors.textPrimary,
            ),
          ),
          SizedBox(height: DMSizes.sm),
          Container(
            padding: EdgeInsets.all(DMSizes.md),
            decoration: BoxDecoration(
              color: DMColors.lightGrey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              widget.product.description,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: DMColors.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSellerInfo() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: DMSizes.defaultSpace),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vendeur',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: DMColors.textPrimary,
            ),
          ),
          SizedBox(height: DMSizes.sm),
          Container(
            padding: EdgeInsets.all(DMSizes.md),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    gradient: LinearGradient(
                      colors: [
                        DMColors.primary.withOpacity(0.8),
                        DMColors.primary,
                      ],
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 30,
                    backgroundImage:
                        widget.product.sellerProfileImageUrl != null &&
                                widget.product.sellerProfileImageUrl!.isNotEmpty
                            ? NetworkImage(
                              widget.product.sellerProfileImageUrl!,
                            )
                            : null,
                    backgroundColor: Colors.transparent,
                    child:
                        widget.product.sellerProfileImageUrl == null ||
                                widget.product.sellerProfileImageUrl!.isEmpty
                            ? const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 30,
                            )
                            : null,
                  ),
                ),
                SizedBox(width: DMSizes.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.product.sellerName,
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: DMColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: DMSizes.xs),
                      Text(
                        'Vendeur vérifié',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.green[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    // Voir le profil du vendeur
                  },
                  icon: const Icon(
                    Icons.arrow_forward_ios,
                    color: DMColors.primary,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActions() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: DMSizes.defaultSpace),
      child: Row(
        children: [
          // Bouton de chat
          Expanded(
            flex: 2,
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [DMColors.primary, DMColors.primary.withOpacity(0.8)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: DMColors.primary.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed:
                    widget.product.quantity > 0
                        ? () {
                          // Logique pour contacter le vendeur
                          String currentUserId = 'mock_buyer_id_123';
                          String conversationId =
                              'mock_conv_id_${widget.product.id}_${widget.product.sellerId}_$currentUserId';

                          // Navigation vers le chat
                        }
                        : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(
                  Icons.chat_bubble_outline,
                  color: Colors.white,
                  size: 20,
                ),
                label: Text(
                  'Contacter',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

          SizedBox(width: DMSizes.sm),

          // Bouton d'achat rapide
          Container(
            height: 56,
            width: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: DMColors.primary.withOpacity(0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
