import '../models/user.dart';
import 'db_helper.dart';

class UserService {
  static String _tableName = 'users';

  //CRUD
  //CREATE
  static Future<User> createUser(User user) async {
    final db = await DBHelper.database;
    final id = await db.insert(_tableName, user.toMap());
    return User(id: id, name: user.name, email: user.email);	
  }

  //READ
  static Future<List<User>> getUsers() async {
    final db = await DBHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(_tableName, orderBy: 'name ASC');
    return maps.map((map) => User.fromMap(map)).toList();
  }

  //READ BY ID
  static Future<User?> getUserById(int id) async {
    final db = await DBHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  //UPDATE
  static Future<int> updateUser(User user) async{
    final db = await DBHelper.database;
    return await db.update(
      _tableName,
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  //DELETE
  static Future<int> deleteUser(int id) async {
    final db = await DBHelper.database;
    return await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

}