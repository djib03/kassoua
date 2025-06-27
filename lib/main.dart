import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:kassoua/controllers/auth_controller.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'app.dart';

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
