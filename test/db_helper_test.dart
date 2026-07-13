import 'package:crud_sqlite/services/db_helper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('DBHelper initializes the users database', () async {
    await DBHelper.close();

    final db = await DBHelper.database;
    expect(db.isOpen, isTrue);

    await db.execute('SELECT 1');
    await DBHelper.close();
  });
}
