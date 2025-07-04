// Path: lib/screens/chat/detailed_chat_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kassoua/constants/colors.dart';
import 'package:kassoua/services/messagerie_service.dart';
import 'package:iconsax/iconsax.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kassoua/models/message.dart';
import 'package:kassoua/models/discussion.dart';

class DetailedChatPage extends StatefulWidget {
  final String conversationId;
  final String otherParticipantId;
  final String otherParticipantName;
  final String productName;
  final String? productImageUrl;
  final double? productPrice;
  final String? prefilledMessage;

  const DetailedChatPage({
    Key? key,
    required this.conversationId,
    required this.otherParticipantId,
    required this.otherParticipantName,
    required this.productName,
    this.productImageUrl,
    this.productPrice,
    this.prefilledMessage,
  }) : super(key: key);

  @override
  State<DetailedChatPage> createState() => _DetailedChatPageState();
}

class _DetailedChatPageState extends State<DetailedChatPage>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  late AnimationController _animationController;
  late AnimationController _sendButtonController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _sendButtonAnimation;

  bool _showScrollToBottom = false;
  bool _isTyping = false;
  bool _isOnline = true;
  String _lastSeen = "En ligne maintenant";

  final MessagerieService _messagerieService = MessagerieService();

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _setupScrollListener();
    _messageController.addListener(_onMessageChanged);

    // Préremplir le champ de message si un message est fourni
    if (widget.prefilledMessage != null) {
      _messageController.text = widget.prefilledMessage!;
      setState(() {
        _isTyping = true;
      });
      _sendButtonController.forward();
    }

    // Simuler l'activité en ligne
    _simulateOnlineActivity();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _sendButtonController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _sendButtonAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _sendButtonController, curve: Curves.elasticOut),
    );

    _animationController.forward();
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      final showScrollButton = _scrollController.offset > 500;
      if (showScrollButton != _showScrollToBottom) {
        setState(() {
          _showScrollToBottom = showScrollButton;
        });
      }
    });
  }

  void _onMessageChanged() {
    final hasText = _messageController.text.trim().isNotEmpty;
    if (hasText != _isTyping) {
      setState(() {
        _isTyping = hasText;
      });
      if (hasText) {
        _sendButtonController.forward();
      } else {
        _sendButtonController.reverse();
      }
    }
  }

  void _simulateOnlineActivity() {
    // Simuler des changements d'état en ligne
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted) {
        setState(() {
          _isOnline = false;
          _lastSeen = "Vu il y a 2 min";
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _sendButtonController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final content = _messageController.text.trim();
    _messageController.clear();
    setState(() => _isTyping = false);

    await _messagerieService.sendMessage(
      discussionId: widget.conversationId,
      senderId: FirebaseAuth.instance.currentUser!.uid,
      receiverId: widget.otherParticipantId,
      content: content,
      type: MessageType.text,
    );

    // Défilement automatique vers le bas
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    const String currentUserId = 'user_current';

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0D1117) : const Color(0xFFF8F9FA),
      extendBodyBehindAppBar: false,
      appBar: _buildAppBar(isDark),
      body: Column(
        children: [
          // En-tête avec informations du produit
          _buildProductHeader(isDark),

          // Liste des messages
          Expanded(
            child: Stack(
              children: [
                _buildMessagesList(currentUserId, isDark),
                if (_showScrollToBottom) _buildScrollToBottomButton(),
              ],
            ),
          ),

          // Zone de saisie
          _buildMessageInput(isDark),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark) {
    return AppBar(
      elevation: 0,
      backgroundColor: isDark ? const Color(0xFF161B22) : Colors.white,
      leading: IconButton(
        icon: Icon(
          Iconsax.arrow_left,
          color: isDark ? Colors.white : Colors.black,
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                // backgroundImage:
                //     widget.productImageUrl != null
                //         ? NetworkImage(widget.productImageUrl!)
                //         : null,
                child:
                    widget.productImageUrl == null
                        ? Icon(Icons.person, color: AppColors.primary)
                        : null,
              ),
              if (_isOnline)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? const Color(0xFF161B22) : Colors.white,
                        width: 2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.otherParticipantName,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _isOnline ? "En ligne" : _lastSeen,
                  style: TextStyle(
                    color: _isOnline ? Colors.green : AppColors.darkGrey,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Iconsax.call, color: isDark ? Colors.white : Colors.black),
          onPressed: () {
            // Action pour appel vocal
          },
        ),
        PopupMenuButton<String>(
          icon: Icon(Iconsax.more, color: isDark ? Colors.white : Colors.black),
          onSelected: (value) {
            // Gérer les actions du menu
          },
          itemBuilder:
              (context) => [
                const PopupMenuItem(
                  value: 'profile',
                  child: Text('Voir le profil'),
                ),
                const PopupMenuItem(value: 'block', child: Text('Bloquer')),
                const PopupMenuItem(value: 'report', child: Text('Signaler')),
              ],
        ),
      ],
    );
  }

  Widget _buildProductHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF30363D) : const Color(0xFFE1E4E8),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          if (widget.productImageUrl != null)
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: NetworkImage(widget.productImageUrl!),
                  fit: BoxFit.cover,
                ),
              ),
            )
          else
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.shopping_bag,
                color: AppColors.primary,
                size: 24,
              ),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.productName,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.productPrice != null)
                  Text(
                    '${widget.productPrice!.toStringAsFixed(0)} FCFA',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.info_outline, color: AppColors.primary),
            onPressed: () {
              // Afficher plus d'infos sur le produit
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList(String currentUserId, bool isDark) {
    return StreamBuilder<List<Message>>(
      stream: _messagerieService.getMessages(widget.conversationId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final messages = snapshot.data ?? [];
        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 8),
          itemCount: messages.length,
          reverse: true, // Pour afficher les derniers messages en bas
          itemBuilder: (context, index) {
            final message = messages[index];
            final isUserMessage = message.senderId == currentUserId;
            final showAvatar =
                !isUserMessage &&
                (index == messages.length - 1 ||
                    messages[index + 1].senderId != message.senderId);
            return _buildMessageBubble(
              message,
              isUserMessage,
              showAvatar,
              isDark,
            );
          },
        );
      },
    );
  }

  Widget _buildMessageBubble(
    Message message,
    bool isUserMessage,
    bool showAvatar,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            isUserMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUserMessage && showAvatar)
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: Icon(Icons.person, size: 20, color: AppColors.primary),
            )
          else if (!isUserMessage)
            const SizedBox(width: 32),

          const SizedBox(width: 8),

          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color:
                    isUserMessage
                        ? AppColors.primary
                        : isDark
                        ? const Color(0xFF21262D)
                        : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUserMessage ? 16 : 4),
                  bottomRight: Radius.circular(isUserMessage ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        isDark
                            ? Colors.black.withOpacity(0.3)
                            : Colors.grey.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: TextStyle(
                      color:
                          isUserMessage
                              ? Colors.white
                              : isDark
                              ? Colors.white
                              : Colors.black,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}",
                        style: TextStyle(
                          color:
                              isUserMessage
                                  ? Colors.white.withOpacity(0.8)
                                  : AppColors.darkGrey,
                          fontSize: 12,
                        ),
                      ),
                      if (isUserMessage) ...[
                        const SizedBox(width: 4),
                        Icon(
                          message.read ? Icons.done_all : Icons.done,
                          size: 16,
                          color:
                              message.read
                                  ? Colors.blue
                                  : Colors.white.withOpacity(0.8),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildScrollToBottomButton() {
    return Positioned(
      bottom: 16,
      right: 16,
      child: FloatingActionButton.small(
        onPressed: _scrollToBottom,
        backgroundColor: AppColors.primary,
        child: const Icon(Iconsax.send, color: Colors.white),
      ),
    );
  }

  Widget _buildMessageInput(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF30363D) : const Color(0xFFE1E4E8),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Boutons d'actions supplémentaires
            IconButton(
              icon: Icon(Icons.add, color: AppColors.primary),
              onPressed: () {
                _showAttachmentOptions(context);
              },
            ),

            // Champ de saisie
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color:
                      isDark
                          ? const Color(0xFF21262D)
                          : const Color(0xFFF6F8FA),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color:
                        _focusNode.hasFocus
                            ? AppColors.primary
                            : Colors.transparent,
                    width: 1,
                  ),
                ),
                child: TextField(
                  controller: _messageController,
                  focusNode: _focusNode,
                  maxLines: 5,
                  minLines: 1,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    hintText: 'Tapez votre message...',
                    hintStyle: TextStyle(
                      color:
                          isDark ? AppColors.darkGrey : AppColors.textSecondary,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    suffixIcon:
                        _isTyping
                            ? IconButton(
                              icon: Icon(
                                Iconsax.emoji_happy,
                                color: AppColors.primary,
                              ),
                              onPressed: () {
                                // Ouvrir le sélecteur d'emojis
                              },
                            )
                            : null,
                  ),
                  onSubmitted: (value) => _sendMessage(),
                ),
              ),
            ),

            const SizedBox(width: 8),

            // Bouton d'envoi animé
            ScaleTransition(
              scale: _sendButtonAnimation,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(
                    _isTyping ? Iconsax.send1 : Iconsax.microphone,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed:
                      _isTyping
                          ? _sendMessage
                          : () {
                            // Action pour enregistrement vocal
                          },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAttachmentOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Ajouter un fichier',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildAttachmentOption(Icons.photo, 'Photo', () {}),
                    _buildAttachmentOption(Icons.camera_alt, 'Caméra', () {}),
                    _buildAttachmentOption(
                      Icons.insert_drive_file,
                      'Document',
                      () {},
                    ),
                    _buildAttachmentOption(
                      Icons.location_on,
                      'Position',
                      () {},
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
    );
  }

  Widget _buildAttachmentOption(
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
