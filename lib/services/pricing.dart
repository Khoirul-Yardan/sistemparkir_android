import '../db/app_db.dart';

Future<int> calcBiaya({
  required String jenis, // 'motor' or 'mobil'
  required DateTime masuk,
  required DateTime keluar,
  bool includeEntrance = false,
}) async {
  final db = await AppDb().database;
  // Load settings with fallback defaults
  Future<int> getInt(String k, int d) async {
    final rows = await db.query('settings', where: 'key=?', whereArgs: [k], limit: 1);
    if (rows.isEmpty) return d;
    return int.tryParse((rows.first['value'] ?? '$d').toString()) ?? d;
  }

  final entrance = await getInt(jenis=='mobil' ? 'masuk_mobil' : 'masuk_motor', 5000);
  final inapPerHari = await getInt('inap_per_hari', 5000);
  final inapMinggu = await getInt('inap_minggu', 10000);
  final switchHour = await getInt('switch_hour', 18);

  int total = 0;
  if (includeEntrance) total += entrance;

  DateTime cursor = masuk;
  while (cursor.isBefore(keluar)) {
    DateTime boundary = DateTime(cursor.year, cursor.month, cursor.day, switchHour);
    if (!cursor.isBefore(boundary)) {
      boundary = boundary.add(const Duration(days: 1));
    }
    final segmentEnd = keluar.isBefore(boundary) ? keluar : boundary;
    if (segmentEnd.isAtSameMomentAs(boundary)) {
      final isSunday = cursor.weekday == DateTime.sunday;
      total += isSunday ? inapMinggu : inapPerHari;
    }
    cursor = segmentEnd;
    if (segmentEnd.isAtSameMomentAs(boundary)) {
      cursor = cursor.add(const Duration(seconds: 1));
    }
  }
  return total;
}

Future<int> getHelmDeposit() async {
  final db = await AppDb().database;
  final rows = await db.query('settings', where: 'key=?', whereArgs: ['helm_deposit'], limit: 1);
  if (rows.isEmpty) return 2000;
  return int.tryParse((rows.first['value'] ?? '2000').toString()) ?? 2000;
}
