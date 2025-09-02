import 'dart:async';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class AppDb {
  static final AppDb _i = AppDb._internal();
  factory AppDb() => _i;
  AppDb._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, 'sistem_parkir.db');
    return openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
        CREATE TABLE parkir(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          kode TEXT UNIQUE NOT NULL,
          plat TEXT NOT NULL,
          jenis TEXT NOT NULL,
          waktu_masuk TEXT NOT NULL,
          waktu_keluar TEXT,
          biaya INTEGER,
          status TEXT NOT NULL DEFAULT 'IN',
          titip_helm INTEGER DEFAULT 0,
          biaya_masuk INTEGER
        );
        ''');
        await db.execute('''
        CREATE TABLE settings(
          key TEXT PRIMARY KEY,
          value TEXT
        );
        ''');
        // default tarif/aturan
        await db.insert('settings', {'key':'tarif_motor_jp','value':'2000'});
        await db.insert('settings', {'key':'tarif_motor_pj','value':'1000'});
        await db.insert('settings', {'key':'tarif_motor_mh','value':'10000'});
        await db.insert('settings', {'key':'tarif_mobil_jp','value':'5000'});
        await db.insert('settings', {'key':'tarif_mobil_pj','value':'3000'});
        await db.insert('settings', {'key':'tarif_mobil_mh','value':'30000'});
        await db.insert('settings', {'key':'masuk_motor','value':'5000'});
        await db.insert('settings', {'key':'masuk_mobil','value':'5000'});
        await db.insert('settings', {'key':'helm_deposit','value':'2000'});
        await db.insert('settings', {'key':'inap_per_hari','value':'5000'});
        await db.insert('settings', {'key':'inap_minggu','value':'10000'});
        await db.insert('settings', {'key':'switch_hour','value':'18'});

        // Pengaturan Login Default
        await db.insert('settings', {'key':'login_username','value':'admin'});
        await db.insert('settings', {'key':'login_password','value':'admin'});
      },
      onUpgrade: (db, oldV, newV) async {
        if (oldV < 2) {
          await db.execute("ALTER TABLE parkir ADD COLUMN titip_helm INTEGER DEFAULT 0");
          await db.execute("ALTER TABLE parkir ADD COLUMN biaya_masuk INTEGER");
          await db.insert('settings', {'key':'masuk_motor','value':'5000'}, conflictAlgorithm: ConflictAlgorithm.ignore);
          await db.insert('settings', {'key':'masuk_mobil','value':'5000'}, conflictAlgorithm: ConflictAlgorithm.ignore);
          await db.insert('settings', {'key':'helm_deposit','value':'2000'}, conflictAlgorithm: ConflictAlgorithm.ignore);
          await db.insert('settings', {'key':'inap_per_hari','value':'5000'}, conflictAlgorithm: ConflictAlgorithm.ignore);
          await db.insert('settings', {'key':'inap_minggu','value':'10000'}, conflictAlgorithm: ConflictAlgorithm.ignore);
          await db.insert('settings', {'key':'switch_hour','value':'18'}, conflictAlgorithm: ConflictAlgorithm.ignore);

          // PERUBAHAN: Hapus 'login_enabled'
          await db.insert('settings', {'key':'login_username','value':'admin'}, conflictAlgorithm: ConflictAlgorithm.ignore);
          await db.insert('settings', {'key':'login_password','value':'admin'}, conflictAlgorithm: ConflictAlgorithm.ignore);
        }
      },
    );
  }

  // ... sisa kode tidak perlu diubah ...
  Future<Map<String, int>> getTarif(String jenis) async {
    final db = await database;
    final prefix = jenis == 'mobil' ? 'tarif_mobil' : 'tarif_motor';
    final rows = await db.query('settings', where: "key LIKE ?", whereArgs: ['${prefix}_%']);
    final map = { for (final r in rows) r['key'] as String : int.parse((r['value'] ?? '0') as String) };
    return {
      'jp': map['${prefix}_jp'] ?? (jenis=='mobil'?5000:2000),
      'pj': map['${prefix}_pj'] ?? (jenis=='mobil'?3000:1000),
      'mh': map['${prefix}_mh'] ?? (jenis=='mobil'?30000:10000),
    };
  }

  Future<void> setTarifDefaults(Map<String, int> motor, Map<String, int> mobil) async {
    final db = await database;
    await db.insert('settings', {'key':'tarif_motor_jp','value':'${motor['jp']}'}, conflictAlgorithm: ConflictAlgorithm.replace);
    await db.insert('settings', {'key':'tarif_motor_pj','value':'${motor['pj']}'}, conflictAlgorithm: ConflictAlgorithm.replace);
    await db.insert('settings', {'key':'tarif_motor_mh','value':'${motor['mh']}'}, conflictAlgorithm: ConflictAlgorithm.replace);
    await db.insert('settings', {'key':'tarif_mobil_jp','value':'${mobil['jp']}'}, conflictAlgorithm: ConflictAlgorithm.replace);
    await db.insert('settings', {'key':'tarif_mobil_pj','value':'${mobil['pj']}'}, conflictAlgorithm: ConflictAlgorithm.replace);
    await db.insert('settings', {'key':'tarif_mobil_mh','value':'${mobil['mh']}'}, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}