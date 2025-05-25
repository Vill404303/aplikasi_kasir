import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../helpers/db_helper.dart';
import '../models/barang.dart';
import '../models/transaksi.dart';

class TransaksiScreen extends StatefulWidget {
  const TransaksiScreen({super.key});

  @override
  State<TransaksiScreen> createState() => _TransaksiScreenState();
}

class _TransaksiScreenState extends State<TransaksiScreen> {
  late Future<List<Barang>> _barangList;
  List<Barang> _barangListCache = [];
  final Map<int, int> _keranjang = {};
  final Map<int, int> _hargaBarang = {};

  final TextEditingController _uangBayarController = TextEditingController();
  final NumberFormat _formatter = NumberFormat('#,###', 'id_ID');

  int _totalBayar = 0;
  int _kembalian = 0;
  int _customIdCounter = -1;
  String _metodeBayar = 'Cash';

  @override
  void initState() {
    super.initState();
    _loadBarang();
    _uangBayarController.addListener(_hitungKembalian);
  }

  void _loadBarang() async {
    List<Barang> barang = await DBHelper().getAllBarang();
    setState(() {
      _barangListCache = barang;
      _barangList = Future.value(_barangListCache);
    });
  }

  void _tambahKeKeranjang(Barang barang) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Masukkan jumlah untuk ${barang.nama}'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Jumlah'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              int jumlah = int.tryParse(controller.text) ?? 0;
              if (jumlah <= 0 || jumlah > barang.stok) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Jumlah tidak valid')),
                );
                return;
              }

              setState(() {
                _keranjang.update(barang.id!, (value) => value + jumlah, ifAbsent: () => jumlah);
                _hargaBarang[barang.id!] = barang.harga;
                _hitungTotalBayar();
              });

              Navigator.pop(context);
            },
            child: const Text('Tambah'),
          ),
        ],
      ),
    );
  }

  void _tambahNominalLainnya() {
    final namaController = TextEditingController();
    final hargaController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nominal Lainnya'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: namaController,
              decoration: const InputDecoration(labelText: 'Nama Barang (opsional)'),
            ),
            TextField(
              controller: hargaController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Nominal Harga'),
              onChanged: (value) {
                String digits = value.replaceAll('.', '');
                if (digits.isEmpty) return;
                int number = int.tryParse(digits) ?? 0;
                String formatted = _formatter.format(number);
                if (formatted != value) {
                  hargaController.value = TextEditingValue(
                    text: formatted,
                    selection: TextSelection.collapsed(offset: formatted.length),
                  );
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              String nama = namaController.text.trim();
              int harga = int.tryParse(hargaController.text.replaceAll('.', '')) ?? 0;

              if (harga <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Isi nominal dengan benar')),
                );
                return;
              }

              if (nama.isEmpty) {
                nama = 'Nominal Lainnya';
              }

              setState(() {
                int customId = _customIdCounter--;
                _keranjang[customId] = 1;
                _hargaBarang[customId] = harga;

                _barangListCache.add(Barang(id: customId, nama: nama, harga: harga, stok: 0));
                _barangList = Future.value(_barangListCache);

                _hitungTotalBayar();
              });

              Navigator.pop(context);
            },
            child: const Text('Tambah'),
          ),
        ],
      ),
    );
  }

  void _hitungTotalBayar() {
    int total = 0;
    _keranjang.forEach((id, jumlah) {
      final barang = _barangListCache.firstWhere(
        (b) => b.id == id,
        orElse: () => Barang(id: id, nama: 'Custom', harga: _hargaBarang[id]!, stok: 0),
      );
      total += barang.harga * jumlah;
    });

    setState(() {
      _totalBayar = total;
      _hitungKembalian();
    });
  }

  void _hitungKembalian() {
    final bayar = int.tryParse(_uangBayarController.text.replaceAll('.', '')) ?? 0;
    setState(() {
      _kembalian = bayar - _totalBayar;
      if (_kembalian < 0) _kembalian = 0;
    });
  }

  String _generateKodeTransaksi() {
    final now = DateTime.now();
    return 'TRX${DateFormat('yyyyMMddHHmmss').format(now)}';
  }

  Future<void> _prosesPembayaran(List<Barang> barangList) async {
    if (_totalBayar == 0) return;

    final bayar = int.tryParse(_uangBayarController.text.replaceAll('.', '')) ?? 0;
    if (bayar < _totalBayar) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Uang bayar kurang')),
      );
      return;
    }

    final tanggal = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final jam = DateFormat('HH:mm:ss').format(DateTime.now());
    final kodeTransaksi = _generateKodeTransaksi();
    final kembalian = bayar - _totalBayar;

    for (var entry in _keranjang.entries) {
      final barang = _barangListCache.firstWhere(
        (b) => b.id == entry.key,
        orElse: () => Barang(id: entry.key, nama: 'Custom', harga: _hargaBarang[entry.key]!, stok: 0),
      );
      final jumlah = entry.value;
      final total = barang.harga * jumlah;

      await DBHelper().insertTransaksi(Transaksi(
        kodeTransaksi: kodeTransaksi,
        namaBarang: barang.nama,
        jumlah: jumlah,
        totalHarga: total,
        tanggal: tanggal,
        jam: jam,
        uangBayar: bayar,
        kembalian: kembalian,
        metodeBayar: _metodeBayar,
      ));

      if (barang.id! > 0) {
        await DBHelper().updateBarangStok(barang.id!, barang.stok - jumlah);
      }
    }

    setState(() {
      _keranjang.clear();
      _hargaBarang.clear();
      _uangBayarController.clear();
      _totalBayar = 0;
      _kembalian = 0;
      _metodeBayar = 'Cash';
      _loadBarang();
    });

    // ✅ Show confirmation dialog
    showDialog(
  context: context,
  builder: (_) => AlertDialog(
    title: const Text('Transaksi Berhasil'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Kode Transaksi: $kodeTransaksi'),
        const SizedBox(height: 8),
        Text('Total Pembayaran: Rp${_formatter.format(_totalBayar)}'),
        Text('Uang Bayar: Rp${_formatter.format(bayar)}'),
        Text('Metode Pembayaran: $_metodeBayar'),
        Text('Kembalian: Rp${_formatter.format(kembalian)}'),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Tutup'),
      ),
    ],
  ),
);

  }

  @override
  void dispose() {
    _uangBayarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transaksi')),
      body: FutureBuilder<List<Barang>>(
        future: _barangList,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final barangList = snapshot.data!;
          if (barangList.isEmpty) return const Center(child: Text('Tidak ada barang'));

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: barangList.length,
                  itemBuilder: (context, index) {
                    final barang = barangList[index];
                    return ListTile(
                      title: Text(barang.nama),
                      subtitle: Text('Stok: ${barang.stok} | Harga: Rp${_formatter.format(barang.harga)}'),
                      trailing: ElevatedButton(
                        onPressed: () => _tambahKeKeranjang(barang),
                        child: const Text('Pilih'),
                      ),
                    );
                  },
                ),
              ),
              const Divider(),
              ListTile(
                title: const Text('Total Bayar'),
                trailing: Text('Rp${_formatter.format(_totalBayar)}'),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _uangBayarController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Uang Bayar',
                          prefixText: 'Rp ',
                        ),
                        onChanged: (value) {
                          String digits = value.replaceAll('.', '');
                          if (digits.isEmpty) return;
                          int number = int.tryParse(digits) ?? 0;
                          String formatted = _formatter.format(number);
                          if (formatted != value) {
                            _uangBayarController.value = TextEditingValue(
                              text: formatted,
                              selection: TextSelection.collapsed(offset: formatted.length),
                            );
                          }
                          _hitungKembalian();
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    DropdownButton<String>(
                      value: _metodeBayar,
                      items: const [
                        DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                        DropdownMenuItem(value: 'Transfer', child: Text('Transfer')),
                        DropdownMenuItem(value: 'QRIS', child: Text('QRIS')),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _metodeBayar = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              ListTile(
                title: const Text('Kembalian'),
                trailing: Text('Rp${_formatter.format(_kembalian)}'),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: _tambahNominalLainnya,
                    icon: const Icon(Icons.add),
                    label: const Text('Nominal Lainnya'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _prosesPembayaran(barangList),
                    icon: const Icon(Icons.payment),
                    label: const Text('Bayar'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }
}
