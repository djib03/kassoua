import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:kassoua/controllers/auth_controller.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'app.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

void enableOfflinePersistence() {
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  enableOfflinePersistence();
  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthController(),
      child: const KassouaApp(),
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
  }

  @override
  Widget build(BuildContext context) {
    return const KassouaAppWithConnectivity();
  }
}
