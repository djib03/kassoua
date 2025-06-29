import 'package:flutter/material.dart';
import 'package:kassoua/constants/colors.dart';
import 'package:kassoua/constants/size.dart';
import 'package:kassoua/views/screen/Chat/detailed_chat_page.dart';

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
      'otherParticipantAvatar': '',
      'productName': 'Robe Traditionnelle Africaine',
      'productImageUrl': '',
      'lastMessage': '',
      'lastMessageTime': '14:30',
      'unreadCount': 2,
      'isOnline': true,
      'lastSeen': 'En ligne',
    },
    {
      'conversationId': 'conv_2_prod_B',
      'otherParticipantName': 'Ali Chaussures',
      'otherParticipantAvatar': '',
      'productName': 'Paire de Sneakers Blanches',
      'productImageUrl': '',
      'lastMessage': 'Oui, il est encore disponible. Taille 42.',
      'lastMessageTime': 'Hier',
      'unreadCount': 0,
      'isOnline': false,
      'lastSeen': 'Il y a 2h',
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
      'isOnline': false,
      'lastSeen': 'Il y a 1 jour',
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
                                ? Border.all(color: AppColors.primary, width: 2)
                                : null,
                      ),
                      child: CircleAvatar(
                        radius: DMSizes.iconLg + 2,
                        backgroundColor: AppColors.primary.withOpacity(0.1),
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
                              conversation['otherParticipantName']!,
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
                          Text(
                            conversation['lastMessageTime']!,
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
                              color: AppColors.primary,
                            ),
                          SizedBox(width: DMSizes.xs),
                          Expanded(
                            child: Text(
                              conversation['productName']!,
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
                              conversation['lastMessage']!,
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
