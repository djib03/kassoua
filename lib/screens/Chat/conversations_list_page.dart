import 'package:flutter/material.dart';
import 'package:kassoua/constants/colors.dart';
import 'package:kassoua/constants/size.dart';
import 'package:kassoua/screens/chat/detailed_chat_page.dart';

class ConversationsListPage extends StatefulWidget {
  const ConversationsListPage({Key? key}) : super(key: key);

  @override
  State<ConversationsListPage> createState() => _ConversationsListPageState();
}

class _ConversationsListPageState extends State<ConversationsListPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Données factices pour simuler des conversations
  final List<Map<String, dynamic>> mockConversations = const [
    {
      'conversationId': 'conv_1_prod_A',
      'otherParticipantName': 'Vendeur Mariam',
      'otherParticipantAvatar':
          'https://images.unsplash.com/photo-1494790108755-2616b612b647?w=150',
      'productName': 'Robe Traditionnelle Africaine',
      'productImageUrl':
          'https://images.unsplash.com/photo-1515372039744-b8f02a3ae446?w=100',
      'lastMessage':
          'Bonjour, le prix est négociable si vous prenez plus d\'une pièce.',
      'lastMessageTime': '14:30',
      'unreadCount': 2,
      'isOnline': true,
      'lastSeen': 'En ligne',
    },
    {
      'conversationId': 'conv_2_prod_B',
      'otherParticipantName': 'Ali Chaussures',
      'otherParticipantAvatar':
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
      'productName': 'Paire de Sneakers Blanches',
      'productImageUrl':
          'https://images.unsplash.com/photo-1549298916-b41d501d3772?w=100',
      'lastMessage': 'Oui, il est encore disponible. Taille 42.',
      'lastMessageTime': 'Hier',
      'unreadCount': 0,
      'isOnline': false,
      'lastSeen': 'Il y a 2h',
    },
    {
      'conversationId': 'conv_3_prod_C',
      'otherParticipantName': 'Electronique Pro',
      'otherParticipantAvatar':
          'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150',
      'productName': 'Téléviseur Smart TV 55"',
      'productImageUrl':
          'https://images.unsplash.com/photo-1593359677879-a4bb92f829d1?w=100',
      'lastMessage': 'Je peux vous livrer demain matin.',
      'lastMessageTime': '23 Mai',
      'unreadCount': 1,
      'isOnline': false,
      'lastSeen': 'Il y a 1 jour',
    },
    {
      'conversationId': 'conv_4_prod_D',
      'otherParticipantName': 'Fatima Bijoux',
      'otherParticipantAvatar':
          'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=150',
      'productName': 'Bracelet en Argent',
      'productImageUrl':
          'https://images.unsplash.com/photo-1515562141207-7a88fb7ce338?w=100',
      'lastMessage': 'Non, le prix est fixe sur cet article.',
      'lastMessageTime': '20 Mai',
      'unreadCount': 0,
      'isOnline': true,
      'lastSeen': 'En ligne',
    },
  ];

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
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get filteredConversations {
    if (_searchQuery.isEmpty) return mockConversations;
    return mockConversations
        .where(
          (conversation) =>
              conversation['otherParticipantName']!.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ||
              conversation['productName']!.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? DMColors.black : const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: isDark ? DMColors.black : Colors.white,
            title: Text(
              'Discussions',
              style: TextStyle(
                color: isDark ? DMColors.white : Colors.black,
                fontSize: DMSizes.fontSizeLg,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: Icon(
                  Icons.more_vert,
                  color: isDark ? DMColors.white : Colors.black,
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
                  color: isDark ? DMColors.dark : Colors.white,
                  borderRadius: BorderRadius.circular(DMSizes.borderRadiusLg),
                  boxShadow: [
                    BoxShadow(
                      color:
                          isDark
                              ? Colors.black.withValues()
                              : Colors.grey.withValues(),
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
                      color: isDark ? DMColors.grey : DMColors.darkGrey,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: isDark ? DMColors.grey : DMColors.darkGrey,
                    ),
                    suffixIcon:
                        _searchQuery.isNotEmpty
                            ? IconButton(
                              icon: Icon(
                                Icons.clear,
                                color:
                                    isDark ? DMColors.grey : DMColors.darkGrey,
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
                    color: isDark ? DMColors.white : Colors.black,
                  ),
                ),
              ),
            ),
          ),

          // Liste des conversations
          filteredConversations.isEmpty
              ? SliverFillRemaining(child: _buildEmptyState(isDark))
              : SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
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
                        filteredConversations[index],
                        isDark,
                        index,
                      ),
                    ),
                  );
                }, childCount: filteredConversations.length),
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
                      ? DMColors.darkGrey.withOpacity(0.3)
                      : DMColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.chat_bubble_outline_rounded,
              size: DMSizes.iconLg * 2,
              color: isDark ? DMColors.grey : DMColors.primary,
            ),
          ),
          SizedBox(height: DMSizes.spaceBtwItems),
          Text(
            _searchQuery.isEmpty
                ? 'Aucune conversation'
                : 'Aucun résultat trouvé',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: isDark ? DMColors.grey : DMColors.darkGrey,
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
              color: isDark ? DMColors.darkGrey : DMColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildConversationCard(
    Map<String, dynamic> conversation,
    bool isDark,
    int index,
  ) {
    final bool hasUnread = conversation['unreadCount']! > 0;
    final bool isOnline = conversation['isOnline'] ?? false;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: DMSizes.md,
        vertical: DMSizes.xs,
      ),
      decoration: BoxDecoration(
        color: isDark ? DMColors.dark : Colors.white,
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
                ? Border.all(color: DMColors.primary.withOpacity(0.3), width: 1)
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
                    (
                      context,
                      animation,
                      secondaryAnimation,
                    ) => DetailedChatPage(
                      conversationId: conversation['conversationId']!,
                      otherParticipantId:
                          'seller_${conversation['otherParticipantName']!.replaceAll(' ', '_').toLowerCase()}',
                      otherParticipantName:
                          conversation['otherParticipantName']!,
                      productName: conversation['productName']!,
                      productImageUrl: conversation['productImageUrl'],
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
                                ? Border.all(color: DMColors.primary, width: 2)
                                : null,
                      ),
                      child: CircleAvatar(
                        radius: DMSizes.iconLg + 2,
                        backgroundColor: DMColors.primary.withOpacity(0.1),
                        backgroundImage:
                            conversation['otherParticipantAvatar'] != null &&
                                    conversation['otherParticipantAvatar']!
                                        .isNotEmpty
                                ? NetworkImage(
                                  conversation['otherParticipantAvatar']!,
                                )
                                : null,
                        child:
                            conversation['otherParticipantAvatar'] == null ||
                                    conversation['otherParticipantAvatar']!
                                        .isEmpty
                                ? Icon(
                                  Icons.person,
                                  color: DMColors.primary,
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
                              color: isDark ? DMColors.darkGrey : Colors.white,
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
                              conversation['otherParticipantName']!,
                              style: Theme.of(
                                context,
                              ).textTheme.titleMedium?.copyWith(
                                fontWeight:
                                    hasUnread
                                        ? FontWeight.bold
                                        : FontWeight.w600,
                                color: isDark ? DMColors.white : Colors.black,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            conversation['lastMessageTime']!,
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(
                              color:
                                  hasUnread
                                      ? DMColors.primary
                                      : DMColors.darkGrey,
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
                          if (conversation['productImageUrl'] != null)
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                image: DecorationImage(
                                  image: NetworkImage(
                                    conversation['productImageUrl']!,
                                  ),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            )
                          else
                            Icon(
                              Icons.shopping_bag_outlined,
                              size: DMSizes.iconSm,
                              color: DMColors.primary,
                            ),
                          SizedBox(width: DMSizes.xs),
                          Expanded(
                            child: Text(
                              conversation['productName']!,
                              style: Theme.of(
                                context,
                              ).textTheme.bodySmall?.copyWith(
                                color: DMColors.primary,
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
                              conversation['lastMessage']!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.copyWith(
                                color:
                                    isDark ? DMColors.grey : DMColors.darkGrey,
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
                                color: DMColors.primary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${conversation['unreadCount']}',
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

                      if (!isOnline && conversation['lastSeen'] != null)
                        Padding(
                          padding: EdgeInsets.only(top: DMSizes.xs / 2),
                          child: Text(
                            conversation['lastSeen']!,
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(
                              color: DMColors.textSecondary,
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
