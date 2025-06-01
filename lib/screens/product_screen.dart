import 'package:flutter/material.dart';
import 'package:kassoua/constants/colors.dart'; // Assurez-vous du bon chemin
import 'package:kassoua/constants/size.dart'; // Assurez-vous du bon chemin

// Importez votre page de discussion détaillée
// import 'package:kassoua/screens/chat/detailed_chat_page.dart'; // Assurez-vous du bon chemin

// Modèle de données simple pour le produit (à remplacer par votre vrai modèle Product)
class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final int quantity;
  final String imageUrl; // Pour simplifier, une seule image pour l'instant
  final String sellerId;
  final String sellerName;
  final String? sellerProfileImageUrl; // Optionnel

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
  });
}

class ProductDetailPage extends StatelessWidget {
  final Product product; // Le produit à afficher

  const ProductDetailPage({Key? key, required this.product}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Pour l'intégration Firebase ultérieure, vous auriez ici la logique
    // de vérification si l'utilisateur est connecté et de récupération de son UID
    // final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
    // final bool isCurrentUserSeller = currentUserId == product.sellerId;

    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
        backgroundColor: DMColors.primary, // Couleur locale
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: DMColors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Image du produit
            Container(
              height: 300, // Hauteur fixe pour l'image
              width: double.infinity,
              decoration: BoxDecoration(
                color: DMColors.lightGrey,
                image: DecorationImage(
                  image: NetworkImage(product.imageUrl),
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  onError: (exception, stackTrace) {
                    // Gérer l'erreur de chargement d'image
                    print('Error loading image: $exception, $stackTrace');
                  },
                ),
              ),
              child: Stack(
                children: [
                  // Optionnel: Badge "Vendu" si le produit est vendu (à gérer avec un statut réel)
                  // Positioned(
                  //   top: DMSizes.md,
                  //   right: DMSizes.md,
                  //   child: Container(
                  //     padding: EdgeInsets.symmetric(horizontal: DMSizes.sm, vertical: DMSizes.xs),
                  //     decoration: BoxDecoration(
                  //       color: DMColors.error.withOpacity(0.8),
                  //       borderRadius: BorderRadius.circular(DMSizes.borderRadiusSm),
                  //     ),
                  //     child: Text(
                  //       'VENDU',
                  //       style: Theme.of(context).textTheme.labelLarge?.copyWith(color: DMColors.white, fontWeight: FontWeight.bold),
                  //     ),
                  //   ),
                  // ),
                ],
              ),
            ),
            SizedBox(height: DMSizes.defaultSpace), // Espace après l'image
            // Détails du produit (Nom, Prix, Quantité)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: DMSizes.defaultSpace),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: DMColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: DMSizes.sm),
                  Text(
                    '${product.price.toStringAsFixed(0)} FCFA', // Formatage du prix
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: DMColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: DMSizes.sm),
                  Row(
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: DMSizes.iconMd,
                        color: DMColors.darkGrey,
                      ),
                      SizedBox(width: DMSizes.sm),
                      Text(
                        'Quantité disponible: ${product.quantity}',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: DMColors.textSecondary),
                      ),
                    ],
                  ),
                  SizedBox(height: DMSizes.spaceBtwSections), // Grand espace
                  // Description du produit
                  Text(
                    'Description du produit',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: DMColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: DMSizes.sm),
                  Text(
                    product.description,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: DMColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: DMSizes.spaceBtwSections),

                  // Section Vendeur
                  Text(
                    'Informations sur le Vendeur',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: DMColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: DMSizes.sm),
                  ListTile(
                    leading: CircleAvatar(
                      radius: DMSizes.iconLg,
                      backgroundImage:
                          product.sellerProfileImageUrl != null &&
                                  product.sellerProfileImageUrl!.isNotEmpty
                              ? NetworkImage(product.sellerProfileImageUrl!)
                              : null,
                      backgroundColor: DMColors.lightGrey,
                      child:
                          product.sellerProfileImageUrl == null ||
                                  product.sellerProfileImageUrl!.isEmpty
                              ? Icon(
                                Icons.person,
                                color: DMColors.darkGrey,
                                size: DMSizes.iconLg,
                              )
                              : null,
                    ),
                    title: Text(
                      product.sellerName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: DMColors.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      'Voir le profil du vendeur', // Optionnel : pour aller sur une page de profil vendeur
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: DMColors.textSecondary,
                      ),
                    ),
                    onTap: () {
                      // Action: naviguer vers le profil du vendeur si vous en avez un
                      // ScaffoldMessenger.of(context).showSnackBar(
                      //   SnackBar(content: Text('Voir le profil de ${product.sellerName}')),
                      // );
                    },
                  ),
                  SizedBox(height: DMSizes.spaceBtwSections),
                ],
              ),
            ),
          ],
        ),
      ),
      // Bouton flottant ou barre de navigation inférieure pour contacter le vendeur
      bottomNavigationBar: Padding(
        padding: EdgeInsets.all(DMSizes.defaultSpace),
        child: ElevatedButton.icon(
          onPressed: () {
            // --- Logique pour contacter le vendeur ---
            // Pour l'instant, on simule l'ID de l'utilisateur actuel
            // et on crée une conversation (ou on la récupère si elle existe).
            // Cette partie sera remplacée par l'intégration Firebase réelle.

            // Données factices pour la simulation d'ID d'utilisateur courant
            String currentUserId =
                'mock_buyer_id_123'; // Simuler un ID d'acheteur connecté

            // Dans une vraie application, vous feriez :
            // User? currentUser = FirebaseAuth.instance.currentUser;
            // if (currentUser == null) {
            //   // Demander à l'utilisateur de se connecter
            //   ScaffoldMessenger.of(context).showSnackBar(
            //     const SnackBar(content: Text('Veuillez vous connecter pour contacter le vendeur.')),
            //   );
            //   return;
            // }
            // String buyerId = currentUser.uid;

            // Logique simplifiée pour naviguer vers la page de chat
            // Dans une vraie application, vous chercheriez/créeriez la conversation ID ici
            String conversationId =
                'mock_conv_id_${product.id}_${product.sellerId}_$currentUserId';

            // Navigator.push(
            //   context,
            //   MaterialPageRoute(
            //     builder:
            //         (context) => DetailedChatPage(
            //           conversationId: conversationId,
            //           otherUserId: product.sellerId,
            //           otherUserName: product.sellerName,
            //           productName: product.name,
            //           productImageUrl: product.imageUrl,
            //         ),
            //   ),
            // );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: DMColors.primary,
            padding: EdgeInsets.symmetric(vertical: DMSizes.md),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DMSizes.buttonRadius),
            ),
          ),
          icon: const Icon(Icons.message_outlined, color: DMColors.white),
          label: Text(
            'Contacter le Vendeur',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: DMColors.white),
          ),
        ),
      ),
    );
  }
}
