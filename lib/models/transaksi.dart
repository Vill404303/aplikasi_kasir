class Transaksi {
  int? id;
  String kodeTransaksi; // ubah ke kode_transaksi jika mau konsisten dengan DB
  String namaBarang;
  int jumlah;
  int totalHarga;
  String tanggal;
  String jam;
  int? uangBayar;
  int? kembalian;
  String metodeBayar; // field baru

  Transaksi({
    this.id,
    required this.kodeTransaksi,
    required this.namaBarang,
    required this.jumlah,
    required this.totalHarga,
    required this.tanggal,
    required this.jam,
    this.uangBayar,
    this.kembalian,
    required this.metodeBayar, // wajib di constructor
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'kode_transaksi': kodeTransaksi, // pakai key DB
      'namaBarang': namaBarang,
      'jumlah': jumlah,
      'totalHarga': totalHarga,
      'tanggal': tanggal,
      'jam': jam,
      'uangBayar': uangBayar,
      'kembalian': kembalian,
      'metodeBayar': metodeBayar, // simpan field baru
    };
  }

  factory Transaksi.fromMap(Map<String, dynamic> map) {
    return Transaksi(
      id: map['id'],
      kodeTransaksi: map['kode_transaksi'], // key DB
      namaBarang: map['namaBarang'],
      jumlah: map['jumlah'],
      totalHarga: map['totalHarga'],
      tanggal: map['tanggal'],
      jam: map['jam'],
      uangBayar: map['uangBayar'],
      kembalian: map['kembalian'],
      metodeBayar: map['metodeBayar'] ?? 'Cash', // default 'Cash' kalau null
    );
  }
}
