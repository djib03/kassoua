import 'package:flutter/material.dart';
import 'package:kassoua/constants/colors.dart';
import 'package:kassoua/constants/size.dart';
import 'package:kassoua/views/screen/Chat/detailed_chat_page.dart';
import 'package:kassoua/services/messagerie_service.dart';
import 'package:kassoua/models/discussion.dart';
import 'package:kassoua/models/message.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ConversationsListPage extends StatefulWidget {
  const ConversationsListPage({Key? key}) : super(key: key);

  @override
  State<ConversationsListPage> createState() => _ConversationsListPageState();
}

class _ConversationsListPageState extends State<ConversationsListPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final MessagerieService _messagerieService = MessagerieService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();

    // Marquer l'utilisateur comme en ligne
    _messagerieService.updateOnlineStatus(true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animationController.dispose();
    _searchController.dispose();
    // Marquer l'utilisateur comme hors ligne
    _messagerieService.updateOnlineStatus(false);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _messagerieService.handleAppLifecycleState(state);
  }

  // Fonction pour obtenir les informations de l'autre participant
  Future<Map<String, dynamic>> _getOtherParticipantInfo(
    Discussion discussion,
    String currentUserId,
  ) async {
    String otherUserId =
        discussion.vendeurId == currentUserId
            ? discussion.acheteurId
            : discussion.vendeurId;

    try {
      // Récupérer les informations de l'utilisateur
      final userDoc =
          await _firestore.collection('users').doc(otherUserId).get();
      final userData = userDoc.data() ?? {};

      // Récupérer les informations du produit
      final productDoc =
          await _firestore
              .collection('produits')
              .doc(discussion.produitId)
              .get();
      final productData = productDoc.data() ?? {};

      return {
        'userId': otherUserId,
        'name': userData['nom'] ?? userData['name'] ?? 'Utilisateur',
        'avatar': userData['photoUrl'] ?? userData['avatar'] ?? '',
        'isOnline': userData['isOnline'] ?? false,
        'lastSeen': userData['lastSeen'],
        'productName': productData['nom'] ?? productData['name'] ?? 'Produit',
        'productImageUrl':
            productData['imageUrl'] ?? productData['images']?[0] ?? '',
      };
    } catch (e) {
      return {
        'userId': otherUserId,
        'name': 'Utilisateur',
        'avatar': '',
        'isOnline': false,
        'lastSeen': null,
        'productName': 'Produit',
        'productImageUrl': '',
      };
    }
  }

  // Fonction pour formater la date du dernier message
  String _formatLastMessageTime(DateTime? timestamp) {
    if (timestamp == null) return '';

    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return difference.inMinutes <= 1
          ? 'À l\'instant'
          : '${difference.inMinutes}min';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays == 1) {
      return 'Hier';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}j';
    } else {
      return '${timestamp.day}/${timestamp.month}';
    }
  }

  // Fonction pour formater le statut "dernière vue"
  String _formatLastSeen(Timestamp? lastSeen) {
    if (lastSeen == null) return 'Hors ligne';

    final lastSeenDate = lastSeen.toDate();
    final now = DateTime.now();
    final difference = now.difference(lastSeenDate);

    if (difference.inMinutes < 5) {
      return 'À l\'instant';
    } else if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes}min';
    } else if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours}h';
    } else {
      return 'Il y a ${difference.inDays}j';
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUserId = _auth.currentUser?.uid;

    if (currentUserId == null) {
      return Scaffold(
        body: Center(
          child: Text(
            'Veuillez vous connecter pour voir vos conversations',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.black : const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: isDark ? AppColors.black : Colors.white,
            title: Text(
              'Discussions',
              style: TextStyle(
                color: isDark ? AppColors.white : Colors.black,
                fontSize: DMSizes.fontSizeLg,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: Icon(
                  Icons.more_vert,
                  color: isDark ? AppColors.white : Colors.black,
                ),
                onPressed: () {
                  // Menu d'options
                },
              ),
            ],
          ),

          // Barre de recherche
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                margin: EdgeInsets.all(DMSizes.md),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.dark : Colors.white,
                  borderRadius: BorderRadius.circular(DMSizes.borderRadiusLg),
                  boxShadow: [
                    BoxShadow(
                      color:
                          isDark
                              ? Colors.black.withOpacity(0.3)
                              : Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Rechercher une conversation...',
                    hintStyle: TextStyle(
                      color: isDark ? AppColors.grey : AppColors.darkGrey,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: isDark ? AppColors.grey : AppColors.darkGrey,
                    ),
                    suffixIcon:
                        _searchQuery.isNotEmpty
                            ? IconButton(
                              icon: Icon(
                                Icons.clear,
                                color:
                                    isDark
                                        ? AppColors.grey
                                        : AppColors.darkGrey,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            )
                            : null,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(DMSizes.md),
                  ),
                  style: TextStyle(
                    color: isDark ? AppColors.white : Colors.black,
                  ),
                ),
              ),
            ),
          ),

          // Liste des conversations avec StreamBuilder
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: _messagerieService.getDiscussionsWithMetadata(
              currentUserId,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                  ),
                );
              }

              if (snapshot.hasError) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: isDark ? AppColors.grey : AppColors.darkGrey,
                        ),
                        SizedBox(height: DMSizes.md),
                        Text(
                          'Erreur lors du chargement',
                          style: Theme.of(
                            context,
                          ).textTheme.titleMedium?.copyWith(
                            color: isDark ? AppColors.grey : AppColors.darkGrey,
                          ),
                        ),
                        SizedBox(height: DMSizes.xs),
                        Text(
                          'Veuillez réessayer plus tard',
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(
                            color:
                                isDark
                                    ? AppColors.darkGrey
                                    : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final discussions = snapshot.data ?? [];

              if (discussions.isEmpty) {
                return SliverFillRemaining(child: _buildEmptyState(isDark));
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final discussionData = discussions[index];
                  final Discussion discussion = discussionData['discussion'];
                  final int unreadCount = discussionData['unreadCount'] ?? 0;
                  final Message? lastMessage = discussionData['lastMessage'];

                  return FutureBuilder<Map<String, dynamic>>(
                    future: _getOtherParticipantInfo(discussion, currentUserId),
                    builder: (context, participantSnapshot) {
                      if (!participantSnapshot.hasData) {
                        return Container(
                          margin: EdgeInsets.symmetric(
                            horizontal: DMSizes.md,
                            vertical: DMSizes.xs,
                          ),
                          height: 80,
                          child: Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primary,
                              ),
                            ),
                          ),
                        );
                      }

                      final participantInfo = participantSnapshot.data!;

                      // Filtrage par recherche
                      if (_searchQuery.isNotEmpty) {
                        final searchLower = _searchQuery.toLowerCase();
                        final nameMatches = participantInfo['name']
                            .toString()
                            .toLowerCase()
                            .contains(searchLower);
                        final productMatches = participantInfo['productName']
                            .toString()
                            .toLowerCase()
                            .contains(searchLower);

                        if (!nameMatches && !productMatches) {
                          return const SizedBox.shrink();
                        }
                      }

                      return FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.3),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: _animationController,
                              curve: Interval(
                                (index * 0.1).clamp(0.0, 1.0),
                                ((index * 0.1) + 0.3).clamp(0.0, 1.0),
                                curve: Curves.easeOut,
                              ),
                            ),
                          ),
                          child: _buildConversationCard(
                            discussion,
                            participantInfo,
                            lastMessage,
                            unreadCount,
                            isDark,
                          ),
                        ),
                      );
                    },
                  );
                }, childCount: discussions.length),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(DMSizes.xl),
            decoration: BoxDecoration(
              color:
                  isDark
                      ? AppColors.darkGrey.withOpacity(0.3)
                      : AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.chat_bubble_outline_rounded,
              size: DMSizes.iconLg * 2,
              color: isDark ? AppColors.grey : AppColors.primary,
            ),
          ),
          SizedBox(height: DMSizes.spaceBtwItems),
          Text(
            _searchQuery.isEmpty
                ? 'Aucune conversation'
                : 'Aucun résultat trouvé',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: isDark ? AppColors.grey : AppColors.darkGrey,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: DMSizes.xs),
          Text(
            _searchQuery.isEmpty
                ? 'Commencez une nouvelle discussion'
                : 'Essayez avec d\'autres termes',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDark ? AppColors.darkGrey : AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildConversationCard(
    Discussion discussion,
    Map<String, dynamic> participantInfo,
    Message? lastMessage,
    int unreadCount,
    bool isDark,
  ) {
    final bool hasUnread = unreadCount > 0;
    final bool isOnline = participantInfo['isOnline'] ?? false;
    final String lastMessageContent = lastMessage?.content ?? '';
    final String lastMessageTime = _formatLastMessageTime(
      lastMessage?.timestamp,
    );
    final String lastSeen =
        isOnline ? 'En ligne' : _formatLastSeen(participantInfo['lastSeen']);

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: DMSizes.md,
        vertical: DMSizes.xs,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.dark : Colors.white,
        borderRadius: BorderRadius.circular(DMSizes.borderRadiusLg),
        boxShadow: [
          BoxShadow(
            color:
                isDark
                    ? Colors.black.withOpacity(0.2)
                    : Colors.grey.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border:
            hasUnread
                ? Border.all(
                  color: AppColors.primary.withOpacity(0.3),
                  width: 1,
                )
                : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(DMSizes.borderRadiusLg),
          onTap: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder:
                    (context, animation, secondaryAnimation) =>
                        DetailedChatPage(
                          conversationId: discussion.id,
                          otherParticipantId: participantInfo['userId'],
                          otherParticipantName: participantInfo['name'],
                          productName: participantInfo['productName'],
                          productImageUrl: participantInfo['productImageUrl'],
                        ),
                transitionsBuilder: (
                  context,
                  animation,
                  secondaryAnimation,
                  child,
                ) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(1.0, 0.0),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeInOut,
                      ),
                    ),
                    child: child,
                  );
                },
              ),
            );
          },
          child: Padding(
            padding: EdgeInsets.all(DMSizes.md),
            child: Row(
              children: [
                // Avatar avec indicateur en ligne
                Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border:
                            hasUnread
                                ? Border.all(color: AppColors.primary, width: 2)
                                : null,
                      ),
                      child: CircleAvatar(
                        radius: DMSizes.iconLg + 2,
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        backgroundImage:
                            participantInfo['avatar'].isNotEmpty
                                ? NetworkImage(participantInfo['avatar'])
                                : null,
                        child:
                            participantInfo['avatar'].isEmpty
                                ? Icon(
                                  Icons.person,
                                  color: AppColors.primary,
                                  size: DMSizes.iconLg,
                                )
                                : null,
                      ),
                    ),
                    if (isOnline)
                      Positioned(
                        bottom: 2,
                        right: 2,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark ? AppColors.darkGrey : Colors.white,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                SizedBox(width: DMSizes.md),

                // Contenu principal
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nom et heure
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              participantInfo['name'],
                              style: Theme.of(
                                context,
                              ).textTheme.titleMedium?.copyWith(
                                fontWeight:
                                    hasUnread
                                        ? FontWeight.bold
                                        : FontWeight.w600,
                                color: isDark ? AppColors.white : Colors.black,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (lastMessageTime.isNotEmpty)
                            Text(
                              lastMessageTime,
                              style: Theme.of(
                                context,
                              ).textTheme.bodySmall?.copyWith(
                                color:
                                    hasUnread
                                        ? AppColors.primary
                                        : AppColors.darkGrey,
                                fontWeight:
                                    hasUnread
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                              ),
                            ),
                        ],
                      ),

                      SizedBox(height: DMSizes.xs),

                      // Produit avec image
                      Row(
                        children: [
                          if (participantInfo['productImageUrl'].isNotEmpty)
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                image: DecorationImage(
                                  image: NetworkImage(
                                    participantInfo['productImageUrl'],
                                  ),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            )
                          else
                            Icon(
                              Icons.shopping_bag_outlined,
                              size: DMSizes.iconSm,
                              color: AppColors.primary,
                            ),
                          SizedBox(width: DMSizes.xs),
                          Expanded(
                            child: Text(
                              participantInfo['productName'],
                              style: Theme.of(
                                context,
                              ).textTheme.bodySmall?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: DMSizes.xs),

                      // Dernier message et badge
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              lastMessageContent.isEmpty
                                  ? 'Aucun message'
                                  : lastMessageContent,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.copyWith(
                                color:
                                    isDark
                                        ? AppColors.grey
                                        : AppColors.darkGrey,
                                fontWeight:
                                    hasUnread
                                        ? FontWeight.w500
                                        : FontWeight.normal,
                              ),
                            ),
                          ),
                          if (hasUnread)
                            Container(
                              margin: EdgeInsets.only(left: DMSizes.xs),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$unreadCount',
                                style: Theme.of(
                                  context,
                                ).textTheme.labelSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),

                      if (!isOnline)
                        Padding(
                          padding: EdgeInsets.only(top: DMSizes.xs / 2),
                          child: Text(
                            lastSeen,
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
