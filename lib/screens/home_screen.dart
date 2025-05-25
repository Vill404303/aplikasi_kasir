import 'package:flutter/material.dart';
import 'tambah_barang_screen.dart';
import 'transaksi_screen.dart';
import 'riwayat_screen.dart';
import 'daftar_barang_screen.dart'; // <- Tambahkan import ini

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Aplikasi Kasir'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            MenuButton(
              label: 'Tambah Barang',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => TambahBarangScreen()),
                );
              },
            ),
            SizedBox(height: 16),
            MenuButton(
              label: 'Daftar Barang', // <- Tombol baru
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => DaftarBarangScreen()),
                );
              },
            ),
            SizedBox(height: 16),
            MenuButton(
              label: 'Transaksi',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => TransaksiScreen()),
                );
              },
            ),
            SizedBox(height: 16),
            MenuButton(
              label: 'Riwayat Transaksi',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RiwayatScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class MenuButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const MenuButton({
    super.key,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.teal,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
