import 'package:flutter/material.dart';
import '../helpers/db_helper.dart';
import '../models/barang.dart';

class DaftarBarangScreen extends StatefulWidget {
  const DaftarBarangScreen({super.key});

  @override
  State<DaftarBarangScreen> createState() => _DaftarBarangScreenState();
}

class _DaftarBarangScreenState extends State<DaftarBarangScreen> {
  late Future<List<Barang>> _barangList;

  @override
  void initState() {
    super.initState();
    _loadBarang();
  }

  void _loadBarang() {
    _barangList = DBHelper().getAllBarang();
    setState(() {});
  }

  void _showEditDialog(Barang barang) {
    final namaController = TextEditingController(text: barang.nama);
    final hargaController = TextEditingController(text: barang.harga.toString());
    final stokController = TextEditingController(text: barang.stok.toString());

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Edit Barang'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: namaController,
                decoration: InputDecoration(labelText: 'Nama Barang'),
              ),
              TextField(
                controller: hargaController,
                decoration: InputDecoration(labelText: 'Harga'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: stokController,
                decoration: InputDecoration(labelText: 'Stok'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              String nama = namaController.text;
              int? harga = int.tryParse(hargaController.text);
              int? stok = int.tryParse(stokController.text);

              if (nama.isEmpty || harga == null || stok == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Data tidak valid')),
                );
                return;
              }

              Barang updatedBarang = Barang(
                id: barang.id,
                nama: nama,
                harga: harga,
                stok: stok,
              );

              await DBHelper().updateBarang(updatedBarang);
              Navigator.pop(context);
              _loadBarang();

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Barang berhasil diupdate')),
              );
            },
            child: Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _hapusBarang(int id) async {
    await DBHelper().deleteBarang(id);
    _loadBarang();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Barang berhasil dihapus')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Daftar Barang')),
      body: FutureBuilder<List<Barang>>(
        future: _barangList,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
          final barangList = snapshot.data!;
          if (barangList.isEmpty) return Center(child: Text('Tidak ada barang'));

          return ListView.builder(
            itemCount: barangList.length,
            itemBuilder: (context, index) {
              final barang = barangList[index];
              return ListTile(
                title: Text(barang.nama),
                subtitle: Text('Harga: Rp${barang.harga} | Stok: ${barang.stok}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, color: Colors.orange),
                      onPressed: () => _showEditDialog(barang),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: Text('Hapus Barang'),
                          content: Text('Yakin ingin menghapus "${barang.nama}"?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context), child: Text('Batal')),
                            ElevatedButton(
                              onPressed: () {
                                _hapusBarang(barang.id!);
                                Navigator.pop(context);
                              },
                              child: Text('Hapus'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
