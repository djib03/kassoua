import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await initDB();
    return _db!;
  }

  static Future<Database> initDB() async {
    final path = await getDatabasesPath();
    final dbPath = join(path, 'kassoua.db');

    return await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE produits_locaux (
            id TEXT PRIMARY KEY,
            nom TEXT,
            description TEXT,
            prix REAL,
            statut TEXT,
            dateAjout TEXT,
            vendeurId TEXT,
            categorieId TEXT,
            adresseId TEXT,
            isSynced INTEGER DEFAULT 0,
            lastUpdated TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE messages_locaux (
            id TEXT PRIMARY KEY,
            contenu TEXT,
            dateEnvoi TEXT,
            expediteurId TEXT,
            destinataireId TEXT,
            discussionId TEXT,
            estLu INTEGER,
            isSynced INTEGER DEFAULT 0,
            lastUpdated TEXT
          )
        ''');
      },
    );
  }
}
