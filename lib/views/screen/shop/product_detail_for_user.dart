// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:kassoua/constants/colors.dart';
// import 'package:kassoua/constants/size.dart';
// import 'package:kassoua/services/firestore_service.dart';
// import 'package:kassoua/models/product.dart';
// import 'package:kassoua/models/image_produit.dart';
// import 'package:kassoua/models/adresse.dart';
// import 'package:kassoua/views/screen/shop/add_edit_product_page.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:iconsax/iconsax.dart';
// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:kassoua/services/categorie_service.dart';
// import 'package:url_launcher/url_launcher.dart';
// import 'package:flutter_smart_dialog/flutter_smart_dialog.dart'; // Import SmartDialog

// class ProductDetailPage extends StatefulWidget {
//   final String productId;

//   const ProductDetailPage({Key? key, required this.productId})
//     : super(key: key);

//   @override
//   State<ProductDetailPage> createState() => _ProductDetailPageState();
// }

// class _ProductDetailPageState extends State<ProductDetailPage> {
//   final FirestoreService _firestoreService = FirestoreService();
//   final CategoryService _CategoryService = CategoryService();
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final PageController _imagePageController = PageController();
//   int _currentImageIndex = 0;

//   String? get currentUserId => _auth.currentUser?.uid;

//   @override
//   void dispose() {
//     _imagePageController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     bool isDark = Theme.of(context).brightness == Brightness.dark;

//     return Scaffold(
//       backgroundColor: isDark ? AppColors.black : AppColors.white,
//       body: StreamBuilder<Produit?>(
//         stream: Stream.fromFuture(
//           _firestoreService.getProduct(widget.productId),
//         ),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return _buildLoadingState();
//           }

//           if (snapshot.hasError) {
//             return _buildErrorState(snapshot.error.toString());
//           }

//           final product = snapshot.data;
//           if (product == null) {
//             return _buildNotFoundState();
//           }

//           return _buildProductDetail(product);
//         },
//       ),
//     );
//   }

//   // void _debugImageUrls(List<String> urls) {
//   //   print('=== DEBUG IMAGES ===');
//   //   print('Nombre d\'images: ${urls.length}');
//   //   for (int i = 0; i < urls.length; i++) {
//   //     print('Image $i: ${urls[i]}');
//   //   }
//   //   print('Index actuel: $_currentImageIndex');
//   //   print('==================');
//   // }

//   Widget _buildLoadingState() {
//     return Scaffold(
//       appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             CircularProgressIndicator(color: AppColors.primary),
//             SizedBox(height: DMSizes.spaceBtwItems),
//             Text(
//               'Chargement du produit...',
//               style: Theme.of(
//                 context,
//               ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildErrorState(String error) {
//     return Scaffold(
//       appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
//       body: Center(
//         child: Padding(
//           padding: EdgeInsets.all(DMSizes.lg),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(
//                 Iconsax.warning_2,
//                 size: DMSizes.iconLg * 2,
//                 color: AppColors.error,
//               ),
//               SizedBox(height: DMSizes.spaceBtwItems),
//               Text(
//                 'Erreur de chargement',
//                 style: Theme.of(context).textTheme.headlineSmall?.copyWith(
//                   fontWeight: FontWeight.bold,
//                   color: AppColors.textPrimary,
//                 ),
//               ),
//               SizedBox(height: DMSizes.xs),
//               Text(
//                 'Impossible de charger ce produit',
//                 style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//                   color: AppColors.textSecondary,
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildNotFoundState() {
//     return Scaffold(
//       appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
//       body: Center(
//         child: Padding(
//           padding: EdgeInsets.all(DMSizes.lg),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(
//                 Iconsax.box,
//                 size: DMSizes.iconLg * 2,
//                 color: AppColors.textSecondary,
//               ),
//               SizedBox(height: DMSizes.spaceBtwItems),
//               Text(
//                 'Produit non trouvé',
//                 style: Theme.of(context).textTheme.headlineSmall?.copyWith(
//                   fontWeight: FontWeight.bold,
//                   color: AppColors.textPrimary,
//                 ),
//               ),
//               SizedBox(height: DMSizes.xs),
//               Text(
//                 'Ce produit n\'existe plus ou a été supprimé',
//                 style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//                   color: AppColors.textSecondary,
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildProductDetail(Produit product) {
//     final bool isOwner = currentUserId == product.vendeurId;
//     bool isDark = Theme.of(context).brightness == Brightness.dark;

//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: isDark ? AppColors.black : AppColors.white,
//         elevation: 0,
//         iconTheme: IconThemeData(
//           color: isDark ? AppColors.white : AppColors.black,
//         ),
//         actions: [
//           if (isOwner)
//             IconButton(
//               icon: Icon(Iconsax.edit),
//               onPressed: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder:
//                         (context) =>
//                             AddEditProductPage(productId: widget.productId),
//                   ),
//                 );
//               },
//             ),
//         ],
//       ),
//       body: SingleChildScrollView(
//         child: Column(
//           children: [
//             // Galerie d'images simple
//             _buildSimpleImageGallery(product),

//             // Contenu du produit
//             Container(
//               decoration: BoxDecoration(
//                 color: isDark ? AppColors.black : AppColors.white,
//               ),
//               child: Padding(
//                 padding: EdgeInsets.all(DMSizes.lg),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     _buildTitleAndPrice(product),
//                     SizedBox(height: DMSizes.spaceBtwItems),
//                     _buildStatusRow(product),
//                     SizedBox(height: DMSizes.spaceBtwSections),
//                     _buildLocationSection(product),
//                     SizedBox(height: DMSizes.spaceBtwSections),
//                     _buildDescriptionSection(product),
//                     SizedBox(height: DMSizes.spaceBtwSections),
//                     _buildAdditionalInfo(product),
//                     if (isOwner) ...[
//                       SizedBox(height: DMSizes.spaceBtwSections),
//                       _buildOwnerActions(product),
//                     ],
//                     SizedBox(height: DMSizes.spaceBtwSections),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   void _showImageFullScreen(List<String> imageUrls, int initialIndex) {
//     Navigator.of(context).push(
//       MaterialPageRoute(
//         builder:
//             (context) => Scaffold(
//               backgroundColor: Colors.black,
//               appBar: AppBar(
//                 backgroundColor: Colors.transparent,
//                 iconTheme: IconThemeData(color: Colors.white),
//                 title: Text(
//                   '${initialIndex + 1} / ${imageUrls.length}',
//                   style: TextStyle(color: Colors.white),
//                 ),
//               ),
//               body: PageView.builder(
//                 controller: PageController(initialPage: initialIndex),
//                 itemCount: imageUrls.length,
//                 itemBuilder: (context, index) {
//                   return Center(
//                     child: InteractiveViewer(
//                       child: CachedNetworkImage(
//                         imageUrl: imageUrls[index],
//                         fit: BoxFit.contain,
//                         placeholder:
//                             (context, url) => Center(
//                               child: CircularProgressIndicator(
//                                 color: Colors.white,
//                               ),
//                             ),
//                         errorWidget: (context, url, error) {
//                           print('Erreur fullscreen: $error pour URL: $url');
//                           return Column(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: [
//                               Icon(
//                                 Iconsax.gallery_slash,
//                                 size: 50,
//                                 color: Colors.white,
//                               ),
//                               SizedBox(height: 16),
//                               Text(
//                                 'Erreur de chargement',
//                                 style: TextStyle(color: Colors.white),
//                               ),
//                             ],
//                           );
//                         },
//                       ),
//                     ),
//                   );
//                 },
//               ),
//             ),
//       ),
//     );
//   }

//   Widget _buildSimpleImageGallery(Produit product) {
//     return StreamBuilder<List<ImageProduit>>(
//       stream: _firestoreService.getImagesProduit(product.id),
//       builder: (context, snapshot) {
//         // Construction de la liste d'URLs simplifiée
//         List<String> imageUrls = [];

//         if (snapshot.hasData && snapshot.data!.isNotEmpty) {
//           imageUrls = snapshot.data!.map((img) => img.url).toList();
//         } else if (product.imageUrl != null && product.imageUrl!.isNotEmpty) {
//           imageUrls = [product.imageUrl!];
//         }

//         // Si pas d'images, afficher placeholder
//         if (imageUrls.isEmpty) {
//           return Container(
//             height: 300,
//             color: AppColors.grey.withOpacity(0.3),
//             child: Center(
//               child: Icon(
//                 Iconsax.gallery_slash,
//                 size: DMSizes.iconLg * 2,
//                 color: AppColors.textSecondary,
//               ),
//             ),
//           );
//         }

//         // S'assurer que l'index actuel ne dépasse pas la taille de la liste
//         if (_currentImageIndex >= imageUrls.length) {
//           WidgetsBinding.instance.addPostFrameCallback((_) {
//             if (mounted) {
//               setState(() {
//                 _currentImageIndex = 0;
//               });
//             }
//           });
//         }

//         return Container(
//           height: 300,
//           child: Stack(
//             children: [
//               PageView.builder(
//                 controller: _imagePageController,
//                 onPageChanged: (index) {
//                   if (mounted) {
//                     setState(() {
//                       _currentImageIndex = index;
//                     });
//                   }
//                 },
//                 itemCount: imageUrls.length,
//                 itemBuilder: (context, index) {
//                   return GestureDetector(
//                     onTap: () => _showImageFullScreen(imageUrls, index),
//                     child: CachedNetworkImage(
//                       imageUrl: imageUrls[index],
//                       fit: BoxFit.cover,
//                       width: double.infinity,
//                       placeholder:
//                           (context, url) => Container(
//                             color: AppColors.grey.withOpacity(0.1),
//                             child: Center(
//                               child: CircularProgressIndicator(
//                                 color: AppColors.primary,
//                               ),
//                             ),
//                           ),
//                       errorWidget: (context, url, error) {
//                         print(
//                           'Erreur de chargement d\'image: $error pour URL: $url',
//                         );
//                         return Container(
//                           color: AppColors.grey.withOpacity(0.3),
//                           child: Center(
//                             child: Column(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               children: [
//                                 Icon(
//                                   Iconsax.gallery_slash,
//                                   size: DMSizes.iconLg,
//                                   color: AppColors.textSecondary,
//                                 ),
//                                 SizedBox(height: 8),
//                                 Text(
//                                   'Image indisponible',
//                                   style: TextStyle(
//                                     color: AppColors.textSecondary,
//                                     fontSize: 12,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         );
//                       },
//                     ),
//                   );
//                 },
//               ),

//               // Badge de statut vendu
//               if (product.isVendu)
//                 Positioned(
//                   top: DMSizes.md,
//                   right: DMSizes.md,
//                   child: Container(
//                     padding: EdgeInsets.symmetric(
//                       horizontal: DMSizes.sm,
//                       vertical: DMSizes.xs,
//                     ),
//                     decoration: BoxDecoration(
//                       color: AppColors.error,
//                       borderRadius: BorderRadius.circular(
//                         DMSizes.borderRadiusMd,
//                       ),
//                     ),
//                     child: Text(
//                       'VENDU',
//                       style: Theme.of(context).textTheme.labelSmall?.copyWith(
//                         color: AppColors.white,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                 ),

//               // Indicateurs de page
//               if (imageUrls.length > 1)
//                 Positioned(
//                   bottom: DMSizes.md,
//                   left: 0,
//                   right: 0,
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: List.generate(
//                       imageUrls.length,
//                       (index) => Container(
//                         width: 8,
//                         height: 8,
//                         margin: EdgeInsets.symmetric(horizontal: 2),
//                         decoration: BoxDecoration(
//                           shape: BoxShape.circle,
//                           color:
//                               _currentImageIndex == index
//                                   ? AppColors.primary
//                                   : AppColors.grey.withOpacity(0.5),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),

//               // Boutons de navigation (optionnel)
//               if (imageUrls.length > 1) ...[
//                 // Bouton précédent
//                 Positioned(
//                   left: DMSizes.sm,
//                   top: 0,
//                   bottom: 0,
//                   child: Center(
//                     child: GestureDetector(
//                       onTap: () {
//                         if (_currentImageIndex > 0) {
//                           _imagePageController.animateToPage(
//                             _currentImageIndex - 1,
//                             duration: Duration(milliseconds: 300),
//                             curve: Curves.easeInOut,
//                           );
//                         }
//                       },
//                       child: Container(
//                         padding: EdgeInsets.all(8),
//                         decoration: BoxDecoration(
//                           color: Colors.black.withOpacity(0.5),
//                           shape: BoxShape.circle,
//                         ),
//                         child: Icon(
//                           Iconsax.arrow_left_2,
//                           color: Colors.white,
//                           size: 16,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),

//                 // Bouton suivant
//                 Positioned(
//                   right: DMSizes.sm,
//                   top: 0,
//                   bottom: 0,
//                   child: Center(
//                     child: GestureDetector(
//                       onTap: () {
//                         if (_currentImageIndex < imageUrls.length - 1) {
//                           _imagePageController.animateToPage(
//                             _currentImageIndex + 1,
//                             duration: Duration(milliseconds: 300),
//                             curve: Curves.easeInOut,
//                           );
//                         }
//                       },
//                       child: Container(
//                         padding: EdgeInsets.all(8),
//                         decoration: BoxDecoration(
//                           color: Colors.black.withOpacity(0.5),
//                           shape: BoxShape.circle,
//                         ),
//                         child: Icon(
//                           Iconsax.arrow_right_3,
//                           color: Colors.white,
//                           size: 16,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ],
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildTitleAndPrice(Produit product) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           product.nom,
//           style: Theme.of(context).textTheme.headlineMedium?.copyWith(
//             fontWeight: FontWeight.bold,
//             color: AppColors.textPrimary,
//           ),
//         ),
//         SizedBox(height: DMSizes.xs),
//         Text(
//           '${product.prix.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} FCFA',
//           style: Theme.of(context).textTheme.headlineLarge?.copyWith(
//             color: AppColors.primary,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildStatusRow(Produit product) {
//     return Row(
//       children: [
//         // Badge d'état
//         Container(
//           padding: EdgeInsets.symmetric(
//             horizontal: DMSizes.sm,
//             vertical: DMSizes.xs,
//           ),
//           decoration: BoxDecoration(
//             color: _getEtatColor(product.etat).withOpacity(0.1),
//             borderRadius: BorderRadius.circular(DMSizes.borderRadiusMd),
//           ),
//           child: Text(
//             product.etatText,
//             style: Theme.of(context).textTheme.labelMedium?.copyWith(
//               color: _getEtatColor(product.etat),
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//         ),
//         SizedBox(width: DMSizes.sm),

//         // Badge de disponibilité
//         Container(
//           padding: EdgeInsets.symmetric(
//             horizontal: DMSizes.sm,
//             vertical: DMSizes.xs,
//           ),
//           decoration: BoxDecoration(
//             color:
//                 product.isVendu
//                     ? AppColors.error.withOpacity(0.1)
//                     : AppColors.success.withOpacity(0.1),
//             borderRadius: BorderRadius.circular(DMSizes.borderRadiusMd),
//           ),
//           child: Row(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Icon(
//                 product.isVendu ? Iconsax.close_circle : Iconsax.tick_circle,
//                 size: 16,
//                 color: product.isVendu ? AppColors.error : AppColors.success,
//               ),
//               SizedBox(width: DMSizes.xs / 2),
//               Text(
//                 product.isVendu ? 'Vendu' : 'Disponible',
//                 style: Theme.of(context).textTheme.labelMedium?.copyWith(
//                   color: product.isVendu ? AppColors.error : AppColors.success,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildLocationSection(Produit product) {
//     return FutureBuilder<Adresse?>(
//       future: _firestoreService.getAdresseById(product.adresseId),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return Padding(
//             padding: EdgeInsets.all(DMSizes.md),
//             child: LinearProgressIndicator(),
//           );
//         }
//         final adresse = snapshot.data;
//         return Container(
//           padding: EdgeInsets.all(DMSizes.md),
//           decoration: BoxDecoration(
//             color:
//                 Theme.of(context).brightness == Brightness.dark
//                     ? AppColors.dark.withOpacity(0.3)
//                     : AppColors.grey.withOpacity(0.1),
//             borderRadius: BorderRadius.circular(DMSizes.borderRadiusMd),
//           ),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 children: [
//                   Icon(
//                     Iconsax.location,
//                     color: AppColors.primary,
//                     size: DMSizes.iconMd,
//                   ),
//                   SizedBox(width: DMSizes.sm),
//                   Text(
//                     'Localisation',
//                     style: Theme.of(context).textTheme.titleMedium?.copyWith(
//                       fontWeight: FontWeight.w600,
//                       color: AppColors.textPrimary,
//                     ),
//                   ),
//                 ],
//               ),
//               SizedBox(height: DMSizes.sm),

//               if (adresse != null &&
//                   (adresse.quartier != null || adresse.ville != null))
//                 Text(
//                   '${adresse.quartier ?? ''} ${adresse.ville ?? ''}'.trim(),
//                   style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//                     color: AppColors.textSecondary,
//                   ),
//                 ),

//               if (adresse != null &&
//                   adresse.ville != null &&
//                   adresse.ville!.isNotEmpty)
//                 Row(
//                   children: [
//                     Icon(
//                       Iconsax.buildings,
//                       size: 16,
//                       color: AppColors.textSecondary,
//                     ),
//                     SizedBox(width: DMSizes.xs),
//                     Text(
//                       adresse.ville!,
//                       style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//                         color: AppColors.textSecondary,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   ],
//                 ),

//               if (adresse != null)
//                 SizedBox(
//                   width: double.infinity,
//                   child: OutlinedButton.icon(
//                     onPressed: () => _openInMaps(adresse),
//                     icon: Icon(Iconsax.map, size: 16),
//                     label: Text('Voir sur la carte'),
//                     style: OutlinedButton.styleFrom(
//                       foregroundColor: AppColors.primary,
//                       side: BorderSide(color: AppColors.primary),
//                       padding: EdgeInsets.symmetric(vertical: DMSizes.sm),
//                     ),
//                   ),
//                 ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildDescriptionSection(Produit product) {
//     if (product.description == null || product.description!.isEmpty) {
//       return SizedBox.shrink();
//     }

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           'Description',
//           style: Theme.of(context).textTheme.titleMedium?.copyWith(
//             fontWeight: FontWeight.w600,
//             color: AppColors.textPrimary,
//           ),
//         ),
//         SizedBox(height: DMSizes.sm),
//         Container(
//           width: double.infinity,
//           padding: EdgeInsets.all(DMSizes.md),
//           decoration: BoxDecoration(
//             color:
//                 Theme.of(context).brightness == Brightness.dark
//                     ? AppColors.dark.withOpacity(0.3)
//                     : AppColors.grey.withOpacity(0.1),
//             borderRadius: BorderRadius.circular(DMSizes.borderRadiusMd),
//           ),
//           child: Text(
//             product.description!,
//             style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//               color: AppColors.textSecondary,
//               height: 1.5,
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildAdditionalInfo(Produit product) {
//     return FutureBuilder<String?>(
//       future: _CategoryService.getCategoryNameById(product.categorieId),
//       builder: (context, snapshot) {
//         final categoryName = snapshot.data ?? 'Non spécifié';
//         return Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Informations',
//               style: Theme.of(context).textTheme.titleMedium?.copyWith(
//                 fontWeight: FontWeight.w600,
//                 color: AppColors.textPrimary,
//               ),
//             ),
//             SizedBox(height: DMSizes.sm),
//             Container(
//               padding: EdgeInsets.all(DMSizes.md),
//               decoration: BoxDecoration(
//                 color:
//                     Theme.of(context).brightness == Brightness.dark
//                         ? AppColors.dark.withOpacity(0.3)
//                         : AppColors.grey.withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(DMSizes.borderRadiusMd),
//               ),
//               child: Column(
//                 children: [
//                   _buildInfoRow(
//                     icon: Iconsax.category,
//                     label: 'Catégorie',
//                     value: categoryName,
//                   ),
//                   _buildInfoRow(
//                     icon: Iconsax.calendar,
//                     label: 'Publié le',
//                     value: _formatDate(product.dateAjout),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   Widget _buildInfoRow({
//     required IconData icon,
//     required String label,
//     required String value,
//   }) {
//     return Padding(
//       padding: EdgeInsets.symmetric(vertical: DMSizes.xs),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Icon(icon, size: 16, color: AppColors.textSecondary),
//           SizedBox(width: DMSizes.sm),
//           Expanded(
//             flex: 2,
//             child: Text(
//               label,
//               style: Theme.of(
//                 context,
//               ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
//             ),
//           ),
//           Expanded(
//             flex: 3,
//             child: Text(
//               value,
//               style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//                 color: AppColors.textPrimary,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildOwnerActions(Produit product) {
//     return Container(
//       padding: EdgeInsets.all(DMSizes.md),
//       decoration: BoxDecoration(
//         color:
//             Theme.of(context).brightness == Brightness.dark
//                 ? AppColors.dark.withOpacity(0.3)
//                 : AppColors.primary.withOpacity(0.05),
//         borderRadius: BorderRadius.circular(DMSizes.borderRadiusMd),
//         border: Border.all(color: AppColors.primary.withOpacity(0.2)),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             'Actions',
//             style: Theme.of(context).textTheme.titleMedium?.copyWith(
//               fontWeight: FontWeight.w600,
//               color: AppColors.textPrimary,
//             ),
//           ),
//           SizedBox(height: DMSizes.sm),
//           Row(
//             children: [
//               // Bouton Marquer vendu/disponible
//               Expanded(
//                 child: ElevatedButton.icon(
//                   onPressed: () {
//                     if (product.isVendu) {
//                       _showReactivateConfirmationDialog(product);
//                     } else {
//                       _showMarkAsSoldConfirmationDialog(product);
//                     }
//                   },
//                   icon: Icon(
//                     product.isVendu ? Iconsax.refresh : Iconsax.tick_circle,
//                     size: 16,
//                   ),
//                   label: Text(product.isVendu ? 'Remettre' : 'Vendu'),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor:
//                         product.isVendu ? AppColors.info : AppColors.success,
//                     foregroundColor: AppColors.white,
//                     padding: EdgeInsets.symmetric(vertical: DMSizes.sm),
//                   ),
//                 ),
//               ),
//               SizedBox(width: DMSizes.sm),

//               // Bouton Supprimer
//               Expanded(
//                 child: OutlinedButton.icon(
//                   onPressed: () => _showDeleteConfirmationDialog(product),
//                   icon: Icon(Iconsax.trash, size: 16),
//                   label: Text('Supprimer'),
//                   style: OutlinedButton.styleFrom(
//                     foregroundColor: AppColors.error,
//                     side: BorderSide(color: AppColors.error),
//                     padding: EdgeInsets.symmetric(vertical: DMSizes.sm),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Color _getEtatColor(String etat) {
//     switch (etat.toLowerCase()) {
//       case 'neuf':
//         return AppColors.success;
//       case 'tres_bon_etat':
//         return AppColors.info;
//       case 'bon_etat':
//         return AppColors.primary;
//       case 'etat_correct':
//         return AppColors.warning;
//       case 'occasion':
//       default:
//         return AppColors.textSecondary;
//     }
//   }

//   String _formatDate(DateTime date) {
//     final now = DateTime.now();
//     final difference = now.difference(date);

//     if (difference.inDays == 0) {
//       return "Aujourd'hui";
//     } else if (difference.inDays == 1) {
//       return "Hier";
//     } else if (difference.inDays < 7) {
//       return "Il y a ${difference.inDays} jours";
//     } else {
//       return "${date.day}/${date.month}/${date.year}";
//     }
//   }

//   void _openInMaps(Adresse adresse) async {
//     String query = '${adresse.latitude},${adresse.longitude}';
//     final googleMapsUrl = 'https://maps.google.com/maps?q=$query';
//     final appleMapsUrl = 'https://maps.apple.com/?q=$query';

//     try {
//       if (await canLaunchUrl(Uri.parse(googleMapsUrl))) {
//         await launchUrl(
//           Uri.parse(googleMapsUrl),
//           mode: LaunchMode.externalApplication,
//         );
//       } else if (await canLaunchUrl(Uri.parse(appleMapsUrl))) {
//         await launchUrl(
//           Uri.parse(appleMapsUrl),
//           mode: LaunchMode.externalApplication,
//         );
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Impossible d\'ouvrir la carte'),
//             backgroundColor: AppColors.error,
//           ),
//         );
//       }
//     }
//   }

//   void _showReactivateConfirmationDialog(Produit product) {
//     SmartDialog.show(
//       alignment: Alignment.bottomCenter,
//       animationType: SmartAnimationType.scale,
//       animationTime: const Duration(milliseconds: 300),
//       builder: (context) {
//         return Container(
//           width: double.infinity,
//           margin: EdgeInsets.all(DMSizes.lg),
//           decoration: BoxDecoration(
//             color:
//                 Theme.of(context).brightness == Brightness.dark
//                     ? AppColors.dark
//                     : AppColors.white,
//             borderRadius: BorderRadius.circular(DMSizes.borderRadiusLg),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.1),
//                 blurRadius: 20,
//                 offset: const Offset(0, -5),
//               ),
//             ],
//           ),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               // Handle bar
//               Container(
//                 width: 40,
//                 height: 4,
//                 margin: EdgeInsets.only(top: DMSizes.sm),
//                 decoration: BoxDecoration(
//                   color: AppColors.grey.withOpacity(0.3),
//                   borderRadius: BorderRadius.circular(2),
//                 ),
//               ),

//               Padding(
//                 padding: EdgeInsets.all(DMSizes.lg),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     // Icône et titre
//                     Row(
//                       children: [
//                         Container(
//                           padding: EdgeInsets.all(DMSizes.sm),
//                           decoration: BoxDecoration(
//                             color: AppColors.info.withOpacity(0.1),
//                             borderRadius: BorderRadius.circular(
//                               DMSizes.borderRadiusSm,
//                             ),
//                           ),
//                           child: Icon(
//                             Iconsax.refresh,
//                             color: AppColors.info,
//                             size: 24,
//                           ),
//                         ),
//                         SizedBox(width: DMSizes.md),
//                         Expanded(
//                           child: Text(
//                             'Remettre en vente',
//                             style: Theme.of(
//                               context,
//                             ).textTheme.titleLarge?.copyWith(
//                               fontWeight: FontWeight.bold,
//                               color: AppColors.textPrimary,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),

//                     SizedBox(height: DMSizes.md),

//                     // Message
//                     Text(
//                       'Êtes-vous sûr de vouloir remettre en vente l\'annonce "${product.nom}" ?',
//                       style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//                         color: AppColors.textSecondary,
//                         height: 1.4,
//                       ),
//                     ),

//                     SizedBox(height: DMSizes.lg),

//                     // Boutons d'action
//                     Row(
//                       children: [
//                         Expanded(
//                           child: OutlinedButton(
//                             onPressed: () {
//                               SmartDialog.dismiss();
//                             },
//                             style: OutlinedButton.styleFrom(
//                               padding: EdgeInsets.symmetric(
//                                 vertical: DMSizes.md,
//                               ),
//                               side: BorderSide(color: AppColors.grey),
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(
//                                   DMSizes.borderRadiusMd,
//                                 ),
//                               ),
//                             ),
//                             child: Text(
//                               'Annuler',
//                               style: TextStyle(
//                                 color: AppColors.textSecondary,
//                                 fontWeight: FontWeight.w600,
//                               ),
//                             ),
//                           ),
//                         ),
//                         SizedBox(width: DMSizes.md),
//                         Expanded(
//                           child: ElevatedButton(
//                             onPressed: () async {
//                               SmartDialog.showLoading(
//                                 msg: 'Remise en vente...',
//                                 maskColor: Colors.black.withOpacity(0.3),
//                               );

//                               try {
//                                 // Remplacez par votre méthode pour réactiver le produit
//                                 await _firestoreService.reactivateProduct(
//                                   product.id,
//                                 );

//                                 if (mounted) {
//                                   SmartDialog.dismiss(); // Ferme le loading
//                                   SmartDialog.dismiss(); // Ferme le dialog

//                                   // Affiche la confirmation
//                                   Future.delayed(
//                                     const Duration(milliseconds: 300),
//                                     () {
//                                       if (mounted) {
//                                         ScaffoldMessenger.of(
//                                           context,
//                                         ).showSnackBar(
//                                           SnackBar(
//                                             content: Row(
//                                               children: [
//                                                 Icon(
//                                                   Iconsax.tick_circle,
//                                                   color: Colors.white,
//                                                   size: 20,
//                                                 ),
//                                                 SizedBox(width: DMSizes.sm),
//                                                 Expanded(
//                                                   child: Text(
//                                                     'Annonce "${product.nom}" remise en vente.',
//                                                   ),
//                                                 ),
//                                               ],
//                                             ),
//                                             backgroundColor: AppColors.info,
//                                             behavior: SnackBarBehavior.floating,
//                                             shape: RoundedRectangleBorder(
//                                               borderRadius:
//                                                   BorderRadius.circular(
//                                                     DMSizes.borderRadiusMd,
//                                                   ),
//                                             ),
//                                           ),
//                                         );
//                                       }
//                                     },
//                                   );
//                                 }
//                               } catch (e) {
//                                 if (mounted) {
//                                   SmartDialog.dismiss();
//                                   ScaffoldMessenger.of(context).showSnackBar(
//                                     SnackBar(
//                                       content: Text(
//                                         'Erreur lors de la remise en vente: $e',
//                                       ),
//                                       backgroundColor: AppColors.error,
//                                     ),
//                                   );
//                                 }
//                               }
//                             },
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: AppColors.info,
//                               foregroundColor: Colors.white,
//                               padding: EdgeInsets.symmetric(
//                                 vertical: DMSizes.md,
//                               ),
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(
//                                   DMSizes.borderRadiusMd,
//                                 ),
//                               ),
//                               elevation: 0,
//                             ),
//                             child: Text(
//                               'Remettre en vente',
//                               style: TextStyle(fontWeight: FontWeight.w600),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//       clickMaskDismiss: true,
//       backDismiss: true,
//     );
//   }

//   void _showDeleteConfirmationDialog(Produit product) {
//     SmartDialog.show(
//       builder: (context) {
//         return AlertDialog(
//           title: const Text('Supprimer l\'annonce'),
//           content: Text(
//             'Êtes-vous sûr de vouloir supprimer l\'annonce "${product.nom}" ?',
//           ),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 SmartDialog.dismiss(); // Ferme le dialogue de confirmation
//               },
//               child: const Text('Annuler'),
//             ),
//             ElevatedButton(
//               onPressed: () async {
//                 // Afficher un indicateur de chargement pendant la suppression
//                 SmartDialog.showLoading(msg: 'Suppression en cours...');
//                 try {
//                   await _firestoreService.deleteProduct(product.id);
//                   if (mounted) {
//                     SmartDialog.dismiss(); // Ferme le loading
//                     SmartDialog.dismiss(); // Ferme le dialog
//                     Navigator.of(context).pop(); // Retour à la liste
//                     // Affiche le SnackBar APRÈS le pop, avec un petit délai
//                     Future.delayed(const Duration(milliseconds: 300), () {
//                       if (mounted) {
//                         ScaffoldMessenger.of(context).showSnackBar(
//                           SnackBar(
//                             content: Text(
//                               'Annonce "${product.nom}" supprimée avec succès.',
//                             ),
//                             backgroundColor: AppColors.success,
//                           ),
//                         );
//                       }
//                     });
//                   }
//                 } catch (e) {
//                   if (mounted) {
//                     SmartDialog.dismiss();
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       SnackBar(
//                         content: Text('Erreur lors de la suppression: $e'),
//                         backgroundColor: AppColors.error,
//                       ),
//                     );
//                   }
//                 }
//               },
//               style: ElevatedButton.styleFrom(
//                 backgroundColor:
//                     AppColors.error, // Couleur rouge pour supprimer
//                 foregroundColor: Colors.white,
//               ),
//               child: const Text('Supprimer'),
//             ),
//           ],
//         );
//       },
//       // Empêcher de fermer le dialogue en cliquant en dehors
//       clickMaskDismiss: false,
//     );
//   }

//   // Méthode pour partager le produit
//   void _shareProduct(Produit product) async {
//     try {
//       final String shareText =
//           '''
// 🛍️ ${product.nom}
// 💰 Prix: ${product.prix.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} FCFA
// 📍 Lieu:  'Non spécifié'}
// 🏷️ État: ${product.etatText}
// ${product.isVendu ? '❌ VENDU' : '✅ DISPONIBLE'}

// ${product.description ?? ''}

// Voir plus de détails sur Kassoua
//       '''.trim();

//       // Copier dans le presse-papiers
//       await Clipboard.setData(ClipboardData(text: shareText));

//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Row(
//               children: [
//                 Icon(Iconsax.copy, color: AppColors.white, size: 16),
//                 SizedBox(width: DMSizes.xs),
//                 Text('Détails copiés dans le presse-papiers'),
//               ],
//             ),
//             backgroundColor: AppColors.success,
//             duration: Duration(seconds: 2),
//           ),
//         );
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Erreur lors du partage'),
//             backgroundColor: AppColors.error,
//           ),
//         );
//       }
//     }
//   }
// }
