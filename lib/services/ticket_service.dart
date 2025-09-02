import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class TicketService {
  // Fungsi utama untuk membuat dokumen PDF dari data tiket
  static Future<Uint8List> generateTicketPdf({
    required String kode,
    required String plat,
    required String jenis,
    required DateTime masuk,
    required bool titipHelm,
    required int biayaMasuk,
  }) async {
    final doc = pw.Document();

    // Mengambil font bawaan
    final font = await PdfGoogleFonts.poppinsRegular();
    final boldFont = await PdfGoogleFonts.poppinsBold();

    // PERBAIKAN: Panggil 'networkImage' secara langsung, tanpa 'Printing.'
    final qrImageUrl = 'https://api.qrserver.com/v1/create-qr-code/?size=150x150&data=$kode';
    final qrImage = await networkImage(qrImageUrl);


    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80, // Ukuran kertas struk thermal 80mm
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Center(
                child: pw.Text(
                  'TIKET PARKIR',
                  style: pw.TextStyle(font: boldFont, fontSize: 16),
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Divider(),
              pw.SizedBox(height: 10),

              // QR Code
              pw.Center(
                child: pw.SizedBox(
                  width: 120,
                  height: 120,
                  child: pw.Image(qrImage),
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Center(
                child: pw.Text(
                  kode,
                  style: pw.TextStyle(font: boldFont, fontSize: 14),
                ),
              ),
              pw.SizedBox(height: 15),

              // Detail Tiket
              _buildDetailRow('Plat Nomor', plat.toUpperCase(), boldFont, font),
              _buildDetailRow('Jenis', jenis.toUpperCase(), boldFont, font),
              _buildDetailRow(
                  'Waktu Masuk',
                  DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(masuk),
                  boldFont,
                  font),
              if (titipHelm)
                _buildDetailRow('Titip Helm', 'YA', boldFont, font),
              _buildDetailRow(
                  'Biaya Masuk', 'Rp ${NumberFormat.decimalPattern('id_ID').format(biayaMasuk)}', boldFont, font),

              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.SizedBox(height: 10),

              // Footer
              pw.Center(
                child: pw.Text(
                  'Simpan tiket ini dengan baik.\nTerima kasih atas kunjungan Anda.',
                  style: pw.TextStyle(font: font, fontSize: 8),
                  textAlign: pw.TextAlign.center,
                ),
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  // Widget bantuan untuk membuat baris detail
  static pw.Widget _buildDetailRow(
      String title, String value, pw.Font titleFont, pw.Font valueFont) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(font: titleFont, fontSize: 10),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(font: valueFont, fontSize: 10),
          ),
        ],
      ),
    );
  }
}