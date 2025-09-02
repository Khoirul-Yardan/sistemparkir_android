import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:excel/excel.dart';
import 'dart:io';

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
  
  int totalAkhir = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = await AppDb().database;
    final endOfDayTo = DateTime(to.year, to.month, to.day, 23, 59, 59);
    final fromDateString = from.toIso8601String();
    final toDateString = endOfDayTo.toIso8601String();

    final r = await db.query('parkir',
        where: '(waktu_masuk >= ? AND waktu_masuk <= ?) OR (waktu_keluar >= ? AND waktu_keluar <= ?)',
        whereArgs: [fromDateString, toDateString, fromDateString, toDateString],
        orderBy: 'waktu_masuk DESC');
    
    int sumAkhir = 0;
    for (final x in r) {
      if (x['status'] == 'OUT') {
        sumAkhir += (x['biaya'] as int?) ?? 0;
      } else {
        sumAkhir += (x['biaya_masuk'] as int?) ?? 0;
      }
    }

    setState(() {
      rows = r;
      totalAkhir = sumAkhir;
    });
  }

  Future<void> _pickFrom() async {
    final d = await showDatePicker(
        context: context,
        firstDate: DateTime(2022),
        lastDate: DateTime(DateTime.now().year + 1),
        initialDate: from);
    if (d != null) setState(() => from = DateTime(d.year, d.month, d.day));
  }

  Future<void> _pickTo() async {
    final d = await showDatePicker(
        context: context,
        firstDate: DateTime(2022),
        lastDate: DateTime(DateTime.now().year + 1),
        initialDate: to);
    if (d != null) {
      setState(() =>
          to = DateTime(d.year, d.month, d.day, 23, 59, 59));
    }
  }

  Future<void> _deleteRow(String kode) async {
    final db = await AppDb().database;
    await db.delete('parkir', where: 'kode=?', whereArgs: [kode]);
    _load();
  }

  Future<void> _resetAll() async {
    final bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Konfirmasi Hapus Data"),
        content: const Text(
            "Apakah Anda yakin ingin menghapus SEMUA data rekap parkir? Tindakan ini tidak dapat diurungkan."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Batal"),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Ya, Hapus Semua"),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final db = await AppDb().database;
      await db.delete('parkir');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Semua data rekap telah berhasil dihapus."),
          backgroundColor: Colors.green,
        ),
      );
      _load();
    }
  }

  Future<void> _editRow(Map<String, dynamic> r) async {
    final platCtrl = TextEditingController(text: r['plat']?.toString() ?? '');
    final jenisCtrl = TextEditingController(text: r['jenis']?.toString() ?? '');
    final biayaCtrl =
        TextEditingController(text: (r['biaya'] ?? '').toString());

    await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              title: const Text("Edit Data"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: platCtrl, decoration: const InputDecoration(labelText: "Plat")),
                  TextField(controller: jenisCtrl, decoration: const InputDecoration(labelText: "Jenis")),
                  TextField(controller: biayaCtrl, decoration: const InputDecoration(labelText: "Biaya")),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
                ElevatedButton(
                    onPressed: () async {
                      final db = await AppDb().database;
                      await db.update(
                          'parkir',
                          {
                            'plat': platCtrl.text,
                            'jenis': jenisCtrl.text,
                            'biaya': int.tryParse(biayaCtrl.text) ?? r['biaya']
                          },
                          where: 'kode=?',
                          whereArgs: [r['kode']]);
                      Navigator.pop(ctx);
                      _load();
                    },
                    child: const Text("Simpan")),
              ],
            ));
  }
  
  Future<void> _exportExcel(String mode) async {
    DateTime now = to;
    DateTime fromDate;
    DateTime toDate;
    String reportTitle;

    if (mode == 'harian') {
      fromDate = DateTime(now.year, now.month, now.day);
      toDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
      reportTitle = "Laporan Harian (${DateFormat('d MMMM yyyy', 'id_ID').format(fromDate)})";
    } else if (mode == 'mingguan') {
      fromDate = now.subtract(Duration(days: now.weekday - 1));
      fromDate = DateTime(fromDate.year, fromDate.month, fromDate.day);
      toDate = fromDate.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
      reportTitle = "Laporan Mingguan (${DateFormat('d MMM', 'id_ID').format(fromDate)} - ${DateFormat('d MMM yyyy', 'id_ID').format(toDate)})";
    } else { // bulanan
      fromDate = DateTime(now.year, now.month, 1);
      toDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      reportTitle = "Laporan Bulanan (${DateFormat('MMMM yyyy', 'id_ID').format(fromDate)})";
    }

    final db = await AppDb().database;
    final fromDateString = fromDate.toIso8601String();
    final toDateString = toDate.toIso8601String();

    final dataToExport = await db.query('parkir',
        where: '(waktu_masuk >= ? AND waktu_masuk <= ?) OR (waktu_keluar >= ? AND waktu_keluar <= ?)',
        whereArgs: [fromDateString, toDateString, fromDateString, toDateString],
        orderBy: 'waktu_masuk ASC');

    if (dataToExport.isEmpty) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Tidak ada data untuk diekspor pada periode ini.")));
      }
      return;
    }

    final excel = Excel.createExcel();
    
    // --- SHEET DATA MASUK (BASIC) ---
    final sheetMasuk = excel['Data Masuk'];
    sheetMasuk.appendRow([TextCellValue("Data Masuk - $reportTitle")]);

    final headersMasuk = [ "Kode", "Plat", "Jenis", "Waktu Masuk", "Biaya Masuk", "Titip Helm"];
    sheetMasuk.appendRow(headersMasuk.map((e) => TextCellValue(e)).toList());

    for (final r in dataToExport.where((d) => d['status'] == 'IN')) {
      sheetMasuk.appendRow([
        TextCellValue(r['kode']?.toString() ?? ''),
        TextCellValue(r['plat']?.toString() ?? ''),
        TextCellValue(r['jenis']?.toString() ?? ''),
        TextCellValue((r['waktu_masuk'] ?? '').toString()),
        IntCellValue((r['biaya_masuk'] as int?) ?? 0),
        TextCellValue(((r['titip_helm'] as int?) ?? 0) == 1 ? 'Ya' : 'Tidak'),
      ]);
    }

    // --- SHEET DATA KELUAR (BASIC) ---
    final sheetKeluar = excel['Data Keluar'];
    sheetKeluar.appendRow([TextCellValue("Data Keluar - $reportTitle")]);
    
    final headersKeluar = ["Kode", "Plat", "Jenis", "Waktu Masuk", "Waktu Keluar", "Total Biaya"];
    sheetKeluar.appendRow(headersKeluar.map((e) => TextCellValue(e)).toList());

    for (final r in dataToExport.where((d) => d['status'] == 'OUT')) {
      sheetKeluar.appendRow([
        TextCellValue(r['kode']?.toString() ?? ''),
        TextCellValue(r['plat']?.toString() ?? ''),
        TextCellValue(r['jenis']?.toString() ?? ''),
        TextCellValue((r['waktu_masuk'] ?? '').toString()),
        TextCellValue((r['waktu_keluar'] ?? '').toString()),
        IntCellValue((r['biaya'] as int?) ?? 0),
      ]);
    }

    // --- PERUBAHAN: Semua styling dan auto-fit dihapus ---

    excel.delete('Sheet1');

    final dir = await getApplicationDocumentsDirectory();
    final file = File("${dir.path}/rekap_${mode}_${DateTime.now().millisecondsSinceEpoch}.xlsx");
    
    final excelData = excel.encode();
    if (excelData != null) {
      await file.writeAsBytes(excelData);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("File disimpan: ${file.path}")));
        OpenFilex.open(file.path);
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
            child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Wrap(
              runSpacing: 12,
              spacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ElevatedButton.icon(
                    onPressed: _pickFrom,
                    icon: const Icon(Icons.date_range),
                    label: Text('Dari: ${from.toString().substring(0, 10)}')),
                ElevatedButton.icon(
                    onPressed: _pickTo,
                    icon: const Icon(Icons.event),
                    label: Text('Sampai: ${to.toString().substring(0, 10)}')),
                FilledButton.icon(
                    onPressed: _load,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Terapkan')),
                const SizedBox(width: 8),
                
                Chip(
                  backgroundColor: Colors.green.shade800,
                  padding: const EdgeInsets.all(8),
                  label: Text(
                    'Total Akhir: ${rupiah(totalAkhir)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  )
                ),

                PopupMenuButton<String>(
                  iconColor: Colors.white,
                  onSelected: (value) {
                    if (value.isNotEmpty) _exportExcel(value);
                  },
                  itemBuilder: (ctx) => const [
                    PopupMenuItem(value: "harian", child: Text("Export Harian")),
                    PopupMenuItem(value: "mingguan", child: Text("Export Mingguan")),
                    PopupMenuItem(value: "bulanan", child: Text("Export Bulanan")),
                  ],
                  child: const Tooltip(message: "Export Laporan", child: Icon(Icons.download)),
                ),
                IconButton(
                  tooltip: "Reset Semua Data",
                  style: IconButton.styleFrom(backgroundColor: Colors.red.withOpacity(0.1)),
                  onPressed: _resetAll,
                  icon: const Icon(Icons.delete_forever, color: Colors.red),
                )
              ]),
        )),
        Card(
            child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
              headingRowColor: MaterialStateProperty.all(Colors.blueGrey.shade800),
              columns: const [
                DataColumn(label: Text('Kode', style: TextStyle(color: Colors.white))),
                DataColumn(label: Text('Plat', style: TextStyle(color: Colors.white))),
                DataColumn(label: Text('Jenis', style: TextStyle(color: Colors.white))),
                DataColumn(label: Text('Masuk', style: TextStyle(color: Colors.white))),
                DataColumn(label: Text('Keluar', style: TextStyle(color: Colors.white))),
                DataColumn(label: Text('Biaya Masuk', style: TextStyle(color: Colors.white))),
                DataColumn(label: Text('Total Akhir', style: TextStyle(color: Colors.white))),
                DataColumn(label: Text('Status', style: TextStyle(color: Colors.white))),
                DataColumn(label: Text('Aksi', style: TextStyle(color: Colors.white))),
              ],
              rows: [
                for (final r in rows)
                  DataRow(
                    cells: [
                      DataCell(Text(r['kode']?.toString() ?? '', style: const TextStyle(color: Colors.white))),
                      DataCell(Text(r['plat']?.toString() ?? '', style: const TextStyle(color: Colors.white))),
                      DataCell(Text(r['jenis']?.toString() ?? '', style: const TextStyle(color: Colors.white))),
                      DataCell(Text((r['waktu_masuk'] ?? '').toString().split('.').first.replaceFirst('T', ' '), style: const TextStyle(color: Colors.white))),
                      DataCell(Text((r['waktu_keluar'] ?? '-').toString().split('.').first.replaceFirst('T', ' '), style: const TextStyle(color: Colors.white))),
                      DataCell(Text(r['biaya_masuk'] == null ? '-' : rupiah(r['biaya_masuk'] as int), style: const TextStyle(color: Colors.white))),
                      DataCell(Text(r['biaya'] == null ? '-' : rupiah(r['biaya'] as int), style: const TextStyle(color: Colors.white))),
                      DataCell(Text(r['status']?.toString() ?? '', style: const TextStyle(color: Colors.white))),
                      DataCell(Row(
                        children: [
                          IconButton(onPressed: () => _editRow(r), icon: const Icon(Icons.edit, color: Colors.lightBlueAccent), tooltip: "Edit"),
                          IconButton(onPressed: () => _deleteRow(r['kode'].toString()), icon: const Icon(Icons.delete, color: Colors.redAccent), tooltip: "Hapus"),
                        ],
                      ))
                    ]),
              ]),
        )),
      ],
    );
  }
}