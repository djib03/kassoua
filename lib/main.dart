import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:kassoua/controllers/auth_controller.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'app.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Gère la notification en arrière-plan
}

void enableOfflinePersistence() {
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  enableOfflinePersistence();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialisation des notifications locales
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthController(),
      child: const KassouaAppWithConnectivity(), // <-- c'est bien ce widget ici
    ),
  );
}

class KassouaAppWithConnectivity extends StatefulWidget {
  const KassouaAppWithConnectivity({super.key});

  @override
  State<KassouaAppWithConnectivity> createState() =>
      _KassouaAppWithConnectivityState();
}

class _KassouaAppWithConnectivityState
    extends State<KassouaAppWithConnectivity> {
  late final Connectivity _connectivity;
  ConnectivityResult? _lastResult;

  @override
  void initState() {
    super.initState();
    _connectivity = Connectivity();
    _connectivity.onConnectivityChanged.listen((result) {
      if (_lastResult != result) {
        _lastResult = result;
        final isOnline = result != ConnectivityResult.none;
        // ignore: use_build_context_synchronously
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isOnline ? 'Vous êtes en ligne' : 'Vous êtes hors ligne',
              ),
              backgroundColor: isOnline ? Colors.green : Colors.red,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    });

    // Ajoute ceci pour afficher les notifications en premier plan
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      RemoteNotification? notification = message.notification;
      if (notification != null) {
        // Affiche la notif locale
        flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'chat_channel',
              'Chat',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
        );

        // Sauvegarde la notif dans Firestore
        await FirebaseFirestore.instance.collection('notifications').add({
          'title': notification.title ?? '',
          'message': notification.body ?? '',
          'dateEnvoi': FieldValue.serverTimestamp(),
          'isRead': false,
          'type': message.data['type'] ?? 'info', // optionnel
          'userId':
              FirebaseAuth.instance.currentUser?.uid, // pour filtrer par user
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const KassouaApp(); // <-- et pas KassouaAppWithConnectivity !
  }
}

FirebaseMessaging messaging = FirebaseMessaging.instance;

void askNotificationPermission() async {
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
}
