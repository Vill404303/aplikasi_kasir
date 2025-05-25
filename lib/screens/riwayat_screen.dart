import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../helpers/db_helper.dart';
import '../models/transaksi.dart';

class RiwayatScreen extends StatefulWidget {
  const RiwayatScreen({Key? key}) : super(key: key);

  @override
  State<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends State<RiwayatScreen> {
  DateTime _selectedDate = DateTime.now();
  late Future<List<String>> _kodeTransaksiListFuture;
  late Future<int> _totalPendapatanFuture;
  final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
    _kodeTransaksiListFuture = DBHelper().getAllKodeTransaksiUnikByTanggal(formattedDate);
    _totalPendapatanFuture = DBHelper().getTotalPendapatanByTanggal(formattedDate);
  }

  Future<void> _hapusTransaksi(String kodeTransaksi) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Transaksi'),
        content: const Text('Apakah Anda yakin ingin menghapus transaksi ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus')),
        ],
      ),
    );

    if (confirm == true) {
      await DBHelper().deleteTransaksiByKode(kodeTransaksi);
      setState(() {
        _loadData();
      });
    }
  }

  String _formatDisplayDateTime(List<Transaksi> transaksiItems) {
    if (transaksiItems.isEmpty) return '';
    final tanggal = transaksiItems.first.tanggal;
    final jam = transaksiItems.first.jam ?? '';
    return '$tanggal $jam';
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _loadData();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Transaksi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _selectDate(context),
          ),
        ],
      ),
      body: FutureBuilder<List<String>>(
        future: _kodeTransaksiListFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Tidak ada transaksi pada tanggal ini'));
          }

          final kodeTransaksiList = snapshot.data!;

          return FutureBuilder<int>(
            future: _totalPendapatanFuture,
            builder: (context, snapshotTotal) {
              if (snapshotTotal.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              int totalPendapatan = snapshotTotal.data ?? 0;

              return Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: kodeTransaksiList.length,
                      itemBuilder: (context, index) {
                        final kodeTransaksi = kodeTransaksiList[index];

                        return FutureBuilder<List<Transaksi>>(
                          future: DBHelper().getTransaksiByKode(kodeTransaksi),
                          builder: (context, snapshotTrx) {
                            if (snapshotTrx.connectionState == ConnectionState.waiting) {
                              return const ListTile(title: Text('Memuat transaksi...'));
                            }

                            if (!snapshotTrx.hasData || snapshotTrx.data!.isEmpty) {
                              return const SizedBox.shrink();
                            }

                            final transaksiItems = snapshotTrx.data!;
                            final displayDateTime = _formatDisplayDateTime(transaksiItems);

                            int totalBelanja = transaksiItems.fold(0, (sum, trx) => sum + trx.totalHarga);
                            int uangBayar = transaksiItems.first.uangBayar ?? 0;
                            int kembalian = transaksiItems.first.kembalian ?? 0;
                            String metodeBayar = transaksiItems.first.metodeBayar ?? 'Tidak diketahui';

                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              elevation: 2,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Transaksi $displayDateTime',
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          onPressed: () => _hapusTransaksi(kodeTransaksi),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    ...transaksiItems.map((trx) {
                                      int hargaSatuan = trx.totalHarga ~/ trx.jumlah;
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 2),
                                        child: Text(
                                          '- ${trx.namaBarang} | Jumlah: ${trx.jumlah} | Harga: ${currencyFormatter.format(hargaSatuan)} | Total: ${currencyFormatter.format(trx.totalHarga)}',
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      );
                                    }).toList(),
                                    const Divider(height: 16, thickness: 1),
                                    Text('Total Belanja: ${currencyFormatter.format(totalBelanja)}'),
                                    Text('Dibayar Pembeli: ${currencyFormatter.format(uangBayar)}'),
                                    Text('Kembalian: ${currencyFormatter.format(kembalian)}'),
                                    Text('Metode Bayar: $metodeBayar'),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.grey[100],
                    width: double.infinity,
                    child: Text(
                      'Total Pendapatan Hari Ini: ${currencyFormatter.format(totalPendapatan)}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
