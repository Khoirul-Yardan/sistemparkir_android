import 'package:flutter/material.dart';
import '../db/app_db.dart';
import '../widgets/utils.dart';

class RekapPage extends StatefulWidget {
  const RekapPage({super.key});

  @override
  State<RekapPage> createState() => _RekapPageState();
}

class _RekapPageState extends State<RekapPage> {
  DateTime from = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime to = DateTime.now();
  List<Map<String, dynamic>> rows = [];
  int total = 0;

  Future<void> _load() async {
    final db = await AppDb().database;
    final r = await db.query('parkir',
        where: 'waktu_masuk >= ? AND waktu_masuk <= ?',
        whereArgs: [from.toIso8601String(), to.toIso8601String()],
        orderBy: 'waktu_masuk DESC');
    int sum = 0;
    for (final x in r) { sum += (x['biaya'] as int?) ?? (x['biaya_masuk'] as int?) ?? 0; }
    setState(()=>{ rows = r, total = sum });
  }

  Future<void> _pickFrom() async {
    final d = await showDatePicker(context: context, firstDate: DateTime(2022), lastDate: DateTime(DateTime.now().year+1), initialDate: from);
    if (d!=null) setState(()=>from = DateTime(d.year, d.month, d.day));
  }

  Future<void> _pickTo() async {
    final d = await showDatePicker(context: context, firstDate: DateTime(2022), lastDate: DateTime(DateTime.now().year+1), initialDate: to);
    if (d!=null) setState(()=>to = DateTime(d.year, d.month, d.day, 23, 59, 59));
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Wrap(runSpacing: 12, spacing: 12, crossAxisAlignment: WrapCrossAlignment.center, children: [
            ElevatedButton.icon(onPressed: _pickFrom, icon: const Icon(Icons.date_range), label: Text('Dari: ${from.toString().substring(0,10)}')),
            ElevatedButton.icon(onPressed: _pickTo, icon: const Icon(Icons.event), label: Text('Sampai: ${to.toString().substring(0,10)}')),
            FilledButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('Terapkan')),
            Chip(label: Text('Total: ${rupiah(total)}')),
          ]),
        )),
        Card(child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(columns: const [
            DataColumn(label: Text('Kode')),
            DataColumn(label: Text('Plat')),
            DataColumn(label: Text('Jenis')),
            DataColumn(label: Text('Masuk')),
            DataColumn(label: Text('Keluar')),
            DataColumn(label: Text('Biaya Masuk')),
            DataColumn(label: Text('Biaya Keluar')),
            DataColumn(label: Text('Status')),
          ], rows: [
            for (final r in rows) DataRow(cells: [
              DataCell(Text(r['kode']?.toString() ?? '')),
              DataCell(Text(r['plat']?.toString() ?? '')),
              DataCell(Text(r['jenis']?.toString() ?? '')),
              DataCell(Text((r['waktu_masuk']??'').toString().replaceFirst('T', ' '))),
              DataCell(Text((r['waktu_keluar']??'-').toString().replaceFirst('T', ' '))),
              DataCell(Text(r['biaya_masuk']==null?'-':rupiah(r['biaya_masuk'] as int))),
              DataCell(Text(r['biaya']==null?'-':rupiah(r['biaya'] as int))),
              DataCell(Text(r['status']?.toString() ?? '')),
            ])
          ]),
        )),
      ],
    );
  }
}
