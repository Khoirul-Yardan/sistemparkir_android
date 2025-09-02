import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/app_db.dart';
import '../widgets/utils.dart';
import 'scan_page.dart';
import '../services/pricing.dart';

class KeluarPage extends StatefulWidget {
  const KeluarPage({super.key});

  @override
  State<KeluarPage> createState() => _KeluarPageState();
}

class _KeluarPageState extends State<KeluarPage> {
  final _kode = TextEditingController();
  DateTime? _dtMasuk;
  final DateTime _dtKeluar = DateTime.now();
  int? _biayaTambahan;
  String _jenis = 'motor';
  int? _biayaMasukAwal;
  List<Map<String, dynamic>> aktif = [];

  @override
  void initState() {
    super.initState();
    _loadAktif();
  }

  Future<void> _loadAktif([String q = '']) async {
    final db = await AppDb().database;
    List<Map<String, dynamic>> rows;
    if (q.isEmpty) {
      rows = await db.query('parkir', where: "status='IN'", orderBy: 'waktu_masuk DESC', limit: 25);
    } else {
      rows = await db.query('parkir', where: "status='IN' AND (kode LIKE ? OR plat LIKE ?)", whereArgs: ['%$q%','%$q%'], orderBy: 'waktu_masuk DESC', limit: 25);
    }
    setState(()=>aktif = rows);
  }

  Future<void> _hitung() async {
    if (_dtMasuk == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih data masuk dari daftar atau scan QR.')));
      return;
    }
    final total = await calcBiaya(jenis: _jenis, masuk: _dtMasuk!, keluar: _dtKeluar);
    setState(()=>_biayaTambahan = total);
  }

  Future<void> _simpan() async {
    if (_biayaTambahan == null || _kode.text.isEmpty) return;
    final db = await AppDb().database;
    
    final totalKeseluruhan = _biayaTambahan! + (_biayaMasukAwal ?? 0);

    await db.update('parkir', {
      'waktu_keluar': _dtKeluar.toIso8601String(),
      'biaya': totalKeseluruhan,
      'status': 'OUT',
    }, where: 'kode = ?', whereArgs: [_kode.text.trim()]);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transaksi selesai')));
      setState((){
        _biayaTambahan = null;
        _dtMasuk = null;
        _biayaMasukAwal = null;
      });
      _kode.clear();
      _loadAktif();
    }
  }

  void _setFromRow(Map<String, dynamic> r) {
    setState((){
      _kode.text = r['kode'].toString();
      _jenis = r['jenis'].toString();
      _dtMasuk = DateTime.parse(r['waktu_masuk'].toString());
      _biayaMasukAwal = r['biaya_masuk'] as int?;
      _biayaTambahan = null;
    });
  }
  
  Future<void> _loadFromCode(String k) async {
    final db = await AppDb().database;
    final r = await db.query('parkir', where: "kode=?", whereArgs: [k], limit: 1);
    if (r.isNotEmpty) _setFromRow(r.first);
  }

  // --- WIDGET DIPISAHKAN UNTUK RESPONSIVENESS ---

  // Widget untuk panel input dan pembayaran
  Widget _buildInputPanel() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Keluar / Pembayaran', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            TextField(
              controller: _kode,
              decoration: InputDecoration(
                labelText: 'Kode Tiket / Plat',
                suffixIcon: IconButton(icon: const Icon(Icons.qr_code_scanner), onPressed: (){
                  Navigator.push(context, MaterialPageRoute(builder: (_)=> ScanPage(onDetect: (k){
                    _kode.text = k;
                    _loadFromCode(k);
                  })));
                }),
              ),
              onChanged: (v)=>_loadAktif(v),
            ),
            const SizedBox(height: 12),
            Row(children: [
              ElevatedButton.icon(onPressed: _dtMasuk == null ? null : _hitung, icon: const Icon(Icons.calculate), label: const Text('Hitung')),
              const SizedBox(width: 12),
              if (_biayaTambahan != null) FilledButton.icon(onPressed: _simpan, icon: const Icon(Icons.save), label: const Text('Simpan')),
            ]),
            if (_biayaTambahan != null) Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(.2),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Tagihan Tambahan Saat Ini', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(rupiah(_biayaTambahan!), style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  if (_biayaMasukAwal != null && _biayaMasukAwal! > 0)
                    Text('Sudah dibayar saat masuk: ${rupiah(_biayaMasukAwal!)}'),
                  const Divider(height: 16),
                  Text('Total Keseluruhan: ${rupiah(_biayaTambahan! + (_biayaMasukAwal ?? 0))}', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text('Keluar: ${DateFormat('dd MMM yyyy HH:mm', 'id_ID').format(_dtKeluar)}'),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // Widget untuk daftar tiket aktif
  Widget _buildTicketList() {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16,16,16,0),
        child: Row(children: [
          Text('Tiket Aktif', style: Theme.of(context).textTheme.titleLarge),
          const Spacer(),
          IconButton(onPressed: ()=>_loadAktif(_kode.text.trim()), icon: const Icon(Icons.refresh)),
        ]),
      ),
      // Gunakan Expanded agar ListView mengisi sisa ruang
      Expanded(child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: aktif.length,
        itemBuilder: (ctx,i){
          final r = aktif[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              tileColor: _kode.text == r['kode'] ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).cardColor,
              title: Text('${r['kode']} • ${r['plat']}'),
              subtitle: Text('${r['jenis']} • Masuk: ${(r['waktu_masuk']??'').toString().replaceFirst('T',' ')}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: ()=>_setFromRow(r),
            ),
          );
        },
      )),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    // Gunakan LayoutBuilder untuk mendeteksi lebar layar
    return LayoutBuilder(builder: (context, constraints) {
      // Tentukan batas lebar layar untuk mode tampilan
      const double breakpoint = 700.0;
      final bool isWideScreen = constraints.maxWidth > breakpoint;

      if (isWideScreen) {
        // Tampilan untuk layar lebar (desktop)
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildInputPanel()),
            Expanded(child: _buildTicketList()),
          ],
        );
      } else {
        // Tampilan untuk layar sempit (mobile)
        return ListView(
          children: [
            _buildInputPanel(),
            // Beri tinggi tetap untuk daftar tiket agar bisa di-scroll di dalam ListView utama
            SizedBox(
              height: 400, // Anda bisa sesuaikan tinggi ini
              child: _buildTicketList()
            ),
          ],
        );
      }
    });
  }
}