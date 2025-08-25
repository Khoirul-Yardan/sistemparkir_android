# Sistem Parkir Flutter (Offline - Full)

Fitur:
- Masuk/Keluar kendaraan dengan **QR tiket** (generate + scan kamera).
- **Cetak/Share PDF** struk thermal (58mm) via `printing`.
- **Backup/Restore JSON**.
- **Pencarian tiket aktif** + validasi kode unik (auto-generate).
- Aturan biaya **lokasi**: biaya masuk, deposit titip helm, biaya inap per tanggal (Minggu beda), pergantian tanggal jam 18:00.

## Menjalankan
```bash
flutter pub get
flutter run
```

## Catatan thermal
Untuk printer thermal Bluetooth (ESC/POS), bisa ditambah plugin khusus.
Saat ini struk dibuat PDF agar bisa diprint ke printer apa pun (termasuk share ke aplikasi printer thermal).

Lisensi: MIT
