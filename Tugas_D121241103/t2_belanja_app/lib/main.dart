import 'package:flutter/material.dart';

void main() {
  runApp(const BelanjaApp());
}

class BelanjaApp extends StatelessWidget {
  const BelanjaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aplikasi Belanja & Diskon',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

/// Model untuk satu baris pada daftar harga
class ItemHarga {
  String nama;
  double harga;
  ItemHarga(this.nama, this.harga);
}

/// Model untuk satu baris pada daftar belanjaan
class ItemBelanjaan {
  String nama;
  int jumlah;
  double hargaSatuan;
  ItemBelanjaan(this.nama, this.jumlah, this.hargaSatuan);

  double get subtotal => jumlah * hargaSatuan;
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // ================================================================
  // 01. MENYIMPAN DAFTAR HARGA (input dari user, built-in type: List)
  // ================================================================
  final List<ItemHarga> daftarHarga = [];
  final TextEditingController _namaHargaCtrl = TextEditingController();
  final TextEditingController _hargaCtrl = TextEditingController();

  void tambahHarga() {
    final String nama = _namaHargaCtrl.text.trim();
    final double? harga = double.tryParse(_hargaCtrl.text.trim());

    if (nama.isEmpty || harga == null || harga <= 0) {
      _showSnackBar('Nama barang dan harga harus diisi dengan benar');
      return;
    }

    setState(() {
      daftarHarga.add(ItemHarga(nama, harga));
      _namaHargaCtrl.clear();
      _hargaCtrl.clear();
    });
  }

  void hapusHarga(int index) {
    setState(() => daftarHarga.removeAt(index));
  }

  // ====================================================================
  // 02. MENYIMPAN DAFTAR BELANJAAN (dipilih dari daftar harga oleh user)
  // ====================================================================
  final List<ItemBelanjaan> daftarBelanjaan = [];
  String? _itemTerpilih;
  final TextEditingController _jumlahCtrl = TextEditingController();

  void tambahBelanjaan() {
    if (_itemTerpilih == null) {
      _showSnackBar('Pilih barang terlebih dahulu');
      return;
    }
    final int? jumlah = int.tryParse(_jumlahCtrl.text.trim());
    if (jumlah == null || jumlah <= 0) {
      _showSnackBar('Jumlah harus diisi dengan angka yang valid');
      return;
    }

    final ItemHarga item = daftarHarga.firstWhere((h) => h.nama == _itemTerpilih);

    setState(() {
      daftarBelanjaan.add(ItemBelanjaan(item.nama, jumlah, item.harga));
      _jumlahCtrl.clear();
      _sudahDihitung = false;
    });
  }

  void hapusBelanjaan(int index) {
    setState(() {
      daftarBelanjaan.removeAt(index);
      _sudahDihitung = false;
    });
  }

  double _hitungSubtotal() {
    double total = 0;
    for (final ItemBelanjaan item in daftarBelanjaan) {
      total += item.subtotal;
    }
    return total;
  }

  // ================================================================
  // 03. MENENTUKAN CASE DISKON (if / else if / else + operator >=)
  // ================================================================
  double _tentukanDiskon(double subtotal) {
    double diskon;
    if (subtotal >= 100000) {
      diskon = 0.15; // belanja >= Rp100.000 -> diskon 15%
    } else if (subtotal >= 50000) {
      diskon = 0.10; // belanja >= Rp50.000  -> diskon 10%
    } else if (subtotal >= 25000) {
      diskon = 0.05; // belanja >= Rp25.000  -> diskon 5%
    } else {
      diskon = 0.0; // di bawah Rp25.000 -> tanpa diskon
    }
    return diskon;
  }

  // ================================================================
  // 04. MENAMPILKAN TOTAL AKHIR BELANJAAN
  // ================================================================
  double subtotal = 0;
  double diskon = 0;
  double totalAkhir = 0;
  bool _sudahDihitung = false;

  void hitungTotalAkhir() {
    if (daftarBelanjaan.isEmpty) {
      _showSnackBar('Tambahkan minimal satu barang belanjaan');
      return;
    }
    final double sub = _hitungSubtotal();
    final double disk = _tentukanDiskon(sub);
    setState(() {
      subtotal = sub;
      diskon = disk;
      totalAkhir = sub - (sub * disk);
      _sudahDihitung = true;
    });
  }

  // ---------------- Helper ----------------
  void _showSnackBar(String pesan) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(pesan), behavior: SnackBarBehavior.floating),
    );
  }

  String _formatRupiah(double value) {
    final int intVal = value.round();
    final String str = intVal.toString();
    final StringBuffer buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      buffer.write(str[i]);
      count++;
      if (count % 3 == 0 && i != 0) buffer.write('.');
    }
    final String hasil = buffer.toString().split('').reversed.join();
    return 'Rp$hasil';
  }

  @override
  void dispose() {
    _namaHargaCtrl.dispose();
    _hargaCtrl.dispose();
    _jumlahCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aplikasi Belanja & Diskon'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionHarga(),
            const SizedBox(height: 20),
            _buildSectionBelanjaan(),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: hitungTotalAkhir,
              icon: const Icon(Icons.calculate),
              label: const Text('Hitung Total'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 20),
            if (_sudahDihitung) _buildHasil(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ---------------- UI: Section 01 ----------------
  Widget _buildSectionHarga() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '01. Daftar Harga',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _namaHargaCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nama barang',
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _hargaCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Harga',
                      isDense: true,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: tambahHarga,
                  icon: const Icon(Icons.add_circle, color: Colors.indigo),
                ),
              ],
            ),
            if (daftarHarga.isNotEmpty)
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: daftarHarga.length,
                itemBuilder: (context, index) {
                  final ItemHarga item = daftarHarga[index];
                  return ListTile(
                    dense: true,
                    title: Text(item.nama),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_formatRupiah(item.harga)),
                        IconButton(
                          icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                          onPressed: () => hapusHarga(index),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  // ---------------- UI: Section 02 ----------------
  Widget _buildSectionBelanjaan() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '02. Daftar Belanjaan',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _itemTerpilih,
                    decoration: const InputDecoration(
                      labelText: 'Pilih barang',
                      isDense: true,
                    ),
                    items: daftarHarga
                        .map(
                          (h) => DropdownMenuItem<String>(
                            value: h.nama,
                            child: Text(h.nama, overflow: TextOverflow.ellipsis),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => _itemTerpilih = value),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _jumlahCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Jumlah',
                      isDense: true,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: tambahBelanjaan,
                  icon: const Icon(Icons.add_shopping_cart, color: Colors.indigo),
                ),
              ],
            ),
            if (daftarHarga.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Tambahkan daftar harga terlebih dahulu di bagian atas.',
                  style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                ),
              ),
            if (daftarBelanjaan.isNotEmpty)
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: daftarBelanjaan.length,
                itemBuilder: (context, index) {
                  final ItemBelanjaan item = daftarBelanjaan[index];
                  return ListTile(
                    dense: true,
                    title: Text('${item.nama} x${item.jumlah}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_formatRupiah(item.subtotal)),
                        IconButton(
                          icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                          onPressed: () => hapusBelanjaan(index),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  // ---------------- UI: Section 03 & 04 ----------------
  Widget _buildHasil() {
    return Card(
      color: Colors.indigo.shade50,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hasil Perhitungan',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildBaris('Subtotal', _formatRupiah(subtotal)),
            _buildBaris('Diskon', '${(diskon * 100).toStringAsFixed(0)}%'),
            const Divider(),
            _buildBaris('Total Akhir', _formatRupiah(totalAkhir), tebal: true),
          ],
        ),
      ),
    );
  }

  Widget _buildBaris(String label, String value, {bool tebal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontWeight: tebal ? FontWeight.bold : FontWeight.normal),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: tebal ? FontWeight.bold : FontWeight.normal,
              fontSize: tebal ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }
}