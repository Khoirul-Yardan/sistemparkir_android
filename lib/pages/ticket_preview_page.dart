import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../services/ticket_service.dart';

class TicketPreviewPage extends StatelessWidget {
  final String kode;
  final String plat;
  final String jenis;
  final DateTime masuk;
  final bool titipHelm;
  final int biayaMasuk;

  const TicketPreviewPage({
    super.key,
    required this.kode,
    required this.plat,
    required this.jenis,
    required this.masuk,
    required this.titipHelm,
    required this.biayaMasuk,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tiket Parkir')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const Text('TIKET PARKIR', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 24),
                    QrImageView(
                      data: kode,
                      version: QrVersions.auto,
                      size: 200.0,
                    ),
                    const SizedBox(height: 16),
                    Text(kode, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 2)),
                    const SizedBox(height: 24),
                    _buildInfoRow('Plat Nomor:', plat.toUpperCase()),
                    _buildInfoRow('Jenis:', jenis.toUpperCase()),
                    _buildInfoRow('Waktu Masuk:', DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(masuk)),
                    if (titipHelm) _buildInfoRow('Titip Helm:', 'YA'),
                    const SizedBox(height: 16),
                    const Text('Simpan tiket ini untuk proses keluar.'),
                  ],
                ),
              ),
            ),
            const Spacer(),
            FilledButton.icon(
              icon: const Icon(Icons.print),
              label: const Text('Print Tiket'),
              onPressed: () async {
                final pdfData = await TicketService.generateTicketPdf(
                  kode: kode,
                  plat: plat,
                  jenis: jenis,
                  masuk: masuk,
                  titipHelm: titipHelm,
                  biayaMasuk: biayaMasuk,
                );
                await Printing.layoutPdf(onLayout: (format) => pdfData);
              },
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.share),
              label: const Text('Bagikan Tiket'),
              onPressed: () async {
                final pdfData = await TicketService.generateTicketPdf(
                  kode: kode,
                  plat: plat,
                  jenis: jenis,
                  masuk: masuk,
                  titipHelm: titipHelm,
                  biayaMasuk: biayaMasuk,
                );
                final tempDir = await getTemporaryDirectory();
                final file = await File('${tempDir.path}/tiket_parkir_$kode.pdf').create();
                await file.writeAsBytes(pdfData);

                await Share.shareXFiles([XFile(file.path)], text: 'Tiket Parkir untuk plat $plat');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }
}