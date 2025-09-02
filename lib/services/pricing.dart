import 'dart:math';
import '../db/app_db.dart';

/// Menghitung biaya parkir berdasarkan durasi dan aturan inap.
/// Biaya yang dihitung di sini adalah BIAYA TAMBAHAN di luar biaya masuk awal.
Future<int> calcBiaya({
  required String jenis,
  required DateTime masuk,
  required DateTime keluar,
}) async {
  final db = await AppDb().database;

  // Ambil semua pengaturan yang relevan dari database
  final settingsRows = await db.query('settings');
  final settings = { for (final r in settingsRows) r['key'] as String : r['value']?.toString() ?? '0' };

  // Helper untuk mengambil nilai integer dari settings dengan fallback default
  int getSettingInt(String key, int defaultValue) {
    return int.tryParse(settings[key] ?? '$defaultValue') ?? defaultValue;
  }

  final inapPerHari = getSettingInt('inap_per_hari', 5000);
  final inapMinggu = getSettingInt('inap_minggu', 10000);
  final switchHour = getSettingInt('switch_hour', 18);
  
  final tarifJp = getSettingInt('tarif_${jenis}_jp', jenis == 'mobil' ? 5000 : 2000);
  final tarifPj = getSettingInt('tarif_${jenis}_pj', jenis == 'mobil' ? 3000 : 1000);
  final tarifMh = getSettingInt('tarif_${jenis}_mh', jenis == 'mobil' ? 30000 : 10000);

  // --- LOGIKA PERHITUNGAN BARU YANG LEBIH AKURAT ---

  // Tentukan batas waktu check-out untuk hari pertama.
  var batasWaktuHariPertama = DateTime(masuk.year, masuk.month, masuk.day, switchHour);
  if (masuk.hour >= switchHour) {
    // Jika masuk sudah lewat switch_hour, batasnya adalah switch_hour hari berikutnya.
    batasWaktuHariPertama = batasWaktuHariPertama.add(const Duration(days: 1));
  }

  // KASUS 1: Kendaraan keluar SEBELUM batas waktu hari pertama (tidak menginap)
  if (keluar.isBefore(batasWaktuHariPertama)) {
    final durasi = keluar.difference(masuk);
    if (durasi.inMinutes < 5) return 0; // Parkir sangat singkat gratis

    final jam = (durasi.inSeconds / 3600).ceil();
    if (jam <= 1) {
        // Biaya jam pertama sudah dicover oleh biaya masuk
        return 0;
    }
    
    // Hitung biaya per jam normal, lalu kurangi biaya jam pertama yg sudah tercover.
    int biayaPerJam = tarifJp + (max(0, jam - 1) * tarifPj);
    int biayaMaksHarian = tarifMh;
    
    int biayaTambahan = min(biayaPerJam, biayaMaksHarian) - tarifJp;
    return max(0, biayaTambahan);
  }
  // KASUS 2: Kendaraan keluar SETELAH batas waktu hari pertama (sudah pasti menginap)
  else {
    int totalBiayaInap = 0;
    // Jadikan batas waktu hari pertama sebagai titik awal perhitungan inap
    var cursor = batasWaktuHariPertama; 

    // Loop maju per hari dari titik awal sampai mencapai waktu keluar
    while (cursor.isBefore(keluar)) {
      // Cek hari pada saat 'cursor' (yaitu saat pergantian hari parkir)
      if (cursor.weekday == DateTime.sunday) {
        totalBiayaInap += inapMinggu;
      } else {
        totalBiayaInap += inapPerHari;
      }
      // Maju ke batas waktu hari berikutnya
      cursor = cursor.add(const Duration(days: 1));
    }
    return totalBiayaInap;
  }
}