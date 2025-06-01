import 'package:flutter/material.dart';
import 'package:kassoua/constants/colors.dart'; // Assurez-vous du bon chemin
import 'package:kassoua/constants/size.dart'; // Assurez-vous du bon chemin

// Supposons que vous ayez une page de détails de chat, nous allons la simuler pour le moment
// Vous devrez la remplacer par votre vraie page DetailedChatPage
class DetailedChatPage extends StatelessWidget {
  final String conversationId;
  final String otherParticipantName;
  final String productName;
  final String? productImageUrl;

  const DetailedChatPage({
    Key? key,
    required this.conversationId,
    required this.otherParticipantName,
    required this.productName,
    this.productImageUrl,
  }) : super(key: key);

  // Messages factices pour la démonstration
  final List<Map<String, dynamic>> mockMessages = const [
    {
      'senderId': 'user',
      'message': 'Bonjour, est-ce que ce produit est disponible ?',
      'timestamp': '10:00',
    },
    {
      'senderId': 'other',
      'message': 'Oui, il est toujours disponible !',
      'timestamp': '10:02',
    },
    {
      'senderId': 'user',
      'message': 'Quel est votre meilleur prix ?',
      'timestamp': '10:03',
    },
    {
      'senderId': 'other',
      'message':
          'Je peux vous faire un prix à -10% si vous achetez aujourd\'hui',
      'timestamp': '10:05',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(otherParticipantName),
            Text(
              'Produit: $productName',
              style: TextStyle(
                fontSize: DMSizes.fontSizeSm,
                color: DMColors.white.withOpacity(0.7),
              ),
            ),
          ],
        ),
        backgroundColor: DMColors.primary,
      ),
      body: Column(
        children: [
          // Zone de produit en haut
          Container(
            padding: EdgeInsets.all(DMSizes.sm),
            decoration: BoxDecoration(
              color: DMColors.lightGrey.withOpacity(0.2),
              border: Border(bottom: BorderSide(color: DMColors.lightGrey)),
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(DMSizes.borderRadiusSm),
                    color: DMColors.lightGrey,
                  ),
                  child:
                      productImageUrl != null && productImageUrl!.isNotEmpty
                          ? Image.network(productImageUrl!, fit: BoxFit.cover)
                          : Icon(Icons.shopping_bag, color: DMColors.darkGrey),
                ),
                SizedBox(width: DMSizes.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        productName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      // Ajoutez ici le prix si nécessaire
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Liste des messages
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(DMSizes.sm),
              itemCount: mockMessages.length,
              itemBuilder: (context, index) {
                final message = mockMessages[index];
                final isUserMessage = message['senderId'] == 'user';

                return Align(
                  alignment:
                      isUserMessage
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                  child: Container(
                    margin: EdgeInsets.only(
                      bottom: DMSizes.sm,
                      left: isUserMessage ? DMSizes.lg : 0,
                      right: isUserMessage ? 0 : DMSizes.lg,
                    ),
                    padding: EdgeInsets.all(DMSizes.sm),
                    decoration: BoxDecoration(
                      color:
                          isUserMessage
                              ? DMColors.primary.withOpacity(0.9)
                              : DMColors.lightGrey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(
                        DMSizes.borderRadiusMd,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message['message'],
                          style: TextStyle(
                            color:
                                isUserMessage
                                    ? DMColors.white
                                    : DMColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: DMSizes.xs),
                        Text(
                          message['timestamp'],
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(
                            color:
                                isUserMessage
                                    ? DMColors.white.withOpacity(0.7)
                                    : DMColors.darkGrey,
                            fontSize: DMSizes.fontSizeSm,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Zone de saisie du message
          Container(
            padding: EdgeInsets.all(DMSizes.sm),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Écrivez votre message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          DMSizes.borderRadiusMd,
                        ),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: DMColors.lightGrey.withOpacity(0.2),
                      contentPadding: EdgeInsets.all(DMSizes.sm),
                    ),
                  ),
                ),
                SizedBox(width: DMSizes.sm),
                CircleAvatar(
                  backgroundColor: DMColors.primary,
                  child: IconButton(
                    icon: Icon(Icons.send, color: Colors.white),
                    onPressed: () {
                      // Logique d'envoi du message
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- Page de liste des conversations ---
class ConversationsListPage extends StatelessWidget {
  const ConversationsListPage({Key? key}) : super(key: key);

  // Données factices pour simuler des conversations
  final List<Map<String, dynamic>> mockConversations = const [
    {
      'conversationId': 'conv_1_prod_A',
      'otherParticipantName': 'Vendeur Mariam',
      'otherParticipantAvatar': '',
      'productName': 'Robe Traditionnelle Africaine',
      'productImageUrl': '',
      'lastMessage':
          'Bonjour, le prix est négociable si vous prenez plus d\'une pièce.',
      'lastMessageTime': '14:30',
      'unreadCount': 2,
    },
    {
      'conversationId': 'conv_2_prod_B',
      'otherParticipantName': 'Ali Chaussures',
      'otherParticipantAvatar': '',
      'productName': 'Paire de Sneakers Blanches',
      'productImageUrl': '',
      'lastMessage': 'Oui, c\'est encore disponible. Taille 42.',
      'lastMessageTime': 'Hier',
      'unreadCount': 0,
    },
    {
      'conversationId': 'conv_3_prod_C',
      'otherParticipantName': 'Electronique Pro',
      'otherParticipantAvatar': '',
      'productName': 'Téléviseur Smart TV 55"',
      'productImageUrl': '',
      'lastMessage': 'Je peux vous livrer demain matin.',
      'lastMessageTime': '23 Mai',
      'unreadCount': 1,
    },
    {
      'conversationId': 'conv_4_prod_D',
      'otherParticipantName': 'Fatima Bijoux',
      'otherParticipantAvatar': '',
      'productName': 'Bracelet en Argent',
      'productImageUrl': '',
      'lastMessage': 'Non, le prix est fixe sur cet article.',
      'lastMessageTime': '20 Mai',
      'unreadCount': 0,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Discussions'),
        backgroundColor:
            DMColors.primary, // Utilisation de votre couleur primaire
        elevation: 0, // Pas d'ombre sous l'app bar
      ),
      body: ListView.builder(
        padding: EdgeInsets.symmetric(
          horizontal: DMSizes.sm, // Utilisez vos tailles définies
          vertical: DMSizes.sm,
        ),
        itemCount: mockConversations.length,
        itemBuilder: (context, index) {
          final conversation = mockConversations[index];

          return Card(
            elevation:
                DMSizes
                    .cardElevation, // Utilisation de votre élévation de carte
            margin: EdgeInsets.symmetric(
              vertical: DMSizes.sm, // Espace vertical entre les cartes
              horizontal: DMSizes.xs, // Petit espace horizontal
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                DMSizes.borderRadiusMd,
              ), // Rayon des bords
            ),
            child: ListTile(
              contentPadding: EdgeInsets.all(
                DMSizes.sm,
              ), // Padding interne de la liste
              leading: CircleAvatar(
                radius: DMSizes.iconLg, // Taille de l'avatar (ex: 32.0)
                backgroundImage: NetworkImage(
                  conversation['otherParticipantAvatar']!,
                ),
                backgroundColor:
                    DMColors
                        .lightGrey, // Couleur par défaut si image ne charge pas
              ),
              title: Text(
                conversation['otherParticipantName']!,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: DMColors.textPrimary,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: DMSizes.xs), // Petit espace
                  Row(
                    children: [
                      Icon(
                        Icons.shopping_bag_outlined,
                        size: DMSizes.iconSm,
                        color: DMColors.darkGrey,
                      ),
                      SizedBox(width: DMSizes.xs),
                      Expanded(
                        child: Text(
                          'Produit: ${conversation['productName']}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: DMColors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: DMSizes.xs),
                  Text(
                    conversation['lastMessage']!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: DMColors.darkGrey,
                      fontWeight:
                          conversation['unreadCount']! > 0
                              ? FontWeight.bold
                              : FontWeight.normal,
                    ),
                  ),
                ],
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    conversation['lastMessageTime']!,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: DMColors.darkGrey),
                  ),
                  if (conversation['unreadCount']! > 0)
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color:
                            DMColors
                                .primary, // Ou une couleur accent pour les non lus
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${conversation['unreadCount']}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: DMColors.white,
                          fontSize:
                              DMSizes.iconXs, // Petite taille pour le badge
                        ),
                      ),
                    ),
                  if (conversation['productImageUrl'] != null &&
                      conversation['productImageUrl']!.isNotEmpty)
                    SizedBox(
                      width: DMSizes.iconLg, // Taille de l'image du produit
                      height: DMSizes.iconLg,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          DMSizes.borderRadiusSm,
                        ), // Rayon des bords
                        child: Image.network(
                          conversation['productImageUrl']!,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (context, error, stackTrace) => const Icon(
                                Icons.broken_image,
                                color: DMColors.darkGrey,
                              ), // Image d'erreur
                        ),
                      ),
                    ),
                ],
              ),
              onTap: () {
                // Naviguer vers la page de discussion détaillée
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => DetailedChatPage(
                          conversationId: conversation['conversationId']!,
                          otherParticipantName:
                              conversation['otherParticipantName']!,
                          productName: conversation['productName']!,
                          productImageUrl: conversation['productImageUrl'],
                        ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
