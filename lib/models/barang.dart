class Barang {
  final int? id;
  final String nama;
  final int harga;
  final int stok;

  Barang({this.id, required this.nama, required this.harga, required this.stok});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nama': nama,
      'harga': harga,
      'stok': stok,
    };
  }

  factory Barang.fromMap(Map<String, dynamic> map) {
    return Barang(
      id: map['id'],
      nama: map['nama'],
      harga: map['harga'],
      stok: map['stok'],
    );
  }
}
