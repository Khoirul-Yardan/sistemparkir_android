import 'package:flutter/material.dart';
import '../db/app_db.dart';
import '../widgets/utils.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int aktif = 0;
  int totalHariIni = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = await AppDb().database;
    final a = await db.rawQuery("SELECT COUNT(*) AS c FROM parkir WHERE status='IN'"); 
    final cAktif = (a.first['c'] as int?) ?? (a.first['c'] as num).toInt();
    final now = DateTime.now();
    final from = DateTime(now.year, now.month, now.day);
    final to = from.add(const Duration(days: 1));
    final rows = await db.query('parkir', where: 'waktu_keluar IS NOT NULL AND waktu_keluar >= ? AND waktu_keluar < ?', whereArgs: [from.toIso8601String(), to.toIso8601String()]);
    int sum = 0; for (final r in rows) { sum += (r['biaya'] as int?) ?? 0; }
    setState(()=>{ aktif = cAktif, totalHariIni = sum });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(spacing: 12, runSpacing: 12, children: [
            _statCard('Kendaraan Aktif', '$aktif unit', Icons.local_parking),
            _statCard('Pendapatan Hari Ini', rupiah(totalHariIni), Icons.payments),
          ]),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Tips', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                const Text('Gunakan Masuk untuk membuat tiket QR. Di Keluar, scan QR atau cari kode untuk hitung biaya.'),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon) => SizedBox(
    width: 280,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Theme.of(context).colorScheme.primary.withOpacity(.12),
            ),
            child: Icon(icon),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 6),
            Text(value, style: Theme.of(context).textTheme.headlineSmall),
          ])),
        ]),
      ),
    ),
  );
}
