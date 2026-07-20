import '../models/contact.dart';
import 'db_helper.dart';

class ContactService {
  static const String _tableName = 'contacts';

  // CREATE
  static Future<Contact> createContact(Contact contact) async {
    final db = await DBHelper.database;
    final id = await db.insert(_tableName, contact.toMap());
    return Contact(
      id: id,
      name: contact.name,
      phone: contact.phone,
      email: contact.email,
      isFavorite: contact.isFavorite,
    );
  }

  // READ ALL
  static Future<List<Contact>> getContacts() async {
    final db = await DBHelper.database;
    // Order by favorite first, then by name
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      orderBy: 'is_favorite DESC, name ASC',
    );
    return maps.map((map) => Contact.fromMap(map)).toList();
  }

  // READ BY ID
  static Future<Contact?> getContactById(int id) async {
    final db = await DBHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Contact.fromMap(maps.first);
    }
    return null;
  }

  // UPDATE
  static Future<int> updateContact(Contact contact) async {
    final db = await DBHelper.database;
    return await db.update(
      _tableName,
      contact.toMap(),
      where: 'id = ?',
      whereArgs: [contact.id],
    );
  }

  // TOGGLE FAVORITE
  static Future<int> toggleFavorite(Contact contact) async {
    final db = await DBHelper.database;
    return await db.update(
      _tableName,
      {'is_favorite': contact.isFavorite ? 0 : 1},
      where: 'id = ?',
      whereArgs: [contact.id],
    );
  }

  // DELETE
  static Future<int> deleteContact(int id) async {
    final db = await DBHelper.database;
    return await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
