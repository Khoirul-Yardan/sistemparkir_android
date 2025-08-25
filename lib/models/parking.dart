class Parking {
  final int? id;
  final String kode;
  final String plat;
  final String jenis; // 'motor' | 'mobil'
  final DateTime masuk;
  final DateTime? keluar;
  final int? biaya;
  final String status; // 'IN' | 'OUT'
  final bool titipHelm;
  final int? biayaMasuk;

  Parking({
    this.id,
    required this.kode,
    required this.plat,
    required this.jenis,
    required this.masuk,
    this.keluar,
    this.biaya,
    this.status = 'IN',
    this.titipHelm = false,
    this.biayaMasuk,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'kode': kode,
        'plat': plat,
        'jenis': jenis,
        'waktu_masuk': masuk.toIso8601String(),
        'waktu_keluar': keluar?.toIso8601String(),
        'biaya': biaya,
        'status': status,
        'titip_helm': titipHelm ? 1 : 0,
        'biaya_masuk': biayaMasuk,
      };

  factory Parking.fromMap(Map<String, dynamic> m) => Parking(
        id: m['id'] as int?,
        kode: m['kode'] as String,
        plat: m['plat'] as String,
        jenis: m['jenis'] as String,
        masuk: DateTime.parse(m['waktu_masuk'] as String),
        keluar: m['waktu_keluar'] != null ? DateTime.parse(m['waktu_keluar'] as String) : null,
        biaya: m['biaya'] as int?,
        status: m['status'] as String,
        titipHelm: (m['titip_helm'] ?? 0) == 1,
        biayaMasuk: m['biaya_masuk'] as int?,
      );
}
