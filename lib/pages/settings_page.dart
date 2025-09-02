import 'package:flutter/material.dart';
import '../db/app_db.dart';
import '../services/backup_service.dart';
import 'package:sqflite/sqflite.dart';


class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _mJp = TextEditingController(text: '2000');
  final _mPj = TextEditingController(text: '1000');
  final _mMh = TextEditingController(text: '10000');
  final _bJp = TextEditingController(text: '5000');
  final _bPj = TextEditingController(text: '3000');
  final _bMh = TextEditingController(text: '30000');

  final _masukMotor = TextEditingController(text: '5000');
  final _masukMobil = TextEditingController(text: '5000');
  final _helm = TextEditingController(text: '2000');
  final _inapPerHari = TextEditingController(text: '5000');
  final _inapMinggu = TextEditingController(text: '10000');
  final _switchHour = TextEditingController(text: '18');

  // State untuk Pengaturan Login
  final _loginUsername = TextEditingController(text: 'admin');
  final _loginPassword = TextEditingController(text: 'admin');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final motor = await AppDb().getTarif('motor');
    final mobil = await AppDb().getTarif('mobil');
    setState(() {
      _mJp.text = '${motor['jp']}';
      _mPj.text = '${motor['pj']}';
      _mMh.text = '${motor['mh']}';
      _bJp.text = '${mobil['jp']}';
      _bPj.text = '${mobil['pj']}';
      _bMh.text = '${mobil['mh']}';
    });
    final db = await AppDb().database;
    Future<String> getVal(String k, String d) async {
      final r = await db.query('settings', where: 'key=?', whereArgs: [k], limit: 1);
      return (r.isEmpty?d:(r.first['value']?.toString() ?? d));
    }
    _masukMotor.text = await getVal('masuk_motor','5000');
    _masukMobil.text = await getVal('masuk_mobil','5000');
    _helm.text = await getVal('helm_deposit','2000');
    _inapPerHari.text = await getVal('inap_per_hari','5000');
    _inapMinggu.text = await getVal('inap_minggu','10000');
    _switchHour.text = await getVal('switch_hour','18');

    // Muat Pengaturan Login
    _loginUsername.text = await getVal('login_username', 'admin');
    _loginPassword.text = await getVal('login_password', 'admin');
  }

  Future<void> _save() async {
    await AppDb().setTarifDefaults(
      {'jp': int.parse(_mJp.text), 'pj': int.parse(_mPj.text), 'mh': int.parse(_mMh.text)},
      {'jp': int.parse(_bJp.text), 'pj': int.parse(_bPj.text), 'mh': int.parse(_bMh.text)},
    );
    final db = await AppDb().database;
    Future<void> put(String k, String v) async {
      await db.insert('settings', {'key':k,'value':v}, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await put('masuk_motor', _masukMotor.text);
    await put('masuk_mobil', _masukMobil.text);
    await put('helm_deposit', _helm.text);
    await put('inap_per_hari', _inapPerHari.text);
    await put('inap_minggu', _inapMinggu.text);
    await put('switch_hour', _switchHour.text);

    // Simpan Pengaturan Login
    await put('login_username', _loginUsername.text);
    await put('login_password', _loginPassword.text);

    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tersimpan.')));
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // PERUBAHAN: Card untuk Pengaturan Login disederhanakan
        _section('Pengaturan Login', [
          _textField('Username', _loginUsername),
          _textField('Password', _loginPassword),
        ]),
        _section('Tarif Motor', [
          _numField('Jam Pertama', _mJp),
          _numField('Per Jam', _mPj),
          _numField('Maks Harian', _mMh),
        ]),
        _section('Tarif Mobil', [
          _numField('Jam Pertama', _bJp),
          _numField('Per Jam', _bPj),
          _numField('Maks Harian', _bMh),
        ]),
        _section('Aturan Khusus Lokasi', [
          _numField('Biaya Masuk Motor', _masukMotor),
          _numField('Biaya Masuk Mobil', _masukMobil),
          _numField('Deposit Titip Helm', _helm),
          _numField('Biaya Inap / Tanggal', _inapPerHari),
          _numField('Biaya Inap Minggu', _inapMinggu),
          _numField('Pergantian Tanggal Jam (0-23)', _switchHour),
        ]),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: Wrap(spacing: 12, runSpacing: 12, children: [
            FilledButton.icon(onPressed: _save, icon: const Icon(Icons.save), label: const Text('Simpan')),
            OutlinedButton.icon(onPressed: () async { final f = await BackupService.exportJson(); if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Backup disimpan ke berkas: ${f.path.split('/').last}'))); }, icon: const Icon(Icons.download), label: const Text('Backup JSON')),
            OutlinedButton.icon(onPressed: () async { final n = await BackupService.importJson(); if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Restore: $n data parkir'))); }, icon: const Icon(Icons.upload), label: const Text('Restore JSON')),
          ]),
        ),
      ],
    );
  }

  Widget _numField(String label, TextEditingController c) => Padding(
    padding: const EdgeInsets.only(bottom: 8.0),
    child: TextField(
      controller: c,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label),
    ),
  );

  Widget _textField(String label, TextEditingController c) => Padding(
    padding: const EdgeInsets.only(bottom: 8.0),
    child: TextField(
      controller: c,
      decoration: InputDecoration(labelText: label),
    ),
  );

  Widget _section(String title, List<Widget> children) => Card(child: Padding(
    padding: const EdgeInsets.all(16.0),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 8),
      ...children,
    ]),
  ));
}