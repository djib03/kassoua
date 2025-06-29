import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart'; // Pour les icônes
import 'package:kassoua/constants/colors.dart';

// Enum pour définir les options de filtrage
enum NotificationFilter { all, unread, read }

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  // Une liste d'exemple de notifications (maintenant mutable car l'état change)
  final List<Map<String, dynamic>> _notifications = [
    {
      'id': '1', // Ajout d'un ID unique pour faciliter la gestion
      'icon': Iconsax.notification_bing,
      'title': 'Nouvelle mise à jour',
      'message':
          'Une nouvelle version de l\'application est disponible. Mettez à jour maintenant !',
      'date': '10 juin 2025 à 14:30',
      'isRead': false,
    },
    {
      'id': '2',
      'icon': Iconsax.shopping_cart,
      'title': 'Commande #1234 livrée',
      'message': 'Votre commande a été livrée avec succès.',
      'date': '09 juin 2025 à 10:00',
      'isRead': true,
    },
    {
      'id': '3',
      'icon': Iconsax.discount_shape,
      'title': 'Promotion Spéciale',
      'message':
          'Profitez de 20% de réduction sur tous les articles ce week-end !',
      'date': '08 juin 2025 à 18:45',
      'isRead': false,
    },
    {
      'id': '4',
      'icon': Iconsax.wallet,
      'title': 'Paiement Reçu',
      'message': 'Votre paiement pour la facture #5678 a été reçu.',
      'date': '07 juin 2025 à 09:15',
      'isRead': true,
    },
    {
      'id': '5',
      'icon': Iconsax.messages,
      'title': 'Nouveau message',
      'message': 'Vous avez un nouveau message de support.',
      'date': '06 juin 2025 à 16:00',
      'isRead': false,
    },
    {
      'id': '6',
      'icon': Iconsax.notification_bing,
      'title': 'Rappel de rendez-vous',
      'message': 'Votre rendez-vous pour demain à 10h est confirmé.',
      'date': '05 juin 2025 à 12:00',
      'isRead': true,
    },
  ];

  NotificationFilter _currentFilter = NotificationFilter.all; // Filtre actuel

  // Méthode pour marquer une notification comme lue/non lue
  void _toggleNotificationReadStatus(String id) {
    setState(() {
      final index = _notifications.indexWhere((notif) => notif['id'] == id);
      if (index != -1) {
        _notifications[index]['isRead'] = !_notifications[index]['isRead'];
      }
    });
  }

  // Méthode pour supprimer une notification
  void _deleteNotification(String id) {
    setState(() {
      _notifications.removeWhere((notif) => notif['id'] == id);
    });
    // Afficher un message de confirmation (facultatif)
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Notification supprimée')));
  }

  // Méthode pour filtrer les notifications affichées
  List<Map<String, dynamic>> get _filteredNotifications {
    switch (_currentFilter) {
      case NotificationFilter.unread:
        return _notifications
            .where((notif) => notif['isRead'] == false)
            .toList();
      case NotificationFilter.read:
        return _notifications
            .where((notif) => notif['isRead'] == true)
            .toList();
      case NotificationFilter.all:
      default:
        return _notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Brightness brightness = Theme.of(context).brightness;
    final Color backgroundColor =
        brightness == Brightness.dark ? AppColors.black : Colors.white;
    final Color textColor =
        brightness == Brightness.dark ? Colors.white : Colors.black;
    final Color secondaryTextColor =
        brightness == Brightness.dark ? Colors.white70 : Colors.grey[600]!;
    final Color cardColor =
        brightness == Brightness.dark
            ? const Color.fromARGB(255, 46, 46, 46)
            : Colors.white;

    // Notifications à afficher en fonction du filtre
    final List<Map<String, dynamic>> notificationsToShow =
        _filteredNotifications;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text('Notifications', style: TextStyle(color: textColor)),
        backgroundColor: backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
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
      body:
          notificationsToShow.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Iconsax.notification_circle,
                      size: 80,
                      color: secondaryTextColor,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Aucune notification ${_currentFilter == NotificationFilter.unread
                          ? 'non lue'
                          : _currentFilter == NotificationFilter.read
                          ? 'lue'
                          : ''} pour le moment',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, color: secondaryTextColor),
                    ),
                  ],
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: notificationsToShow.length,
                itemBuilder: (context, index) {
                  final notification = notificationsToShow[index];
                  final bool isRead = notification['isRead'];

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12.0),
                    color: cardColor,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side:
                          isRead
                              ? BorderSide.none
                              : BorderSide(
                                color: Colors.blue.withOpacity(0.5),
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
                          notification['icon'],
                          color: AppColors.primary,
                          size: 28,
                        ),
                      ),
                      title: Text(
                        notification['title'],
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: textColor,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            notification['message'],
                            style: TextStyle(
                              fontSize: 14,
                              color: secondaryTextColor,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            notification['date'],
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                      trailing: Row(
                        // Utilise un Row pour placer plusieurs widgets
                        mainAxisSize:
                            MainAxisSize.min, // Occupe l'espace minimal
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
                              color: secondaryTextColor,
                            ),
                            onPressed:
                                () => _deleteNotification(notification['id']),
                          ),
                        ],
                      ),
                      onTap: () {
                        _toggleNotificationReadStatus(
                          notification['id'],
                        ); // Marquer comme lu/non lu au tap
                        print('Notification tapped: ${notification['title']}');
                      },
                    ),
                  );
                },
              ),
    );
  }
}
