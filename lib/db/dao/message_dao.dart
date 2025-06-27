import 'package:sqflite/sqflite.dart';
import 'package:kassoua/db/database_helper.dart';
import 'package:kassoua/models/sqlite/produit_local.dart';

class ProductDao {
  static Future<void> insertProduit(ProduitLocal produit) async {
    final db = await DatabaseHelper.database;
    await db.insert(
      'produits_locaux',
      produit.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<ProduitLocal>> getAllProduits() async {
    final db = await DatabaseHelper.database;
    final result = await db.query('produits_locaux');
    return result.map((e) => ProduitLocal.fromMap(e)).toList();
  }

  static Future<void> updateProduit(ProduitLocal produit) async {
    final db = await DatabaseHelper.database;
    await db.update(
      'produits_locaux',
      produit.toMap(),
      where: 'id = ?',
      whereArgs: [produit.id],
    );
  }

  static Future<void> deleteProduit(String id) async {
    final db = await DatabaseHelper.database;
    await db.delete('produits_locaux', where: 'id = ?', whereArgs: [id]);
  }
}
