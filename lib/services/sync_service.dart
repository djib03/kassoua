import 'package:cloud_firestore/cloud_firestore.dart';
import '../db/database_helper.dart';
import '../services/connectivity_service.dart';

class SyncService {
  static Future<void> syncProduitsLocaux() async {
    if (!await NetworkService.isConnected()) return;
    final db = await DatabaseHelper.database;

    final produits = await db.query(
      'produits_locaux',
      where: 'isSynced = ?',
      whereArgs: [0],
    );
    for (final produit in produits) {
      await FirebaseFirestore.instance
          .collection('produits')
          .doc(produit['id'].toString())
          .set(produit);
      await db.update(
        'produits_locaux',
        {'isSynced': 1, 'lastUpdated': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [produit['id']],
      );
    }
  }

  static Future<void> syncMessagesLocaux() async {
    if (!await NetworkService.isConnected()) return;
    final db = await DatabaseHelper.database;

    final messages = await db.query(
      'messages_locaux',
      where: 'isSynced = ?',
      whereArgs: [0],
    );
    for (final msg in messages) {
      await FirebaseFirestore.instance
          .collection('discussions')
          .doc(msg['discussionId'].toString())
          .collection('messages')
          .doc(msg['id'].toString())
          .set(msg);
      await db.update(
        'messages_locaux',
        {'isSynced': 1, 'lastUpdated': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [msg['id']],
      );
    }
  }

  static Future<void> synchroniserTout() async {
    await syncProduitsLocaux();
    await syncMessagesLocaux();
  }
}
