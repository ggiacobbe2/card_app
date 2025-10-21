import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static const _databaseName = "MyDatabase.db";
  static const _databaseVersion = 1;

  static const folder = 'folder';
  static const columnId = 'id';
  static const columnName = 'name';
  static const columnPreviewImage = 'previewImage';
  static const columnCreatedAt = 'createdAt';

  static const cards = 'cards';
  static const columnSuit = 'suit';
  static const columnImageURL = 'imageURL';
  static const columnImageBytes = 'imageBytes';
  static const columnFolderId = 'folderId';

  late Database _db;

  Future<void> init() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _databaseName);

    _db = await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $folder (
        $columnId INTEGER PRIMARY KEY,
        $columnName TEXT,
        $columnPreviewImage TEXT,
        $columnCreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE $cards (
        $columnId INTEGER PRIMARY KEY,
        $columnName TEXT,
        $columnSuit TEXT,
        $columnImageURL TEXT,
        $columnImageBytes TEXT,
        $columnFolderId INTEGER,
        $columnCreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY($columnFolderId) REFERENCES $folder($columnId) ON DELETE CASCADE
      )
    ''');
  }

  Future<int> insertCard(Map<String, dynamic> row) async {
    return await _db.insert(cards, row);
  }

  Future<List<Map<String, dynamic>>> queryCards(int folderId) async {
    return await _db.query(cards, where: '$columnFolderId = ?', whereArgs: [folderId]);
  }

  Future<int> updateCard(Map<String, dynamic> row) async {
    int id = row[columnId];
    return await _db.update(cards, row, where: '$columnId = ?', whereArgs: [id]);
  }

  Future<int> deleteCard(int id) async {
    return await _db.delete(cards, where: '$columnId = ?', whereArgs: [id]);
  }
}