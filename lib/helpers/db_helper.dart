// helpers/db_helper.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/barang.dart';
import '../models/transaksi.dart';

class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  factory DBHelper() => _instance;
  DBHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    final path = join(await getDatabasesPath(), 'kasir.db');
    return await openDatabase(
      path,
      version: 5,  // Naikkan versi database jadi 5
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE barang (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nama TEXT,
            harga INTEGER,
            stok INTEGER
          )
        ''');

        await db.execute('''
          CREATE TABLE transaksi (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            kode_transaksi TEXT,
            namaBarang TEXT,
            jumlah INTEGER,
            totalHarga INTEGER,
            tanggal TEXT,
            jam TEXT,
            uangBayar INTEGER,
            kembalian INTEGER,
            metodeBayar TEXT
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // migrasi versi 2
          await db.execute('''
            CREATE TABLE transaksi_new (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              kode_transaksi TEXT,
              namaBarang TEXT,
              jumlah INTEGER,
              totalHarga INTEGER,
              tanggal TEXT
            )
          ''');
          await db.execute('''
            INSERT INTO transaksi_new (id, namaBarang, jumlah, totalHarga, tanggal)
            SELECT id, namaBarang, jumlah, totalHarga, tanggal FROM transaksi
          ''');
          await db.execute('DROP TABLE transaksi');
          await db.execute('ALTER TABLE transaksi_new RENAME TO transaksi');
        }
        if (oldVersion < 3) {
          await db.execute('ALTER TABLE transaksi ADD COLUMN jam TEXT DEFAULT ""');
        }
        if (oldVersion < 4) {
          await db.execute('ALTER TABLE transaksi ADD COLUMN uangBayar INTEGER DEFAULT 0');
          await db.execute('ALTER TABLE transaksi ADD COLUMN kembalian INTEGER DEFAULT 0');
        }
        if (oldVersion < 5) {
          await db.execute('ALTER TABLE transaksi ADD COLUMN metodeBayar TEXT DEFAULT "Cash"');
        }
      },
    );
  }

  // ------------------- BARANG -------------------
  Future<int> insertBarang(Barang barang) async {
    final db = await database;
    return await db.insert('barang', barang.toMap());
  }

  Future<List<Barang>> getAllBarang() async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.query('barang');
    return result.map((e) => Barang.fromMap(e)).toList();
  }

  Future<int> updateBarangStok(int id, int stokBaru) async {
    final db = await database;
    return await db.update(
      'barang',
      {'stok': stokBaru},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateBarang(Barang barang) async {
    final db = await database;
    return await db.update(
      'barang',
      barang.toMap(),
      where: 'id = ?',
      whereArgs: [barang.id],
    );
  }

  Future<int> deleteBarang(int id) async {
    final db = await database;
    return await db.delete(
      'barang',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ------------------- TRANSAKSI -------------------
  Future<int> insertTransaksi(Transaksi transaksi) async {
    final db = await database;
    return await db.insert('transaksi', transaksi.toMap());
  }

  Future<List<Transaksi>> getAllTransaksi() async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.query('transaksi');
    return result.map((e) => Transaksi.fromMap(e)).toList();
  }

  Future<List<Transaksi>> getTransaksiByTanggal(String tanggal) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.query(
      'transaksi',
      where: 'tanggal = ?',
      whereArgs: [tanggal],
      orderBy: 'id DESC',
    );
    return result.map((e) => Transaksi.fromMap(e)).toList();
  }

  Future<List<Transaksi>> getTransaksiByKode(String kodeTransaksi) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.query(
      'transaksi',
      where: 'kode_transaksi = ?',
      whereArgs: [kodeTransaksi],
      orderBy: 'id ASC',
    );
    return result.map((e) => Transaksi.fromMap(e)).toList();
  }

  Future<List<String>> getAllKodeTransaksiUnikByTanggal(String tanggal) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT DISTINCT kode_transaksi FROM transaksi
      WHERE tanggal = ?
      ORDER BY id DESC
    ''', [tanggal]);

    return result.map((row) => row['kode_transaksi'] as String).toList();
  }

  // Tambahan method baru untuk total pendapatan hari ini
  Future<int> getTotalPendapatanByTanggal(String tanggal) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT SUM(totalHarga) as total FROM transaksi WHERE tanggal = ?
    ''', [tanggal]);

    if (result.isNotEmpty && result[0]['total'] != null) {
      return result[0]['total'] as int;
    } else {
      return 0;
    }
  }

  Future<int> deleteTransaksiByKode(String kodeTransaksi) async {
  final db = await database;
  return await db.delete(
    'transaksi',
    where: 'kode_transaksi = ?',
    whereArgs: [kodeTransaksi],
  );
}

}
