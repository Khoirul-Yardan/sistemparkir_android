import 'package:flutter/material.dart';
import '../db/app_db.dart';
import '../services/code_gen.dart';
import 'ticket_preview_page.dart';

class MasukPage extends StatefulWidget {
  const MasukPage({super.key});

  @override
  State<MasukPage> createState() => _MasukPageState();
}

class _MasukPageState extends State<MasukPage> {
  final _form = GlobalKey<FormState>();
  final _plat = TextEditingController();
  String _jenis = 'motor';
  bool _titipHelm = false;
  bool _busy = false;

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    final db = await AppDb().database;
    String code;
    while (true) {
      code = generateTicketCode();
      final exists =
          await db.query('parkir', where: 'kode=?', whereArgs: [code], limit: 1);
      if (exists.isEmpty) break;
    }
    // entrance fee
    final st = await db.query('settings',
        where: 'key IN (?,?)', whereArgs: ['masuk_motor', 'masuk_mobil']);
    int biayaMasuk = 5000;
    for (final r in st) {
      if (r['key'] == 'masuk_motor' && _jenis == 'motor') {
        biayaMasuk = int.parse((r['value'] ?? '5000').toString());
      }
      if (r['key'] == 'masuk_mobil' && _jenis == 'mobil') {
        biayaMasuk = int.parse((r['value'] ?? '5000').toString());
      }
    }
    final helmRows = await db
        .query('settings', where: 'key=?', whereArgs: ['helm_deposit'], limit: 1);
    final helm = int.tryParse(
            (helmRows.isNotEmpty ? helmRows.first['value'] : '2000').toString()) ??
        2000;
    final masuk = DateTime.now();
    final totalMasuk = biayaMasuk + (_titipHelm ? helm : 0);

    // --- PERBAIKAN DI SINI ---
    // 1. Simpan status 'titipHelm' saat ini ke variabel baru sebelum direset.
    final bool isTitipHelm = _titipHelm;

    await db.insert('parkir', {
      'kode': code,
      'plat': _plat.text.trim().toUpperCase(),
      'jenis': _jenis,
      'waktu_masuk': masuk.toIso8601String(),
      'status': 'IN',
      'titip_helm': isTitipHelm ? 1 : 0, // 2. Gunakan variabel baru ini untuk database.
      'biaya_masuk': totalMasuk,
    });
    if (mounted) {
      final platNow = _plat.text.toUpperCase();
      // Reset form setelah semua data disimpan dan siap dikirim
      _plat.clear();
      setState(() {
        _titipHelm = false;
        _busy = false;
      });
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TicketPreviewPage(
            kode: code,
            plat: platNow,
            jenis: _jenis,
            masuk: masuk,
            titipHelm: isTitipHelm, // 3. Gunakan variabel baru ini untuk dikirim ke halaman pratinjau.
            biayaMasuk: totalMasuk,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _form,
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Input Masuk', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              TextFormField(
                controller: _plat,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(labelText: 'Plat Nomor'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _jenis,
                items: const [
                  DropdownMenuItem(value: 'motor', child: Text('Motor')),
                  DropdownMenuItem(value: 'mobil', child: Text('Mobil')),
                ],
                onChanged: (v) => setState(() => _jenis = v ?? 'motor'),
                decoration: const InputDecoration(labelText: 'Jenis'),
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                value: _titipHelm,
                onChanged: (v) => setState(() => _titipHelm = v ?? false),
                title: const Text('Titip helm (+ deposit)'),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                  onPressed: _busy ? null : _save,
                  icon: const Icon(Icons.qr_code),
                  label: Text(
                      _busy ? 'Menyimpan...' : 'Simpan & Buat QR')),
              const SizedBox(height: 8),
              const Text('Kode tiket dibuat otomatis & dicek agar unik.'),
            ]),
          ),
        ),
      ),
    );
  }
}