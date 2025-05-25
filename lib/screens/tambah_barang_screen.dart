import 'package:flutter/material.dart';
import '../helpers/db_helper.dart';
import '../models/barang.dart';

class TambahBarangScreen extends StatefulWidget {
  const TambahBarangScreen({super.key});

  @override
  State<TambahBarangScreen> createState() => _TambahBarangScreenState();
}

class _TambahBarangScreenState extends State<TambahBarangScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _hargaController = TextEditingController();
  final TextEditingController _stokController = TextEditingController();

  void _simpanBarang() async {
    if (_formKey.currentState!.validate()) {
      String nama = _namaController.text;
      int harga = int.parse(_hargaController.text);
      int stok = int.parse(_stokController.text);

      Barang barang = Barang(nama: nama, harga: harga, stok: stok);
      await DBHelper().insertBarang(barang);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Barang berhasil disimpan ke database')),
      );

      _namaController.clear();
      _hargaController.clear();
      _stokController.clear();
    }
  }

  @override
  void dispose() {
    _namaController.dispose();
    _hargaController.dispose();
    _stokController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Tambah Barang')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _namaController,
                decoration: InputDecoration(labelText: 'Nama Barang'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Wajib diisi' : null,
              ),
              TextFormField(
                controller: _hargaController,
                decoration: InputDecoration(labelText: 'Harga (Rp)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Wajib diisi';
                  if (int.tryParse(value) == null) return 'Harus berupa angka';
                  return null;
                },
              ),
              TextFormField(
                controller: _stokController,
                decoration: InputDecoration(labelText: 'Stok'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Wajib diisi';
                  if (int.tryParse(value) == null) return 'Harus berupa angka';
                  return null;
                },
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _simpanBarang,
                child: Text('Simpan Barang'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
