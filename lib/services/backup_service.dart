import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../db/app_db.dart';
import 'package:sqflite/sqflite.dart';


class BackupService {
  static Future<File> exportJson() async {
    final db = await AppDb().database;
    final parkir = await db.query('parkir');
    final settings = await db.query('settings');
    final data = {'parkir': parkir, 'settings': settings, 'exported_at': DateTime.now().toIso8601String()};
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/backup_parkir_${DateTime.now().millisecondsSinceEpoch}.json');
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(data));
    return file;
  }

  static Future<int> importJson() async {
    final res = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json']);
    if (res == null) return 0;
    final file = File(res.files.single.path!);
    final text = await file.readAsString();
    final map = json.decode(text) as Map<String, dynamic>;
    final db = await AppDb().database;
    final batch = db.batch();
    if (map['parkir'] is List) {
      for (final r in (map['parkir'] as List)) {
        batch.insert('parkir', Map<String, Object?>.from(r as Map), conflictAlgorithm: ConflictAlgorithm.replace);
      }
    }
    if (map['settings'] is List) {
      for (final r in (map['settings'] as List)) {
        batch.insert('settings', Map<String, Object?>.from(r as Map), conflictAlgorithm: ConflictAlgorithm.replace);
      }
    }
    await batch.commit(noResult: true);
    return (map['parkir'] as List?)?.length ?? 0;
  }
}
