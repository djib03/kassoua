import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart'; // Pour les icônes
import 'package:kassoua/constants/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Enum pour définir les options de filtrage
enum NotificationFilter { all, unread, read }

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  NotificationFilter _currentFilter = NotificationFilter.all; // Filtre actuel

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications', style: TextStyle(color: Colors.white)),
        actionsIconTheme: IconThemeData(color: Colors.white),
        backgroundColor: AppColors.primary,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          PopupMenuButton<NotificationFilter>(
            icon: Icon(Icons.filter_list), // Icône de filtre
            onSelected: (NotificationFilter result) {
              setState(() {
                _currentFilter = result;
              });
            },
            itemBuilder:
                (BuildContext context) => <PopupMenuEntry<NotificationFilter>>[
                  const PopupMenuItem<NotificationFilter>(
                    value: NotificationFilter.all,
                    child: Text('Toutes'),
                  ),
                  const PopupMenuItem<NotificationFilter>(
                    value: NotificationFilter.unread,
                    child: Text('Non lues'),
                  ),
                  const PopupMenuItem<NotificationFilter>(
                    value: NotificationFilter.read,
                    child: Text('Lues'),
                  ),
                ],
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('notifications')
                .where('userId', isEqualTo: currentUserId)
                .orderBy('dateEnvoi', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return Center(child: Text('Aucune notification'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final notif = docs[index].data() as Map<String, dynamic>;
              final id = docs[index].id;
              final isRead = notif['isRead'] ?? false;

              return Card(
                margin: const EdgeInsets.only(bottom: 12.0),
                color: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side:
                      isRead
                          ? BorderSide.none
                          : BorderSide(
                            color: AppColors.primary.withOpacity(0.5),
                            width: 1.5,
                          ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16.0),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      notif['icon'],
                      color: AppColors.primary,
                      size: 28,
                    ),
                  ),
                  title: Text(
                    notif['title'],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        notif['message'],
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        notif['date'],
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  trailing: Row(
                    // Utilise un Row pour placer plusieurs widgets
                    mainAxisSize: MainAxisSize.min, // Occupe l'espace minimal
                    children: [
                      if (!isRead) // N'affiche le point que si non lu
                        Container(
                          width: 10,
                          height: 10,
                          margin: const EdgeInsets.only(
                            right: 8,
                          ), // Espace entre le point et la corbeille
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                        ),
                      IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          color: Colors.grey[600],
                        ),
                        onPressed: () {
                          FirebaseFirestore.instance
                              .collection('notifications')
                              .doc(id)
                              .delete();
                          FirebaseFirestore.instance
                              .collection('notifications')
                              .doc(id)
                              .update({'isRead': !isRead});
                        },
                      ),
                    ],
                  ),
                  onTap: () {
                    FirebaseFirestore.instance
                        .collection('notifications')
                        .doc(id)
                        .update({'isRead': !isRead});
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
