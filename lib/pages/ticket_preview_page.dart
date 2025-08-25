import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../widgets/utils.dart';

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

  Future<Uint8List> _buildPdf() async {
    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(58 * PdfPageFormat.mm, 100 * PdfPageFormat.mm, marginAll: 8),
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Struk Parkir', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            pw.Text('Kode: $kode'),
            pw.Text('Plat: $plat'),
            pw.Text('Jenis: $jenis'),
            pw.Text('Masuk: ${masuk.toLocal()}'),
            pw.Text('Titip helm: ${titipHelm ? 'Ya' : 'Tidak'}'),
            pw.Text('Biaya masuk: ${rupiah(biayaMasuk)}'),
            pw.SizedBox(height: 8),
            pw.Container(
              alignment: pw.Alignment.center,
              child: pw.BarcodeWidget(
                data: kode,
                barcode: pw.Barcode.qrCode(),
                width: 120,
                height: 120,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Text('Terima kasih.'),
          ],
        ),
      ),
    );
    return doc.save();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tiket Masuk')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(kode, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    QrImageView(data: kode, version: QrVersions.auto, size: 200),
                    const SizedBox(height: 8),
                    Text('Plat: $plat • $jenis • ${dtHuman(masuk)}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: () async {
                    final bytes = await _buildPdf();
                    await Printing.layoutPdf(onLayout: (_) async => bytes);
                  },
                  icon: const Icon(Icons.print),
                  label: const Text('Print PDF'),
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    final bytes = await _buildPdf();
                    await Share.shareXFiles([
                      XFile.fromData(bytes, name: 'tiket_$kode.pdf', mimeType: 'application/pdf')
                    ]);
                  },
                  icon: const Icon(Icons.share),
                  label: const Text('Bagikan'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
